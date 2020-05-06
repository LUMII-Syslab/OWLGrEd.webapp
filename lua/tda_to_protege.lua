module(..., package.seeall)

require("core")
require("utilities")
require("owl_protege_export")
parser = require("owl_parser")
specific = require("OWL_specific")
require("progress_reporter")
require("re")
MP = require("ManchesterParser")
report = require("reporter.report")

elements = {}
elements['Class'] = {"Thing"}
elements['Object'] = {}
elements['ObjectProp'] = {}

annotation_table = {
	backwardCompatibleWith = "owl:backwardCompatibleWith",
	deprecated = "owl:deprecated",
	comment = "rdfs:comment",
	incompatibleWith = "owl:incompatibleWith",
	isDefinedBy = "rdfs:isDefinedBy",
	label = "rdfs:label",
	priorVersion = "owl:priorVersion",
	seeAlso = "rdfs:seeAlso",
	versionInfo = "owl:versionInfo",
	date = "<http://purl.org/dc/elements/1.1/date>"
}

class_table = {
	Thing = "http://www.w3.org/2002/07/owl#",
	Nothing = "http://www.w3.org/2002/07/owl#"
}


function export_from_diagram()
	tda.CallFunctionWithPleaseWaitWindow("tda_to_protege.export_muliple_ontologies", "CurrentDgrPointer/graphDiagram/parent")
end

function export_from_seed()
	tda.CallFunctionWithPleaseWaitWindow("tda_to_protege.export_muliple_ontologies", "CurrentDgrPointer/graphDiagram/collection/element")
end

function export_muliple_ontologies(path_to_root_seed)
	local seed = lQuery(path_to_root_seed)
	local seed_set = specific.get_ontologies_from_seed(seed, "/compartment")
	table.insert(seed_set, seed)
	local export_size = get_number_of_elements_in_export(seed_set)
	local increment_progress = progress_reporter.create_progress_logger(export_size, "Exporting...")
	local export_array = {}

	--object_property_table = get_object_properties(seed_set)
	--print(dumptable(object_property_table))


	for i, ontology in pairs(seed_set) do
		local diagram = ontology:find("/child")
		local uri, str, global_table, iris_table = export_ontology(diagram, ontology, increment_progress)
		table.insert(export_array, {
		  ontology = str,
  		expressions = global_table,
  		ontology_uri = uri,
  		ontology_import_iris = iris_table
		})
	end
	owl_protege_export.export_data("127.0.0.1", 1234, export_array)
end

function get_number_of_elements_in_export(seed_set)
	local total = 0
	for i, seed in pairs(seed_set) do
		total = total + seed:find("/child/element"):size()
	end
	return total
end

function send_ontology(iri, str, global_table, iris_table)
	local ip, port = "127.0.0.1", 1234
	local send_table = {
		ontology = str,
		expressions = global_table,
		ontology_uri = iri,
		ontology_import_iris = iris_table
		}
	owl_protege_export.export_data(ip, port, send_table)
end

function get_ontologies(diagram, diagrams)
	diagram = lQuery(diagram)
	diagram:find("/element:has(/elemType[id='OntologyFragment'])"):each(function(ontology_seed, i)
		ontology_seed = lQuery(ontology_seed)
		local target_diagram = ontology_seed:find("/child")
		table.insert(diagrams, target_diagram)
		get_ontologies(target_diagram, diagrams)
	end)
end

function find_diagram_source(diagram_source)
	if diagram_source:find("/elemType"):attr("id") == "OWL" then return diagram_source
	else return find_diagram_source(diagram_source:find("/graphDiagram/parent")) end
end

function make_global_ns_uri_table(diagram)
	local ns_uri_table = {}
	local ontology_seeds = {}
	ontology_seeds = specific.get_ontologies_from_seed(diagram:find("/parent"), "/compartment:has(/compartType[id = 'Prefix'])")

	for i, elem in pairs(ontology_seeds) do
		local ns = specific.remove_dot_owl(elem:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("value"))
		local uri = elem:find("/compartment:has(/compartType[id = 'Prefix'])"):attr_e("value")
		ns_uri_table[ns] = make_uri(uri)
	end

	local diagram_source = find_diagram_source(diagram:find("/parent"))
	local current_diagram_uri = diagram_source:find("/compartment:has(/compartType[id = 'Prefix'])"):attr_e("value")

	local length = string.len(current_diagram_uri)
	if (string.sub(current_diagram_uri, -1, length) ~= "/") then
		current_diagram_uri = current_diagram_uri .. "#"
	end

	local current_diagram_name = specific.remove_dot_owl(diagram_source:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("value"))
	current_diagram_name = string.gsub(current_diagram_name, " ", "_")
	ns_uri_table[""] = current_diagram_uri
	ns_uri_table[current_diagram_name] = current_diagram_uri
	ns_uri_table["owl2xml"] = "http://www.w3.org/2006/12/owl2-xml#"
	ns_uri_table["owl"] = "http://www.w3.org/2002/07/owl#"
	ns_uri_table["rdf"] = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	ns_uri_table["rdfs"] = "http://www.w3.org/2000/01/rdf-schema#"
	ns_uri_table["xsd"] = "http://www.w3.org/2001/XMLSchema#"
	ns_uri_table["xml"] = "http://www.w3.org/XML/1998/namespace"
	ns_uri_table["XMLSchema"] = "http://www.w3.org/2001/XMLSchema#"
	set_OWLGrEd_namespaces(ns_uri_table)
	diagram_source:find("/compartment/subCompartment:has(/compartType[id = 'Namespaces'])"):each(function(namespace_compart)
		local prefix = namespace_compart:find("/subCompartment:has(/compartType[id = 'Prefix'])"):attr("value")
		local iri = namespace_compart:find("/subCompartment:has(/compartType[id = 'IRI'])"):attr("value")
		if prefix ~= "" and iri ~= "" then
			ns_uri_table[prefix] =  make_uri(iri)
		end
	end)

	--get namespace tags from diagram
	local grammer = re.compile([[ grammer <- {:key: [^%nl]*:} {:delimiter: (%nl):}  {:namespace: .*:} ]])
	utilities.get_tags(diagram, "namespace"):each(function(ns)
		local res = re.match(ns:attr("value"), lpeg.Ct(grammer) * -1)
		ns_uri_table[res["key"]] = res["namespace"]
	end)

	diagram:find("/element:has(/elemType[id = 'DataType'])"):each(function(data_type)
		make_uri_table(diagram, "DataType", "/compartment/subCompartment:has(/compartType[id = 'Name'])",
												"/compartment/subCompartment:has(/compartType[id = 'Namespace'])", ns_uri_table)
	end)

	--get namspaces from AnnoationProperties
	-- diagram:find("/element:has(/elemType[id = 'AnnotationProperty'])"):each(function(annot)
	-- 	local name_compart = annot:find("/compartment:has(/compartType[id = 'Name'])")
	-- 	local key = name_compart:find("/subCompartment:has(/compartType[id = 'Name'])"):attr("value")
	-- 	if key ~= "" and key ~= nil then
	-- 		local uri = name_compart:find("/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
	-- 		if (ns_uri_table[uri]) then
	-- 			ns_uri_table[key] = ns_uri_table[uri]
	-- 		else
	-- 			ns_uri_table[key] = uri
	-- 		end
	-- 	end
	-- end)

	return ns_uri_table
end

function make_uri(uri)
	local new_uri = uri
	local len = string.len(uri)
	local position1 = string.find(uri, "#", -1)
	local position2 = string.find(uri, "/", -1)
	if position1 == nil and position2 ==  nil then
		new_uri = uri .. "#"
	end
	return new_uri
end

function set_OWLGrEd_namespaces(ns_uri_table)
	--owlFields:=<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#>
	lQuery("ToolType"):find("/tag[key = 'owl_NamespaceDef']"):each(function(tag_)
		local definition = tag_:attr("value")
		local res_table = specific.split_owl_NamespaceDef_tag(definition)
		if res_table ~= nil then
			local index = res_table["ns"]
			if ns_uri_table[index] == nil then
				ns_uri_table[index] = res_table["URI"]
			end
		end
	end)
end

function make_assoc_path(type_name, name)
	return "/compartment:has(/compartType[id = '" .. type_name .. "'])/subCompartment:has(/compartType[id = '" .. name .. "'])"
end

function make_global_element_uri_table_for_diagramm(diagram, elem_type, path_prefix)
	local path_prefix = "/compartment/subCompartment:has(/compartType[id = 'Attributes'])"
	local uri_table = make_uri_table(diagram, elem_type, path_prefix .. "/subCompartment:has(/compartType[id = 'Name'])", path_prefix .. "/subCompartment:has(/compartType[id = 'Namespace'])")

	diagram:find("/element:has(/elemType[id='OntologyFragment'])"):each(function(el)
		el:find("/child"):each(function(dia)
			local uri_table_temp = make_global_element_uri_table_for_diagramm(dia, elem_type, path_prefix)
			uri_table = concat_uri_tables(uri_table, uri_table_temp)
		end)
	end)
	return uri_table
end

function make_global_object_property_uri_table(diagram)
	local top_diagram = get_top_diagram(diagram)
	return make_global_object_property_uri_table_for_diagram(top_diagram)
end

function make_global_object_property_uri_table_for_diagram(diagram)
	local role_uri_table = {}
	diagram:find("/element:has(/elemType[id='Association'])"):each(function(assoc, i)
		assoc = lQuery(assoc)
		local direct_role, direct_uri, _ = get_obj_name_uri(assoc, make_assoc_path("Name", "Name"), make_assoc_path("Name", "Namespace"))
		local inv_role, inv_uri, _ = get_obj_name_uri(assoc, make_assoc_path("InvName", "Name"), make_assoc_path("InvName", "Namespace"))
		role_uri_table[direct_role] = direct_uri
		role_uri_table[inv_role] = inv_uri
	end)
	
	diagram:find("/element:has(/elemType[id='OntologyFragment'])"):each(function(el)
		el:find("/child"):each(function(dia)
			local role_uri_table_temp = make_global_object_property_uri_table_for_diagram(dia)
			role_uri_table = concat_uri_tables(role_uri_table, role_uri_table_temp)
		end)
	end)
	
	return role_uri_table
end


function make_global_data_property_uri_table(diagram)
	local path_prefix = "/compartment/subCompartment:has(/compartType[id = 'Attributes'])"
	local elem_type = "Class"
	local top_diagram = get_top_diagram(diagram)
	return  make_global_element_uri_table_for_diagramm(top_diagram, elem_type, path_prefix)
end

function make_global_object_uri_table(diagram)
	local path_prefix = "/compartment/subCompartment:has(/compartType[id = 'Name'])"
	local elem_type = "Object"
	local top_diagram = get_top_diagram(diagram)
	return make_global_element_uri_table_for_diagramm(top_diagram, elem_type, path_prefix)
end


function make_global_class_uri_table(diagram)
	local path_prefix = "/compartment:has(/compartType[id = 'Name'])"
	local elem_type = "Class"
	local top_diagram = get_top_diagram(diagram)
	return make_global_element_uri_table_for_diagramm(top_diagram, elem_type, path_prefix)
end

function make_uri_table(diagram, elem_type_name, path_to_name, path_to_ns, role_uri_table)
	role_uri_table = role_uri_table or {}
	diagram:find("/element:has(/elemType[id='" .. elem_type_name .. "'])"):each(function(class)
		class:find(path_to_name):each(function(name)
			local attr_name = name:attr_e("value")
			attr_name = string.gsub(attr_name, " ", "_")
			local uri = get_uri_by_ns(class, path_to_ns)
			role_uri_table[attr_name] = uri
		end)
	end)
	return role_uri_table
end

function concat_uri_tables(uri_table_1, uri_table_2)
	for k, v in pairs(uri_table_2) do
		uri_table_1[k] = v
	end
	return uri_table_1
end

function get_top_diagram(diagram)
	local source_diagram = diagram:find("/parent/graphDiagram:has(/graphDiagramType[id = 'OWL'])")
	local res_diagram = nil
	if source_diagram:size() == 0 then
		res_diagram = diagram
	else
		res_diagram = get_top_diagram(source_diagram)
	end
return res_diagram
end

ns_uri_table = {}
error_table = {}

function export_ontology(diagram, ontology, increment_progress)
	ontology_ns = "test:"
	local str = ""
	local global_table = {}
	local iris_table = {}

--Ontology(<http://lumii.lv/ontologies/test/test.owl>
	ns_uri_table = nil
	ns_uri_table = make_global_ns_uri_table(diagram)
	object_property_uri_table = make_global_object_property_uri_table(diagram)
	data_property_uri_table = make_global_data_property_uri_table(diagram)	
	object_uri_table = make_global_object_uri_table(diagram)
	class_uri_table = make_global_class_uri_table(diagram)

	--print(dumptable(class_uri_table))

	--local diagram = lQuery(path_to_seed)
	--local ontology = lQuery(path_to_ontology)
	local comment = ""
	local diagrams = {}
	local top_diagram = get_top_diagram(diagram)

	ontology = lQuery(top_diagram):find("/parent")
	table.insert(diagrams, top_diagram)
	get_ontologies(top_diagram, diagrams)

	local name = ontology:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("value")
	local uri = ontology:find("/compartment:has(/compartType[id = 'Prefix'])"):attr_e("value")
	ontology_ns = ontology:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("value")
	local ontology_comment_obj = ontology:find("/compartment:has(/compartType[id = 'Comment'])")
	local ontology_comment = ontology_comment_obj:attr_e("value")

	if ontology_comment ~= nil and ontology_comment ~= "" then
		ontology_comment = "\"" .. string.gsub(ontology_comment, "\"", "\\\"") .. "\""
		comment = comment .. ontology_annotations(ontology_comment_obj, "Comment", ontology_comment, "")
	end

	local tmp_annot = make_ontology_annotation(ontology, "/compartment/subCompartment:has(/compartType[id = 'Annotation'])")
	if tmp_annot ~= nil and tmp_annot ~= "" then
		comment = comment .. tmp_annot
	end

	local imports = ""
	ontology:find("/eStart:has(/elemType[id = 'Import'])/end"):each(function(obj)
		local import_ontology_uri = obj:find("/compartment:has(/compartType[id = 'Prefix'])"):attr_e("value")
		if import_ontology_uri ~= "" then
			table.insert(iris_table, import_ontology_uri)
			--imports = "Import(<" .. import_ontology_uri .. ">)\n"
		end
	end)
	local header1 = get_import_ontology_ns_uri(ns_uri_table)
	if uri ~= nil then
		header = header1 .. "Ontology(<" .. uri .. ">\n" .. comment
	end
	lQuery("Element:has(/elemType)"):attr("axiom", "")
	str, global_table = export_diagram(diagrams, increment_progress)
	str = string.format("%s%s%s)", header, str, export_plugin(diagram))

	--print(dumptable(global_table))
	--print(str)
return uri, str, global_table, iris_table
end

function export_plugin(diagram)
	local res = ""
	local export_translet = utilities.get_tags(lQuery("ToolType"), "owlgred_export"):attr("value")
	res = utilities.execute_translet(export_translet, diagram) or ""
	return res
end


function export_Header(diagram)
	if diagram == nil then
		diagram = utilities.current_diagram()
	end
	ns_uri_table = make_global_ns_uri_table(diagram)
	local ontology = find_diagram_source(diagram:find("/parent"))
	local name = ontology:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("value")
	local uri = ontology:find("/compartment:has(/compartType[id = 'Prefix'])"):attr_e("value")
	ontology_ns = ontology:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("value")
	local ontology_comment_obj = ontology:find("/compartment:has(/compartType[id = 'Comment'])")
	local comment = ""
	if ontology_comment_obj ~= nil then
		local ontology_comment = ontology_comment_obj:attr_e("value")
		if ontology_comment ~= "" then
			ontology_comment = string.format('%s%s%s', "\"", string.gsub(ontology_comment, "\"", "\\\""), "\"")
			comment = ontology_annotations(ontology_comment_obj, "Comment", ontology_comment, "")
		end
	end
	local ontology_header = ""
	local header = get_import_ontology_ns_uri(ns_uri_table)

	if uri ~= nil then
		local exportOntology = require("exportOntology")
		local imports = exportOntology.getImports(ontology)
		ontology_header = header .. "Ontology(<" .. uri .. ">\n" .. imports  --.. comment
	end
	return ontology_header
end

function export_diagram(diagrams, increment_progress, is_global_tables_needed)
	local global_table = {}

	local res = {}
	if lQuery("OWL_PP#ExportParameter[pName='includeToolAndPluginVersionAnnotations']"):attr("pValue") == "true" then
		local release_version = lQuery("Project"):attr("release_version")
		if release_version == nil then release_version = lQuery("Project"):attr("version") end
		table.insert(res,'Annotation(owlgred:tool_version "' .. release_version .. '")')

		lQuery("Plugin"):each(function(plugin)
			table.insert(res,'Annotation(owlgred:plugin_version "' .. plugin:attr("id") .. " " .. plugin:attr("version") .. '")')
		end)
	end
	for i, diagram in pairs(diagrams) do
		local isObjectAttribute = require("isObjectAttribute")
		
		if is_global_tables_needed then
			ns_uri_table = make_global_ns_uri_table(diagram)
			object_property_uri_table = make_global_object_property_uri_table(diagram)
			data_property_uri_table = make_global_data_property_uri_table(diagram)
			object_uri_table = make_global_object_uri_table(diagram)
			class_uri_table = make_global_class_uri_table(diagram)
		end
		
		isObjectAttribute.setIsObjectAttributeForAllAttribute(diagram, ns_uri_table)

		-- print(dumptable(data_property_uri_table))
		local export_ontology = require("exportOntology")
		table.insert(res, export_ontology.forAllElementsExportTags(diagram, ns_uri_table, object_property_uri_table, data_property_uri_table))
		
		-- get_classes(diagram)

		-- annotation_to_annotation(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Annotation']):not(:has(/eStart)):not(:has(/eEnd))"))

		-- enumeration_to_datatype(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Enumeration'])"))

		-- datatype_to_datatype(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='DataType'])"))

		-- class_to_concept(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Class']):has(/graphDiagram)"))

		-- generalization_to_subtype(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Generalization'])"))

		-- object_to_individual(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Object'])"))

		-- link_to_objectPropertyAssertion(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Link'])"))

		-- association_to_property(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Association'])"))

		-- equivalent_to_equivalent(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='EquivalentClass'])"))

		-- disjoint_to_disjoint(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Disjoint'])"))

		-- complement_to_complement(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='ComplementOf'])"))

		-- different_to_different(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='DifferentIndivid'])"))

		-- same_to_same(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='SameAsIndivid'])"))

		-- sameAs_to_sameAs(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='SameAsIndivids'])"))

		-- differentIndivids_to_differentIndivids(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='DifferentIndivids'])"))

		-- equivalentClasses_to_equivalentClasses(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='EquivalentClasses'])"))

		-- disjointClasses_to_disjointClasses(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='DisjointClasses'])"))

		-- generalizationFork_to_subtypeFork(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='HorizontalFork'])"))

		-- someValuesFrom_to_someValuesFrom(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='Restriction'])"))

		-- annotationProperty_to_annotationProperty(global_table, diagram, increment_progress)
		-- table.insert(res, get_element_type_axioms(diagram, "/element:has(/elemType[id='AnnotationProperty'])"))

		-- table.insert(res, make_error_class())
	end

	--print(dumptable(global_table))
	--log(str)
