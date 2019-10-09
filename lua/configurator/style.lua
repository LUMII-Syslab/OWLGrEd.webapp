module(..., package.seeall)

cu = require("configurator.configurator_utilities")
const_utilities = require("configurator.const.const_utilities")
d = require("dialog_utilities")
report = require("reporter.report")


function add_new_style()
	cu.log_button_press("Styles")
	local elem = utilities.active_elements()
	if elem:filter(".Edge"):is_not_empty() then
		add_style_form("Line Styles")
	elseif elem:filter(".Node"):is_not_empty() then
		add_style_form("Box Styles")
	elseif elem:filter(".Port"):is_not_empty() then
		add_style_form("Port Styles")
	elseif elem:filter(".FreeBox"):is_not_empty() then
		add_style_form("FreeBox Styles")
	elseif elem:filter(".FreeLine"):is_not_empty() then
		add_style_form("FreeLine Styles")
	end
end

function add_style_line()
	add_style_form("Line Styles")
end

function add_style_port()
	add_style_form("Port Styles")
end

function add_style_free_box()
	add_style_form("FreeBox Styles")
end

function add_style_free_line()
	add_style_form("FreeLine Styles")
end

function add_style_box()
	add_style_form("Box Styles")
end

function add_style_form(form_caption)
	cu.log_button_press({Button = "Add", Context = "Add Style"})
	local form = d.add_form({id = "form", caption = form_caption, minimumWidth = 300, minimumHeight = 100})
	local row = d.add_component(form, {id = "list_box_edit_button_row", horizontalAlignment = 0, verticalAlignment = -1}, "D#HorizontalBox")
		local list_box = d.add_component(row, {id = "elem_style_list_box", horizontalAlignment = 0, minimumWidth = 220, minimumHeight = 150}, "D#ListBox")
		d.add_event_handlers(list_box, {Change = "lua.configurator.style.change_style()"})
		local vertical_row = d.add_component(row, {id = "vertical_box", verticalAlignment = -1}, "D#VerticalBox")
		local edit_button = d.add_button(vertical_row, {id = "edit_style_button", caption = "Style"}, {Click = "lua.configurator.style.edit_style()"})
		local edit_name_button = d.add_button(vertical_row, {id = "edit_style_name_button", caption = "Rename"}, {Click = "lua.configurator.style.edit_style_name()"})
	local button_row = d.add_component(form, {id = "add_delete_buttons", horizontalAlignment = -1}, "D#HorizontalBox")
		local add_button = d.add_button(button_row, {id = "add_style_button", caption = "Add"}, {Click = "lua.configurator.style.add_style_name()"})
		local delete_button = d.add_button(button_row, {id = "delete_style_button", caption = "Delete"}, {Click = "lua.configurator.style.delete_elem_style()"})
		local close_row = d.add_component(button_row, {id = "add_delete_buttons", horizontalAlignment = 1}, "D#HorizontalBox")
			local close_button = d.add_button(close_row, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.style.close_elem_style_form()"})
	fill_elem_style_list_box(list_box)
	if list_box:find("/item"):size() == 1 then
		delete_button:attr({enabled = "false"})
	end
	d.show_form(form)
end

function get_elem_style_list_box()
	return d.get_component_by_id("elem_style_list_box")
end

function fill_elem_style_list_box(list_box) 
	fill_list_box(list_box, utilities.active_elements():find("/target_type/elemStyle"))
end

function fill_list_box(list_box, collection)
	collection:each(function(style)
		add_style_list_box_item(list_box, style)
	end)
	list_box:find("/item:first()"):link("parentListBox", list_box)
end

function add_style_list_box_item(list_box, style)
	local item = lQuery.create("D#Item", {value = style:attr_e("id"), style = style})
	list_box:link("item", item)
return item
end

function change_style()
	change_elem_style_from_list_box("selected")
end

function change_elem_style_from_list_box(path_to_item)
	set_style(utilities.active_elements(), path_to_item)
end

function set_style(active_elem, path_to_item)
	local elem_style = get_elem_style_list_box():find("/" .. path_to_item .. "/style")
	active_elem:remove_link("elemStyle")
	active_elem:link("elemStyle", elem_style)
	utilities.execute_cmd("OkCmd", {element = active_elem, graphDiagram = active_elem:find("/graphDiagram")})
end

function edit_style_name()
	cu.log_button_press("Rename")
	make_style_name_form(get_elem_style_list_box():find("/selected"):attr_e("value"), "close_update_elem_style", {}, "Style")
end

function delete_elem_style()
	cu.log_button_press({Button = "Delete", Context = "Delete Style"})
	delete_style_from_list_box(get_elem_style_list_box(), utilities.active_elements():find("/target_type"), 1, set_delete_button)
end

function delete_compart_style()
	cu.log_button_press("Delete")
	delete_style_from_list_box(get_compart_style_list_box(), cu.get_selected_type(), 0, set_edit_delete_button)
end

--this function has to be changed to use links instead of ids
function delete_style_from_list_box(list_box, source_type, nr, func_name)
	local active_item = list_box:find("/selected")
	active_item:find("/style"):delete()
	active_item:delete()
	local last_item = list_box:find("/item:last()")
	last_item:link("parentListBox", list_box)
	utilities.refresh_form_component(list_box)
	if list_box:find("/item"):size() == nr then
		func_name("false")
	end
	set_style(utilities.active_elements(), "item:last()")
end

--the function how it should work
function delete_style_from_list_box_with_link(list_box, source_type, role)
	local active_item = list_box:find("/selected")
	source_type:find(role .. "/elemStyle"):delete()
	active_item:delete()
	list_box:find("/item:last()"):link("parentListBox", list_box)
	utilities.refresh_form_component(list_box)
	if source_type:find(role):size() == 0 then
		set_style_edit_delete_button("false")	
	end
end

function make_style_name_form(name, function_name, handler_list, form_name)
	local form = d.add_form({id = "called_form", caption = form_name, minimumWidth = 70, minimumHeight = 50})
	d.add_row_labeled_field(form, {caption = "Name"}, {id = "style_name", text = name}, {id = "row_rename"}, "D#InputField", handler_list)
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")	
	local close_button = d.add_button(button_box, {id = "called_form_close_button", caption = "Close"}, {Click = "lua.configurator.style." .. function_name}):link("defaultButtonForm", form)
	d.show_form(form)
end

function add_style_name()
	cu.log_button_press({Button = "Add", Context = "Style Name"})
	local name = ""
	local elem = utilities.active_elements()
	if elem:filter(".Node"):size() > 0 then
		name = "NodeStyle"
	elseif elem:filter(".Edge"):size() > 0 then
		name = "EdgeStyle"
	elseif elem:filter(".FreeBox"):size() > 0 then
		name = "FreeBoxStyle"
	elseif elem:filter(".FreeLine"):size() > 0 then
		name = "FreeLineStyle"
	elseif elem:filter(".Port"):size() > 0 then
		name = "PortStyle"
	end
	local name = const_utilities.generate_unique_id(name, elem:find("/target_type"), "elemStyle")
	make_style_name_form(name, "close_create_new_elem_style", {}, "Style")
end

function close_elem_style_form()
	change_elem_style_from_list_box("item:first()")
	close_form()
end

function close_update_elem_style()
	local list_box = get_elem_style_list_box()
	local selected_item = list_box:find("/selected")
	local selected_name = selected_item:attr_e("value")
	local elem_name = d.get_component_by_id("style_name"):attr_e("text")
	local elem_style = selected_item:find("/style"):attr({id = elem_name})
	--local elem_style = get_target_elem_style_by_id(utilities.active_elements():find("/target_type"), selected_name):attr({id = elem_name})
	selected_item:attr({value = elem_name})
	utilities.refresh_form_component(list_box)
	local active_elem = utilities.active_elements()
	log_configurator_field("ElemStyle", {Name = elem_name})
	close_called_form()
end

function close_create_new_elem_style()
	local edge_name = d.get_component_by_id("style_name"):attr_e("text")
	local list_box = get_elem_style_list_box()
	local first_item_name = list_box:find("/item:first()"):attr_e("value")
	local element = utilities.active_elements()
	local target_type = element:find("/target_type")
	if target_type:find("/elemStyle[id = '" .. edge_name .. "']"):is_empty() then
		local elem_style = add_elem_style(target_type)
		local base_style = get_target_elem_style_by_id(element:find("/target_type"), first_item_name)
		elem_style:copy_attrs_from(base_style)
				:attr({id = edge_name, caption = edge_name})
		local new_item = add_style_list_box_item(list_box, elem_style)
		list_box:remove_link("selected")
			:link("selected", new_item)
		if target_type:find("/elemStyle"):size() == 2 then
			set_delete_button("true")	
		end
	else
		list_box:remove_link("selected")
			:link("selected", list_box:find("/item[value = '" .. edge_name .. "']"))
	end
	utilities.refresh_form_component(list_box)
	set_style(element, "item:first()")
	close_called_form()
end

function close_called_form()
	cu.log_button_press("Close")
	utilities.close_form ("called_form")
end

function edit_style()
	cu.log_button_press("Style")
	local active_elem = utilities.active_elements()
	local selected_item = get_elem_style_list_box():find("/selected")
	local style_name = selected_item:attr_e("value")
	local target_style = selected_item:find("/style")
	local elem_type = active_elem:find("/elemType")
	local elem_style = elem_type:find("/elemStyle")
	elem_type:link("elemStyle", elem_style)
	active_elem:remove_link("elemStyle", elem_style)
	active_elem:link("elemStyle", target_style)
	if active_elem:filter(".Node"):size() > 0 or active_elem:filter(".FreeBox"):size() > 0 then
		remove_box_compartments(active_elem)
	end
	cu.add_command_without_diagram(active_elem, "OkCmd", {})
	cu.add_command_without_diagram(active_elem, "DefaultStyleCmd", {})
	cu.add_command_without_diagram(active_elem, "StyleDialogCmd", {info = "SHAPE;lua_engine#lua.configurator.style.ok_style_dialog;"})
end

function remove_box_compartments(elem)
	local name_compart = cu.get_name_compart(elem)
	utilities.add_tag(name_compart, "UnLinked", name_compart:id(), true)
	elem:remove_link("compartment", name_compart)
end

function add_elem_style(elem_type, name)
	if elem_type:filter(".NodeType"):size() > 0 then 
		return cu.add_default_node_style(name, name):link("elemType", elem_type)
	elseif elem_type:filter(".EdgeType"):size() > 0 then 
		return cu.add_default_edge_style(name, name):link("elemType", elem_type)
	elseif elem_type:filter(".PortType"):size() > 0 then 
		return cu.add_default_port_style(name, name):link("elemType", elem_type)
	end
end

function get_target_elem_style_by_id(target_type, style_name)
	return target_type:find("/elemStyle[id = '" .. style_name .. "']")
end

function set_delete_button(val)
	utilities.refresh_form_component(d.get_component_by_id("delete_style_button"):attr({enabled = val}))
end

function ok_style_dialog()
	--lQuery("OKStyleDialogEvent"):delete()
	cu.log_button_press({Button = "OK", Context = "Style Box"})
	local dgr = utilities.current_diagram()
	local elem = utilities.active_elements()
	local style = elem:attr("style")
	local old_elem_style = utilities.make_elem_copy(elem:find("/elemStyle:first()"))
	utilities.execute_cmd("SaveStylesCmd", {graphDiagram = dgr})
	utilities.execute_cmd("AfterConfigCmd", {graphDiagram = dgr})
	local new_elem_style = elem:find("/elemStyle:first()")
	local list = utilities.get_object_difference(new_elem_style, old_elem_style)
	local target_type = elem:find("/target_type")	
	target_type:find("/element/graphDiagram"):each(function(target_dgr)
		utilities.save_dgr_cmd(target_dgr)
	end)
	local target_elems = elem:find("/target_type/element:has(/tag[key = 'ConfiguratorStyle'][value = 'true'])")
	utilities.set_elem_style(target_elems, list)
	if elem:filter(".Node"):size() > 0 or elem:filter(".FreeBox"):size() > 0 or elem:filter(".Edge"):size() > 0 then
		local name_compart = get_unlinked_box_freebox_compartments(elem)
		elem:find("/compartment"):delete()
		elem:link("compartment", name_compart)
			--:link("compartment", attr_compart)
	end
	remove_tags(elem)
end

function remove_tags(source)
	source:find("/target_type/element/tag[key = 'ConfiguratorStyle'][value = 'true']"):delete()
end

function cancel_style_dialog()
	cu.log_button_press({Button = "Cancel", Context = "Style Box"})
	local elem = utilities.active_elements()
	local name_compart = get_unlinked_box_freebox_compartments(elem)
	local name_value = elem:find("/target_type"):attr_e("id")
	elem:find("/compartment"):delete()
	elem:link("compartment", name_compart)
	name_compart:attr({input = name_value, value = name_value})
	update_diagram_names_from_compart(name_compart)
	remove_tags(elem)
end

function compartment_style(container, obj_type)
	local group_box = d.add_component(container, {id = "table_id", caption = "Styles"}, "D#GroupBox")
	local row = d.add_component(group_box, {id = "list_box_edit_button_row", horizontalAlignment = 0, verticalAlignment = -1}, "D#HorizontalBox")
		local list_box = d.add_component(row, {id = "compart_style_list_box", horizontalAlignment = 0, minimumWidth = 220, minimumHeight = 150}, "D#ListBox")
		local v_box = d.add_component(row, {id = "vertical_box", horizontalAlignment = 0, verticalAlignment = -1}, "D#VerticalBox")
			local edit_button = d.add_button(v_box, {id = "edit_style_button", caption = "Style"}, {Click = "lua.configurator.style.edit_compart_style"})
			local rename_button = d.add_button(v_box, {id = "rename_style_button", caption = "Rename"}, {Click = "lua.configurator.style.make_compart_style_form"})
	local add_delete_row = d.add_component(group_box, {id = "add_delete_buttons", horizontalAlignment = 0}, "D#HorizontalBox")
		local add_button = d.add_button(add_delete_row, {id = "add_compart_style_button", caption = "Add"}, {Click = "lua.configurator.style.add_compart_style()"})
		local delete_button = d.add_button(add_delete_row, {id = "delete_style_button", caption = "Delete"}, {Click = "lua.configurator.style.delete_compart_style()"})
	fill_compart_style_list_box(list_box)
	if list_box:find("/item"):size() == 0 then
		delete_button:attr({enabled = "false"})
		edit_button:attr({enabled = "false"})
	end
end

function make_compart_style_form()
	cu.log_button_press("Rename")
	local list_box = d.get_component_by_id("compart_style_list_box")
	local selected_node = list_box:find("/selected")
	make_style_name_form(selected_node:attr("value"), "close_rename_compart_style", {}, "Rename")
end

function close_rename_compart_style()
	local value = d.get_component_by_id("style_name"):attr("text")
	local list_box = d.get_component_by_id("compart_style_list_box")
	local selected_node = list_box:find("/selected")
	selected_node:find("/style"):attr({id = value})
	selected_node:attr({value = value})
	utilities.refresh_form_component(list_box)
	close_called_form()
end

function get_compart_style_names()
	cu.add_lQuery_configurator_comboBox(cu.make_combo_box_item_table(cu.get_selected_type():find("/compartStyle"), "caption"))
end

function update_compart_style()
	local id, val = cu.get_event_source_attrs("text")
	log_configurator_field(id, {Name = val})
	get_compart_style_list_box():find("/selected/style"):attr(id)
	d.delete_event()
end

function add_compartment_style_field_text(container, object, field_name, id, handler_list)
	if handler_list == nil then
		add_compartment_style_field_table(container, object, field_name, id, {FocusLost = "lua.configurator.style.update_compart_style"})
	else
		add_compartment_style_field_table(container, object, field_name, id, handler_list)
	end
end

function add_compartment_style_field(container, object, field_name, id)
	add_compartment_style_field_table(container, object, field_name, id, {FocusLost = "lua.configurator.style.update_compart_style", Change = "lua.configurator.configurator.check_field_value"})
end

function add_compartment_style_field_table(container, object, field_name, id, table)
	cu.add_input_field_event_function(container, field_name, id, object, table)
end


function fill_compart_style_list_box(listbox)
	fill_list_box(listbox, cu.get_selected_type():find("/compartStyle"))
end

function compart_style_form(compart_style)
	local form = d.add_form({id = "called_form", caption = "Compartment Style", minimumWidth = 70, minimumHeight = 50})
	add_compartment_style_field_text(form, compart_style, "Name", "id")	
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
	local close_button = d.add_button(button_box, {id = "called_form_close_button", caption = "Close", enabled = "true"}, {Click = "lua.configurator.style.close_style_compart_form()"}):link("defaultButtonForm", form)
	d.show_form(form)
end

function check_compart_style()
	local _, value = cu.get_event_source_attrs("text")
	local compart_type = cu.get_selected_type()
	local tmp_compart_style = compart_type:find("/compartStyle[id = '" .. value .. "']")
	local list_box = get_compart_style_list_box()
	local selected_item = list_box:find("/selected")
	local style_name = selected_item:attr_e("value")
	local compart_style = compart_type:find("/compartStyle[id = '" .. style_name .. "']:last()")
	local close_button = d.get_component_by_id("called_form_close_button")
	local enabled = "true"
	if tmp_compart_style:is_not_empty() and style_name ~= value then
		enabled = "false"
	end
	compart_style:attr({id = value})
	selected_item:attr({value = value})
	if close_button:is_not_empty() then
		utilities.refresh_form_component(close_button:attr({enabled = enabled}))
	end
	utilities.refresh_form_component(list_box)
end

function edit_compart_style()
	cu.log_button_press("Style")
	d.delete_event()
	local active_elem = utilities.active_elements()
	local selected_item = get_compart_style_list_box():find("/selected")
	local style_id = selected_item:attr_e("value")
	local compart_style = selected_item:find("/style")
	remove_box_compartments(active_elem)
	active_elem:link("compartment", lQuery.create("Compartment", {}):link("compartStyle", compart_style))
	utilities.refresh_element_without_diagram(active_elem)
	cu.add_command_without_diagram(active_elem, "DefaultStyleCmd", {})
	cu.add_command_without_diagram(active_elem, "StyleDialogCmd", {info = "COMPARTMENT;lua_engine#lua.configurator.style.ok_compart_style_dialog;lua_engine#lua.configurator.style.cancel_compart_style_dialog"})
end

function ok_compart_style_dialog()
	cu.log_button_press({Button = "OK", Context = "Compartment Style Dialog"})
	local elem = utilities.active_elements()
	local dgr = elem:find("/graphDiagram")
	utilities.execute_cmd("SaveStylesCmd", {graphDiagram = dgr})
	utilities.execute_cmd("AfterConfigCmd", {graphDiagram = dgr})
	process_compart_style_dialog()
end

function cancel_compart_style_dialog()
	process_compart_style_dialog()
end

function process_compart_style_dialog()
	cu.log_button_press({Button = "Cancel", Context = "Compartment Style Dialog"})
	local elem = utilities.active_elements()
	local name_compart = get_unlinked_box_freebox_compartments(elem)
	elem:find("/compartment"):delete()
	elem:link("compartment", name_compart)
end

function add_compart_style()
	cu.log_button_press("Add")
	d.delete_event()
	local list_box = get_compart_style_list_box()
	d.add_list_comb_box(list_box, name)
	local selected_item = list_box:find("/selected")
	local name = const_utilities.generate_unique_id("Style", cu.get_selected_type(), "compartStyle")
	local compart_style = cu.add_default_compart_style(name, name):link("compartType", cu.get_selected_type())
									:link("item", selected_item)
	if list_box:find("/item"):is_not_empty() then
		set_edit_delete_button("true")
	end
	utilities.refresh_form_component(list_box)
	compart_style_form(compart_style)
end

function close_style_compart_form()
	local name = d.get_component_by_id_in_depth(lQuery("D#Form[id = 'called_form']"), "id"):attr_e("text")
	local list_box = get_compart_style_list_box()
	local item = list_box:find("/selected")
	item:attr({value = name})
	utilities.refresh_form_component(list_box)
	close_called_form()
	d.delete_event()
end

function get_compart_style_list_box()
	return lQuery("D#ListBox[id = 'compart_style_list_box']")
end

function set_edit_delete_button(val)
	local delete_button = d.get_component_by_id_in_depth(lQuery("D#Form[id = 'configurator_form']"), "delete_style_button"):attr({enabled = val})
	local edit_button = d.get_component_by_id_in_depth(lQuery("D#Form[id = 'configurator_form']"), "edit_style_button"):attr({enabled = val})
	utilities.refresh_form_component(delete_button)
	utilities.refresh_form_component(edit_button)
end

function open_style_form()
	cu.log_button_press("Symbol")
	local element = utilities.active_elements()
	local diagram = element:find("/graphDiagram")

	remove_box_compartments(element)

	element:find("/compartment"):delete()
	make_configurator_element_compartments(element, element:find("/target_type"), "compartType")
	
	utilities.save_dgr_cmd(diagram)
	
	local style = element:attr("style")
	local target_type = element:find("/target_type")
	target_type:find("/element/graphDiagram"):each(function(dgr)
		utilities.save_dgr_cmd(dgr)
	end)
	local target_elems = target_type:find("/element[style = '" .. style .. "']")
	add_style_tags(target_elems)

	--diagram:link("command", utilities.execute_cmd("AfterConfigCmd"))
	--add_command(element, diagram, "OkCmd", {})
	
	add_command(element, diagram, "DefaultStyleCmd", {})
	add_command(element, diagram, "StyleDialogCmd", {info = ";lua_engine#lua.configurator.style.ok_style_dialog;lua_engine#lua.configurator.style.cancel_style_dialog"})
end

function add_style_tags(elems)
	utilities.add_tag(elems, "ConfiguratorStyle", "true")
end

function make_configurator_element_compartments(element, base_type, role_to_compart_type)
	base_type:find("/" .. role_to_compart_type):each(function(compart_type)
		if compart_type:attr("isGroup") == "true" then
			make_configurator_element_compartments(element, compart_type, "subCompartType")
		else
			local compart = lQuery.create("Compartment", {value = value,
									isGroup = compart_type:attr("isGroup"),
									element = element,
									compartStyle = compart_type:find("/compartStyle:first()")})
		end
	end)
end

function update_diagram_names_from_compart(compart)
	local value = compart:attr_e("input")
	local elem = utilities.get_element_from_compartment(compart)
	local diagram = elem:find("/target")
	if diagram:is_not_empty() then
		diagram:attr({caption = value})
		diagram:find("/target_type"):attr({id = value})
	end
end

function get_unlinked_box_freebox_compartments(elem)
	--return elem:find("/elemType/compartType[id = 'AS#Name']/compartment")--, elem:find("/elemType/compartType[id = 'AS#Attributes']/compartment:not(:has(/element))")
	local key = lQuery("Tag[key = 'UnLinked']")
	local compart = key:find("/thing")
	key:delete()
	return compart
end

function close_form()
	cu.log_button_press("Close")
	utilities.close_form("form")
end

function log_configurator_field(name, list)
	report.event("Field " .. name, list)
end

function add_command(elem, diagram, command_name, attr_table)
	local cmd = lQuery.create(command_name, attr_table)
	cmd:link("element", elem)
		:link("graphDiagram", diagram)
	utilities.execute_cmd_obj(cmd)
end