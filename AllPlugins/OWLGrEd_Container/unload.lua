require("lQuery")
local del = require("configurator.delete")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
syncProfile = require "OWLGrEd_UserFields.syncProfile"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"


local profileName = "Container"
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
-- viewMechanism.deleteViewFromProfile(profileName)
--izdzest profilu, extension
lQuery(profile):delete()
lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):delete()

local contextType = lQuery("AA#ContextType[type='Container']")
contextType:delete()

local presentation = lQuery("ElemType[id='Container']/presentation")
del.delete_elem_type(lQuery("ElemType[id='Container']"))
presentation:delete()

-- lQuery("PropertyEventHandler[procedureName='OWLGrEd_Container.container.setUniqueContainerName']"):delete()
-- lQuery("PaletteElementType[id='Container']"):delete()
-- lQuery("NodeStyle[id='Container']"):delete()
-- lQuery("ElemType[id='Container']/presentation"):delete()
-- lQuery("ElemType[id='Container']"):delete()


lQuery("ElemType[id='Class']/tag[key ='ExportAxiom']"):delete()
lQuery("ElemType[id='Object']/tag[key ='ExportAxiom']"):delete()
lQuery("ElemType[id='DataType']/tag[key ='ExportAxiom']"):delete()
lQuery("ElemType[id='AnnotationProperty']/tag[key ='ExportAxiom']"):delete()

lQuery("ElemType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[Annotation([/eStart:$isEmpty == true][/eEnd:$isEmpty== true][/Property:$isEmpty == true] $getUri(/AnnotationType) "$value(/ValueLanguage/Value)"?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eStart/end:$elemType == 'Class'][/Property:$isEmpty == true]$getUri(/AnnotationType) $getClassExpr(/eStart/end) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eEnd/start:$elemType == 'Class'][/Property:$isEmpty == true]$getUri(/AnnotationType) $getClassExpr(/eEnd/start) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eStart/end:$elemType == 'Object'][/Property:$isEmpty == true]$getUri(/AnnotationType) $getObjectExpr(/eStart/end) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eEnd/start:$elemType == 'Object'][/Property:$isEmpty == true]$getUri(/AnnotationType) $getObjectExpr(/eEnd/start) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/Property:$isEmpty != true]$getUri(/AnnotationType) $getUri(/Property) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

return true
-- return false, error_string