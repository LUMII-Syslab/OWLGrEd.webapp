module(..., package.seeall)

require("re")

u = require("configurator.configurator_utilities")
cu = require("configurator.const.const_utilities")
d = require("dialog_utilities")
delta = require("configurator.delta")
report = require("reporter.report")
toolbar = require("configurator.toolbar")
popup = require("configurator.popup")
configurator_delete = require("configurator.delete")
conf_dialog = require("configurator.dialog")
style = require("configurator.style")
copy = require("configurator.copy")
versioning = require("configurator.versioning")


function configurator_dialog(elem)
	if elem == nil then
		elem = utilities.active_elements()
	end
	local form, configurator_horizontal_box = configurator_form()
	local tree = add_configurator_tree(configurator_horizontal_box, elem)
	local tab_container = add_configurator_tabs(configurator_horizontal_box, elem)
	d.show_form(form)
end

function configurator_form()
	local form = d.add_form({id = "configurator_form", caption = "Configurator", buttonClickOnClose = "false", minimumWidth = 600, minimumHeight = 500, maximumHeight = 700})
		d.add_event_handlers(form, {Close = "lua.configurator.configurator.close_configurator_form()"})
	local configurator_horizontal_box = d.add_component(form, {id = "configurator_horizontal_box", horizontalAlignment = 1}, "D#HorizontalBox")
return form, configurator_horizontal_box
end

function add_configurator_tree(container, elem)
	local tree_vertical_box = d.add_component(container, {id = "tree_vertical_box", horizontalAlignment = 1}, "D#VerticalBox")
	local tree = d.add_component(tree_vertical_box, {id = "Tree", draggableNodes = "true", minimumWidth = 250, minimumHeight = 200}, "D#Tree")
	d.add_event_handlers(tree, {TreeNodeSelect = "lua.configurator.configurator.tree_node_change", TreeNodeMove = "lua.configurator.configurator.tree_node_move"})
	fill_tree(tree, elem)
	local tree_button_box = d.add_component(tree_vertical_box, {id = "tree_button_box", horizontalAlignment = 0}, "D#HorizontalBox")
	local add_button = d.add_button(tree_button_box, {id = "add_button", caption = "Add"}, {Click = "lua.configurator.configurator.add_tree_node_from_button()"})
	local delete_button = d.add_button(tree_button_box, {id = "delete_button", caption = "Delete", enabled = "false"}, {Click = "lua.configurator.delete.delete_tree_node_from_button"})
return tree
end

function add_configurator_tabs(container, elem)
	local tab_vertical_box = d.add_component(container, {id = "tab_vertical_box", horizontalAlignment = 1}, "D#VerticalBox")
	local tab_container = d.add_component(tab_vertical_box, {id = "tab_container"}, "D#TabContainer")
	d.add_event_handlers(tab_container, {TabChange = "lua.configurator.configurator.tab_changed"})	
	local main_tab = d.add_component(tab_container, {id = "main_tab", caption = "Main"}, "D#Tab")
	local extras_tab = d.add_component(tab_container, {id = "extras_tab", caption = "Extras"}, "D#Tab")
	local transformation_tab = d.add_component(tab_container, {id = "transformation_tab", caption = "Translets"}, "D#Tab")

	local object_type = elem:find("/target_type")
	make_main_tab(main_tab, object_type)
	add_configurator_buttons(tab_vertical_box, u.is_dialog_button_enabled(object_type))
return row
end

