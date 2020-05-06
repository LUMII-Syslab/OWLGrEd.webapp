module(..., package.seeall)

require("lQuery")
T_to_P = require("tda_to_protege")
d = require("dialog_utilities")
generate_lexical_info = require("OWLCNL_LanguageFields.generate_lexical_info")
require("java")


function OWLGrEd_CNL_UpdateLexicon()
	local diagram = utilities.current_diagram():log()
	local json_str = generate_lexical_info.generate_lexical_info_for_ontology(diagram)
	log("update lexicon called, got", type(json_str)--[[, json_str]]) --Normunds teica sho izdruku nonjemt

	local java_class_name = "lv.lumii.owlgred.cnl.Dispatcher"
	local method_name = "generateLexicon"

	log("Dispatcher.generateLexicon called, got", java.call_static_class_method(java_class_name, method_name, json_str))
end

function LexicalizeOntology()
	--save_as_cnl()
	show_lexicalized_form()
end

function set_display_label(compart)
	local display_compart = get_display_label_compart(compart)
	set_display_label_compart_value(display_compart)
end

function add_display_label(form)
	local parent = form:find("/presentationElement")
	if parent:find("/subCompartment:has(/compartType[id = 'DisplayLabel'])"):is_empty() then
		local compart_type = parent:find("/compartType/subCompartType[id = 'DisplayLabel']")
		core.add_compart(compart_type, parent, "")
	end
end

function set_display_label_for_all_elements(diagram)
	process_classes(diagram)
	process_objects(diagram)
	process_associations(diagram)
	utilities.refresh_only_diagram(diagram)
end

function process_classes(diagram)
	diagram:find("/element:has(/elemType[id = 'Class'])"):each(function(class)
		local display_compart = class:find("/compartment:has(/compartType[id = 'DisplayLabel'])")
		set_display_label_compart_value(display_compart)
		class:find("/compartment/subCompartment:has(/compartType[id = 'Attributes'])/subCompartment:has(/compartType[id = 'DisplayLabel'])"):each(function(compart)
			set_display_label_compart_value(compart)
		end)
	end)
end

function process_objects(diagram)
	diagram:find("/element:has(/elemType[id = 'Object'])"):each(function(object)
		local display_compart = object:find("/compartment:has(/compartType[id = 'DisplayLabel'])")
		set_display_label_compart_value(display_compart)
	end)
end

function process_associations(diagram)
	diagram:find("/element:has(/elemType[id = 'Association'])"):each(function(assoc)
		local direct_display_compart = assoc:find("/compartment:has(/compartType[id = 'Role'])/subCompartment:has(/compartType[id = 'DisplayLabel'])")
		set_display_label_compart_value(direct_display_compart)
		local inverse_display_compart = assoc:find("/compartment:has(/compartType[id = 'InvRole'])/subCompartment:has(/compartType[id = 'DisplayLabel'])")
		set_display_label_compart_value(inverse_display_compart)
	end)
end

function change_render_by_label(compart)
	local elem = utilities.get_element_from_compartment(compart)
	local diagram = elem:find("/child")
	set_display_label_for_all_elements(diagram)
end

function change_language(compart)
	local elem = utilities.get_element_from_compartment(compart)
	local is_rendering_needed = get_renderByLabel_from_seed(elem)
	if is_rendering_needed == "true" then
		local seed = utilities.get_element_from_compartment(compart)
		local diagram = seed:find("/child")
		set_display_label_for_all_elements(diagram)
	end
end

function change_showURIs(compart)
	local elem = utilities.get_element_from_compartment(compart)
	local is_rendering_needed = get_renderByLabel_from_seed(elem)
	if is_rendering_needed == "true" then
		local diagram = elem:find("/child")
		set_display_label_for_all_elements(diagram)
	end
end

