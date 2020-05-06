require("lQuery")
local plugin_name = "OWLGrEd_Container"

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_Container") .. "/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_Container\\"
end

local plugin_info_path = path .. "info.lua"
local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*a"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")


if current_version < "0.2" and current_version < plugin_version then
	lQuery("ElemType[id='Class']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getUri(/Name /Namespace) $getContainer)'}))
	lQuery("ElemType[id='Object']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Title/Name:$getUri(/Name /Namespace) $getContainer)'}))
	lQuery("ElemType[id='DataType']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getUri(/Name /Namespace) $getContainer)'}))
	lQuery("ElemType[id='AnnotationProperty']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getAnnotationProperty(/Name /Namespace) $getContainer)'}))

	lQuery("ElemType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[Annotation([/eStart:$isEmpty == true][/eEnd:$isEmpty== true][/Property:$isEmpty == true]?(Annotation([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> $getContainer)) $getAnnotationProperty(/AnnotationType) "$value(/ValueLanguage/Value)"?(@$value(/ValueLanguage/Language)))
	AnnotationAssertion([/eStart/end:$elemType == 'Class'][/Property:$isEmpty == true]$getAnnotationProperty(/AnnotationType) $getClassExpr(/eStart/end) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
	AnnotationAssertion([/eEnd/start:$elemType == 'Class'][/Property:$isEmpty == true]$getAnnotationProperty(/AnnotationType) $getClassExpr(/eEnd/start) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
	AnnotationAssertion([/eStart/end:$elemType == 'Object'][/Property:$isEmpty == true]$getAnnotationProperty(/AnnotationType) $getObjectExpr(/eStart/end) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
	AnnotationAssertion([/eEnd/start:$elemType == 'Object'][/Property:$isEmpty == true]$getAnnotationProperty(/AnnotationType) $getObjectExpr(/eEnd/start) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
	AnnotationAssertion([/Property:$isEmpty != true]$getAnnotationProperty(/AnnotationType) $getUri(/Property) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
end			
return true
-- return false, error_string