function add_configurator_buttons(container, buls)
	local button_box = d.add_component(container, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
	local dialog_button = d.add_button(button_box, {id = "new_style_button", caption = "Styles"}, {Click = "lua.configurator.style.add_new_style()"})
	local dialog_button = d.add_button(button_box, {id = "dialog_button", caption = "Dialog", enabled = buls}, {Click = "lua.configurator.dialog.make_dialog_form()"})
	local style_button = d.add_button(button_box, {id = "style_button", caption = "Symbol"}, {Click = "lua.configurator.style.open_style_form()"})
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_configurator_form"})--:link("defaultButtonForm", lQuery("D#Form[id = 'configurator_form']"))
end

function fill_tree(tree, elem)
	local target_type = elem:find("/target_type")
	local elem_caption = target_type:attr("caption")
	local treeNode = d.add_tree_node(tree, "tree", {id = elem_caption, text = elem_caption, expanded = "true"}):link("type", target_type)
	make_compartType_tree_nodes(treeNode, target_type, "/compartType", "parentNode")
return tree
end

function make_compartType_tree_nodes(treeNode, source_type, path, tree_link)
	if source_type ~= nil then
		source_type:find(path):each(function(obj_type)
			--local start, finish = string.find(obj_type:attr("id"), "ASFictitious")
			--if start == 1 and finish == 12 then
			--	replace_multi_row_links(obj_type, obj_type:find("/subCompartType"))
			--	make_compartType_tree_nodes(treeNode, obj_type, "/subCompartType", "parentNode")
			--else
				local caption = obj_type:attr("id")
				local added_node = d.add_tree_node(treeNode, tree_link, {id = caption, text = caption, expanded = "true"}):link("type", obj_type)
				make_compartType_tree_nodes(added_node, obj_type, "/subCompartType", "parentNode")
			--end
		end)
	end
end

function replace_multi_row_links(source_type, target_type)
	local prop_row = source_type:find("/propertyRow")
	local prop_tab = source_type:find("/propertyTab")
	local prop_dgr = source_type:find("/propertyDiagram")
	source_type:remove_link("propertyRow", prop_row)
			:remove_link("propertyTab", prop_tab)
			:remove_link("propertyDiagram", prop_dgr)
	target_type:link("propertyRow", prop_row)
			:link("propertyTab", prop_tab)
			:link("propertyDiagram", prop_dgr)
end

function add_tree_node_from_button()
	u.log_button_press({Button = "Add", Context = "CompartType"})
	local tree = d.get_component_by_id("Tree")
	local selected_node = d.get_selected_tree_node()
	local node_name = "NewAttribute"
	local added_node = d.add_tree_node(selected_node, "parentNode", {id = node_name, text = node_name, expanded = "true"})
	add_compartType(added_node, node_name)
	d.execute_command("D#AddTreeNodeCmd", tree, nil, {treeNode = added_node, parent = selected_node})
	d.execute_command("D#SelectTreeNodeCmd", tree, nil, {treeNode = added_node})
end

function tree_node_change()
	local delete_button = d.get_component_by_id("delete_button")
	if d.get_selected_tree_node():find("/parentNode"):size() == 0 then
		delete_button:attr({enabled = "false"})
		d.execute_d_command(delete_button, "Refresh")
	else
		delete_button:attr({enabled = "true"})
		d.execute_d_command(delete_button, "Refresh")
	end
	local tab_container = lQuery("D#TabContainer:has([id = 'tab_container'])")
	tab_container:find("/component"):each(function(tab)
		d.delete_container_components(tab)
	end)
	refresh_tab(tab_container:find("/activeTab"))
end

function tree_node_move()
	local ev = lQuery("D#Event")
	local selected_node = ev:find("/treeNode")
	local old_parent = ev:find("/previousParent")
	local old_parent_type = old_parent:find("/type")
	local new_parent = selected_node:find("/parentNode")
	local new_parent_type = new_parent:find("/type")
	if old_parent:id() ~= new_parent:id() or new_parent:is_empty() then
		if new_parent:is_empty() then
			selected_node:remove_link("tree")
		else
			selected_node:remove_link("parentNode", new_parent)
		end
		selected_node:link("parentNode", old_parent)
		utilities.refresh_form_component(d.get_tree_from_tree_node(selected_node))
	end
	d.delete_event(ev)
	relink_compart_types()
	recalculate_compartment_order(old_parent_type)
end

function recalculate_compartment_order(old_parent_type)
	local elem_type = utilities.get_elemType_from_compartType(old_parent_type)
	local compart_types = elem_type:find("/compartType")
	local diagram_list = {}
	elem_type:find("/element"):each(function(elem)
		local diagram = elem:find("/graphDiagram")
		diagram_list[diagram:id()] = diagram
		local list = {}
		elem:find("/compartment"):each(function(compart)
			list[compart:find("/compartType"):id()] = compart
		end)
		elem:remove_link("compartment")
		compart_types:each(function(compart_type)
			elem:link("compartment", list[compart_type:id()])
		end)
		elem:find("/compartment"):each(recalculate_sub_compartment_order)
	end)
	for _, diagram in pairs(diagram_list) do
		utilities.refresh_only_diagram(diagram)
	end
end

function recalculate_sub_compartment_order(compart)
	local compart_type = compart:find("/compartType")
	local sub_compart_types = compart_type:find("/subCompartType")
	if sub_compart_types:is_not_empty() then
		local list = {}
		compart:find("/subCompartment"):each(function(sub_compart)
			list[sub_compart:find("/compartType"):id()] = sub_compart
		end)
		compart:remove_link("subCompartment")
		sub_compart_types:each(function(sub_compart_type)
			compart:link("subCompartment", list[sub_compart_type:id()])
		end)
		compart:find("/subCompartment"):each(recalculate_sub_compartment_order(compart))
	end
end

function tab_changed()
	refresh_tab(u.active_tab())
end

function refresh_tab(tab)
	if tab:find("/component"):is_empty() then
		local object_type = u.get_selected_obj_type()
		--d.delete_container_components(tab)
		local tab_id = tab:attr("id")
		if tab_id == "main_tab" then
			make_main_tab(tab, object_type)
		elseif tab_id == "transformation_tab" then
			make_tranformation_tab(tab, object_type)
		elseif tab_id == "extras_tab" then
			make_extras_tab(tab, object_type)
		end
		--utilities.refresh_form_component(tab)
		--utilities.execute_cmd("D#Command", {info = "Refresh"}):link("receiver", tab)
		utilities.execute_cmd("D#Command", {info = "Refresh", receiver = tab})
		report.event("Tab Changed", {
			ChangedTo = tab_id
		})
	end
end

function make_main_tab(tab, object_type)
	local tmp = object_type:attr("concatStyle")
	if tmp == nil then
		make_elemType_main_tab(tab, object_type)
	else
		make_compartType_main_tab(tab, object_type)
	end
end

--some functions are needed to improve the coding style
function make_elemType_main_tab(tab, object_type)
	local palette_element_type = object_type:find("/paletteElementType")
	local isAbstract_value = "false"
	if object_type:filter(".NodeType"):size() > 0 then
		if palette_element_type:size() == 0 then
			isAbstract_value = "true"
		end
		d.add_row_labeled_field(tab, {caption = "Is Abstract"}, {id = "isAbstract", checked = isAbstract_value}, {id = "row_isAbstract"}, "D#CheckBox", {Change = "lua.configurator.configurator.process_is_abstract"})
	end
	add_input_field_change(tab, "ID", "id", object_type, "lua.configurator.configurator.check_id_field_syntax", "lua.configurator.configurator.update_seed_id")
	local _, field = add_input_field_change(tab, "Caption", "caption", object_type, "lua.configurator.configurator.update_tree_node_from_caption_field", "lua.configurator.configurator.update_seed_caption")
	--d.get_component_by_id("configurator_form"):link("focused", field)
	d.set_component_focused(d.get_form_from_component(tab), field)
	add_input_field_change(tab, "Multiplicity", "multiplicityConstraint", object_type, "lua.configurator.configurator.check_multiplicity_field", "lua.configurator.configurator.update_type_input_field")
	add_checkBox_field(tab, "Properties On Create", "openPropertiesOnElementCreate", object_type)
	if object_type:filter(".NodeType"):size() > 0 then
		add_checkBox_field(tab, "Is Container Mandatory", "isContainerMandatory", object_type)
		local _, combo = add_comboBox_field_function_start_value(tab, "Navigate To Diagram", "id", "false", "lua.configurator.configurator.update_navigate_to_diagram", "lua.configurator.configurator.navigate_to_diagram", navigate_start_value())
		navigate_to_diagram(combo)
		--local palette_group = d.add_component(tab, {id = "palette_group", caption = "Palette Element"}, "D#GroupBox")
		u.add_input_field_function(tab, "Palette Element Name", "caption", palette_element_type, "lua.configurator.configurator.set_palette_name")
		add_input_field_change(tab, "Palette Element Nr", "nr", palette_element_type, "lua.configurator.configurator.check_field_value", "lua.configurator.configurator.set_palette_nr_box")
		d.add_row_labeled_field(tab, {caption = "Palette Element Image"}, {id = "picture", fileName = get_fileName(), editable = "true", minimumWidth = 50, minimumHeight = 50, maximumWidth = 50, maximumHeight = 50}, {id = "row_picture"}, "D#Image", {Change = "lua.configurator.configurator.set_palette_image_box"})
	elseif object_type:filter(".EdgeType"):size() > 0 then
		add_comboBox_field_change_dropdown(tab, "Direction", "direction", object_type:attr("direction"), "lua.configurator.configurator.update_type_input_field", "lua.configurator.configurator.get_direction_values", object_type)	
		add_input_field_change(tab, "Start Cardinality", "startMultiplicityConstraint", object_type, "lua.configurator.configurator.check_multiplicity_field", "lua.configurator.configurator.update_type_input_field")
		add_input_field_change(tab, "End Cardinality", "endMultiplicityConstraint", object_type, "lua.configurator.configurator.check_multiplicity_field", "lua.configurator.configurator.update_type_input_field")
		add_comboBox_field_change_dropdown(tab, "Palette Element Name", "caption", "true", "lua.configurator.configurator.set_palette_name_line", "lua.configurator.configurator.get_palette_line_elems", palette_element_type)
		add_input_field_change(tab, "Palette Element Nr", "nr", palette_element_type, "lua.configurator.configurator.check_field_value", "lua.configurator.configurator.set_palette_nr_line")
		d.add_row_labeled_field(tab, {caption = "Palette Image"}, {id = "picture", fileName = get_fileName(), editable = "true", minimumWidth = 50, minimumHeight = 50, maximumWidth = 50, maximumHeight = 50}, {id = "row_picture"}, "D#Image", {Change = "lua.configurator.configurator.set_palette_image_line"})
	elseif object_type:filter(".PortType"):size() > 0 then
		u.add_input_field_function(tab, "Palette Element Name", "caption", palette_element_type, "lua.configurator.configurator.set_palette_name")
		add_input_field_change(tab, "Palette Element Nr", "nr", palette_element_type, "lua.configurator.configurator.check_field_value", "lua.configurator.configurator.set_palette_nr_pin")
		d.add_row_labeled_field(tab, {caption = "Palette Image"}, {id = "picture", fileName = get_fileName(), editable = "true", minimumWidth = 50, minimumHeight = 50, maximumWidth = 50, maximumHeight = 50}, {id = "row_picture"}, "D#Image", {Change = "lua.configurator.configurator.set_palette_image_pin"})
	elseif object_type:filter(".FreeBoxType"):size() > 0 then
		add_comboBox_field_function_start_value(tab, "Navigate To Diagram", "id", "false", "lua.configurator.configurator.update_navigate_to_diagram", "lua.configurator.configurator.navigate_to_diagram", navigate_start_value())
		u.add_input_field_function(tab, "Palette Element Name", "caption", palette_element_type, "lua.configurator.configurator.set_palette_name")
		add_input_field_change(tab, "Palette Element Nr", "nr", palette_element_type, "lua.configurator.configurator.check_field_value", "lua.configurator.configurator.set_palette_nr_free_box")
		d.add_row_labeled_field(tab, {caption = "Palette Image"}, {id = "picture", fileName = get_fileName(), editable = "true", minimumWidth = 50, minimumHeight = 50, maximumWidth = 50, maximumHeight = 50}, {id = "row_picture"}, "D#Image", {Change = "lua.configurator.configurator.set_palette_image_free_box"})
	elseif object_type:filter(".FreeLineType"):size() > 0 then
		u.add_input_field_function(tab, "Palette Element Name", "caption", palette_element_type, "lua.configurator.configurator.set_palette_name")
		add_input_field_change(tab, "Palette Element Nr", "nr", palette_element_type, "lua.configurator.configurator.check_field_value", "lua.configurator.configurator.set_palette_nr_free_line")
		d.add_row_labeled_field(tab, {caption = "Palette Image"}, {id = "picture", fileName = get_fileName(), editable = "true", minimumWidth = 50, minimumHeight = 50, maximumWidth = 50, maximumHeight = 50}, {id = "row_picture"}, "D#Image", {Change = "lua.configurator.configurator.set_palette_image_free_line"})
	else
		print("Error in make main tab")
	end
	u.add_main_popUp_table(tab)	
end

function get_direction_values()
	u.add_configurator_comboBox({"UniDirectional", "BiDirectional", "ReverseBiDirectional"})
end

function get_palette_line_elems()
	local combo_box = get_event_source()
	d.clear_list_box(combo_box)
	local palette_type = utilities.active_elements():find("/target_type/paletteElementType/paletteType")
	if palette_type:is_not_empty() then
		d.fill_list_combo_box(combo_box, u.make_combo_box_item_table(palette_type:find("/paletteElementType:has(/elemType.EdgeType)"), "caption"))
	end
end

function process_is_abstract()
	local attr, value = u.get_event_source_attrs("checked")
	local obj_type = u.get_selected_obj_type()
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(obj_type), IsAbstract = value})
	if value == "false" then
		local attr_table = {}
		local palette_element_type = get_palette_element_type()
		local palette_name_field = d.get_component_by_id("caption")
		attr_table["caption"] = palette_name_field:attr_e("text")
		local palette_nr_field = d.get_component_by_id("nr")
		attr_table["nr"] = palette_nr_field:attr_e("text")
		local palette_elem_image = d.get_component_by_id("picture"):attr_e("fileName")
		if palette_elem_name == "" then
			attr_table["caption"] = obj_type:attr_e("caption")
		end
		if attr_table["nr"] == "" then
			attr_table["nr"] = utilities.current_diagram():find("/target_type/paletteType/paletteElementType"):size() + 1
		end
		set_palette_element_type_attribute(palette_element_type, attr_table)
		refresh_palette_nr_and_image(palette_name_field:attr({text = attr_table["caption"]}), palette_nr_field:attr({text = attr_table["nr"]}))
		utilities.set_palette_element_attribute()
	else
		configurator_delete.delete_palette_element_type(obj_type:find("/paletteElementType"))
	end	
	utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
