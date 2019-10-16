--local socket = require("socket")
--local http = require("socket.http")
--local luasql = require("luasql.sqlite3")
--local dkjson = require("reporter.dkjson")
--local zlib = require("zlib")

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
        return true
end

--
-- Initialize logging/reporting facilities.
--
local function init()
end

local function background()
end

--
-- Stop reporting.
--
local function stop()
end

return {
        init = init,
        background = background,
        stop = stop,
        event = event
}