function set_display_label_compart_value(display_compart, is_refresh_needed)
	local is_rendering_needed = get_render_by_label(display_compart)
	local elem_type_id = utilities.get_element_from_compartment(display_compart):find("/elemType"):attr("id")
	local display_label_value = ""
	local display_label_input = ""
	
	if elem_type_id == "Link" then
		if display_compart:attr("value")=="" then
			display_label_value = display_compart:find("/parentCompartment/subCompartment:has(/compartType[caption='Property'])"):attr("value")
			display_label_input = display_compart:find("/parentCompartment/subCompartment:has(/compartType[caption='Property'])"):attr("input")
		else
			display_label_value = display_compart:attr("value")
			display_label_input = display_compart:attr("input")
		end
	else
		if is_rendering_needed == "true" then
			local is_showURIs = get_show_URIs(display_compart)
			-- if is_showURIs == "true" then
				-- display_label_value = make_obj_full_name(display_compart)
			-- else
				local language = get_language(display_compart)
				display_label_value = get_label_by_language(display_compart, language)
				if display_label_value == "" then
					--display_label_value = make_obj_full_name(display_compart)
					_, display_label_value = get_ns_and_name(display_compart)
				--end
				elseif is_showURIs == "true" and display_label_value ~= "" and (elem_type_id ~= "Class" or display_compart:find("/compartType/parentCompartType"):attr("id") == "Attributes")  then
					local URI = "URI"
					local name,  namespace = ""
					namespace, name = get_ns_and_name(display_compart)
					if namespace~="" then name = name .. "{" .. namespace .. "}" end
					display_label_value = display_label_value .. "(" .. name .. ")"
				end
			-- end
			if elem_type_id == "Association" then
				_,_,_, name_compart = get_ns_and_name(display_compart)
				name_compart:find("/parentCompartment"):attr({input = ""})
			end
			display_label_input = display_label_value
		else
			_, display_label_value = get_ns_and_name(display_compart)
			if elem_type_id == "Class" then
				display_label_input = display_label_value
			elseif elem_type_id == "Association" then
				_,_,_, name_compart = get_ns_and_name(display_compart)
				core.set_parent_value(name_compart)
			end
		end
		if elem_type_id == "Class" then
			display_label_value = display_label_value:gsub("^%l", string.upper)
			display_label_input = display_label_input:gsub("^%l", string.upper)
		end
	end
	core.set_compartment_and_field(display_compart, display_label_value, display_label_input)
end

function make_obj_full_name(display_compart)
	local ns, name = get_ns_and_name(display_compart)
	if name ~= "" then
		if ns == "" then
			ns = get_default_ns(display_compart)
		end
		return string.format("%s {%s}", name, ns)
	end
	return ""
end

function get_default_ns(display_compart)
	local ontology_name = get_seed(display_compart):find("/compartment:has(/compartType[id = 'Name'])"):attr("value")
	return ontology_name
end

function get_uri(display_compart)
	local ns, name = get_ns_and_name(display_compart)
	local diagram = utilities.get_diagram_from_compartment(display_compart)
	local list = T_to_P.make_global_ns_uri_table(diagram)
	return T_to_P.make_full_object_name(ns, name, list)
end

function get_ns_and_name(compart)
	local parent, role = get_parent_and_role_to_child(compart)
	local parent_name_compart = get_parent_name_compart(parent, role)
	local name_compart = parent_name_compart:find("/subCompartment:has(/compartType[id = 'Name'])")
	local ns_compart = parent_name_compart:find("/subCompartment:has(/compartType[id = 'Namespace'])")
	return ns_compart:attr("value") or "", name_compart:attr("value") or "", ns_compart, name_compart
end

function get_parent_name_compart(parent, role)
	local name_compart = parent:find(string.format("/%s:has(/compartType[id = 'Name'])", role))
	if name_compart:is_empty() then
		local compart_list = {}
		parent:find("/" .. role):each(function(sub_compart)
			table.insert(compart_list, sub_compart)
		end)
		for _, compart in ipairs(compart_list) do
			name_compart = get_parent_name_compart(compart, "subCompartment")
			if name_compart:is_not_empty() then
				break
			end
		end
	end
	return name_compart
end

function get_display_label_compart(compart)
	local parent, role = get_parent_and_role_to_child(compart)
	local display_label = parent:find(string.format("/%s:has(/compartType[id = 'DisplayLabel'])", role))
	if display_label:is_not_empty() then
		return display_label
	else
		return get_display_label_compart(parent)
	end
end

function get_label_by_language(display_label, lang)
	local parent, role = get_parent_and_role_to_child(display_label)
	return parent:find(string.format("/%s:has(/compartType[id = CNL_%s])", role, lang)):attr("value") or ""
end

function get_render_by_label(compart)
	local seed = get_seed(compart)
	return get_renderByLabel_from_seed(seed)
end

function get_language(compart)
	return get_language_from_seed(get_seed(compart))
end

function get_show_URIs(compart)
	return get_showURIs_from_seed(get_seed(compart))
end

function get_renderByLabel_from_seed(seed)
	if get_attr_from_seed(seed, "RenderingLanguage") ~= "" then
		return "true"
	else
		return "false"
	end
end

function get_language_from_seed(seed)
	return get_attr_from_seed(seed, "RenderingLanguage")
end

