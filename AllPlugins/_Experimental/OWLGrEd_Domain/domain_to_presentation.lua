module(..., package.seeall)

require "lQuery"
renderer = require "OWLGrEd_Domain.owl2_domain_renderer"
compartment = require "OWLGrEd_Domain.get_create_compartment"
parser = require "OWLGrEd_Domain.parser"
require "re"

function load_and_visualize()
	if parser.load_and_parse_ontology() then
		visualize()
	end
end

function visualize()
	local ontology = lQuery("OWL#Ontology"):last()
	local graph_diagram, node = create_diagram()
	link_ontology_to_diagram(ontology, node, graph_diagram)
	add_namespaces_to_ontology_node(ontology, node)

	create_classes(rule_all_classes(ontology), graph_diagram)
	create_classes(rule_source_of_subclasses(ontology), graph_diagram)
	create_classes(rule_domain_for_properties(ontology), graph_diagram)
	create_classes(rule_range_for_object_properties(ontology), graph_diagram)
	create_classes(rule_property_restriction_target_boxes(ontology), graph_diagram)
	create_classes(rule_class_restrictions(ontology), graph_diagram)
	create_classes(rule_member_of_equivalent_classes(ontology), graph_diagram)
	create_classes(rule_member_of_disjoint_classes(ontology), graph_diagram)
	create_classes(rule_target_of_class_assertions(ontology), graph_diagram)
	--create_classes(rule_class_annotations(ontology), graph_diagram)
	--create_classes(rule_object_property_annotations(ontology), graph_diagram)
	--create_classes(rule_data_property_annotations(ontology), graph_diagram)
	--create_classes(rule_individual_annotations(ontology), graph_diagram)

	create_box_candidates(graph_diagram)
	
	add_subclassof_axioms(ontology, graph_diagram)
	add_equivalent_class_axioms(ontology, graph_diagram)
	add_disjoint_class_axioms(ontology, graph_diagram)
	add_named_individual_axioms(ontology, graph_diagram)
	add_class_assertion_axioms(ontology, graph_diagram)
	add_different_individual_axioms(ontology, graph_diagram)
	add_same_individual_axioms(ontology, graph_diagram)
	add_data_property_axioms(ontology)
	add_equivalent_data_property_axioms(ontology)
	add_disjoint_data_property_axioms(ontology)
	add_subdata_property_axioms(ontology)
	add_functional_data_property_axioms(ontology)
	add_object_property_axioms(ontology, graph_diagram)
	add_object_property_characteristics(ontology)
	add_equivalent_object_property_axioms(ontology)
	add_disjoint_object_property_axioms(ontology)
	add_subobject_property_axioms(ontology)
	add_annotation_property_axioms(ontology, graph_diagram)
	add_class_annotation_assertion_axioms(ontology, graph_diagram)
	add_object_prop_annotation_assertion_axioms(ontology, graph_diagram)
	add_data_prop_annotation_assertion_axioms(ontology, graph_diagram)
	add_individual_annotation_assertion_axioms(ontology, graph_diagram)
	add_object_property_assertion_axioms(ontology, graph_diagram)
	add_data_property_assertion_axioms(ontology, graph_diagram)
	add_datatype_axioms(ontology, graph_diagram)
	add_datatype_definition_axioms(ontology)
	add_has_key_axioms(ontology)
	
	utilities.execute_cmd("OkCmd", {graphDiagram = graph_diagram})
end

function add_box_candidate(class_expression)
	local box_candidate = class_expression:find("/boxCandidate")

	if box_candidate:is_empty() then
		local new = lQuery.create("OWL#BoxCandidate", {useCount = 1})
		class_expression.link(class_expression, "boxCandidate", new)
	else
		local use_count = box_candidate:attr("useCount") + 1
		box_candidate:attr("useCount", use_count)
	end
end

function create_diagram()
	local ontology_name = "Ontology Name"
	local graph_diagram = utilities.add_graph_diagram_to_graph_diagram_type(ontology_name, lQuery("GraphDiagramType:has([id=OWL])"))
	
	local project_diagram = lQuery("GraphDiagram:has(/graphDiagramType[id='projectDiagram'])")
	local node_type = lQuery("NodeType[id='OWL']")
	local node = core.add_node(node_type, project_diagram)
	local name_comp = compartment.create_compartment(node, "Name")
	
	core.set_compartment_value(name_comp, ontology_name)
	graph_diagram.link(graph_diagram, "parent", node)
	
	utilities.execute_cmd("OkCmd", {graphDiagram = project_diagram})
	
	return graph_diagram, node
end

function link_ontology_to_diagram(ontology, node, graph_diagram)
	local iri_instance = ontology:find("/ontologyIRI")
	local iri_value = iri_instance:attr("value")
	local prefix_comp = compartment.create_compartment(node, "Prefix")
	
	node.link(node, "mapped", iri_instance)
	core.set_compartment_value(prefix_comp, iri_value)
	
	local project_diagram = lQuery("GraphDiagram:has(/graphDiagramType[id='projectDiagram'])")
	utilities.execute_cmd("OkCmd", {graphDiagram = project_diagram})
end

function add_namespaces_to_ontology_node(ontology, node)
	ontology:find("/usedNamespace"):each(
		function(namespace_instance)
			local ns_comp = compartment.create_compartment(node, "Namespaces")
			local prefix_comp = compartment.create_compartment(ns_comp, "Prefix")
			local iri_comp = compartment.create_compartment(ns_comp, "IRI")
			
			local prefix = namespace_instance:attr("prefix")
			local iri = namespace_instance:attr("IRIprefix")
			
			core.set_compartment_value(prefix_comp, prefix)
			core.set_compartment_value(iri_comp, iri)
		end)
		
	local project_diagram = lQuery("GraphDiagram:has(/graphDiagramType[id='projectDiagram'])")
	utilities.execute_cmd("OkCmd", {graphDiagram = project_diagram})
end

----- RULES

function rule_all_classes(ontology)
	return ontology:find("/iriInOntology/entity/equivalent.OWL#Class")
end

function rule_source_of_subclasses(ontology)
	return ontology:find("/axioms.OWL#SubClassOf"):find("/subClassExpression")
end

function rule_domain_for_properties(ontology)
	return ontology:find("/axioms.OWL#ObjectPropertyDomain"):find("/domain"):add(lQuery("OWL#DataPropertyDomain"):find("/domain"))
end

function rule_range_for_object_properties(ontology)
	local op_state = get_parameter_value("Object Properties")

	if op_state == "1" then
		return ontology:find("/axioms.OWL#ObjectPropertyRange"):find("/range")
	end
end

-- TO-DO: Details...
function rule_property_restriction_target_boxes(ontology)
	local pr_state = get_parameter_value("Property Restrictions")
	local target_state = get_parameter_value("Property Restrictions Target Box")
	
	local restrictions = {
		"OWL#ObjectAllValuesFrom",
		"OWL#ObjectSomeValuesFrom",
		"OWL#ObjectMinCardinality",
		"OWL#ObjectMaxCardinality",
		"OWL#ObjectExactCardinality"
	}

	if pr_state == "1" then
		if target_state == "0" then
			local expressions
			for _, restr in ipairs(restrictions) do
				local new_expr = ontology:find("/axioms.OWL#SubClassOf"):find("/superClassExpression, /subClassExpression"):find("."..restr):find("/classExpression")
				expressions = merge(expressions, new_expr)
			end
			return expressions
			
		elseif target_state == "2" then
			for _, restr in ipairs(restrictions) do
				local expr = ontology:find("/axioms.OWL#SubClassOf"):find("/superClassExpression, /subClassExpression"):find("."..restr):find("/classExpression")
				expr:each(
					function(expression)
						add_box_candidate(expression)
					end)
			end
		end
	end
end

-- TO-DO: Extra items
function rule_class_restrictions(ontology)
	local cr_state = get_parameter_value("Class Restrictions")
	local target_state = get_parameter_value("Class Restrictions Target Box")
	local expressions
	
	if cr_state == "1" then
		if target_state == "0" then
			ontology:find("/axioms.OWL#SubClassOf"):find("/superClassExpression"):each(
				function(element)
					if not is_property_restriction(element) then
						expressions = merge(expressions, element)
					end
				end)
			return expressions
			
		elseif target_state == "2" then
			ontology:find("/axioms.OWL#SubClassOf"):find("/superClassExpression"):each(
				function(expression)
					if not is_property_restriction(element) then
						add_box_candidate(expression)
					end
				end)
		end
	end
end

function rule_member_of_equivalent_classes(ontology)
	local classes_state = get_parameter_value("Equivalent Classes")
	local group_state = get_parameter_value("Equivalent Classes Group Binary")
	local expressions
	
	if classes_state == "0" then
		if group_state == "0" then
			-- TO-DO
		elseif group_state == "1" then
			ontology:find("/axioms.OWL#EquivalentClasses"):each(
				function(eq_classes)
					local is_box = false
					eq_classes:find("/classExpressions"):each(
						function(expression)
							if not is_box and expression:find("/map"):is_not_empty() then
								is_box = true
								return
							end
						end)
					if not is_box then
						expressions = merge(expressions, eq_classes:find("/classExpressions"):first())
					end
				end)
		elseif group_state == "2" then
			-- TO-DO
		end
	elseif classes_state == "1" then
		if group_state == "0" then
			-- TO-DO
		elseif group_state == "1" then
			ontology:find("/axioms.OWL#EquivalentClasses"):each(
				function(eq_classes)
					if eq_classes:find("/classExpressions"):size() > 2 then
						expressions = merge(expressions, eq_classes:find("/classExpressions"))
					else
						local first = eq_classes:find("/classExpressions"):first()
						local last = eq_classes:find("/classExpressions"):last()
						local first_class_name = first:get(1):class().name
						local last_class_name = last:get(1):class().name
						
						if first_class_name == "OWL#Class" and last_class_name ~= "OWL#Class" then
							expressions = merge(expressions, first)
						elseif last_class_name == "OWL#Class" and first_class_name ~= "OWL#Class" then
							expressions = merge(expressions, last)
						else
							expressions = merge(expressions, first:add(last))
						end
					end
				end)
		elseif group_state == "2" then
			-- TO-DO
		end
	elseif classes_state == "2" then
		-- TO-DO
	end
	
	return expressions
