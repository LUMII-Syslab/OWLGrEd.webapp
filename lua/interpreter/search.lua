module(..., package.seeall)
d = require("dialog_utilities")
require("re")
report = require("reporter.report")
require("config_properties")

function search()
	local form = d.add_form({id = "search", caption = "Find", horizontalAlignment = -1, verticalAlignment = 0, preferredWidth = 350})
	local hbox = d.add_component(form, {id = "find_hbox"}, "D#HorizontalBox")
		local vbox_for_params = d.add_component(hbox, {id = "button_vbox", verticalAlignment = -1, horizontalAlignment = -1}, "D#VerticalBox")
			local hbox_find_row = d.add_component(vbox_for_params, {id = "find_hbox", verticalAlignment = -1}, "D#HorizontalBox")
				local label = d.add_component(hbox_find_row, {id = "find_label", caption = "Find what:"}, "D#Label")
				local input = d.add_component(hbox_find_row, {id = "find_field"}, "D#InputField")
			local hbox_checkbox_row = d.add_component(vbox_for_params, {id = "checkbox_hbox", verticalAlignment = -1, horizontalAlignment = -1}, "D#HorizontalBox")
				local vbox_for_checkboxes_1 = d.add_component(hbox_checkbox_row, {id = "button_vbox1", horizontalAlignment = -1}, "D#VerticalBox")
					d.add_component_with_handler(vbox_for_checkboxes_1, {id = "case_sensitive"}, "D#CheckBox", {Change = "lua.interpreter.search.remove_tag"})	
					d.add_component_with_handler(vbox_for_checkboxes_1, {id = "whole_world_only"}, "D#CheckBox", {Change = "lua.interpreter.search.remove_tag"})				
					d.add_component_with_handler(vbox_for_checkboxes_1, {id = "class_names_only", checked = true}, "D#CheckBox", {Change = "lua.interpreter.search.remove_tag"})				
				local vbox_for_checkboxes_2 = d.add_component(hbox_checkbox_row, {id = "button_vbox2", horizontalAlignment = -1}, "D#VerticalBox")
					d.add_component(vbox_for_checkboxes_2, {id = "case_sensitive_label", caption = "Case Sensitive"}, "D#Label")
					d.add_component(vbox_for_checkboxes_2, {id = "whole_world_only_label", caption = "Whole World Only"}, "D#Label")
					d.add_component(vbox_for_checkboxes_2, {id = "class_names_only_label", caption = "In Class Names Only"}, "D#Label")
				local vbox_for_checkboxes_3 = d.add_component(hbox_checkbox_row, {id = "button_vbox3", horizontalAlignment = -1}, "D#VerticalBox")
					d.add_component_with_handler(vbox_for_checkboxes_3, {id = "pattern"}, "D#CheckBox", {Change = "lua.interpreter.search.pattern_click"})
					d.add_component_with_handler(vbox_for_checkboxes_3, {id = "active_diagram", checked = true}, "D#CheckBox", {Change = "lua.interpreter.search.remove_tag"})	
				local vbox_for_checkboxes_4 = d.add_component(hbox_checkbox_row, {id = "button_vbox3", horizontalAlignment = -1}, "D#VerticalBox")
					d.add_component(vbox_for_checkboxes_4, {id = "pattern_label", caption = "Pattern"}, "D#Label")
					d.add_component(vbox_for_checkboxes_4, {id = "active_diagram_label", caption = "In Active Diagram"}, "D#Label")
		local vbox_for_buttons = d.add_component(hbox, {id = "button_vbox"}, "D#VerticalBox")
			local find_button = d.add_component_with_handler(vbox_for_buttons, {id = "find_button", caption = "Find"}, "D#Button", {Click = "lua.interpreter.search.find"})
			local prev_button = d.add_component_with_handler(vbox_for_buttons, {id = "prev_button", caption = "Previous"}, "D#Button", {Click = "lua.interpreter.search.activate_prev_elem"})
			local close_button = d.add_component_with_handler(vbox_for_buttons, {id = "close_button", caption = "Close"}, "D#Button", {Click = "lua.interpreter.search.close_form"})
	form:link("defaultButton", close_button)
	form:link("eventHandler", utilities.d_handler("Close", "lua_engine", "lua.interpreter.search.close_form"))
	d.show_form(form)
end

function close_form()
	remove_tag()
	d.close_form("search")
end

