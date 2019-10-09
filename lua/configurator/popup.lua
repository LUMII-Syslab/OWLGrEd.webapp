module(..., package.seeall)

d = require("dialog_utilities")
cu = require("configurator.configurator_utilities")
const_utilities = require("configurator.const.const_utilities")
report = require("reporter.report")


-- Add Toolar

function add_diagram_toolbar()
	local form = d.add_form({id = "form", caption = "Toolbar", minimumWidth = 455, minimumHeight = 150, maximumHeight = 300})
	local toolbar_table = add_toolbar(form, "toolbar", "lua.configurator.popup.process_diagram_toolbar")
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
		local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
	cu.fill_table_from_obj(utilities.current_diagram():find("/target_type/toolbarType"), toolbar_table, "/toolbarElementType", {"caption", "picture", "procedureName"})
	d.show_form(form)
end

function add_toolbar(container, id, function_name, table_name)
	local table = d.add_component(container, {id = id, editable = "true", insertButtonCaption = "Add", deleteButtonCaption = "Delete"}, "D#VTable") 
	d.add_event_handlers(table, {FocusLost = function_name})
	local name_column = d.add_columnType(table, {caption = "Name", editable = "true", horizontalAlignment = -1}, "D#TextBox", {editable = "true"})
	local picture_column = d.add_columnType(table, {caption = "Picture", editable = "true", horizontalAlignment = -1}, "D#TextBox", {editable = "true"})
	local procedure_column = d.add_columnType(table, {caption = "Transformation", editable = "true", horizontalAlignment = -1}, "D#TextBox", {editable = "true"})
return table:attr({minimumWidth = 150, minimumHeight = 150})
end

function process_diagram_toolbar()
	local toolbar_table = {}
	local diagram_type = utilities.current_diagram():find("/target_type")
	local toolbar = diagram_type:find("/toolbarType")
	if toolbar:size() > 0 then
		toolbar:find("/toolbarElementType"):delete()
	else
		toolbar = lQuery.create("ToolbarType"):link("graphDiagramType", diagram_type)
	end
	cu.get_event_source():find("/vTableRow"):each(function(row)
		local tmp_table = {}
		if row:attr_e("deleted") ~= "true" then
			row:find("/vTableCell"):each(function(cell)
				cell = lQuery(cell)
				table.insert(tmp_table, cell:attr_e("value"))
			end)
			table.insert(toolbar_table, tmp_table)
		end
	end)
	for i, row in pairs(toolbar_table) do  
		lQuery.create("ToolbarElementType", {id = row[1], caption = row[1], picture = row[2], procedureName = row[3]}):link("toolbarType", toolbar)
	end
	make_toolbar(diagram_type)
	utilities.execute_cmd("OkCmd")
end

function make_toolbar(diagram_type)
	local diagrams = diagram_type:find("/graphDiagram")
	local toolbar = diagrams:find("/toolbar")
	toolbar:find("/toolbarElement"):delete()
	toolbar:delete()
	diagrams:each(function(diagram)	
		utilities.add_toolbar_to_diagram(diagram, diagram_type)
		utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
	end)
end


-- Add Context Menu