end

function rule_member_of_disjoint_classes(ontology)
	local classes_state = get_parameter_value("Disjoint Classes")
	local group_state = get_parameter_value("Disjoint Classes Group Binary")
	local target_state = get_parameter_value("Disjoint Classes Target")
	local expressions
	
	if classes_state == "0" then
		if group_state == "0" then
			-- TO-DO
		elseif group_state == "1" then
			ontology:find("/axioms.OWL#DisjointClasses"):each(
				function(dj_classes)
					local is_box = false
					dj_classes:find("/classExpressions"):each(
						function(expression)
							if not is_box and expression:find("/map"):is_not_empty() then
								is_box = true
								return
							end
						end)
					if not is_box then
						expressions = merge(expressions, dj_classes:find("/classExpressions"):first())
					end
				end)
		elseif group_state == "2" then
			-- TO-DO
		end
	elseif classes_state == "1" then
		if group_state == "0" then
			-- TO-DO
		elseif group_state == "1" then
			ontology:find("/axioms.OWL#DisjointClasses"):each(
				function(dj_classes)
					if dj_classes:find("/classExpressions"):size() > 2 then
						expressions = merge(expressions, dj_classes:find("/classExpressions"))
					else
						local first = dj_classes:find("/classExpressions"):first()
						local last = dj_classes:find("/classExpressions"):last()
						local first_class_name = first:get(1):class().name
						local last_class_name = last:get(1):class().name
						
						if target_state == "0" then
							expressions = merge(expressions, first:add(last))
						elseif first_class_name == "OWL#Class" and last_class_name ~= "OWL#Class" then
							if target_state == "1" then
								expressions = merge(expressions, first)
							elseif target_state == "2" then
								expressions = merge(expressions, first)
								add_box_candidate(last)
							end
						elseif last_class_name == "OWL#Class" and first_class_name ~= "OWL#Class" then
							if target_state == "1" then
								expressions = merge(expressions, last)
							elseif target_state == "2" then
								expressions = merge(expressions, last)
								add_box_candidate(first)
							end
						else
							-- target ~= "0" and both classes are OWL#Class or OWL#ClassExpression
							expressions = merge(expressions, first:add(last))
						end
					end
				end)
		elseif group_state == "2" then
			-- TO-DO
		end
	elseif classes_state == "2" then
		-- TO-DO
	end
	
	return expressions
end

function rule_target_of_class_assertions(ontology)
	local assertion_state = get_parameter_value("Class Assertions")
	local target_state = get_parameter_value("Class Assertions Class")
	local expressions
	
	if assertion_state == "1" then
		if target_state == "0" then
			return ontology:find("/axioms.OWL#ClassAssertion"):find("/classExpression")
			
		elseif target_state == "2" then
			ontology:find("/axioms.OWL#ClassAssertion"):find("/classExpression"):each(
				function(element)
					add_box_candidate(element)
				end)
		end
	end
end

function rule_class_annotations(ontology)
	ca_state = get_parameter_value("Class Annotations")
	
	if ca_state == "1" then
		return ontology:find("/iriInOntology/entity.OWL#ClassEntity"):find("/entityIRI/annotationSubject/annotationAssertion")
	end
end

function rule_object_property_annotations(ontology)
	opa_state = get_parameter_value("Object Properties Annotations")
	
	if opa_state == "1" then
		return ontology:find("/iriInOntology/entity.OWL#ObjectPropertyEntity"):find("/entityIRI/annotationSubject/annotationAssertion")
	end
end

function rule_data_property_annotations(ontology)
	dpa_state = get_parameter_value("Data Properties Annotations")
	
	if dpa_state == "1" then
		return ontology:find("/iriInOntology/entity.OWL#DataPropertyEntity"):find("/entityIRI/annotationSubject/annotationAssertion")
	end
end

function rule_individual_annotations(ontology)
	ia_state = get_parameter_value("Individuals Annotations")
	
	if ia_state == "1" then
		return ontology:find("/iriInOntology/entity.OWL#NamedIndividualEntity"):find("/entityIRI/annotationSubject/annotationAssertion")
	end
end

-----

function merge(old, new)
	if old == nil then
		return new:unique()
	elseif new == nil then
		return old:unique()
	end
	
	new:each(
		function(element)
			old = old:add(element)
		end)
	return old:unique()
end

function is_named_class(class_expression)
	if class_expression:get(1):class().name == "OWL#Class" then
		return true
	else
		return false
	end
end

function is_property_restriction(class_expression)
	local class_name = class_expression:get(1):class().name
	local restrictions = {
		"OWL#ObjectAllValuesFrom",
		"OWL#ObjectSomeValuesFrom",
		"OWL#ObjectMinCardinality",
		"OWL#ObjectMaxCardinality",
		"OWL#ObjectExactCardinality"
	}
	
	for _, restr in ipairs(restrictions) do
		if class_name == restr then
			return true
		end
	end
	return false
end

function get_property_restriction_type(class_expression)
	local class_name = class_expression:get(1):class().name
	if class_name == "OWL#ObjectAllValuesFrom" then
		return "only"
	elseif class_name == "OWL#ObjectSomeValuesFrom" then
		return "some"
	elseif class_name == "OWL#ObjectMinCardinality" then
		return "min"
	elseif class_name == "OWL#ObjectMaxCardinality" then
		return "max"
	elseif class_name == "OWL#ObjectExactCardinality" then
		return "exactly"
	end
	return nil
end

----------

function create_box_candidates(graph_diagram)
	lQuery("OWL#BoxCandidate"):each(
		function(element)
			if tonumber(element:attr("useCount")) > 1 then
				create_classes(element:find("/classExpression"), graph_diagram)
				element.delete(element)
			end
		end)
end

-----

function create_classes(classes, graph_diagram)
	if classes == nil then
		return
	end

	classes:each(
		function(class)
			if class:find("/map:has(/elemType[id='Class'])"):is_not_empty() then
				return
			end
			
			if is_named_class(class) then
				create_named_class(class, graph_diagram)
			else
				create_anonymous_class(class, graph_diagram)
			end
		end)
end

function create_named_class(class, graph_diagram)
	local declaration_instance = class:find("/equivalent/declaration")
	local class_name, class_namespace, iri_instance, entity_instance = renderer.render_class_expression(class)
	
	local node = core.add_node(lQuery("NodeType[id='Class']"), graph_diagram)
	local upper_name_comp = compartment.create_compartment(node, "Name")
	local name_comp = compartment.create_compartment(upper_name_comp, "Name")
	local namespace_comp = compartment.create_compartment(upper_name_comp, "Namespace")
	
	core.set_compartment_value(name_comp, class_name)
	core.set_compartment_value(namespace_comp, class_namespace)
	
	node.link(node, "mapped", declaration_instance)
	node.link(node, "mapped", class)
	upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
	upper_name_comp.link(upper_name_comp, "mappedC", entity_instance)
end

function create_anonymous_class(class_expression, graph_diagram)
	local expression_value, ns, iris, entity_instances = renderer.render_class_expression(class_expression)
	
	local node = core.add_node(lQuery("NodeType[id='Class']"), graph_diagram)
	local expression_comp = compartment.create_compartment(node, "EquivalentClasses/EquivalentClass/Expression")
	
	core.set_compartment_value(expression_comp, expression_value)
	
	node.link(node, "mapped", class_expression)
	expression_comp.link(expression_comp, "mapped", class_expression)
	for _, entity in ipairs(entity_instances) do
		expression_comp.link(expression_comp, "mappedC", entity)
	end
end

-----
function add_subclassof_axioms(ontology, graph_diagram)
	local crf_state = get_parameter_value("Class Restrictions Fork")
	local cr_state = get_parameter_value("Class Restrictions")
	local pr_state = get_parameter_value("Property Restrictions")
	
	if cr_state == "1" and crf_state == "1" then
		add_subclasses_by_fork(ontology, graph_diagram)
	end
	
	ontology:find("/axioms.OWL#SubClassOf"):each(
		function(element)
			if element:find("/map"):is_not_empty() then
				return
			end
		
			local sub_class_node = element:find("/subClassExpression/map:has(/elemType[id='Class'])")
			local super_class_node = element:find("/superClassExpression/map:has(/elemType[id='Class'])")
			local super_class_expression = element:find("/superClassExpression")
			
			if pr_state == "1" and is_property_restriction(super_class_expression)
					and super_class_expression:find("/classExpression/map"):is_not_empty() then -- property restrictions, use graphics
				super_class_node = super_class_expression:find("/classExpression/map")
				add_property_restriction_link(sub_class_node, super_class_node, super_class_expression, element, graph_diagram)
				
			elseif cr_state == "1" and sub_class_node:is_not_empty() and super_class_node:is_not_empty() then -- class restrictions, use graphics
				add_generalization_link(sub_class_node, super_class_node, element, graph_diagram)
				
			elseif super_class_node:is_empty() or cr_state == "0" then -- compartment
				add_superclass_compartment(sub_class_node, element)
			end
		end)
