module(..., package.seeall)
require("utilities")
require("lpeg")
require("re")
Delete = require("interpreter.Delete")

function make_pattern(palette_element, diagram)
	local elem_type_list = {}
	elem_type_list["Node"] = {}
	elem_type_list["Edge"] = {}
	elem_type_list["Port"] = {}
	elem_type_list["FreeBox"] = {}
	elem_type_list["FreeLine"] = {}
	palette_element:find("/type/elemType"):each(function(elem_type)
		table.insert(elem_type_list[utilities.get_class_name(elem_type:find("/presentation"))], elem_type)
	end)
	make_pattern_from_elem_type_list(elem_type_list, diagram)
end

function make_pattern_from_elem_type_list(elem_type_list, diagram)
	local elem_list = {}
	create_pattern_nodes(elem_type_list["Node"], diagram, elem_list)
	create_pattern_ports(elem_type_list["Port"], diagram, elem_list)
	create_pattern_edges(elem_type_list["Edge"], diagram, elem_list)
	create_pattern_free_boxes(elem_type_list["FreeBox"], diagram, elem_list)
	create_pattern_free_lines(elem_type_list["FreeLine"], diagram, elem_list)
	local cmd = lQuery.create("PasteCmd")
	local cmd2 = lQuery.create("ActiveElementCmd")
	for _, obj in pairs(elem_list) do
		cmd:link("element", obj)
			:link("graphDiagram", obj:find("/graphDiagram"))
		cmd2:link("element", obj)
			:link("graphDiagram", obj:find("/graphDiagram"))
	end
	utilities.execute_cmd_obj(cmd)
	utilities.execute_cmd_obj(cmd2)	
end

function create_pattern_free_boxes(free_box_type_list, diagram, elem_list)
	for _, free_box_type in pairs(free_box_type_list) do
		local free_node = add_free_node(free_box_type, diagram, {}, true)
		insert_elem_in_list(free_node, free_box_type, elem_list) 
	end
end

function create_pattern_free_lines(free_line_type_list, diagram, elem_list)
	for _, free_line_type in pairs(free_line_type_list) do
		local coordinate_table = {}
		local free_line = free_line_type:find("/presentation")
		coordinate_table["freeLine_x1"] = free_line:attr("freeLine_x1")
		coordinate_table["freeLine_y1"] = free_line:attr("freeLine_y1")
		coordinate_table["freeLine_xn"] = free_line:attr("freeLine_xn")
		coordinate_table["freeLine_yn"] = free_line:attr("freeLine_yn")
		local free_edge = add_free_edge(free_line_type, diagram, coordinate_table, true)
		insert_elem_in_list(free_edge, free_line_type, elem_list)
	end
end

function create_pattern_nodes(node_type_list, diagram, elem_list)
	for _, node_type in pairs(node_type_list) do
		create_pattern_node(node_type, nil, diagram, elem_list)
	end
end

function create_pattern_ports(port_type_list, diagram, elem_list)
	for _, port_type in pairs(port_type_list) do
		create_pattern_port(port_type, diagram, elem_list)
	end
end

function create_pattern_port(port_type, diagram, elem_list)
	local node_type = port_type:find("/nodeType")
	local port = add_port(port_type, elem_list[node_type:id()], diagram, true)
	insert_elem_in_list(port, port_type, elem_list)
end

function create_pattern_edges(edge_type_list, diagram, elem_list)
	for _, edge_type in pairs(edge_type_list) do
		create_pattern_edge(edge_type, diagram, elem_list)
	end
end

function create_pattern_node(elem_type, parent, diagram, elem_list)
	local node = add_node_with_restrictions(elem_type, nil, diagram, "true", true)
	utilities.copy_objects(node, elem_type:find("/presentation"))
	insert_elem_in_list(node, elem_type, elem_list)
end

function create_pattern_edge(elem_type, diagram, elem_list)
	local pair = elem_type:find("/pair:not([id = 'reverse'])")
	local start_type = pair:find("/start")
	local end_type = pair:find("/end")
	local start_element = elem_list[start_type:id()]
	local end_element = elem_list[end_type:id()]
	local edge = add_edge_with_end_elems(elem_type, start_element, end_element, diagram, true)
	utilities.copy_objects(edge, elem_type:find("/presentation"))
	insert_elem_in_list(edge, elem_type, elem_list)
end

function insert_elem_in_list(elem, elem_type, list)
	list[elem_type:id()] = elem
end

function add_node_with_restrictions(node_type, parent_node, graph_diagram, show_properties, is_parser_needed)
	local node = nil
	local pre_condition = check_pre_condition(node_type, parent_node)
	if pre_condition then
		local res, constraint, count = check_multiplicity_constraint(node_type, graph_diagram)
		if res == 1 and pre_condition then
			if parent_node == nil or parent_node:is_empty() then
				local container_mandatory = node_type:attr_e("isContainerMandatory")
				if container_mandatory ~= "true" then
					node = add_node(node_type, graph_diagram)
				else
					local error_msg = node_type:attr_e("caption") .. " requires container!"
					utilities.ShowInformationBarCommand(error_msg)
					return -1, error_msg
				end
			else
				local parent_type = is_element_container_constraint_satisfied(parent_node, node_type)
				if parent_type:is_not_empty() then
					node = add_node(node_type, graph_diagram):link("container", parent_node)
				else
					local error_msg = node_type:attr_e("caption") .. " cannot have container " .. parent_type:attr_e("caption") .. "!"
					utilities.ShowInformationBarCommand(error_msg)
					return -1, error_msg
				end
			end
			add_element_additions(node, node_type, show_properties, is_parser_needed)
			return node
		else
			local error_msg = "Violated multiplicty constraint! Constraint - " .. constraint .. ", Elements - " .. count
			utilities.ShowInformationBarCommand(error_msg)
			return -1, error_msg
		end
	else
		local error_msg = "Violated pre condition constraints!"
		utilities.ShowInformationBarCommand(error_msg)
		return -1, error_msg
	end
end

function is_element_container_constraint_satisfied(container, component_type)
	local container_type = utilities.get_elem_type(container)
	return container_type:filter_has_links_to_all("componentType", component_type)
end

function add_node(node_type, graph_diagram)
	return add_element("Node", node_type, graph_diagram)
end

function add_edge_with_end_elems(edge_type_set, start_element, end_element, graph_diagram, is_parser_needed)
	local error_msg = ""
	local edge_type, is_reverse = find_edge_type(edge_type_set, start_element, "/start", end_element, "/end")
	if edge_type ~= nil then
		local check_result, error_msg = check_pre_condition(edge_type, start_element, end_element)
		if check_result then	
			local res, constraint, count = check_multiplicity_constraint(edge_type, graph_diagram)
			if res == 1 then
				local start_end_constraints = check_start_end_constraints(edge_type, start_element, end_element) 				
				if start_end_constraints then
					if edge_type:is_not_empty() then
						local start_type = start_element:find("/elemType")
						local end_type = end_element:find("/elemType")
						local edge = nil
						if edge_type:attr("direction") == "ReverseBiDirectional" then
							if is_reverse then
								edge = add_edge(edge_type, start_element, end_element, graph_diagram)
							else
								edge = add_edge(edge_type, end_element, start_element, graph_diagram)
							end
						else
							edge = add_edge(edge_type, start_element, end_element, graph_diagram)
						end
						add_element_additions(edge, edge_type, nil, is_parser_needed)
						return edge
					end
					show_edge_error_msg(start_element:find("/elemType"):attr_e("caption"), end_element:find("/elemType"):attr_e("caption"))
				else
					error_msg = "Violated start or end multiplicity constraint!"
					utilities.ShowInformationBarCommand(error_msg)
					return -1, error_msg
				end
			else
				error_msg = "Violated multiplicty constraint! Constraint - " .. constraint .. ", Elements - " .. count
				utilities.ShowInformationBarCommand(error_msg)
				return -1, error_msg
			end
		else
			error_msg = "Violated pre condition constraints!"
			utilities.ShowInformationBarCommand(error_msg)
			return -1, error_msg
		end
	else
		return show_edge_error_msg(start_element:find("/elemType"):attr_e("caption"), end_element:find("/elemType"):attr_e("caption"))
	end
