module(..., package.seeall)
require("utilities")

local report = require("reporter.report")

function PopUpElemSelect(ec_in)
	local ev = utilities.get_event(ev_in, "PopUpElemSelectEvent")
	local pop_up_elem = ev:find("/popUpElement")

	-- Log "pop-up element select" event.
	report.event("PopUpElemSelect", {
		caption = function() return pop_up_elem:attr("caption") end,
	})

	local proc_name = pop_up_elem:attr_e("procedureName")
	--local pop_up_diagram = pop_up_elem:find("/popUpDiagram")
	--pop_up_diagram:delete()
	lQuery("PopUpDiagram"):delete()
	utilities.execute_translet(proc_name)
	ev:delete()
end