end

function add_property_restriction_link(sub_class_node, super_class_node, expression, sub_class_of_axiom, graph_diagram)
	local edge_type = lQuery("EdgeType[id='Restriction']")
	local some, only, multiplicity = "", "", ""
	if get_property_restriction_type(expression) == "some" then
		some = "some"
	elseif get_property_restriction_type(expression) == "only" then
		only = "only"
	elseif get_property_restriction_type(expression) == "min" then
		multiplicity = expression:attr("cardinality").."..*"
	elseif get_property_restriction_type(expression) == "max" then
		multiplicity = "0.."..expression:attr("cardinality")
	elseif get_property_restriction_type(expression) == "exactly" then
		multiplicity = expression:attr("cardinality")
	end
	
	if sub_class_node:is_not_empty() and super_class_node:is_not_empty() then
		local role, namespace, iri_instance, entity_instance = renderer.render_object_property_expression(expression:find("/objectPropertyExpression"))
		local edge = core.add_edge(edge_type, sub_class_node, super_class_node, graph_diagram)
		local role_comp = compartment.create_compartment(edge, "Name/Role")
		local namespace_comp = compartment.create_compartment(edge, "Name/Namespace")
		local only_comp = compartment.create_compartment(edge, "Only")
		local some_comp = compartment.create_compartment(edge, "Some")
		local multiplicity_comp = compartment.create_compartment(edge, "Multiplicity")
		
		core.set_compartment_value(role_comp, role)
		core.set_compartment_value(namespace_comp, namespace)
		core.set_compartment_value(only_comp, only)
		core.set_compartment_value(some_comp, some)
		core.set_compartment_value(multiplicity_comp, multiplicity)
		
		edge.link(edge, "mapped", expression)
		edge.link(edge, "mapped", sub_class_of_axiom)
		role_comp.link(role_comp, "mappedC", entity_instance)
	end
end

function add_generalization_link(sub_class_node, super_class_node, sub_class_of_axiom, graph_diagram)
	local edge_type = lQuery("EdgeType[id='Generalization']")
	local edge = core.add_edge(edge_type, sub_class_node, super_class_node, graph_diagram)
	
	edge.link(edge, "mapped", sub_class_of_axiom)
end

function add_superclass_compartment(class_node, sub_class_of_axiom)
	local super_class_expression = sub_class_of_axiom:find("/superClassExpression")
	local expression_value, ns, iris, entity_instances = renderer.render_class_expression(super_class_expression)
	local super_classes_comp = compartment.create_compartment(class_node, "SuperClasses")
	local expression_comp = compartment.create_compartment(super_classes_comp, "Expression")
	
	core.set_compartment_value(expression_comp, expression_value)
	
	expression_comp.link(expression_comp, "mapped", sub_class_of_axiom)
	expression_comp.link(expression_comp, "mapped", super_class_expression)
	for _, entity in ipairs(entity_instances) do
		expression_comp.link(expression_comp, "mappedC", entity)
	end
end

function add_subclasses_by_fork(ontology, graph_diagram)
	local fork_type = lQuery("NodeType[id='HorizontalFork']")
	local assoc_type = lQuery("EdgeType[id='AssocToFork']")
	local gen_type = lQuery("EdgeType[id='GeneralizationToFork']")

	ontology:find("/axioms.OWL#SubClassOf"):find("/superClassExpression:has(/subClassAxiom):has(/map:has(/elemType[id='Class']))"):each(
		function(super_class)
			local subclass_axioms = super_class:find("/subClassAxiom")
			if subclass_axioms:find("/map"):is_not_empty() then
				return
			end
			
			if subclass_axioms:size() > 1 then
				local fork = core.add_node(fork_type, graph_diagram)
				local generalization = core.add_edge(gen_type, fork, super_class:find("/map"), graph_diagram)
				
				subclass_axioms:each(
					function(subclass_axiom)
						local sub_class = subclass_axiom:find("/subClassExpression")
						local association = core.add_edge(assoc_type, sub_class:find("/map"), fork, graph_diagram)
						--association.link(association, "mapped", sub_class)
						--fork.link(fork, "mapped", subclass_axiom)
						
						association:link("mapped", subclass_axiom)
					end)
			end
		end)
end

-----

function add_equivalent_class_axioms(ontology, graph_diagram)
	local classes_state = get_parameter_value("Equivalent Classes")
	
	ontology:find("/axioms.OWL#EquivalentClasses"):each(
		function(element)
			if element:find("/map"):is_not_empty() then
				return
			end
		
			if classes_state == "1" then -- use graphics
				if element:find("/classExpressions"):size() > 2 then -- equivalent classes box
					add_equivalent_box(element, graph_diagram)
				else -- equivalent classes link
					local first = element:find("/classExpressions"):first():find("/map:has(/elemType[id='Class'])")
					local last = element:find("/classExpressions"):last():find("/map:has(/elemType[id='Class'])")
					
					if first:is_not_empty() and last:is_not_empty() then
						add_equivalent_link(first, last, element, graph_diagram)
						
					elseif first:is_empty() then
						add_equivalent_class_compartments(last, element:find("/classExpressions"):first(), element)
						
					elseif last:is_empty() then
						add_equivalent_class_compartments(first, element:find("/classExpressions"):last(), element)
						
					end
				end
			else -- no graphics
				element:find("/classExpressions:has(/map:has(/elemType[id='Class']))"):each(
					function(expression)
						local node = expression:find("/map:has(/elemType[id='Class'])")
						add_equivalent_class_compartments(node, element:find("/classExpressions"):remove(expression), element)
					end)
			end
		end)
end

function add_equivalent_class_compartments(node, expressions, equivalent_class_axiom)
	local equivalent_classes_comp = compartment.create_compartment(node, "EquivalentClasses")
	local expression_value, ns, iris, entity_instances
	local expression_comp
	
	expressions:each(
		function(expression)
			expression_value, ns, iris, entity_instances = renderer.render_class_expression(expression)
			expression_comp = compartment.create_compartment(equivalent_classes_comp, "EquivalentClass/Expression")
			
			core.set_compartment_value(expression_comp, expression_value)
			
			expression_comp.link(expression_comp, "mapped", expression)
		end)
	
	equivalent_classes_comp.link(equivalent_classes_comp, "mapped", equivalent_class_axiom)
	for _, entity in ipairs(entity_instances) do
		expression_comp.link(expression_comp, "mappedC", entity)
	end
end

function add_equivalent_box(equivalent_class_axiom, graph_diagram)
	local node_type = lQuery("NodeType[id='EquivalentClasses']")
	local edge_type = lQuery("EdgeType[id='Line']")
	local box = core.add_node(node_type, graph_diagram)
	local label_comp = compartment.create_compartment(box, "Label")
	
	core.set_compartment_value(label_comp, "equivalent")
	
	equivalent_class_axiom:find("/classExpressions/map:has(/elemType[id='Class'])"):each(
		function(node)
			core.add_edge(edge_type, box, node, graph_diagram)
		end)
	
	box.link(box, "mapped", equivalent_class_axiom)
end

function add_equivalent_link(first_node, second_node, equivalent_class_axiom, graph_diagram)
	local edge_type = lQuery("EdgeType[id='EquivalentClass']")
	local edge = core.add_edge(edge_type, first_node, second_node, graph_diagram)
	local label_comp = compartment.create_compartment(edge, "Label")
	
	core.set_compartment_value(label_comp, "equivalent")
	
	edge.link(edge, "mapped", equivalent_class_axiom)
end

-----

function add_disjoint_class_axioms(ontology, graph_diagram)
	local classes_state = get_parameter_value("Disjoint Classes")

	local link_type = lQuery("ElemType[id='Disjoint']")
	local box_type = lQuery("ElemType[id='DisjointClasses']")
	local link_to_box_type = lQuery("ElemType[id='Line']")
	local compartments_table = {Label = "disjoint"}
	
	ontology:find("/axioms.OWL#DisjointClasses"):each(
		function(element)
			if element:find("/map"):is_not_empty() then
				return
			end
		
			if classes_state == "1" then -- use graphics
				if element:find("/classExpressions"):size() > 2 then -- disjoint box
					add_disjoint_box(element, graph_diagram)
				else -- disjoint link
					local first = element:find("/classExpressions"):first():find("/map:has(/elemType[id='Class'])")
					local last = element:find("/classExpressions"):last():find("/map:has(/elemType[id='Class'])")
					
					if first:is_not_empty() and last:is_not_empty() then
						add_disjoint_link(first, last, element, graph_diagram)
						
					elseif first:is_empty() then
						add_disjoint_class_compartments(last, element:find("/classExpressions"):first(), element)
						
					elseif last:is_empty() then
						add_disjoint_class_compartments(first, element:find("/classExpressions"):last(), element)
						
					end
				end
			else -- no graphics
				element:find("/classExpressions:has(/map:has(/elemType[id='Class']))"):each(
					function(expression)
						local node = expression:find("/map:has(/elemType[id='Class'])")
						add_disjoint_class_compartments(node, element:find("/classExpressions"):remove(expression), element)
					end)
			end
		end)
end