function get_showURIs_from_seed(seed)
	return get_attr_from_seed(seed, "showURIs")
end

function get_attr_from_seed(seed, id)
	return seed:find(string.format("/compartment:has(/compartType[id = '%s'])", id)):attr("value") or ""
end

function get_seed(compart)
	local diagram = utilities.get_diagram_from_compartment(compart)
	local seed = diagram:find("/parent")
	return seed
end

function get_parent_and_role_to_child(display_label_compart)
	local parent = display_label_compart:find("/element")
	if parent:is_not_empty() then
		return parent, "compartment"
	else
		return display_label_compart:find("/parentCompartment"), "subCompartment"
	end
end

function is_hidden(compart)
	local val = get_render_by_label(compart)
	if val == "true" then
		return true
	else
		return false
	end
end

function is_attributes_read_only()
	local seed = utilities.current_diagram():find("/parent")
	local val = get_renderByLabel_from_seed(seed)
	if val == "true" then
		return true
	else
		return false
	end
end


function cnl_form(ontology_diagram)
	local java = require("java")
	local OWL_specific = require("OWL_specific")

	local ontology_string = escape_quotes(OWL_specific.ontology_functional_form(ontology_diagram))
	print("!!!!!", ontology_string)
	local ontology_name = ontology_diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")
	local ontology_language = ontology_diagram:find("/parent/compartment:has(/compartType[id=RenderingLanguage])"):attr("value")

	local verbalization_spec = string.format([[
{
	"ontology": "%s",
	"owl_fss" : "%s",
	"language": "%s"
}
	]], ontology_name, ontology_string, ontology_language)


	local java_class_name = "lv.lumii.owlgred.cnl.Dispatcher"
	local method_name = "verbalizeOntology"

	print("$$$$$", verbalization_spec)
	local verbalization = java.call_static_class_method(java_class_name, method_name, verbalization_spec)
	print(verbalization)
	return verbalization
end

function save_as_cnl()
	local diagram = utilities.current_diagram()

	local project = lQuery("Project")
	local tag_ = utilities.get_tags(project, "Path")
	local path = tag_:attr("value")
	--path = tda.BrowseForFolder("Save Ontology", path)
	local file_name = diagram:attr("caption")
	path = tda.BrowseForFile("Save", "All Files (*.*)", path or "", file_name, true)
	if path ~= nil and path ~= "" then
		tag_:attr({value = path})
		local ontology_text = cnl_form(diagram)
		print("#####", ontology_text)
		local diagram_name = diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")
		if diagram_name == nil or diagram_name == "" then
			diagram_name = os.tmpname() .. ".txt"
		end
		--local path_to_file = path .. "\\" .. diagram_name .. ".owl"

		--log("------\n", path_to_file, "---------")

		local path_to_file = path
		local export_file = io.open(path_to_file, "w")
		if export_file == nil then
			show_msg("failed to create the file:\n" .. path_to_file)
		else
			export_file:write(json_to_text(ontology_text))
			export_file:close()
		end
	end
end

function add_dynamic_tooltip_translets_and_style()

  dt = require('interpreter.DynamicTooltip')

  elem_type_ids_to_add_dynamic_tooltip = {
    'Class',
    'Association',
    'Generalization',
    'Restriction',
    'HorizontalFork',
    'AssocToFork',
    'GeneralizationToFork',
    'Object',
    'Link',
    'EquivalentClasses',
    'DisjointClasses',
  }

  for _,elemType_id in  ipairs(elem_type_ids_to_add_dynamic_tooltip) do
    dt.add_dynamic_tooltip_to(elemType_id, 'OWLCNL_LanguageFields.OWL_CNL_specific.tooltip')
  end
end

function compose_attribute_input(compart)
	local val = compart:attr("value")
	local display_label_val = compart:find("/subCompartment:has(/compartType[id = 'DisplayLabel'])"):attr("input")
	local input = val
	local name_compart_val = compart:find("/subCompartment:has(/compartType[id = 'Name'])"):attr("input")
	if get_render_by_label(compart) == "true" then
		if display_label_val ~= "" and display_label_val ~= nil then
			local name_len = string.len(name_compart_val)
			local tmp = string.sub(val, 1, name_len)
			if tmp ~= nil then
				val = string.sub(val, name_len+1, string.len(val))
			end
			input = string.format("%s %s", display_label_val, val)
		end
	end
	compart:attr({input = input})
end

