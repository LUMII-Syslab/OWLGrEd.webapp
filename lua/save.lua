module(..., package.seeall)
require("utilities")
report = require("reporter.report")
require("project_open_trace")


function OnSave()
	report.event("Save Executed", {
		project_name = function() return lQuery("Project/graphDiagram"):attr("caption") end,
		tool_name = function() return lQuery("ToolType"):attr("caption") end,
		build_date = function() return lQuery("Project"):attr("build_date") end,
		build_number = function() return lQuery("Project"):attr("build_number")	end,
	})
	local tmp_version_file = utilities.open_tmp_version_file("a")
	local session_file = utilities.open_session_file("r")
	if session_file ~= nil then
		local session = session_file:read("*a")
		tmp_version_file:write(session)
		tmp_version_file:close()
		utilities.clear_session_file()
	end
	-- project open trace
	-- record project save time in the last project open trace instance
	project_open_trace.record_save_in_project_open_trace()
end
