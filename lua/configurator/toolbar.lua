module(..., package.seeall)

d = require("dialog_utilities")
rep = require("lua_raapi")
repo = require("mii_rep_obj")
cu = require("configurator.configurator_utilities")
m = require("interpreter.Migration")
report = require("reporter.report")
delta = require("configurator.delta")

-- New Version Created

function new_version()
	cu.log_button_press("Versioning")
	local form = d.add_form({id = "new_version_form", caption = "Versioning", minimumWidth = 200})	
		local form_horizontal_box = d.add_component(form, {id = "form_horizontal_box", horizontalAlignment = 1}, "D#HorizontalBox")
		--add_input_field_event_function(form_horizontal_box, "New Vesion", "version", project, {FocusLost = "lua.configurator.configurator.update_from_project_version_field"})
		d.add_row_labeled_field(form, {caption = "New Version"}, {id = "new_version", text = make_new_version_value()}, {id = "row_version"}, "D#InputField", {Change = "lua.configurator.toolbar.check_unique_version"})
	
	local button_box = d.add_component(form, {id = "dialog_button_box", horizontalAlignment = 1}, "D#HorizontalBox")
		local cancel_button = d.add_button(button_box, {id = "dialog_close_button", caption = "Cancel"}, {Click = "lua.dialog_utilities.close_form"})
													:link("defaultButtonForm", lQuery("D#Form[id = 'new_version_form']"))
		local ok_button = d.add_button(button_box, {id = "dialog_close_button", caption = "OK"}, {Click = "lua.configurator.toolbar.close_versioning()"})										
	d.delete_event()
	d.show_form(form)
end

function update_from_project_version_field()
	local project = lQuery("Project")
	local old_version = project:attr("version")
	local value = d.get_component_by_id("new_version"):attr("text")
	project:attr({version = value})
	utilities.get_tags(project, "OldVersion"):delete()
	utilities.add_tag(project, "OldVersion", old_version, true)
end

function check_unique_version()
	local file_name_list = get_list_of_version_names(get_migration_files())
	local entered_new_version_field = d.get_component_by_id("new_version")
	if file_name_list[entered_new_version_field:attr("text")] then
		d.set_error_field(entered_new_version_field, "Enter unique version!", true)
	else
		d.set_field_ok(entered_new_version_field, true)
	end
end

function make_new_version_file(is_new_version_file_needed)
	local List = {}
	local list_of_configurator_diagram_types = {specificationDgr = true, Repository = true, MMInstances = true}
	lQuery("GraphDiagramType"):each(function(diagram_type)
		local diagram_type_id = diagram_type:attr("id")
		if list_of_configurator_diagram_types[diagram_type_id] ~= true then
			List[diagram_type_id] = {Status = "Updated", ElemTypes = {}, OldName = diagram_type_id}
			diagram_type:find("/elemType"):each(function(elem_type)
				local elem_type_id = elem_type:attr("id")
				List[diagram_type:attr("id")]["ElemTypes"][elem_type_id] = {Status = "Updated", CompartTypes = {}, OldName = elem_type_id}
				elem_type:find("/compartType"):each(function(compart_type)
					local compart_type_id = compart_type:attr("id")
					List[diagram_type:attr("id")]["ElemTypes"][elem_type_id]["CompartTypes"][compart_type_id] = {Status = "Updated", SubCompartTypes = {}, OldName = compart_type_id}
					make_subcompartments_in_new_version_file(compart_type, List[diagram_type:attr("id")]["ElemTypes"][elem_type_id]["CompartTypes"][compart_type_id]['SubCompartTypes'])
				end)
			end)
		end
	end)
	local tmp_version_content = ""
	local file = utilities.open_tmp_version_file("r")
	if file ~= nil then
		tmp_version_content = file:read("*a")
		io.close(file)
	end
	local session_file_content = ""
	file = utilities.open_session_file("r")
	session_file_content = file:read("*a")
	io.close(file)

	if is_new_version_file_needed then
		local old_version, new_version = get_project_old_and_new_versions()
		local file = utilities.open_file_from_current_project(string.format("\\migration\\%s_to_%s.lua", old_version, new_version), "w")
		assert(file, "Failed to create migration file")
		file:write('migration = require("interpreter.Migration")\nmigration.add_tag()\nlocal target_type_list = migration.delete_configurator_types()\n', 
			delta.dump_configurator(), 
			tmp_version_content, 
			session_file_content, 
			'migration.process_version_list(List)\nmigration.delete_target_types(target_type_list)\n')
		file:write(string.format('lQuery("Project"):attr("version", "%s")', new_version))
		io.close()
	else
		--file:write('--first migration\n')
	end

	file = utilities.open_file_from_current_project("\\tmp_version.lua", "w")
		file:write("List = " .. dumptable(List) .. "\n")
	io.close(file)
