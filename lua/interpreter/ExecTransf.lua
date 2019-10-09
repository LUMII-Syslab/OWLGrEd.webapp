module(..., package.seeall)
require("utilities")

function ExecTransf(ev_in)
	log("start exec transf")
	local ev = utilities.get_event(ev_in, "ExecTransfEvent")
	local proc_name = ev:attr_e("info")
	if proc_name ~= "" then
		utilities.execute_translet(proc_name)
	end
	ev:delete()
	log("end exec taransf")
end
