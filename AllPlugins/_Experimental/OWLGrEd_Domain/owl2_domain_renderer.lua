module(..., package.seeall)

require "lQuery"


function render_class_expression(class_expression)
	local tag = lQuery("ToolType"):find("/tag[key = owlgred_d_render]")
	if tag:is_not_empty() then
		local translet = tag:attr("value")
		return utilities.execute_translet(translet)
	end

	if class_expression:is_empty() then
		return "", "", {}, {}
	end
	
	local class_name = class_expression:get(1):class().name
	local expression_value = tostring(class_expression:id()) -- default value
	local expression_namespace = ""
	local iris = {}
	local entities = {}

	if class_name == "OWL#Class" then
		local entity_instance = class_expression:find("/equivalent")
		local iri_instance = entity_instance:find("/entityIRI")
		expression_value = iri_instance:attr("shortValue")
		expression_namespace = iri_instance:find("/namespace"):attr("prefix") or ""
		table.insert(entities, entity_instance)
		table.insert(iris, iri_instance)
		
	elseif class_name == "OWL#ObjectIntersectionOf" then
		expression_value = ""
		class_expression:find("/classExpressions"):each(
			function(element)
				local name, namespace, iri, entity = render_class_expression(element)
				if namespace ~= "" then
					namespace = "{"..namespace.."}"
				end
				for _,v in ipairs(iri) do
					table.insert(iris, v)
				end
				for _,v in ipairs(entity) do
					table.insert(entities, v)
				end
				
				expression_value = expression_value..name..namespace.." and "
			end)
		
		expression_value = string.sub(expression_value, 1, string.len(expression_value)-5)
	
	elseif class_name == "OWL#ObjectUnionOf" then
		expression_value = ""
		class_expression:find("/classExpressions"):each(
			function(element)
				local name, namespace, iri, entity = render_class_expression(element)
				if namespace ~= "" then
					namespace = "{"..namespace.."}"
				end
				for _,v in ipairs(iri) do
					table.insert(iris, v)
				end
				for _,v in ipairs(entity) do
					table.insert(entities, v)
				end
				
				expression_value = expression_value..name..namespace.." or "
			end)
		
		expression_value = string.sub(expression_value, 1, string.len(expression_value)-4)
	
	elseif class_name == "OWL#ObjectComplementOf" then
		local name, namespace, iri, entity = render_class_expression(class_expression:find("/classExpression"))
		if namespace ~= "" then
			namespace = "{"..namespace.."}"
		end
		for _,v in ipairs(iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(entity) do
			table.insert(entities, v)
		end
		
		expression_value = "not("..name..namespace..")"
	
	elseif class_name == "OWL#ObjectOneOf" then
		expression_value = "{"
		class_expression:find("/individuals"):each(
			function(individual)
				local name, namespace, iri, entity = render_individual_expression(individual)
				if namespace ~= "" then
					namespace = "{"..namespace.."}"
				end
				for _,v in ipairs(iri) do
					table.insert(iris, v)
				end
				for _,v in ipairs(entity) do
					table.insert(entities, v)
				end
				
				expression_value = expression_value..name..namespace..", "
			end)
		
		expression_value = string.sub(expression_value, 1, string.len(expression_value)-2).."}"
	
	elseif class_name == "OWL#ObjectSomeValuesFrom" then
		local object_property_expression = class_expression:find("/objectPropertyExpression")
		local op_name, op_namespace, op_iri, op_entity = render_object_property_expression(object_property_expression)
		local cl_name, cl_namespace, cl_iri, cl_entity = render_class_expression(class_expression:find("/classExpression"))
		
		if op_namespace ~= "" then
			op_namespace = "{"..op_namespace.."}"
		end
		table.insert(iris, op_iri)
		table.insert(entities, op_entity)
		
		if cl_namespace ~= "" then
			cl_namespace = "{"..cl_namespace.."}"
		end
		for _,v in ipairs(cl_iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(cl_entity) do
			table.insert(entities, v)
		end
		
		expression_value = op_name..op_namespace.." some "..cl_name..cl_namespace
	
	elseif class_name == "OWL#ObjectAllValuesFrom" then
		local object_property_expression = class_expression:find("/objectPropertyExpression")
		local op_name, op_namespace, op_iri, op_entity = render_object_property_expression(object_property_expression)
		local cl_name, cl_namespace, cl_iri, cl_entity = render_class_expression(class_expression:find("/classExpression"))
		
		if op_namespace ~= "" then
			op_namespace = "{"..op_namespace.."}"
		end
		table.insert(iris, op_iri)
		table.insert(entities, op_entity)
		
		if cl_namespace ~= "" then
			cl_namespace = "{"..cl_namespace.."}"
		end
		for _,v in ipairs(cl_iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(cl_entity) do
			table.insert(entities, v)
		end
		
		expression_value = op_name..op_namespace.." only "..cl_name..cl_namespace
	
	elseif class_name == "OWL#ObjectHasValue" then
		local object_property_expression = class_expression:find("/objectPropertyExpression")
		local op_name, op_namespace, op_iri, op_entity = render_object_property_expression(object_property_expression)
		local i_name, i_namespace, i_iri, i_entity = render_individual_expression(class_expression:find("/individual"))
		
		if op_namespace ~= "" then
			op_namespace = "{"..op_namespace.."}"
		end
		table.insert(iris, op_iri)
		table.insert(entities, op_entity)
		
		if i_namespace ~= "" then
			i_namespace = "{"..i_namespace.."}"
		end
		table.insert(iris, i_iri)
		table.insert(entities, i_entity)
		
		expression_value = op_name..op_namespace.." value "..i_name..i_namespace
	
	elseif class_name == "OWL#ObjectHasSelf" then
		local object_property_expression = class_expression:find("/objectPropertyExpression")
		local op_name, op_namespace, op_iri, op_entity = render_object_property_expression(object_property_expression)
		
		if op_namespace ~= "" then
			op_namespace = "{"..op_namespace.."}"
		end
		table.insert(iris, op_iri)
		table.insert(entities, op_entity)
		
		expression_value = op_name..op_namespace.." Self"
		
	elseif class_name == "OWL#ObjectMinCardinality" then
		local object_property_expression = class_expression:find("/objectPropertyExpression")
		local op_name, op_namespace, op_iri, op_entity = render_object_property_expression(object_property_expression)
		local cl_name, cl_namespace, cl_iri, cl_entity = render_class_expression(class_expression:find("/classExpression"))
		local cardinality = class_expression:attr("cardinality")
		
		if op_namespace ~= "" then
			op_namespace = "{"..op_namespace.."}"
		end
		table.insert(iris, op_iri)
		table.insert(entities, op_entity)
		
		if cl_namespace ~= "" then
			cl_namespace = "{"..cl_namespace.."}"
		end
		for _,v in ipairs(cl_iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(cl_entity) do
			table.insert(entities, v)
		end
		
		table.insert(iris, class_expression) -- cardinality
		
		if cl_name ~= "" then
			cl_name = " "..cl_name
		end
		
		expression_value = op_name..op_namespace.." min "..cardinality..cl_name..cl_namespace
	
	elseif class_name == "OWL#ObjectMaxCardinality" then
		local object_property_expression = class_expression:find("/objectPropertyExpression")
		local op_name, op_namespace, op_iri, op_entity = render_object_property_expression(object_property_expression)
		local cl_name, cl_namespace, cl_iri, cl_entity = render_class_expression(class_expression:find("/classExpression"))
		local cardinality = class_expression:attr("cardinality")
		
		if op_namespace ~= "" then
			op_namespace = "{"..op_namespace.."}"
		end
		table.insert(iris, op_iri)
		table.insert(entities, op_entity)
		
		if cl_namespace ~= "" then
			cl_namespace = "{"..cl_namespace.."}"
		end
		for _,v in ipairs(cl_iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(cl_entity) do
			table.insert(entities, v)
		end
		
		table.insert(iris, class_expression) -- cardinality
		
		if cl_name ~= "" then
			cl_name = " "..cl_name
		end
		
		expression_value = op_name..op_namespace.." max "..cardinality..cl_name..cl_namespace
	
	elseif class_name == "OWL#ObjectExactCardinality" then
		local object_property_expression = class_expression:find("/objectPropertyExpression")
		local op_name, op_namespace, op_iri, op_entity = render_object_property_expression(object_property_expression)
		local cl_name, cl_namespace, cl_iri, cl_entity = render_class_expression(class_expression:find("/classExpression"))
		local cardinality = class_expression:attr("cardinality")
		
		if op_namespace ~= "" then
			op_namespace = "{"..op_namespace.."}"
		end
		table.insert(iris, op_iri)
		table.insert(entities, op_entity)
		
		if cl_namespace ~= "" then
			cl_namespace = "{"..cl_namespace.."}"
		end
		for _,v in ipairs(cl_iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(cl_entity) do
			table.insert(entities, v)
		end
		
		table.insert(iris, class_expression) -- cardinality
		
		if cl_name ~= "" then
			cl_name = " "..cl_name
		end
		
		expression_value = op_name..op_namespace.." exactly "..cardinality..cl_name..cl_namespace
		
	elseif class_name == "OWL#DataSomeValuesFrom" then
		local data_property_expressions = class_expression:find("/dataPropertyExpressions")
		local dp_name, dp_namespace, dp_iri, dp_entity = render_data_property_expression(data_property_expressions)
		local range, r_namespace, r_iris, r_entities = render_data_range(class_expression:find("/dataRange"))
		
		if dp_namespace ~= "" then
			dp_namespace = "{"..dp_namespace.."}"
		end
		table.insert(iris, dp_iri)
		table.insert(entities, dp_entity)
		
		if r_namespace ~= "" then
			r_namespace = "{"..r_namespace.."}"
		end
		for _,v in ipairs(r_iris) do
			table.insert(iris, v)
		end
		for _,v in ipairs(r_entities) do
			table.insert(entities, v)
		end
		
		expression_value = dp_name..dp_namespace.." some "..range..r_namespace
		
	elseif class_name == "OWL#DataAllValuesFrom" then
		local data_property_expressions = class_expression:find("/dataPropertyExpressions")
		local dp_name, dp_namespace, dp_iri, dp_entity = render_data_property_expression(data_property_expressions)
		local range, r_namespace, r_iris, r_entities = render_data_range(class_expression:find("/dataRange"))
		
		if dp_namespace ~= "" then
			dp_namespace = "{"..dp_namespace.."}"
		end
		table.insert(iris, dp_iri)
		table.insert(entities, dp_entity)
		
		if r_namespace ~= "" then
			r_namespace = "{"..r_namespace.."}"
		end
		for _,v in ipairs(r_iris) do
			table.insert(iris, v)
		end
		for _,v in ipairs(r_entities) do
			table.insert(entities, v)
		end
		
		expression_value = dp_name..dp_namespace.." only "..range..r_namespace
		
	elseif class_name == "OWL#DataHasValue" then
		local data_property_expression = class_expression:find("/dataPropertyExpression")
		local dp_name, dp_namespace, dp_iri, dp_entity = render_data_property_expression(data_property_expression)
		local literal, language, l_iri, l_entity = render_literal_expression(class_expression:find("/literal"))
		
		if dp_namespace ~= "" then
			dp_namespace = "{"..dp_namespace.."}"
		end
		table.insert(iris, dp_iri)
		table.insert(entities, dp_entity)
		
		table.insert(iris, l_iri)
		table.insert(entities, l_entity)
		
		expression_value = dp_name..dp_namespace.." value "..literal
		
	elseif class_name == "OWL#DataMinCardinality" then
		local data_property_expression = class_expression:find("/dataPropertyExpression")
		local dp_name, dp_namespace, dp_iri, dp_entity = render_data_property_expression(data_property_expression)
		local cl_name, cl_namespace, cl_iri, cl_entity = render_data_range(class_expression:find("/dataRange"))
		local cardinality = class_expression:attr("cardinality")
		
		if dp_namespace ~= "" then
			dp_namespace = "{"..dp_namespace.."}"
		end
		table.insert(iris, dp_iri)
		table.insert(entities, dp_entity)
		
		if cl_namespace ~= "" then
			cl_namespace = cl_namespace..":"
		end
		for _,v in ipairs(cl_iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(cl_entity) do
			table.insert(entities, v)
		end
		
		table.insert(iris, class_expression) -- cardinality
		
		if cl_name ~= "" then
			cardinality = cardinality.." "
		end
		
		expression_value = dp_name..dp_namespace.." min "..cardinality..cl_namespace..cl_name
	
	elseif class_name == "OWL#DataMaxCardinality" then
		local data_property_expression = class_expression:find("/dataPropertyExpression")
		local dp_name, dp_namespace, dp_iri, dp_entity = render_data_property_expression(data_property_expression)
		local cl_name, cl_namespace, cl_iri, cl_entity = render_data_range(class_expression:find("/dataRange"))
		local cardinality = class_expression:attr("cardinality")
		
		if dp_namespace ~= "" then
			dp_namespace = "{"..dp_namespace.."}"
		end
		table.insert(iris, dp_iri)
		table.insert(entities, dp_entity)
		
		if cl_namespace ~= "" then
			cl_namespace = cl_namespace..":"
		end
		for _,v in ipairs(cl_iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(cl_entity) do
			table.insert(entities, v)
		end
		
		table.insert(iris, class_expression) -- cardinality
		
		if cl_name ~= "" then
			cardinality = cardinality.." "
		end
		
		expression_value = dp_name..dp_namespace.." max "..cardinality..cl_namespace..cl_name
	
	elseif class_name == "OWL#DataExactCardinality" then
		local data_property_expression = class_expression:find("/dataPropertyExpression")
		local dp_name, dp_namespace, dp_iri, dp_entity = render_data_property_expression(data_property_expression)
		local cl_name, cl_namespace, cl_iri, cl_entity = render_data_range(class_expression:find("/dataRange"))
		local cardinality = class_expression:attr("cardinality")
		
		if dp_namespace ~= "" then
			dp_namespace = "{"..dp_namespace.."}"
		end
		table.insert(iris, dp_iri)
		table.insert(entities, dp_entity)
		
		if cl_namespace ~= "" then
			cl_namespace = cl_namespace..":"
		end
		for _,v in ipairs(cl_iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(cl_entity) do
			table.insert(entities, v)
		end
		
		table.insert(iris, class_expression) -- cardinality
		
		if cl_name ~= "" then
			cardinality = cardinality.." "
		end
		
		expression_value = dp_name..dp_namespace.." exactly "..cardinality..cl_namespace..cl_name
	end
	
	return expression_value, expression_namespace, iris, entities
end

function render_object_property_expression(expression)
	local tag = lQuery("ToolType"):find("/tag[key = owlgred_d_render]")
	if tag:is_not_empty() then
		local translet = tag:attr("value")
		return utilities.execute_translet(translet)
	end
	
	local class_name = expression:get(1):class().name
	local expression_value = expression:id() -- default value
	local expression_namespace = ""
	local entity_instance
	local iri_instance
	
	if class_name == "OWL#ObjectProperty" then
		local entity_instance = expression:find("/equivalent")
		iri_instance = entity_instance:find("/entityIRI")
		expression_value = iri_instance:attr("shortValue")
		expression_namespace = iri_instance:find("/namespace"):attr("prefix") or ""
	elseif class_name == "OWL#InverseObjectProperty" then
		local name, namespace, iri_instance, entity_instance = render_object_property_expression(expression:find("/objectProperty"))
		if namespace ~= "" then
			namespace = "{"..namespace.."}"
		end
		expression_value = "inverse ("..name..namespace..")"
	end
	
	return expression_value, expression_namespace, iri_instance, entity_instance
end

function render_data_property_expression(expression)
	local tag = lQuery("ToolType"):find("/tag[key = owlgred_d_render]")
	if tag:is_not_empty() then
		local translet = tag:attr("value")
		return utilities.execute_translet(translet)
	end

	local expression_value = expression:id() -- default value
	local expression_namespace = ""
	local entity_instance = expression:find("/equivalent")
	local iri_instance = entity_instance:find("/entityIRI")
	
	expression_value = iri_instance:attr("shortValue")
	expression_namespace = iri_instance:find("/namespace"):attr("prefix") or ""
	
	return expression_value, expression_namespace, iri_instance, entity_instance
end

function render_data_range(data_range)
	local tag = lQuery("ToolType"):find("/tag[key = owlgred_d_render]")
	if tag:is_not_empty() then
		local translet = tag:attr("value")
		return utilities.execute_translet(translet)
	end
	
	if data_range:is_empty() or data_range == nil then
		return "", "", {}, {}
	end
	
	local class_name = data_range:get(1):class().name
	local expression_value = data_range:id() -- default value
	local expression_namespace = ""
	local entities = {}
	local iris = {}
	local entities = {}
	
	if class_name == "OWL#Datatype" then
		local entity_instance = data_range:find("/equivalent")
		local iri_instance = entity_instance:find("/entityIRI")
		expression_value = iri_instance:attr("shortValue")
		expression_namespace = iri_instance:find("/namespace"):attr("prefix") or ""
		table.insert(iris, iri_instance)
		table.insert(entities, entity_instance)
		
	elseif class_name == "OWL#DataIntersectionOf" then
		expression_value = ""
		data_range:find("/dataRanges"):each(
			function(element)
				local name, namespace, iri, entity = render_data_range(element)
				if namespace ~= "" and namespace ~= nil then
					namespace = "{"..namespace.."}"
				end
				for _,v in ipairs(iri) do
					table.insert(iris, v)
				end
				for _,v in ipairs(entity) do
					table.insert(entities, v)
				end
				
				expression_value = expression_value..name..namespace.." and "
			end)
		
		expression_value = string.sub(expression_value, 1, string.len(expression_value)-5)
		
	elseif class_name == "OWL#DataUnionOf" then
		expression_value = ""
		data_range:find("/dataRanges"):each(
			function(element)
				local name, namespace, iri, entity = render_data_range(element)
				if namespace ~= "" and namespace ~= nil then
					namespace = "{"..namespace.."}"
				end
				for _,v in ipairs(iri) do
					table.insert(iris, v)
				end
				for _,v in ipairs(entity) do
					table.insert(entities, v)
				end
				
				expression_value = expression_value..name..namespace.." or "
			end)
		
		expression_value = string.sub(expression_value, 1, string.len(expression_value)-4)
		
	elseif class_name == "OWL#DataComplementOf" then
		local name, namespace, iri, entity = render_data_range(data_range:find("/dataRange"))
		if namespace ~= "" and namespace ~= nil then
			namespace = "{"..namespace.."}"
		end
		for _,v in ipairs(iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(entity) do
			table.insert(entities, v)
		end
		
		expression_value = "not("..name..namespace..")"
		
	elseif class_name == "OWL#DataOneOf" then
		expression_value = "{"
		data_range:find("/literals"):each(
			function(literal)
				local value, language, iri, entity = render_literal_expression(literal)
				for _,v in ipairs(iri) do
					table.insert(iris, v)
				end
				for _,v in ipairs(entity) do
					table.insert(entities, v)
				end
				table.insert(iris, literal)
				
				expression_value = expression_value..value..", "
			end)
		
		expression_value = string.sub(expression_value, 1, string.len(expression_value)-2).."}"
		
	elseif class_name == "OWL#DatatypeRestriction" then
		local name, namespace, iri, entity = render_data_range(data_range:find("/datatype"))
		for _,v in ipairs(iri) do
			table.insert(iris, v)
		end
		for _,v in ipairs(entity) do
			table.insert(entities, v)
		end
		
		expression_value = name.."["
		data_range:find("/restrictions"):each(
			function(restriction)
				local facet = get_facet_abbr(restriction:find("/constrainingFacet"):attr("shortValue"))
				local value = restriction:find("/restrictionValue"):attr("text")
				
				expression_value = expression_value..facet..value..", "
			end)
		expression_value = string.sub(expression_value, 1, string.len(expression_value)-2).."]"
	end
	
	return expression_value, expression_namespace, iris, entities
end

function render_individual_expression(individual)
	local tag = lQuery("ToolType"):find("/tag[key = owlgred_d_render]")
	if tag:is_not_empty() then
		local translet = tag:attr("value")
		return utilities.execute_translet(translet)
	end
	
	if individual:get(1):class().name == "OWL#NamedIndividual" then
		local entity_instance = individual:find("/equivalent")
		local iri_instance = entity_instance:find("/entityIRI")
		value = iri_instance:attr("shortValue")
		namespace = iri_instance:find("/namespace"):attr("prefix") or ""
		
		return value, namespace, iri_instance, entity_instance
	else -- individual:get(1):class().name == "OWL#AnonymousIndividual"
		return individual:attr("nodeID"), "", individual, individual
	end
end

function render_literal_expression(literal)
	local tag = lQuery("ToolType"):find("/tag[key = owlgred_d_render]")
	if tag:is_not_empty() then
		local translet = tag:attr("value")
		return utilities.execute_translet(translet)
	end
	
	local entity_instance = literal:find("/datatype/equivalent")
	local iri_instance = entity_instance:find("/entityIRI")
	local literal_value = literal:attr("text")
	local literal_language = literal:attr("language")
	
	if iri_instance:is_not_empty() then
		local iri_value = iri_instance:attr("shortValue")
		local namespace_value = iri_instance:find("/namespace"):attr("prefix") or ""
		if namespace_value ~= "" then
			namespace_value = namespace_value..":"
		end
		
		literal_value = literal_value.."^^"..namespace_value..iri_value
	end
	
	return literal_value, literal_language, iri_instance, entity_instance
end

function render_annotation_property(annotation_property)
	local tag = lQuery("ToolType"):find("/tag[key = owlgred_d_render]")
	if tag:is_not_empty() then
		local translet = tag:attr("value")
		return utilities.execute_translet(translet)
	end
	
	local iri_instance = annotation_property:find("/entityIRI")
	
	return iri_instance:attr("shortValue")
end

function render_annotation_value(annotation_value)
	local tag = lQuery("ToolType"):find("/tag[key = owlgred_d_render]")
	if tag:is_not_empty() then
		local translet = tag:attr("value")
		return utilities.execute_translet(translet)
	end
	
	return render_literal_expression(annotation_value)
end

----------

function get_facet_abbr(value)
	abbr = {
		minExclusive = ">",
		minInclusive = ">=",
		maxExclusive = "<",
		maxInclusive = "<="
	}

	return abbr[value] or ""
end