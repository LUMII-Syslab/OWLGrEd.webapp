require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"

lQuery.create("PopUpElementType", {id="transform_property_names", caption="Transform Property Names", nr=30, visibility=true, procedureName="RefactoringDB.transformation.transform_property_names"})
	:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))

lQuery.create("PopUpElementType", {id="orderAttributesDiagramm", caption="Order Attributes", nr=31, visibility=true, procedureName="RefactoringDB.transformation.orderAttributesDiagramm"})
	:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))
		
lQuery.create("PopUpElementType", {id="orderAttributesClass", caption="Order Attributes", nr=32, visibility=true, procedureName="RefactoringDB.transformation.orderAttributesClass"})
	:link("popUpDiagramType", lQuery("ElemType[id='Class']/popUpDiagramType"))

return true
-- return false, error_string