require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local d = require("dialog_utilities")

lQuery("PopUpElementType[id='VisualMetrics']"):delete()

lQuery("GraphDiagramType[id='OWL']/rClickEmpty"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "VisualMetrics", caption = "Visual Metrics", nr = 40, procedureName = "VisualMetrics.VisualMetrics.showDialog", visibility = true}))

return true
-- return false, error_string