module(..., package.seeall)
require "lQuery"
require "re"
require "parser"
dtp = require "domain_to_presentation"
renderer = require "owl2_domain_renderer"

function compute_domain(element)
	local elem_type = element:find("/compartType, /elemType")
	local path = get_path(elem_type)
	local procedure = proc_table(path, element)
	
	procedure()
end


function get_path(elem_type)
	if elem_type:is_empty() or elem_type == nil then
		return ""
	end
	
	local value = elem_type:attr("id")
	local parent_type = elem_type:find("/parentCompartType, /elemType")
	
	if string.sub(value, 0, 12) == "ASFictitious" then -- skip ASFictitous compartments
		return get_path(parent_type)
		
	elseif parent_type:is_empty() then -- top parent
		return value
		
	else
		return get_path(parent_type).."_"..value -- "Parent_Child"
	end
end

function proc_table(path, element)

	local functions = {
	
		Class = class_pattern(element),
		Class_Name_Name = class_pattern(element),
		Class_Name_Namespace = class_pattern(element),
		
		Class_EquivalentClasses_EquivalentClass_Expression = function()
			return false
		end,
		
		Class_Attributes = data_property_pattern(element),
		Class_Attributes_Name_Name = data_property_pattern(element),
		
		Association = object_property_pattern(element),
		Association_Role_Name_Name = object_property_pattern(element)
		
	}
	
	return functions[path]
end

function class_pattern(compartment)
	return function()
		local element
		if compartment:get(1):class().name == "Compartment" then
			element = utilities.get_element_from_compartment(compartment)
		else
			element = compartment
		end
		
		local named_class = {
			
			mapping_condition = function()
				return is_name_ok(element)
			end,
			
			map_pattern = function()
				return element:find("/mapped"):is_not_empty()
				--return element:find("/mapped.OWL#Class"):is_not_empty()
			end,
			
			domain_condition = function()
				local class_instance = element:find("/mapped.OWL#Class")
				local declaration_instance = element:find("/mapped.OWL#Declaration")
				local presentation_name = dtp.strict_get_compartment(element, "Name/Name"):attr("value") or ""
				local presentation_namespace = dtp.strict_get_compartment(element, "Name/Namespace"):attr("value") or ""
				local domain_name = class_instance:find("/equivalent/entityIRI"):attr("shortValue") or ""
				local domain_namespace = class_instance:find("/equivalent/entityIRI/namespace"):attr("prefix") or ""
				
				if declaration_instance:is_not_empty() then
					if declaration_instance:find("/entity/equivalent"):id() == class_instance:id() then
						return presentation_name == domain_name and presentation_namespace == domain_namespace and class_instance:size() == 1
					else
						return false
					end
				else
					return presentation_name == domain_name and presentation_namespace == domain_namespace and class_instance:size() == 1
				end
			end,
			
			escape_condition = function()
				local instance = element:find("/mapped.OWL#ClassExpression")
				local class_name = instance:get(1):class().name
				
				if instance:is_empty() then
					return false
				else
					return class_name ~= "OWL#Class"
				end
			end,
			
			delete_proc = function()
				delete_mapped_instances(element, {"Name"})
			end,
			
			create_proc = function()
				local ontology_instance = lQuery("OWL#Ontology"):first()
				local attributes = {}
				local links = {}
				
				local upper_name_comp = dtp.strict_get_compartment(element, "Name")
				local name_value = dtp.strict_get_compartment(upper_name_comp, "Name"):attr("value") or ""
				local namespace_value = dtp.strict_get_compartment(upper_name_comp, "Namespace"):attr("value") or ""
				
				attributes = {
					value = name_value,
					prefix = namespace_value,
					delim = ":"
				}
				local iri_instance = create_instance({class = "OWL#IRI", attrs = attributes})
				
				if namespace_value ~= "" then
					attributes = {
						prefix = namespace_value,
						IRIprefix = "" -- ???
					}
					links = {
						iri = {
							iri_instance
						}
					}
					create_instance({class = "OWL#Namespace", attrs = attributes, links = links})
				end
				
				links = {
					entityIRI = {
						iri_instance
					}
				}
				local class_entity_instance = create_instance({class = "OWL#ClassEntity", links = links})
				
				links = {
					equivalent = {
						class_entity_instance
					}
				}
				local class_instance = create_instance({class = "OWL#Class", links = links})
				
				links = {
					entity = {
						class_entity_instance
					}
					--[[
					,
					ontology = {
						ontology_instance
					}
					]]
				}
				local declaration_instance = create_instance({class = "OWL#Declaration", links = links})
				
				element.link(element, "mapped", class_instance)
				element.link(element, "mapped", declaration_instance)
				upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
			end
		}
		
		local anonymous_class = {
		
			mapping_condition = function()
				local is_empty_name = dtp.strict_get_compartment(element, "Name/Name"):attr("value") == ""
				if not is_empty_name then
					return false
				end
				
				local eq_classes_comp = dtp.strict_get_compartment(element, "EquivalentClasses"):first()
				local eq_class_comp = dtp.strict_get_compartment(eq_class_comp, "EquivalentClass")
				local expression_comp = dtp.strict_get_compartment(eq_classes_comp, "Expression")
				
				return eq_class_comp:size() == 1 and expression_comp:is_not_empty()
			end,
			
			map_pattern = function()
				return element:find("/mapped"):is_not_empty()
			end,
			
			domain_condition = function()
				local eq_classes_comp = dtp.strict_get_compartment(element, "EquivalentClasses"):first()
				local expression_comp = dtp.strict_get_compartment(eq_class_comp, "EquivalentClass/Expression")
				
				local expression_from_element = element:find("/mapped.OWL#ClassExpression")
				local expression_from_comp = expression_comp:find("/mapped.OWL#ClassExpression")
				
				return expression_from_element:id() == expression_from_comp:id()
			end,
			
			escape_condition = function()
				return false
			end,
			
			delete_proc = function()
				
			end,
			
			create_proc = function()
				local eq_classes_comp = dtp.strict_get_compartment(element, "EquivalentClasses"):first()
				local eq_class_comp = dtp.strict_get_compartment(eq_class_comp, "EquivalentClass")
				local expression_comp = dtp.strict_get_compartment(eq_classes_comp, "Expression")
				
				
			end
		}
		
		local action_on_update = function()
			dtp.strict_get_compartment(element, "Attributes"):each(
				function(attribute)
					local update_proc = data_property_pattern(attribute)
					update_proc()
				end)
		end
		
		--compute(named_class)
		--compute(anonymous_class)
		
		if compute(named_class) then
			action_on_update()
		end
	end
