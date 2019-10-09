module(..., package.seeall)

configurator = require("configurator.configurator")
u = require("configurator.configurator_utilities")
conf_dialog = require("configurator.dialog")
versioning = require("configurator.versioning")

function add_toolbar_element_type(toolbar_type, name, proc_name, nr, picture)
	return lQuery.create("ToolbarElementType", {
		id = name,
		caption = name,
		nr = nr,
		picture = picture,
		procedureName = proc_name,
		toolbarType = toolbar_type
	})
end

function add_PopUpElementType(popUpDiagramType, name, proc_name, nr)
	return lQuery.create("PopUpElementType", {
		id = name,
		caption = name,
		nr = nr,
		procedureName = proc_name,
		popUpDiagramType = popUpDiagramType
	})
end

function add_PopUpElement(popUpDiagram, name, proc_name)
	return lQuery.create("PopUpElement", {
		caption = name,
		--visibility = true,
		procedureName = proc_name,
		popUpDiagram = popUpDiagram
	})
end

function add_key_shortcut(elem, role, key, proc)
	return lQuery.create("KeyboardShortcut", {
		key = key,
		procedureName = proc
	}):link(role, elem)
end

function default_key_shortcuts(elem, role)
	add_key_shortcut(elem, role, "Ctrl X", "Cut")
	add_key_shortcut(elem, role, "Ctrl C", "Copy")
	add_key_shortcut(elem, role, "Delete", "Delete")
	add_key_shortcut(elem, role, "Enter", "Properties")
end

function default_configurator_key_shortcuts(elem, role)
	add_key_shortcut(elem, role, "Ctrl X", "Cut")
	add_key_shortcut(elem, role, "Ctrl C", "Copy")
	add_key_shortcut(elem, role, "Delete", "Delete")
	add_key_shortcut(elem, role, "Enter", "configurator.configurator.configurator_dialog")
end

function default_configurator_key_line_shortcuts(elem, role)
	add_key_shortcut(elem, role, "Delete", "Delete")
	add_key_shortcut(elem, role, "Enter", "configurator.configurator.configurator_dialog")
end

function default_box_popUp(elem, role)
	local diagram = lQuery.create("PopUpDiagramType"):link(role, elem)
	add_PopUpElementType(diagram, "Properties	Enter", "Properties", 1)
	add_cut_copy_delete_popUp(diagram)
	add_PopUpElementType(diagram, "Symbol Style", "SymbolStyle", 5)
return diagram
end

function add_cut_copy_delete_popUp(diagram)
	add_PopUpElementType(diagram, "Cut	Ctrl+X", "Cut", 2)
	add_PopUpElementType(diagram, "Copy	Ctrl+C", "Copy", 3)
	add_PopUpElementType(diagram, "Delete	Delete", "Delete", 4)
end

function add_collection_pop_up(diagram)
	add_cut_copy_delete_popUp(diagram)
	add_PopUpElementType(diagram, "Align Selected Boxes", "align_selected_boxes", 5)
end

function default_configurator_box_popUp(elem, role)
	local popUpDiagram = lQuery.create("PopUpDiagramType"):link(role, elem)
	add_PopUpElementType(popUpDiagram, "Properties	Enter", "configurator.configurator.configurator_dialog", 1)
	--add_PopUpElementType(popUpDiagram, "Add Style", "configurator.configurator.add_style_box", 2)
	--add_PopUpElementType(popUpDiagram, "Show compart tree", "configurator.delta.test_compart_type_tree", 2)
	--add_PopUpElementType(popUpDiagram, "Hide/Show Attributes", "configurator.configurator.hide_show_attributes", 3)
	add_cut_copy_delete_popUp(popUpDiagram)
return popUpDiagram
end

function default_configurator_line_popUp(elem, role)
	local pop_diagram_type = lQuery.create("PopUpDiagramType"):link(role, elem)
	add_PopUpElementType(pop_diagram_type, "Properties	Enter", "configurator.configurator.configurator_dialog", 1)
	add_PopUpElementType(pop_diagram_type, "Reroute Line", "Reroute", 2)
	--return add_configurator_line_port_popUp(elem, role, "configurator.configurator.add_style_line")

	return pop_diagram_type
end

function default_configurator_free_line_popUp(elem, role)
	local pop_up_diagram = add_configurator_line_port_popUp(elem, role, "configurator.configurator.add_style_free_line")
	add_cut_copy_delete_popUp(pop_up_diagram)
	add_PopUpElementType(diagram, "Symbol Style", "SymbolStyle", 5)
	return pop_up_diagram