function add_diagram_popUp()
	local current_diagram = utilities.current_diagram()
	local diagram_type = current_diagram:find("/target_type")
	local form = d.add_form({id = "form", caption = "Diagram Context Menus", minimumWidth = 455, minimumHeight = 150, maximumHeight = 300})
	local tab_container = d.add_component(form, {id = "tab_container"}, "D#TabContainer")
	local empty_tab = d.add_component(tab_container, {id = "procDynamicPopUpE", caption = "Diagram", minimumWidth = 420, minimumHeight = 250}, "D#Tab")
	local empty_collection_translet = diagram_type:find("/translet[extensionPoint = 'procDynamicPopUpE']")
	cu.add_input_field_event_function(empty_tab, "Dynamic Context Menu", "procedureName", empty_collection_translet, {FocusLost = "lua.configurator.popup.set_dynamic_pop_up_dgr"})

	local collection_tab = d.add_component(tab_container, {id = "procDynamicPopUpC", caption = "Collection", minimumWidth = 300, minimumHeight = 250}, "D#Tab")
	local collection_translet = diagram_type:find("/translet[extensionPoint = 'procDynamicPopUpC']")
	cu.add_input_field_event_function(collection_tab, "Dynamic Context Menu", "procedureName", collection_translet, {FocusLost = "lua.configurator.popup.set_dynamic_pop_up_dgr"})

	local empty_table = cu.add_main_popUp_table_header(empty_tab, "lua.configurator.popup.process_empty_diagram_popUpTable", "Static Context Menu")
	local collection_table = cu.add_main_popUp_table_header(collection_tab, "lua.configurator.popup.process_collection_diagram_popUpTable", "Static Context Menu")

	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
		local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
	cu.fill_table_from_obj(current_diagram, collection_table, "/target_type/rClickCollection/popUpElementType", {"id", "procedureName", "nr"})
	cu.fill_table_from_obj(current_diagram, empty_table, "/target_type/rClickEmpty/popUpElementType", {"id", "procedureName", "nr"})
	d.show_form(form)
end

function process_empty_diagram_popUpTable()
	cu.process_diagram_popUpTable("/rClickEmpty", "eType")
end

function process_collection_diagram_popUpTable()
	cu.process_diagram_popUpTable("/rClickCollection", "cType")
end

function set_dynamic_pop_up_dgr()
	local attr, val = cu.get_event_source_attrs("text")
	local active_tab_name = cu.get_event_source():find("/container/container/container"):attr("id")
	local diagram_type = utilities.current_diagram():find("/target_type")
	local translet = diagram_type:find("/translet[extensionPoint = '" .. active_tab_name .. "']")
	if val == "" then
		translet:delete()
	else
		if translet:is_empty() then
			const_utilities.add_translet_to_obj_type(diagram_type, active_tab_name, val)
		else
			translet:attr({procedureName = val})
		end
	end
end


-- Key Shortcuts

function add_diagram_key_shortcuts()
	local form = d.add_form({id = "form", caption = "Diagram Key Shortcuts", minimumWidth = 455, minimumHeight = 150, maximumHeight = 300})
	local tab_container = d.add_component(form, {id = "tab_container"}, "D#TabContainer")
	local empty_tab = d.add_component(tab_container, {id = "diagram_tab", caption = "Diagram", minimumWidth = 420, minimumHeight = 250}, "D#Tab")
	local collection_tab = d.add_component(tab_container, {id = "collection_tab", caption = "Collection", minimumWidth = 300, minimumHeight = 250}, "D#Tab")

	local empty_table = cu.add_key_shortcuts(empty_tab, "element_key_shortcuts", "lua.configurator.configurator_utilities.process_empty_diagram_key_shortcut", "")
	local collection_table = cu.add_key_shortcuts(collection_tab, "element_key_shortcuts", "lua.configurator.configurator_utilities.process_collection_diagram_key_shortcut", "")

	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
		local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
	cu.fill_table_from_obj(utilities.current_diagram(), empty_table, "/target_type/eKeyboardShortcut", {"key", "procedureName"})
	cu.fill_table_from_obj(utilities.current_diagram(), collection_table, "/target_type/cKeyboardShortcut", {"key", "procedureName"})
	d.show_form(form)
end

-- Diagram Style