end

function show_edge_error_msg(start_type_name, end_type_name)
	local error_msg = start_type_name .. " and " .. end_type_name .. " cannot be connected!"
	utilities.ShowInformationBarCommand(error_msg)
	return -1, error_msg
end

function check_pre_condition(elem_type, ...)
	local proc_name = utilities.get_translet_by_name(elem_type, "procPreCondition")
	if proc_name ~= "" and proc_name ~= nil then
		return utilities.execute_translet(proc_name, elem_type, ...)
	else
		return true
	end
end

function check_start_end_constraints(edge_type, start_element, end_element)
	local edge_type_id = edge_type:attr("id")
	local start_constraint = tonumber(get_start_end_constraint(edge_type, "startMultiplicityConstraint")) or math.huge
	local end_constraint = tonumber(get_start_end_constraint(edge_type, "endMultiplicityConstraint")) or math.huge
	local direction = edge_type:attr("direction")
	local start_count = get_start_end_count_uni_directional(edge_type_id, start_element, "eStart")
	local end_count = get_start_end_count_uni_directional(edge_type_id, end_element, "eEnd")
	if start_count >= start_constraint or end_count >= end_constraint then
		return false
	end
	return true
end

function get_start_end_constraint(edge_type, id)
	local constraint = edge_type:attr(id)
	if constraint == nil then
		local super_type = edge_type:find("/supertType")
		if super_type:is_not_empty() then
			return get_start_end_constraint(super_type, id)
		end
		return constraint
	else
		return constraint
	end
end

function get_start_end_count_uni_directional(edge_type_id, start_elem, start_role)
	local edges = start_elem:find("/" .. start_role .. ":has(/elemType[id = " .. edge_type_id .. "])")
	return edges:size()
end

function check_multiplicity_constraint(elem_type, diagram)
	local elem_count = get_elem_type_count(elem_type, diagram, 0, {})
	local multiplicity = get_multiplicity(elem_type)
	if multiplicity == "*" or tonumber(multiplicity) > elem_count then
		return 1, multiplicity, elem_count
	else
		return 0, multiplicity, elem_count
	end
end

function get_elem_type_count(elem_type, diagram, count, list)
	if elem_type:is_empty() then
		return count
	end
	elem_type:each(function(tmp_type)
		local id = tmp_type:id()
		if list[id] == nil then
			list[id] = tmp_type
			count = count + diagram:find("/element:has(/elemType[id = " .. tmp_type:attr_e("id") .. "])"):size()
		end
	end)
	return get_elem_type_count(elem_type:find("/supertype"), diagram, count, list)
end

function get_multiplicity(elem_type)
	local multiplicity = elem_type:attr_e("multiplicityConstraint")
	if multiplicity == "" then
		local super_type = elem_type:find("/supertype")
		if super_type:is_not_empty() then
			return get_multiplicity(super_type)
		else
			return "*"
		end
	else
		return multiplicity
	end
end

function find_edge_type(edge_type_set, start_element, start_role, end_element, end_role)
	local start_type = start_element:find("/elemType")
	local end_type = end_element:find("/elemType")
return get_edge_type(edge_type_set, start_type, end_type, start_role, end_role)
end

function get_edge_type(edge_type_set, start_type_set, end_type_set, start_role, end_role)
	local res_type, is_reverse = nil
	local buls = false
	edge_type_set:each(function(edge_type)
		if buls == false and start_type_set:is_not_empty() and end_type_set:is_not_empty() then
			res_type, is_reverse = check_pair(edge_type, start_type_set, end_type_set, start_role, end_role)
			if res_type ~= nil and buls == false then
				buls = true
			end
			if buls == false then
				res_type, is_reverse = get_edge_type(edge_type, start_type_set:find("/supertype"), end_type_set, start_role, end_role)
				if res_type ~= nil then
					buls = true
				end
				if buls == false then
					res_type, is_reverse = get_edge_type(edge_type, start_type_set, end_type_set:find("/supertype"), start_role, end_role)
					if res_type ~= nil then
						buls = true
					end
				end
			end
		end
	end)
	return res_type, is_reverse
end

function check_pair(edge_type, start_type_set, end_type_set, start_role, end_role)
	local res_type = nil
	local is_reverse = false
	local direction = edge_type:attr("direction")
	start_type_set:each(function(start_type)
		local start_type_id = start_type:id()
		end_type_set:each(function(end_type)
			local end_type_id = end_type:id()
			--edge_type:find("/pair"):each(function(pair)
				
				local start_id = edge_type:find(start_role):id()
				local end_id = edge_type:find(end_role):id()
				if start_id == start_type_id and end_id == end_type_id then
					res_type = edge_type
					is_reverse = false
				elseif (direction == "BiDirectional" or direction == "ReverseBiDirectional") and start_id == end_type_id and end_id == start_type_id then
					res_type = edge_type
					is_reverse = true
				end
			--end)	
		end)
	end)
	return res_type, is_reverse
end

function add_edge(edge_type, start_element, end_element, graph_diagram)
	return add_edge_by_roles(edge_type, start_element, "start", end_element, "end", graph_diagram)
end

function add_edge_by_roles(edge_type, elem1, role1, elem2, role2, graph_diagram)
	return add_element("Edge", edge_type, graph_diagram):link(role1, elem1)
							:link(role2, elem2)
end

function add_element_additions(elem, elem_type, show_properties, is_parser_needed)
	create_compartment_tree(elem, is_parser_needed)
	create_elem_domain(elem, elem_type)
	utilities.refresh_only_diagram(elem:find("/graphDiagram"))
	utilities.activate_element(elem)
	if show_properties == nil or show_properties then
		if elem_type:attr_e("openPropertiesOnElementCreate") == "true" then
			utilities.call_element_proc_thru_type(elem, "procProperties")
		end
	end
return elem
end

function add_free_node(free_node_type, graph_diagram, coordinate_table, is_parser_needed)
	if check_pre_condition(free_node_type) then
		local res, constraint, count = check_multiplicity_constraint(free_node_type, graph_diagram)
		if res == 1 then
			local free_node = add_element("FreeBox", free_node_type, graph_diagram)
			set_free_box_coordinates(free_node, coordinate_table)
			add_element_additions(free_node, free_node_type, nil, is_parser_needed)
			return free_node
		else
			utilities.ShowInformationBarCommand("Violated multiplicty constraint! Constraint - " .. constraint .. ", Elements - " .. count)
			return -1
		end
	else
		utilities.ShowInformationBarCommand("Violated pre condition constraints!")
		return -1
	end
end

function set_free_box_coordinates(free_box, coordinate_table)
	free_box:attr({freeBox_w = coordinate_table[1], 
			freeBox_h = coordinate_table[2],
			freeBox_x = coordinate_table[3],
			freeBox_y = coordinate_table[4]})
end

function add_free_edge(free_edge_type, graph_diagram, coordinate_table, is_parser_needed)
	if check_pre_condition(free_edge_type) then
		local res, constraint, count = check_multiplicity_constraint(free_edge_type, graph_diagram)
		if res == 1 then
			local free_edge = add_element("FreeLine", free_edge_type, graph_diagram)
			set_free_line_coordinates(free_edge, coordinate_table)
			add_element_additions(free_edge, free_edge_type, nil, is_parser_needed)
			return free_edge
		else
			utilities.ShowInformationBarCommand("Violated multiplicty constraint! Constraint - " .. constraint .. ", Elements - " .. count)
			return -1
		end
	else
		utilities.ShowInformationBarCommand("Violated pre condition constraints!")
		return -1
	end
end

function set_free_line_coordinates(free_line, coordinate_table)
	free_line:attr({freeLine_x1 = coordinate_table[1],
		 freeLine_y1 = coordinate_table[2],
		 freeLine_xn = coordinate_table[3],
		 freeLine_yn = coordinate_table[4]})
end

