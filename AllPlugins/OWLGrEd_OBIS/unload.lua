require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
syncProfile = require "OWLGrEd_UserFields.syncProfile"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"


lQuery("ElemType[id = 'Class']/compartType[id='defaultOrder']"):attr("shouldBeIncluded", "")
lQuery("ElemType[id = 'Class']/compartType[id='defaultOrder']/propertyRow"):attr("shouldBeIncluded", "")

lQuery("ElemType[id = 'Class']/compartType[caption='view_short']"):attr("shouldBeIncluded", "")
lQuery("ElemType[id = 'Class']/compartType[caption='view_short']/propertyRow"):attr("shouldBeIncluded", "")

lQuery("ElemType[id = 'Class']/compartType[caption='report_short']"):attr("shouldBeIncluded", "")
lQuery("ElemType[id = 'Class']/compartType[caption='report_short']/propertyRow"):attr("shouldBeIncluded", "")


lQuery("ElemType[id='Class']/propertyDiagram"):find("/propertyEventHandler[eventType='onClose'][procedureName='OWLGrEd_OBIS.obis_specific.defaultOrder']"):delete()
lQuery("ElemType[id='Association']/propertyDiagram"):find("/propertyEventHandler[eventType='onClose'][procedureName='OWLGrEd_OBIS.obis_specific.replaceAxiom']"):delete()

lQuery("Translet[extensionPoint='RecalculateStylesInImport']"):attr("procedureName", 'OWLGrEd_UserFields.owl_fields_specific.setImportStyles')


lQuery("Tag[value='OWLGrEd_UserFields.axiom.axiom'][key='owlgred_export']"):attr("value", 'OWLGrEd_UserFields.axiom.axiom')

local profileName = "OBIS"
local profile = lQuery("AA#Profile[name = '" .. profileName .. "']")
--izdzest AA# Dalu
lQuery(profile):find("/field"):each(function(obj)
	profileMechanism.deleteField(obj)
end)
--saglabajam stilus
lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
end)
--palaist sinhronizaciju
syncProfile.syncProfile(profileName)
viewMechanism.deleteViewFromProfile(profileName)
--izdzest profilu, extension
lQuery(profile):delete()
lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):delete()

return true
-- return false, error_string