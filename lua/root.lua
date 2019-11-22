module(..., package.seeall)
const = require("configurator.const.const")
require("utilities")
report = require("reporter.report")
--MM = require("MM_build")

function create_project()
    lQuery.create("AttachEngineCommand", {
	name = "GraphDiagramEngine" })
                :link("submitter", lQuery("Submitter"))
                :delete()
    lQuery.create("AttachEngineCommand", {
	name = "TreeEngine" })
                :link("submitter", lQuery("Submitter"))
                :delete()
    lQuery.create("AttachEngineCommand", {
	name = "DialogEngine" })
                :link("submitter", lQuery("Submitter"))
                :delete()
	dofile(tda.GetRuntimePath() .. "/lua/configurator/MetaModels/TypeAndMappingMM.lua")
	const.const()
	open_project_diagram()
	report.event("New Project", {
		Name = lQuery("Project"):attr("name")
	})
	--utilities.execute_translet("utilities.session_started")
end

function open_project_diagram()
	local path = utilities.get_project_name()
	first(path)
end

function first(project_name)
	local tool_type = lQuery("ToolType")
	local project = tool_type:find("/presentationElement")
	project:attr({name = project_name, version = 0})
	local diagram = project:find("/graphDiagram")
	diagram:link("project", project)
	utilities.add_tag(project, "isFirstVersion", "true")
	utilities.execute_cmd("ActiveDgrCmd", {graphDiagram = diagram})
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end