end

function default_configurator_free_box_popUp(elem, role)
	local popUpDiagram = lQuery.create("PopUpDiagramType"):link(role, elem)
	add_PopUpElementType(popUpDiagram, "Properties	Enter", "configurator.configurator.configurator_dialog", 1)
	--add_PopUpElement(popUpDiagram, "Add Style", "configurator.configurator.add_style_free_box", 2)
	add_cut_copy_delete_popUp(popUpDiagram)
	add_PopUpElementType(diagram, "Symbol Style", "SymbolStyle", 5)
return popUpDiagram
end

function default_configurator_port_popUp(elem, role)
	return add_configurator_line_port_popUp(elem, role, "configurator.configurator.add_style_port")
end

function add_configurator_line_port_popUp(elem, role, add_style_function)
	local popUpDiagram = lQuery.create("PopUpDiagramType"):link(role, elem)
	add_PopUpElementType(popUpDiagram, "Properties	Enter", "configurator.configurator.configurator_dialog", 1)
	--add_PopUpElement(popUpDiagram, "Add Style", add_style_function, 2)
	add_PopUpElementType(popUpDiagram, "Delete		Delete", "Delete", 3)
return popUpDiagram
end

function default_line_popUp(elem, role)
	local diagram = lQuery.create("PopUpDiagramType"):link(role, elem)
	add_PopUpElementType(diagram, "Properties		Enter", "Properties", 1)
	add_PopUpElementType(diagram, "Delete		Delete", "Delete", 2)
	add_PopUpElementType(diagram, "Reroute Line", "Reroute", 3)
	add_PopUpElementType(diagram, "Symbol Style", "SymbolStyle", 4)
return diagram
end

function default_key_line_shortcuts(elem, role)
	add_key_shortcut(elem, role, "Delete", "Delete")
	add_key_shortcut(elem, role, "Enter", "Properties")
end

function add_pair(edge_type, start_type, end_type, direction)
	edge_type:attr({direction = direction})
		:link("start", start_type)
		:link("end", end_type)
end

function add_compartType(attr)
	local compart_type = lQuery.create("CompartType", attr)
	local translet = add_compart_type_translets(compart_type)
	return compart_type, translet
end

function add_compart_const(name)
	return add_compartType({id = name, caption = name, isEssential = "true", pattern = "a-zA-Z0-9-_ "})
end

function add_compartStyle(name)
	return lQuery.create("CompartStyle", {
		id = name,
		caption = name,
		nr = 1,
		alignment = 1,
		adjustment = 0,
		picture = "",
		picWidth = 0,
		picHeight = 0,
		picPos = 1,
		picStyle = 0,
		adornment = 0,
		lineWidth = 1,
		lineColor = 0,
		fontTypeFace = "Arial",
		fontCharSet = 1,
		fontColor = 16777215,
		fontSize = 12,
		fontPitch = 1,
		fontStyle = 1,
		isVisible = 1
	})
end

function add_edge_compartStyle(name)
	return lQuery.create("CompartStyle", {
		id = name,
		caption = name,
		nr = 1,
		alignment = 1,
		adjustment = 0,
		picture = "",
		picWidth = 0,
		picHeight = 0,
		picPos = 1,
		picStyle = 0,
		adornment = 0,
		lineWidth = 1,
		lineColor = 0,
		fontTypeFace = "Arial",
		fontCharSet = 1,
		fontColor = 0,
		fontSize = 12,
		fontPitch = 1,
		fontStyle = 1,
		isVisible = 1
	})
end

function add_compart(elem_type, name)
	local compart_type = add_compart_const(name):link("elemType", elem_type)
	local compart_style = add_compartStyle(name):link("compartType", compart_type)
return compart_type, compart_style
end

function get_palette_type(diagram_type)
	local palette_type = diagram_type:find("/paletteType")
	if palette_type:is_not_empty() then
		return palette_type
	else
		return lQuery.create("PaletteType", {graphDiagramType = diagram_type})
	end
end