end

function refresh_palette_nr_and_image(nr, image)
	utilities.refresh_form_component(nr)
	utilities.refresh_form_component(image)
end

function get_fileName()
	return utilities.active_elements():find("/target_type/paletteElementType"):attr_e("picture")
end

function make_compartType_main_tab(tab, object_type)
	local property_row = object_type:find("/propertyRow")
	--add_ID_input_field(tab, "ID", "id", object_type)
	add_input_field_change(tab, "ID", "id", object_type, "lua.configurator.configurator.check_id_field_syntax", "lua.configurator.configurator.update_prop_row_id")
	add_input_field_change(tab, "Caption", "caption", object_type, "lua.configurator.configurator.update_tree_node_from_caption_field_compart", "lua.configurator.configurator.update_compart_caption")
	u.add_checkBox_field_function(tab, "Is Group", "isGroup", object_type, {Change = "lua.configurator.configurator.set_isGroup"})
	local _, combo = add_checkBox_comboBox_field(tab, "Row Type", "rowType", "true", "lua.configurator.dialog.make_property_field", "lua.configurator.dialog.row_type_generator", property_row)
	local _, combo = add_comboBox_field_function(tab, "Tab", "id", "true", "lua.configurator.dialog.set_row_tab", "lua.configurator.dialog.row_tab_generator", property_row:find("/propertyTab"))
	add_input_field(tab, "Default Value", "startValue", object_type)
	add_multi_field(tab, "Prefix", "adornmentPrefix", object_type)
	add_multi_field(tab, "Suffix", "adornmentSuffix", object_type)
	--local concat_type = object_type:find("/parentCompartType[id ^= 'ASFictitious']")
	--if concat_type:is_empty() then
	--	concat_type = object_type
	--end
	add_multi_field(tab, "Delimiter", "concatStyle", object_type, {FocusLost = "lua.configurator.configurator.update_concat_style"})
	add_multi_field(tab, "Pattern", "pattern", object_type)
	--add_checkBox_field(tab, "Is Essential", "isEssential", object_type)
end

function update_prop_row_id()
	local compart_type = u.get_selected_obj_type()
	compart_type:find("/propertyRow"):attr({id = compart_type:attr("id")})
end

function set_elem_style_id()
	local attr, value = u.get_event_source_attrs("text")
	local target_type = u.get_selected_obj_type()
	local target_type_id = target_type:attr("id")
	local style
	if target_type:filter(".CompartType"):is_not_empty() then
		style = target_type:find("/compartStyle[id = " .. target_type_id .. "]:first()")
	else
		style = target_type:find("/elemStyle[id = " .. target_type_id .. "]:first()")
	end
	if style:is_not_empty() then
		style:attr({id = value})
	end
end

function set_isGroup()
	local attr, value = u.get_event_source_attrs("checked")
	local compart_type = u.get_selected_obj_type()
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(compart_type), [attr] = value})
	set_isGroup_for_compart_types(compart_type, value)
end

function set_isGroup_for_compart_types(compart_type, value)
	if compart_type:is_not_empty() then
		compart_type:attr({isGroup = value})
		local compart_styles = compart_type:find("/compartStyle")
		local compartments = compart_type:find("/compartment")
		if value ~= "true" then
			if compart_styles:is_not_empty() then
				compart_styles:find(":first()"):link("compartment", compartments)
			else
				local compart_type_id = compart_type:attr("id")
				cu.add_default_compart_style(compart_type_id, compart_type_id)():link("compartType", compart_type)
												:link("compartment", compartments)
			end
			set_isGroup_for_compart_types(compart_type:find("/subCompartType"), value)
		else
			compart_styles:remove_link("compartment", compartments)
			set_isGroup_for_compart_types(compart_type:find("/parentCompartType"), value)
		end
	end
end

function set_should_be_included()
	local attr, value = u.get_event_source_attrs("text")
	local prop_row = u.get_selected_obj_type():find("/propertyRow"):attr({[attr] = value})
end

function set_should_be_included_for_tab()
	local attr, value = u.get_event_source_attrs("text")
	local prop_row = u.get_selected_obj_type():find("/propertyRow/propertyTab"):attr({[attr] = value})
end

function update_concat_style()
	local attr, value = u.get_event_source_attrs("text")
	local obj_type = u.get_selected_obj_type()
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(obj_type), [attr] = value})
	--local parent_type = obj_type:find("/parentCompartType[id ^= 'ASFictitious']")
	--if parent_type:is_not_empty() then
	--	parent_type:attr(attr, value)
	--else
	obj_type:attr({[attr] = value})
	--end
end

function make_tranformation_tab(tab, object_type)
	if object_type:filter(".CompartType"):size() > 0 then
		make_compartType_transformation_tab(tab, object_type)
	else
		make_elemTye_transformation_tab(tab, object_type)
	end
end

function make_extras_tab(tab, object_type)
	d.delete_container_components(tab)
	if object_type:find(".CompartType"):size() > 0 then
		style.compartment_style(tab, object_type)
	else	
		u.add_element_key_shortcuts(tab)
		if object_type:find(".NodeType"):size() > 0 then
			add_contain_table(tab)
		end
	end
end