function add_disjoint_class_compartments(node, expressions, disjoint_class_axiom)
	local disjoint_classes_comp = compartment.create_compartment(node, "DisjointClasses")
	local expression_value, ns, iris, entity_instances
	local expression_comp
	
	expressions:each(
		function(expression)
			expression_value, ns, iris, entity_instances = renderer.render_class_expression(expression)
			expression_comp = compartment.create_compartment(disjoint_classes_comp, "DisjointClass/Expression")
			
			core.set_compartment_value(expression_comp, expression_value)
			
			expression_comp.link(expression_comp, "mapped", expression)
		end)
	
	disjoint_classes_comp.link(disjoint_classes_comp, "mapped", disjoint_class_axiom)
	for _, entity in ipairs(entity_instances) do
		expression_comp.link(expression_comp, "mappedC", entity)
	end
end

function add_disjoint_box(disjoint_class_axiom, graph_diagram)
	local node_type = lQuery("NodeType[id='DisjointClasses']")
	local edge_type = lQuery("EdgeType[id='Line']")
	local box = core.add_node(node_type, graph_diagram)
	local label_comp = compartment.create_compartment(box, "Label")
	
	core.set_compartment_value(label_comp, "disjoint")
	
	disjoint_class_axiom:find("/classExpressions/map:has(/elemType[id='Class'])"):each(
		function(node)
			core.add_edge(edge_type, box, node, graph_diagram)
		end)
	
	box.link(box, "mapped", disjoint_class_axiom)
end

function add_disjoint_link(first_node, second_node, disjoint_class_axiom, graph_diagram)
	local edge_type = lQuery("EdgeType[id='Disjoint']")
	local edge = core.add_edge(edge_type, first_node, second_node, graph_diagram)
	local label_comp = compartment.create_compartment(edge, "Label")
	
	core.set_compartment_value(label_comp, "disjoint")
	
	edge.link(edge, "mapped", disjoint_class_axiom)
end

-----

function add_named_individual_axioms(ontology, graph_diagram)
	local node_type = lQuery("NodeType[id='Object']")
	
	ontology:find("/iriInOntology/entity/equivalent.OWL#NamedIndividual"):each(
		function(individual)
			local object_name, object_namespace, iri_instance, entity_instance = renderer.render_individual_expression(individual)
			local node = core.add_node(node_type, graph_diagram)
			
			local upper_name_comp = compartment.create_compartment(node, "Title/Name")
			local name_comp = compartment.create_compartment(upper_name_comp, "Name")
			local namespace_comp = compartment.create_compartment(upper_name_comp, "Namespace")
			local kols_comp = compartment.create_compartment(node, "Title/Kols")
			
			core.set_compartment_value(name_comp, object_name)
			core.set_compartment_value(namespace_comp, object_namespace)
			core.set_compartment_value(kols_comp, ":")
			
			node.link(node, "mapped", individual)
			upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
			upper_name_comp.link(upper_name_comp, "mappedC", entity_instance)
		end)
end

function add_class_assertion_axioms(ontology, graph_diagram)
	local ca_state = get_parameter_value("Class Assertions")
	local text_state = get_parameter_value("Class Assertions Text")
	
	ontology:find("/axioms.OWL#ClassAssertion"):each(
		function(assertion_axiom)
			local node = assertion_axiom:find("/individual/map:has(/elemType[id='Object'])")
			local class_expression = assertion_axiom:find("/classExpression")
			
			if ca_state == "0" or text_state == "0" then
				add_object_class_name(node, class_expression, assertion_axiom)
			end
			
			if ca_state == "1" then
				local class_node = assertion_axiom:find("/classExpression/map:has(/elemType[id='Class'])")
				add_dependency_link(node, class_node, assertion_axiom, graph_diagram)
			end
		end)
end

function add_object_class_name(node, class_expression, class_assertion_axiom)
	local class_name, class_namespace, iri_instance, entity_instance = renderer.render_class_expression(class_expression)
	local class_name_comp = compartment.create_compartment(node, "Title/ClassName")
	
	core.set_compartment_value(class_name_comp, class_name)
	
	class_name_comp.link(class_name_comp, "mapped", class_assertion_axiom)
	class_name_comp.link(class_name_comp, "mapped", class_expression)
	class_name_comp.link(class_name_comp, "mapped", entity_instance)
	
	-- vçlâk bûs jâsalinko upper_name_comp ar iri_instance un entity_instance
	-- (droði vien tad, kad bûs nevis viens Compartments ClassName, bet Name/Name un Name/Namespace)
end

function add_dependency_link(individual_node, class_node, class_assertion_axiom, graph_diagram)
	local edge_type = lQuery("EdgeType[id='Dependency']")
	local edge = core.add_edge(edge_type, individual_node, class_node, graph_diagram)
	local label_comp = compartment.create_compartment(edge, "Label")
	
	core.set_compartment_value(label_comp, "instanceOf")
	
	edge.link(edge, "mapped", class_assertion_axiom)
end

-----

function add_different_individual_axioms(ontology, graph_diagram)
	local di_state = get_parameter_value("Different Individuals")
	
	ontology:find("/axioms.OWL#DifferentIndividuals"):each(
		function(element)
			local individuals = element:find("/individuals")
			
			if di_state == "0" then -- no graphics
				individuals:each(
					function(individual)
						local object = individual:find("/map:has(/elemType[id='Object'])")
						add_different_individual_compartment(object, individuals:remove(individual), element)
					end)
				
			elseif di_state == "1" then -- use graphics
				if individuals:size() > 2 then -- box
					add_different_individual_box(individuals, element, graph_diagram)
					
				else -- link
					local first_node = individuals:first():find("/map:has(/elemType[id='Object'])")
					local second_node = individuals:last():find("/map:has(/elemType[id='Object'])")
					
					add_different_individual_link(first_node, second_node, element, graph_diagram)
				end
			end
		end)
end

function add_different_individual_compartment(node, expressions, different_individual_axiom)
	local value = ""
	expressions:each(
		function(expression)
			value, ns, iri, entity_instance = value..renderer.render_individual_expression(expression)..", "
		end)
	value = string.sub(value, 1, string.len(value)-2)
	
	local different_comp = compartment.create_compartment(node, "DifferentIndividuals")
	
	core.set_compartment_value(different_comp, value)
	
	different_comp.link(different_comp, "mapped", different_individual_axiom)
	different_comp.link(different_comp, "mappedC", entity_instance)
end

function add_different_individual_box(individuals, different_individual_axiom, graph_diagram)
	local node_type = lQuery("NodeType[id='DifferentIndivids']")
	local edge_type = lQuery("EdgeType[id='Line']")
	local node = core.add_node(node_type, graph_diagram)
	local label_comp = compartment.create_compartment(node, "Label")
	
	core.set_compartment_value(label_comp, "different")
	
	individuals:each(
		function(individual)
			local object = individual:find("/map:has(/elemType[id='Object'])")
			core.add_edge(edge_type, node, object, graph_diagram)
		end)
	
	node.link(node, "mapped", different_individual_axiom)
end

function add_different_individual_link(first_node, second_node, different_individual_axiom, graph_diagram)
	local edge_type = lQuery("EdgeType[id='DifferentIndivid']")
	local edge = core.add_edge(edge_type, first_node, second_node, graph_diagram)
	local label_comp = compartment.create_compartment(edge, "Label")
	
	core.set_compartment_value(label_comp, "different")
	
	edge.link(edge, "mapped", different_individual_axiom)
end

-----

function add_same_individual_axioms(ontology, graph_diagram)
	local si_state = get_parameter_value("Same Individuals")
	
	ontology:find("/axioms.OWL#SameIndividual"):each(
		function(element)
			local individuals = element:find("/individuals")
			
			if si_state == "0" then -- no graphics
				individuals:each(
					function(individual)
						local object = individual:find("/map:has(/elemType[id='Object'])")
						add_same_individual_compartment(object, individuals:remove(individual), element)
					end)
				
			elseif si_state == "1" then -- use graphics
				if individuals:size() > 2 then -- box
					add_same_individual_box(individuals, element, graph_diagram)
					
				else -- link
					local first_node = individuals:first():find("/map:has(/elemType[id='Object'])")
					local second_node = individuals:last():find("/map:has(/elemType[id='Object'])")
					
					add_same_individual_link(first_node, second_node, element, graph_diagram)
				end
			end
		end)
end

function add_same_individual_compartment(node, expressions, same_individual_axiom)
	local value = ""
	expressions:each(
		function(expression)
			value, ns, iri, entity_instance = value..renderer.render_individual_expression(expression)..", "
		end)
	value = string.sub(value, 1, string.len(value)-2)
	
	local same_comp = compartment.create_compartment(node, "SameIndividuals")
	
	core.set_compartment_value(same_comp, value)
	
	same_comp.link(same_comp, "mapped", same_individual_axiom)
	same_comp.link(same_comp, "mappedC", entity_instance)
end

function add_same_individual_box(individuals, same_individual_axiom, graph_diagram)
	local node_type = lQuery("NodeType[id='SameAsIndivids']")
	local edge_type = lQuery("EdgeType[id='Line']")
	local node = core.add_node(node_type, graph_diagram)
	local label_comp = compartment.create_compartment(node, "Label")
	
	core.set_compartment_value(label_comp, "sameAs")
	
	individuals:each(
		function(individual)
			local object = individual:find("/map:has(/elemType[id='Object'])")
			core.add_edge(edge_type, node, object, graph_diagram)
		end)
	
	node.link(node, "mapped", same_individual_axiom)
end

