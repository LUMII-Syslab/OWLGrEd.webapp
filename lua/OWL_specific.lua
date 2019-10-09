module(..., package.seeall)

require("lQuery")
require("utilities")
require "mii_rep_obj"
require "core"
require "java" --for save_ontology_diagram
T_to_P = require "tda_to_protege"
d = require("dialog_utilities")
CutCopyPaste = require("interpreter.CutCopyPaste")
Delete = require("interpreter.Delete")
require("config_properties")
require("re")
gdsu = require("graph_diagram_style_utils")

function copy_paste_diagram_seed(elem)
	CutCopyPaste.copy_paste_diagram_seed(elem)
end

function change_OWL_link_style(link)
	set_link_style(link, false)
end

function change_OWL_link_style_from_compartment(compart)
	set_link_style(core.get_compartment_element(compart), true)
	return ""
end

function set_link_style(link, is_refresh_needed)
	decide_style_for_line(link, "/compartment/subCompartment:has(/compartType[id = 'Property'])", "/compartment/subCompartment:has(/compartType[id = 'InvProperty'])", "Link", "Link_inverse", "Link_direct", "Link_both_end", is_refresh_needed)
end

function change_OWL_assoc_style(assoc)
	local direct_path, inv_path, default_name, inverse_name, direct_name, both = get_assoc_style_args()
	decide_style_for_line(assoc, direct_path, inv_path, default_name, inverse_name, direct_name, both, false)
	return ""
end

function change_OWL_assoc_style_from_compartment(compart)
	set_assoc_style(compart, true)
	return ""
end

function get_paths_to_assoc_names()
	return "/compartment:has(/compartType[id = 'Role'])/subCompartment/subCompartment:has(/compartType[id = 'Name'])", "/compartment:has(/compartType[id = 'InvRole'])/subCompartment/subCompartment:has(/compartType[id = 'Name'])"
end

function get_assoc_style_args()
	local path1, path2 = get_paths_to_assoc_names()
	return path1, path2, "Association", "Association_inverse", "Association_direct", "Association_both_end"
end

function set_assoc_style(compart, is_refresh_needed)
	local direct_path, inv_path = get_paths_to_assoc_names()
	local assoc = core.get_compartment_element(compart)
	local direct_compart = assoc:find("/compartment:has(/compartType[id = 'Role'])/subCompartment:has(/compartType[id = 'IsComposition'])")
		local direct_value = direct_compart:attr_e("value")
		local direct_name = assoc:find(direct_path):attr_e("value")
	local inverse_compart = assoc:find("/compartment:has(/compartType[id = 'InvRole'])/subCompartment:has(/compartType[id = 'IsComposition'])")
		local inverse_value = inverse_compart:attr_e("value")
		local inverse_name = assoc:find(inv_path):attr_e("value")
--decision making
	if direct_value ~= "true" and inverse_value ~= "true" then
		local direct_path, inv_path, default_name, inverse_name, direct_name, both = get_assoc_style_args()
		decide_style_for_line(assoc, direct_path, inv_path, default_name, inverse_name, direct_name, both, is_refresh_needed)
	else
		if direct_value == "true" and inverse_value == "true" then
			local tmp_compart = compart:find(":has(/compartType[id = 'IsComposition'])")
			if tmp_compart:size() > 0 then
				inverse_compart:attr("value", "false")
				inverse_value = "false"
				local field = inverse_compart:find("/component"):attr({checked = inverse_value})
				if is_refresh_needed then
					utilities.refresh_form_component(field)
				end
			else
				direct_compart:attr("value", "false")
				direct_value = "false"
				local field = direct_compart:find("/component"):attr({checked = direct_value})
				if is_refresh_needed then
					utilities.refresh_form_component(field)
				end
			end
		end
		if direct_value == "true" and inverse_name ~= "" then
			set_OWL_assoc_style(assoc, "Composition_reverse_with_end", is_refresh_needed)
		elseif direct_value == "true" and inverse_name == "" then
			set_OWL_assoc_style(assoc, "Composition_reverse", is_refresh_needed)
		elseif inverse_value == "true" and direct_name ~= "" then
			set_OWL_assoc_style(assoc, "Composition_with_end", is_refresh_needed)
		elseif inverse_value == "true" and direct_name == "" then
			set_OWL_assoc_style(assoc, "Composition", is_refresh_needed)
		end
	end
	return ""
end

function decide_style_for_line(assoc, direct_path, inv_path, default_name, inverse_name, direct_name, both, is_refresh_needed)
	local direct_value = assoc:find(direct_path):attr_e("value")
	local inv_value = assoc:find(inv_path):attr_e("value")
	if direct_value == "" and inv_value == "" then
		set_OWL_assoc_style(assoc, default_name)
	elseif direct_value == "" and inv_value ~= "" then
		set_OWL_assoc_style(assoc, inverse_name)
	elseif inv_value == "" and direct_value ~= "" then
		set_OWL_assoc_style(assoc, direct_name)
	else
		set_OWL_assoc_style(assoc, both)
	end
end

function set_OWL_assoc_style(assoc, style_name, is_refresh_needed)
	assoc:remove_link("elemStyle")
	assoc:link("elemStyle", lQuery("/elemType/elemStyle[id = " .. style_name .. "]"))
	if is_refresh_needed then
		utilities.enqued_cmd("OkCmd", {graphDiagram = assoc:find("/graphDiagram")})
	end
end

function open_style_box()
	utilities.add_command(utilities.active_elements(), utilities.current_diagram(), "StyleDialogCmd", {info = ";lua_engine#lua.OWL_specific.ok_style;"})
end

function ok_style()
	gdsu.save_diagram_element_and_compartment_styles()
	local active_element = utilities.active_elements()
	local diagram = utilities.get_diagram_from_element(active_element)
	local elems = diagram:find('/element:has(/elemType[id = ' .. active_element:find('/elemType'):attr('id') .. '])')
	gdsu.ok_style_dialog_for_collection(active_element, elems)
end

function change_enumeration_label()
	local is_complete = lQuery("Collection/element/compartment:has(/compartType[id = 'isComplete'])")
	local is_complete_sub_compart = is_complete:find("/subCompartment")
	local ev = lQuery("D#Event")
	local checked = ev:find("/source"):attr("checked")
	if checked == "true" then
		is_complete:attr({value = "true", input = "{isComplete}"})
		is_complete_sub_compart:attr({value = "true"})
	else
		is_complete:attr({value = "false", input = ""})
		is_complete_sub_compart:attr({value = "false"})
	end
	local elem = utilities.get_element_from_compartment(is_complete)
	utilities.execute_cmd("OkCmd", {graphDiagram = elem:find("/graphDiagram"), element = elem})
	d.delete_event(ev)
	return ""