function make_elemTye_transformation_tab(tab, object_type)
	local element_group_box = d.add_component(tab, {id = "group_box", caption = "Element"}, "D#GroupBox")
		local list1 = {
			l2ClickEvent = "L2Click",
			procProperties = "Properties",
			procDynamicPopUp = "Dynamic Context Menu",
			procDynamicTooltip = "Dynamic Tooltip",
			procPreCondition = "Pre Condition",
			procNewElement = "New Element", 
		}
		generatre_transformation_field_rows(list1, element_group_box, object_type)

	local domain_group_box = d.add_component(tab, {id = "domain_group_box", caption = "Domain"}, "D#GroupBox")
		local list2 = {
			procCreateElementDomain = "Create Domain",
			procDeleteElement = "Delete Element",
			procDeleteElementDomain = "Delete Domain",
			procCopyElement = "Copy Element", 
			procCopied = "Copy Domain",	
		}
		generatre_transformation_field_rows(list2, domain_group_box, object_type)

--type specific fields
	if object_type:filter(".NodeType"):size() > 0 then
		add_transformation_field(element_group_box, "Container Changed", "procContainerChanged", object_type)
	elseif object_type:filter(".EdgeType"):size() > 0 then
		add_transformation_field(element_group_box, "Move Line", "procMoveLine", object_type)
	elseif object_type:filter(".PortType"):size() > 0 then
		--currently nothing
	end
	d.add_component(tab, {id = "empty_box"}, "D#HorizontalBox")
end

function make_compartType_transformation_tab(tab, object_type)
	local group_box = d.add_component(tab, {id = "group_box", caption = "Dialog"}, "D#GroupBox")
		local list1 = {
			procGenerateInputValue = "Start Value Generate",
			procBlockingFieldEntered = "Blocking Field Entered",
			procForcedValuesEntered = "Forced Values Field Entered",
			procCheckCompartmentFieldEntered = "Check Compartment Field Entered",
			procGenerateItemsClickBox = "Generate Items ClickBox",
			procFieldEntered = "Field Entered",			
		}
		generatre_transformation_field_rows(list1, group_box, object_type)

	group_box = d.add_component(tab, {id = "compartment_group_box", caption = "Attribute"}, "D#GroupBox")
		local list2 = {
			procCompose = "Compose",
			procDecompose = "Decompose",
			procGetPrefix = "Get Prefix",
			procGetSuffix = "Get Suffix",
			procGetPattern = "Get Pattern",
			procIsHidden = "Is Hidden"
		}
		generatre_transformation_field_rows(list2, group_box, object_type)

	group_box = d.add_component(tab, {id = "domain_group_box", caption = "Domain"}, "D#GroupBox")
		local list3 = {
			procCreateCompartmentDomain = "Create Domain",
			procUpdateCompartmentDomain = "Update Domain",
			procDeleteCompartmentDomain = "Delete Domain",
		}
		generatre_transformation_field_rows(list3, group_box, object_type)

	d.add_component(tab, {id = "empty_box"}, "D#HorizontalBox")
end

function update_ID_field()
	versioning.update_elem_type_ID()
	update_form_field("text")
end

function update_type_ID_input_field()
	versioning.update_compart_type_ID()
	update_form_field("text")
end

function update_transformation_field()
	local attr, value = u.get_event_source_attrs("text")
	local obj_type = u.get_selected_obj_type()
	cu.add_translet_to_obj_type(obj_type, attr, value)
	--local translet = obj_type:find("/translet[extensionPoint = " .. attr .. "]")
	
	report.event("Translet " .. attr, {
		ObjectType = utilities.get_class_name(obj_type),
		[attr] = value
	})
	--:attr({procedureName = value})
end

function update_type_input_field()
	update_form_field("text")
end

function update_check_box_field()
	update_form_field("checked")
end

function update_form_field(attr_name)
	local attr, value = u.get_event_source_attrs(attr_name)
	local obj_type = u.get_selected_obj_type()
	obj_type:attr(attr, value)
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(obj_type), [attr] = value})
end

function update_tree_node_from_caption_field()
	local attr, value = u.get_event_source_attrs("text")
	local tree_node = d.get_selected_tree_node()
	tree_node:find("/type"):attr({caption = value})
	tree_node:find("/target"):attr({caption = value})
	tree_node:attr({text = value, id = value})
	local parent_tree = tree_node:find("/parentTree")
	d.execute_d_command(parent_tree, "Refresh")
	local is_abstract = d.get_component_by_id("isAbstract")
	if is_abstract:attr("chekced") ~= "true" then
		local palette_name_component = lQuery("D#Component[id = 'row_caption']:has(/component[id = 'label_box']/component[caption = 'Palette Element Name'])/component[id = 'field_box']/component")
		--local id_field = lQuery("D#Component[id = 'row_id']:has(/component[id = 'label_box']/component[caption = 'ID'])/component[id = 'field_box']/component")
		--refresh_component_from_caption(id_field, value)
		refresh_component_from_caption(palette_name_component, value)
	end
end

function refresh_component_from_caption(component, value)
--vajag vel sataisit, lai ari dzesana ari tiktu nemta vera
	if component:attr("text") == string.sub(value, 1, -2) then
		component:attr({text = value})
		d.execute_d_command(component, "Refresh")
	end
end

function update_tree_node_from_caption_field_compart()
	local attr, value = u.get_event_source_attrs("text")
	local tree_node = d.get_selected_tree_node()
	tree_node:attr({text = value, id = value})
	local parent_tree = tree_node:find("/parentTree")
	d.execute_d_command(parent_tree, "Refresh")
	--local id_field = lQuery("D#Component[id = 'row_id']:has(/component[id = 'label_box']/component[caption = 'ID'])/component[id = 'field_box']/component")
	--refresh_component_from_caption(id_field, value)
end

function update_seed_caption()
	local attr, value = u.get_event_source_attrs("text")
	update_target_diagram_type(attr, value)
	local active_elem = utilities.active_elements()
	u.get_name_compart(active_elem):attr({input = value, value = value})
	local target_diagram = active_elem:find("/child")
	if target_diagram:is_empty() then
		target_diagram = active_elem:find("/target")
	end
	if target_diagram:is_not_empty() then
		target_diagram:attr({caption = value})
		utilities.execute_cmd("AfterConfigCmd", {graphDiagram = active_elem:find("/graphDiagram/target_type"):find("/graphDiagram")})
	end
end

function update_seed_id()
	local attr, value = u.get_event_source_attrs("text")
	update_target_diagram_type(attr, value)
end
 
function update_target_diagram_type(attr, value)
	local active_elem = utilities.active_elements()
	local target_type = active_elem:find("/target_type")
	local target_type_id = target_type:attr("id")
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(target_type), [attr] = value})
	target_type:attr({[attr] = value})--:find("/paletteElement"):attr({id = value, caption = value})
	target_type:find("/propertyDiagram"):attr({[attr] = target_type:attr(attr)})
	local target_diagram_type = target_type:find("/target")
	if target_diagram_type:is_not_empty() then
		if attr == "id" then
			versioning.update_diagram_type_ID(target_diagram_type)
		end
		target_diagram_type:attr({[attr] = value})
	end
end

function get_attribute_compart(elem)
	return elem:find("/compartment:has(/compartType[id = 'AS#Attributes'])")
end

function update_compart_caption()
	local attr, value = u.get_event_source_attrs("text")
	--local id_field_value = lQuery("D#Component[id = 'row_id']:has(/component[id = 'label_box']/component[caption = 'ID'])/component[id = 'field_box']/component"):attr("text")
	local compart_type = u.get_selected_obj_type()
	--local compart_id = compart_type:attr_e("id")
	--local compart_style = compart_type:find("/compartStyle:has([id = '" .. compart_id .. "'])"):log()
	local compart_style = compart_type:find("/compartStyle")
	compart_type:find("/propertyRow"):attr({caption = value})
	compart_type:attr({caption = value})
	compart_style:attr({caption = value})
end

function navigate_start_value()
	return utilities.active_elements():find("/target_type/target"):attr_e("id")
end

function generatre_transformation_field_rows(list, parent, object_type)
	for index, name in pairs(list) do
		add_transformation_field(parent, name, index, object_type)
	end
end

