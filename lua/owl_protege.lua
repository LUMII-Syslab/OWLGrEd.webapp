module(..., package.seeall)

require "core"
require "utilities"
require "OWL_specific"
require "socket"

require "java"
require "owl_protege_export"

require "lfs"

require "empty_project_dialog"

require "progress_reporter"


require("parameters")

d = require("dialog_utilities")
json = require ("reporter.dkjson")

local report = require("reporter.report")

local min_protege_owlgred_bridge_version = 2.0


function get_prefixes()
  return table.concat(utilities.get_tooltype_tags("owl_NamespaceDef"):map(function(t) return "Prefix(" .. t:attr("value") .. ")" end), "\n")
end

function get_axioms()
  return table.concat(utilities.get_tooltype_tags("owl_Annotation_Import"):map(function(t) return t:attr("value") end), "\n")
end

function select_ontology_path(start_path)
	return tda.BrowseForFile("Open", "OWL File (*.owl;*.xml;*.rdf)\nAll Files (*)", start_path or "", "", false)
end

function select_and_load_ontology(start_path)
	local path = select_ontology_path(start_path or "")
	if path ~= "" then
		load_ontology(path)
		return true
	end
	return false
end

function str_starts_with(str, start)
   return string.sub(str, 1, string.len(start)) == start
end

local function file_size_in_kb(file_path)
	return math.floor((lfs.attributes(file_path, "size") or 0) / 1024)
end

local function file_name(file_path)
	local name = string.gsub(file_path, '.*\\', '')
	return name
end

function disabled_renderers(render_pefs)
	local disable_renderer_names = {}
	for renderer_name, status in pairs(render_pefs) do
		if status == false or status == "false" then
			table.insert(disable_renderer_names, renderer_name)
		end
	end
	return disable_renderer_names
end

function load_ontology(ontology_path)
	local status, render_prefs_table = pcall(parameters.createParametersTable)
	render_prefs_table = status and render_prefs_table or {}
	-- print(dumptable(render_prefs_table))


	-- Log "ontology load" event.
	report.event("OWLGrEd_LoadOntology", {
		file_size_in_kb = file_size_in_kb(ontology_path),
		file_name = file_name(ontology_path),
		disabled_renderers = disabled_renderers(render_prefs_table),
		render_preferences_set = status,
	})


	local java_class_name = "loadOntology"
	local method_name = "importOntologies"
	
	local extensionsTable = {}
	local container = false
	if lQuery("ElemType[id='Container']"):is_not_empty() then container = true end
	local OWLGrEd_Schema = false
	if lQuery("Plugin[id='OWLGrEd_Schema']"):is_not_empty() and lQuery("Plugin[id='OWLGrEd_Schema']"):attr("status") == "loaded" then OWLGrEd_Schema = true end
	extensionsTable['container'] = container
	extensionsTable['OWLGrEd_Schema'] = OWLGrEd_Schema
	extensionsTable['defaultMaxCardinality'] = lQuery("ToolType/tag[key = 'DefaultMaxCardinality1']"):attr("value")
	
	local args = {
		ontology_path = ontology_path,
		extensions = extensionsTable,
		-- signature = { "AboutPage" },
		custom_render_spec = {
			prefixes = get_prefixes(),
			axioms = get_axioms()
		},
		preferences = parameters.createJSONParameterTable()
	}
	-- local serialized_args = owl_protege_export.serialize_to_clojure_string_form(args)
	local serialized_args = json.encode(args)
	-- local file = assert(io.open("C:/Users/Julija/Desktop/Darbs/ImportaModulis/ontology2.txt", "w+"))
	-- local file = assert(io.open("C:/Users/user/Desktop/ontology2.txt", "w+"))
	-- file:write(serialized_args)
	-- file:close()
	ont_as_table_str = java.call_static_class_method(java_class_name, method_name, serialized_args)
	if str_starts_with(ont_as_table_str, "error - ") then
		report.event("OWLGrEd_owlapi_error", {message = ont_as_table_str})
		error(ont_as_table_str)
	else
		import_from_owlapi(ont_as_table_str)
	end