end

function dependency_values(compart)
	local items = {"seeAlso", "isDefinedBy"}
	local edge = compart:find("/element")
	local start_elem_type = edge:find("/start/elemType"):attr("id")
	local end_elem_type = edge:find("/end/elemType"):attr("id")
	if start_elem_type == "Object" and end_elem_type == "Class" then
		table.insert(items, "instanceOf")
	end
	return items
end

function language_values(compart)
	return config_properties.get_config_value("annotation_languages")
end

function default_types(compart)
	
	local list = {"Literal", "NCName", "NMTOKEN", "Name", "PlainLiteral", "XMLLiteral", "anyURI", "base64Binary", "boolean", "byte", "date", "dateTime", "dateTimeStamp",
	"decimal", "double", "float", "hexBinary", "int", "integer", "language", "long", "negativeInteger", "nonNegativeInteger", "nonPositiveInteger", "normalizedString",
	"positiveInteger", "rational", "real", "short", "string", "time", "token", "unsignedByte", "unsignedInt", "unsignedLong", "unsignedShort"
	}
	if compart ~= nil then
		local top_diagram = T_to_P.get_top_diagram(core.get_compartment_element(compart):find("/graphDiagram"))
		
		local temp_list = get_data_property_names_from_diagram(top_diagram)
		for _, v in pairs(temp_list) do
			table.insert(list, v)
		end
	end
	--return {"string", "integer", "boolean", "double", "date", "dateTime", "gDay", "gMonth", "gYear", "gYearMonth"}
	return list
end

function get_data_property_names_from_diagram(diagram)
	local res = {}
	diagram:find("/element:has(/elemType[id = 'DataType'])/compartment/subCompartment:has(/compartType[id = 'Name'])"):each(function(name)
		local class_name = name:attr_e("input")
		if class_name ~= "" then
			table.insert(res, class_name)
		end
	end)
	
	diagram:find("/element:has(/elemType[id='OntologyFragment'])"):each(function(el)
		el:find("/child"):each(function(dia)
			local temp_res = get_data_property_names_from_diagram(dia)
			for _, v in pairs(temp_res) do
				table.insert(res, v)
			end
		end)
	end)
	
return res
end

function annotation_types(compart)
	local annotation_table = {"backwardCompatibleWith", "comment", "deprecated", "incompatibleWith", "isDefinedBy", "label", "priorVersion", "seeAlso", "versionInfo"}
	local diagram = utilities.get_element_from_compartment(compart):find("/graphDiagram")
	local top_diagram = T_to_P.get_top_diagram(diagram)
	get_annotation_properties(top_diagram, annotation_table)
	local elems = get_ontologies(compart, "/compartment:has(/compartType[id = 'Prefix'])")
	for _, elem in ipairs(elems) do
		elem:find("/target"):each(function(dgr)
			get_annotation_properties(dgr, annotation_table)
		end)
	end
	return annotation_table
end

function get_annotation_properties(diagram, annotation_table)
	diagram:find("/element:has(/elemType[id = 'AnnotationProperty'])"):each(function(annot_property)
		local name = annot_property:find("/compartment:has(/compartType[id = 'Name'])/subCompartment:has(/compartType[id = 'Name'])"):attr("value")
		table.insert(annotation_table, name)
	end)

	diagram:find("/element:has(/elemType[id='OntologyFragment'])"):each(function(el)
		el:find("/child"):each(function(dia)
			get_annotation_properties(dia, annotation_table)
		end)
	end)
	
end

function default_multiplicity(compart)
	return {"*", "1", "0..1", "1..*"}
end

function get_package_names(compart)
	return get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Prefix'])", "/parentCompartment/element/graphDiagram/source")
end

function get_namespaces(compart)
	local list = get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Name'])", "/parentCompartment/element/graphDiagram/source")
	lQuery("ToolType"):find("/tag[key = 'owl_NamespaceDef']"):each(function(tag_)
		local value = tag_:attr("value")
		local res = split_owl_NamespaceDef_tag(value)
		if res["ns"] ~= "owlFields" then
			table.insert(list, res["ns"])
		end
	end)
	
	local current_diagram_name = get_seed_prefix()
	if current_diagram_name ~= nil and current_diagram_name ~= "" then table.insert(list, current_diagram_name) end
	
	return list
end