function add_transformation_field(container, label, field_id, object_type)
	local translet_name = object_type:find("/translet[extensionPoint = " .. field_id .. "]"):attr_e("procedureName")
	local row = d.add_row_labeled_field(container, {caption = label}, {id = field_id, text = translet_name}, {id = "row_" .. field_id}, "D#InputField", {FocusLost = "lua.configurator.configurator.update_transformation_field"})
	--local button = d.add_button(row, {id = field_id .. "_button", caption = "..."}, {Click = "lua.configurator.configurator.add_specific_transformation()"})
end

function add_input_field(container, label, field_id, object_type)
	u.add_input_field_function(container, label, field_id, object_type, "lua.configurator.configurator.update_type_input_field")
end

function add_ID_input_field(container, label, field_id, object_type)
	u.add_input_field_function(container, label, field_id, object_type, "lua.configurator.configurator.update_type_ID_input_field")
end

function add_input_field_change(container, label, field_id, object_type, change_function_name, focus_lost_function)
	local func_table = {}
	if change_function_name ~= "" and change_function_name ~= nil then
		func_table["Change"] = change_function_name
	end
	if focus_lost_function ~= "" and focus_lost_function ~= nil then
		func_table["FocusLost"] = focus_lost_function
	end
	return u.add_input_field_event_function(container, label, field_id, object_type, func_table)
end

function add_multi_field(container, label, field_id, object_type, event_list)
	if event_list == nil then
		event_list = {FocusLost = "lua.configurator.configurator.update_type_input_field"}
	end
	local row = d.add_row_labeled_field(container, {caption = label}, {id = field_id, text = object_type:attr(field_id)}, {id = "row_" .. field_id}, "D#TextArea", event_list)
end

function add_checkBox_field(container, label, field_id, object_type)
	local row = d.add_row_labeled_field(container, {caption = label}, {id = field_id, checked = object_type:attr(field_id)}, {id = "row_" .. field_id}, "D#CheckBox", {FocusLost = "lua.configurator.configurator.update_check_box_field"})
end

function add_comboBox_field(container, label, field_id, is_editable, item_generator, object_type)
	return add_comboBox_field_function(container, label, field_id, is_editable, "lua.configurator.configurator.update_type_input_field", item_generator, object_type)
end

function add_comboBox_field_function(container, label, field_id, is_editable, focus_lost, item_generator, object_type)
	return add_comboBox_field_function_value(container, label, field_id, is_editable, focus_lost, item_generator, object_type:attr(field_id))
end

function add_comboBox_field_function_start_value(container, label, field_id, is_editable, focus_lost, item_generator, field_value_generator)
	return add_comboBox_field_function_value(container, label, field_id, is_editable, focus_lost, item_generator, field_value_generator)
end

function add_comboBox_field_function_value(container, label, field_id, is_editable, focus_lost, item_generator, value)
	return d.add_row_labeled_field(container, {caption = label}, {id = field_id, editable = is_editable, text = value, enabled = "true"},
	{id = "row_" .. field_id}, "D#ComboBox", {FocusLost = focus_lost, DropDown = item_generator})
end

function add_comboBox_field_change_dropdown(container, label, field_id, is_editable, change, item_generator, object_type)
	return d.add_row_labeled_field(container, {caption = label}, {id = field_id, editable = is_editable, enabled = "true", text = object_type:attr_e(field_id)},
	{id = "row_" .. field_id}, "D#ComboBox", {Change = change, DropDown = item_generator})
end

function add_checkBox_comboBox_field(container, label, field_id, is_editable, change, item_generator, object_type)
	local value = object_type:attr_e(field_id)
	local row, combo = d.add_vertical_box_labeled_field(container, {caption = label}, {id = field_id, editable = is_editable, text = value},
	{id = "row_" .. field_id}, "D#ComboBox", {Change = change, DropDown = item_generator})
	conf_dialog.manage_property_row_field_table(combo, value, "true")
	return row, combo
end

function navigate_to_diagram(combo_box)
	if combo_box == nil then
		combo_box = u.get_event_source()
	end
	local res_table = {}
	table.insert(res_table, "")
	u.make_combo_box_item_table(lQuery("GraphDiagramType"):filter(":not([id = 'specificationDgr'], [id = 'diagramTypeDiagram'], [id = 'MMInstances'], [id = 'Repository'])"), "id", res_table)
	u.add_lQuery_configurator_comboBox(res_table, combo_box)
end

function update_navigate_to_diagram()
	local attr, value = u.get_event_source_attrs("text")
	local elem_type = utilities.active_elements():find("/target_type")
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(elem_type), NavigateToDiagram = value})
	elem_type:remove_link("target")
	local attr_table = {}
	if value ~= "" then
		attr_table = {
			l2ClickEvent = "utilities.navigate",
			procCreateElementDomain = "utilities.add_navigation_diagram",
			procDeleteElement = "interpreter.Delete.delete_seed",
			procPasted = "interpreter.CutCopyPaste.copy_paste_diagram_seed",
			procCopied = "interpreter.CutCopyPaste.copy_paste_diagram_seed"
		}
		lQuery("GraphDiagramType[id = '" .. value .."']"):link("source", elem_type)
	else
		attr_table = {
			l2ClickEvent = "interpreter.Properties.Properties",
			procCreateElementDomain = "",
			procDeleteElement = "",
			procPasted = "",
			procCopied = ""
		}
	end
	for index, name in pairs(attr_table) do
		cu.add_translet_to_obj_type(elem_type, index, name)	
	end

	local l2Click = d.get_component_by_id("l2ClickEvent")
	local procCreateElementDomain = d.get_component_by_id("procCreateElementDomain")
	local procDeleteElement = d.get_component_by_id("procDeleteElement")
	local procPasted = d.get_component_by_id("procPasted")
	local procCopied = d.get_component_by_id("procCopied")
	if l2Click:is_not_empty() and procCreateElementDomain:is_not_empty() and procDeleteElement:is_not_empty() then
		utilities.refresh_form_component(l2Click:attr({text = attr_table["l2ClickEvent"]}))
		utilities.refresh_form_component(procCreateElementDomain:attr({text = attr_table["procCreateElementDomain"]}))
		utilities.refresh_form_component(procDeleteElement:attr({text = attr_table["procDeleteElement"]}))
		utilities.refresh_form_component(procPasted:attr({text = attr_table["procPasted"]}))
		utilities.refresh_form_component(procCopied:attr({text = attr_table["procCopied"]}))
	end
end

function add_compartType(treeNode, node_name)
	local parent = treeNode:find("/parentNode")
	local source_type = parent:find("/type")
	if parent:find("/tree"):is_not_empty() then
		local id = cu.generate_unique_id(node_name, source_type, "compartType")
		local compartType, compartStyle = add_compart_type_compart_style(id)
					:link("treeNode", treeNode:attr({text = id}))
		source_type:link("compartType", compartType)
		add_configurator_compart_type(compartType, compartStyle)
		versioning.compart_type_versioning(compartType)
	else
		local id = cu.generate_unique_id(node_name, source_type, "subCompartType")
		local compartType, compartStyle = add_compart_type_compart_style(id)
					:link("treeNode", treeNode:attr({text = id}))
		source_type:link("subCompartType", compartType)
		versioning.compart_type_versioning(compartType)
	end
end

function add_configurator_compart_type(compartType, compartStyle)
	local elem = utilities.active_elements()
	local attr_compart_type = elem:find("/elemType/compartType[id = 'AS#Attributes']")
	return lQuery.create("Compartment", {element = elem,
					target_type = compartType,
					compartStyle = compartStyle,
					compartType = attr_compart_type})
end

function add_compart_type_compart_style(node_name)
	local compart_type = u.add_compart_type(node_name)
	cu.add_compart_type_translets(compart_type)
	local compart_style = u.add_default_compart_style(compart_type:attr_e("id"), compart_type:attr_e("caption")):link("compartType", compart_type)
	return compart_type, compart_style
end

