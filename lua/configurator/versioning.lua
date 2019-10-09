module(..., package.seeall)

cu = require("configurator.configurator_utilities")
d = require("dialog_utilities")

-- Versioning

function elem_type_versioning(elem_type)
	obj_type_versioning(elem_type, "CompartTypes")
end

function diagram_type_versioning(diagram_type)
	obj_type_versioning(diagram_type, "ElemTypes")
end

function compart_type_versioning(compart_type)
	if compart_type:find("/elemType"):is_not_empty() then
		obj_type_versioning(compart_type, "CompartTypes")
	else
		obj_type_versioning(compart_type, "SubCompartTypes")
	end
end

function obj_type_versioning(obj_type, child_types)
	local obj_type_id = obj_type:attr("id")
	local definition, new_name = address_list_from_obj_type(obj_type, obj_type_id)
	local str = string.format("%s%s = {%s = {}, Status = 'New'}\n", definition, new_name, child_types)
	utilities.append_to_session_file(str)
end

function address_list_from_obj_type(obj_type, id)
	local res = ""
	local list = {}
	list_of_all_steps(list, obj_type, id)
	return table.concat(list), list[#list - 1]
end

function list_of_all_steps(list, obj_type, id)
	if obj_type:filter(".GraphDiagramType"):is_not_empty() then
		local step = make_one_step(obj_type, id)
		table.insert(list, "List = List or {}\n")
		table.insert(list, string.format("List%s", step))
		table.insert(list, string.format(' = List%s or {}\n', step))
	elseif obj_type:filter(".ElemType"):is_not_empty() then
		list_of_all_steps(list, obj_type:find("/graphDiagramType"))
		local index = list[#list - 1]
		local step = make_one_step(obj_type, id)
		table.insert(list, string.format("%s['ElemTypes'] = %s['ElemTypes'] or {}\n", index, index))
		table.insert(list, string.format("%s['ElemTypes']%s", index, step))	
		table.insert(list, string.format(" = %s['ElemTypes']%s or {}\n", index, step))
	elseif obj_type:filter(".CompartType"):is_not_empty() then
		local parent_type = obj_type:find("/elemType")
		local child_type = "CompartTypes"
		if parent_type:is_empty() then
			parent_type = obj_type:find("/parentCompartType")
			child_type = "SubCompartTypes"
		end
		list_of_all_steps(list, parent_type)
		local index = list[#list - 1]
		local step = make_one_step(obj_type, id)
		table.insert(list, string.format("%s['%s'] = %s['%s'] or {}\n", index, child_type, index, child_type))
		table.insert(list, string.format("%s['%s']%s", index, child_type, step))	
		table.insert(list, string.format(" = %s['%s']%s or {}\n", index, child_type, step, index, child_type, step))
	end
end

function make_one_step(obj_type, id)
	if id == nil then	
		id = obj_type:attr("id")
	end
	return string.format("['%s']", id)
end

function update_elem_type_ID()
	local elem_type = cu.get_selected_obj_type()
	local elem_type_id = elem_type:attr("id")
	local _, new_elem_type_id = cu.get_event_source_attrs("text")
	if elem_type_id ~= new_elem_type_id then
		local diagram_type = elem_type:find("/graphDiagramType")
		local diagram_type_id = diagram_type:attr("id")
		local _, old_name = address_list_from_obj_type(elem_type, elem_type_id)
		local new_definition, new_name = address_list_from_obj_type(elem_type, new_elem_type_id)
		local str = string.format("%s%s = %s\n%s = nil\n",  new_definition, new_name, old_name, old_name)
		utilities.append_to_session_file(str)
	end
end

function update_diagram_type_ID(diagram_type)
	local diagram_type_id = diagram_type:attr("id")
	local _, new_elem_type_id = cu.get_event_source_attrs("text")
	if diagram_type_id ~= new_elem_type_id then
		local _, old_name = address_list_from_obj_type(diagram_type, diagram_type_id)
		local new_definition, new_name = address_list_from_obj_type(diagram_type, new_elem_type_id)
		local str = string.format("%s%s = %s\n%s = nil\n", new_definition, new_name, old_name, old_name)
		utilities.append_to_session_file(str)
	end
end

function update_compart_type_ID()
	local compart_type = cu.get_selected_obj_type()
	local compart_type_id = compart_type:attr("id")
	local _, new_compart_type_id = cu.get_event_source_attrs("text")
	if new_elem_type_id ~= new_compart_type_id then
		local _, old_name = address_list_from_obj_type(compart_type, compart_type_id)
		local new_definition, new_name = address_list_from_obj_type(compart_type, new_compart_type_id)
		local str = string.format("%s%s = %s\n%s = nil\n", new_definition, new_name, old_name, old_name)
		utilities.append_to_session_file(str)
	end
end

function make_path_from_compart_type_to_elem_type(compart_type, str)
	local parent_type = compart_type:find("/elemType")
	local compart_type_id = compart_type:attr("id")
	if parent_type:is_not_empty() then
		return ':find("/compartType[id = ' .. compart_type_id  .. ']"' .. str .. ")\n\t"
	else
		local tmp_str = '/subCompartType[id = ' .. compart_type_id .. ']' .. str
		return make_path_from_compart_type_to_elem_type(compart_type:find("/parentCompartType"), tmp_str)
	end
end

function make_path_from_diagram_type(diagram_type)
	return 'lQuery("GraphDiagramType[id = ' .. diagram_type:attr("id") .. ']"):filter(":not([isNew = true])"):log("id")\n\t'
end

function make_path_from_elem_type(elem_type)
	return ':find("/elemType[id = ' .. elem_type:attr("id") .. ']"):log("id")\n\t'
end

function make_path_from_compart_type(compart_type)
	if compart_type:find("/elemType"):is_not_empty() then
		return ':find("/compartType[id = ' .. compart_type:attr("id") .. ']"):log("id")\n\t'
	else
		return ':find("/subCompartType[id = ' .. compart_type:attr("id") .. ']"):log("id")\n\t'
	end
end

function set_new_attr_value()
	local attr, value = cu.get_event_source_attrs("text")
	return ':attr({id = "' .. value .. '"}):log("id")\n'
end