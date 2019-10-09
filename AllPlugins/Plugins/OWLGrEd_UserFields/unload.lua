require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")

-- delete toolbar element
lQuery("ToolbarElementType[id=OWLGrEd_UserFields_Toolbar_Element]"):delete()
lQuery("ToolbarElementType[id=OWLGrEd_UserFields_Toolbar_Element_View]"):delete()
lQuery("ToolbarElementType[id=OWLGrEd_UserFields_View_Toolbar_Element]"):delete()
lQuery("ToolbarElementType[id=OWLGrEd_UserFields_Toolbar_Element_Styles]"):delete()
lQuery("ToolbarElementType[id=OWLGrEd_UserFields_Toolbar_Element_Styles_Dia]"):delete()
--lQuery("ToolbarElementType[procedureName='OWLGrEd_UserFields.styleMechanism.applyViewFromToolBar']"):delete()


local path
local picturePath

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "OWLGrEd_UserFields")
	picturePath = tda.GetToolPath().. "\\web-root\\Pictures"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields"
	picturePath = tda.GetProjectPath() .. "\\Pictures"
end


lQuery("AA#View[showInPalette='true']"):each(function(view)
	local picture = lQuery("ToolbarElementType[id=" .. view:id() .. "]"):attr("picture")
	if picture~=nil then utils.delete(picturePath .. "\\"..picture) end
	lQuery("ToolbarElementType[id=" .. view:id() .. "]"):delete()
end)
lQuery("AA#View[showInToolBar='true']"):each(function(view)
	local picture = lQuery("ToolbarElementType[id=" .. view:id() .. "]"):attr("picture")
	if picture~=nil then utils.delete(picturePath .. "\\"..picture) end
	lQuery("ToolbarElementType[id=" .. view:id() .. "]"):delete()
end)

-- refresh project diagram
configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))

-- delete toolbar element icon
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aa.BMP")
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aaView.BMP")
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aaViewHorizontal.BMP")
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aaViewHorizontalActivated.BMP")
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aaViewVertical.BMP")
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aaViewVerticalActivated.BMP")
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aaHideAnnotations.BMP")
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aaHideAnnotationsActivated.BMP")
utils.delete(picturePath .. "\\OWLGrEd_UserFields_aaStyles.BMP")
local uncompleteMetamodel = require ("OWLGrEd_UserFields.uncompleteMetamodel")
uncompleteMetamodel.uncompleteMetamodel()

return true
-- return false, error_string