module(..., package.seeall)
require("core")
require("utilities")
require("lQuery")
cu = require("configurator.const.const_utilities")
require("config_properties")

local report = require("reporter.report")

function RClick(ev_in)
	local ev = utilities.get_event(ev_in, "RClickEvent")
	lQuery("PopUpDiagram"):delete()
	local pop_up_diagram_type = nil
	local diagram = utilities.current_diagram()
	local elem = ev:find("/element")
	local elem_type = elem:find("/elemType")

	-- Log "pop-up diagram show" event.
	report.event("PopUpDiagramShow", {
		diagram = function() return diagram:attr("caption") end,
		diagram_type = function() return diagram:attr("/graphDiagramType@id") end,
		collection_size = function() return utilities.active_elements():size() end,
		element_type = function() 
			local elements = utilities.active_elements()
			return elements:size() == 1 and elements:attr("/elemType@caption") or nil
		end,
	})

	if elem_type:is_not_empty() then
		local dynamic_popUp_function = elem_type:find("/translet[extensionPoint = 'procDynamicPopUp']"):attr_e("procedureName")
		if dynamic_popUp_function ~= "" and dynamic_popUp_function ~= nil then
			local pop_up_table = utilities.execute_fn(dynamic_popUp_function, elem)
			build_pop_up_from_table(pop_up_table)
		else
			pop_up_diagram_type = elem_type:find("/popUpDiagramType")
			make_pop_up_diagram_from_types(pop_up_diagram_type, diagram)
		end
	else
		local diagram_type = diagram:find("/graphDiagramType")
		local collection_elements = utilities.active_elements()
		if collection_elements:size() == 0 then
			local dynamic_pop_up = diagram_type:find("/translet[extensionPoint = 'procDynamicPopUpE']"):attr_e("procedureName")
			if dynamic_pop_up ~= "" then
				local pop_up_table = utilities.execute_fn(dynamic_pop_up)
				build_pop_up_from_table(pop_up_table)
			else
				pop_up_diagram_type = diagram_type:find("/rClickEmpty")
				make_pop_up_diagram_from_types(pop_up_diagram_type, diagram, true)
			end
		else
			local dynamic_pop_up = diagram_type:find("/translet[extensionPoint = 'procDynamicPopUpC']"):attr_e("procedureName")
			if dynamic_pop_up ~= "" and dynamic_pop_up ~= nil then
				local pop_up_table = utilities.execute_fn(dynamic_pop_up)
				build_pop_up_from_table(pop_up_table)
			else
				pop_up_diagram_type = diagram_type:find("/rClickCollection")
				make_pop_up_diagram_from_types(pop_up_diagram_type, diagram)
			end
		end
	end
	ev:delete()
end

function make_pop_up_diagram_from_types(pop_up_diagram_type, diagram)
	local popUpDiagram = make_pop_up_diagram(pop_up_diagram_type)
	--by SK: this is the second popup command, which is not needed: utilities.execute_cmd("PopUpCmd", {popUpDiagram = popUpDiagram, graphDiagram = diagram})	
end

function make_pop_up_diagram(pop_up_diagram_type)
	if pop_up_diagram_type ~= nil then
		local pop_up_table = {}
		pop_up_diagram_type:find("/popUpElementType"):each(function(pop_up_elem_type)
			if utilities.execute_should_be_included(pop_up_elem_type) then
				local row = {}
				row["Name"] = pop_up_elem_type:attr("caption")
				row["Procedure"] = pop_up_elem_type:attr("procedureName")
				table.insert(pop_up_table, row)
			end
		end)
		if utilities.current_diagram():find("/graphDiagramType[id = 'projectDiagram']"):is_not_empty() and not config_properties.get_config_value("is_configurator_hidden") then
			local row = {}
			row["Name"] = "Configurator"
			row["Procedure"] = "interpreter.RClick.show_specificationDgr"
			table.insert(pop_up_table, row)
		end
		build_pop_up_from_table(pop_up_table, {type = pop_up_diagram_type})
	end	
end

function build_pop_up_from_table(pop_up_table, pop_up_diagram_attr_list)
	if pop_up_table ~= nil and #pop_up_table > 0 then
		local new_pop_up_diagram = lQuery.create("PopUpDiagram", pop_up_diagram_attr_list)
		for i, row in ipairs(pop_up_table) do
			local name = row["Name"]
			local proc = row["Procedure"]
			local action_transformations = utilities.default_actions()
			if action_transformations[proc] ~= nil then
				proc = action_transformations[proc]
			end
			cu.add_PopUpElement(new_pop_up_diagram, name, proc, i)											
		end
		utilities.execute_cmd("PopUpCmd", {popUpDiagram = new_pop_up_diagram, graphDiagram = utilities.current_diagram()})	
		return new_pop_up_diagram
	end
end

function project_diagram_pop_up()
	build_pop_up_from_table({{Name = "Configurator", Procedure = "interpreter.RClick.show_specificationDgr"}})
end

function show_specificationDgr()
	local diagram = utilities.current_diagram():find("/graphDiagramType/presentation")
	utilities.execute_cmd("ActiveDgrCmd", {graphDiagram = diagram})
end



