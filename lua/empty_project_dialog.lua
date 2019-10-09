module(..., package.seeall)

require "utilities"
require "owl_protege"
require "core"
d = require("dialog_utilities")

local empty_project_form_id = "owlgred_empty_project_dialog"

function navigate()
	utilities.navigate(utilities.active_elements())
end

local button_height = 60

function open()
	local form = lQuery.create("D#Form", {
		caption = "OWLGrEd",
		id = empty_project_form_id,
		buttonClickOnClose = false,
		eventHandler = utilities.d_handler("Close", "lua_engine", "lua.empty_project_dialog.close_dialog"),
		minimumHeight = 300,
		minimumWidth = 300,
	    component = {
	      lQuery.create("D#VerticalBox", {
					-- horizontalAlignment = 1,
	        component = {
	          lQuery.create("D#Button", {
		          caption = "Visualize Ontology"
		          ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.empty_project_dialog.open_ontology()")
		          ,minimumHeight = button_height
		        }),
						lQuery.create("D#Button", {
		          caption = "Visualize Ontology Module"
		          ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.empty_project_dialog.open_ontology_module()")
		          ,minimumHeight = button_height
		        }),
						lQuery.create("D#Button", {
		          caption = "Create Ontology"
		          ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.empty_project_dialog.create_ontology()")
		          ,minimumHeight = button_height
		        }),
	        }
      	  })
    	}
  	})
	d.show_form(form)
end

function close_dialog()
	utilities.close_form(empty_project_form_id)
end

function open_ontology()
	utilities.close_form(empty_project_form_id)
	load_or_reopen_dialog()
end

function open_ontology_module()
	utilities.close_form(empty_project_form_id)
	owl_protege.open_module_specification_dialog({call_on_fail = "empty_project_dialog.open"})
end

function load_or_reopen_dialog()
	local ontology_loaded = owl_protege.select_and_load_ontology(tda.GetRuntimePath().."\\..\\sample ontologies")
	if not ontology_loaded then
--		open()
	end
end

function create_ontology()
	utilities.close_form(empty_project_form_id)
	local project_diagram = lQuery("Project/graphDiagram")
	local owl_seed_type = project_diagram:find("/graphDiagramType/elemType[id=OWL]")
	core.add_node_with_restrictions(owl_seed_type, lQuery({}), project_diagram, true)
	-- utilities.enqued_cmd("ExecTransfCmd", {info = "lua_engine#lua.empty_project_dialog.navigate"})
end