function add_same_individual_link(first_node, second_node, same_individual_axiom, graph_diagram)
	local edge_type = lQuery("EdgeType[id='SameAsIndivid']")
	local edge = core.add_edge(edge_type, first_node, second_node, graph_diagram)
	local label_comp = compartment.create_compartment(edge, "Label")
	
	core.set_compartment_value(label_comp, "sameAs")
	
	edge.link(edge, "mapped", same_individual_axiom)
end

-----

function add_data_property_axioms(ontology)
	ontology:find("/iriInOntology/entity/equivalent.OWL#DataProperty"):each(
		function(data_property_axiom)
			if data_property_axiom:find("/map:has(/compartType[id='Attributes'])"):is_not_empty() then
				return
			end
		
			local domain_axiom = data_property_axiom:find("/dataPropertyDomain")
			local domain_expression = domain_axiom:find("/domain")
			local range_expression = data_property_axiom:find("/dataPropertyRange/range")
			
			domain_expression:find("/map:has(/elemType[id='Class'])"):each(
				function(node)
					add_data_attribute(node, domain_axiom, range_expression, data_property_axiom)
				end)
		end)
end

function add_data_attribute(node, domain_axiom, range_expression, data_property_axiom)
	local property_name, property_namespace, iri_instance, entity_instance = renderer.render_data_property_expression(data_property_axiom)
	local range_value, range_namespace, iris, entity_instances = renderer.render_data_range(range_expression)
	if #iris > 1 then
		range_value = "("..range_value..")"
	end
	
	local declaration_instance = data_property_axiom:find("/equivalent/declaration")
	
	local attribute_comp = compartment.create_compartment(node, "Attributes")
	local upper_name_comp = compartment.create_compartment(attribute_comp, "Name")
	local name_comp = compartment.create_compartment(upper_name_comp, "Name")
	local namespace_comp = compartment.create_compartment(upper_name_comp, "Namespace")
	local type_comp = compartment.create_compartment(attribute_comp, "Type")
	local type_value_comp = compartment.create_compartment(type_comp, "Type")
	local type_namespace_comp = compartment.create_compartment(type_comp, "Namespace")
	
	core.set_compartment_value(name_comp, property_name)
	core.set_compartment_value(namespace_comp, property_namespace)
	core.set_compartment_value(type_value_comp, range_value)
	core.set_compartment_value(type_namespace_comp, range_namespace)
	
	attribute_comp.link(attribute_comp, "mapped", data_property_axiom)
	attribute_comp.link(attribute_comp, "mapped", domain_axiom)
	attribute_comp.link(attribute_comp, "mapped", declaration_instance)
	upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
	type_comp.link(type_comp, "mapped", range_expression)
	for _, entity in ipairs(entity_instances) do
		upper_name_comp.link(upper_name_comp, "mappedC", entity)
	end
end

-----

function add_equivalent_data_property_axioms(ontology)
	add_eq_or_dj_data_property_axioms(ontology:find("/axioms.OWL#EquivalentDataProperties"), "EquivalentProperties/EquivalentProperties")
end

function add_disjoint_data_property_axioms(ontology)
	add_eq_or_dj_data_property_axioms(ontology:find("/axioms.OWL#DisjointDataProperties"), "DisjointProperties/DisjointProperties")
end

function add_eq_or_dj_data_property_axioms(eq_or_dj_property_axioms, property_comp_path)
	eq_or_dj_property_axioms:each(
		function(data_prop_axiom)
			if data_prop_axiom:find("/map"):is_not_empty() then
				return
			end
			
			local properties = data_prop_axiom:find("/dataPropertyExpressions")
			
			properties:each(
				function(property)
					local attribute_comp = property:find("/map:has(/compartType[id='Attributes'])")
					if attribute_comp:is_not_empty() then
						add_eq_or_dj_data_property(attribute_comp, properties:remove(property), data_prop_axiom, property_comp_path)
					end
				end)
		end)
end

function add_eq_or_dj_data_property(attribute_comp, properties, data_prop_axiom, property_comp_path)
	properties:each(
		function(property)
			local property_name, ns, iri, entity_instance = renderer.render_data_property_expression(property)
			local properties_comp = compartment.create_compartment(attribute_comp, property_comp_path)
			local expression_comp = compartment.create_compartment(properties_comp, "Expression")
			
			core.set_compartment_value(expression_comp, property_name)
			
			properties_comp.link(properties_comp, "mapped", data_prop_axiom)
			expression_comp.link(expression_comp, "mappedC", entity_instance)
		end)
end

-----

function add_subdata_property_axioms(ontology)
	ontology:find("/axioms.OWL#SubDataPropertyOf"):each(
		function(sub_data_prop_of_axiom)
			if sub_data_prop_of_axiom:find("/map"):is_not_empty() then
				return
			end
			
			local super_property = sub_data_prop_of_axiom:find("/superDataPropertyExpression")
			local sub_property = sub_data_prop_of_axiom:find("/subDataPropertyExpression")
			local attribute_comp = sub_property:find("/map:has(/compartType[id='Attributes'])")
			
			if attribute_comp:is_not_empty() then
				add_super_data_property(attribute_comp, super_property, sub_data_prop_of_axiom)
			end
		end)
end

function add_super_data_property(attribute_comp, super_property, sub_data_prop_of_axiom)
	local property_name, ns, iri, entity_instance = renderer.render_data_property_expression(super_property)
	local super_properties_comp = compartment.create_compartment(attribute_comp, "SuperProperties/SuperProperties")
	local expression_comp = compartment.create_compartment(super_properties_comp, "Expression")
	
	core.set_compartment_value(expression_comp, property_name)
	
	super_properties_comp.link(super_properties_comp, "mapped", sub_data_prop_of_axiom)
	expression_comp.link(expression_comp, "mappedC", entity_instance)
end

-----

function add_functional_data_property_axioms(ontology)
	ontology:find("/axioms.OWL#FunctionalDataProperty"):each(
		function(axiom)
			local property = axiom:find("/dataPropertyExpression")
			local attribute_comp = property:find("/map:has(/compartType[id='Attributes'])")
			local is_func_comp = compartment.create_compartment(attribute_comp, "IsFunctional")
			
			core.set_compartment_value(is_func_comp, "func")
			
			is_func_comp.link(is_func_comp, "mapped", axiom)
		end)
end

-----

function add_object_property_axioms(ontology, graph_diagram)
	local op_state = get_parameter_value("Object Properties")
	local opm_state = get_parameter_value("Object Properties Merge")
	
	if op_state == "1" and opm_state == "0" then
		add_inverse_properties_as_links(ontology, graph_diagram)
	end
	
	add_object_properties(ontology, graph_diagram)
end

-----

function add_object_properties(ontology, graph_diagram)
	local op_state = get_parameter_value("Object Properties")
	
	ontology:find("/iriInOntology/entity/equivalent.OWL#ObjectProperty"):each(
		function(property_axiom)
			if op_state == "0" then -- no graphics
				if property_axiom:find("/map:has(/compartType[id='Attributes'])"):is_empty() then
					add_object_property_as_compartment(property_axiom, graph_diagram)
				end
				
			elseif op_state == "1" then -- use graphics
				if property_axiom:find("/map:has(/compartType[id='Role'], /compartType[id='InvRole'])"):is_empty() then
					add_object_property_as_link(property_axiom, graph_diagram)
				end
			end
		end)
end

function add_inverse_properties_as_links(ontology, graph_diagram)
	ontology:find("/axioms.OWL#InverseObjectProperties"):each( -- add inverse properties
		function(inverse_prop_axiom)
			first_property = inverse_prop_axiom:find("/objectPropertyExpression1")
			second_property = inverse_prop_axiom:find("/objectPropertyExpression2")
			
			local domain_path = "/objectPropertyDomain/domain/map:has(/elemType[id='Class'])"
			local range_path = "/objectPropertyRange/range/map:has(/elemType[id='Class'])"
			
			domain_node = merge(first_property:find(domain_path), second_property:find(range_path))
			range_node = merge(first_property:find(range_path), second_property:find(domain_path))
			
			local association = add_object_property_as_link(first_property, graph_diagram)
			
			add_inverse_object_property(association, second_property, inverse_prop_axiom)
		end)
end

function add_object_property_as_compartment(property_axiom, graph_diagram)
	if property_axiom:find("/objectPropertyDomain"):is_empty() then
		return
	end
	
	local property_name, property_namespace, iri_instance, entity_instance = renderer.render_object_property_expression(property_axiom)

	local domain_node = property_axiom:find("/objectPropertyDomain/domain/map:has(/elemType[id='Class'])")
	local range_value, range_namespace, iris, entity_instances = renderer.render_class_expression(property_axiom:find("/objectPropertyRange/range"))
	if #iris > 1 then
		range_value = "("..range_value..")"
	end
	
	local attribute_comp = compartment.create_compartment(domain_node, "Attributes")
	local upper_name_comp = compartment.create_compartment(attribute_comp, "Name")
	local name_comp = compartment.create_compartment(upper_name_comp, "Name")
	local namespace_comp = compartment.create_compartment(upper_name_comp, "Namespace")
	local type_comp = compartment.create_compartment(attribute_comp, "Type")
	local type_value_comp = compartment.create_compartment(type_comp, "Type")
	local type_namespace_comp = compartment.create_compartment(type_comp, "Namespace")
	
	core.set_compartment_value(name_comp, property_name)
	core.set_compartment_value(namespace_comp, property_namespace)
	core.set_compartment_value(type_value_comp, range_value)
	core.set_compartment_value(type_namespace_comp, range_namespace)
	
	attribute_comp:link("mapped", property_axiom)
	attribute_comp:link("mapped", property_axiom:find("/objectPropertyDomain"))
	attribute_comp:link("mapped", property_axiom:find("/equivalent/declaration"))
	upper_name_comp:link("mapped", iri_instance)
	type_comp:link("mapped", property_axiom:find("/objectPropertyRange/range"))
	for _, entity in ipairs(entity_instances) do
		upper_name_comp:link("mappedC", entity)
	end
