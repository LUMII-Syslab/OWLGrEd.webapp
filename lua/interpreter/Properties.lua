module(..., package.seeall)
require("utilities")
require("lQuery")
d = require("dialog_utilities")
require("re")
Delete = require("interpreter.Delete")
report = require("reporter.report")

function Properties()
	local elem = utilities.active_elements()
	if elem:size() == 1 then
		if is_property_diagram_empty(elem) == "false" then	
			local elem_type = elem:find("/elemType")
			local form, prop_dgr = generate_property_diagram(elem_type, elem)
			populate_dialog_form(form, elem, prop_dgr)
			d.show_form(form)
		end
	end
end

function generate_property_diagram(obj_type, compart)
	local prop_dgr = obj_type:find("/propertyDiagram")
	if prop_dgr:is_empty() then
		prop_dgr = obj_type:find("/parentCompartType/propertyDiagram")
	end
	local form = generate_property_diagram_from_prop_dgr(prop_dgr, compart)
	--add_event_handlers(prop_dgr, form)
	return form, prop_dgr
end

function get_property_diagram_name(compart)
	local compart_type = compart:find("/elemType,/compartType"):attr("id")
	if compart_type == "Class" then
		return compart:find("/compartment:has(/compartType[id='Name'])"):attr("value")
	elseif compart_type == "Object" then
	    return compart:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
	elseif compart_type == "Attributes" then
		if compart:find("/subCompartment:has(/compartType[id='Name'])"):size() > 0 then return compart:find("/subCompartment:has(/compartType[id='Name'])"):attr("value") end
	end
	return ""
end

function generate_property_diagram_from_prop_dgr(prop_dgr, compart)
	local caption_name = ((prop_dgr:attr("caption") ~= "" and prop_dgr:attr("caption")) or prop_dgr:attr("id")) .. " " .. get_property_diagram_name(compart)
	local form = d.add_form({id = prop_dgr:attr("id"),
				caption = caption_name,
				readOnly = prop_dgr:attr("isReadOnly"),
				buttonClickOnClose = "true",
				horizontalAlignment = -1,
				verticalAlignment = 0,
				editable = set_form_edit_mode_from_active_diagram(),
				preferredHeight = prop_dgr:attr("height"),
				preferredWidth = prop_dgr:attr("width"),
				propertyElement = prop_dgr,
				presentationElement = compart})
	add_property_tabs(prop_dgr, form)
	add_property_rows(prop_dgr, form)
	add_close_button(prop_dgr, form)
	return form
end

function add_close_button(prop_dgr, form)
	local button_name = get_close_button_name()
	local hbox = d.add_component(form, {id = "HorizontalBox", horizontalAlignment = 1, maximumHeight = 0}, "D#HorizontalBox")
	local button = d.add_component(hbox, {id = "close_button", caption = button_name}, "D#Button")
	d.add_event_handlers(button, {Click = "lua.interpreter.Properties.close_form"})
	form:link("defaultButton", button)
return button, hbox
end

function get_close_button_name()
	local lang = utilities.get_project_language()
	local button_name = ""
	if lang == "lv" then
		button_name = "Aizvērt"
	elseif lang == "eng" then
		button_name = "Close"
	end
	return button_name
end

function close_form(ev)
	if (ev==nil) or (ev:size()==0) then
    ev = lQuery("D#Event")
  end
    local form = ev:find("/source/defaultButtonForm")
    if (form:size()==0) then
          local form = ev:find("/source")
    end
	local prop_dgr = form:find("/propertyElement")
	execute_handler_procedure(prop_dgr, "onClose", form)
	if (form:size()>0) then
            d.close_form(form:get(1).id)
        else
            d.close_form()
        end
	report.event("Button", {
		Button = "Close"
	})
end

function execute_handler_procedure(source, event_type, ...)
	local handler = get_handler(source, event_type)
	utilities.execute_translet(handler:attr("procedureName"), ...)
end

function get_handler(source, event_type)
	return source:find("/propertyEventHandler[eventType = " .. event_type .. "]")
end

function add_property_tabs(prop_dgr, form)
	local prop_tabs = prop_dgr:find("/propertyTab")
	if prop_tabs:is_not_empty() then
		prop_tabs:each(function(prop_tab)
			if utilities.execute_should_be_included(prop_tab) then
				local tab_container = get_tab_container(form)
				if tab_container:is_empty() then
					tab_container = d.add_component(form, {id = "TabContainer"}, "D#TabContainer")
					d.add_event_handlers(tab_container, {TabChange = "lua.interpreter.Properties.tab_changed"})	
				end
				local tab = d.add_component(tab_container, {caption = prop_tab:attr("id"), 
									--readOnly = prop_tab:attr("isReadOnly"), 
									propertyElement = prop_tab,
									preferredHeight = prop_tab:attr("height"),
									preferredWidth = prop_tab:attr("width")		
							}, "D#Tab")
				add_property_rows(prop_tab, tab)
				add_focus_links(tab)
				--add_event_handlers(prop_tab, tab)
			end
		end)
	end
end

function get_tab_container(form)
	return form:find("/component"):filter(".D#TabContainer")
end

function tab_changed()
	local ev = lQuery("D#TabChangeEvent")
	local tab = ev:find("/tab")
	execute_handler_procedure(tab:find("/propertyElement"), "onShow", tab)
	tab:find("/component/component"):each(function(field)
		if field:find("/compartment/compartType/propertyRow"):attr("isFirstRespondent") == "true" then
			set_as_first_respondent(field)
			utilities.refresh_form_component(field)
		end
	end)
	report.event("Tab Changed", {
		ChangedTo = tab:attr("caption")
	})
	d.delete_event(ev)
end

function add_property_rows(prop_elem, container)
	local group = add_relative_height_group(container)
	prop_elem:find("/propertyRow"):each(function(prop_row)
		add_property_row(prop_row, container)
	end)
end

function add_property_row(prop_row, container)
	local relative_group = container:find("/ownedGroup")
	if row_type == "TagRow" then
		local row_type = prop_row:attr("rowType")
		local row = d.add_component(container, {id = "taggedValues", 
							readOnly = prop_row:attr("isReadOnly"),
							maximumHeight = 0, 
							propertyElement = prop_row}, 
							"D#Row")
		local label_column = d.add_component(row, {id = "label_column", horizontalAlignment = 1}, "D#Column")
		local tag_column = d.add_component(row, {id = "tag_column"}, "D#Column")
		local column = d.add_component(row, {id = ""}, "D#Column")
	else
		local row = add_labeled_field_from_compart_type(prop_row, container)
		row:attr({minimumRelativeWidth = 888})
		if utilities.execute_should_be_included(prop_row) then
			fill_row(container, row, prop_row)
		end
	end