function add_contain_table(container)
	local group_box = d.add_component(container, {id = "table_id", caption = "Contains"}, "D#GroupBox")
	local list_box = d.add_component(group_box, {id = "contains_list_box",  multiSelect = "true", horizontalAlignment = 0, minimumWidth = 220, minimumHeight = 150}, "D#ListBox")
	d.add_event_handlers(list_box, {Change = "lua.configurator.configurator.change_contains()"})
	fill_contains_list_box(list_box)
end

function change_contains()
	log_list_box({Name = "Contains"})
	local ev = lQuery("D#Event")
	local selected_item = ev:find("/selected")
	local obj_type = u.get_type_from_tree_node()
	if selected_item:is_not_empty() then
		local selected_item_value = selected_item:attr("value")
		local component_type = obj_type:find("/graphDiagramType/elemType NodeType[id = '" .. selected_item_value .. "']")
		if component_type:is_not_empty() then
			component_type:link("containerType", obj_type)
		end
	else
		local deselected_item_val = ev:find("/deselected"):attr("value")
		local component_type = obj_type:find("/graphDiagramType/elemType NodeType[caption = '" .. deselected_item_val .. "']")
		obj_type:remove_link("componentType", component_type)
	end
	d.delete_event()
end

function fill_contains_list_box(list_box)
	local obj_type = u.get_type_from_tree_node()
	local contains_list = {}
	obj_type:find("/componentType"):each(function(component_type)
		local id = component_type:attr("id")
		contains_list[id] = true
	end)
	utilities.active_elements():find("/target_type/graphDiagramType/elemType NodeType"):each(function(node_type)
		local palette_element_type = node_type:find("/paletteElementType")
		if palette_element_type:is_not_empty() then
			local value = node_type:attr("id")
			local item = lQuery.create("D#Item", {value = value})
			list_box:link("item", item)
			if contains_list[value] then
				list_box:link("selected", item)
			end
		end
	end)
end

function process_element_contains()
	local obj_type = u.get_type_from_tree_node()
	obj_type:remove_link("componentType")
	get_event_source():find("/vTableRow"):each(function(row)
		row = lQuery(row)
		row:find("/vTableCell"):each(function(cell)
			cell = lQuery(cell)
			local cell_value = cell:attr_e("value")
			if cell_value ~= "" then
				local component_type = obj_type:find("/graphDiagramType/elemType NodeType[caption = '" .. cell_value .. "']")
				if component_type:size() > 0 then
					component_type:link("containerType", obj_type)
					component_type:link("parentType", obj_type)
				end
			end
		end)
	end)
end

function container_items()
	return u.add_lQuery_configurator_comboBox(u.make_combo_box_item_table(utilities.active_elements():find("/target_type/graphDiagramType/elemType NodeType"), "caption"))
end

function fill_container_table(table)
	fill_table(table, "/componentType", {"caption"})
end

--palette name
function set_palette_name_line()
	local attr, value = u.get_event_source_attrs("text")
	local elem_type = utilities.active_elements():find("/target_type")
	local palette_type = elem_type:find("/graphDiagramType/paletteType")
	if palette_type:is_not_empty() then
		local palette_type_elem = palette_type:find("/paletteElementType[" .. attr .. " = " .. value .. "]")	
		local tmp_palette_elem_type = elem_type:find("/paletteElementType")
		if palette_type_elem:is_not_empty() then
			if tmp_palette_elem_type:id() ~= palette_type_elem:id() then
				if tmp_palette_elem_type:find("/elemType"):size() == 1 then	
					configurator_delete.delete_palette_elem_type(tmp_palette_elem_type)
					elem_type:link("paletteElementType", palette_type_elem)
				else
					tmp_palette_elem_type:remove_link("elemType", elem_type)
					palette_type_elem:link("elemType", elem_type)
				end
			end
		else
			if tmp_palette_elem_type:find("/elemType"):size() == 1 then
				local pic = tmp_palette_elem_type:attr("picture")
				local nr = tmp_palette_elem_type:attr("nr")
				configurator_delete.delete_palette_elem_type(tmp_palette_elem_type)	
				set_palette_element_type_attribute(get_palette_element_type(), {id = value, caption = value, picture = pic, nr = nr})
				utilities.set_palette_element_attribute()
			else
				tmp_palette_elem_type:remove_link("elemType", elem_type)
				--set_palette_element_name()
				set_palette_name()
			end
		end
	else
		set_palette_name()
		--set_palette_element_name()
	end
	local palette_type_elem = elem_type:find("/paletteElementType:has(/elemType.EdgeType)")
	local nr_value = palette_type_elem:attr_e("nr")
	local image_value = palette_type_elem:attr_e("picture")
	local _, nr, image = u.get_palette_components()
	refresh_palette_nr_and_image(nr:attr({text = nr_value}), image:attr({fileName = image_value}))
end

function set_palette_name()
	local attr, value = u.get_event_source_attrs("text")
	local palette_elem_type = set_palette_element_type_attribute(get_palette_element_type(), {id = value, caption = value})
 	utilities.set_palette_element_attribute()
	log_configurator_field(attr, {ObjectType = "PaletteElementType", name = value})
	return palette_elem_type
end

--palette image
function set_palette_image_box()
	set_palette_image("PaletteBox")
end

function set_palette_image_line()
	set_palette_image("PaletteLine")
end

function set_palette_image_pin()
	set_palette_image("PalettePin")
end

function set_palette_image_free_box()
	set_palette_image("PaletteFreeBox")
end

function set_palette_image_free_line()
	set_palette_image("PaletteFreeLine")
end

function set_palette_image(name)
	local attr, fileName = u.get_event_source_attrs("fileName")
	log_configurator_field(attr, {type = "PaletteElementType", picture = fileName})
	local fileName_reverse = string.reverse(fileName)
	fileName = string.reverse(string.sub(fileName_reverse, 1, string.find(fileName_reverse, "\\") - 1))
	set_palette_element_type_attribute(get_palette_element_type(), {picture = fileName}, name)
	utilities.set_palette_element_attribute()
end

--palette nr
function set_palette_nr_box()
	set_palette_element_nr("PaletteBox")
end

function set_palette_nr_line()
	set_palette_element_nr("PaletteLine")
end

function set_palette_nr_pin()
	set_palette_element_nr("PalettePin")
end

function set_palette_nr_free_box()
	set_palette_element_nr("PaletteFreeBox")
end

function set_palette_nr_free_line()
	set_palette_element_nr("PaletteFreeLine")
end

function set_palette_element_nr(name)
	local attr, nr = u.get_event_source_attrs("text")
	local palette_element_type = get_palette_element_type()
	set_palette_element_type_attribute(palette_element_type, {nr = nr}, name)
	log_configurator_field(attr, {ObjectType = utilities.get_class_name(palette_element_type), nr = nr})
end

function set_palette_element_type_attribute(palette_element_type, attrs)
	local diagram_type = utilities.active_elements():find("/target_type/graphDiagramType")
	local graphDiagram = diagram_type:find("/graphDiagram")
	if attrs["caption"] == "" and palette_element_type:is_not_empty() then
		configurator_delete.delete_palette_element_type(palette_element_type)
	else
		if palette_element_type:is_not_empty() then 
			palette_element_type:attr(attrs)
		else
			local palette_type = diagram_type:find("/paletteType")
			if attrs["nr"] == nil then
				attrs["nr"] = palette_type:find("/paletteElementType"):size() + 1
			end
			if palette_type:is_not_empty() then	
				palette_elem_type = lQuery.create("PaletteElementType", {elemType = u.get_type_from_tree_node(), paletteType = palette_type}):attr(attrs)
			else
				palette_type = lQuery.create("PaletteType", {graphDiagramType = diagram_type})
				palette_elem_type = lQuery.create("PaletteElementType", attrs)
									:link("paletteType", palette_type)
									:link("elemType", u.get_type_from_tree_node())
			end
		end
	end
	return palette_elem_type
end

function get_palette_element()
	return utilities.active_elements():find("/target_type/paletteElementType/paletteElement")
end

function get_palette_element_type()
	return utilities.active_elements():find("/target_type/paletteElementType")