end

function add_object_property_as_link(object_property_axiom, graph_diagram)
	local domain_node = object_property_axiom:find("/objectPropertyDomain/domain/map:has(/elemType[id='Class'])")
	local range_node = object_property_axiom:find("/objectPropertyRange/range/map:has(/elemType[id='Class'])")

	local edge_type = lQuery("EdgeType[id='Association']")
	local role_value = compartment.strict_get_compartment(range_node, "Name/Name"):attr("value") or ""
	local inv_role_value = compartment.strict_get_compartment(domain_node, "Name/Name"):attr("value") or ""
	local property_name, property_namespace, iri_instance, entity_instance = renderer.render_object_property_expression(object_property_axiom)
	
	local declaration_instance = object_property_axiom:find("/equivalent/declaration")
	local domain_instance = object_property_axiom:find("/objectPropertyDomain")
	local range_instance = object_property_axiom:find("/objectPropertyRange")
	
	local edge = core.add_edge(edge_type, domain_node, range_node, graph_diagram)
	local role_comp = compartment.create_compartment(edge, "Role")
	local upper_name_comp = compartment.create_compartment(role_comp, "Name")
	local name_comp = compartment.create_compartment(upper_name_comp, "Name")
	local namespace_comp = compartment.create_compartment(upper_name_comp, "Namespace")
	local inv_role_comp = compartment.create_compartment(edge, "InvRole")
	
	core.set_compartment_value(role_comp, role_value)
	core.set_compartment_value(inv_role_comp, inv_role_value)
	core.set_compartment_value(name_comp, property_name)
	core.set_compartment_value(namespace_comp, property_namespace)
	
	role_comp.link(role_comp, "mapped", object_property_axiom)
	role_comp.link(role_comp, "mapped", declaration_instance)
	role_comp.link(role_comp, "mapped", domain_instance)
	role_comp.link(role_comp, "mapped", range_instance)
	upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
	upper_name_comp.link(upper_name_comp, "mappedC", entity_instance)
	
	return edge
end

function add_inverse_object_property(edge, object_property_axiom, inverse_object_property_axiom)
	if edge == nil or edge:is_empty() then
		return
	end

	local property_name, property_namespace, iri_instance, entity_instance = renderer.render_object_property_expression(object_property_axiom)
	local declaration_instance = object_property_axiom:find("/equivalent/declaration")
	local domain_instance = object_property_axiom:find("/objectPropertyDomain")
	local range_instance = object_property_axiom:find("/objectPropertyRange")
	
	local inv_role_comp = compartment.get_compartment(edge, "InvRole")
	local upper_name_comp = compartment.create_compartment(inv_role_comp, "Name")
	local name_comp = compartment.create_compartment(upper_name_comp, "Name")
	local namespace_comp = compartment.create_compartment(upper_name_comp, "Namespace")
	
	core.set_compartment_value(name_comp, property_name)
	core.set_compartment_value(namespace_comp, property_namespace)
	
	inv_role_comp.link(inv_role_comp, "mapped", object_property_axiom)
	inv_role_comp.link(inv_role_comp, "mapped", declaration_instance)
	inv_role_comp.link(inv_role_comp, "mapped", domain_instance)
	inv_role_comp.link(inv_role_comp, "mapped", range_instance)
	upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
	upper_name_comp.link(upper_name_comp, "mappedC", entity_instance)
	
	edge.link(edge, "mapped", inverse_object_property_axiom)
end

-----

function add_object_property_characteristics(ontology)
	local chars_class_table = {
		-- abbreviation = {domain_class, compartment_for_link, compartment_for_attribute}
		func = {"OWL#FunctionalObjectProperty", "Functional", "IsFunctional"},
		invf = {"OWL#InverseFunctionalObjectProperty", "InverseFunctional", ""},
		sym = {"OWL#SymmetricObjectProperty", "Symmetric", ""},
		asym = {"OWL#AsymmetricObjectProperty", "Asymmetric", ""},
		tran = {"OWL#TransitiveObjectProperty", "Transitive", ""},
		refl = {"OWL#ReflexiveObjectProperty", "Reflexive", ""},
		irefl = {"OWL#IrreflexiveObjectProperty", "Irreflexive", ""}
	}
	
	for abbrev, t in pairs(chars_class_table) do
		local characteristic = t[1]
		local comp_name_for_link = t[2]
		local comp_name_for_attr = t[3]
		ontology:find("/axioms."..characteristic):each(
			function(c)
				c:find("/objectPropertyExpression/map"):each(
					function(op_element)
						if op_element:find(":has(/compartType[id='Role'], /compartType[id='InvRole'])"):is_not_empty() then
							local compartment = compartment.get_compartment(op_element, comp_name_for_link)
							compartment:attr("value", abbrev)
							core.update_compartment_input_from_value(compartment)
							
						elseif op_element:find(":has(/compartType[id='Attributes'])"):is_not_empty() then
							add_characteristic_for_attribute(op_element, comp_name_for_attr, abbrev)
							
						end
					end)
			end)
	end
end

function add_characteristic_for_attribute(attr_comp, comp_name, abbrev)
	if comp_name == "IsFunctional" then
		local compartment = compartment.get_compartment(attr_comp, comp_name)
		compartment:attr("value", abbrev)
		core.update_compartment_input_from_value(compartment)
	elseif comp_name == "..." then
		-- nevizualizçjamas aksiomas
	end
end

-----

function add_equivalent_object_property_axioms(ontology)
	add_eq_or_dj_object_property_axioms(ontology:find("/axioms.OWL#EquivalentObjectProperties"), "EquivalentProperties/EquivalentProperties")
end

function add_disjoint_object_property_axioms(ontology)
	add_eq_or_dj_object_property_axioms(ontology:find("/axioms.OWL#DisjointObjectProperties"), "DisjointProperties/DisjointProperties")
end

function add_eq_or_dj_object_property_axioms(eq_or_dj_property_axioms, property_comp_path)
	eq_or_dj_property_axioms:each(
		function(object_prop_axiom)
			if object_prop_axiom:find("/map"):is_not_empty() then
				return
			end
		
			local properties = object_prop_axiom:find("/objectPropertyExpressions")
			
			properties:each(
				function(property)
					local property_comp = property:find("/map")
					if property_comp:is_not_empty() then
						add_eq_or_dj_object_property(property_comp, properties:remove(property), object_prop_axiom, property_comp_path)
					end
				end)
		end)
end

function add_eq_or_dj_object_property(property_comp, properties, object_prop_axiom, property_comp_path)
	local path_to_expression = string.match(property_comp_path, "%a+"):gsub("ies", "y")
	
	properties:each(
		function(property)
			local property_name, ns, iri, entity_instance = renderer.render_object_property_expression(property)
			local properties_comp = compartment.create_compartment(property_comp, property_comp_path)
			local expression_comp = compartment.create_compartment(properties_comp, path_to_expression.."/Expression")
			
			core.set_compartment_value(expression_comp, property_name)
			
			properties_comp.link(properties_comp, "mapped", object_prop_axiom)
			expression_comp.link(expression_comp, "mappedC", entity_instance)
		end)
end

-----

function add_subobject_property_axioms(ontology)
	ontology:find("/axioms.OWL#SubObjectPropertyOf"):each(
		function(sub_object_prop_of_axiom)
			if sub_object_prop_of_axiom:find("/map"):is_not_empty() then
				return
			end
			
			local super_property = sub_object_prop_of_axiom:find("/superObjectPropertyExpression")
			local sub_property = sub_object_prop_of_axiom:find("/subObjectPropertyExpressions")
			if sub_property:size() == 1 then
				local property_comp = sub_property:find("/map")
				
				if property_comp:is_not_empty() then
					add_super_object_property(property_comp, super_property, sub_object_prop_of_axiom)
				end
			elseif sub_property:size() > 1 then
				local property_comp = super_property:find("/map")
				add_object_property_chain(property_comp, sub_property, sub_object_prop_of_axiom)
			end
		end)
end

function add_super_object_property(property_comp, super_property, sub_object_prop_of_axiom)
	local property_name, ns, iri, entity_instance = renderer.render_object_property_expression(super_property)
	local super_properties_comp = compartment.create_compartment(property_comp, "SuperProperties/SuperProperties")
	local expression_comp = compartment.create_compartment(super_properties_comp, "Expression")
	
	core.set_compartment_value(expression_comp, property_name)
	
	super_properties_comp:link("mapped", sub_data_prop_of_axiom)
	expression_comp:link("mappedC", entity_instance)
end

function add_object_property_chain(property_comp, sub_properties, sub_object_prop_of_axiom)

	if property_comp:find(":has(/compartType[id='Role'], /compartType[id='InvRole'])"):is_not_empty() then	
		local upper_prop_chains_comp = compartment.get_compartment(property_comp, "PropertyChains")
		local prop_chains_comp = compartment.create_compartment(upper_prop_chains_comp, "PropertyChains")
		
		sub_properties:each(
			function(property)
				local name, namespace, iri, entity_instance = renderer.render_object_property_expression(property)
				local prop_chain_comp = compartment.create_compartment(prop_chains_comp, "PropertyChain")
				local inverse_comp = compartment.create_compartment(prop_chain_comp, "Inverse")
				local property_comp = compartment.create_compartment(prop_chain_comp, "Property")
				local namespace_comp = compartment.create_compartment(prop_chain_comp, "Namespace")
				
				core.set_compartment_value(property_comp, name)
				core.set_compartment_value(namespace_comp, namespace)
				
				prop_chain_comp:link("mapped", entity_instance)
			end)
			
		prop_chains_comp:link("mapped", sub_object_prop_of_axiom)
		
	elseif property_comp:find(":has(/compartType[id='Attributes'])"):is_not_empty() then
		-- nevizualizçjamas aksiomas
	end
