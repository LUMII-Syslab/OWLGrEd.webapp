module(..., package.seeall)
require("utilities")
require("core")
Delete = require("interpreter.Delete")

function MoveLineStartPoint(ev_in)
	move_line(ev_in, "MoveLineStartPointEvent", "start", "end")
end

function MoveLineEndPoint(ev_in)
	move_line(ev_in, "MoveLineEndPointEvent", "end", "start")
end

function move_line(ev_in, event_name, role, opposite_role)
	local ev = utilities.get_event(ev_in, event_name)	
	local edge = ev:find("/edge")
	local diagram = utilities.current_diagram()
	local opposite_elem = edge:find("/" .. opposite_role)
	local old_elem = edge:find("/" .. role)
	local new_elem = ev:find("/target")
	local edge_type = edge:find("/elemType")
	ev:delete()
	local new_edge_type = core.find_edge_type(edge_type:find("/paletteElementType/elemType"), opposite_elem, "/" .. opposite_role, new_elem, "/" .. role)
	if new_edge_type ~= nil and new_edge_type:is_not_empty() then
		if new_edge_type:attr_e("id") == edge_type:attr_e("id") then
			if edge_type:id() ~= new_edge_type:id() then
				edge:remove_link("elemType", edge_type)
				edge:link("elemType", new_edge_type)
			end
			edge:remove_link(role, old_elem)
			edge:link(role, new_elem)
			utilities.call_elemType_proc_with_supertypes(new_edge_type, "procMoveLine", edge, new_elem, old_elem)
		else
			Delete.delete_elements(edge)
			edge = core.add_edge_by_roles(new_edge_type, opposite_elem, opposite_role, new_elem, role, diagram)
		end
		utilities.enqued_cmd("OkCmd", {element = edge, graphDiagram = edge:find("/graphDiagram")})
	else
		utilities.ShowInformationBarCommand("Elements cannot be connected!")
		return -1
	end
end