end


function diff_ontologies(origin_ontology_path)
	local status, render_prefs_table = pcall(parameters.createParametersTable)
	render_prefs_table = status and render_prefs_table or {}


	-- Log "ontology roundtrip test start" event.
	report.event("OWLGrEd_RoundtripStart", {
		disabled_renderers = disabled_renderers(render_prefs_table),
		render_preferences_set = status,
	})

	--
	-- read ontology from file
	--
	local java_class_name = "owlgred.OWLGrEdImport"
	local method_name = "read"

	local args = {
		ontology_path = origin_ontology_path,
		custom_render_spec = {
			prefixes = get_prefixes(),
			axioms = get_axioms()
		},
		preferences = render_prefs_table
	}
	local serialized_args = owl_protege_export.serialize_to_clojure_string_form(args)
	
	local ont_as_table_str = java.call_static_class_method(java_class_name, method_name, serialized_args)
	local ontology_diagram = import_from_owlapi_helper(ont_as_table_str)


	--
	-- diff ontologies
	--
	local java_class_name = "owlgred.OWLGrEdImport"
	local method_name = "diff"

	-- local file = io.open(origin_ontology_path, "r")
	-- ontology_content = file:read("*a")
	-- io.close(file)

	ontology_text = OWL_specific.ontology_functional_form(ontology_diagram)

	local args = {
		origin_ontology_path = origin_ontology_path,

		ontology_uri = "http://lumii.lv/abc",
		ontology = ontology_text -- "Ontology(<http://lumii.lv/ontologies/pizza.owl>)",
	}
	local serialized_args = owl_protege_export.serialize_to_clojure_string_form(args)
	
	local diff_table_str = java.call_static_class_method(java_class_name, method_name, serialized_args)

	local diff = eval(diff_table_str)

	require("set")

	local extra = set.new(diff.extra or {})
	local missing = set.new(diff.missing or {})

	diff.extra = {}
	for axiom in pairs(extra - missing) do
		table.insert(diff.extra, axiom)
	end

	diff.missing = {}
	for axiom in pairs(missing - extra) do
		table.insert(diff.missing, axiom)
	end

	return diff
end

