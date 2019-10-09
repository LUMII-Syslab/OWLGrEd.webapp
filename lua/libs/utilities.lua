module(..., package.seeall)
lQuery = require("lQuery")
report = require("reporter.report")
require ("lpeg")
require ("initialize")
tda = require("lua_tda")
d = require("dialog_utilities")
t = require("interpreter.tree")
serialization = require("serialize")
require("lua_graphDiagram")
report = require("reporter.report")
styles = require("graph_diagram_style_utils")

---utilities

---Ierindo komandu
-- @param command_name komandas nosaukums 
-- @param attrs atribûtu saraksts
-- @return komandas objekts
function enqued_cmd (command_name, attrs)
	local cmd = lQuery.create(command_name, attrs)
	tda.EnqueueCommand(cmd:id())
	return cmd
end

---Izveido komandai atbilstoðo objektu
-- @param command_name komandas nosaukums 
-- @param attrs atribûtu saraksts
-- @return komandas objekts
function create_command(command_name, attrs)
	return lQuery.create(command_name, attrs)
end

---Izveido un izpilda komandai atbilstoðo objektu
-- @param command_name komandas nosaukums 
-- @param attrs atribûtu saraksts
function execute_cmd(command_name, attrs)
	local cmd = lQuery.create(command_name, attrs)
print("executing from lua "..command_name, attrs)
	execute_cmd_obj(cmd)
end

---Izpilda komandai atbilstoðo objektu
-- @param command komandai atbilstoðais objekts
function execute_cmd_obj(command)
	tda.ExecuteCommand(command:id())
end

function refresh_form_component(component)
	d.refresh_form_component(component)
end

function close_diagram(diagram)
print("closing diagram ",diagram)
	execute_cmd("CloseDgrCmd", {graphDiagram = diagram})
end

function refresh_diagram(diagram, previous_object_id)
	if previous_object_id then
		utilities.execute_cmd("RefreshDgrCmd", {graphDiagram = diagram, info = previous_object_id})
	end
end

function close_form(form_id)
	d.close_form(form_id)
end

---Sameklç aktîvo diagrammu
-- @return diagrammas objekts
function current_diagram()
	return lQuery("CurrentDgrPointer/graphDiagram")
end

---Sameklç diagrammâ iezîmçtos elementus
-- @return iezîmçto objektu kolekcija
function active_elements()
	return current_diagram():find("/collection/element")
end

function save_dgr_cmd(diagram)
	execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
end

function d_handler(event_name, dll_name, transformation)
	return lQuery.create("D#EventHandler", {
      eventName = event_name
      ,transformationName = dll_name
      ,procedureName = transformation
  })
end

function serialize (o)
  local result = ""
  if type(o) == "number" then
    result = result .. o
  elseif type(o) == "string" then
    result = result .. string.format("%q", o)
  elseif type(o) == "table" then
    result = result .. "{"
    for k,v in pairs(o) do
      if type(k) == "number" then
        result = result .. "  [" .. k .. "] = " .. serialize(v) .. ","
      else
        result = result .. "  [\"" .. k .. "\"] = " .. serialize(v) .. ","
      end
    end
    result = result .. "}"
  else
    error("cannot serialize a " .. type(o))
  end
  
  return result
end

function deserialize(string)
  return loadstring("return " .. string)()
end

function export_active_diagram_with_subtree()
  export_diagram_with_subtree(lQuery("CurrentDgrPointer/graphDiagram"))
end

function export_diagram(diagram)
  serialization.save_to_file(diagram, serialization.diagram_only_export_spec, "diagram_export_result")
end

function export_diagram_to_file(diagram, file_name)
  serialization.save_to_file(diagram, serialization.diagram_only_export_spec, file_name)
end

function export_diagram_with_subtree(diagram)
  serialization.save_to_file(diagram, serialization.export_spec, "diagram_export_result")
end

function import_diagram()
  local root_object = serialization.import_from_file("diagram_export_result")
  execute_cmd("ActiveDgrCmd", {graphDiagram = lQuery(root_object)})
  execute_cmd("OkCmd")
end

---Pârbauda, vai saraksts ir tukðs
-- @param list saraksts
function is_table_empty(list)
  if next(list) == nil then
    return true
  else
    return false
  end
end

function activate_element(element)
  local diagram = element:find("/graphDiagram")
-- added by SK

    diagram:find("/collection"):each(function(coll)
      coll:remove_link("element", coll:find("/element"))
    end)

    diagram:find("/collection"):delete()
    local coll = lQuery.create("Collection", {element = element})
    diagram:link("collection", coll)

-- added by SK
  tda.ExecuteCommand(lQuery.create("ActiveElementCmd"):link("element", element):link("graphDiagram", diagram):id())
   -- execute_cmd("ActiveElementCmd", {element = element})