end


function data_property_pattern(compartment)
	return function()
		
		if compartment:find("/compartType"):attr("id") ~= "Attributes" then
			compartment = compartment:find("/parentCompartment/parentCompartment:has(/compartType[id='Attributes'])")
		end
		
		local attribute = {
			
			mapping_condition = function()
				return is_name_ok(compartment)
			end,
			
			map_pattern = function()
				return compartment:find("/mapped"):is_not_empty()
			end,
			
			domain_condition = function()
				local element = utilities.get_element_from_compartment(compartment)
				local property_instance = compartment:find("/mapped.OWL#DataProperty")
				local property_domain_instance = compartment:find("/mapped.OWL#DataPropertyDomain")
				local declaration_instance = compartment:find("/mapped.OWL#Declaration")
				local presentation_name = dtp.strict_get_compartment(compartment, "Name/Name"):attr("value") or ""
				local presentation_namespace = dtp.strict_get_compartment(compartment, "Name/Namespace"):attr("value") or ""
				local domain_name = property_instance:find("/equivalent/entityIRI"):attr("shortValue") or ""
				local domain_namespace = property_instance:find("/equivalent/entityIRI/namespace"):attr("prefix") or ""
				
				if property_domain_instance:is_not_empty() or renderer.render_class_expression(element) == "Thing" then
					if element:find("/mapped.OWL#ClassExpression"):id() == property_domain_instance:find("/domain"):id() then
						if declaration_instance:is_not_empty() then
							if declaration_instance:find("/entity/equivalent"):id() == property_instance:id() then
								return presentation_name == domain_name and presentation_namespace == domain_namespace and property_instance:size() == 1
							end
						else
							return presentation_name == domain_name and presentation_namespace == domain_namespace and property_instance:size() == 1
						end
					end
				end
				
				return false
			end,
			
			escape_condition = function()
				return false
			end,
			
			delete_proc = function()
				delete_mapped_instances(compartment, {"Name"})
			end,
			
			create_proc = function()
				local ontology_instance = lQuery("OWL#Ontology"):first()
				local element = utilities.get_element_from_compartment(compartment)
				local class_expression_instance = element:find("/mapped.OWL#ClassExpression")
				local attributes = {}
				local links = {}
				
				local upper_name_comp = dtp.strict_get_compartment(compartment, "Name")
				local name_value = dtp.strict_get_compartment(upper_name_comp, "Name"):attr("value") or ""
				local namespace_value = dtp.strict_get_compartment(upper_name_comp, "Namespace"):attr("value") or ""
				
				attributes = {
					value = name_value,
					prefix = namespace_value,
					delim = ":"
				}
				local iri_instance = create_instance({class = "OWL#IRI", attrs = attributes})
				
				if namespace_value ~= "" then
					attributes = {
						prefix = namespace_value,
						IRIprefix = "" -- ???
					}
					links = {
						iri = {
							iri_instance
						}
					}
					create_instance({class = "OWL#Namespace", attrs = attributes, links = links})
				end
				
				links = {
					entityIRI = {
						iri_instance
					}
				}
				local property_entity_instance = create_instance({class = "OWL#DataPropertyEntity", links = links})
				
				links = {
					equivalent = {
						property_entity_instance
					}
				}
				local property_instance = create_instance({class = "OWL#DataProperty", links = links})
				
				local property_domain_instance = lQuery("")
				if class_expression_instance:is_not_empty() then
					links = {
						dataPropertyExpression = {
							property_instance
						},
						domain = {
							class_expression_instance
						}
					}
					property_domain_instance = create_instance({class = "OWL#DataPropertyDomain", links = links})
				end
				
				links = {
					entity = {
						property_entity_instance
					}
					--[[
					,
					ontology = {
						ontology_instance
					}
					]]
				}
				local declaration_instance = create_instance({class = "OWL#Declaration", links = links})
				
				compartment.link(compartment, "mapped", property_instance)
				compartment.link(compartment, "mapped", property_domain_instance)
				compartment.link(compartment, "mapped", declaration_instance)
				upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
			end
		}

		compute(attribute)
	end
