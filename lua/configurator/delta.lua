module(..., package.seeall)

require("core")
require("utilities")
u = require("configurator.configurator_utilities")
cu = require("configurator.const.const_utilities")
d = require("dialog_utilities")
require("re")
copy_paste = require("interpreter.CutCopyPaste")

function dump_configurator()
	local list_of_code = {}
	local edge_list = {}

	table.insert(list_of_code, '--start of configurator types\n')
	table.insert(list_of_code, generate_diagram_type_code(lQuery("GraphDiagramType[id = 'specificationDgr']:first()")))
	table.insert(list_of_code, '--end of configurator types\n')

	table.insert(list_of_code, '--start of target types\n')
	table.insert(list_of_code, generate_diagram_type_code(lQuery("GraphDiagram/target_type")))
	table.insert(list_of_code, '--end of target types\n')

	table.insert(list_of_code, '--start of configurator elements\n')
	table.insert(list_of_code, dump_configurator_presentation())
	table.insert(list_of_code, '--end of configurator elements\n')

	table.insert(list_of_code, '--start of domain\n')
	table.insert(list_of_code, restore_links_to_domain_objects())
	table.insert(list_of_code, '--end of domain\n')

	return table.concat(list_of_code)
end

function generate_diagram_type_code(diagram_types)
	local list_of_code = {}
	local edge_list = {}
	diagram_types:each(function(diagram_type)
		dump_diagram_type(diagram_type, edge_list, list_of_code)
	end)
	table.insert(list_of_code, tool_type_dump(edge_list))
	table.insert(list_of_code, process_edges(edge_list))
	return table.concat(list_of_code)
end

function dump_configurator_presentation()
	local diagrams = lQuery("GraphDiagramType[id = 'specificationDgr']/graphDiagram")
	List = {}
	List["GraphDiagram"] = {}
	List["Node"] = {}
	List["Port"] = {}
	List["Edge"] = {}
	List["FreeBox"] = {}
	get_configurator_elems(List, diagrams)
	return generate_code_from_presentation_objects(List)
end

function get_configurator_elems(List, diagrams)
	diagrams:each(function(diagram)
		table.insert(List["GraphDiagram"], diagram)
		diagram:find("/element"):each(function(elem)
			table.insert(List[utilities.get_class_name(elem)], elem)
		end)
	end)
end

