local socket = require("socket")
local http = require("socket.http")
local luasql = require("luasql.sqlite3")
local dkjson = require("reporter.dkjson")
local zlib = require("zlib")

--
-- Configuration settings:
--
-- server_url           Where event reports are sent.
-- report_interval      Time in seconds between reports sent to server.
-- unsent_threshold     Number of unsent events that, if reached, forces a
--                      report to be sent even if time since last report is less
--                      than `report_interval`.
-- idle_time            Time in seconds that reporter thread spends sleeping.
--                      Every `idle_time` seconds it wakes up to check if enough
--                      events have been accumulated (or enough time has passed)
--                      to send a new report.
-- max_saved_reports    Save up to `max_saved_reports` unsent reports. New
--                      reports replace older ones.
-- show_log             Display log messages (disable for release).
--
local server_url = "http://update.oranzais.lumii.lv/tda"
local report_interval = 30
local unsent_threshold = 10
local idle_time = 5
local max_saved_reports = 15
local show_log = false

--
-- Print log message (accepts multiple values) if `show_log` switch is on.
--
local function log(...)
        if not show_log then
                return
        end
        print("[report.lua]", ...)
end

--
-- Go to sleep for a given number of seconds using select().
--
local function sleep(sec)
        socket.select(nil, nil, sec)
end

--
-- Strip leading and trailing whitespace from string.
--
local function strip(s)
        return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

--
-- Append `tail` array to `t` array.
--
local function array_append(t, tail)
        local ins = table.insert
        for i, v in ipairs(tail) do
                ins(t, v)
        end
end

--
-- Return a timezone string in ISO 8601:2000 standard form (+hhmm or -hhmm).
-- Source: http://lua-users.org/wiki/TimeZone
--
local function tzoffset()
        local now = os.time()
        local timezone = os.difftime(now, os.time(os.date("!*t", now)))
        local h, m = math.modf(timezone / 3600)
        return string.format("%+.4d", 100 * h + 60 * m)
end

--
-- Our little database module.
--
local db = {

--
-- Connect to report.db, set `autocommit` to false (we want transactions), and
-- return the connection object.
--
connect = function()
        -- Connect to database and set `autocommit` to false.
        local env = luasql.sqlite3()
        local con, err = env:connect(appdata_path("report.db"))
        if not con then
                log("Database connection failure:", err)
                return nil
        end
        con:setautocommit(false)
        return con
end,

--
-- Close connection without potentially throwing an exception.
--
close = function(con)
        local no_exception, msg = pcall(function() con:close() end)
        if not no_exception then
                log("Exception while closing DB connection:", msg)
        end
end,

--
-- Execute function f(con). If it succeeds (does not throw any errors), then
-- commit the transaction. If it fails, roll the transaction back.
--
transaction = function(con, f)
        local no_exception, msg = pcall(f, con)
        if no_exception then
                local ok, err = con:commit()
                if not ok then
                        log("Cannot commit transaction:", err)
                end
                return true
        end

        log("Rolling back transaction:", msg)
        local ok, err = con:rollback()
        if not ok then
                log("Cannot rollback transaction:", err)
        end
        return false
end
}

--
-- Connect to database, execute user function in a single transaction,
-- disconnect.
--
db.session = function(f)
        local con = db.connect()
        if not con then
                return
        end

        db.transaction(con, f)
        db.close(con)
end