end

-----

function add_annotation_property_axioms(ontology, graph_diagram)
	ontology:find("/iriInOntology/entity.OWL#AnnotationProperty"):each(
		function(property)
			local range_expression = property:find("/annotationPropertyRange")
			local domain_expression = property:find("/annotationPropertyDomain")
			
			local property_node = add_annotation_property(property, graph_diagram)
			if range_expression:is_not_empty() then
				add_range_to_annotation_property(range_expression, property_node)
			end
			if domain_expression:is_not_empty() then
				add_domain_to_annotation_property(domain_expression, property_node)
			end
		end)
end

function add_annotation_property(property, graph_diagram)
	local node_type = lQuery("NodeType[id='AnnotationProperty']")
	local declaration_instance = property:find("/declaration")
	local iri_instance = property:find("/entityIRI")
	local property_name = iri_instance:attr("shortValue")
	local property_namespace = iri_instance:find("/namespace"):attr("prefix") or ""
	
	local node = core.add_node(node_type, graph_diagram)
	local upper_name_comp = compartment.create_compartment(node, "Name")
	local name_comp = compartment.create_compartment(upper_name_comp, "Name")
	local namespace_comp = compartment.create_compartment(upper_name_comp, "Namespace")
	
	core.set_compartment_value(name_comp, property_name)
	core.set_compartment_value(namespace_comp, property_namespace)
	
	node:link("mapped", declaration_instance)
	node:link("mapped", property)
	upper_name_comp:link("mapped", iri_instance)
	upper_name_comp:link("mappedC", property)
	
	return node
end

function add_range_to_annotation_property(range_expression, node)
	local iri_instance = range_expression:find("/range")
	local range_name = iri_instance:attr("shortValue")
	local range_namespace = iri_instance:find("/namespace"):attr("prefix") or ""
	
	local range_comp = compartment.create_compartment(node, "Range")
	local name_comp = compartment.create_compartment(range_comp, "Name")
	local namespace_comp = compartment.create_compartment(range_comp, "Namespace")
	
	core.set_compartment_value(name_comp, range_name)
	core.set_compartment_value(namespace_comp, range_namespace)
	
	range_comp:link("mapped", iri_instance)
	range_comp:link("mappedC", range_expression)
end

function add_domain_to_annotation_property(domain_expression, node)
	local iri_instance = domain_expression:find("/domain")
	local domain_name = iri_instance:attr("shortValue")
	local domain_namespace = iri_instance:find("/namespace"):attr("prefix") or ""
	
	local domain_comp = compartment.create_compartment(node, "Domain")
	local name_comp = compartment.create_compartment(domain_comp, "Name")
	local namespace_comp = compartment.create_compartment(domain_comp, "Namespace")
	
	core.set_compartment_value(name_comp, domain_name)
	core.set_compartment_value(namespace_comp, domain_namespace)
	
	domain_comp:link("mapped", iri_instance)
	domain_comp:link("mappedC", domain_expression)
end

-----

function add_class_annotation_assertion_axioms(ontology, graph_diagram)
	local ca_state = get_parameter_value("Class Annotations")
	
	ontology:find("/iriInOntology/entity.OWL#ClassEntity"):find("/entityIRI/annotationSubject"):each(
		function(subject)
			subject:find("/annotationAssertion"):each(
				function(assertion)
					local class_node = subject:find("/iri/entity/equivalent/map:has(/elemType[id='Class'])")
					if class_node:is_not_empty() then
						if ca_state == '0' then -- no graphics
							add_annotation_assertions(class_node, subject, assertion, graph_diagram)
						
						elseif ca_state == '1' then -- use graphics
							add_annotation_assertion_boxes(class_node, "", subject, assertion, graph_diagram)
							
						elseif ca_state == '-1' then -- rule
							local translet = get_rule_procedure("Class Annotations")
							local state = utilities.execute_translet(translet)
							
							if state == '0' then
								add_annotation_assertions(class_node, subject, assertion, graph_diagram)
							elseif state == '1' then
								add_annotation_assertion_boxes(class_node, "", subject, assertion, graph_diagram)
							end
						end
					end
				end)
		end)
end

-----

function add_object_prop_annotation_assertion_axioms(ontology, graph_diagram)
	local op_state = get_parameter_value("Object Properties Annotations")
	
	ontology:find("/iriInOntology/entity.OWL#ObjectPropertyEntity"):find("/entityIRI/annotationSubject"):each(
		function(subject)
			subject:find("/annotationAssertion"):each(
				function(assertion)
					local properties = subject:find("/iri/entity/equivalent/map:has(/compartType[id='Role'], /compartType[id='InvRole'])")
					properties:each(
						function(property)
							local edge = utilities.get_element_from_compartment(property)
							local name_comp = compartment.strict_get_compartment(property, "Name/Name")
							local name = name_comp:attr("value") or ""
						
							if op_state == '0' then -- no graphics
								add_annotation_assertions(property, subject, assertion, graph_diagram)
							
							elseif op_state == '1' then -- use graphics
								add_annotation_assertion_boxes(edge, name, subject, assertion, graph_diagram)
								
							elseif op_state == '-1' then -- rule
								local translet = get_rule_procedure("Object Properties Annotations")
								local state = utilities.execute_translet(translet)
								
								if state == '0' then
									add_annotation_assertions(property, subject, assertion, graph_diagram)
								elseif state == '1' then
									add_annotation_assertion_boxes(edge, name, subject, assertion, graph_diagram)
								end
							end
						end)
				end)
		end)
end

-----

function add_data_prop_annotation_assertion_axioms(ontology, graph_diagram)
	local dp_state = get_parameter_value("Data Properties Annotations")
	
	ontology:find("/iriInOntology/entity.OWL#DataPropertyEntity"):find("/entityIRI/annotationSubject"):each(
		function(subject)
			subject:find("/annotationAssertion"):each(
				function(assertion)
					local properties = subject:find("/iri/entity/equivalent/map:has(/compartType[id='Attributes'])")
					properties:each(
						function(property)
							local node = utilities.get_element_from_compartment(property)
							local name_comp = compartment.strict_get_compartment(property, "Name/Name")
							local name = name_comp:attr("value") or ""
						
							if dp_state == '0' then -- no graphics
								add_annotation_assertions(property, subject, assertion, graph_diagram)
							
							elseif dp_state == '1' then -- use graphics
								add_annotation_assertion_boxes(node, name, subject, assertion, graph_diagram)
								
							elseif dp_state == '-1' then -- rule
								local translet = get_rule_procedure("Data Properties Annotations")
								local state = utilities.execute_translet(translet)
								
								if state == '0' then
									add_annotation_assertions(property, subject, assertion, graph_diagram)
								elseif state == '1' then
									add_annotation_assertion_boxes(node, name, subject, assertion, graph_diagram)
								end
							end
						end)
				end)
		end)
end

-----

function add_individual_annotation_assertion_axioms(ontology, graph_diagram)
	local ia_state = get_parameter_value("Individuals Annotations")
	
	ontology:find("/iriInOntology/entity.OWL#NamedIndividualEntity"):find("/entityIRI/annotationSubject"):each(
		function(subject)
			subject:find("/annotationAssertion"):each(
				function(assertion)
					local object_node = subject:find("/iri/entity/equivalent/map:has(/elemType[id='Object'])")
					if object_node:is_not_empty() then
						if ia_state == '0' then -- no graphics
							add_annotation_assertions(object_node, subject, assertion, graph_diagram)
						
						elseif ia_state == '1' then -- use graphics
							add_annotation_assertion_boxes(object_node, "", subject, assertion, graph_diagram)
							
						elseif ia_state == '-1' then -- rule
							local translet = get_rule_procedure("Individuals Annotations")
							local state = utilities.execute_translet(translet)
							
							if state == '0' then
								add_annotation_assertions(object_node, subject, assertion, graph_diagram)
							elseif state == '1' then
								add_annotation_assertion_boxes(object_node, "", subject, assertion, graph_diagram)
							end
						end
					end
				end)
		end)
end

-----

function add_annotation_assertions(element ,subject, assertion, graph_diagram)	
	if assertion:find("/map"):is_not_empty() then
		return
	end
	
	local type_value = renderer.render_annotation_property(assertion:find("/annotationProperty"))
	local value, language = renderer.render_annotation_value(assertion:find("/annotationValue"))
	
	local annotation_comp = compartment.create_compartment(element, "Annotation")
	local annotation_type_comp = compartment.create_compartment(annotation_comp, "AnnotationType")
	local value_comp = compartment.create_compartment(annotation_comp, "ValueLanguage/Value")
	local language_comp = compartment.create_compartment(annotation_comp, "ValueLanguage/Language")
	
	core.set_compartment_value(annotation_type_comp, type_value:gsub("^%l", string.upper))
	core.set_compartment_value(value_comp, value)
	core.set_compartment_value(language_comp, language)
	
	annotation_comp.link(annotation_comp, "mapped", assertion)