function diagram_style()
	local form = d.add_form({id = "base_form", caption = "Diagram Styles", minimumWidth = 300, minimumHeight = 100})
	local row = d.add_component(form, {id = "list_box_edit_button_row", horizontalAlignment = 0, verticalAlignment = -1}, "D#HorizontalBox")
		local list_box = d.add_component(row, {id = "diagram_style_list_box", horizontalAlignment = 0, minimumWidth = 220, minimumHeight = 150}, "D#ListBox")
		--d.add_event_handlers(list_box, {Change = "lua.configurator.configurator.change_style()"})
		local vertical_row = d.add_component(row, {id = "vertical_box", verticalAlignment = -1}, "D#VerticalBox")
		local edit_button = d.add_button(vertical_row, {id = "edit_style_button", caption = "Style"}, {Click = "lua.configurator.popup.edit_diagram_style()"})
		--local edit_name_button = d.add_button(vertical_row, {id = "edit_style_name_button", caption = "Rename"}, {Click = "lua.configurator.configurator.edit_diagram_style_name()"})
	local button_row = d.add_component(form, {id = "add_delete_buttons", horizontalAlignment = -1}, "D#HorizontalBox")
		local add_button = d.add_button(button_row, {id = "add_style_button", caption = "Add"}, {Click = "lua.configurator.popup.add_diagram_style()"})
		local delete_button = d.add_button(button_row, {id = "delete_style_button", caption = "Delete"}, {Click = "lua.configurator.popup.delete_diagram_style()"})
		local close_row = d.add_component(button_row, {id = "add_delete_buttons", horizontalAlignment = 1}, "D#HorizontalBox")
			local close_button = d.add_button(close_row, {id = "close_button", caption = "Close"}, {Click = "lua.dialog_utilities.close_form()"})
	fill_diagram_style_list_box(list_box)
	if list_box:find("/item"):size() == 1 then
		delete_button:attr({enabled = "false"})
	end
	d.show_form(form)
end

function fill_diagram_style_list_box(list_box)
	utilities.current_diagram():find("/target_type"):find("/graphDiagramStyle"):each(function(diagram_style)
		list_box:link("item", lQuery.create("D#Item", {value = diagram_style:attr("id")}):link("style", diagram_style))
	end)
	list_box:link("selected", list_box:find("/item:first()"))
end

function add_diagram_style()
	local diagram_type = utilities.current_diagram():find("/target_type")
	local name = const_utilities.generate_unique_id("Style", diagram_type, "graphDiagramStyle")
	local diagram_style = cu.add_default_graph_diagram_style(diagram_type)
	diagram_style:attr({id = name, caption = name})
	local form = build_style_extra_form(diagram_style)
	local list_box = lQuery("D#ListBox[id = 'diagram_style_list_box']")
	local item = lQuery.create("D#Item", {value = name}):link("style", diagram_style)
	list_box:remove_link("selected")
		:link("item", item)
		:link("selected", item)
	utilities.refresh_form_component(list_box)
	if diagram_type:find("/graphDiagramStyle"):size() > 1 then
		utilities.refresh_form_component(d.get_component_by_id("delete_style_button"):attr({enabled = "true"}))
	end
	d.show_form(form)
--vajag refresot delete pogu
end

function edit_diagram_style()
	local diagram_style = get_selected_diagram_style()
	local form = build_style_extra_form(diagram_style)
	d.show_form(form)
end

function build_style_extra_form(diagram_style)
	local form = d.add_form({id = "extra_form", caption = "Diagram Style", minimumWidth = 300, minimumHeight = 200})
		add_diagram_style_field_text(form, "Name", "id", diagram_style)
		add_diagram_style_field(form, "Layout Mode", "layoutMode", diagram_style)
		add_diagram_style_field(form, "Layout Algorithm", "layoutAlgorithm", diagram_style)
		add_diagram_style_field(form, "Background Color", "bkgColor", diagram_style)
		add_diagram_style_field(form, "Screen Zoom", "screenZoom", diagram_style)
		add_diagram_style_field(form, "Print Zoom", "printZoom", diagram_style)
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")	
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.popup.close_diagram_style_extra_form()"}):link("defaultButtonForm", form)
	d.delete_event()
	return form
end

function add_style_box()
	local active_elem = utilities.active_elements()
	local diagram = utilities.current_diagram()
	local style_box = core.add_node(lQuery("NodeType[id = 'BoxStyle']"), diagram)
	local default_style = style_box:find("/elemStyle")
	default_style:remove_link("element")
	core.add_edge(lQuery("EdgeType[id = 'Box_Style_Line']"), active_elem, style_box, diagram)
	local new_style = lQuery.create("NodeStyle")
				:link("elemType", active_elem:find("/target_type"))
				:link("element", style_box)
				:copy_attrs_from(default_style)
	utilities.activate_element(style_box)	
end

