require("lQuery")


local plugin_name = "RefactoringServices"

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "RefactoringServices") .. "/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\RefactoringServices\\"
end

local plugin_info_path = path .. "info.lua"
local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*a"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")


if current_version < "0.5" and current_version < plugin_version then

	lQuery("PopUpElementType[id='TransformeToAttribute']"):delete()
	lQuery("PopUpElementType[id='AttributeToAssociation']"):delete()
	lQuery("PopUpElementType[id='TrasformToSuperClass']"):delete()
	lQuery("PopUpElementType[id='SuperClassToRestriction']"):delete()
	lQuery("PopUpElementType[id='ForkToSuperClass']"):delete()
	lQuery("PopUpElementType[id='AttributeToAttributeLink']"):delete()
	lQuery("PopUpElementType[id='AttributeToClassAttribute']"):delete()
	lQuery("PopUpElementType[id='ConnectAttributeToDataType']"):delete()

	lQuery("ElemType[id='Association']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "TransformeToAttribute", caption = "Transforme To Attribute", nr = 15, procedureName = "RefactoringServices.refactoringServices.associationToAttribute", visibility = true}))
	lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "AttributeToAssociation", caption = "Attribute To Association", nr = 16, procedureName = "RefactoringServices.refactoringServices.attributeToAssociation", visibility = true}))
	lQuery("ElemType[id='Restriction']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "TrasformToSuperClass", caption = "Trasform To SuperClass", nr = 17, procedureName = "RefactoringServices.refactoringServices.ObjectPropertyRestrictionToSuperClass", visibility = true}))
	lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "SuperClassToRestriction", caption = "SuperClass To Restriction", nr = 18, procedureName = "RefactoringServices.refactoringServices.superClassToRestriction", visibility = true}))
	lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "ForkToSuperClass", caption = "SuperClass as text", nr = 19, procedureName = "RefactoringServices.refactoringServices.forkToSuperClass", visibility = true}))
	lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "AttributeToAttributeLink", caption = "Attribute To DataType link", nr = 20, procedureName = "RefactoringServices.refactoringServices.attributeToAttributeLink", visibility = true}))
	lQuery("ElemType[id='Attribute']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "AttributeToClassAttribute", caption = "Attribute as text", nr = 21, procedureName = "RefactoringServices.refactoringServices.attributeToClassAttribute", visibility = true}))
	lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "ConnectAttributeToDataType", caption = "Connect Attributes to DataTypes", nr = 22, procedureName = "RefactoringServices.refactoringServices.connectAttributeToDataType", visibility = true}))
end
if current_version < "0.6" and current_version < plugin_version then

	lQuery("ElemType[id='Class']/popUpDiagramType"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "EquivalentClassAsText", caption = "EquivalentClass as text", nr = 23, procedureName = "RefactoringServices.refactoringServices.equivalentClassAsText", visibility = true}))
end
			
return true
-- return false, error_string