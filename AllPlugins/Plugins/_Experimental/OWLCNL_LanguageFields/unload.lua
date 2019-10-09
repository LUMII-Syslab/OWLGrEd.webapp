require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
syncProfile = require "OWLGrEd_UserFields.syncProfile"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"

lQuery("ToolbarElementType[id=UpdateLexicon]"):delete()
lQuery("ToolbarElementType[id=LexicalizeOntology]"):delete()

-- refresh project diagram toolbar
configurator.make_toolbar(owl_dgr_type)


lQuery("Translet[procedureName='OWLCNL_LanguageFields.OWL_CNL_specific.compose_attribute_input']"):delete()
lQuery("Translet[procedureName='OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label']"):delete()
lQuery("Translet[procedureName='OWLCNL_LanguageFields.OWL_CNL_specific.set_attr_display_label']"):delete()
lQuery("PopUpElementType[procedureName='OWLCNL_LanguageFields.OWL_CNL_specific.save_as_cnl']"):delete()

--DynamicTooltip dzesana
local elem_type_ids_to_add_dynamic_tooltip = {
    'Class',
    'Association',
    'Generalization',
    'Restriction',
    'HorizontalFork',
    'AssocToFork',
    'GeneralizationToFork',
    'Object',
    'Link',
    'EquivalentClasses',
    'DisjointClasses',
  }

  for _,elemType_id in  ipairs(elem_type_ids_to_add_dynamic_tooltip) do
    lQuery("ElemType[id='" .. elemType_id .. "']"):find("/translet[extensionPoint='procDynamicTooltip'][procedureName='owl_protege.tooltip']"):delete()
  end



local profileName = 'OWLCNL_LanguageFields'
local profile = lQuery("AA#Profile[name = '" .. profileName .. "']")
--izdzest AA# Dalu
lQuery(profile):find("/field"):each(function(obj)
	profileMechanism.deleteField(obj)
end)
--saglabajam stilus
lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
end)
--palaist sinhronizaciju
syncProfile.syncProfile(profileName)
viewMechanism.deleteViewFromProfile(profileName)
--izdzest profilu, extension
lQuery(profile):delete()
lQuery("Extension[id='" .. profileName .. "']"):delete()


return true
-- return false, error_string