module(..., package.seeall)

require("graph_diagram_style_utils")

require("chroma")


--[[
{
  id = 1,
  type = "graph_diagram_type_1",

  caption = "",

  background_color = "ffffff", --rgb hex

  nodes = {},
  edges = {},  
}
--]]
function get_diagram_in_table_form(diagram)
  graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)

  local diagram_type_id = diagram:attr("/graphDiagramType@id")

  local elements_with_types = diagram:find("/element:has(/elemType)")

  -- Extract diagram background color from "style" attribute.
  local bg_color
  local style = diagram:attr("style")
  if type(style) == "string" and #style > 0 then
    bg_color = chroma.tda(style:match("^%[(%d+);")):hex()
  end

  return {
    id = diagram:id(),
    caption = diagram:attr("caption"),
    background_color = bg_color or "#f0f8ff",
    type = diagram_type_id,

    nodes = elements_with_types:find(".Node"):map(get_node_in_table_form, diagram_type_id),
    edges = elements_with_types:find(".Edge"):map(get_edge_in_table_form, diagram_type_id),
  }
end



--[[
{
  id = 12,
  type = "node_type_1",

  location = "???",
  style = {"???"},

  compartments = {},
}
--]]
function get_node_in_table_form(node, diagram_type_id)
  local node_table_form = get_element_in_table_form(node, diagram_type_id)

  if node:find("/container"):is_not_empty() then
    node_table_form["container_node_id"] = node:find("/container"):id()
  end

  return node_table_form
end



--[[
{
  id = 123,
  type = "edge_type_1",

  start_elem_id = 12,
  end_elem_id = 34,

  location = "???",
  style = {"???"},
  
  compartments = {},
}
--]]
function get_edge_in_table_form(edge, diagram_type_id)
  local edge_table_form = get_element_in_table_form(edge, diagram_type_id)

  edge_table_form["start_elem_id"] = edge:find("/start"):id()
  edge_table_form["end_elem_id"] = edge:find("/end"):id()

  return edge_table_form
end

-- from src/doc/ge_style4.doc
function replace_codes_with_readable_form(style_table)
  local keys_with_color_value = {
    'bkgColor',
    'lineColor',
    'fontColor',
    'startBkgColor',
    'startLineColor',
    'middleBkgColor',
    'middleLineColor',
    'endBkgColor',
    'endLineColor'
  }

  for _, color_key in ipairs(keys_with_color_value) do
    if style_table[color_key] then
      style_table[color_key] = chroma.tda(style_table[color_key]):hex()
    end
  end

  local shape_codes = {
     ['1'] = 'box_Rectangle',
     ['2'] = 'box_RoundRectangle',
     ['3'] = 'box_Parallelogram',
     ['4'] = 'box_Arrow',
     ['5'] = 'box_Ellipse',
     ['6'] = 'box_Hexagon',
     ['7'] = 'box_Trapeze',
     ['8'] = 'box_DownwardTrapeze',
     ['9'] = 'box_Diamond',
    ['10'] = 'box_Triangle',
    ['11'] = 'box_Note',
    ['12'] = 'box_InArrow',
    ['13'] = 'box_OutArrow',
    ['14'] = 'box_Octagon',
    ['15'] = 'box_LittleMan',
    ['18'] = 'box_BigArrow',
    ['17'] = 'box_Activity_State',
    ['16'] = 'box_Package',
    ['19'] = 'box_BlackLine',
    ['20'] = 'box_Component',
    ['21'] = 'box_VertCylinder',
    ['22'] = 'box_HorzCylinder',
    ['23'] = 'box_VertBlackLine',
    ['24'] = 'box_SandGlass',
  }
  local le_codes = {    -- Line endpoint shape codes.
     ['1'] = 'le_None',
     ['2'] = 'le_Arrow',
     ['3'] = 'le_PureArrow',
     ['4'] = 'le_Circle',
    ['10'] = 'le_Diamond',
    ['11'] = 'le_Triangle',
    ['15'] = 'le_Square',
    ['16'] = 'le_Card_0toN',
    ['17'] = 'le_Card_1toN',
    ['18'] = 'le_Card_1to1',
    ['19'] = 'le_Card_0to1',
     ['5'] = 'le_BigCircle',
     ['6'] = 'le_HalfArrow',
    ['21'] = 'le_DiamondOblique',
    ['20'] = 'le_Oblique',
    ['14'] = 'le_ArrowSquare',
    ['13'] = 'le_DoableSquare',
    ['12'] = 'le_ArrowDoableSquare'
  }

  if style_table['shapeCode'] then
      style_table['shapeCode'] = shape_codes[style_table['shapeCode']]
  end
  if style_table['startShapeCode'] then
      style_table['startShapeCode'] = le_codes[style_table['startShapeCode']]
  end
  if style_table['endShapeCode'] then
      style_table['endShapeCode'] = le_codes[style_table['endShapeCode']]
  end

  return style_table