function add_port(port_type, parent_node, diagram, is_parser_needed)
	local res, constraint, count = check_multiplicity_constraint(port_type, diagram)
	if res == 1 then
		local parent_type = parent_node:find("/elemType")
		if check_port_parent(port_type, parent_type) == 1 then
			local port = add_element("Port", port_type, diagram):link("node", parent_node)
			add_element_additions(port, port_type, nil, is_parser_needed)
		else
			if parent_type == nil then
				utilities.ShowInformationBarCommand(port_type:attr_e("caption") .. " must have a parent box!")
			else
				utilities.ShowInformationBarCommand(port_type:attr_e("caption") .. " cannot be attached to " .. parent_type:attr_e("caption") .. "!")
			end
		end
	else
		utilities.ShowInformationBarCommand("Violated multiplicty constraint! Constraint - " .. constraint .. ", Elements - " .. count)
		return -1
	end
end

function create_elem_domain(elem, elem_type)
	utilities.call_elemType_proc_with_supertypes(elem_type, "procCreateElementDomain", elem)
	utilities.call_elemType_proc_with_supertypes(elem_type, "procNewElement", elem)
end

function check_port_parent(port_type, parent_type)
	local buls = 0
	parent_type:find("/portType"):each(function(tmp_type)
		if tmp_type:id() == port_type:id() then
			buls = 1
		end
	end)
return buls
end

function add_element(class_name, element_type, graph_diagram)
	local element = add_element_without_style(class_name, element_type, graph_diagram)
	element:link("elemStyle", element_type:find("/elemStyle:first"))
	return element
end

function add_element_without_style(class_name, element_type, graph_diagram)
	local element = lQuery.create(class_name, {
					graphDiagram = graph_diagram,
					elemType = element_type})
	return element
end


function add_diagram(diagram_type, caption, seed)
	local diagram = utilities.add_graph_diagram_to_graph_diagram_type(caption, diagram_type)
	diagram:link("parent", seed)
  return diagram
end

function link_compartment_to_parent(compartment, parent)
  if not parent:filter(".Element"):is_empty() then
    compartment:link("element", parent)
  else -- assume compartment
    compartment:link("parentCompartment", parent)
  end
end

function update_compartment_input_from_value(compartment, compartType, is_parser_needed)
	compartType = compartType or compartment:find("/compartType")
	local value, input = set_compartment_input_value(compartment, compartType)
	local notation = compartType:find("/choiceItem"):filter_attr_value_equals("value", value):find("/notation")
	if notation:is_not_empty() then
		local val = notation:attr("value")
		input = build_input_from_value(val, compartType, compartment)
		compartment:attr("input", input)
	end
	split_compart_value(compartment, is_parser_needed)
	set_parent_value(compartment)
	return compartment, input
end

function set_compartment_input_value(compartment, compartType, value, input)
	local old_val = compartment:attr("value")
	local new_input = utilities.call_compartment_proc_thru_type(compartment, "procValueToInputBase", value)
	if new_input ~= nil then
		input = new_input
	else
		if input == nil or value == nil then
			if value == nil then
				value = compartment:attr("value")
			end
			input = build_compartment_input_from_value(value, compartType, compartment)
		end
	end
	compartment:attr({input = input, value = value})
	if old_val ~= value then
		utilities.call_compartment_proc_thru_type(compartment, "procUpdateCompartmentDomain", old_val)
	end
	return value, input
end

function build_compartment_input_from_value(value, compart_type, compartment)
	local value = get_choice_item_by_value(value, compart_type)
	return build_input_from_value(value, compart_type, compartment)
end

function build_input_from_value(value, compart_type, compartment)
	local prefix, suffix = get_prefix_suffix(compart_type, compartment)
	if value ~= "" and value ~= nil then
		return string.gsub(prefix .. value .. suffix, "\\n", "\n")
	else
		return ""
	end
end

function get_prefix_suffix(compart_type, compart, multi_compart)
	local prefix_proc = utilities.get_translets(compart_type, "procGetPrefix")
	local suffix_proc = utilities.get_translets(compart_type, "procGetSuffix")
	local prefix
	if #prefix_proc == 0 then
		prefix = compart_type:attr("adornmentPrefix") or ""
	else
		prefix = utilities.execute_translet(prefix_proc, compart_type, compart, multi_compart)
	end
	local suffix
	if #suffix_proc == 0 then
		suffix = compart_type:attr("adornmentSuffix") or ""
	else
		suffix = utilities.execute_translet(suffix_proc, compart_type, compart, multi_compart)
	end
	return prefix or "", suffix or ""
end

function get_pattern(compart_type, suffix)
	local pattern_proc = utilities.get_translets(compart_type, "procGetPattern")
	local pattern
	local pattern_clauses = ""
	if #pattern_proc == 0 then
		pattern = compart_type:attr("pattern") or ""
		if pattern ~= nil and pattern ~= "" then
			pattern = "[" .. pattern .. "]*"
		else
			if suffix ~= "" then
				pattern = '([^' .. suffix .. '])*'
			end
		end
	else
		pattern, pattern_clauses = utilities.execute_translet(pattern_proc, compart_type)
	end
	return pattern, pattern_clauses
end

function set_parent_value(compart, is_refresh_needed, list_of_components)
	if is_refresh_needed == nil then
		is_refresh_needed = true
	end
	if list_of_components == nil then
		list_of_components = {}
	end
	local compart_type = compart:find("/compartType")
	if compart:is_not_empty() then
		local super_compart = compart:find("/parentCompartment")
		if super_compart:is_not_empty() and super_compart:attr("isGroup") ~= "true" then
			local proc_set_value = compart_type:find("/parentCompartType/translet[extensionPoint = 'procCompose']"):attr("procedureName")
			if proc_set_value ~= "" and proc_set_value ~= nil then
				utilities.execute_translet(proc_set_value, super_compart)
			else
				make_compart_value_from_sub_comparts(super_compart)
			end
			set_component_value_from_compart(compart, compart:attr("value"), list_of_components)
			set_parent_value(super_compart, is_refresh_needed, list_of_components)
			
		else
			local component = compart:find("/component")
			if component:is_not_empty() then
				component:attr({text = compart:attr("value")})
				table.insert(list_of_components, component)
			end
			if is_refresh_needed then
				for _, component in pairs(list_of_components) do
					utilities.refresh_form_component(component)
				end
			end
		end
	end
end

function set_component_value_from_compart(compart, val, list_of_components)
	local component = compart:find("/component")
	if component:is_not_empty() then
		local text_val = component:attr("text")
		if val ~= text_val then
			component:attr({text = val})
			process_component_refresh(component, list_of_components)
		end
	else
		local text_line = compart:find("/textLine")
		if text_line:is_not_empty() then
			text_line:attr({text = val})
			component = text_line:find("/multiLineTextBox")
			process_component_refresh(component, list_of_components)
		end
	end
end

function process_component_refresh(component, list_of_components)
	if component:is_not_empty() then
		if list_of_components ~= nil then
			list_of_components[component:id()] = component
		else
			utilities.refresh_form_component(component)
		end
	end
end

function get_choice_item_by_value(val, compart_type)
	local choice_item = compart_type:find("/choiceItem"):filter_attr_value_equals("value", val)
	if choice_item:is_not_empty() then
		return choice_item:find("/notation"):attr_e("value")
	else
		return val, {}
	end
end