function close_diagram_style_extra_form()
	d.close_form()
	d.delete_event()
end

function delete_diagram_style()
	local list_box = lQuery("D#ListBox[id = 'diagram_style_list_box']")
	local selected_item = list_box:find("/selected")
	local diagram_style = get_selected_diagram_style()
	local diagram_type = diagram_style:find("/graphDiagramType")
	diagram_style:delete()
	selected_item:delete()
	list_box:link("selected", list_box:find("/item:last()"))
	utilities.refresh_form_component(list_box)
	if diagram_type:find("/graphDiagramStyle"):size() == 1 then
		local delete_button = cu.get_event_source()
		utilities.refresh_form_component(delete_button:attr({enabled = "false"}))	
	end
	d.delete_event()
end

function get_selected_diagram_style()
	return lQuery("D#ListBox[id = 'diagram_style_list_box']"):find("/selected/style")
end

function add_diagram_style_field(container, label, field_id, object_type)
	cu.add_input_field_event_function(container, label, field_id, object_type, {FocusLost = "lua.configurator.popup.update_diagram_style_input_field", Change = "lua.configurator.configurator.check_field_value"})
end

function add_diagram_style_field_text(container, label, field_id, object_type)
	cu.add_input_field_event_function(container, label, field_id, object_type, {FocusLost = "lua.configurator.popup.update_diagram_style_input_field"})
end

function update_diagram_style_input_field()
	local attr, value = cu.get_event_source_attrs("text")
	local diagram_style = get_selected_diagram_style()
	diagram_style:attr({[attr] = value})
	if attr == "id" then
		local list_box = lQuery("D#ListBox[id = 'diagram_style_list_box']")
		list_box:find("/selected"):attr({value = value})
		utilities.refresh_form_component(list_box)
	end
	d.delete_event()
end

-- Generate instances

function generate_instances(source_diagram_type)
	local instance_diagram_type = lQuery("GraphDiagramType[id = 'MMInstances']")
	--instance_diagram_type:find("/graphDiagram"):delete()
	local diagram = utilities.add_graph_diagram_to_graph_diagram_type("Instances", instance_diagram_type)
	--local diagram = cu.add_graph_diagram("Test"):link("graphDiagramType", instance_diagram_type)
	make_MM_instances(diagram, instance_diagram_type, source_diagram_type)
	utilities.execute_cmd("ActiveDgrCmd", {graphDiagram = diagram})
	utilities.execute_cmd("OkCmd")
end

function make_MM_instances(diagram, instance_diagram_type, source_dgr_type)
	local instance_table = {}
	instance_table["Node"] = {}
	instance_table["Edge"] = {}
	if source_dgr_type == nil then
		source_dgr_type = utilities.current_diagram():find("/target_type")
	end
	--local source_dgr_type = source_diagram:find("/target_type")
		local diagram_type_node = add_MM_instance(source_dgr_type, diagram, instance_table["Node"])
		traverse_elem_childs_by_each_in_two_levels(source_dgr_type, "/rClickEmpty", "/popUpElementType", diagram, diagram_type_node, instance_table, "rClickEmpty", "popUpElementType")
		traverse_elem_childs_by_each_in_two_levels(source_dgr_type, "/rClickCollection", "/popUpElementType", diagram, diagram_type_node, instance_table, "rClickCollection", "popUpElementType")
		traverse_elem_childs_by_each_in_two_levels(source_dgr_type, "/toolbarType", "/toolbarElementType", diagram, diagram_type_node, instance_table, "toolbar", "tool")
		traverse_elem_childs_by_each(source_dgr_type, "/eKeyboardShortcut", diagram, diagram_type_node, add_MM_composition, instance_table, "eKeyboardShortcut")
		traverse_elem_childs_by_each(source_dgr_type, "/cKeyboardShortcut", diagram, diagram_type_node, add_MM_composition, instance_table, "cKeyboardShortcut")
		traverse_elem_childs_by_each(source_dgr_type, "/graphDiagramStyle", diagram, diagram_type_node, add_MM_link, instance_table, "graphDiagramStyle", "graphDiagramType")
		local palette_node = process_palette(source_dgr_type, diagram, diagram_type_node, instance_table)
		process_elem_types(source_dgr_type, diagram_type_node, palette_node, diagram, instance_table)
		for _, edge in pairs(instance_table["Edge"]) do
			local edge_type = edge["link"]
			local edge1 = core.add_edge(edge_type, edge["source"], edge["target"], diagram)
			core.add_compartment(edge_type:find("/compartType[id = 'DirectRole']"), edge1, edge["inverseRole"])
			core.add_compartment(edge_type:find("/compartType[id = 'InverseRole']"), edge1, edge["directRole"])
		end
