module(..., package.seeall)
d = require("dialog_utilities")
require("re")
report = require("reporter.report")
require("config_properties")

function replace()
	local form = d.add_form({id = "search", caption = "Replace", horizontalAlignment = -1, verticalAlignment = 0, preferredWidth = 350})
	local hbox = d.add_component(form, {id = "find_hbox"}, "D#HorizontalBox")
		local vbox_for_params = d.add_component(hbox, {id = "button_vbox", verticalAlignment = -1, horizontalAlignment = -1}, "D#VerticalBox")
			local hbox_find_row = d.add_component(vbox_for_params, {id = "find_hbox", verticalAlignment = -1}, "D#HorizontalBox")
				local label = d.add_component(hbox_find_row, {id = "find_label", caption = "Find what:       "}, "D#Label")
				-- local input = d.add_component(hbox_find_row, {id = "find_field"}, "D#InputField")
				d.add_component_with_handler(hbox_find_row, {id = "find_field"}, "D#InputField", {FocusLost = "lua.interpreter.replace.find_change"})	
			local hbox_replase_row = d.add_component(vbox_for_params, {id = "find_hbox", verticalAlignment = -1}, "D#HorizontalBox")
				local labelR = d.add_component(hbox_replase_row, {id = "replace_label", caption = "Replace with:"}, "D#Label")
				local inputR = d.add_component(hbox_replase_row, {id = "replase_field"}, "D#InputField")
				
			local hbox_checkbox_row = d.add_component(vbox_for_params, {id = "checkbox_hbox", verticalAlignment = -1, horizontalAlignment = -1}, "D#HorizontalBox")
				local vbox_for_checkboxes_1 = d.add_component(hbox_checkbox_row, {id = "button_vbox1", horizontalAlignment = -1}, "D#VerticalBox")
					d.add_component_with_handler(vbox_for_checkboxes_1, {id = "case_sensitive"}, "D#CheckBox", {Change = "lua.interpreter.replace.remove_tag"})	
					d.add_component_with_handler(vbox_for_checkboxes_1, {id = "whole_world_only"}, "D#CheckBox", {Change = "lua.interpreter.replace.remove_tag"})				
					d.add_component_with_handler(vbox_for_checkboxes_1, {id = "class_names_only", checked = true}, "D#CheckBox", {Change = "lua.interpreter.replace.remove_tag"})				
				local vbox_for_checkboxes_2 = d.add_component(hbox_checkbox_row, {id = "button_vbox2", horizontalAlignment = -1}, "D#VerticalBox")
					d.add_component(vbox_for_checkboxes_2, {id = "case_sensitive_label", caption = "Case Sensitive"}, "D#Label")
					d.add_component(vbox_for_checkboxes_2, {id = "whole_world_only_label", caption = "Whole World Only"}, "D#Label")
					d.add_component(vbox_for_checkboxes_2, {id = "class_names_only_label", caption = "In Class Names Only"}, "D#Label")
				local vbox_for_checkboxes_3 = d.add_component(hbox_checkbox_row, {id = "button_vbox3", horizontalAlignment = -1}, "D#VerticalBox")
					d.add_component_with_handler(vbox_for_checkboxes_3, {id = "pattern"}, "D#CheckBox", {Change = "lua.interpreter.replace.pattern_click"})
					d.add_component_with_handler(vbox_for_checkboxes_3, {id = "active_diagram", checked = true}, "D#CheckBox", {Change = "lua.interpreter.replace.remove_tag"})	
				local vbox_for_checkboxes_4 = d.add_component(hbox_checkbox_row, {id = "button_vbox3", horizontalAlignment = -1}, "D#VerticalBox")
					d.add_component(vbox_for_checkboxes_4, {id = "pattern_label", caption = "Pattern"}, "D#Label")
					d.add_component(vbox_for_checkboxes_4, {id = "active_diagram_label", caption = "In Active Diagram"}, "D#Label")
		local vbox_for_buttons = d.add_component(hbox, {id = "button_vbox", verticalAlignment = -1}, "D#VerticalBox")
			local find_button = d.add_component_with_handler(vbox_for_buttons, {id = "find_button", caption = "Find"}, "D#Button", {Click = "lua.interpreter.replace.findReplace"})
		local vbox_for_buttons2 = d.add_component(hbox, {id = "button_vbox_rep"}, "D#VerticalBox")
			local find_next_button = d.add_component_with_handler(vbox_for_buttons2, {id = "find_next_button", caption = "Find next", enabled = false}, "D#Button", {Click = "lua.interpreter.replace.findNext"})
			local replace_next_button = d.add_component_with_handler(vbox_for_buttons2, {id = "replace_next_button", caption = "Replace next", enabled = false}, "D#Button", {Click = "lua.interpreter.replace.replaceNext"})
			local replace_all_button = d.add_component_with_handler(vbox_for_buttons2, {id = "replace_all_button", caption = "Replace all", enabled = false}, "D#Button", {Click = "lua.interpreter.replace.replaceAll"})
			local close_button = d.add_component_with_handler(vbox_for_buttons2, {id = "close_button", caption = "Close"}, "D#Button", {Click = "lua.interpreter.replace.close_form"})
	form:link("defaultButton", close_button)
	form:link("eventHandler", utilities.d_handler("Close", "lua_engine", "lua.interpreter.replace.close_form"))
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