end

function get_element_styles()
	local obj_type = u.get_elem_type_from_compartment(u.get_selected_obj_type())
	return get_style_names_from_object(obj_type, "/elemStyle")
end

function get_compart_styles()
	return get_style_names_from_object(u.get_selected_obj_type(), "/compartStyle")
end

function get_style_names_from_object(obj, path)
	local res = {}
	obj:find(path):each(function(style)
		table.insert(res, lQuery(style):attr_e("id"))
	end)
	u.add_configurator_comboBox(res)
end

function set_notation_field()
	local table = d.get_component_by_id("click_box_table")
	table:find("/selectedRow/vTableCell"):find("/componentType")
end

function close_configurator_form()
	u.log_button_press("Close")
	local active_elem = utilities.active_elements()
	active_elem:find("/compartment"):find("/compartType")
	relink_palette(active_elem)
	--if active_elem:filter(".Edge"):size() == 0 and active_elem:filter(".FreeLine"):size() == 0 and active_elem:filter(".Port"):size() == 0 then
	--	manage_element_properties(active_elem)
	--end
	u.add_command_without_diagram(active_elem, "OkCmd", {})
	utilities.close_form("configurator_form")
end

function relink_palette(elem)
	local palette_elem_type = elem:find("/target_type/paletteElementType")
	relink_palette_from_palette_elem_type(palette_elem_type)
end

function relink_palette_from_palette_elem_type(palette_elem_type)
	if palette_elem_type:is_not_empty() then
		local palette_type = palette_elem_type:find("/paletteType")
		local nr = tonumber(palette_elem_type:attr("nr")) or math.huge
		if palette_type:find("/paletteElementType"):size() > 1 then
			palette_elem_type:remove_link("paletteType", palette_type)	
			local palette_elems = palette_type:find("/paletteElementType")
			local min_nr = tonumber(palette_elems:filter(":first()"):attr("nr")) or math.huge
			local max_nr = tonumber(palette_elems:filter(":last()"):attr("nr")) or math.huge
			if nr < min_nr then
				palette_type:remove_link("paletteElementType", palette_elems)
				palette_elem_type:link("paletteType", palette_type)
				palette_type:link("paletteElementType", palette_elems)
			elseif nr > max_nr then
				palette_elem_type:link("paletteType", palette_type)
			else	
				local is_added = false
				palette_elems:each(function(tmp_palette_elem_type)
					if (tonumber(tmp_palette_elem_type:attr("nr")) or math.huge) >= nr and not(is_added) then
						tmp_palette_elem_type:remove_link("paletteType", palette_type)
						palette_elem_type:link("paletteType", palette_type)
						tmp_palette_elem_type:link("paletteType", palette_type)
						is_added = true
					elseif (tonumber(tmp_palette_elem_type:attr("nr")) or math.huge) >= nr and is_added then
						tmp_palette_elem_type:remove_link("paletteType", palette_type)
						tmp_palette_elem_type:link("paletteType", palette_type)	
					end		
				end)
			end
		end
		relink_palette_elements(palette_type)
		utilities.execute_cmd("AfterConfigCmd")
	end
end

function relink_palette_elements(palette_type)
	palette_type:find("/presentationElement"):each(function(palette)
		palette:find("/paletteElement"):delete()
		palette_type:find("/paletteElementType"):each(function(palette_elem_type)
			utilities.add_element_to_base(palette, "PaletteElement", "paletteElement", palette_elem_type)
		end)
		palette:find("/paletteElement")
	end)
end

function relink_compart_types()
	local tree = d.get_component_by_id("Tree")
	traverse_tree_node_children(tree:find("/treeNode"), "compartType")
end

function traverse_tree_node_children(tree_node, role)
	local parent_type = tree_node:find("/type")
	tree_node:find("/childNode"):each(function(child_node)	
		local compart_type = child_node:find("/type")
		conf_dialog.relink_to_parent(parent_type, role, compart_type)
		traverse_tree_node_children(child_node, "subCompartType")
	end)
end

function make_compartType_tree_nodes1(treeNode, source_type, path, tree_link)
	if source_type ~= nil then
		source_type:find(path):each(function(obj_type)
			local caption = obj_type:attr("caption")
			local added_node = d.add_tree_node(treeNode, tree_link, {id = caption, text = caption, expanded = "true"}):link("type", obj_type)
			make_compartType_tree_nodes(added_node, obj_type, "/subCompartType", "parentNode")
		end)
	end
end

function make_free_component_box(container)
	local right_vertical_box = d.add_component(container, {id = "free_component_vertical_box", horizontalAlignment = -1}, "D#VerticalBox")	
		d.add_component(right_vertical_box, {caption = "Components"}, "D#Label")
		d.add_component_with_handler(right_vertical_box, {id = 'components'}, "D#ListBox", {})
end

function get_property_diagrams()
	u.add_lQuery_configurator_comboBox(u.make_combo_box_item_table(utilities.active_elements():find("/target_type/propertyDiagram"), "id"))
end

function update_property_listboxes()
	local listbox1 = d.get_component_by_id("diagram_components")
	add_items(listbox1, get_property_diagram_components())
	d.execute_d_command(listbox1, "Refresh")
	local listbox2 = d.get_component_by_id("diagram_component_components")
	local listbox3 = d.get_component_by_id("free_component_vertical_box")
end

function add_items(box, value_table)
	for _, value in pairs(value_table) do
		box:link("item", lQuery.create("D#Item", {value = value}))
	end
end

function get_property_diagram_components()
	local list = {}
	get_property_diagram_items("/target_type/propertyDiagram/propertyTab", "caption", list)
	get_property_diagram_items("/target_type/propertyDiagram/propertyRow", "id", list)
return list
end

function get_property_diagram_items(path, attr, list)
	utilities.active_elements():find(path):each(function(obj)
		obj = lQuery(obj)
		table.insert(list, obj:attr_e(attr))
	end)	
end

function close_form()
	u.log_button_press("Close")
	utilities.close_form("form")
end

function set_attribute_compart(elem)
	local attr_compart_type = elem:find("/elemType/compartType:has([id = 'AS#Attributes'])")
	local compart_table = {}
	elem:find("/compartment"):each(function(compart)
		if compart:find(":has(/compartType[id = 'AS#Attributes'])/element/elemType[id = 'Box']"):size() > 0 then
			local compart_style = compart:find("/compartStyle")
			local compart_type_caption = compart:find("/target_type"):attr_e("id")
			local value = get_compart_sub_tree(compart, "")
			compart:attr({input = compart_type_caption, value = compart_type_caption})
			compart:remove_link("element", elem)
		end
	end)
	local compart_table = {}
	make_compart_type_table(elem:find("/target_type"), "/compartType", compart_table)
	for i, compart in pairs(compart_table) do
		local compart_type = compart:find("/target_type")
		local val = ""
		local start, finish = string.find(compart_type:attr("id"), "ASFictitious")
		if start == 1 and finish == 12 then
			val = get_compart_sub_tree(compart_type, "")
		else
			val = compart_type:attr("id") .. get_compart_sub_tree(compart_type, "\n   ")
		end
		compart:link("element", elem)
		if compart:attr("isInvisible") == "true" then
			compart:attr({input = "", value = val})
		else
			compart:attr({input = val, value = val})
		end
	end
end

function get_compart_sub_tree(compart_type, distance)
	local tmp = ""
	compart_type:find("/subCompartType"):each(function(sub_compart_type)
		local start, finish = string.find(sub_compart_type:attr("id"), "ASFictitious")
		if start == 1 and finish == 12 then
			tmp = tmp .. get_compart_sub_tree(sub_compart_type, distance)
		else
			local new_distance = ""
			if distance == "" then
				new_distance = "\n" .. "   "
			else
				new_distance = distance .. "   "
			end
			tmp = tmp .. distance .. sub_compart_type:attr("id") .. get_compart_sub_tree(sub_compart_type, new_distance)
		end
	end)
	return  tmp
end

