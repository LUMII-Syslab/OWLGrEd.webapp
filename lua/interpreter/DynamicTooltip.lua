module(..., package.seeall)



-- compartment may be empty collection, means that only element tooltip enabled
-- must return a string
function get_tooltip_value(element, compartment)
	log("DynamicTooltip called")

	local color_int, tooltip_value_str

	if compartment:is_not_empty() then
		color_int, tooltip_value_str = utilities.call_compartment_proc_thru_type(compartment, "procDynamicTooltip", element)
		if not color_int then
			log("!!! compartment did not return valid tooltip - showing element tooltip")
			color_int, tooltip_value_str = utilities.call_element_proc_thru_type(element, "procDynamicTooltip", compartment)
		end
	elseif element:is_not_empty() then
		color_int, tooltip_value_str = utilities.call_element_proc_thru_type(element, "procDynamicTooltip", compartment)
	else
		log("!!! called tooltip with no element - should not happen")
	end

	if type(color_int) ~= "number" then
		log(string.format("!!! procDynamicTooltip should return int color value; got %s of type %s", tostring(color_int), type(color_int)))
		color_int = 0
	end
	if type(tooltip_value_str) ~= "string" then
		log(string.format("!!! procDynamicTooltip should return string toolpti text; got %s of type %s", tostring(tooltip_value_str), type(tooltip_value_str)))
		tooltip_value_str = ""
	end


	return color_int, tooltip_value_str
end

function add_dynamic_tooltip_to(eleme_type_id, tooltip_fn_name)
	tooltip_fn_name = tooltip_fn_name or 'interpreter.DynamicTooltip.dynamic_tooltip_test'

	local cu = require('configurator.const.const_utilities')

	local elem_types_to_change = lQuery("ElemType"):filter_attr_value_equals("id", eleme_type_id)

	-- add tooltip proc to each elem type
	for elem_type in elem_types_to_change do
		log('added dynamic dynamic tooltip to')
		elem_type:log('id')

		cu.add_translet_to_obj_type(elem_type, 'procDynamicTooltip', tooltip_fn_name)
	end

	-- set each elem style to show tooltip
	elem_types_to_change:find('/elemStyle'):attr("dynamicTooltip", 1)

	-- set all existing elements to show tooltip
	local gdsu = require('graph_diagram_style_utils')

	for diagram in elem_types_to_change:find('/graphDiagramType/graphDiagram') do
		gdsu.save_diagram_element_and_compartment_styles(diagram)

		for element in diagram:find('/element'):filter_has_links_to_some('elemType', elem_types_to_change) do
			local style_table = gdsu.get_style_table(element)
			style_table['dynamicTooltip'] = '1'
			gdsu.update_style_without_diagram_refresh(element, style_table)
		end

		gdsu.refresh_diagram(diagram)
	end
end


function dynamic_tooltip_test(element, compartment)
	require("color")

	local tooltip_value = "DynamicTooltip "
	
	local elem_type_caption = element:attr("/elemType@caption")

	if elem_type_caption then
		tooltip_value = tooltip_value .. "for element " ..
						elem_type_caption .. " " .. element:id() .. "\n  "
	end
	

	if compartment:is_not_empty() then
		local compart_type_caption = compartment:attr("/compartType@caption")
		tooltip_value = tooltip_value .. "and compartment " ..
						compart_type_caption .. " " .. compartment:id() ..
						"\n    with value '" .. (compartment:attr("value") or "nil") .. "'"
	else
		tooltip_value = tooltip_value .. "got no compartment"
	end
	
	local random_color = color.rgb_to_tda_int(color.random_hue_rgb(0.5, 0.95))

	return random_color, tooltip_value
end