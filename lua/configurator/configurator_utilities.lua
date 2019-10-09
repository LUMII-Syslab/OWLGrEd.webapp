module(..., package.seeall)

require("core")
require("utilities")
require("lQuery")
d = require("dialog_utilities")
c = require("configurator.configurator")
cu = require("configurator.const.const_utilities")
report = require("reporter.report")

function get_compartment_by_id(element, id)
	return element:find("/compartment:has(/compartType[id = '" .. id .. "'])")
end

function add_default_compart_style(id, caption)
	return lQuery.create("CompartStyle", {
				id = id,
				caption = caption,
				nr = 0,
				alignment = 0,
				adjustment = 0,
				picture = "",
				picWidth = 0,
				picHeight = 0,
				picPos = 1,
				picStyle = 0,
				adornment = 0,
				lineWidth = 1,
				lineColor = 0,
				fontTypeFace = "Arial",
				fontCharSet = 1,
				fontColor = 0,
				fontSize = 9,
				fontPitch = 0,
				fontStyle = 0,
				isVisible = 1})
end

function add_default_edge_style(id, caption)
	return lQuery.create("EdgeStyle", {	
		id = id,
		caption = caption,
		shapeCode = 1,
		shapeStyle = 0,
		lineWidth = 1,
		dashLength = 0,
		breakLength = 0,
		bkgColor = 15790320,
		lineColor = 0,
		lineType = 1,
		startShapeCode = 1,
		startLineWidth = 1,
		startDashLength = 0,
		startBreakLength = 0,
		startBkgColor = 15790320,
		startLineColor = 0,
		endShapeCode = 3,
		endLineWidth = 1,
		endDashLength = 0,
		endBreakLength = 0,
		endBkgColor = 15790320,
		endLineColor = 0,
		middleShapeCode = 1,
		middleLineWidth = 1,
		middleDashLength = 0,
		middleBreakLength = 0,
		middleBkgColor = 15790320,
		middleLineColor = 0
	})
end

function add_default_node_style(id, caption)
	return lQuery.create("NodeStyle", {	
		id = id,
		caption = caption,
		shapeCode = 2,
		shapeStyle = 0,
		lineWidth = 2,
		dashLength = 0,
		breakLength = 0,
		alignment = 0,
		bkgColor = 12419151,
		lineColor = 9067831,
		picture = "",
		picWidth = 0,
		picHeight = 0,
		picPos = 1,
		picStyle = 0,
		width = 110,
		height = 45
	})
end

function add_default_port_style(id, caption)
	return lQuery.create("PortStyle", {	
		id = id,
		caption = caption,
		shapeCode = 1,
		shapeStyle = 0,
		lineWidth = 2,
		dashLength = 0,
		breakLength = 0,
		alignment = 0,
		bkgColor = 12419151,
		lineColor = 9067831,
		picture = "",
		picWidth = 0,
		picHeight = 0,
		picPos = 1,
		picStyle = 0,
		width = 20,
		height = 20
	})
end

function add_default_configurator_edge_style(id, caption, list)
	return add_default_edge_style(id, caption):attr(list)
end

function add_default_configurator_node(id, caption, color, lineColor)
	local node_style = add_default_node_style(id, caption)
	if color ~= nil then
		node_style:attr({bkgColor = color})
	end
	if lineColor ~= nil then
		node_style:attr({lineColor = lineColor})
	end
	return node_style
end

function add_default_configurator_port(id, caption, color)
	return add_default_port_style(id, caption):attr({
		bkgColor = color
	})
end

function get_elem_type_from_compartment(compart_type)
	local elem_type = compart_type:find("/elemType")
	if elem_type:size() > 0 then 
		return elem_type
	else
		return get_elem_type_from_compartment(compart_type:find("/parentCompartType"))
	end
end

function add_compartment(elem, compart_type, compart_style, attr_list)
	return lQuery.create("Compartment", attr_list)
					:link("element", elem)
					:link("compartType", compart_type)
					:link("compartStyle", compart_style)
end