end

function make_field(row, prop_row, relative_group)
	local row_type = prop_row:attr("rowType")
	local min_width = prop_row:attr("width")
	if min_width == "" then
		min_width = 150
	end
	local min_height = prop_row:attr("height")
	if min_height == "" or min_height == nil then
		min_height = 100
	end
	local change_proc_name = get_function_name_from_property_element_handler(prop_row, "onChange")
	if change_proc_name ~= nil then
		change_proc_name = "lua." .. change_proc_name
	end
	local compart_type = prop_row:find("/compartType")
	local input = nil
	if row_type == "InputField" then
		input = add_field(row, "D#InputField", {minimumWidth = min_width, enabled = "true"}, {FocusLost = "lua.interpreter.Properties.update_presentation", Change = change_proc_name})
	elseif row_type == "CheckBox" then
		input = add_check_box_field(row, {minimumHeight = min_height, maximumWidth = 10000, caption = "", checked = "false", editable = "true", enabled = "true"}, {Change = "lua.interpreter.Properties.update_presentation"})
	elseif row_type == "ComboBox" or row_type == "StereotypeRow" then
		input = add_field(row, "D#ComboBox", {minimumWidth = min_width, enabled = "true", editable = prop_row:attr("isEditable")}, {FocusLost = "lua.interpreter.Properties.update_presentation", Change = "lua.interpreter.Properties.comboBox_changed", DropDown = "lua.interpreter.Properties.update_comboBox_items"})
	elseif row_type == "TextArea" then
		input = add_field(row, "D#TextArea", {minimumHeight = min_height, minimumWidth = min_width,  enabled = "true"}, {FocusLost = "lua.interpreter.Properties.update_presentation", Change = change_proc_name}, relative_group)
	elseif row_type == "InputField+Button" then
		input = add_field(row, "D#InputField", {minimumWidth = min_width, enabled = "true"}, {FocusLost = "lua.interpreter.Properties.update_presentation"})
		add_called_button(row, {id = "called_button", caption = "<-"}, {Click = "lua.interpreter.Properties.show_called_dgr"})
	elseif row_type == "ComboBox+Button" then
		input = add_field(row, "D#ComboBox", {minimumWidth = min_width, enabled = "true", editable = prop_row:attr("isEditable")}, {FocusLost = "lua.interpreter.Properties.update_presentation", Change = "lua.interpreter.Properties.comboBox_changed", DropDown = "lua.interpreter.Properties.update_comboBox_items"})
		add_called_button(row, {id = "called_button", caption = "<-"}, {Click = "lua.interpreter.Properties.show_called_dgr"})	
	elseif row_type == "TextArea+Button" then
		local min_height = prop_row:attr("height")
		if min_height == "" or min_height == nil then
			min_height = nil
		end
		input = add_field(row, "D#MultiLineTextBox", {minimumWidth = min_width, minimumHeight = min_height, maximumHeight = min_height, enabled = "true"}, {FocusLost = "lua.interpreter.Properties.update_presentation", MultiLineTextBoxChange = change_proc_name}, relative_group)
		add_called_button(row, {id = "called_button", caption = "<-"}, {Click = "lua.interpreter.Properties.show_called_dgr"})
	elseif row_type == "Label" then
		label = add_field(row, "D#Label", {minimumWidth = min_width, enabled = "true"}, {FocusLost = "lua.interpreter.Properties.update_presentation"}, relative_group)
		--hbox:attr({horizontalAlignment = -1})
		--label:link("container", row)
	elseif row_type == "TextArea+DBTree" then		
		input = add_field(row, "D#TextArea", {minimumWidth = min_width, enabled = "true", readOnly = "false"}, {FocusLost = "lua.interpreter.Properties.update_presentation"}, relative_group)
		local proc_name = get_function_name_from_property_element_handler(prop_row, "Click")
		add_called_button(row, {id = "called_button", caption = "<-"}, {Click = proc_name})
	elseif row_type == "CheckBox+Button" then
		local list_of_comparts = {}
		local parent_type = compart_type:find("/parentCompartType/parentCompartType")	
		local compart
		local parent = lQuery("Compartment[id = '']")
		local elem = utilities.active_elements()
		if parent_type:is_not_empty() then
			parent_type:find("/compartment"):each(function(compart)
			local tmp_elem = utilities.get_element_from_compartment(compart)
				if tmp_elem ~= nil and tmp_elem:id() == elem:id() then
					table.insert(list_of_comparts, compart)
				end
			end)
			if #list_of_comparts == 1 then
				parent = list_of_comparts[1]
			else
				for _, tmp_compart in ipairs(list_of_comparts) do
					local text_line = tmp_compart:find("/textLine")
					if text_line:find("/parentMultiLineTextBox"):is_not_empty() then
						parent = tmp_compart
						break
					end
				end
			end
			compart = parent:find("/subCompartment:has(/compartType[id = " .. compart_type:attr("id") .. "])")
		else
			parent_type = compart_type:find("/parentCompartType/elemType")
			parent = elem
			compart = parent:find("/compartment:has(/compartType[id = " .. compart_type:attr("id") .. "])")
		end
		if compart:is_empty() then
			compart = core.create_missing_compartment(parent, parent_type, compart_type)
			local check_box_fictious = compart:find("/parentCompartment")
			local check_box_fictious_type = check_box_fictious:find("/compartType")
			check_box_fictious_type:find("/subCompartType"):each(function(sub_compart_type)
				if sub_compart_type:id() ~= compart_type:id() then
					core.create_missing_compartment(check_box_fictious, check_box_fictious_type, sub_compart_type)
				end
			end)
		end
		input = add_check_box_field(row, {id = 'field', minimumHeight = min_height, maximumWidth = 10000, caption = "", checked = "false", editable = "true", enabled = "true"}, {Change = "lua.interpreter.Properties.update_presentation_from_check_box_expression"})
		compart:link("component", input)
		add_called_button(row, {id = "called_button", caption = "<-"}, {Click = "lua.interpreter.Properties.show_called_check_box_dgr"})
		--add_checkbox_expression_value_from_compartment(row, compart)
		input:attr({checked = compart:attr("value")})
	end
	if input ~= nil then
		--add_event_handlers(prop_row, row)
		if prop_row:attr("isFirstRespondent") == "true" then
			set_as_first_respondent(input)
		end
		local is_read_only = prop_row:attr("isReadOnly")
		if is_read_only ~= "true" then
			local is_read_only_translet = prop_row:find("/propertyEventHandler[eventType = 'procIsReadOnly']"):attr("procedureName")
			is_read_only = utilities.execute_translet(is_read_only_translet)
		end
		input:attr({id = "field", readOnly = is_read_only, preferredHeight = prop_row:attr("height"),
							preferredWidth = prop_row:attr("width")})
	end