end


function object_property_pattern(compartment)
	return function()
		local element
		if compartment:get(1):class().name == "Compartment" then
			element = utilities.get_element_from_compartment(compartment)
		else
			element = compartment
		end
		
		local association = {
			
			mapping_condition = function()
				local role_comp = dtp.strict_get_compartment(element, "Role")
				return is_name_ok(role_comp)
			end,
			
			map_pattern = function()
				return dtp.strict_get_compartment(element, "Role"):find("/mapped"):is_not_empty()
						and dtp.strict_get_compartment(element, "InvRole"):find("/mapped"):is_not_empty()
			end,
			
			domain_condition = function()
				local role_comp = dtp.strict_get_compartment(element, "Role")
				local inv_role_comp = dtp.strict_get_compartment(element, "Role")
				local end_node = element:find("/end")
				local start_node = element:find("/start")
				local domain_instance = role_comp:find("/mapped.OWL#ObjectPropertyDomain")
				local range_instance = role_comp:find("/mapped.OWL#ObjectPropertyRange")
				local declaration_instance = role_comp:find("/mapped.OWL#Declaration")
				local property_instance = role_comp:find("/mapped.OWL#ObjectProperty")
				
				local presentation_name = dtp.strict_get_compartment(element, "Role/Name/Name"):attr("value") or ""
				local presentation_namespace = dtp.strict_get_compartment(element, "Role/Name/Namespace"):attr("value") or ""
				local domain_name = property_instance:find("/equivalent/entityIRI"):attr("shortValue") or ""
				local domain_namespace = property_instance:find("/equivalent/entityIRI/namespace"):attr("prefix") or ""
				
				if property_instance:id() == inv_role_comp:find("/mapped.OWL#ObjectProperty"):id() then
					if domain_instance:is_not_empty() and domain_instance:find("/domain/map"):id() == start_node:id() then
						if range_instance:is_not_empty() and range_instance:find("/range/map"):id() == end_node:id() then
							if declaration_instance:is_not_empty() then
								if declaration_instance:find("/entity/equivalent"):id() == property_instance:id() then
									return presentation_name == domain_name and presentation_namespace == domain_namespace and property_instance:size() == 1
								end
							else
								return presentation_name == domain_name and presentation_namespace == domain_namespace and property_instance:size() == 1
							end
						end
					end
				end
				
				return false
			end,
			
			escape_condition = function()
				return false
			end,
			
			delete_proc = function()
				local role_comp = dtp.strict_get_compartment(element, "Role")
				delete_mapped_instances(role_comp, {"Role/Name"})
			end,
			
			create_proc = function()
				local ontology_instance = lQuery("OWL#Ontology"):first()
				local range_class_expression = element:find("/end/mapped.OWL#ClassExpression")
				local domain_class_expression = element:find("/start/mapped.OWL#ClassExpression")
				local attributes = {}
				local links = {}
				
				local role_comp = dtp.strict_get_compartment(element, "Role")
				local inv_role_comp = dtp.strict_get_compartment(element, "InvRole")
				local upper_name_comp = dtp.strict_get_compartment(role_comp, "Name")
				local name_value = dtp.strict_get_compartment(upper_name_comp, "Name"):attr("value") or ""
				local namespace_value = dtp.strict_get_compartment(upper_name_comp, "Namespace"):attr("value") or ""
				
				attributes = {
					value = name_value,
					prefix = namespace_value,
					delim = ":"
				}
				local iri_instance = create_instance({class = "OWL#IRI", attrs = attributes})
				
				if namespace_value ~= "" then
					attributes = {
						prefix = namespace_value,
						IRIprefix = "" -- ???
					}
					links = {
						iri = {
							iri_instance
						}
					}
					create_instance({class = "OWL#Namespace", attrs = attributes, links = links})
				end
				
				links = {
					entityIRI = {
						iri_instance
					}
				}
				local property_entity_instance = create_instance({class = "OWL#ObjectPropertyEntity", links = links})
				
				links = {
					equivalent = {
						property_entity_instance
					}
				}
				local property_instance = create_instance({class = "OWL#ObjectProperty", links = links})
				
				links = {
					objectPropertyExpression = {
						property_instance
					},
					domain = {
						domain_class_expression
					}
				}
				local property_domain_instance = create_instance({class = "OWL#ObjectPropertyDomain", links = links})
				
				links = {
					objectPropertyExpression = {
						property_instance
					},
					range = {
						range_class_expression
					}
				}
				local property_range_instance = create_instance({class = "OWL#ObjectPropertyRange", links = links})
				
				links = {
					entity = {
						property_entity_instance
					}
				}
				local declaration_instance = create_instance({class = "OWL#Declaration", links = links})
				
-- TO-DO: JÂSALINKO UN JÂNOTESTÇ
				role_comp.link(role_comp, "mapped", property_instance)
				role_comp.link(role_comp, "mapped", property_domain_instance)
				role_comp.link(role_comp, "mapped", property_tange_instance)
				role_comp.link(role_comp, "mapped", declaration_instance)
				inv_role_comp.link(inv_role_comp, "mapped", property_instance)
				inv_role_comp.link(inv_role_comp, "mapped", property_domain_instance)
				inv_role_comp.link(inv_role_comp, "mapped", property_tange_instance)
				inv_role_comp.link(inv_role_comp, "mapped", declaration_instance)
				upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
				--[[
				compartment.link(compartment, "mapped", property_instance)
				compartment.link(compartment, "mapped", property_domain_instance)
				compartment.link(compartment, "mapped", declaration_instance)
				upper_name_comp.link(upper_name_comp, "mapped", iri_instance)
				]]
			end
		}

		compute(association)
	end
