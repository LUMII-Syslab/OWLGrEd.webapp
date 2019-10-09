module(..., package.seeall)

cu = require("configurator.configurator_utilities")
d = require("dialog_utilities")
report = require("reporter.report")

function row_type_generator(combo)
	cu.add_configurator_comboBox({"", 
				"InputField",
				"ComboBox",
				"CheckBox",
				"TextArea",
				"Label",
				"ListBox",
				"InputField+Button",
				"ComboBox+Button",
				"TextArea+Button",
				"TextArea+DBTree",
				"CheckBox+Button"}, combo)
	--"MultiLineTextBoxRow+Tree","GroupedInputsRow", "TagRow", "StereotypeRow", "EmptyRow"})
end

function make_property_field()
	local attr, value = cu.get_event_source_attrs("text")
	local field = d.get_component_by_id(attr)
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(field), [attr] = value})
-- vajag izdzçst check box un combo box tabulu sarazoto domain
	manage_property_row_field_table(field, value, "false")
	set_row_type()
end

function manage_property_row_field_table(field, value, start_build)
	local compart_type = cu.get_selected_type()
	local active_tab = cu.active_tab()
	local row_type_box = d.get_component_by_id_in_depth(active_tab, "row_rowType")
	local vertical_box = d.get_component_by_id_in_depth(row_type_box, "field_box")
	local table = d.get_component_by_id_in_depth(vertical_box, "click_box_table")
	if table ~= nil then
		table:delete()
	end
	local combo_box = d.get_component_by_id_in_depth(vertical_box, "row_editable")
	if combo_box ~= nil then
		combo_box:delete()
	end
	if value == "CheckBox" or value == "ComboBox" or value == "CheckBox+Button" then
		if start_build ~= "true" then
			local choice_items = compart_type:find("/choiceItem"):delete()
		end
		if value == "CheckBox" or value == "CheckBox+Button" then
			if start_build ~= "true" then
				add_default_check_box_items(compart_type)
			end
			table = add_click_box_table(vertical_box, {id = "click_box_table", editable = "false"}, "lua.configurator.dialog.update_from_click_box_table")
			d.add_columnType(table, {caption = "Notation", editable = "true", horizontalAlignment = -1}, "D#TextBox", {editable = "true"})
			fill_click_box_table(table, "Notation")
		elseif value == "ComboBox" then
			table = add_click_box_table(vertical_box, {id = "click_box_table", editable = "true", insertButtonCaption = "Add", deleteButtonCaption = "Delete"}, "lua.configurator.dialog.update_from_combo_box_table")
			local is_visible = d.add_columnType(table, {caption = "IsInvisible", editable = "true", horizontalAlignment = -1}, "D#CheckBox", {editable = "true"})
			local _, check_box = cu.add_checkBox_field_function(vertical_box, "Is Editable", "editable", field, {Change =  "lua.configurator.dialog.set_combobox_editable"})			
			check_box:attr({checked = compart_type:find("/propertyRow"):attr("isEditable")})
			fill_click_box_table(table, "IsVisible")
		end
	end
	if start_build ~= "true" then
		local old_row_type = compart_type:find("/propertyRow"):attr("rowType")
		if (old_row_type == "ComboBox" and value ~= "ComboBox") or (old_row_type == "CheckBox" and value ~= "CheckBox") or
		(value == "ComboBox" and old_row_type ~= "ComboBox") or (value == "CheckBox" and old_row_type ~= "CheckBox") or
		(old_row_type == "CheckBox+Button" and value ~= "CheckBox+Button") or (value == "CheckBox+Button" and old_row_type ~= "CheckBox+Button") then
			utilities.refresh_form_component(vertical_box)
		end
	end
end

function fill_click_box_table(table, last_cell)
	cu.get_selected_type():find("/choiceItem"):each(function(item)
		local table_row = lQuery.create("D#VTableRow"):link("vTable", table)
		lQuery.create("D#VTableCell", {vTableRow = table_row, value = item:attr_e("value")})
		lQuery.create("D#VTableCell", {vTableRow = table_row, value = item:find("/elemStyleByChoiceItem"):attr_e("id")})
		lQuery.create("D#VTableCell", {vTableRow = table_row, value = item:find("/compartStyleByChoiceItem"):attr_e("id")})
		if last_cell == "Notation" then
			local notation_value = item:find("/notation"):attr_e("value")
			lQuery.create("D#VTableCell", {vTableRow = table_row, value = notation_value})
		elseif last_cell == "IsVisible" then
			if item:find("/notation"):is_empty() then
				lQuery.create("D#VTableCell", {vTableRow = table_row, value = "true"})
			else
				lQuery.create("D#VTableCell", {vTableRow = table_row, value = "false"})
			end
		elseif last_cell == "button" then
			lQuery.create("D#VTableCell", {vTableRow = table_row})
		end
	end)
end

function add_called_diagram(row)
	local parent, role = get_existing_row_parent(row)
	local obj_type = row:find("/compartType")
	local called_dgr = create_property_diagram(obj_type, "compartType")
	obj_type:find("/propertyDiagram", called_dgr)
	row:link("calledDiagram", called_dgr, parent, role)
	relink_property_rows(obj_type, called_dgr, parent, role)
end

function relink_property_rows(obj_type, called_dgr, parent, role)
	local sub_compart_type = obj_type:find("/subCompartType")
	if sub_compart_type:size() > 0 then
		sub_compart_type:each(function(compart_type)
			local row = compart_type:find("/propertyRow")
			if row:size() > 0 then
				local row_parent, parent_role = get_existing_row_parent(row)
				if row_parent:filter(".PropertyTab"):size() > 0 then
					if row_parent:find("/propertyRow"):size() == 1 then
						row_parent:remove_link("propertyDiagram")
						row_parent:link("propertyDiagram", called_dgr)
					else
						--japadoma, vai nevajag izveidot jaunu tabu?
						row:remove_link(parent_role, row_parent)
						row:link("propertyDiagram", called_dgr)
						remove_up_the_tree_from_row(row_parent:find("/calledPropertyRow"))
					end
				else
					row:remove_link("propertyDiagram", row_parent)
					row:link("propertyDiagram", called_dgr)
					remove_up_the_tree_from_row(row_parent:find("/calledPropertyRow"))
				end
			end
			relink_property_rows(compart_type, called_dgr, parent, role)
		end)
	end
