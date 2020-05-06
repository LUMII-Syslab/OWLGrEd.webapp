require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodel = require "RDB2OWL_AutoCompletion.completeMetamodel"
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"


local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")
local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")

-- get or create toolbar type
local toolbarType = project_dgr_type:find("/toolbarType")
if toolbarType:is_empty() then
  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
end

local toolbarTypeOwl = owl_dgr_type:find("/toolbarType")
if toolbarTypeOwl:is_empty() then
  toolbarTypeOwl = lQuery.create("ToolbarType", {graphDiagramType = owl_dgr_type})
end

-- add plugin manager toolbar element

local pl_manager_toolbar_el = lQuery.create("ToolbarElementType", {
  toolbarType = toolbarTypeOwl,
  id = "RDB2OWLDatabase",
  caption = "Generate Database instances",
 -- picture = "OWLGrEd_UserFields_aaStyles.bmp",
  procedureName = "RDB2OWL_AutoCompletion.reGrammar.generateDatabaseInstances"
})

local pl_manager_toolbar_el = lQuery.create("ToolbarElementType", {
  toolbarType = toolbarType,
  id = "RDB2OWLAutoCompletion",
  caption = "Auto Completion On/Off",
 -- picture = "OWLGrEd_UserFields_aaStyles.bmp",
  procedureName = "RDB2OWL_AutoCompletion.completeMetamodel.onOffAutoCompletion"
})

-- refresh project diagram toolbar
configurator.make_toolbar(project_dgr_type)
configurator.make_toolbar(owl_dgr_type)

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "RDB2OWL_AutoCompletion") .. "/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\RDB2OWL_AutoCompletion\\"
end

--ieladet DBExpr profilu
local pathContextType = path .. "AutoLoad"
completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)

--complete metamodel
completeMetamodel.completeMetamodel()



return true
-- return false, error_string