end


function compute(pattern)
	if pattern.mapping_condition() then
		if pattern.map_pattern() then
			if not pattern.domain_condition() then
				print("DELETE, CREATE")
				pattern.delete_proc()
				pattern.create_proc()
				return true
			end
		else
			print("CREATE")
			pattern.create_proc()
			return true
		end
	else
		if pattern.map_pattern() then
			if not pattern.escape_condition() then
				print("DELETE")
				pattern.delete_proc()
				return true
			end
		end
	end
	
	return false
end

-----

function iri_prefix_chars()
	local s = "( [A-Z] / [a-z] / [0-9] / [\192-\214] / [\216-\246] / [\248-\255] / [_] / [.] / [-] / [/] )+ !."
	return re.compile(s)
end

-----

function link_tables(class_name)
	local tables = {
		Class = {
			"classExpression",
			"classExpressions",
			"subClassExpression",
			"superClassExpression",
			"disjointClassExpressions",
			"equivalent"
		},
		ClassEntity = {
			"equivalent",
			"declaration",
			"entityIRI"
		},
		Declaration = {
			"entity"
		},
		IRI = {
			"entity",
			"namespace"
		},
		DataProperty = {
			"equivalent"
		},
		DataPropertyEntity = {
			"equivalent",
			"declaration",
			"entityIRI"
		},
		DataPropertyDomain = {
			"domain",
			"dataPropertyExpression"
		},
		ObjectProperty = {
			"equivalent",
			"objectPropertyDomain",
			"objectPropertyRange"
		},
		ObjectPropertyEntity = {
			"equivalent",
			"declaration",
			"entityIRI"
		},
		ObjectPropertyDomain = {
			
		}
	}
	
	return tables[string.sub(class_name, 5)]