end

function relink_property_diagram()
	local prop_diagram = utilities.active_elements():find("/target_type/propertyDiagram")
	add_property_diagram_links(prop_diagram)
end

function add_property_diagram_links(prop_diagram)
	local tree = d.get_component_by_id("property_tree")
	link_property_diagram_elements(prop_diagram, tree:find("/treeNode"))
end

function link_property_diagram_elements(prop_parent, tree_node)
	tree_node:find("/childNode"):each(function(child_node)
		local prop_elem = child_node:find("/propertyElement")
		if prop_elem:filter(".PropertyRow"):is_not_empty() then
			prop_parent:remove_link("propertyRow", prop_elem)
					:link("propertyRow", prop_elem)
			local called_dgr = prop_elem:find("/calledDiagram")
			if called_dgr:is_not_empty() then
				link_property_diagram_elements(called_dgr, child_node:find("/childNode"))
			end
		else
			--local prop_tab = child_node:find("/propertyElement")
			if prop_elem:filter(".PropertyTab"):is_not_empty() then
				prop_parent:remove_link("propertyTab", prop_elem)
						:link("propertyTab", prop_elem)
				link_property_diagram_elements(prop_elem, child_node)
			end
		end
	end)
end

function manage_palette_element()
	print("manage palette element")
end

function relink_to_parent(parent, role, elem)
	parent:remove_link(role, elem)
		:link(role, elem)
end

function add_fiction_compart_for_check_box_button(compart_type)
--	local parent, role = utilities.get_obj_type_parent(compart_type)
--	compart_type:remove_link(role, parent)
--	local name = "CheckBoxFictitious" .. compart_type:attr("id")
--	local fiction_type = add_compart_type(name)
--	u.add_default_compart_style(name, name):link("compartType", fiction_type)
--	local sub_compart_types = compart_type:find("/subCompartType")
--	compart_type:remove_link("subCompartType", sub_compart_types)
--	fiction_type:link(role, parent)
--			:link("subCompartType", compart_type)
--			:link("subCompartType", sub_compart_types)
--	local tree_node = compart_type:find("/treeNode")
--	local parent_node = tree_node:find("/parentNode")
--	tree_node:remove_link("parentNode", parent_node)
--	local id = fiction_type:attr("id")
--	d.add_tree_node(parent_node, "parentNode", {id = id, text = id, expanded = "true"})
--			:link("typeWithMapping", fiction_type)
--			:link("childNode", tree_node)
--	utilities.refresh_form_component(d.get_component_by_id("Tree"))


	add_fiction_compart("CheckBoxFictitious" .. compart_type:attr("id"), compart_type)


--	if parent:filter(".ElemType"):is_not_empty() then
--		local compart = compart_type:find("/presentation")
--		compart_type:remove_link("presentation", compart)
--		fiction_type:link("presentation", compart)
--		local compart_style = compart_type:find("/compartStyle")
--		compart_type:remove_link("compartStyle", compart_style)
--		fiction_type:link("compartStyle", compart_style)
--	end
--	fiction_type:attr({concatStyle = compart_type:attr("concatStyle"), caption = compart_type:attr("caption")})
--	compart_type:attr({concatStyle = ""})
	return fiction_type
end

function add_fiction_copmart_for_text_field(object_type)
	--vajag pielikt fiction compartmentu
	add_fiction_compart("ASFictitious" .. object_type:attr("id"), object_type)

	local parent_type = object_type:find("/parentCompartType")
	local row = object_type:find("/propertyRow")
	local diagram = object_type:find("/propertyDiagram")
	object_type:remove_link("propertyRow")
			:remove_link("propertyDiagram")
	parent_type:link("propertyRow", row)
			:link("propertyDiagram", diagram)
end

function add_fiction_compart(name, compart_type)
	local parent, role = utilities.get_obj_type_parent(compart_type)
	compart_type:remove_link(role, parent)
	--local name = "CheckBoxFictitious" .. compart_type:attr("id")
	local fiction_type = cu.add_compart_type(name)
	cu.add_default_compart_style(name, name):link("compartType", fiction_type)
	local sub_compart_types = compart_type:find("/subCompartType")
	compart_type:remove_link("subCompartType", sub_compart_types)
	fiction_type:link(role, parent)
			:link("subCompartType", compart_type)
			:link("subCompartType", sub_compart_types)
	local tree_node = compart_type:find("/treeNode")
	local parent_node = tree_node:find("/parentNode")
	tree_node:remove_link("parentNode", parent_node)
	local id = fiction_type:attr("id")
	d.add_tree_node(parent_node, "parentNode", {id = id, text = id, expanded = "true"})
			:link("type", fiction_type)
			:link("childNode", tree_node)
	utilities.refresh_form_component(d.get_component_by_id("Tree"))

end

function add_fiction_compartment(compart_type)
	local role = "parentCompartType"
	local parent = compart_type:find("/" .. role)
	if parent:is_empty() then
		role = "elemType"
		parent = compart_type:find("/" .. role)
	end
	compart_type:remove_link(role, parent)
	local fiction_type = add_compart_type("ASFictitious" .. compart_type:attr("id"))
	if parent:filter(".ElemType"):is_not_empty() then
		local compart = compart_type:find("/presentation")
		compart_type:remove_link("presentation", compart)
		fiction_type:link("presentation", compart)
		local compart_style = compart_type:find("/compartStyle")
		compart_type:remove_link("compartStyle", compart_style)
		fiction_type:link("compartStyle", compart_style)
	end
	fiction_type:attr({concatStyle = compart_type:attr("concatStyle"), caption = compart_type:attr("caption")})
	compart_type:attr({concatStyle = ""})
	fiction_type:link(role, parent)
			:link("subCompartType", compart_type)
	return fiction_type
end

function get_type_parent(object_type)
	local parent_type = object_type:find("/parentCompartType")
	if parent_type:size() > 0 then
		return parent_type
	else
		return object_type:find("/elemType")
	end
end