end

function close_diagram_cmd(diagram)
	execute_cmd("CloseDgrCmd", {graphDiagram = diagram})
end

---Navigç no elementa uz diagrammu
-- @param elem elements, no kura navigçs
function navigate(elem)
	if elem == nil then
		elem = utilities.active_elements()
	end
	local diagram = elem:find("/target")
	if diagram:is_not_empty() then
		open_diagram(diagram)	
	else
		diagram = elem:find("/child")
		open_diagram(diagram)
	end
end

---Ja ir iespçjams, navigç no elementa uz diagrammu, ja ne, tad atver dialogu logu
-- @param elem elements, no kura navigçs, vai, kuram atvçrs dialogu logu
function navigate_or_properties(elem)
	if elem:find("/child"):is_not_empty() or elem:find("/target"):is_not_empty() then
		utilities.navigate(elem)
	else
		utilities.call_element_proc_thru_type(elem, "procProperties")
	end
end

---Atver diagrammu
-- @param diagram diagrammu, kuru atvçrs
function open_diagram(diagram)
	if diagram ~= nil and diagram:is_not_empty() then
		if diagram:attr("isReadOnly") ~= "true" then
			report.event("Navigation", {
				Diagram = function() return diagram:attr("caption") end,
				ElemType = get_source_elem_type(diagram)
			})
			execute_cmd("ActiveDgrCmd", {graphDiagram = diagram})
    			local tree_node = get_tree_node_from_thing(diagram)
			if tree_node:is_not_empty() then
				--t.select_node(tree_node)
			else
				--t.set_no_selected_node(is_refresh_needed)
			end
		else
			execute_cmd("ActiveDgrViewCmd", {graphDiagram = diagram})
		end
	end
end

function get_source_elem_type(diagram)
	local elem = diagram:find("/parent")
	if elem:is_empty() then
		elem = diagram:find("/source")
	end
	if elem:is_not_empty() then
		return elem:find("/elemType"):attr("id")
	end
end

---Parâda ziòojumu
-- @param msg ziòojuma teksts
function ShowInformationBarCommand(msg)
	execute_cmd("ShowInformationBarCommand", {message = msg})
end

function add_command(elem, diagram, command_name, attr_table)
	attr_table = attr_table or {}
	attr_table["element"] = elem
	attr_table["graphDiagram"] = diagram
	utilities.execute_cmd(command_name, attr_table)
end

function add_command_to_execute(elem, diagram, command_name, attr_table)
	local cmd = create_command(command_name, attr_table):link("element", elem)
							:link("graphDiagram", diagram)
	execute_cmd_obj(cmd)
end

function add_command_without_diagram(elem, command_name, attr_table)
	attr_table["element"] = elem
	attr_table["graphDiagram"] = elem:find("/graphDiagram")
	utilities.execute_cmd(command_name, attr_table)
end

function call_element_proc_thru_type(element, attr_name, ...)
	return call_elemType_proc_with_supertypes(element:find("/elemType"), attr_name, element, ...)
end

function call_elemType_proc_with_supertypes(elemType, attr_name, ...)
	local func_names = get_translets(elemType, attr_name, true)
	if func_names ~= "" and #func_names > 0 then
		return execute_translet(func_names, ...)
	end
end

function execute_translets(obj, attr_name, ...)
	local func_names = get_translets(obj, attr_name, true)
	if func_names ~= "" and #func_names > 0 then
		return execute_translet(func_names, ...)
	end
end

function call_compartment_proc_thru_type(compart, attr_name, ...)
	local compart_type = compart:find("/compartType")
	--local translet = compart_type:find("/translet[extensionPoint = " .. attr_name .. "]")
	local func_names = get_translets(compart_type, attr_name)
	if #func_names > 0 then
		return execute_translet(func_names, compart, ...)
	end
	local translet = compart_type:find("/translet[extensionPoint = " .. attr_name .. "]")
	if utilities.execute_should_be_included(translet) then
		local func_name = translet:attr("procedureName")
		return execute_translet(func_name, compart, ...)
	end
end

function decode_function_and_dll_name(func_name)
	local res = split_string_by_delimiter(func_name, "#")
	local proc_name, dll_name = ""
	if res ~= nil then
		if res["End"] == nil then
			dll_name = "main.dll"
			proc_name = "_L0_Func_" + res["Start"]
		elseif res["Start"] == "lua" then
			dll_name = "lua"
			proc_name = res["End"]
		else
			dll_name = res["Start"] .. ".dll"
			proc_name = res["End"]
		end
	end
return proc_name, dll_name
end

