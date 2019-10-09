module(..., package.seeall)

cu = require("configurator.configurator_utilities")
d = require("dialog_utilities")
copy_paste = require("interpreter.CutCopyPaste")
delta = require("configurator.delta")

function copy_target_diagram(diagram)
	return delta.copy_target_diagram_type(diagram)
end

function configurator_seed_copied(elem)
	return configurator_elem_copied(elem)
end

function configurator_elem_copied(elem)
	return copy_configurator_element(elem)
end

function copy_configurator_element(elem, is_unique)
	local list_of_code = {}
	if elem:find("/elemType[id = 'Specialization']"):is_empty() then
		table.insert(list_of_code, delta.process_target_elem_type(elem))
		return table.concat(list_of_code)
	else
		return copy_specialization(elem)
	end
end

function copy_specialization(elem)
	if elem:find("/start"):is_not_empty() and elem:find("/end"):is_not_empty() then
		local list_of_code = {}
		table.insert(list_of_code, delta.process_specialization_element(elem))	
		return table.concat(list_of_code)
	else
		return ""
	end
end

function copy_name_compartment(elem, is_unique_needed)
	local code = ""
	local elem_type = elem:find("/target_type")
	local elem_type_name = elem_type:attr("id")
	local elem_type_code = utilities.make_obj_to_var(elem_type)
	--if is_unique_needed then
		code = code .. 'id = cu.generate_unique_id(' .. elem_type_code .. ':attr("id"), ' .. elem_type_code .. ':find("/graphDiagramType"), "elemType")\n'
		local name_code = elem_type_code .. ':attr({id = id, caption = id})\n'
		code = code .. name_code
	--end
	local compart = elem:find("/compartment:has(/compartType[id = 'AS#Name'])")
	code = code .. utilities.make_obj_to_var(compart) .. ':attr({input = id, value = id})\n'
	local diagram = elem:find("/target")
	if diagram:is_not_empty() then
		code = code .. utilities.make_obj_to_var(diagram) .. ':attr({caption = id})\n'
	end
	local palette_elem_type = elem_type:find("/paletteElementType")
	if palette_elem_type:is_not_empty() then
		code = code .. utilities.make_obj_to_var(palette_elem_type) .. ':attr({id = id, caption = id})\n'
	end
	return code
end

function copy_element_compartments(original, copy)
	local elem_type = copy:find("/target_type")
	original:find("/compartment"):each(function(compart)
		local compart_type = compart:find("/target_type")
		if compart_type:is_not_empty() then
			local new_compart_type = lQuery.create("CompartType"):copy_attrs_from(compart_type)										
										:link("elemType", elem_type)
			local new_compart = lQuery.create("Compartment"):copy_attrs_from(compart)
									:link("target_type", new_compart_type)
									:link("element", copy)
									:link("compartType", compart:find("/compartType"))
			compart_type:find("/compartStyle"):each(function(compart_style)
				local new_compart_style = lQuery.create("CompartStyle"):copy_attrs_from(compart_style)
				new_compart_type:link("compartStyle", new_compart_style)
				if compart:find("/compartStyle"):id() == compart_style:id() then
					new_compart:link("compartStyle", new_compart_style)
				end
			end)
			copy_prop_diagram_to_obj_type(compart_type, new_compart_type, "compartType")
			copy_compart_type_row(compart_type, new_compart_type)
			copy_choice_item(compart_type, new_compart_type)
			copy_sub_compart_types(compart_type, new_compart_type)
		end
	end)
	copy:find("/compartment:has(/compartType[id = 'AS#Attributes']):not(:has(/target_type))"):delete()
end

function copy_choice_item(old_compart_type, new_compart_type)
	old_compart_type:find("/choiceItem"):each(function(choice_item)
		local new_choice_item = lQuery.create("ChoiceItem"):copy_attrs_from(choice_item)
									:link("compartType", new_compart_type)
		local compart_style = choice_item:find("/compartStyleByChoiceItem")
		if compart_style:is_not_empty() then
			new_compart_type:find("/compartStyle[id = '" .. compart_style:attr("id") .. "']"):link("choiceItem", choice_item)
		end
		local elem_style = choice_item:find("/elemStyleByChoiceItem")
		if elem_style:is_not_empty() then
			u.get_elem_type_from_compartment(new_compart_type):find("/elemStyle[id = '" .. elem_style:attr("id") .. "']"):link("choiceItem", choice_item)
		end
		local old_notation = choice_item:find("/notation")
		if old_notation:is_not_empty() then
			lQuery.create("Notation"):copy_attrs_from(old_notation)
						:link("choiceItem", choice_item)
		end
		local tag_compart_type = choice_item:find("/tag")
		if tag_compart_type:is_not_empty() then
			local tag_prop_row = tag_compart_type:find("/propertyRow")
			local compart_style = tag_compart_type:find("/compartStyle")
			lQuery.create("CompartType"):copy_attrs_from(tag_compart_type)
							:link("stereotype", new_choice_item)
							:link("propertyRow", lQuery.create("PropertyRow"):copy_attrs_from(tag_prop_row))
							:link("compartStyle", lQuery.create("CompartStyle"):copy_attrs_from(compart_style))
		end
	end)