function get_res_table_from_table(source)
	local res_table = {}
	local indexed_res_table = {}
	source:find("/vTableRow"):each(function(row)
		local tmp_table = {}
		if row:attr_e("deleted") ~= "true" then
			local buls = 0
			local id = ""
			row:find("/vTableCell"):each(function(cell)
				if buls == 0 then
					id = cell:attr_e("value")
					buls = 1
				end
				table.insert(tmp_table, cell:attr_e("value"))
			end)
			table.insert(res_table, tmp_table)
			indexed_res_table[id] = tmp_table
		end
	end)
	return res_table, indexed_res_table
end

function get_choice_item()
	local choice_item_id = d.get_component_by_id("click_box_table"):find("/selectedRow/vTableCell:first()"):attr("value")
	local compart_type = d.get_component_by_id("Tree"):find("/selected/type")
	local res = nil
	local buls = 0
	compart_type:find("/choiceItem"):each(function(choice_item)
		if choice_item:attr("value") == choice_item_id and buls == 0 then
			buls = 1
			res = choice_item
		end	
	end)
	return res
end

function add_rows_to_diagram_from_compart_type(object_type)
	local child_type = object_type:find("/subCompartType")
	if child_type:size() > 0 then
		local called_dgr = create_property_diagram(object_type, "compartType"):link("calledPropertyRow", property_row)
		child_type:find("/propertyRow"):remove_link("propertyTab")
					:remove_link("propertyDiagram")
					:link("propertyDiagram", called_dgr)
		child_type:find("/subCompartType"):each(function(child)
			add_rows_to_diagram_from_compart_type(child)
		end)
	end
end

function set_combobox_editable()
	local _, value = cu.get_event_source_attrs("checked")
	cu.get_selected_type():find("/propertyRow"):attr({isEditable = value})
end

function add_click_box_table(container, table_attr_list, focus_lost_function)
	local table = d.add_component(container, table_attr_list, "D#VTable")
		:attr({minimumWidth = 100, minimumHeight = 100})
	d.add_event_handlers(table, {FocusLost = focus_lost_function})
	local choice_item = d.add_columnType(table, {caption = "ChoiceItem", editable = "true", horizontalAlignment = -1}, "D#TextBox", {editable = "true"})
	local elem_style = d.add_columnType(table, {caption = "ElemStyle", editable = "true", horizontalAlignment = -1}, "D#ComboBox", {editable = "true"}, {DropDown = "lua.configurator.configurator.get_element_styles"})
	local compart_style = d.add_columnType(table, {caption = "CompartStyle", editable = "true", horizontalAlignment = -1}, "D#ComboBox", {editable = "true"}, {DropDown = "lua.configurator.configurator.get_compart_styles"})
return table
end


function get_style_from_type_object(object, path)
	if object ~= nil then
		return object:find(path)
	else
		return nil
	end
end

function manage_called_diagram(property_row, value, row_parent, role)
	local old_value = property_row:attr("rowType")
	print("old value " .. old_value .. " new value " .. value)
	if (old_value == "InputField+Button" or old_value == "TextArea+Button" or old_value == "ComboBox+Button") and
	(value ~= "InputField+Button" and value ~= "TextArea+Button" and value ~= "CheckBox+Button" and value ~= "ComboBox+Button") then
		--local dgr = property_row:find("/calledDiagram")
		local dgr = property_row:find("/compartType/propertyDiagram")
		delete_called_diagram(dgr)
	elseif old_value == "CheckBox+Button" then --and (value ~= "InputField+Button" and value ~= "TextArea+Button" and value ~= "CheckBox+Button") then
		local compart_type = property_row:find("/compartType")
		local diagram = compart_type:find("/propertyDiagram")
		local rows = diagram:find("/propertyRow")
		local tabs = diagram:find("/propertyTab")
		diagram:remove_link("propertyRow")
			:remove_link("propertyTab")
		local new_tab = property_row:find("/propertyTab")
		local new_diagram = property_row:find("/propertyDiagram")
		if new_tab:is_not_empty() then
			new_diagram = new_tab:find("/propertyDiagram")
			new_diagram:link("propertyTab", tabs)
			new_tab:link("propertyRow", rows)
		else
			new_diagram:link("tab", tabs)
			new_diagram:link("propertyRow", rows)
		end
		diagram:delete()
		local parent_type = utilities.get_obj_type_parent(compart_type)
		local parent_tree_node = parent_type:find("/treeNode")
	
		local parent_parent_type, role = utilities.get_obj_type_parent(parent_type)
		local parent_parent_tree_node = parent_parent_type:find("/treeNode")

		local sub_types = parent_type:find("/subCompartType")
		local sub_tree_nodes = sub_types:find("/treeNode")

		parent_type:remove_link("subCompartType")
		parent_type:remove_link("parentCompartType")
		parent_type:delete()
		parent_tree_node:remove_link("childNode")
		parent_tree_node:remove_link("parentNode")
		parent_tree_node:delete()

		sub_types:link(role, parent_parent_type)
		parent_parent_tree_node:link("childNode", sub_tree_nodes)
		utilities.refresh_form_component(d.get_component_by_id("Tree"))
		if old_value == "CheckBox+Button" and (value == "InputField+Button" and value == "TextArea+Button" and value == "ComboBox+Button") then
			--local compart_type = property_row:find("/compartType")
			add_fiction_copmart_for_text_field(compart_type)
		end
	elseif value == "CheckBox+Button" then
		add_called_diagram(property_row)
		add_fiction_compart_for_check_box_button(property_row:find("/compartType"))
	elseif (old_value == "InputField+Button" or old_value == "TextArea+Button" or old_value == "ComboBox+Button") and value == "CheckBox+Button" then
		local dgr = property_row:find("/compartType/propertyDiagram")
		delete_called_diagram(dgr)
		add_fiction_compart_for_check_box_button(compart_type)
	
	elseif value == "InputField+Button" or value == "TextArea+Button" or value == "ComboBox+Button" then
		local compart_type = property_row:find("/compartType")
		add_fiction_copmart_for_text_field(compart_type)
	end
end

