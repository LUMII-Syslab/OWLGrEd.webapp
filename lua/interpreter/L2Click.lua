module(..., package.seeall)
require("utilities")

function L2Click(ev_in)
	--print("L2Click")
	--local ev = lQuery("L2ClickEvent"):log
	local ev = utilities.get_event(ev_in, "Event")
	utilities.call_element_proc_thru_type(ev:find("/element"), "l2ClickEvent")
	ev:delete()
end