function make_compart_value_from_sub_comparts(super_compart)
	local sub_comparts = super_compart:find("/subCompartment")
	local super_compart_val = ""
	if sub_comparts:is_not_empty() then
		local res_table = {}
		local super_compart_type = super_compart:find("/compartType")
		local delimiter = super_compart_type:attr("concatStyle")
		sub_comparts:each(function(sub_compart)
			local sub_compart_type = sub_compart:find("/compartType")
			if not(utilities.call_compartment_proc_thru_type(sub_compart, "procIsHidden") or sub_compart:find("/compartType"):attr("isHidden") == "true") then
				local index = sub_compart_type:attr("id")
				--local prefix, suffix = get_prefix_suffix(sub_compart_type, sub_compart, nil)
				local val = sub_compart:attr("value")
				--local input, tmp_list = get_choice_item_by_value(val, sub_compart_type)
				--if tmp_list then
				local input = sub_compart:attr("input")
				--end
				if input ~= "" then
					local indexed_table = {}
					table.insert(indexed_table, input)
					if res_table[index] == nil then	
						res_table[index] = {}			
					end
					table.insert(res_table[index], indexed_table)
				end
			end
		end)
		local sub_compart_types = super_compart:find("/compartType/subCompartType")
		--hacks prieks tagotajam vertibam
		if sub_compart_types:is_empty() then
			sub_compart_types = super_compart:find("/subCompartment/compartType")
		end
		local item_value_table = {}

		sub_compart_types:each(function(sub_compart_type)
			local tmp_table = res_table[sub_compart_type:attr("id")]
			if tmp_table ~= nil then
				for _, item_table in pairs(tmp_table) do
					table.insert(item_value_table, table.concat(item_table))
				end
			end
		end)
		super_compart_val = table.concat(item_value_table, delimiter)
		set_compartment_input_value(super_compart, super_compart:find('/compartType'), super_compart_val)
		--super_compart:attr({value = super_compart_val})
	else
		super_compart_val = super_compart:attr("value")
		set_compartment_input_value(super_compart, super_compart:find('/compartType'), super_compart_val)
	end
	local input = build_input_from_value(super_compart_val, super_compart:find("/compartType"), super_compart)
	super_compart:attr({input = input})
	return input
end

function split_compart_value(compartment, is_parser_needed)
	local compart_type = compartment:find("/compartType")
	if compart_type:find("/subCompartType"):is_not_empty() then
		local grammer = ""
		local proc_decompose = utilities.get_translet_by_name(compart_type, "procDecompose")

		if proc_decompose ~= "" and proc_decompose ~= nil then
			grammer = utilities.execute_translet(proc_decompose, compartment)
		else
			local additional_clauses = {}
			local generated_grammer = make_compart_grammer(compart_type, compartment, "?", additional_clauses, true)
			grammer = string.format("%s%s", generated_grammer, table.concat(additional_clauses))
		end	
		if grammer ~= "" and grammer ~= nil then
			grammer = "grammer <- " .. grammer --.. "/ !."

			local val = compartment:attr("value")	
			if val ~= nil and val ~= "" then
				if is_parser_needed then
					--local path_to_file = tda.GetProjectPath() .. "\\" .. "grammer.lua"
					--local export_file = io.open(path_to_file, "w")
					--	export_file:write(grammer)
					--export_file:close()
					local c = re.compile(grammer)
					val = replace_new_lines(val)
					local res = lpeg.match(lpeg.Ct(c), val)
					--print("PARSER CALLED")
					-- print(dumptable(res))
					if type(res) == "table" then
						if check_parsed_table_consistency(res) ~= "false" then
							local rebuilt_val = rebuild_compart_value(compartment, res)
							if compartment:attr("input") == rebuilt_val then
								--merge_compartment_table_with_res(res, compartment)
								--print(dumptable(res))
								
								clear_sub_compart_values(compartment)
								remove_empty_values(res)
								set_sub_compart_values(compartment, res)
								--set_parent_value(compartment)
							else
								print("Rebuilt and parsed values do not match!")
								print("Keeping the re-built value (value updates in the editor ignored).")
								print("To make value changes, edit the text on the most detailed form level.")
								--print("Rebuilt and parsed values do not match!")
								print("Rebuilt value:")
								print(rebuilt_val)
								print("Parsed value:")
								print(compartment:attr("input"))
							end
						end
					end
				end
			else
				if val == nil then
					local res_table = {}
					create_compart_value_table(compartment:find("/compartType"), res_table, "/subCompartType", utilities.get_element_from_compartment(compartment))
					set_sub_compart_values(compartment, res_table)
					set_component_value_from_compart(compartment, compartment:attr("value"))
					set_parent_value(compartment)
				else
					set_sub_compart_values(compartment, {})
					set_component_value_from_compart(compartment, compartment:attr("value"))
					set_parent_value(compartment)
				end
			end
		end
	end
end

function remove_empty_values(res)
	for index, val in pairs(res) do
		if type(val) == "table" then
			remove_empty_values(val)
		else
			if val == "" then
				res[index] = nil
			end
		end
	end
end

function rebuild_compart_value(compartment, res_table)
	local list = {}
	local compart_type = compartment:find("/compartType")
	list = traverse(compartment, compart_type, res_table)
	local tableList = table.concat(list)
	tableList = tableList:match("^%s*(.-)%s*$") 
	return tableList
end

function traverse(compartment, compart_type, res_table)
	local list = {}
	--local compart_type = compartment:log("value"):find("/compartType"):log("id")
	if type(res_table) == "table" then
		local prefix, suffix = get_prefix_suffix(compart_type, compartment)
		local sub_list = {}
		local start, finish = string.find(compart_type:attr("id"), "ASFictitious")
		if start == 1 and finish == 12 then
			local delimiter = compart_type:attr("concatStyle")
			local compart_list = {}
			compartment:find("/subCompartment"):each(function(sub_compart)
				table.insert(compart_list, sub_compart)
			end)	
			for index, item in ipairs(res_table) do
				local sub_compart = compart_list[index]
				compart_type:find("/subCompartType"):each(function(sub_compart_type)
					local id = sub_compart_type:attr("id")
					local tmp_list = traverse(sub_compart, sub_compart_type, item[id])
					local tmp_list_value = table.concat(tmp_list)
					if index > 1 and tmp_list_value ~= "" then
						table.insert(sub_list, delimiter)
					end
					table.insert(sub_list, tmp_list_value)	
				end)
			end
			table.insert(list, prefix)
			for _, item in ipairs(sub_list) do
				table.insert(list, item)	
			end
			table.insert(list, suffix)
		else
			local delimiter = compart_type:attr("concatStyle")
			local index = 1
			compart_type:find("/subCompartType"):each(function(sub_compart_type)
				local id = sub_compart_type:attr("id")
				local sub_compart
				if compartment ~= nil then
					sub_compart = compartment:find("/subCompartment:has(/compartType[id = " .. id .. "])")
				end
				local tmp_list = traverse(sub_compart, sub_compart_type, res_table[id])
				local tmp_list_value = table.concat(tmp_list)
				if index > 1 and tmp_list_value ~= "" then
					table.insert(sub_list, delimiter)
				end
				table.insert(sub_list, tmp_list_value)	
				index = index + 1
			end)
			table.insert(list, prefix)
			for _, item in ipairs(sub_list) do
				table.insert(list, item)	
			end
			table.insert(list, suffix)
		end
	else
		local input = build_input_from_value(res_table, compart_type, compartment)
		table.insert(list, input)
	end
	return list
end



--	local compart_type = compart:find("/compartType")
--	if compart:is_not_empty() then
--		local super_compart = compart:find("/parentCompartment")
--		if super_compart:is_not_empty() and super_compart:attr("isGroup") ~= "true" then
--			local proc_set_value = compart_type:find("/translet[extensionPoint = 'procCompose']"):attr("procedureName")
--			local super_compart_val = ""
--			if proc_set_value ~= "" and proc_set_value ~= nil then
--				super_compart_val = utilities.execute_translet(proc_set_value, compart)
--			else
--				super_compart_val = make_compart_value_from_sub_comparts(super_compart)
--			end
--			set_component_value_from_compart(super_compart, super_compart:attr("value"), list_of_components)
--			set_parent_value(super_compart, is_refresh_needed, list_of_components)			
--		else
--			local compart_type = compart:find("/compartType")
--			local val, input = compart:attr("value")
--			if val ~= "" then
--				input = build_input_from_value(val, compart_type, compart)
--			end
--			compart:attr({value = val, input = input})
--			if is_refresh_needed then
--				for _, component in pairs(list_of_components) do
--					utilities.refresh_form_component(component)
--				end
--			end
--		end
--	end




function clear_sub_compart_values(compart)
	local is_cleaning_needed = true
	local is_hidden = check_if_compartment_is_hidden(compart)
	if is_hidden then
		is_cleaning_needed = false
	end
	if is_cleaning_needed then
		--compart:find("/compartType"):log("id")
		compart:find("/subCompartment"):each(function(sub_compart)
			clear_sub_compart_values(sub_compart)
			--sub_compart:attr({value = "", input = ""})
		end)
		compart:attr({value = "", input = ""})
	end
end

