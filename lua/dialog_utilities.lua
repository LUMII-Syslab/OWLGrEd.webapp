module(..., package.seeall)
require("core")
require("utilities")
require("lQuery")
report = require("reporter.report")
---Dialogu logu dzinēja API funkcijas

---Izveido formu
-- @param attr_table tabula, kas satur klases D#Form atribūtu vērtības
-- @return formas objekts
function add_form(attr_table)
	local component = add_component(nil, attr_table, "D#Form")
	return component
end

---Pievieno pogu
-- @param container komponente, uz kuras poga tiks izveidota
-- @param attr_table tabula, kas satur klases Button atribūtu vērtības
-- @param events tabula, kuras indekss ir notikuma nosaukums un vērtība ir notikumu apstrādājošās transformācijas adrese
-- @return pogas objekts
function add_button(container, attr_table, events)
	local button = add_component(container, attr_table, "D#Button")
	add_event_handlers(button, events)
return button
end

function add_event_handlers(source, event_table)
	if event_table ~= nil then 
		for event, func_name in pairs(event_table) do
			add_eventHandler(event, source, "lua_engine", func_name)
		end
	end
end

function add_eventHandler(event_name, event_source, dll_name, procedure_name)
	return utilities.d_handler(event_name, dll_name, procedure_name):link("eventSource", event_source)
end

function set_field_ok(field)
	field:attr({outlineColor = "536870911", hint = ""})
end

---Meklē dialoga loga komponenti pēc id vērtības
-- @param id komponentes id vērtība
-- @return atrastās komponentes objekts
function get_component_by_id(id)
	return lQuery("D#Component:has([id = " .. id .. "])")
end

---Meklē dialoga loga komponenti no konkrēta vecāka pēc id vērtības
-- @param container komponente, no kuras meklē
-- @param id komponentes id vērtība
-- @return atrastās komponentes objekts
function get_component_from_container_by_id(container, id)
	return container:find("/component[id = " .. id .. "]")
end

---Meklē dialoga loga komponenti no konkrēta vecāka pēc atribūta vērtības
-- @param container komponente, no kuras meklē
-- @param attr_name atribūta nosaukums
-- @param value atribūta vērtība
-- @return atrastās komponentes objekts
function get_component_from_container_by_attr_name(container, attr_name, value)
	return container:find("/component[" .. attr_name .. " = " .. value .. "]")
end

function get_component_by_id_in_depth(container, id)
	local list = {}
	get_component_by_id_in_depth_list(container, id, list)
	return list[1]
end

function get_component_by_id_in_depth_list(container, id, list)
	local component = container:find("/component")
	local component_with_id = component:find("[id = '" .. id .. "']")
	if component_with_id:size() > 0 then
		table.insert(list, component_with_id)
	else
		component:each(function(comp)
			get_component_by_id_in_depth_list(lQuery(comp), id, list)
		end)
	end
end

---Aizpilda ListBox vai ComboBox no tabulas
-- @param box ListBox vai ComboBox objekts
-- @param value_table  itemu saraksts
function fill_list_combo_box(box, value_table)
	for i, value in pairs(value_table) do
		add_item_to_box(box, value)
	end
end

function add_item_to_box(box, value)
	local item = lQuery.create("D#Item", {value = value})
	box:link("item", item)
	return item
end

function set_selected_item_in_list_box(list_box, item)
	list_box:remove_link("selected")
		:link("selected", item)
end

function add_list_comb_box(box, value)
	local item = lQuery.create("D#Item", {value = value})
	box:remove_link("selected")
	box:link("item", item):link("selected", item)
end

function clear_list_box(listbox)
	listbox:find("/item"):delete()
end

function check_field_value_int_and_chars(table)
	local field = get_event_source()
	local attr, value = get_event_source_attrs("text")
	nr_value = tonumber(value)
	if type(nr_value) == "number" then
		set_field_ok(field)
	else
		local buls = "false"
		for _, val in pairs(table) do
			if value == val then
				buls = "true"
				set_field_ok(field)
				break
			end
		end
		if buls == "false" then
			field:attr({outlineColor = "255", hint = "Error: Value is not an integer!"})
		end
	end
	execute_d_command(field, "Refresh")
end

function get_event_source()
	local ev = lQuery("D#Event")
	local source = ev:find("/source")
	return source, ev
end

function get_event_source_attrs(attr_name)
	local event_source = get_event_source()
return event_source:attr_e("id"), event_source:attr_e(attr_name)
end

function add_row_labeled_field(container, label_attrs, field_attrs, row_attrs, field_type, events)
	local row = add_component(container, row_attrs, "D#Row")
	local label_box = add_component(row, {id = "label_box", horizontalAlignment = -1, }, "D#HorizontalBox")
	local label = add_component(label_box, label_attrs, "D#Label")
	local field_box = add_component(row, {id = "field_box", horizontalAlignment = -1}, "D#HorizontalBox")
	local field = add_component(field_box, field_attrs, field_type)
	add_event_handlers(field, events)
return row, field
end