function get_property_diagram(object_type)
	local parent_type = object_type:find("/parentCompartType")
	if parent_type:is_empty() then
		parent_type = object_type:find("/elemType")
	end
	local dgr = parent_type:find("/propertyDiagram")
	if dgr:is_empty() then
		local sub_compart_type = parent_type:find("/subCompartType:has(/propertyRow[rowType = 'CheckBox+Button'])")
		local tmp_dgr = sub_compart_type:find("/propertyDiagram")
		if tmp_dgr:is_not_empty() and object_type:id() ~= sub_compart_type:id() then
			return tmp_dgr
		else
			return get_property_diagram(parent_type)
		end
	else
		return dgr
	end
end

function create_property_diagram(object_type, role_type)
	return lQuery.create("PropertyDiagram", {id = object_type:attr("id"), caption = object_type:attr("caption")}):link(role_type, object_type)
end

function create_property_row(attr, caption, value, row_parent, parent_role, object_type)
	return lQuery.create("PropertyRow", {id = attr, caption = caption, rowType = value, isEditable = "true", isReadOnly = "false", isFirstRespondent = "false"})
			:link(parent_role, row_parent)
			:link("compartType", object_type)
end

function set_property_row_attributes(property_row, attrs)
	property_row:attr(attrs)
end

--vajag vel izdzest rowus patvaliga dziluma
function delete_called_diagram(diagram)
	print("delete called diagram")
	if diagram:size() > 0 then
		diagram:find("/propertyTab"):each(function(tab)
			tab:find("/propertyRow"):each(function(row)
				local called_dgr = row:find("/calledDiagram")
				row:delete()
				delete_called_diagram(called_dgr)
			end)
			tab:delete()
		end)
		diagram:find("/propertyRow"):each(function(row)
			local called_dgr = row:find("/calledDiagram")
			row:delete()
			delete_called_diagram(called_dgr)
		end)
		diagram:delete()
	end
	print("end delete called diagram")
end

function manage_property(property_row)
	print("manage property")
	property_row:log("rowType")
	local property_diagram = property_row:find("/propertyDiagram")
	local property_tab = property_row:find("/propertyTab")
	local called_diagram = property_row:find("/calledDiagram")
	if called_diagram:size() > 0 then
		print("in called diagram")
		local called_tab = called_diagram:find("/propertyTab")
		local called_rows = called_diagram:find("/propertyRow")
		called_diagram:remove_link("propertyRow")
				:remove_link("propertyTab")
				:delete()
		if property_tab:size() > 0 then
			print("property tab")
			local diagram = property_tab:find("/propertyDiagram")
			called_tab:link("propertyDiagram", diagram)
			called_rows:link("propertyTab", property_tab)	
		else
			called_rows:link("propertyDiagram", property_diagram)	
		end
		property_row:delete()
		if property_tab:find("/propertyRow"):size() == 0 then
			print("property tab delete")
			property_tab:delete()
		end
	elseif property_tab:find("/propertyRow"):size() == 1 then
		print("in tab")
		local res = manage_property_diagram(property_tab)
		if res == "not_deleted" then 
			property_tab:delete() 	
		end
	elseif property_diagram:find("/propertyRow"):size() == 1 and property_diagram:find("/propertyTab"):size() == 0 then
		print("in diagram")
		property_row:delete()
		property_diagram:delete()
	else
		print("in row")
		property_row:delete()
	end
	print("end manage property")

--		print("manage property emptpy")
--		local called_diagram = property_row:find("/calledDiagram"):log()
--		local row_parent, role = get_property_row_parent(property_row:find("/compartType"))
--		row_parent:log()
--		print("role " .. role)
--
--		if called_diagram:size() > 0 then
--			print("called diagram")
--			called_diagram:find("/propertyRow"):link(role, row_parent)
--			called_diagram:remove_link("propertyRow")
--			if role == "propertyDiagram" then
--				called_diagram:find("/propertyTab"):link(role, row_parent)
--			elseif role == "propertyTab" then
--				local parent_diagram = row_parent:find("/propertyDiagram")
--				called_diagram:find("/propertyTab"):link("propertyDiagram", parent_diagram)
--			end
--			delete_called_diagram(called_diagram)
--		end
--		property_row:delete() 
--	end
end

function add_default_check_box_items(compart_type)
print("add default check box items")
	local elem_type = cu.get_elem_type_from_compartment(compart_type)
	create_choice_item(compart_type, elem_type, {"true", "", "", "true"})
	create_choice_item(compart_type, elem_type, {"false", "", "", "false"})

	compart_type:find("/choiceItem"):log()
print("end add default check box items")
end

function create_choice_item(compart_type, elem_type, row)
	return create_choice_item_without_notation(compart_type, elem_type, row):link("notation", create_notation(row[4], row[1]))
end

function create_choice_item_without_notation(compart_type, elem_type, row)
print("create choice item")
	return lQuery.create("ChoiceItem", {
		compartType = compart_type,
		value = row[1],
		elemStyleByChoiceItem = get_style_from_type_object(elem_type, "/elemStyle:has([id = '" .. row[2] .. "'])"),
		compartStyleByChoiceItem = get_style_from_type_object(compart_type, "/compartStyle:has([id = '" .. row[3] .. "'])"):log()})
end

function create_notation(val, default_val)
	if val == nil then
		return lQuery.create("Notation", {value = default_val})
	else
		return lQuery.create("Notation", {value = val})
	end
end

function update_from_click_box_table()
	local compart_type = cu.get_selected_type()
	delete_choice_items_and_notation(compart_type)
	local res_table = get_res_table_from_table(cu.get_event_source())
	local elem_type = cu.get_elem_type_from_compartment(compart_type)
	for _, row in pairs(res_table) do  
		create_choice_item(compart_type, elem_type, row)
	end
end

function delete_choice_items_and_notation(compart_type)
	local choice_items = compart_type:find("/choiceItem")
	if choice_items:size() > 0 then
		local notation = choice_items:find("/notation")
		if notation:size() > 0 then
			notation:delete()
		end
		choice_items:delete()
	end
end