return table.concat(res) .."\n", global_table
end

function get_import_ontology_ns_uri(ns_uri_table)
	local res = ""
	for ns, uri in pairs(ns_uri_table) do
		if ns == "xml" then
			res = res .. string.format("Prefix(%s:=<%s>)\n", ns, uri)
		else
			if string.sub(uri, string.len(uri)-1) == "##" then
			res = res .. string.format("Prefix(%s:=<%s>)\n", ns, string.sub(uri, 1, string.len(uri)-1))
			else res = res .. string.format("Prefix(%s:=<%s>)\n", ns, uri)
			end
		end
	end
	-- print("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRrr", res, string.sub(res, string.len(res)-1), "END")
	-- if string.sub(res, string.len(res)-1) == "##" then res = string.sub(res, 1, string.len(res)) end
	return res
end

function get_current_uri()
	local path = ""
	local source = utilities.active_elements()
	if source:size() == 0 then
		source = utilities.current_diagram()
		path = "/parent/compartment:has(/compartType[id = 'Prefix'])"
	else
		path = "/compartment:has(/compartType[id = 'Prefix'])"
	end
	local res = source:find(path):attr_e("value") .. "#"
	return res
end

function get_element_type_axioms(diagram, path)
	local str = ""
	diagram:find(path):each(function(elem)
		str = str .. elem:attr("axioms")
	end)
return str
end

function annotation_to_annotation(global_table, diagram, increment_progress)
	local axiom_value = ""
	diagram:find("/element:has(/elemType[id='Annotation']):not(:has(/eStart)):not(:has(/eEnd))"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='Annotation']):not(:has(/eStart)):not(:has(/eEnd))"):each(function(annotation)
		increment_progress()
		local annotation_type = annotation:find("/compartment:has(/compartType[id = 'AnnotationType'])"):attr_e("value")
		local annotation_value = annotation:find("/compartment/subCompartment:has(/compartType[id = 'Value'])"):attr_e("value")
		annotation_value = "\"" .. string.gsub(annotation_value, "\"", "\\\"") .. "\""
		local annotation_lang = annotation:find("/compartment/subCompartment:has(/compartType[id = 'Language'])"):attr_e("value")
		local annot_ns = annotation:find("/compartment:has(/compartType[id = 'Namespace'])"):attr_e("value")

		local tmp = ontology_annotations(annotation, annotation_type, annotation_value, annotation_lang, annot_ns)
		if tmp ~= nil and tmp ~= "" then
			axiom_value = axiom_value .. tmp
		end
		annotation:attr("axioms", axiom_value)
	end)
end