function check_if_compartment_is_hidden(compart)
	local is_hidden = false
	local compart_type = compart:find("/compartType")
	local translet = compart_type:find("/translet[extensionPoint = 'procIsHidden']")
	if translet:is_not_empty() then
		is_hidden = utilities.call_compartment_proc_thru_type(compart, "procIsHidden")
	end
	if compart_type:attr("isHidden") == "true" then
		is_hidden = true
	end
	return is_hidden
end

function check_parsed_table_consistency(res)
	local check = "true"
	local delimiter_count = #res
	local count = 0 
	for index, val in pairs(res) do 
		if type(val) == "table" then
			count = count + 1
			if check_parsed_table_consistency(val) == "false" then
				return "false"
			end
		elseif type(index) == "number" then
			res[index] = nil
		else
			if val ~= "" then
				count = count + 1
			end
		end
	end
	if not (count <= delimiter_count + 1) then
		check = "false"
	end
	return check
end

function merge_compartment_table_with_res(res, compartment)
	compartment:find("/subCompartment"):each(function(sub_compart)
		local sub_compart_type = sub_compart:find("/compartType")
		local sub_compart_type_id = sub_compart_type:attr("id")
		local start, finish = string.find(sub_compart_type_id, "ASFictitious")
		--if start == 1 and finish == 12 then
			if res[sub_compart_type_id] == nil then
				if sub_compart_type:find("/subCompartType"):is_not_empty() then
					res[sub_compart_type_id] = {}
				else
					res[sub_compart_type_id] = sub_compart_type:attr("startValue")
				end
			end
			merge_compartment_table_with_res(res[sub_compart_type_id], sub_compart)
		--end
	end)
end

function make_compart_grammer(compart_type, compart, is_optional, additional_clauses, root)
	--is_optional = ""

	local delimiter = compart_type:attr("concatStyle") or ""
	delimiter = string.format("{('%s')}?", delimiter)
	local sub_comparts = compart_type:find("/subCompartType")
	local size = sub_comparts:size()
	local i = 0
	local grammer = ""
	sub_comparts:each(function(sub_compart_type)
		--local proc_decompose = utilities.get_translet_by_name(sub_compart_type, "procDecompose")
		local new_grammer = ""
		--if proc_decompose == nil or proc_decompose == "" then
			local id = sub_compart_type:attr("id")
			i = i + 1
			local sub_sub_comparts = sub_compart_type:find("/subCompartType")
			local sub_compart_id = sub_compart_type:attr("id")
			local prefix, suffix = get_prefix_suffix(sub_compart_type, nil, compart)
			prefix = recalculate_pattern(prefix)
			suffix = recalculate_pattern(suffix)
			local pattern, pattern_clauses = get_pattern(sub_compart_type, suffix)
			if prefix ~= "" then
				prefix = "'" .. prefix .. "'"
			end
			if suffix ~= "" then
				suffix = "'" .. suffix .. "'"
			end
			if i > 1 and i <= size then
				local tmp_optional = is_optional
				if sub_sub_comparts:is_not_empty() then
					--print("1 " .. sub_compart_id)
					--local sub_compart_pattern = make_compart_grammer(sub_compart_type)
			
					local sub_compart_delimiter = sub_compart_type:attr("concatStyle")
					sub_compart_delimiter = recalculate_pattern(sub_compart_delimiter)
					if (sub_compart_delimiter ~= nil) and (sub_compart_delimiter ~= "") then -- by SK
						sub_compart_delimiter = "'" .. sub_compart_delimiter .. "'"
					end		
					--new_grammer = '{(\"' .. delimiter .. '\")}? (\"' .. prefix .. '\" {:' .. sub_compart_id .. ': (' .. make_compart_grammer(sub_compart_type) .. ') -> {} :} \"' .. suffix .. '\")? \n'
					local start, finish = string.find(sub_compart_id, "ASFictitious")
					if  start == 1 and finish == 12 then
						local sub_compart_pattern = make_compart_grammer(sub_compart_type, compart, "?", additional_clauses, true)
						new_grammer = delimiter .. " (" .. prefix .. " {:" .. sub_compart_id .. ": ("
											.. sub_compart_pattern .. " -> {} "
											.. "(" .. sub_compart_delimiter .. " " .. sub_compart_pattern .. " -> {})*  "
											--.. ") -> {} :} " .. suffix .. ")" .. "  \n"
											.. ") -> {} :} " .. suffix .. ")"  .. tmp_optional .. " \n"

											--.. delimiter .. sub_compart_pattern .. " -> {} :} " .. suffix .. ")? " .. "-> {} "
					else
						local sub_compart_pattern = make_compart_grammer(sub_compart_type, compart, is_optional, additional_clauses)
						new_grammer = delimiter .. " (" .. prefix .. " {:" .. sub_compart_id .. ": ("
											.. sub_compart_pattern .. ") "
											.. " -> {} :} " .. suffix .. ")" .. tmp_optional .. " \n"
					end
				else
					--print("2 " .. sub_compart_id)
					--new_grammer = '{(\"' .. delimiter .. '\")}? (\"' .. prefix .. '\" {:' .. sub_compart_id .. ': ' .. pattern .. ' :} \"' .. suffix .. '\")? \n'
					new_grammer = delimiter .. " (" .. prefix .. " {:" .. sub_compart_id .. ": " .. pattern .. " :} " .. suffix .. ")" .. tmp_optional .. " \n"		
					table.insert(additional_clauses, pattern_clauses)							

				end
			else
				local tmp_optional = is_optional
				if sub_sub_comparts:size() == 1 then
					tmp_optional = "?"
				else
					tmp_optional = ""

				end
				if sub_sub_comparts:is_not_empty() then
					--print("3 " .. sub_compart_id)
					--local sub_compart_pattern = make_compart_grammer(sub_compart_type)
					local sub_compart_delimiter = sub_compart_type:attr("concatStyle")
					if (sub_compart_delimiter ~= nil) and (sub_compart_delimiter ~= "") then -- by SK
						sub_compart_delimiter = "'" .. sub_compart_delimiter .. "'"
					end

					--print(sub_compart_pattern)
					local start, finish = string.find(sub_compart_id, "ASFictitious")
					if start == 1 and finish == 12 then
						local sub_compart_pattern = make_compart_grammer(sub_compart_type, compart, "?", additional_clauses, true)
						new_grammer = "(" .. prefix .. " {:" .. sub_compart_id ..  ": ("
										.. sub_compart_pattern .. " -> {} "
										.. "(" .. sub_compart_delimiter .. " " .. sub_compart_pattern .. " -> {})*  "
										.. ") -> {} :}" .. suffix .. ")" .. tmp_optional .. " \n"

					else
						local sub_compart_pattern = make_compart_grammer(sub_compart_type, compart, is_optional, additional_clauses)
						new_grammer = "(" .. prefix .. " {:" .. sub_compart_id ..  ": (" .. sub_compart_pattern .. ") -> {} :} " .. suffix .. ")" .. tmp_optional .. " \n"	
					end
				else
					--print("4 " .. sub_compart_id )
					--new_grammer = '(\"' .. prefix .. '\" {:' .. sub_compart_id ..  ': ' .. pattern .. ' :} \"' .. suffix .. '\")?  \n'
					new_grammer = "(" .. prefix .. " {:" .. sub_compart_id ..  ": " .. pattern .. " :} " .. suffix .. ")" .. tmp_optional .. " \n"
					table.insert(additional_clauses, pattern_clauses)									
				end
			end
		--else
		--	new_grammer = utilities.execute_translet(proc_decompose)
		--end
		grammer = grammer .. new_grammer	
	end)
	return grammer
end

function recalculate_pattern(val)
	local res = string.gsub(val, "\n", '\\n')
	return res
end

