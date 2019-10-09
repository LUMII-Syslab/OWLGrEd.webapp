module(..., package.seeall)
t = require("interpreter.tree")

function ActivateDgr(ev_in)
	local ev = utilities.get_event(ev_in, "ActivateDgrEvent")
	local activated_dgr = ev:find("/graphDiagram")
	local tree_node = utilities.get_tree_node_from_thing(activated_dgr)
	if tree_node:is_not_empty() then
		--t.select_node(tree_node)
	else
		--t.set_no_selected_node(true)
	end
	utilities.delete_event()
end