function split_string_by_delimiter(value, delimiter)
	local Delimiter = lpeg.P(delimiter)
	local String = lpeg.C((1 - Delimiter) ^ 1)
	local res = nil
	if value ~= nil and value ~= "" then
		res = lpeg.match((lpeg.Ct(lpeg.Cg(String, "Start") * (lpeg.Cg(Delimiter, "Delimiter") * lpeg.Cg(String, "End")) ^ -1) ^ -1), value)
	end
return res
end

function get_translets(elem_type, attr_name, isParentTraversingNeeded)
	local proc_names = {}
	if elem_type ~= nil then
		if elem_type:size() > 0 then
			--hacks => ja nav translet, tad nem no elemType - prieks vecajiem projektiem
			local translets = elem_type:find("/translet[extensionPoint = " .. attr_name .. "]")
			if translets:is_not_empty() then
				translets:each(function(translet)
					local proc_name = translet:attr_e("procedureName")
					if proc_name ~= "" then
						table.insert(proc_names, proc_name)
					end
				end)
			else
				local proc_name = elem_type:attr_e(attr_name)
				if proc_name ~= "" then
					table.insert(proc_names, proc_name)
				end
			end
			if isParentTraversingNeeded then
				if #proc_names == 0 then
					local super_type = elem_type:find("/superType, /parentCompartType")
					if super_type:size() > 0 then
						proc_names = get_translets(super_type, attr_name, isParentTraversingNeeded)
					end
				end
			end
		end
	end
	return proc_names
end

local function is_file_in_lua_path(lua_package_path, path)
  for c in string.gfind(lua_package_path, "[^;]+") do
    c = string.gsub(c, "%?", path)
    local f = io.open (c)
		if f then
			f:close ()
			return true
		end
  end
end

function getfield (f)
  local pattern = "[%w_]+"
  local lua_package_search_path = package.path
  local current_path_steps = {}
  
  local first_step = string.match(f, pattern)
  local v = _G[first_step] and _G or nil -- start with the table of globals or nothing
  
  for path_step in string.gfind(f, pattern) do
    table.insert(current_path_steps, path_step)
    local path = table.concat(current_path_steps, "/")
    local pathdot = table.concat(current_path_steps, ".")
    if v and v[path_step] then
      v = v[path_step]
    else
      if is_file_in_lua_path(lua_package_search_path, path) or is_file_in_lua_path(lua_package_search_path, pathdot) then
        v = require(pathdot)
        if v == true then
          error("Error loading module, file should start with a module declaration, e.g. module(..., package.seeall)", 1)
        end
      else
        v = nil
      end
    end
  end
  
  if not v then
    error("could not find " .. f, 3)
  end
  
  return v
end

-- print error to console, so that user knowns something went wrong
-- report error so that we know something went wrong
function create_error_handler(function_path)
	return function (error_obj)
		local traceback = debug.traceback()

		print(error_obj, "\n", traceback)

		report.event("lua-error", {
			error_message = error_obj,
			stacktrace = traceback,
			origin_path = function_path,
		})
		
		return false
	end
end

---Izpilda patvaïîgu lua funkciju
-- @param function_path ceïð uz izpildâmo funkciju
-- @param ... paremetri, kas tiks nodoti izpildâmajai funkcijai
function execute_fn(function_path, ...)
	return execute_function(function_path, true, ...)
end

function quiet_execute_fn(function_path, ...)
	return execute_function(function_path, false, ...)
end

function execute_function(function_path, is_error_msg_needed, ...)
	local module_loading_errors = {}
	local record_loading_error = function(error_obj)
		table.insert(module_loading_errors, error_obj)
		table.insert(module_loading_errors, debug.traceback())
	end
	local is_function_found, fn = xpcall(function() return getfield(function_path) end, record_loading_error)

	if not is_function_found then
		local error_message = "function " .. function_path .. " could not be found"
		if is_error_msg_needed then
			error(error_message .. "\n" .. table.concat(module_loading_errors, "\n"), 2)
		else
			log("supressed error", error_message)
		end
	elseif is_function_found then
		local args = {...}
		local status_boolean, res1, res2 = xpcall(function() return fn(unpack(args)) end,
						create_error_handler(function_path))
		if not status_boolean then
			error(res1)
		end

		return res1, res2
	end
end

function concat_attr_dictionary(list, sep)
	local res = ""
	for index, value in pairs(list) do
		if res == "" then
			res = index .. " = " .. value
		else
			res = res .. sep .. index .. " = " .. value
		end
	end
return res
end

function concat_dictionary(list, sep)
	local res = ""
	for _, value in pairs(list) do
		if res == "" then
			res = value
		else
			res = res .. sep .. value
		end
	end
return res
end

function execute_translet(translets, ...)
	if type(translets) == "table" then
		if #translets == 1 then
			return execute_translet_funcion(translets[1], ...)
		else
			for _, translet_name in ipairs(translets) do
				execute_translet_funcion(translet_name, ...)
			end
		end
	elseif translets ~= "" and translets ~= nil then
		return execute_translet_funcion(translets, ...)
	end
