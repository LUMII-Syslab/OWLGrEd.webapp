module(..., package.seeall)
require "socket"


function sleep(sec)
    socket.select(nil, nil, sec)
end

function t()
		sleep(1)
		local tab_container = lQuery("D#Form:last/component.D#TabContainer")
		local active_tab = tab_container:find("/component")
		local new_active_tab = tab_container:find("/component"):log():remove(active_tab:id()):log():find(":rand"):log()
		
		tab_container:remove_link("activeTab", active_tab)
		tab_container:link("activeTab", new_active_tab)
		tab_container:find("/activeTab"):log()
		
		
		local command = utilities.create_command("D#Command", {info = "Refresh"})
		tab_container:link("command", command)
		
		tda.CallFunctionInMainThread("tda.ExecuteCommand", command:id())
		
--		utilities.refresh_form_component(tab_container)
end