end


--[[
{
  id = 1234,
  type = "element_type_1",

  location = "???",
  style = {"???"},

  compartments = {},
  sub_diagram_id = diagram_id or nil, -- diagram that should be below this element in tree view
  referencing_diagram_id = diagram_id or nil, -- diagram to which navigate (most of the time the same as sub_diagram, but there are situations when there is no subdiagram but we want to navigate to some diagram)
}
--]]
function get_element_in_table_form(element, diagram_type_id)
  local element_type_id = string.format("%s.%s", diagram_type_id, element:attr("/elemType@id"))

  compartments = {}
  element:find("/compartment:has(/compartType)"):each(function(compartment)
    if compartment:attr("isGroup") ~= "true" then
      local compartment_table_form = get_compartment_in_table_form(compartment, element_type_id)
      table.insert(compartments, compartment_table_form)
    else
      compartment:find("/subCompartment:has(/compartType)"):each(function(sub_compartment)
        local compartment_table_form = get_compartment_in_table_form(sub_compartment, element_type_id)
        table.insert(compartments, compartment_table_form)
      end)
    end
  end)

  return {
    id = element:id(),
    type = element_type_id,

    location = element:attr("location") ~= "" and graph_diagram_style_utils.get_location_table(element) or {},
    style = element:attr("style") ~= "" and replace_codes_with_readable_form(graph_diagram_style_utils.get_style_table(element)) or {},

    compartments = compartments,

    sub_diagram_id = element:find("/child"):id(),
    referencing_diagram_id = element:find("/target"):id(),
  }
end



--[[
{
  id = 1234,
  type = "compartment_type_1",

  value = "abc",

  style = {"???"},
}
--]]
function get_compartment_in_table_form(compartment, element_type_id)
  local compartment_type_id = string.format("%s.%s", element_type_id, compartment:attr("/compartType@id"))

  return {
    id = compartment:id(),
    type = compartment_type_id,
    value = compartment:attr("input"),
    style = compartment:attr("style")  ~= "" and replace_codes_with_readable_form(graph_diagram_style_utils.get_style_table(compartment)) or {},
  }
end



--[[
{
  diagrams = {
    {
      id = 1,
      type = "graph_diagram_type_1",

      caption = "",
      background_color = "ffffff", --rgb hex

      nodes = {
        {
          id = 12,
          type = "node_type_1",

          location = "???",
          style = {"???"},

          compartments = {
            {
              id = 1234,
              type = "compartment_type_1",

              value = "abc",

              style = {"???"},
            },
            -- ...
          },
          -- ...
        }, 
      },

      edges = {
        {
          id = 123,
          type = "edge_type_1",

          start_elem_id = 12,
          end_elem_id = 34,

          location = "???",
          style = {"???"},

          compartments = {
            {
              id = 12345,
              type = "compartment_type_2",

              value = "bcd",

              style = {"???"},
            },
            -- ...
          },
        },
        -- ...
      },  
    },
    -- ...
  }
}
--]]
function all_diagrams_in_table_form()
  local results = {
    diagrams = {},
    root_diagram_id = id, -- the id of the root diagram
  }

  results.diagrams = lQuery("GraphDiagram"):map(get_diagram_in_table_form)
  
  results.root_diagram_id = lQuery("Project/graphDiagram"):id()

  print(dumptable(results))
  return results
end
