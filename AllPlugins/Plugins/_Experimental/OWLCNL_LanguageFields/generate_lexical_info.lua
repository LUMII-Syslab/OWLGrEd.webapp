module(...,package.seeall)

function generate_lexical_info_for_ontology(diagram)
	local languages = --put any new languages in here
	{
		{
			language = "en",
			compart_name = "CNL_English"
		},
		{
			language = "lv",
			compart_name = "CNL_Latvian"
		}
	}

	--this block collects all objects that need to be lexicalized and groups them by the namespace used
	local things_by_namespace = {} --each ontology prefix will be a collection of all lexicalizable items that use that prefix
	diagram:find("/element:has(/elemType[id=Class])"):each(
		function(class)
			local class_ns = class:find("/compartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
			if things_by_namespace[class_ns] == nil then things_by_namespace[class_ns] = class else things_by_namespace[class_ns] = things_by_namespace[class_ns]:add(class) end --first, add all classes to things_by_namespace
			--next, add all attributes
			class:find("/compartment:has(/compartType[id=ASFictitiousAttributes])/subCompartment:has(/compartType[id=Attributes])"):each(
				function(attribute)
					local attr_ns = attribute:find("/subCompartment/subCompartment:has(/compartType[id=Namespace])"):attr("value") or ""
					if things_by_namespace[attr_ns] == nil  then things_by_namespace[attr_ns] = attribute else things_by_namespace[attr_ns] = things_by_namespace[attr_ns]:add(attribute) end
				end
			)
		end
	)
	diagram:find("/element:has(/elemType[id=Object])"):each(
		function(individual)
			local individual_ns = individual:find("/compartment/subCompartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
			if things_by_namespace[individual_ns] == nil then things_by_namespace[individual_ns] = individual else things_by_namespace[individual_ns] = things_by_namespace[individual_ns]:add(individual) end --next, add all individuals to things_by_namespace
		end
	)
	diagram:find("/element:has(/elemType[id=Association])"):each(
		function(association) --an association represents two object properties that can potentially use different namespaces, so two additions need to be performed
			local role_compart = association:find("/compartment:has(/compartType[id=Role])")
			local inv_role_compart = association:find("/compartment:has(/compartType[id=InvRole])")
			local role_ns = role_compart:find("/subCompartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
			local inv_role_ns = inv_role_compart:find("/subCompartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
			if things_by_namespace[role_ns] == nil then things_by_namespace[role_ns] = role_compart else things_by_namespace[role_ns] = things_by_namespace[role_ns]:add(role_compart) end
			if things_by_namespace[inv_role_ns] == nil then things_by_namespace[inv_role_ns] = inv_role_compart else things_by_namespace[inv_role_ns] = things_by_namespace[inv_role_ns]:add(inv_role_compart) end
		end
	)

	local ontology_name = diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")

	--begin generating the lexical information string
	local json_string = '[{"ontology": "'..ontology_name..'","namespace": ""},'

	for key, namespace in pairs(things_by_namespace) do
		namespace:each(
			function(item)
				local item_type = item:find("/elemType"):attr("id") or item:find("/compartType"):attr("id")
				if item_type == "Class" then json_string = json_string..generate_lexicon_for_class(item, languages, key) end
				if item_type == "Object" then json_string = json_string..generate_lexicon_for_individual(item, languages, key) end
				if item_type == "Attributes" then json_string = json_string..generate_lexicon_for_data_property(item, languages, key) end
				if item_type == "Role" or item_type == "InvRole" then json_string = json_string..generate_lexicon_for_object_property(item, languages, key) end
			end
		)
	end
	json_string = json_string:sub(1,-2).."]" --remove the last comma and add the closing square bracket
	return json_string
end

function generate_lexicon_for_class(element, language_table, onto_namespace)
	local class_uri = element:find("/compartment:has(/compartType[id=Name])"):attr("value")
	if class_uri == "" then return "" end --blank classes shouldn't be lexicalized

	local json_entry_table = {element = "class", URI = class_uri, namespace = onto_namespace} --element, URI and namespace are fields that are guaranteed to be in the JSON
	for i, language in ipairs(language_table) do
		local lang_compart = element:find("/compartment:has(/compartType[id="..language.compart_name.."])")
		if lang_compart:find("/tag[key=CNL_JSON]"):is_not_empty() then
			local table_from_tag = parse_json(lang_compart:find("/tag[key=CNL_JSON]"):attr("value")) --gather all information from a specific language JSON tag
			local transformed = transform_table(table_from_tag, language.language) --turn table from {{"key1","value1"},...} into {language.key1 = "value1", language.key2 = "value2",...}
			json_entry_table = merge_tables(json_entry_table, transformed) --merge the table of new entries into the already existing table
		end
	end
	json_entry_table = filter_json_rows(json_entry_table, "class") --remove unneeded lines from the result table
	return generate_json_from_table(json_entry_table) --generate a JSON string from all the information gathered about this particular element
end

function generate_lexicon_for_individual(element, language_table, onto_namespace) --everything works here just like in the generate_lexicon_for_class function
	local individual_uri = element:find("/compartment/subCompartment:has(/compartType[id=Name])"):attr("value")
	if individual_uri == "" then return "" end --blank individuals shouldn't be lexicalized

	local json_entry_table = {element = "individual", URI = individual_uri, namespace = onto_namespace}
	for i, language in ipairs(language_table) do
		local lang_compart = element:find("/compartment:has(/compartType[id="..language.compart_name.."])")
		if lang_compart:find("/tag[key=CNL_JSON]"):is_not_empty() then
			local table_from_tag = parse_json(lang_compart:find("/tag[key=CNL_JSON]"):attr("value"))
			local transformed = transform_table(table_from_tag, language.language)
			json_entry_table = merge_tables(json_entry_table, transformed)
		end
	end
	json_entry_table = filter_json_rows(json_entry_table, "individual")
	return generate_json_from_table(json_entry_table)
end

function generate_lexicon_for_data_property(compartment, language_table, onto_namespace)
	local data_property_uri = compartment:find("/subCompartment:has(/compartType[id=Name])"):attr("value")
	if data_property_uri == "" then return "" end --blank data properties shouldn't be lexicalized

	local json_entry_table = {element = "dataProperty", URI = data_property_uri, namespace = onto_namespace}
	for i, language in ipairs(language_table) do
		local lang_compart = compartment:find("/subCompartment:has(/compartType[id="..language.compart_name.."])")
		if lang_compart:find("/tag[key=CNL_JSON]"):is_not_empty() then
			local table_from_tag = parse_json(lang_compart:find("/tag[key=CNL_JSON]"):attr("value"))
			local transformed = transform_table(table_from_tag, language.language)
			json_entry_table = merge_tables(json_entry_table, transformed)
		end
	end
	json_entry_table = filter_json_rows(json_entry_table, "dataProperty")
	return generate_json_from_table(json_entry_table)
end

function generate_lexicon_for_object_property(compartment, language_table, onto_namespace)
	local object_property_uri = compartment:find("/subCompartment:has(/compartType[id=Name])"):attr("value")
	if object_property_uri == "" then return "" end --to prevent the addition of a blank objectProperty (invRole, when just the Role has been shown in the diagram)

	local json_entry_table = {element = "objectProperty", URI = object_property_uri, namespace = onto_namespace}
	json_entry_table["entry.POS"] = compartment:find("/subCompartment:has(/compartType[id=CNL_NounVerb])"):attr("value") --the compartment says whether the property is a noun or verb
	for i, language in ipairs(language_table) do
		local lang_compart = compartment:find("/subCompartment:has(/compartType[id="..language.compart_name.."])")
		if lang_compart:find("/tag[key=CNL_JSON]"):is_not_empty() then
			local table_from_tag = parse_json(lang_compart:find("/tag[key=CNL_JSON]"):attr("value"))
			local transformed = transform_table(table_from_tag, language.language)
			json_entry_table = merge_tables(json_entry_table, transformed)
		end
	end
	json_entry_table = filter_json_rows(json_entry_table, "objectProperty")
	return generate_json_from_table(json_entry_table)
end

function generate_json_from_table(t) --t is a table containing JSON entries. This function turns that table intro a string
	local json = "{"
	for key, value in pairs(t) do
		local s = ""
		if value ~= "null" then s = '"'..key..'": "'..value..'",' else s = '"'..key..'": '..value..',' end
		json = json..s
	end
	json = json:sub(1,-2).."}," --a comma is placed after a key-value pair, not before. Therefore, the last one needs to be removed after processing all pairs
	return json
end

--tags in OWLGrEd contain JSONs with lots of spare/incomplete information. re will be used to disassemble whatever is there into a more manageable form (string -> table)
require "re"
local json_grammar = [[
	json		<-	(
						whitespace*
						'{'
						whitespace*
						entry
						whitespace*
						(',' whitespace* entry)*
						whitespace*
						'}'
						whitespace*
					) -> {}
	entry		<-	(
						'"'{:key: thing :}'"'
						whitespace*
						':'
						whitespace*
						('"'{:value: thing :}'"' / {:value: "null" -> "null" :})
					) -> {}
	thing		<-	(
						%char*
					)
	whitespace	<-	(
						%s
					)
]]

local symbol_table =
{
	char = re.compile("[\1-\33] / [\35-\255]")
}

function parse_json(s) --s contains JSON information in a string. This function converts that string into a table
	local g = re.compile(json_grammar, symbol_table)
	local t = g:match(s)
	return t
end

function transform_table(t, language) --t is in format {{"key1","value1"},{"key2","value2"},...}. It needs to be transformed into {key1="value1",key2="value2",...} for the function generate_json_from_table
	for i, subtable in ipairs(t) do
		if string.sub(subtable.key, 1, 10) == "predicate." then subtable.key = string.sub(subtable.key, 11) end --added to remove 'predicate.' from keys - TRAC ticket #525
		t[language..'.'..subtable.key] = subtable.value
		t[i] = nil
	end
	return t
end

function merge_tables(t1,t2) --merges two tables into one. If two elements have the same key, the one from t2 takes precedence (but it doesn't matter in calls from this file)
	for key, value in pairs(t2) do t1[key] = value end
	return t1
end

function filter_json_rows(t, element_type) --the table as generated previously contains lots of irrelevant entries. This function removes those, leaving only the necessary ones (according to CNL javadoc)
	local elements_to_remain =  --this table will contain all keywords that are to be preserved when filtering the JSON. Any other key-value pairs will be discarded
	{
		class =
		{
			"element",
			"URI",
			"namespace",
			"en.entry.singular",
			"en.entry.plural",
			"en.entry.gender",
			"lv.entry.components",
			"lv.entry.pattern",
			"lv.entry.number",
			"lv.entry.gender"
		},
		individual =
		{
			"element",
			"URI",
			"namespace",
			"en.entry.singular",
			"en.entry.plural",
			"en.entry.gender",
			"lv.entry.components",
			"lv.entry.pattern",
			"lv.entry.number",
			"lv.entry.gender"
		},
		dataProperty =
		{
			"element",
			"URI",
			"namespace",
			"en.entry.singular",
			"en.entry.plural",
			"en.entry.gender",
			"lv.entry.components",
			"lv.entry.pattern",
			"lv.entry.number",
			"lv.entry.gender"
		},
		objectProperty =
		{
			"element",
			"URI",
			"namespace",
			"entry.POS",
			"en.entry.infinitive",
			"en.entry.present",
			"en.entry.participle",
			"en.entry.preposition",
			"en.entry.voice",
			"en.entry.tense",
			"en.entry.singular",
			"en.entry.plural",
			"en.entry.gender",
			"lv.entry.infinitive",
			"lv.entry.present",
			"lv.entry.past",
			"lv.entry.preposition",
			"lv.entry.voice",
			"lv.entry.tense",
			"lv.entry.subject",
			"lv.entry.object",
			"lv.entry.components",
			"lv.entry.pattern",
			"lv.entry.number",
			"lv.entry.gender"
		}
	}
	local filtered_table = {}
	for key, value in pairs(t) do
		if table_contains_entry(elements_to_remain[element_type],key) then filtered_table[key] = value end
	end
	return filtered_table
end

function table_contains_entry(t, entry)
	for i, value in ipairs(t) do
		if value == entry then return true end
	end
	return false
end

function printTable(t,indent) --used as test function, not necessary in the final version. Prints a table along with any subtables it may have
--can be used to examine the structure of tables re creates when given the grammar (see end of file for structure description)
	for k,v in pairs(t) do
		if type(v) == "table" then
			s = ""
			for i = 1, indent do s = s.." " end
			print (s..k..": ")
			printTable(v,indent+2)
		else
			s = ""
			for i = 1, indent do s = s.." " end
			print(s..k..": "..v)
		end
	end
end