function add_vertical_box_labeled_field(container, label_attrs, field_attrs, row_attrs, field_type, events)
	--local vertical_box = add_component(container, row_attrs, "D#VerticalBox")
	local row = add_component(container, row_attrs, "D#Row")
		--row:attr{horizontalAlignment = 1}
	local label_box = add_component(row, {id = "label_box", horizontalAlignment = -1, verticalAlignment = -1}, "D#HorizontalBox")
	local label = add_component(label_box, label_attrs, "D#Label")
	local field_box = add_component(row, {id = "field_box", horizontalAlignment = -1}, "D#VerticalBox")
	local field = add_component(field_box, field_attrs, field_type)
	add_event_handlers(field, events)
return row, field
end


function add_component(container, attributes, component_type)
	if container ~= nil then
		return lQuery.create(component_type, attributes):link("container", container)
	else
		return lQuery.create(component_type, attributes)
	end
end

function add_component_with_handler(container, attributes, component_type, events)
	local component = add_component(container, attributes, component_type)
	add_event_handlers(component, events)
end

function add_tree_node(tree_element, tree_link, attr_table)
	return lQuery.create("D#TreeNode", attr_table):link(tree_link, tree_element)
end

function get_container_component_by_id(container, id)
	if container ~= nil then
		return container:find("/component:has([id = " .. id .. "])")
	end
end

function delete_container_components(container)
	local list = {}
	get_list_of_components(container, list)
	for _, component in ipairs(list) do
		component:delete()
	end
end

function  get_list_of_components(container, list)
	if container ~= nil then 
		container:find("/component"):each(function(component)
			if component:is_not_empty() then
				get_list_of_components(component, list)
				table.insert(list, component)
			end
		end)
	end
end

function add_columnType(table, colum_attrs, field_type, field_attrs, events)
	local column = lQuery.create("D#VTableColumnType", colum_attrs)
	local column_field = lQuery.create(field_type, field_attrs)
	add_event_handlers(column_field, events)
	column:link("defaultComponent", column_field)
	table:link("column", column)
	return column
end

function get_selected_tree_node()
	return get_component_by_id("Tree"):find("/selected")
end

function add_component_in_hbox(container, component_name, attr_list)
	local hbox = add_component(container, {id = "HorizontalBox", horizontalAlignment = -1, verticalAlignment = -1, maximumWidth = 0}, "D#HorizontalBox")
	local component = add_component(hbox, attr_list, component_name)
return component, hbox
end

function get_tree_from_tree_node(tree_node)
	local parent = tree_node:find("/parentNode")
	if parent:is_empty() then
		
		return tree_node:find("/tree")
	else
		return get_tree_from_tree_node(parent)
	end
end

---Izdzēš notikuma objektu. Ja objekts nav norādīts, tad izdzēš visus objektus
-- @param ev notikuma objekts
function delete_event(ev)
	if ev == nil then
		lQuery("D#Event"):delete()
	else
		ev:delete()
	end
end

---Aizver formu
-- @param form_id formas, kuru jāaizver id vērtība
function close_form(form_id)
-- changed by SK 
    local ev
        if (form_id == nil) or (form_id=="") then
          ev = lQuery("D#Event") -- [info = Close]
        else
      ev = lQuery("D#Form[id = " .. form_id .. "]"):find("/event")
    end
-- changed by SK	local ev = lQuery("D#Event")
	if ev:size() < 2 then
		local form
		if (form_id == nil) or (form_id=="") then
			local button = ev:find("/source")
			if (button:size()==0) then
              form = lQuery("D#Form")
              if (form:size()>1) then
                local maxID = form:get(1).id
                local i = 2
                while (i<=form:size()) do
                  if (form:get(i).id > maxID) then
                    maxID = form:get(i).id
                  end
                  i = i+1
                end
                form = lQuery("D#Form[id = " .. maxID .. "]")
              end
            else
              form = get_form_from_component(button)
            end
		else
			form = lQuery("D#Form[id = " .. form_id .. "]")
		end
		--utilities.execute_cmd("D#Command", {info = "Close", receiver = form})
		--ev:find("/source/defaultButtonForm"):link("command", function() return utilities.execute_cmd("D#Command", {info = "Close"}) end)

		ev:delete()
		-- delete_container_components(form)
		-- delete_container_components(lQuery("D#Form[id = " .. form:attr("id") .. "]"))	
		execute_d_command(form, "Close")	
		-- form:delete()
	end
end

function get_form_from_component(component)
	if component:filter(".D#Form"):is_not_empty() then
		return component
	else
		return get_form_from_component(component:find("/container"))
	end
end

function get_event_source_attrs(attr_name)
	local event_source = get_event_source()
return event_source:attr_e("id"), event_source:attr_e(attr_name)
end

function set_component_focused(container, component)
	container:link("focused", component)
	container:link("focusOrder", component)
end

function execute_d_command(component, info, attr_list)
	execute_command("D#Command", component, info, attr_list)
end

function execute_command(command_name, component, info, attr_list)
	attr_list = attr_list or {}
	attr_list["receiver"] = component
	attr_list["info"] = info
	utilities.execute_cmd(command_name, attr_list)
end

function show_form(form)
	execute_d_command(form, "ShowModal")
end

function refresh_form_component(component)
	--execute_d_command(component, "Refresh")
	local cmd = utilities.create_command("D#Command", {info = "Refresh"})
	component:link("command", cmd)
	utilities.execute_cmd_obj(cmd)
end


