require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
local d = require("dialog_utilities")

cu = require("configurator.const.const_utilities")
u = require("configurator.configurator_utilities")
dt = require("configurator.const.diagramType")

local containerNode = core.add_node(lQuery("NodeType[id='Box']"), lQuery("GraphDiagram[caption='OWL']"))
local containerNodeStyle = lQuery.create("NodeStyle", {	
		id = "Container",
		caption = "Container",
		shapeCode = 2,
		shapeStyle = 32,
		lineWidth = 2,
		dashLength = 0,
		breakLength = 0,
		alignment = 0,
		bkgColor = 16777215,
		lineColor = 0,
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
	
local diagram_type = lQuery("GraphDiagramType[id='OWL']")
local id = cu.generate_unique_id("Container", diagram_type, "elemType")
local elem_type, elem_style, palette_type, palette_element_type = cu.add_element_type_style_palette(containerNode, "Node", id, {}, diagram_type, id)
palette_element_type:attr("picture", "Group.bmp")
cu.default_box_popUp(elem_type, "elemType")
cu.default_key_shortcuts(elem_type, "elemType")
containerNode:link("/target_type", elem_type)

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "OWLGrEd_Container")
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_Container"
end

--ieladet konfiguraciju
local pathConfiguration = path .. "\\AutoLoadConfiguration"
completeMetamodelUserFields.loadAutoLoadContextType(pathConfiguration)

-- ieladet profilu
local pathContextType = path .. "\\AutoLoad"
completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)

local containerNameInvisibleStyle = lQuery.create("CompartStyle", {
		id = "NameInvisible",
		caption = "NameInvisible",
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
		fontSize = 9,
		fontPitch = 1,
		fontStyle = 1,
		isVisible = 0
	})

	elem_type:find("/compartType[id='Name']"):link("compartStyle", containerNameInvisibleStyle)
	
	-- containerType
	local typesInContainer = {
		"Class",
		"OntologyFragment",
		"HorizontalFork",
		"Object",
		"Annotation",
		"DifferentIndivids",
		"SameAsIndivids",
		"EquivalentClasses",
		"DisjointClasses",
		"DataType",
		"AnnotationProperty",
		"Container"
	}
	
	for k,v in pairs(typesInContainer) do
		lQuery("NodeType[id='" ..v .. "']:has(/graphDiagramType[id='OWL'])"):link("containerType", elem_type)
	end
	
	configurator.relink_palette(containerNode)
	
	-- procOnClose
	local prEH  = lQuery.create("PropertyEventHandler", {eventType = "onClose", procedureName = "OWLGrEd_Container.container.setUniqueContainerName"})
	lQuery("PropertyDiagram[id='Container']"):link("propertyEventHandler", prEH)
	
lQuery("ElemType[id='Class']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getUri(/Name /Namespace) $getContainer)'}))
lQuery("ElemType[id='Object']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Title/Name:$getUri(/Name /Namespace) $getContainer)'}))
lQuery("ElemType[id='DataType']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getUri(/Name /Namespace) $getContainer)'}))
lQuery("ElemType[id='AnnotationProperty']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getAnnotationProperty(/Name /Namespace) $getContainer)'}))

lQuery("ElemType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[Annotation([/eStart:$isEmpty == true][/eEnd:$isEmpty== true][/Property:$isEmpty == true]?(Annotation([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> $getContainer)) $getAnnotationProperty(/AnnotationType) "$value(/ValueLanguage/Value)"?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eStart/end:$elemType == 'Class'][/Property:$isEmpty == true]$getAnnotationProperty(/AnnotationType) $getClassExpr(/eStart/end) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eEnd/start:$elemType == 'Class'][/Property:$isEmpty == true]$getAnnotationProperty(/AnnotationType) $getClassExpr(/eEnd/start) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eStart/end:$elemType == 'Object'][/Property:$isEmpty == true]$getAnnotationProperty(/AnnotationType) $getObjectExpr(/eStart/end) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eEnd/start:$elemType == 'Object'][/Property:$isEmpty == true]$getAnnotationProperty(/AnnotationType) $getObjectExpr(/eEnd/start) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/Property:$isEmpty != true]$getAnnotationProperty(/AnnotationType) $getUri(/Property) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

return true
-- return false, error_string