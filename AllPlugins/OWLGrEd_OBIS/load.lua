require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
local d = require("dialog_utilities")

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "OWLGrEd_OBIS")
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_OBIS"
end

--ieladet konfiguraciju
local pathConfiguration = path .. "\\AutoLoadConfiguration"
completeMetamodelUserFields.loadAutoLoadContextType(pathConfiguration)

--ieladet OBIS profilu
local pathContextType = path .. "\\AutoLoad"
completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)


lQuery("ElemType[id = 'Class']/compartType[id='defaultOrder']"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")
lQuery("ElemType[id = 'Class']/compartType[id='defaultOrder']/propertyRow"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")

lQuery("ElemType[id = 'Class']/compartType[caption='view_short']"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")
lQuery("ElemType[id = 'Class']/compartType[caption='view_short']/propertyRow"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")

lQuery("ElemType[id = 'Class']/compartType[caption='report_short']"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")
lQuery("ElemType[id = 'Class']/compartType[caption='report_short']/propertyRow"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")


lQuery("ElemType[id='Class']/propertyDiagram"):link("propertyEventHandler", lQuery.create("PropertyEventHandler", {eventType = "onClose", procedureName = "OWLGrEd_OBIS.obis_specific.defaultOrder"}))
lQuery("ElemType[id='Association']/propertyDiagram"):link("propertyEventHandler", lQuery.create("PropertyEventHandler", {eventType = "onClose", procedureName = "OWLGrEd_OBIS.obis_specific.replaceAxiom"}))

lQuery("Translet[extensionPoint='RecalculateStylesInImport']"):attr("procedureName", 'OWLGrEd_OBIS.obis_specific.setImport')


lQuery("ToolType"):find("/tag[key = 'DefaultMaxCardinality1']"):attr("value", 1)
-- print("ddddddd", lQuery("ToolType"):find("/tag[key = 'DefaultMaxCardinality1']"):attr("value"))
return true
-- return false, error_string