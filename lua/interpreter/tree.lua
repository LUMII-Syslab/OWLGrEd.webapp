module(..., package.seeall)
report = require("reporter.report")
---Koka dzinēja API funkcijas

---Izveido formu
-- @param attr_table tabula, kas satur klases D#Form atribūtu vērtības
-- @return formas objekts
function DoubleClick(ev_in)
	local ev = utilities.get_event(ev_in, "PT#Event")
	local tree_node = ev:find("/node")
	local diagram = tree_node:find("/thing")
	report.event("Tree Node Double Click", {
		DiagramName = diagram:attr("caption"),
		diagram_id = diagram:id()
	})
	utilities.open_diagram(diagram)
	ev:delete()
end

function RightClick(ev_in)
	local ev = utilities.get_event(ev_in, "PT#Event")	
	local node = ev:find("/node")
	--set_selected_node(node)
	report.event("Tree Node Right Click", {
		Node = node:attr("caption")
	})
	--local pop_up_diagram = utilities.create_pop_up_diagram()
	--utilities.add_pop_up_element(pop_up_diagram, {caption = "Test", procedureName = "utilities.test"})
	--utilities.execute_cmd("PT#PopUpCmd", {popUpDiagram = pop_up_diagram, node = node})
	
	--utilities.do_nothing()
	ev:delete()
end

function Select(ev_in)
	local ev = utilities.get_event(ev_in, "PT#Event")	
	local node = ev:find("/node")
	set_selected_node(node)
	--utilities.do_nothing()
	report.event("Tree Node Select", {
		Node = node:attr("caption")
	})
	ev:delete()
end

function Expand(ev_in)
	local ev = utilities.get_event(ev_in, "PT#Event")	
	local tree_node = ev:find("/node")
	utilities.execute_cmd("PT#ExpandCmd", {node = tree_node})
	report.event("Tree Node Expand", {
		Node = tree_node:attr("caption")
	})
	ev:delete()
end

function Colapse(ev_in)
	local ev = utilities.get_event(ev_in, "PT#Event")	
	local tree_node = ev:find("/node")
	utilities.execute_cmd("PT#ColapseCmd", {node = tree_node})
	report.event("Tree Node Colapse", {
		Node = tree_node:attr("caption")
	})
	ev:delete()
end

function KeyDown(ev_in)
	local ev = utilities.get_event(ev_in, "PT#Event")	
	utilities.do_nothing()
	ev:delete()
end

---Pārzīmē koka komponenti
-- @param obj koka komponentes objekts, kuru pārzīmē
function refresh(node)
	--local obj = lQuery.create("PT#RefreshCmd", {nodeParent = node})
	--utilities.execute_cmd_obj(obj)
	--log("refresh node")
	utilities.execute_cmd("PT#RefreshCmd", {nodeParent = node})
end

---Izveido jaunu koka virsotni
-- @param parent objekts, pie kura piesaista koka jauno koka virsotni
-- @param attr_list saraksts ar koka virsotnes atribūtu nosaukumiem un to vērtībām
-- @param is_selected norāda, vai jauno koka virsotni vajag aktivizēt
-- @return koka virsotnes objekts
function add_tree_node(parent, attr_list, is_selected)
	if parent:is_empty() then
		parent = get_tab()	
	end
	local node = lQuery.create("PT#Node", attr_list):link("parent", parent)
	if is_selected then
		--select_node(node)
	end
	return node
end

---Izdzēš koka virsotni
-- @param node koka virsotne
function delete_tree_node(node)
	local parent = node:find("/parent")
	node:delete()
	refresh(parent)
end

---Aktivizē koka virsotni
-- @param node koka virsotne
function select_node(node)
	if set_selected_node(node) then
		utilities.execute_cmd("PT#SelectCmd", {node = node})
		--log("select node")
	end
end

---Sameklē iezīmēto koka virsotni
function get_selected_tree_node()
	local parent = lQuery("PT#Node[selected = 'true']")
	if parent:is_not_empty() then
		return parent
	end
	parent = lQuery("PT#Tab:first()")
	if parent:is_not_empty() then
		return parent
	end
	parent = get_tab()
	return parent
end

---Sameklē cilni pēc tā nosaukuma
-- @param name nosaukums
function get_tab(name)
	local tab
	if name == nil then
		tab = utilities.current_diagram():find("/nodeParent")   --lQuery("PT#Tab[caption = '" .. utilities.get_project_name() .. "']:first()"
	else
		tab = lQuery("PT#Tab[caption = '" .. name .. "']")
	end
	if tab:is_empty() then
		tab = add_tab(name)
	end
	return tab
end

function add_tab(name)
	if name == "" then
		name = utilities.get_project_name()
	end
	diagram = lQuery("PT#Diagram")
	if diagram:is_empty() then
		diagram = add_diagram()
	end
	local tab = lQuery.create("PT#Tab", {caption = name, isVisible = "true", diagram = diagram})
	refresh(tab)
	return tab
end

function add_diagram(name)
	name = name or utilities.get_project_name()
	return lQuery.create("PT#Diagram", {caption = name})
end

function set_selected_node(node)
	if node:attr("selected") == "true" then
		return false
	else
		set_no_selected_node()
		node:attr({selected = 'true'})
		return true
	end
end

function set_no_selected_node(is_refresh_needed)
	lQuery("PT#Node[selected = 'true']"):each(function(tmp_node)
		tmp_node:attr({selected = "false"})
	end)
	if is_refresh_needed then
		local tab = lQuery("PT#Tab:first()")
		refresh(tab)
	end
end