function make_compart_type_table(elem_type, path, compart_type_table)
	elem_type:find(path):each(function(compart_type)
		local compart = compart_type:find("/presentation")
		if compart:is_not_empty() then
			table.insert(compart_type_table, compart)
		end
	end)
end

function get_configurator_box_compart(id, elem, get_compart_func)
	local compart = get_compart_func(elem)
	if compart:size() == 0 then
		compart = elem:find("/elemType/compartType/compartment:has(/compartType[id = '" .. id .. "'])")
		compart:link("element", elem)
	end
return compart
end

function set_compart_names(parent, role, prefix)
	local attr_value = ""
	parent:find(role):each(function(compart_type)
		compart_type = lQuery(compart_type)
		attr_value = attr_value .. prefix .. concat_compartment_names(compart_type, attr_value) .. set_compart_names(compart_type, "/subCompartType", prefix .. "\t")
	end)
return attr_value
end

function concat_compartment_names(compart_type)
	local attr_value = ""
	local compart_name = compart_type:attr_e("caption")
	if compart_name ~= "" then
		return attr_value .. compart_name .. "\n"
	end
end
	
function box_style_properties()
	box_style_properties_element(utilities.active_elements())
end

function box_style_properties_element(element)
	local form = d.add_form({id = "form", caption = "Box Style", minimumWidth = 70, minimumHeight = 50})
		u.add_input_field_function(form, "Name", "id", element:find("/elemStyle"), "lua.configurator.configurator.update_style_id")	
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")	
	local style_button = d.add_button(button_box, {id = "style_button", caption = "Style"}, {Click = "lua.configurator.style.open_style_form()"})
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
	d.show_form(form)
end

function update_style_id()
	local _, value = u.get_event_source_attrs("text")
	utilities.active_elements():find("/elemStyle"):attr({id = value, caption = value})
end

function list_of_components_from_container(container, field_list)
	local list_of_fields = {}
	for i, val in pairs(field_list) do
		container:find("/component[id = 'row_" .. val .. "']"):each(function(box)
			field = lQuery(box):find("/composition/composition[id = '" .. val .. "']")
			list_of_fields[val] = field
		end)
	end
return list_of_fields
end

function list_of_object_values(obj, attr_list)
	local res = {}
	for i, val in pairs(attr_list) do
		res[val] = obj:attr_e(val)
	end
return res
end

function check_field_value()
	d.check_field_value_int_and_chars({""})
end

function check_multiplicity_field()
	d.check_field_value_int_and_chars({"*", ""})
end

function move_line_type(edge, new_elem, old_elem)
	local old_elem_type = old_elem:find("/target_type")
	local new_elem_type = new_elem:find("/target_type")
	local edge_type = edge:find("/target_type")
	if edge:find("/start"):id() == new_elem:id() then
		process_move_line_pairs(edge_type, new_elem_type, old_elem_type, "start")	--start moved
	elseif edge:find("/end"):id() == new_elem:id() then
		process_move_line_pairs(edge_type, new_elem_type, old_elem_type, "end")		--end moved
	else
		print("Error in move line")
	end
end

function process_move_line_pairs(edge_type, new_type, old_type, role)
	local buls = "false"
	edge_type:remove_link(role, old_type)
		:link(role, new_type)
end

function move_specialization(edge, new_elem, old_elem)
	local old_type = old_elem:find("/target_type")
	local new_type = new_elem:find("/target_type")
	local start_elem = edge:find("/start")
	local end_elem = edge:find("/end")
	local start_type = start_elem:find("/target_type")
	local end_type = end_elem:find("/target_type")
	if start_elem:id() == new_elem:id() then	--start moved
		old_type:remove_link("supertype", end_type)
		new_type:link("supertype", end_type)
	elseif end_elem:id() == new_elem:id() then	--end moved
		old_type:remove_link("subtype", start_type)
		start_type:link("supertype", new_type)		
	else
		print("Error in move specialization")
	end
end

function check_id_field_syntax()
	local _, value = u.get_event_source_attrs("text")
	local field, _ = u.get_event_source()
	local grammer = re.compile[[grammer <- ({[a-zA-Z0-9_]*})]]
	local res = re.match(value, lpeg.Ct(grammer) * -1)
	if type(res) == "table" then
		
		local bool, hint = check_ID_uniqness(value)
		if bool then
			set_elem_style_id()
			update_ID_field()
			d.set_field_ok(field)
		else
			field:attr({outlineColor = "255", hint = hint})
		end
	else
		field:attr({outlineColor = "255", hint = "Error: ID field may contain only characters from range [a-zA-Z0-9_]"})
	end
	utilities.refresh_form_component(field)
end

function check_ID_uniqness(id)
	local obj_type = u.get_selected_obj_type()
	local role_to_parent = "graphDiagramType"
	local role_to_child = "elemType"
	if obj_type:filter(".CompartType"):is_not_empty() then
		role_to_parent = "elemType"
		role_to_child = "compartType"
	end
	local tmp_type = obj_type:find("/" .. role_to_parent .. "/" .. role_to_child .. "[id = " .. id .. "]")
	if tmp_type:is_not_empty() and tmp_type:id() ~= obj_type:id() then
		return false, "Error: Violated unique ID constraint"
	else
		return true
	end
end

function set_diagram_translets()
	local attr, value = u.get_event_source_attrs("text")
	local diagram_type = utilities.current_diagram():find("/target_type")
	local translet = diagram_type:find("/translet[extensionPoint = '" .. attr .. "']")
	if value == "" then
		translet:delete()
	else
		if translet:is_empty() then
			cu.add_translet_to_obj_type(diagram_type, attr, value)
		else	
			translet:attr({procedureName = value})
		end
	end
end

function set_model_diagram_name()
	local form = d.add_form({id = "form", caption = "Diagram Name", minimumWidth = 120})
	local diagram = utilities.current_diagram()
	u.add_input_field_function(form, "Name", "caption", diagram, "lua.configurator.configurator.update_model_diagram_caption")
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")	
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
	d.show_form(form)
end

function update_model_diagram_caption()
	local diagram = utilities.current_diagram()
	local _, value = u.get_event_source_attrs("text")
	utilities.set_diagram_caption(diagram, value)
	d.delete_event()	
end

--Loggging functions

function log_configurator_field(name, list)
	report.event("Field " .. name, list)
end

function log_list_box(list)
	report.event("ListBox", list)
end

function remove_diagram_type_with_elem_types(diagram_type)
	diagram_type:find("/elemType"):each(function(elem_type)
		configurator_delete.delete_elem_type(elem_type)	
	end)
	configurator_delete.delete_diagram_type(diagram_type)
end

--toolbar for old versions
function make_repozitory_class_diagram()
	toolbar.make_repozitory_class_diagram()
end

function edit_head_engine()
	toolbar.edit_head_engine()
end

function edit_tree_engine()
	toolbar.edit_tree_engine()
end

function edit_project_object()
	toolbar.edit_project_object()
end

-- popup for old versions
function add_diagram_toolbar()
	popup.add_diagram_toolbar()
end

function add_diagram_popUp()
	popup.add_diagram_popUp()
end

function add_diagram_key_shortcuts()
	popup.add_diagram_key_shortcuts()
end

function diagram_style()
	popup.diagram_style()
end

function generate_instances(source_diagram_type)
	popup.generate_instances(source_diagram_type)
end

function add_diagram_translets()
	popup.add_diagram_translets()
end

--delete for old versions
function delete_elem_type_from_configurator(element)
	configurator_delete.delete_elem_type_from_configurator(element)
end

--copy for old versions
function configurator_seed_copied(elem)
	return copy.configurator_seed_copied(elem)
end

function configurator_elem_copied(elem)
	return copy.configurator_elem_copied(elem)
end

function copy_target_diagram()
	return copy.copy_target_diagram()
end

--delete for old versions
function delete_specialization(elem)
	configurator_delete.delete_specialization(elem)
end

--make toolbar for old versions
function make_toolbar(diagram_type)
	popup.make_toolbar(diagram_type)
end