require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")



-- refresh project diagram
--configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
--configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))


lQuery("Tag[value='OWLGrEd_UserFields.axiom.axiom'][key='owlgred_export']"):attr("value", 'OWLGrEd_UserFields.axiom.axiom')

return true
-- return false, error_string