end

function get_function_name_from_property_element_handler(prop_elem, event_name)
	return prop_elem:find("/propertyEventHandler[eventType = " .. event_name .. "]"):attr("procedureName")
end

function add_called_button(container, attr_table, handler_table)
	local hbox = d.add_component(container, {verticalAlignment = -1, horizontalAlignment = 1}, "D#HorizontalBox")
	return d.add_button(hbox, attr_table, handler_table), hbox
end

function comboBox_changed(ev) -- 	local ev = lQuery("D#Event")
	local combo_box = ev:find("/source")
	if combo_box:find("/selected"):is_not_empty() then
		update_presentation_from_component_helper(combo_box)
	end
	ev:delete()
end

function update_presentation_from_check_box_expression()
	local ev = lQuery("D#Event")
	local h_box = ev:find("/source/container")
	update_compartment_value_from_check_expression(h_box)
end

function update_presentation_from_combo_box(component)
	local row = nil
	if component:filter(".D#CheckBox"):is_not_empty() then
		row = component:find("/container")
	else
		row = component:find("/container")
	end
	update_presentation_from_component(row)
end

function update_comboBox_items()
	local ev = lQuery("D#Event")
	local component = ev:find("/source")
	local compart = component:find("/compartment")
	if compart:is_empty() then
		compart = create_missing_compartment_from_component(component, "/container/propertyElement/compartType")
	end
	update_comboBox_items_helper(component, compart)
end

function update_comboBox_items_from_user_function(combo_box, compart)
	local item_table = utilities.call_compartment_proc_thru_type(compart, "procGenerateItemsClickBox")
	if item_table ~= nil and #item_table > 0 then
		for _, val in pairs(item_table) do
			combo_box:link("item", lQuery.create("D#Item", {value = val}))
		end
	end
end

function update_comboBox_items_from_choiceItems(combo_box, compart)
	compart:find("/compartType/choiceItem"):each(function(choice_item)
		if utilities.execute_should_be_included(choice_item) then
			local item_val = choice_item:attr("value")
			combo_box:link("item", lQuery.create("D#Item", {value = item_val, choiceItem = choice_item}))
			if compart:attr("value") == item_val then
				combo_box:link("selected", item)
				--set_blocking_status_from_compartment(combo, compart)
			end
		end
	end)
end

function set_as_first_respondent(input)
	set_first_respondent(input, input, "true")
end

function set_first_respondent(component, container, bool)
	if container:filter(".D#Form"):is_not_empty() then
		container:link("focused", component)
		if bool == "true" then
			container:link("focusOrder", component)
		end
	--else
	--	set_first_respondent(component, container:find("/container"), bool)
	end
end

function add_field(container, component_type, attr_list, handler_list, relative_group)
	local component = lQuery.create(component_type, attr_list):link("container", container)
	d.add_event_handlers(component, handler_list)
	if relative_group ~= nil then
		container:link("relativeHeightGroup", relative_group)
			:attr({prefferedRelativeHeight = 1})
	end
return component
end

function add_check_box_field(container, attr_list, handler_list, relative_group)
	local hbox = lQuery.create("D#HorizontalBox", {minimumWidth = 250}):link("container", container)
	local component = lQuery.create("D#CheckBox", attr_list):link("container", hbox)
	d.add_event_handlers(component, handler_list)
	if relative_group ~= nil then
		container:link("relativeHeightGroup", relative_group)
	end
return component
end

function add_labeled_field_from_compart_type(prop_row, container)
	local row = d.add_component(container, {id = prop_row:attr("id"), preferredRelativeHeight=1, readOnly = prop_row:attr("isReadOnly"), propertyElement = prop_row}, "D#Row")
	--local label, hbox = add_row_values(row, prop_row)
	return row
end

function add_row_values(row, prop_row)
	local label, hbox = d.add_component_in_hbox(row, "D#Label", {id = "", caption = get_property_row_caption(prop_row)})
	return label, hbox
end

function get_property_row_caption(prop_row)
	--local compart_type = prop_row:find("/compartType")
	return prop_row:attr("caption")
end

function add_relative_height_group(component)
	return lQuery.create("D#Group", {owner = component})
end

function add_event_handlers(prop_obj, component)
	local event_table = {}
	prop_obj:find("/propertyEventHandler"):each(function(handler)
		event_table[handler:attr("eventType")] = handler:attr("procedureName")
	end)
	d.add_event_handlers(component, event_table)
end

function add_focus_links(tab)
	local focus_row = tab:find("/component:has(/propertyElement[isFirstRespondent=true])/component[text]")
	tab:link("focus", focus_row)
end

function set_form_edit_mode_from_active_diagram()
	local diagram = utilities.current_diagram()
	if diagram:attr("isReadOnly") == "true" then
		return "false"
	end
	return "true"
end

function is_property_diagram_empty(elem)
	if elem:filter(".Compartment"):is_not_empty() then
		elem:find("/compartType")
		if elem:find("/compartType/propertyDiagram/propertyRow"):is_not_empty() or elem:find("/compartType/propertyDiagram/propertyTab/propertyRow"):is_not_empty() 
			or elem:find("/compartType/parentCompartType/propertyDiagram/propertyRow"):is_not_empty() then
			return "false"
		else
			return "true"
		end
	else
		if elem:find("/elemType/propertyDiagram/propertyRow"):is_not_empty() or elem:find("/elemType/propertyDiagram/propertyTab/propertyRow"):is_not_empty() then
			return "false"
		else
			return "true"
		end
	end
end

function populate_dialog_form(form, elem, prop_dgr)
	elem:link("form", form)	
--populate_form_from_subcompartments(form, elem)
	--connect_element_children_generating_components(elem, form)
	local path = set_tree_traversal_values(elem)
	elem:find(path):each(function(compart)
		populate_form_from_compartment(form, compart)
	end)
	execute_handler_procedure(prop_dgr, "onOpen", form)
end

function connect_element_children_generating_components(elem, form)
	local elem_type = elem:find("/elemType")
	if elem_type:is_not_empty() then
		local path = set_tree_traversal_values(elem_type)
		elem_type:find(path):each(function(compart_type)
			if is_multiple_compartType(compart_type) == "true" then
				local component = get_form_component_corresponding_to_compartType(form, compart_type)
				component:link("generatorRoot", elem)
			end
		end)
	end