function set_attr_display_label(compart)
	local display_compart_parent = compart:find("/parentCompartment/parentCompartment")

	local display_compart = display_compart_parent:find("/subCompartment:has(/compartType[id = 'DisplayLabel'])")
	if display_compart:is_empty() then
		display_compart = core.add_compart(display_compart_parent:find("/compartType/subCompartType[id = 'DisplayLabel']"), display_compart_parent, "")
		local display_label_component = get_display_label_component(compart)
		display_compart:link("component", display_label_component)
	end
	set_display_label_compart_value(display_compart)
end

function get_display_label_component(compart)
	local component = compart:find("/component")
	local form = d.get_form_from_component(component)
	local display_label_component = form:find("/component[id = 'DisplayLabel']/component[id = 'field']")
	return display_label_component
end

function json_to_text(json)
	local s = json:sub(2, json:len()-2) --remove the square brackets
	s = s:gsub('",',"\n")
	s = s:gsub('"',"")
	return s
end

function tooltip(element)
		require("color")
	require("tda_to_protege")

	local ontology_diagram = utilities.get_diagram_from_element(element)
	local ontology_header = tda_to_protege.export_Header(ontology_diagram)
	local element_axioms = tda_to_protege.export_Element(element)
	local ontology_string = string.format('%s%s)', ontology_header, element_axioms)

	local ontology_name = ontology_diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")

	local verbalization_spec = string.format([[
{
	"ontology": "%s",
	"owl_fss" : "%s",
	"language": "en"
}
	]], ontology_name, ontology_string)


	local java_class_name = "lv.lumii.owlgred.cnl.Dispatcher"
	local method_name = "verbalizeOntology"


	local verbalization = java.call_static_class_method(java_class_name, method_name, verbalization_spec)


	local tooltip_color = color.rgb_to_tda_int(color.random_hue_rgb(0.5, 0.95))
	local tooltip_text = verbalization


	return tooltip_color, tooltip_text
end

function verbalize_element(elem) --verbalize the active elements in the diagram, show results in dialog box
	local diagram = utilities.current_diagram()
	--check for generateLexicon tag. If found, generateLexicon is currently running and verbalizeElement will need to be done later
	if utilities.get_tags(diagram, "generateLexicon"):is_not_empty() then
		utilities.add_tag(diagram, "verbalizeElement", "waiting", true)
		utilities.add_tag(utilities.active_elements(), "elementForVerbalize", "waiting", true) --add the tag to the active element(-s) as well, so we know which elements to verbalize
		--show some kind of warning that verbalizeElement will be done later
		tda.ShowInformationBar("generateLexicon is currently running. The requested element(-s) will be verbalized as soon as that is done.")
		return
	else
		--if tag isn't found, proceed as normal
		require("tda_to_protege")

		local element = elem or utilities.active_elements()
		local ontology_diagram = utilities.get_diagram_from_element(element)
		local ontology_header = tda_to_protege.export_Header(ontology_diagram)
		local element_axioms = tda_to_protege.export_Element(element)

		local ontology_string = escape_quotes(string.format('%s%s)', ontology_header, element_axioms))

		local ontology_name = ontology_diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")
		local ontology_language = ontology_diagram:find("/parent/compartment:has(/compartType[id=RenderingLanguage])"):attr("value")

		local verbalization_spec = string.format([[
	{
		"ontology": "%s",
		"owl_fss" : "%s",
		"language": "%s"
	}
		]], ontology_name, ontology_string, ontology_language)

		local java_class_name = "lv.lumii.owlgred.cnl.Dispatcher"
		local method_name = "verbalizeOntology"

		local verbalization = java.call_static_class_method(java_class_name, method_name, verbalization_spec)

		if verbalization == "null: ace_text" then verbalization = "[<<No axioms to verbalize>>] " end

		show_verbalization_form(json_to_text(verbalization))
	end
end

function show_verbalization_form(text)
	local verbalization_form = lQuery.create("D#Form",
	{
		id = "verbalization_form",
		caption = "Axioms related to the element",
		eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLCNL_LanguageFields.OWL_CNL_specific.close_verbalization_form"),
		preferredWidth = 450,
		preferredHeight = 200,
		buttonClickOnClose = false,
		component =
		{
			lQuery.create("D#TextArea",
			{
				readOnly = true,
				text = text
			}),
			lQuery.create("D#HorizontalBox",
			{
				horizontalAlignment = 1,
				component =
				{
					lQuery.create("D#Button",
					{
						caption = "Close",
						eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLCNL_LanguageFields.OWL_CNL_specific.close_verbalization_form"),
					})
				}
			})
		}
	})
	d.show_form(verbalization_form)
end

