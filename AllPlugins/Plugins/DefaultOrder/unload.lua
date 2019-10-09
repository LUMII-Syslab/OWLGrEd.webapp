require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
syncProfile = require "OWLGrEd_UserFields.syncProfile"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"


lQuery("ElemType[id = 'Class']/compartType[id='defaultOrder']"):attr("shouldBeIncluded", "")
lQuery("ElemType[id = 'Class']/compartType[id='defaultOrder']/propertyRow"):attr("shouldBeIncluded", "")



lQuery("ElemType[id='Class']/propertyDiagram"):find("/propertyEventHandler[eventType='onClose'][procedureName='DefaultOrder.defaultOrder_specific.defaultOrder']"):delete()

lQuery("ElemType[id='Class']/popUpDiagramType/popUpElementType[id = 'orderAttributesByDefaultOrderInClass']"):delete()
lQuery("ElemType[id='Class']/popUpDiagramType/popUpElementType[id = 'RecomputeOrderAnnotations']"):delete()
lQuery("PopUpElementType[id='Order attributes by default']"):delete()
lQuery("PopUpElementType[id='RecomputeOrderAnnotationsInDiagram']"):delete()
lQuery("PopUpElementType[id='OrderAttributesByDefaultCollection']"):delete()
lQuery("PopUpElementType[id='RecomputeOrderAnnotationsCollection']"):delete()

local profileName = "DefaultOrder"
local profile = lQuery("AA#Profile[name = '" .. profileName .. "']")
local profileAssociation = lQuery("AA#Profile[name = 'DefaultOrderAssociation']")
--izdzest AA# Dalu
lQuery(profile):find("/field"):each(function(obj)
	profileMechanism.deleteField(obj)
end)
lQuery(profileAssociation):find("/field"):each(function(obj)
	profileMechanism.deleteField(obj)
end)
--saglabajam stilus
lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
end)
--palaist sinhronizaciju
syncProfile.syncProfile(profileName)
syncProfile.syncProfile('DefaultOrderAssociation')
viewMechanism.deleteViewFromProfile(profileName)
viewMechanism.deleteViewFromProfile('DefaultOrderAssociation')
--izdzest profilu, extension
lQuery(profile):delete()
lQuery(profileAssociation):delete()
lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):delete()
lQuery("Extension[id='DefaultOrderAssociation'][type='aa#Profile']"):delete()


lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):delete()
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):delete()

return true
-- return false, error_string