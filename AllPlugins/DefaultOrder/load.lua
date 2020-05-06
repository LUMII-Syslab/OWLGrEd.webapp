require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
local defaultOrder_specific = require "DefaultOrder.defaultOrder_specific"
local d = require("dialog_utilities")


local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "DefaultOrder") .."/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\DefaultOrder\\"
end

--ieladet OBIS profilu
local pathContextType = path .. "AutoLoad"
completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)


lQuery("ElemType[id = 'Class']/compartType[id='defaultOrder']"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")
lQuery("ElemType[id = 'Class']/compartType[id='defaultOrder']/propertyRow"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")


lQuery("ElemType[id='Class']/propertyDiagram"):link("propertyEventHandler", lQuery.create("PropertyEventHandler", {eventType = "onClose", procedureName = "DefaultOrder.defaultOrder_specific.defaultOrder"}))

lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "orderAttributesByDefaultOrderInClass", caption = "Order attributes alphabetically", nr = 35, procedureName = "DefaultOrder.defaultOrder_specific.orderAttributesByDefaultOrderInClass", visibility = true}))
lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "RecomputeOrderAnnotations", caption = "Re-compute order annotations", nr = 36, procedureName = "DefaultOrder.defaultOrder_specific.reComputeOrderAnnotationsInClass", visibility = true}))
		
lQuery.create("PopUpElementType", {id="Order attributes by default", caption="Order attributes alphabetically", nr=35, visibility=true, procedureName="DefaultOrder.defaultOrder_specific.orderAttributesByDefaultOrderInDiagram"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))
		
lQuery.create("PopUpElementType", {id="RecomputeOrderAnnotationsInDiagram", caption="Re-compute order annotations", nr=36, visibility=true, procedureName="DefaultOrder.defaultOrder_specific.reComputeOrderAnnotationsInDiagram"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))
	
lQuery.create("PopUpElementType", {id="OrderAttributesByDefaultCollection", caption="Order attributes alphabetically", nr=35, visibility=true, procedureName="DefaultOrder.defaultOrder_specific.orderAttributesByDefaultOrderInSelectedClasses"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickCollection"))

lQuery.create("PopUpElementType", {id="RecomputeOrderAnnotationsCollection", caption="Re-compute order annotations", nr=36, visibility=true, procedureName="DefaultOrder.defaultOrder_specific.reComputeOrderAnnotationsInSelectedClasses"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickCollection"))

defaultOrder_specific.recalculateDefaultOrderForAllDiagrams()

if (lQuery("Plugin[id='OWLGrEd_Schema']"):is_not_empty() and lQuery("Plugin[id='OWLGrEd_Schema']"):attr("status") == "loaded") or (lQuery("Plugin[id='OWLGrEd_XSchema']"):is_not_empty() and lQuery("Plugin[id='OWLGrEd_XSchema']"):attr("status") == "loaded") then
	if lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):size() == 0 then
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']"):link("tag", lQuery.create("Tag",{key = 'ExportAxiom', value = ""}))
	end
	if lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):size() == 0 then
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']"):link("tag", lQuery.create("Tag",{key = 'ExportAxiom', value = ""}))
	end
	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])

	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'owl_Field_axiom']"):delete()
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'owl_Field_axiom']"):delete()
end

lQuery.create("Translet", {extensionPoint='OnDiagramExport', procedureName='DefaultOrder.defaultOrder_specific.calculateDafaultOrderOnDiagramSave'}):link("type", lQuery("ToolType"))

return true
-- return false, error_string