end

function process_palette(source_dgr_type, diagram, diagram_type_node, instance_table)
	local palette = source_dgr_type:find("/paletteType")
	if palette:size() > 0 then
		local palette_node = add_MM_instance(palette, diagram, instance_table["Node"])
		add_MM_link(diagram_type_node, palette_node, diagram, instance_table["Edge"], "paletteElement")
		return palette_node
	end
end

function process_elem_types(source_dgr_type, diagram_type_node, palette_node, diagram, instance_table)
	source_dgr_type:find("/elemType"):each(function(elem_type)
		local elem_type_node = add_MM_instance(elem_type, diagram, instance_table["Node"])
		add_MM_composition(elem_type_node, diagram_type_node, diagram, instance_table["Edge"], "elemType")
		traverse_elem_childs_by_each(elem_type, "/elemStyle", diagram, elem_type_node, add_MM_link, instance_table, "elemStyle", "elemType")
		traverse_compart_types(elem_type, diagram, elem_type_node, instance_table)
		traverse_elem_childs_by_each_in_two_levels(elem_type, "/popUpDiagramType", "/popUpElementType", diagram, elem_type_node, instance_table, "popUpDiagramType", "popUpElementType")
		traverse_elem_childs_by_each(elem_type, "/keyboardShortcut", diagram, elem_type_node, add_MM_composition, instance_table, "keyboardShortcut")
		traverse_elem_childs_by_each(elem_type, "/translet", diagram, elem_type_node, add_MM_composition, instance_table, "translet")
		process_palette_element(elem_type, palette_node, elem_type_node, diagram, instance_table)
		process_property_diagram(elem_type, elem_type_node, diagtram, instance_table)
		elem_type:find("/subtype"):each(function(sub_type)
			--print("in each supertype")
			add_MM_link(elem_type_node, instance_table["Node"][sub_type:id()], diagram, instance_table["Edge"], "supertype", "subtype")

			--traverse_elem_childs_by_each(elem_type, "/supertype", diagram, elem_type_node, add_MM_link, instance_table, "supertype", "subtype")
		end)
		if elem_type:filter(".EdgeType"):is_not_empty() then
			local start = elem_type:find("/start")
			local end_ = elem_type:find("/end")
			add_MM_link(elem_type_node, instance_table["Node"][start:id()], diagram, instance_table["Edge"], "eStart", "start")
			add_MM_link(elem_type_node, instance_table["Node"][end_:id()], diagram, instance_table["Edge"], "eEnd", "end")
		end
	end)
end

function process_property_diagram(elem_type, elem_type_node, diagram, instance_table)
	local prop_diagram = elem_type:find("/propertyDiagram")
	if prop_diagram:size() > 0 then
		local prop_dgr_node = add_MM_instance(prop_diagram, diagram, instance_table["Node"])
		add_MM_link(elem_type_node, prop_dgr_node, diagram, instance_table["Edge"], "elemType", "propertyDiagram")
		process_property_diagram_childs(prop_diagram, prop_dgr_node, diagram, instance_table)
	end
end

function process_property_diagram_childs(prop_diagram, prop_dgr_node, diagram, instance_table)
	process_row_from_parent(prop_diagram, prop_dgr_node, diagram, instance_table)
end