function update_from_combo_box_table()
	local compart_type = cu.get_selected_type()
	delete_choice_items_and_notation(compart_type)
	local res_table = get_res_table_from_table(cu.get_event_source())
	local elem_type = cu.get_elem_type_from_compartment(compart_type)
	for _, row in pairs(res_table) do
		local choice_item = create_choice_item_without_notation(compart_type, elem_type, row)
		if row[4] ~= "true" then
			local val = core.build_input_from_value(row[1], compart_type)
			choice_item:link("notation", create_notation(val))
		end
	end
end

function manage_property_diagram(property_tab)
	local result = "not_deleted"
	local property_diagram = property_tab:find("/propertyDiagram")
	if property_diagram:find("/propertyTab"):size() == 1 and property_diagram:find("/propertyRow"):size() == 0 then
		property_diagram:delete()
		result = "deleted"
	end
return result
end

function get_property_row_parent(object_type)
	print("get property row parent")
	local tab_value = lQuery("D#Component:has([id = 'id'])"):filter(".D#ComboBox"):attr("text")
	if tab_value ~= "" then
		print("in tab")
		local diagram = get_property_diagram(object_type)
		local tab = get_tab_by_name(diagram, "caption", tab_value)
		if tab ~= nil then
			return tab, "propertyTab"
		else
			return lQuery.create("PropertyTab", {caption = tab_value}):link("propertyDiagram", diagram), "propertyTab"
		end
	else 
		print("diagram")
		local parent_type = object_type:find("/parentCompartType")
		if parent_type:is_not_empty() then
			print("compartType")
			local diagram = parent_type:find("/propertyDiagram")
			if diagram:is_not_empty() then 
				return diagram, "propertyDiagram"
			else	
				print("add diagram")
				local row = parent_type:find("/propertyRow")
				local row_value = row:attr("rowType")
				if row_value == "InputField+Button" or row_value == "TextArea+Button" or row_value == "ComboBox+Button"then
					print("button")
					local called_diagram = parent_type:find("/propertyDiagram")
					--local called_diagram = row:find("/calledDiagram")
					if called_diagram:is_not_empty() then
						return called_diagram, "propertyDiagram"
					else
						--return create_property_diagram(parent_type, "compartType"), "propertyDiagram"
						local prop_dgr = create_property_diagram(row, "calledPropertyRow")
						prop_dgr:link("compartType", parent_type)
						return prop_dgr, "propertyDiagram"
					end
				elseif row_value == "CheckBox+Button" then
					print("check box + button")
					local called_diagram = parent_type:find("/propertyDiagram")
					--local called_diagram = row:find("/calledDiagram")
					if called_diagram:is_not_empty() then
						return called_diagram, "propertyDiagram"
					else
						--return create_property_diagram(parent_type, "compartType"), "propertyDiagram"
						local prop_dgr = create_property_diagram(row, "calledPropertyRow")
						prop_dgr:link("compartType", parent_type)
						return prop_dgr, "propertyDiagram"
					end

				else
					print("in else")

					local tmp_dgr = parent_type:find("/subCompartType:has(/propertyRow[rowType = 'CheckBox+Button'])/propertyDiagram")
					if tmp_dgr:is_not_empty() then
					--	print("in if")
						return tmp_dgr, "propertyDiagram"
					else
					--	print("get parent")
						return get_property_row_parent(parent_type)
					end
				end
			end
		else	
			parent_type = object_type:find("/elemType")
			local diagram = parent_type:find("/propertyDiagram")
			if diagram:is_not_empty() then
				return diagram, "propertyDiagram"
			else
				return create_property_diagram(parent_type, "elemType"), "propertyDiagram"
			end
		end
	end

	print("end get property row parent")
end

function set_row_tab()
print("function set row tab")
	if lQuery("D#Component:has([id = 'rowType'])"):attr("text") ~= "" then
		local attr, value = cu.get_event_source_attrs("text")
		local object_type = cu.get_selected_obj_type()
		log_configurator_field(attr, {Tab = value})
		local diagram = get_property_diagram(object_type)
		local row = object_type:find("/propertyRow")
		local tab = get_tab_by_name(diagram, attr, value)
		if value == "" then 
			print("empty tab")
			local parent_tab = row:find("/propertyTab")
			row:remove_link("propertyTab", parent_tab):link("propertyDiagram", diagram)
			local rows = parent_tab:find("/propertyRow")
			if rows:size() == 0 then
				print("delete tab")
				delete_empty_property_tab(parent_tab)
			end
		else
print("else tab")
			if tab == nil then
			print("new tab")
				set_property_tab(attr, value, diagram, row)
			else
			print("change tab")
				change_to_tab(tab, row)
			end
		end
	end
print("end set row tab")
end

function set_row_type()
	local attr, value = cu.get_event_source_attrs("text")
	local object_type = cu.get_selected_obj_type()
	local name = object_type:attr("caption")
	--remove_fiction_compartment(object_type)
	if value == "" then 
		manage_property(object_type:find("/propertyRow"))
	else
		set_property_row(name, value, object_type)
	end
	local buls = cu.is_dialog_button_enabled(get_active_target_type())
	local dialog_button = d.get_component_by_id_in_depth(lQuery("D#Form[id = 'configurator_form']"), "dialog_button")
	dialog_button:attr({enabled = buls})
	d.execute_d_command(dialog_button, "Refresh")
end

function remove_up_the_tree_from_row(row)
	local tab = row:find("/propertyTab")
	local diagram = row:find("/propertyDiagram")
	if tab:size() > 0 then
		if tab:find("/propertyRow"):size() == 1 then
			diagram = find("/propertyDiagram")
			tab:delete()
			if diagram:find("/propertyRow"):size() == 0 and diagram:find("/propertyTab"):size() == 0 then
				local calling_row = diagram:find("/calledPropertyRow")
				diagram:delete()
				remove_up_the_tree_from_row(calling_row)
			end
		end
	elseif diagram:size() > 0 then
		if diagram:find("/propertyRow"):size() == 1 and diagram:find("/propertyTab"):size() == 0 then
			local calling_row = diagram:find("/calledPropertyRow")
			diagram:delete()
			remove_up_the_tree_from_row(calling_row)	
		end
	end
end

function get_existing_row_parent(row)
	local tab = row:find("/propertyTab")
	local diagram = row:find("/propertyDiagram")
	if tab:size() > 0 then
		return tab, "propertyTab"
	elseif diagram:size() > 0 then
		return diagram, "propertyDiagram"
	else
		print("Error in get_existing_row_parent")
	end
