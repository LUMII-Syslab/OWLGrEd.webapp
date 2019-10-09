require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodel = require "RDB2OWL.completeMetamodel"


lQuery.model.add_class("D#MoveTextCursorCommand")
lQuery.model.add_property("D#MoveTextCursorCommand", "row")
lQuery.model.add_property("D#MoveTextCursorCommand", "horizontalPosition")
lQuery.model.set_super_class("D#MoveTextCursorCommand", "D#Command")


if lQuery("ToolbarElementType[id=RDB2OWLAutoCompletion]"):is_empty() then
	
	local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")

	-- get or create toolbar type
	local toolbarType = project_dgr_type:find("/toolbarType")
	if toolbarType:is_empty() then
	  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
	end
	
	local pl_manager_toolbar_el = lQuery.create("ToolbarElementType", {
	  toolbarType = toolbarType,
	  id = "RDB2OWLAutoCompletion",
	  caption = "Auto Completion On/Off",
	 -- picture = "OWLGrEd_UserFields_aaStyles.bmp",
	  procedureName = "RDB2OWL.completeMetamodel.onOffAutoCompletion"
	})


	configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
end
	
completeMetamodel.readUseAutoCompletion()
							
return true
-- return false, error_string