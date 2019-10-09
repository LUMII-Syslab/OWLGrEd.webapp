require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local d = require("dialog_utilities")

lQuery("PopUpElementType[id='TransformeToAttribute']"):delete()
	lQuery("PopUpElementType[id='AttributeToAssociation']"):delete()
	lQuery("PopUpElementType[id='TrasformToSuperClass']"):delete()
	lQuery("PopUpElementType[id='SuperClassToRestriction']"):delete()
	lQuery("PopUpElementType[id='ForkToSuperClass']"):delete()
	lQuery("PopUpElementType[id='AttributeToAttributeLink']"):delete()
	lQuery("PopUpElementType[id='AttributeToClassAttribute']"):delete()
	lQuery("PopUpElementType[id='ConnectAttributeToDataType']"):delete()


lQuery("ElemType[id='Association']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "TransformeToAttribute", caption = "Transforme To Attribute", nr = 15, procedureName = "RefactoringServices.refactoringServices.associationToAttribute", visibility = true}))
lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "AttributeToAssociation", caption = "Attribute To Association", nr = 15, procedureName = "RefactoringServices.refactoringServices.attributeToAssociation", visibility = true}))
lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "AttributeToAttributeLink", caption = "Attribute To DataType link", nr = 17, procedureName = "RefactoringServices.refactoringServices.attributeToAttributeLink", visibility = true}))
lQuery("ElemType[id='Restriction']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "TrasformToSuperClass", caption = "Trasform To SuperClass", nr = 15, procedureName = "RefactoringServices.refactoringServices.ObjectPropertyRestrictionToSuperClass", visibility = true}))
lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "SuperClassToRestriction", caption = "SuperClass To Restriction", nr = 16, procedureName = "RefactoringServices.refactoringServices.superClassToRestriction", visibility = true}))
lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "ConnectAttributeToDataType", caption = "Connect Attributes to DataTypes", nr = 17, procedureName = "RefactoringServices.refactoringServices.connectAttributeToDataType", visibility = true}))
lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "ForkToSuperClass", caption = "SuperClass as text", nr = 19, procedureName = "RefactoringServices.refactoringServices.forkToSuperClass", visibility = true}))
lQuery("ElemType[id='Attribute']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "AttributeToClassAttribute", caption = "Attribute as text", nr = 18, procedureName = "RefactoringServices.refactoringServices.attributeToClassAttribute", visibility = true}))

return true
-- return false, error_string