end

function make_subcompartments_in_new_version_file(compart_type, list)
	compart_type:find("/subCompartType"):each(function(sub_compart_type)	
		local sub_compart_type_id = sub_compart_type:attr("id")
		list[sub_compart_type_id] = {Status = "Updated", SubCompartTypes = {}, OldName = sub_compart_type_id}
		make_subcompartments_in_new_version_file(sub_compart_type, list[sub_compart_type_id]['SubCompartTypes'])
	end)
end

function get_project_old_and_new_versions()
	local project = lQuery("Project")
	local new_version = project:attr("version")
	local old_version = utilities.get_tags(project, "OldVersion"):attr("value")
	return old_version, new_version
end

function make_new_version_value()
	local version = "Version"
	local file_name_list = get_list_of_version_names(get_migration_files())
	for i = 1,math.huge do
		if not(file_name_list[version]) then
			return version
		end
		version = version .. i
	end
end

function get_list_of_version_names(file_list)
	local file_name_list = {}
	for _, file_name in ipairs(file_list) do
		local start_version_name = get_start_version(file_name)
		file_name_list[start_version_name] = true
	end
	file_name_list[lQuery("Project"):attr("version")] = true
	return file_name_list
end

function get_start_version(file_name)
	local start = string.find(file_name, "_to_")
	if start == nil then
		error("Migration file naming error")
	end
	return string.sub(file_name, 1, start-1)
end

function close_versioning()
	close_new_version_form()
end

function close_new_version_form()
	cu.log_button_press("Close")
	update_from_project_version_field()
	local project = lQuery("Project")
	local tag_ = utilities.get_tags(project, "isFirstVersion")
	local is_new_version_file_needed = true
	if tag_:is_not_empty() then
		is_new_version_file_needed = false
		tag_:delete()
	end
	make_new_version_file(is_new_version_file_needed)
	utilities.clear_session_file()
	utilities.close_form("new_version_form")
	-- rep.Save()
end

-- Execute Migration

function execute_migration()
	execute_script_form({FormCaption = "Execute Script", ExtraPath = "\\Migration\\", DropDown = "lua.configurator.toolbar.get_migration_file_list"})
end

-- Create Domain

function create_domain()
	execute_script_form({FormCaption = "Create Domain", ExtraPath = "\\", DropDown = "lua.configurator.toolbar.get_domain_file_list"})	
end

function execute_script_form(list)
	local form = d.add_form({id = "execute_script_form", caption = list["FormCaption"], minimumWidth = 400})
		local label_caption = tda.GetProjectPath() .. list["ExtraPath"]
		local label = d.add_component(form, {caption = label_caption, id = "label_field",}, "D#Label")
		d.add_row_labeled_field(form, {caption = "Script"}, {id = "execute_script", text = ""}, {id = "row_execute_script"}, "D#ComboBox", {DropDown = list["DropDown"]})
		local button_box = d.add_component(form, {id = "dialog_button_box", horizontalAlignment = 1}, "D#HorizontalBox")
			local cancel_button = d.add_button(button_box, {id = "dialog_close_button", caption = "Cancel"}, {Click = "lua.dialog_utilities.close_form"})
														:link("defaultButtonForm", lQuery("D#Form[id = 'new_version_form']"))
			local ok_button = d.add_button(button_box, {id = "dialog_close_button", caption = "OK"}, {Click = "lua.configurator.toolbar.close_execute_script()"})
	d.delete_event()
	d.show_form(form)
end

function close_execute_script()
	local label_field = d.get_component_by_id("label_field")
	local path = label_field:attr("caption")
	local text_field = d.get_component_by_id("execute_script")
	local file_name = text_field:attr("text")
	if file_name ~= "" then
		dofile(path .. file_name)
	end
	utilities.close_form("execute_script_form")
end