function get_class_name(class)
	local class_name = class:find("/compartment/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
	if class_name ~= "" then
		return string.gsub(class_name, " ", "_")
	else
		return ""
	end
end

function datatype_to_datatype(global_table, diagram, increment_progress)
	local list_of_text = {}
	--diagram:find("/element:has(/elemType[id='DataType'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id = 'DataType'])"):each(function(data_type)
		increment_progress()
		local uri = diagram:find("/parent/compartment:has(/compartType[id = 'Prefix'])"):attr_e("value")
		local name = data_type:find("/compartment/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
		local ns = data_type:find("/compartment/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
		local full_data_type_name = make_full_object_name(ns, name)
		local anotations = execute_tag_key_procedures(data_type)
		table.insert(list_of_text, string.format('Declaration(%s Datatype(%s))\n', anotations, full_data_type_name))
		data_type:find("/compartment:has(/compartType[id = 'DataTypeDefinition'])"):each(function(expr)
			local expr_val = expr:attr_e("value")
			local paresed_expr_val = process_data_type_expr_value(expr_val, diagram)
			if paresed_expr_val ~= nil and paresed_expr_val ~= "" then
				table.insert(list_of_text, string.format("DatatypeDefinition(%s ", full_data_type_name))
				table.insert(list_of_text, paresed_expr_val)
				table.insert(list_of_text, ")\n")
			end

			--print("Axiom value")
			--print(axion_value)
			--if expr_val ~= "" then
			--	--axiom_value = axiom_value .. make_data_type_axiom(full_data_type_name, expr_val)
			--	--axiom_value = axiom_value .. process_each_expression("DatatypeDefinition", make_full_object_name_for_table(ns, name), sub_expr)
			--	local res = MP.parseDatatypeRestriction(expr_val)
			--	if res ~= nil then
			--		axiom_value = axiom_value .. res .. "\n"
			--	else
			--		print("Syntax error or unsupported syntax")
			--		print(expr_val)
			--	end
			--	--insert_axiom_in_table(global_table['OWLDatatype']['OWLDatatypeDefinitionAxiom'], make_full_object_name_for_table(ns, name), expr_val)
			--end
		end)
		data_type:attr("axioms", table.concat(list_of_text))
	end)
end

function process_data_type_expr_value(expr_val, diagram)
	local result = ""
	if expr_val ~= "" and expr_val ~= nil then
		local res = MP.parseDatatypeRestriction(expr_val, diagram)
		if res ~= nil then
			local tmp_list = {}
			table.insert(tmp_list, res)
			result = table.concat(tmp_list)
			--axiom_value = axiom_value .. res .. "\n"
		else
			parser_error(expr_val)
			print("Syntax error or unsupported syntax")
			print(expr_val)
			error_table[expr_val] = true
		end
	end
	return result
end

function enumeration_to_datatype(global_table, diagram, increment_progress)
	local axiom_value = ""
	local tmp_diagram = diagram
	local list_of_code = {}
	--tmp_diagram:find("/element:has(/elemType[id='DataType'])"):attr("axiom", "")
	tmp_diagram:find("/element:has(/elemType[id = 'Enumeration'])"):each(function(data_type)
		increment_progress()
		local name = data_type:find("/compartment/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
		local ns = data_type:find("/compartment/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
		local full_data_type_name = make_full_object_name(ns, name)
		local anotations = execute_tag_key_procedures(data_type)
		table.insert(list_of_code, string.format("Declaration(%s Datatype(%s))\n", anotations, full_data_type_name))
		local expr_table = {}
		data_type:find("/compartment/subCompartment:has(/compartType[id = 'Values'])"):each(function(expr)
			table.insert(expr_table, lQuery(expr):attr_e("value"))
		end)
		local expr_val = table.concat(expr_table, ", ")
		if expr_val ~= "" then
			--axiom_value = axiom_value .. make_data_type_axiom(full_data_type_name, expr_val)
			--axiom_value = axiom_value .. process_each_expression("DatatypeDefinition", make_full_object_name_for_table(ns, name), sub_expr)
			--insert_axiom_in_table(global_table['OWLDatatype']['OWLDatatypeDefinitionAxiom'], make_full_object_name_for_table(ns, name), "{" .. expr_val .. "}")
			--table.insert(list_of_code, process_data_type_expr_value(expr_val))
			table.insert(list_of_text, string.format("DatatypeDefinition(%s ", full_data_type_name))
			table.insert(list_of_text, process_data_type_expr_value(expr_val, diagram))
			table.insert(list_of_text, ")\n")
		end
		data_type:attr("axioms", table.concat(list_of_code))
	end)
end

function make_data_type_axiom(base, data_type_axiom)
	local axiom = ""
	axiom = axiom .. "DatatypeDefinition(" ..  base .. " " .. data_type_axiom .. ")\n"
	return axiom
end

function class_to_concept(global_table, diagram, increment_progress)

	print("*************************************")

	local axiom_value = ""
	local class_value = ""
	local class_declaration = ""
	diagram = lQuery(diagram)
	diagram:find("/element:has(/elemType[id='Class'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='Class'])"):each(function(class)
		export_Class(class)
	end)
end

function export_Class(class, increment_progress)
	axiom_value = ""
	class_value = ""
	class_declaration = ""
	if increment_progress ~= nil then
		increment_progress()
	end
	local class_name_obj = class:find("/compartment/subCompartment:has(/compartType[id = 'Name'])")
	local class_name = class_name_obj:attr_e("value")
	local ns_obj = class:find("/compartment/subCompartment:has(/compartType[id = 'Namespace'])")
	local ns = ns_obj:attr_e("value")
	local full_class_name = ""
	local uri = ""
	--class_name = get_class_name(class)
	local anotations = execute_tag_key_procedures(class)
	if class_name ~= "" and class_name ~= nil then
--			if class_name == "Thing" then
--				full_class_name = "owl:" .. class_name
--			else
--				full_class_name = "<" .. uri .. class_name .. ">"
--			end
		full_class_name, uri = get_full_class_name_by_name_and_ns(class_name, ns)
		class_declaration = "Declaration(" .. anotations .. "Class(" .. full_class_name .. "))\n"
		axiom_value = make_multiple_annotations(class, "/compartment/subCompartment:has(/compartType[id = 'Annotation'])", "Class", full_class_name, ")")
	end

	--print(full_class_name)

	local comment = class:find("/compartment:has(/compartType[id = 'Comment'])")
	local comment_text = comment:attr("value")
	if comment_text ~= "" and comment_text ~= nil then
		comment_text = "\"" .. string.gsub(comment_text, "\"", "\\\"") .. "\""
		axiom_value = axiom_value .. make_annotation("comment", comment_text, "", full_class_name, ")", comment)
	end
	local comment_in_box = get_comment(class, "Class", full_class_name,  "/compartment:has(/compartType[id = 'AnnotationType'])", "/compartment/subCompartment:has(/compartType[id = 'Value'])", "/compartment/subCompartment:has(/compartType[id = 'Language'])")
	for i, j in pairs(comment_in_box) do
		axiom_value = axiom_value .. comment_in_box[i]
	end
	axiom_value = axiom_value .. add_disjoint_axioms(class)
	axiom_value = axiom_value .. add_complete_axioms(class, full_class_name)

	local tmp_str = ""
	axiom_value = axiom_value .. process_class_expresssion_eq_disjoint("EquivalentClasses", class, "/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])", "EquivalentClass", full_class_name)
	axiom_value = axiom_value .. process_class_expresssion_eq_disjoint("DisjointClasses", class, "/compartment/subCompartment:has(/compartType[id = 'DisjointClasses'])", "DisjointClass", full_class_name)
	--axiom_value = axiom_value .. process_class_expresssion("SubClassOf", class, "/compartment/subCompartment:has(/compartType[id = 'SuperClasses'])", full_class_name)

	axiom_value = axiom_value .. process_class_expresssion("SubClassOf", class, "/compartment/subCompartment:has(/compartType[id = 'SuperClasses'])/subCompartment:has(/compartType[id = 'Expression'])", full_class_name)


--		axiom_value = axiom_value .. set_enumerated(diagram, class, increment_progress)
	local attr_values = ""
	axiom_value = axiom_value .. get_key_values(class, full_class_name)

	class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attr)
		local attr_name_obj = attr:find("/subCompartment/subCompartment:has(/compartType[id = 'Name'])")
		local attr_name = attr_name_obj:attr_e("value")
		attr_name = string.gsub(attr_name, " ", "_")
		if attr_name ~= "" and attr_name ~= nil then

			local attr_uri = data_property_uri_table[attr_name]

			local full_attr_name = ""
			if attr_uri ~= nil then
				full_attr_name = "<" .. attr_uri .. attr_name .. ">"
			else
				full_attr_name = "<" .. uri .. attr_name .. ">"
			end
			--local attr_type_obj = attr:find("/subCompartment:has(/compartType[id = 'Type'])")
			--if attr_type_obj:is_empty() then

			local data_or_object_prop = "DataProperty"
			local attr_type_obj = attr:find("/subCompartment/subCompartment:has(/compartType[id = 'Type'])")
			if attr_type_obj:is_empty() then
				attr_type_obj = attr:find("/subCompartment/subCompartment/subCompartment:has(/compartType[id = 'Type'])")
			end
			--local attribute_type = attr_type_obj:attr_e("value")
			local attribute_ns = attr:find("/subCompartment:has(/compartType[id = 'Type'])/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
			local attr_type

			local attribute_type = attr:find("/subCompartment:has(/compartType[id='Type'])"):attr("value")

			if attribute_type ~= nil and attribute_type ~= "" then
				attribute_type = string.gsub(attribute_type, ":", "")
				--end
				--local base_type, attr_type, buls = get_attribute_type(class:find("/graphDiagram"), attribute_type, attribute_ns, increment_progress)
				local isObjectAttribute = attr:find("/subCompartment:has(/compartType[id = 'isObjectAttribute'])")
				--attr_type, data_or_object_prop = MP.generateAttributeType(attribute_type, class:find("/graphDiagram"), isObjectAttribute)
				local OA = require("isObjectAttribute")
				attr_type, data_or_object_prop = OA.checkAttributeType(attribute_type, class:find("/graphDiagram"), isObjectAttribute, attr)

				if attr_type == nil or data_or_object_prop == nil then
					log("Axiom expression is incorrect")
					log(attribute_type)
					error_table[attribute_type] = true
				end
			end
			attr_values = string.format("%sDeclaration(%s(%s))\n", attr_values, data_or_object_prop, full_attr_name)
			attr_values = string.format("%s%sDomain(%s %s)\n", attr_values, data_or_object_prop, full_attr_name, full_class_name)
			-- local prefix = "Data"
			-- if buls then
			if attr_type ~= nil and attr_type ~= "" then
				local anotations = execute_tag_key_procedures(attr_type_obj)
				attr_values = attr_values .. data_or_object_prop .. "Range(" .. anotations .. full_attr_name .. " " .. attr_type .. ")\n"
			end
			-- else
			-- 	local res = utilities.search_in_table(elements['Class'], base_type)
			-- 	if res then
			-- 		prefix = "Object"
			-- 	end
			-- 	if res then
			-- 		attr_values = attr_values .. process_each_expression(prefix .. "PropertyRange", full_attr_name, attr_type_obj)
			-- 	else
			-- 		if attr_type ~= "" and attr_type ~= nil then
			-- 			attr_values = attr_values .. process_each_expression(prefix .. "PropertyRange", full_attr_name, attr_type_obj)
			-- 		end
			-- 	end
			-- end
			local anotations = execute_tag_key_procedures(attr)

			--attr_values = attr_values .. "Declaration(" .. anotations .. prefix .. "Property(" .. full_attr_name .. "))\n"
			--if class_name ~= nil and class_name ~= "" then
			--	local axiom_type = prefix .. "PropertyDomain"
			--	local anotations = execute_tag_key_procedures(attr_name_obj)
			--	attr_values = attr_values .. axiom_type .. "(" .. anotations .. full_attr_name .. " " .. full_class_name .. ")\n"
			--end

			
			local data_or_object
			if data_or_object_prop == "ObjectProperty" then data_or_object = "Object"
			else data_or_object = "Data" end
			
			local super_properties = add_string_filtered(attr,"SuperProperties", full_attr_name, "(%w+)", uri, "Sub" .. data_or_object.. "PropertyOf")
			local disjoint_properties = add_string_filtered(attr, "DisjointProperties", full_attr_name, "(%w+)", uri, "Disjoint" .. data_or_object .. "Properties")
			local equivalent_properties = add_string_filtered(attr, "EquivalentProperties", full_attr_name, "(%w+)", uri, "Equivalent" .. data_or_object .. "Properties")

			attr_values = attr_values .. super_properties .. disjoint_properties .. equivalent_properties
			local multiplicity_obj = attr:find("/subCompartment:has(/compartType[id = 'Multiplicity'])")
			if multiplicity_obj:is_empty() then
				multiplicity_obj = attr:find("/subCompartment/subCompartment:has(/compartType[id = 'Multiplicity'])")
			end
			local multiplicity = multiplicity_obj:attr_e("value")
			if multiplicity ~= "" and multiplicity ~= nil then
				local data = "Data"
				if data_or_object_prop == "ObjectProperty" then
					data = "Object"
				end
				attr_values = attr_values .. get_multiplicity(multiplicity_obj, full_class_name, full_attr_name, data, attr_type)
			end
			local functional_obj = attr:find("/subCompartment:has(/compartType[id = 'IsFunctional'])")
			if functional_obj:is_empty() then
			    functional_obj = attr:find("/subCompartment/subCompartment:has(/compartType[id = 'IsFunctional'])")
			end
			local functional = functional_obj:attr_e("value")
			if functional == "true" then
				local anotations = execute_tag_key_procedures(functional_obj)
				attr_values = attr_values .. "Functional" .. data_or_object_prop .. "(" .. anotations .. full_attr_name .. ")\n"
			end
			attr_values = attr_values .. make_multiple_annotations(attr, "/subCompartment/subCompartment:has(/compartType[id = 'Annotation'])", data_or_object_prop, full_attr_name, ")")
		end
	end)
	axiom_value = class_declaration .. axiom_value .. "\n" .. attr_values
	class:attr("axioms", axiom_value)
	return axiom_value
end

function get_built_in_data_type(attr_type)
	local built_in_data_types = {
			Literal = "http://www.w3.org/2000/01/rdf-schema#",
			NCName = "http://www.w3.org/2001/XMLSchema#",
			NMTOKEN = "http://www.w3.org/2001/XMLSchema#",
			Name = "http://www.w3.org/2001/XMLSchema#",
			PlainLiteral = "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
			XMLLiteral = "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
			anyURI = "http://www.w3.org/2001/XMLSchema#",
			base64Binary = "http://www.w3.org/2001/XMLSchema#",
			boolean = "http://www.w3.org/2001/XMLSchema#",
			byte = "http://www.w3.org/2001/XMLSchema#",
			dateTime = "http://www.w3.org/2001/XMLSchema#",
			dateTimeStamp = "http://www.w3.org/2001/XMLSchema#",
			decimal = "http://www.w3.org/2001/XMLSchema#",
			double = "http://www.w3.org/2001/XMLSchema#",
			float = "http://www.w3.org/2001/XMLSchema#",
			hexBinary = "http://www.w3.org/2001/XMLSchema#",
			int = "http://www.w3.org/2001/XMLSchema#",
			integer = "http://www.w3.org/2001/XMLSchema#",
			language = "http://www.w3.org/2001/XMLSchema#",
			long = "http://www.w3.org/2001/XMLSchema#",
			negativeInteger = "http://www.w3.org/2001/XMLSchema#",
			nonNegativeInteger = "http://www.w3.org/2001/XMLSchema#",
			nonPositiveInteger = "http://www.w3.org/2001/XMLSchema#",
			normalizedString = "http://www.w3.org/2001/XMLSchema#",
			positiveInteger = "http://www.w3.org/2001/XMLSchema#",
			rational = "http://www.w3.org/2002/07/owl#",
			real = "http://www.w3.org/2002/07/owl#",
			short = "http://www.w3.org/2001/XMLSchema#",
			string = "http://www.w3.org/2001/XMLSchema#",
			token = "http://www.w3.org/2001/XMLSchema#",
			unsignedByte = "http://www.w3.org/2001/XMLSchema#",
			unsignedInt = "http://www.w3.org/2001/XMLSchema#",
			unsignedLong = "http://www.w3.org/2001/XMLSchema#",
			unsignedShort = "http://www.w3.org/2001/XMLSchema#"
	}
	if built_in_data_types[attr_type] ~= nil then
		return	"<" .. built_in_data_types[attr_type] .. attr_type .. ">"
	else
		return ""
	end
end

function get_classes(diagram)
	diagram:find("/element:has(/elemType[id = 'Class'])"):each(function(class)
		local class_name = get_class_name(class)
		table.insert(elements['Class'], class_name)
	end)
	--diagram:find("/element:has(/elemType[id = 'OntologyFragment'])"):each(function(fragment)
	--	local dgr = fragment:find("/target")
	--	get_classes(dgr)
	--end)
end

function insert_axiom_in_table(axiom_table, initial_domain, initial_range)
	local domain = clear_uri(initial_domain)
	local range = clear_uri(initial_range)
	table.insert(axiom_table, {domain, range})
end

function clear_uri(value)
	local len = string.len(value)
	if string.sub(value, 1, 1) == "<" and string.sub(value, len, len) == ">" then
		value = string.sub(value, 2, len-1)
	end
return value
end

function get_key_values(class, full_class_name)
	local result = ""
	class:find("/compartment/subCompartment:has(/compartType[id = 'Keys'])"):each(function(tmp_key)
		local obj_prop_table = {}
		local data_prop_table = {}
		local expressions = ""
		tmp_key:find("/subCompartment/subCompartment:has(/compartType[id = 'Key'])"):each(function(key)
			local prop = key:find("/subCompartment:has(/compartType[id = 'Property'])"):attr_e("value")
			local ns = key:find("/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
			local inverse = key:find("/subCompartment:has(/compartType[id = 'Inverse'])"):attr_e("value")
			local prop_name = make_full_object_name(ns, prop)
			local _, key_type = get_uri_from_data_or_object_property_table(data_property_uri_table, object_property_uri_table, prop)
			if prop_name ~= "" then
				if key_type == "data" then
					--if not(inverse ~= "false" and inverse ~= "") then
						table.insert(data_prop_table, prop_name)
					--end
					--expressions = expressions .. " () " .. prop_name .. ""
				elseif key_type == "object" then
					if inverse ~= "false" and inverse ~= "" then
						prop_name = "ObjectInverseOf(" .. prop_name .. ")"
					end
					table.insert(obj_prop_table, prop_name)
					--expressions = expressions ..  " " .. prop_name .. " ()"
				end
			end
		end)
		local anotations = execute_tag_key_procedures(tmp_key)
		if #obj_prop_table > 0 or #data_prop_table > 0 then
			result = result .. "HasKey" .. "(" .. anotations .. full_class_name .. " "
			if #data_prop_table == 0 then
				--result = result .. "(" .. table.concat(obj_prop_table, " ") .. ")" .. " ()"
				result = string.format("%s(%s ) ()", result, table.concat(obj_prop_table, " "))
			elseif #obj_prop_table == 0 then
				--result = result .. " () " .. "(" .. table.concat(data_prop_table, " ") .. ")"
				result = string.format("%s () (%s)", result, table.concat(data_prop_table, " "))
			else
				--result = result .. "(" .. table.concat(obj_prop_table, " ") .. ") " .. "(" .. table.concat(data_prop_table, " ") .. ")"
				result = string.format("%s (%s) (%s)", result, table.concat(obj_prop_table, " "), table.concat(data_prop_table, " "))
			end
			result = result .. ")\n"
		end
	end)
	return result
end

function get_prop_name(val)
	local result = ""
	if val ~= "" and val ~= nil then
		local res = specific.parse_key(val)
		if type(res) == "table" then
			local key = res["Property"]
			if res["Inverse"] == "inverse" then
				local uri, key_type = get_uri_from_data_or_object_property_table(data_property_uri_table, object_property_uri_table, key)
				return "ObjectInverseOf(<" .. uri .. key .. ">)" , "object"
			else
				local uri, key_type = get_uri_from_data_or_object_property_table(data_property_uri_table, object_property_uri_table, key)
				return "<" .. uri .. key .. ">", key_type
			end
		end
	end
	return ""
end

function get_property_full_name(value)
	local Space = lpeg.S(" \n\r\t") ^ 0
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.P("_") + lpeg.S("āēūīšģķļņčž") + lpeg.S("ĀĒŪĪŠĢĶĻŅČŽ")
	local String = lpeg.C(lpeg.P(Letter * (Letter + lpeg.R("09")) ^ 0)) * Space
	local ns = lpeg.Cg(lpeg.P"{" * Space * String * lpeg.P"}" * Space + lpeg.Cc(""), "Namespace")
	local prop_name = lpeg.Cg(String, "Property") * Space
	local res = lpeg.match((lpeg.Ct(prop_name * ns) ^ -1), value)
	if type(res) == "table" then
		local prop_name = res["Property"]
		local key_type = ""
		if data_property_uri_table[prop_name] ~= nil then
			key_type = "data"
		else
			key_type = "object"
		end
		return make_full_object_name(res["Namespace"], prop_name), key_type
	end
end

function get_class_uri(class)
	local name = get_class_name(class)
	local ns = class:find(path):attr_e("value")
	local full_name, uri = get_full_class_name_by_name_and_ns(name, ns)
	return uri, name, full_name
end

function get_uri_by_ns(elem, path)
	local index = elem:find(path):attr_e("value")
	if index == nil or index == "" then
		return ns_uri_table[""]
	else
		local tmp = ns_uri_table[index]
		if tmp ~= nil then
			return tmp
		else
			return ns_uri_table[""]
		end
	end
end

function set_enumerated(diagram, class, increment_progress)
	local uri, class_name, full_class_name = get_class_uri(class)
	local stereotype = class:find("/compartment:has(/compartType[id = 'Stereotype'])"):attr_e("value")
	local isComplete = class:find("/compartment:has(/compartType[id = 'isComplete'])"):attr_e("value")
	if stereotype == "<<EnumeratedClass>>" and isComplete == "{isComplete}" then
		local obj_names = {}
		diagram:find("/element:has(/elemType[id = 'Object'])"):each(function(obj)
			local obj_name, uri, full_obj_name = get_object_uri(obj)
			obj_className = obj:find("/compartment/subCompartment:has(/compartType[id = 'ClassName'])"):attr_e("value")
			if obj_className == class_name and obj_name ~= "" then
				table.insert(obj_names, full_obj_name)
			end
		end)
		class:find("/eEnd:has(/elemType[id = 'Dependency'])"):each(function(depend)
			increment_progress()
			if depend:find("/compartment"):attr_e("value") == "instanceOf" then
				depend:find("/start:has(/elemType[id = 'Object'])"):each(function(object)
					local name, _, full_name = get_object_uri(object)
					if name ~= "" then
						table.insert(obj_names, full_name)
					end
				end)
			end
		end)
		if table.getn(obj_names) > 0 then
			return "EquivalentClasses(" .. full_class_name .. " ObjectOneOf(" .. table.concat(obj_names, " ") .. "))\n"
		else
			return ""
		end
	else
		return ""
	end
end

--function add_object_property(diagram, global_table, class_name, full_attr_name, attr_type)
--	local value = ""
--	diagram:find("/element:has(/elemType[id='Class'])"):each(function(class, i)
--		class = lQuery(class)
--		local stereotype = class:find("/compartment:has(/compartType[id = 'Stereotype'])")
--		--local isComplete = class:find("/compartment:has(/compartType[id = 'isComplete'])")
--		if stereotype ~= nil then
--			stereotype_value = stereotype:attr("value")
--			if stereotype_value == "<<EnumeratedClass>>" then
--				local range_name = get_class_name(class)
--				if range_name == attr_type then
--					value = "Declaration(ObjectProperty(" .. full_attr_name .. "))"
--					insert_axiom_in_table(global_table['OWLObjectProperty']['OWLObjectPropertyDomainAxiom'], full_attr_name, class_name)
--					insert_axiom_in_table(global_table['OWLObjectProperty']['OWLObjectPropertyRangeAxiom'], full_attr_name, attr_type)
--				end
--			end
--		end
--	end)
--return value
--end

function get_attribute_type(diagram, attr_type, attr_ns, increment_progress)
	local val = attr_type
	local buls = false
	if val ~= "" then
		buls = true
		local res = specific.default_type_special()
		if string.sub(attr_type, 1, 1) ~= "(" then
			buls = check_default_type(attr_type)
			if buls == false then
				local seed = diagram:find("/parent")
				local seed_set = specific.get_ontologies_from_seed(seed, "/compartment")
				table.insert(seed_set, seed)
				val = ""
				val, buls = get_ontologies_data_type(seed_set, "Enumeration", "/compartment:has(/compartType[id = 'Name'])", attr_type)
				if val == "" then
					val, buls = get_ontologies_data_type(seed_set, "DataType", "/compartment/subCompartment:has(/compartType[id = 'Name'])", attr_type)
				end
				if val == "" then
					buls = nil
				end
			elseif val ~= "" then
				if attr_ns ~= nil and attr_ns ~= "" then
					local uri = get_uri_from_ns(attr_ns)
					val = make_full_name_from_URI_and_name(uri, attr_type)
				else
					val = get_built_in_data_type(attr_type)
				end
			end
		else
			val = process_data_type_expr_value(attr_type, diagram)
		end
	end
return attr_type, val, buls
end

function check_default_type(attr_type)
	local buls = false
	local lower_attr_type = string.lower(attr_type)
	local types = specific.default_type_special()
	for _, tmp_type in pairs(types) do
		if string.lower(tmp_type) == lower_attr_type then
			buls = true
			break
		end
	end
return buls
end


function get_ontologies_data_type(seed_set, elem_name, path_to_name, attr_type)
	local val = ""
	local buls = false
	for _, ontology in pairs(seed_set) do
		local diagram = ontology:find("/child")
		diagram:find("/element:has(/elemType[id = '" .. elem_name .. "'])"):each(function(data_type)
			local data_type_name = data_type:find(path_to_name):attr_e("value")
			local ns = data_type:find("/compartment/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
			if data_type_name == attr_type then
				buls = true
				--if ns ~= "" then
					local uri = get_uri_from_ns(ns)
					val = make_full_name_from_URI_and_name(uri, data_type_name) -- .. ":" .. data_type_name
				--else
				--	val = data_type_name
				--end
			end
		end)
	end
return val, buls
end

function add_complete_axioms(class, class_name)
	local res = ""
	local result = get_subclasses(class, "subClass_complete")
	local classes = table.concat(result, " or ")
	local anotations = execute_tag_key_procedures(class)
	if classes ~= "" then
		res = res .. "EquivalentClasses(" .. anotations .. class_name .. " " .. classes .. ")\n"
	end
return res
end

function add_disjoint_axioms(class)
	local res = ""
	local result = get_subclasses(class, "subClass_disjoint")
	local classes = table.concat(result, " ")
	local anotations = execute_tag_key_procedures(class)
	if classes ~= "" then
		res = res .. "DisjointClasses(" .. anotations .. classes .. ")\n"
	end
return res
end

function get_subclasses(class, id)
	local res = {}
	local value = class:find("/compartment:has(/compartType[id = '" .. id .. "'])"):attr("value")
	if value ~= nil then
		class:find("/eEnd:has(/elemType[id = 'Generalization'])/start"):each(function(class)
			insert_class_names_in_table(res, class)
		end)
		get_fork_subClasses(class, "/eEnd:has(/elemType[id = 'GeneralizationToFork'])/start:has(/elemType[id = 'HorizontalFork'])", res)
		get_fork_subClasses(class, "/eStart:has(/elemType[id = 'GeneralizationToFork'])/end:has(/elemType[id = 'HorizontalFork'])", res)
	end
return res
end

function get_fork_subClasses(elem, path_to_fork, res)
	elem:find(path_to_fork):each(function(fork)
		get_fork_subClass_names(fork, "/eEnd:has(/elemType[id = 'AssocToFork'])/start", res)
		get_fork_subClass_names(fork, "/eStart:has(/elemType[id = 'AssocToFork'])/end", res)
	end)
end

function get_fork_subClass_names(fork, path, res)
	fork:find(path):each(function(class)
		insert_class_names_in_table(res, class)
	end)
end

function insert_class_names_in_table(res, class)
	local _,_,class_name = get_class_uri(class)
	if class_name ~= nil and class_name ~= "" then
		table.insert(res, class)
	end
end

function get_multiplicity(multiplicity_obj, domain_class, attr_name, property_type, suffix)
	return get_multiplicity_functional(multiplicity_obj, domain_class, attr_name, property_type, "Functional", suffix)
end

function get_multiplicity_functional(multiplicity_obj, domain_class, attr_name, property_type, functional_type, suffix)
	prop_type = prop_type or ""
	local delimiter = " "
	if property_type == "" then
		delimiter = ""
	end
	local result = ""
	suffix = suffix or ""
	local suffix = " " .. suffix .. "))\n"
	local multiplicity = multiplicity_obj:attr_e("value")
	if multiplicity ~= nil then
		local grammer = re.compile[[grammer <- (('(i)'/'(c)')?{:min: [0-9_*]*:}('..'('(i)'/'(c)')?{:max: [0-9_*]*:})?)]]
		local res_table = re.match(multiplicity, lpeg.Ct(grammer) * -1)
		if res_table ~= nil then
			multiplicity = res_table["min"]
			local max_cardinality = res_table["max"]
			if max_cardinality ~= nil then
				multiplicity = multiplicity .. ".." .. max_cardinality
			end
		end
	end
	local res = multiplicity_split(multiplicity)
	local anotations = ""
	--local prefix = "SubClassOf(" .. anotations .. domain_class .. " "
	if type(res) == "table" then
		if res['Number'] ~= nil and functional_type ~= "InverseFunctional" then
			anotations = execute_tag_key_procedures(multiplicity_obj, "ExactCardinality")
			result = "SubClassOf(" .. anotations .. domain_class .. delimiter .. property_type .. "ExactCardinality(" .. multiplicity .. " " .. attr_name .. suffix
		elseif res['Asteric'] ~= nil then
			--result = prefix .. property_type .. "MaxCardinality(999999999 " .. prop_name .. suffix
		elseif res['MinMax'] ~= nil then
			local max_value = ""
			--if res['MinMax']['Min'] == "0" and res['MinMax']['Max'] == "1" and (functional_type == "Functional" or functional_type == "InverseFunctional") then
			--	anotations = execute_tag_key_procedures(multiplicity_obj, functional_type)
			--	result = result .. functional_type .. property_type .. "Property(" .. anotations .. attr_name .. ")\n"
			--else
			--	if functional_type ~= "InverseFunctional" then

				if res['MinMax']['Max'] ~= "*"  then
					anotations = execute_tag_key_procedures(multiplicity_obj, "MaxCardinality")
					result = result .. "SubClassOf(" .. anotations .. domain_class .. delimiter .. property_type ..  "MaxCardinality(" .. res['MinMax']['Max'] .. " " .. attr_name .. suffix
				end
				if tonumber(res['MinMax']['Min']) > 0 then
					anotations = execute_tag_key_procedures(multiplicity_obj, "MinCardinality")
					result = result .. "SubClassOf(" .. anotations .. domain_class .. delimiter .. property_type .. "MinCardinality(" .. res['MinMax']['Min'] .. " " .. attr_name .. suffix
				end
			--	end
			--end
		end
	end
	return result
end

function multiplicity_split(multiplicity)
	if multiplicity ~= nil then
		local Number = lpeg.Cg(lpeg.R("09")^1 * lpeg.R("09") ^ 0, "Number");
		local AstericSymbol = lpeg.S("*");
		local Asteric = lpeg.Cg(AstericSymbol, "Asteric");
		local MinMax = lpeg.Cg(lpeg.Ct(lpeg.Cg(Number, "Min") * ".." * lpeg.Cg(Asteric + Number, "Max")), "MinMax");
		local Expr = lpeg.Ct(MinMax + Number + Asteric) * -1;
		local res = lpeg.match(Expr, multiplicity)
		if type(res) == "table" then
			return res
		else
			return nil
		end
	else
		return nil
	end
end

function add_propery(attr_names, attr_name)
	if attr_names[attr_name] == nil then
		attr_names[attr_name] = {count = 1}
	else
		attr_names[attr_name] = {count = 2}
	end
end

function get_all_attr_names()
	local class_attr_names = {}
	lQuery("CurrentDgrPointer/graphDiagram/element:has(/elemType[id = 'Class'])/compartment/subCompartment/subCompartment:has(/compartType[id = 'Name'])"):each(function(attr, i)
		add_propery(class_attr_names, attr:attr("value"))
	end)
	return class_attr_names
end

function get_all_property_names()
	local class_attr_names = {}
	get_roles("Name", class_attr_names)
	get_roles("InvName", class_attr_names)
	return class_attr_names
end

function get_roles(id, class_attr_names)
	lQuery("CurrentDgrPointer/graphDiagram/element:has(/elemType[id = 'Association'])/compartment:has(/compartType[id = '" .. id .. "'])"):each(function(attr, i)
		local direct_value = string.gsub(attr:attr("value"), " ", "_")
		local len = string.len(direct_value)
		local direct_value = string.sub(direct_value, 1, len-1)
		add_propery(class_attr_names, direct_value)
	end)
end

function is_single_attr(class_attr_names, attr_name)
	local buls = "false"
	if class_attr_names[attr_name] ~= nil then
		if class_attr_names[attr_name]['count'] == 1 then
			buls = "true"
		end
	else
		buls = "nil"
	end
	return buls
end

function make_annotation(annotation_type, annotation_value, annotation_lang, class_name, finish, obj)
	local axiom_value = ""
	if annotation_value == "" or annotation_value == nil then
		annotation_value = "\"" .. class_name .. "\""
	end
	if annotation_lang ~= nil and annotation_lang ~= "" then
		annotation_value =  annotation_value .. "@" .. annotation_lang
	end
	if annotation_type ~= "" and annotation_type ~= nil then
		axiom_value = make_complete_annotation(annotation_type, annotation_value, class_name, finish, obj)
	end
return axiom_value
end

function make_ontology_annotation(source, path)
	local val = ""
	source:find(path):each(function(attrs)
		local annotation_type, annotation_value, annotation_lang, annot_ns = get_annotation_values(attrs)
		local tmp_val = ontology_annotations(attrs, annotation_type, annotation_value, annotation_lang, annot_ns)
		if tmp_val ~= nil then
			val = val .. tmp_val
		end
	end)
return val
end

function ontology_annotations(annotation, annotation_type, annotation_value, annotation_lang, annot_ns)
	
	local res = ""
	if annotation_value == "" then
		--annotation_value = "\"\""
		return ""
	end
	if annotation_value ~= nil then
		if annotation_lang ~= nil and annotation_lang ~= ""  then
			annotation_value = annotation_value .. "@" .. annotation_lang
		end
		local anot_type = annotation_table[annotation_type]
		local anotations = execute_tag_key_procedures(annotation)
		if anot_type ~= nil then
			return  "Annotation(" .. anotations .. anot_type .. " " .. annotation_value .. ")\n"
		elseif ns_uri_table[annotation_type] then
			local uri = ns_uri_table[annotation_type] .. ":"
			--local full_anot_type = make_full_name_from_URI_and_name(uri, annotation_type)
			local full_anot_type = uri..annotation_type
			return  "Annotation(" .. anotations .. full_anot_type .. " " .. annotation_value .. ")\n"
		elseif annotation_type ~= nil and annotation_type ~= "" then
			annotation_type = "<" .. get_current_uri() .. annotation_type .. ">"
			return "Annotation(" .. anotations .. annotation_type .. " " .. annotation_value .. ")\n"
		else
			return ""
		end
	else
		return ""
	end
end

function make_multiple_annotations(source, path, class_val, name, close)
	local property = ""
	source:find(path):each(function(attrs)
		local annotation_type, annotation_value, annotation_lang, annot_ns = get_annotation_values(attrs)
		property = property .. make_annotation(annotation_type, annotation_value, annotation_lang, name, close, attrs)
	end)
return property
end

function get_annotation_values(source)
	local annotation_type = source:find("/subCompartment:has(/compartType[id = 'AnnotationType'])"):attr_e("value")
	local annotation_value = source:find("/subCompartment/subCompartment:has(/compartType[id = 'Value'])"):attr_e("value")
	annotation_value = "\"" .. string.gsub(annotation_value, "\"", "\\\"") .. "\""
	local annotation_lang = source:find("/subCompartment/subCompartment:has(/compartType[id = 'Language'])"):attr_e("value")
	local annotation_ns = source:find("/subCompartment/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
return annotation_type, annotation_value, annotation_lang, annotation_ns
end


function insert_in_table(element, path, domain, classes_table)
	local table_name = {}
	element:find(path):each(function(elem)
		if domain ~= nil and domain ~= "" then
			insert_axiom_in_table(classes_table, domain, elem:attr_e("value"))
			--table.insert(classes_table, {domain, elem:attr_e("value")})
			--local res = parser.Manchester_parser(elem:attr("value"))
		end
	end)
return classes_table
end

function process_class_expresssion(axiom_type, element, path, domain)
	local result = ""
	element:find(path):each(function(elem)
		result = result .. process_each_expression(axiom_type, domain, elem, elem)
	end)
return result
end

function process_class_expresssion_eq_disjoint(axiom_type, element, path, sub_compart_name,  domain)
	local result = {}
	if domain ~= "" then
		element:find(path):each(function(tmp_elem)
			local expr_table = {}
			local annotation_table = {}
			tmp_elem:find("/subCompartment/subCompartment:has(/compartType[id = " .. sub_compart_name .. "])"):each(function(elem)
				local results, expr = process_each_expression(axiom_type, domain, elem)
				table.insert(expr_table, expr)
				table.insert(annotation_table, execute_tag_key_procedures(tmp_elem))
			end)
			local expressions = table.concat(expr_table, " ")
			local anotations = table.concat(annotation_table, " ")
			if expressions ~= "" then
				table.insert(result, string.format("%s(%s %s %s)", axiom_type, anotations, domain, expressions))
			end
		end)
	end
return table.concat(result, "\n")
end

function process_each_expression(axiom_type, domain, elem, anot_obj, arg1)
	local result = ""
	local expr = ""
	if domain ~= nil and domain ~= "" then
		--local res, err = parser.new_manchester_parser(elem)
		local val = elem:attr_e("value")
		if val ~= "" then
			local res = MP.parseClassExpression(val, elem:transitive_closure("/element,/parentCompartment"):find("/graphDiagram"))
			if res ~= nil and res ~= "" then
				if string.sub(res, 1,  20) ~= "DataMinCardinality(0" and string.sub(res, 1,  20) ~= "ObjectMinCardinality(0" then
					local anotations = execute_tag_key_procedures(anot_obj, arg1)
					expr = res
					if domain ~= expr then
						result = string.format("%s%s(%s%s %s)\n", result, axiom_type, anotations, domain, expr)
					end
				end
			else
				parser_error(val)
				print("Syntax error or unsupported syntax")
				print(val)
				error_table[val] = true
			end
		end
	end
	return result, expr
end

function translate_syntax_tree_to_functional_syntax(res_table)
	--print(dumptable(res_table))
	local result = ""
	if #res_table == 1 then
		--print("single expression")
		result = process_expression(res_table[1])
	else
		for i = #res_table, 2, -2 do
			local op = res_table[i - 1]
			local arg1 = res_table[i - 2]
			if #res_table > 1 then
				local expr_1, property_type_1 = process_expression(arg1)
				local property_type = property_type_1
				if property_type == nil then
					property_type = "Object"
				end
				if i == #res_table then
					local expr_2, property_type_2 = process_expression(res_table[i])
					result = translate_operation_to_functional(op, property_type) .. "(" .. expr_1 .. " " .. expr_2 .. ")"
				else
					result = translate_operation_to_functional(op, property_type) .. "(" .. expr_1 .. " " .. result .. ")"
				end
			end
		end
	end
	--print("end translate_syntax_tree_to_functional_syntax")
	return result
end

function process_expression(expr_table)
	local result = ""
	local property_type = ""
	if expr_table["SomeExpression"] ~= nil then
		result = process_some_expression(expr_table["SomeExpression"])
	elseif expr_table["ValueExpression"] ~= nil then
		result = process_value_expression(expr_table["ValueExpression"])
	elseif expr_table["CardinalityExpression"] ~= nil then
		result = make_cardinality_expression(expr_table["CardinalityExpression"])
	elseif expr_table["ClassExpression"] ~= nil then
		result = get_built_in_data_type(expr_table['ClassExpression']['Class'])
		property_type = "Data"
		if result == "" then
			property_type = "Object"
			result = get_full_class_name(expr_table["ClassExpression"])
		end
	elseif expr_table['SelfExpression'] ~= nil then
		result = "ObjectHasSelf(" .. process_property_name(expr_table["SelfExpression"]) .. ")"
	elseif expr_table["IndividualList"] ~= nil then
		result = process_individuals(expr_table["IndividualList"])
	elseif expr_table["Paranthesis"] ~= nil then
		result = translate_syntax_tree_to_functional_syntax(expr_table["Paranthesis"])
	elseif expr_table['Negation'] ~= nil then
		result = "ObjectComplementOf(" ..  translate_syntax_tree_to_functional_syntax(expr_table["Negation"]) .. ")"
	elseif expr_table['That'] ~= nil then
		result = "ObjectIntersectionOf(" .. get_full_class_name(expr_table["That"]["ClassExpression"]) .. " " .. translate_syntax_tree_to_functional_syntax(expr_table["That"]["Restriction"]) .. ")"
	else
		print("Error in expression analyze")
	end
	return result, property_type
end
function process_some_expression(sub_expr_table)
	return get_axiom_name(sub_expr_table) .. "(" .. process_property_name(sub_expr_table) .. " " .. analyze_primary_type(sub_expr_table) .. ")"
end

function get_axiom_name(sub_expr_table)
	local axiom_type = get_axiom_type(sub_expr_table)
	local cardinality = sub_expr_table["Cardinality"]
return get_axiom_name_by_cardinality(axiom_type, cardinality)
end

function get_axiom_name_by_cardinality(axiom_type, cardinality)
	if cardinality == "some" then
		return axiom_type .. "SomeValuesFrom"
	elseif cardinality == "only" then
		return axiom_type .. "AllValuesFrom"
	else
		print("Error in get axiom name")
	end
end

function get_axiom_type(sub_expr_table)
	if sub_expr_table["Primary"] ~= nil then
		return "Object"
	elseif sub_expr_table["DataPrimary"] ~= nil then
		return "Data"
	elseif sub_expr_table["Negation"] ~= nil then
		return get_axiom_type(sub_expr_table["Negation"])
	end
end

function analyze_primary_type(sub_expr_table)
	if sub_expr_table["Primary"] ~= nil then
		return process_primary_expression(sub_expr_table["Primary"])
	elseif sub_expr_table["DataPrimary"] ~= nil then
		return process_data_primary_expression(sub_expr_table["DataPrimary"])
	elseif sub_expr_table["Negation"]["DataPrimary"]  ~= nil then
		return "DataComplementOf(" .. process_data_primary_expression(sub_expr_table["Negation"]["DataPrimary"]) .. ")"
	elseif sub_expr_table["Negation"]["Primary"] ~= nil then
		return "ObjectComplementOf(" .. process_primary_expression(sub_expr_table["Negation"]["Primary"]) .. ")"
	end
end

function process_primary_expression(primary)
	if primary['ClassExpression'] ~= nil then
		return get_full_class_name(primary['ClassExpression'])
	elseif primary["PrimaryExpression"]['Paranthesis'] ~= nil then
		return translate_syntax_tree_to_functional_syntax(primary["PrimaryExpression"]['Paranthesis'])
	elseif primary['PrimaryExpression'] ~= nil then
		return process_expression(primary['PrimaryExpression'])
	else
		print("Error in process_primary")
	end
end

function process_data_primary_expression(data_primary_table)
	if data_primary_table["DataType"] ~= nil then
		return get_full_data_type_name(data_primary_table["DataType"])
	elseif data_primary_table["LiteralList"] ~= nil then
		local res = ""
		for i, type_restriction in ipairs(data_primary_table["LiteralList"]) do
			res = res .. " ".. process_literal(type_restriction)
		end
		return "DataOneOf(" .. res .. ")"
	elseif data_primary_table["DataTypeRestriction"] ~= nil then
		local res = ""
		for i, type_restriction in ipairs(data_primary_table["DataTypeRestriction"]) do
			res = res .. " ".. get_cardinality_from_facet(type_restriction["Facet"]) .. " " .. process_literal(type_restriction["RestrictionValue"])
		end
		return "DatatypeRestriction(" .. get_full_data_type_name(data_primary_table["DataTypeRestriction"]["DataType"]) ..  res .. ")"
	elseif data_primary_table["DataRange"] ~= nil then
		local result = ""
		if #data_primary_table["DataRange"] == 1 then
			result = process_data_primary_expression(data_primary_table["DataRange"][1]["DataPrimary"])
		else
			for i = #data_primary_table["DataRange"], 2, -2 do
				local op = data_primary_table["DataRange"][i - 1]
				local arg1 = data_primary_table["DataRange"][i - 2]
				if #data_primary_table["DataRange"] > 1 then
					if i == #data_primary_table["DataRange"] then
						result = translate_operation_to_functional(op, "Data") .. "(" .. process_data_primary_expression(arg1["DataPrimary"]) .. " " .. process_data_primary_expression(data_primary_table["DataRange"][i]["DataPrimary"]) .. ")"
					else
						result = translate_operation_to_functional(op, "Data") .. "(" .. process_data_primary_expression(arg1["DataPrimary"]) .. " " .. result .. ")"
					end
				end
			end
		end
		return result
	elseif data_primary_table["Negation"] ~= nil then
		return "DataComplementOf(" .. process_data_primary_expression(data_primary_table["Negation"]) .. ")"
	else
		print("Error in data process primary expression")
	end
end

function process_individuals(sub_expr_table)
	local tmp_list = {}
	for i, item_table in pairs(sub_expr_table) do
		tmp_list[i] = make_full_object_name(item_table["Namespace"], item_table["Individ"])
	end
	return string.format("ObjectOneOf(%s)", table.concat(tmp_list, " "))
end

function process_value_expression(sub_expr_table)
	if sub_expr_table["Individual"] ~= nil then
		local individual = sub_expr_table["Individual"]
		return "ObjectHasValue(" .. process_property_name(sub_expr_table) .. " " .. make_full_object_name(individual["Namespace"], individual["Individ"]) .. ")"
	elseif sub_expr_table["Literal"] ~= nil then
		return "DataHasValue(" .. process_property_name(sub_expr_table) .. " " .. process_literal(sub_expr_table["Literal"]) .. ")"
	end
end

function make_cardinality_expression(expr_table)
--vajag pielikt, lai megina izdomat no konteksta atkariba, kas ir prop_name, ja izteiksmes forma ir prop_name cardinality number
	local axiom_type = "Object"
	if expr_table["Primary"] ~= nil then
		axiom_type = "Object"
	elseif expr_table["DataPrimary"] ~= nil then
		axiom_type = "Data"
	else
		--print("Error in make cardinality expression")
	end
	local cardinality = expr_table["Cardinality"]
	if cardinality == "min" then
		axiom_type = axiom_type .. "MinCardinality"
	elseif cardinality == "max" then
		axiom_type = axiom_type .. "MaxCardinality"
	elseif cardinality == "exactly" then
		axiom_type = axiom_type .. "ExactCardinality"
	end
	return make_cardinality_expression_specified(axiom_type, expr_table)
end

function make_cardinality_expression_specified(axiom_type, expr_table)
	local number = expr_table["Number"]
	if expr_table["Primary"] ~= nil then
		return axiom_type .. "(" .. number .. " " .. process_property_name(expr_table) .. " " .. process_primary_expression(expr_table["Primary"]) .. ")"
	elseif expr_table["DataPrimary"] ~= nil then
		return axiom_type .. "(" .. number .. " " .. process_property_name(expr_table) .. " " .. process_data_primary_expression(expr_table["DataPrimary"]) .. ")"
	else
		return axiom_type .. "(" .. number .. " ".. process_property_name(expr_table) .. ")"
	end
end

function process_literal(literal_table)
	local result = ""
	if literal_table["TypedLiteral"] ~= nil then
		local literal = literal_table["TypedLiteral"]
		result = literal["QuotedString"] .. " ^^ " .. "xsd:" .. literal["DataType"]["Value"]
	elseif literal_table["NoLanguage"] ~= nil then
		result = literal_table["NoLanguage"]["QuotedString"] .. " ^^ " .. "xsd:string"
	elseif literal_table["WithLanguage"] ~= nil then
		result = literal_table["WithLanguage"]["QuotedString"] .. " ^^ " .. "rdf:PlainLiteral"
	elseif literal_table["Floating"] ~= nil then
		result = '"' .. literal_table["Floating"]["Value"] .. '"' .. " ^^ " .. "xsd:float"
	elseif literal_table["Decimal"] ~= nil then
		result = '"' .. literal_table["Decimal"]["Value"] .. '"' .. " ^^ " .. "xsd:double"
	elseif literal_table["Integer"] ~= nil then
		result = '"' .. literal_table["Integer"]["Value"] .. '"' .. " ^^ " .. "xsd:integer"
	end
return result
end

function translate_operation_to_functional(operation, object_type)
	operation = string.lower(operation)
	if operation == "and" then
		return object_type .. "IntersectionOf"
	elseif operation == "or" then
		return object_type .. "UnionOf"
	end
end

function make_full_object_name(ns, value, list)
	local uri = get_uri_from_ns(ns, list)
	if value ~= "" then
		return make_full_name_from_URI_and_name(uri, value)
	else
		return ""
	end
end

function make_full_name_from_URI_and_name(uri, name)
	return 	string.format("<%s%s>", uri, name)
end

function make_full_object_name_for_table(ns, value)
	local uri = get_uri_from_ns(ns)
	return make_full_name_from_URI_and_name(uri, value)
end

function get_full_class_name(expr_table)
	return get_full_class_name_by_name_and_ns(expr_table["Class"], expr_table["Namespace"])
end

function get_full_class_name_by_name_and_ns(name, ns)
	if name == "" then
		return "", ""
	end
	if ns == nil then
		ns = ""
	end
	local uri = ""
	if ns == "" and class_table[name] ~= nil then
		uri = class_table[name]
	else
		uri = get_uri_from_ns(ns)
	end
	return make_full_name_from_URI_and_name(uri, name), uri
end

function get_full_class_name_from_class(class)
	local class_name = class:find("/compartment/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
	local ns = class:find("/compartment/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
	return get_full_class_name_by_name_and_ns(class_name, ns)
end

function get_uri_from_ns(ns, list)
	if list ~= nil then
		ns_uri_table = list
	end
	local uri = ns_uri_table[ns]
	if uri == nil then
		uri = ns_uri_table[""]
	end
	return uri
end

function get_full_object_name(name)
	return string.format("<%s%s>", object_uri_table[name], name)
end

--datu tipiem var but ari cits namespace, vajag salabot
function get_full_data_type_name(data_type_table)
	local data_type = data_type_table["Value"]
	local ns = data_type_table["Namespace"]
	if ns ~= "" then
		return "<" .. get_uri_from_ns(ns) .. data_type .. ">"
	else
		return "xsd:" .. data_type
	end
end

function get_cardinality_from_facet(facet)
	if facet == ">" then
		return "xsd:minExclusive"
	elseif facet == ">=" then
		return "xsd:minInclusive"
	elseif facet == "<" then
		return "xsd:maxExclusive"
	elseif facet == "<=" then
		return "xsd:maxInclusive"
	elseif facet == "langPattern" then
		return "rdf:" .. facet
	elseif facet ~= nil then
		return "xsd:" .. facet
	end
end

function process_property_name(expr_table)
	local uri = ns_uri_table[expr_table["Namespace"]]
	--print("uri " .. uri)
	local res = ""
	if uri == nil then
		uri = ns_uri_table[""]
	end
	if expr_table["PropertyValue"] ~= nil then
		res = "<" .. uri .. expr_table["PropertyValue"] .. ">"
	elseif expr_table["InverseProperty"] ~= nil then
		res = "ObjectInverseOf(<" .. uri .. expr_table["InverseProperty"] .. ">)"
	else
		print("Error in process property name")
	end
return res
end

function merge_parser_table_elements(class_table, res, res_index, axioms)
	local buls = 0
	for i, elem in pairs(res) do
		if elem[res_index] then
			for j, val in pairs(class_table) do
				if val == elem[res_index] then
					buls = 1
					break
				end
			end
			if buls == 0 then
				add_axiom(res_index, axioms)
			end
			buls = 0
		end
	end
end

function add_axiom(index, str)
	str = str .. elem[index]
end

function insert_in_table_Thing(range, domain, classes_table)
	table.insert(classes_table, {domain, range})
end

function add_string_filtered(element, prop_type, domain, expression, uri, functional_name)
	local str = ""
	local res_table = {}
	utilities.insert_compart(element, "/subCompartment", res_table)
	element:find("/subCompartment:has(/compartType[id = '" .. prop_type .. "'])/subCompartment/subCompartment/subCompartment:has(/compartType[id = 'Expression'])"):each(function(sub_compart)
		local anotations = execute_tag_key_procedures(sub_compart)

		str = str .. functional_name .. "(" .. anotations .. domain .. " " .. " <" .. uri .. sub_compart:attr("value") .. ">)\n"
	end)
	return str
end

function link_to_objectPropertyAssertion(global_table, diagram, increment_progress)
	local axiom_value = ""
	diagram:find("/element:has(/elemType[id='Link'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='Link'])"):each(function(link)
		export_Link(link, increment_progress)
	end)
end

function export_Link(link, increment_progress)
	local axiom_value = ""
	if increment_progress ~= nil then
		increment_progress()
	end
	local assertion_obj = link:find("/compartment/subCompartment:has(/compartType[id = 'IsNegativeAssertion'])")
	local tmp = assertion_obj:attr_e("value")
	local assertion = "ObjectPropertyAssertion"
	if tmp == "true" then
		assertion = "NegativeObjectPropertyAssertion"
	end
	local start_value = get_role_by_direction(link, "Direct", "Property", "/start", "/end", assertion, assertion_obj)
	assertion_obj = link:find("/compartment/subCompartment:has(/compartType[id = 'InvIsNegativeAssertion'])")
	tmp = assertion_obj:attr_e("value")
	assertion = "ObjectPropertyAssertion"
	if tmp == "true" then
		inv_assertion = "NegativeObjectPropertyAssertion"
	end
	local end_value = get_role_by_direction(link, "Inverse", "InvProperty", "/end", "/start", assertion, assertion_obj)
	axiom_value = start_value .. "\n" .. end_value
	link:attr("axioms", axiom_value)
	return axiom_value
end

function get_role_by_direction(link, parent_compart_id, role_name, start_role, end_role, assertion, assertion_obj)
	local axiom_value = ""
	local parent_compart = link:find("/compartment:has(/compartType[id = '" .. parent_compart_id .. "'])")
	local prop_name = parent_compart:find("/subCompartment:has(/compartType[id = '" .. role_name .. "'])"):attr("value")
	--local prop_name = property_compart:find("/subCompartment:has(/compartType[id = 'Property'])"):attr_e("value")
	local prop_ns = parent_compart:find("/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
	if prop_name ~= nil and prop_name ~= "" then
		local grammer = re.compile[[grammer <- ({[a-zA-Z0-9_]*}('{'{[a-zA-Z0-9_]*}'}')?)]]
	    local res_table = re.match(prop_name, lpeg.Ct(grammer) * -1)
	    if res_table ~= nil then
		    prop_name = res_table[1]
		    if res_table[2] ~= nil then
			    prop_ns = res_table[2]
		    end
	    end
		local full_prop_name = make_full_object_name(prop_ns, prop_name)
		local path_to_name = "/compartment/subCompartment/subCompartment:has(/compartType[id = 'Name'])"
		local path_to_ns = "/compartment/subCompartment/subCompartment:has(/compartType[id = 'Namespace'])"
		local start_obj_name = make_full_object_name(link:find(start_role):find(path_to_ns):attr_e("value"), link:find(start_role):find(path_to_name):attr_e("value"))
		local end_obj_name = make_full_object_name(link:find(end_role):find(path_to_ns):attr_e("value"), link:find(end_role):find(path_to_name):attr_e("value"))
		if start_obj_name ~= nil and end_obj_name ~= nil and start_obj_name ~= "" and end_obj_name ~= "" then
			local anotations = execute_tag_key_procedures(assertion_obj)
			axiom_value = string.format("%s(%s%s %s %s)\n", assertion, anotations, full_prop_name, start_obj_name, end_obj_name)
		end
	end
	return axiom_value
end

function make_full_role_name(role)
	local start_index = string.find(role, "{")
	local end_index = string.find(role, "}")
	if start_index ~= nil and end_index ~= nil then
		local ns = string.sub(role, start_index + 1, end_index - 1)
		local role_name = string.sub(role, 1, start_index - 2)
		local uri = ns_uri_table[ns]
		if uri == nil then
			uri = get_current_uri()
		end
		return "<" .. uri .. role_name .. ">", role_name
	else
		return "<" .. get_current_uri() .. role .. ">", role
	end
end

function generalization_to_subtype(global_table, diagram, increment_progress)
	diagram:find("/element:has(/elemType[id='Generalization'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='Generalization'])"):each(function(generalization)
		export_Generalization(generalization, increment_progress, global_table, diagram)
	end)
end

function export_Generalization(generalization, increment_progress, global_table, diagram)
	local axiom_value = ""
	if increment_progress ~= nil then
		increment_progress()
	end
	local _, start_name, full_start_name = get_class_uri(generalization:find("/start"))
	local _, end_name, full_end_name = get_class_uri(generalization:find("/end"))

	if start_name ~= "Thing" or end_name ~= "Thing" then
		if start_name ~= nil and start_name ~= "" and end_name ~= "" and end_name ~= nil then
			local anotations = execute_tag_key_procedures(generalization)
			axiom_value = axiom_value .. "SubClassOf(" .. anotations .. full_start_name .. " " .. full_end_name .. ")\n"
			generalization:attr("axioms", axiom_value)
		else
			generalization:attr("axioms", "")
			class_to_class_table(global_table, diagram, "Generalization", "/compartment/subCompartment:has(/compartType[id = 'Name'])", "/compartment/subCompartment:has(/compartType[id = 'Namespace'])", "", "/subCompartment", "OWLClass", "SubClassOf", 3, increment_progress)
		end
	end
	return axiom_value
end

function generalizationFork_to_subtypeFork(global_table, diagram, increment_progress)
	diagram:find("/element:has(/elemType[id='HorizontalFork'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='HorizontalFork'])"):each(function(fork)
		export_HorizontalFork(fork, increment_progress)
	end)
end

function export_HorizontalFork(fork, increment_progress)
	local axiom_value = ""
	local super_type_table = {}
	--increment_progress()
	local complete_obj = fork:find("/compartment:has(/compartType[id = 'Complete'])")
	if complete_obj:is_empty() then
		complete_obj = fork:find("/compartment/subCompartment:has(/compartType[id = 'Complete'])")
	end
	local complete = complete_obj:attr_e("value")
	local assoc_to_fork = ":has(/elemType[id = 'AssocToFork'])"
	local eq_class_type = "/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])"

	axiom_value = axiom_value .. generalization_fork(fork, "/eStart", "/end", assoc_to_fork, "/end" .. eq_class_type, super_type_table, increment_progress)
	axiom_value = axiom_value .. generalization_fork(fork, "/eEnd", "/start", assoc_to_fork, "/start" .. eq_class_type, super_type_table, increment_progress)
	if complete == "true" then
		local super_classes1 = get_list_of_classes_from_fork(fork, "/eStart:has(/elemType[id = 'GeneralizationToFork'])/end", increment_progress)
		local super_classes2 = get_list_of_classes_from_fork(fork, "/eEnd:has(/elemType[id = 'GeneralizationToFork'])/start", increment_progress)
		local sub_classes1 = get_list_of_classes_from_fork(fork, "/eStart:has(/elemType[id = 'AssocToFork'])/end", increment_progress)
		local sub_classes2 = get_list_of_classes_from_fork(fork, "/eEnd:has(/elemType[id = 'AssocToFork'])/start", increment_progress)
		axiom_value = axiom_value .. make_classes_complete(merge_tables(super_classes1, super_classes2), merge_tables(sub_classes1, sub_classes2), complete_obj)
	end

	for _, set in pairs(super_type_table) do
		axiom_value = axiom_value .. process_each_expression("SubClassOf", set[1], set[2], set[2])
	end
	local disjoint_classes_obj = fork:find("/compartment:has(/compartType[id = 'Disjoint'])")
	if disjoint_classes_obj:is_empty() then
		disjoint_classes_obj = fork:find("/compartment/subCompartment:has(/compartType[id = 'Disjoint'])")
	end
	local disjoint_classes = disjoint_classes_obj:attr_e("value")
	--true
	if disjoint_classes == "true" then
		local list1 = get_list_of_classes_from_fork(fork, "/eStart:has(/elemType[id = 'AssocToFork'])/end", increment_progress)
		local list2 = get_list_of_classes_from_fork(fork, "/eEnd:has(/elemType[id = 'AssocToFork'])/start", increment_progress)
		local list = merge_tables(list1, list2)
		local concat_disjoint_classes = concat_disjoint_classes(list)
		if concat_disjoint_classes ~= "" then
			local anotations = execute_tag_key_procedures(disjoint_classes_obj)
			axiom_value = axiom_value .. "DisjointClasses(" .. anotations .. concat_disjoint_classes .. ")\n"
		end
	end
	fork:attr("axioms", axiom_value)
	return axiom_value
end

function make_classes_complete(super_classes, sub_classes, complete_obj)
	local res = ""
	local anotations = execute_tag_key_procedures(complete_obj)
	local sub_classes_string = concat_disjoint_classes(sub_classes)
	if #sub_classes > 1 then
		for i, super_class in pairs(super_classes) do
			res = res .. "EquivalentClasses(" .. anotations .. super_class .. " ObjectUnionOf(" .. sub_classes_string .. "))\n"
		end
	else
		res = res .. "EquivalentClasses(" .. anotations .. super_class .. " " .. sub_classes_string .. ")\n"
	end
	return res
end

function concat_disjoint_classes(list)
	if #list > 0 then
		return table.concat(list, " ")
	else
		return ""
	end
end

function merge_tables(list1, list2)
	for i, item in pairs(list2) do
		table.insert(list1, item)
	end
	return list1
end

function get_list_of_classes_from_fork(fork, path, increment_progress)
	local list = {}
	fork:find(path):each(function(class, i)
		class = lQuery(class)
		if increment_progress ~= nil then
			increment_progress()
		end
		local _,_, class_name = get_class_uri(class)
		table.insert(list, class_name)
	end)
	return list
end

function generalization_fork(fork, path_to_line, path_to_super_type, assoc_to_fork, path_to_eq_values, super_type_table, increment_progress)
	local axiom_value = ""
	fork:find(path_to_line .. ":has(/elemType[id = 'GeneralizationToFork'])"):each(function(generalization)
		axiom_value = axiom_value .. export_GeneralizationToFork(generalization, fork, path_to_super_type, assoc_to_fork, path_to_eq_values, super_type_table, increment_progress)
	end)
return axiom_value
end

function export_GeneralizationToFork(generalization, fork, path_to_super_type, assoc_to_fork, path_to_eq_values, super_type_table, increment_progress)
	local axiom_value = ""
	local _, name, super_type = get_class_uri(generalization:find(path_to_super_type .. ":has(/elemType[id = 'Class'])"))
	if name ~= "" and name ~= nil and name ~= "Thing" then
		axiom_value = axiom_value .. get_fork_subclasses(fork, "/eEnd" .. assoc_to_fork .. "/start", "SubClassOf(", name, super_type, increment_progress, super_type_table, generalization)
		axiom_value = axiom_value .. get_fork_subclasses(fork, "/eStart" .. assoc_to_fork .. "/end", "SubClassOf(", name, super_type, increment_progress, super_type_table, generalization)
	else
		get_fork_eq_subclasses(generalization, fork, super_type_table, "/end", "/eStart", "/end")
		get_fork_eq_subclasses(generalization, fork, super_type_table, "/end", "/eEnd", "/start")
		get_fork_eq_subclasses(generalization, fork, super_type_table, "/start", "/eStart", "/end")
		get_fork_eq_subclasses(generalization, fork, super_type_table, "/start", "/eEnd", "/start")
	end
	return axiom_value
end

function get_fork_subclasses(fork, path_to_class, functional_name, name, super_type, increment_progress, super_type_table, generalization)
	local general_fork = ""
	local anotations  = execute_tag_key_procedures(generalization)
	fork:find(path_to_class):each(function(class)
		if increment_progress ~= nil then
			increment_progress()
		end
		local _, name, full_class_name = get_class_uri(class)
		if name ~= nil and name ~= "" then
			general_fork = general_fork .. functional_name .. anotations .. full_class_name .. " " .. super_type .. ")\n"
		else
			class:find("/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])"):each(function(eq_class)
				local eq_class_name = eq_class:attr("value")
				if eq_class_name ~= "" then
					table.insert(super_type_table, {full_class_name, eq_class})
				end
			end)
		end
	end)
return general_fork
end

function get_fork_eq_subclasses(generalization, fork, super_type_table, path_to_super_class, role_to_assoc_fork, role_to_sub_class)
	local res = ""
	fork:find(role_to_assoc_fork .. ":has(/elemType[id = 'AssocToFork'])" .. role_to_sub_class):each(function(sub_class)
		generalization:find(path_to_super_class):each(function(super_class)
			local _, _, full_sub_class_name = get_class_uri(sub_class)
			if sub_class_name ~= "" then
				super_class:find("/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])"):each(function(eq_class)
					if eq_class_name ~= "" then
						table.insert(super_type_table, {full_sub_class_name, eq_class})
					end
				end)
			end
		end)
	end)
	return res
end

function equivalent_to_equivalent(global_table, diagram, increment_progress)
class_to_class(diagram, "EquivalentClass", "EquivalentClasses", " ", ")\n", increment_progress)
class_to_class_table(global_table, diagram, "EquivalentClass", "/compartment/subCompartment:has(/compartType[id = 'Name'])", "/compartment/subCompartment:has(/compartType[id = 'Namespace'])",  "/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])", "/subCompartment", "OWLClass", "EquivalentClasses", 2, increment_progress)
end

function disjoint_to_disjoint(global_table, diagram, increment_progress)
class_to_class(diagram, "Disjoint", "DisjointClasses", " ", ")\n", increment_progress)
class_to_class_table(global_table, diagram, "Disjoint", "/compartment/subCompartment:has(/compartType[id = 'Name'])", "/compartment/subCompartment:has(/compartType[id = 'Namespace'])",   "/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])", "/subCompartment", "OWLClass", "DisjointClasses", 2, increment_progress)
end

function complement_to_complement(global_table, diagram, increment_progress)
class_to_class(diagram, "ComplementOf", "EquivalentClasses", " ObjectComplementOf(", "))\n", increment_progress)
class_to_class_table_composite(global_table, diagram, "ComplementOf", "/compartment/subCompartment:has(/compartType[id = 'Name'])", "/compartment/subCompartment:has(/compartType[id = 'Namespace'])",  "/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])", "/subCompartment", "OWLClass", "EquivalentClasses", 2, "not", increment_progress)
end

function different_to_different(global_table, diagram, increment_progress)
object_to_object(diagram, "DifferentIndivid", "DifferentIndividuals", " ", ")\n", increment_progress)
object_to_object_anonymous(diagram, "DifferentIndivid", "DifferentIndividuals", "/compartment/subCompartment/subCompartment:has(/compartType[id = 'Namesapce'])", "/compartment/subCompartment/subCompartment:has(/compartType[id = 'Name'])", "/compartment:has(/compartType[id = 'SameIndividuals'])", "", increment_progress)
end

function same_to_same(global_table, diagram, increment_progress)
object_to_object(diagram, "SameAsIndivid", "SameIndividual", " ", ")\n", increment_progress)
object_to_object_anonymous(diagram, "SameAsIndivid", "SameIndividual", "/compartment/subCompartment/subCompartment:has(/compartType[id = 'Namesapce'])", "/compartment/subCompartment/subCompartment:has(/compartType[id = 'Name'])", "/compartment:has(/compartType[id = 'SameIndividuals'])", "", increment_progress)
end

function object_to_individual(global_table, diagram, increment_progress)
	local individual_axioms = {}
	local axiom_value = ""
	diagram:find("/element:has(/elemType[id='Object'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='Object'])"):each(function(object)
		export_Object(object, increment_progress)
	end)
end

function export_Object(object, increment_progress)
	local axiom_value = ""
	if increment_progress ~= nil then
		increment_progress()
	end
	local path_prefix = "/compartment/subCompartment/subCompartment"
	local object_name, uri, full_obj_name = get_obj_name_uri(object, path_prefix .. ":has(/compartType[id = 'Name'])", path_prefix .. ":has(/compartType[id = 'Namespace'])")
	local title_compart = object:find("/compartment:has(/compartType[id = 'Title'])")
	local object_className_obj = title_compart:find("/subCompartment:has(/compartType[id = 'ClassName'])")
	--local ns_compart_val = title_compart:find("/subCompartment:has(/compartType[id = 'ClassName'])/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
	if object_className_obj:is_empty() then
		object_className_obj = object:find("/compartment:has(/compartType[id = 'Title'])/subCompartment/subCompartment:has(/compartType[id = 'ClassName'])")
	end
	local comment = object:find("/compartment:has(/compartType[id = 'Comment'])")
	local comment_text = comment:attr("value")
	if comment_text ~= "" and comment_text ~= nil then
		comment_text = "\"" .. string.gsub(comment_text, "\"", "\\\"") .. "\""
		axiom_value = string.format("%s%s", axiom_value, make_annotation("comment", comment_text, "", full_obj_name, ")", comment))
	end

	local annotations = make_multiple_annotations(object, "/compartment/subCompartment:has(/compartType[id = 'Annotation'])", "Individual", full_obj_name, ")")
	local different_values = ""
	local class_name_axioms = {}
	local class_name_table = {}
	local tmp_object_className = object_className_obj:attr_e("value")
	local full_class_name = ""
	if object_className_obj:is_not_empty() then
		--full_class_name = get_full_class_name_by_name_and_ns(tmp_object_className, "")
		full_class_name = MP.parseClassExpression(tmp_object_className, object:transitive_closure("/element,/parentCompartment"):find("/graphDiagram")) or ""
		--_, _, full_class_name =  get_class_uri(object_className_obj)
		--full_class_name, _ = make_full_role_name(tmp_object_className)
	end


	--local full_class_name = get_full_class_name_by_name_and_ns(tmp_object_className, ns_compart_val)
	object:find("/eStart/end:has(/elemType[id = 'Class'])"):each(function(elem)
		if increment_progress ~= nil then increment_progress() end
		--local _, tmp_class_name, tmp = get_class_uri(elem)
		local tmp_class_name = get_full_class_name_from_class(elem)
		--print("tmp elem")
		--print(tmp_class_name)
		if tmp_class_name ~= "" then
			table.insert(class_name_table, tmp_class_name)
		else
			elem:find("/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])"):each(function(tmp_elem)
				insert_axiom_in_table(class_name_axioms, full_obj_name, lQuery(tmp_elem):attr_e("value"))
			end)
		end
	end)
	local property_assertion = get_property_assertions(object, full_obj_name, "/compartment/subCompartment:has(/compartType[id = 'DataPropertyAssertion'])",
	"/subCompartment:has(/compartType[id = 'Property'])", "/subCompartment:has(/compartType[id = 'Value'])", "/subCompartment:has(/compartType[id = 'Type'])", uri, "DataPropertyAssertion")

	local negative_property_assertion = get_property_assertions(object, full_obj_name, "/compartment/subCompartment:has(/compartType[id = 'NegativeDataPropertyAssertion'])",
	"/subCompartment:has(/compartType[id = 'Property'])", "/subCompartment:has(/compartType[id = 'Value'])", "/subCompartment:has(/compartType[id = 'Type'])", uri, "NegativeDataPropertyAssertion")

	if object_name ~= "" then
		axiom_value = axiom_value .. "Declaration(NamedIndividual(" .. full_obj_name  .. "))\n"
	end

	if object_name ~= "" and full_class_name ~= "" then
		--local full_class_name = make_full_object_name("", object_className)
		axiom_value = axiom_value .. make_class_assertion_axiom(full_class_name, full_obj_name, object_className_obj)
		--process_each_expression("ClassAssertion", full_class_name, object_className_obj)
		--insert_axiom_in_table(global_table['OWLNamedIndividual']['OWLClassAssertionAxiom'], full_obj_name, object_className)
	end
	for i, class_name in pairs(class_name_table) do
		--local full_class_name = get_full_class_name_by_name_and_ns(class_name, "")
		axiom_value = axiom_value .. make_class_assertion_axiom(class_name, full_obj_name)
		--insert_axiom_in_table(global_table['OWLNamedIndividual']['OWLClassAssertionAxiom'], full_obj_name, class_name_table[1])
	end
	for i, set in pairs(class_name_axioms) do
	    for _, class_name in ipairs(set) do
		axiom_value = axiom_value .. make_class_assertion_axiom(class_name, full_obj_name)
		--table.insert(global_table['OWLNamedIndividual']['OWLClassAssertionAxiom'], class_name_axioms[1])
	end
	end
	if #class_name_table == 0 and #class_name_axioms == 0 and full_obj_name ~= "" and full_obj_name ~= nil and object_className == "" then
		axiom_value = axiom_value .. "ClassAssertion(owl:Thing " .. full_obj_name .. ")\n"
	end
	if object_name ~= "" then
		table.insert(elements['Object'], full_obj_name)
		object:find("/compartment/subCompartment:has(/compartType[id = 'SameIndividuals'])"):each(function(same_individ)
			local individual = same_individ:find("/subCompartment:has(/compartType[id = 'Individual'])"):attr("value")
			if individual ~= "" then
				local ns = same_individ:find("/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
				local value = make_full_object_name(ns, individual)
				local anotations = execute_tag_key_procedures(same_individ)
				axiom_value = axiom_value .. "SameIndividual(" .. anotations .. full_obj_name .. " " .. value .. ")\n"
			end
		end)
		object:find("/compartment/subCompartment:has(/compartType[id = 'DifferentIndividuals'])"):each(function(different_individual)
			local individual = different_individual:find("/subCompartment:has(/compartType[id = 'Individual'])"):attr("value")
			if individual ~= "" then
				local ns = different_individual:find("/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
				local value = make_full_object_name(ns, individual)
				local anotations = execute_tag_key_procedures(different_individual)
				axiom_value = axiom_value .. "DifferentIndividuals(" .. anotations .. full_obj_name .. " " .. value .. ")\n"
			end
		end)

		if annotations ~= nil and annotations ~= "" then
			axiom_value = axiom_value .. annotations
		end
		axiom_value = axiom_value .. property_assertion .. negative_property_assertion
		object:attr("axioms", axiom_value)
	else
		object:attr("axioms", "")
	end
	--log("axiom value " .. axiom_value)
	return axiom_value
end

function make_class_assertion_axiom(full_class_name, full_obj_name, object_className_obj)
	local axiom_value = ""
	--axiom_value = axiom_value .. "Declaration(" .. "Class(" .. full_class_name .. "))\n"
	local anotations = execute_tag_key_procedures(object_className_obj)
	axiom_value = axiom_value .. "ClassAssertion(" .. anotations .. full_class_name .. " " ..  full_obj_name .. ")\n"
	return axiom_value
end

function get_object_uri(object)
	local path_prefix = "/compartment/subCompartment/subCompartment"
	return get_obj_name_uri(object, path_prefix .. ":has(/compartType[id = 'Name'])", path_prefix .. ":has(/compartType[id = 'Namespace'])")
end


function table_map(list, prefix, suffix)
	local res = {}
	for i, item in pairs(list) do
		table.insert(res, prefix .. item .. suffix)
	end
return res
end

function get_property_assertions(object, object_name, path_to_elem, path_to_property, path_to_value, path_to_type, uri, functional_type)
	local property_assertion = ""
	object:find(path_to_elem):each(function(elem)
		local property_obj = elem:find(path_to_property)
		local property = property_obj:attr_e("value")
		local ns = elem:find(path_to_ns):attr_e("value")
		local full_prop_name = make_full_object_name(ns, property)
		local value = elem:find(path_to_value):attr_e("value")
		local data_type = elem:find(path_to_type):attr_e("value")
		local tail = ""
		if property ~= "" and value ~= "" and property ~= nil and value ~= nil then
			local axiom_end = ")\n"
			if data_type ~= "" then
				local _, buls = utilities.search_in_table(specific.default_types(), data_type)
				if buls == 0 then
					tail = "^^xsd:" .. data_type .. axiom_end
				else
					tail = "^^" .. make_full_object_name("", data_type) .. axiom_end
				end
				--tail =  .. tail
			else
				local digit = lpeg.C(lpeg.R("09"))
				local digits = digit * digit ^ 0
				local float = lpeg.match(lpeg.Ct(lpeg.Cg(lpeg.C(digits * lpeg.C(".") * digits), "Number") * lpeg.Cg((lpeg.C("f") ^ -1), "F")), value)
				if float ~= nil then
					value = float["Number"]
					tail = "^^xsd:float" .. axiom_end
				elseif lpeg.match(digits, value) ~= nil then
					tail = "^^xsd:integer" .. axiom_end
				else
					tail =  "^^xsd:string" .. axiom_end
				end
			end
			local anotations = execute_tag_key_procedures(property_obj)
			property_assertion = property_assertion .. functional_type .. "(" .. anotations .. full_prop_name .. " " .. object_name .. " " ..  "\"" .. string.gsub(value, "\"", "") .. "\"" .. tail
		end
	end)
return property_assertion
end

function sameAs_to_sameAs(global_table, diagram, increment_progress)
	object_box_object(global_table, diagram, "SameAsIndivids", "SameIndividual", increment_progress)
end

function disjointClasses_to_disjointClasses(global_table, diagram, increment_progress)
	class_box_class(global_table, diagram, "DisjointClasses", "DisjointClasses", "/compartment/subCompartment:has(/compartType[id = 'Name'])[value != '']", "OWLClass", "DisjointClasses", increment_progress)
end

function equivalentClasses_to_equivalentClasses(global_table, diagram, increment_progress)
	class_box_class(global_table, diagram, "EquivalentClasses", "EquivalentClasses", "/compartment/subCompartment:has(/compartType[id = 'Name'])[value != '']", "OWLClass", "EquivalentClasses", increment_progress)
end

function differentIndivids_to_differentIndivids(global_table, diagram, increment_progress)
	object_box_object(global_table, diagram, "DifferentIndivids", "DifferentIndividuals", increment_progress)
end

function class_box_class(global_table, diagram, elem_type, functional_name, path, table_type, axiom_type, increment_progress)
	diagram:find("/element:has(/elemType[id=" .. elem_type .. "])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id=" .. elem_type .. "])"):each(function(same)
		local axiom_value = ""
		increment_progress()
		local obj_table = {}
		get_obj_name_table(same, obj_table, get_class_uri, increment_progress)
		local path_to_axiom = "/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])/subCompartment"
		local classes = global_table[table_type]
		axiom_value = axiom_value .. process_class_axioms(same, "/eEnd/start", path_to_axiom, obj_table, axiom_type, increment_progress)
		axiom_value = axiom_value .. process_class_axioms(same, "/eStart/end", path_to_axiom, obj_table, axiom_type, increment_progress)
		local annotation = same:find("/compartment:has(/compartType[id = 'Annotation'])")
		local annotation_type = annotation:find("/subCompartment:has(/compartType[id = 'AnnotationType'])"):attr("value")
		local annotation_value = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Value'])"):attr("input")
		local annotation_lang = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Language'])"):attr("value")
		local annot_ns = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
		local static_annotation = ontology_annotations(annotation, annotation_type, annotation_value, annotation_lang, annot_ns)
		if #obj_table >= 2 then
			local obj_names = table.concat(obj_table, " ")
			local anotations = execute_tag_key_procedures(same)
			local delimiter = " "
			if static_annotation == "" then
				delimiter = ""
			end
			obj_names = string.format("%s(%s%s%s%s)\n", functional_name, static_annotation, delimiter, anotations, obj_names)
			axiom_value = axiom_value .. obj_names
			same:attr("axioms", axiom_value)
		else
			same:attr("axioms", "")
		end
	end)
end

function get_obj_name_table(same, obj_table, uri_function_name, increment_progress)
	local obj_name_start = get_table_of_class_names(same, "/eStart/end", uri_function_name, increment_progress)
	for _, val in pairs(obj_name_start) do
		table.insert(obj_table, val)
	end
	local obj_name_end = get_table_of_class_names(same, "/eEnd/start", uri_function_name, increment_progress)
	for _, val in pairs(obj_name_end) do
		table.insert(obj_table, val)
	end
end

function object_box_object(global_table, diagram, elem_type, functional_name, increment_progress)
	diagram:find("/element:has(/elemType[id=" .. elem_type .. "])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id=" .. elem_type .. "])"):each(function(same)
		increment_progress()
		local obj_table = {}
		local axiom_value = ""
		get_obj_name_table(same, obj_table, get_object_uri, increment_progress)
		axiom_value = axiom_value .. process_object_axioms(same, "/eEnd/start", obj_table, functional_name)
		axiom_value = axiom_value .. process_object_axioms(same, "/eStart/end", obj_table, functional_name)
		local annotation = same:find("/compartment:has(/compartType[id = 'Annotation'])")
		local annotation_type = annotation:find("/subCompartment:has(/compartType[id = 'AnnotationType'])"):attr("value")
		local annotation_value = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Value'])"):attr("input")
		local annotation_lang = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Language'])"):attr("value")
		local annot_ns = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
		local static_annotation = ontology_annotations(annotation, annotation_type, annotation_value, annotation_lang, annot_ns)
		if #obj_table >= 2 then
			local obj_names = table.concat(obj_table, " ")
			local delimiter = " "
			if static_annotation == "" then
				delimiter = ""
			end
			axiom_value = axiom_value .. string.format("%s(%s%s%s%s)\n", functional_name, static_annotation, delimiter, static_annotation, obj_names)
			same:attr("axioms", axiom_value)
		else
			same:attr("axioms", "")
		end
	end)
end

function process_object_axioms(same, path, obj_table, functional_name)
	local str = ""
	same:find(path):each(function(obj)
		local obj_name, _, full_obj_name = get_object_uri(obj)
		local same_objects = obj:find("/compartment:has(/compartType[id = 'SameIndividuals'])"):attr_e("value")
		local res = remove_preffix_delimiter_suffix(same_objects, "", "", ",")
		if type(res) == "table" then
			for j, domain in pairs(obj_table) do
				if domain ~= full_obj_name then
					for i, name in pairs(res) do
						--more complex uri analyze is needed
						local uri = get_uri_from_global_table(object_uri_table, name)
						local anotations = execute_tag_key_procedures(same)
						str = str .. functional_name .. "(" .. anotations .. domain .. full_obj_name .. ")\n"
					end
				end
			end
		end
	end)
	return str
end

function annotationProperty_to_annotationProperty(global_table, diagram, increment_progress)
	local axiom_value = ""
	diagram:find("/element:has(/elemType[id='AnnotationProperty'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='AnnotationProperty'])"):each(function(property)
		axiom_value = ""
		increment_progress()

		local name_obj = property:find("/compartment:has(/compartType[id = 'Name'])/subCompartment:has(/compartType[id = 'Name'])")
		local name = name_obj:attr("value")
		local name_space = property:find("/compartment:has(/compartType[id = 'Name'])/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
		local full_name = make_full_object_name(name_space, name)

		local anotations = execute_tag_key_procedures(name_obj)
		axiom_value = axiom_value .. "Declaration(" .. anotations .. "AnnotationProperty(" .. full_name .. "))\n"

		local comment_obj = property:find("/compartment:has(/compartType[id = 'Comment'])")
		local comment = comment_obj:attr("value")
		if comment ~= "" then
			anotations = execute_tag_key_procedures(comment_obj)
			axiom_value = axiom_value .. "AnnotationAssertion(" .. anotations .. "rdfs:comment " .. full_name .. ' "'.. comment .. '")\n'
		end

		local superproperties = property:find("/compartment/subCompartment:has(/compartType[id = 'SuperProperties'])")
		axiom_value = axiom_value .. add_association_attribute(superproperties, "SubAnnotationPropertyOf", full_name)

		local domain_name_obj = property:find("/compartment:has(/compartType[id = 'Domain'])/subCompartment:has(/compartType[id = 'Name'])")
		local domain_name = domain_name_obj:attr("value")
		local domain_name_space = property:find("/compartment:has(/compartType[id = 'Domain'])/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
		local full_domain = make_full_object_name(domain_name_space, domain_name)
		anotations = execute_tag_key_procedures(domain_name_obj)
		if full_domain ~= "" then
			axiom_value = axiom_value .. "AnnotationPropertyDomain(" .. anotations .. full_name .. " " .. full_domain .. ")\n"
		end
		local range_name_obj = property:find("/compartment:has(/compartType[id = 'Range'])/subCompartment:has(/compartType[id = 'Name'])")
		local range_name = range_name_obj:attr("value")
		local range_name_space = property:find("/compartment:has(/compartType[id = 'Range'])/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
		local full_range = make_full_object_name(range_name_space, range_name)
		anotations = execute_tag_key_procedures(range_name_obj)
		if full_range ~= "" then
			axiom_value = axiom_value .. "AnnotationPropertyRange(" .. anotations .. full_name .. " " .. full_range .. ")\n"
		end
		axiom_value = axiom_value .. make_multiple_annotations(property, "/compartment/subCompartment:has(/compartType[id = 'Annotation'])", "AnnotationAssertion", full_name, ")")

		property:attr("axioms", axiom_value)
	end)
end

function someValuesFrom_to_someValuesFrom(global_table, diagram, increment_progress)
	diagram:find("/element:has(/elemType[id='Restriction'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='Restriction'])"):each(function(some)
		export_Restriction(some, increment_progress)
	end)
end

function export_Restriction(some, increment_progress)
	local axiom_value = ""
	if increment_progress ~= nil then
		increment_progress()
	end
	local _, start_class_name, full_start_class = get_class_uri(some:find("/start"))
	if (start_class_name ~= "" and start_class_name ~= nil) or (end_class_name ~= "" and end_class_name ~= nil) then
		local _, end_class_name, full_end_class = get_class_uri(some:find("/end"))
		local name_compart = some:find("/compartment:has(/compartType[id = 'Name'])")
		local role_obj = name_compart:find("/subCompartment:has(/compartType[id = 'Role'])")
		local role = role_obj:attr_e("value")
		local multiplicity = some:find("/compartment:has(/compartType[id = 'Multiplicity'])")
		if multiplicity:is_empty() then
			multiplicity = some:find("/compartment/subCompartment:has(/compartType[id = 'Multiplicity'])")
		end
		if role ~= "" and role ~= nil then
			local equivalent = {}
			local only_checkBox = some:find("/compartment:has(/compartType[id = 'Only'])"):attr_e("value")
			local cardinality = "some"
			if only_checkBox == "true" then
				cardinality = "only"
			end
			local axiom_cardinality = get_axiom_name_by_cardinality("Object", cardinality)
			local ns_compart = name_compart:find("/subCompartment:has(/compartType[id = 'Namespace'])")
			local ns = ns_compart:attr("value")
			local full_role = make_full_object_name(ns, role)
			local anotations = execute_tag_key_procedures(role_obj)
			axiom_value = axiom_value .. string.format('Declaration(%s ObjectProperty(%s))\n', anotations, full_role)
			local res = get_multiplicity_functional(multiplicity, full_start_class, full_role, "Object", "Functional", full_end_class)
			anotations = execute_tag_key_procedures(role_obj, axiom_cardinality)
			if name_compart:find("/subCompartment:has(/compartType[id = 'IsInverse'])"):attr("value") == "true" then
				full_role = string.format("ObjectInverseOf(%s)", full_role)
			end
			axiom_value = axiom_value .. string.format('SubClassOf(%s %s %s(%s %s))\n', anotations, full_start_class, axiom_cardinality, full_role, full_end_class)
			axiom_value = axiom_value .. res .. "\n"
			some:attr("axioms", axiom_value)
		else
			some:attr("axioms", "")
		end
	end
	return axiom_value
end

function process_association_properties(assoc, direction, assoc_direction, path_to_range, path_to_domain, functional_name, inverse_direction)
		--print(inverse_direction)
		local axiom = ""
		local is_inverse = false
		local first_compartment = "/compartment:has(/compartType[id = " .. assoc_direction .. "])"
		local path_to_class_name = "/compartment/subCompartment:has(/compartType[id = 'Name'])"
		local path_to_ns = first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Namespace'])"
		--local start_class_name, start_uri, start_name, start_class_obj = get_obj_name_uri(assoc:find(path_to_domain), path_to_class_name, path_to_ns)
		--local end_class_name, end_uri, end_name, end_class_obj = get_obj_name_uri(assoc:find(path_to_range), path_to_class_name, path_to_ns)
		local start_class_name = get_full_class_name_from_class(assoc:find(path_to_domain))
		local end_class_name = get_full_class_name_from_class(assoc:find(path_to_range))
		local path_prefix = first_compartment .. "/subCompartment:has(/compartType[id = 'Name'])/subCompartment:has(/compartType[id = '"
		local direct_value, uri, full_direct_value, direct_obj = get_obj_name_uri(assoc, path_prefix .. "Name'])", path_prefix .. "Namespace'])")
		direct_value = string.gsub(direct_value, " ", "_")
		if direct_value == "" then
			is_inverse = true
			local prefix = "/compartment:has(/compartType[id = " .. inverse_direction .. "])/subCompartment:has(/compartType[id = 'Name'])/subCompartment:has(/compartType[id = '"
			direct_value, uri, full_direct_value = get_obj_name_uri(assoc, prefix .. "Name'])", prefix .. "Namespace'])")
			direct_value = string.gsub(direct_value, " ", "_")
		end
		if is_inverse then
			full_direct_value = "ObjectInverseOf(" .. full_direct_value .. ")"
		end
		local property = ""
		if direct_value ~= "" and direct_value ~= nil then
			--local class_val = "AnnotationAssertion(ObjectProperty(" .. full_direct_value .. ") "
			--if is_inverse then
				--table.insert(elements['ObjectProp'], direct_value)
			--end
			property = make_multiple_annotations(assoc, first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Annotation'])", "ObjectProperty", full_direct_value, ")")

			local multiplicity = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'Multiplicity'])")
			if multiplicity:is_empty() then
				multiplicity = assoc:find(first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Multiplicity'])")
			end
			property = property .. association_multiplicity(assoc, direction, multiplicity, end_class_name, full_direct_value, start_class_name)

			local functional_property = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'Functional'])")
			if functional_property:is_empty() then
				functional_property = assoc:find(first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Functional'])")
			end
			property = make_functional_string(property, functional_property, "FunctionalObjectProperty", full_direct_value)

			local inverse_functional_property = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'InverseFunctional'])")
			if inverse_functional_property:is_empty() then
				inverse_functional_property = assoc:find(first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'InverseFunctional'])")
			end
			property = make_functional_string(property, inverse_functional_property, "InverseFunctionalObjectProperty", full_direct_value)

			local symmetric = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'Symmetric'])")
			if symmetric:is_empty() then
				symmetric = assoc:find(first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Symmetric'])")
			end
			property = make_functional_string(property, symmetric, "SymmetricObjectProperty", full_direct_value)

			local asymmetric = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'Asymmetric'])")
			if asymmetric:is_empty() then
				asymmetric = assoc:find(first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Asymmetric'])")
			end
			property = make_functional_string(property, asymmetric, "AsymmetricObjectProperty", full_direct_value)

			local reflexive = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'Reflexive'])")
			if reflexive:is_empty() then
				reflexive = assoc:find(first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Reflexive'])")
			end
			property = make_functional_string(property, reflexive, "ReflexiveObjectProperty", full_direct_value)

			local irreflexive = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'Irreflexive'])")
			if irreflexive:is_empty() then
				irreflexive = assoc:find(first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Irreflexive'])")
			end
			property = make_functional_string(property, irreflexive, "IrreflexiveObjectProperty", full_direct_value)

			local transitive = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'Transitive'])")
			if transitive:is_empty() then
				transitive = assoc:find(first_compartment .. "/subCompartment/subCompartment:has(/compartType[id = 'Transitive'])")
			end
			property = make_functional_string(property, transitive, "TransitiveObjectProperty", full_direct_value)

			property = property .. get_equivalent_axioms(start_class_name, full_direct_value, assoc, path_to_domain  .. "/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])", "ObjectPropertyRange", is_inverse, start_class_obj)
			property = property .. get_equivalent_axioms(end_class_name, full_direct_value, assoc, path_to_range .. "/compartment/subCompartment:has(/compartType[id = 'EquivalentClasses'])", "ObjectPropertyDomain", is_inverse, end_class_obj)

			local equivalent = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'EquivalentProperties'])/subCompartment")
			property = property .. add_association_eq_disjoint_attribute(equivalent, "EquivalentObjectProperties", "EquivalentProperty",  full_direct_value)

			local superproperties = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'SuperProperties'])/subCompartment")
			property = property .. add_association_attribute(superproperties, "SubObjectPropertyOf", full_direct_value)

			local disjoint = assoc:find(first_compartment .. "/subCompartment:has(/compartType[id = 'DisjointProperties'])/subCompartment")
			property = property .. add_association_eq_disjoint_attribute(disjoint, "DisjointObjectProperties", "DisjointProperty", full_direct_value)

			property = property .. add_property_chain(assoc, full_direct_value, first_compartment)
		end
		if not(is_inverse) then
			return  property, direct_value, uri, direct_obj
		else
			return property
		end
end

function association_multiplicity(assoc, direction, multiplicity, start_class_name, direct_value, end_class_name)
	local result = ""
	if direction == "Direct" then
		result = result .. get_multiplicity_functional(multiplicity, start_class_name, direct_value, "Object", "Functional", end_class_name)
		local inv_multiplicity = assoc:find("/compartment:has(/compartType[id = 'InvMultiplicity'])")
		result = result .. get_multiplicity_functional(inv_multiplicity, start_class_name, direct_value, "Object", "InverseFunctional", end_class_name)
		return result
	else
		result = result .. get_multiplicity_functional(multiplicity, start_class_name, direct_value, "Object", "Functional", end_class_name)
		local inv_multiplicity = assoc:find("/compartment:has(/compartType[id = 'Multiplicity'])")
		result = result .. get_multiplicity_functional(inv_multiplicity, start_class_name, direct_value, "Object", "InverseFunctional", end_class_name)
		return result
	end
end

function association_to_property(global_table, diagram, increment_progress)
	local axiom_value = ""
	local ontology_ns = ""
	diagram:find("/element:has(/elemType[id='Association'])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id='Association'])"):each(function(assoc)
		export_Association(assoc, increment_progress)
	end)
end

function export_Association(assoc, increment_progress)
	axiom_value = ""
	if increment_progress ~= nil then
		increment_progress()
	end
	--all_prop_names = get_all_property_names()

	local axiom_values_direct, direct_value, uri, direct_obj = process_association_properties(assoc, "Direct", "Role", "/start", "/end", "Declaration(ObjectProperty", "InvRole")
	local axiom_values_inv, inv_value, inv_uri, inv_direct_obj = process_association_properties(assoc, "Inverse", "InvRole", "/end", "/start", "InverseObjectProperties", "Role")
--		local comment_in_box = get_comment(assoc, "ObjectProperty", direct_value, "/compartment:has(/compartType[id = 'Annotation'])", "/compartment/subCompartment:has(/compartType[id = 'Value'])", "/compartment/subCompartment:has(/compartType[id = 'Language'])")

	local comment_table = get_assoc_comment_in_box(assoc, get_prop_name(direct_value))
	for i, val in pairs(comment_table) do
		axiom_value = axiom_value .. val .. "\n"
	end
	if direct_value ~= nil and direct_value ~= "" then
		local anotations = execute_tag_key_procedures(direct_obj, "Declaration")
		axiom_value = axiom_value .. "Declaration(" .. anotations .. "ObjectProperty(<" .. uri .. direct_value .. ">))\n"
	end
	if inv_value ~= "" and inv_value ~= nil and direct_value ~= nil and direct_value ~= "" then
	    local anotations = execute_tag_key_procedures(inv_direct_obj, "InverseObjectProperties")
		axiom_value = axiom_value .. "InverseObjectProperties(" .. anotations .. " <" .. uri .. direct_value .. "> <" .. inv_uri .. inv_value .. ">)\n"
	end
	if axiom_values_direct ~= nil then
		axiom_value = axiom_value .. axiom_values_direct .. axiom_values_inv
	end
	assoc:attr("axioms", axiom_value)
	return axiom_value
end

function get_assoc_comment_in_box(assoc, direct_value)
	local comment_table = {}
	make_comment_axioms(assoc, elem_type, direct_value, "/eStart:has(/elemType[id = 'Connector'])", "/end", comment_table, "/compartment/subCompartment:has(/compartType[id = 'Value'])", "/compartment:has(/compartType[id = 'AnnotationType'])",  "/compartment/subCompartment:has(/compartType[id = 'Language'])")
	make_comment_axioms(assoc, elem_type, direct_value, "/eEnd:has(/elemType[id = 'Connector'])", "/start", comment_table, "/compartment/subCompartment:has(/compartType[id = 'Value'])", "/compartment:has(/compartType[id = 'AnnotationType'])", "/compartment/subCompartment:has(/compartType[id = 'Language'])")
return comment_table
end

function get_equivalent_axioms(class_name, domain, assoc, path, axiom_type, is_inverse, class_obj)
	local res = ""
	if (class_name ~= "" and class_name ~= nil and domain ~= class_name) and not(is_inverse) then
		local anotations = execute_tag_key_procedures(class_obj, axiom_type)
		res = res .. axiom_type .. "(" .. anotations .. domain .. " " .. class_name .. ")\n"
	else
		local tmp_table = insert_names_in_table(assoc, path)
		for _, attr in pairs(tmp_table) do
			res = res .. process_each_expression(axiom_type, domain, attr, attr, axiom_type)
		end
	end
	return res
end

function insert_names_in_table(class, path)
	local tmp_table = {}
	class:find(path):each(function(attr)
		table.insert(tmp_table, attr)
	end)
	return tmp_table
end

function add_property_chain(assoc, property_name, first_compart)
	local str = ""
	if assoc ~= nil then
		assoc:find(first_compart .. "/subCompartment/subCompartment/subCompartment:has(/compartType[id = 'PropertyChains'])"):each(function(tmp_chain)
			local full_prop_table = {}
			tmp_chain:find("/subCompartment/subCompartment:has(/compartType[id = 'PropertyChain'])"):each(function(chain)
				local prop = chain:find("/subCompartment:has(/compartType[id = 'Property'])"):attr_e("value")
				local ns = chain:find("/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
				local inverse = chain:find("/subCompartment:has(/compartType[id = 'Inverse'])"):attr_e("value")
				local prop_name = make_full_object_name(ns, prop)
				if inverse == "true" then
					prop_name = "ObjectInverseOf(" .. prop_name .. ")"
				end
				table.insert(full_prop_table, prop_name)
			end)
			local anotations = execute_tag_key_procedures(tmp_chain)
			if #full_prop_table ~= 0 then
				str = str .. "SubObjectPropertyOf(" ..  anotations .. "ObjectPropertyChain(" .. table.concat(full_prop_table, " ") .. ") " .. property_name .. ")\n"
			end
		end)
	end
	return str
end

function parse_prop_chain(val)
	local grammer = re.compile[[grammer <- ({[a-zA-Z0-9_]*}((' ')*('o')(' ')*{[a-zA-Z0-9_]*})*)]]
	return re.match(val, lpeg.Ct(grammer) * -1)
end

function add_association_attribute(attr, functional_type, inverse_value)
	local str = ""
	if attr ~= "" and attr ~= nil then
		attr:find("/subCompartment/subCompartment:has(/compartType[id = 'Expression'])"):each(function(sub_compart)
			local name = sub_compart:attr("value")
			local uri = get_uri_from_global_table(object_property_uri_table, name)
			local anotations = execute_tag_key_procedures(sub_compart)
			if name ~= "" then
				str = str .. functional_type .. "(" .. anotations .. inverse_value .. " <" .. uri .. name .. ">)\n"
			end
		end)
	end
return str
end

function add_association_eq_disjoint_attribute(attr, functional_type, sub_compart_name, inverse_value)
	local str = ""
	if attr ~= "" and attr ~= nil then
		attr:find("/subCompartment"):each(function(tmp_compart)
			local expressions = ""
			local annotations = ""
			tmp_compart:find("/subCompartment/subCompartment:has(/compartType[id = " .. sub_compart_name .. "])"):each(function(sub_compart)
				local name = sub_compart:attr("value")
				local uri = get_uri_from_global_table(object_property_uri_table, name)
				expressions = expressions .. " <" .. uri .. name .. ">"

			end)
			if expressions ~= "" then
				--local anotations = ""	--execute_tag_key_procedures(sub_compart)
				annotations = annotations .. execute_tag_key_procedures(tmp_compart)
				str = str .. functional_type .. "(" .. annotations .. inverse_value .. expressions .. ")\n"
			end
		end)
	end
	return str
end

function remove_preffix_delimiter_suffix(val, preffix, suffix, delimiter)
	local list = {}
	if val ~= "" then
		local generated_grammer = "grammer <- ('" .. preffix .. "'{[a-zA-Z0-9_]*}((' ')*('" .. delimiter .. "'(' ')*){[a-zA-Z0-9_]*})*'" .. suffix .. "')"
		local string = "[a-zA-Z0-9_]*"
		local value =  "{:Value: " .. string .. ":}"
		local ns = "(('{'){:Namespace: " .. string .. ":}('}'))?"
		local property = "{:Property: (" .. value .. ns .. ") -> {}:} -> {}"
		local generated_grammer = re.compile("grammer <- ('" .. preffix .. "'" .. property .. "((' ')*(('" .. delimiter .. "')(' ')*)" .. property .. ")*('" .. suffix .. "'))")
		local res = re.match(val, lpeg.Ct(generated_grammer) * -1)
		for _, item in pairs(res) do
			table.insert(list, make_full_object_name(item["Property"]["Namespace"], item["Property"]["Value"]))
		end
	end
	return list
end

function remove_preffix(value, preffix)
	local Space = lpeg.S(" \n\r\t") ^ 0
	local preffix = lpeg.P(preffix)
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.S("-_()") + lpeg.R("09") + lpeg.S("āēīūčģķļņšž") + lpeg.S("ĀĒĪŪČĢĶĻŅŠŽ")
	local String = lpeg.C(Letter ^ 1) * lpeg.S(" \n\t") ^ 0
	local res = lpeg.match(lpeg.Ct(preffix * String), value)
return res
end


function get_uri_from_global_table(table_in, index)
	local uri = table_in[index]
	if uri == nil then
		return get_current_uri()
	else
		return uri
	end
end

function get_uri_from_data_or_object_property_table(data_table, obj_table, index)
	local uri = data_table[index]
	if uri == nil then
		uri = obj_table[index]
		if uri == nil then
			return get_current_uri(), "object"
		else
			return uri, "object"
		end
	else
		return uri, "data"
	end
end

function make_functional_string(property, attr_obj, description, value)
	--print("make functional string")
	--print(property)
	--print(value)
	--attr_obj:log("value")

	local anotations = execute_tag_key_procedures(attr_obj)
	if attr_obj:attr("value") ~= "" and attr_obj:attr("value") ~= "false" then
		property = property .. description .. "(".. anotations .. value .. ")\n"
	end
return property
end

function get_comment(element, elem_type, name, path_to_value_type, path_to_value, path_to_language)
	local comments = ""
	local comment_table = {}
	make_comment_axioms(element, elem_type, name, "/eStart:has(/elemType[id = 'Connector'])", "/end", comment_table, path_to_value, path_to_value_type, path_to_language)
	make_comment_axioms(element, elem_type, name, "/eEnd:has(/elemType[id = 'Connector'])", "/start", comment_table, path_to_value, path_to_value_type, path_to_language)
return comment_table
end

function make_comment_axioms(element, elem_type, name, path, path_to_comment, comment_table, path_to_value, path_to_value_type, path_to_language)
	element:find(path):each(function(connector2)
		local comment = connector2:find(path_to_comment)
		local comment_type = comment:find(path_to_value_type):attr_e("value")
		local property = comment:find("/compartment:has(/compartType[id = 'Property'])"):attr_e("value")
		comment_type = string.gsub(comment_type, "<<", "")
		comment_type = string.gsub(comment_type, ">>", "")
		local comment_lang = comment:find(path_to_language):attr_e("value")
		local comment_obj = comment:find(path_to_value)
		local comment_value = comment_obj:attr_e("input") or ""
		local comment_text = ""
		if property ~= "" then
			local full_attr_name = get_attribute_full_name(element, property)
			if full_attr_name ~= "" then
				comment_text = make_annotation(comment_type, comment_value, comment_lang, full_attr_name, ")", comment_obj)
			end
		else
			comment_text = make_annotation(comment_type, comment_value, comment_lang, name, ")", comment_obj)
		end
 		table.insert(comment_table, comment_text)
	end)
end

function get_attribute_full_name(elem, property)
	local full_attr_name = ""
	elem:find("/compartment/subCompartment:has(/compartType[id = 'Attributes'])"):each(function(attribute)
		if attribute:find("/subCompartment/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value") == property then
			full_attr_name = "<" .. get_uri_by_ns(attribute, "/subCompartment/subCompartment:has(/compartType[id = 'Namespace'])") .. property .. ">"
		end
	end)
	if full_attr_name == "" then
		local name_compart = elem:find("/compartment:has(/compartType[id = 'Name'])")
		local name = name_compart:find("/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
		if name ~= property then
			name_compart = elem:find("/compartment:has(/compartType[id = 'InvName'])")
			name = name_compart:find("/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
		end
		if name == property then
			full_attr_name = "<" .. get_uri_by_ns(name_compart, "/subCompartment:has(/compartType[id = 'Namespace'])") .. property .. ">"
		end
	end
	return full_attr_name
end

function make_complete_annotation(annotation_type, annotation_value, class_uri_name, finish, obj)
	local anotations = execute_tag_key_procedures(obj)
	local prefix = "AnnotationAssertion(" .. anotations
	annotation_value = " " .. annotation_value
	local full_annotation_type = ""
	if annotation_type ~= nil and annotation_type ~= "" then
		local annot_type = annotation_table[annotation_type]
		if annot_type ~= nil then
			full_annotation_type = annot_type
		else
			full_annotation_type = "<" .. get_current_uri() .. annotation_type .. "> "
		end
		return prefix .. full_annotation_type .. " " .. class_uri_name .. annotation_value .. finish .. "\n"
	else
		return ""
	end
end

function process_class_axioms(same, path_to_class, path_to_axiom, obj_table, axiom_type, increment_progress)
	local res = ""
	local name_table1 = {}
	same:find(path_to_class):each(function(class)
		increment_progress()
		local _, _, full_name = get_class_uri(class)
		class:find(path_to_axiom):each(function(axiom)
			local axiom_value = axiom:attr_e("value")
			if axiom_value ~= "" then
				for _, base in pairs(obj_table) do
					if base ~= full_name then
						res = res .. process_each_expression(axiom_type, base, axiom)
					end
				end
			end
		end)
	end)
	return res
end

function get_table_of_class_names(same, path, uri_function_name, increment_progress)
	local name_table1 = {}
	same:find(path):each(function(item)
		increment_progress()
		local _, name, full_name = uri_function_name(item)
		if name ~= "" then
			table.insert(name_table1, full_name)
		end
	end)
	return name_table1
end

function get_obj_name_uri(elem, path_to_name, path_to_ns)
	local elem_obj = elem:find(path_to_name)
	local val = elem_obj:attr_e("value")
	val = string.gsub(val, " ", "_")
	local uri = get_uri_by_ns(elem, path_to_ns)
	return val, uri, make_full_name(uri, val), elem_obj
end

function make_full_name(uri, val)
	if val == "" then
		return ""
	else
		return "<" .. uri .. val .. ">"
	end
end

function object_to_object(diagram, elem_type, functional_name, complement, tail, increment_progress)
	box_to_box(diagram, elem_type, functional_name, complement, tail, get_object_uri, increment_progress)
end

function box_to_box(diagram, elem_type, functional_name, complement, tail, uri_function_name, increment_progress)
	diagram:find("/element:has(/elemType[id = " .. elem_type .. "])"):attr("axiom", "")
	diagram:find("/element:has(/elemType[id = " .. elem_type .. "])"):each(function(elem)
		increment_progress()
		local start_name, _, start_full_name = uri_function_name(elem:find("/start"))
		local end_name, _, end_full_name = uri_function_name(elem:find("/end"))
		local annotation = elem:find("/compartment:has(/compartType[id = 'Annotation'])")
		local annotation_type = annotation:find("/subCompartment:has(/compartType[id = 'AnnotationType'])"):attr("value")
		local annotation_value = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Value'])"):attr("input")
		local annotation_lang = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Language'])"):attr("value")
		local annot_ns = annotation:find("/subCompartment:has(/compartType[id = 'ValueLanguage'])/subCompartment:has(/compartType[id = 'Namespace'])"):attr("value")
		local static_annotation = ""
		if annotation_value ~= "" and annotation_value ~= nil then
			static_annotation = ontology_annotations(annotation, annotation_type, annotation_value, annotation_lang, annot_ns)
		end

		local anotations = execute_tag_key_procedures(elem)
		if start_full_name ~= nil and start_full_name ~= "" and end_full_name ~= nil and end_full_name ~= "" then
			local list_of_text = {}
			table.insert(list_of_text, functional_name)
			table.insert(list_of_text, "(")
			table.insert(list_of_text, static_annotation)
			table.insert(list_of_text, " ")
			table.insert(list_of_text, anotations)
			table.insert(list_of_text, start_full_name)
			table.insert(list_of_text, complement)
			table.insert(list_of_text, end_full_name)
			table.insert(list_of_text, tail)
			elem:attr("axioms", table.concat(list_of_text))
		else
			elem:attr("axioms", "")
		end
	end)
end

function class_to_class(diagram, elem_type, functional_name, complement, tail, increment_progress)
	box_to_box(diagram, elem_type, functional_name, complement, tail, get_class_uri, increment_progress)
end

function class_to_class_table_composite(global_table, diagram, elem_type, path_to_element, path_to_ns, path_to_attr, path_to_value, global_table_index, table_index, direction, composite, increment_progress)
	local list = {}

	diagram:find("/element:has(/elemType[id = " .. elem_type .. "])"):each(function(elem)
		increment_progress()
		local start_name, _, full_start_name = get_obj_name_uri(elem:find("/start"), path_to_element, path_to_ns)
		local end_name, _, full_end_name = get_obj_name_uri(elem:find("/end"), path_to_element, path_to_ns)

		if start_name == nil or start_name == "" and end_name ~= nil and end_name ~= "" and direction <= 2 then
			make_axiom_class_table(elem, path_to_attr, path_to_value, composite, list, full_end_name, "/start")
		elseif end_name == nil or end_name == "" and start_name ~= nil and start_name ~= "" and direction >= 2 then
			make_axiom_class_table(elem, path_to_attr, path_to_value, composite, list, full_start_name, "/end")
		end

		local classes = global_table[global_table_index] or {}

		for i, set in pairs(list) do

			if (not classes[table_index]) then
				classes[table_index] = {}
			end
 
			table.insert(classes[table_index],  list[i])
		end
		global_table[global_table_index] = classes
	end)
end

function make_axiom_class_table(elem, path_to_attr, path_to_value, composite, list, start_obj_name, role)
	elem:find(role .. path_to_attr):each(function(tmp)
		local val = tmp:find(path_to_value):attr_e("value")
		if composite ~= "" then
			val = composite .. "(" .. tmp:find(path_to_value):attr_e("value") .. ")"
		end
		if start_obj_name ~= val then
			insert_axiom_in_table(list, start_obj_name, val)
			--table.insert(list, {prefix .. start_obj_name, val})
		end
	end)
end

function class_to_class_table(global_table, diagram, elem_type, path_to_element, path_to_ns, path_to_attr, path_to_value, global_table_index, table_index, direction, increment_progress)
	class_to_class_table_composite(global_table, diagram, elem_type, path_to_element, path_to_ns, path_to_attr, path_to_value, global_table_index, table_index, direction, "", increment_progress)
end

function object_to_object_anonymous(diagram, elem_type, functional_type, path_to_ns, path_to_element, path_to_attr, path_to_value, increment_progress)
	local str = ""
	diagram:find("/element:has(/elemType[id=" .. elem_type .. "])"):each(function(elem)
		increment_progress()
		local _, _, full_start_name = get_obj_name_uri(elem:find("/start"), path_to_element, path_to_ns)
		local _, _, full_end_name = get_obj_name_uri(elem:find("/end"), path_to_element, path_to_ns)
		if full_start_name == nil or full_start_name == "" and full_end_name ~= nil and full_end_name ~= "" then
			str = str .. add_string_filtered_equivalent(elem, "/start" .. path_to_attr, full_end_name, functional_type)
		elseif full_end_name == nil or full_end_name == "" and full_start_name ~= nil and full_start_name ~= "" then
			str = str .. add_string_filtered_equivalent(elem, "/end" .. path_to_attr, full_start_name, functional_type)
		end
		local axiom_values = elem:attr("axioms") .. str
		elem:attr("axioms", axiom_values)
	end)
end

function add_string_filtered_equivalent(elem, path, domain, functional_type)
	local str = ""
	elem:find(path):each(function(tmp)
		local value = tmp:attr_e("value")
		if value ~= nil and value ~= "" then
			local res = remove_preffix_delimiter_suffix(value, "", "", ",")
			local anotations = execute_tag_key_procedures(tmp)
			for _, name in pairs(res) do
				str = str .. functional_type .. "(" .. anotations .. domain .. " " ..  name .. ")\n"
			end
		end
	end)
return str
end

function execute_tag_key_procedures(obj, argument)
	local res = ""
	if obj ~= nil and obj:is_not_empty() then
		local obj_type = utilities.get_obj_type(obj)
		obj_type:find("/translet[extensionPoint = 'OWLGrEd_GetAxiomAnnotation']"):each(function(translet)
			res = res .. utilities.execute_fn(translet:attr("procedureName"), obj, argument)
		end)
	end
	return res
end

function parser_error(expr)
	report.event("Export Error", {Expression = expr})
end

function export_Element(elem)
	local list = {
		Class = "export_Class",
		Association = "export_Association",
		Generalization = "export_Generalization",
		Restriction = "export_Restriction",
		Object = "export_Object",
		Link = "export_Link",
		HorizontalFork = "export_HorizontalFork"
	}
	local elem_type_name = utilities.get_obj_type(elem):attr("id")
	local func_name = list[elem_type_name]
	local diagram = utilities.get_diagram_from_element(elem)
	ns_uri_table = make_global_ns_uri_table(diagram)
	object_property_uri_table = make_global_object_property_uri_table(diagram)
	data_property_uri_table = make_global_data_property_uri_table(diagram)
	object_uri_table = make_global_object_uri_table(diagram)
	class_uri_table = make_global_class_uri_table(diagram)
	if func_name ~= nil then
		print(utilities.execute_fn("tda_to_protege." .. func_name, elem))
		return utilities.execute_fn("tda_to_protege." .. func_name, elem)
	else
		return ""
	end
end

function make_error_class()
	local axioms = {}
	local class_name = make_full_object_name("", "UnParsedExpressions")
	for index, _ in pairs(error_table) do
		local axiom = string.format('AnnotationAssertion(rdfs:comment %s "%s")', class_name, index)
		table.insert(axioms, axiom)
	end
	if #axioms > 0 then
		local class_declaration = string.format("Declaration(Class(%s))", class_name)
		table.insert(axioms, class_declaration)
	end
	return table.concat(axioms, "\n")
end

