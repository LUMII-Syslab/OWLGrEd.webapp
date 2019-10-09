require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local d = require("dialog_utilities")

lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "TransformClassToAssociations", caption = "Transform class to associations", nr = 25, procedureName = "UR.ur.transformClassToAssociations", visibility = true}))

lQuery.create("PopUpElementType", {id="Transform data type names", caption="Transform data type names", nr=36, visibility=true, procedureName="UR.ur.tarnsformDataTypeNames"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))

return true
-- return false, error_string