module(..., package.seeall)
report = require("reporter.report")


-- ProjectOpenTrace
-- 	previous/next -> ProjectOpenTrace
-- 	machine_id = machine_id()
--  sessios_number = 1234, -- by SK: removed get_session_value("session_number")
--  project_name = lQuery("Project"):attr("name")
--  timezone_offset = tzoffset() -- +/-hhmm
--  open_time = os.date("%Y-%m-%d %H:%M:%S")
-- 	last_save_time = os.date("%Y-%m-%d %H:%M:%S")

-- get rid of user name part
local function plain_machine_id()
	return "some id" --removed string.match(machine_id() or "", "[^/]*")
end

function init_project_open_trace_metamodel()
	local mm = lQuery.model
	mm.add_class("ProjectOpenTrace")
		mm.add_property("ProjectOpenTrace", "machine_id")
		mm.add_property("ProjectOpenTrace", "session_number")
		mm.add_property("ProjectOpenTrace", "project_name")
		mm.add_property("ProjectOpenTrace", "timezone_offset")
		mm.add_property("ProjectOpenTrace", "open_time")
		mm.add_property("ProjectOpenTrace", "last_save_time")
	mm.add_link("ProjectOpenTrace", "previous", "next", "ProjectOpenTrace")
end

local function tzoffset()
	local now = os.time()
	local timezone = 0 -- removed os.difftime(now, os.time(os.date("!*t", now)))
	local h, m = math.modf(timezone / 3600)
	return string.format("%+.4d", 100 * h + 60 * m)
end

local function current_time_string()
	return os.date("%Y-%m-%d %H:%M:%S")
end

local function last_project_open_trace()
	return lQuery("ProjectOpenTrace:not(/next)")
end

-- create a project open trace instance
-- should be called every time a project is opened
function add_project_open_trace_instance()
	return lQuery.create("ProjectOpenTrace", {
		open_time = current_time_string(),
		machine_id = plain_machine_id(),
		sessios_number = 1234, -- by SK: removed get_session_value("session_number"),
		project_name = lQuery("Project"):attr("name"),
		timezone_offset = tzoffset(),
		previous = last_project_open_trace(),
	})
end

-- record project save in the last project open trace instance
-- should be called each time the project is saved
function record_save_in_project_open_trace()
	local last_trace = last_project_open_trace()
	
	if last_trace:is_empty() then
		last_trace = add_project_open_trace_instance()
	end

	last_trace:attr({
		last_save_time = current_time_string(),
		project_name = lQuery("Project"):attr("name"),
	})
end


local function project_open_history_newest_first()
	local first_project_open_trace_instance = last_project_open_trace()
	local history = {} -- latest first

	local project_open_trace = first_project_open_trace_instance
	while project_open_trace:is_not_empty() do
		local trace_instance_in_table_form = {
				 machine_id = project_open_trace:attr("machine_id"),
			 sessios_number = project_open_trace:attr("sessios_number"),
			   project_name = project_open_trace:attr("project_name"),
			timezone_offset = project_open_trace:attr("timezone_offset"),
				  open_time = project_open_trace:attr("open_time"),
			 last_save_time = project_open_trace:attr("last_save_time"),
		}
		table.insert(history, trace_instance_in_table_form)

		project_open_trace = project_open_trace:find("/previous")
	end

	return history
end

-- report project history to server
function report_project_open_history()
	report.event("ProjectOpenHistory", {
		history_newest_first = project_open_history_newest_first,
	})
end

--
-- usage
--
-- require("project_open_trace")
--
-- project_open_trace.init_project_open_trace_metamodel() -- on open
-- project_open_trace.add_project_open_trace_instance() -- create project open trace instance every time a project is opened
-- project_open_trace.record_save_in_project_open_trace() -- record project save in the last project open trace instance
-- project_open_trace.report_project_open_history() -- report to server