function enable_disable_buttons(value)
	lQuery("D#Button[id='find_next_button']"):attr("enabled", value)
	lQuery("D#Button[id='replace_next_button']"):attr("enabled", value)
	lQuery("D#Button[id='replace_all_button']"):attr("enabled", value)
	local cmd = utilities.create_command("D#Command", {info = "Refresh"})
	local cmd2 = utilities.create_command("D#Command", {info = "Refresh"})
	local cmd3 = utilities.create_command("D#Command", {info = "Refresh"})
	lQuery("D#Button[id='find_next_button']"):link("command", cmd)
	lQuery("D#Button[id='replace_next_button']"):link("command", cmd2)
	lQuery("D#Button[id='replace_all_button']"):link("command", cmd3)
	utilities.execute_cmd_obj(cmd)
	utilities.execute_cmd_obj(cmd2)
	utilities.execute_cmd_obj(cmd3)
end

function remove_tag()
	enable_disable_buttons(false)
	lQuery("Tag[key = '__Find']"):delete()
end

function findReplace()
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
		compartments = compartments:filter(function(compart)
			return compart:find("/subCompartment"):is_empty()
		end)
		compartments:each(function(compart)
			local val = compart:attr("value")
			-- local elem = get_element_from_compartment(compart)
			if whole_world_only == "true" then
				if case_sensitive == "true" then
					if val == search_for then
						table.insert(result, compart)
					end
				elseif string.lower(val) == string.lower(search_for) then
						table.insert(result, compart)
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
							table.insert(result, compart)
						end
					else
						table.insert(result, compart)
					end
				end
			end
		end)
		process_result(result, search_for)
	-- else
		-- activate_next_elem(tag_)
		if #result > 0 then 
			enable_disable_buttons(true)
		end
	end
end

function replaceAll()
	local search_for = d.get_component_by_id("find_field"):attr("text")
	local replace_with = d.get_component_by_id("replase_field"):attr("text")
	if replace_with ~= "" then
		local tag_ = get_Find_tag()
		local compartments = tag_:find("/thing")
		compartments:each(function(compart)
			replaceValue(compart, replace_with)
			utilities.refresh_element(get_element_from_compartment(compart), utilities.current_diagram())
			-- compart:attr("value", replace_with)
			local elem = get_element_from_compartment(compart)
			utilities.activate_element(elem)
		end)
	end
	remove_tag()
end

function replaceNext()
	local search_for = d.get_component_by_id("find_field"):attr("text")
	local replace_with = d.get_component_by_id("replase_field"):attr("text")
	if replace_with ~= "" then
		local tag_ = get_Find_tag()
		-- local current_elem = utilities.active_elements()
		activate_next_elem_after_replace(tag_, replace_with)
	end	
