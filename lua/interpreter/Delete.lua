module(..., package.seeall)
require("utilities")
t = require("interpreter.tree")
require("config_properties")
d = require("dialog_utilities")

function Delete()
	if is_delete_confirm_msg_needed() then
		show_delete_confirm_msg()
	else
		confirmed_delete()
	end
end

function show_delete_confirm_msg()
	local form = d.add_form({id = "delete_msg", caption = "Delete"})
	d.add_component(form, {id = "label", caption = "Are you sure you want to delete?"}, "D#Label")
	local box = d.add_component(form, {id = "box", horizontalAlignment = 1, }, "D#HorizontalBox")
	d.add_button(box, {caption = "Yes"}, {Click = "lua.interpreter.Delete.delete_msg_form_OK"})
	d.add_button(box, {caption = "No"}, {Click ="lua.interpreter.Delete.close_delete_msg_form"})	
	d.show_form(form)
end

function delete_msg_form_OK()
	close_delete_msg_form()
	confirmed_delete()
end

function close_delete_msg_form()
	d.close_form("delete_msg")
end

function is_delete_confirm_msg_needed()
	if config_properties.get_config_value("is_delete_confirm_msg_needed") == "" then
		return false
	end
	return config_properties.get_config_value("is_delete_confirm_msg_needed") or false
end

function confirmed_delete()
	local diagram = utilities.current_diagram()
	delete_diagram(diagram:find("/collection"))
end

function delete_diagram(collection)
	--if diagram:attr_e("isReadOnly") ~= "true" then
	if collection == nil then
		collection = utilities.current_diagram()
	end
	local elements = collection:find("/element")
	delete_elements(elements)
	--end
end

function delete_elements(elements)
	diagram = elements:find("/graphDiagram")
	local list = {}
	elements:each(function(elem)
		delete_element(elem, list)
	end)
	--delete_elements_with_compartments(elements)
	delete_objects_from_list(list)
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end

function delete_element(elem, list)
	local elem_type = elem:find("/elemType")
	local proc_names = utilities.get_translets(elem_type, "procDeleteElement")
	if #proc_names > 0 then
		utilities.execute_translet(proc_names, elem)
	else
		default_delete_element(elem, list)
	end
end

function default_delete_element(elem, list)
	local elem_type = elem:find("/elemType")
	delete_connected_edges(elem, list)
	if elem:filter(".Node"):is_not_empty() then
		delete_connected_ports(elem, list)
		delete_connected_child_nodes(elem, list)
	end
	--delete_compartments(elem, "/compartment", list)
	--delete_objects_from_list(list)
	delete_compartment_tree(elem)
	utilities.call_element_proc_thru_type(elem, "procDeleteElementDomain")
	table.insert(list, elem)
	--elem:delete()
end

function delete_connected_child_nodes(node, list)
	node:find("/component"):each(function(child_node)
		default_delete_element(child_node, list)
	end)
end

function delete_connected_ports(elem, list)
	elem:find("/port"):each(function(port)
		default_delete_element(port, list)
	end)
end

function delete_connected_edges(elem, list)
	delete_edge_by_path(elem, "/eStart", list)
	delete_edge_by_path(elem, "/eEnd", list)
end

function delete_edge_by_path(elem, path, list)
	elem:find(path):each(function(edge)
		default_delete_element(edge, list)
	end)
end

function delete_compartments(elem, path_to_compart, list)
	local list = {}
	elem:find(path_to_compart):each(function(compart)	
		delete_compartments(compart, "/subCompartment", list)
		table.insert(list, compart)
	end)	
end

function delete_objects_from_list(list)
	for _, obj in ipairs(list) do
		utilities.call_compartment_proc_thru_type(obj, "procDeleteCompartmentDomain")
		obj:delete()
	end
end

function delete_seed(element)
	local diagram = element:find("/graphDiagram")
	delete_seed_with_collection(element, element:find("/graphDiagram/collection"))
end

function delete_current_diagram()
	local diagram = utilities.current_diagram()
	utilities.close_diagram_cmd(diagram)
	local list = {}
	table.insert(list, diagram)
	delete_diagrams_from_table(list)
	utilities.execute_cmd("OkCmd", {graphDiagram = lQuery("GraphDiagram:first()")})
end

function delete_seed_with_collection(element, collection)
	local diagram = element:find("/graphDiagram")
	local dgr_to_be_deleted = {}
	close_diagrams(collection:find("/element"), dgr_to_be_deleted)
	delete_diagrams_from_table(dgr_to_be_deleted)
	--delete_elements(element)
	local list = {}
	default_delete_element(element, list)
	delete_objects_from_list(list)
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end

function delete_diagrams_from_table(dgr_to_be_deleted, components_to_be_deleted_in)
	local components_to_be_deleted = {}
	if components_to_be_deleted_in == nil then
		components_to_be_deleted['palette'] = false
		components_to_be_deleted['toolbar'] = false
		components_to_be_deleted['popUp'] = false		
	else
		for index, component in pairs(components_to_be_deleted_in) do
			components_to_be_deleted[index] = component
		end
	end
	for _, dgr in pairs(dgr_to_be_deleted) do
		utilities.close_diagram(dgr)
		--utilities.execute_cmd("CloseDgrCmd", {graphDiagram = dgr})
		local translet_name = dgr:find("/graphDiagramType/translet[extensionPoint = 'procDeleteDiagram']"):attr("procedureName")
		utilities.execute_translet(translet_name, dgr)
		if not(components_to_be_deleted['toolbar']) then
			utilities.delete_toolbar(dgr)
		end
		if not(components_to_be_deleted['popUp']) then			
			utilities.delete_pop_up(dgr)
		end
		if not(components_to_be_deleted['palette']) then		
			utilities.delete_palette(dgr)
		end
		delete_elements_from_diagram(dgr)
		delete_tree_node(dgr)
		delete_diagram_obj(dgr)
	end
	local tree_node = utilities.get_tree_node_from_thing(utilities.current_diagram())
	if tree_node ~= nil then
		t.refresh(tree_node)	
	end
end

function delete_tree_node(dgr)
	local tree_node = utilities.get_tree_node_from_thing(dgr)
	tree_node:delete()
end

function delete_diagram_obj(dgr)
	dgr:delete()
end

function close_diagrams(collection_elems, traversed_dgrs)
	collection_elems:each(function(elem)
		local target_dgr = elem:find("/child")
		if target_dgr:is_not_empty()then
			local target_dgr_id = target_dgr:id()
			if traversed_dgrs[target_dgr_id] == nil then
				traversed_dgrs[target_dgr_id] = target_dgr
				utilities.close_diagram_cmd(target_dgr)
				close_diagrams(target_dgr:find("/element"), traversed_dgrs)
			end
		end
	end)
	--collection_elems:delete()
end

function delete_elements_from_diagram(dgr)
	local elems = dgr:find("/element")
	delete_elements_with_compartments(elems)
end

function delete_elements_with_compartments(elems)
	local list = {}
	elems:each(function(elem)
		delete_compartment_tree(elem)
		table.insert(list, elem)
	end)
	delete_objects_from_list(list)
end

function delete_compartment_tree(base)
	delete_compartment_tree_from_object(base, "/compartment")
end

function delete_compartment_tree_from_object(base, role)
	local list = {}
	delete_compartments_from_base(base, role, list)
	delete_objects_from_list(list)	
end

function delete_compartments_from_base(base, role, list)
	base:find(role):each(function(compart)
		table.insert(list, compart)	
		delete_compartments_from_base(compart, "/subCompartment", list)
	end)
end