function set_sub_compart_values(compartment, res)
	if type(res) == "table" then
		for index, val in pairs(res) do
			local start, finish = string.find(index, "ASFictitious")
			if start == 1 and finish == 12 then
				local i = 1
				local fiction_compart = compartment:find("/subCompartment:has(/compartType[id = '" .. index .. "'])")
				if fiction_compart:is_empty() then
					local compart_type = compartment:find("/compartType")
					fiction_compart = create_missing_compartment(compartment, compart_type, compart_type:find("/subCompartType[id = '" .. index .. "']"))
				end
				fiction_compart:find("/subCompartment"):each(function(sub_compart)
					if res[index][i] ~= nil then
						for k, res_k in pairs(res[index][i]) do
							Delete.delete_compartment_tree_from_object(sub_compart, "/subCompartment")
							sub_compart:find("/subCompartment"):each(function(tmp_sub_compart)
								local compart_type = tmp_sub_compart:find("/compartType")
								if not(utilities.call_compartment_proc_thru_type(sub_compart, "procIsHidden") or sub_compart:find("/compartType"):attr("isHidden") == "true") then
									tmp_sub_compart:delete()
								end
							end)
							manage_compart_value(sub_compart, fiction_compart, res_k, k)
						end
					else
						sub_compart:delete()
					end
					i = i + 1
				end)
				while res[index][i] do
					for sub_compart_index, res_sub_compart in pairs(res[index][i]) do
						local sub_compart_type = fiction_compart:find("/compartType/subCompartType[id = '" .. sub_compart_index .. "']")
						sub_compart = add_compart(sub_compart_type, fiction_compart, "")
						manage_compart_value(sub_compart, fiction_compart, res_sub_compart, sub_compart_index)
					end
					i = i + 1
				end
				make_compart_value_from_sub_comparts(fiction_compart)
				set_parent_value(fiction_compart, false)
			else
				local sub_compart = compartment:find("/subCompartment:has(/compartType[id = '" .. index .. "'])")
				manage_compart_value(sub_compart, compartment, val, index)
				reconnect_compartment_to_parent(sub_compart)
				make_compart_value_from_sub_comparts(compartment)
				set_parent_value(sub_compart, false)
			end	
		end
	end
end

function manage_compart_value(sub_compart, compartment, val, index)
	local sub_compart_type = compartment:find("/compartType/subCompartType[id = '" .. index .. "']")
	if type(val) == "table" then
		if sub_compart:is_empty() then
			sub_compart = add_compart(sub_compart_type, compartment, "")
		end
		set_sub_compart_values(sub_compart, val)
	else
		if sub_compart:is_empty() then	
			sub_compart = create_missing_compartment(compartment, compartment:find("/compartType"), sub_compart_type)
		end
		local input = build_compartment_input_from_value(val, sub_compart_type, sub_compart)
		if input == " " then input = "" end
		sub_compart:attr({value = val, input = input})
	end
end

function create_missing_compartment(parent, parent_type, compart_type)
	if parent_type:is_empty() and compart_type:is_empty() then
		error("ERROR in create missing compartment")
	else	
		if parent_type:is_not_empty() and (compart_type:find("/parentCompartType"):id() == parent_type:id() or compart_type:find("/elemType"):id() == parent_type:id()) then
			local compart = get_compartment_by_type(parent, compart_type)
			if compart == nil then
				compart = core.add_compart(compart_type, parent, "")
				core.reorder_child_compartments_according_to_type_order(parent)
			end
			return compart
		else
			--local compart = get_compartment_from_parent_by_compart_type(parent, compart_type)
			--if compart then
			--	return compart
			--end
			--print("in else")
			local median_compart = create_missing_compartment(parent, parent_type, compart_type:find("/parentCompartType"))
			core.reorder_child_compartments_according_to_type_order(parent)
			local compart = get_compartment_by_type(median_compart, compart_type)
			if compart == nil then
				compart = core.add_compart(compart_type, median_compart, "")
				core.reorder_child_compartments_according_to_type_order(median_compart)
			end
			return compart
		end
	end
end


function get_compartment_from_parent_by_compart_type(parent, compart_type)
	local path = "/subCompartment"
	if parent:filter(".Element"):is_not_empty() then
		path = "/compartment"
	end
	local res
	parent:find(path):each(function(compart)
		--local tmp = get_compartment_from_parent_by_compart_type(compart, compart_type)
		--local tmp_compart_type = compart:find("/compartType")
	end)
	return res
end

function is_reachable(start_compart_type, end_compart_type)
	start_compart_type:find("/subCompartType"):each(function(tmp_compart_type)
		
	
	end)
end

function get_compartment_by_type(obj, compart_type)
	local path = ""
	if obj:filter(".Compartment"):is_not_empty() then
		path = "/subCompartment"
	else
		path = "/compartment"
	end
	local buls = 0
	local result = nil
	obj:find(path):each(function(compart)
		if compart:find("/compartType"):id() == compart_type:id() and buls == 0 then
			buls = 1
			result = compart
		end
	end)
	return result
end

function add_compartment(compartment_type, parent, value, is_parser_needed)
	value = value or compartment_type:attr("startValue")
	local compartment = add_compartment_object(compartment_type, parent, value)
	set_compartment_value(compartment, value, nil, is_parser_needed)
return compartment
end

function add_compart(compartment_type, parent, value)
	local compartment = add_compartment_object(compartment_type, parent, value)
	local input = build_compartment_input_from_value(value, compartment_type, compartment)
	compartment:attr({input = input})
return compartment
end

function add_compartment_object(compartment_type, parent, value)
	local compart = lQuery.create("Compartment", {
							value = value,
							compartType = compartment_type,
							isGroup = compartment_type:attr("isGroup"),
							compartStyle = compartment_type:find("/compartStyle:first()")})
	link_compartment_to_parent(compart, parent)
	utilities.call_element_proc_thru_type(compart, "procCreateCompartmentDomain")
	return compart
end

function set_compartment_value(compartment, value, check_box_val, is_parser_needed)
	set_compartment_input_value(compartment, compartment:find("/compartType"), value)
	update_compartment_input_from_value(compartment, nil, is_parser_needed)
	if check_box_val == nil then
		--print("check box val is nil")
		update_style_from_value(compartment, value)
		update_compart_style_from_value(compartment, value)
	else
		update_style_from_value(compartment, check_box_val)
		update_compart_style_from_value(compartment, check_box_val)
	end
	return compartment
end

function get_compartment_element(compartment)
	local parent_compartment = compartment:find("/parentCompartment")
	if parent_compartment:is_empty() then
		return compartment:find("/element")
	else
		return get_compartment_element(parent_compartment)
	end
end

function update_style_from_value(compartment, value)
	local elem_style_by_value = compartment:find("/compartType/choiceItem")
						:filter_attr_value_equals("value", value)
						:find("/elemStyleByChoiceItem")
	local compartment_element = get_compartment_element(compartment)


	if elem_style_by_value:is_not_empty() then
		compartment_element:remove_link("elemStyle")
					:link("elemStyle", elem_style_by_value)
	else
		--local elem_style = compartment_element:find("/elemType/elemStyle:first()")
		--compartment_element:remove_link("elemStyle")
		--			:link("elemStyle", elem_style)	
	end
	compartment_element:attr("style","#")
end

function update_compart_style_from_value(compartment, value)
	local compart_style_by_value = compartment:find("/compartType/choiceItem"):filter_attr_value_equals("value", value):find("/compartStyleByChoiceItem")
	if compart_style_by_value:is_not_empty() then
		local compartment2_type_id = compart_style_by_value:find("/compartType"):attr("id")
		--varbut vajag visiem nomainit???
		--local compartment2 = compartment:find("/element/compartment:has(/compartType[id="..compartment2_type_id.."])"):log()
		compartment:remove_link("compartStyle")
		compartment:link("compartStyle",compart_style_by_value)
		compartment:attr("style","#")
	end
end

function reorder_child_compartments_tree(parent)
	local child_role, child_role_type, type_role = get_parent_type(parent)
	local child_type_list = {}
	parent:find("/" .. child_role):each(function(child)
		local compart_type = child:find("/compartType")
		if compart_type:is_not_empty() then
			local id = compart_type:attr("id")
			if (child_type_list[id] == nil) then
				child_type_list[id] = {}
			end

			table.insert(child_type_list[id], child)
			parent:remove_link(child_role, child)
		end
	end)

	parent:find("/" .. type_role):find("/" .. child_role_type):each(function(compart_type)
		local list = child_type_list[compart_type:attr("id")]
		if (list) then
			for i, val in ipairs(list) do
				parent:link(child_role,	val)
			end
		end
	end)

	parent:find("/" .. child_role):each(function(child)
		reorder_child_compartments_tree(child)
	end)