end

function copy_sub_compart_types(compart_type, new_compart_type)
	compart_type:find("/subCompartType"):each(function(sub_compart_type)
		local new_sub_compart_type = lQuery.create("CompartType"):copy_attrs_from(sub_compart_type)
									:link("parentCompartType", new_compart_type)
		copy_prop_diagram_to_obj_type(sub_compart_type, new_sub_compart_type, "compartType")
		copy_compart_type_row(sub_compart_type, new_sub_compart_type)
		copy_choice_item(sub_compart_type, new_sub_compart_type)
		copy_sub_compart_types(sub_compart_type, new_sub_compart_type)	
	end)
end

function copy_prop_diagram_to_obj_type(old_type, obj_type, role)
	local prop_diagram = old_type:find("/propertyDiagram")
	if prop_diagram:is_not_empty() then
		local new_prop_diagram = lQuery.create("PropertyDiagram"):copy_attrs_from(prop_diagram)
									:link(role, obj_type)
									:link("original", prop_diagram)
		copy_prop_row_event_handler(prop_diagram, new_prop_diagram)
	end
	return  prop_diagram
end

function copy_compart_type_row(compart_type, new_compart_type)
	compart_type:find("/propertyRow"):each(function(prop_row)
		local new_prop_row = lQuery.create("PropertyRow"):copy_attrs_from(prop_row)
								:link("compartType", new_compart_type)
								:link("original", prop_row)
		copy_prop_row_event_handler(prop_row, new_prop_row)
	end)
end

function copy_property_row_links(prop_diagram)
	local new_prop_diagram = prop_diagram:find("/copy")
	if new_prop_diagram:is_not_empty() then
		prop_diagram:find("/propertyTab"):each(function(tab)
			local new_tab = lQuery.create("PropertyTab"):copy_attrs_from(tab)
									:link("propertyDiagram", new_prop_diagram)
			copy_prop_row_event_handler(tab, new_tab)
			tab:find("/propertyRow"):each(function(prop_row)
				copy_property_row(prop_row, new_tab, "propertyTab")
			end)
		end)
		prop_diagram:find("/propertyRow"):each(function(prop_row)
			copy_property_row(prop_row, new_prop_diagram, "propertyDiagram")
		end)
		prop_diagram:remove_link("copy", new_prop_diagram)
	end
end

function copy_property_row(prop_row, new_parent, role)
	local new_prop_row = prop_row:find("/copy"):link(role, new_parent)
							:remove_link("original", prop_row)
	local called_diagram = prop_row:find("/calledDiagram")
	if called_diagram:is_not_empty() then
		lQuery.create("PropertyDiagram"):copy_attrs_from(called_diagram)
						:link("calledPropertyRow", new_prop_row)
						:link("original", called_diagram)
		copy_property_row_links(called_diagram)
	end
end

function copy_prop_row_event_handler(prop_row, new_prop_row)
	local handler = prop_row:find("/propertyEventHandler")
	if handler:is_not_empty() then
		local new_handler = lQuery.create("PropertyEventHandler"):copy_attrs_from(handler):link("propertyElement", new_prop_row)
	end
end

function copy_target_diagram1(elem, target_type, function_name)
	local original = elem:find("/original")
	local target_diagram = original:find("/target")
	local target_diagram_type = target_diagram:find("/target_type")
	local target_diagram_copy = lQuery.create("GraphDiagram"):copy_attrs_from(target_diagram)
								:link("source", elem)
								:link("graphDiagramType", target_diagram:find("/graphDiagramType"))
	local new_diagram_type = lQuery.create("GraphDiagramType"):copy_attrs_from(target_diagram_type)
									:link("source", target_type)
									:link("presentation", target_diagram_copy)
	copy_paste.copy_diagram_elements(target_diagram, target_diagram_copy)
end

function configurator_seed_pasted(elem)
	local target_type = configurator_elem_pasted(elem)
	--copy_target_diagram(elem, target_type, configurator_elem_pasted)
end
