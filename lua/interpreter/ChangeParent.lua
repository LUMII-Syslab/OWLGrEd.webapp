module(..., package.seeall)
require("utilities")

function ChangeParent(ev_in)
	local ev = utilities.get_event(ev_in, "ChangeParentEvent")
	change_parent(ev:find("/node"), ev:find("/target"))
	ev:delete()
end

function change_parent(component, container)
	if component:filter(".Node"):size() > 0 and (container:filter(".Node"):size() > 0 or container:size() == 0) then
		local component_type = component:find("/elemType")
		local old_container = component:find("/container")
		local buls = 0
		local msg = ""
		if container:filter(".Node"):size() > 0 then
			local container_type = container:find("/elemType")
			container_type:find("/componentType"):each(function(comp_type)
				if comp_type:id() == component_type:id() then
					component:remove_link("container", old_container)
					component:link("container", container)
					buls = 1
				end
			end)
			msg = container_type:attr_e("caption") .. " cannot contain " .. component_type:attr_e("caption") .. "!"
		else
			if component_type:attr_e("isContainerMandatory") ~= "true" then
				component:remove_link("container")
				buls = 1
			else
				msg = component_type:attr_e("caption") .. " needs a container!"
			end
		end
		if buls == 1 then
			local translet_name = utilities.get_translet_by_name(component_type, "procContainerChanged")
			utilities.execute_translet(translet_name, component, old_container, container)
			utilities.add_command_without_diagram(component, "OkCmd", {})
		else
			utilities.ShowInformationBarCommand(msg)
		end
	end	
end

	