end

function inv_link_tables(class_name)
	local tables = {
		Class = {
			"mapped",
			"classExpression",
			"classExpressions",
			"subClassExpression",
			"superClassExpression",
			"disjointClassExpressions",
			"domain",
			"range"
		},
		ClassEntity = {
		},
		Declaration = {
			"mapped"
		},
		IRI = {
			"mapped",
			"entityIRI"
		},
		DataProperty = {
			"mapped",
			"dataPropertyExpression",
			"dataPropertyExpressions",
			"subDataPropertyExpression",
			"superDataPropertyExpression"
		},
		DataPropertyEntity = {
		},
		DataPropertyDomain = {
			"mapped"
		}
	}
	
	return tables[string.sub(class_name, 5)]
end

function get_link_string(link_table)
	local links = ""
	
	for _, link in ipairs(link_table) do
		links = links.."/"..link..","
	end
	
	return string.sub(links, 1, string.len(links)-1)
end

function get_inv_link_string(link_table)
	local inv_links = ""
	
	for _, link in ipairs(link_table) do
		inv_links = inv_links.."/inv("..link.."),"
	end
	
	return string.sub(inv_links, 1, string.len(inv_links)-1)
end

-----

function create_instance(t, srt)
	local instance_id = get_instance_id(t['class'], t['attrs'], t['links'], srt)
	
	local instance
	if instance_id ~= "" and lQuery(t['class']):find("[id = '"..instance_id.."']"):is_not_empty() then
		instance =  lQuery(t['class']):find("[id = '"..instance_id.."']")
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

function delete_mapped_instances(root, path_table)
	local mapped_elements = root:find("/mapped")
	root:remove_link("mapped")
	
	local delete_failed = {}
	mapped_elements:each(
		function(mapped_element)
			delete_instance(mapped_element)
			--[[
			if not delete_instance(mapped_element) then -- instance is not deleted
				table.insert(delete_failed, mapped_element)
			end
			]]
		end)
	--[[
	if # delete_failed > 0 then
		-- tries to delete instances one more time
		for _, mapped_element in ipairs(delete_failed) do
			delete_instance(mapped_element)
		end
	end
	]]
	
	if type(path_table) == "table" then
		for _, path in ipairs(path_table) do
			local child = dtp.strict_get_compartment(root, path)
			if child:is_not_empty() then
				delete_mapped_instances(child)
			end
		end
	end
end

function delete_instance(instance)
	local class_name = instance:get(1):class().name
	local links = get_link_string(link_tables(class_name))
	local inv_links = get_inv_link_string(inv_link_tables(class_name))

	if instance:find(inv_links):is_empty() then
		local children = instance:find(links)
		instance:delete()
		
		children:each(
			function(child)
				delete_instance(child)
			end)
		
		return true -- instance is deleted
	end
	
	return false -- instance is not deleted
end

-----

function is_name_ok(element_or_compartment)
	local upper_name = dtp.strict_get_compartment(element_or_compartment, "Name")
	local name = dtp.strict_get_compartment(upper_name, "Name"):attr("value") or ""
	local namespace = dtp.strict_get_compartment(upper_name, "Namespace"):attr("value") or ""
	
	if namespace ~= "" then
		return iri_prefix_chars():match(name) and iri_prefix_chars():match(namespace)
	else
		return iri_prefix_chars():match(name)
	end
end

-----

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