end

function set_property_row(name, value, object_type)
	local row_parent, parent_role = get_property_row_parent(object_type)
	local property_row = object_type:find("/propertyRow")
	if property_row:is_not_empty() then
		print("old row")
		manage_called_diagram(property_row, value, row_parent, parent_role)
		set_property_row_attributes(property_row, {id = name, rowType = value})
	else
		print("else row")
		local property_row
		if row_parent:filter(".PropertyDiagram"):is_not_empty() and row_parent:find("/compartType/propertyRow[rowType = 'CheckBox+Button']"):is_not_empty() then
			property_row = create_property_row(object_type:attr("id"), name, value, row_parent, parent_role, object_type)
		else
			property_row = create_property_row(object_type:attr("id"), name, value, row_parent, parent_role, object_type)
		end

		--local property_row = create_property_row(object_type:attr("id"), name, value, row_parent, parent_role, object_type)
		--if value == "InputField+Button" or value == "TextArea+Button" or value == "CheckBox+Button" then
		if value == "TextArea+Button" or value == "CheckBox+Button" then
			print("add called diagram")
			
			if value == "CheckBox+Button" then
				add_called_diagram(property_row)

				add_fiction_compart_for_check_box_button(object_type)
			else
				print("in fiction")
				add_called_diagram(property_row)
				add_fiction_copmart_for_text_field(object_type)
			end
		else
			remove_sub_property_rows(property_row)
		end
	end
end

function remove_sub_property_rows(property_row)
	local compart_type = property_row:find("/compartType")
	compart_type:find("/subCompartType"):each(function(c_type)
		local row = c_type:find("/propertyRow")
		local dgr = row:find("/calledDiagram")
		delete_called_diagram(dgr)
		remove_up_the_tree_from_row(row)
		remove_sub_property_rows(row)
		row:delete()
	end)
end

function row_tab_generator()
	cu.add_lQuery_configurator_comboBox(cu.make_combo_box_item_table(get_property_diagram(cu.get_selected_type()):find("/propertyTab"), "id"))
end

function change_to_tab(tab, row)
	local diagram = row:find("/propertyDiagram")
	if diagram:size() > 0 then
		diagram:remove_link("propertyRow", row)
	else
		local parent_tab = row:find("/propertyTab")
		if parent_tab:size() > 0 then
			parent_tab:remove_link("propertyRow", row)
			if parent_tab:find("/propertyRow"):size() == 0 then 
				delete_empty_property_tab(parent_tab)
			end
		end
	end
	tab:link("propertyRow", row)
end

function get_tab_by_name(diagram, attr, value)
	local res = nil
	diagram:find("/propertyTab"):each(function(tab)
		tab = lQuery(tab)
		if tab:attr(attr) == value then
			res = tab
		end
	end)
return res
end

function set_property_tab(attr, value, diagram, row)
	local tab = lQuery.create("PropertyTab"):link("propertyDiagram", diagram)
	tab:attr(attr, value)
	change_to_tab(tab, row)
return tab
end

function log_configurator_field(name, list)
	report.event("Field " .. name, list)
end

function get_active_target_type()
	return utilities.active_elements():find("/target_type")
end

function delete_empty_property_tab(property_tab)
	local res = manage_property_diagram(property_tab)
	--print("delete tab res " .. res)
	if res == "not_deleted" then
		property_tab:delete()
	end
end


-- Dialog editing by pressing Dialog button

function make_dialog_form()
	cu.log_button_press("Dialog")
	local form = d.add_form({id = "dialog_form", caption = "Dialog Properties", minimumWidth = 400, minimumHeight = 300})
	local prop_elem = get_active_target_type():find("/propertyDiagram")
	local form_horizontal_box = d.add_component(form, {id = "form_horizontal_box", horizontalAlignment = 1}, "D#HorizontalBox")
	local first_row = d.add_component(form_horizontal_box, {id = "vertical_box", verticalAlignment = -1}, "D#VerticalBox")
	local second_row = d.add_component(form_horizontal_box, {id = "vertical_box2", verticalAlignment = -1}, "D#VerticalBox")
	make_dialog_component_box(first_row)	
	
	local properties_group = d.add_component(second_row, {id = "dialog_properties_box", caption = "Form Properties"}, "D#GroupBox")
	d.add_row_labeled_field(properties_group, {caption = "Name"}, {id = "prop_elem_name", text = prop_elem:attr("id")}, {id = "row_style_name"}, "D#InputField", 
	{FocusLost = "lua.configurator.dialog.update_property_element_name", Change = "lua.configurator.dialog.refresh_property_element_tree_node"})
	d.add_row_labeled_field(properties_group, {caption = "Set Focused"}, {id = "isFirstRespondent", checked = "false", enabled = "false"}, {id = "row_isFirstRespondent"}, 
										"D#CheckBox", {Change = "lua.configurator.dialog.set_first_respondent"})	
	d.add_row_labeled_field(properties_group, {caption = "Is Read Only"}, {id = "isReadOnly", checked = "false", enabled = "false"}, {id = "row_isReadOnly"}, 
										"D#CheckBox", {Change = "lua.configurator.dialog.set_is_read_only"})
	cu.add_input_field_event_function(properties_group, "Height", "height", prop_elem, {FocusLost = "lua.configurator.dialog.update_property_element_size", 
												Change = "lua.configurator.dialog.check_dialog_size"})
	cu.add_input_field_event_function(properties_group, "Width", "width", prop_elem, {FocusLost = "lua.configurator.dialog.update_property_element_size", 
												Change = "lua.configurator.dialog.check_dialog_size"})

	--d.add_row_labeled_field(properties_group, {caption = "Label Alignment"}, {id = "alignment", editable = "true", enabled = "true", text = prop_elem:attr("alignment")},
	--{id = "row_alignment"}, "D#ComboBox", {Change = "lua.configurator.configurator.set_alignment", DropDown = "lua.configurator.configurator.get_alignment_options"})	
	
	local translet_group = d.add_component(second_row, {id = "dialog_translet_box", caption = "Translets"}, "D#GroupBox")
	build_translet_box(translet_group, false)
	local translet_group = d.add_component(second_row, {id = "dialog_translet_box2", caption = "Translets"}, "D#HorizontalBox")
	local button_box = d.add_component(form, {id = "dialog_button_box", horizontalAlignment = 1}, "D#HorizontalBox")
	local close_button = d.add_button(button_box, {id = "dialog_close_button", caption = "Close"}, {Click = "lua.configurator.dialog.close_dialog_form()"})
													:link("defaultButtonForm", lQuery("D#Form[id = 'dialog_form']"))
	d.delete_event()
	d.show_form(form)