function process_row_from_parent(row_parent, parent_node, diagram, instance_table)
	local row = row_parent:find("/propertyRow")
	if row:size() > 0 then
		process_child(row, parent_node, diagram, instance_table)
	else
		local tab = row_parent:find("/propertyTab")
		if tab:size() > 0 then		
			tab:each(function(obj)
				local tab_node = add_MM_instance(obj, diagram, instance_table["Node"])
				add_MM_composition(tab_node, parent_node, diagram, instance_table["Edge"])
				process_row_from_parent(obj, tab_node, diagram, instance_table)
			end)
		end
	end
end

function process_child(child, start_node, diagram, instance_table)
	child:each(function(obj)
		local obj_node = add_MM_instance(obj, diagram, instance_table["Node"])
		local compart_type_node = instance_table["Node"][obj:find("/compartType"):id()]
		add_MM_composition(obj_node, start_node, diagram, instance_table["Edge"], "propertyRow")
		add_MM_link(compart_type_node, obj_node, diagram, instance_table["Edge"], "compartType", "propertyRow")
	end)
end

function process_palette_element(elem_type, palette_node, elem_type_node, diagram, instance_table)
	local palette_elem = elem_type:find("/paletteElementType")
--vajaga parbaudi, vai viens paletes elements neatbilst vairakiem elementa tipiem(EdgeType gadîjums)
	if palette_elem:size() > 0 then
		local palette_elem_node = add_MM_instance(palette_elem, diagram, instance_table["Node"])
		add_MM_link(elem_type_node, palette_elem_node, diagram, instance_table["Edge"], "elemType", "paletteElementType")
		add_MM_composition(palette_elem_node, palette_node, diagram, instance_table["Edge"], "paletteElementType")
	end
end

function traverse_compart_types(elem_type, diagram, elem_type_node, instance_table, role1)
	local instance_type, name_compart_type, value_compart_type = get_MM_instance_types()
	if elem_type:filter(".CompartType"):size() > 0 then
		elem_type:find("/subCompartType"):each(function(compart_type)
			process_compart_types(compart_type, diagram, elem_type_node, instance_table, role1)
		end)
	else
		elem_type:find("/compartType"):each(function(compart_type)
			process_compart_types(compart_type, diagram, elem_type_node, instance_table, role1)
		end)
	end
end

function process_compart_types(compart_type, diagram, elem_type_node, instance_table)
	local compart_node = add_MM_instance(compart_type, diagram, instance_table["Node"])
	add_MM_composition(compart_node, elem_type_node, diagram, instance_table["Edge"], "compartType")
	traverse_compart_types(compart_type, diagram, compart_node, instance_table, "subCompartType")
	traverse_elem_childs_by_each(compart_type, "/compartStyle", diagram, compart_node, add_MM_link, instance_table, "compartStyle", "compartType")
	process_choice_items(compart_node, compart_type, diagram, instance_table)
end

function process_choice_items(compart_node, compart_type, diagram, instance_table)
	compart_type:find("/choiceItem"):each(function(choice_item)
		local choice_item_node = add_MM_instance(choice_item, diagram, instance_table["Node"])
		add_MM_composition(choice_item_node, compart_node, diagram, instance_table["Edge"], "choiceItem")
		local notation = choice_item:find("/notation")
		if notation:is_not_empty() then
			local notation_node = add_MM_instance(notation, diagram, instance_table["Node"])
			add_MM_link(choice_item_node, notation_node, diagram, instance_table["Edge"], "choiceItem", "notation")
		end
		choice_item:find("/tag"):each(function(tag_compart)
			add_MM_composition(instance_table["Node"][tag_compart:id()], choice_item_node, diagram, instance_table["Edge"], "tag")
		end)
		choice_item:find("/compartStyleByChoiceItem"):each(function(compart_style)
			add_MM_link(instance_table["Node"][compart_style:id()], choice_item_node, diagram, instance_table["Edge"], "compartStyleByChoiceItem")
		end)
		choice_item:find("/elemStyleByChoiceItem"):each(function(elem_style)
			add_MM_link(instance_table["Node"][elem_style:id()], choice_item_node, diagram, instance_table["Edge"], "elemStyleByChoiceItem", "choiceItem")
		end)
	end)
end