function add_default_graph_diagram_style(diagram_type)
	return lQuery.create("GraphDiagramStyle", {
					id = name,
					caption = name,
					layoutMode = 0,
					layoutAlgorithm = 3,
					bkgColor = 16777215,
					screenZoom = 1000,
					printZoom = 1000,
					graphDiagramType = diagram_type
	})
end

function add_translet_to_source(source, extension_point, value)
	local translet_name, translet, _ = utilities.get_translet_by_name(source, extension_point)
	if value == "" then
		translet:delete()
	else
		if translet:is_empty() then
			cu.add_translet_to_obj_type(source, extension_point, value)
		else	
			translet:attr({procedureName = value})
		end
	end
end

function add_configurator_comboBox(items, combo_box)
	if combo_box == nil then
		combo_box = empty_comboBox()
	end	
	add_comboBox_items(combo_box, items)
end

function add_comboBox_items(combo_box, items)
	for i, item in ipairs(items) do
		combo_box:link("item", lQuery.create("D#Item", {value = item}))
	end
end

function empty_comboBox(combo_box)
	if combo_box == nil then
		combo_box = get_event_source()
	end
	remove_combo_box_items(combo_box)
return combo_box
end

function remove_combo_box_items(combo_box)
	combo_box:find("/item"):delete()
end

function log_button_press(param)
	local event = "Button"
	if type(param) == "string" then
		report.event(event, {
			Button = param
		})
	else
		report.event(event, param)
	end
end

function get_type_from_tree_node()
	local obj_type = d.get_selected_tree_node():find("/type")
	if obj_type:size() > 0 then 
		return obj_type
	else
		return d.get_component_by_id("Tree"):find("/treeNode/type ElemType")
	end
end

function add_transformation_field_with_events(container, label, field_id, object_type, event_table)
	local translet_name = object_type:find("/translet[extensionPoint = " .. field_id .. "]"):attr_e("procedureName")
	local row = d.add_row_labeled_field(container, {caption = label}, {id = field_id, text = translet_name}, {id = "row_" .. field_id}, "D#InputField", event_table)
	local button = d.add_button(row, {id = field_id .. "_button", caption = "..."}, {Click = "lua.configurator.configurator.add_specific_transformation()"})
end

function get_event_source_attrs(attr_name)
	return d.get_event_source_attrs(attr_name)
end

function get_event_source()
	local ev = lQuery("D#Event")
	local source = ev:find("/source")
	return source, ev
end

function add_input_field_function(container, label, field_id, object_type, function_name)
	return add_input_field_event_function(container, label, field_id, object_type, {FocusLost = function_name})
end

function add_input_field_event_function(container, label, field_id, object_type, event_function_table)
	return d.add_row_labeled_field(container, {caption = label}, {id = field_id, text = object_type:attr_e(field_id)}, {id = "row_" .. field_id}, "D#InputField", event_function_table)
end

function add_main_popUp_table(container)
	local table = add_main_popUp_table_header(container, "lua.configurator.configurator_utilities.process_popUpTable", "Context Menu")
	fill_popUpTable(table)
end

function add_main_popUp_table_header(container, function_name, table_name)
	return add_default_popUp_table_header(container, "main_popUp_table", function_name, table_name)
end

function fill_popUpTable(pop_up_table)
	fill_table(pop_up_table, "/popUpDiagramType/popUpElementType", {"id", "procedureName", "nr"})
end

function fill_table(table, path_to_elem, attr_table)
	local obj_type = get_type_from_tree_node()
	fill_table_from_obj(obj_type, table, path_to_elem, attr_table)
end

function add_default_popUp_table_header(container, table_id, focus_lost_function, table_name)
	--local label = d.add_component(container, {id = "table_id", caption = table_name}, "D#Label")
	local group_box = d.add_component(container, {id = "table_group_box", caption = table_name}, "D#GroupBox")
	local table = d.add_component(group_box, {id = table_id, editable = "true", insertButtonCaption = "Add", deleteButtonCaption = "Delete"}, "D#VTable") 
	d.add_event_handlers(table, {FocusLost = focus_lost_function})
	local name_column = d.add_columnType(table, {caption = "ItemName", editable = "true", horizontalAlignment = -1}, "D#TextBox", {editable = "true"})
	local item_column = d.add_columnType(table, {caption = "Action/Transformation", editable = "true", horizontalAlignment = -1}, "D#ComboBox", {editable = "true"}, {DropDown = "lua.configurator.configurator_utilities.default_transformation_names"})
	local nr_column = d.add_columnType(table, {caption = "Nr", editable = "true", horizontalAlignment = -1}, "D#TextBox", {editable = "true"})
	--local should_be_included = d.add_columnType(table, {caption = "ShouldBeIncluded", editable = "true", horizontalAlignment = -1}, "D#TextBox", {editable = "true"})
