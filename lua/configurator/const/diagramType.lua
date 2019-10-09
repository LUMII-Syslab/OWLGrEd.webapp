module(..., package.seeall)

require("core")
require("utilities")
require("lQuery")
cu = require("configurator.const.const_utilities")
u = require("configurator.configurator_utilities")
--Specification Diagram and Diagram Type Diagram

function diagramType_const(box_function, diagram_type_id, diagram_type_name)
--diagram
	local diagram_type, palette_type = add_diagramType_diagram(diagram_type_id, diagram_type_name)
--boxes
	local super_box = diagramType_diagram_superBox(diagram_type, palette_type)	
	local box = box_function(diagram_type, palette_type):link("supertype", super_box)
	--local free_box = diagramType_diagram_freeBox(diagram_type, palette_type):link("supertype", super_box)
	local pin = diagramType_diagram_pin(diagram_type, palette_type):link("supertype", super_box):link("nodeType", box)
--lines
	local line = diagramType_diagram_line(diagram_type, palette_type):link("supertype", super_box)
		cu.add_pair(line, super_box, super_box, "BiDirectional")
	--local free_line = diagramType_diagram_free_line(diagram_type, palette_type):link("supertype", super_box)
	local specialization = diagramType_diagram_specialization_line(diagram_type, palette_type)
		cu.add_pair(specialization, super_box, super_box, "BiDirectional")
--translets
	cu.add_translet_to_obj_type(diagram_type, "procCopied", "configurator.configurator.copy_target_diagram")

return diagram_type
end

function add_diagramType_diagram(id, caption)	
	local diagram_type = cu.add_graph_diagram_type(id, caption)
	local empty_popUpDiagram = lQuery.create("PopUpDiagramType", {eType = diagram_type})
		cu.add_PopUpElementType(empty_popUpDiagram, "Paste", "interpreter.CutCopyPaste.Paste", 1)
		cu.add_PopUpElementType(empty_popUpDiagram, "Add ToolBar", "configurator.configurator.add_diagram_toolbar", 2)
		cu.add_PopUpElementType(empty_popUpDiagram, "Add Context Menu", "configurator.configurator.add_diagram_popUp", 3)
		cu.add_PopUpElementType(empty_popUpDiagram, "Add Key Shortcuts", "configurator.configurator.add_diagram_key_shortcuts", 4)
		cu.add_PopUpElementType(empty_popUpDiagram, "Diagram Style", "configurator.configurator.diagram_style", 5)
		cu.add_PopUpElementType(empty_popUpDiagram, "Generate Instances", "configurator.configurator.generate_instances", 6)
		cu.add_PopUpElementType(empty_popUpDiagram, "Diagram Translets", "configurator.configurator.add_diagram_translets", 13)		
		--cu.add_PopUpElementType(empty_popUpDiagram, "Execute Script", "configurator.configurator.generate_script_dialog", 7)
		--cu.add_PopUpElementType(empty_popUpDiagram, "Edit Interpreter", "configurator.configurator.edit_head_engine", 8)
		--cu.add_PopUpElementType(empty_popUpDiagram, "Edit Project Behaviour", "configurator.configurator.edit_project_object", 9)
		--cu.add_PopUpElementType(empty_popUpDiagram, "Edit Patterns", "configurator.configurator.edit_patterns", 10)
		--cu.add_PopUpElementType(empty_popUpDiagram, "Dump MM", "configurator.delta.dump_type_MM", 11)
		--cu.add_PopUpElementType(empty_popUpDiagram, "Visualize MM", "configurator.configurator.make_repozitory_class_diagram", 12)


	local collection_popUpDiagram = lQuery.create("PopUpDiagramType", {cType = diagram_type})
		cu.add_PopUpElementType(collection_popUpDiagram, "Cut", "Cut", 1)
		cu.add_PopUpElementType(collection_popUpDiagram, "Copy", "Copy", 2)
		cu.add_PopUpElementType(collection_popUpDiagram, "Delete", "Delete", 3)
		--cu.add_PopUpElementType(collection_popUpDiagram, "Generate Instances", "configurator.configurator.generate_instances", 4)
		--cu.add_PopUpElementType(collection_popUpDiagram, "Add Pattern", "configurator.configurator.add_pattern", 5)
		cu.add_PopUpElementType(collection_popUpDiagram, "Reroute Line", "Reroute", 6)

	cu.default_key_shortcuts(diagram_type, "cType")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl V", "Paste")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl T", "configurator.popup.add_diagram_toolbar")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl P", "configurator.popup.add_diagram_popUp")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl K", "configurator.popup.add_diagram_key_shortcuts")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl D", "configurator.popup.diagram_style")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl G", "configurator.popup.generate_instances")
	cu.add_key_shortcut(diagram_type, "eType", "E", "configurator.popup.generate_script_dialog")
	
	local toolbar_type = lQuery.create("ToolbarType", {graphDiagramType = diagram_type})
		cu.add_toolbar_element_type(toolbar_type, "New Version Created", "configurator.toolbar.new_version", 1, "Version.BMP")
		cu.add_toolbar_element_type(toolbar_type, "Execute Migration", "configurator.toolbar.execute_migration", 2, "Migration.BMP")
		cu.add_toolbar_element_type(toolbar_type, "Create Domain", "configurator.toolbar.create_domain", 3, "domain.BMP")	

		cu.add_toolbar_element_type(toolbar_type, "Visualize MM", "configurator.toolbar.make_repozitory_class_diagram", 4, "VisualizeMM.BMP")
		cu.add_toolbar_element_type(toolbar_type, "Project Translets", "configurator.toolbar.edit_project_object", 5, "ProjectTranslets.bmp")
		cu.add_toolbar_element_type(toolbar_type, "Graph Diagram Engine", "configurator.toolbar.edit_head_engine", 6, "graphDiagramEngine.bmp")
		cu.add_toolbar_element_type(toolbar_type, "Tree Engine", "configurator.toolbar.edit_tree_engine", 7, "tree.bmp")	
	
	local palette_type = lQuery.create("PaletteType", {graphDiagramType = diagram_type})