function add_type(element)
	local diagram = element:find("/graphDiagram")
	local diagram_type = diagram:find("/target_type")
	local target_diagrams = diagram_type:find("/graphDiagram")
	local elem_type, elem_style, palette_type, palette_element_type = nil
	local id = ""
	if element:filter(".Node"):is_not_empty() then
		id = generate_unique_id("Box", diagram_type, "elemType")
		elem_type, elem_style, palette_type, palette_element_type = add_element_type_style_palette(element, "Node", id, {}, diagram_type, id)
		default_box_popUp(elem_type, "elemType")
		default_key_shortcuts(elem_type, "elemType")
	elseif element:filter(".FreeBox"):is_not_empty() then
		id = generate_unique_id("FreeBox", diagram_type, "elemType")
		elem_type, elem_style, palette_type, palette_element_type = add_element_type_style_palette(element, "FreeBox", id, {}, diagram_type, id)
		default_box_popUp(elem_type, "elemType")
		default_key_shortcuts(elem_type, "elemType")
	elseif element:filter(".FreeLine"):is_not_empty() then
		id = generate_unique_id("FreeLine", diagram_type, "elemType")
		elem_type, elem_style, palette = add_element_type_style_palette(element, "Edge", id, {}, diagram_type, id)
		default_box_popUp(elem_type, "elemType")
		default_key_shortcuts(elem_type, "elemType")
	elseif element:filter(".Edge"):is_not_empty() then 
		id = generate_unique_id("Line", diagram_type, "elemType")
		elem_type, elem_style, palette = add_element_type_style_palette(element, "Edge", id, {}, diagram_type, id)
		local start_elem_type = element:find("/start/target_type")
		local end_elem_type = element:find("/end/target_type")
		add_pair(elem_type, start_elem_type, end_elem_type, "UniDirectional")
		default_line_popUp(elem_type, "elemType")
		default_key_line_shortcuts(elem_type, "elemType")
	elseif element:filter(".Port"):is_not_empty()  then
		id = generate_unique_id("Port", diagram_type, "elemType")
		elem_type, elem_style, palette = add_element_type_style_palette(element, "Port", id, {openPropertiesOnElementCreate = "false"}, diagram_type, id)
		local node_type = element:find("/node/target_type")
		elem_type:link("nodeType", node_type)
		default_line_popUp(elem_type, "elemType")
		default_key_line_shortcuts(elem_type, "elemType")
	else
		print("Error in add type")
	end
	add_palette_element_from_configurator(element)
	local compart = element:find("/compartment:has(/compartType[id = 'AS#Name'])")
	if compart:is_not_empty() then
		compart:attr({value = id, input = id})
	end
	versioning.elem_type_versioning(elem_type)
return elem_type
end

function generate_unique_id(base_id, container_type, role_to_child)
	local i = ""
	local tmp_id = base_id
	while true do
		if container_type:find("/" .. role_to_child .. "[id = '" .. tmp_id .. "']"):is_not_empty() then
			if i == "" then
				i = 0
			end
			i = i + 1
			tmp_id = base_id .. i
		else
			base_id = base_id .. i
			break
		end
	end
	return base_id
end

function add_palette_element_from_configurator(elem)
	local target_type = elem:find("/target_type")
	local palette_elem_type = target_type:find("/paletteElementType")
	local palette_elements = palette_elem_type:find("/presentationElement")
	local diagram_type = target_type:find("/graphDiagramType")
	local diagrams = diagram_type:find("/graphDiagram")
	if palette_elements:is_empty() then
		diagrams:each(function(diagram)	
			local palette = diagram:find("/palette")
			if palette:is_empty() then
				local palette_type = diagram_type:find("/paletteType")
				palette = utilities.add_palette_toolbar_base("Palette", palette_type, diagram)
			end
			utilities.add_element_to_base(palette, "PaletteElement", "paletteElement", palette_elem_type)
		end)
	else
		palette_elements:attr({caption = palette_elem_type:attr("caption"), picture = palette_elem_type:attr("picture")})
	end
end

function add_element_type_style_palette(element, elem_type_name, name, extension_functions, diagram_type, style_id)
--elemType
	local elem_type = lQuery.create(elem_type_name .. "Type", {
		id = name,
		caption = name,
		--l2ClickEvent = "interpreter.Properties.Properties",
		--procProperties = "interpreter.Properties.Properties",
		openPropertiesOnElementCreate = true,
		isContainerMandatory = false})
			:attr(extension_functions)
			:link("graphDiagramType", diagram_type)
			:link("presentation", element) -- adds target_type link
	add_elem_type_translets(elem_type)

--style	
	local elem_style = lQuery.create(elem_type_name .. "Style"):link("elemType", elem_type)
	local base_style = element:find("/elemStyle")
		elem_style:copy_attrs_from(base_style)	
		element:remove_link("elemStyle", base_style)
			:link("elemStyle", elem_style)
	elem_style:attr({
		id = name,
		caption = name
	})