return table
end

function default_transformation_names()
	add_configurator_comboBox({"Cut", "Copy", "Delete", "Paste", "Properties"})
end

function fill_table_from_obj(obj_type, table, path_to_elem, attr_table)
	obj_type:find(path_to_elem):each(function(elem)
		local row = lQuery.create("D#VTableRow"):link("vTable", table)
		for i, index in pairs(attr_table) do
			row:link("vTableCell", lQuery.create("D#VTableCell", {value = elem:attr_e(index)}))
		end
	end)
end

function add_element_key_shortcuts(container)
	return add_key_shortcuts(container, "element_key_shortcuts", "lua.configurator.configurator_utilities.process_element_shortcut_table", "KeyShortcuts")
end

function add_key_shortcuts(container, id, function_name, table_name)
	--local label = d.add_component(container, {id = "table_id", caption = table_name}, "D#Label")
	local group_box = d.add_component(container, {id = "table_id", caption = table_name}, "D#GroupBox")
	
	local table = d.add_component(group_box, {id = id, editable = "true", insertButtonCaption = "Add", deleteButtonCaption = "Delete"}, "D#VTable") 
	d.add_event_handlers(table, {FocusLost = function_name})
	local shortcut_column = d.add_columnType(table, {caption = "KeyShortcut", editable = "true", horizontalAlignment = -1}, "D#ComboBox", {editable = "true"}, {DropDown = "lua.configurator.configurator_utilities.default_keyshortcuts"})
	local transformation_column = d.add_columnType(table, {caption = "Action/Transformation", editable = "true", horizontalAlignment = -1}, "D#ComboBox", {editable = "true"}, {DropDown = "lua.configurator.configurator_utilities.default_transformation_names"})
	fill_element_key_shortcuts(table)
return table
end

function fill_element_key_shortcuts(table)
	fill_table(table, "/keyboardShortcut", {"key", "procedureName"})
end

function default_keyshortcuts()
	add_configurator_comboBox({"Ctrl X", "Ctrl C", "Ctrl V", "Delete", "Enter", "Num Enter", "Application"})
end

function process_shortcut_table_header(obj_type, role, path_to_element)
	log_table({Name = "KeyShortcuts"})
	local shortcut_table = {}
	obj_type:find(path_to_element):delete()
	get_event_source():find("/vTableRow"):each(function(row)
		local tmp_table = {}
		if row:attr_e("deleted") ~= "true" then
			row:find("/vTableCell"):each(function(cell)
				cell = lQuery(cell)
				table.insert(tmp_table, cell:attr_e("value"))
			end)
			table.insert(shortcut_table, tmp_table)
		end
	end)
	for i, row in pairs(shortcut_table) do  
		lQuery.create("KeyboardShortcut", {key = row[1], procedureName = row[2]}):link(role, obj_type)
	end
end

function process_element_shortcut_table()
	process_shortcut_table("/keyboardShortcut", "elemType")
end

function process_shortcut_table(path_to_element, role)
	local obj_type = get_type_from_tree_node()
	process_shortcut_table_header(obj_type, role, path_to_element)
end

function process_empty_diagram_key_shortcut()
	process_shortcut_table_header(utilities.current_diagram():find("/target_type"), "eType", "/eKeyboardShortcut")
end

function process_collection_diagram_key_shortcut()
	process_shortcut_table_header(utilities.current_diagram():find("/target_type"), "cType", "/cKeyboardShortcut")
end

function process_diagram_popUpTable(path, role)
	local diagram_type = utilities.current_diagram():find("/target_type")
	process_popUpTable_cells(diagram_type:find(path), diagram_type, role)
end

