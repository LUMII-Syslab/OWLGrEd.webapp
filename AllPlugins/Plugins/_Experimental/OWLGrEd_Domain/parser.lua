module(..., package.seeall)
require "mii_rep_obj"
require "re"
grammar = require "OWLGrEd_Domain.grammar"
dm = require "OWLGrEd_Domain.domain_manip"


function load_and_parse_ontology()
	local loaded_file = select_ontology_path()
	if loaded_file == "" then
		return false
	end
	
	local prefix_decl_grammar = grammar.prefix_declaration()
	local allow_prefix = true
	local ontology_grammar = grammar.ontology()
	local allow_ontology = true
	local version_grammar = grammar.version()
	local allow_version = true
	local import_grammar = grammar.directly_imports_documents()
	local allow_import = true
	local annotation_grammar = grammar.ontology_annotations()
	local axiom_grammar = grammar.axiom()
	local axioms_only = false
	
	local ontology = lQuery("")
	local prefixes = lQuery("")
	
	for line in io.lines(loaded_file) do
		line = line:match "^%s*(.-)%s*$" -- trim
		local r_prefix = prefix_decl_grammar:match(line)
		local r_ontology = ontology_grammar:match(line)
		local r_version = version_grammar:match(line)
		local r_import = import_grammar:match(line)
		local r_annotation = annotation_grammar:match(line)
		local r_axiom = axiom_grammar:match(line)
		
		if r_axiom ~= nil then
			generate_id(r_axiom)
			local axiom = create_domain_objects(r_axiom, ontology)
			if axiom:find("/ontology"):id() ~= ontology:id() then
				dm.link_objects(axiom, ontology, "ontology")
			end
			
			axioms_only = true
			
		elseif not axioms_only then
			if allow_prefix and r_prefix ~= nil then
				generate_id(r_prefix)
				prefixes = prefixes:add(dm.create_object(r_prefix))
				
			elseif allow_ontology and r_ontology ~= nil then
				generate_id(r_ontology)
				ontology = create_domain_objects(r_ontology)
				
				allow_prefix = false
				allow_ontology = false
				
			elseif allow_version and r_version ~= nil then
				create_ontology_property(r_version, ontology)
				
			elseif allow_import and r_import ~= nil then
				create_ontology_property(r_import, ontology)
				
				allow_version = false
				
			elseif r_annotation ~= nil then
				create_ontology_property(r_annotation, ontology)
				
				allow_import = false
			end
		end
	end
	
	dm.link_objects(prefixes, ontology, "ontology")
	
	return true
end

function parse_class_expression(line, ontology)
	local grammar = grammar.class_expression()
	local cl_expr_table = grammar:match(line)
	generate_id(cl_expr_table)
	
	return create_domain_objects(cl_expr_table, ontology)
end

function parse_data_property_expression(line, ontology)
	local grammar = grammar.data_property_expression()
	local dp_expr_table = grammar:match(line)
	generate_id(dp_expr_table)
	
	return create_domain_objects(dp_expr_table, ontology)
end

function parse_iri(line, ontology)
	local grammar = grammar.iri()
	local iri_table = grammar:match(line)
	generate_id(iri_table)
	
	return create_iri_object(iri_table, ontology)
end

function select_ontology_path()
	return tda.BrowseForFile("Open", "OWL File (*.owl)\nAll Files (*)", "", "", false)
end

function create_domain_objects(object_or_obj_table, ontology)
	if is_lQuery_col(object_or_obj_table) then
		return object_or_obj_table
	end

	if object_or_obj_table['class'] == "OWL#IRI" then
		return create_iri_object(object_or_obj_table, ontology)
	end

	local object = dm.create_object(object_or_obj_table)
	
	if object_or_obj_table['links'] ~= nil then
		for link, link_table in pairs(object_or_obj_table['links']) do
			
			for _, sub_table in ipairs(link_table) do
				local sub_object = create_domain_objects(sub_table, ontology)
				dm.link_objects(object, sub_object, link)
			end
		end
	end
	
	return object
end

function create_ontology_property(obj_table, ontology)
	for link, link_table in pairs(obj_table) do
	
		for _, sub_table in ipairs(link_table) do
			generate_id(sub_table)
			local object = create_domain_objects(sub_table, ontology)
			dm.link_objects(ontology, object, link)
		end
	end
end

function create_iri_object(obj_table, ontology)
	local prefix = "”¿$¸$ù”"
	if obj_table['attrs']['delim'] ~= nil then
		prefix = obj_table['attrs']['prefix']
	end
	
	obj_table['attrs'] = form_iri_attributes(obj_table['attrs'])
	local iri_object = dm.create_object(obj_table)
	
	if ontology ~= nil and iri_object:find("/containingOntology"):id() ~= ontology:id() then
		dm.link_objects(iri_object, ontology, "containingOntology")
	end
	
	dm.link_objects(iri_object, lQuery("OWL#Namespace[prefix = '"..prefix.."']"), "namespace")
	
	return iri_object
end

function generate_id(object_or_obj_table)
	if is_lQuery_col(object_or_obj_table) then
		return object_or_obj_table:attr("id")
	end

	if object_or_obj_table['attrs'] ~= nil and object_or_obj_table['attrs']['id'] ~= nil then
		return object_or_obj_table['attrs']['id']
	end

	local id = ""
	
	if object_or_obj_table['links'] ~= nil then
		for link, link_table in pairs(object_or_obj_table['links']) do
			
			local id_table = {}
			for _, sub_table in ipairs(link_table) do
				table.insert(id_table, generate_id(sub_table))
				--id = id .. " " .. generate_id(sub_table)
			end
			if object_or_obj_table['sort'] == "true" then
				table.sort(id_table)
			end
			id = id..table.concat(id_table, " ")
		end
	end
	
	if object_or_obj_table['attrs'] ~= nil then
		for _, attr_value in pairs(object_or_obj_table['attrs']) do
			id = id .. " " .. attr_value
		end
	end
	
	id = "(" .. id .. ")"
	if type(object_or_obj_table['class']) == "table" then
		for _, class_name in ipairs(object_or_obj_table['class']) do
			id = class_name .. id
		end
	else
		id = object_or_obj_table['class'] .. id
	end
	
	if object_or_obj_table['attrs'] == nil then
		object_or_obj_table['attrs'] = {}
	end
	object_or_obj_table['attrs']['id'] = id
	
	return id
end

function form_iri_attributes(attrs)
	local attributes = {}
	local has_link = false
	
	if attrs['delim'] ~= nil then
		attributes['value'] = attrs['prefix']..attrs['delim']..attrs['value']
		attributes['shortValue'] = attrs['value']
		
		if attrs['delim'] == ':' then
			has_link = true
		end
	else
		attributes['value'] = attrs['value']
		attributes['shortValue'] = attrs['value']
	end
	
	attributes['id'] = attrs['id']
	
	return attributes, has_link
end

-----

function is_lQuery_col(col)
	return getmetatable(col) == getmetatable(lQuery())
end