module(..., package.seeall)
t = require("interpreter.tree")

function LClick(ev_in)
	local ev = utilities.get_event(ev_in, "Event")	
	local elem = ev:find("/element")
	local diagram
	if elem:is_not_empty() then
		find_diagram_and_tree_node(elem, utilities.get_diagram_from_element)
	else
		local compart = ev:find("/compartment")
		if compart:is_not_empty() then
			find_diagram_and_tree_node(compart, utilities.get_diagram_from_compartment)
		end
	end
	--	else
	--		diagram = utilities.current_diagram()
	--	end
	--end
	--utilities.open_diagram(diagram)
	utilities.delete_event()
end

function find_diagram_and_tree_node(obj, func_name)
	local diagram = func_name(obj)
	local tree_node = utilities.get_tree_node_from_thing(diagram)
	if tree_node:is_not_empty() then
		--t.select_node(tree_node)
	else
		--t.set_no_selected_node(true)
	end
end

