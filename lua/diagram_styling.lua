module(..., package.seeall)

require("graph_diagram_style_utils")

require("chroma")

function get_outline_color(base_color)
  -- outline diff from google search button
  local sample_base = chroma.Color(76,142,251, 'rgb')
  local sample_outline = chroma.Color(48,121,237, 'rgb')
  
  local diff = sample_base:get_color_diff(sample_outline)
  -- return base_color:subtract_diff(diff)
  return base_color:subtract_diff(diff)
end

function get_text_color(base_color)
   -- text color diff by lelde zaļais
  -- local sample_base = chroma.Color(130,197,113, 'rgb')
  -- local sample_text = chroma.Color(0,89,53, 'rgb')
  -- text color diff by lelde lillā
  local sample_base = chroma.Color(175,180,243, 'rgb')
  local sample_text = chroma.Color(69,60,147, 'rgb')
  
  local diff = sample_base:get_color_diff(sample_text)
  -- return base_color:add_diff(diff)--:add_diff(diff)--:add_diff(diff)
  return base_color:subtract_diff(diff)--:add_diff(diff)--:add_diff(diff)
  -- return chroma.Color(250,250,250, 'rgb')
  -- return chroma.Color(24,24,24, 'rgb')
end



function set_element_color(element, base_color)
  local class_name = utilities.get_class_name(element)
  if class_name == "Edge" then
    graph_diagram_style_utils.update_style_without_diagram_refresh(element, {
      lineColor = base_color:tda(),
      endLineColor = base_color:tda(),
      startLineColor = base_color:tda(),
    })
  else
    graph_diagram_style_utils.update_style_without_diagram_refresh(element, {
      bkgColor = base_color:tda(),
      lineColor = get_outline_color(base_color):tda(),
    })
  end
end


function get_element_base_color(element)
  assert(element:size() == 1)
  local class_name = utilities.get_class_name(element)

  if class_name == "Edge" then
    return chroma.tda(graph_diagram_style_utils.get_style_table(element).lineColor)
  else
    return chroma.tda(graph_diagram_style_utils.get_style_table(element).bkgColor)
  end
end

function set_element_compartment_color(element, element_base_color)
  element:find("/compartment[isGroup!=true], /compartment[isGroup=true]/subCompartment"):each(function(c)
    local random_text_color = get_text_color(element_base_color)

    graph_diagram_style_utils.update_style_without_diagram_refresh(c, {
      fontColor = random_text_color:tda()
    })
  end)
end


function apply_random_colors(dgr, get_element_base_color)
  print("-- apply generated colors --")


  -- save current element and compartment styles
  -- to corresponding style attributes
  -- because user may have set some custom style
  graph_diagram_style_utils.save_diagram_element_and_compartment_styles(dgr)


  -- set all diagram element colors to random
  dgr:find("/element"):each(function(el)
    local random_el_color = get_element_base_color(el)

    set_element_color(el, random_el_color)

    -- set all diagram element compartment colors to random
    set_element_compartment_color(el, random_el_color)
  end)


  -- redraw diagram with the new styles
  graph_diagram_style_utils.refresh_diagram(dgr)
end


function unique(t)
  local results = {}

  local tmp = {}

  for _, v in ipairs(t) do
    if not(tmp[v]) then
      tmp[v] = true
      table.insert(results, v)
    end
  end

  return results
end


function get_element_base_color_fn(dgr, color_constraint_fn, element_color_key_fn)
  require("palette_generator")


  local elements = dgr:find("/element")

  

  local color_keys = unique(elements:map(element_color_key_fn))

  local palette_size = #color_keys
  print("palette_size", palette_size)

  local palette = palette_generator.generate(palette_size, color_constraint_fn)
  palette = chroma.palette_generator.diffSort(palette)

  local type_colors = {}
  for i, key in ipairs(color_keys) do
    type_colors[key] = palette[i]
  end

  function get_element_base_color(element)
    return type_colors[element_color_key_fn(element)] -- palette[math.random(palette_size)]
  end

  return get_element_base_color
end


function get_color_key(element)
  -- return element:attr("/elemType@id")
  if utilities.get_class_name(element) == "Edge" then
    return graph_diagram_style_utils.get_style_table(element).lineColor
  else
    return graph_diagram_style_utils.get_style_table(element).bkgColor
  end
end

function checkColor(color)
  local hcl = color:hcl()

  return (hcl[1]>=0   and hcl[1]<=280 or hcl[1]>=320 and hcl[1]<=360 ) -- izgriežam ārā violetos
      and hcl[2]>=1   and hcl[2]<=1.1
      and hcl[3]>=1.0 and hcl[3]<=1.1
end

function dump_active_element_colors()
  e = utilities.active_elements()
  print("fil", dumptable(chroma.tda(graph_diagram_style_utils.get_style_table(e).bkgColor)))
  print("stroke", dumptable(chroma.tda(graph_diagram_style_utils.get_style_table(e).lineColor)))
  print("font", dumptable(chroma.tda(graph_diagram_style_utils.get_style_table(e:find("/compartment:first")).fontColor)))
end



function apply_random_color_palete_to_active_diagram()
  -- get current diagram
  dgr = utilities.current_diagram()

  local randmo_color_generator = get_element_base_color_fn(dgr, checkColor, get_color_key)
  apply_random_colors(dgr, randmo_color_generator)
end


function apply_base_color_to_active_elements(base_color)
  local dgr = utilities.current_diagram()
  graph_diagram_style_utils.save_diagram_element_and_compartment_styles(dgr)

  local elements = utilities.active_elements()
  for el in elements do
    -- local base_color = get_element_base_color(el)

    set_element_color(el, base_color)

    -- set all diagram element compartment colors to random
    set_element_compartment_color(el, base_color)
  end

  -- redraw diagram with the new styles
  graph_diagram_style_utils.refresh_diagram(dgr)
end


return {
  dump_active_element_colors = dump_active_element_colors,
  apply_random_color_palete_to_active_diagram = apply_random_color_palete_to_active_diagram,
  get_element_base_color = get_element_base_color,
  apply_base_color_to_active_elements = apply_base_color_to_active_elements,
}