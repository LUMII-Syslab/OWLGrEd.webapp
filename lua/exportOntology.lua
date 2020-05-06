module(..., package.seeall)

local MP = require("ManchesterParser")
local t_to_p = require("tda_to_protege")
local configurator = require("configurator.configurator")
require "java"

local source
local axiom
local generateAxiom = true
local UnParsedExpressions = {}
local count = 0
local allAxioms = ""
local allAnnotationAxioms = ""
local diagram
local ns_uri_table
local data_property_uri_table
local object_property_uri_table
local ns_uri_table_annot = {}
local classList
local datatypeList
local t


function getImports(ontology)
	local project = lQuery("Project")
	local tag_ = utilities.get_tags(project, "Path")
	local path = tag_:attr("value")
	path = string.sub(path, 1, string.find(path, "\\[^\\]*$"))
	local imports = ""
	local importedDiagrams = ontology:find("/eStart/end")
	importedDiagrams:each(function(imp)
		local dia = imp:find("/child")
		local diaName = imp:find("/compartment:has(/compartType[id='Name'])"):attr("value")
		if string.find(diaName, ".owl") == nil then diaName = diaName .. ".owl" end
		-- diaName = string.gsub(diaName, "%/", "\\")
		path = path:gsub("\\", "/")
		imports = imports .. "Import( <file:///" .. path .. diaName .. ">)\n"
		saveOntology(path .. diaName, dia)
	end)
	return imports
end

function saveOntology(path, dia)
	if path ~= nil and path ~= "" then
		typeIndex = 2
		-- tag_:attr({value = path})
		local OWL_specific = require("OWL_specific")
		local ontology_text = OWL_specific.ontology_functional_form(dia)
		local diagram_name = dia:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")
		if diagram_name == nil or diagram_name == "" then
			diagram_name = os.tmpname() .. ".owl"
		end
		local path_to_file = path

		if typeIndex == 4 then --typeIndex = 4 means the user selected All files. In this case, let's have it mean functional syntax without using OWL API.
			local export_file = io.open(path_to_file, "w")
			if export_file == nil then
				show_msg("failed to create the file:\n" .. path_to_file)
			else
				export_file:write(ontology_text)
				export_file:close()
				print ("Ontology successfully saved in Functional notation file at "..path_to_file)
			end
		else
			--this block handles saving the file with OWL API.
			local types = {"RDF/XML", "OWL/XML", "Functional", "Manchester"}

			--Java only takes one string as an argument, so we need to combine all things into one string. Use \n as delimiter.
			--typeIndex +1 is used because typeIndex values start from 0, while Lua table indices normally start from 1 and I'm too lazy to change that
			local combinedOntologyString = path_to_file.."\n"..types[typeIndex + 1].."\n"..ontology_text
			--print (combinedOntologyString)

			--Java creates the file and reports results to Lua
			local saveResult = java.call_static_class_method("OntologySaver", "saveOntologyToFile", combinedOntologyString)
			-- print (saveResult)
		end
	end
end

function getAnnotationPropertyNS(diagram, ns_uri_table)
	
	-- print(dumptable(ns_uri_table))
	
	local tableTemp = {}
	diagram:find("/element"):each(function(el)
		if el:find("/elemType"):attr("id") == "OntologyFragment" then
			el:find("/child"):each(function(d)
				for k, v in pairs(getAnnotationPropertyNS(d, ns_uri_table)) do
					tableTemp[k] = v
				end
			end)
		end
		if el:find("/elemType"):attr("id") == "AnnotationProperty" then
			local nameComp =  el:find("/compartment:has(/compartType[id='Name'])")
			tableTemp[nameComp:find("/subCompartment:has(/compartType[id='Name'])"):attr("value")] = "<"..ns_uri_table[nameComp:find("/subCompartment:has(/compartType[id='Namespace'])"):attr("value")] .. nameComp:find("/subCompartment:has(/compartType[id='Name'])"):attr("value") .. ">"
			-- tableTemp[nameComp:find("/subCompartment:has(/compartType[id='Name'])"):attr("value")] = nameComp:find("/subCompartment:has(/compartType[id='Namespace'])"):attr("value").. ":" .. nameComp:find("/subCompartment:has(/compartType[id='Name'])"):attr("value")
		end
	end)
	
	-- print(dumptable(tableTemp))
	
	return tableTemp
end

function forAllElementsExportTags(dia, ns_uri_t, object_property_uri_t, data_property_uri_t)
	allAxioms = ""
	UnParsedExpressions = {}
	if dia == nil then diagram = utilities.current_diagram() 
	else diagram = dia end
	
	t = tda_to_protege.make_global_ns_uri_table(diagram)
	classList = MP.getAllClasses(diagram:find("/element:has(/elemType[id=Class])"))
	datatypeList = MP.getAllDatatypes(diagram:find("/element:has(/elemType[id=DataType])"))
	
	if ns_uri_t == nil then ns_uri_table = {} 
	else ns_uri_table = ns_uri_t end
	if object_property_uri_t == nil then object_property_uri_table = {} 
	else object_property_uri_table = object_property_uri_t end
	if data_property_uri_t == nil then data_property_uri_table = {} 
	else data_property_uri_table = data_property_uri_t end
	ns_uri_table_annot["backwardcompatiblewith"] = "owl:backwardCompatibleWith"
	ns_uri_table_annot["deprecated"] = "owl:deprecated"
	ns_uri_table_annot["comment"] = "rdfs:comment"
	ns_uri_table_annot["incompatiblewith"] = "owl:incompatibleWith"
	ns_uri_table_annot["isdefinedby"] = "rdfs:isDefinedBy"
	ns_uri_table_annot["label"] = "rdfs:label"
	ns_uri_table_annot["Label"] = "rdfs:label"
	ns_uri_table_annot["priorversion"] = "owl:priorVersion"
	ns_uri_table_annot["seealso"] = "rdfs:seeAlso"
	ns_uri_table_annot["versioninfo"] = "owl:versionInfo"
	ns_uri_table_annot["date"] = "<http://purl.org/dc/elements/1.1/date>"
	
	--get annotation properties
	for k, v in pairs(getAnnotationPropertyNS(diagram, ns_uri_table)) do
		ns_uri_table_annot[string.lower(k)] = v
	end
	
	-- print(dumptable(ns_uri_table_annot));
	
	
	--seed
	diagram:find("/parent/compartment"):each(function(com)
		parseExportGrammar(com)
		forAllCompartentExportTag(com)
	end)
	if lQuery("ToolType/tag[key = 'DefaultMaxCardinality1']"):attr("value") == "1" then
		diagram:find("/element:has(/elemType[id='Class'])/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)
			if attribute:find("/subCompartment:has(/compartType[id='Multiplicity'])"):is_empty() then
				core.add_compartment(attribute:find("/compartType/subCompartType[id='Multiplicity']"), attribute, "")
			end
		end)
		diagram:find("/element:has(/elemType[id='Association'])/compartment"):each(function(attribute)
			if attribute:find("/subCompartment:has(/compartType[id='Multiplicity'])"):is_empty() then
				core.add_compartment(attribute:find("/compartType/subCompartType[id='Multiplicity']"), attribute, "")
			end
		end)
	end
	
	
	exportAllDiagrams(diagram)
	
	
	if UnParsedExpressions~={} and #UnParsedExpressions~=0 then 
		allAxioms = allAxioms .. "Declaration(Class(" .. getFullName("UnParsedExpressions", "") .. "))\n"
		for k, v in pairs(UnParsedExpressions) do
			local campValue = string.gsub(v, "\\n", "\n")
			campValue = string.gsub(campValue, "\"", "\\\"")
			allAxioms = allAxioms .. 'AnnotationAssertion(rdfs:comment ' .. getFullName("UnParsedExpressions", "") .. ' "' .. v .. '")\n'
		end
	end
	
	if ((lQuery("Plugin[id='OWLGrEd_XSchema']"):is_not_empty() and lQuery("Plugin[id='OWLGrEd_XSchema']"):attr("status") == "loaded") 
	or (lQuery("Plugin[id='OWLGrEd_Schema']"):is_not_empty() and lQuery("Plugin[id='OWLGrEd_Schema']"):attr("status") == "loaded" and lQuery("Plugin[id='OWLGrEd_Schema']"):attr("version") <= "0.6") ) and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") ~= "Standard (non-shema) ontology only" then
		local schemaDataTable, domainOnlyDataTable, schemaObjectTable, domainOnlyObjectTable  = getPropertiesTablesXSchema(diagram)
		
		if lQuery("OWL_PP#ExportParameter[pName = 'existentialAssertions']"):attr("pValue") == "true" then
			local elements = getFragmentEllements(diagram, "Restriction")
			schemaObjectTable  = getExistentialAssertionsTables(elements, schemaObjectTable)
			local classes = getFragmentClasses(diagram)
			schemaObjectTable, schemaDataTable  = getExistentialAssertionsTablesTextual(classes, schemaObjectTable, schemaDataTable)
		end
		-- print("attributeTable", dumptable(schemaObjectTable), dumptable(domainOnlyObjectTable))
		if lQuery("OWL_PP#ExportParameter[pName = 'explicitSubProperties']"):attr("pValue") == "true" then
			local elements = getFragmentClasses(diagram)
			local attributes = getFragmentEllements(diagram, "Attribute")
			schemaDataTable, schemaObjectTable  = getExplicitSubPropertiesTables(elements, attributes, schemaDataTable, schemaObjectTable)
			
			local associacions = getFragmentEllements(diagram, "Association")
			schemaObjectTable  = getExplicitObjectSubPropertiesTables(elements, associacions, schemaObjectTable)
			
			schemaObjectTable = getInversePropertyResoningProperties(associacions, schemaObjectTable)
			
		end
		
		-- print("attributeTable", dumptable(schemaDataTable), dumptable(domainOnlyDataTable), dumptable(schemaObjectTable), dumptable(domainOnlyObjectTable))
	
		for i, j in pairs(schemaDataTable) do
			local generatedDomains = generatePropertyDomainClasses(j, "ObjectUnionOf")
			if generatedDomains ~= "" then allAxioms = allAxioms .. "\nDataPropertyDomain(" ..  i .. " " .. generatedDomains .. ")" end
		end
		
		for i, j in pairs(domainOnlyDataTable) do
			for k, v in pairs(j) do
				allAxioms = allAxioms .. "\nDataPropertyDomain(" ..  k .. " " .. v .. ")"
			end
		end
		
		for i, j in pairs(schemaObjectTable) do
			local generatedDomains = generatePropertyDomainClasses(j, "ObjectUnionOf")
			if generatedDomains ~= "" then allAxioms = allAxioms .. "\nObjectPropertyDomain(" ..  i .. " " .. generatedDomains .. ")" end
		end
		
		for i, j in pairs(domainOnlyObjectTable) do
			for k, v in pairs(j) do
				allAxioms = allAxioms .. "\nObjectPropertyDomain(" ..  k .. " " .. v .. ")"
			end
		end
		
	end
	
	if lQuery("Plugin[id='OWLGrEd_Schema']"):is_not_empty() and lQuery("Plugin[id='OWLGrEd_Schema']"):attr("status") == "loaded" and lQuery("Plugin[id='OWLGrEd_Schema']"):attr("version") > "0.6" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") ~= "Standard (non-shema) ontology only" then
		
		local schemaDataTable, domainOnlyDataTable, schemaObjectTable, domainOnlyObjectTable  = getPropertiesTables(diagram)
		
		if lQuery("OWL_PP#ExportParameter[pName = 'existentialAssertions']"):attr("pValue") == "true" then
			local elements = getFragmentEllements(diagram, "Restriction")
			schemaObjectTable  = getExistentialAssertionsTables(elements, schemaObjectTable)
			local classes = getFragmentClasses(diagram)
			schemaObjectTable, schemaDataTable  = getExistentialAssertionsTablesTextual(classes, schemaObjectTable, schemaDataTable)
		end
		-- print("attributeTable", dumptable(schemaObjectTable), dumptable(domainOnlyObjectTable))
		if lQuery("OWL_PP#ExportParameter[pName = 'explicitSubProperties']"):attr("pValue") == "true" then
			local elements = getFragmentClasses(diagram)
			local attributes = getFragmentEllements(diagram, "Attribute")
			schemaDataTable, schemaObjectTable  = getExplicitSubPropertiesTables(elements, attributes, schemaDataTable, schemaObjectTable)
			
			local associacions = getFragmentEllements(diagram, "Association")
			schemaObjectTable  = getExplicitObjectSubPropertiesTables(elements, associacions, schemaObjectTable)
			
			schemaObjectTable = getInversePropertyResoningProperties(associacions, schemaObjectTable)
			
		end
		
		-- print("attributeTable", dumptable(schemaDataTable), dumptable(domainOnlyDataTable), dumptable(schemaObjectTable), dumptable(domainOnlyObjectTable))
	
		for i, j in pairs(schemaDataTable) do
			local generatedDomains = generatePropertyDomainClasses(j, "ObjectUnionOf")
			if generatedDomains ~= "" then allAxioms = allAxioms .. "\nDataPropertyDomain(" ..  i .. " " .. generatedDomains .. ")" end
		end
		
		for i, j in pairs(domainOnlyDataTable) do
			for k, v in pairs(j) do
				allAxioms = allAxioms .. "\nDataPropertyDomain(" ..  k .. " " .. v .. ")"
			end
		end
		
		for i, j in pairs(schemaObjectTable) do
			local generatedDomains = generatePropertyDomainClasses(j, "ObjectUnionOf")
			if generatedDomains ~= "" then allAxioms = allAxioms .. "\nObjectPropertyDomain(" ..  i .. " " .. generatedDomains .. ")" end
		end
		
		for i, j in pairs(domainOnlyObjectTable) do
			for k, v in pairs(j) do
				allAxioms = allAxioms .. "\nObjectPropertyDomain(" ..  k .. " " .. v .. ")"
			end
		end
	end
	allAxioms = allAnnotationAxioms .. "\n" .. allAxioms
	return allAxioms