end

function execute_translet_funcion(translet_name, ...)
	if string.find(translet_name, "lua_engine") ~= nil or string.find(translet_name, '[.]') ~= nil  then --[^%a%d_]
		return utilities.execute_fn(translet_name, ...)
	else
		utilities.execute_cmd("ExecTransfCmd", {info = translet_name})
	end
end

function do_nothing()
	log("do nothing")
end

function get_elem_type(elem)
	return get_obj_type(elem)
end

---Pârkopç vienu lQuery objektu uz otru 
-- @param source_elem elements, no kura kopç
-- @param target_elem elements, kurâ kopç
function copy_objects(source_elem, target_elem)
	local attr_list = get_lQuery_object_attribute_list(source_elem)
	target_elem:attr(attr_list[1])
end

function make_elem_copy(source_elem)
	return make_obj_copy(source_elem)
end

---Uztaisa lQuery objekta klonu
-- @param obj objekts, kuru klonç 
-- @return objekts, kas ir padotâ objekta klons
function make_obj_copy(source_elem)
	return lQuery.create(utilities.get_class_name(source_elem), get_lQuery_object_attribute_list(source_elem)[1])
end

function get_lQuery_object_attribute_list(obj)
	local list = obj:map(function(o) 
		return o:get(1):get_property_table() 
	end)
return list
end

function get_object_difference(obj1, obj2)
	local res = {}
	local list1 = get_lQuery_object_attribute_list(obj1)[1]
	local list2 = get_lQuery_object_attribute_list(obj2)[1]
	for index, val in pairs(list1) do
		local list2_val = list2[index]
		if list2_val ~= val then
			res[index] = list2_val
		end
	end
	return res
end

---Sameklç objekta tipu
-- @param obj objekts 
-- @return objekta tipa objekts
function get_obj_type(obj)
	if obj:filter(".Element"):is_not_empty() then
		return obj:find("/elemType")
	elseif obj:filter(".Compartment"):is_not_empty() then
		return obj:find("/compartType")
	elseif obj:filter(".GraphDiagram"):is_not_empty() then
		return obj:find("/graphDiagramType")
	else
		error("No Object Type")
	end
end

function update_target_diagram_caption(compart)
	local caption = compart:attr_e("input")
	local diagram = utilities.active_elements():find("/target")
	if diagram:is_not_empty() and caption ~= nil and caption ~= "" then
		set_diagram_caption(diagram, caption)
	end
end

function refresh_active_diagram(elem)
	local dgr = lQuery("CurrentDgrPointer/graphDiagram")
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = dgr})
	if elem ~= nil then
		utilities.execute_cmd("OkCmd", {graphDiagram = dgr, element = elem})
	else
		utilities.execute_cmd("OkCmd", {graphDiagram = dgr})
	end
end

function refresh_element_without_diagram(elem)
	utilities.execute_cmd("OkCmd", {element = elem})
end

function refresh_element(elem, diagram)
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram, element = elem})
end

function refresh_only_diagram(diagram)
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end

---Sameklç elementa objektu, kuram ðis compartments pieder
-- @param compart compartment objekts 
-- @return elementa objekts
function get_element_from_compartment(compart)
	return get_root_from_obj(compart, "/parentCompartment", "/element")
end

function get_elemType_from_compartType(obj_type)
	return get_root_from_obj(obj_type, "/parentCompartType", "/elemType")
end

function get_root_from_obj(obj, path1, path2)
	local parent = obj:find(path1)
	if parent:is_not_empty() then
		return get_root_from_obj(parent, path1, path2)
	else
		parent = obj:find(path2)
		if parent:is_not_empty() then
			return parent
		elseif obj:is_not_empty() then
			return obj
		else
			error("no root")
		end
	end
end

function apply_elemStyle(elem, elem_style)
	if elem ~= nil and elem_style ~= nil then
		elem:link("elemStyle", elem_style)
	end
	--apply_elemStyle_to_occurrences(elem, elem_style)
end

function apply_default_elemStyle(elem)
	local elem_style = elem:find("/elemType/elemStyle:first()")
	apply_elemStyle(elem, elem_style)
end

function apply_compartStyle(compart, compart_style)
	if compart_style ~= nil then
		compart:link("compartStyle", compart_style)
		if compart:attr("style") ~= "" then
			compart:attr({style = "#"}) 
		end
	end
	--apply_compartStyle_to_occurrences(compart, compart_style)
end

function apply_default_compartStyle(compart)
	local compart_style = compart:find("/compartType/compartStyle:first()")
	apply_compartStyle(compart, compart_style)
end