end

function close_dialog_form()
	cu.log_button_press("Close")
	relink_property_diagram()
	utilities.close_form("dialog_form")
end

function dialog_tree_node_moved()
	local ev = lQuery("D#Event")
	local old_parent = ev:find("/previousParent")
	local selected_node = ev:find("/treeNode")
	d.delete_event(ev)
	local new_parent = selected_node:find("/parentNode")
	if new_parent:id() ~= old_parent:id() or new_parent:is_empty() then
		if new_parent:is_empty() then
			selected_node:remove_link("tree", d.get_tree_from_tree_node(selected_node))
					:link("parentNode", old_parent)
		else
			selected_node:remove_link("parentNode", new_parent)
					:link("parentNode", old_parent)
		end
		utilities.refresh_form_component(d.get_component_by_id("property_tree"))
	end	
end

function make_dialog_component_box(container)
	local component_vertical_box = d.add_component(container, {id = "diagram_component_vertical_box", horizontalAlignment = -1}, "D#VerticalBox")
	local tree = d.add_component(component_vertical_box, {id = "property_tree", minimumHeight = 400, draggableNodes = "true"}, "D#Tree")
		d.add_event_handlers(tree, {TreeNodeMove = "lua.configurator.dialog.dialog_tree_node_moved",
					TreeNodeSelect = "lua.configurator.dialog.dialog_tree_node_changed"})
	fill_property_diagram_tree(tree)
end

function dialog_tree_node_changed()
	build_translet_box(translet_group, true)
	local selected_node = d.get_component_by_id("property_tree"):find("/selected")
	local check_box = d.get_component_by_id("isFirstRespondent")
	local is_read_only_check_box = d.get_component_by_id("isReadOnly")
	local prop_row = selected_node:find("/propertyElement"):filter(".PropertyRow")
	if prop_row:is_not_empty() then
		check_box:attr({enabled = "true", checked = prop_row:attr("isFirstRespondent")})
		is_read_only_check_box:attr({enabled = "true", checked = prop_row:attr("isReadOnly")})
	else
		local prop_diagram = selected_node:find("/propertyElement"):filter(".PropertyDiagram")
		if prop_diagram:is_not_empty() then
			local height_field = d.get_component_by_id("height"):attr({text = prop_diagram:attr("height")})
			local width_field = d.get_component_by_id("width"):attr({text = prop_diagram:attr("width")})
		end
		check_box:attr({checked = "false", enabled = "false"})
		is_read_only_check_box:attr({checked = "false", enabled = "false"})
	end
	d.delete_event(lQuery("D#TreeNodeSelectEvent"))
	utilities.refresh_form_component(check_box)
	utilities.refresh_form_component(is_read_only_check_box)
	--d.delete_event()
end

function fill_property_diagram_tree(tree)
	local prop_dgr = utilities.active_elements():find("/target_type/propertyDiagram")
	local dgr_value = prop_dgr:attr_e("id")
	local treeNode = d.add_tree_node(tree, "tree", {id = "propertyDiagram", text = dgr_value, expanded = "true", propertyElement = prop_dgr})
	make_diagram_children(prop_dgr, treeNode)
end

function make_diagram_children(source, parent_node)
	if source:filter(".PropertyDiagram"):size() > 0 then
		process_property_object(source, parent_node, "propertyTab", "id", "propertyElement")
		process_property_object(source, parent_node, "propertyRow", "id", "propertyElement")
	elseif source:filter(".PropertyTab"):size() > 0 then
		process_property_object(source, parent_node, "propertyRow", "id", "propertyElement")
	elseif source:filter(".PropertyRow"):size() > 0 then
		process_property_object(source, parent_node, "calledDiagram", "id", "propertyElement")
	end
end

function process_property_object(source, parent_node, role, attr_name, role_from_tree_node)
	source:find("/" .. role):each(function(obj)
		local val = obj:attr_e(attr_name)
		local first_respondent = obj:attr("isFirstRespondent") 
		if first_respondent ~= nil and first_respondent ~= "false" then
			val = val .. "(focused)"
		end
		local parent = d.add_tree_node(parent_node, "parentNode", {id = role, text = val, expanded = "true"}):link(role_from_tree_node, obj)
		parent:find("/" .. role_from_tree_node)
		make_diagram_children(obj, parent)
	end)	
end

function refresh_property_element_tree_node()
	local ev = lQuery("D#Event")
	local prop_tree = d.get_component_by_id("property_tree")
	local selected_node = prop_tree:find("/selected")
	local attr, val = cu.get_event_source_attrs("text")
	selected_node:attr({text = val})
	utilities.refresh_form_component(prop_tree)
	d.delete_event(ev)
end

function set_first_respondent()
	local prop_tree = d.get_component_by_id("property_tree")
	local selected_node = prop_tree:find("/selected")
	local prop_row = selected_node:find("/propertyElement")
	local check_box, ev = cu.get_event_source()
	log_configurator_field("FirstRespondent", {ObjectType = utilities.get_class_name(prop_row), isFirstRespondent = check_box:attr("checked")})
	if ev:size() == 1 then
		if check_box:attr("checked") == "true" then
			local prop_parent = prop_row:find("/propertyDiagram")
			if prop_parent:is_empty() then
				prop_parent = prop_row:find("/propertyTab")		
			end
			local focused_row = prop_parent:find("/propertyRow[isFirstRespondent = true]")
			if focused_row:id() ~= prop_row:id() then
				focused_row:attr({isFirstRespondent = "false"})
					:find("/treeNode"):attr({text = focused_row:attr("id")})
				prop_row:attr({isFirstRespondent = "true"})
				selected_node:attr({text = prop_row:attr("id") .. "(focused)"})
			end
		else
			prop_row:attr({isFirstRespondent = "false"})
			selected_node:attr({text = prop_row:attr("id")})
		end
		utilities.refresh_form_component(prop_tree)
	end
	d.delete_event()