return diagram_type, palette_type
end

function diagramType_diagram_box(diagram_type, palette_type)
	local node_type = lQuery.create("NodeType", {
		id = "Box",
		caption = "Box",
		--procCreateElementDomain = "configurator.const.const_utilities.add_type",
		openPropertiesOnElementCreate = "true",
		--l2ClickEvent = "configurator.configurator.configurator_dialog",
		--procProperties = "configurator.configurator.configurator_dialog",
		--procCopied = "configurator.configurator.configurator_elem_copied",
		--procPasted = "configurator.configurator.configurator_elem_pasted",
		--procClipboardCleared = "configurator.configurator.delete_elem_type_from_configurator",
		--procDeleteElementDomain = "configurator.configurator.delete_elem_type_from_configurator",
		graphDiagramType = diagram_type,
		paletteElementType = lQuery.create("PaletteElementType", {id = "Box", caption = "Box", nr = 1, picture = "Box.bmp", paletteType = palette_type})
	})
	cu.add_translet_to_obj_type(node_type, "procCreateElementDomain", "configurator.const.const_utilities.add_type")
	cu.add_translet_to_obj_type(node_type, "l2ClickEvent", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(node_type, "procProperties", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(node_type, "procCopied", "configurator.configurator.configurator_elem_copied")
	--cu.add_translet_to_obj_type(node_type, "procPasted", "configurator.configurator.configurator_elem_pasted")
	--cu.add_translet_to_obj_type(node_type, "procPasted", "")
	--cu.add_translet_to_obj_type(node_type, "procClipboardCleared", "configurator.configurator.delete_elem_type_from_configurator")
	cu.add_translet_to_obj_type(node_type, "procDeleteElementDomain", "configurator.configurator.delete_elem_type_from_configurator")

	local node_style = u.add_default_configurator_node("Box", "Box", 12419151):link("elemType", node_type)
	box_type_additions(cu.default_configurator_box_popUp, node_type)
return node_type
end

function diagramType_diagram_freeBox(diagram_type, palette_type)
	local node_type = lQuery.create("FreeBoxType", {
		id = "FreeBox",
		caption = "FreeBox",
		--procCreateElementDomain = "configurator.const.const_utilities.add_type",
		openPropertiesOnElementCreate = "true",
		--l2ClickEvent = "configurator.configurator.configurator_dialog",
		--procProperties = "configurator.configurator.configurator_dialog",
		--procCopied = "configurator.configurator.configurator_elem_copied",
		--procPasted = "configurator.configurator.configurator_elem_pasted",
		--procClipboardCleared = "configurator.configurator.delete_elem_type_from_configurator",
		--procDeleteElementDomain = "configurator.configurator.delete_elem_type_from_configurator",
		graphDiagramType = diagram_type,
		paletteElementType = lQuery.create("PaletteElementType", {id = "FreeBox", caption = "FreeBox", nr = 4, picture = "FreeBox.BMP", paletteType = palette_type})
	})
	cu.add_translet_to_obj_type(node_type, "procCreateElementDomain", "configurator.const.const_utilities.add_type")
	cu.add_translet_to_obj_type(node_type, "l2ClickEvent", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(node_type, "procProperties", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(node_type, "procCopied", "configurator.configurator.configurator_elem_copied")
	cu.add_translet_to_obj_type(node_type, "procPasted", "configurator.configurator.configurator_elem_pasted")
	cu.add_translet_to_obj_type(node_type, "procClipboardCleared", "configurator.configurator.delete_elem_type_from_configurator")
	cu.add_translet_to_obj_type(node_type, "procDeleteElementDomain", "configurator.configurator.delete_elem_type_from_configurator")

	local node_style = u.add_default_configurator_node("FreeBox", "FreeBox", 13020235, 9534773):link("elemType", node_type)
	box_type_additions(cu.default_configurator_free_box_popUp, node_type)
return node_type
end

function diagramType_diagram_pin(diagram_type, palette_type)
	local node_type = lQuery.create("PortType", {
		id = "Pin",
		caption = "Pin",
		--procCreateElementDomain = "configurator.const.const_utilities.add_type",
		openPropertiesOnElementCreate = "true",
		--l2ClickEvent = "configurator.configurator.configurator_dialog",
		--procProperties = "configurator.configurator.configurator_dialog",
		--procCopied = "configurator.configurator.configurator_elem_copied",
		--procPasted = "configurator.configurator.configurator_elem_pasted",
		--procClipboardCleared = "configurator.configurator.delete_elem_type_from_configurator",
		--procDeleteElementDomain = "configurator.configurator.delete_elem_type_from_configurator",
		graphDiagramType = diagram_type,
		paletteElementType = lQuery.create("PaletteElementType", {id = "Pin", caption = "Pin", nr = 3, picture = "Pin.bmp", paletteType = palette_type})
	})
	
	cu.add_translet_to_obj_type(node_type, "procCreateElementDomain", "configurator.const.const_utilities.add_type")
	cu.add_translet_to_obj_type(node_type, "l2ClickEvent", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(node_type, "procProperties", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(node_type, "procCopied", "configurator.configurator.configurator_elem_copied")
	cu.add_translet_to_obj_type(node_type, "procPasted", "configurator.configurator.configurator_elem_pasted")
	cu.add_translet_to_obj_type(node_type, "procClipboardCleared", "configurator.configurator.delete_elem_type_from_configurator")
	cu.add_translet_to_obj_type(node_type, "procDeleteElementDomain", "configurator.configurator.delete_elem_type_from_configurator")

	local node_style = u.add_default_configurator_port("Pin", "Pin", 12419151):link("elemType", node_type)
	cu.default_configurator_port_popUp(node_type, "elemType")
	cu.default_configurator_key_line_shortcuts(node_type, "elemType")
return node_type
end

function diagramType_diagram_superBox(diagram_type, palette_type)
	local node_type = lQuery.create("NodeType", {
		id = "SuperBox",
		caption = "SuperBox",
		graphDiagramType = diagram_type
	})
	local node_style = u.add_default_configurator_node("SuperBox", "SuperBox", 12419151):link("elemType", node_type)
return node_type
end

--Lines
function diagramType_diagram_line(diagram_type, palette_type)
	local edge_type = lQuery.create("EdgeType", {
		id = "Line",
		caption = "Line",
		openPropertiesOnElementCreate = true,
		graphDiagramType = diagram_type,
		paletteElementType = lQuery.create("PaletteElementType", {id = "Line", caption = "Line", nr = 2, picture = "Line.BMP", paletteType = palette_type})
	})
	cu.add_translet_to_obj_type(edge_type, "procCreateElementDomain", "configurator.const.const_utilities.add_type")
	cu.add_translet_to_obj_type(edge_type, "l2ClickEvent", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(edge_type, "procProperties", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(edge_type, "procMoveLine", "configurator.configurator.move_line_type")
	cu.add_translet_to_obj_type(edge_type, "procCopied", "configurator.configurator.configurator_elem_copied")
	cu.add_translet_to_obj_type(edge_type, "procPasted", "configurator.configurator.configurator_elem_pasted")
	cu.add_translet_to_obj_type(edge_type, "procClipboardCleared", "configurator.configurator.delete_elem_type_from_configurator")
	cu.add_translet_to_obj_type(edge_type, "procDeleteElementDomain", "configurator.configurator.delete_elem_type_from_configurator")
	local list_of_line_attributes = {
		lineColor = 9067831,
		lineWidth = 3,
		endBkgColor = 9067831,
		endLineColor = 9067831,
	}
	local edge_style = u.add_default_configurator_edge_style("Line", "Line", list_of_line_attributes):link("elemType", edge_type)
	cu.default_configurator_line_popUp(edge_type, "elemType")
	cu.default_configurator_key_line_shortcuts(edge_type, "elemType")
	local _, name_compart_style = cu.add_compart(edge_type, "AS#Name")
	name_compart_style:attr({fontColor = 0, fontSize = 9, adjustment = 24})
return edge_type
end

function diagramType_diagram_free_line(diagram_type, palette_type)
	local edge_type = lQuery.create("FreeLineType", {
		id = "FreeLine",
		caption = "FreeLine",
		openPropertiesOnElementCreate = true,
		graphDiagramType = diagram_type,
		paletteElementType = lQuery.create("PaletteElementType", {id = "FreeLine", caption = "FreeLine", nr = 5, picture = "Specialization.bmp", paletteType = palette_type})
	})
	cu.add_translet_to_obj_type(edge_type, "procCreateElementDomain", "configurator.const.const_utilities.add_type")
	cu.add_translet_to_obj_type(edge_type, "l2ClickEvent", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(edge_type, "procProperties", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(edge_type, "procCopied", "configurator.configurator.configurator_elem_copied")
	cu.add_translet_to_obj_type(edge_type, "procDeleteElementDomain", "configurator.configurator.delete_elem_type_from_configurator")
	local edge_style = u.add_default_configurator_edge_style("FreeLine", "FreeLine", 15790320, 0):link("elemType", edge_type)
		edge_style:attr({lineType = 16})
	cu.default_configurator_free_line_popUp(edge_type, "elemType")
	cu.default_configurator_key_shortcuts(edge_type, "elemType")
return edge_type
end

function diagramType_diagram_specialization_line(diagram_type, palette_type)
	local edge_type = lQuery.create("EdgeType", {
		id = "Specialization",
		caption = "Specialization",
		graphDiagramType = diagram_type,
		paletteElementType = lQuery.create("PaletteElementType", {id = "Specialization", caption = "Specialization", nr = 6, picture = "Specialization.bmp", paletteType = palette_type})
	})
	cu.add_translet_to_obj_type(edge_type, "procCreateElementDomain", "configurator.const.const_utilities.add_specialization")
	cu.add_translet_to_obj_type(edge_type, "procDeleteElementDomain", "configurator.configurator.delete_specialization")
	cu.add_translet_to_obj_type(edge_type, "procMoveLine", "configurator.configurator.move_specialization")
	cu.add_translet_to_obj_type(edge_type, "procCopied", "configurator.configurator.configurator_elem_copied")
	local list_of_line_attributes = {
		lineColor = 10498160,
		lineWidth = 3,
		endShapeCode = 11,
		endLineColor = 10498160,
		endLineWidth = 3,
		endBkgColor = 10498160
	}
	local edge_style = u.add_default_configurator_edge_style("Specialization", "Specialization", list_of_line_attributes):link("elemType", edge_type)
	local pop_diagram_type = lQuery.create("PopUpDiagramType"):link("elemType", edge_type)
		cu.add_PopUpElementType(pop_diagram_type, "Delete", "Delete.Delete", 1)
		cu.add_PopUpElementType(pop_diagram_type, "Reroute Line", "utilities.Reroute", 2)
		cu.add_PopUpElementType(pop_diagram_type, "Symbol Style", "utilities.symbol_style", 3)
	cu.default_key_line_shortcuts(edge_type, "elemType")
return edge_type
end

function specification_diagram_box(diagram_type, palette_type)
	local node_type = lQuery.create("NodeType", {
		id = "Box",
		caption = "Box",
		--procCreateElementDomain = "configurator.const.const_utilities.add_type_seed",
		openPropertiesOnElementCreate = "true",
		--l2ClickEvent = "utilities.navigate",
		--procProperties = "configurator.configurator.configurator_dialog",
		--procCopied = "configurator.configurator.configurator_seed_copied",
		--procPasted = "configurator.configurator.configurator_seed_pasted",
		--procClipboardCleared = "configurator.configurator.delete_elem_type_from_configurator",
		--procDeleteElementDomain = "configurator.configurator.delete_elem_type_from_configurator",
		graphDiagramType = diagram_type,
		paletteElementType = lQuery.create("PaletteElementType", {id = "Box", caption = "Box", nr = 1, picture = "Box.bmp", paletteType = palette_type})
	})
	cu.add_translet_to_obj_type(node_type, "procCreateElementDomain", "configurator.const.const_utilities.add_type_seed")
	cu.add_translet_to_obj_type(node_type, "l2ClickEvent", "utilities.navigate_or_properties")
	cu.add_translet_to_obj_type(node_type, "procProperties", "configurator.configurator.configurator_dialog")
	cu.add_translet_to_obj_type(node_type, "procCopied", "configurator.configurator.configurator_seed_copied")
	cu.add_translet_to_obj_type(node_type, "procDeleteElementDomain", "configurator.configurator.delete_elem_type_from_configurator")

	local node_style = u.add_default_configurator_node("Box", "Box", 12419151):link("elemType", node_type)
--	cu.add_translet_to_obj_type(node_type, "procNewElement", "configurator.configurator.copy_name_compartment")
	box_type_additions(cu.default_configurator_box_popUp, node_type)
return node_type
end

function box_type_additions(pop_up_function_name, node_type)
--compartTypes
	local name_compart_type, name_compart_style = cu.add_compart(node_type, "AS#Name")

	--local _, attr_compart_style = cu.add_compart(node_type, "AS#Attributes")
	name_compart_style:attr({adornment = 0})
	--attr_compart_style:delete()
--key strokes
	cu.default_configurator_key_shortcuts(node_type, "elemType")
	--cu.add_key_shortcut(node_type, "elemType", "Enter", "Properties.Properties")
--popUp
	local popUp = pop_up_function_name(node_type, "elemType")
end

--Project Diagram
function project_diagram_const()
	local diagram_type = cu.add_graph_diagram_type("projectDiagram", "", true)
		cu.add_translet_to_obj_type(diagram_type, "procDynamicPopUpE", "interpreter.RClick.project_diagram_pop_up")
	
	--add_project_diagram_pop_up
	local collection_popUpDiagram = lQuery.create("PopUpDiagramType", {cType = diagram_type})
		cu.add_cut_copy_delete_popUp(collection_popUpDiagram)
		
	cu.default_key_shortcuts(diagram_type, "cType")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl V", "interpreter.CutCopyPaste.Paste")
return diagram_type
end

--diagram for MM instances
function instance_diagram_const()
	local diagram_type = cu.add_graph_diagram_type("MMInstances", "MMInstances")
	utilities.add_tree_node_tag(diagram_type)
	return diagram_type
end

function make_instance_diagram_type(diagram_type)
--palette
	local palette_type = lQuery.create("PaletteType", {graphDiagramType = diagram_type})

--Instance
	local node_type = lQuery.create("NodeType", {id = "Instance", caption = "Instance", openPropertiesOnElementCreate = "true"}):link("graphDiagramType", diagram_type)
	local node_style = u.add_default_configurator_node("Instance", "Instance", 13020490, 9008690):link("elemType", node_type)
		local name_compart, name_compart_style = cu.add_compart(node_type, "Name")
			name_compart:attr({adornmentPrefix = ":"})
			name_compart_style:attr({adornment = 9, fontColor = 0})
		local value_compart, value_compart_style = cu.add_compart(node_type, "Value")
			value_compart_style:attr({alignment = 0, fontSize = 9, fontColor = 0})
	cu.default_box_popUp(node_type, "elemType")
	cu.default_key_shortcuts(node_type, "elemType")
	make_property_diagram(node_type, name_compart, value_compart)
	cu.add_translet_to_obj_type(node_type, "l2ClickEvent", "interpreter.Properties.Properties")
	cu.add_translet_to_obj_type(node_type, "procProperties", "interpreter.Properties.Properties")
	lQuery.create("PaletteElementType", {id = "Box", caption = "Box", nr = 1, picture = "Instance.bmp", paletteType = palette_type, elemType = node_type})

--Link
	local link_style = u.add_default_edge_style("Link", "Link"):attr({startShapeCode = 1, endShapeCode = 1, lineColor = 9008690})
	local link = lQuery.create("EdgeType", {id = "Link", caption = "Link"})
						:link("graphDiagramType", diagram_type)
						:link("elemStyle", link_style)
		cu.add_pair(link, node_type, node_type, "BiDirectional")
		local direct_role_compart, direct_role_compart_style = cu.add_compart(link, "DirectRole")
			direct_role_compart_style:attr({adjustment = 6, fontColor = 0, fontSize = 9, fontStyle = 0})
		local inverse_role_compart, inverse_direct_role_compart_style = cu.add_compart(link, "InverseRole")
			inverse_direct_role_compart_style:attr({adjustment = 5, fontColor = 0, fontSize = 9, fontStyle = 0})
	cu.default_box_popUp(link, "elemType")
	cu.default_key_shortcuts(link, "elemType")
	make_property_diagram_for_link(link, direct_role_compart, inverse_role_compart)
	cu.add_translet_to_obj_type(link, "l2ClickEvent", "interpreter.Properties.Properties")
	cu.add_translet_to_obj_type(link, "procProperties", "interpreter.Properties.Properties")
	lQuery.create("PaletteElementType", {id = "Link", caption = "Link", nr = 2, picture = "Link.bmp", paletteType = palette_type, elemType = link})

--Composition
	local composition_style = u.add_default_edge_style("Composition", "Composition"):attr({startShapeCode = 1, endShapeCode = 10, lineColor = 9008690, endLineColor = 9008690, endBkgColor = 9008690})
	local composition = lQuery.create("EdgeType", {id = "Composition", caption = "Composition"})
						:link("graphDiagramType", diagram_type)
						:link("elemStyle", composition_style)
		cu.add_pair(composition, node_type, node_type, "BiDirectional")
		local direct_role_compart, direct_role_compart_style = cu.add_compart(composition, "DirectRole")
			direct_role_compart_style:attr({adjustment = 6, fontColor = 0, fontSize = 9, fontStyle = 0})
		local inverse_role_compart, inverse_direct_role_compart_style = cu.add_compart(composition, "InverseRole")
			inverse_direct_role_compart_style:attr({adjustment = 5, fontColor = 0, fontSize = 9, fontStyle = 0})
	cu.default_box_popUp(composition, "elemType")
	cu.default_key_shortcuts(composition, "elemType")
	make_property_diagram_for_link(composition, direct_role_compart, inverse_role_compart)
	cu.add_translet_to_obj_type(composition, "l2ClickEvent", "interpreter.Properties.Properties")
	cu.add_translet_to_obj_type(composition, "procProperties", "interpreter.Properties.Properties")
	lQuery.create("PaletteElementType", {id = "Composition", caption = "Composition", nr = 3, picture = "Composition_instance.bmp", paletteType = palette_type, elemType = composition})

--diagram type features
	local collection_popUpDiagram = lQuery.create("PopUpDiagramType", {id = "collection", cType = diagram_type})
		cu.add_cut_copy_delete_popUp(collection_popUpDiagram)
	local empty_popUpDiagram = lQuery.create("PopUpDiagramType", {id = "empty", eType = diagram_type})
		cu.add_PopUpElementType(empty_popUpDiagram, "Delete Diagram", "interpreter.Delete.delete_current_diagram", 1)
		cu.add_PopUpElementType(empty_popUpDiagram, "Diagram Name", "configurator.configurator.set_model_diagram_name", 2)
	cu.default_key_shortcuts(diagram_type, "cType")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl V", "interpreter.CutCopyPaste.Paste")
	cu.add_key_shortcut(diagram_type, "eType", "F", "find.show_window")

end

--repository class diagram type
function repository_diagram_const()
	local diagram_type = cu.add_graph_diagram_type("Repository", "Repository")
	utilities.add_tree_node_tag(diagram_type)
	return diagram_type
end

function make_repository_diagram_type(diagram_type)
--palette
	local palette_type = lQuery.create("PaletteType", {graphDiagramType = diagram_type})

--class
	local node_type = lQuery.create("NodeType", {id = "Class", caption = "Class", openPropertiesOnElementCreate = "true"}):link("graphDiagramType", diagram_type)
	local node_style = u.add_default_configurator_node("Class", "Class", 5880731, 4163953):link("elemType", node_type)
		local name_compart, name_compart_style = cu.add_compart(node_type, "Name")
			name_compart_style:attr({adornment = 9, fontColor = 0})
		local value_compart, value_compart_style = cu.add_compart(node_type, "Value")
			value_compart_style:attr({alignment = 0, fontSize = 9, fontColor = 0})
	cu.default_box_popUp(node_type, "elemType")
	cu.default_key_shortcuts(node_type, "elemType")
	make_property_diagram(node_type, name_compart, value_compart)
	cu.add_translet_to_obj_type(node_type, "l2ClickEvent", "interpreter.Properties.Properties")
	cu.add_translet_to_obj_type(node_type, "procProperties", "interpreter.Properties.Properties")
	lQuery.create("PaletteElementType", {id = "Box", caption = "Box", nr = 1, picture = "Class.bmp", paletteType = palette_type, elemType = node_type})

--association
	local link_style = u.add_default_configurator_edge_style("Association", "Association", {startShapeCode = 1, endShapeCode = 1, lineColor = 4163953})
	local link = lQuery.create("EdgeType", {id = "Association", caption = "Association", openPropertiesOnElementCreate = "true"})
						:link("graphDiagramType", diagram_type)
						:link("elemStyle", link_style)
		cu.add_pair(link, node_type, node_type, "bidirectional")
		
		local direct_role_compart, direct_role_compart_style = cu.add_compart(link, "DirectRole")
			direct_role_compart_style:attr({adjustment = 6, fontColor = 0, fontSize = 9, fontStyle = 0})
		local inverse_role_compart, inverse_direct_role_compart_style = cu.add_compart(link, "InverseRole")
			inverse_direct_role_compart_style:attr({adjustment = 5, fontColor = 0, fontSize = 9, fontStyle = 0})
		local direct_cardinality_compart, direct_cardinality_compart_style = cu.add_compart(link, "DirectCardinality")
			direct_cardinality_compart_style:attr({adjustment = 10, fontColor = 0, fontSize = 9, fontStyle = 0})
		local inverse_cardinality_compart, inverse_direct_cardinality_compart_style = cu.add_compart(link, "InverseCardinality")
			inverse_direct_cardinality_compart_style:attr({adjustment = 9, fontColor = 0, fontSize = 9, fontStyle = 0})
	cu.default_line_popUp(link, "elemType")
	cu.default_key_line_shortcuts(link, "elemType")
	make_property_diagram_for_line(link, direct_role_compart, inverse_role_compart, direct_cardinality_compart, inverse_cardinality_compart)
	cu.add_translet_to_obj_type(link, "l2ClickEvent", "interpreter.Properties.Properties")
	cu.add_translet_to_obj_type(node_type, "procProperties", "interpreter.Properties.Properties")
	lQuery.create("PaletteElementType", {id = "Association", caption = "Association", nr = 1, picture = "Association.bmp", paletteType = palette_type, elemType = link})

--composition
	local composition_style = u.add_default_configurator_edge_style("Composition", "Composition", {startShapeCode = 10, endShapeCode = 1, lineColor = 4163953, startLineColor = 4163953, startBkgColor = 4163953})
	local composition = lQuery.create("EdgeType", {id = "Composition", caption = "Composition", openPropertiesOnElementCreate = "true"})
						:link("graphDiagramType", diagram_type)
						:link("elemStyle", composition_style)
		cu.add_pair(composition, node_type, node_type, "BiDirectional")
		local direct_role_compart, direct_role_compart_style = cu.add_compart(composition, "DirectRole")
			direct_role_compart_style:attr({adjustment = 6, fontColor = 0, fontSize = 9, fontStyle = 0})
		local inverse_role_compart, inverse_direct_role_compart_style = cu.add_compart(composition, "InverseRole")
			inverse_direct_role_compart_style:attr({adjustment = 5, fontColor = 0, fontSize = 9, fontStyle = 0})
		local direct_cardinality_compart, direct_cardinality_compart_style = cu.add_compart(composition, "DirectCardinality")
			direct_cardinality_compart_style:attr({adjustment = 10, fontColor = 0, fontSize = 9, fontStyle = 0})
		local inverse_cardinality_compart, inverse_direct_cardinality_compart_style = cu.add_compart(composition, "InverseCardinality")
			inverse_direct_cardinality_compart_style:attr({adjustment = 9, fontColor = 0, fontSize = 9, fontStyle = 0})

	cu.default_line_popUp(composition, "elemType")
	cu.default_key_line_shortcuts(composition, "elemType")
	make_property_diagram_for_line(composition, direct_role_compart, inverse_role_compart, direct_cardinality_compart, inverse_cardinality_compart)
	cu.add_translet_to_obj_type(composition, "l2ClickEvent", "interpreter.Properties.Properties")
	cu.add_translet_to_obj_type(node_type, "procProperties", "interpreter.Properties.Properties")
	lQuery.create("PaletteElementType", {id = "Composition", caption = "Composition", nr = 1, picture = "Composition.bmp", paletteType = palette_type, elemType = composition})

--generalization
	local generalizaion_style = u.add_default_configurator_edge_style("Generalization", "Generalization", {startShapeCode = 1, endShapeCode = 11, lineColor = 4163953, endLineColor = 4163953, endBkgColor = 16777215})
	local generalization = lQuery.create("EdgeType", {id = "Generalization", caption = "Generalization"})
						:link("graphDiagramType", diagram_type)
						:link("elemStyle", generalizaion_style)
		cu.add_pair(generalization, node_type, node_type, "BiDirectional")
	cu.default_line_popUp(generalization, "elemType")
	cu.default_key_line_shortcuts(generalization, "elemType")
	lQuery.create("PaletteElementType", {id = "Generalization", caption = "Generalization", nr = 1, picture = "Generalization.bmp", paletteType = palette_type, elemType = generalization})

--diagram type features
	local collection_popUpDiagram = lQuery.create("PopUpDiagramType", {id = "collection", cType = diagram_type})
		cu.add_cut_copy_delete_popUp(collection_popUpDiagram)
	local empty_popUpDiagram = lQuery.create("PopUpDiagramType", {id = "empty", eType = diagram_type})
		cu.add_PopUpElementType(empty_popUpDiagram, "Delete Diagram", "interpreter.Delete.delete_current_diagram", 1)
		cu.add_PopUpElementType(empty_popUpDiagram, "Diagram Name", "configurator.configurator.set_model_diagram_name", 2)
		--cu.add_cut_copy_delete_popUp(collection_popUpDiagram)
	--local toolbar_type = lQuery.create("ToolbarType", {graphDiagramType = diagram_type})
	--	cu.add_toolbar_element_type(toolbar_type, "Delete Diagram", "interpreter.Delete.delete_current_diagram", 1, "DeleteDiagram.BMP")		
	cu.default_key_shortcuts(diagram_type, "cType")
	cu.add_key_shortcut(diagram_type, "eType", "Ctrl V", "interpreter.CutCopyPaste.Paste")
	cu.add_key_shortcut(diagram_type, "eType", "F", "find.show_window")

end

--Creating singleton diagrams
function make_specification_project_diagrams(specification_diagram_type, project_diagram_type)
	local spec_diagram = utilities.add_graph_diagram_to_graph_diagram_type("", specification_diagram_type):link("target_type", project_diagram_type)
	local project_name = utilities.get_project_name()
	local project_diagram = utilities.add_graph_diagram_to_graph_diagram_type(project_name, project_diagram_type):link("project", lQuery.create("Project"))
	--project_diagram:find("/graphDiagramType")
	--		:link("palette", lQuery.create("Palette", {graphDiagram = project_diagram})
	--				:link("paletteElement", lQuery.create("PaletteBox", {caption = "X"})))
end

function make_property_diagram(elem_type, name_compart_type, value_compart_type)
	local prop_dgr = lQuery.create("PropertyDiagram", {id = elem_type:attr("id")}):link("elemType", elem_type)
	create_property_row(name_compart_type:attr("id"), name_compart_type:attr("caption"), "InputField", prop_dgr, "propertyDiagram", name_compart_type)
	create_property_row(value_compart_type:attr("id"), value_compart_type:attr("caption"), "TextArea", prop_dgr, "propertyDiagram", value_compart_type)
end

function create_property_row(id, caption, value, row_parent, parent_role, object_type)
	return lQuery.create("PropertyRow", {id = id, caption = caption, rowType = value, isEditable = "true", isReadOnly = "false", isFirstRespondent = "false"})
			:link(parent_role, row_parent):link("compartType", object_type)
end

function make_property_diagram_for_line(elem_type, compart_type1, compart_type2, compart_type3, compart_type4)
	local prop_dgr = lQuery.create("PropertyDiagram", {id = elem_type:attr("id")}):link("elemType", elem_type)
	create_property_row(compart_type1:attr("id"), compart_type1:attr("caption"), "InputField", prop_dgr, "propertyDiagram", compart_type1)
	create_property_row(compart_type3:attr("id"), compart_type3:attr("caption"), "InputField", prop_dgr, "propertyDiagram", compart_type3)
	create_property_row(compart_type2:attr("id"), compart_type2:attr("caption"), "InputField", prop_dgr, "propertyDiagram", compart_type2)
	create_property_row(compart_type4:attr("id"), compart_type4:attr("caption"), "InputField", prop_dgr, "propertyDiagram", compart_type4)
end

function make_property_diagram_for_link(elem_type, compart_type1, compart_type2)
	local prop_dgr = lQuery.create("PropertyDiagram", {id = elem_type:attr("id")}):link("elemType", elem_type)
	create_property_row(compart_type1:attr("id"), compart_type1:attr("caption"), "InputField", prop_dgr, "propertyDiagram", compart_type1)
	create_property_row(compart_type2:attr("id"), compart_type2:attr("caption"), "InputField", prop_dgr, "propertyDiagram", compart_type2)
end