---Atgrieþ objekta klases nosaukumu
-- @param obj objekts, kura klases nosaukumu meklç
-- @return objekta klases nosaukums
function get_class_name(obj)
	return obj:get(1):class().name
end

function show_element_compartment_tree()
	local elem = utilities.active_elements()
	local res_table = {}
	local copmarts = elem:find("/compartment")
	insert_compart(copmarts, res_table)
	print(dumptable(res_table))

	--local path_to_file = tda.GetProjectPath() .. "\\" .. "show_elements.txt"
	--local export_file = io.open(path_to_file, "w")
	--	export_file:write(dumptable(res_table))
	--export_file:close()
end

function insert_compart(copmarts, res_table)
	copmarts:each(function(compart)
		local compart_id = compart:find("/compartType"):attr("id")
		local sub_comparts = compart:find("/subCompartment")
		local id_list = {}
		sub_comparts:each(function(sub_compart)
			local id = sub_compart:find("/compartType"):attr("id")
			id_list[id] = true
		end)
		local count = 0
		for _, _ in pairs(id_list) do
			count = count + 1
		end
		if sub_comparts:is_empty() then
			res_table[compart_id] = compart:attr("value")
		elseif sub_comparts:size() > 1 and count == 1 then
			res_table[compart_id] = {}
			local counter = 1
			sub_comparts:each(function(sub_compart)
				table.insert(res_table[compart_id], {})
				insert_compart(sub_compart, res_table[compart_id][counter])
				counter = counter + 1
			end)
		else
			res_table[compart_id] = {}
			insert_compart(sub_comparts, res_table[compart_id])
		end
	end)
end

function insert_compart(source, path, res_table)
	source:find(path):each(function(compart)
		local compart_id = compart:find("/compartType"):attr("id")
		if compart:find("/subCompartment"):is_empty() then
			res_table[compart_id] = compart:attr("input")
		else
			res_table[compart_id] = {}
			insert_compart(compart, "/subCompartment", res_table[compart_id])
		end
	end)
end

function search_in_table(in_table, item)
	local buls = false
	local res = nil
	for _, tmp in pairs(in_table) do
		if tmp == item then
			buls = true
			res = tmp
			break
		end
	end
	return res, buls
end

function add_navigation_diagram(element)
	local elem_type = element:find("/elemType")
	local diagram = utilities.add_graph_diagram_to_graph_diagram_type("", elem_type:find("/target"))
	diagram:link("source", element)
	diagram:link("parent", element)
	return diagram
end

function add_graph_diagram(name, diagram_style)
	local diagram = lQuery.create("GraphDiagram", {
		caption = name, 
		layoutMode = diagram_style:attr("layoutMode"), 
		layoutAlgorithm = diagram_style:attr("layoutAlgorithm"),
		bkgColor = diagram_style:attr("bkgColor"), 
		screenZoom = diagram_style:attr("screenZoom"), 
		printZoom = diagram_style:attr("printZoom")
	})
	return diagram
end

function add_graph_diagram_to_graph_diagram_type(name, diagram_type)
	local diagram_style = diagram_type:find("/graphDiagramStyle:first()")
	local diagram = add_graph_diagram(name, diagram_style):link("graphDiagramType", diagram_type)
						:link("graphDiagramStyle", diagram_style)
	set_diagram_caption(diagram, name, is_refresh_needed)	
	add_palette_to_diagram(diagram, diagram_type)
	add_toolbar_to_diagram(diagram, diagram_type)
	local translet_name = diagram_type:find("/translet[extensionPoint = 'procCreateDiagram']"):attr("procedureName")
	execute_translet(translet_name, diagram)
	--execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
	return diagram
end

function add_palette_to_diagram(diagram, diagram_type)
	make_palette_toolbar_with_palette_elements(diagram_type:find("/paletteType"), "paletteElementType", "Palette", "paletteElement", "PaletteElement", diagram, "palette", diagram_type)
end

function add_toolbar_to_diagram(diagram, diagram_type)
	make_palette_toolbar_with_palette_elements(diagram_type:find("/toolbarType"), "toolbarElementType", "Toolbar", "toolbarElement", "ToolbarElement", diagram, "toolbar", diagram_type)
end

function make_palette_toolbar_with_palette_elements(base_type, role_type, base, role, base_element, diagram, role_to_obj, diagram_type)
	if base_type:is_not_empty() then
		diagram:find("/" .. role_to_obj):delete()
		local new_base = add_palette_toolbar_base(base, base_type, diagram)
		new_base:find("/" .. role):delete()
		base_type:find("/" .. role_type):each(function(obj_type)
			if utilities.execute_should_be_included(obj_type) then
				add_element_to_base(new_base, base_element, role, obj_type)
			end
		end)
	end
end

function add_palette_toolbar_base(base, base_type, diagram)
	return lQuery.create(base):link("type", base_type)
					:link("graphDiagram", diagram)