end

function findNext()
	local search_for = d.get_component_by_id("find_field"):attr("text")
	local tag_ = get_Find_tag()
	if tag_:attr("value") ~= search_for then
	else
		activate_next_elem(tag_)
	end
end

function activate_next_elem(tag_)
	local compartments = tag_:find("/thing")
	local compart = compartments:filter(":first()")
	if compart~=nil then 
	local elem = get_element_from_compartment(compart)
		tag_:remove_link("thing", compart)
			:link("thing", compart)
		utilities.activate_element(elem)
	end
end

function activate_next_elem_after_replace(tag_, replace_with)
	local compartments = tag_:find("/thing")
	if compartments:size() ~= 0 then
		local compart = compartments:filter(":first()")
		print(compartments:size(), compartments:filter(":last()"):attr("value"), compartments:filter(":last()"):find("/compartType"):attr("id"))
		local replaceCompart = compartments:filter(":last()")
		replaceValue(replaceCompart, replace_with)
		utilities.refresh_element(get_element_from_compartment(replaceCompart), utilities.current_diagram())
		-- compart:attr("value", replace_with)
		local elem = get_element_from_compartment(compart)
		tag_:remove_link("thing", compart)
			:link("thing", compart)
		tag_:remove_link("thing", replaceCompart)
		utilities.activate_element(elem)
	else
		remove_tag()
	end
end

function replaceValue(compart, replaceWith)
	local compartValue = compart:attr("value")
	if compartValue ~= nil and compartValue ~= "" then
		local class_names_only = d.get_component_by_id("class_names_only"):attr("checked")
		local case_sensitive = d.get_component_by_id("case_sensitive"):attr("checked")
		local pattern = d.get_component_by_id("pattern"):attr("checked")
		local search_for = d.get_component_by_id("find_field"):attr("text")
		
		if whole_world_only == "true" then
			core.set_compartment_value(compart, replaceWith)
		else
			local start, fin
			if pattern == "true" then
				start, fin = string.find(compartValue, search_for)
			else
				start, fin = string.find(string.lower(compartValue), string.lower(search_for), 1, true)
			end
			if start ~= nil then
				if case_sensitive == "true" then
					local sub_string = string.sub(compartValue, start, fin)
					if sub_string == search_for then
						core.set_compartment_value(compart, string.gsub(compartValue, search_for, replaceWith))
					end
				else
					local l = 1
					while l == 1 do
						local s = ""
						local f = ""
						if start > 1 then
							s = string.sub(compartValue, 1, start-1)
						end
						if fin < string.len(compartValue) then
							f = string.sub(compartValue, fin+1)
						end
						compartValue =  s .. replaceWith .. f
						start, fin = string.find(string.lower(compartValue), string.lower(search_for), 1, true)
						if start == nil then l = 0 end 
					end
					core.set_compartment_value(compart, compartValue)
				end
			end
		end
		core.update_compartment_input_from_value(compart, compart:find("/copartType"))
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
			for _, compart in ipairs(result) do
				local elem = get_element_from_compartment(compart)
				if elem:find("/graphDiagram"):id() == current_dgr_id then
					link_compart_to_tag(compart, tag_, tmp_list)
				end
			end
		else
			for _, compart in ipairs(result) do
				link_compart_to_tag(compart, tag_, tmp_list)
			end
		end
		activate_next_elem(tag_)
	end
end

function link_compart_to_tag(compart, tag_, tmp_list)
	local compart_id = compart:id()
	if not tmp_list[compart_id] then
		tmp_list[compart_id] = true
		tag_:link("thing", compart)
	end
end

function get_Find_tag()
	return lQuery("Tag[key = '__Find']")
end

function find_change(a,b,c)
	local search_for = d.get_component_by_id("find_field"):attr("text")
	local tag_ = get_Find_tag()
	if tag_:attr("value") ~= search_for then
		remove_tag()
	end
end