end

function get_form_component_corresponding_to_compartType(form, compart_type)
	local res_component = nil
	local buls = 0
	compart_type:find("/propertyRow"):each(function(prop_row)
		prop_row:find("/component"):each(function(component)
			if is_sub_component_of(component, form) == "true" and buls == 0 then
				buls = 1
				res_component = component
			end
		end)
	end)
	return res_component
end

function is_sub_component_of(component, parent_container)
	local container = component:find("/container")
	if container:is_empty() then
		return "false"
	else
		if parent_container:id() == container:id() then
			return "true"
		else
			return is_sub_component_of(component, container)
		end
	end
end

function set_tree_traversal_values(obj)
	if obj:filter(".Compartment"):is_not_empty() then
		return "/subCompartment"
	elseif obj:filter(".Node,.Edge,.Port,.FreeLine,.FreeBox,.Element"):is_not_empty() then
		return "/compartment"
	elseif obj:filter(".NodeType,.EdgeType,.PortType,.ElemType"):is_not_empty() then
		return "/compartType"
	elseif obj:filter(".CompartType"):is_not_empty() then
		return "/subCompartType"
	end
end

function get_component_type(component)
	local prop_elem = component:find("/propertyElement")
	if prop_elem:is_not_empty() then
		return prop_elem:attr("rowType")
	else
		return component:attr("type")
	end
end

function populate_form_from_compartment(form, compart)
	local row = get_component_corresponding_to_compartment(form, compart)
	if row ~= nil and row:is_not_empty() then
		local component_type = get_component_type(row)
		local component = row:find("/component[id = 'field']")
		if component_type == "InputField" then
			add_inputField_value_from_compartment(component, compart)
		elseif component_type == "CheckBox" then
			add_checkbox_value_from_compartment(row:find("/component/component[id = 'field']"), compart)
		elseif component_type == "ComboBox" then
			add_comboBox_value_from_compartment(component, compart)
		elseif component_type == "TextArea" then
			add_textArea_value_from_compartment(component, compart)
		elseif component_type == "InputField+Button" then
			add_inputField_value_from_compartment(component, compart)
		elseif component_type == "ComboBox+Button" then
			add_inputField_value_from_compartment(component, compart)			
		elseif component_type == "TextArea+Button" then
			add_multiLineTextBox_value_from_compartment(component, compart)
		elseif component_type == "TagRow" then
			compart:find("/compartType")
			add_tagged_values_from_compartment(row, compart)
		elseif component_type == "StereotypeRow" then
			add_comboBox_value_from_compartment(component, compart)
		elseif component_type == "Label" then
			add_label_value_from_compartment(row:find("/component[id = 'HorizontalBox']/component"), compart)
		elseif component_type == "TextArea+DBTree" then
			add_textArea_value_from_compartment(component, compart)
			--component:attr({readOnly = "true"})
		elseif component_type == "CheckBox+Button" then
			--add_checkbox_expression_value_from_compartment(row, compart)
		else
			--custom row
			--utilities.execute_translet(component_type, row, compart, form)
		end
	else
		populate_form_from_sub_compartments(form, compart)
	end
end

function add_checkbox_expression_value_from_compartment(row, compart)
	--local sub_compart = get_check_box_value_compartment(compart)
	local val = compart:attr("value")
	local check_box = row:find("/component/component[id = 'field']")
	check_box:attr({checked = val})
	compart:link("component", check_box)
end

function get_component_corresponding_to_compartment(form, compart)
	local compart_type = compart:find("/compartType")
	local res = nil
	local buls = 0
	compart_type:find("/propertyRow"):each(function(prop_row)
		local component = prop_row:find("/component")
		if is_sub_component_of(component, form) == "true" and buls == 0 then
			res = component
			buls = 1
		end
	end)
	return res
end

function add_inputField_value_from_compartment(input_field, compart)
	input_field:attr({text = compart:attr("value")})
	--set_blocking_status_from_compartment(input_field, compart)
	compart:link("component", input_field)
	validate_input(input_field, compart)
end

function add_checkbox_value_from_compartment(check_box, compart)
	check_box:attr({checked = compart:attr("value")})
	--set_blocking_status_from_compartment(check_box, compart)
	compart:link("component", check_box)
end

function add_comboBox_value_from_compartment(combo_box, compart)
	compart:link("component", combo_box)
	combo_box:attr({text = compart:attr("value")})
	--set_blocking_status_from_compartment(combo_box, compart)
	--update_comboBox_items_helper(combo_box, compart)
end

function update_comboBox_items_helper(component, compart)
	component:find("/item"):delete()
	update_comboBox_items_from_choiceItems(component, compart)
	update_comboBox_items_from_user_function(component, compart)
end

function add_textArea_value_from_compartment(text_area, compart)
	compart:link("component", text_area)
	text_area:attr({text = compart:attr("value")})
	--set_blocking_status_from_compartment(combo_box, compart)
	validate_input(text_area, compart)
end

function add_multiLineTextBox_value_from_compartment(multi_line_text_box, compart)
	compart:link("component", multi_line_text_box)
	compart:find("/subCompartment"):each(function(sub_compart)
		local val = sub_compart:attr("value")
		if val ~= nil and val ~= "" and val ~= "\n" then
			lQuery.create("D#TextLine", {text = val,
							multiLineTextBox = multi_line_text_box,
							compartment = sub_compart})
		end
	end)
end

function add_label_value_from_compartment(label, compart)
	local compart_type = compart:find("/compartType")
	local start_value = compart_type:attr("startValue")
	if start_value == "" then
		local action = compart_type:find("/translet[extensionPoint = 'procGenerateInputValue']"):attr("procedureName")	
		local tmp_start_value = utilities.execute_translet(action, utilities.get_element_from_compartment(compart))
		if tmp_start_value ~= nil then
			start_value = tmp_start_value
		end
	end
	local res = compart_type:attr("caption") .. " " .. start_value
	label:attr({caption = res})
end

function populate_form_from_sub_compartments(form, compart)
	connect_element_children_generating_components(compart, form)
	local path = set_tree_traversal_values(compart)
	compart:find(path):each(function(sub_compart)
		populate_form_from_compartment(form, sub_compart)
	end)
end

function validate_input(component, compart)
--vajag refresh pielikt
	local hint = utilities.call_compartment_proc_thru_type(compart, "procCheckCompartmentFieldEntered")
	if hint ~= "" and hint ~= nil then
		component:attr({outlineColor = 255, hint = hint})
	else
		component:attr({outlineColor = 536870911, hint = ""})
	end