end

function add_element_to_base(new_base, base_element, role_to_base_elem, obj_type)
	if base_element ~= "ToolbarElement" then
		local palette_elem_table = {
			NodeType = "PaletteBox",
			EdgeType = "PaletteLine",
			FreeBoxType = "PaletteFreeBox",
			FreeLineType = "PaletteFreeLine",
			PortType = "PalettePin"
		}
		base_element = palette_elem_table[utilities.get_class_name(obj_type:find("/elemType"))]
	end
	local attr_list = {}
	attr_list["caption"] = obj_type:attr("caption")
	attr_list["picture"] = obj_type:attr("picture")
	attr_list["procedureName"] = obj_type:attr("procedureName")
	local new_obj = lQuery.create(base_element, attr_list)
			:link("type", obj_type)
	new_base:link(role_to_base_elem, new_obj)
return new_obj
end

function append_to_session_file(str)
	local file = open_session_file("a")
		io.output(file)
		file:write(str)
	io.close(file)
end

function append_to_tmp_version_file(str)
	local file = open_tmp_version_file("a")
		file:write(str)
	io.close(file)
end

function open_session_file(mode)
	return open_file_from_current_project("session.lua", mode)
end

function open_tmp_version_file(mode)
	return open_file_from_current_project("tmp_version.lua", mode)
end

function clear_tmp_version_file()
	local file = utilities.open_tmp_version_file("w")
		file:write("")
	file:close()
end

function clear_session_file()
	local file = utilities.open_file_from_current_project("\\session.lua", "w")
		file:write("")
	io.close(file)
end

function open_file_from_current_project(file_name, mode)
	return io.open(tda.GetProjectPath() .. "\\" .. file_name, mode)
end

---Uzìenerç kodu, kas izveido objektu
-- @param obj objekts, kura kodu ìenerç
-- @return kods, kas izveido padoto objektu
function generate_create_instance_code(obj)
	local obj_id = obj:id()
	local attr_list = utilities.get_lQuery_object_attribute_list(obj)
	local distance = "\t"
	local list_of_code = {}
	table.insert(list_of_code, string.format('%s = lQuery.create("%s", {\n%s%s})\n', make_obj_to_var(obj), utilities.get_class_name(obj), distance, concat_attr_list(attr_list[1], ',\n' .. distance)))
	return table.concat(list_of_code)
end

function concat_attr_list(attr_list, sep)
	local list = {}
	for index, value in pairs(attr_list) do
		if tonumber(value) == nil then
			local new_val = string.gsub(value, "\\", "\\\\")
			new_val = string.gsub(new_val, '"', '\\"')
			new_val = string.gsub(new_val, '\n', '\\n')
			value = string.format('"%s"', new_val)
		end
		table.insert(list, string.format("%s = %s", index, value))
	end
	return table.concat(list, sep)
end

---Izveido objekta mainîgâ kodu
-- @param obj objekts, kuram veido kodu
-- @return objekta kods
function make_obj_to_var(obj)
	return string.format("var_%s", obj:id())
end

function is_compart_type_fictious(compart_type)
	if compart_type:is_not_empty() then
		local start, finish = string.find(compart_type:attr("id"), "ASFictitious")
		if start == 1 and finish == 12 then
			return true
		else
			return false
		end
	else
		return false
	end
end

function execute_should_be_included(obj)
	local func_name = obj:attr_e("shouldBeIncluded")
	if func_name == "" or func_name == nil or utilities.execute_translet(func_name) then
		return true
	else
		return false
	end
end

---Maina konkrçtas elementa stila vçrtîbas
-- @param elem elements, kuram maina stilu
-- @param list saraksts ar atribûtiem, kurus maina
function set_elem_style(elem, list)
	if elem:size() > 0 then	
		local cmd = lQuery.create("UpdateStyleCmd")
		local first_elem = elem:filter(":first()")
		local class_name = utilities.get_class_name(first_elem:find("/elemType/elemStyle:first()"))
		local tmp_style = lQuery.create(class_name, list)
		elem:remove_link("elemStyle", elem:find("/elemStyle"))
		cmd:link("element", elem)
               		:link("elemStyle", tmp_style)
	       		:link("graphDiagram", elem:find("/graphDiagram"))
		utilities.execute_cmd_obj(cmd)
		tmp_style:delete()
	end
end

function set_palette_element_attribute()
	local elem = utilities.active_elements()
	make_palette_element(elem)
end

function make_palette_element(elem)
	local cu = require("configurator.const.const_utilities")
	cu.add_palette_element_from_configurator(elem)
end

function get_translet_by_name(source, extension_point)
	local translets = source:find("/translet[extensionPoint = '" .. extension_point .. "']")
	local translet = translets:find(":first()")
	return translet:attr("procedureName"), translet, translets