function close_verbalization_form()
	lQuery("D#Event"):delete()
	utilities.close_form("verbalization_form")
end

function escape_quotes(owl_fss) --escape all " - required for well-formed JSON (Normunds)
	return owl_fss:gsub('"', '\\"')
end

function show_lexicalized_form()
	local diagram = utilities.current_diagram()

	--check for generateLexicon tag. If found, generateLexicon is currently running and verbalization will need to be done later
	if utilities.get_tags(diagram, "generateLexicon"):is_not_empty() then
		utilities.add_tag(diagram, "verbalizeOntology", "waiting", true)
		--show some kind of warning that verbalizeOntology will be done later
		tda.ShowInformationBar("generateLexicon is currently running. The ontology will be verbalized as soon as that is done.")
		return
	else
		--if tag wasn't found, proceed as normal
		local ontology_text = cnl_form(diagram)

		local lexicalize_result = json_to_text(ontology_text)

		if lexicalize_result == "null: ace_text" then lexicalize_result = "[<<No axioms to verbalize>>] " end

		local results_form = lQuery.create("D#Form",
		{
			id = "results_form",
			caption = "Ontology in Controlled Natural Language",
			eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLCNL_LanguageFields.OWL_CNL_specific.close_results_form"),
			preferredWidth = 450,
			preferredHeight = 500,
			buttonClickOnClose = false,
			component =
			{
				lQuery.create("D#TextArea",
				{
					readOnly = true,
					id = "cnl_results_area",
					text = lexicalize_result
				}),
				lQuery.create("D#HorizontalBox",
				{
					horizontalAlignment = 1,
					component =
					{
						lQuery.create("D#HorizontalBox",
						{
							component =
							{
								lQuery.create("D#Button",
								{
									caption = "Save to file",
									eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLCNL_LanguageFields.OWL_CNL_specific.save_cnl_to_file")
								})
							}
						}),
						lQuery.create("D#HorizontalBox",
						{
							horizontalAlignment = 1,
							component =
							{
								lQuery.create("D#Button",
								{
									caption = "Close",
									eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLCNL_LanguageFields.OWL_CNL_specific.close_results_form"),
								})
							}
						})
					}
				})
			}
		})

		d.show_form(results_form)
	end
end

function close_results_form()
	lQuery("D#Event"):delete()
	utilities.close_form("results_form")
end

function generateNames()

end

function save_cnl_to_file()
	local text = lQuery("D#TextArea[id=cnl_results_area]"):attr("text")
	--the following code was mostly copied from save_as_cnl()
	local diagram = utilities.current_diagram()
	local project = lQuery("Project")
	local tag_ = utilities.get_tags(project, "Path")
	local path = tag_:attr("value")
	local file_name = diagram:attr("caption")
	path = tda.BrowseForFile("Save", "Text file (*.txt)", path or "", file_name, true)
	if path ~= nil and path ~= "" then
		tag_:attr({value = path})
		local diagram_name = diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")
		if diagram_name == nil or diagram_name == "" then
			diagram_name = os.tmpname() .. ".txt"
		end
		local path_to_file = path
		local export_file = io.open(path_to_file, "w")
		if export_file == nil then
			show_msg("failed to create the file:\n" .. path_to_file)
		else
			export_file:write(text)
			export_file:close()
		end
	end
end

