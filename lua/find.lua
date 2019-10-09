module(..., package.seeall)

require "scoreForAbbreviation"
d = require("dialog_utilities")

function show_window()
  local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.find.close()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "find"
    ,caption = "Find"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.find.close()")
    ,component = {
      lQuery.create("D#HorizontalBox", {
        component = {
          filter("Element:", "ElemType", "lua.find.items_for_elem_type_list()", "lua.find.items_for_compart_type_list()",  utilities.current_diagram():find("/graphDiagramType/elemType"))
          ,filter("Compartment:", "CompartType", "lua.find.items_for_compart_type_list()", "lua.find.items_for_value_list()")
          ,filter("Value:", "Compartment", "lua.find.items_for_value_list()", "lua.find.activate_element()")
        }
      })
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
        ,component = close_button
      })
    }
  })
  d.show_form(form)
end

function close()
	d.close_form("find")
end

function filter(caption, type_name, change_function, list_change_function, source)
  return lQuery.create("D#VerticalBox", {
    horizontalAlignment = -1
    ,component = {
      lQuery.create("D#Label", {caption = caption})
      ,lQuery.create("D#InputField", {
        id = type_name .. "FilterForFind"
        ,text = ""
        ,eventHandler = {
          utilities.d_handler("Change", "lua_engine", change_function)
        }
      })
      ,lQuery.create("D#ListBox", {
        id = type_name .. "ListForFind"
        ,minimumHeight = 145
        ,multiSelect = false
        ,item = items_for_abbreviation("", source, "caption")
        ,eventHandler = {
          utilities.d_handler("Change", "lua_engine", list_change_function)
        }
      })
    }
  })
end

function items_for_elem_type_list()
  items("ElemType", utilities.current_diagram():find("/graphDiagramType/elemType"), "caption", true)
  items_for_compart_type_list()
end

function items(type_name, source, attr_name, select_first)
  local abbrev = lQuery("D#InputField[id=" .. type_name .. "FilterForFind]"):attr("text")
  local type_list_box = lQuery("D#ListBox[id=" .. type_name .. "ListForFind]")
  
  type_list_box:find("/item"):delete()
  
  local items = items_for_abbreviation(abbrev, source, attr_name)
  
  type_list_box:link("item", items)
  if select_first then type_list_box:link("selected", items[1]) end
  d.execute_d_command(type_list_box, "Refresh")
end

function items_for_abbreviation(abbrev, source, attr_name)
  source = source or lQuery({})
  local elem_type_names = source:map(function(el) 
                                       el = lQuery(el)
                                       return {el:attr(attr_name), el:id()}
                                     end)
  if abbrev ~= "" then
    elem_type_names = lQuery.grep(elem_type_names, function(t) return t[1]:scoreForAbbreviation(abbrev) > 0 end)
    table.sort(elem_type_names, function(t1, t2) return t1[1]:scoreForAbbreviation(abbrev) > t2[1]:scoreForAbbreviation(abbrev) end)
  end
  
  return lQuery.map(elem_type_names, function(item_value) return lQuery.create("D#Item", {value = item_value[1], id = item_value[2]}) end)
end

function items_for_compart_type_list()
  local elem_type_name = lQuery("D#ListBox[id=ElemTypeListForFind]/selected"):attr("value")
  local source = lQuery({})
  if elem_type_name then
    source = lQuery("ElemType[caption='" .. elem_type_name .. "']/compartType")
  end
  items("CompartType", source, "caption", true)
  items_for_value_list()
end

function items_for_value_list()
  local elem_type_name = lQuery("D#ListBox[id=ElemTypeListForFind]/selected"):attr("value")
  local source = lQuery({})
  if elem_type_name then
    local compart_type_name = lQuery("D#ListBox[id=CompartTypeListForFind]/selected"):attr("value")
    if compart_type_name then
      local current_diagram_id = utilities.current_diagram():id()
      source = lQuery("ElemType[caption='" .. elem_type_name .. "']/compartType[caption='" .. compart_type_name .. "']/compartment")
      source = source:filter(function(compartment)
                                return compartment:find("/element/graphDiagram"):id() == current_diagram_id
                              end)
    end
  end
  items("Compartment", source, "value", false)
  -- activate_element()
end

function activate_element()
  local compartment_repo_id = lQuery("D#ListBox[id=CompartmentListForFind]/selected"):attr("id")
  if compartment_repo_id then
    local compartment_repo_id = tonumber(compartment_repo_id)
    local element = lQuery(compartment_repo_id):find("/element")
    utilities.activate_element(element)
  end
end