end

function update_presentation(ev) --	local ev = lQuery("D#Event")
	local component = ev:find("/source")
	if component:is_not_empty() then
		update_presentation_from_component_helper(component)
		--recalculate_form(component)
		utilities.refresh_only_diagram(utilities.current_diagram())
	end
	d.delete_event(ev)
end

function recalculate_form(component)
	local compart = component:find("/compartment")
	local diagram = utilities.get_element_from_compartment(compart):find("/graphDiagram")
	recalculate_palette_and_toolbar(diagram)
	recalculate_rows(component)
end

function recalculate_rows(component)
	local active_form = d.get_form_from_component(component)
	local prop_diagram = active_form:find("/propertyElement")
	local is_tabs_changed = process_tabs(active_form)
	local is_rows_changed = process_rows(active_form)
	--populate_dialog_form(active_form, utilities.active_elements())
	if is_tabs_changed or is_rows_changed then
		--utilities.refresh_form_component(active_form)
	end
end

function process_tabs(active_form)
	local is_changed = false
	local prop_diagram = active_form:find("/propertyElement")
	prop_diagram:find("/propertyTab"):each(function(tab)
		local tab_container = get_tab_container(active_form)
		local tab_id = tab:attr("caption")
		local form_tab = d.get_component_from_container_by_attr_name(tab_container, "caption", tab_id)
		local is_included = utilities.execute_should_be_included(tab)
		is_included = true
		if is_included then
			local is_refresh_needed = true
			if form_tab:is_empty() then
				form_tab = d.add_component(tab_container, {caption = tab:attr("caption"), readOnly = tab:attr("isReadOnly") }, "D#Tab")
				is_changed = true
			end
			tab:find("/propertyRow"):each(function(row)
				if row:find("/component"):is_empty() then
					local form_row = add_labeled_field_from_compart_type(row, form_tab)
					utilities.refresh_form_component(form_row)
					is_changed = true
				end
				local tmp_changed = process_single_row(row, active_form)
				if tmp_changed then
					is_changed = true
				end
			end)
		else
			form_tab:find("/component"):filter(".D#Row"):each(function(form_row)
				process_should_be_included_row(form_row:find("/propertyElement"))
			end)
			if form_tab:is_not_empty() then
				local tab_container = form_tab:find("/container")
				d.delete_container_components(form_tab)
				form_tab:delete()
				utilities.refresh_form_component(tab_container)
				is_changed = true
			end
		end
	end)
	return is_changed
end

function process_rows(active_form)
	local is_changed = false
	local prop_diagram = active_form:find("/propertyElement")
	local counter = 0
	prop_diagram:find("/propertyRow"):each(function(row)
		counter = counter + 1
		local tmp_changed = process_single_row(row, active_form, counter)
		if tmp_changed then
			is_changed = true
		end
	end)
	return is_changed
end

function process_single_row(row, active_form)
	local is_included = utilities.execute_should_be_included(row)
	is_included = true
	local has_changed = false
	local form_row = row:find("/component")
	if is_included then
		if form_row:find("/component"):is_empty() then
			fill_row(active_form, form_row, row)
			utilities.refresh_form_component(form_row)
			has_changed = true
		end
	else
		process_should_be_included_row(row)
		if form_row:find("/component"):is_not_empty() then
			d.delete_container_components(form_row)
			utilities.refresh_form_component(form_row)
			has_changed = true
		end
	end
	return has_changed
end

function process_should_be_included_row(row)
	local form_row = row:find("/component")
	form_row:find("/component")
	local field = form_row:find("/component[id = 'field']")
	local compart = field:find("/compartment")
	local compart_type = compart:find("/compartType")
	if utilities.execute_should_be_included(compart_type) and compart:is_not_empty() then
		core.set_compartment_value(compart, "", nil, true)
		--compart:attr({value = "", input = ""})
	end
end

function fill_row(form, form_row, prop_row)
	local row_type = prop_row:attr("rowType")
	local widget_table = {}
	widget_table[""] = true
	widget_table["InputField"] = true
	widget_table["ComboBox"] = true
	widget_table["CheckBox"] = true
	widget_table["TextArea"] = true
	widget_table["Label"] = true
	widget_table["ListBox"] = true
	widget_table["InputField+Button"] = true
	widget_table["TextArea+Button"] = true
	widget_table["TextArea+DBTree"] = true
	widget_table["CheckBox+Button"] = true
	widget_table["ComboBox+Button"] = true	
	if widget_table[row_type] then
		add_row_values(form_row, prop_row)
		make_field(form_row, prop_row, form:find("/ownedGroup"))
	else
		--custom row
		local transf_name = row_type
		local compart = find_compart_from_row(prop_row)
		utilities.execute_translet(transf_name, form_row, compart, form)
	end
end

function find_compart_from_row(prop_row)
	local elem = utilities.active_elements()
	local res_compart
	local compart_type = prop_row:find("/compartType/compartment"):each(function(compart)
		local tmp_elem = utilities.get_element_from_compartment(compart)
		if tmp_elem:id() == elem:id() then
			res_compart = compart
		end
	end)
	return res_compart
end

function recalculate_palette(diagram)
	return recalculate_palette_toolbar(diagram, "palette", "paletteElement")
end

function recalculate_toolbar(diagram)
	return recalculate_palette_toolbar(diagram, "toolbar", "tool")
end

function recalculate_palette_and_toolbar(diagram)
	local is_palette_changed = recalculate_palette(diagram)
	local is_toolbar_changed = recalculate_toolbar(diagram)
	if is_palette_changed or is_toolbar_changed then
		utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
	end
end

function recalculate_palette_toolbar(diagram, base_name, base_elem_name)	
	local palette_elem_list = {}
	local old_palette_elem_list = {}
	local active_palette = diagram:find("/" .. base_name)
	active_palette:find("/" .. base_elem_name):each(function(elem)
		old_palette_elem_list[elem:attr("id")] = elem
	end)
	local base_palette = diagram:find("/graphDiagramType/" .. base_name)
	base_palette:find("/" .. base_elem_name):each(function(palette_elem)
		if utilities.execute_should_be_included(palette_elem) then
			table.insert(palette_elem_list, {paletteElement = palette_elem, name = palette_elem:attr("id")})
		end
	end)
	local is_palette_changed = is_palette_changed(old_palette_elem_list, palette_elem_list) 
	if is_palette_changed then
		active_palette:find("/" .. base_elem_name):delete()
		for _, set in ipairs(palette_elem_list) do
			local palette_elem = set["paletteElement"]
			local copy_palette_elem = utilities.make_elem_copy(palette_elem)
			active_palette:link(base_elem_name, copy_palette_elem)
			palette_elem:link("copy", copy_palette_elem)
		end
	end
	return is_palette_changed