function generate_code_from_presentation_objects(List)
	local list_of_code = {}
	for _, obj in ipairs(List["GraphDiagram"]) do
		table.insert(list_of_code, add_presentation_diagram(obj))
		local var = utilities.make_obj_to_var(obj)
		table.insert(list_of_code, string.format('utilities.add_palette_to_diagram(%s, %s)\n', var, string.format('%s:find("/graphDiagramType")', var)))
		table.insert(list_of_code, string.format('utilities.add_toolbar_to_diagram(%s, %s)\n', var, string.format('%s:find("/graphDiagramType")', var)))
	end
	for _, obj in ipairs(List["Node"]) do
		table.insert(list_of_code, add_presentation_element(obj))
		local child_diagram = obj:find("/child")
		if child_diagram:is_not_empty() then
			table.insert(list_of_code, string.format('%s:link("child", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(child_diagram)))
		else
			local target_diagram = obj:find("/target")
			if target_diagram:is_not_empty() then
				table.insert(list_of_code, string.format('%s:link("target", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(target_diagram)))
			end
		end
	end
	for _, obj in ipairs(List["Port"]) do
		table.insert(list_of_code, add_presentation_element(obj))
		table.insert(list_of_code, string.format('%s:link("node", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(obj:find("/node"))))
	end
	for _, obj in ipairs(List["Edge"]) do
		table.insert(list_of_code, add_presentation_element(obj))
		table.insert(list_of_code, string.format('%s:link("start", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(obj:find("/start"))))
		table.insert(list_of_code, string.format('%s:link("end", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(obj:find("/end"))))
	end
	for _, obj in ipairs(List["FreeBox"]) do
		table.insert(list_of_code, add_presentation_element(obj))
	end
	return table.concat(list_of_code)
end

function add_presentation_diagram(obj)
	local list_of_code = {}
	table.insert(list_of_code, utilities.generate_create_instance_code(obj))
	local elem_var = utilities.make_obj_to_var(obj)
	table.insert(list_of_code, string.format('%s:link("graphDiagramType", %s)\n', elem_var, utilities.make_obj_to_var(obj:find("/graphDiagramType"))))
	table.insert(list_of_code, string.format('%s:link("graphDiagramStyle", %s)\n', elem_var, utilities.make_obj_to_var(obj:find("/graphDiagramStyle"))))
	table.insert(list_of_code, string.format('%s:link("target_type", %s)\n', elem_var, utilities.make_obj_to_var(obj:find("/target_type"))))
	return table.concat(list_of_code)
end

function add_presentation_element(obj)
	local list_of_code = {}
	table.insert(list_of_code, utilities.generate_create_instance_code(obj))
	local elem_var = utilities.make_obj_to_var(obj)
	table.insert(list_of_code, string.format('%s:link("graphDiagram", %s)\n', elem_var, utilities.make_obj_to_var(obj:find("/graphDiagram"))))
	table.insert(list_of_code, string.format('%s:link("elemType", %s)\n', elem_var, utilities.make_obj_to_var(obj:find("/elemType"))))
	table.insert(list_of_code, string.format('%s:link("elemStyle", %s)\n', elem_var, utilities.make_obj_to_var(obj:find("/elemStyle"))))
	local target_type = obj:find("/target_type")
	if target_type:is_not_empty() then
		table.insert(list_of_code, string.format('%s:link("target_type", %s)\n', elem_var, utilities.make_obj_to_var(target_type)))
	end
	table.insert(list_of_code, copy_paste.add_compartments(obj))
	return table.concat(list_of_code)
end

function dump_diagram_type(diagram_type, edge_list, list_of_code)
	table.insert(list_of_code, process_diagram_type(diagram_type, edge_list))
	table.insert(list_of_code, process_seeds(diagram_type, edge_list))
	table.insert(list_of_code, process_port(diagram_type, edge_list))
	table.insert(list_of_code, process_line(diagram_type, edge_list))
	table.insert(list_of_code, process_free_elems(diagram_type, edge_list))
	process_specialization(diagram_type, edge_list)
	add_elem_types_to_diagram(diagram_type, edge_list)
	add_palette_elements_to_palette(diagram_type, edge_list)
end

function tool_type_dump(edge_list)
	local list_of_code = {}
	local tool_type = lQuery("ToolType")
	table.insert(list_of_code, utilities.generate_create_instance_code(tool_type))
	tool_type:find("/graphDiagramType"):each(function(diagram_type)
		add_edge(tool_type, diagram_type, "graphDiagramType", edge_list)
	end)
	return table.concat(list_of_code)
end

function add_elem_types_to_diagram(diagram_type, edge_list)
	diagram_type:find("/elemType"):each(function(elem_type)
		add_edge(diagram_type, elem_type, "elemType", edge_list)
	end)	
end

function add_palette_elements_to_palette(diagram_type, edge_list)
	local palette_type = diagram_type:find("/paletteType")
	palette_type:find("/paletteElementType"):each(function(palette_elem_type)
		add_edge(palette_type, palette_elem_type, "paletteElementType", edge_list)
	end)	
end

function create_configurator_presentation_from_types(diagram, export_file, list_of_elems)
	create_instance(diagram, export_file)
	add_edge(diagram, diagram:find("/target_type"), "target_type", list_of_elems["Edges"])
	add_edge_to_diagram_type(diagram, {graphDiagramType = diagram:find("/graphDiagramType"):attr("id")}, "graphDiagramType", export_file)
	create_nodes(diagram, export_file, list_of_elems)
	create_edges(diagram, export_file, list_of_elems)
	create_ports(diagram, export_file, list_of_elems)
	create_specialization(diagram, export_file, list_of_elems)
end

function create_nodes(diagram, export_file, list_of_elems)
	utilities.save_dgr_cmd(diagram)
	diagram:find("/element:has(/elemType[id = 'Box']), /element:has(/elemType[id = 'FreeBox']), /element:has(/elemType[id = 'FreeLine'])"):each(function(node)
		create_instance(node, export_file)	
		add_edge(diagram, node, "element", list_of_elems["Edges"])
		add_edge(node, node:find("/target_type"), "target_type", list_of_elems["Edges"])
		add_edge(node, node:find("/elemStyle"), "elemStyle", list_of_elems["Edges"])
		add_edge_to_element_type(node, {graphDiagramType = diagram:find("/graphDiagramType"):attr("id"), elemType = node:find("/elemType"):attr("id")}, "elemType", export_file)
		local target_diagram = node:find("/target")
		if target_diagram:size() > 0 then
			add_edge(node, target_diagram, "target", list_of_elems["Edges"])
			create_configurator_presentation_from_types(target_diagram, export_file, list_of_elems)
		end
		create_compartments(node, export_file, list_of_elems)
	end)
end

function create_edges(diagram, export_file, list_of_elems)
	diagram:find("/element:has(/elemType[id = 'Line'])"):each(function(edge)
		create_instance(edge, export_file)	
		add_edge(diagram, edge, "element", list_of_elems["Edges"])
		add_edge(edge, edge:find("/target_type"), "target_type", list_of_elems["Edges"])
		add_edge(edge, edge:find("/elemStyle"), "elemStyle", list_of_elems["Edges"])
		add_edge(edge, edge:find("/start"), "start", list_of_elems["Edges"])
		add_edge(edge, edge:find("/end"), "end", list_of_elems["Edges"])
		add_edge_to_element_type(edge, {graphDiagramType = diagram:find("/graphDiagramType"):attr("id"), elemType = edge:find("/elemType"):attr("id")}, "elemType", export_file)
		create_compartments(edge, export_file, list_of_elems)
	end)
end

function create_ports(diagram, export_file, list_of_elems)
	diagram:find("/element:has(/elemType[id = 'Pin'])"):each(function(port)
		create_instance(port, export_file)	
		add_edge(diagram, port, "element", list_of_elems["Edges"])
		add_edge(port, port:find("/target_type"), "target_type", list_of_elems["Edges"])
		add_edge(port, port:find("/elemStyle"), "elemStyle", list_of_elems["Edges"])
		add_edge(port, port:find("/node"), "node", list_of_elems["Edges"])
		add_edge_to_element_type(port, {graphDiagramType = diagram:find("/graphDiagramType"):attr("id"), elemType = port:find("/elemType"):attr("id")}, "elemType", export_file)
		create_compartments(port, export_file, list_of_elems)
	end)
end

function create_specialization(diagram, export_file, list_of_elems)
	diagram:find("/element:has(/elemType[id = 'Specialization'])"):each(function(specialization)
		create_instance(specialization, export_file)	
		add_edge(diagram, specialization, "element", list_of_elems["Edges"])
		add_edge(specialization, specialization:find("/start"), "start", list_of_elems["Edges"])
		add_edge(specialization, specialization:find("/end"), "end", list_of_elems["Edges"])
		local elem_style_table = {}
		table.insert(elem_style_table, {GraphDiagramType = diagram:find("/graphDiagramType"):attr("id")})
		table.insert(elem_style_table, {elemType = specialization:find("/elemType"):attr("id")})
		table.insert(elem_style_table, {elemStyle = specialization:find("/elemStyle"):attr("id")})
		add_edge_by_table(specialization, elem_style_table, "elemStyle", list_of_elems)
		add_edge_to_element_type(specialization, {graphDiagramType = diagram:find("/graphDiagramType"):attr("id"), elemType = specialization:find("/elemType"):attr("id")}, "elemType", export_file)
	end)
end

function create_compartments(elem, export_file, list_of_elems)
	create_compartment_tree(elem, export_file, list_of_elems, "compartment")
end

function create_compartment_tree(elem, export_file, list_of_elems, role)
	elem:find("/" .. role):each(function(compart)
		create_instance(compart, export_file)
		add_edge(elem, compart, role, list_of_elems["Edges"])
		local target_type = compart:find("/target_type")
		if target_type:size() > 0 then
			add_edge(compart, target_type, "target_type", list_of_elems["Edges"])
		end
		local id_table = {}
		local compart_type = compart:find("/compartType")
		local compart_type_id = compart_type:attr("id")
		if compart_type_id == "AS#Name" then
			table.insert(id_table, {GraphDiagramType = elem:find("/graphDiagram/graphDiagramType"):attr("id")})
			table.insert(id_table, {elemType = elem:find("/elemType"):attr("id")})
			table.insert(id_table, {compartType = compart_type:attr("id")})
			table.insert(id_table, {compartStyle = compart:find("/compartStyle"):attr("id")})
		else
			local compart_style = compart:find("/compartStyle")
			local target_compart_type = compart_style:find("/compartType")
			local target_elem_type = target_compart_type:find("/elemType")
			if compart_style:is_empty() then
				target_compart_type = compart:find("/compartType")		
				compart_style = compart:find("/target_type/compartStyle")
				target_elem_type = target_compart_type:find("/elemType")
			end
			table.insert(id_table, {GraphDiagramType = target_elem_type:find("/graphDiagramType"):attr("id"), filter = '[isNew = true]'})
			table.insert(id_table, {elemType = target_elem_type:attr("id")})
			table.insert(id_table, {compartType = target_compart_type:attr("id")})
			table.insert(id_table, {compartStyle = compart_style:attr("id")})
		end
		add_edge_by_table(compart, id_table, "compartStyle", list_of_elems)
		add_edge_to_compartment_type(compart, {graphDiagramType = elem:find("/graphDiagram/graphDiagramType"):attr("id"), elemType = elem:find("/elemType"):attr("id"), compartType = compart:find("/compartType"):attr("id")}, "compartType", list_of_elems)
		create_compartment_tree(compart, export_file, list_of_elems, "subCompartment")
	end)
end

function process_diagram_type(diagram_type, edge_list)
	local list_of_code = {}
	table.insert(list_of_code, create_instance(diagram_type))
	table.insert(list_of_code, process_elems_in_one_level(diagram_type, "graphDiagramStyle", edge_list))
	table.insert(list_of_code, process_elems_in_two_levels(diagram_type, "rClickEmpty", "popUpElementType", edge_list))
	table.insert(list_of_code, process_elems_in_two_levels(diagram_type, "rClickCollection", "popUpElementType", edge_list))
	table.insert(list_of_code, process_elems_in_two_levels(diagram_type, "toolbarType", "toolbarElementType", edge_list))
	table.insert(list_of_code, process_elems_in_one_level(diagram_type, "eKeyboardShortcut", edge_list))
	table.insert(list_of_code, process_elems_in_one_level(diagram_type, "cKeyboardShortcut", edge_list))
	table.insert(list_of_code, process_palette_type(diagram_type, edge_list))		
	return table.concat(list_of_code)
end

function copy_target_diagram_type(target_diagram)
	local list_of_code = {}
	local edge_list = {}
	local target_diagram_type = target_diagram:find("/target_type")
	table.insert(list_of_code, process_diagram_type(target_diagram_type, edge_list))
	local diagram_type_code = utilities.make_obj_to_var(target_diagram_type)
	table.insert(list_of_code, string.format('%s:link("target_type", %s)\n', utilities.make_obj_to_var(target_diagram), diagram_type_code))
	local seed_type = target_diagram_type:find("/source")
	if seed_type:is_not_empty() then
		local source_type_code = utilities.make_obj_to_var(seed_type)
		table.insert(list_of_code, string.format('%s:link("target", %s)\n', source_type_code, diagram_type_code))
		table.insert(list_of_code, string.format('%s:attr({id = %s:attr("id"), caption = %s:attr("caption")})\n', diagram_type_code, source_type_code, source_type_code))
		table.insert(list_of_code, string.format('%s:attr({caption = %s:attr("caption")})\n', utilities.make_obj_to_var(target_diagram), source_type_code))
	end
	table.insert(list_of_code, process_edges(edge_list))
	return table.concat(list_of_code)
end

function process_palette_type(dgr_type, edge_list)
	local list_of_code = {}	
	local palette_type = dgr_type:find("/paletteType")
	if palette_type:is_not_empty() then
		table.insert(list_of_code, create_instance(palette_type))
		add_edge(dgr_type, palette_type, "paletteType", edge_list)
	end
	return table.concat(list_of_code)
end

function create_instance(obj)
	return utilities.generate_create_instance_code(obj)
end

function process_seeds(diagram_type, edge_list)
	local list_of_code = {}	
	diagram_type:find("/elemType.NodeType"):each(function(elem_type)
		table.insert(list_of_code, process_elem_type(elem_type, edge_list))
		local target_diagram_type = elem_type:find("/target")
		if target_diagram_type:is_not_empty() then
			--dump_diagram_type(target_diagram_type, edge_list, list_of_code)
			add_edge(elem_type, target_diagram_type, "target", edge_list)
		end
	end)
	return table.concat(list_of_code)
end

function process_palette_element(elem_type, edge_list)
	local list_of_code = {}	
	local palette_elem = elem_type:find("/paletteElementType")
	local palette_type = palette_elem:find("/paletteType")
	if palette_elem:is_not_empty() then	
		local palette_elem_nr = palette_elem:attr("nr")
		table.insert(list_of_code, string.format('if %s == nil then\n\t%send\n', utilities.make_obj_to_var(palette_elem), create_instance(palette_elem)))
		add_edge(elem_type, palette_elem, "paletteElementType", edge_list)
	end
	return table.concat(list_of_code)
end

function process_property_diagram(elem_type, edge_list)
	local list_of_code = {}		
	local prop_diagram = elem_type:find("/propertyDiagram")
	if prop_diagram:is_not_empty() then
		table.insert(list_of_code, create_instance(prop_diagram))
		add_edge(elem_type, prop_diagram, "propertyDiagram", edge_list)
		process_child_from_parent(prop_diagram, edge_list, list_of_code)
	end
	return table.concat(list_of_code)
end

function process_child_from_parent(row_parent, edge_list, list_of_code)
	row_parent:find("/propertyRow"):each(function(row)
		process_child(row_parent, row, edge_list, list_of_code)
	end)
	if row_parent:filter(".PropertyDiagram"):is_not_empty() then
		row_parent:find("/propertyTab"):each(function(tab)
			table.insert(list_of_code, create_instance(tab))
			add_edge(tab, row_parent, "propertyDiagram", edge_list)
			process_child_from_parent(tab, edge_list, list_of_code)
			--process_child(row_parent, tab, edge_list, list_of_code)
		end)
	end
end

function process_child(parent, child, edge_list, list_of_code)
	table.insert(list_of_code, create_instance(child))
	add_edge(parent, child, "propertyRow", edge_list)
	local compart_type_node = child:find("/compartType")
	add_edge(child, compart_type_node, "compartType", edge_list)
	local called_dgr = compart_type_node:find("/propertyDiagram")
	if called_dgr:is_not_empty() then
		if child:find("/calledDiagram"):id() == called_dgr:id() then
			add_edge(child, called_dgr, "calledDiagram", edge_list)
		end
		table.insert(list_of_code, process_property_diagram(compart_type_node, edge_list))
	end
end

function traverse_compart_types(elem_type, edge_list)
	local list_of_code = {}	
	process_compart_types(elem_type, edge_list, list_of_code, "compartType")
	return table.concat(list_of_code)
end

function process_compart_types(elem_type, edge_list, list_of_code, role)
	elem_type:find("/" .. role):each(function(compart_type)
		table.insert(list_of_code, create_instance(compart_type))
		table.insert(list_of_code, process_elems_in_one_level(compart_type, "compartStyle", edge_list))
		table.insert(list_of_code, process_choice_items(compart_type, edge_list))
		add_edge(elem_type, compart_type, role, edge_list)
		table.insert(list_of_code, process_elems_in_one_level(compart_type, "translet", edge_list))
		process_compart_types(compart_type, edge_list, list_of_code, "subCompartType")
	end)
end

function process_choice_items(compart_type, edge_list)
	local list_of_code = {}	
	compart_type:find("/choiceItem"):each(function(choice_item)
		table.insert(list_of_code, create_instance(choice_item))
		add_edge(compart_type, choice_item, "choiceItem", edge_list)
		local notation = choice_item:find("/notation")
		if notation:is_not_empty() then
			table.insert(list_of_code, create_instance(notation))
			add_edge(choice_item, notation, "notation", edge_list)
		end
		choice_item:find("/tag"):each(function(tag_compart)
			add_edge(choice_item, tag_compart, "tag", edge_list)
		end)
		choice_item:find("/compartStyleByChoiceItem"):each(function(compart_style)
			add_edge(choice_item, compart_style, "compartStyleByChoiceItem", edge_list)
		end)
		choice_item:find("/elemStyleByChoiceItem"):each(function(elem_style)
			add_edge(choice_item, elem_style, "elemStyleByChoiceItem", edge_list)
		end)
	end)
	return table.concat(list_of_code)
end

function process_elems_in_two_levels(obj_type, role1, role2, edge_list)
	local list_of_code = {}
	obj_type:find("/" .. role1):each(function(obj1)
		table.insert(list_of_code, create_instance(obj1))
		add_edge(obj_type, obj1, role1, edge_list)
		obj1:find("/" .. role2):each(function(obj2)
			table.insert(list_of_code, create_instance(obj2))
			add_edge(obj1, obj2, role2, edge_list)
		end)
	end)
	return table.concat(list_of_code)
end

function process_elems_in_one_level(obj_type, role1, edge_list, export_file)
	local list_of_code = {}
	obj_type:find("/" .. role1):each(function(obj1)
		table.insert(list_of_code, create_instance(obj1, export_file))
		add_edge(obj_type, obj1, role1, edge_list)
	end)
	return table.concat(list_of_code)
end

function process_line(diagram_type, edge_list)
	local list_of_code = {}	
	diagram_type:find("/elemType.EdgeType"):each(function(line_type)
		table.insert(list_of_code, process_elem_type(line_type, edge_list))
		add_edge(line_type, line_type:find("/start"), "start", edge_list)
		add_edge(line_type, line_type:find("/end"), "end", edge_list)
	end)
	return table.concat(list_of_code)
end

function process_port(diagram_type, edge_list)
	local list_of_code = {}
	diagram_type:find("/elemType.PortType"):each(function(pin_type)
		table.insert(list_of_code, process_elem_type(pin_type, edge_list))
		add_edge(pin_type, pin_type:find("/nodeType"), "nodeType", edge_list)
	end)
	return table.concat(list_of_code)
end

function process_free_elems(diagram_type, edge_list)
	local list_of_code = {}
	diagram_type:find("/elemType.FreeBoxType"):each(function(free_elem)
		table.insert(list_of_code, process_elem_type(free_elem, edge_list))
	end)
	return table.concat(list_of_code)
end

function process_elem_type(elem_type, edge_list)
	local list_of_code = {}
	table.insert(list_of_code, create_instance(elem_type))
	table.insert(list_of_code, process_elems_in_two_levels(elem_type, "popUpDiagramType", "popUpElementType", edge_list))
	table.insert(list_of_code, process_elems_in_one_level(elem_type, "elemStyle", edge_list))
	table.insert(list_of_code, process_elems_in_one_level(elem_type, "keyboardShortcut", edge_list))
	table.insert(list_of_code, process_elems_in_one_level(elem_type, "translet", edge_list))
	table.insert(list_of_code, traverse_compart_types(elem_type, edge_list))
	table.insert(list_of_code, process_property_diagram(elem_type, edge_list))
	table.insert(list_of_code, process_palette_element(elem_type, edge_list))
	if elem_type:filter(".EdgeType"):is_not_empty() then
		add_edge(elem_type, elem_type:find("/start"), "start", edge_list)
		add_edge(elem_type, elem_type:find("/end"), "end", edge_list)
	elseif elem_type:filter(".PortType"):is_not_empty() then
		add_edge(elem_type, elem_type:find("/nodeType"), "nodeType", edge_list)
	end
	return table.concat(list_of_code)
end

function process_target_elem_type(elem)
	local elem_type = elem:find("/target_type")
	local list_of_code = {}
	local edge_list = {}
	table.insert(list_of_code, process_elem_type(elem_type, edge_list))
	local diagram_type = elem:find("/graphDiagram/target_type")
	local diagram_type_id = diagram_type:id()
	local palette_type_id = diagram_type:find("/paletteType"):id()
	local elem_type_code = utilities.make_obj_to_var(elem_type)
	local diaram_type_code = utilities.make_obj_to_var(diagram_type)
	local elem_code = utilities.make_obj_to_var(elem)
	add_edge(elem, elem_type, "target_type", edge_list)
	add_edge(elem, elem_type:find("/elemStyle:first()"), "elemStyle", edge_list)
	table.insert(list_of_code, process_edges(edge_list))
	table.insert(list_of_code, string.format('if %s == nil then\n\tdiagram_type = %s:find("/graphDiagram/target_type")\nelse\n\tdiagram_type = %s\nend\n', diaram_type_code, utilities.make_obj_to_var(elem), diaram_type_code))
	table.insert(list_of_code, string.format('%s:link("graphDiagramType", diagram_type)\n', elem_type_code))
	local palette_elem_type = elem_type:find("/paletteElementType")
	if palette_elem_type:is_not_empty() then
		local palette_type_id = diagram_type:find("/paletteType"):id()
		table.insert(list_of_code, string.format('%s:link("paletteType", diagram_type:find("/paletteType"))\n', utilities.make_obj_to_var(palette_elem_type), diaram_type_code))
		table.insert(list_of_code, string.format('%s:attr({nr = lQuery(%s):find("/paletteElementType"):size()})\n', utilities.make_obj_to_var(palette_elem_type), palette_type_id))
	end
	local target_diagram = elem:find("/child")
	if target_diagram:is_not_empty() then
		table.insert(list_of_code, copy_target_diagram_type(target_diagram))
	end
	table.insert(list_of_code, string.format('if %s == nil then\n\t%send\n', utilities.make_obj_to_var(diagram_type), set_unique_names(elem)))
	return table.concat(list_of_code)
end

function process_specialization_element(elem)
	local super_type = elem:find("/end/target_type")
	local sub_type = elem:find("/start/target_type")
	local edge_list = {}
	add_edge(sub_type, super_type, "supertype", edge_list)
	return process_edges(edge_list)
end

function set_unique_names(elem)
	local list_of_code = {}
	local elem_type = elem:find("/target_type")
	local elem_type_name = elem_type:attr("id")
	local elem_type_code = utilities.make_obj_to_var(elem_type)
	table.insert(list_of_code, string.format('id = cu.generate_unique_id(%s:attr("id"), %s:find("/graphDiagramType"), "elemType")\n', elem_type_code, elem_type_code))	
	table.insert(list_of_code, string.format('%s:attr({id = id, caption = id})\n', elem_type_code))
	local compart = elem:find("/compartment:has(/compartType[id = 'AS#Name'])")
	if compart:is_not_empty() then
		table.insert(list_of_code, string.format('%s:attr({input = id, value = id})\n', utilities.make_obj_to_var(compart)))
	end
	local diagram = elem:find("/target")
	if diagram:is_not_empty() then
		table.insert(list_of_code, string.format('%s:attr({caption = id})\n', utilities.make_obj_to_var(diagram)))
	end
	local palette_elem_type = elem_type:find("/paletteElementType")
	if palette_elem_type:is_not_empty() then
		table.insert(list_of_code, string.format('%s:attr({id = id, caption = id})\n', utilities.make_obj_to_var(palette_elem_type)))
		table.insert(list_of_code, string.format('utilities.make_palette_element(%s)\n', utilities.make_obj_to_var(elem)))
		table.insert(list_of_code, string.format('utilities.execute_cmd("AfterConfigCmd", {graphDiagram = %s:find("/graphDiagram")})\n', utilities.make_obj_to_var(elem)))
	end
	return table.concat(list_of_code)
end

function process_specialization(diagram_type, edge_list)
	diagram_type:find("/elemType"):each(function(elem_type)
		elem_type:find("/supertype"):each(function(super_type)
			add_edge(elem_type, super_type, "supertype", edge_list)
		end)		
	end)
end

function add_edge(start_obj, end_obj, role, edge_list)
	table.insert(edge_list, {Start = utilities.make_obj_to_var(start_obj), End = utilities.make_obj_to_var(end_obj), Role = role})
end

function add_edge_to_diagram_type(obj, list_of_ids, role, export_file)
	export_file:write(utilities.make_obj_to_var(obj), ':link("', role, '", ', 'lQuery("GraphDiagramType[id = ', list_of_ids["graphDiagramType"],  ']")', ')\n')	
end 

function add_edge_to_element_type(obj, list_of_ids, role, export_file)
	export_file:write(utilities.make_obj_to_var(obj), ':link("', role, '", ', 'lQuery("GraphDiagramType[id = ', list_of_ids["graphDiagramType"], ']")', ':find("/elemType[id = ', list_of_ids["elemType"],  ']")', ')\n')
end 

function add_edge_to_compartment_type(obj, list_of_ids, role, list_of_elems)
	table.insert(list_of_elems["Edges"], {Start = utilities.make_obj_to_var(obj), Role = role, End = 'lQuery("GraphDiagramType[id = ' .. list_of_ids["graphDiagramType"] .. ']")' .. ':find("/elemType[id = ' .. list_of_ids["elemType"] .. ']")' .. ':find("/compartType[id = ' .. list_of_ids["compartType"] .. ']")'})
end 

function add_edge_by_table(obj, list_of_ids, role, list_of_elems)
	local count = 0
	local res = ""
	if utilities.is_table_empty(list_of_ids) == false then
		for _, id_table in ipairs(list_of_ids) do
			for index, id in pairs(id_table) do
				if index ~= "filter" then
					if count == 0 then
						res = res .. 'lQuery("' .. index .. '[id = ' .. id .. ']")'
					else
						res = res .. ':find("/' .. index .. '[id = ' .. id .. ']")'
					end
					local filter = id_table["filter"]
					if filter ~= nil then
						res = res .. ':filter("' .. filter .. '")'
					end
					count = count + 1
				end
			end
		end
		res = res
		table.insert(list_of_elems["Edges"], {Start = utilities.make_obj_to_var(obj), Role = role, End = res})
	end
end 

function process_edges(list)
	local list_of_code = {}
	for _, edge in ipairs(list) do
		table.insert(list_of_code, string.format('%s:link("%s", %s)\n', edge["Start"], edge["Role"], edge["End"]))
	end
	return table.concat(list_of_code)
end


--####################################################
function make_merge_code()
return [[

--migration


function process_elem_types(old_diagram_type, new_diagram_type)
	print("process elem types")
	local elem_type_list = {}
	new_diagram_type:find("/elemType"):each(function(elem_type)
		table.insert(elem_type_list, elem_type:attr("id"))
	end)
	for _, id in ipairs(elem_type_list) do
		local new_elem_type = new_diagram_type:find("/elemType[id = " .. id .. "]")
		local old_elem_type = old_diagram_type:find("/elemType[id = " .. id .. "]")
		local elems = old_elem_type:find("/element")
		old_elem_type:remove_link("element")
		new_elem_type:link("element", elems)
		set_obj_style(elems, "elemStyle", new_elem_type)
		
		process_compart_type(old_elem_type, new_elem_type)

		local old_target_diagram_type = old_elem_type:find("/target")
		if old_target_diagram_type:size() > 0 then
			print("old target diagram type")
			process_elem_types(old_target_diagram_type, new_elem_type:find("/target"))
		
			local presentation_diagram = old_target_diagram_type:find("/presentation"):log()
			utilities.close_diagram(presentation_diagram)
			presentation_diagram:delete()


			--old_target_diagram_type:find("/graphDiagram"):delete()
			c.delete_diagram_type(old_target_diagram_type)
		end
		
	--vajag jau esosu funkciju, kas izdzes visu apkartni
		c.delete_elem_type(old_elem_type)
		--old_elem_type:delete()
	end
	old_diagram_type:find("/elemType"):each(function(old_elem_type)
		--old_elem_type:find("/element"):delete()
		c.delete_elem_type(old_elem_type)
		--old_elem_type:delete()
	end)
	print("end process elem types")
end

function set_obj_style(objects, role, new_obj_type)
	objects:each(function(obj)
		local obj_style = obj:find("/" .. role)
		local new_obj_style = new_obj_type:find("/" .. role .. "[id = " .. obj_style:attr("id") .. "]")
		if new_obj_style:size() == 0 then
			new_obj_style = new_obj_type:find("/" .. role .. "[id = " .. new_obj_type:attr("id") .. "]")
		end
		obj:remove_link(role)
		obj:link(role, new_obj_style)
	end)
end



function process_compart_type(old_elem_type, new_elem_type)
--no new uztaisa tabulu, tad apstaiga old un parvelk linkus
--dzesot compartType vajag izmantot jau esosu funkciju, jo ir jadzes visa apkartne
	print("process compart type")
	local compart_type_table = {}
	make_sub_compart_type_table(new_elem_type, "/compartType", compart_type_table)
	traverse_compart_type_table(old_elem_type, new_elem_type, compart_type_table, "/compartType")
	
	print("end process compart type")
	
	
	--print(dumptable(compart_type_table))

end

function traverse_compart_type_table(old_elem_type, new_elem_type, compart_type_table, role)
print("traverse compart type table")
	for index, val in pairs(compart_type_table) do
		local old_compart_type = old_elem_type:find(role .. "[id = " .. index .. "]")
		local new_compart_type = new_elem_type:find(role .. "[id = " .. index .. "]")
		local comparts = old_compart_type:find("/compartment")
		old_compart_type:remove_link("compartment")
		new_compart_type:link("compartment", comparts)
		set_obj_style(comparts, "compartStyle", new_compart_type)
		if type(val) == "table" then
			traverse_compart_type_table(old_compart_type, new_compart_type, val, "/subCompartType")
		end
	end
print("end traverse compart type table")
end

function make_sub_compart_type_table(base_obj_type, role, compart_type_table)
	base_obj_type:find(role):each(function(compart_type)
		local sub_compart_type = compart_type:find("/subCompartType")
		if sub_compart_type:is_empty() then	
			compart_type_table[compart_type:attr("id")] = compart_type:attr("id")
		else
			compart_type_table[compart_type:attr("id")] = {}
			local tmp_table = compart_type_table[compart_type:attr("id")]
			make_sub_compart_type_table(compart_type, "/subCompartType", tmp_table)
		end
	end)
end

local diagram_type_list = {}
table.insert(diagram_type_list, "projectDiagram")
lQuery("GraphDiagram"):each(function(diagram)
	utilities.close_diagram(diagram)
end)
for _, id in ipairs(diagram_type_list) do
	local diagram_type_pair = lQuery("GraphDiagramType[id = '" .. id .. "']")
		local new_diagram_type = diagram_type_pair:filter("[isNew = true]")
		local old_diagram_type = diagram_type_pair:filter(":not([isNew = true])")
		local diagrams = old_diagram_type:find("/graphDiagram")
		old_diagram_type:remove_link("graphDiagram")
		new_diagram_type:link("graphDiagram", diagrams)
		process_elem_types(old_diagram_type, new_diagram_type)
		local presentation_diagram = old_diagram_type:find("/presentation"):delete()
		old_diagram_type:find("/palette"):delete()
		c.delete_diagram_type(old_diagram_type)
end
lQuery("GraphDiagramType"):attr({isNew = ""})
root.open_project_diagram()
utilities.execute_cmd("OkCmd")
]]

end

function test_compart_type_tree()
	process_compart_type(old_elem_type, utilities.active_elements():find("/target_type"))

end

function restore_links_to_domain_objects()
	rep = require("lua_raapi")
	repo = require("mii_rep_obj")

	local link_ids = {}
	for index, class in ipairs(repo.class_list()) do
		if class["name"] == "GraphDiagramType" or class["name"] == "CompartType" or class["name"] == "NodeType" or class["name"] == "EdgeType" or class["name"] == "PortType" then
			link_ids[class.name] = {}
                  local it = rep.getIteratorForAllOutgoingAssociationEnds(self.id)
                  local r = rep.resolveIteratorFirst(it)
                  local i = 0
                  while (r) do
                    i = i+1
                    link_ids[class.name][i] = r
                    r = rep.resolveIteratorNext(it)
                  end
                  rep.freeIterator(it)
		end
	end

	local default_roles = {
		  CompartType = {
		    choiceItem = true,
		    compartStyle = true,
		    compartment = true,
		    component = true,
		    elemType = true,
		    extension = true,
		    iRef = true,
		    item = true,
		    nodeParent = true,
		    parentCompartType = true,
		    presentation = true,
		    presentationElement = true,
		    propertyDiagram = true,
		    propertyRow = true,
		    propertyTab = true,
		    style = true,
		    subCompartType = true,
		    tag = true,
		    translet = true,
		    treeNode = true,
		    vTableRow = true
		  },
		  EdgeType = {
		    compartType = true,
		    eEnd = true,
		    eStart = true,
		    elemStyle = true,
		    element = true,
		    ["end"] = true,
		    extension = true,
		    graphDiagramType = true,
		    iRef = true,
		    item = true,
		    keyboardShortcut = true,
		    nodeParent = true,
		    paletteElement = true,
		    paletteElementType = true,
		    popUpDiagramType = true,
		    presentation = true,
		    presentationElement = true,
		    propertyDiagram = true,
		    start = true,
		    style = true,
		    subtype = true,
		    supertype = true,
		    tag = true,
		    target = true,
		    translet = true,
		    treeNode = true
		  },
		  GraphDiagramType = {
		    cKeyboardShortcut = true,
		    eKeyboardShortcut = true,
		    elemType = true,
		    extension = true,
		    graphDiagram = true,
		    graphDiagramStyle = true,
		    iRef = true,
		    item = true,
		    nodeParent = true,
		    palette = true,
		    paletteType = true,
		    presentation = true,
		    presentationElement = true,
		    rClickCollection = true,
		    rClickEmpty = true,
		    source = true,
		    style = true,
		    tag = true,
		    toolType = true,
		    toolbar = true,
		    toolbarType = true,
		    translet = true,
		    treeNode = true
		  },
		  NodeType = {
		    compartType = true,
		    componentType = true,
		    containerType = true,
		    eEnd = true,
		    eStart = true,
		    elemStyle = true,
		    element = true,
		    extension = true,
		    graphDiagramType = true,
		    iRef = true,
		    item = true,
		    keyboardShortcut = true,
		    nodeParent = true,
		    paletteElement = true,
		    paletteElementType = true,
		    popUpDiagramType = true,
		    portType = true,
		    presentation = true,
		    presentationElement = true,
		    propertyDiagram = true,
		    style = true,
		    subtype = true,
		    supertype = true,
		    tag = true,
		    target = true,
		    translet = true,
		    treeNode = true
		  },
		  PortType = {
		    compartType = true,
		    eEnd = true,
		    eStart = true,
		    elemStyle = true,
		    element = true,
		    extension = true,
		    graphDiagramType = true,
		    iRef = true,
		    item = true,
		    keyboardShortcut = true,
		    nodeParent = true,
		    nodeType = true,
		    paletteElement = true,
		    paletteElementType = true,
		    popUpDiagramType = true,
		    presentation = true,
		    presentationElement = true,
		    propertyDiagram = true,
		    style = true,
		    subtype = true,
		    supertype = true,
		    tag = true,
		    target = true,
		    translet = true,
		    treeNode = true
		  }
	}

	local roles = {}
	for class_name, links in pairs(link_ids) do
		roles[class_name] = {}
		for _, link in ipairs(links) do
			-- local role_attributes = rep.GetLinkTypeAttributes(link)
			-- local role_name = rep.GetTypeName(role_attributes.link_type_id)
                  local role_name = rep.getRoleName(link)
			if not(default_roles[class_name][role_name]) then
				roles[class_name][role_name] = true
			end
		end
	end

	return generate_code_to_domain_objects(roles)
end

function generate_code_to_domain_objects(roles)
	local code = {}
	for class_name, links in pairs(roles) do
		for role_name, _ in pairs(links) do
			lQuery(class_name):each(function(obj)
				local domain_obj = obj:find("/" .. role_name)
				if domain_obj:is_not_empty() then
					table.insert(code, string.format('%s:link("%s", lQuery(%s))\n', utilities.make_obj_to_var(obj), role_name, domain_obj:id()))
				end
			end)
		end
	end
	return table.concat(code)
end