function split_owl_NamespaceDef_tag(value)
	local grammer = re.compile[[grammer <- ({:ns: [a-zA-Z0-9_]*:}(':=<'{:URI: [a-zA-Z0-9_.:/#]*:}'>'))]]
	local res_table = re.match(value, lpeg.Ct(grammer) * -1)
	return res_table
end

function set_class_name(compart)
	set_Name_compartment_value(compart:find("/parentCompartment"))
	set_role_for(compart)
	return ""
end

function set_namespace(compart)
	set_class_URI_ns_fields(compart, "Namespace", "URI", "Name", "Prefix")
end

function set_URI(compart)
	set_class_URI_ns_fields(compart, "URI", "Namespace", "Prefix", "Name")
	set_Name_compartment_value(compart)
end

function get_generalization_uri(compart)
	return get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Prefix'])", "/element/graphDiagram/source")
end

function get_generalization_ns(compart)
	return get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Name'])", "/element/graphDiagram/source")
end

function set_generalization_URI(compart)
	set_URI_namespace_fields(compart, "/compartment:has(/compartType[id = 'URI'])", "/compartment:has(/compartType[id = 'Namespace'])", "Prefix", "Name", "/element/graphDiagram/source")
end

function set_generalization_ns(compart)
	set_URI_namespace_fields(compart, "/compartment:has(/compartType[id = 'Namespace'])", "/compartment:has(/compartType[id = 'URI'])", "Name", "Prefix", "/element/graphDiagram/source")
end

function get_object_uri(compart)
	return get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Prefix'])", "/parentCompartment/parentCompartment/element/graphDiagram/source")
end

function get_object_ns(compart)
	local list = get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Name'])", "/parentCompartment/parentCompartment/element/graphDiagram/source")

	local current_diagram_name = get_seed_prefix()
	if current_diagram_name ~= nil and current_diagram_name ~= "" then table.insert(list, current_diagram_name) end
	
	return list
end

function get_link_ns(compart)
	return get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Name'])", "/parentCompartment/element/graphDiagram/source")
end

function set_object_URI(compart)
	local prefix, suffix = "/compartment/subCompartment/subCompartment:has(/compartType[id = '", "'])"
	set_URI_namespace_fields(compart, prefix .. "URI" .. suffix, prefix .. "Namespace" .. suffix, "Prefix", "Name", "/parentCompartment/parentCompartment/element/graphDiagram/source")
	--set_Name_compartment_value_param("Name", "Namespace", "/compartment/subCompartment:has(/compartType[id = 'Name'])")
	set_object_Name_compartment_value()
end

function set_object_ns(compart)
	local prefix, suffix = "/compartment/subCompartment/subCompartment:has(/compartType[id = '", "'])"
	set_URI_namespace_fields(compart, prefix .. "Namespace" .. suffix, prefix .. "URI" .. suffix, "Name", "Prefix", "/parentCompartment/parentCompartment/element/graphDiagram/source")
	--set_Name_compartment_value_param("Name", "Namespace", "/compartment/subCompartment:has(/compartType[id = 'Name'])")
	set_object_Name_compartment_value()
end

function get_attribute_uri(compart)
	return get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Prefix'])", "/parentCompartment/parentCompartment/parentCompartment/element/graphDiagram/source")
end

function get_attribute_ns(compart)
	local list = get_related_ontologies(compart, "/compartment:has(/compartType[id = 'Name'])", "/parentCompartment/parentCompartment/element/graphDiagram/source")

	local current_diagram_name = get_seed_prefix()
	if current_diagram_name ~= nil and current_diagram_name ~= "" then table.insert(list, current_diagram_name) end
	
	return list
end

function set_attribute_URI(compart)
	--print("set attribute uri")
	local prefix, suffix = "/compartment:has(/compartType[id = 'Attributes'])/subCompartment:has(/textLine/parentMultiLineTextBox)/subCompartment:has(/compartType[id = 'Name'])/subCompartment:has(/compartType[id = '", "'])"
	set_URI_namespace_fields(compart, prefix .. "URI" .. suffix, prefix .. "Namespace" .. suffix, "Prefix", "Name", "/parentCompartment/parentCompartment/parentCompartment/element/graphDiagram/source")
	set_attribute_compartment_value()
end

function set_attribute_ns(compart)
	--print("set attribute ns")
	local prefix, suffix = "/compartment:has(/compartType[id = 'Attributes'])/subCompartment:has(/textLine/parentMultiLineTextBox)/subCompartment:has(/compartType[id = 'Name'])/subCompartment:has(/compartType[id = '", "'])"
	set_URI_namespace_fields(compart, prefix .. "Namespace" .. suffix, prefix .. "URI" .. suffix, "Name", "Prefix", "/parentCompartment/parentCompartment/parentCompartment/element/graphDiagram/source")
	set_attribute_compartment_value()
end

function set_Name_compartment_value(compart)
	--set_Name_compartment_value_param("Name", "Namespace", "/compartment:has(/compartType[id = 'Name'])")
	set_Name_compartment_value_param2("Name", "Namespace", compart)
end

function set_object_Name_compartment_value()
	set_Name_compartment_value_param("Name", "Namespace", "/compartment/subCompartment:has(/compartType[id = 'Name'])")
end

function set_assoc_Name_compartment_value(compart)
	set_Name_compartment_value_param("Name", "Namespace", "/compartment:has(/compartType[id = 'Name'])")
end

function set_attribute_compartment_value(compart)
	set_Name_compartment_value_param("Name", "Namespace", "/compartment:has(/compartType[id = 'Attributes'])/subCompartment:has(/textLine/parentMultiLineTextBox)/subCompartment:has(/compartType[id = 'Name'])")
end
--/subCompartment/subCompartment:has(/compartType[id = 'Name'])
--textLine

function get_related_ontologies(compart, path, path_to_source)
	local elements = get_ontologies(compart, path, path_to_source)
	local result = {}
	for _, elem in pairs(elements) do
		table.insert(result, elem:find(path):attr("input"))
	end
	local elem = utilities.get_element_from_compartment(compart)
	local ontology = elem:find("/graphDiagram/parent")
	ontology:find("/compartment/subCompartment:has(/compartType[id = 'Namespaces'])"):each(function(namespace_compart)
		local prefix = namespace_compart:find("/subCompartment:has(/compartType[id = 'Prefix'])"):attr("value")
		if prefix ~= nil and prefix ~= "" and prefix ~= "owlFields" then
			table.insert(result, prefix)
		end
	end)
return result
end

function get_ontologies(compart, path, path_to_source)
	local seed = utilities.get_element_from_compartment(compart):find("/graphDiagram/source")
	local visited = {}
	local names = {}
	local elements = {}
	--local seed = compart:find(path_to_source)
	seed:find("/eStart:has(/elemType[id = 'Import'])/end"):each(function(elem)
		local key = elem:find(path):attr("input")
		table.insert(visited, {key, elem})
		table.insert(elements, elem)
	end)
	while #visited > 0 do
		get_import_ontologies(visited, names, path, elements)
	end
return elements
end

function get_import_ontologies(visited, names, path, elements)
	local pair = table.remove(visited, 1)
	local name, node = pair[1], pair[2]
	if name ~= "" and name ~= nil then
		node:find("/eEnd:has(/elemType[id = 'Import'])/start"):each(function(elem)
			local key = node:find(path):attr("input")
			if visited[key] == nil then
				table.insert(visited, {key, elem})
				table.insert(elements, elem)
			end
		end)
	end
end

function set_restriction_fields(compart)
	local check_box = d.get_event_source()
	local source_compart = check_box:find("/compartment")
	local check_box_val = check_box:attr("checked")
	if check_box_val == "true" then
		if source_compart:find("/compartType[id = 'Only']"):is_not_empty() then
			set_restriction_field_values(source_compart, "Some")
		elseif source_compart:find("/compartType[id = 'Some']"):is_not_empty() then
			set_restriction_field_values(source_compart, "Only")
		end
	end
end

function set_restriction_field_values(source_compart, compart_name)
	local element = utilities.get_element_from_compartment(source_compart)
	local target_inputs = {Some = "only", Only = "some"}
	local target_compart = element:find("/compartment:has(/compartType[id = '" .. compart_name .. "']):first")
	if target_compart:attr("value") == "true" then
		local val = "false"
		target_compart:attr({input = "", value = val})
		local target_check_box = target_compart:find("/component")
		target_check_box:attr({checked = val})

		--nestrada execute_cmd
		local attr_list = {}
		attr_list["receiver"] = target_check_box
		attr_list["info"] = "Refresh"
		utilities.enqued_cmd ("D#Command", attr_list)
	end
end

function set_Name_compartment_value_param(name, ns, path_to_target_compart)
	local name_compart = utilities.active_elements():find(path_to_target_compart)
	set_Name_compartment_value_param2(name, ns, name_compart)
end

function set_Name_compartment_value_param2(name, ns, name_compart)
	--local name_compart = utilities.active_elements():log():find(path_to_target_compart):log()
	local value = class_name_compose(name_compart, name, ns)
	name_compart:attr({input = value, value = value})
	local input_field = name_compart:find("/component")
	if input_field:size() > 0 then
		input_field:attr("text", value)
		utilities.refresh_form_component(input_field)
		--utilities.enqued_cmd("D#Command", {info = "Refresh"}):link("receiver", input_field)
	end
end

function set_class_URI_ns_fields(compart, field_name, source_compart_name, source_id, target_id)
	local path_to_field = "/compartment/subCompartment:has(/compartType[id = '" .. field_name .. "'])"
	local path_to_source_compart = "/compartment/subCompartment:has(/compartType[id = '" .. source_compart_name .. "'])"
	set_URI_namespace_fields(compart, path_to_field, path_to_source_compart, source_id, target_id, "/parentCompartment/element/graphDiagram/source")
end

function set_URI_namespace_fields(compart, path_to_field_compart, path_to_source_compart, source_id, target_id, path_to_seed)
	local target_compart = utilities.active_elements():find(path_to_field_compart)
	local input_field = target_compart:find("/component")
	local path_to_source = "/compartment:has(/compartType[id = '" .. source_id .. "'])"
	local path_to_target = "/compartment:has(/compartType[id = '" .. target_id .. "'])"
	local source_compart = utilities.active_elements():find(path_to_source_compart)
	local ontology_ns = get_ontology_URI_namespace(path_to_target, path_to_source, source_compart, path_to_seed)
	if ontology_ns ~= "" then
		input_field:attr("text", ontology_ns)
		input_field:remove_link("item")
		target_compart:attr({value = ontology_ns})
		local tmp = get_compartment_prefix_delimiter_suffix(target_compart)
		target_compart:attr({input = tmp})
		utilities.refresh_form_component(input_field)
		--utilities.enqued_cmd("D#Command", {info = "Refresh"}):link("receiver", input_field)
	end
end

function get_ontology_URI_namespace(path_to_URI, path_to_ns, URI_compart, path_to_seed)
	return get_ontology_URI_namespace_value(path_to_URI, path_to_ns, URI_compart, URI_compart:attr("value"), path_to_seed)
end

function get_ontology_URI_namespace_value(path_to_URI, path_to_ns, compart, value, path_to_seed)
		local elements = get_ontologies(compart, path_to_URI, path_to_seed)
		for i, elem in pairs(elements) do
			elem = lQuery(elem)
			if elem:find(path_to_URI):attr("value") == value then
				return elem:find(path_to_ns):attr("value")
			end
		end
return ""
end

function get_compartment_prefix_delimiter_suffix(compart)
	local compart_type = compart:find("/compartType")
	if compart:attr_e("value") == "" then
		return ""
	else
		local prefix, suffix = core.get_prefix_suffix(compart_type, compart)
		return  prefix .. compart:attr_e("value") .. suffix .. compart_type:attr_e("concatStyle")
	end
end

function class_name_compose(compart, name, ns)
	local name = compart:find("/subCompartment:has(/compartType[id = '" .. name .. "'])")
	local ns = compart:find("/subCompartment:has(/compartType[id = '" .. ns .. "'])")
return get_compartment_prefix_delimiter_suffix(name) .. get_compartment_prefix_delimiter_suffix(ns)
end

function dependency_change(compartment)
	local compart = utilities.active_elements():find("/compartment")
	if compart:attr_e("value") == "instanceOf" then
		compart:attr({input = ""})
	end
end

function generate_uri_and_date(default_compart)
	local elem = utilities.active_elements()
	local compart = elem:find("/compartment:has(/compartType[id = 'Name'])")
	local name = string.gsub(compart:attr_e("input"), " ", "_")
	local diagram = elem:find("/child")
	utilities.set_diagram_caption(diagram, name)
	local default_uri = "http://lumii.lv/ontologies/"
	local old_prefix = elem:find("/compartment:has(/compartType[id = 'Prefix'])"):attr("value")
	local start, fin = string.find(old_prefix, default_uri, 1)
	-- if start == 1 or old_prefix == "" then
	if old_prefix == "" then
		local uri = default_uri .. name
		if string.find(name, ".owl") == nil then
			uri = uri .. ".owl"
		end
		set_compartment_and_field(compart, "Prefix", uri)
		set_compartment_and_field(compart, "Date", os.date())
		--local ok_cmd = utilities.create_command("OkCmd", {graphDiagram = elem:find("/graphDiagram")})
		--		utilities.execute_cmd_obj(ok_cmd)
		--ok_cmd = utilities.create_command("OkCmd", {element = elem})
		--	utilities.execute_cmd_obj(ok_cmd)
	end
	return ""
end

function set_compartment_and_field(compart, compart_id, val)
	local target_compart = compart:find("/element/compartment:has(/compartType[id = '" .. compart_id .. "'])")--:attr({value = val, input = val})
	core.set_compartment_and_field(target_compart, val)
end

function role_name_from_ns(compart)
	local elem = core.get_compartment_element(compart)
	local ns = elem:find("/compartment/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
	if ns ~= "" then
		local seed = get_seed_by_name(elem, ns)
		if seed ~= nil then
			return get_roles_in_diagram(seed:find("/child"))
		else
			return {}
		end
	else
		return get_roles_in_diagram(utilities.current_diagram())
	end
	return {}
end

function class_name_from_ns(compart)
	local elem = core.get_compartment_element(compart)
	local ns = elem:find("/compartment/subCompartment:has(/compartType[id = 'Namespace'])"):attr_e("value")
	if ns ~= "" then
		local seed = get_seed_by_name(elem, ns)
		if seed ~= nil then
			return get_class_names_from_diagram(seed:find("/child"))
		else
			return {}
		end
	--else
		--return get_class_names_from_diagram(utilities.current_diagram())
	end
return {}
end

function get_ontologies_from_seed(seed, path)
	local visited = {}
	local names = {}
	local colour = {}
	local elements = {}
	table.insert(colour, {seed:id(), "black"})
	seed:find("/eStart:has(/elemType[id = 'Import'])/end"):each(function(elem)
		elem = lQuery(elem)
		local key = elem:find(path):attr_e("input")
		local index = elem:id()
		table.insert(visited, {index, elem})
		table.insert(colour, {index, "grey"})
		table.insert(elements, elem)
	end)
	get_import_ontologies(visited, colour, names, path, elements, seed_count)
return elements
end

function get_import_ontologies(visited, colour, names, path, elements, count)
	while is_empty(visited) == false do
		local pair = table.remove(visited)
		local name, node = pair[1], pair[2]
		if name ~= "" and name ~= nil then
			colour[name] = "black"
			node:find("/eStart:has(/elemType[id = 'Import'])/end"):each(function(elem)
				elem = lQuery(elem)
				if colour[elem:id()] ~= "grey" and colour[elem:id()] ~= "black" then
					table.insert(visited, {elem:id(), elem})
					table.insert(colour, {elem:id(), "grey"})
					table.insert(elements, elem)
				end
			end)
		end
	end
end

function is_empty(t)
	local empty = true
	for _ in pairs(t) do
		empty = false
		break
	end
	return empty
end

function get_seed_by_name(elem, ns)
	local source = nil
	elem:find("/graphDiagram/source/graphDiagram/element:has(/elemType[id = 'OWL'])"):each(function(seed)
		if seed:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("input") == ns then
			source = seed
		end
	end)
	return source
end

function get_class_names_from_diagram(diagram)
	local res = {}
	diagram:find("/element:has(/elemType[id = 'Class'])/compartment/subCompartment:has(/compartType[id = 'Name'])"):each(function(name)
		local class_name = name:attr_e("input")
		if class_name ~= "" then
			table.insert(res, class_name)
		end
	end)
	
	diagram:find("/element:has(/elemType[id='OntologyFragment'])"):each(function(el)
		el:find("/child"):each(function(dia)
			local temp_res = get_class_names_from_diagram(dia)
			for _, v in pairs(temp_res) do
				table.insert(res, v)
			end
		end)
	end)
	
return res
end

function get_class_names_for_object(compart)
	local top_diagram = T_to_P.get_top_diagram(core.get_compartment_element(compart):find("/graphDiagram"))
	return get_class_names_from_diagram(top_diagram)
end

function concat_for_drop_down(result, item_name)
	if item_name ~= "" then
		return result .. item_name .. "$"
	else
		return result
	end
end

function get_roles(compart)
	local diagram = core.get_compartment_element(compart):find("/graphDiagram")
	return get_roles_in_diagram(diagram)
end

function get_roles_in_diagram(diagram)
	local result = {}
	diagram:find("/element:has(/elemType[id = 'Association'])"):each(function(assoc)
		local tmp_name = assoc:find("/compartment:has(/compartType[id = 'Role'])/subCompartment/subCompartment:has(/compartType[id = 'Name'])"):attr("value")
		if tmp_name ~= "" then
			table.insert(result, tmp_name)
		end
		tmp_name = assoc:find("/compartment:has(/compartType[id = 'InvRole'])/subCompartment/subCompartment:has(/compartType[id = 'Name'])"):attr("value")
		if tmp_name ~= "" then
			table.insert(result, tmp_name)
		end
	end)
	return result
end

function set_role_for(compart)
	local class_name = compart:attr_e("input")
	local class = core.get_compartment_element(compart)
	set_role_for_compartment_value(class, class_name, "/eStart:has(/elemType[id = 'Association'])", "Role")
	set_role_for_compartment_value(class, class_name, "/eEnd:has(/elemType[id = 'Association'])", "InvRole")
end

function set_role_for_compartment_value(class, class_name, path, id)
	local tmp_value = ""
	class:find(path):each(function(assoc)
		tmp_value = class_name
		assoc:find("/compartment:has(/compartType[id = '" .. id .. "'])/subCompartment:has(/compartType[id = 'RoleFor'])"):attr({value = tmp_value, input = tmp_value})
	end)
	return tmp_value
end

function set_role_for_direct(elem)
	return elem:find("/end:has(/elemType[id = 'Class'])/compartment/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
end

function set_role_for_inverse(elem)
	return elem:find("/start:has(/elemType[id = 'Class'])/compartment/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
end

function get_properties()
	local diagram = utilities.current_diagram()
	local top_diagram = T_to_P.get_top_diagram(diagram)
	return get_properties_for_diagramm(top_diagram)
end

function get_properties_for_diagramm(diagram)
	local prop_table = {}
	diagram:find("/element:has(/elemType[id = 'Class'])"):each(function(class)
		class:find("/compartment:has(/compartType[id = 'ASFictitiousAttributes'])"):each(function(attr)
			attr:find("/subCompartment:has(/compartType[id = 'Attributes'])/subCompartment:has(/compartType[id = 'Name'])"):each(function(name)
				insert_property_value(prop_table, name:attr_e("value"))
			end)
		end)
	end)
	diagram:find("/element:has(/elemType[id = 'Association'])"):each(function(assoc)
		local val = assoc:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("input")
		local inv_val = assoc:find("/compartment:has(/compartType[id = 'InvName'])"):attr_e("input")
		val = string.gsub(val, " ", "")
		inv_val = string.gsub(inv_val, " ", "")
		insert_property_value(prop_table, val)
		insert_property_value(prop_table, inv_val)
	end)
	
	diagram:find("/element:has(/elemType[id='OntologyFragment'])"):each(function(el)
		el:find("/child"):each(function(dia)
			local prop_table_temp = get_properties_for_diagramm(dia)
			for _, v in pairs(prop_table_temp) do
				insert_property_value(prop_table, v)
			end
		end)
	end)
	
	return prop_table
end

function insert_property_value(in_table, value)
	if value ~= "" then
		table.insert(in_table, value)
	end
end

function split_chains_value(compart)
	local compart_type = compart:find("/compartType")
	local val = compart:attr("value")
	local grammer = re.compile[[grammer <- (item (" o " (" ")* item)*)
	item <- {[^" o "]*}]]
	local res = lpeg.match(lpeg.Ct(grammer), val)
	local counter = 1
	local sub_compartment = compart:find("/subCompartment")
	local sub_compart_type = compart_type:find("/subCompartType")
	if sub_compartment:is_empty() then
		sub_compartment = core.add_compart(sub_compart_type, compart, "")
	end
	sub_compartment:find("/subCompartment"):each(function(sub_compart)
		if res[counter] == nil then
			Delete.delete_compartment_tree_from_object(sub_compart, "/subCompartment")
			sub_compart:delete()
		else
			sub_compart:attr({value = res[counter], input = res[counter]})
			counter = counter + 1
		end
	end)
	local child_compart_type = sub_compart_type:find("/subCompartType[id = 'PropertyChain']")
	while res[counter] ~= nil do
		local new_compart = core.add_compart(child_compart_type, sub_compartment, "")
		new_compart:attr({value = res[counter], input = res[counter]})
		counter = counter + 1
	end
	sub_compartment:find("/subCompartment"):each(function(chain_compart)
		split_chain_value(chain_compart)
	end)
end

function split_chain_value(compart)
	local val = compart:attr("value")
	local res = parse_key(val)
	local expr_compart = compart:find("/subCompartment:has(/compartType[id = 'Property'])")
	local inverse_compart = compart:find("/subCompartment:has(/compartType[id = 'Inverse'])")
	local ns_compart = compart:find("/subCompartment:has(/compartType[id = 'Namespace'])")
	if type(res) == "table" then
		if inverse_compart:is_empty() then
			local compart_type = compart:find("/compartType")
			inverse_compart = core.create_missing_compartment(compart, compart_type, compart_type:find("/subCompartType[id = 'Inverse']"))
		end
		if res["Inverse"] ~= nil then
			inverse_compart:attr({value = "true", input = "true"})
		else
			inverse_compart:attr({value = "false", input = "false"})
		end
		if expr_compart:is_empty() then
			local compart_type = compart:find("/compartType")
			expr_compart = core.create_missing_compartment(compart, compart_type, compart_type:find("/subCompartType[id = 'Property']"))
		end
		expr_compart:attr({value = res["Property"], input = res["Property"]})
		if ns_compart:is_empty() then
			local compart_type = compart:find("/compartType")
			ns_compart = core.create_missing_compartment(compart, compart_type, compart_type:find("/subCompartType[id = 'Namespace']"))
		end
		--ns_compart:attr({value = res["Namespace"]})
		core.set_compartment_input_value(ns_compart, ns_compart:find("/compartType"), res["Namespace"])
	end
end

function set_chain_value(compart)
	return set_key_value(compart)
end

function set_key_value(parent)
	local key_compart_val = parent:find("/subCompartment:has(/compartType[id = 'Property'])"):attr("value") or ""
	local inverse_compart_val = parent:find("/subCompartment:has(/compartType[id = 'Inverse'])"):attr("value") or ""
	local ns_compart_val = parent:find("/subCompartment:has(/compartType[id = 'Namespace'])"):attr("input") or ""
	local val = ""
	if inverse_compart_val == "false" or inverse_compart_val == ""  then
		val = key_compart_val .. ns_compart_val
	else
		val = "inverse(" .. key_compart_val .. ns_compart_val .. ")"
	end
	parent:attr({input = val, value = val})
	return val
end

function split_keys_value(compart)
	local compart_type = compart:find("/compartType")
	local val = compart:attr("value")
	local grammer = re.compile[[grammer <- (item ("," (" ")* item)*)
	item <- {[^","]*}]]
	local res = lpeg.match(lpeg.Ct(grammer), val)
	local counter = 1
	local sub_compartment = compart:find("/subCompartment")
	local sub_compart_type = compart_type:find("/subCompartType")
	if sub_compartment:is_empty() then
		sub_compartment = core.add_compart(sub_compart_type, compart, "")
	end
	sub_compartment:find("/subCompartment"):each(function(sub_compart)
		if res[counter] == nil then
			Delete.delete_compartment_tree_from_object(sub_compart, "/subCompartment")
			sub_compart:delete()
		else
			sub_compart:attr({value = res[counter], input = res[counter]})
			counter = counter + 1
		end
	end)
	local child_compart_type = sub_compart_type:find("/subCompartType[id = 'Key']")
	while res[counter] ~= nil do
		local new_compart = core.add_compart(child_compart_type, sub_compartment, "")
		new_compart:attr({value = res[counter], input = res[counter]})
		counter = counter + 1
	end
	sub_compartment:find("/subCompartment"):each(function(key_compart)
		split_key_value(key_compart)
	end)
end

function split_key_value(compart)
	local val = compart:attr("value")
	local res = parse_key(val)
	local key_compart = compart:find("/subCompartment:has(/compartType[id = 'Property'])")
	local inverse_compart = compart:find("/subCompartment:has(/compartType[id = 'Inverse'])")
	local ns_compart = compart:find("/subCompartment:has(/compartType[id = 'Namespace'])")
	if type(res) == "table" then
		if inverse_compart:is_empty() then
			local compart_type = compart:find("/compartType")
			inverse_compart = core.create_missing_compartment(compart, compart_type, compart_type:find("/subCompartType[id = 'Inverse']"))
		end
		if res["Inverse"] ~= nil then
			inverse_compart:attr({value = "true", input = "true"})
		else
			inverse_compart:attr({value = "false", input = "false"})
		end
		if key_compart:is_empty() then
			local compart_type = compart:find("/compartType")
			key_compart = core.create_missing_compartment(compart, compart_type, compart_type:find("/subCompartType[id = 'Property']"))
		end
		key_compart:attr({value = res["Property"], input = res["Property"]})
		if ns_compart:is_empty() then
			local compart_type = compart:find("/compartType")
			ns_compart = core.create_missing_compartment(compart, compart_type, compart_type:find("/subCompartType[id = 'Namespace']"))
		end
		--ns_compart:attr({value = res["Namespace"]})
		--core.set_compartment_input_value(ns_compart, ns_compart:find("/compartType"), res["Namespace"])
		--ns_compart:attr({value = res["Namespace"], input = "{" .. res["Namespace"] .. "}"})

		local input = core.build_compartment_input_from_value(res["Namespace"], ns_compart:find("/compartType"), ns_compart)
		ns_compart:attr({value = res["Namespace"], input = input})
	end
end

function parse_key(val)
	local grammer = re.compile[[grammer <- ({:Inverse: 'inverse' :}? {:Open: '(' :}? {:Property: [a-zA-Z0-9_]* :}	{:OpenSq: '{' :}? {:Namespace: [a-zA-Z0-9_]* :} {:CloseSq: '}' :}? {:Close: ')' :}? )]]
	return lpeg.match(lpeg.Ct(grammer), val)
end

function remove_dot_owl(name)
	local ns = ""
	local length = string.len(name)
	local start_index, end_index = string.find(name, ".owl")
	if start_index ~= nil and length == end_index then
		ns = string.sub(name, 1, start_index - 1)
	else
		ns = name
	end
	return ns
end

function default_type_special(compart)
	return default_types(compart)
end

function stereotype_window()
	--print("stereotype window")

	local form = d.add_form({id = "form", caption = "Annotation Vizualization Specification", minimumWidth = 230, minimumHeight = 50})

	d.add_row_labeled_field(form, {id = "user_annotation_label", caption = "User Annotation"}, {id = "user_annotation", text = "aa"}, {id = "user_annotation_row"}, "D#InputField", {})
	d.add_row_labeled_field(form, {id = "for_label", caption = "For"}, {id = "for", text = "bb"}, {id = "for_row"}, "D#ComboBox", {})
	d.add_row_labeled_field(form, {id = "inside_label", caption = "Inside"}, {id = "inside", checked = "true"}, {id = "inside_row"}, "D#CheckBox", {})


	local tab_container = d.add_component(form, {id = "tab_container"}, "D#TabContainer")
	--d.add_event_handlers(tab_container, {TabChange = "lua.configurator.configurator.tab_changed"})
	local inside_tab = d.add_component(tab_container, {id = "inside_tab", caption = "Inside"}, "D#Tab")
		d.add_row_labeled_field(inside_tab, {id = "element_style_label", caption = "Element Style"}, {id = "element_style", caption = "Style"}, {id = "element_style_row"}, "D#Button", {})
		d.add_row_labeled_field(inside_tab, {id = "compartment_style_label", caption = "Compartment Style"}, {id = "compartment_style", caption = "Style"}, {id = "compartment_style_row"}, "D#Button", {})

	local outside_tab = d.add_component(tab_container, {id = "outside_tab", caption = "Outside"}, "D#Tab")



	--user annoation
	--for
	--inside

	--tabi

	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)


end

function delete_rest()
	local diagram = utilities.current_diagram()
	delete_not_active_elements(diagram)
	utilities.enqued_cmd("OkCmd", {graphDiagram = diagram})
end

function delete_not_active_elements(diagram)
	diagram:find("/element"):each(function(elem)
		if elem:find("/collection"):is_empty() then
			local target_diagram = elem:find("/target")
			if target_diagram:size() > 0 then
				delete_not_active_elements(target_diagram)
				target_diagram:delete()
			end
			elem:delete()
		end
	end)
end

function process_export_translet()
	local form = d.add_form({id = "form", caption = "OWLGrEd Export", minimumWidth = 70, minimumHeight = 50})
	local tool_type = lQuery("ToolType")
	if tool_type:is_empty() then
		tool_type = lQuery.create("ToolType")
	end
	add_tag_field(form, "OWLGrEd Export++", "owlgred_export", tool_type)
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
end

function add_tag_field(container, label, field_id, obj_type)
	local translet_name = obj_type:find("/tag[key = " .. field_id .. "]"):attr_e("value")
	local row = d.add_row_labeled_field(container, {caption = label}, {id = field_id, text = translet_name}, {id = "row_" .. field_id}, "D#InputField", {FocusLost = "lua.OWL_specific.set_tag_to_tool_type"})
end

function set_tag_to_tool_type()
	local attr, value = d.get_event_source_attrs("text")
	local tool_type = lQuery("ToolType")
	local tag1 = tool_type:find("/tag[key = '" .. attr .. "']")
	if value == "" then
		tag1:delete()
	else
		if tag1:is_empty() then
			add_tag_to_obj_type(tool_type, attr, value)
		else
			tag1:attr({value = value})
		end
	end
	d.delete_event()
end

function add_tag_to_obj_type(obj_type, key, value)
	local tag1 = obj_type:find("/tag[key = " .. key .. "]:not(:has(/extenstion))")
	if key == "" and tag1 ~= nil then
		tag1:delete()
	else
		if tag1 == nil or tag1:is_empty() then
			tag1 = lQuery.create("Tag", {key = key, value = value})
			obj_type:link("tag", tag1)
		else
			tag1:attr({value = value})
		end
	end
	return tag1
end

function splitting_items()
	return {"", "I", "C"}
end

function set_attribute_field_disabled(form)
	form:find("/component/component[caption = 'Attributes']/component/component.D#MultiLineTextBox"):attr({enabled = "true", readOnly = "true"})
end

function update_ontology_fragment_title(compart)
	local elem = utilities.get_element_from_compartment(compart)
	local dgr = elem:find("/child")
	if dgr:is_not_empty() then
		utilities.set_diagram_caption(dgr, compart:attr("value"))
	end
end

function recalculate_styles_in_import(ontology_diagram)
	--print("THIS IS ontology diagram recalculate styles")
end

function set_is_read_only_field()
	local diagram = utilities.current_diagram()
	if diagram:find("/tag[key = 'read_only_property_fields']"):attr("value") == "true" then
		return true
	else
		return false
	end
end

function Copy()
	CutCopyPaste.Copy()
end

function collection_pop_up()
	local elems = utilities.active_elements()
	local edges = elems:filter(".Edge")
	local pop_up_diagram = lQuery.create("PopUpDiagram")
		add_pop_up_element(pop_up_diagram, {caption = "Cut	Ctrl+X", procedureName = "interpreter.CutCopyPaste.Cut"})
		add_pop_up_element(pop_up_diagram, {caption = "Copy	Ctrl+C", procedureName = "interpreter.CutCopyPaste.Copy"})
		add_pop_up_element(pop_up_diagram, {caption = "Delete	Delete", procedureName = "interpreter.Delete.Delete"})
		if edges:is_not_empty() then
			add_pop_up_element(pop_up_diagram, {caption = "Reroute Line", procedureName = "utilities.Reroute"})
		end
		add_pop_up_element(pop_up_diagram, {caption = "Align Boxes", procedureName = "utilities.align_selected_boxes"})
		add_pop_up_element(pop_up_diagram, {caption = "Collection Symbol Style", procedureName = "utilities.symbol_style_for_collection"})
	
	lQuery("GraphDiagramType[id='OWL']/rClickCollection/popUpElementType"):each(function(pop_up)
		add_pop_up_element(pop_up_diagram, {caption = pop_up:attr("caption"), procedureName = pop_up:attr("procedureName")})
	end)
	
	utilities.enqued_cmd("PopUpCmd")
		:link("popUpDiagram", pop_up_diagram)
		:link("graphDiagram", elems:find("/graphDiagram"))
end

function add_pop_up_element(pop_up_diagram, attr_table)
	pop_up_diagram:link("popUpElement", lQuery.create("PopUpElement", attr_table))
end

function set_restriction_role(compart)
	local elem = utilities.get_element_from_compartment(compart)
	local is_inverse_compart = elem:find("/compartment/subCompartment:has(/compartType[id = 'IsInverse'])")
	set_restriction_inverse(is_inverse_compart)
end

function set_restriction_inverse(compart)
	local name_compart = compart:find("/parentCompartment")
	local role_compart_input = name_compart:find("/subCompartment:has(/compartType[id = 'Role'])"):attr("input") or ""
	local ns_compart_input = name_compart:find("/subCompartment:has(/compartType[id = 'Namespace'])"):attr("input") or ""
	local name_val = role_compart_input .. " " .. ns_compart_input
	if compart:attr("value") == "true" then
		name_val = "inverse(" .. name_val .. ")"
	end
	core.set_compartment_input_value(name_compart, name_compart:find("/compartType"), name_val)
end

function save_ontology_from_seed()
	local elem = utilities.active_elements()
	local target_diagram = elem:find("/child")
	if target_diagram:is_empty() then
		target_diagram = elem:find("/target")
	end
	save_ontology_diagram(target_diagram)
end

function ontology_functional_form(diagram)
	local list = {}
	table.insert(list, diagram)
	local ontology_header = T_to_P.export_Header(diagram)
	local ontology_body = T_to_P.export_diagram(list, function() end, true)
	local ontology_plugin = T_to_P.export_plugin(diagram)
	local ontology_footer = ")"
	local ontology_text = string.format("%s%s%s%s", ontology_header, ontology_body, ontology_plugin, ontology_footer)
	return ontology_text
end

function save_ontology_diagram(diagram)
	if diagram == nil then
		diagram = utilities.current_diagram()
	end
	
	lQuery("ToolType/translet[extensionPoint='OnDiagramExport']"):each(function(translet)
		utilities.execute_translet(translet:attr("procedureName"), diagram, list)
	end)
	
	local project = lQuery("Project")
	local tag_ = utilities.get_tags(project, "Path")
	local path = tag_:attr("value")
	local file_name = diagram:attr("caption")
	--path = tda.BrowseForFile("Save", "OWL File (*.owl)\nAll Files (*.*)", path or "", file_name, true)
	local fileTypeString = "RDF/XML file (*.owl)\nOWL/XML file (*.owl)\nOWL Functional syntax file (*.owl)\nOWL Manchester syntax file (*.owl)"
	local allFilesString = "\nOWL Functional syntax without OWL API (*.owl)"
	--comment/delete the next line for release versions - it enables the selection 'All files', which means saving the file without using OWL API.
	fileTypeString = fileTypeString..allFilesString
	local typeIndex = nil
	path, typeIndex = tda.BrowseForFile("Save", fileTypeString, path or "", file_name, true)
	--path = tda.BrowseForFile("Save", fileTypeString, path or "", file_name, true)

	if path ~= nil and path ~= "" then
		tag_:attr({value = path})
		local ontology_text = ontology_functional_form(diagram)
		local diagram_name = diagram:find("/parent/compartment:has(/compartType[id=Name])"):attr("value")
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
				log("Ontology successfully saved in Functional notation file at "..path_to_file)
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
			log(saveResult)
		end
	end
end


-- graph diagram engine exports svg with width and height 100%
-- with such settings zoom doesn't work in webkit based browsers
-- this function rewrites width and height to absolute values
-- taken from viewbox
function correct_width_and_height_in_svg(svg_file_path)
	-- because lua doesn't have a function for replacing a line in a file
	-- we read the file and store lines until we reach the line we want to change.
	-- than we make the change, read the entire rest of the file as one string,
	-- and then write all the previously read lines in order.

	local replace_witdth_height = function(str)
		require("re")
		local width, height = re.match(str, [[' width="100%" height="100%" viewBox="0 0 '{(%d*)}%s{(%d*)}]])
		local replaced_line = string.format(' width="%d" height="%d" viewBox="0 0 %d %d">', width, height, width, height)
		return replaced_line
	end

	local hFile = io.open(svg_file_path, "r") --Reading.
	local lines = {}
	local restOfFile
	local lineCt = 1
	for line in hFile:lines() do
		-- the 6th line should contain the width and height
		if(lineCt == 6) then --Is this the line to modify?
			lines[#lines + 1] = replace_witdth_height(line) --Change old line into new line.
			restOfFile = hFile:read("*a")
			break
		else
			lineCt = lineCt + 1
			lines[#lines + 1] = line
		end
	end
	hFile:close()

	hFile = io.open(svg_file_path, "w") --write the file.
	for i, line in ipairs(lines) do
		hFile:write(line, "\n")
	end
	hFile:write(restOfFile)
	hFile:close()
end

function save_diagram_as_SVG()
	local diagram = utilities.current_diagram()
	local project = lQuery("Project")
	local tag_ = utilities.get_tags(project, "__SVG_path")
	local path = tag_:attr("value")
	local file_name = diagram:attr("caption")
	path = tda.BrowseForFile("Save", "SVG File (*.svg)\nAll Files (*.*)", path or "", file_name, true)
	if path ~= nil and path ~= "" then
		tag_:attr({value = path})
		local diagram_id = diagram:id()
		local diagram_caption = diagram:attr("caption")
		local svg_file_folder_path = path
		local svg_picture_folder_path = path
		lua_graphDiagram.ExportDiagramToSVG(diagram_id, svg_file_folder_path, svg_picture_folder_path)
		correct_width_and_height_in_svg(svg_file_folder_path)
	end
end

function export_from_diagram()
	tda.CallFunctionWithPleaseWaitWindow("tda_to_protege.export_muliple_ontologies", "CurrentDgrPointer/graphDiagram/parent")
end

function export_from_seed()
	tda.CallFunctionWithPleaseWaitWindow("tda_to_protege.export_muliple_ontologies", "CurrentDgrPointer/graphDiagram/collection/element")
end

function test_db_expr(compart_type)
	local pattern_name = "(DT_A)"
	local clauses = [[
DT_A <- ({DT_B ('(' DT_A ')')* })
DT_B <- ({([^"()"])*})
]]
	return pattern_name, clauses
end

function type_parser_clauses(compart_type)
	local pattern_name = "(DT_C)"
	local clauses = [[
DT_C <- (DT_X / [a-zA-Z0-9-_]*)
DT_X <- ({'(' DT_A ')' })
DT_A <- ({DT_B ('(' DT_A ')' DT_A)* })
DT_B <- ({([^()])*})
]]
	return pattern_name, clauses
end

function get_seed_prefix()
	local diagram = utilities.current_diagram()
	local diagram_source = diagram:find("/parent")
	local current_diagram_name = remove_dot_owl(diagram_source:find("/compartment:has(/compartType[id = 'Name'])"):attr_e("value"))
	current_diagram_name = string.gsub(current_diagram_name, " ", "_")
	
	return current_diagram_name
end
