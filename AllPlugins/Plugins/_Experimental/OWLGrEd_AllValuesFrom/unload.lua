require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
syncProfile = require "OWLGrEd_UserFields.syncProfile"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"


local profileName = "AllValuesFrom"
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

lQuery("ElemType[id='Association']/compartType[id = 'Role']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
lQuery("ElemType[id='Association']/compartType[id = 'InvRole']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
ObjectPropertyDomain([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
DataPropertyDomain([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)]])

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Type']/tag[key = 'ExportAxiom']"):attr("value",[[ObjectPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'ObjectProperty'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))
DataPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'DataProperty'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))]])

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion($getUri(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain( $getUri(/Name /Namespace) $getDomainOrRange(/start))
ObjectPropertyRange( $getUri(/Name /Namespace) $getDomainOrRange(/end))]])

lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain($getUri(/Name /Namespace) $getDomainOrRange(/end))
ObjectPropertyRange($getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))]])

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getUri(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getUri(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])



return true
-- return false, error_string