--palette
	local palette_type, palette_elem_type = add_palette_element_type(diagram_type, elem_type, elem_type_name)
	return elem_type, elem_style, palette_type, palette_elem_type
end

--vajag atbilstosi MM
function add_elem_type_translets(elem_type)
	add_translet_to_obj_type(elem_type, "l2ClickEvent", "interpreter.Properties.Properties")
	add_translet_to_obj_type(elem_type, "procProperties", "interpreter.Properties.Properties")
--	add_translet_to_obj_type(elem_type, "procDynamicPopUp", "")
--	add_translet_to_obj_type(elem_type, "procPreCondition", "")
--	add_translet_to_obj_type(elem_type, "procNewElement", "")
--	add_translet_to_obj_type(elem_type, "procElementEntered", "")
--	add_translet_to_obj_type(elem_type, "procCreateElementDomain", "")
--	add_translet_to_obj_type(elem_type, "procCopied", "")
--	add_translet_to_obj_type(elem_type, "procPasted", "")
--	add_translet_to_obj_type(elem_type, "procClipboardCleared", "")
--	add_translet_to_obj_type(elem_type, "procDeleteElement", "")

	
	if elem_type:filter(".NodeType"):size() > 0 then
		--add_translet_to_obj_type(elem_type, "procContainerChanged", "")
	elseif elem_type:filter(".EdgeType"):size() > 0 then
		--add_translet_to_obj_type(elem_type, "procMoveLine", "")
	end
end

function add_compart_type_translets(compart_type)
--	add_translet_to_obj_type(compart_type, "procGenerateInputValue", "")
--	add_translet_to_obj_type(compart_type, "procBlockingFieldEntered", "")
--	add_translet_to_obj_type(compart_type, "procForcedValuesEntered", "")
--	add_translet_to_obj_type(compart_type, "procCheckCompartmentFieldEntered", "")
--	add_translet_to_obj_type(compart_type, "procGenerateItemsClickBox", "")
--	add_translet_to_obj_type(compart_type, "procFieldEntered", "")
--	add_translet_to_obj_type(compart_type, "procCompose", "")
--	add_translet_to_obj_type(compart_type, "procDecompose", "")
--	add_translet_to_obj_type(compart_type, "procCreateCompartmentDomain", "")
--	add_translet_to_obj_type(compart_type, "procUpdateCompartmentDomain", "")
--	add_translet_to_obj_type(compart_type, "procDeleteCompartmentDomain", "")
end

function add_translet_to_obj_type(obj_type, proc, proc_name)
	local translet = obj_type:find("/translet[extensionPoint = " .. proc .. "]:not(:has(/extenstion))")
	if proc_name == "" and translet ~= nil then
		translet:delete()
	else
		if translet == nil or translet:is_empty() then
			translet = lQuery.create("Translet", {extensionPoint = proc, procedureName = proc_name, shouldBeIncluded = ""})
			obj_type:link("translet", translet)
		else
			translet:attr({procedureName = proc_name})
		end
	end
	return translet
end

function get_palette_line_elems(palette_type)
	return palette_type:find("/paletteElementType")
end

function add_type_seed(element)
	local id = "Box"
	local elem_type = add_type(element)
	local diagram_type = elem_type:find("/graphDiagramType")
	local diagram = element:find("/graphDiagram")
	if diagram:find("/parent"):is_empty() then
		add_translet_to_obj_type(elem_type, "procCreateElementDomain", "utilities.add_navigation_diagram")
		add_translet_to_obj_type(elem_type, "l2ClickEvent", "utilities.navigate")
		add_translet_to_obj_type(elem_type, "procDeleteElement", "interpreter.Delete.delete_seed")
	
		local compart_name = "Name"
		local compart_type, compart_style = add_compart(elem_type, compart_name)
			add_translet_to_obj_type(compart_type, "procFieldEntered", "utilities.update_target_diagram_caption")
		--local compart_attr_type = element:find("/elemType/compartType[id = 'AS#Attributes']")
		--local compart = u.add_compartment(element, compart_attr_type, compart_style, {})
		--compart:link("target_type", compart_type)
	
		local prop_dgr = conf_dialog.create_property_diagram(elem_type, "elemType")
		conf_dialog.create_property_row(compart_name, compart_name, "InputField", prop_dgr, "propertyDiagram", compart_type)

		local diagram = utilities.add_graph_diagram_to_graph_diagram_type("", lQuery("GraphDiagramType[id = 'specificationDgr']")):link("parent", element)
		local target_type, target_style = add_graph_diagram_type(id, "", true)
		target_type:link("presentation", diagram)
				:link("source", elem_type)
				:attr({procDynamicPopUpE = "configurator.const.const_utilities.add_default_diagram_pop_up"})
		diagram:remove_link("graphDiagramStyle")
			:link("graphDiagramStyle", target_style)
		--local empty_popUpDiagram = lQuery.create("PopUpDiagram", {id = "empty_collection", eType = diagram_type})
		--add_PopUpElement(empty_popUpDiagram, "Paste", "interpreter.CutCopyPaste.Paste", 1)

		local collection_popUpDiagram = lQuery.create("PopUpDiagramType", {cType = target_type})
		add_collection_pop_up(collection_popUpDiagram)

		default_key_shortcuts(target_type, "cType")
		add_key_shortcut(target_type, "eType", "Ctrl V", "Paste")
	end
