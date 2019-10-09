module(..., package.seeall)

require "lQuery"
parser = require "OWLGrEd_Domain.parser"
gcc = require "OWLGrEd_Domain.get_create_compartment"
renderer = require "OWLGrEd_Domain.owl2_domain_renderer"
mcp = require "ManchesterParser"


function iri_valid(graph_diagram, compartment, iri_object)
	local name_comp = gcc.strict_get_compartment(compartment, "Name")
	local namespace_comp = gcc.strict_get_compartment(compartment, "Namespace")
	
	local iri_value = iri_object:attr("shortValue")
	local iri_ns_prefix = iri_object:find("/namespace"):attr("prefix")
	
	if name_comp:is_not_empty() and iri_value then
		if namespace_comp:is_not_empty() and iri_ns_prefix then
			return name_comp:attr("value") == iri_value and namespace_comp:attr("value") == iri_ns_prefix
		else
			return name_comp:attr("value") == iri_value
		end
	else
		return false
	end
end

function get_iri(graph_diagram, compartment)
	if compartment:find("/mapped.OWL#IRI"):is_not_empty() then
		return compartment:find("/mapped.OWL#IRI")
	else
		local name_comp = gcc.strict_get_compartment(compartment, "Name")
		local namespace_comp = gcc.strict_get_compartment(compartment, "Namespace")
		local name_value, namespace_value = "", ""
		if name_comp:is_not_empty() then
			name_value = name_comp:attr("value")
		end
		if namespace_comp:is_not_empty() then
			namespace_value = namespace_comp:attr("value")
		end
		
		local ontology_object = get_ontology(graph_diagram)
		local obj_table = {
			class = "OWL#IRI",
			attrs = {
				value = name_value,
				prefix = namespace_value,
				delim = ":"
			}
		}
		parser.generate_id(obj_table)
		return parser.create_iri_object(obj_table, ontology_object)
	end
end

function manchester_class_expression_valid(graph_diagram, compartment_value_str, class_expression_object)
	return compartment_value_str == renderer.render_class_expression(class_expression_object)
end

function get_manchester_class_expression(graph_diagram, compartment)
	if compartment:find("/mapped.OWL#ClassExpression"):is_not_empty() then
		return compartment:find("/mapped.OWL#ClassExpression")
	else
		local compartment_value = compartment:attr("value")
		if compartment_value ~= "" then
			local func_string = mcp.parseClassExpression(compartment_value, graph_diagram)
			local ontology_object = get_ontology(graph_diagram)
			
			return parser.parse_class_expression(func_string, ontology_object)
		else
			return lQuery("")
		end
	end
end

function get_manchester_data_property_expression(graph_diagram, compartment)
	if compartment:find("/mapped.OWL#DataPropertyExpression"):is_not_empty() then
		return compartment:find("/mapped.OWL#DataPropertyExpression")
	else
		local compartment_value = compartment:attr("value")
		if compartment_value ~= "" then
			local func_string = mcp.parseDatatypeRestriction(compartment_value, graph_diagram)
			local ontology_object = get_ontology(graph_diagram)
			
			return parser.parse_data_property_expression(func_string, ontology_object)
		else
			return lQuery("")
		end
	end
end

-----

function get_ontology(graph_diagram)
	return graph_diagram:find("/parent/mapped.OWL#IRI/ontologyIRI")
end

-----

function create_object(t, srt)
	local instance_id = get_instance_id(t['class'], t['attrs'], t['links'], srt)
	
	local instance
	if instance_id ~= "" and lQuery(t['class']):find("[id = '"..instance_id.."']"):is_not_empty() then
		instance = lQuery(t['class']):find("[id = '"..instance_id.."']")
	else
		if t['class'] == "OWL#IRI" then
			t['attrs'] = parser.form_attributes(t['attrs'])
		end
		if t['attrs'] ~= nil then
			t['attrs']['id'] = instance_id
		else
			t['attrs'] = {id = instance_id}
		end

		instance = lQuery.create(t['class'], t['attrs'])
	end
	
	if type(t['links']) == "table" then
		for link_name, inst_table in pairs(t['links']) do
			for _, inst in ipairs(inst_table) do
				instance.link(instance, link_name, inst)
			end
		end
	end
	
	return instance
end

function get_instance_id(class_name, attributes, links, srt)
	local id = ""
	-- OWL#ClassEntity -> OWL#Class
	if string.sub(class_name, -6) == "Entity" and string.len(class_name) > 10 then
		class_name = string.sub(class_name, 0, string.len(class_name)-6)
	end

	if links ~= nil then
		local id_table = {}
		for link, inst_table in pairs(links) do
			for _, sub_instance in ipairs(inst_table) do
				local sub_class_name = sub_instance:get(1):class().name
				if sub_class_name ~= "OWL#Ontology" and class_name ~= "OWL#Namespace" then
					table.insert(id_table, sub_instance:attr("id"))
					
					if srt then
						table.sort(id_table)
					end
					id = table.concat(id_table, " ")
				end
				
				if string.sub(sub_class_name, -6) == "Entity" and class_name ~= "OWL#Declaration" then
					return id
				end
			end
		end
	end
	
	if attributes ~= nil then
		local attributes_string = parser.attributes_string(attributes)
		
		if links ~= nil then
			if class_name ~= "OWL#Namespace" then
				id = " "..id
			end
			id = class_name.."("..attributes_string..id..")"
		else
			if id ~= "" then
				id = id.." "
			end
			id = id..class_name.."("..attributes_string..")"
		end
	else
		id = class_name.."("..id..")"
	end
	
	return id
end
