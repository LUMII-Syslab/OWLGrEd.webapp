require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
syncProfile = require "OWLGrEd_UserFields.syncProfile"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"


lQuery("Translet[extensionPoint='RecalculateStylesInImport']"):attr("procedureName", 'OWLGrEd_UserFields.owl_fields_specific.setImportStyles')

local profileName = "UML_Plus"

-- delete custom field definitions (AA# part in the metamodel), introduced by the extension
local profile = lQuery("AA#Profile[name = '" .. profileName .. "']")
lQuery(profile):find("/field"):each(function(obj)
	profileMechanism.deleteField(obj)
end)

-- save the re-calculated styles (after the custom field definition removal)
lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
end)

-- delete the extension profile custom fields from diagrams
syncProfile.syncProfile(profileName)
viewMechanism.deleteViewFromProfile(profileName)

-- delete the extension definitions
lQuery(profile):delete()
lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):delete()

return true