end
function generatePropertyDomainClasses(aOUOf, propertyType)
	local associationObjectUnionOf = {}
	for k, v in pairs(aOUOf) do
		table.insert(associationObjectUnionOf, k)
	end
	if #associationObjectUnionOf == 0 then
		if lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue") == "Strict schema assertion" then 
			return "owl:Nothing"
		end
	elseif #associationObjectUnionOf == 1 then
		return associationObjectUnionOf[1]
	elseif #associationObjectUnionOf > 1 then
		
		return propertyType .. "(" .. table.concat(associationObjectUnionOf, " ") .. ")"
	end
	return ""
end

function forAllCompartentExportTag(compartment)
	local n = 1
	local size = compartment:find("/subCompartment"):size()
	compartment:find("/subCompartment"):each(function(com)
		parseExportGrammar(com)
		forAllCompartentExportTag(com)
	end)
end

function exportGrammar()
	
local grammar2 =re.compile( [[
	gramar <- ( {:expression: main:}!.) -> {}
	main <- ((space expression)+) ->{}
	expression <- (axiomSymbols /axiom / filter / functionExpr / pathFunction / {:path: path:} / optional / mandatory /  string)
	axiom <- ({:axiom: axiomExpr:}) -> {}
	axiomExpr <- ({string} {"("} ({space} expression)+ {")"}) -> {}
	filter <- ({:filter: filterExprs:}) -> {}
	filterExprs <- ("[" filterExpr (space "||" space filterExpr)* "]") -> {}
	filterExpr <- ( {:filterItem1: filterItem :} space {:filterOp: filterOp :} space {:filterItem2: filterItem :} )->{}
	filterExpr2 <- ("[" {:filterItem1: filterItem :} space {:filterOp: filterOp :} space {:filterItem2: filterItem :} "]")->{}
	filterItem <- ({:function: function:} / ("'" {:string: stringFilteredItem:} "'") /{:pathFunction: pathFunctionExpr:} / {:path: path:} / {:number: number:} / {:boolean: "true":} / {:boolean: "false":})->{}
	filterOp <- "==" / "!=" / ">"
	path <- (("/" {(".." / string / filter)})+) -> {}
	pathFunction <-({:pathFunction: pathFunctionExpr:}) -> {}
	pathFunctionExpr <-({:path: path :} ":" {:function: function:}) -> {}
	pathFilter <-({:path: path :} {:filter: filterExpr2:})->{}
	functionExpr <- ({:function: function:}) -> {}
	function <- (getUri  / getExpression / value / getClassExpr / getClassName / getObjectExpr / getAnnotationProperty
						/ getRoleExpr / getHasKeyProperties / getAttributeType / getMultiplicity 
						/ getTypeExpression / getDomainOrRange / elemType / isEmpty / count 
						/ getContainer / getDataTypeRestriction / getDataTypeExpression /isURI)
	mandatory <- ({:mandatory: mandatoryExpr:}) -> {}
	mandatoryExpr <- ("!"  "(" {:mandatoryExpressions: mandatoryExpressions:} ")" ({:filter: filterExpr2:})?) -> {}
	mandatoryExpressions <- ((space expression)+) -> {}
	optional <- ({:optional: optionalExpr:}) -> {}
	optionalExpr <- (("?" "(" (space {:expression: main:})+ ")") / "?" functionExpr) -> {}
	axiomSymbols <- ({"^^" / "@" / (string ":" string) / ("<" stringExtengded+ "#" string ">")})
	stringExtengded <-(([A-Za-z] [A-Za-z]*) / [0-9]+ /":" / "/" / ".")
	string <- ([A-Za-z+] [A-Za-z+]*)
	stringFilteredItem <- (([A-Za-z+!: ] [A-Za-z+!: ]*) / "")
	number <- ("-")? [0-9]+
	space <- (" " / %nl)*
	
	getUri <- ("$" {:functionType: "getUri":} "(" {:name: uriName :} (space {:namespace: uriNamespace:})? ")") ->{}
	getAnnotationProperty <- ("$" {:functionType: "getAnnotationProperty":} "(" {:name: uriName :} (space {:namespace: uriNamespace:})? ")") ->{}
	isURI <- ("$" {"isURI"})
	uriName <- (('"'{:string:  string :}'"') / {:function: function:} / {:path: path:}) -> {}
	uriNamespace <- ({:function: functionExpr:} / {:path: path:}) -> {}
	getExpression <- ("$" {:functionType: "getExpression":} "(" {:name: expressionName :} ")") -> {}
	getContainer <- ("$" {:functionType: "getContainer":}) -> {}
	getDataTypeRestriction <- ("$" {:functionType: "getDataTypeRestriction":}) -> {}
	getDataTypeExpression <- ("$" {:functionType: "getDataTypeExpression":}) -> {}
	expressionName <- ({:function: function:} / {:path: path:}) -> {}
	value <-  (valuePath / valueQuotes) -> {}
	valuePath <- ("$" {:functionType: "value":} ("(" {:path: path:} ")")?)
	valueQuotes <- ('"' "$" {:functionType: "value":} ("(" {:path: path:} ")")? '"' {:inQuotes: '' -> "true" :})
	getDomainOrRange <-("$" {:functionType: "getDomainOrRange":} ("("  {:path: path:} ")")?) -> {}
	getClassExpr <-("$" {:functionType: "getClassExpr":} ("(" ({:pathFilter: pathFilter:} /  {:path: path:}) ")")?) -> {}
	getClassName <-("$" {:functionType: "getClassName":} ("(" ({:pathFilter: pathFilter:} /  {:path: path:}) ")")?) -> {}
	getObjectExpr <-("$" {:functionType: "getObjectExpr":} ("(" ({:pathFilter: pathFilter:} /  {:path: path:}) ")")?) -> {}
	getRoleExpr <-("$" {:functionType: "getRoleExpr":}) -> {}
	getHasKeyProperties <- ("$" {:functionType: "getHasKeyProperties":} "(" "'"({:string:  string :}"'") ")") -> {}
	getAttributeType <- ("$" {:functionType: "getAttributeType":} "(" {:type: path:} space {:isObjectAttribute: path :} ")") -> {}
	getMultiplicity <- ("$" {:functionType: "getMultiplicity":} "(" "'" {:multiplisity:("Min" / "Max" / "Exact"):} "'" ")") -> {}
	getTypeExpression <- ("$" {:functionType: "getTypeExpression":} "(" {:type: path:} space {:isObjectAttribute: path :}")") -> {}
	elemType <- ("$" {"elemType"})
	isEmpty <- ("$" {"isEmpty"})
	count <- ("$" {"count"}) 
	]])
	return grammar2
end

function URIgramar()
local grammar =re.compile( [[
	main <- (("<" expression ">"))
	expression <- ("ftp" / "http" / "https")
					"://"
					string
	string <-	([A-Za-z] / [0-9] / "/" / "." / "_" / "-")+		
	]])
	return grammar
end

function parseExportGrammar(object)
	local axiomTag = object:find("/elemType, /compartType"):find("/tag[key='ExportAxiom']"):attr("value")
	
	if axiomTag~=nil and axiomTag~= "" then
		-- print(axiomTag, object:attr("value"))
		if object:find("/compartType"):attr("id") ~= "Multiplicity" and object:find("/compartType"):is_not_empty() and (object:attr("value") == nil or object:attr("value") == "") then
			
		else
			local parseResult = re.match(axiomTag, exportGrammar()) or "NOT"
			-- print(axiomTag)
			-- print(dumptable(parseResult))
			if parseResult~="NOT" then
				if parseResult["expression"]~=nil then
					for k, v in pairs(parseResult["expression"]) do
						source = object
						axiom = ""
						generateAxiom = true
						count = 0

						concatAxiom(v)
						

						if generateAxiom == true then 
							if string.find(axiom, "$getDomainOrRange") ~= nil then
								
								local gramar = [[main <- getDomainOrRange "(" number ")"
								getDomainOrRange <- "$getDomainOrRange"
								number <- {[0-9]+}]]
								local _, id = re.find(axiom, gramar)
								local axiomPattern = axiom
								axiom = ""
								local compartment = lQuery("Compartment"):filter(function(el) return el:id() == tonumber(id) end)
								compartment:find("/subCompartment/subCompartment/subCompartment"):each(function(comp)
									local expr = MP.parseClassExpression(comp:attr("value"), diagram, t, classList, datatypeList)
									axiom = axiom .. "\n" .. string.gsub(axiomPattern, "$getDomainOrRange%(%d+%)", expr)
								end)
							end
							if allAxioms == "" then allAxioms = axiom
							else
								if string.find(axiom, "Annotation%(", 1) ~= nil then 
									-- allAxioms =  axiom .. "\n" .. allAxioms 
									allAnnotationAxioms =  allAnnotationAxioms .. "\n" .. axiom 
									-- print("TTTTTTTTTTTTTTTTTTTTTTTT", axiom)
									-- print("vvvvv", dumptable(v))
								else
									allAxioms = allAxioms .. "\n" .. axiom
								end
							end
						else 
							-- print("NOT AXIOM", generateAxiom)
						end
					end
				end
			end
		end
	end
end

function splitPath(path)
	local pathTable = {}
	for token in string.gmatch(path, "[^/]+") do
	   table.insert(pathTable, token)
	end
	return pathTable
end

function getNameAndNamespace(nameNamespaceTable, currentComp)
	
	if currentComp == nil then currentComp = source end
	local name, namespace = nil
	if nameNamespaceTable["name"]~=nil then
		if nameNamespaceTable["name"]["path"]~=nil then
			name = getValueFromPath(nameNamespaceTable["name"]["path"], currentComp)
		elseif nameNamespaceTable["name"]["string"]~=nil then
			name = nameNamespaceTable["name"]["string"]
		elseif nameNamespaceTable["name"]["value"]~=nil then
			name = currentComp:attr("value")
		elseif nameNamespaceTable["name"]["function"]~=nil then
			name = createFunctionAxiom(nameNamespaceTable["name"]["function"])
		end
	end
	
	if nameNamespaceTable["namespace"]~=nil then
		if nameNamespaceTable["namespace"]["path"]~=nil then
			namespace = getValueFromPath(nameNamespaceTable["namespace"]["path"], currentComp)
		end
	end
	-- print(name, namespace)
	return name, namespace
end

function getValueFromPath(pathTable, currentComp)
	local object = currentComp
	if object == nil then object = source end
	for _, v in pairs(pathTable) do
		if v == ".." then
			object = object:find("/parentCompartment, /element")
		else
			object = object:find("/compartment, /subCompartment"):filter(function(com)
				return com:find("/compartType"):attr("id") == v
			end)
		end
	end
	return object:attr("value")
end

function get_current_uri()
	local path = ""
	-- local s = utilities.active_elements()
	-- s = diagram
	-- if s:size() == 0 then
		s = diagram
		path = "/parent/compartment:has(/compartType[id = 'Prefix'])"
	-- else
		-- path = "/compartment:has(/compartType[id = 'Prefix'])"
	-- end
	local res = t_to_p.find_diagram_source(diagram:find("/parent")):find("/compartment:has(/compartType[id = 'Prefix'])"):attr_e("value") --.. "#"
	if string.sub(res, string.len(res)) == "#" then return res end
	return res .. "#"
end

function concatAxiom(parseResult)

	if type(parseResult) == "table" then
		for key, value in pairs(parseResult) do
			if key == "function" then 
				axiom = axiom .. createFunctionAxiom(value)
			elseif key == "pathFunction" and value["path"]~= nil then 
				local compartments = getCompartmentsFromPath(value["path"])
				compartments:each(function(compartment)
					if value["function"]~= nil then
						axiom = axiom .. createFunctionAxiom(value["function"], compartment)
					end
				end)
			elseif key == "filter" then
				filterResult = getFilters(value)
				if filterResult == false then generateAxiom = false end
			elseif key == "optional" then
				local tempA = axiom
				local tempG = generateAxiom
				axiom = ""
				generateAxiom = true
				local oprionalResult = concatAxiom(value)
				if generateAxiom == true then axiom = tempA .. axiom
				else axiom = tempA end
				generateAxiom = tempG
			elseif key == "mandatory" then
				count = 0
				local tempA = axiom
				local tempG = generateAxiom
				axiom = ""
				generateAxiom = true
				-- concatAxiom(value["mandatoryExpressions"])
				concatAxiom({mandatoryExpressions = value["mandatoryExpressions"]})
				if value["filter"]~=nil and value["filter"]["filterItem1"]["function"] == "count" then
					local filterItem1 = count
					local filterItem2 = tonumber(getFilterItem(value["filter"]["filterItem2"]))
					local filterOp = value["filter"]["filterOp"]
					if compareFilterItems(filterItem1, filterItem2, filterOp) == true then
						axiom = tempA .. axiom
					else generateAxiom = false  end
				elseif count > 0 and axiom~="" and generateAxiom ~= false then 
					axiom = tempA .. axiom
				else generateAxiom = false 
				end
				if generateAxiom == true then generateAxiom = tempG  end
			elseif key == "expression" and value["path"]~= nil then
				-- if value["path"]~= nil then 
					local compartments = getCompartmentsFromPath(value["path"])
					local tempSource = source
					local tempG = generateAxiom
					compartments:each(function(compartment)
						local tempA = axiom
						axiom = ""
						source = compartment
						generateAxiom = true
						value["path"] = nil
						concatAxiom(value)
						if generateAxiom == true then axiom = tempA .. " " .. axiom 
						else
							axiom = tempA
						end
					end)
					generateAxiom = tempG
					source = tempSource
				-- end
			elseif key == "mandatoryExpressions" and value["path"]~= nil then
				-- if value["path"]~= nil then 
					local compartments = getCompartmentsFromPath(value["path"])
					local tempSource = source
					local tempG = generateAxiom
					compartments:each(function(compartment)
						local tempA = axiom
						axiom = ""
						source = compartment
						generateAxiom = true
						value["path"] = nil
						concatAxiom(value)
						if generateAxiom == true then axiom = tempA .. " " .. axiom 
						else
							axiom = tempA
						end
					end)
					generateAxiom = tempG
					source = tempSource
				-- end
			else
				concatAxiom(value)
			end
		end
	else 
		axiom = axiom .. parseResult
	end
