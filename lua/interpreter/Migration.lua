module(..., package.seeall)
report = require("reporter.report")
configurator = require("configurator.configurator")
delete = require("interpreter.Delete")

function process_version_list(List)
	proces_obj_types(List)
end

function proces_obj_types(List, child_indexes_in, old_parent_type, new_parent_type)
	for obj_type_id, obj_table in pairs(List) do
		if obj_table["Status"] == "Updated" then
			local relink_function = relink_diagram_objects
			local child_index = "ElemTypes"
			local path_to_child = path_to_child --or "/graphDiagramType"
			if child_indexes_in == "ElemTypes" then
				child_index = "CompartTypes"	
				path_to_child = "/elemType"
				relink_function = relink_element_objects
			elseif child_indexes_in == "CompartTypes" then
				child_index = "SubCompartTypes"
				path_to_child = "/compartType"
				relink_function = relink_compartment_objects
			elseif child_indexes_in == "SubCompartTypes" then
				child_index = "SubCompartTypes"
				path_to_child = "/subCompartType"
				relink_function = relink_compartment_objects
			end
			local old_name = obj_table["OldName"]
			local old_type = get_child_type(old_parent_type, old_name, path_to_child, true)
			local new_type = get_child_type(new_parent_type, obj_type_id, path_to_child, false)	
			relink_function(new_type, old_type)
			proces_obj_types(obj_table[child_index], child_index, old_type, new_type)
		else	
			print("Diagram Status is New")
		end
	end
end

--Find new and old typs in repository
function get_child_type(parent_type, id, path_to_child, is_old_type)
	if parent_type ~= nil then
		return parent_type:find(string.format("%s[id = %s]", path_to_child, id))
	else
		if is_old_type then
			return lQuery("GraphDiagramType[id = '" .. id .. "']:has(/toolType/tag[key = '__old'])")
		else
			return lQuery("GraphDiagramType[id = '" .. id .. "']:not(:has(/toolType/tag[key = '__old']))")
		end
	end
end

--Relink functions
function relink_diagram_objects(new_diagram_type, old_diagram_type)
	relink_presentation_objects(new_diagram_type, old_diagram_type, "graphDiagram", "graphDiagramStyle")
	local diagrams = new_diagram_type:find("/graphDiagram")
	diagrams:each(function(diagram)
		--add_palette
		utilities.add_palette_to_diagram(diagram, new_diagram_type)
	end)
end

function relink_element_objects(new_elem_type, old_elem_type)
	relink_presentation_objects(new_elem_type, old_elem_type, "element", "elemStyle")
end

function relink_compartment_objects(new_compart_type, old_compart_type)
	relink_presentation_objects(new_compart_type, old_compart_type, "compartment", "compartStyle")
end

--Function relinks presenation element to its new type
function relink_presentation_objects(new_type, old_type, role, role_to_style)
	local path = "/" .. role
	local presentation_objects = old_type:find(path)
	if new_type:is_not_empty() then
		old_type:remove_link(role, presentation_objects)
		new_type:link(role, presentation_objects)
	end
	local new_default_style = new_type:find(string.format(	"/%s:first()", role_to_style))
	old_type:find("/" .. role_to_style):each(function(style)
		local tmp_presentation_objects = style:find(path)
		style:remove_link(role, tmp_presentation_objects)
		local new_style = new_type:find(string.format('/%s[id = %s]', role_to_style,  style:attr("id")))
		if new_style:is_empty() then
			new_style = new_default_style
		end
		new_style:link(role, tmp_presentation_objects)
	end)
end

function add_tag()
	utilities.add_tag(lQuery("ToolType"), "__old", "true", true)
end

function delete_configurator_types()
	local tool_type = get_old_tool_type()
	local list_of_target_types = {}
	local list_of_diagrams = {}
	tool_type:find("/graphDiagramType"):each(function(graph_diagram_type)
		if graph_diagram_type:attr("id") == "specificationDgr" or graph_diagram_type:attr("id") == "MMInstances" or graph_diagram_type:attr("id") == "Repository" or graph_diagram_type:attr("id") == "Instances" then
			graph_diagram_type:find("/graphDiagram"):each(function(diagram)
				table.insert(list_of_target_types, diagram:find("/target_type"))
				table.insert(list_of_diagrams, diagram)
			end)
		end
	end)
	delete_configurator_diagrams(list_of_diagrams)
	configurator.remove_diagram_type_with_elem_types(lQuery("GraphDiagramType[id = 'specificationDgr']"))
	return list_of_target_types
end

function delete_configurator_diagrams(dgr_to_be_deleted)
	for _, dgr in ipairs(dgr_to_be_deleted) do
		--if dgr:is_not_empty() then
			--utilities.execute_cmd("CloseDgrCmd", {graphDiagram = dgr})
		--end
		utilities.delete_toolbar(dgr)
		utilities.delete_pop_up(dgr)
		delete.delete_elements_from_diagram(dgr)
		delete.delete_tree_node(dgr)
		delete.delete_diagram_obj(dgr)
	end
end

function delete_target_types(list_of_diagram_types)
	for _, target_type in ipairs(list_of_diagram_types) do
		configurator.remove_diagram_type_with_elem_types(target_type)
	end
	local tool_type = get_old_tool_type()
	tool_type:find("/tag"):delete()
	tool_type:delete()
end

function get_old_tool_type()
	return lQuery("ToolType:has(/tag[key = '__old'])")
end