--
-- Execute SQL statement safely (throwing exception in case there's an error)
-- using assert().
--
db.exec = function(con, stmt, ...)
        assert(type(con) == "userdata" and type(stmt) == "string")

        -- Escape string arguments.
        for k, v in pairs(arg) do
                if type(v) == "string" then
                        arg[k] = con:escape(v)
                end
        end

        -- Execute statement.
        return assert(con:execute(string.format(stmt, unpack(arg))))
end

--
-- Execute SQL statement safely (throwing exception in case there's an error)
-- and get single result from cursor.
--
db.fetchone = function(con, mode, stmt, ...)
        local cur = db.exec(con, stmt, ...)
        local value = cur:fetch({}, mode)
        cur:close()
        return value
end

--
-- Execute SQL statement (thowing error in case of an error) and return all
-- results in an array.
--
db.fetchall = function(con, mode, stmt, ...)
        local cur = db.exec(con, stmt, ...)
        local result = {}
        local ins = table.insert
        local row = cur:fetch({}, mode)
        while row do
                ins(result, row)
                row = cur:fetch({}, mode)
        end
        cur:close()
        return result
end

--
-- Retrieve value from "Client" table. Returns nil if the value is missing.
-- Lua error is produced if something goes wrong.
--
local function get_client_value(con, key)
        assert(type(key) == "string" and key == con:escape(key))
        local row = db.fetchone(con, "n", [[ SELECT value FROM Client
                                             WHERE key = '%s']], key)
        if not row then
                return nil
        end
        return row[1]
end

--
-- Insert or replace value in "Client" table.
-- Lua error is produces if something goes wrong.
--
local function set_client_value(con, key, value)
        assert(type(key) == "string" and key == con:escape(key))
        return db.exec(con, [[ INSERT OR REPLACE INTO Client (key, value)
                               VALUES ('%s', '%s') ]], key, tostring(value))
end

--
-- Create database tables if they do not exist. If they do exist but their
-- "CREATE TABLE" statements differ from what we expect, drop and recreate them.
--
-- Produces Lua error in case of failure.
--
local function setup_db(con)
        assert(type(con) == "userdata")
        local create_client = strip([[
            CREATE TABLE Client (
                key    TEXT NOT NULL,
                value  TEXT NOT NULL,
                UNIQUE(key)
            )]])
        local create_unsent = strip([[
            CREATE TABLE UnsentReport (
                session_number INT NOT NULL,
                report         TEXT NOT NULL
            )]])

        -- Recreate table using `create_table_stmt` if it differs from the
        -- statement stored inside `sqlite_master` table.
        local function recreate(table, create_table_stmt)
                assert(table == con:escape(table) and
                    type(create_table_stmt) == "string")

                -- Get present "CREATE TABLE" statement from database.
                local cur = db.exec(con,
                        [[ SELECT sql FROM sqlite_master
                           WHERE type='table' AND name='%s' ]], table)
                local sql = cur:fetch()

                -- NOTE: it is important to close the cursor here. Otherwise
                -- subsequent "DROP TABLE" statement fails with generic SQLite
                -- error.
                assert(cur:close())

                -- If statements differ, drop and recreate table.
                if sql ~= create_table_stmt then
                        db.exec(con, [[ DROP TABLE IF EXISTS %s ]], table)
                        db.exec(con, create_table_stmt)
                end
        end

        -- (Re)create Client table and make sure "session_number" and
        -- "instance_id" values are set.
        recreate("Client", create_client)
        if not get_client_value(con, "instance_id") then
                set_client_value(con, "instance_id",
                    os.date("%Y-%m-%d %H:%M:%S")..'/'..machine_id())
        end
        if not get_client_value(con, "session_number") then
                set_client_value(con, "session_number", 0)
        end

        -- (Re)create unsent reports table.
        recreate("UnsentReport", create_unsent);
end

--
-- Create multi-session report from previously saved unsent reports. Optionally,
-- merge with supplied single-session report (`merge_r` argument).
-- Returns the multi-session report table (which could be empty).
--
local function unsent_reports(merge_r)
        local snum_to_r = {}
        db.session(function(con)
                local cur = db.exec(con, [[ SELECT session_number, report
                                            FROM UnsentReport ]])

                -- The goal here is to get a list of reports so that all
                -- session numbers within that list are unique. This means that
                -- if two reports belong to the same session, their event lists
                -- are concatenated.
                local row = cur:fetch({}, "a")
                while row do
                        local r = dkjson.decode(row.report)
                        local snum = row.session_number
                        if snum_to_r[snum] then
                                array_append(snum_to_r[snum].events, r.events)
                        else
                                snum_to_r[snum] = r
                        end
                        row = cur:fetch({}, "a")
                end
                cur:close()
        end)

        -- Merge argument report if it is present.
        if merge_r then
                local snum = merge_r.session_number
                if snum_to_r[snum] then
                        array_append(snum_to_r[snum].events, merge_r.events)
                else
                        snum_to_r[snum] = merge_r
                end
        end

        -- Create the final, complete report (an array of reports).
        local complete_r = {}
        local ins = table.insert
        for k, r in pairs(snum_to_r) do
                ins(complete_r, r)
        end
        return complete_r
end

--
-- Save report whose transmission failed in SQLite database `report.db`.
--
local function save_report(r)
        db.session(function(con)
                -- Discard older reports.
                local num_r = tonumber(db.fetchone(con, "n",
                        [[ SELECT count(*) FROM UnsentReport ]])[1])
                if num_r >= max_saved_reports then
                        local num_extra = num_r - max_saved_reports + 1
                        local extra = db.fetchall(con, "n",
                                [[ SELECT ROWID FROM UnsentReport
                                   ORDER BY ROWID LIMIT %d ]], num_extra)
                        for i, rowid in ipairs(extra) do
                                db.exec(con, [[ DELETE FROM UnsentReport
                                                WHERE ROWID = %d ]], rowid[1])
                        end
                end

                -- Insert JSON-encoded report.
                local js = dkjson.encode(r)
                db.exec(con, [[ INSERT INTO UnsentReport (session_number, report)
                               VALUES (%d, '%s') ]], r.session_number, js)
        end)
end

--
-- Delete all unsent reports.
--
local function delete_unsent()
        db.session(function(con)
                db.exec(con, [[DELETE FROM UnsentReport]])
        end)
end

--
-- Log an event. This function is called by user scripts whenever they desire to
-- record an event. The `name` argument is necessary and must be a string that
-- gives a name to the event. `data` is an optional table that provides more
-- information about the event. Its keys and values must adhere to these rules:
--     * Keys must be strings.
--     * Keys must not start with an underscore character.
--     * Values must be JSON-serializable. That means that it's either a number,
--       string, boolean, or table that only contains JSON-serializable data.
--     * As a special case, values can also be functions without arguments that
--       produce a JSON-serializable value. These functions will be executed
--       with pcall() which means that any errors are caught and logged as part
--       of the event. Whenever unsure if an event-data expression could produce
--       an error, wrap it in a function (see NOTE below).
--
-- Here's an example of how the event() function may be used:
--   report.event("NewBox", {
--     diagram_id = diagram:id(),
--     elem_type  = function() return node_type:attr("caption") end,
--     parent_id  = function() return parent_node:id() end,
--     element_id = function() return node:id() end
--   })
--
-- NOTE: failure to record an event should not produce a Lua error, so that it
-- would not interfere with normal operation.
--
local function event(name, data)
        -- Validate user event data.
        assert(type(name) == "string")
        data = data or {}
        for k, v in pairs(data) do
                if type(k) ~= "string" then
                        log("Unexpected event key type:", type(k))
                        return false
                end
                if k:sub(1, 1) == "_" then
                        log("User event keys must not start with "..
                            "an underscore:", k)
                        return false
                end

                -- If value is a function, execute it (safely) and store the
                -- result in its place.
                if type(v) == "function" then
                    local rc, value = pcall(v)
                    if rc then
                        data[k] = value
                    else
                        data[k] = "[error] "..value
                    end
                end
        end

        -- Set common values (name, time).
        data._name = name
        data._time = os.date("%Y-%m-%d %H:%M:%S")

        -- Turn data table into JSON string. Make sure we catch any errors
        -- produced by dkjson.encode(). Indent only if logging is switched on.
        local rc, json_data = pcall(dkjson.encode, data, {indent=show_log})
        if not rc then
                log("[insert_event] dkjson.encode() failed:", json_data)
                return false
        end
        log("[insert_event]", json_data)

        -- Store event in thread-safe queue. See NOTE in init() function for
        -- more information.
        local rc, err = sessevent_add(json_data)
        if not rc then
                log("[insert_event] sessevent_add() failed:", err)
                return false
        end
        return true
end

--
-- Create single-session report from latest events.
--
local function latest_report()
        local report = {
                session_number = get_session_value("session_number"),
                session_start  = get_session_value("start_time"),
                machine_id     = get_session_value("machine_id"),
                instance_id    = get_session_value("instance_id"),
                email_id       = get_session_value("email_id"),
                tz = tzoffset()
        }

        -- Session values may not have been set if there was an error.
        if not report.session_number then
                log("Missing session identifier(s).")
                return nil
        end

        -- Note that sessevent_burn_all() simultaneously fetches and deletes
        -- event data stored in thread-safe queue. See NOTE in init() function
        -- for more information.
        local events = {}
        local insert = table.insert
        for ev_number, ev_data in pairs(sessevent_burn_all()) do
                -- Decode event JSON data and add to sendable event list.
                local decoded, errpos, errmsg = dkjson.decode(ev_data)
                if decoded then
                        -- Record event number and store decoded JSON.
                        decoded._n = ev_number
                        insert(events, decoded)
                else
                        -- Log decode error and add it as a new event.
                        log("Event decode error:", errmsg)
                        decoded = {
                                _name = "decode-error",
                                _time = os.date("%Y-%m-%d %H:%M:%S"),
                                _n = ev_number,
                                event_json = ev_data,
                                error = errmsg
                        }
                        insert(events, decoded)
                end
        end
        report.events = events

        return report
end

--
-- Send report to server. Optional timeout parameter determines an upper limit
-- (in seconds) to how long the HTTP request may block.
--
-- If transmission of data fails for whatever reason, the function retuns false.
-- Otherwise it returns true.
--
local function send_report(r, timeout)
        -- Encode complete report data as JSON and compress using ZLIB.
        local js = dkjson.encode(r)
        local js, eof, bytes_in, bytes_out = zlib.deflate()(js, "finish")

        -- Source function for HTTP request body.
        local function body_source()
                local done = false
                return function()
                        if not done then
                                done = true
                                return js
                        end
                        return nil
                end
        end

        -- Sink function for received HTTP response from server.
        local function response_sink()
                local response = ""
                return function(chunk, err)
                        if chunk then
                                response = response..chunk
                                return 1
                        end
                        if #strip(response) > 0 then
                                log("Response:", response)
                        end
                        return nil
                end
        end

        -- Send report to server.
        local response, code = http.request{
            url = server_url,
            method = "POST",
            headers = {
                ["Content-Type"] = "application/octet-stream",
                ["Content-Length"] = bytes_out
            },
            source = body_source(),
            sink = response_sink(),
            create = function()
                local sock = socket.tcp()
                if timeout then
                        sock:settimeout(timeout, "t")
                end
                return sock
            end
        }
        if code ~= 200 then
                log("Event network failure:", code)
                return false
        end
        return true
end

--
-- Initialize logging/reporting facilities.
--
local function init()
        -- Get session number and instance ID.
        local snum
        local instance_id
        db.session(function(con)
                -- Recreate tables if necessary.
                setup_db(con)

                -- Read and increment session number. Get instance ID.
                snum = tonumber(get_client_value(con, "session_number")) + 1
                set_client_value(con, "session_number", snum)
                instance_id = get_client_value(con, "instance_id")
        end)

        -- Store session values in shared (thread-safe) application memory.
        --
        -- NOTE: "Shared memory" in this context refers to memory managed by
        --       lua_engine.dll that is safe to access from multiple threads.
        --       One of these threads is the "reporter background" thread that
        --       does the actual sending (report.background function), and the
        --       others report events by calling report.event() occasionaly.
        --
        --       Functions set/get_session_value() and sessevent_*() are used
        --       to manipulate this shared state (see lua_engine.cpp for
        --       details).
        assert(set_session_value("session_number", snum))
        assert(set_session_value("instance_id", instance_id))
        assert(set_session_value("machine_id", machine_id()))
        assert(set_session_value("start_time", os.date("%Y-%m-%d %H:%M:%S")))

        -- Open "user.info" file to get email ID (generated during application
        -- download).
        local user_file = tda.GetRuntimePath().."\\user.info"
        local f, err = io.open(user_file, "r")
        local user_email_id = false
        if f then
                local file_content = f:read("*a")
                if file_content then
                        user_email_id = strip(file_content)
                        set_session_value("email_id", user_email_id)
                end
                f:close()
        end

        -- Log `application-open` event.
        event("application-open", { email_id = user_email_id })
end

--
-- Send latest report. If that fails, save the report for later transmission.
--
local function send_or_save_latest(timeout)
        local r = latest_report()
        if r and not send_report(r, timeout) then
                save_report(r)
        end
end

--
-- Start reporting. The function never returns (unless there are errors) so it
-- must be called in a separate thread.
--
local function background()
        -- Try sending previously unsent reports together with current session.
        local r = latest_report()
        local complete_r = unsent_reports(r)
        if complete_r then
                if send_report(complete_r) then
                        delete_unsent()
                elseif r then
                        save_report(r)
                end
        end

        -- Wake up every `idle_time` seconds to check if enough events have
        -- been accumulated or enough time has passed to send a new report. Do
        -- nothing if no new events have been logged.
        local last_report_time = os.time()
        while true do
                sleep(idle_time)

                local unsent = sessevent_count()
                if unsent ~= 0 then
                        -- Send report if number of unsent events for session
                        -- reaches `unsent_threshold`. Also send report if time
                        -- since last report is more than `report_interval`.
                        local now = os.time()
                        if (unsent >= unsent_threshold) or
                           (os.difftime(now, last_report_time) >= report_interval) then
                                send_or_save_latest()
                                last_report_time = now
                        end
                end
        end
end

--
-- Stop reporting.
--
local function stop()
        -- Log `application-close` event and send final session report.
        --
        -- NOTE: For now there is no way to keep the application process alive
        --       after its window has been destroyed. This function is called
        --       from the main thread and will keep the application window open
        --       for as long as the below send_report() call blocks. To not keep
        --       a non-responding application window visible for more than just
        --       a short moment, we give send_report() a one-second timeout. If
        --       it fails to send its report to server during that interval,
        --       then so be it.
        event("application-close")
        send_or_save_latest(1.5)
end

return {
        init = init,
        background = background,
        stop = stop,
        event = event
}
