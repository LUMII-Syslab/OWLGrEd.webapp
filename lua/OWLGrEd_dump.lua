module(..., package.seeall)

json = require "reporter.dkjson"
require("graph_diagram_style_utils")

require("chroma")


function add_translets(obj_type, list)
	obj_type:find("/translet"):each(function(translet)
		local translet_id = translet:id()
		list[translet_id] = utilities.get_lQuery_object_attribute_list(translet)[1]
	end)
end

function add_choice_item(compart_type, list)
	compart_type:find("/choiceItem"):each(function(choice_item)
		choice_item:log("value")
		local notation_value = choice_item:find("/notation"):attr("value")
		list[choice_item:id()] = {value = choice_item:attr("value"), notation = notation_value}
	end)
end

function sub_compart_type_tree_to_table(compart_type, list)
	list["subCompartments"] = {}
	compart_type:find("/subCompartType"):each(function(sub_compart_type)

		local sub_compart_list = {}
		local sub_compart_type_id = sub_compart_type:id()
		sub_compart_list[sub_compart_type_id] = {}
		local sub_compart_list_id = sub_compart_list[sub_compart_type_id]

		sub_compart_list_id["attributes"] = utilities.get_lQuery_object_attribute_list(sub_compart_type)[1]
		sub_compart_list_id["translets"] = {}
		
		add_translets(sub_compart_type, sub_compart_list_id["translets"])

		sub_compart_list_id["choiceItems"] = {}
		local choice_item_list = sub_compart_list_id["choiceItems"]
		add_choice_item(sub_compart_type, choice_item_list)

		sub_compart_list_id["styles"] = {}

		sub_compart_type:find("/compartStyle"):each(function(compart_style)
			local compart_style_id = compart_style:id()
			sub_compart_list_id["styles"][compart_style_id] = utilities.get_lQuery_object_attribute_list(compart_style)[1]
		end)

		sub_compart_type_tree_to_table(sub_compart_type, sub_compart_list_id)


		table.insert(list["subCompartments"], sub_compart_list)
	end)
end

function diagram_type_tree_to_json(diagram_types)

	local res = {}
	diagram_types:each(function(diagram_type)

		local diagram_type_attrs = utilities.get_lQuery_object_attribute_list(diagram_type)[1]
		local diagram_type_id = diagram_type:id()
		res[diagram_type_id] = {}
		res[diagram_type_id]["attributes"] = diagram_type_attrs

		local diagram_style = diagram_type:find("/graphDiagramStyle")
		res[diagram_type_id]["style"] = utilities.get_lQuery_object_attribute_list(diagram_style)[1]

		res[diagram_type_id]["elements"] = {}

		diagram_type:find("/elemType"):each(function(elem_type)
			local elem_attrs = utilities.get_lQuery_object_attribute_list(elem_type)[1]
			local elem_type_id = elem_type:id()
			res[diagram_type_id]["elements"][elem_type_id] = {}

			local res_element_list = res[diagram_type_id]["elements"][elem_type_id]

			res_element_list["className"] = utilities.get_class_name(elem_type)
			res_element_list["attributes"] = elem_attrs
			res_element_list["styles"] = {}

			elem_type:find("/elemStyle"):each(function(elem_style)
				local elem_style_id = elem_style:id()
				res_element_list["styles"][elem_style_id] = utilities.get_lQuery_object_attribute_list(elem_style)[1]
			end)

			res[diagram_type_id]["elements"][elem_type_id]["translets"] = {}
			add_translets(elem_type, res_element_list["translets"])		

			res_element_list["compartments"] = {}
			elem_type:find("/compartType"):each(function(compart_type)

				local compart_list = {}
				local compart_type_id = compart_type:id()

				compart_list[compart_type_id] = {}
				local res_comparment_list = compart_list[compart_type_id]

				res_comparment_list["attributes"] = utilities.get_lQuery_object_attribute_list(compart_type)[1]
				res_comparment_list["styles"] = {}

				compart_type:find("/compartStyle"):each(function(compart_style)
					local compart_style_id = compart_style:id()
					res_comparment_list["styles"][compart_style_id] = utilities.get_lQuery_object_attribute_list(compart_style)[1]
				end)

				res_comparment_list["translets"] = {}
				add_translets(compart_type, res_comparment_list["translets"])

				res_comparment_list["choiceItems"] = {}
				local choice_item_list = res_comparment_list["choiceItems"]
				add_choice_item(compart_type, choice_item_list)

				sub_compart_type_tree_to_table(compart_type, res_comparment_list)


				table.insert(res_element_list["compartments"], compart_list)
			end)
		end)
	end)
		
	--print(dumptable(res))
	json_str = json.encode(res)
	--print(json_str)


	--writing in file for testing
	local path_to_file = tda.GetProjectPath() .. "\\" .. "OWLGrEd_dump.json"
	local export_file = io.open(path_to_file, "w")
		export_file:write(json_str)
	export_file:close()
	--end of writing in file for testing

end

local diagram = utilities.current_diagram()
local diagram_type = diagram:find("/graphDiagramType"):log("id")

diagram_type_tree_to_json(diagram_type)