end

function get_parent_type(parent)
	if parent:filter(".Element"):is_not_empty() then
		return "compartment", "compartType", "elemType"
	else
		return "subCompartment", "subCompartType", "compartType"
	end
end

function reorder_child_compartments_according_to_type_order(parent)
	reorder_child_compartments_tree(parent)
--  local parent_compart_types = parent:find("/compartType/subCompartType, /elemType/compartType")
--  local order = {}
--  local counter = 0
--  parent_compart_types:each(function(compartType)
--                              counter = counter + 1
--                              order[lQuery(compartType):id()] = counter
--                            end)
--  local compartment_id_to_type_id_map = {}
--  
--  parent:find("/compartment, /subCompartment"):each(function(compartment)
--                                                      compartment = lQuery(compartment)
--                                                      compartment_id_to_type_id_map[compartment:id()] = compartment:find("/compartType"):id()
--                                                    end)
--  
--  local sort_function = function(compartment_1, compartment_2)
--    return order[compartment_id_to_type_id_map[lQuery(compartment_1):id()]] < order[compartment_id_to_type_id_map[lQuery(compartment_2):id()]]
--  end
--  
--  if not parent:filter("Element"):is_empty() then
--    parent:sort_linked("compartment", sort_function)
--  else -- assume compartment
--    parent:sort_linked("subCompartment", sort_function)
--  end
--  
--  return sort_function
end

function update_compartment_value_from_subcompartments(compartment)
	local compartType = compartment:find("/compartType")
	local concat_string = compartType:attr("concatStyle") or ""
	local sub_inputs = {}
	local sub_comparts = compartment:find("/subCompartment")
	if sub_comparts:is_not_empty() then
		local translets = sub_comparts:find("/compartType"):find("/translet[extensionPoint = 'procCompose']")
		local value = ""
		local input = ""
		if translets:is_not_empty() then
			local translet = translets:filter(":first()")
			local proc_name = translet:attr("procedureName")
			value = utilities.execute_translet(proc_name, sub_comparts:filter(":first()"))
			input = value
		else
			sub_comparts:each(function(sub)
				local is_hidden = check_if_compartment_is_hidden(sub)
				if not(is_hidden) then
					local val = sub:attr("input")
					if val ~= "" then
						table.insert(sub_inputs, val)
					end
				end
			end)
			value = table.concat(sub_inputs, concat_string)
			input  = build_compartment_input_from_value(value, compartType, compartment)
		end
		set_compartment_input_value(compartment, compartment:find("/compartType"), value, input)
	end
	return value
end

function is_array(t)
  if type(t) ~= "table" then
    return false
  else
    local only_number_keys = true
    for k, v in pairs(t) do
      if type(k) ~= "number" then
        only_number_keys = false
        break
      end
    end
    return only_number_keys
  end
end

function get_default_value_supplied(value_table)
	if #value_table == 1 and type(value_table[1]) == "string" then
		return value_table[1]
	end
end

function add_compartments_by_table(parent, value_table, is_parser_needed)
	if(type(value_table) == "string") then
		local compart_type = parent:find("/compartType")
		set_compartment_input_value(parent, compart_type, value_table)
	elseif is_array(value_table) then
		for _, sub_table in ipairs(value_table) do
			add_compartments_by_table(parent, sub_table, is_parser_needed)
		end
		update_compartment_value_from_subcompartments(parent)
	elseif(type(value_table) == "table") then
		parent:find("/compartType, /elemType"):find("/subCompartType, /compartType"):each(function(compart_type)
			local compart_type_id = compart_type:attr("id")
			local sub_table = value_table[compart_type_id]
			if sub_table ~= nil then
				local compartment = add_compart(compart_type, parent, "")
				add_compartments_by_table(compartment, sub_table, is_parser_needed)
				local supplied_default_value = get_default_value_supplied(sub_table)
				if supplied_default_value then
					--vai nevag updatot properties???
					set_compartment_input_value(compartment, compart_type, supplied_default_value, supplied_default_value)
					update_style_from_value(compartment, supplied_default_value)
				else
					update_compartment_value_from_subcompartments(compartment)
					update_style_from_value(compartment, compartment:attr("value"))
				end
			elseif compart_type:attr("isEssential") == "true" or utilities.execute_should_be_included(compart_type) then	--vai vajag kaut ko darit???
				add_compartment(compart_type, parent, "", is_parser_needed)
			end
		end)
	end
end

function create_compartment_tree(parent, is_parser_needed)
	local value_table = {}
	create_compart_value_table(parent:find("/elemType"), value_table, "/compartType", parent)
	add_compartments_from_table(parent, value_table)
	reorder_child_compartments_tree(parent)
return compart 
end

function add_compartments_from_table(elem, value_table, is_parser_needed)
	elem:find("/elemType/compartType"):each(function(compart_type)
		local index = compart_type:attr("id")
		if type(value_table[index]) == "table" then
			set_sub_compart_values(add_compartment(compart_type, elem, "", is_parser_needed), value_table[index])
		else
			local compart = add_compart(compart_type, elem, value_table[index])
			set_compartment_input_value(compart, compart_type)
		end
	end)
end

function create_compart_value_table(parent_type, value_table, path_to_compart_type, elem)
	parent_type:find(path_to_compart_type):each(function(compart_type)
		if compart_type:attr_e("isEssential") == "true" and utilities.execute_should_be_included(compart_type) then
			local compart_type_id = compart_type:attr_e("id")
			if compart_type_id ~= "" then
				local start, finish = string.find(compart_type_id, "ASFictitious")
				if compart_type:find("/subCompartType"):size() > 0 and (start ~= 1 and finish ~= 12) then
					value_table[compart_type_id] = {}
					create_compart_value_table(compart_type, value_table[compart_type_id], "/subCompartType", elem)
				else
					local default_val = get_default_value(compart_type, elem)
					value_table[compart_type_id] = default_val
				end
			end
		end
	end)
end

function get_default_value(compart_type, elem)
	--local proc_name = compart_type:attr_e("procStartValue")
	local proc_name = compart_type:find("/translet[extensionPoint = 'procGenerateInputValue']"):attr_e("procedureName")
	if proc_name ~= "" and proc_name ~= nil then
		return utilities.execute_translet(proc_name, elem)
	else
		return compart_type:attr_e("startValue")	
	end
end

function delete_compartment(compartment)
  local parent_compartment = compartment:find("/parentCompartment")
  local compartment_id = lQuery(compartment):id()
  compartment:delete()
  --lua_l0_core.delete_compartment(compartment_id)
  
  if not parent_compartment:is_empty() then
    core.update_compartment_value_from_subcompartments(parent_compartment)
  end
end


--test
-- add_compartments_by_table(el, {
--   Name = {
--     Package = "bbb",
--     Class = "ccc"
--   },
--   ["Equivalent classes(=)"] = {
--     ["Equivalent classes(=)"] = {
--       "e1",
--       "e2"
--     }
--   },
--   Attributes = {
--     Attributes = {
--       {
--         "attr1:TTT",
--         Name = "a",
--         Type = "t"
--       },
--       "attr2",
--       {
--         Name = "a",
--         Type = "t"
--       }
--     }
--   }})

local type_to_class = {
  NodeType = "Node",
  EdgeType = "Edge"
}

function get_class_name_for_type(elem_type)
  return type_to_class[elem_type:get(1):class().name]
end

function get_elemType_by_id(graph_diagram_type, elem_type_id)
  return graph_diagram_type:find("/elemType[id='" .. elem_type_id .. "']")
end

local keys_from_dirrection = {
  outgoing = {"target", "start", "end"},
  incomming = {"source", "end", "start"}
}

local function add_link_or_add_to_pending(source, link_name, target_id, mappings, pending_links, table_elem_id_for_pending_err, target_key_for_err)
  if target_id then
    local target = mappings[target_id]
    if target then
      source:link(link_name, target)
    else
      table.insert(pending_links, {source, link_name, target_id, table_elem_id_for_pending_err, target_key_for_err})
    end
  end
end