end

function getFullName(name, namespace)
	if name == "Thing" then namespace = "owl" end
	
	if namespace~=nil and namespace~="" then 
		if ns_uri_table[namespace]~=nil then return "<" .. ns_uri_table[namespace] .. name .. ">" end
		if string.starts(namespace, "http") or string.starts(namespace, "www") then return "<" .. namespace .. "#" .. name .. ">" end
		return "<" .. get_current_uri()  .. name .. ">" 
	else 
		-- if ns_uri_table_annot[string.lower(name)]~=nil then return ns_uri_table_annot[string.lower(name)] end
		return "<" .. get_current_uri()  .. name .. ">" 
	end
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function createFunctionAxiom(value, currentComp)
	if currentComp == nil then currentComp = source end
	local axiomPart = ""

	if generateAxiom == true then
		if value["functionType"]~= nil and value["functionType"]=="getUri" then
			
			local name, namespace = getNameAndNamespace(value, currentComp)
	
			if name~=nil and name~="" then
				axiomPart = axiomPart .. getFullName(name, namespace)
				count = count + 1
			else
				generateAxiom = false
			end
		elseif value["functionType"]~= nil and value["functionType"]=="getAnnotationProperty" then
			
			local name, namespace = getNameAndNamespace(value, currentComp)
	
			if name~=nil and name~="" then
				axiomPart = axiomPart .. getAnnotationPropertyName(name, namespace)
				count = count + 1
			else
				generateAxiom = false
			end
		elseif value["functionType"]~= nil and value["functionType"]=="getClassExpr" then 
			if value["pathFilter"] == nil and value["path"] == nil  then 
				axiomPart = axiomPart .. getClassExpression()
				count = count + 1
			elseif value["path"] ~= nil then 
				local classes = getElementsFromPath(value["path"])
				classes:each(function(class)
					axiomPart = axiomPart .. getClassExpression(class) --.. " "
					count = count + 1
				end)
				if classes:is_empty() then generateAxiom = false  end
			elseif value["pathFilter"] ~= nil then 
				local classes = getElementsFromPath(value["pathFilter"]["path"])
				if value["pathFilter"]["filter"]["filterItem1"]["function"] ~= nil and value["pathFilter"]["filter"]["filterItem1"]["function"] == "count" then
					local filterItem1 = classes:size()
					local filterItem2 = tonumber(getFilterItem(value["pathFilter"]["filter"]["filterItem2"]))
					local filterOp = value["pathFilter"]["filter"]["filterOp"]
					if compareFilterItems(filterItem1, filterItem2, filterOp) == true then
						classes:each(function(class)
							axiomPart = axiomPart .. getClassExpression(class) --.. " "
							count = count + 1
						end)
					else
						generateAxiom = false
					end
				else
					--TODO path
				end
			end
		elseif value["functionType"]~= nil and value["functionType"]=="getClassName" then 
			if value["pathFilter"] == nil and value["path"] == nil  then 
				axiomPart = axiomPart .. getClassExpressionShort()
				count = count + 1
			elseif value["path"] ~= nil then 
				local classes = getElementsFromPath(value["path"])
				classes:each(function(class)
					axiomPart = axiomPart .. getClassExpressionShort(class) --.. " "
					count = count + 1
				end)
				if classes:is_empty() then generateAxiom = false  end
			elseif value["pathFilter"] ~= nil then 
				local classes = getElementsFromPath(value["pathFilter"]["path"])
				if value["pathFilter"]["filter"]["filterItem1"]["function"] ~= nil and value["pathFilter"]["filter"]["filterItem1"]["function"] == "count" then
					local filterItem1 = classes:size()
					local filterItem2 = tonumber(getFilterItem(value["pathFilter"]["filter"]["filterItem2"]))
					local filterOp = value["pathFilter"]["filter"]["filterOp"]
					if compareFilterItems(filterItem1, filterItem2, filterOp) == true then
						classes:each(function(class)
							axiomPart = axiomPart .. getClassExpressionShort(class) --.. " "
							count = count + 1
						end)
					else
						generateAxiom = false
					end
				else
					--TODO path
				end
			end
		elseif value["functionType"]~= nil and value["functionType"]=="getDomainOrRange" then
			if value["pathFilter"] == nil and value["path"] == nil  then 
				axiomPart = axiomPart .. getDomainOrRange()
				count = count + 1
			elseif value["path"] ~= nil then 
				local classes = getElementsFromPath(value["path"])
				classes:each(function(class)
					axiomPart = axiomPart .. getDomainOrRange(class) --.. " "
					count = count + 1
				end)
				if classes:is_empty() then generateAxiom = false  end
			end
		elseif value["functionType"]~= nil and value["functionType"]=="getObjectExpr" then
			if value["pathFilter"] == nil and value["path"] == nil  then 
				axiomPart = axiomPart .. getObjectExpression()
				count = count + 1
			elseif value["path"] ~= nil then 
				local classes = getElementsFromPath(value["path"])
				classes:each(function(class)
					axiomPart = axiomPart .. getObjectExpression(class) --.. " "
					count = count + 1
				end)
			end
		elseif value["functionType"]~= nil and value["functionType"]=="getRoleExpr" then
			axiomPart = axiomPart .. getRoleExpression()-- .. " "
			count = count + 1
		elseif value["functionType"]~= nil and value["functionType"]=="getContainer" then
			axiomPart = axiomPart .. getContainerName()-- .. " "
			count = count + 1
		elseif value["functionType"]~= nil and value["functionType"]=="getDataTypeRestriction" then
			axiomPart = axiomPart .. getDataTypeRestrictionName()-- .. " "
			count = count + 1
		elseif value["functionType"]~= nil and value["functionType"]=="getDataTypeExpression" then
			axiomPart = axiomPart .. getAttributeDataTypeExpression()-- .. " "
			count = count + 1
		elseif value["functionType"]~= nil and value["functionType"]=="getExpression" then 
			local name = getNameAndNamespace(value, currentComp)
			local a = string.gsub(name, "\\n", "\n")
			-- a = string.gsub(a, "\"", "\\\"")
			local expr = MP.parseClassExpression(a, diagram, t, classList, datatypeList)
			
			if expr==nil then 
				UnParsedExpressions[a] = a
			end
			if currentComp:find("/compartType"):attr("id") == "ClassName" then 
				axiomPart = axiomPart .. expr --.." "
				count = count + 1
			elseif getClassExpression() ~= expr and expr~=nil then
				axiomPart = axiomPart .. expr --.." "
				count = count + 1
			else 
				generateAxiom = false
			end
		elseif value["functionType"]~= nil and value["functionType"]=="getHasKeyProperties" then 
			local keys = source:find("/subCompartment/subCompartment:has(/compartType[id='Key'])")
			local propertyType = value["string"]
			local properties = ""
			keys:each(function(key)
				if key:find("/subCompartment:has(/compartType[id='Property'])"):attr("value") ~= nil and key:find("/subCompartment:has(/compartType[id='Property'])"):attr("value") ~= "" then
				local keyName = getFullName(key:find("/subCompartment:has(/compartType[id='Property'])"):attr("value"), key:find("/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local _, key_type = t_to_p.get_uri_from_data_or_object_property_table(data_property_uri_table, object_property_uri_table, key:find("/subCompartment:has(/compartType[id='Property'])"):attr("value"))
				if propertyType == "ObjectProperty" and key_type == "object" then
					local inverse = key:find("/subCompartment:has(/compartType[id='Inverse'])"):attr("value")
					if inverse ~= "false" and inverse ~= "" then
						properties = properties .. "ObjectInverseOf(" .. keyName .. ")"
					else
						properties = properties .. keyName
					end
				elseif propertyType == "DataProperty" and key_type == "data" then
					properties = properties .. keyName
				end
				end
			end)
			axiomPart = "(" .. properties .. ")"
		elseif value["functionType"]~= nil and value["functionType"]=="value" then 
			if value["path"]~= nil then
				local compartments = getCompartmentsFromPath(value["path"])
				compartments:each(function(compartment)
					if compartment:attr("value")~="" then
						if value["inQuotes"] == "true" then 
							local campValue = string.gsub(compartment:attr("value"), "\\n", "\n")
							campValue = string.gsub(campValue, "\"", "\\\"")
							axiomPart = axiomPart .. '"' .. campValue .. '"'
						else axiomPart = axiomPart .. compartment:attr("value") end
						
						count = count + 1
					end
				end)
				if compartments:is_empty() or axiomPart == "" then generateAxiom = false  end
			else
				if source:attr("value")~="" then
					if value["inQuotes"] == "true" then 
						local campValue = string.gsub(source:attr("value"), "\\n", "\n")
						campValue = string.gsub(campValue, "\"", "\\\"")
						axiomPart = axiomPart .. '"' .. campValue .. '"'
					else axiomPart = axiomPart .. source:attr("value") end
					count = count + 1
				else
					generateAxiom = false
				end
			end
		elseif value["functionType"]~=nil and value["functionType"] == "getAttributeType" then
			local isObjectAttribute = getCompartmentsFromPath(value["isObjectAttribute"])
			local typeComp = getValueFromPath(value["type"], currentComp)
			if typeComp~=nil and typeComp~="" then
				local typeExpr, attrType = MP.generateAttributeType(typeComp, diagram, t, classList, datatypeList, isObjectAttribute)
				if attrType == nil then attrType = "DataProperty" end
				axiomPart = attrType
			else
				axiomPart = "DataProperty"
			end
		elseif value["functionType"]~=nil and value["functionType"] == "getTypeExpression" then
			local isObjectAttribute = getCompartmentsFromPath(value["isObjectAttribute"])
			core.split_compart_value(currentComp, true)
			local typeComp = getValueFromPath(value["type"], currentComp)
			local typeExpr, attrType = MP.generateAttributeType(currentComp:attr("value"), diagram, t, classList, datatypeList, isObjectAttribute)
			if typeExpr == nil then 
				typeExpr = "" 
				generateAxiom = false
			else
				count = count + 1
			end

			axiomPart = axiomPart .. typeExpr
		elseif value["functionType"]~=nil and value["functionType"] == "getMultiplicity" then
			axiomPart = axiomPart .. getMultiplicity(value)
			count = count + 1
		elseif value["functionType"]~=nil and value["functionType"] == "isEmpty" then
			
		else
		--TODO
		end
	end
	return axiomPart
end

function getMultiplicity(value)
	local mulValue = source:attr("value")
	if lQuery("ToolType/tag[key = 'DefaultMaxCardinality1']"):attr("value") == "1" then
		if mulValue == "" then mulValue = "0..*" end
		if string.find(mulValue, "..") == nil then mulValue = mulValue .. "..*" end
	end
	local mul = value["multiplisity"]
	local mulTable = t_to_p.multiplicity_split(mulValue)
	if mulTable~=nil then
		if mul == "Exact" then
			if mulTable["Number"]~=nil then return tonumber(mulTable["Number"]) end
		elseif mul == "Min" then
			if mulTable["MinMax"]~=nil and mulTable["MinMax"]["Min"]~=nil and mulTable["MinMax"]["Min"]~="0" then return tonumber(mulTable["MinMax"]["Min"]) end
		elseif mul == "Max" then
			if mulTable["MinMax"]~=nil and mulTable["MinMax"]["Max"]~=nil and mulTable["MinMax"]["Max"]~="*" then return tonumber(mulTable["MinMax"]["Max"]) end
		end
	end
	return -1
end

function getDomainOrRange(elem)
	if elem == nil then elem = utilities.get_element_from_compartment(source) end
	local name = elem:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
	if name~= nil and name~="" then
		namespace = elem:find("/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
		return getFullName(name, namespace)
	else
		local eqcl = elem:find("/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])"):first()
		if eqcl:is_not_empty() then return "$getDomainOrRange(" .. eqcl:id() ..")" end
	end
	generateAxiom = false
	return ""
end

function getContainerName()
	local elem = utilities.get_element_from_compartment(source)
	local container = elem:find("/container")
	return '"' .. container:find("/compartment:has(/compartType[id='Name'])"):attr("value") .. '"'
end

function getDataTypeRestrictionName()
	local dataTypeRestrictionValue = MP.parseDatatypeRestriction(source:attr("value"), diagram, t, classList, datatypeList)
	if dataTypeRestrictionValue == nil then dataTypeRestrictionValue = "" end
	return dataTypeRestrictionValue
end

function getAttributeDataTypeExpression()
	local elem = utilities.get_element_from_compartment(source)
	local dataType = elem:find("/end:has(/elemType[id='DataType'])")
	dataType = dataType:add(elem:find("/start:has(/elemType[id='DataType'])"))
	return getFullName(dataType:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value"), dataType:find("/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
end

function getAnnotationPropertyName(name, namespace)
	if namespace~=nil and namespace~="" then 
		if ns_uri_table[namespace]~=nil then return "<" .. ns_uri_table[namespace] .. name .. ">" end
		if string.starts(namespace, "http") or string.starts(namespace, "www") then return "<" .. namespace .. "#" .. name .. ">" end
		return "<" .. get_current_uri()  .. name .. ">" 
	else 
		if ns_uri_table_annot[string.lower(name)]~=nil then return ns_uri_table_annot[string.lower(name)] end
		return "<" .. get_current_uri()  .. name .. ">" 
	end
end

function getClassExpression(elem)
	if elem == nil then elem = utilities.get_element_from_compartment(source) end
		if elem:find("/elemType"):attr("id") == "Class" then
		local name = elem:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
		if name~= nil and name~="" then
			namespace = elem:find("/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
			return getFullName(name, namespace)
		else
			local eqcl = elem:find("/compartment/subCompartment/subCompartment/subCompartment:has(/compartType[id = 'EquivalentClass'])"):first()
			if eqcl:is_not_empty() then return MP.parseClassExpression(eqcl:attr("value"), diagram, t, classList, datatypeList) end
		end
	end
	generateAxiom = false
	return ""
end

function getClassExpressionShort(elem)
	if elem == nil then elem = utilities.get_element_from_compartment(source) end
		if elem:find("/elemType"):attr("id") == "Class" then
		local name = elem:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
		if name~= nil and name~="" then
			namespace = elem:find("/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
			return name
		end
	end
	generateAxiom = false
	return ""
end

function getObjectExpression(elem)
	if elem == nil then elem = utilities.get_element_from_compartment(source) end
	local name = elem:find("/compartment/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
	if name~= nil and name~="" then
		namespace = elem:find("/compartment/subCompartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
		return getFullName(name, namespace)
	end
	generateAxiom = false
	return ""
end

function getRoleExpression()
	local object = source
	while object:find("/compartType"):attr("id")~="Role" and object:find("/compartType"):attr("id")~="InvRole" do
		object = object:find("/parentCompartment")
	end
	local name = object:find("/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
	if name~= nil and name~="" then
		local namespace = object:find("/subCompartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
		return getFullName(name, namespace)
	else
		local elem = utilities.get_element_from_compartment(source)
		if object:find("/compartType"):attr("id")=="Role" then object = elem:find("/compartment:has(/compartType[id='InvRole'])")
		else object = elem:find("/compartment:has(/compartType[id='Role'])") end 
		local name = object:find("/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
		if name~= nil and name~="" then
			local namespace = object:find("/subCompartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
			if namespace~="" then return "ObjectInverseOf(<" .. namespace .. "#" .. name .. ">)"
			else return "ObjectInverseOf(<" .. get_current_uri()  .. name .. ">)" end
		end
	end
	generateAxiom = false
	return ""
end

function getFilters(parseResult)
	local result = false
	for key, value in pairs(parseResult) do
		if getFilter(value) == true then result = true end
	end
	return result
end

function getFilter(value)
	local filterItem1 = getFilterItem(value["filterItem1"])
	local filterItem2 = getFilterItem(value["filterItem2"])
	local filterOp = value["filterOp"]
	-- print("filterItem1", filterItem1)
	-- print("filterItem2", filterItem2)
	-- print("reault", compareFilterItems(getFilterItem(value["filterItem1"]), getFilterItem(value["filterItem2"]), value["filterOp"]))
	
	return compareFilterItems(getFilterItem(value["filterItem1"]), getFilterItem(value["filterItem2"]), value["filterOp"])
end

function getFilterItem(filterItemTable)
	if filterItemTable["function"]~=nil then
		return createFunctionAxiom(filterItemTable["function"])
	elseif filterItemTable["string"]~=nil then
		return filterItemTable["string"]
	elseif filterItemTable["number"]~=nil then
		return filterItemTable["number"]
	elseif filterItemTable["boolean"]~=nil then
		return filterItemTable["boolean"]
	elseif filterItemTable["path"]~=nil then
		local comp = getCompartmentsFromPath(filterItemTable["path"])
		return comp:attr("value")
	elseif filterItemTable["pathFunction"]~=nil then
		if filterItemTable["pathFunction"]["function"]~= nil and filterItemTable["pathFunction"]["function"] == "isEmpty" then
			local elements
			if string.match(string.sub(filterItemTable["pathFunction"]["path"][1], 1, 1), "[a-z]") then 
				elements = getElementsFromPath(filterItemTable["pathFunction"]["path"])
			else
				elements = getCompartmentsFromPath(filterItemTable["pathFunction"]["path"])
			end
			if elements:is_empty() or elements:attr("value") == "" then return "true" else return "false" end
		elseif filterItemTable["pathFunction"]["function"]~= nil and filterItemTable["pathFunction"]["function"] == "isURI" then
			local comp = getCompartmentsFromPath(filterItemTable["pathFunction"]["path"])
			local parseResult = re.match(comp:attr("value"), URIgramar()) or "NOT"
			if parseResult ~= "NOT" then return "true" end
			return "false"
		elseif filterItemTable["pathFunction"]["function"]~= nil and filterItemTable["pathFunction"]["function"] == "elemType" then
			elements = getElementsFromPath(filterItemTable["pathFunction"]["path"])
			return elements:find("/elemType"):attr("id")
		else
			--TODO
		end
	else
	--TODO
	end
end

function compareFilterItems(filterItem1, filterItem2,  filterOp) 
   -- "==" / "!=" / ">"
   -- print(filterItem1, filterItem2,  filterOp)
	if filterItem1~=nil and filterItem2~=nil and filterOp~=nil then
		if filterOp == "==" and filterItem1 == filterItem2 then return true
		elseif filterOp == "!=" and filterItem1 ~= filterItem2 then return true
		elseif filterOp == ">" and filterItem1 > filterItem2 then return true
		end
	elseif filterOp == "!=" and (filterItem1==nil or filterItem2==nil) then
		return true
	end
	return false
end

function getCompartmentsFromPath(pathTable)
	local object = source
	for _, v in pairs(pathTable) do
		if v == ".." then
			object = object:find("/parentCompartment, /element")
		else
			object = object:find("/compartment, /subCompartment"):filter(function(com)
				return com:find("/compartType"):attr("id") == v
			end)
		end
	end
	return object
end

function getElementsFromPath(pathTable)
	local elem = utilities.get_element_from_compartment(source)
	for _, v in pairs(pathTable) do
		elem = elem:find("/"..v)
	end
	return elem
end

function findInverseSuperPropertiesAndPropertyChains(associacions, schemaObjectTable, invrole, roleOrig)
	associacions:find("/compartment"):filter(function(assoc)
		return assoc:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):attr("value") == invrole:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value")
	end):each(function(role)
		local name = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		if (name:attr("value") ~= nil and name:attr("value") ~= "") or role:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment"):size() > 0 then
			local compartType = "InvRole"
			if role:find("/compartType"):attr("id") == "InvRole" then compartType = "Role" end
				
			local irole = role:find("/element/compartment:has(/compartType[id='"..compartType.."'])")
			local iname = irole:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			if iname:attr("value") ~= nil and iname:attr("value") ~= "" then
				local superPropertyFullName = getFullName(roleOrig:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value"), roleOrig:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local propertyFullName = getFullName(iname:attr("value"), irole:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				if superPropertyFullName~= nil and superPropertyFullName ~= "" then
					for k, v in pairs(schemaObjectTable[propertyFullName]) do 
						if schemaObjectTable[superPropertyFullName] == nil then 
							schemaObjectTable[superPropertyFullName] = {}
						end
						schemaObjectTable[superPropertyFullName][k] = true
					end
				end
			end
			
			local pr = findInverseSuperPropertiesAndPropertyChains(associacions, schemaObjectTable, role, roleOrig)

			if superPropertyFullName~= nil and superPropertyFullName ~= "" then
				for k, v in pairs(pr) do
					for i, j in pairs(v) do
						if schemaObjectTable[superPropertyFullName] == nil then 
							schemaObjectTable[superPropertyFullName] = {}
						end
						schemaObjectTable[superPropertyFullName][i] = true
					end
				end
			end
		end
	end)
	
	if lQuery("OWL_PP#ExportParameter[pName = 'extendByInitialChainProperties']"):attr("pValue") == "true" then

		associacions:find("/compartment/subCompartment:has(/compartType[id='PropertyChains'])/subCompartment/subCompartment/subCompartment/subCompartment"):filter(function(chain)
			return chain:find("/subCompartment:has(/compartType[id='Property'])"):attr("value") == invrole:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value")
			and chain:find("/subCompartment:has(/compartType[id='Inverse'])"):attr("value") == "true"
		end):each(function(chain)
			local chainRole = chain:find("/parentCompartment/parentCompartment/parentCompartment/parentCompartment/parentCompartment")
			local propertyFullName = getFullName(chainRole:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value"), chain:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))	
			local superPropertyFullName = getFullName(roleOrig:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value"), roleOrig:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
		
			for k, v in pairs(schemaObjectTable[propertyFullName]) do 
				if schemaObjectTable[superPropertyFullName] == nil then 
					schemaObjectTable[superPropertyFullName] = {}
				end
				schemaObjectTable[superPropertyFullName][k] = true
			end
		end)
	end
	
	return schemaObjectTable
end

function getInversePropertyResoningProperties(associacions, schemaObjectTable)
	
	associacions:each(function(association)
		local role = association:find("/compartment:has(/compartType[id='Role'])")	
		local name = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")

		if name:attr("value") ~= nil and name:attr("value") ~= "" then
			local invrole = association:find("/compartment:has(/compartType[id='InvRole'])")	
			local invname = invrole:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			
			if (invname:attr("value") ~= nil and invname:attr("value") ~= "") or invrole:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment"):size() > 0 then
				schemaObjectTable = findInverseSuperPropertiesAndPropertyChains(associacions, schemaObjectTable, invrole, role)
			end
		end
		
	end)
	
	return  schemaObjectTable
end

function  getExplicitObjectSubPropertiesTables(elements, associacions, schemaObjectTable)
	elements:each(function(clazz)
	    clazz:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)

			local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")

			if attrName:attr("value")~=nil and attrName:attr("value")~="" then
				attribute:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):each(function(expr)
				    local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					local superPropertyFullName = getFullName(expr:attr("value"), "")
					if attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])"):attr("value")== "true" then
						for k, v in pairs(schemaObjectTable[propertyFullName]) do 
							if schemaObjectTable[superPropertyFullName] ~= nil then 
								schemaObjectTable[superPropertyFullName][k] = true;
							end
						end
						--super properties
						local pr = findObjectSuperProperties(attrName:attr("value"), elements, associacions, schemaObjectTable, superPropertyFullName)
						-- print(dumptable(pr))
						
						for k, v in pairs(pr) do
							for i, j in pairs(v) do
								if schemaObjectTable[superPropertyFullName] ~= nil then 
									schemaObjectTable[superPropertyFullName][i] = true
								end
							end
						end
					end
				end)
			end
		end)
	end)
	
	associacions:each(function(association)
		local role = association:find("/compartment:has(/compartType[id='Role'])")	
		local name = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		local class = association:find("/start")
		local classFullName = getClassNameExpression(class)
			
		if name:attr("value") ~= nil and name:attr("value") ~= "" and classFullName~=nil and classFullName~="" then
			role:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):each(function(expr)
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
			    local superPropertyFullName = getFullName(expr:attr("value"), "")
				if schemaObjectTable[propertyFullName]~= nil then
					for k, v in pairs(schemaObjectTable[propertyFullName]) do 
						if schemaObjectTable[superPropertyFullName] ~= nil then 
							schemaObjectTable[superPropertyFullName][k] = true;
						end
						--super properties
						local pr = findObjectSuperProperties(name:attr("value"), elements, associacions, schemaObjectTable, superPropertyFullName)
						-- print(dumptable(pr))
						
						for k, v in pairs(pr) do
							for i, j in pairs(v) do
								if schemaObjectTable[superPropertyFullName] ~= nil then 
									schemaObjectTable[superPropertyFullName][i] = true
								end
							end
						end
					end
				end
			end)
			
			if lQuery("OWL_PP#ExportParameter[pName = 'extendByInitialChainProperties']"):attr("pValue") == "true" then
				role:find("/subCompartment:has(/compartType[id='PropertyChains'])/subCompartment/subCompartment/subCompartment/subCompartment"):each(function(expr)
					local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					
					if expr:find("/subCompartment:has(/compartType[id='Inverse'])"):attr("value") ~= "true" then	
						local superPropertyFullName = getFullName(expr:find("/subCompartment:has(/compartType[id='Property'])"):attr("value"), expr:find("/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						for k, v in pairs(schemaObjectTable[propertyFullName]) do 
							if schemaObjectTable[superPropertyFullName] ~= nil then 
								schemaObjectTable[superPropertyFullName][k] = true;
							end

							local pr = findObjectPropertyChains(name:attr("value"), associacions, schemaObjectTable, superPropertyFullName)

							for k, v in pairs(pr) do
								for i, j in pairs(v) do
									if schemaObjectTable[superPropertyFullName] ~= nil then 
										schemaObjectTable[superPropertyFullName][i] = true
									end
								end
							end
						end
					end
				end)
			end
		end
		
		local role = association:find("/compartment:has(/compartType[id='InvRole'])")	
		local name = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		local class = association:find("/end")
		local classFullName =getClassNameExpression(class)
		
		if name:attr("value") ~= nil and name:attr("value") ~= "" and classFullName~=nil and classFullName~="" then
			role:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):each(function(expr)
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
			    local superPropertyFullName = getFullName(expr:attr("value"), "")
				if schemaObjectTable[propertyFullName] ~= nil then
					for k, v in pairs(schemaObjectTable[propertyFullName]) do 
						if schemaObjectTable[superPropertyFullName] ~= nil then 
							schemaObjectTable[superPropertyFullName][k] = true;
						end
						--super properties
						local pr = findObjectSuperProperties(name:attr("value"), elements, associacions, schemaObjectTable, superPropertyFullName)
						-- print(dumptable(pr))
						
						for k, v in pairs(pr) do
							for i, j in pairs(v) do
								if schemaObjectTable[superPropertyFullName] ~= nil then 
									schemaObjectTable[superPropertyFullName][i] = true
								end
							end
						end
					end
				end
			end)
			
			if lQuery("OWL_PP#ExportParameter[pName = 'extendByInitialChainProperties']"):attr("pValue") == "true" then
				role:find("/subCompartment:has(/compartType[id='PropertyChains'])/subCompartment/subCompartment/subCompartment/subCompartment"):each(function(expr)
					local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					
					if expr:find("/subCompartment:has(/compartType[id='Inverse'])"):attr("value") ~= "true" then	
						local superPropertyFullName = getFullName(expr:find("/subCompartment:has(/compartType[id='Property'])"):attr("value"), expr:find("/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						for k, v in pairs(schemaObjectTable[propertyFullName]) do 
							if schemaObjectTable[superPropertyFullName] ~= nil then 
								schemaObjectTable[superPropertyFullName][k] = true;
							end

							local pr = findObjectPropertyChains(name:attr("value"), associacions, schemaObjectTable, superPropertyFullName)

							for k, v in pairs(pr) do
								for i, j in pairs(v) do
									if schemaObjectTable[superPropertyFullName] ~= nil then 
										schemaObjectTable[superPropertyFullName][i] = true
									end
								end
							end
						end
					else
					   -- TODO
					end
				end)
			end
			
		end
	end)
	
	return  schemaObjectTable
end

function getExistentialAssertionsTables(elements, schemaObjectTable)
	elements:each(function(restriction)
	    local classA = restriction:find("/start")
	    
		local multiplisity = t_to_p.multiplicity_split(restriction:find("/compartment:has(/compartType[id='Multiplicity'])"):attr("value"))
		local name = restriction:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Role'])")
		
		if name:attr("value")~= nil and name:attr("value") ~= "" and (restriction:find("/compartment:has(/compartType[id='Some'])"):attr("value") == "true" 
		    or (restriction:find("/compartment:has(/compartType[id='Some'])"):attr("value") ~= "true" and restriction:find("/compartment:has(/compartType[id='Only'])"):attr("value") ~= "true")
		    or (multiplisity ~= nil and ((multiplisity["Number"] ~= nil and tonumber(multiplisity["Number"]) >= 1) or (multiplisity["MinMax"] ~= nil and tonumber(multiplisity["MinMax"]["Min"]) >= 1))))
		then
			local classFullName = getClassNameExpression(classA)
			
			
			local propertyFullName = getFullName(name:attr("value"), restriction:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Role'])"):attr("value"))
				    
			if schemaObjectTable[propertyFullName] == nil then 
				schemaObjectTable[propertyFullName] = {}
			end
			schemaObjectTable[propertyFullName][classFullName] = true;
		end	
	end)
	
	return schemaObjectTable
end

function getExistentialAssertionsTablesTextual(elements, schemaObjectTable, schemaDataTable)

	elements:find("/compartment:has(/compartType[id='ASFictitiousSuperClasses'])/subCompartment/subCompartment"):each(function(expr)
	   local propertyTable = MP.parseSchemaExpression(expr:attr("value"))
	   local classFullName = getClassNameExpression(expr:find("/parentCompartment/parentCompartment/element"))
		
		for i, j in pairs(propertyTable) do
			local propertyFullName = getFullName(j, "")
				    
			if schemaObjectTable[propertyFullName] ~= nil then 
				schemaObjectTable[propertyFullName][classFullName] = true;
			end
			if schemaDataTable[propertyFullName] ~= nil then 
				schemaDataTable[propertyFullName][classFullName] = true;
			end
			
		end
	end)
	
	return schemaObjectTable, schemaDataTable
end

function getExplicitSubPropertiesTables(elements, attributes, schemaDataTable, schemaObjectTable)

	elements:each(function(clazz)
	    clazz:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)

			local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")

			if attrName:attr("value")~=nil and attrName:attr("value")~="" then
				attribute:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):each(function(expr)
				    local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					local superPropertyFullName = getFullName(expr:attr("value"), "")
					
					if attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])"):attr("value")~= "true" then
						if schemaDataTable[propertyFullName] ~= nil then 
							for k, v in pairs(schemaDataTable[propertyFullName]) do 
								if schemaDataTable[superPropertyFullName] == nil then 
									schemaDataTable[superPropertyFullName] = {}
								end
								schemaDataTable[superPropertyFullName][k] = true
							end
						end
						--super properties
						local pr = findSuperProperties(attrName:attr("value"), elements, schemaDataTable, superPropertyFullName, attributes)

						for k, v in pairs(pr) do
							for i, j in pairs(v) do
								if schemaDataTable[superPropertyFullName] == nil then 
									schemaDataTable[superPropertyFullName] = {}
								end
								schemaDataTable[superPropertyFullName][i] = true
							end
						end
					end
				end)
			end
		end)
	end)
	
	attributes:each(function(attribute)
			local attrName = attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")

			if attrName:attr("value")~=nil and attrName:attr("value")~="" then
				attribute:find("/compartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):each(function(expr)
				    local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					local superPropertyFullName = getFullName(expr:attr("value"), "")
					
						if schemaDataTable[propertyFullName] ~= nil then 
							for k, v in pairs(schemaDataTable[propertyFullName]) do 
								if schemaDataTable[superPropertyFullName] == nil then 
									schemaDataTable[superPropertyFullName] = {}
								end
								schemaDataTable[superPropertyFullName][k] = true
							end
						end
						--super properties
						local pr = findSuperProperties(attrName:attr("value"), elements, schemaDataTable, superPropertyFullName, attributes)

						for k, v in pairs(pr) do
							for i, j in pairs(v) do
								if schemaDataTable[superPropertyFullName] == nil then 
									schemaDataTable[superPropertyFullName] = {}
								end
								schemaDataTable[superPropertyFullName][i] = true
							end
						end
				end)
			end
	end)
	return schemaDataTable, schemaObjectTable
end

function findObjectSuperProperties(value, elements, associations, schemaObjectTable, propertyName)
	local superPropertiesTable = {}
	
	elements:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):filter(function(elem) 
		return elem:find("/subCompartment:has(/compartType[id='isObjectAttribute'])"):attr("value") == "true" 
		and elem:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):attr("value") == value
	end):add(associations:find("/compartment"):filter(function(elem)
		return elem:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):attr("value") == value
	end)):each(function(attribute)
		local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")

		if attrName:attr("value")~=nil and attrName:attr("value")~="" then
			attribute:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):each(function(expr)
				local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local superPropertyFullName = getFullName(expr:attr("value"), "")
				for k, v in pairs(schemaObjectTable[propertyFullName]) do 
					if superPropertiesTable[propertyName] == nil then 
						superPropertiesTable[propertyName] = {}
					end
					superPropertiesTable[propertyName][k] = true;
				end
				--super properties
				local temp = findSuperProperties(attrName:attr("value"), elements, schemaObjectTable, propertyName)
				for k, v in pairs(temp) do
					for i, j in pairs(v) do
						if superPropertiesTable[k] == nil then 
							superPropertiesTable[k] = {}
						end
						superPropertiesTable[k][i] = true;
					end
				end				
			end)
		end
	end)
	
	return superPropertiesTable
end

function findObjectPropertyChains(value, associations, schemaObjectTable, propertyName)
	local superPropertiesTable = {}
	
	associations:find("/compartment"):filter(function(elem)
		return elem:find("/subCompartment:has(/compartType[id='PropertyChain'])/subCompartment/subCompartment/subCompartment/subCompartment/subCompartment:has(/compartType[id='Property'])"):attr("value") == value
	end):each(function(attribute)
		local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")

		if attrName:attr("value")~=nil and attrName:attr("value")~="" then
			attribute:find("/subCompartment:has(/compartType[id='PropertyChain'])/subCompartment/subCompartment/subCompartment/subCompartment"):each(function(expr)
				local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local superPropertyFullName = getFullName(expr:find("/subCompartment:has(/compartType[id='Property'])"):attr("value"), expr:find("/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				for k, v in pairs(schemaObjectTable[propertyFullName]) do 
					if superPropertiesTable[propertyName] == nil then 
						superPropertiesTable[propertyName] = {}
					end
					superPropertiesTable[propertyName][k] = true;
				end
				
				local temp = findObjectPropertyChains(attrName:attr("value"), associations, schemaObjectTable, propertyName)
				for k, v in pairs(temp) do
					for i, j in pairs(v) do
						if superPropertiesTable[k] == nil then 
							superPropertiesTable[k] = {}
						end
						superPropertiesTable[k][i] = true;
					end
				end				
			end)
		end
	end)
	
	return superPropertiesTable
end

function findSuperProperties(value, elements, schemaDataTable, propertyName, attributes)
	local superPropertiesTable = {}
	elements:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):filter(function(elem) 
		return elem:find("/subCompartment:has(/compartType[id='isObjectAttribute'])"):attr("value") ~= "true" 
		and elem:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):attr("value") == value
	end):each(function(attribute)
		local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")

		if attrName:attr("value")~=nil and attrName:attr("value")~="" then
			attribute:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):each(function(expr)
				local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local superPropertyFullName = getFullName(expr:attr("value"), "")
				
				for k, v in pairs(schemaDataTable[propertyFullName]) do 
					if superPropertiesTable[propertyName] == nil then 
						superPropertiesTable[propertyName] = {}
					end
					superPropertiesTable[propertyName][k] = true;
				end
				--super properties
				local temp = findSuperProperties(attrName:attr("value"), elements, schemaDataTable, propertyName, attributes)
				for k, v in pairs(temp) do
					for i, j in pairs(v) do
						if superPropertiesTable[k] == nil then 
							superPropertiesTable[k] = {}
						end
						superPropertiesTable[k][i] = true;
					end
				end				
			end)
		end
	end)
	if attributes ~= nil then
		attributes:filter(function(elem) 
			return elem:find("/compartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):attr("value") == value
		end):each(function(attribute)
			local attrName = attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")

			if attrName:attr("value")~=nil and attrName:attr("value")~="" then
				attribute:find("/compartment:has(/compartType[id='SuperProperties'])/subCompartment/subCompartment/subCompartment"):each(function(expr)
					local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					local superPropertyFullName = getFullName(expr:attr("value"), "")
					
					for k, v in pairs(schemaDataTable[propertyFullName]) do 
						if superPropertiesTable[propertyName] == nil then 
							superPropertiesTable[propertyName] = {}
						end
						superPropertiesTable[propertyName][k] = true;
					end
					--super properties
					local temp = findSuperProperties(attrName:attr("value"), elements, schemaDataTable, propertyName, attributes)
					for k, v in pairs(temp) do
						for i, j in pairs(v) do
							if superPropertiesTable[k] == nil then 
								superPropertiesTable[k] = {}
							end
							superPropertiesTable[k][i] = true;
						end
					end				
				end)
			end
		end)
	end
	return superPropertiesTable
end

function getPropertiesTables(diagram)
	local attributeTable = {}
	local domainOnlyAttributeTable = {}
	local schemaObjectTable = {}
	local domainOnlyObjectTable = {}
	
	diagram:find("/element:has(/elemType[id='Class'])"):each(function(clazz)
	    local classFullName = getClassNameExpression(clazz)
		clazz:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)
		    if attribute:find("/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value") == "true" then
				local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
				if attrName:attr("value")~=nil and attrName:attr("value")~="" then
					if attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])"):attr("value")~= "true" then
						local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						
						if attributeTable[propertyFullName] == nil then 
							attributeTable[propertyFullName] = {}
						end
						attributeTable[propertyFullName][classFullName] = true;
					else
						local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						
						if schemaObjectTable[propertyFullName] == nil then 
							schemaObjectTable[propertyFullName] = {}
						end
						schemaObjectTable[propertyFullName][classFullName] = true;
					end
				end
			else
				local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
				if attrName:attr("value")~=nil and attrName:attr("value")~=""then
					if attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])"):attr("value")~= "true" then
						local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						local t = {}
						t[propertyFullName] = classFullName
						table.insert(domainOnlyAttributeTable, t)
					else
						local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						local t = {}
						t[propertyFullName] = classFullName
						table.insert(domainOnlyObjectTable, t)
					end
				end
			end
		end)
	end)
	
	--attribute as link
	diagram:find("/element:has(/elemType[id='Attribute'])"):each(function(attribute)
		local classFullName = getClassNameExpression(attribute:find("/start:has(/elemType[id='Class']),/end:has(/elemType[id='Class'])"))
		if attribute:find("/compartment:has(/compartType[id='schemaAssertion'])"):attr("value") == "true" then
			local attrName = attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			if attrName:attr("value")~=nil and attrName:attr("value")~="" then
					
				local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))		
				if attributeTable[propertyFullName] == nil then 
					attributeTable[propertyFullName] = {}
				end
				attributeTable[propertyFullName][classFullName] = true;
			end
		else
			local attrName = attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			if attrName:attr("value")~=nil and attrName:attr("value")~=""then
					
				local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local t = {}
				t[propertyFullName] = classFullName
				table.insert(domainOnlyAttributeTable, t)
					
			end
		end
	end)
	
	--associacion
	diagram:find("/element:has(/elemType[id='Association'])"):each(function(assoc)
		local role = assoc:find("/compartment:has(/compartType[id='Role'])")
		local name = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		local class = assoc:find("/start")
		local classFullName = getClassNameExpression(class)
		
		if name:attr("value") ~= nil and name:attr("value") ~= "" and classFullName~=nil and classFullName~="" then
			if role:find("/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value") == "true" then
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					
				if schemaObjectTable[propertyFullName] == nil then 
					schemaObjectTable[propertyFullName] = {}
				end
				schemaObjectTable[propertyFullName][classFullName] = true;
			else
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local t = {}
				t[propertyFullName] = classFullName
				table.insert(domainOnlyObjectTable, t)
			end
		end
		
		local role = assoc:find("/compartment:has(/compartType[id='InvRole'])")
		local name = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		local class = assoc:find("/end")
		local classFullName = getClassNameExpression(class)
		
		if name:attr("value") ~= nil and name:attr("value") ~= "" and classFullName~=nil and classFullName~="" then
			if role:find("/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value") == "true" then
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					
				if schemaObjectTable[propertyFullName] == nil then 
					schemaObjectTable[propertyFullName] = {}
				end
				schemaObjectTable[propertyFullName][classFullName] = true;
			else
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local t = {}
				t[propertyFullName] = classFullName
				table.insert(domainOnlyObjectTable, t)
			end
		end
	end)
	
	diagram:find("/element"):each(function(el)
		if el:find("/elemType"):attr("id") == "OntologyFragment" then
			el:find("/child"):each(function(e)
				local tempSchema, tempAttr, tempSchemaOP, tempOP = getPropertiesTables(e)
				for k, v in pairs(tempSchema) do
					for i, j in pairs(v) do
						if attributeTable[k] == nil then 
							attributeTable[k] = {}
						end
						attributeTable[k][i] = true;
					end
				end
				for k, v in pairs(tempAttr) do
					table.insert(domainOnlyAttributeTable, v)
				end
				for k, v in pairs(tempSchemaOP) do
					for i, j in pairs(v) do
						if schemaObjectTable[k] == nil then 
							schemaObjectTable[k] = {}
						end
						schemaObjectTable[k][i] = true;
					end
				end
				for k, v in pairs(tempOP) do
					table.insert(domainOnlyObjectTable, v)
				end
			end)
		end
	end)
	
	return attributeTable, domainOnlyAttributeTable, schemaObjectTable, domainOnlyObjectTable
