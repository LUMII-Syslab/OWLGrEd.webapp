module(..., package.seeall)
require("utilities")

local report = require("reporter.report")

function ToolbarElementSelect(ev_in)
	local ev = utilities.get_event(ev_in, "ToolbarElementSelectEvent")	
	local toolbar_element = ev:find("/toolbarElement")

	-- Log "toolbar element select" event.
	report.event("ToolbarElementSelect", {
		caption = function() return toolbar_element:attr("caption") end,
		diagram = function() return utilities.current_diagram():attr("caption") end,
		diagram_type = function() return utilities.current_diagram():attr("/graphDiagramType@id") end,
	})

	utilities.execute_translet(toolbar_element:attr_e("procedureName"))

	ev:delete()
end