require("lQuery")
local plugin_name = "OWLGrEd_XSchema"

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_XSchema") .. "/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_XSchema\\"
end

local plugin_info_path = path .. "info.lua"
local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*a"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")



if current_version < "0.2" and current_version < plugin_version then
	local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
	
	local pathConfiguration = path .. "AutoLoadConfiguration"
	completeMetamodelUserFields.loadAutoLoadContextType(pathConfiguration)
	
	local pathContextType = path .. "AutoLoadAttributes"
	completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)
	
	lQuery("CompartType[id='allValuesFrom']"):attr("caption", "Schema Only (no domain assertion)")
	lQuery("PropertyRow[id='allValuesFrom']"):attr("caption", "Schema Only (no domain assertion)")

	lQuery("CompartType[id='noSchema']"):attr("caption", "No schema (domain only)")
	lQuery("PropertyRow[id='noSchema']"):attr("caption", "No schema (domain only)")
	
	lQuery("ElemType[id='Attribute']/compartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_XSchema.schema.setPrefixesPlusAttribute"}))

	lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_XSchema.schema.onAttributeLinkOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Attribute']"))

	lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

	lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) ?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

end

if current_version < "0.3" and current_version < plugin_version then
	if lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue") ~= "Weak schema closure" and lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue") ~= "Strict schema closure" and lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue") ~= "Standard (non-shema) ontology only" then
		lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue", 'Weak schema closure')
		
		
		if lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "true" then
			lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/noSchema != 'true'][/noSchema != '!'] <http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

			lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../noSchema != 'true'][/../../noSchema != '+']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

			lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

			lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) ?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/start))]])

			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/end))]])

			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		else
			lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

			lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]])

			lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]])

			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]])

			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		end
	end
end
	
return true
-- return false, error_string