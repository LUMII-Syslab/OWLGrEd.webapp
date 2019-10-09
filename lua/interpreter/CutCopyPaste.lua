module(..., package.seeall)
require("utilities")
require("core")
Delete = require("interpreter.Delete")
require("lua_tda")
require("config_properties")


local global_table = {}
local global_counter_table = {}

function Cut()
	local diagram = utilities.current_diagram()
	if diagram:attr_e("isReadOnly") ~= "true" then
		Copy()
		Delete.Delete()
	end
end

function Copy(deep_copy_boolean, is_container_needed)
	local limit = config_properties.get_config_value("copy_limit")
	if deep_copy_boolean == nil then
		deep_copy_boolean = true
	end
	if is_container_needed == nil then
		is_container_needed = true
	end
	local diagram = utilities.current_diagram()
	utilities.save_dgr_cmd(diagram)
	save_target_diagrams_from_element(diagram, deep_copy_boolean)
	local code = get_copy_code(diagram:find("/collection"), diagram, deep_copy_boolean, is_container_needed)
	local sum = get_sum_in_table(global_counter_table)
	if limit > sum then
		tda.PutTransformationToClipboard(code)
	else
		tda.PutTransformationToClipboard("--Too many elemens in clipboard")	
	end
	--print(os.time() - time)
end

function Dublicate()
    Copy(false, false)
    Paste()
end

function save_target_diagrams_from_element(diagram, deep_copy_boolean)
	diagram:find("/collection/element"):each(function(elem)
		save_target_diagram(elem, {}, deep_copy_boolean)
	end)
end

function save_target_diagram(elem, traversed_list, deep_copy_boolean)
    if deep_copy_boolean then
	    elem:find("/child"):each(function(diagram)
		    local diagram_id = diagram:id()
		    if traversed_list[diagram_id] == nil then
			    traversed_list[diagram_id] = diagram
			    utilities.save_dgr_cmd(diagram)
			    diagram:find("/element"):each(function(element)
				    save_target_diagram(element, traversed_list)
			    end)
		    end
	    end)
	end
end

function Paste()
	--local time1 = os.time()
	get_from_cliboard()
	--print(os.time() - time1)
end

function add_original_link()
	local list_of_code = {}
	for _, elem in pairs(global_table) do
		elem:find("/copy"):each(function(elem_copy)
			table.insert(list_of_code, string.format('%s:link("copy", %s)\n', utilities.make_obj_to_var(elem),  utilities.make_obj_to_var(elem_copy)))
		end)
	end
	return table.concat(list_of_code)
end

function get_copy_code(collection, diagram, deep_copy_boolean, is_container_needed)
	local list_of_code = {}
	local copied_elems = {}
	table.insert(list_of_code, generated_clipboard_code(collection, diagram, copied_elems, true, deep_copy_boolean, is_container_needed))
	table.insert(list_of_code, add_original_link())
	table.insert(list_of_code, 'local tmp_diagram = utilities.current_diagram()\n')
	table.insert(list_of_code, 'local cmd = utilities.create_command("PasteCmd"):link("graphDiagram", tmp_diagram)\n')
	if deep_copy_boolean then	
		table.insert(list_of_code, get_target_diagrams(copied_elems))
	end
	table.insert(list_of_code, 'lQuery("FreeBox:has(/command)"):attr({freeBox_w = "", freeBox_h = "", freeBox_y = "", freeBox_x = "", location = ""})\n')
	collection:find("/element"):each(function(elem)
		table.insert(list_of_code, string.format('cmd:link("element", %s)\n', utilities.make_obj_to_var(elem)))
		table.insert(list_of_code, string.format('cmd:link("element", %s)\n', utilities.make_obj_to_var(elem)))
	end)
	table.insert(list_of_code, 'utilities.execute_cmd_obj(cmd)\n')
	table.insert(list_of_code, 'if tree_node ~= nil then\n\tt = require("interpreter.tree")\n\tt.refresh(tree_node)\nend\n')


	return table.concat(list_of_code)