function verbalize_elements_to_table()
	require("tda_to_protege")
	local mp = require ("ManchesterParser")

	local verbalization_table = {}

	local ontology_diagram = utilities.current_diagram()
	local ontology_header = tda_to_protege.export_Header(ontology_diagram) --verbalization needs all kinds of header info; since it's the same for all elements, collect it beforehand
	local ontology_name = ontology_diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")
	local ontology_language = ontology_diagram:find("/parent/compartment:has(/compartType[id=RenderingLanguage])"):attr("value")

	local ontology_text = OWL_specific.ontology_functional_form(ontology_diagram) --save the ontology to file; used for Class verbalization
	local path

	if tda.isWeb then 
		path = tda.GetRuntimePath().."/temp_for_class_verbalization.owl"
	else
		path = tda.GetRuntimePath().."\\temp_for_class_verbalization.owl"
	end
	local combinedString = path.."\nFunctional\n"..ontology_text
	java.call_static_class_method("OntologySaver", "saveOntologyToFile", combinedString)
	local referencing_axioms = java.call_static_class_method("AxiomCollector", "collectAxiomsForEntities", path) --pass ontology file to Java, get a table of axioms somehow encoded in a string

	printToFile(referencing_axioms)

	local referencing_axiom_table = string_split(referencing_axioms, "]\n")

	for i, v in ipairs(referencing_axiom_table) do
		referencing_axiom_table[i] = string_split(v, "=%[") --escape the [, because Lua wants to do some kind of pattern matching here
	end

	for i, v in ipairs(referencing_axiom_table) do --one last conversion for the table into a different format
		local objectType = v[1] --currently, this is Class, Object or ObjectProperty
		referencing_axiom_table[objectType] = string_split(v[2], "}\n")
		for key, val in ipairs(referencing_axiom_table[objectType]) do
			referencing_axiom_table[objectType][key] = string_split(val, ":{")
			local iri = referencing_axiom_table[objectType][key][1]
			referencing_axiom_table[objectType][iri] = referencing_axiom_table[objectType][key][2]:gsub("; ", "\n")
			referencing_axiom_table[objectType][key] = nil
		end
		referencing_axiom_table[i] = nil
	end

	for iri, axioms in pairs(referencing_axiom_table.Class) do --this block will rearrange classes in DisjointClasses axioms
		local axiom_table = string_split(axioms, '\n')
		local s = ""
		for i, axiom in ipairs(axiom_table) do
			axiom_table[i] = rewrite_disjoint_classes_axiom_for_class(axiom, iri)
			s = s..axiom_table[i].."\n"
		end
		s = s:sub(1, s:len()-1) --remove the last "\n"
		referencing_axiom_table.Class[iri] = s
	end

	ontology_diagram:find("/element"):each( --verbalize each element separately
		function (elem)
			--[[
			local element_axioms = ""
			local elem_type_name = utilities.get_obj_type(elem):attr("id")
			if elem_type_name == "Class" or elem_type_name == "Object" then --class verbalization will be different for now
				local name = elem:find("/compartment/subCompartment:has(/compartType[id=Name])"):attr("value")
				local namespace = elem:find("/compartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
				full_name = tda_to_protege.get_full_class_name_by_name_and_ns(name, namespace)
				full_name = full_name:sub(2, full_name:len() - 1) --remove the <> around class name
				element_axioms = referencing_axiom_table[elem_type_name][full_name] or ""
			else
				if elem_type_name == "Association" then
					local name = elem:find("/compartment:has(/compartType[id=Role])/subCompartment/subCompartment:has(/compartType[id=Name])"):attr("value")
					local namespace = elem:find("/compartment:has(/compartType[id=Role])/subCompartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
					local full_name = tda_to_protege.get_full_class_name_by_name_and_ns(name, namespace)
					full_name = full_name:sub(2, full_name:len() - 1)
					local inv_name = elem:find("/compartment:has(/compartType[id=InvRole])/subCompartment/subCompartment:has(/compartType[id=Name])"):attr("value")
					local inv_namespace = elem:find("/compartment:has(/compartType[id=InvRole])/subCompartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
					local inv_full_name = tda_to_protege.get_full_class_name_by_name_and_ns(inv_name, inv_namespace)
					inv_full_name = inv_full_name:sub(2, inv_full_name:len() - 1)
					local role_axioms = referencing_axiom_table[elem_type_name][full_name] or ""
					local inv_role_axioms = referencing_axiom_table[elem_type_name][inv_full_name] or ""
					element_axioms = role_axioms.."\n"..inv_role_axioms
				else
					element_axioms = tda_to_protege.export_Element(elem)
				end
			end]]

			local element_axiom_table = string_split(tda_to_protege.export_Element(elem)..'\nAnnotationAssertion(rdfs:label "delim"^^xsd:string)\n', "\n") --AnnotationAssertion(rdfs:label ..) will be converted into a
			--delimiting string that separates direct verbalization from the axioms found with Java
			local elem_type_name = utilities.get_obj_type(elem):attr("id")
			if elem_type_name == "Class" or elem_type_name == "Object" then --use the axioms obtained with Java for classes, individuals and object properties
				local name = elem:find("/compartment/subCompartment:has(/compartType[id=Name])"):attr("value")
				local namespace = elem:find("/compartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
				full_name = tda_to_protege.get_full_class_name_by_name_and_ns(name, namespace)
				full_name = full_name:sub(2, full_name:len() - 1) --remove the <> around class name
				local java_axiom_table = rewrite_disjoint_classes_in_table(string_split(referencing_axiom_table[elem_type_name][full_name], "\n"), full_name)
				element_axiom_table = combine_tables_no_duplicates(element_axiom_table, java_axiom_table, name)
			end
			if elem_type_name == "Association" then
				local name = elem:find("/compartment:has(/compartType[id=Role])/subCompartment/subCompartment:has(/compartType[id=Name])"):attr("value")
				local namespace = elem:find("/compartment:has(/compartType[id=Role])/subCompartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
				local full_name = tda_to_protege.get_full_class_name_by_name_and_ns(name, namespace)
				full_name = full_name:sub(2, full_name:len() - 1)
				local inv_name = elem:find("/compartment:has(/compartType[id=InvRole])/subCompartment/subCompartment:has(/compartType[id=Name])"):attr("value")
				local inv_namespace = elem:find("/compartment:has(/compartType[id=InvRole])/subCompartment/subCompartment:has(/compartType[id=Namespace])"):attr("value")
				local inv_full_name = tda_to_protege.get_full_class_name_by_name_and_ns(inv_name, inv_namespace)
				inv_full_name = inv_full_name:sub(2, inv_full_name:len() - 1)
				local java_role_axioms = string_split(referencing_axiom_table[elem_type_name][full_name], "\n")
				local java_inv_role_axioms = string_split(referencing_axiom_table[elem_type_name][inv_full_name], "\n")
				element_axiom_table = combine_tables_no_duplicates(element_axiom_table, java_role_axioms, name)
				element_axiom_table = combine_tables_no_duplicates(element_axiom_table, java_inv_role_axioms, name.."-inv")
			end

			local element_axioms = table_to_string(element_axiom_table, "\n")

			if element_axioms ~= "" then
				local ontology_string = escape_quotes(string.format('%s%s)', ontology_header, element_axioms))

				local ontology_name = ontology_diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")
				local ontology_language = ontology_diagram:find("/parent/compartment:has(/compartType[id=RenderingLanguage])"):attr("value")

				local verbalization_spec = string.format([[
			{
				"ontology": "%s",
				"owl_fss" : "%s",
				"language": "%s"
			}
				]], ontology_name, ontology_string, ontology_language)

				local java_class_name = "lv.lumii.owlgred.cnl.Dispatcher"
				local method_name = "verbalizeOntology"

				local verbalization = java.call_static_class_method(java_class_name, method_name, verbalization_spec)

				local elem_title = ""
				if elem_type_name == "Class" or elem_type_name == "Object" then elem_title = elem:find("/compartment/subCompartment:has(/compartType[id=Name])"):attr("value") end
				if elem_type_name == "Association" then
					local name = elem:find("/compartment:has(/compartType[id=Role])/subCompartment/subCompartment:has(/compartType[id=Name])"):attr("value")
					local inv_name = elem:find("/compartment:has(/compartType[id=InvRole])/subCompartment/subCompartment:has(/compartType[id=Name])"):attr("value")
					if name ~= "" and inv_name ~= "" then elem_title = name.."/"..inv_name else elem_title = name..inv_name end
				end
				if elem_type_name == "Link" then
					local name = elem:find("/compartment/subCompartment:has(/compartType[id=Property])"):attr("value") or ""
					local inv_name = elem:find("/compartment/subCompartment:has(/compartType[id=InvProperty])"):attr("value") or ""
					if name ~= "" and inv_name ~= "" then elem_title = name.."/"..inv_name else elem_title = name..inv_name end
				end
				if elem_title == "" then elem_title = elem_type_name end

				if verbalization ~= "null: ace_text" then verbalization_table[elem:id()] = {name = elem_title, verbalizations = string_split(json_to_text(verbalization), "\n")} end --as required, each CNL sentence is a separate item in a table
				if verbalization ~= "null: ace_text" then
					local sentences = string_split(json_to_text(verbalization), "\n")
					sentences = remove_duplicates(sentences)
					verbalization_table[elem:id()] = {name = elem_title, verbalizations = sentences}
				end
			end

		end
	)
	local mp = require("ManchesterParser")
	os.execute("cls")
	mp.printTable(verbalization_table, 0)
	return verbalization_table
end

function string_split(str, delim) --splits str into substrings wherever delim is found. Substrings don't include delim. Results are returned as a table
	local results = {}
	local s = str or ""
	while true do
		local pos_begin, pos_end = s:find(delim)
		if pos_begin == nil then break end
		local r = s:sub(1, pos_begin - 1)
		--if r ~= "" and r ~= nil then
		if r ~= nil then --removed the r ~= "" clause so that the verbalization can contain delimiting empty lines
			table.insert(results, r)
			s = s:sub(pos_end + 1) or ""
		end
	end
	if s ~= "" and s ~= nil then table.insert(results, s) end
	return results
end

function table_to_string(t, delim) --Gets table t, containing strings, and a delim string. Combines the strings into one string, separated by delim
	local res = ""
	for i, v in ipairs(t) do res = res..v..'\n' end
	return res
end

function combine_tables_no_duplicates(t1, t2, fname) --gets two tables containing strings. Adds the strings from t2 to t1, checking for duplicates beforehand. Duplicate checking is case-insensitive
	--local export_file = io.open(fname..".txt", "w")
	--local mp = require("ManchesterParser")
	--print("------------------------TABLE 1-------------------------")
	--export_file:write("-----------------TABLE 1-----------------------------\n")
	--for i, v in ipairs(t1) do export_file:write(i..": "..v.."\n") end
	--mp.printTable(t1, 0)
	--print("------------------------TABLE 2-------------------------")
	--export_file:write("-----------------TABLE 2-----------------------------\n")
	--for i, v in ipairs(t2) do export_file:write(i..": "..v.."\n") end
	--mp.printTable(t2, 0)
	for i, v in ipairs (t2) do
		local axiom_upper = v:upper()
		local can_add = true
		for a, b in ipairs(t1) do
			if b:upper() == axiom_upper then can_add = false end
		end
		if can_add then table.insert(t1, v) end
	end
	--export_file:write("-----------------TABLE 3-----------------------------\n")
	--for i, v in ipairs(t1) do export_file:write(i..": "..v.."\n") end
	--export_file:close()
	return t1
end

function remove_duplicates (t) --t contains strings. This function removes duplicate strings (other than blank lines), and replaces multiple consecutive blank lines with just one
	for i, v in ipairs(t) do --this block removes duplicate strings
		for a = 1, i - 1 do
			if t[a] ~= nil and t[i] ~= nil and t[i] ~= "" then --only do comparing if neither string is nil and the current isn't empty (blank line)
				if string.upper(t[a]) == string.upper(t[i]) then t[i] = nil end
			end
		end
	end
	for i, v in ipairs(t) do --this block removes consecutive empty lines
		if i > 1 then
			if t[i] == "" and t[i-1] == "" then t[i] = nil end
		end
	end
	return t
end

function rewrite_disjoint_classes_in_table(t, class)
	for i, v in ipairs(t) do t[i] = rewrite_disjoint_classes_axiom_for_class(v, class) end
	return t
end

function printToFile(str)
	local export_file = io.open("randomstuff.txt", "w")
	export_file:write(str)
	export_file:close()
end

function generate_lexicon_for_parallel_process() --this function needs to be called to a parallel thread
	local diagram = utilities.current_diagram()

	--add tag to the current diagram
	utilities.add_tag(diagram, "generateLexicon", "in progress", true)

	--generateLexicon
	OWLGrEd_CNL_UpdateLexicon()

	--remove tag from diagram
	utilities.get_tags(diagram, "generateLexicon"):delete()

	--if the user tried to verbalize the ontology or some elements of it during the generateLexicon process, complete that action now
	if utilities.get_tags(diagram, "verbalizeOntology"):is_not_empty() then
		show_lexicalized_form()
		utilities.get_tags(diagram, "verbalizeOntology"):delete()
	end

	if utilities.get_tags(diagram, "verbalizeElement"):is_not_empty() then
		local elem = lQuery("Tag[key=elementForVerbalize]/thing") --the element(-s) to verbalize
		verbalize_element(elem)
		utilities.get_tags(elem, "elementForVerbalize"):delete()
		utilities.get_tags(diagram, "verbalizeElement"):delete()
	end
end

function rewrite_disjoint_classes_axiom_for_class(axiom, class) --reorder classes in the DisjointClasses axiom so that class is first. For any other axiom, no changes will be applied
	require "re"
	local disjoint_classes_grammar = [[
		axiom	<-	(
						"DisjointClasses("
						' '?
						'<' {:firstClass: iri :} '>'
						' '
						'<' {:secondClass: iri :} '>'
						")"
					) -> {}
		iri		<-	(
						%char+
					)
	]]
	local class_table =
	{
		char = re.compile("[\32-\59] / '=' / [\63-\126]")
	}

	local grammar = re.compile(disjoint_classes_grammar, class_table)
	local disjoint_table = grammar:match(axiom)
	if disjoint_table == nil then return axiom end
	if disjoint_table.firstClass == class then return "DisjointClasses(<"..disjoint_table.firstClass.."> <"..disjoint_table.secondClass..">)" end
	return "DisjointClasses(<"..disjoint_table.secondClass.."> <"..disjoint_table.firstClass..">)"
end