function traverse_elem_childs_by_each_in_two_levels(elem_type, path, path_to_child, diagram, start_node, instance_table, role1, role2)
	elem_type:find(path):each(function(item)
		local middle_node = add_MM_instance(item, diagram, instance_table["Node"])
		add_MM_composition(middle_node, start_node, diagram, instance_table["Edge"], role1)
		traverse_elem_childs_by_each(item, path_to_child, diagram, middle_node, add_MM_composition, instance_table, role2)
	end)
end

function traverse_elem_childs_by_each(elem_type, path, diagram, start_node, link_function, instance_table, role1, role2)
	elem_type:find(path):each(function(item)
		local end_node = add_MM_instance(item, diagram, instance_table["Node"])
		link_function(end_node, start_node, diagram, instance_table["Edge"], role1, role2)
	end)
end

function add_MM_instance(source_dgr_type, diagram, node_instance_table)
	local instance_type, name_compart_type, value_compart_type = get_MM_instance_types()
	local node = core.add_node(instance_type, diagram)
		local obj_type_value = utilities.get_class_name(source_dgr_type)
		core.add_compart(name_compart_type, node, obj_type_value)
		local list = utilities.get_lQuery_object_attribute_list(source_dgr_type)[1]
		process_instance_attributes(list)
		core.add_compart(value_compart_type, node, utilities.concat_attr_dictionary(list, "\n"))
		node_instance_table[source_dgr_type:id()] = node
	return node
end

function get_MM_instance_types()
	local source_type = lQuery("GraphDiagramType[id = 'MMInstances']")
	local instance_type = source_type:find("/elemType[id = 'Instance']")
	local name_compart_type = instance_type:find("/compartType[id = 'Name']")
	local value_compart_type = instance_type:find("/compartType[id = 'Value']")
return instance_type, name_compart_type, value_compart_type
end

function process_instance_attributes(list)
	for i, item in pairs(list) do
		list[i] = '"' .. item .. '"'
	end
end

function get_MM_link_types(type_name)
	local link = lQuery("GraphDiagramType[id = 'MMInstances']")
	local link_type = link:find("/elemType[id = '" .. type_name .. "']")
return link_type
end

function add_MM_link(source, target, diagram, link_instance_table, direct_role, inverse_role)
	return add_MM_line_by_type("Link", source, target, diagram, link_instance_table, direct_role, inverse_role)
end

function add_MM_composition(source, target, diagram, line_instance_table, direct_role, inverse_role)
	return add_MM_line_by_type("Composition", source, target, diagram, line_instance_table, direct_role, inverse_role)
end

function add_MM_line_by_type(type_name, source, target, diagram, line_instance_table, direct_role, inverse_role)
	local link_type = get_MM_link_types(type_name)
	--local edge = core.add_edge(link_type, source, target, diagram)
		table.insert(line_instance_table, {source = source, target = target, link = link_type, directRole = direct_role, inverseRole = inverse_role})
		--local obj_type_value = ":" .. source_dgr_type:get(1):class().name
		--add_compartment(name_compart_type, node, obj_type_value)
		--local list = get_lQuery_object_attribute_list(source_dgr_type)
		--add_compartment(value_compart_type, node, utilities.concat_attr_dictionary(list[1], "\n"))
	return edge
end


-- Add Diagram Translets

function add_diagram_translets()
	local form = d.add_form({id = "form", caption = "Diagram Translets", minimumWidth = 70, minimumHeight = 50})
	local diagram_type = utilities.current_diagram():find("/target_type")
	add_diagram_type_translet_field(form, "Create Diagram", "procCreateDiagram", diagram_type)
	add_diagram_type_translet_field(form, "Delete Diagram", "procDeleteDiagram", diagram_type)
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")	
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
	d.show_form(form)
end

function add_diagram_type_translet_field(container, label, field_id, diagram_type)
	local translet_name = diagram_type:find("/translet[extensionPoint = " .. field_id .. "]"):attr_e("procedureName")
	local row = d.add_row_labeled_field(container, {caption = label}, {id = field_id, text = translet_name}, {id = "row_" .. field_id}, "D#InputField", {FocusLost = "lua.configurator.configurator.set_diagram_translets"})
end