end


function add_translet_if_missing(type, extension_point, procedure_name)
  local translet = type:find("/translet")
                        :filter_attr_value_equals("extensionPoint", extension_point)
                        :filter_attr_value_equals("procedureName", procedure_name)
  if translet:is_empty() then
	add_translet(type, extension_point, procedure_name)
  end
end

function add_translet(type, extension_point, procedure_name)
  return lQuery.create("Translet", {
      type = type,
      extensionPoint = extension_point,
      procedureName = procedure_name
    })
end

function test()
	print("utilities test")
end

function field_test(compart, old_val)
print("field test")
	compart:log("value")
	print(old_val)
print("end field test")
end

function refresh_diagram_from_compart(compart)
	local elem = utilities.get_element_from_compartment(compart)
	if elem ~= nil then
		local diagram = elem:find("/graphDiagram")
		if diagram:is_not_empty() then
			local ok_cmd = utilities.create_command("OkCmd", {graphDiagram = elem:find("/graphDiagram")})
			utilities.execute_cmd_obj(ok_cmd)
			--utilities.execute_cmd("OkCmd", {graphDiagram = elem:find("/graphDiagram")})
		end
	end
end

function add_pop_up_element(pop_up_diagram, attr_table)
	pop_up_diagram:link("popUpElement", lQuery.create("PopUpElement", attr_table))
end

function get_obj_type_parent(compart_type)
	local role = "parentCompartType"
	local parent = compart_type:find("/" .. role)
	if parent:is_empty() then
		role = "elemType"
		parent = compart_type:find("/" .. role)
	end
	return parent, role
end

function get_project_language()
	local lang = ""
	local project_lang = lQuery("Project"):attr("language")
	if project_lang == nil or project_lang == "" then
		lang = "eng"
	else
		lang = project_lang
	end
	return lang
end

---Pievieno objektam tagu
-- @param obj objekts, kuram pievieno Tag objektu
-- @param key Tag identifikators
-- @param value Tag veriba
-- @param add_new norâda, vai veidot jaunu Tag objektu, vai arî pârrakstît kâdu no jau esoðajiem ar ðâdu identifikatoru
-- @return Tag objekts
function add_tag(obj, key, value, add_new)
	local tags = lQuery.new({})
	if obj:size() == 1 then
		local tag = get_tags(obj, key):find(":first")
		if tag:is_empty() or add_new then
			tag = lQuery.create("Tag", {
				key = key
			})
			obj:link("tag", tag)
		end
		tag:attr("value", value)
		--tags:add(tag)
		tags = tag
	else 
		obj:each(add_tag, key, value, add_new)
	end
	return tags
end

---Sameklç objekta tagus pçc identifikatora
-- @param obj objekts, kuram meklç tagu
-- @param key Tag identifikators
-- @return Tag objekts
function get_tags(obj, key)
	local tags = obj:find("/tag")
	if key then
		return tags:filter_attr_value_equals("key", key)
	else
		return tags
	end
end

function add_tree_node_tag(obj)
	add_tag(obj, "IsTreeNode", "true")
end

function add_tooltype_tag(key, value, append)
	local tool_type = lQuery("ToolType")
	return add_tag(tool_type, key, value, append)
end

function get_tooltype_tags(key)
	return lQuery("ToolType/tag"):filter_attr_value_equals("key", key)
end

function log_tags(obj)
	obj:log():find("/tag"):log("key", "value")
end

---Pârzîmç lînijas
-- @param elems elementu kopa, kuriem ir jâpârzîmç lînijas
function Reroute(elems)
	if elems == nil then
		elems = utilities.active_elements()
	end
	local edges = elems:filter(".Edge")
	local edge = edges:find(":first()")
	local cmd = lQuery.create("RerouteCmd"):link("element", edges)
						:link("graphDiagram", edge:find("/graphDiagram"))
	execute_cmd_obj(cmd)
end

---Atver stila kasti un, ja vajag nomaina, aktîvâ elementa stilu
function symbol_style()
	local element = utilities.active_elements()
	local diagram = element:find("/graphDiagram")
	add_command(element, diagram, "StyleDialogCmd")
end

---Atver stila kasti un, ja vajag nomaina, visiem kolekcijas elementiem stilu
function symbol_style_for_collection()
	styles.symbol_style_for_collection()
end

function ok_style_dialog_for_collection()
	styles.ok_style_dialog_for_collection()
end

function cancel_style_dialog_for_collection()
end

function delete_toolbar(diagram)
	delte_palette_or_toolbar(diagram, "/toolbar", "/toolbarElement")
end

function delete_palette(diagram)
	delte_palette_or_toolbar(diagram, "/palette", "/paletteElement")
end