end

function is_palette_changed(old_palette_elem_list, palette_elem_list)
	local result = false
	for _, set in ipairs(palette_elem_list) do
		local name = set["name"]
		if old_palette_elem_list[name] ~= nil then
			old_palette_elem_list[name] = nil
		else
			return true
		end
	end
	if utilities.is_table_empty(old_palette_elem_list) then
		return false
	else
		return true
	end
end

function update_presentation_from_component_helper(component)
	if component:filter(".D#CheckBox"):is_not_empty() then
		update_presentation_from_component(component:find("/container/container"))
	else
		update_presentation_from_component(component:find("/container"))
	end	
end

function update_presentation_from_component(row)
	local component_type = get_component_type(row)
	local component = row:find("/component[id = 'field']")
	local compart
	local meta_compart
	local old_val = ""
	if component_type == "InputField" then
		compart, old_val = update_compartment_value_from_inputField(component)
	elseif component_type == "CheckBox" then
		compart, old_val = update_compartment_value_from_checkbox(row:find("/component/component[id = 'field']"))
	elseif component_type == "ComboBox" then
		compart, old_val = update_compartment_value_from_comboBox(component)
	elseif component_type == "TextArea" then
		compart, old_val = update_compartment_value_from_textArea(component)
	elseif component_type == "InputField+Button" then
		compart, old_val = update_compartment_value_from_inputField(component)
	elseif component_type == "ComboBox+Button" then
		compart, old_val = update_compartment_value_from_inputField(component)	
	elseif component_type == "TextArea+Button" then
		meta_compart, old_val = update_compartment_value_from_multiLineTextBox(component)
		--compart = fictious_compart:find("/subCompartment")
	--elseif component_type == "StereotypeRow" then
	--	compart = update_compartment_value_from_stereotype(component)
	elseif component_type == "TextArea+DBTree" then
		compart, old_val = update_compartment_value_from_textArea(component)
	end

	if type(component_type) == "string" then
		local c = compart or meta_compart
		report.event("update_"..component_type, {
			compart_type = function() return c:find("/compartType"):attr("caption") end,
			value        = function() return c:attr("value") end,
			element_id   = function() return c:transitive_closure("/superCompartment,/element"):find(":last"):id() end
		})
	end

	if compart ~= nil then
		compartment_changed_transformations(compart, old_val)
	end
end

function update_compartment_value_from_multiLineTextBox(multi_text_box)
	if multi_text_box:find("/container"):is_not_empty() then
		local old_val = ""
		local buls = false
		multi_text_box:find("/textLine"):each(function(text_line)
			local compart = text_line:find("/compartment")
			if compart:is_empty() then
				compart = create_corresponding_compartment(text_line)
				--core.reorder_child_compartments_according_to_type_order(component:find("/generatorRoot"))
				text_line:attr({edited = "true"})
			end
			local parent_compart = compart:find("/parentCompartment")
			compart:remove_link("parentCompartment", parent_compart)
				:link("parentCompartment", parent_compart)
		end)
		multi_text_box:find("/textLine"):each(function(text_line)
			local compart = text_line:find("/compartment")

			local old_val = compart:attr("value")
			local text_line_val = text_line:attr("text")

			--if is_auto_inserted_text_line(text_line) == "false" then
				--text_line:log("text")
				local val = text_line:attr("text")
				if text_line:attr("deleted") == "true" or text_line_val == "" then
					--text_line:delete()
					Delete.delete_compartment_tree_from_object(compart, "/subCompartment")
					update_value_and_set_status(compart, "", nil, true)					
					compart:delete()
					--text_line:delete()
					if text_line:attr("edited") == "true" then
						text_line:attr({deleted = "true"})
					end
					buls = true
				else
					if (old_val ~= text_line_val) then
						update_value_and_set_status_for_multi_field(compart, text_line_val)
					end
				end
			--end
		end)
		local compart = multi_text_box:find("/compartment")
		--compart:find("/compartType"):log("id")
		if buls then
			local elem = utilities.get_element_from_compartment(compart)
			utilities.refresh_element_without_diagram(elem)
			utilities.refresh_form_component(multi_text_box)
		end
		return compart, old_val
	end
end

function reconnect_compartment(compart)
	local parent_compart = compart:find("/parentCompartment")
	parent_compart:remove_link("subCompartment", compart):link("subCompartment", compart)
end

function compose(compart, direction)
	local res = utilities.execute_translet(compart:attr("procCompose"))
	set_compartment_value_helper(compart, res, direction, "true")
	return res
end

function set_compartment_value_helper(compart, new_val, direction, call_transform)
	if compart:attr("value") ~= new_val then
		local old_val = compart:attr("value")
		compart:attr({value = new_val})
		connect_compartment_to_choiceItem_by_compartment_value(compart)
		set_compartment_input(compart)
--		if direction == "" then
--			decompose(compart, "down")
--			local parent_compart = compart:find("/parentCompartment")
--			if parent_compart:is_not_empty() then
--				compose(parent_compart, "up")
--			end
--		elseif direction == "down" then
--			decompose(compart, "down");
--		elseif direction == "up" then
--			local parent_compart = compart:find("/parentCompartment")
--			if parent_compart:is_not_empty() then
--				compose(parent_compart, "up")
--			end
--		end
		--set_blocked_status_to_dependant(compart)
		if call_transform == "true" then
			compartment_changed_transformations(compart, old_val)
		end
		--update_occurrences_from_definition(compart)
		update_property_from_compartment(compart)
	end
end

function decompose(compart, direction)
	log("decompose")
end

function compartment_changed_transformations(compart, old_val)
	utilities.call_compartment_proc_thru_type(compart, "procForcedValuesFieldEntered", old_val)
	utilities.call_compartment_proc_thru_type(compart, "procFieldEntered", old_val)
	--utilities.call_compartment_proc_thru_type(compart, "procUpdateCompartmentDomain", old_val)
end