function process_popUpTable()
	local obj_type = get_type_from_tree_node()
	process_popUpTable_cells(obj_type:find("/popUpDiagramType"), obj_type, "elemType")
end

function process_popUpTable_cells(popUpDiagramType, obj_type, role)
	log_table({Name = "Context Menu"})
	if popUpDiagramType:size() > 0 then
		popUpDiagramType:find("/popUpElementType"):delete()
		popUpDiagramType:delete()
	end
	local popUpDiagramType = lQuery.create("PopUpDiagramType"):link(role, obj_type)
	add_popUpDiagram_type_from_table(popUpDiagramType, get_event_source())
end

function add_popUpDiagram_type_from_table(popUpDiagramType, event_source)
	local popUp_table = {}
	event_source:find("/vTableRow"):each(function(row)
		local tmp_table = {}
		if row:attr_e("deleted") ~= "true" then
			row:find("/vTableCell"):each(function(cell)
				table.insert(tmp_table, cell:attr_e("value"))
			end)
			table.insert(popUp_table, tmp_table)
		end
	end)
	table.sort(popUp_table, sort_context_menu_table_function)
	for _, row in ipairs(popUp_table) do
		lQuery.create("PopUpElementType", {id = row[1], caption = row[1], visibility = "true", nr = row[3], procedureName = row[2]}):link("popUpDiagramType", popUpDiagramType)
	end
end

function sort_context_menu_table_function(row1, row2)
	local nr1 = tonumber(row1[3])
	local nr2 = tonumber(row2[3])
	if nr1 ~= nil and nr2 ~= nil then
		if nr1 < nr2 then
			return row2
		end
	end
end

function log_table(list)
	report.event("Table", list)
end

function is_dialog_button_enabled(object_type)
	if object_type:find("/propertyDiagram"):size() > 0 then
		return "true"
	else
		return "false"
	end
end

function get_selected_obj_type()
	return get_selected_type()
end

function get_selected_type()
	return d.get_selected_tree_node():find("/type")
end

function active_tab()
	return lQuery("D#TabContainer:has([id = 'tab_container'])/activeTab")
end

function make_combo_box_item_table(items, attr_name, item_table)
	if item_table == nil then
		item_table = {}
	end
	items:each(function(item)
		table.insert(item_table, item:attr(attr_name))
	end)
	return item_table
end

function add_lQuery_configurator_comboBox(item_table, combo_box)
	if combo_box == nil then
		combo_box = get_event_source()
	end
	d.clear_list_box(combo_box)
	d.fill_list_combo_box(combo_box, item_table)
	return combo_box
end

function add_compart_type(node_name)
	return lQuery.create("CompartType", { 
				id = node_name,
				caption = node_name,
				startValue = "",
				pattern = "a-zA-Z0-9-_",
				nr = 0,
				isStereotypable = "false",
				isStereotype = "false",
				isMultiple = "false",
				isHint = "false",
				toBeInvisible = "false",
				isEssential = "true",
				is_occurrence_compartment = "false",
				isDiagramName = "false",
				isGroup = "false"})
end

function add_checkBox_field_function(container, label, field_id, object_type, function_list)
	return d.add_row_labeled_field(container, {caption = label}, {id = field_id, checked = object_type:attr(field_id)}, {id = "row_" .. field_id}, "D#CheckBox", function_list)
end

function add_command_without_diagram(elem, command_name, attr_table)
	attr_table["element"] = elem
	attr_table["graphDiagram"] = elem:find("/graphDiagram")
	utilities.execute_cmd(command_name, attr_table)
end

function get_name_compart(elem)
	return elem:find("/compartment:has(/compartType[id = 'AS#Name'])")
end

function get_palette_components()
	local palette_name = lQuery("D#Component[id = 'row_caption']:has(/component/component[caption = 'Palette Element Name'])/component/component"):attr({text = ""})
	local palette_nr = lQuery("D#Component[id = 'row_nr']/component/component[id = 'nr']"):attr({text = ""})
	local palette_image = lQuery("D#Component[id = 'row_picture']/component/component[id = 'picture']"):attr({fileName = ""})
return palette_name, palette_nr, palette_image
end

