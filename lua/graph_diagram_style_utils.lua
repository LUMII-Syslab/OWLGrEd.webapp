module(..., package.seeall)

require("lua_graphDiagram")

require("re")
require("ordered_table")


-- for parsing lua table string form
-- that are returned by graph diagram engine
local function parse_lua_table_string_form(t_string_form)
  local p = re.compile([[
      table <- ('{'  (record ',' %s* )* '}') -> {}
      record <- ('{' [^}]* '}') -> parse_table
              / ({:key: %w+ :} '=' "'"  {:val: [^']* :}  "'") -> {}
  ]], {parse_table = parse_lua_table_string_form})

  return p:match(t_string_form)
end

local function to_ordered_table(d)
  local t = ordered_table.new()
  local counter = 1
  for _, key_val in ipairs(d) do
    if key_val.key then
      t[key_val.key] = key_val.val
    else
      t[counter] = to_ordered_table(key_val)
      counter = counter + 1
    end
  end

  return t
end



-- returns an ordered table
-- from element or compartment style attribute
-- the order of keys are the same as in style class
-- you should call save on diagram before this
-- to get the uptodate style in style attribute
function get_style_table(element_or_compartment)
	assert(element_or_compartment:size() == 1, "style parser works on exactly one instance")

	local style_parser_by_type = {
		Node = lua_graphDiagram.GetNodeStyle,
		Edge = lua_graphDiagram.GetEdgeStyle,
		Port = lua_graphDiagram.GetPortStyle,
		Compartment = lua_graphDiagram.GetCompartmentStyle,
	}

	local class_name = utilities.get_class_name(element_or_compartment)

	local style_parser_fn = style_parser_by_type[class_name]

	if type(style_parser_fn) == "function" then
		local style_str = element_or_compartment:attr("style")
        if (style_str == nil) then
          style_str = "" -- by SK
        end

		local t = ordered_table.new()

		if style_str ~= "" and style_str ~= "#" then
			assert(type(style_str) == "string", "style string must be string")
			assert(style_str ~= "", "style string should not be empty string ''")

			local lua_table_string_form = style_parser_fn(style_str)
			-- print(lua_table_string_form)

			local key_val_list = parse_lua_table_string_form(lua_table_string_form)

			
			t = to_ordered_table(key_val_list)
		else
			-- get style from style instance
			local style_instance = element_or_compartment:find("/elemStyle,/compartStyle,/elemType/elemStyle,/compartType/compartStyle")
			-- element_or_compartment:log("/compartType@id", "isGroup")
			assert(style_instance:is_not_empty(), "there must be a style instance if style attribute is empty")

			for key, val in style_instance:get(1):property_key_val_pairs() do
				t[key] = val
			end
		end
		-- print(dumptable(t))
		return t
	else
		error("objects of class " .. class_name .. " have no parser")
	end
end

-- returns an ordered table
-- from node or edge location attribute
-- the order of keys is important because needed for reverse encoding
-- you should call save on diagram before this
-- to get the latest location in thi location attribute
function get_location_table(node_or_edge)
	assert(node_or_edge:size() == 1, "location parser works on exactly one instance")

	local parser_by_type = {
		Node = lua_graphDiagram.GetNodeLocation,
		Edge = lua_graphDiagram.GetEdgeLocation,
	}

	local class_name = utilities.get_class_name(node_or_edge)

	local parser_fn = parser_by_type[class_name]

	if type(parser_fn) == "function" then
		local location_str = node_or_edge:attr("location")

		local t = ordered_table.new()

		if location_str ~= "" then
			assert(type(location_str) == "string", "location string must be string")
			

			local lua_table_string_form = parser_fn(location_str)
			print(lua_table_string_form)

			local key_val_list = parse_lua_table_string_form(lua_table_string_form)

			
			t = to_ordered_table(key_val_list)
		else
			error("location string should not be empty string ''")
		end
		-- print(dumptable(t))
		return t
	else
		error("objects of class " .. class_name .. " have no parser")
	end
end

-- serialize table to string form
-- that is understood by graph diagram engine
-- the table is order_table
-- because the order of keys is importand for graph diagram engine
local function table_to_string(t)
	local components = {}

	for key, val in t:opairs() do
		if type(val) ~= "table" then
			table.insert(components, string.format("%s='%s'", key, val))
		else
			table.insert(components, string.format("%s='%s'", key, table_to_string(val)))
		end
	end

	return string.format("{%s,}", table.concat(components, ","))
end


-- updates element or compartment style attribute string with the supplied delta
-- the diagram is not refresh
-- to refresh use lua_graphDiagram.RefreshEditor(diagram_id)
-- also before you should call save diagram to get the newest style in style attribute
function update_style_without_diagram_refresh(element_or_compartment, style_delta)
	assert(element_or_compartment:size() == 1, "style parser works on exactly one instance")

	local style_parser_by_type = {
		Node = lua_graphDiagram.GetNodeStyleGE,
		Edge = lua_graphDiagram.GetEdgeStyleGE,
		Port = lua_graphDiagram.GetPortStyleGE,
		Compartment = lua_graphDiagram.GetCompartmentStyleGE,
	}

	local class_name = utilities.get_class_name(element_or_compartment)

	local style_parser_fn = style_parser_by_type[class_name]

	if type(style_parser_fn) == "function" then
		local current_style = get_style_table(element_or_compartment)

		assert(type(current_style) == "table", "style table must be tabl; got" .. type(current_style))

		local new_style = current_style
		for key, val in pairs(style_delta) do
		  new_style[key] = val
		end

		local table_string_form = table_to_string(new_style)
		-- print(table_string_form)

		local graph_diagram_style_string = style_parser_fn(table_string_form)
		-- print(graph_diagram_style_string)

		element_or_compartment:attr("style", graph_diagram_style_string)
	else
		error("objects of class " .. class_name .. " have no parser")
	end
end


-- save diagram element and compartment styles
-- into the coressponding style attributes
function save_diagram_element_and_compartment_styles(diagram)
	utilities.save_dgr_cmd(diagram)
end


-- redraw the diagram using styles
-- from element and compartment style attributes
function refresh_diagram(diagram)
	lua_graphDiagram.RefreshEditor(diagram:id())
end

--sets style for element collection
function symbol_style_for_collection()
  local element = utilities.active_elements():find(":first()")
  local diagram = element:find("/graphDiagram:first()")
  save_diagram_element_and_compartment_styles(diagram)
  utilities.add_command(element, diagram, "StyleDialogCmd", {info = ";lua_engine#lua.utilities.ok_style_dialog_for_collection;lua_engine#lua.utilities.cancel_style_dialog_for_collection"})
end

function ok_style_dialog_for_collection(base_elem, elems)
  if elems == nil then
  	elems = utilities.active_elements()
  end
  if base_elem == nil then
  	base_elem = elems:filter(":first()")
  end
  local diagram = base_elem:find("/graphDiagram")
  save_diagram_element_and_compartment_styles(diagram)
  local elem_style_table = get_style_table(base_elem)
  local compart_styles_list = {}
  get_compart_styles(base_elem, compart_styles_list, "/compartment")
  elems:each(function(elem)
    if utilities.get_class_name(elem) == utilities.get_class_name(base_elem) then
      update_style_without_diagram_refresh(elem, elem_style_table)
      change_compart_styles(elem, compart_styles_list)
    end
  end)
  refresh_diagram(diagram)
end

function get_compart_styles(base_elem, list, path)
  if utilities.get_class_name(base_elem) == "Compartment" then  
    path = path .. "/subCompartment"
  end
  base_elem:find(path):each(function(compart)
    local id = compart:find("/compartType"):attr("id")
    local new_path = string.format("%s:has(/compartType[id = %s])", path, id)
    if compart:find("/compartType"):attr("isGroup") ~= "true" then
      table.insert(list, {style = get_style_table(compart), path = new_path})
    else
      get_compart_styles(compart, list, new_path) 
    end
  end)
end

function change_compart_styles(elem, compart_styles_list)
  for _, item in ipairs(compart_styles_list) do
    update_style_without_diagram_refresh(elem:find(item["path"]), item["style"])
  end
end


return {
	save_diagram_element_and_compartment_styles = save_diagram_element_and_compartment_styles,

	get_style_table = get_style_table,
	
	update_style_without_diagram_refresh = update_style_without_diagram_refresh,


	get_location_table = get_location_table,

	refresh_diagram = refresh_diagram,

	symbol_style_for_collection = symbol_style_for_collection,

	ok_style_dialog_for_collection = ok_style_dialog_for_collection,
}