end

function add_annotation_assertion_boxes(element, for_name, subject, assertion, graph_diagram)
	local node_type = lQuery("NodeType[id='Annotation']")
	local edge_type = lQuery("EdgeType[id='Connector']")
	local class_expression = subject:find("/iri/entity/equivalent")
	
	if assertion:find("/map"):is_not_empty() then
		return
	end
	
	local node = core.add_node(node_type, graph_diagram)
	local edge = core.add_edge(edge_type, node, element, graph_diagram)
	
	local type_comp = compartment.create_compartment(node, "AnnotationType")
	local property_comp = compartment.create_compartment(node, "Property")
	local value_comp = compartment.create_compartment(node, "ValueLanguage/Value")
	local language_comp = compartment.create_compartment(node, "ValueLanguage/Language")
	
	local type_value = renderer.render_annotation_property(assertion:find("/annotationProperty"))
	local value, language = renderer.render_annotation_value(assertion:find("/annotationValue"))
	
	core.set_compartment_value(type_comp, type_value)
	core.set_compartment_value(property_comp, for_name)
	core.set_compartment_value(value_comp, value)
	core.set_compartment_value(language_comp, language)
	
	node.link(node, "mapped", assertion)
end

-----

function add_object_property_assertion_axioms(ontology, graph_diagram)
	ontology:find("/axioms.OWL#ObjectPropertyAssertion"):each(
		function(assertion)
			local op_expression = assertion:find("/objectPropertyExpression")
			local source_node = assertion:find("/sourceIndividual/map:has(/elemType[id='Object'])")
			local target_node = assertion:find("/targetIndividual/map:has(/elemType[id='Object'])")
			
			add_object_property_assertion(assertion, op_expression, source_node, target_node, false, graph_diagram)
		end)
		
	ontology:find("/axioms.OWL#NegativeObjectPropertyAssertion"):each(
		function(assertion)
			local op_expression = assertion:find("/objectPropertyExpression")
			local source_node = assertion:find("/sourceIndividual/map:has(/elemType[id='Object'])")
			local target_node = assertion:find("/targetIndividual/map:has(/elemType[id='Object'])")
			
			add_object_property_assertion(assertion, op_expression, source_node, target_node, true, graph_diagram)
		end)
end

function add_object_property_assertion(assertion, op_expression, source, target, is_negative, graph_diagram)
	local edge_type = lQuery("GraphDiagramType[id='OWL']/elemType[id='Link']")
	
	if assertion:find("/map"):is_not_empty() then
		return
	end
	
	local edge = core.add_edge(edge_type, source, target, graph_diagram)
	
	local direct_comp = compartment.create_compartment(edge, "Direct")
	local is_negative_comp = compartment.create_compartment(direct_comp, "IsNegativeAssertion")
	local property_comp = compartment.create_compartment(direct_comp, "Property")
	local namespace_comp = compartment.create_compartment(direct_comp, "Namespace")
	
	local property_name, property_namespace = renderer.render_object_property_expression(op_expression)
	
	core.set_compartment_value(property_comp, property_name)
	core.set_compartment_value(namespace_comp, property_namespace)
	if is_negative then
		core.set_compartment_value(is_negative_comp, "<>")
	end
	
	edge:link("mapped", assertion)
end

-----

function add_data_property_assertion_axioms(ontology, graph_diagram)
	ontology:find("/axioms.OWL#DataPropertyAssertion"):each(
		function(assertion)
			local dp_expression = assertion:find("/dataPropertyExpression")
			local source_node = assertion:find("/sourceIndividual/map:has(/elemType[id='Object'])")
			local target_value = assertion:find("/targetValue")
			
			add_data_property_assertion(assertion, dp_expression, source_node, target_value, false, graph_diagram)
		end)
		
	ontology:find("/axioms.OWL#NegativeDataPropertyAssertion"):each(
		function(assertion)
			local dp_expression = assertion:find("/dataPropertyExpression")
			local source_node = assertion:find("/sourceIndividual/map:has(/elemType[id='Object'])")
			local target_value = assertion:find("/targetValue")
			
			add_data_property_assertion(assertion, dp_expression, source_node, target_value, true, graph_diagram)
		end)
end

function add_data_property_assertion(assertion, dp_expression, source, target, is_negative, graph_diagram)
	local property_name = renderer.render_data_property_expression(dp_expression)
	local value = target:attr("text")
	local vtype = target:find("/datatype/equivalent/entityIRI"):attr("shortValue")
	
	local assertion_comp
	if is_negative then
		assertion_comp = compartment.create_compartment(source, "NegativeDataPropertyAssertion")
	else
		assertion_comp = compartment.create_compartment(source, "DataPropertyAssertion")
	end
	local property_comp = compartment.create_compartment(assertion_comp, "Property")
	local value_comp = compartment.create_compartment(assertion_comp, "Value")
	local type_comp = compartment.create_compartment(assertion_comp, "Type")
	
	core.set_compartment_value(property_comp, property_name)
	core.set_compartment_value(value_comp, value)
	core.set_compartment_value(type_comp, vtype)
	
	assertion_comp:link("mapped", assertion)
end

-----

function add_datatype_axioms(ontology, graph_diagram)
	ontology:find("/axioms.OWL#Declaration/entity.OWL#DatatypeEntity/equivalent"):each(
		function(datatype)
			add_datatype(datatype, graph_diagram)
		end)
end

function add_datatype(datatype, graph_diagram)
	if datatype:find("/equivalent/map"):is_not_empty() then
		return
	end

	local node_type = lQuery("GraphDiagramType[id='OWL']/elemType[id='DataType']")
	local node = core.add_node(node_type, graph_diagram)
	
	local name, namespace, iri, entity = renderer.render_data_range(datatype)
	
	local label_comp = compartment.create_compartment(node, "Label")
	local upper_name_comp = compartment.create_compartment(node, "Name")
	local name_comp = compartment.create_compartment(upper_name_comp, "Name")
	local namespace_comp = compartment.create_compartment(upper_name_comp, "Namespace")
	
	core.set_compartment_value(label_comp, "DataType")
	core.set_compartment_value(name_comp, name)
	core.set_compartment_value(namespace_comp, namespace)
	
	node:link("mapped", entity)
	upper_name_comp:link("mapped", iri)
end

-----

function add_datatype_definition_axioms(ontology)
	ontology:find("/axioms.OWL#DatatypeDefinition"):each(
		function(definition)
			add_datatype_definition(definition)
		end)
end

function add_datatype_definition(definition)
	local datatype = definition:find("/datatype/equivalent")
	local data_range = definition:find("/dataRange")
	
	if datatype:find("/map"):is_empty() or definition:find("/map"):is_not_empty() then
		return
	end
	
	local expression = renderer.render_data_range(data_range)
	local def_comp = compartment.create_compartment(datatype:find("/map"), "DataTypeDefinition")
	core.set_compartment_value(def_comp, expression)
	
	def_comp:link("mapped", definition)
end

-----

function add_has_key_axioms(ontology)
	ontology:find("/axioms.OWL#HasKey"):each(
		function(has_key)
			local class_expression = has_key:find("/classExpression")
			local op_expressions = has_key:find("/objectPropertyExpressions")
			local dp_expressions = has_key:find("/dataPropertyExpressions")
			
			add_has_key(has_key, class_expression, op_expressions, dp_expressions)
		end)
end

function add_has_key(has_key, class_expression, op_expressions, dp_expressions)
	if class_expression:find("/map:has(/elemType[id='Class'])"):is_empty() or has_key:find("/map"):is_not_empty() then
		return
	end
	
	local node = class_expression:find("/map:has(/elemType[id='Class'])")
	local keys_comp = compartment.create_compartment(node, "Keys")
	
	op_expressions:each(
		function(op_expression)
			local key_comp = compartment.create_compartment(keys_comp, "Key")
			local inv_comp = compartment.create_compartment(key_comp, "Inverse")
			local prop_comp = compartment.create_compartment(key_comp, "Property")
			local namespace_comp = compartment.create_compartment(key_comp, "Namespace")
			
			local property, namespace, iri, entity = renderer.render_object_property_expression(op_expression)
			
			core.set_compartment_value(inv_comp, "false")
			core.set_compartment_value(prop_comp, property)
			core.set_compartment_value(namespace_comp, namespace)
		end)
	
	dp_expressions:each(
		function(dp_expression)
			local key_comp = compartment.create_compartment(keys_comp, "Key")
			local inv_comp = compartment.create_compartment(key_comp, "Inverse")
			local prop_comp = compartment.create_compartment(key_comp, "Property")
			local namespace_comp = compartment.create_compartment(key_comp, "Namespace")
			
			local property, namespace, iri, entity = renderer.render_data_property_expression(dp_expression)
			
			core.set_compartment_value(inv_comp, "false")
			core.set_compartment_value(prop_comp, property)
			core.set_compartment_value(namespace_comp, namespace)
		end)
		
	keys_comp:link("mapped", has_key)
end

----------

function get_parameter_value(instruction_id)
	local selected_profile = lQuery("P_OWL#ParamProfile[selected = true]")
	return selected_profile:find("/instructionInProfile/instruction[id = "..instruction_id.."]/instructionInProfile/selected"):attr("index")
end

function get_rule_procedure(instruction_id)
	local selected_profile = lQuery("P_OWL#ParamProfile[selected = true]")
	return selected_profile:find("/instructionInProfile/instruction[id = "..instruction_id.."]/item[index = -1]"):attr("itemProc")
end