-- require code modeles
require("lQuery")
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
	-- reference to completeMetamodel.lua within OWLGrEd_UserFields folder

-- OWLGrEd namespace is http://lumii.lv/2011/1.0/owlgred#

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "UML_Plus")
else
	path = tda.GetProjectPath() .. "\\Plugins\\UML_Plus"
end

-- load additional configuration (not present for UML_Plus extension)
local pathConfiguration = path .. "\\AutoLoadConfiguration"
completeMetamodelUserFields.loadAutoLoadContextType(pathConfiguration)

-- load custom field definitions
local pathContextType = path .. "\\AutoLoad"
completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)

-- add translet to extension point RecalculateStylesInImport
lQuery("Translet[extensionPoint='RecalculateStylesInImport']"):attr("procedureName", 'UML_Plus.uml_plus_specific.setImport')


lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):last():delete()

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):last():delete()

return true

