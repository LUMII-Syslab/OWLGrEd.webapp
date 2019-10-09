module(..., package.seeall)

cu = require("configurator.configurator_utilities")
d = require("dialog_utilities")
delete = require("interpreter.Delete")
conf_dialog = require("configurator.dialog")

function delete_treeNode_compartType(selected_node)
	selected_node:find("/childNode"):each(function(child_node)
		delete_treeNode_compartType(child_node)	
	end)
	local obj_type = selected_node:find("/type")	
	local parent_type = obj_type:find("/parentCompartType[id ^= 'ASFictitious']")
	delete_compart_type_with_additions(obj_type)	
	conf_dialog.manage_property(obj_type:find("/propertyRow"))
	obj_type:delete()
	if parent_type:is_not_empty() then
		delete_compart_type_with_additions(parent_type)
		conf_dialog.manage_property(parent_type:find("/propertyRow"))
		parent_type:delete()
	end
end

function delete_compart_type_with_additions(compart_type)
	compart_type:find("/compartment"):delete()
	compart_type:find("/compartStyle"):delete()
	delete_choice_items(compart_type)
end

function delete_tree_node_from_button()	
	cu.log_button_press({Button = "Delete", Context = "CompartType"})
	local tree = d.get_component_by_id("Tree")
	local selected_node = d.get_selected_tree_node()
	delete_treeNode_compartType(selected_node)
	d.execute_command("D#DeleteTreeNodeCmd", tree, "DeleteTreeNode", {treeNode = selected_node})
end

function delete_palette_elem_type(palette_elem_type)
	palette_elem_type:find("/presentationElement"):delete()
	palette_elem_type:delete()
end

function delete_palette_element_type(palette_element_type)
	local palette_type = palette_element_type:find("/paletteType")
	local palette_size = palette_type:find("/paletteElementType"):size()
	if palette_size == 1 then
		palette_type:delete()
	end
	local palette_name, palette_nr, palette_image = cu.get_palette_components()
	utilities.refresh_form_component(palette_name)
	utilities.refresh_form_component(palette_nr)
	utilities.refresh_form_component(palette_image)
	palette_element_type:find("/presentationElement"):each(function(palette_element)
		delete_palette_element(palette_element)
	end)
	palette_element_type:delete()
end

function delete_palette_element(palette_element)
	local palette = palette_element:find("/palette")
	local diagram = palette:find("/graphDiagram")
	local palette_size = palette:find("/paletteElement"):size()
	if palette_size == 1 then
		palette:delete()
	end
	palette_element:delete()
end

function delete_style()
	utilities.active_elements():find("/elemStyle"):delete()
end

function delete_elem_type_from_configurator(element)
	local elem_type = element:find("/target_type")
	delete_elem_type(elem_type)
end

function delete_elem_type(elem_type)
	elem_type:find("/compartType"):each(function(compart_type)
		compart_type:find("/compartment"):delete()
		compart_type:find("/compartStyle"):delete()
		delete_sub_compart_types(compart_type)
		delete_choice_items(compart_type)
		compart_type:delete()
	end)
	
	elem_type:find("/elemStyle"):delete()
	elem_type:find("/keyboardShortcut"):delete()
	delete_palette_from_elem_type(elem_type)
	delete_propety_diagram(elem_type:find("/propertyDiagram"))

	local pop_up_diagram = elem_type:find("/popUpDiagram")
	pop_up_diagram:find("/popUpElement"):delete()
	pop_up_diagram:delete()

	local elements = elem_type:find("/element")
	local diagrams = elements:find("/graphDiagram")
	delete_target_diagrams(elements:find("/target"))
	delete_target_diagrams(elements:find("/child"))
	
	elements:delete()
	diagrams:each(function(dgr)
		utilities.execute_cmd("OkCmd", {graphDiagram = dgr})
	end)

	local element = elem_type:find("/presentation")
	local target_diagram = element:find("/child")
	if target_diagram:is_empty() then
		target_diagram = element:find("/target")
	end
	delete_configurator_target_diagrams(target_diagram)
	elem_type:delete()
end

function delete_configurator_target_diagrams(target_diagram)
	target_diagram:find("/element"):each(function(element)
		delete_elem_type_from_configurator(element)
	end)
	utilities.close_diagram(target_diagram)
	delete_diagram_type(target_diagram:find("/target_type"))
	target_diagram:delete()
end

function delete_diagram_type(diagram_type)
	diagram_type:find("/paletteType"):delete()
	diagram_type:find("/rClickEmpty"):delete()
	diagram_type:find("/rClickCollection"):delete()
	diagram_type:find("/eKeyboardShortcut"):delete()
	diagram_type:find("/cKeyboardShortcut"):delete()
	diagram_type:find("/toolbarType"):delete()
	diagram_type:find("/graphDiagram"):delete()
	diagram_type:delete()
end

function delete_target_diagrams(target_diagrams)
	delete_configurator_diagrams(target_diagrams)
end

function delete_configurator_diagrams(diagrams)
	diagrams:find("/element"):each(function(elem)
		delete_elem_type_from_configurator(elem)
	end)
	local list = {}
	--utilities.close_diagram(diagrams)
	diagrams:each(function(diagram)
		--utilities.close_diagram(diagram)
		table.insert(list, diagram)
	end)
	delete.delete_diagrams_from_table(list)
end

function delete_choice_items(compart_type)
	compart_type:find("/choiceItem"):each(function(choice_item)
		choice_item:find("/notation"):delete()
		choice_item:delete()
	end)
end

function delete_propety_diagram(prop_diagrams)
	prop_diagrams:each(function(prop_dgr)
		local tabs = prop_dgr:find("/propertyTab")
		delete_prop_rows(tabs)
		delete_prop_rows(prop_dgr)
	end)
end

function delete_prop_rows(source)
	local rows = source:find("/propertyRow")
	local called_dgrs = rows:find("/calledDiagram")
	if called_dgrs:size() > 0 then
		delete_propety_diagram(called_dgrs)
	end
	rows:delete()
	source:delete()
end

function delete_palette_from_elem_type(elem_type)
	elem_type:find("/paletteElementType"):each(function(palette_elem_type)
		if palette_elem_type:find("/elemType"):size() < 2 then
			local palette_type = palette_elem_type:find("/paletteType")
			palette_elem_type:find("/presentationElement"):delete()
			palette_elem_type:delete()
			if palette_type:find("/paletteElementType"):is_empty() then
				palette_type:find("/presentationElement"):delete()
				palette_type:delete()
			end
			local dgr = elem_type:find("/graphDiagramType/graphDiagram")
			utilities.execute_cmd("AfterConfigCmd", {graphDiagram = dgr})
		end
	end)
end

function delete_sub_compart_types(compart_type)
	compart_type:find("/subCompartType"):each(function(sub_compart_type)
		delete_choice_items(sub_compart_type)
		delete_sub_compart_types(sub_compart_type)
		sub_compart_type:delete()
	end)
end

function delete_specialization(elem)
	local start_type = elem:find("/start/target_type")
	local end_type = elem:find("/end/target_type")
	start_type:remove_link("supertype", end_type)
end



