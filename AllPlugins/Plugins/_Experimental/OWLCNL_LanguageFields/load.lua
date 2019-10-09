require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodel = require "OWLCNL_LanguageFields.completeMetamodel"
local OWL_CNL_specific = require "OWLCNL_LanguageFields.OWL_CNL_specific"
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"

local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")

local toolbarTypeOwl = owl_dgr_type:find("/toolbarType")
if toolbarTypeOwl:is_empty() then
  toolbarTypeOwl = lQuery.create("ToolbarType", {graphDiagramType = owl_dgr_type})
end

local path
local picturePath

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "OWLCNL_LanguageFields")
	picturePath = tda.GetToolPath().. "\\web-root\\Pictures"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLCNL_LanguageFields"
	picturePath = tda.GetProjectPath() .. "\\Pictures"
end	

utils.copy(path .. "\\aaCNL.bmp",
           picturePath .. "\\OWLCNL_LanguageFields_aaCNL.bmp")

local toolbar_el = lQuery.create("ToolbarElementType", {
  toolbarType = toolbarTypeOwl,
  id = "UpdateLexicon",
  caption = "Update Lexicon",
  picture = "OWLGrEd_CNL_UpdateLexicon.bmp",
  procedureName = "OWLCNL_LanguageFields.OWL_CNL_specific.OWLGrEd_CNL_UpdateLexicon"
})

local toolbar_el2 = lQuery.create("ToolbarElementType", {
  toolbarType = toolbarTypeOwl,
  id = "LexicalizeOntology",
  caption = "Verbalize Ontology",
  picture = "OWLCNL_LanguageFields_aaCNL.bmp",
  procedureName = "OWLCNL_LanguageFields.OWL_CNL_specific.LexicalizeOntology"
})

-- refresh project diagram toolbar
configurator.make_toolbar(owl_dgr_type)

--ieladet konfiguraciju
local pathConfiguration = path .. "\\AutoLoadConfiguration"
completeMetamodelUserFields.loadAutoLoadContextType(pathConfiguration)

--ieladet DBExpr profilu
local pathContextType = path .. "\\AutoLoad"
completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)

--complete metamodel
completeMetamodel.completeMetamodel()



-- local compartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']/subCompartType[id='Name']")
-- lQuery.create("Translet", {extensionPoint = 'procIsHidden', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.is_hidden'}):link("type", compartType)

lQuery.create("Translet", {extensionPoint='LoadOntology', procedureName='OWLCNL_LanguageFields.languageFields.set_display_label_and_CNL_JSON_tag_for_all_elements'}):link("type", lQuery("ToolType"))
	

local compartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']")
lQuery.create("Translet", {extensionPoint = 'procCompose', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.compose_attribute_input'}):link("type", compartType)

local compartType = lQuery("ElemType[id='Class']/compartType[id='Name']/subCompartType[id='Name']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Class']/compartType[id='Name']/subCompartType[id='Namespace']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']/subCompartType[id='Name']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_attr_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']/subCompartType[id='Namespace']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_attr_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Object']/compartType[id='Title']/subCompartType[id='Name']/subCompartType[id='Name']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Object']/compartType[id='Title']/subCompartType[id='Name']/subCompartType[id='Namespace']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/subCompartType[id='Name']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/subCompartType[id='Namespace']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/subCompartType[id='Name']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/subCompartType[id='Namespace']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)

local compartType = lQuery("ElemType[id='Link']/compartType[id='Direct']/subCompartType[id='Property']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)
local compartType = lQuery("ElemType[id='Link']/compartType[id='Inverse']/subCompartType[id='InvProperty']")
lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLCNL_LanguageFields.OWL_CNL_specific.set_display_label'}):link("type", compartType)


--lQuery("CompartType[id='DisplayLabel']/propertyRow"):attr("isReadOnly", true)
lQuery("CompartType[id='DisplayLabel']"):each(function(dl)
	if dl:find("/parentCompartType/elemType"):is_not_empty() and dl:find("/parentCompartType/elemType"):attr("id")== "Link" then
	else
	    dl:find("/propertyRow"):attr("isReadOnly", true)
	end
end)

--OWL_CNL_specific.add_dynamic_tooltip_translets_and_style()

lQuery.create("PopUpElementType", {id="Save Verbalized Ontology", caption="Save Verbalized Ontology", nr=6, visibility=true, procedureName="OWLCNL_LanguageFields.OWL_CNL_specific.save_as_cnl"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))

		
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
	'Dependency',
	'Disjoint',
	'EquivalentClass',
	'ComplementOf',
	'SameAsIndivid',
	'DifferentIndivid'
  }
		
  for i,elemType_id in  ipairs(elem_type_ids_to_add_dynamic_tooltip) do
    lQuery.create("PopUpElementType", {id="Verbalize element", caption="Verbalize element", nr=10, visibility=true, procedureName="OWLCNL_LanguageFields.OWL_CNL_specific.verbalize_element"})
		:link("popUpDiagramType", lQuery("ElemType[id='"..elemType_id.."']/popUpDiagramType"))
	--dt.add_dynamic_tooltip_to(elemType_id, 'OWLCNL_LanguageFields.OWL_CNL_specific.tooltip')
  end

  lQuery("ElemType[id='Class']/compartType[id='Name']/subCompartType[id='Name']/propertyRow"):attr("isFirstRespondent", "false")
  lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']/subCompartType[id='Name']/propertyRow"):attr("isFirstRespondent", "false")
  lQuery("ElemType[id='Object']/compartType[id='Title']/subCompartType[id='Name']/subCompartType[id='Name']/propertyRow"):attr("isFirstRespondent", "false")
  lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/subCompartType[id='Name']/propertyRow"):attr("isFirstRespondent", "false")
  lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/subCompartType[id='Name']/propertyRow"):attr("isFirstRespondent", "false")
  
return true
-- return false, error_string