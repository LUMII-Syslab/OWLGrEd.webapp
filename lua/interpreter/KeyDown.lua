module(..., package.seeall)
require("utilities")
d = require("dialog_utilities")
report = require("reporter.report")
require("config_properties")
--visualizeMM = require("Plugins.visualizeMM.visualizeMM")
visualizeMM = require("interpreter.visualize_MM_instances")

function KeyDown(ev_in)
	local ev = utilities.get_event(ev_in, "KeyDownEvent")
	local key_combination = ev:attr_e("info")
	local enter_table = {Enter = true, ['Num Enter'] = true}
	if enter_table[key_combination] then
		key_combination = "Enter"
	end
	if key_combination == "`" then
		display_console()
	elseif key_combination == "L" then
		report_key_down_event({key = key_combination, action = "main.lua"})
		dofile(tda.GetRuntimePath() .. "/lua/main.lua")
	elseif key_combination == "C" then
		if not config_properties.get_config_value("is_configurator_hidden") then
			report_key_down_event({key = key_combination, action = "Show Configurator"})
			utilities.open_diagram(lQuery("GraphDiagramType[id = 'specificationDgr']/graphDiagram:first()"))
		end
	else
		local diagram = lQuery("CurrentDgrPointer/graphDiagram")
		local collection_elems = diagram:find("/collection/element")
		local collection_size = collection_elems:size()
		local key_board_short_cut = nil
		if collection_size == 0 then
			key_board_short_cut = diagram:find("/graphDiagramType/eKeyboardShortcut[key = " .. key_combination  .. "]")
		elseif collection_size == 1 then
			key_board_short_cut = collection_elems:find("/elemType/keyboardShortcut[key = " .. key_combination  .. "]")
		elseif collection_size > 1 then
			key_board_short_cut = diagram:find("/graphDiagramType/cKeyboardShortcut[key = " .. key_combination  .. "]")
		else
			print("Error in KeyDown")
			return -1
		end
		if key_board_short_cut ~= nil then
			local proc_name = key_board_short_cut:attr_e("procedureName")
			local action_transformations = utilities.default_actions()
			if action_transformations[proc_name] ~= nil then
				proc_name = action_transformations[proc_name]
			end
			utilities.execute_translet(proc_name)
			report_key_down_event({key = key_combination, action = proc_name})
		end
	end
	ev:delete()	
end

function display_console()
	local form = d.add_form({caption = "Console", id = "cosnole_form"})
		d.add_vertical_box_labeled_field(form, {caption = "Expression"}, {id = "multi_text_box"}, {id = "row_multi_text_box"}, "D#MultiLineTextBox", {})
		local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
			d.add_button(button_box, {caption = "Visualize", id = "visualize_button"}, {Click = "lua.interpreter.KeyDown.visualize_query"})
			d.add_button(button_box, {caption = "Evaluate", id = "eval_button"}, {Click = "lua.interpreter.KeyDown.evaluate"})
			d.add_button(button_box, {caption = "Close", id = "close_button"}, {Click = "lua.interpreter.KeyDown.close_console"})
								:link("defaultButtonForm", form)
	d.show_form(form)
end

function visualize_query()
	local expression = get_query_expresssion()
	local collection = loadstring(string.format('return lQuery("%s")', expression))()
	visualizeMM.visualizeCollection(collection)
	close_console()
end

function evaluate()
	local expression = get_query_expresssion()
	local diagram = lQuery("CurrentDgrPointer/graphDiagram")
	local collection_elems = diagram:find("/collection/element")
	local collection_size = collection_elems:size()
	local res_obj = nil
	if collection_size == 0 then
		res_obj = diagram:find(expression)		
	elseif collection_size > 0 then
		if expression == "" then 
			res_obj = collection_elems
		else
			res_obj = collection_elems:find(expression)
		end
	end
	if res_obj ~= nil then
		show_object(res_obj)
	end
end

function show_object(res_objects)
	local query_res = ""
	res_objects:each(function(obj)
		query_res = query_res .. ":" .. obj:get(1):class().name .. "\n"
		local list = obj:map(function(o) 
			return obj:get(1):get_property_table()
		end)
		query_res = query_res .. utilities.concat_attr_dictionary(list[1], "\n") .. "\n"
	end)
	local form = d.add_form({caption = "Query Result", id = "query_form", maximumWidth = 50, horizontalAlignment = -1})
		--local row = d.add_component(form, {id = "row"}, "D#Row")
		local label_box = d.add_component(form, {id = "label_box", horizontalAlignment = -1, maximumWidth = 50}, "D#VerticalBox")
			d.add_component(label_box, {id = "query_label", caption = query_res, horizontalAlignment = -1, maximumWidth = 150}, "D#Label")
		local button_box = d.add_component(form, {id = "query_button_box", horizontalAlignment = 1, maximumWidth = 150}, "D#HorizontalBox")
			d.add_button(button_box, {caption = "Close", id = "close_query_button", horizontalAlignment = 1}, {Click = "lua.interpreter.KeyDown.close_query_form"})
								:link("defaultButtonForm", form)
	d.show_form(form)
end

function get_query_expresssion()
	local expression = d.get_component_by_id("multi_text_box"):attr_e("text")
	expression = string.gsub(expression, '[%s\n\t]', "")
	return expression
end

function close_query_form()
	utilities.close_form("query_form")
end

function close_console()
	utilities.close_form("cosnole_form")
end

function report_key_down_event(list)
	report.event("KeyDown", list)
end
