require("lQuery")

local plugin_name = "OWLGrEd_AllValuesFrom"

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_AllValuesFrom") .. "/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_AllValuesFrom\\"
end

local plugin_info_path = path .. "info.lua"
local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*a"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")


if current_version < "0.2" and current_version < plugin_version then
	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
	Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
	ObjectPropertyDomain([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
	DataPropertyDomain([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
	SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom == 'true'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
	SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom == 'true'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
	AnnotationAssertion([/allValuesFrom == 'true'] <http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr)]])

	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Type']/tag[key = 'ExportAxiom']"):attr("value",[[ObjectPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'ObjectProperty'][/../allValuesFrom != 'true'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))
	DataPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'DataProperty'][/../allValuesFrom != 'true'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))]])

	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion(?([/../../allValuesFrom == 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr)) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
	ObjectPropertyDomain([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
	ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
	SubClassOf([/../allValuesFrom == 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
	AnnotationAssertion([/../allValuesFrom == 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/start))]])

	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
	ObjectPropertyDomain([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
	ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
	InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
	SubClassOf([/../allValuesFrom == 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
	AnnotationAssertion([/../allValuesFrom == 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/end))]])

	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../allValuesFrom == 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../allValuesFrom == 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

end

						
return true
-- return false, error_string