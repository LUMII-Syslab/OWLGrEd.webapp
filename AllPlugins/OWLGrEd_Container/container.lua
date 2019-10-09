module(..., package.seeall)

local MP = require("ManchesterParser")
cu = require("configurator.const.const_utilities")
u = require("configurator.configurator_utilities")
dt = require("configurator.const.diagramType")

function setContainerNameVisible(compartment,oldValue)
	local containerName= compartment:find("/element/compartment:has(/compartType[id='Name'])")
	if compartment:attr("value") == "true" then
		containerName:link("compartStyle",containerName:find("/compartType/compartStyle[id='NameInvisible']"))
	else
		containerName:link("compartStyle",containerName:find("/compartType/compartStyle[id='Name']"))
	end
end

function setUniqueContainerName(form)
	local name = form:find("/presentationElement/compartment:has(/compartType[id='Name'])")
	if name:attr("value") == nil or name:attr("value") == "" then
		local containerName = "Container_"
		local count = 1
		while lQuery("ElemType[id='Container']/element/compartment:has(/compartType[id='Name'])[value='" .. containerName .. count .. "']"):is_not_empty() do
			count = count + 1
		end
		name:attr("value", containerName .. count)
		name:attr("input", containerName .. count)
		utilities.refresh_element(form:find("/presentationElement"), utilities.current_diagram())
	end
end

function setPrefixesPlus(dataCompartType, dataCompartment, parsingCompartment)
	--izsaukt OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView(dataCompartType, dataCompartment, parsingCompartment)
	local result = ""
	if dataCompartment~=nil then
		local allValuesFrom = dataCompartment:find("/parentCompartment/subCompartment:has(/compartType[id='allValuesFrom'])")
		if allValuesFrom:attr("value")=="true" then result = "+" end
	end
	return result
end

function setPrefixesPlusFromAllFaluesFrom(compartment, oldValue)
	local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	if compartment:attr("value") == "true" then 
		name:attr("input", "+" .. name:attr("value"))
	else
		name:attr("input", name:attr("value"))
	end
	utilities.refresh_element(name, utilities.current_diagram())
end

function createContainerElemType()

	-- local palette_type = lQuery("PaletteType:has(/graphDiagramType[id='OWL'])")
   -- print("palette_type size", palette_type:size())
   -- local node_type = lQuery.create("NodeType", {
		-- id = "Container",
		-- caption = "Container",
		-- openPropertiesOnElementCreate = "true",
		-- graphDiagramType = diagram_type,
		-- paletteElementType = lQuery.create("PaletteElementType", {id = "Container", caption = "Container", nr = 23, picture = "Group.bmp", paletteType = palette_type})
	-- })
	-- cu.add_translet_to_obj_type(node_type, "procCreateElementDomain", "configurator.const.const_utilities.add_type")
	-- cu.add_translet_to_obj_type(node_type, "l2ClickEvent", "configurator.configurator.configurator_dialog")
	-- cu.add_translet_to_obj_type(node_type, "procProperties", "configurator.configurator.configurator_dialog")
	-- cu.add_translet_to_obj_type(node_type, "procCopied", "configurator.configurator.configurator_elem_copied")
	-- cu.add_translet_to_obj_type(node_type, "procDeleteElementDomain", "configurator.configurator.delete_elem_type_from_configurator")

	-- local node_style = u.add_default_configurator_node("Container", "Container", 12419151):link("elemType", node_type)
	-- dt.box_type_additions(cu.default_configurator_box_popUp, node_type)
	
	local containerNode = core.add_node(lQuery("NodeType[id='Box']"), lQuery("GraphDiagram[caption='OWL']"))
	local containerNodeStyle = lQuery.create("NodeStyle", {	
		id = "Container",
		caption = "Container",
		shapeCode = 2,
		shapeStyle = 0,
		lineWidth = 2,
		dashLength = 0,
		breakLength = 0,
		alignment = 0,
		bkgColor = 12419151,
		lineColor = 9067831,
		picture = "",
		picWidth = 0,
		picHeight = 0,
		picPos = 1,
		picStyle = 0,
		width = 400,
		height = 300
	})
	-- containerNode:remove_link("elemStyle", containerNode:find("/elemStyle"))
	containerNode:link("elemStyle", containerNodeStyle)
	
	local diagram_type = lQuery("GraphDiagram[id='OWL']")
	local id = cu.generate_unique_id("Container", diagram_type, "elemType")
	local elem_type, elem_style, palette_type, palette_element_type = cu.add_element_type_style_palette(containerNode, "Node", id, {}, diagram_type, id)
	cu.default_box_popUp(elem_type, "elemType")
	cu.default_key_shortcuts(elem_type, "elemType")
	containerNode:link("/target_type", elem_type)
	
-- print(lQuery("Compartment[value='Container']/element/graphDiagram"):attr("caption"))
-- print(lQuery("Compartment[value='Container']/element/target_type"):attr("caption"))
-- print(lQuery("Compartment[value='Container']/element/elemType"):attr("caption"))
-- print(lQuery("Compartment[value='Container']/element/elemType/graphDiagramType"):attr("id"))
-- print(lQuery("Compartment[value='Container']/element/target_type/paletteElementType"):attr("caption"))
-- print(lQuery("Compartment[value='Container']/element/target_type/paletteElementType/paletteType/graphDiagramType"):attr("id"))
-- print(lQuery("Compartment[value='Container']/element/target_type/paletteElementType/presentationElement"):size())
-- print(lQuery("Compartment[value='Container']/element/target_type/graphDiagramType"):attr("id"))
-- print(lQuery("Compartment[value='Container']/compartType"):attr("id"))
end