end

function generated_clipboard_code(collection, diagram, copied_elems, is_root, deep_copy_boolean, is_container_needed)
	--print("generated_clipboard_code")
	local elem_table = {}
	elem_table["Node"] = {}
	elem_table["Edge"] = {}
	elem_table["Port"] = {}
	elem_table["FreeBox"] = {}
	elem_table["FreeLine"] = {}
	local tmp_table = {}
	tmp_table["Node"] = {}
	tmp_table["Edge"] = {}
	tmp_table["Port"] = {}
	tmp_table["FreeBox"] = {}
	tmp_table["FreeLine"] = {}
	local count = 0
	collection:find("/element"):each(function(elem)
		count = count + 1
		if elem:find("/copy"):is_not_empty() then
			global_table[elem:id()] = elem
		end
		local class_name = utilities.get_class_name(elem)
		if class_name == "Edge" then
			if elem:find("/start"):is_not_empty() and elem:find("/end"):is_not_empty() then	
				table.insert(elem_table[utilities.get_class_name(elem)], elem)	
			end
		else
    			local list = {}
    			if is_container_needed then
				get_container_list(elem, list)
				for i = #list,1,-1 do
					local tmp = list[i]	
					insert_elem_in_table(tmp, elem_table, tmp_table)
				end
			end
--			if deep_copy_boolean then
			insert_elem_in_table(elem, elem_table, tmp_table)
--			end
		end
	end)
	local list_of_code = {}
	table.insert(list_of_code, '--This is TDA copy\n')
	table.insert(list_of_code, 'cu = require("configurator.const.const_utilities")\n')	
	local project = lQuery("Project")
	if is_root then
		table.insert(list_of_code, string.format('local %s = utilities.current_diagram()\n', utilities.make_obj_to_var(diagram)))
		table.insert(list_of_code, string.format('local root_diagram_id = "%s"\n', diagram:find("/graphDiagramType"):attr("id")))		
		table.insert(list_of_code, string.format('if not(%s:find("/graphDiagramType"):attr("id") == root_diagram_id and lQuery("Project"):attr("name") == "%s") then\n	return -1\nend\n', utilities.make_obj_to_var(diagram), project:attr("name")))
	end
	table.insert(copied_elems, elem_table)
	table.insert(list_of_code, generate_code_for_copies(elem_table, diagram, copied_elems, deep_copy_boolean, is_container_needed))
	table.insert(global_counter_table, count)
return table.concat(list_of_code)
end

function get_target_diagrams(copied_elems)
	local list_of_code = {}
	for _, tables in ipairs(copied_elems) do
		table.insert(list_of_code, process_copied_table(tables["Node"]))
		table.insert(list_of_code, process_copied_table(tables["Edge"]))
		table.insert(list_of_code, process_copied_table(tables["Port"]))
		table.insert(list_of_code, process_copied_table(tables["FreeBox"]))
		table.insert(list_of_code, process_copied_table(tables["FreeLine"]))
	end
	return table.concat(list_of_code)
end

function process_copied_table(tables)
	local list_of_code = {}
	for _, elem in ipairs(tables) do
		local target_diagram = elem:find("/target")
		if target_diagram:is_not_empty() then
			--table.insert(list_of_code, string.format('%s:link("target", lQuery("GraphDiagram[caption = %s%s%s]:last()"))\n', utilities.make_obj_to_var(elem), "'", string.gsub(target_diagram:attr("caption"), '"', '\\"'), "'"))
			table.insert(list_of_code, string.format('%s:link("target", %s)\n', utilities.make_obj_to_var(elem), utilities.make_obj_to_var(target_diagram)))

			table.insert(list_of_code, copy_tags(target_diagram))
		end
	end
	return table.concat(list_of_code)
end

function get_copied_elems(elem_table)
	for _, elem in ipairs(elem_table["Node"]) do
		table.insert(copied_elems, elem)
	end
