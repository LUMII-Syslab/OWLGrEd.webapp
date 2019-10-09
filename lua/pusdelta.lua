module(..., package.seeall)
require("utilities")
cu = require("configurator.configurator_utilities")
require("core")

--copy node funkcija
--pirmais arguments ir kopejama elementa tipa id, otrais arguments ir id diagrammas tipam, no kuras kope, tresais arguments ir id diagrammas tipam, uz kuru kope
function copy_node_type(elem_type_id, diagram_type_id, new_diagram_type_id)
	local elem_type = lQuery("GraphDiagramType[id = '" .. diagram_type_id .. "']/elemType[id = '" .. elem_type_id .. "']")
	local new_diagram_type = lQuery("GraphDiagramType[id = '" .. new_diagram_type_id .. "']")
	local new_elem_type = lQuery.create("NodeType"):copy_attrs_from(elem_type)
					:link("graphDiagramType", new_diagram_type)
	local prop_diagram = copy_prop_diagram_to_obj_type(elem_type, new_elem_type, "elemType")
	copy_element_type_features(elem_type, new_elem_type)
	copy_property_row_links(prop_diagram)
	local diagram = new_diagram_type:find("/presentation")
	local box_type = diagram:find("/graphDiagramType/elemType[id = 'box']")
	local node = core.add_node(box_type, diagram):link("target_type", new_elem_type)
							:remove_link("elemStyle")
							:link("elemStyle", new_elem_type:find("/elemStyle:first"))
	local compart_type = box_type:find("/compartType[id = 'AS#Name']")
	local compart = core.add_compart(box_type:find("/compartType[id = 'AS#Name']"), node, new_elem_type:attr("caption"))
	refresh_new_element(node, diagram, new_elem_type)
end

--copy edge funkcija
--pirmais arguments ir EdgeType, otrais arguments ir id diagrammai, no kuras kopes, tresais arguements ir id diagrammai, uz kuru kopes, ceturtais un piektais arguments ir id elementu tipiem, kurus linija savienos
function copy_edge_type(edge_type_id, diagram_type_id, new_diagram_type_id, start_type_id, end_type_id)
	local elem_type = lQuery("GraphDiagramType[id = '" .. diagram_type_id .. "']/elemType[id = '" .. edge_type_id .. "']")
	local new_diagram_type = lQuery("GraphDiagramType[id = '" .. new_diagram_type_id .. "']")
	local start_elem_type = new_diagram_type:find("/elemType[id = '" .. start_type_id .. "']")
	local end_elem_type = new_diagram_type:find("/elemType[id = '" .. end_type_id .. "']")
	local new_edge_type = lQuery.create("EdgeType"):copy_attrs_from(elem_type)
					:link("graphDiagramType", new_diagram_type)
					:link("pair", lQuery.create("Pair"):link("start", start_elem_type)
									:link("end", end_elem_type))
	local prop_diagram = copy_prop_diagram_to_obj_type(elem_type, new_edge_type, "elemType")
	copy_element_type_features(elem_type, new_edge_type)
	copy_property_row_links(prop_diagram)
	local diagram = new_diagram_type:find("/presentation")
	local edge = core.add_edge(diagram:find("/graphDiagramType/elemType[id = 'line']"), start_elem_type:find("/presentation"), end_elem_type:find("/presentation"), diagram)
												:link("target_type", new_edge_type)
												:remove_link("elemStyle")
												:link("elemStyle", new_edge_type:find("/elemStyle:first"))
	refresh_new_element(edge, diagram, new_edge_type)
end

--add comppartment funkcija
--pirmais argument ir id elementa tipam, pie kura vajag pielikt jaunu compartmenta tipu, otrais arguments ir tabula ar CompartType atributiem, tresais arguments ir augseja compartmenta tipa id,
--ceturtais arguments ir property row tips, piektais arguments ir id rindai, zem kuras property loga tiks ielikta jauna property row, sestais arguments ir taba id
function add_new_compartment(elem_type_id, compart_type_attr_table, top_compart_id, prop_type, top_prop_row_id, tab_name)
	local elem_type = utilities.current_diagram():find("/target_type/elemType[id = '" .. elem_type_id .. "']")
	if utilities.is_table_empty(compart_type_attr_table) == false then
		local compart_type = lQuery.create("CompartType", compart_type_attr_table)
		local prop_row = lQuery.create("PropertyRow", {id = compart_type_attr_table[id],
								rowType = prop_type,  
								isEditable = "true",
								isReadOnly = "false",
								isFirstRespondent = "false"
								})
								:link("compartType", compart_type)
		link_prop_row_to_tab(elem_type, top_prop_row_id, prop_row, tab_name)
		relink_compart_types_to_elem_type(elem_type, top_compart_id, compart_type)
	end
end

--paligfunkcijas
function relink_compart_types_to_elem_type(elem_type, top_compart_id, new_compart_type)
	elem_type:find("/compartType"):each(function(compart_type)
		elem_type:remove_link("compartType", compart_type)
			:link("compartType", compart_type)
		if compart_type:attr("id") == top_compart_id then
			elem_type:link("compartType", new_compart_type)
		end
	end)