function add_directory_files_to_drop_down(combo_box_id, path)
	local luafiles = get_directories_files(path)
	local combo_box = d.get_component_by_id(combo_box_id)
	d.clear_list_box(combo_box)
	cu.add_configurator_comboBox(luafiles, combo_box)
end

function get_migration_file_list()
	add_directory_files_to_drop_down("execute_script", tda.GetProjectPath() .. "\\Migration")
end

function get_domain_file_list()
	add_directory_files_to_drop_down("execute_script", tda.GetProjectPath())
end

function get_migration_files()
	return get_directories_files(tda.GetProjectPath() .. "\\Migration")
end

function get_directories_files(path)
	local file_name = "_tmp"
	local dircmd = "cd " .. path .." && dir /b > " .. file_name
	os.execute(dircmd)
	local luafiles = {}
	local path_to_file = path .. "\\" .. file_name
	for f in io.lines(path_to_file) do
	    if f:sub(-4) == ".lua" then
	        luafiles[#luafiles+1] = f --utilities.get_last_item_from_path(f)
	    end
	end
	os.execute("del " .. path_to_file)
	return luafiles
end

-- Visualize MM

function make_repozitory_class_diagram()
	local repo_diagram_type = lQuery("GraphDiagramType[id = 'Repository']")
	--repo_diagram_type:find("/graphDiagram"):delete()
	local count = repo_diagram_type:find("/graphDiagram"):size()
	count = count + 1

	--utilities.add_graph_diagram_to_graph_diagram_type("Class Diagram", repo_diagram_type)
	local diagram = utilities.add_graph_diagram_to_graph_diagram_type("Metamodel" .. count, repo_diagram_type)
	make_repository_classes(diagram, repo_diagram_type)
	utilities.execute_cmd("ActiveDgrCmd", {graphDiagram = diagram})
	utilities.execute_cmd("OkCmd")
end

function make_repository_classes(diagram, diagram_type)
--kompozicijas, visparinasanas, vajag tikt vala no mantotajam asociacijam un atributiem
	local diagram_list = {}
	diagram_list["Classes"] = {}
	local class_list = repo.class_list()
	for _, class in ipairs(class_list) do
		local class_name = class.name
		if string.sub(class_name, 1, 2) ~= "D#" then 
			local class_id = rep.findClass(class_name)
			local attr_list = class:property_list()
			generate_attr_types(attr_list)
			local dictionary = transform_attr_list_to_dictionary(attr_list)
			local classes = {}
			local elem_type = diagram_type:find("/elemType[id = 'Class']")	 
			diagram_list["Classes"][class_id] = {class = add_class(class_name, diagram), attrs = dictionary}
		end
	end
	
	local links = lQuery.foldr(lQuery.map(class_list, function(x)
                  local retVal = {}
                  local it = rep.getIteratorForAllOutgoingAssociationEnds(x.id)
                  local r = rep.resolveIteratorFirst(it)
                  local i = 0
                  while (r) do
                    i = i+1
                    retVal[i] = r
                    r = rep.resolveIteratorNext(it)
                  end
                  rep.freeIterator(it)
                  return retVal
           end), {}, function(accumulator, link_list) 		
		for _, link_id in ipairs(link_list) do
			local inv_link_id = rep.getInverseAssociationEnd(link_id)
			if accumulator[inv_link_id] == nil then
				accumulator[link_id] = link_id	
			end
		end
		return	accumulator
	end)

	for link_id, link in pairs(links) do
		local association = {}
		local role_list = {}
        local inv_id = rep.getInverserAssociationEnd(link_id)
        if rep.isComposition(link_id) then
          role_list.role = 12
          role_list.inv_role = 2
        elseif rep.isComposition(inv_id) then
          role_list.role = 2
          role_list.inv_role = 12
        else
          role_list.role = 4
          role_list.inv_role = 4
        end
        role_list.link_type_id = link_id
        role_list.inv_link_type_id = inv_id
        role_list.cardinality = 2
        role_list.inv_cardinality = 2
        role_list.object_type_id = rep.getTargetClass(link_id)
        role_list.inv_object_type_id = rep.getSourceClass(link_id)
		make_repository_line(diagram, role_list, diagram_list["Classes"])
	end
	for class_id, class_entity in pairs(diagram_list["Classes"]) do
		local sub_class_list = {}
        local it = raapi.getIteratorForDirectSubClasses(class_id)
        local subclass_id = raapi.resolveIteratorFirst(it)
        local i = 0
        while (subclass_id) do
          i = i+1
          sub_class_list[i] = subclass_id
          subclass_id = raapi.resolveIteratorNext(it)
        end
        raapi.freeIterator(it)
		for _, sub_class_id in ipairs(sub_class_list) do
			local sub_class_entity = diagram_list["Classes"][sub_class_id]
			if sub_class_entity ~= nil then
				remove_dublicate_attributes(sub_class_entity, class_entity)
				make_repository_generalization(sub_class_entity["class"], class_entity["class"], diagram)
			end
		end
	end
	for _, class_entity in pairs(diagram_list["Classes"]) do
		local class = class_entity["class"]
		local attr_list = class_entity["attrs"]
		local attrs = utilities.concat_dictionary(attr_list, "\n")
		add_class_attributes(class, attrs)
	end
end

function add_class_attributes(node, attributes)
	local _, _, value_compart_type = get_repository_types()
		add_compartment(value_compart_type, node, attributes)
end

function get_repository_types()
	local source_type = lQuery("GraphDiagramType[id = 'Repository']")
	local instance_type = source_type:find("/elemType[id = 'Class']")
	local name_compart_type = instance_type:find("/compartType[id = 'Name']")
	local value_compart_type = instance_type:find("/compartType[id = 'Value']")
return instance_type, name_compart_type, value_compart_type
end

function add_class(class_name, diagram)
	local class_type, name_compart_type = get_repository_types()
	local node = core.add_node(class_type, diagram)
		add_compartment(name_compart_type, node, class_name)
return node
end

function add_compartment(compartment_type, parent, value)
	local input = core.build_input_from_value(value, compartment_type)
	local compartment = lQuery.create("Compartment", {
				input = input,
				value = value,
				compartType = compartment_type,
				compartStyle = compartment_type:find("/compartStyle")
				})
	if parent:filter(".Compartment"):size() > 0 then
		compartment:link("parentCompartment", parent)
	else
		compartment:link("element", parent)
	end
end

function make_repository_line(diagram, role_list, class_list)
	local line_type_name = "Association"
	if role_list.role ~= 4 or role_list.inv_role ~= 4 then
		line_type_name = "Composition"
	end
	local role_id = role_list.link_type_id
	local inv_role_id = role_list.inv_link_type_id
	local card_id = role_list.cardinality
	local inv_card_id = role_list.inv_cardinality
	
	local direct_role = rep.getRoleName(role_id)
	local inverse_role = rep.getRoleName(inv_role_id)

	local direct_cardinality = get_cardinality(card_id)
	local inverse_cardinality = get_cardinality(inv_card_id)

 	local direct_class_id = role_list.object_type_id
	local inverse_class_id = role_list.inv_object_type_id
	local start_element = class_list[direct_class_id]
	local end_element = class_list[inverse_class_id]
	if start_element ~= nil and end_element ~= nil then
		local edge_type, direct_role_type, inverse_role_type, direct_cardinality_type, inverse_cardinality_type = get_repository_line_types(line_type_name)
		local edge = core.add_edge(edge_type, end_element["class"], start_element["class"], diagram)
			if line_type_name == "Composition" then
				inverse_role = ""
				inverse_cardinality = ""
			end
			add_compartment(direct_role_type, edge, direct_role)
			add_compartment(inverse_role_type, edge, inverse_role)
			add_compartment(direct_cardinality_type, edge, direct_cardinality)
			add_compartment(inverse_cardinality_type, edge, inverse_cardinality)
			
		return edge
	end
	
end

function get_cardinality(val)
--Card_01 = 1,
--Card_0N = 2,
--Card_1 = 3,
--Card_1N = 4,
	if val == 1 then
		return "0..1"
	elseif val == 2 then
		return "*"
	elseif val == 3 then
		return "1"
	elseif val == 4 then
		return "1..*"
	end
end

function generate_attr_types(attr_list)
--hacks, vajag nemt tipus no repozitorija
	for i, attr in ipairs(attr_list) do
		local data_type = ":String"
		if string.find(attr, "is", 1) == 1 then
			data_type = ":Boolean"
		end
		attr_list[i] = attr .. data_type
	end
end

function transform_attr_list_to_dictionary(attr_list)
	local dictionary = {}
	for _, id in ipairs(attr_list) do
		dictionary[id] = id
	end
return dictionary
end

function remove_dublicate_attributes(sub_class_entity, super_class_entity)
	local super_class_attr_list = super_class_entity["attrs"]
	local sub_class_attr_list = sub_class_entity["attrs"]
	for _, attr in pairs(super_class_attr_list) do
		if sub_class_attr_list[attr] ~= nil then
			sub_class_attr_list[attr] = nil
		end
	end
end

function make_repository_generalization(sub_class, super_class, diagram)
	local edge_type = lQuery("GraphDiagramType[id = 'Repository']/elemType[id = 'Generalization']")
	local edge = core.add_edge(edge_type, sub_class, super_class, diagram)
	
end

function get_repository_line_types(line_type_name)
	local source_type = lQuery("GraphDiagramType[id = 'Repository']")
	local line_type = source_type:find("/elemType[id = '" .. line_type_name .. "']")
	local direct_role_type = line_type:find("/compartType[id = 'DirectRole']")
	local inverse_role_type = line_type:find("/compartType[id = 'InverseRole']")
	local direct_cardinality = line_type:find("/compartType[id = 'DirectCardinality']")
	local inverse_cardinality = line_type:find("/compartType[id = 'InverseCardinality']")
return line_type, direct_role_type, inverse_role_type, direct_cardinality, inverse_cardinality
end


--Project translets

function edit_project_object()
	local form = d.add_form({id = "form", caption = "Project Properties", minimumWidth = 200, minimumHeight = 50})	
	local tool_type = lQuery("ToolType")
	local project = lQuery("Project")
	d.add_row_labeled_field(form, {caption = "Name"}, {id = "name", text = project:attr("name")}, {id = "row_name"}, "D#InputField", {FocusLost = "lua.configurator.toolbar.update_project_attribute"})
	d.add_row_labeled_field(form, {caption = "Version"}, {id = "version", text = project:attr("version")}, {id = "row_version"}, "D#InputField", {FocusLost = "lua.configurator.toolbar.update_project_attribute"})
	cu.add_transformation_field_with_events(form, "On Open", "procOnOpen", tool_type, {FocusLost = "lua.configurator.toolbar.update_project_obj"})
	cu.add_transformation_field_with_events(form, "On Close", "procOnClose", tool_type, {FocusLost = "lua.configurator.toolbar.update_project_obj"})
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
	d.show_form(form)
end

function update_project_attribute()
	local attr, value = cu.get_event_source_attrs("text")
	local project = lQuery("Project")
	project:attr({[attr] = value})
	d.delete_event()
end

function update_project_obj()
	local attr, value = cu.get_event_source_attrs("text")
	local tool_type = lQuery("ToolType")
	cu.add_translet_to_source(tool_type, attr, value)
	d.delete_event()
end

function update_project_version()
	local project = lQuery("Project")
	local version = project:attr("version")
	version = version + 1
	project:attr({version = version})
end


-- GraphDiagramType Engine

function edit_head_engine()
	edit_engine("GraphDiagramEngine", "Graph Diagram Engine", "lua.configurator.toolbar.update_graph_engine")
end

function edit_engine(engine_name, form_caption, func_name)
	local form = d.add_form({id = "form", caption = form_caption, minimumWidth = 670, minimumHeight = 50})
	local graph_engine = lQuery(engine_name)
	local list = utilities.get_lQuery_object_attribute_list(graph_engine)
	for index, value in pairs(list[1]) do
		cu.add_input_field_function(form, index, index, graph_engine, func_name)
	end
	local button_box = d.add_component(form, {id = "button_box", horizontalAlignment = 1}, "D#HorizontalBox")	
	local close_button = d.add_button(button_box, {id = "close_button", caption = "Close"}, {Click = "lua.configurator.configurator.close_form()"}):link("defaultButtonForm", form)
	d.show_form(form)
end

function update_graph_engine()
	update_engine("GraphDiagramEngine")
end

function update_engine(engine_name)
	local attr, value = cu.get_event_source_attrs("text")
	local graph_engine = lQuery(engine_name):attr({[attr] = value})
	d.delete_event()
end


--Tree Engine

function edit_tree_engine()
	edit_engine("TreeEngine", "Tree Engine",  "lua.configurator.toolbar.update_tree_engine")
end

function update_tree_engine()
	update_engine("TreeEngine")	
end