function pattern_click()
	local pattern = d.get_component_by_id("pattern")
	local pattern_value = pattern:attr("checked")
	local whole_world_only = d.get_component_by_id("whole_world_only")
	local list = {}
	if pattern_value == "true" then
		whole_world_only:attr({hint = whole_world_only:attr("checked")})
		list = {checked = "false", enabled = "false"}
	else
		list = {checked = whole_world_only:attr("hint"), enabled = "true"}
	end
	whole_world_only:attr(list)
	d.refresh_form_component(whole_world_only)
end

function remove_tag()
	lQuery("Tag[key = '__Find']"):delete()
end

function find()
	local result ={}
	local search_for = d.get_component_by_id("find_field"):attr("text")
	local tag_ = get_Find_tag()
	local class_names_only = d.get_component_by_id("class_names_only"):attr("checked")
	local case_sensitive = d.get_component_by_id("case_sensitive"):attr("checked")
	local pattern = d.get_component_by_id("pattern"):attr("checked")
	local whole_world_only = d.get_component_by_id("whole_world_only"):attr("checked")
	if tag_:attr("value") ~= search_for then
		tag_:delete()
		local compartments
		if class_names_only == "true" then 
			compartments = lQuery("ElemType[id='Class']/compartType[id='Name']/subCompartType[id='Name']/compartment")
		else
			compartments = lQuery("Compartment")
		end
		compartments:each(function(compart)
			local val = compart:attr("value")
			local elem = get_element_from_compartment(compart)
			if whole_world_only == "true" then
				if case_sensitive == "true" then
					if val == search_for then
						table.insert(result, elem)
					end
				elseif string.lower(val) == string.lower(search_for) then
						table.insert(result, elem)
				end
			else
				local start, fin
				if pattern == "true" then
					start, fin = string.find(val, search_for)
				else
					start, fin = string.find(string.lower(val), string.lower(search_for), 1, true)
				end
				if start ~= nil then
					if case_sensitive == "true" then
						local sub_string = string.sub(val, start, fin)
						if sub_string == search_for then
							table.insert(result, elem)
						end
					else
						table.insert(result, elem)
					end
				end
			end
		end)
		process_result(result, search_for)
	else
		activate_next_elem(tag_)
	end
end

function activate_next_elem(tag_)
	local elems = tag_:find("/thing")
	local elem = elems:filter(":first()")
	tag_:remove_link("thing", elem)
		:link("thing", elem)
	local current_elem = utilities.active_elements()
	if current_elem:id() == elem:id() then
		local elem_count = elems:size()
		if elem_count > 1 then
			activate_next_elem(tag_)
		end
	else
		utilities.activate_element(elem)
	end
end

function activate_prev_elem()
	local tag_ = get_Find_tag()
	local elem = tag_:find("/thing:last()")
	tag_:remove_link("thing", elem)
	local elems = tag_:find("/thing")
	tag_:remove_link("thing", elems)
	tag_:link("thing", elem)
		:link("thing", elems)
	local current_elem = utilities.active_elements()
	if current_elem:id() == elem:id() then
		local elem_count = elems:size() + 1
		if elem_count > 1 then
			activate_prev_elem()
		end
	else
		utilities.activate_element(elem)
	end
end

function get_element_from_compartment(compart)
	local elem = utilities.get_element_from_compartment(compart)
	if config_properties.get_config_value("is_configurator_hidden") then
		local list = utilities.get_configurator_diagram_types()
		local diagram_type_id = elem:find("/graphDiagram/graphDiagramType"):attr("id")
		if not list[diagram_type_id] then
			return elem
		end
	else
		return elem
	end
end

function process_result(result, search_for)
	if #result > 0  then
		local tag_ = lQuery.create("Tag", {key = "__Find", value = search_for})
		local tmp_list = {}
		local is_in_active_diagram = d.get_component_by_id("active_diagram"):attr("checked")	
		if is_in_active_diagram == "true" then
			local current_dgr_id = utilities.current_diagram():id()
			for _, elem in ipairs(result) do
				if elem:find("/graphDiagram"):id() == current_dgr_id then
					link_elem_to_tag(elem, tag_, tmp_list)
				end
			end
		else
			for _, elem in ipairs(result) do
				link_elem_to_tag(elem, tag_, tmp_list)
			end
		end
		activate_next_elem(tag_)
	end
end

function link_elem_to_tag(elem, tag_, tmp_list)
	local elem_id = elem:id()
	if not tmp_list[elem_id] then
		tmp_list[elem_id] = true
		tag_:link("thing", elem)
	end
end

function get_Find_tag()
	return lQuery("Tag[key = '__Find']")
end