function add_edges_by_features(graph_dgr, graph_diagram_type, mappings, pending_links, element, features, direction, table_elem_id_for_pending_err)
  local keys = keys_from_dirrection[direction]
  
  for edge_type_id, edges in pairs(features[direction] or {}) do
    local edge_type = get_elemType_by_id(graph_diagram_type, edge_type_id)
    local elem_class_name = get_class_name_for_type(edge_type)
    if type(edges) ~= "table" then --assume id
      local edge = add_element(elem_class_name, edge_type, graph_dgr)
      edge:link(keys[2], element)
      add_link_or_add_to_pending(edge, keys[3], edges, mappings, pending_links, table_elem_id_for_pending_err, direction)
    else --assume list of edges
      for _, edge_features in ipairs(edges) do
        if type(edge_features) ~= "table" then --assume id
          local edge = add_element(elem_class_name, edge_type, graph_dgr)
          edge:link(keys[2], element)
          add_link_or_add_to_pending(edge, keys[3], edge_features, mappings, pending_links, table_elem_id_for_pending_err, direction)
        else -- assume table of features
          local edge = add_element(elem_class_name, edge_type, graph_dgr)
          edge:link(keys[2], element)
          add_link_or_add_to_pending(edge, keys[3], edge_features[keys[1]], mappings, pending_links, table_elem_id_for_pending_err, direction)
        end
      end
    end
  end
end

function add_elements_by_table(graph_dgr, mappings, features, progress_reporter_fn, is_parser_needed)
  progress_reporter_fn = progress_reporter_fn or function () end
  local graph_diagram_type = graph_dgr:find("/graphDiagramType")
  local pending_links = {}
  
  for elem_type_id, elems in pairs(features) do
    local elem_type = get_elemType_by_id(graph_diagram_type, elem_type_id)
    if not elem_type:is_empty() then
      local elem_class_name = get_class_name_for_type(elem_type)
      for elem_id, elem_features in pairs(elems) do
        local element = add_element(elem_class_name, elem_type, graph_dgr)
        progress_reporter_fn()
        mappings[elem_id] = element

	
		tune_element_table(element, elem_features.compartments)
        add_compartments_by_table(element, elem_features.compartments, is_parser_needed)
      
        add_link_or_add_to_pending(element, "start", elem_features.source, mappings, pending_links, elem_id, 'source')
        add_link_or_add_to_pending(element, "end", elem_features.target, mappings, pending_links, elem_id, 'target')
		
		add_link_or_add_to_pending(element, "container", elem_features.container, mappings, pending_links, elem_id, 'container')
      
        add_edges_by_features(graph_dgr, graph_diagram_type, mappings, pending_links, element, elem_features, "outgoing", elem_id)
        add_edges_by_features(graph_dgr, graph_diagram_type, mappings, pending_links, element, elem_features, "incomming", elem_id)
      end
    else
      log("missing type", elem_type_id)
    end
  end
  
  log(#pending_links .. " pending")
  
  local missing_objects = {}
  for _, link_to_add in ipairs(pending_links) do
    local source, link_name, target_id, src_elem_key_in_table, taget_id_key_in_table = unpack(link_to_add)
    local target = mappings[target_id]
    if target then
      source:link(link_name, target)
    else
      table.insert(missing_objects, string.format("missing link end for elem <%s> link <%s> (value <%s>)", tostring(src_elem_key_in_table), tostring(taget_id_key_in_table), tostring(target_id)))
    end
  end
  
  log(#missing_objects .. " missing:")
  log(dumptable(missing_objects))
  
  return mappings
end

function tune_element_table(element, list)
	if list ~= nil then
		local elem_type = element:find("/elemType")
		elem_type:find("/compartType"):each(function(compart_type)
			tune_table(compart_type, list)
		end)
	end
end

function tune_table(compart_type, list)
	--print("tune table")
	local sub_compart_types = compart_type:find("/subCompartType")
	local compart_type_id = compart_type:attr("id")
	if list[compart_type_id] == nil then
		local start, finish = string.find(compart_type_id, "ASFictitious")
		if start == 1 and finish == 12 then
			list[compart_type_id] = ""
		elseif sub_compart_types:is_empty() then
			list[compart_type_id] = ""
		else
			list[compart_type_id] = {}
			sub_compart_types:each(function(sub_compart_type)
				tune_table(sub_compart_type, list[compart_type_id])
			end)
		end
	elseif list[compart_type_id] == "" then
		local sub_compart_type_id = ""
		if sub_compart_types:size() == 1 then
			sub_compart_type_id = sub_compart_types:attr("id")
		end
		local start, finish = string.find(sub_compart_type_id, "ASFictitious")
		if sub_compart_types:size() == 1 and start == 1 and finish == 12 then
			list[compart_type_id] = {}
			list[compart_type_id][sub_compart_type_id] = ""
			--tune_table(sub_compart_types, list[compart_type_id][sub_compart_type_id])
		else
			if sub_compart_types:size() > 0 then
				list[compart_type_id] = {}
				sub_compart_types:each(function(sub_compart_type)
					tune_table(sub_compart_type, list[compart_type_id])
				end)
			end
		end
	else
		if is_array(list[compart_type_id]) then
			for _, new_list in ipairs(list[compart_type_id]) do
				tune_table(compart_type:find("/subCompartType"), new_list)
			end
		elseif type(list[compart_type_id]) == "table" then
			sub_compart_types:each(function(sub_compart_type)
				tune_table(sub_compart_type, list[compart_type_id])
			end)
		end
	end
end

function reconnect_compartment_to_parent(compart)
	local parent_elem = compart:find("/element")
	if parent_elem:is_not_empty() then
		reconnect(compart, parent_elem, "element")
	else
		local parent_compart = compart:find("/parentCompartment")
		reconnect(compart, parent_compart, "parentCompartment")
	end
end

function reconnect(start_obj, end_obj, role)
	start_obj:remove_link(role, end_obj)
		:link(role, end_obj)
end

function build_compartment_table_from_table(base, value_table, role_to_base, role_to_base_type, role_to_child_type)
	for index, val in pairs(value_table) do
		local path =  '/' .. role_to_base_type .. '/' .. role_to_child_type .. '[id = ' .. index .. ']'
		local base_type = base:find(path)
		local compart = add_compart(base_type, base, "")
		compart:link(role_to_base, base)
		if val["value"] ~= nil then
			compart:attr(val)
			set_parent_value(compart)
		else
			build_compartment_table_from_table(compart, val, "parentCompartment", "compartType", "subCompartType")
		end
	end
end

function replace_new_lines(val)
	local new_val = val
	local grammer = re.compile([[grammer <- (nl? line (nl line)* nl?)
	line <- {[^%nl]*}
	nl <- %nl -> void  ]], {void = function() return '\\n' end})

	local list = lpeg.match(lpeg.Ct(grammer), val)
	if type(list) == "table" then
		new_val = table.concat(list)
	end
	return new_val
end

function set_compartment_and_field(compart, val, input)
	if input == nil then
		input = value
	end
	core.set_compartment_value(compart, val)
	compart:attr({value = val, input = input})
	local input_field = compart:find("/component")
	if input_field:is_not_empty() then 
		input_field:attr("text", val)
		utilities.refresh_form_component(input_field)
		return input_field
	end
end

-- extended_mappings = add_elements_by_table(graph_dgr, mappings, {
--   Class = {
--     c_id1 = {
--       compartments = {
--         Name = 'class 1'
--       }
--     },
--     c_id2 = {
--       compartments = {
--         Name = 'class 2'
--       }
--     },
--     c_id3 = {
--       compartments = {
--         Name = 'class 3'
--       }
--     }
--   },
--   Fork = {
--     f_id1 = {
--       outgoing = {
--         GeneralizationToFork = {
--           {target = "c_id1"}
--         }
--       },
--       incomming = {
--         AssocToFork= {
--           {source = "c_id2"},
--           {source = "c_id3"},
--         }
--       }
--     }
--   },
--   Association = {
--     a_id1 = {
--       source = "c_id2",
--       target = "c_id3",
--       compartments = {
--         Name = 'c2',
--         InvName = 'c3'
--       }
--     }
--   }
-- })