function update_property_from_compartment(compart)
	local text_line = compart:find("/textLine")
	if text_line:is_not_empty() then
		local multi_text_box = text_line:find("/multiLineTextBox")
		if multi_text_box:is_not_empty() then
			--set_blocking_status_from_compartment(multi_text_box, compart)
			utilities.refresh_form_component(multi_text_box)
		end
	else
		local component = compart:find("/component")
		local val = compart:attr("value")
		if component:filter(".D#InputField"):is_not_empty() then
			component:attr({text = val})
		elseif component:filter(".D#TextArea"):is_not_empty() then
			component:attr({text = val})
		elseif component:filter(".D#ComboBox"):is_not_empty() then
			component:attr({text = val})
		elseif component:filter(".D#CheckBox"):is_not_empty() then
			component:attr({checked = val})
		elseif component:filter(".D#Label"):is_not_empty() then
			component:attr({caption = val})
		end
		--set_blocking_status_from_compartment(component, compart)
		utilities.refresh_form_component(component)
	end
end

function connect_compartment_to_choiceItem_by_compartment_value(compart, val)
	disconnect_compartment_from_previous_value_item(compart)	
	local compart_type = compart:find("/compartType")
	local buls = 0
	local res = nil
	compart_type:find("/choiceItem"):each(function(choice_item)
		if choice_item:attr("value") == val and buls == 0 then
			buls = 1
			res = choice_item
		end
	end)
	compart:link("selectedItem", res)
	update_styles_from_compartment(compart, "false")
end

function disconnect_compartment_from_previous_value_item(compart)
	local prev_choice_item = compart:find("/selectedItem")
	update_styles_from_compartment(compart, "false")
	compart:remove_link("selectedItem", prev_choice_item)
end

function update_styles_from_compartment(compart, restore_default)
	local root_compart = get_compartment_root_compartment(compart)
	local elem = root_compart:find("/element")
	compart:find("/selectedItem"):each(function(choice_item)
		local elem_style = choice_item:find("/elemStyleByChoiceItem")
		if elem_style:is_not_empty() then
			if restore_default == "false" then
				utilities.apply_elemStyle(elem, elem_style)
			else
				utilities.apply_default_elemStyle(elem)
			end
		end
		choice_item:find("/compartStyleByChoiceItem"):each(function(compart_style)
			if root_compart:id() == compart:id() then
				apply_compartStyle_to_corresponding_element_compartments(elem, compart_style, restore_default)
			else
				apply_compartStyle_compartment_if_match(root_compart, compart_style, restore_default)
			end
		end)
	end)
end

function get_compartment_root_compartment(compart)
	local parent_compart = compart:find("/parentCompartment")
	if parent_compart:is_empty() then
		return compart
	else
		return get_compartment_root_compartment(parent_compart)
	end
end

function apply_compartStyle_to_corresponding_element_compartments(elem, compart_style, restore_default)
	elem:find("/compartment"):each(function(compart)
		apply_compartStyle_compartment_if_match(compart, compart_style, restore_default)
	end)
end

function apply_compartStyle_compartment_if_match(compart, compart_style, restore_default)
	local compart_type_from_style = compart_style:find("/compartType")
	local compart_type = compart:find("/compartType")
	if compart_type:id() == compart_type_from_style:id() then
		if restore_default == "false" then
			utilities.apply_compartStyle(compart, compart_style)
		else
			utilities.apply_default_compartStyle(compart)
		end
	end
end

function is_auto_inserted_text_line(text_line)
	local is_auto_inserted = "false"
	if text_line:attr("text") == "" then
		if text_line:attr("inserted") == "true" then
			if text_line:attr("edited") == "false" then
				is_auto_inserted = "true"
			end
		end
	end
	return is_auto_inserted
end

function add_input_field(tag_column, sub_compart, proc_name)
	local input_field = d.add_component(tag_column, {id = "TagInputField", text = sub_compart:attr("value"), compartment = sub_compart}, "D#InputField")
	d.add_event_handlers(input_field, {FocusLost = proc_name})
end

function update_compartment_value_from_textArea(text_area)
	local compart = text_area:find("/compartment")
	if compart:is_empty() then
		compart = create_missing_compartment_from_component(text_area, "/container/propertyElement/compartType")
	end
	local old_val = compart:attr("value")
	update_value_and_set_status(compart, text_area:attr("text"), nil, false)
	validate_input(text_area, compart)
	return compart, old_val
end

function update_compartment_value_from_check_expression(h_box)
	local check_box = h_box:find("/component"):filter("D#CheckBox")
	local checked = check_box:attr("checked")	
	local val = ""
	local choice_item = h_box:find("/container/propertyElement/compartType"):find("/choiceItem"):filter_attr_value_equals("value", checked)
	if choice_item:is_not_empty() then
		local notation = choice_item:find("/notation")	
		val = notation:attr("value")
	end
	local compart = check_box:find("/compartment")
	if compart:is_empty() then
		local compart_type = check_box:find("/container/container/propertyElement/compartType")--:log("id")
		--local parent_type = compart_type:find("/parentCompartType")
		local parent = get_parent_elem(compart_type)
		compart = core.add_compart(compart_type, parent, "")

		compart:find("/compartStyle")--:log("id")
		compart:link("component", check_box)
	end

	compart:find("/parentCompartment")
	update_value_and_set_status(compart, val)
	compart:attr({value = checked})
end

function get_check_box_value_compartment(compart)
	return compart:find("/subCompartment:not(:has(/compartType))")
end

function get_parent_elem(compart_type)
	local comparts = compart_type:find("/parentCompartType/parentCompartType"):find("/compartment")
	local parent
	local elem = utilities.active_elements()
	comparts:each(function(compart)
		local tmp_elem = utilities.get_element_from_compartment(compart)
		if tmp_elem ~= nil and tmp_elem:id() == elem:id() then
			--parent = compart:find("/parentCompartment")
			parent = compart
			return
		end
	end)
	return parent
end

function get_parent_elem1(compart_type)
	local elem = utilities.active_elements()
	local list_of_leafs = {}
	local parent
	elem:find("/compartment"):each(function(compart)
		local childs = compart:find("/subCompartment")
		if childs:is_empty() then
			table.insert(list_of_leafs, compart)
		else
			local type_size = compart:find("/compartType/subCompartType"):size()
			local child_size = childs:size()
			if child_size ~= type_size then
				table.insert(list_of_leafs, compart)
			end
			childs:each(function(child)
				get_sub_comparts(child, list_of_leafs)
			end)
		end
	end)
	for _, compart in ipairs(list_of_leafs) do
		local super_type = compart:find("/compartType")
		if is_parent_compart_type(compart_type, super_type) then
			parent = compart
			break
		end
	end
	return parent
end

function is_parent_compart_type(compart_type, super_type)
	local parent_type = compart_type:find("/parentCompartType")
	if parent_type:is_empty() then
		return false
	else
		if parent_type:id() == super_type:id() then
			return true
		else
			return is_parent_compart_type(parent_type, super_type)
		end
	end
end