end

function refresh_new_element(elem, diagram, elem_type)
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
	utilities.activate_element(elem)
	if elem_type:attr_e("openPropertiesOnElementCreate") == "true" then
		utilities.call_element_proc_thru_type(elem, "procProperties")
	end
end

function link_prop_row_to_tab(elem_type, top_prop_row_id, new_prop_row, tab_name)
	local tab = get_tab_by_id(elem_type, tab_name)
	tab:find("/propertyRow"):each(function(prop_row)
		tab:remove_link("propertyRow", prop_row)
			:link("propertyRow", prop_row)
		if prop_row:attr("id") == top_prop_row_id then
			tab:link("propertyRow", new_prop_row)
		end
	end)
end

function get_tab_by_id(elem_type, tab_name)
	local prop_dgr = elem_type:find("/propertyDiagram")
	local tab = prop_dgr:find("/propertyTab[caption = '" .. tab_name .. "']")
	if tab:is_not_empty() then
		return tab
	end
end

function copy_element_type_features(original_type, elem_type)
	original_type:find("/elemStyle"):each(function(elem_style)
		local new_elem_style = lQuery.create(utilities.get_class_name(elem_style)):copy_attrs_from(elem_style)
						:link("elemType", elem_type)
	end)
	local diagram_type = elem_type:find("/graphDiagramType")
	original_type:find("/containerType"):each(function(container_type)
		local tmp_elem_type = diagram_type:find("/elemType[id = '" .. container_type:attr("id") .. "']")
		if tmp_elem_type:is_not_empty() then
			elem_type:link("containerType", tmp_elem_type)
		end
	end)
	local palette_elem = original_type:find("/paletteElement")
	if palette_elem:is_not_empty() then
		local copied_palette_elem = lQuery.create(utilities.get_class_name(palette_elem)):copy_attrs_from(palette_elem)
										:link("elemType", elem_type)
		local target_diagram_type = elem_type:find("/graphDiagramType")
		local palette = target_diagram_type:find("/palette")
		if palette:is_empty() then
			palette = lQuery.create("Palette"):link("graphDiagramType", target_diagram_type)
		end
		copied_palette_elem:link("palette", palette)
	end
	local pop_up_diagram = original_type:find("/popUpDiagram")
	if pop_up_diagram:is_not_empty() then
		local new_pop_up_diagram = lQuery.create("PopUpDiagram"):link("elemType", elem_type)
		pop_up_diagram:find("/popUpElement"):each(function(pop_up_elem)
			lQuery.create("PopUpElement"):copy_attrs_from(pop_up_elem)
						     :link("popUpDiagram", new_pop_up_diagram)
		end)
	end
	original_type:find("/keyboardShortcut"):each(function(key_board_short_cut)
		lQuery.create("KeyboardShortcut"):copy_attrs_from(key_board_short_cut)
						 :link("elemType", elem_type)	
	end)
	copy_compart_types(original_type, elem_type)
end

function copy_compart_types(original_type, elem_type)
	original_type:find("/compartType"):each(function(compart_type)
		local new_compart_type = lQuery.create("CompartType"):copy_attrs_from(compart_type)
									:link("elemType", elem_type)
		compart_type:find("/compartStyle"):each(function(compart_style)
			lQuery.create("CompartStyle"):copy_attrs_from(compart_style)
							:link("compartType", new_compart_type)
		end)
		copy_prop_diagram_to_obj_type(compart_type, new_compart_type, "compartType")
		copy_compart_type_row(compart_type, new_compart_type)
		copy_choice_item(compart_type, new_compart_type)
		copy_sub_compart_types(compart_type, new_compart_type)
	end)
end

function copy_choice_item(old_compart_type, new_compart_type)
	old_compart_type:find("/choiceItem"):each(function(choice_item)
		local new_choice_item = lQuery.create("ChoiceItem"):copy_attrs_from(choice_item)
									:link("compartType", new_compart_type)
		local compart_style = choice_item:find("/compartStyleByChoiceItem")
		if compart_style:is_not_empty() then
			new_compart_type:find("/compartStyle[id = '" .. compart_style:attr("id") .. "']"):link("choiceItem", choice_item)
		end
		local elem_style = choice_item:find("/elemStyleByChoiceItem")
		if elem_style:is_not_empty() then
			cu.get_elem_type_from_compartment(new_compart_type):find("/elemStyle[id = '" .. elem_style:attr("id") .. "']"):link("choiceItem", choice_item)
		end
		local old_notation = choice_item:find("/notation")
		if old_notation:is_not_empty() then
			lQuery.create("Notation"):copy_attrs_from(old_notation)
						:link("choiceItem", choice_item)
		end
		local tag_compart_type = choice_item:find("/tag")
		if tag_compart_type:is_not_empty() then
			local tag_prop_row = tag_compart_type:find("/propertyRow")
			local compart_style = tag_compart_type:find("/compartStyle")
			lQuery.create("CompartType"):copy_attrs_from(tag_compart_type)
							:link("stereotype", new_choice_item)
							:link("propertyRow", lQuery.create("PropertyRow"):copy_attrs_from(tag_prop_row))
							:link("compartStyle", lQuery.create("CompartStyle"):copy_attrs_from(compart_style))
		end
	end)