end

function add_palette_element_type(diagram_type, elem_type, elem_type_name)
	local palette_type = get_palette_type(diagram_type)
	local palette_elem_type = nil
	local palette_elem_caption = elem_type:attr_e("caption")
	local buls = "add_palette_elem"
	if elem_type_name == "Edge" then
		local palette_line_type = palette_type:find("/paletteElementType[caption = " .. palette_elem_caption .. "]")
		if palette_line_type:is_not_empty() then
			palette_line_type:link("elemType", elem_type)
			buls = "do_not_add_palette_elem"
		end
	end
	if buls == "add_palette_elem" then
		local palette_nr = palette_type:find("/paletteElementType"):size() + 1
		palette_elem_type = lQuery.create("PaletteElementType", {
			id = elem_type:attr_e("id"),
			caption = palette_elem_caption,
			nr = palette_nr,
			elemType = elem_type
		})
		palette_type:link("paletteElementType", palette_elem_type)
	end
	return palette_type, palette_elem_type
end

function add_specialization(element)
	element:find("/start/target_type"):link("supertype", element:find("/end/target_type"))
end

function add_navigation_diagram(element)
	return utilities.add_navigation_diagram(element)
end

function add_graph_diagram_type(diagram_id, caption, is_tree_node)
	local diagram_type = lQuery.create("GraphDiagramType", {
						id = diagram_id,
						caption = caption
					}):link("toolType", lQuery("ToolType"))
	local diagram_style = lQuery.create("GraphDiagramStyle", {
						id = diagram_id,
						layoutMode = 0,
						layoutAlgorithm = 3,
						bkgColor = 16777215,
						--bkgColor = 11702408,
						screenZoom = 1000,
						printZoom = 1000
				}):link("graphDiagramType", diagram_type)
	if is_tree_node then
		utilities.add_tag(diagram_type, "IsTreeNode", "true")
	end
	versioning.diagram_type_versioning(diagram_type)
	return diagram_type, diagram_style
end

function add_project_diagram_pop_up()
	local pop_up_diagram = lQuery.create("PopUpDiagram")
	local diagram = utilities.current_diagram()
	local diagram_type = diagram:find("/graphDiagramType")
		--if lQuery("Clipboard"):find("/graphDiagramType"):id() == diagram_type:id() then
		--	add_PopUpElement(pop_up_diagram, "Ielīmēt	Ctrl+V", "interpreter.CutCopyPaste.Paste", 1)
		--end
		add_PopUpElement(pop_up_diagram, "Configurator", "configurator.configurator.show_specificationDgr", 2)
	pop_up_diagram:find("/popUpElement")
	add_pop_up_cmd(pop_up_diagram)
end

function add_pop_up_cmd(pop_up_diagram)
	local cmd = utilities.create_command("PopUpCmd")
						:link("popUpDiagram", pop_up_diagram)
						:link("graphDiagram", utilities.current_diagram())
	utilities.execute_cmd_obj(cmd)
end

function add_default_diagram_pop_up()
	add_default_diagram_pop_up_with_language("Paste	Ctrl+V")
end

function add_default_diagram_pop_up_lv()
	add_default_diagram_pop_up_with_language("Ielīmēt	Ctrl+V")
end

function add_default_diagram_pop_up_with_language(item_name)
	local pop_up_diagram = lQuery.create("PopUpDiagram")
	local diagram = utilities.current_diagram()
	local diagram_type = diagram:find("/graphDiagramType")
		--if lQuery("Clipboard"):find("/graphDiagramType"):id() == diagram_type:id() then
			add_PopUpElement(pop_up_diagram, item_name, "interpreter.CutCopyPaste.Paste", 1)
		--end
	add_pop_up_cmd(pop_up_diagram)
end