function get_sub_comparts(parent, list_of_leafs)
	parent:find("/subCompartment"):each(function(tmp_compart)
		local child = tmp_compart:find("/subCompartment")
		if child:is_empty() then
			table.insert(list_of_leafs, parent)
		else
			get_sub_comparts(child, list_of_leafs)
		end
	end)
end

function update_compartment_value_from_comboBox(combo_box)
	local compart = combo_box:find("/compartment")
	if compart:is_empty() then
		compart = create_missing_compartment_from_component(combo_box, "/container/propertyElement/compartType")
	end
	local old_val = compart:attr("value")
	local item = combo_box:find("/selected")
	local val = ""
	if item:is_not_empty() then
		val = item:attr("value")
	else
		val = combo_box:attr("text")
	end		
	local compart_type = compart:find("/compartType")
	local choice_item = compart:find("/compartType/choiceItem"):filter_attr_value_equals("value", val)
	update_value_and_set_status(compart, val, nil, false)
	--if choice_item:is_not_empty() then
		--local notation = choice_item:find("/notation")
		--if notation:is_not_empty() then
		--	val = notation:attr("value")
		--else
		--	val = ""
		--end
		--compart:attr({input = val})
	--end
	
	if val == old_val then
		old_val = nil
	end
	return compart, old_val
end

function update_compartment_value_from_checkbox(check_box)
	local compart = check_box:find("/compartment")
	if compart:is_empty() then
		compart = create_missing_compartment_from_component(check_box, "/container/container/propertyElement/compartType")
	end
	local old_val = compart:attr("value")
	local compart_type = compart:find("/compartType")
	local checked = check_box:attr("checked")
	local val = checked
	local choice_item = compart_type:find("/choiceItem"):filter_attr_value_equals("value", checked)
	if choice_item:is_not_empty() then
		local notation = choice_item:find("/notation")
		val = notation:attr("value")
	end
	update_value_and_set_status(compart, val, checked, false)
	compart:attr({value = checked})
	return compart, old_val
end

function update_compartment_value_from_inputField(input_field)
	local compart = input_field:find("/compartment")
	if compart:is_empty() then
			input_field:find("/container/propertyElement/compartType")
		compart = create_missing_compartment_from_component(input_field, "/container/propertyElement/compartType")
	end
	local old_val = compart:attr("value")
	update_value_and_set_status(compart, input_field:attr("text"), nil, false)
	validate_input(input_field, compart)
	return compart, old_val
end

function create_missing_compartment_from_component(component, path)
	local parent = get_parent_thru_form(component)
	local parent_type = utilities.get_obj_type(parent)
	local compart_type = component:find(path)
	compart_type:find("/parentCompartType")
	local missing_compart = core.create_missing_compartment(parent, parent_type, compart_type)
	missing_compart:link("component", component)
	return missing_compart
end

function get_parent_thru_form(component)
	local form = get_component_root_container(component)
	return form:find("/presentationElement")
end

function get_component_root_container(component)
	local container = component:find("/container")
	if container:is_empty() then
		return component
	else
		return get_component_root_container(container)
	end
end

function update_value_and_set_status(compart, val, check_box_val, is_refresh_needed)
	local changed = "false"
	if compart:attr("value") ~= val then
		changed = "true"
		core.set_compartment_value(compart, val, check_box_val, true)
		if is_refresh_needed then
			utilities.refresh_diagram_from_compart(compart)
		end
	end
	return changed
end

function update_value_and_set_status_for_multi_field(compart, val)
	local changed = "true"
	local prop_row = compart:find("/compartType/parentCompartType"):find("/propertyRow")
	local is_parser_needed = true
	if prop_row:attr("isReadOnly") == "true" then
		is_parser_needed = false
	end
	core.set_compartment_value(compart, val, nil, is_parser_needed)
	utilities.refresh_diagram_from_compart(compart)
	return changed
end

function show_called_dgr()
	local ev = lQuery("D#Event")
	local component = ev:find("/source/container/container/component[id = 'field']")
	utilities.delete_event(ev)
	--set_as_first_respondent(component)
	--utilities.refresh_form_component(component)
	if component:filter(".D#InputField"):is_not_empty() or component:filter(".D#ComboBox"):is_not_empty() then
		local compart = component:find("/compartment")
		if compart:is_empty() then
			compart = create_missing_compartment_from_component(component, "/container/propertyElement/compartType")
		end
		build_called_diagram(compart)
	elseif component:filter(".D#MultiLineTextBox"):is_not_empty() then
		local text_line = component:find("/current")
		local compart = text_line:find("/compartment")
		if compart:is_empty() then
			compart = create_corresponding_compartment(text_line)
			--core.reorder_child_compartments_according_to_type_order(component:find("/generatorRoot"))
			text_line:attr({edited = "true"})
		end
		build_called_diagram(compart)
	end
	report.event("Button", {
		Button = "<-"
	})
end

function show_called_check_box_dgr()
	local ev = lQuery("D#Event")
	local component = ev:find("/source/container/container/component/component[id = 'field']")
	local compart = component:find("/compartment")
	local prop_dgr = compart:find("/compartType/propertyDiagram")
	local form = generate_property_diagram_from_prop_dgr(prop_dgr, compart)
	local tmp_compart = compart:find("/parentCompartment")
	populate_dialog_form(form, tmp_compart, prop_dgr)
	d.show_form(form)
	ev:delete()
end

function create_corresponding_compartment(text_line)
	local compart = text_line:find("/compartment")
	if compart:is_empty() then
		local multi_box = text_line:find("/multiLineTextBox")
		local multi_compart = multi_box:find("/compartment")
		if multi_compart:is_empty() then
			multi_compart = create_missing_compartment_from_component(multi_box, "/container/propertyElement/compartType")
		end
		local sub_compart_type = multi_compart:find("/compartType/subCompartType")
		local val = text_line:attr("text")
		compart = core.add_compartment(sub_compart_type, multi_compart, val, true):link("textLine", text_line)
	end
	return compart
end

function build_called_diagram(compart)
	if is_property_diagram_empty(compart) == "false" then
		local compart_type = compart:find("/compartType")
		local form, prop_dgr = generate_property_diagram(compart_type, compart)
		populate_dialog_form(form, compart, prop_dgr)
		d.show_form(form)
	end
end

function is_multiple_compartType(compartType)
	local is_multiple = "false"
	if compartType:find("/propertyRow"):attr("rowType") == "TextArea+Button" then
		is_multiple = "true"
	end
	return is_multiple
end;

function test_should_be_included_true()
	return true
end

function test_should_be_included_false()
	return false
end