end

function copy_sub_compart_types(compart_type, new_compart_type)
	compart_type:find("/subCompartType"):each(function(sub_compart_type)
		local new_sub_compart_type = lQuery.create("CompartType"):copy_attrs_from(sub_compart_type)
									:link("parentCompartType", new_compart_type)
		copy_prop_diagram_to_obj_type(sub_compart_type, new_sub_compart_type, "compartType")
		copy_compart_type_row(sub_compart_type, new_sub_compart_type)
		copy_choice_item(sub_compart_type, new_sub_compart_type)
		copy_sub_compart_types(sub_compart_type, new_sub_compart_type)	
	end)
end

function copy_prop_diagram_to_obj_type(old_type, obj_type, role)
	local prop_diagram = old_type:find("/propertyDiagram")
	if prop_diagram:is_not_empty() then
		local new_prop_diagram = lQuery.create("PropertyDiagram"):copy_attrs_from(prop_diagram)
									:link(role, obj_type)
									:link("original", prop_diagram)
		copy_prop_row_event_handler(prop_diagram, new_prop_diagram)
	end
	return  prop_diagram
end

function copy_compart_type_row(compart_type, new_compart_type)
	compart_type:find("/propertyRow"):each(function(prop_row)
		local new_prop_row = lQuery.create("PropertyRow"):copy_attrs_from(prop_row)
								:link("compartType", new_compart_type)
								:link("original", prop_row)
		copy_prop_row_event_handler(prop_row, new_prop_row)
	end)
end

function copy_property_row_links(prop_diagram)
	local new_prop_diagram = prop_diagram:find("/copy")
	if new_prop_diagram:is_not_empty() then
		prop_diagram:find("/propertyTab"):each(function(tab)
			local new_tab = lQuery.create("PropertyTab"):copy_attrs_from(tab)
									:link("propertyDiagram", new_prop_diagram)
			copy_prop_row_event_handler(tab, new_tab)
			tab:find("/propertyRow"):each(function(prop_row)
				copy_property_row(prop_row, new_tab, "propertyTab")
			end)
		end)
		prop_diagram:find("/propertyRow"):each(function(prop_row)
			copy_property_row(prop_row, new_prop_diagram, "propertyDiagram")
		end)
		prop_diagram:remove_link("copy", new_prop_diagram)
	end
end

function copy_property_row(prop_row, new_parent, role)
	local new_prop_row = prop_row:find("/copy"):link(role, new_parent)
							:remove_link("original", prop_row)
	local called_diagram = prop_row:find("/calledDiagram")
	if called_diagram:is_not_empty() then
		lQuery.create("PropertyDiagram"):copy_attrs_from(called_diagram)
						:link("calledPropertyRow", new_prop_row)
						:link("original", called_diagram)
		copy_property_row_links(called_diagram)
	end
end

function copy_prop_row_event_handler(prop_row, new_prop_row)
	local handler = prop_row:find("/propertyEventHandler")
	if handler:is_not_empty() then
		local new_handler = lQuery.create("PropertyEventHandler"):copy_attrs_from(handler):link("propertyElement", new_prop_row)
	end
end

function copy_property_row_links(prop_diagram)
	local new_prop_diagram = prop_diagram:find("/copy")
	if new_prop_diagram:is_not_empty() then
		prop_diagram:find("/propertyTab"):each(function(tab)
			local new_tab = lQuery.create("PropertyTab"):copy_attrs_from(tab)
									:link("propertyDiagram", new_prop_diagram)
			copy_prop_row_event_handler(tab, new_tab)
			tab:find("/propertyRow"):each(function(prop_row)
				copy_property_row(prop_row, new_tab, "propertyTab")
			end)
		end)
		prop_diagram:find("/propertyRow"):each(function(prop_row)
			copy_property_row(prop_row, new_prop_diagram, "propertyDiagram")
		end)
		prop_diagram:remove_link("copy", new_prop_diagram)
	end
end

function copy_property_row(prop_row, new_parent, role)
	local new_prop_row = prop_row:find("/copy"):link(role, new_parent)
							:remove_link("original", prop_row)
	local called_diagram = prop_row:find("/calledDiagram")
	if called_diagram:is_not_empty() then
		lQuery.create("PropertyDiagram"):copy_attrs_from(called_diagram)
						:link("calledPropertyRow", new_prop_row)
						:link("original", called_diagram)
		copy_property_row_links(called_diagram)
	end
end

function copy_prop_row_event_handler(prop_row, new_prop_row)
	local handler = prop_row:find("/propertyEventHandler")
	if handler:is_not_empty() then
		local new_handler = lQuery.create("PropertyEventHandler"):copy_attrs_from(handler):link("propertyElement", new_prop_row)
	end
end