end

function insert_elem_in_table(elem, list, tmp_list)
	if tmp_list[utilities.get_class_name(elem)][elem:id()] == nil then
		tmp_list[utilities.get_class_name(elem)][elem:id()] = elem
		table.insert(list[utilities.get_class_name(elem)], elem)
	end
end

function get_container_list(elem, list)
	local container = elem:find("/container")
	if container:is_not_empty() and container:find("/collection"):is_not_empty() then
		table.insert(list, container)
		return get_container_list(container, list)
	else
		return list
	end
end

function generate_code_for_copies(elem_table, diagram, copied_elems, deep_copy_boolean, is_container_needed)
	local list_of_code = {}
	table.insert(list_of_code, create_code_each_element(elem_table, "Node", diagram, copied_elems, deep_copy_boolean, is_container_needed))
	table.insert(list_of_code, create_code_each_element(elem_table, "FreeBox", diagram, copied_elems, deep_copy_boolean, is_container_needed))
	table.insert(list_of_code, create_code_each_element(elem_table, "FreeLine", diagram, copied_elems, deep_copy_boolean, is_container_needed))
	for _, obj in pairs(elem_table["Port"]) do
		table.insert(list_of_code, create_code_single_element(obj, diagram, copied_elems, deep_copy_boolean, is_container_needed))
		table.insert(list_of_code, string.format('%s:link("node", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(obj:find("/node"))))
	end
	for _, obj in pairs(elem_table["Edge"]) do
		table.insert(list_of_code, create_code_single_element(obj, diagram, copied_elems, deep_copy_boolean, is_container_needed))
	end
	for _, obj in pairs(elem_table["Edge"]) do
		table.insert(list_of_code, string.format('%s:link("start", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(obj:find("/start"))))
		table.insert(list_of_code, string.format('%s:link("end", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(obj:find("/end"))))
	end
	if deep_copy_boolean then
    		table.insert(list_of_code, copy_target_diagrams(elem_table))
	end
	return table.concat(list_of_code)
end

function copy_target_diagrams(elem_table)
	local list_of_code = {}
	table.insert(list_of_code, copy_target_diagram_from_element(elem_table, "Node"))
	table.insert(list_of_code, copy_target_diagram_from_element(elem_table, "Port"))
	table.insert(list_of_code, copy_target_diagram_from_element(elem_table, "FreeLine"))
	table.insert(list_of_code, copy_target_diagram_from_element(elem_table, "FreeBox"))
	table.insert(list_of_code, copy_target_diagram_from_element(elem_table, "Edge"))
	return table.concat(list_of_code)
end

function copy_target_diagram_from_element(elem_table, class_name)
	local list_of_code = {}
	for _, obj in ipairs(elem_table[class_name]) do
		local target_dgr = obj:find("/target")
		if target_dgr:is_not_empty() then
			--table.insert(list_of_code, string.format('%s:link("target", lQuery("GraphDiagram[caption = %s%s%s]:last()"))\n', utilities.make_obj_to_var(obj), "'", string.gsub(target_dgr:attr("caption"), '"', '\\"'), "'"))
			--table.insert(list_of_code, string.format('%s:link("target", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(target_dgr)))
		end
	end
	return table.concat(list_of_code)
end

function create_code_each_element(elem_table, elem_name, diagram, copied_elems, deep_copy_boolean, is_container_needed)
	local list_of_code = {}
	for _, obj in pairs(elem_table[elem_name]) do
		local copy_func = obj:find("/elemType/translet[extensionPoint = 'procCopyElement']"):attr_e("procedureName")
		if copy_func ~= nil and copy_func ~= "" then
			table.insert(list_of_code, string.format('--%s\n', copy_func))
			table.insert(list_of_code, utilities.execute_translet(copy_func, obj, copied_elems, deep_copy_boolean))
		else
			table.insert(list_of_code, create_code_single_element(obj, diagram, copied_elems, deep_copy_boolean, is_container_needed))
		end
	end
	return table.concat(list_of_code)
end

function create_code_single_element(obj, diagram, copied_elems, deep_copy_boolean, is_container_needed)
	local list_of_code = {}
	table.insert(list_of_code, create_code_for_element(obj, diagram, is_container_needed))
	local target_diagram = obj:find("/child")
	if target_diagram:is_not_empty() then
		if deep_copy_boolean then
			local target_diagram_type = target_diagram:find("/graphDiagramType")
			local target_diagram_id = target_diagram_type:attr("id")
			table.insert(list_of_code, utilities.generate_create_instance_code(target_diagram))
			table.insert(list_of_code, string.format('%s:link("child", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(target_diagram)))
			table.insert(list_of_code, string.format('%s:link("graphDiagramType", lQuery("GraphDiagramType[id = %s]"))\n', utilities.make_obj_to_var(target_diagram), target_diagram_id))
			table.insert(list_of_code, copy_domain(obj, target_diagram, target_diagram_type))
			table.insert(list_of_code, copy_tree_node(target_diagram))
			table.insert(list_of_code, generated_clipboard_code(target_diagram, target_diagram, copied_elems, false, deep_copy_boolean, is_container_needed))
		end
	else
		table.insert(list_of_code, copy_domain(obj, target_diagram, target_diagram_type))
	end
	return table.concat(list_of_code)
end

function copy_tree_node(diagram)
	local tree_node = utilities.get_tree_node_from_thing(diagram)
	local list_of_code = {}
	if tree_node:is_not_empty() then
		table.insert(list_of_code, 'tree_node = utilities.get_tree_node_from_thing(utilities.current_diagram())\n')
		table.insert(list_of_code, 'if tree_node:is_not_empty() then\n\t')
		table.insert(list_of_code, utilities.generate_create_instance_code(tree_node))
		table.insert(list_of_code, string.format('\t%s:link("thing", %s)\n', utilities.make_obj_to_var(tree_node), utilities.make_obj_to_var(diagram)))	
		table.insert(list_of_code, string.format('\t%s:link("parent", tree_node)\n', utilities.make_obj_to_var(tree_node)))
		table.insert(list_of_code, 'end\n')
	end
	return table.concat(list_of_code)
end

function create_code_for_element(obj, diagram, is_container_needed)
	local list_of_code = {}
	table.insert(list_of_code, utilities.generate_create_instance_code(obj))
	table.insert(list_of_code, add_element_to_parent(obj, diagram, is_container_needed))
	table.insert(list_of_code, add_element_to_elem_type(obj))
	table.insert(list_of_code, add_compartments(obj))
	table.insert(list_of_code, copy_tags(obj))
	return table.concat(list_of_code)
end

function copy_domain(obj, target_diagram, target_diagram_type)
	local list_of_code = {}
	local copy_domain_func = obj:find("/elemType/translet[extensionPoint = 'procCopied']"):attr_e("procedureName")
	if copy_domain_func ~= "" then
		table.insert(list_of_code, string.format('--%s\n', copy_domain_func))
		local domain = utilities.execute_translet(copy_domain_func, obj)
		table.insert(list_of_code, domain)
	end
	if target_diagram:is_not_empty() then
		local diagram_style = target_diagram:find("/graphDiagramStyle")
		table.insert(list_of_code, utilities.generate_create_instance_code(diagram_style))
		table.insert(list_of_code, string.format('%s:link("graphDiagramType", %s)\n', utilities.make_obj_to_var(diagram_style), utilities.make_obj_to_var(target_diagram_type)))
		table.insert(list_of_code, string.format('%s:link("graphDiagramStyle", %s)\n', utilities.make_obj_to_var(target_diagram),  utilities.make_obj_to_var(diagram_style)))
		table.insert(list_of_code, string.format('utilities.add_palette_to_diagram(%s, %s:find("/graphDiagramType"))\n', utilities.make_obj_to_var(target_diagram), utilities.make_obj_to_var(target_diagram)))
		table.insert(list_of_code, string.format('utilities.add_toolbar_to_diagram(%s, %s:find("/graphDiagramType"))\n', utilities.make_obj_to_var(target_diagram), utilities.make_obj_to_var(target_diagram)))	
		local copy_diagram_domain_func = target_diagram:find("/graphDiagramType/translet[extensionPoint = 'procCopied']"):attr_e("procedureName")
		if copy_diagram_domain_func ~= "" then
			table.insert(list_of_code, string.format('--%s\n', copy_diagram_domain_func))
			local domain = utilities.execute_translet(copy_diagram_domain_func, target_diagram)
			table.insert(list_of_code, domain)
		end
	end
	return table.concat(list_of_code)	
end

function make_cmd_variable(diagram)
	return string.format('cmd_%s', utilities.make_obj_to_var(diagram))
end

function add_element_to_parent(obj, diagram, is_container_needed)
	local list_of_code = {}
	table.insert(list_of_code, add_element_to_diagram(obj, diagram))
	if obj:filter(".Node"):is_not_empty() then
		table.insert(list_of_code, generate_container_code(obj, diagram, is_container_needed))
	end
	if is_container_needed then
    	local container = obj:find("/container")
	    if container:is_not_empty() then
		    table.insert(list_of_code, string.format('%s:link("container", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(container)))
	    end
	end
	return table.concat(list_of_code)
end

function generate_container_code(obj, diagram, is_container_needed)	
	local list_of_code = {}
	if is_container_needed then
		table.insert(list_of_code, string.format('if %s:id() == utilities.current_diagram():id() then\n', utilities.make_obj_to_var(diagram)))
		table.insert(list_of_code, string.format('local elem_collection = %s:find("/collection/element")\n', utilities.make_obj_to_var(diagram)))
		table.insert(list_of_code, string.format('\tif elem_collection:size() == 1 and elem_collection:id() ~= %s:id() then\n', utilities.make_obj_to_var(obj)))
		table.insert(list_of_code, string.format('\t\t%s:link("container", elem_collection)\n\tend\nend\n', utilities.make_obj_to_var(obj)))
	end
	return table.concat(list_of_code)
end

function add_element_to_diagram(obj, diagram)
	return string.format('%s:link("graphDiagram", %s)\n', utilities.make_obj_to_var(obj), utilities.make_obj_to_var(diagram))
end

function add_element_to_elem_type(obj)
	local list_of_code = {}
	local diagram_type_id = obj:find("/graphDiagram/graphDiagramType"):attr("id")
	local elem_type = obj:find("/elemType")
	local elem_type_id = elem_type:attr("id")
	local var = utilities.make_obj_to_var(obj)
	local elem_type_var = utilities.make_obj_to_var(elem_type)
	table.insert(list_of_code, string.format(' %s = lQuery("GraphDiagramType[id = %s]/elemType[id = %s]")\n', elem_type_var, diagram_type_id, elem_type_id))
	table.insert(list_of_code, string.format('%s:link("elemType", %s)\n', var, elem_type_var))
	local elem_style = obj:find("/elemStyle")
	if elem_style:is_not_empty() then
		elem_style_id = elem_style:attr("id")
		table.insert(list_of_code, string.format('%s:link("elemStyle", %s:find("/elemStyle[id = %s]"))\n', var, elem_type_var, elem_style_id))
	end
	return table.concat(list_of_code)
end

function copy_tags(obj)
	local list_of_code = {}
	obj:find("/tag"):each(function(tag)
		table.insert(list_of_code, utilities.generate_create_instance_code(tag))
		table.insert(list_of_code, string.format('%s:link("thing", %s)\n', utilities.make_obj_to_var(tag), utilities.make_obj_to_var(obj)))
	end)
	return table.concat(list_of_code)
end

function add_compartments(obj)
	return make_compartment_tree(obj, "compartment", "elemType", "compartType", true)
end

function make_compartment_tree(obj, role, parent_role_type, child_role_type, is_first)
	local list_of_code = {}
	local buls = 0
	obj:find("/" .. role):each(function(compart)
		local compart_type = compart:find("/compartType")
		if compart_type:is_not_empty() then	
			local compart_type_id = compart_type:attr("id")
			local parent_type = compart_type:find("/" .. parent_role_type)--:log("id")
			local compart_style_id = compart:find("/compartStyle"):attr("id")
			table.insert(list_of_code, utilities.generate_create_instance_code(compart))
			table.insert(list_of_code, string.format('%s:link("%s", %s)\n', utilities.make_obj_to_var(obj), role, utilities.make_obj_to_var(compart)))
			table.insert(list_of_code, copy_tags(compart))
			if buls == 0 and is_first and compart_type:is_not_empty() then
				table.insert(list_of_code, string.format(' %s = %s:find("/%s[id = %s]")\n', utilities.make_obj_to_var(compart_type), utilities.make_obj_to_var(parent_type), child_role_type, compart_type_id))
			end
			if compart_type_id ~= nil then
				table.insert(list_of_code, string.format('%s:link("compartType", %s)\n', utilities.make_obj_to_var(compart), utilities.make_obj_to_var(compart_type)))
				if compart_style_id ~= nil then
					table.insert(list_of_code, string.format('%s:link("compartStyle", %s:find("/compartStyle[id = %s]"))\n', utilities.make_obj_to_var(compart), utilities.make_obj_to_var(compart_type), compart_style_id))	
				end
			end
			if utilities.is_compart_type_fictious(parent_type) == false then
				table.insert(list_of_code, make_compartment_tree(compart, "subCompartment", "parentCompartType", "subCompartType", is_first))
			elseif utilities.is_compart_type_fictious(parent_type) and buls == 0 then
				table.insert(list_of_code, make_compartment_tree(compart, "subCompartment", "parentCompartType", "subCompartType", is_first))
			else
				table.insert(list_of_code, make_compartment_tree(compart, "subCompartment", "parentCompartType", "subCompartType", false))
			end
			local copy_compart_domain = compart_type:find("/translet[extensionPoint = 'procCreateCompartmentDomain']"):attr("procedureName")
			if copy_compart_domain ~= nil and copy_compart_domain ~= "" then
				table.insert(list_of_code, utilities.execute_fn(copy_compart_domain, compart))
			end
		end
	end)
	return table.concat(list_of_code)
end

function get_from_cliboard()
	local generated_code = tda.GetTransformationFromClipboard()
	local tmp = "--This is TDA copy"
	local copy_limit_text = "--Too many elemens in clipboard"
	if generated_code ~= nil then
		--writing in file for testing
		--local path_to_file = tda.GetProjectPath() .. "\\" .. "copy_paste.lua"
		--local export_file = io.open(path_to_file, "w")
		--	export_file:write(generated_code)
		--export_file:close()
		--dofile(path_to_file)
		--end of writing in file for testing
		if string.sub(generated_code, 1, string.len(tmp)) == tmp then
			loadstring(generated_code)()
		elseif string.sub(generated_code, 1, string.len(copy_limit_text)) == copy_limit_text then
			utilities.ShowInformationBarCommand("Too many elements copied!")
		end
	end
end

function copy_paste_diagram_seed(elem, is_container_needed)
	local list_of_code = {}
	local diagram = elem:find("/child")
	if diagram:is_not_empty() then
		table.insert(list_of_code, generated_clipboard_code(diagram, diagram, {}, false, false, is_container_needed))
		table.insert(list_of_code, copy_tree_node(diagram))
	end
	return table.concat(list_of_code)
end

function copy_diagram()

end

function get_sum_in_table(counter_table)
	local sum = 0
	for _, counter in ipairs(counter_table) do
		sum = sum + counter
	end
	return sum
end