function delte_palette_or_toolbar(diagram, role_to_base, role_to_element)
	local toolbars = diagram:find(role_to_base)
	toolbars:each(function(toolbar)
		toolbar:find(role_to_element):delete()
	end)
	toolbars:delete()
end

function delete_pop_up(diagram)
	local pop_ups = diagram:find("/popUpDiagram")
	pop_ups:each(function(pop_up)
		pop_up:find("/popUpElement"):delete()
	end)
	pop_ups:delete()
end

-- izdrukâ compartment koku
-- tipiskais lietojums iekð main ierakstam log_compart_tree(utilities.active_elements())
-- izdrukâs aktîvâ elementa compartment apakðkoku nospieþot L
function log_compart_tree(el, depth)
	depth = depth or 0
	print(string.rep(" ", depth) .. el:find("/elemType,/compartType"):attr("id"), el:attr("value"))
	el:find("/compartment,/subCompartment"):each(log_compart_struct, depth+1)
end

---Uzstâda diagrammas nosaukumu
-- @param diagram diagramma, kurai nomaina nosaukumu
-- @param name nosaukums
-- @param is_refresh_needed norâda, vai atbilstoðâ koka virsotne ir jâpârzîmç
function set_diagram_caption(diagram, name, is_refresh_needed)
	diagram:attr({caption = name})
	utilities.execute_cmd("UpdateDgrCmd", {graphDiagram = diagram})
	local diagram_type = diagram:find("/graphDiagramType")
	if get_tags(diagram_type, "IsTreeNode"):attr("value") == "true" then
		local node = diagram:find("/nodeParent")
		if node:is_empty() then
			local parent = diagram():find("/nodeParent")
			node = t.add_tree_node(parent)
			node:link("thing", diagram)
		end
		node:attr({caption = name})
		if is_refresh_needed == nil or is_refresh_needed == true then
			t.refresh(node)
		end
		return node
	end
end

---Sameklç diagrammas objektu, kurai ðis elements pieder
-- @param elem Element objekts, no kura meklç diagrammu
-- @return diagrammas objekts
function get_diagram_from_element(elem)
	return elem:find("/graphDiagram")
end

---Sameklç diagrammas objektu, kurai ðis compartments pieder
-- @param compart Compartment objekts, no kura meklç diagrammu
-- @return diagrammas objekts
function get_diagram_from_compartment(compart)
	local elem = get_element_from_compartment(compart)
	local diagram = get_diagram_from_element(elem)
	return diagram
end

function get_tree_node_from_thing(thing_obj)
	local parent = thing_obj:find("/nodeParent")
	if parent:is_empty() then
		local parent = lQuery("PT#Tab:first()")
	end
	return parent
end

---Sameklç projekts nosaukumu
-- @return projekta nosaukums
function get_project_name()
	return get_last_item_from_path(tda.GetProjectPath())
end

function get_last_item_from_path(path)
	local path_reverse = string.reverse(path)
	return string.reverse(string.sub(path_reverse, 1, string.find(path_reverse, "\\") - 1))
end

function create_pop_up_diagram()
	return lQuery.create("PopUpDiagram")
end

function show_pop_up_diagram(pop_up_diagram, elem)
	utilities.execute_cmd("PopUpCmd", {popUpDiagram = pop_up_diagram, graphDiagram = elem:find("/graphDiagram")})
end

function remove_target_diagram()

end

---Izlîdzina aktîvâs diagrammas kastes
function align_selected_boxes()
	lua_graphDiagram.AlignSelectedBoxesInDiagram(utilities.current_diagram():id())
end

---Atgrieþ saraksta elementu pretçjâ secîbâ
-- @param list saraksts
-- @return saraksts pretçjâ secîbâ
function make_reverse_list(list)
	local res_list = {}
	for i = #list,1,-1 do
		table.insert(res_list, list[i])
	end
	return res_list
end

function delete_event(ev)
	if ev == nil then
		ev = lQuery("Event")
	end
	ev:delete()
end

function get_property_row_from_row(row)
	return row:find("/propertyElement")
end

function export_to_SVG()
	lua_graphDiagram.ExportProjectToSVG()
end

function garbage_collection()

end

function get_event(ev, event_name)
	if ev == nil then
		if event_name == nil then
			return lQuery("Event")
		else
			return lQuery(event_name)
		end
	else
		return ev
	end
end

function default_actions()
	return {
		Cut = "interpreter.CutCopyPaste.Cut",
		Copy = "interpreter.CutCopyPaste.Copy",
		Paste = "interpreter.CutCopyPaste.Paste",
		Delete = "interpreter.Delete.Delete",
		SymbolStyle = "utilities.symbol_style",
		Reroute = "utilities.Reroute",
		Properties = "interpreter.Properties.Properties",
		AlignSelectedBoxes = "utilities.align_selected_boxes"
	} 
end