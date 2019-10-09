require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
local d = require("dialog_utilities")



lQuery.create("PopUpElementType", {id="Merge_disjoints_into_forks", caption="Merge disjoints into forks", nr=20, visibility=true, procedureName="OWLGrEd_Disjoint_to_fork.disjoint_to_fork.merge_disjoint_into_forks"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))

lQuery.create("PopUpElementType", {id="Merge_disjoints_into_fork", caption="Merge disjoint into fork", nr=20, visibility=true, procedureName="OWLGrEd_Disjoint_to_fork.disjoint_to_fork.merge_disjoint_into_fork"})
		:link("popUpDiagramType", lQuery("ElemType[id='HorizontalFork']/popUpDiagramType"))

lQuery.create("PopUpElementType", {id="Merge disjoint into forks (split forks)", caption="Merge disjoint into forks (split forks)", nr=20, visibility=true, procedureName="OWLGrEd_Disjoint_to_fork.disjoint_to_fork.split_fork_disjoint"})
		:link("popUpDiagramType", lQuery("ElemType[id='HorizontalFork']/popUpDiagramType"))
		
return true
-- return false, error_string