module(..., package.seeall)

function get_project_tree_dgr()
	pt_dgr = lQuery("PT#Diagram")
	if pt_dgr:is_empty() then
		pt_dgr = lQuery.create("PT#Diagram", {tab = lQuery.create("PT#DefaultTree", {caption = "Default", isVisible = true})})
	end
	return pt_dgr
end

function create_tab()
	return lQuery.create("PT#Tab", {caption = "tab test",
															  isVisible = true})
end

function get_root_diagrams()
	return lQuery("GraphDiagram:not(/source)")
end

function create_node(diagram)
	local node = lQuery.create("PT#Node", {caption = diagram:attr("caption"),
																			isExpanded = false,
																			  selected = false})
	
	local sub_diagrams = diagram:find("/element/target")
	
	if sub_diagrams:is_empty() then
		node:attr{expandable = false}
	else
		node:attr{expandable = true,
							     child = sub_diagrams:map(create_node)}
	end
	
	return node:log("caption")
end

function generate_tree_tab()
	local tree_diagram = get_project_tree_dgr()
	local tab = create_tab()
	tree_diagram:link("tab", tab)
	local root_diagrams = get_root_diagrams()
	
	tab:link("child", root_diagrams:map(create_node))
	
	
end
