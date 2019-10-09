module(..., package.seeall)

local report = require("reporter.report")

function startup()
	-- Launch user activity reporter thread.
	report.init()
	execute_in_new_thread("reporter.report.background")
end

function close()
	-- Stop reporting user activity.
	report.stop()
end

function exception(message)
	log("TDA exception:\n", message)
	
	report.event("application-exception", {message = message})

	show_msg("TDA exception:\n" .. message)
end
