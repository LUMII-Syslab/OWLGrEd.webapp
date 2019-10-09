local owl2_domain = require"OWLGrED_Domain.owl2_domain"
local configurator = require("configurator.configurator")
--local parameters_form = require"OWLGrED_Domain.parameters_form"

owl2_domain.load_owl2_domain()
owl2_domain.add_and_fill_parameters()
--parameters_form.show_main_window()

local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")

-- get or create toolbar type
local toolbarType = project_dgr_type:find("/toolbarType")
if toolbarType:is_empty() then
  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
end


local view_manager_toolbar_el = lQuery.create("ToolbarElementType", {
		  toolbarType = toolbarType,
		  id = "Domain",
		  caption = "Domain",
		  procedureName = "OWLGrEd_Domain.parameters_form.show_main_window"
		})

configurator.make_toolbar(project_dgr_type)		
return true
-- return false, error_string