end

function getPropertiesTablesXSchema(diagram)
	local attributeTable = {}
	local domainOnlyAttributeTable = {}
	local schemaObjectTable = {}
	local domainOnlyObjectTable = {}
	
	diagram:find("/element:has(/elemType[id='Class'])"):each(function(clazz)
	    local classFullName = getClassNameExpression(clazz)
		-- print("fffffffffffffffffffffffffff", classFullName)
		clazz:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)
		    if attribute:find("/subCompartment:has(/compartType[id='noSchema'])"):attr("value") ~= "true" and attribute:find("/subCompartment:has(/compartType[id='noSchema'])"):attr("value") ~= "!" then
				local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
				if attrName:attr("value")~=nil and attrName:attr("value")~="" then
					if attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])"):attr("value")~= "true" then
						local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						
						if attributeTable[propertyFullName] == nil then 
							attributeTable[propertyFullName] = {}
						end
						attributeTable[propertyFullName][classFullName] = true;
					else
						local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						
						if schemaObjectTable[propertyFullName] == nil then 
							schemaObjectTable[propertyFullName] = {}
						end
						schemaObjectTable[propertyFullName][classFullName] = true;
					end
				end
			else
				local attrName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
				if attrName:attr("value")~=nil and attrName:attr("value")~=""then
					if attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])"):attr("value")~= "true" then
						local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						local t = {}
						t[propertyFullName] = classFullName
						table.insert(domainOnlyAttributeTable, t)
					else
						local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
						local t = {}
						t[propertyFullName] = classFullName
						table.insert(domainOnlyObjectTable, t)
					end
				end
			end
		end)
	end)
	
	--attribute as link
	diagram:find("/element:has(/elemType[id='Attribute'])"):each(function(attribute)
		local classFullName = getClassNameExpression(attribute:find("/start:has(/elemType[id='Class']),/end:has(/elemType[id='Class'])"))
		
		if attribute:find("/compartment:has(/compartType[id='noSchema'])"):attr("value") ~= "true" and attribute:find("/compartment:has(/compartType[id='noSchema'])"):attr("value") ~= "!" then
			local attrName = attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			if attrName:attr("value")~=nil and attrName:attr("value")~="" then
					
				local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))		
				if attributeTable[propertyFullName] == nil then 
					attributeTable[propertyFullName] = {}
				end
				attributeTable[propertyFullName][classFullName] = true;
			end
		else
			local attrName = attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			if attrName:attr("value")~=nil and attrName:attr("value")~=""then
					
				local propertyFullName = getFullName(attrName:attr("value"), attribute:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local t = {}
				t[propertyFullName] = classFullName
				table.insert(domainOnlyAttributeTable, t)
					
			end
		end
	end)
	
	--associacion
	diagram:find("/element:has(/elemType[id='Association'])"):each(function(assoc)
		local role = assoc:find("/compartment:has(/compartType[id='Role'])")
		local name = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		local class = assoc:find("/start")
		local classFullName = getClassNameExpression(class)
		
		if name:attr("value") ~= nil and name:attr("value") ~= "" and classFullName~=nil and classFullName~="" then
			if role:find("/subCompartment:has(/compartType[id='noSchema'])"):attr("value") ~= "true" and role:find("/subCompartment:has(/compartType[id='noSchema'])"):attr("value") ~= "!" then
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					
				if schemaObjectTable[propertyFullName] == nil then 
					schemaObjectTable[propertyFullName] = {}
				end
				schemaObjectTable[propertyFullName][classFullName] = true;
			else
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local t = {}
				t[propertyFullName] = classFullName
				table.insert(domainOnlyObjectTable, t)
			end
		end
		
		local role = assoc:find("/compartment:has(/compartType[id='InvRole'])")
		local name = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		local class = assoc:find("/end")
		local classFullName = getClassNameExpression(class)
		
		if name:attr("value") ~= nil and name:attr("value") ~= "" and classFullName~=nil and classFullName~="" then
			if role:find("/subCompartment:has(/compartType[id='noSchema'])"):attr("value") ~= "true" and role:find("/subCompartment:has(/compartType[id='noSchema'])"):attr("value") ~= "!" then
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
					
				if schemaObjectTable[propertyFullName] == nil then 
					schemaObjectTable[propertyFullName] = {}
				end
				schemaObjectTable[propertyFullName][classFullName] = true;
			else
				local propertyFullName = getFullName(name:attr("value"), role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
				local t = {}
				t[propertyFullName] = classFullName
				table.insert(domainOnlyObjectTable, t)
			end
		end
	end)
	
	diagram:find("/element"):each(function(el)
		if el:find("/elemType"):attr("id") == "OntologyFragment" then
			el:find("/child"):each(function(e)
				local tempSchema, tempAttr, tempSchemaOP, tempOP = getPropertiesTablesXSchema(e)
				for k, v in pairs(tempSchema) do
					for i, j in pairs(v) do
						if attributeTable[k] == nil then 
							attributeTable[k] = {}
						end
						attributeTable[k][i] = true;
					end
				end
				for k, v in pairs(tempAttr) do
					table.insert(domainOnlyAttributeTable, v)
				end
				for k, v in pairs(tempSchemaOP) do
					for i, j in pairs(v) do
						if schemaObjectTable[k] == nil then 
							schemaObjectTable[k] = {}
						end
						schemaObjectTable[k][i] = true;
					end
				end
				for k, v in pairs(tempOP) do
					table.insert(domainOnlyObjectTable, v)
				end
			end)
		end
	end)
	
	return attributeTable, domainOnlyAttributeTable, schemaObjectTable, domainOnlyObjectTable
end

function getFragmentClasses(diagram)
	local elements = diagram:find("/element:has(/elemType[id='Class'])")
	
	diagram:find("/element"):each(function(el)
		if el:find("/elemType"):attr("id") == "OntologyFragment" then
			el:find("/child"):each(function(e)
				elements = elements:add(getFragmentClasses(e))
			end)
		end
	end)
	return elements
end

function getFragmentEllements(diagram, elemType)
	local elements = diagram:find("/element:has(/elemType[id='"..elemType.."'])")
	
	diagram:find("/element"):each(function(el)
		if el:find("/elemType"):attr("id") == "OntologyFragment" then
			el:find("/child"):each(function(e)
				elements = elements:add(getFragmentEllements(e, elemType))
			end)
		end
	end)
	return elements
end

function exportAllDiagrams(diagram, number)
	local number = 1
	diagram:find("/element"):each(function(el)
		if el:find("/elemType"):attr("id") == "OntologyFragment" then
			el:find("/child/element"):each(function(e)
				parseExportGrammar(e)
				e:find("/compartment"):each(function(com)
					parseExportGrammar(com)
					forAllCompartentExportTag(com)
				end)
				
			end)
			allAxioms = allAxioms .. "\n" .. t_to_p.export_plugin(el:find("/child"))
			el:find("/child"):each(function(e)
				exportAllDiagrams(e, number)
			end)
		end
		parseExportGrammar(el)
		local n = 1
		local size = el:find("/compartment"):size()
		el:find("/compartment"):each(function(com)
			parseExportGrammar(com)

			forAllCompartentExportTag(com)
			n= n + 1
		end)
		log("Saved element " .. number .. " / " .. diagram:find("/element"):size())
		number = number + 1
	end)
end

function getClassNameExpression(class)
	local classFullName = getDomainOrRange(class)
	if string.find(classFullName, "$getDomainOrRange") ~= nil then
		local gramar = [[main <- getDomainOrRange "(" number ")"
							getDomainOrRange <- "$getDomainOrRange"
							number <- {[0-9]+}]]
		local _, id = re.find(classFullName, gramar)
		local compartment = lQuery("Compartment"):filter(function(el) return el:id() == tonumber(id) end)
		compartment:find("/subCompartment/subCompartment/subCompartment"):each(function(comp)
			classFullName = MP.parseClassExpression(comp:attr("value"), diagram, t, classList, datatypeList)
		end)
	end
	-- print("classFullName", classFullName)
	return classFullName
end

function exportParameterMetamodel()
	lQuery.model.add_class("OWL_PP#ExportParameter")
	lQuery.model.add_property("OWL_PP#ExportParameter", "pName")
	lQuery.model.add_property("OWL_PP#ExportParameter", "pValue")
	lQuery.model.add_property("OWL_PP#ExportParameter", "caption")
	lQuery.model.add_property("OWL_PP#ExportParameter", "procedure")
	lQuery.model.add_property("OWL_PP#ExportParameter", "topMargin")
	lQuery.model.add_property("OWL_PP#ExportParameter", "leftMargin")
	
	lQuery.model.add_class("OWL_PP#ExportParameterTab")
	lQuery.model.add_property("OWL_PP#ExportParameterTab", "caption")
	lQuery.model.add_property("OWL_PP#ExportParameterTab", "source")
	
	lQuery.model.add_class("OWL_PP#ExportParameterRow")
	lQuery.model.add_property("OWL_PP#ExportParameterRow", "type")
	
	lQuery.model.add_class("OWL_PP#ExportParameterGroupBox")
	lQuery.model.add_property("OWL_PP#ExportParameterGroupBox", "caption")
	lQuery.model.add_property("OWL_PP#ExportParameterGroupBox", "topMargin")
	
	lQuery.model.add_class("OWL_PP#ExportParameterValueOption")
	lQuery.model.add_property("OWL_PP#ExportParameterValueOption", "value")
	
	lQuery.model.add_link("OWL_PP#ExportParameterTab", "tab", "groupBox", "OWL_PP#ExportParameterGroupBox")
	lQuery.model.add_link("OWL_PP#ExportParameterGroupBox", "groupBox", "parameter", "OWL_PP#ExportParameter")
	
	lQuery.model.add_link("OWL_PP#ExportParameter", "parameter", "row", "OWL_PP#ExportParameterRow")
	lQuery.model.add_link("OWL_PP#ExportParameter", "parameter", "option", "OWL_PP#ExportParameterValueOption")
	
	
	local tab = lQuery.create("OWL_PP#ExportParameterTab", {caption = "General", source = "Tool"})
	local groupBox = lQuery.create("OWL_PP#ExportParameterGroupBox", {caption = "empty", topMargin = 0}):link("tab", tab)
	local checkBox = lQuery.create("OWL_PP#ExportParameterRow", {type = "checkBox"})
	local radioButton = lQuery.create("OWL_PP#ExportParameterRow", {type = "radioButton"})
	
	lQuery.create("OWL_PP#ExportParameter", {pName = "includeToolAndPluginVersionAnnotations", pValue = "false", caption = "Include tool and plug-in version annotations", procedure = "lua.exportOntology.saveCheckBoxParameter()"})
	:link("groupBox", groupBox)
	:link("row", checkBox)
	
	
	local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")
-- local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")-----------------------------------------------------

	-- get or create toolbar type
	local toolbarType = project_dgr_type:find("/toolbarType")
	if toolbarType:is_empty() then
	  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
	end


	local view_manager_toolbar_el = lQuery.create("ToolbarElementType", {
		  toolbarType = toolbarType,
		  id = "Ontology_export_preferences",
		  caption = "Ontology export preferences",
		  picture = "export_preferences.BMP",
		  procedureName = "exportOntology.exportParameterForm"
		})	
	-- refresh project diagram toolbar
	configurator.make_toolbar(project_dgr_type)

	lQuery.create("PopUpElementType", {id="Ontology Export Options", caption="Ontology Export Options", nr=6, visibility=true, procedureName="exportOntology.exportParameterForm"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='projectDiagram']/rClickEmpty"))
		
	local popUpElementTypes = lQuery("GraphDiagramType[id='projectDiagram']/rClickEmpty/popUpElementType")
	local popUpDiagramType = lQuery("GraphDiagramType[id='projectDiagram']/rClickEmpty")
	
	 popUpElementTypes:each(function(popUp)
		popUp:remove_link("popUpDiagramType", popUpDiagramType)
	end)
	
	local popUp_table = {}
	popUpElementTypes:each(function(popUp)
		table.insert(popUp_table, popUp)
	end)
	table.sort(popUp_table, sort_context_menu_table_function)
	for _, popUp in ipairs(popUp_table) do
		popUp:link("popUpDiagramType", popUpDiagramType)
	end
	
end

function sort_context_menu_table_function(row1, row2)
	local nr1 = tonumber(row1:attr("nr"))
	local nr2 = tonumber(row2:attr("nr"))
	if nr1 ~= nil and nr2 ~= nil then
		if nr1 < nr2 then
			return row2
		end
	end
end

function exportParameterForm()

	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.exportOntology.close()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "ontology_export_preferences"
    ,caption = "Ontology export options"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.exportOntology.close()")
    ,minimumWidth = 410
	,component = {
		lQuery.create("D#TabContainer",{
			component = getExportParameterTabs()
		})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
	
end

function getExportParameterTabs()
	local values = lQuery("OWL_PP#ExportParameterTab"):map(
	  function(obj)
		return {obj:attr("caption"), obj}
	  end)  
	
	return lQuery.map(values, function(tab) 
		return lQuery.create("D#Tab", {
			caption = tab[1]
			,horizontalAlignment = -1
			,component = getExportParameterGroupBoxes(tab[2])
		}) 
	end)
end

function getExportParameterGroupBoxes(tab)
	local values = tab:find("/groupBox"):map(
	  function(obj)
		return {obj:attr("caption"), obj:attr("topMargin"), obj}
	  end)  
	
	return lQuery.map(values, function(box) 
		if box[1] ~= "empty" then
			return lQuery.create("D#GroupBox",{
				caption = box[1]
				,topMargin = box[2]
				,minimumWidth = 450
				,component = getExportParameters(box[3])
			})
		else
			return getExportParameters(box[3])
		end
	end)
end

function getExportParameters(box)
	local values = box:find("/parameter"):map(
	  function(obj)
		return {obj:attr("caption"), obj:attr("pName"),obj:attr("pValue"), obj:attr("procedure"), obj:attr("topMargin"), obj:attr("leftMargin"),  obj:find("/row"):attr("type"), obj}
	  end)  
	
	return lQuery.map(values, function(parameter) 
		if parameter[7] == "checkBox" then
			return lQuery.create("D#VerticalBox", {
				horizontalAlignment = -1
				,verticalAlignment = -1
				,leftMargin = parameter[6]
				,component = {
					lQuery.create("D#Row", {
						horizontalAlignment = -1
						,topMargin = parameter[5]
						,component = {
							lQuery.create("D#CheckBox", {
								caption = parameter[1]
								,id = parameter[2]
								,checked = lQuery("OWL_PP#ExportParameter[pName = '"..parameter[2].."']"):attr("pValue")
								,eventHandler = utilities.d_handler("Change", "lua_engine", parameter[4])
							})
													
						}
					})
				}})
		end
		if parameter[7] == "radioButton" then
			return lQuery.create("D#VerticalBox", {
				horizontalAlignment = -1
				,leftMargin = parameter[6]
				,component = {
					lQuery.create("D#Row", {
						horizontalAlignment = -1
						,topMargin = parameter[5]
						,component = {
							lQuery.create("D#VerticalBox", {
								horizontalAlignment = -1
								,id = parameter[2]
								,component = getRadioButtonOptions(parameter[8])
							})			
						}
					})
				}})
		end
	end)
end

function getRadioButtonOptions(parameter)
	local values = parameter:find("/option"):map(
	  function(obj)
		return {obj:attr("value"), obj:attr("pName"),obj:attr("pValue"), obj:attr("procedure"), obj:attr("topMargin"), obj:attr("leftMargin"),  obj:find("/row"):attr("type"), obj}
	  end)  
	 
	 return lQuery.map(values, function(option) 
		return lQuery.create("D#RadioButton",{
			caption = option[1]
			,id = parameter:attr("pName")
			,selected = selectRadioButtonValue( parameter:attr("pName"), option[1])
			,eventHandler = utilities.d_handler("Click", "lua_engine", parameter:attr("procedure"))											
		})
	end)
end

function selectRadioButtonValue(id, caption)	
	local pValue = lQuery("OWL_PP#ExportParameter[pName = '" .. id .. "']"):attr("pValue")
	if caption == pValue then return true else return false end
end

function saveCheckBoxParameter()
	local checkBox = lQuery("D#Event/source"):last()
	local checkedId = checkBox:attr("id")
	local checked = checkBox:attr("checked")
	local pValue = lQuery("OWL_PP#ExportParameter[pName = '" .. checkedId .. "']")
	pValue:attr("pValue", checked)
end

function close()
	lQuery("D#Event"):delete()
	utilities.close_form("ontology_export_preferences")
end

function configExportTags()
lQuery("Tag[key='ExportAxiom']"):delete()


lQuery("ElemType[id='Class']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getUri(/Name /Namespace) $getContainer)'}))

lQuery("ElemType[id='OWL']/compartType[id='Comment']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[Annotation($getAnnotationProperty("Comment" /../Prefix) "$value")]]}))
lQuery("ElemType[id='OWL']/compartType[id='ASFictitiousAnnotation']/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[Annotation($getAnnotationProperty(/AnnotationType /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))
-- lQuery("ElemType[id='OWL']/compartType[id='ASFictitiousNamespaces']/subCompartType[id='Namespaces']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[Prefix($value)]]}))

lQuery("ElemType[id='Class']/compartType[id='Name']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "Declaration(Class($getUri(/Name /Namespace)))"}))
lQuery("ElemType[id='Class']/compartType[id='Comment']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion(rdfs:comment $getClassExpr "$value")'}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='EquivalentClasses']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "EquivalentClasses($getClassExpr /ASFictitiousEquivalentClass/EquivalentClass:$getExpression(/Expression))"}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='SuperClasses']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "SubClassOf($getClassExpr $getExpression($value))"}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='DisjointClass']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "DisjointClasses($getClassExpr /ASFictitiousDisjointClass/DisjointClass:$getExpression(/Expression))"}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Keys']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "HasKey($getClassExpr $getHasKeyProperties('ObjectProperty') $getHasKeyProperties('DataProperty'))"}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[Declaration(ObjectProperty([$getAttributeType(/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
ObjectPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
DataPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]]}))

-- lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Type']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[ObjectPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'ObjectProperty'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))
-- DataPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'DataProperty'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))]]}))

-- lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
-- DataPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]]}))


lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Multiplicity']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubClassOf($getClassExpr !(?(ObjectExactCardinality([$getMultiplicity('Exact') > -1][$getAttributeType(/../Type/Type /../isObjectAttribute) == 'ObjectProperty'] $getMultiplicity('Exact') /../Name:$getUri(/Name /Namespace) ?(/../Type:$getTypeExpression(/Type  /Namespace)))) ?(DataExactCardinality([$getMultiplicity('Exact') > -1] [$getAttributeType(/../Type/Type /../isObjectAttribute)  == 'DataProperty'] $getMultiplicity('Exact') /../Name:$getUri(/Name /Namespace) ?(/../Type:$getTypeExpression(/Type /Namespace))))))
SubClassOf($getClassExpr !(?(ObjectMinCardinality([$getMultiplicity('Min') > -1][$getAttributeType(/../Type/Type /../isObjectAttribute) == 'ObjectProperty'] $getMultiplicity('Min') /../Name:$getUri(/Name /Namespace) ?(/../Type:$getTypeExpression(/Type /Namespace)))) ?(DataMinCardinality([$getMultiplicity('Min') > -1] [$getAttributeType(/../Type/Type /../isObjectAttribute)  == 'DataProperty'] $getMultiplicity('Min') /../Name:$getUri(/Name /Namespace) ?(/../Type:$getTypeExpression(/Type /Namespace))))))
SubClassOf($getClassExpr !(?(ObjectMaxCardinality([$getMultiplicity('Max') > -1][$getAttributeType(/../Type/Type /../isObjectAttribute) == 'ObjectProperty'] $getMultiplicity('Max') /../Name:$getUri(/Name /Namespace) ?(/../Type:$getTypeExpression(/Type /Namespace)))) ?(DataMaxCardinality([$getMultiplicity('Max') > -1] [$getAttributeType(/../Type/Type /../isObjectAttribute)  == 'DataProperty'] $getMultiplicity('Max') /../Name:$getUri(/Name /Namespace) ?(/../Type:$getTypeExpression(/Type /Namespace))))))]]}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='IsFunctional']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[FunctionalObjectProperty([$getAttributeType(/../Type/Type /../isObjectAttribute) == 'ObjectProperty'][$value == 'true'] /../Name:$getUri(/Name /Namespace))
FunctionalDataProperty([$getAttributeType(/../Type/Type /../isObjectAttribute) == 'DataProperty'][$value == 'true'] /../Name:$getUri(/Name /Namespace))]]}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType/subCompartType[id='EquivalentProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[EquivalentDataProperties([$getAttributeType(/../../../Type/Type /../../../isObjectAttribute) == 'DataProperty'] /../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))
EquivalentObjectProperties([$getAttributeType(/../../../Type/Type /../../../isObjectAttribute) == 'ObjectProperty'] /../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))]]}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType/subCompartType[id='SuperProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubDataPropertyOf([$getAttributeType(/../../../Type/Type /../../../isObjectAttribute) == 'DataProperty'] /../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))
SubObjectPropertyOf([$getAttributeType(/../../../Type/Type /../../../isObjectAttribute)  == 'ObjectProperty'] /../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))]]}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType/subCompartType[id='DisjointProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[DisjointDataProperties([$getAttributeType(/../../../Type/Type /../../../isObjectAttribute) == 'DataProperty'] /../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))
DisjointObjectProperties([$getAttributeType(/../../../Type/Type /../../../isObjectAttribute)  == 'ObjectProperty'] /../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))]]}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value =[[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))
lQuery("ElemType[id='HorizontalFork']/compartType[id='Disjoint']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "DisjointClasses([$value == 'true'] $getClassExpr(/eEnd/start[$count > 1]))"}))
lQuery("ElemType[id='HorizontalFork']/compartType[id='Complete']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "EquivalentClasses([$value == 'true'] $getClassExpr(/eStart/end) ObjectUnionOf($getClassExpr(/eEnd/start[$count > 1])))"}))

lQuery("ElemType[id='Object']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Title/Name:$getUri(/Name /Namespace) $getContainer)'}))
lQuery("ElemType[id='Object']/compartType/subCompartType[id='Name']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "Declaration(NamedIndividual($getObjectExpr))"}))
lQuery("ElemType[id='Object']/compartType/subCompartType[id='ClassName']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "ClassAssertion($getExpression($value) $getObjectExpr)"}))
lQuery("ElemType[id='Object']/compartType[id='Comment']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion(rdfs:comment $getObjectExpr "$value")'}))
lQuery("ElemType[id='Object']/compartType/subCompartType[id='SameIndividuals']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "SameIndividual($getUri($value) $getObjectExpr)"}))
lQuery("ElemType[id='Object']/compartType/subCompartType[id='DifferentIndividuals']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "DifferentIndividuals($getUri($value) $getObjectExpr)"}))
lQuery("ElemType[id='Object']/compartType/subCompartType[id='DataPropertyAssertion']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'DataPropertyAssertion($getUri(/Property) $getObjectExpr "$value(/Value)" ?(^^$getUri(/Type)))'}))
lQuery("ElemType[id='Object']/compartType/subCompartType[id='NegativeDataPropertyAssertion']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'NegativeDataPropertyAssertion($getUri(/Property) $getObjectExpr "$value(/Value)" ?(^^$getUri(/Type)))'}))
lQuery("ElemType[id='Object']/compartType/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) $getObjectExpr "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))



lQuery("ElemType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[Annotation([/ValueLanguage/Value:$isURI == true][/eStart:$isEmpty == true][/eEnd:$isEmpty== true][/Property:$isEmpty == true]?(Annotation([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> $getContainer)) $getAnnotationProperty(/AnnotationType /Namespace) $value(/ValueLanguage/Value))
Annotation([/ValueLanguage/Value:$isURI != true][/eStart:$isEmpty == true][/eEnd:$isEmpty== true][/Property:$isEmpty == true]?(Annotation([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> $getContainer)) $getAnnotationProperty(/AnnotationType /Namespace) "$value(/ValueLanguage/Value)"?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eStart/end:$elemType == 'Class'][/Property:$isEmpty == true][/ValueLanguage/Value:$isURI == true]$getAnnotationProperty(/AnnotationType /Namespace) $getClassExpr(/eStart/end) $value(/ValueLanguage/Value))
AnnotationAssertion([/eStart/end:$elemType == 'Class'][/Property:$isEmpty == true][/ValueLanguage/Value:$isURI != true]$getAnnotationProperty(/AnnotationType /Namespace) $getClassExpr(/eStart/end) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eEnd/start:$elemType == 'Class'][/Property:$isEmpty == true][/ValueLanguage/Value:$isURI == true]$getAnnotationProperty(/AnnotationType /Namespace) $getClassExpr(/eEnd/start) $value(/ValueLanguage/Value))
AnnotationAssertion([/eEnd/start:$elemType == 'Class'][/Property:$isEmpty == true][/ValueLanguage/Value:$isURI != true]$getAnnotationProperty(/AnnotationType /Namespace) $getClassExpr(/eEnd/start) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eStart/end:$elemType == 'Object'][/Property:$isEmpty == true][/ValueLanguage/Value:$isURI == true]$getAnnotationProperty(/AnnotationType /Namespace) $getObjectExpr(/eStart/end) $value(/ValueLanguage/Value))
AnnotationAssertion([/eStart/end:$elemType == 'Object'][/Property:$isEmpty == true][/ValueLanguage/Value:$isURI != true]$getAnnotationProperty(/AnnotationType /Namespace) $getObjectExpr(/eStart/end) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/eEnd/start:$elemType == 'Object'][/Property:$isEmpty == true][/ValueLanguage/Value:$isURI == true]$getAnnotationProperty(/AnnotationType /Namespace) $getObjectExpr(/eEnd/start) $value(/ValueLanguage/Value))
AnnotationAssertion([/eEnd/start:$elemType == 'Object'][/Property:$isEmpty == true][/ValueLanguage/Value:$isURI != true]$getAnnotationProperty(/AnnotationType /Namespace) $getObjectExpr(/eEnd/start) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/Property:$isEmpty != true][/ValueLanguage/Value:$isURI == true]$getAnnotationProperty(/AnnotationType /Namespace) $getUri(/Property) $value(/ValueLanguage/Value))
AnnotationAssertion([/Property:$isEmpty != true][/ValueLanguage/Value:$isURI != true]$getAnnotationProperty(/AnnotationType /Namespace) $getUri(/Property) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))


	
lQuery("ElemType[id='DifferentIndivids']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[DifferentIndividuals(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType /Namespace) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) !(?$getObjectExpr(/eEnd/start) ?$getObjectExpr(/eStart/end))[$count > 1])]]}))

lQuery("ElemType[id='SameAsIndivids']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SameIndividual(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType /Namespace) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) !(?$getObjectExpr(/eEnd/start) ?$getObjectExpr(/eStart/end))[$count > 1])]]}))

lQuery("ElemType[id='EquivalentClasses']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[EquivalentClasses(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType /Namespace) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) !(?$getClassExpr(/eEnd/start) ?$getClassExpr(/eStart/end))[$count > 1])]]}))

lQuery("ElemType[id='DisjointClasses']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[DisjointClasses(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType /Namespace) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) !(?$getClassExpr(/eEnd/start) ?$getClassExpr(/eStart/end))[$count > 1])]]}))

lQuery("ElemType[id='DataType']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getUri(/Name /Namespace) $getContainer)'}))
lQuery("ElemType[id='DataType']/compartType[id='Name']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "Declaration(Datatype($getUri(/Name /Namespace)))"}))
lQuery("ElemType[id='DataType']/compartType[id='Comment']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion(rdfs:comment /../Name:$getUri(/Name /Namespace) "$value")]]}))
lQuery("ElemType[id='DataType']/compartType[id='DataTypeDefinition']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "DatatypeDefinition(/../Name:$getUri(/Name /Namespace) $getDataTypeRestriction)"}))
lQuery("ElemType[id='DataType']/compartType/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))


lQuery("ElemType[id='AnnotationProperty']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = 'AnnotationAssertion([/container:$isEmpty != true]<http://lumii.lv/2011/1.0/owlgred#Container> /Name:$getAnnotationProperty(/Name /Namespace) $getContainer)'}))
lQuery("ElemType[id='AnnotationProperty']/compartType[id='Name']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "Declaration(AnnotationProperty($getAnnotationProperty(/Name /Namespace)))"}))
lQuery("ElemType[id='AnnotationProperty']/compartType[id='Comment']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion(rdfs:comment /../Name:$getUri(/Name /Namespace) "$value")]]}))
lQuery("ElemType[id='AnnotationProperty']/compartType/subCompartType[id='SuperProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "SubAnnotationPropertyOf(/../../Name:$getAnnotationProperty(/Name /Namespace) $getUri(/Text))"}))
lQuery("ElemType[id='AnnotationProperty']/compartType[id='Domain']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "AnnotationPropertyDomain(/../Name:$getAnnotationProperty(/Name /Namespace) $getAnnotationProperty(/Name /Namespace))"}))
lQuery("ElemType[id='AnnotationProperty']/compartType[id='Range']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "AnnotationPropertyRange(/../Name:$getAnnotationProperty(/Name /Namespace) $getAnnotationProperty(/Name /Namespace))"}))
lQuery("ElemType[id='AnnotationProperty']/compartType/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getAnnotationProperty(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))

lQuery("ElemType[id='Generalization']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "SubClassOf($getClassExpr(/start) $getClassExpr(/end))"}))

lQuery("ElemType[id='AssocToFork']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "SubClassOf($getClassExpr(/start) $getClassExpr(/end/eStart/end))"}))

lQuery("ElemType[id='Restriction']/compartType[id='Name']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubClassOf([/../Only == 'true'] $getClassExpr(/start) ObjectAllValuesFrom(!(?(ObjectInverseOf([/IsInverse == 'true'] $getUri(/Role /Namespace))) ?([/IsInverse != 'true'] $getUri(/Role /Namespace))) $getClassExpr(/end)))
SubClassOf([/../Only != 'true'] $getClassExpr(/start) ObjectSomeValuesFrom(!(?(ObjectInverseOf([/IsInverse == 'true'] $getUri(/Role /Namespace))) ?([/IsInverse != 'true'] $getUri(/Role /Namespace))) $getClassExpr(/end)))]]}))
-- lQuery("ElemType[id='Restriction']/compartType[id='Only']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "SubClassOf($getClassExpr(/start) ObjectAllValuesFrom(!(?(ObjectInverseOf([/../Name/IsInverse == 'true'][$value == 'true'] /../Name:$getUri(/Role /Namespace))) ?([/../Name/IsInverse != 'true'][$value == 'true'] /../Name:$getUri(/Role /Namespace))) $getClassExpr(/end)))"}))
-- lQuery("ElemType[id='Restriction']/compartType[id='Some']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "SubClassOf($getClassExpr(/start) ObjectSomeValuesFrom(!(?(ObjectInverseOf([/../Name/IsInverse == 'true'][$value == 'true'] /../Name:$getUri(/Role /Namespace))) ?([/../Name/IsInverse != 'true'][$value == 'true'] /../Name:$getUri(/Role /Namespace))) $getClassExpr(/end)))"}))
lQuery("ElemType[id='Restriction']/compartType[id='Multiplicity']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubClassOf($getClassExpr(/start) ObjectExactCardinality([$getMultiplicity('Exact') > -1] $getMultiplicity('Exact') !(?( ObjectInverseOf([/../Name/IsInverse == 'true'] /../Name:$getUri(/Role /Namespace))) ?([/../Name/IsInverse != 'true'] /../Name:$getUri(/Role /Namespace))) $getClassExpr(/end)))
SubClassOf($getClassExpr(/start) ObjectMinCardinality([$getMultiplicity('Min') > -1] $getMultiplicity('Min') !(?(ObjectInverseOf([/../Name/IsInverse == 'true'] /../Name:$getUri(/Role /Namespace))) ?([/../Name/IsInverse != 'true'] /../Name:$getUri(/Role /Namespace))) $getClassExpr(/end)))
SubClassOf($getClassExpr(/start) ObjectMaxCardinality([$getMultiplicity('Max') > -1] $getMultiplicity('Max') !(?(ObjectInverseOf([/../Name/IsInverse == 'true'] /../Name:$getUri(/Role /Namespace))) ?([/../Name/IsInverse != 'true'] /../Name:$getUri(/Role /Namespace))) $getClassExpr(/end)))]]}))

lQuery("ElemType[id='EquivalentClass']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[EquivalentClasses(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType /Namespace) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) !(?$getClassExpr(/start) ?$getClassExpr(/end))[$count > 1])]]}))

lQuery("ElemType[id='Disjoint']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[DisjointClasses(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType /Namespace) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) !(?$getClassExpr(/start) ?$getClassExpr(/end))[$count > 1])]]}))

lQuery("ElemType[id='ComplementOf']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[EquivalentClasses(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType /Namespace) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) $getClassExpr(/start) ObjectComplementOf($getClassExpr(/end)))]]}))

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain( $getUri(/Name /Namespace) $getDomainOrRange(/start))
ObjectPropertyRange( $getUri(/Name /Namespace) $getDomainOrRange(/end))]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain($getUri(/Name /Namespace) $getDomainOrRange(/end))
ObjectPropertyRange($getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType[id='SuperProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubObjectPropertyOf($getRoleExpr $getUri($value))]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType[id='SuperProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubObjectPropertyOf($getRoleExpr $getUri($value))]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType[id='DisjointProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[DisjointObjectProperties(/ASFictitiousDisjointProperty/DisjointProperty:$getUri(/Expression) $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType[id='DisjointProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[DisjointObjectProperties(/ASFictitiousDisjointProperty/DisjointProperty:$getUri(/Expression) $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Multiplicity']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubClassOf($getClassExpr(/start) ObjectExactCardinality([$getMultiplicity('Exact') > -1] $getMultiplicity('Exact') $getRoleExpr $getClassExpr(/end)))
SubClassOf($getClassExpr(/start) ObjectMinCardinality([$getMultiplicity('Min') > -1] $getMultiplicity('Min') $getRoleExpr $getClassExpr(/end)))
SubClassOf($getClassExpr(/start) ObjectMaxCardinality([$getMultiplicity('Max') > -1] $getMultiplicity('Max') $getRoleExpr $getClassExpr(/end)))]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Multiplicity']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubClassOf($getClassExpr(/end) ObjectExactCardinality([$getMultiplicity('Exact') > -1] $getMultiplicity('Exact') $getRoleExpr $getClassExpr(/start)))
SubClassOf($getClassExpr(/end) ObjectMinCardinality([$getMultiplicity('Min') > -1] $getMultiplicity('Min') $getRoleExpr $getClassExpr(/start)))
SubClassOf($getClassExpr(/end) ObjectMaxCardinality([$getMultiplicity('Max') > -1] $getMultiplicity('Max') $getRoleExpr $getClassExpr(/start)))]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Functional']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[FunctionalObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Functional']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[FunctionalObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='InverseFunctional']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[InverseFunctionalObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='InverseFunctional']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[InverseFunctionalObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Symmetric']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SymmetricObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Symmetric']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SymmetricObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Asymmetric']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AsymmetricObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Asymmetric']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AsymmetricObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Reflexive']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[ReflexiveObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Reflexive']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[ReflexiveObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Irreflexive']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[IrreflexiveObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Irreflexive']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[IrreflexiveObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Transitive']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[TransitiveObjectProperty([$value == 'true'] $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Transitive']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[TransitiveObjectProperty([$value == 'true'] $getRoleExpr)]]}))
----------------------------lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType[id='PropertyChains']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubObjectPropertyOf(ObjectPropertyChain(!(?(/ASFictitiousPropertyChain/PropertyChain[/Inverse == 'true'] ObjectInverseOf($getUri(/Property /Namespace))) ?(/ASFictitiousPropertyChain/PropertyChain[/Inverse != 'true'] $getUri(/Property /Namespace)))) $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType[id='PropertyChains']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubObjectPropertyOf(ObjectPropertyChain(!(/ASFictitiousPropertyChain/PropertyChain ?([/Inverse == 'true'] ObjectInverseOf($getUri(/Property /Namespace))) ?([/Inverse != 'true'] $getUri(/Property /Namespace)))) $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType[id='PropertyChains']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubObjectPropertyOf(ObjectPropertyChain(!(/ASFictitiousPropertyChain/PropertyChain ?([/Inverse == 'true'] ObjectInverseOf($getUri(/Property /Namespace))) ?([/Inverse != 'true'] $getUri(/Property /Namespace)))) $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType[id='EquivalentProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[EquivalentObjectProperties(/ASFictitiousEquivalentProperty/EquivalentProperty:$getUri(/Expression) $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType[id='EquivalentProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[EquivalentObjectProperties(/ASFictitiousEquivalentProperty/EquivalentProperty:$getUri(/Expression) $getRoleExpr)]]}))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))

lQuery("ElemType[id='Dependency']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = "ClassAssertion($getClassExpr(/end) $getObjectExpr(/start))"}))

lQuery("ElemType[id='Link']/compartType[id='Direct']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[NegativeObjectPropertyAssertion([/IsNegativeAssertion == 'true'] $getUri(/Property /Namespace) $getObjectExpr(/start) $getObjectExpr(/end))
ObjectPropertyAssertion([/IsNegativeAssertion != 'true'] $getUri(/Property /Namespace) $getObjectExpr(/start) $getObjectExpr(/end))]]}))
lQuery("ElemType[id='Link']/compartType[id='Inverse']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[NegativeObjectPropertyAssertion([/InvIsNegativeAssertion == 'true'] $getUri(/InvProperty /InvNamespace) $getObjectExpr(/start)  $getObjectExpr(/end))
ObjectPropertyAssertion([/InvIsNegativeAssertion!= 'true'] $getUri(/InvProperty /InvNamespace) $getObjectExpr(/start) $getObjectExpr(/end))]]}))

lQuery("ElemType[id='SameAsIndivid']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SameIndividual(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) $getObjectExpr(/end) $getObjectExpr(/start))]]}))

lQuery("ElemType[id='DifferentIndivid']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[DifferentIndividuals(?(Annotation(/Annotation:$getAnnotationProperty(/AnnotationType) "$value(/Annotation/ValueLanguage/Value)" ?(@$value(/Annotation/ValueLanguage/Language)))) $getObjectExpr(/end) $getObjectExpr(/start))]]}))



-----------------------------------------------------------------------Attribute

lQuery("ElemType[id='Attribute']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyDomain(/Name:$getUri(/Name /Namespace) $getClassExpr(/end))
DataPropertyDomain(/Name:$getUri(/Name /Namespace) $getClassExpr(/start))
DataPropertyRange(/Name:$getUri(/Name  /Namespace) $getDataTypeExpression)]]}))

lQuery("ElemType[id='Attribute']/compartType[id='Multiplicity']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubClassOf($getClassExpr(/start) DataExactCardinality([$getMultiplicity('Exact') > -1]$getMultiplicity('Exact') /../Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/end) DataExactCardinality([$getMultiplicity('Exact') > -1]$getMultiplicity('Exact') /../Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/start) DataMinCardinality([$getMultiplicity('Min') > -1]$getMultiplicity('Min') /../Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/end) DataMinCardinality([$getMultiplicity('Min') > -1]$getMultiplicity('Min') /../Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/start) DataMaxCardinality([$getMultiplicity('Max') > -1]$getMultiplicity('Max') /../Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/end) DataMaxCardinality([$getMultiplicity('Max') > -1]$getMultiplicity('Max') /../Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]}))

lQuery("ElemType[id='Attribute']/compartType[id='IsFunctional']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[FunctionalObjectProperty(/../Name:$getUri(/Name /Namespace))]]}))

lQuery("ElemType[id='Attribute']/compartType/subCompartType/subCompartType[id='EquivalentProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[EquivalentDataProperties(/../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))]]}))
lQuery("ElemType[id='Attribute']/compartType/subCompartType/subCompartType[id='SuperProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[SubDataPropertyOf(/../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))]]}))
lQuery("ElemType[id='Attribute']/compartType/subCompartType/subCompartType[id='DisjointProperties']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[DisjointDataProperties(/../../../Name:$getUri(/Name /Namespace) $getUri(/Expression))]]}))
lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']"):link("tag", lQuery.create("Tag", {key = "ExportAxiom", value = [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]]}))

end