function roundtrip_test(path)
	local form = lQuery("D#Form[id=roundtrip-diff-results]")

	local file_path = path or select_ontology_path("")

	if form:is_empty() then
		form = lQuery.create("D#Form", {
			caption = "Roundtrip diff   -   file -> graphics -> file",
			id = "roundtrip-diff",
			buttonClickOnClose = false,
			eventHandler = utilities.d_handler("Close", "lua_engine", "lua.owl_protege.close_roundtrip_diff_form"),
			minimumHeight = 600,
			minimumWidth = 800,
			component = {
				lQuery.create("D#HorizontalBox", {
					id = "row_container"
				})
			}
		})

		local relative_height_group = lQuery.create("D#Group", {owner = form})

		d.add_row_labeled_field(form:find("/component[id=row_container]"), {caption="Missing"}, {id = "missing", relativeHeightGroup = relative_height_group}, {}, "D#TextArea", {})
		d.add_row_labeled_field(form:find("/component[id=row_container]"), {caption="Extra"}, {id = "extra", relativeHeightGroup = relative_height_group}, {}, "D#TextArea", {})
	end

	local diff_results_table = diff_ontologies(file_path)

	form:attr("caption", string.format("%d missing, %d extra - Roundtrip diff   -   file -> graphics -> file", #(diff_results_table.missing or {}), #(diff_results_table.extra or {})))

	table.sort(diff_results_table.extra or {})
	form:transitive_closure("/component"):find("[id=extra]"):attr("text", table.concat(diff_results_table.extra or {}, "\n\n"))

	table.sort(diff_results_table.missing or {})
	form:transitive_closure("/component"):find("[id=missing]"):attr("text", table.concat(diff_results_table.missing or {}, "\n\n"))

	-- Log "ontology roundtrip test results" event.
	report.event("OWLGrEd_RoundtripTest_results", {
		missing_count = #(diff_results_table.missing or {}),
		extra_count = #(diff_results_table.extra or {})
	})

	d.show_form(form)
end

function close_roundtrip_diff_form()
	utilities.close_form("roundtrip-diff")
end







function load_ontology_module(ontology_path, module_signature_list)
	
	local status, render_prefs_table = pcall(parameters.createParametersTable)
	render_prefs_table = status and render_prefs_table or {}

	-- Log "ontology module load" event.
	report.event("OWLGrEd_LoadOntologyModule", {
		module_signature = module_signature_list,
		file_size_in_kb = file_size_in_kb(ontology_path),
		file_name = file_name(ontology_path),
		disabled_renderers = disabled_renderers(render_prefs_table),
		render_preferences_set = status,
	})


	local java_class_name = "loadOntology"
	local method_name = "importOntologies"

	local extensionsTable = {}
	local container = false
	if lQuery("ElemType[id='Container']"):is_not_empty() then container = true end
	local OWLGrEd_Schema = false
	if lQuery("Plugin[id='OWLGrEd_Schema']"):is_not_empty() and lQuery("Plugin[id='OWLGrEd_Schema']"):attr("status") == "loaded" then OWLGrEd_Schema = true end
	extensionsTable['container'] = container
	extensionsTable['OWLGrEd_Schema'] = OWLGrEd_Schema
	extensionsTable['defaultMaxCardinality'] = lQuery("ToolType/tag[key = 'DefaultMaxCardinality1']"):attr("value")
	
	
	local args = {
		ontology_path = ontology_path,
		signature = module_signature_list,
		extensions = extensionsTable,
		custom_render_spec = {
			prefixes = get_prefixes(),
			axioms = get_axioms()
		},
		preferences = parameters.createJSONParameterTable()
	}
	local serialized_args = json.encode(args)
	-- local file = assert(io.open("C:/Users/Julija/Desktop/Darbs/ImportaModulis/ontology2.txt", "w+"))
	-- local file = assert(io.open("C:/Users/user/Desktop/ontology2.txt", "w+"))
	-- file:write(serialized_args)
	-- file:close()
	ont_as_table_str = java.call_static_class_method(java_class_name, method_name, serialized_args)
	if str_starts_with(ont_as_table_str, "error - ") then
		report.event("OWLGrEd_owlapi_error", {message = ont_as_table_str})
		error(ont_as_table_str)
	else
		import_from_owlapi(ont_as_table_str)
	end
end

local module_signature_form_id = "owlgred-module-signature-specification-window"
local owlgred__ontology_path_for_module_loading = "owlgred__ontology_path_for_module_loading"

function open_module_specification_dialog(spec)
	
	local path = select_ontology_path()
	if path == "" then
		-- log(spec.call_on_fail)
		-- if spec.call_on_fail ~= nil then
			-- utilities.execute_fn(spec.call_on_fail)
		-- else
			-- return
		-- end
	else
		local form = lQuery.create("D#Form", {
			id = module_signature_form_id,
			caption = "Module Signature",
			[owlgred__ontology_path_for_module_loading] = path,
			buttonClickOnClose = false,
			eventHandler = utilities.d_handler("Close", "lua_engine", "lua.owl_protege.module_specification_close_window"),
		    component = {
		      lQuery.create("D#VerticalBox", {
						-- horizontalAlignment = 1,
		        component = {
		          lQuery.create("D#Label", {
			          caption = "Enter a set of entity names that should be included in the module",
			        }),
							lQuery.create("D#MultiLineTextBox", {id = "module_entities"}),
							lQuery.create("D#Button", {
			          caption = "Visualize Ontology Module",
			          eventHandler = utilities.d_handler("Click", "lua_engine", "lua.owl_protege.load_ontology_module_from_module_spec_form")
			        }),
		        }
		      })
		    }
		  })
		d.show_form(form)
	end
end

function module_specification_close_window()
	utilities.close_form(module_signature_form_id)
end

function load_ontology_module_from_module_spec_form()
	local form = lQuery("D#Form"):filter_attr_value_equals("id", module_signature_form_id)
	
	local ontology_path = form:attr(owlgred__ontology_path_for_module_loading)
	
	local items = form:find("/component/component[id=module_entities]"):assert_not_empty():find("/textLine[deleted=false]")
	
	local module_entity_names = items:map(function(item) return item:attr("text") end)
	
	utilities.close_form(module_signature_form_id)
	load_ontology_module(ontology_path, module_entity_names)
end


function load_java()
	class_name = "owlgred.OWLGrEdImport"
	method_name = "test"
	arg = "1"
	rez = java.call_static_class_method(class_name, method_name, arg)
	log("-- java vm loaded --", rez)
end


function project_open()
	
	log("project open")
	
	local project = lQuery("Project")
	local project_diagram = project:find("/graphDiagram")

	execute_in_new_thread("owl_protege.load_java")

	if project_diagram:find("/element.Node:has(/elemType[id=OWL])"):is_empty() then
		empty_project_dialog.open()
	end

	local tag_ = utilities.get_tags(project, "Path")
	local path = tda.GetProjectPath()
	if tag_:is_empty() then
		tag_ = utilities.add_tag(project, "Path", path)
	else
		tag_:attr({value = path})
	end
end

function start_import_from_protege_server()
	execute_in_new_thread("server.start")
end

function get_tool_name()
	local path_reverse = string.reverse(tda.GetToolPath())
	local tool_name = string.reverse(string.sub(path_reverse, 1, string.find(path_reverse, "\\") - 1))
	return tool_name
end

function close_server_on_port(port)
  local ip, port, message = "127.0.0.1", port, "exit"
  local tcp = assert(socket.tcp())
  tcp:connect(ip, port)
  tcp:send(message)
end

function close_import_server()
  log("close import server")
  close_server_on_port(6543)
  --close_server_on_port(65432)
end

function recalculate_styles(diagram, element_selector, style_change_function, progress_increment_fn)
  progress_increment_fn = progress_increment_fn or function () end
  diagram
    :find(element_selector)
      :each(function(element)
							local element = lQuery(element)
							style_change_function(element)
							progress_increment_fn()
						end)
end

function table_item_count(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

function estimate_import_item_count(import_data_table)
  local total_elements = 0
  
  for _, ontology_features in pairs(import_data_table["ontologies"] or {}) do
    local o_elements = 0
    for type_id, o_element_with_type in pairs(ontology_features["Elements"] or {}) do
      o_elements = o_elements + table_item_count(o_element_with_type)
      if type_id == "Link" or type_id == "Association" then -- because need separete style recalculation in the end
        o_elements = o_elements + 1
      end
    end
    total_elements = total_elements + o_elements
  end
  
  return total_elements
end

function import_from_protege(table_as_string)
  tda.CallFunctionWithPleaseWaitWindow("owl_protege.import_from_protege_helper", table_as_string)
end

function protege_owlgred_bridge_version_valid(data)
	local bridge_version = data.protege_owlgred_bridge_version
	if bridge_version and tonumber(bridge_version) >= min_protege_owlgred_bridge_version then
		return true
	else
		show_msg("Incompatible Protege OWLGrEd plugin.\nPlease download the latest version from owlgred.lumii.lv")
		return false
	end
end

function import_from_protege_helper(table_as_string)
  local t = os.time(); log("import start")
  local import_data = eval(table_as_string)
	
	tda.BringTDAToForground()
	
	if protege_owlgred_bridge_version_valid(import_data) then
		-- find out if there are render prefs
		render_prefs_set = false
		for _ in pairs(import_data.data.preferences or {}) do
			render_prefs_set = true
			break
		end


		-- Log "ontology import from protege" event.
  		report.event("OWLGrEd_OntologyFromProtege", {
  			string_length = string.len(table_as_string),
  			disabled_renderers = disabled_renderers(import_data.data.preferences),
  			render_preferences_set = render_prefs_set,
  		})

		local java_class_name = "owlgred.OWLGrEdImport"
		local method_name = "read_from_protege"
		
		import_data.data.custom_render_spec = {
			prefixes = get_prefixes(),
			axioms = get_axioms()
		}
		
		-- print(dumptable(import_data.data.preferences))

		local args = import_data.data

		local serialized_args = owl_protege_export.serialize_to_clojure_string_form(args)


		local file = io.open("data_to_owlapi.clj", "w")
		file:write(serialized_args)
		file:close()


		ont_as_table_str = java.call_static_class_method(java_class_name, method_name, serialized_args)
		if str_starts_with(ont_as_table_str, "error - ") then
			report.event("OWLGrEd_owlapi_error", {message = ont_as_table_str})
			error(ont_as_table_str)
		else 
			import_from_owlapi_helper(ont_as_table_str)
		end
	end
	log("import protege finished in " .. (os.time() - t) .. " seconds")
end

function import_from_owlapi(table_as_string)
  tda.CallFunctionWithPleaseWaitWindow("owl_protege.import_from_owlapi_helper", table_as_string)
end

function get_import_stats(import_data)
	local impart_stats = {}
	for _, ontology_data in pairs(import_data["ontologies"]) do
		table.insert(impart_stats, ontology_data.ontology.stats)
	end
	return impart_stats
end


function import_from_owlapi_helper(table_as_string)
  local t = os.time(); log("import start")
  local import_data = eval(table_as_string)
  
  -- print(dumptable(import_data))

  -- Log "ontology deserialization" event.
  report.event("OWLGrEd_OntologyDeserialization", {ontologies = get_import_stats(import_data)})


  local progress_reporter = progress_reporter.create_progress_logger(1.0*estimate_import_item_count(import_data), "Rendering...")

  local ontology_diagram = deserialize_ontology_data(import_data, progress_reporter)
  utilities.execute_translets(lQuery("ToolType"), "LoadOntology", ontology_diagram)
 
  utilities.enqued_cmd("OkCmd", {graphDiagram = lQuery("Project/graphDiagram")}) -- refresh project diagram

  utilities.enqued_cmd("ActiveDgrCmd", {graphDiagram = ontology_diagram})
  utilities.enqued_cmd("ActiveElementCmd", {
    element = ontology_diagram:find("/element:has(/elemType[caption=Class]):first"),
    graphDiagram = ontology_diagram
  })
 
  log("import finished in " .. (os.time() - t) .. " seconds")
  tda.BringTDAToForground()
  return ontology_diagram
end


function deserialize_ontology_data(import_data, progress_reporter_fn)
  progress_reporter_fn = progress_reporter_fn or function() end
  local project_diagram_mappings = {}
  local project_diagram = lQuery("GraphDiagramType[id=projectDiagram]/graphDiagram:first")
  
  local active_ontology_id = import_data["active-ontology"]
  
  local ontology_to_activate
  
  local ontology_diagram_ids_for_style_recalculation = {}

  for id, ontology_data in pairs(import_data["ontologies"]) do
    local mappings = {}
    local ontology_seed, ontology_diagram = create_ontology(project_diagram, ontology_data["ontology"])
    
    project_diagram_mappings[id] = ontology_seed
    
    core.add_elements_by_table(ontology_diagram, mappings, ontology_data["Elements"] or {}, progress_reporter_fn)
    
    add_unexported_axioms(ontology_diagram, ontology_data, mappings)
    
    --recalculate association styles
    recalculate_styles(ontology_diagram, "/element:has(/elemType[id=Association])", OWL_specific.change_OWL_assoc_style, progress_reporter_fn)
    recalculate_styles(ontology_diagram, "/element:has(/elemType[id=Link])", OWL_specific.change_OWL_link_style, progress_reporter_fn)
	
    table.insert(ontology_diagram_ids_for_style_recalculation, ontology_diagram:id())

    if id == active_ontology_id then
      ontology_to_activate = ontology_diagram
    end
  end
  
  -- FIXME
  -- RecalculateStylesInImport needs to know whitch diagrams need to be recalculated
  -- we cannot call it derectly because there is a crash after calling one
  -- progress bar thread from onother
  -- and we cannot pass arguments through ExecTransfCmd
  -- therefore we pass them through a tmp argument in the Project instance
  lQuery("Project"):attr("owlgred_diagram_ids_for_style_recalculation", table.concat(ontology_diagram_ids_for_style_recalculation, ","))
  utilities.enqued_cmd("ExecTransfCmd", {info = "lua_engine#lua.owl_protege.call_RecalculateStylesInImport_translet"})


  core.add_elements_by_table(project_diagram, project_diagram_mappings, import_data["Elements"] or {}, progress_reporter_fn)
  
  return ontology_to_activate
end

function call_RecalculateStylesInImport_translet()
	local diagrams = lQuery({})

	-- retrieve diagrams from tmp atribute in Project
	local owlgred_diagram_ids_for_style_recalculation = lQuery("Project"):attr("owlgred_diagram_ids_for_style_recalculation") or ""

	for diagram_id_str in string.gfind(owlgred_diagram_ids_for_style_recalculation, "%d+") do
		diagrams = diagrams:add(lQuery(tonumber(diagram_id_str)))
	end

	local recalculate_styles_in_import = lQuery("ToolType"):find("/translet[extensionPoint = 'RecalculateStylesInImport']"):attr("procedureName")
	utilities.execute_translet(recalculate_styles_in_import, diagrams, list)
end

function prefixes_map_to_compart_struct(prefixes_map)
	local prefixes_comparts = {}
	for prefix, iri in pairs(prefixes_map or {}) do
		local compart_table = {
			Namespaces = {
				Prefix = prefix,
				IRI = iri
			}
		}
		
		table.insert(prefixes_comparts, compart_table)
	end
	
	return prefixes_comparts
end

function create_ontology(project_diagram, ontology_features)
  local ontology_seed_type = project_diagram:find("/graphDiagramType/elemType[id=OWL]")
  local ontology_seed = core.add_node(ontology_seed_type, project_diagram)
  
  core.add_compartments_by_table(ontology_seed, {
    Name = ontology_features["name"],
    Prefix = ontology_features["uri"],
    Date = os.date("%c"),
    Annotation = ontology_features["annotations"] or nil,
		ASFictitiousNamespaces = prefixes_map_to_compart_struct(ontology_features["prefixes"])
  })
  
  local ontology_diagram_type = lQuery("GraphDiagramType[id=OWL]")
  local ontology_diagram = core.add_diagram(ontology_diagram_type, ontology_features["name"], ontology_seed)
  ontology_diagram:attr("caption", ontology_features["uri"])
		
	-- if ontology_features["read_only_properties"] == "true" then
	-- 	utilities.add_tag(ontology_diagram, "read_only_property_fields", true)
	-- end

  return ontology_seed, ontology_diagram
end

function add_unexported_axioms(ontology_diagram, import_data, mappings)
  local list_of_unexported = import_data['unexported'] or {}
  ontology_diagram:attr("unexported_axioms", table.concat(list_of_unexported, "\n"))
end


function tooltip(element)
	require("color")
	require("tda_to_protege")

	local ontology_header = tda_to_protege.export_Header(utilities.get_diagram_from_element(element))
	local element_axioms = tda_to_protege.export_Element(element)

	local tooltip_color = color.rgb_to_tda_int(color.random_hue_rgb(0.5, 0.95))
	local tooltip_text = string.format('%s%s)', ontology_header, element_axioms)

	return tooltip_color, tooltip_text
end



function close_form()
  utilities.close_form("unexported_axioms")
end

function show_unexported()
  form = lQuery.create("D#Form", {
    id = "unexported_axioms"
    ,preferredWidth = 700
    ,preferredHeight = 500
    ,caption = "Axioms not shown"
    ,buttonClickOnClose = false
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.owl_protege.close_form()")
    ,component = {
      lQuery.create("D#TextArea", {
        readOnly = true
        ,text = lQuery("CurrentDgrPointer/graphDiagram"):attr("unexported_axioms")
      })
      ,lQuery.create("D#HorizontalBox",{
        horizontalAlignment = 1
        ,component = lQuery.create("D#Button", {
          caption = "Close"
          ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.owl_protege.close_form()")
        })
      })
    }
  })
  d.show_form(form)
end