end

function build_translet_box(translet_group, is_refresh_needed)
	if translet_group == nil then
		translet_group = d.get_component_by_id("dialog_translet_box")
	end
	translet_group:find("/component"):delete()
	local group_box = d.get_component_by_id("dialog_properties_box")
	local tree = d.get_component_by_id("property_tree")
	local selected_node = tree:find("/selected")
	local prop_elem = selected_node:find("/propertyElement")
	if prop_elem:filter(".PropertyDiagram"):is_not_empty() or selected_node:is_empty() then
		if selected_node:is_empty() then
			prop_elem = tree:find("/treeNode"):find("/propertyElement")
		end
		add_dialog_translet_field(prop_elem, translet_group, "onOpen", "onOpen")
		add_dialog_translet_field(prop_elem, translet_group, "onClose", "onClose")
		group_box:attr({caption = "Form Properties"})
	elseif prop_elem:filter(".PropertyTab"):is_not_empty() then
		add_dialog_translet_field(prop_elem, translet_group, "onShow", "onShow")
		group_box:attr({caption = "Tab Properties"})
	elseif prop_elem:filter(".PropertyRow"):is_not_empty() then
		add_dialog_translet_field(prop_elem, translet_group, "onFocusLost", "onFocusLost")
		add_dialog_translet_field(prop_elem, translet_group, "onChange", "onChange")
		add_dialog_translet_field(prop_elem, translet_group, "isReadOnly", "procIsReadOnly")
		--if prop_elem:attr("rowType") == "ComboBox" then
		--	add_dialog_translet_field(prop_elem, translet_group, "onDropDown", "onDropDown")
		--end
		if prop_elem:attr("rowType") == "TextArea+DBTree" then
			add_dialog_translet_field(prop_elem, translet_group, "onClick", "Click")
		end
		group_box:attr({caption = "Row Properties"})

	end
	local height = d.get_component_by_id("height"):attr({text = prop_elem:attr_e("height")})
	local width = d.get_component_by_id("width"):attr({text = prop_elem:attr_e("width")})
	local name_field = d.get_component_by_id("prop_elem_name"):attr({text = prop_elem:attr("id")})
	if is_refresh_needed then
		--utilities.refresh_form_component(name_field)
		--utilities.refresh_form_component(height)
		--utilities.refresh_form_component(width)
		utilities.refresh_form_component(translet_group)
		utilities.refresh_form_component(group_box)
	end
end

function add_dialog_translet_field(prop_elem, container, caption, attr_name)
	local handler = prop_elem:find("/propertyEventHandler[eventType = " .. attr_name .. "]")
	return d.add_row_labeled_field(container, {caption = caption}, {id = attr_name, text = handler:attr_e("procedureName")}, 
	{id = "row_" .. attr_name}, "D#InputField", {FocusLost = "lua.configurator.dialog.update_prop_elem_handler"})
end

function update_prop_elem_handler()
	local tree = d.get_component_by_id("property_tree")
	local selected_node = tree:find("/selected")
	local prop_elem = selected_node:find("/propertyElement")
	local event_type, proc_name = cu.get_event_source_attrs("text")
	log_configurator_field("PopUpElement", {ObjectType = utilities.get_class_name(prop_elem), [event_type] = proc_name})
	local handler = prop_elem:find("/propertyEventHandler[eventType = " .. event_type .. "]")
	if proc_name ~= "" then
		if handler:is_empty() then
			prop_elem:link("propertyEventHandler", lQuery.create("PropertyEventHandler", {eventType = event_type, procedureName = proc_name}))
		else
			handler:attr({procedureName = proc_name})
		end
	else
		handler:delete()
	end
end

function set_is_read_only()
	local prop_tree = d.get_component_by_id("property_tree")
	local selected_node = prop_tree:find("/selected")
	local prop_row = selected_node:find("/propertyElement")
	local check_box, ev = cu.get_event_source()
	if ev:size() == 1 then
		prop_row:attr({isReadOnly = check_box:attr("checked")})
	end
	log_configurator_field("readOnly", {ObjectType = utilities.get_class_name(prop_row), isReadOnly = check_box:attr("checked")})
	d.delete_event()
end

function set_alignment()
	local prop_tree = d.get_component_by_id("property_tree")
	local selected_node = prop_tree:find("/selected")
	local prop_diagram = selected_node:find("/propertyDiagram")
	if prop_diagram:is_not_empty() then
		prop_diagram:attr(cu.get_event_source_attrs("text"))
	end
end

function get_alignment_options()
	cu.add_configurator_comboBox({"Left", "Center", "Right"})
end

function rename_tab(prop_elem, val)
	local tab = d.get_component_by_id("Tree"):find("/selected/type/propertyRow/propertyTab")
	if prop_elem:id() == tab:id() then
		local row = d.get_component_by_id("row_id")
		local field = row:find(":has(/component[id = 'label_box']/component[caption = 'Tab'])"):find("/component/component[id = 'id']")
		field:attr({text = val})
		utilities.refresh_form_component(field)
	end
end

function update_property_element_name()
	local ev = lQuery("D#Event")
	local prop_tree = d.get_component_by_id("property_tree")
	local selected_node = prop_tree:find("/selected")
	local prop_elem = selected_node:find("/propertyElement")
	local attr, val = cu.get_event_source_attrs("text")
	prop_elem:attr({id = val})
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(prop_elem), id = val})
	d.delete_event(ev)
end

function update_property_element_size()
	local ev = lQuery("D#Event")
	local prop_tree = d.get_component_by_id("property_tree")
	local selected_node = prop_tree:find("/selected")
	local prop_elem = selected_node:find("/propertyElement")
	local attr, value = cu.get_event_source_attrs("text")
	prop_elem:attr({[attr] = value})
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(prop_elem), [attr] = value})
	d.delete_event(ev)
end

function check_dialog_size()
	d.check_field_value_int_and_chars({""})
end
