require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
local d = require("dialog_utilities")

local path
local picturePath

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "OWLGrEd_XSchema")
	picturePath = tda.GetToolPath().. "\\web-root\\Pictures"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_XSchema"
	picturePath = tda.GetProjectPath() .. "\\Pictures"
end	

utils.copy(path .. "\\export.BMP",
           picturePath .. "\\OWLGrEd_XSchema_export.BMP")
		   
lQuery.model.add_class("OWL_PP#ExportParameter")
lQuery.model.add_property("OWL_PP#ExportParameter", "pName")
lQuery.model.add_property("OWL_PP#ExportParameter", "pValue")


lQuery.create("OWL_PP#ExportParameter", {pName = 'includeSchemaAssertionsInAnnotationForm', pValue = 'true'})
lQuery.create("OWL_PP#ExportParameter", {pName = 'schemaExtension', pValue = 'Weak schema closure'})
lQuery.create("OWL_PP#ExportParameter", {pName = 'explicitSubProperties', pValue = 'true'})
lQuery.create("OWL_PP#ExportParameter", {pName = 'enableInversePropertyResoning', pValue = 'false'})
lQuery.create("OWL_PP#ExportParameter", {pName = 'extendByInitialChainProperties', pValue = 'false'})
lQuery.create("OWL_PP#ExportParameter", {pName = 'existentialAssertions', pValue = 'false'})


local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")
-- local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")-----------------------------------------------------

-- get or create toolbar type
local toolbarType = project_dgr_type:find("/toolbarType")
if toolbarType:is_empty() then
  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
end


local view_manager_toolbar_el = lQuery.create("ToolbarElementType", {
		  toolbarType = toolbarType,
		  id = "SchemaExportParameters",
		  caption = "Ontology export preferences",
		  picture = "OWLGrEd_XSchema_export.BMP",
		  procedureName = "OWLGrEd_XSchema.schema.exportParametersForm"
		})	
-- refresh project diagram toolbar
configurator.make_toolbar(project_dgr_type)

local pathConfiguration = path .. "\\AutoLoadConfiguration"
completeMetamodelUserFields.loadAutoLoadContextType(pathConfiguration)

--ieladet profilu
local pathContextType = path .. "\\AutoLoad"
completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)

lQuery("CompartType[id='allValuesFrom']"):attr("caption", "Schema Only (no domain assertion)")
lQuery("PropertyRow[id='allValuesFrom']"):attr("caption", "Schema Only (no domain assertion)")

lQuery("CompartType[id='noSchema']"):attr("caption", "No schema (domain only)")
lQuery("PropertyRow[id='noSchema']"):attr("caption", "No schema (domain only)")

-- lQuery("ElemType[id='Class']/compartType[id = 'ASFictitiousAttributes']/subCompartType/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
lQuery("ElemType[id='Association']/compartType[id = 'Role']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
lQuery("ElemType[id='Association']/compartType[id = 'InvRole']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
-- lQuery("ElemType[id='Class']/compartType[id = 'ASFictitiousAttributes']/subCompartType/subCompartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_XSchema.schema.setPrefixesPlus"}))
lQuery("ElemType[id='Association']/compartType[id = 'Role']/subCompartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_XSchema.schema.setPrefixesPlus"}))
lQuery("ElemType[id='Association']/compartType[id = 'InvRole']/subCompartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_XSchema.schema.setPrefixesPlus"}))

lQuery("ElemType[id='Attribute']/compartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_XSchema.schema.setPrefixesPlusAttribute"}))


-- lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
-- lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_XSchema.schema.setPrefixesPlus"}))

-- ObjectPropertyDomain([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
-- DataPropertyDomain([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)


lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/noSchema != 'true'][/noSchema != '!'] <http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

-- lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Type']/tag[key = 'ExportAxiom']"):attr("value",[[ObjectPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'ObjectProperty'][/../allValuesFrom != 'true'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))
-- DataPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'DataProperty'][/../allValuesFrom != 'true'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))]])

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../noSchema != 'true'][/../../noSchema != '+']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

-- ObjectPropertyDomain([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/start))]])

-- ObjectPropertyDomain([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))

lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/end))]])

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
	if lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):size() == 0 then
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']"):link("tag", lQuery.create("Tag",{key = 'ExportAxiom', value = ""}))
	end
	if lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):size() == 0 then
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']"):link("tag", lQuery.create("Tag",{key = 'ExportAxiom', value = ""}))
	end
	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])

	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'owl_Field_axiom']"):delete()
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'owl_Field_axiom']"):delete()

end
-------------------------------------------------------------------------
lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) ?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
---------------------------------------------


lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='hiddenCompartment']"):attr("shouldBeIncluded", "OWLGrEd_XSchema.schema.hideField")
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='hiddenCompartment']/propertyRow"):attr("shouldBeIncluded", "OWLGrEd_XSchema.schema.hideField")

lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_XSchema.schema.onAttributeOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Attributes']"))
lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_XSchema.schema.disablePropertiesOnOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Association']"))
lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_XSchema.schema.onAttributeLinkOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Attribute']"))
return true
-- return false, error_string