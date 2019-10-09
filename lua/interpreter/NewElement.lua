module(..., package.seeall)
require("utilities")
require("core")
require("re")
d = require("dialog_utilities")
report = require("reporter.report")

function NewBox(ev_in)
	local ev = utilities.get_event(ev_in, "NewBoxEvent")	
	local diagram = utilities.current_diagram()
	if diagram:attr_e("isReadOnly") ~= "true" then
		local palette_box = ev:find("/paletteBox")
		local palette_box_id = palette_box:find("/type"):attr("id")
		if palette_box_id == "pattern" then
			core.make_pattern(palette_box, diagram)
		else
			local direct_palette_element = palette_box:find("/type")
			local node_type
			if direct_palette_element:is_not_empty() then
				node_type = direct_palette_element:find("/elemType")
			else
				node_type = palette_box:find("/elemType")
			end
			local parent_node = ev:find("/node")
			local node, error_msg = core.add_node_with_restrictions(node_type, parent_node, diagram)
			if node ~= -1 then
				report.event("NewBox", {
					diagram_id = diagram:id(),
					elem_type  = function() return node_type:attr("caption") end,
					parent_id  = function() return parent_node:id() end,
					element_id = function() return node:id() end
				})
			else
				report.event("NewBox", {
					Error = error_msg,
					diagram_id = diagram:id(),
					elem_type  = function() return node_type:attr("caption") end,
					parent_id  = function() return parent_node:id() end
				})
			end
		end
	end
	ev:delete()
end

function NewLine(ev_in)
	local ev = utilities.get_event(ev_in, "NewLineEvent")
	local diagram = utilities.current_diagram()
	local start_elem = ev:find("/start")
	local end_elem = ev:find("/end")
	local palette_line = ev:find("/paletteLine")
	if diagram:attr_e("isReadOnly") ~= "true" then
		local direct_palette_element = palette_line:find("/type")
		local edge_type_set
		if direct_palette_element:is_not_empty() then
			edge_type_set = direct_palette_element:find("/elemType")
		else
			edge_type_set = palette_line:find("/elemType")
		end
		local edge, error_msg = core.add_edge_with_end_elems(edge_type_set, start_elem, end_elem, diagram)

		-- Log "new-line" event.
		if edge ~= -1 then
			report.event("NewLine", {
				diagram_id = diagram:id(),
				elem_type  = function() return edge_type_set:attr("caption") end,
				start_id   = function() return start_elem:id() end,
				end_id     = function() return end_elem:id() end,
				element_id = function() return edge:id() end
			})
		else
			report.event("NewLine", {
				Error = error_msg,
				diagram_id = diagram:id(),
				elem_type  = function() return edge_type_set:attr("caption") end,
				start_id   = function() return start_elem:id() end,
				end_id     = function() return end_elem:id() end,
			})

		end
	end
	ev:delete()
end

function NewPin(ev_in)
	local ev = utilities.get_event(ev_in, "NewPinEvent")	
	local diagram = utilities.current_diagram()
	local palette_pin = ev:find("/palettePin")
	if diagram:attr_e("isReadOnly") ~= "true" then
		local direct_palette_element = palette_pin:find("/type")
		local port_type
		if direct_palette_element:is_not_empty() then
			port_type = direct_palette_element:find("/elemType")
		else
			port_type = palette_pin:find("/elemType")
		end
		local parent_node = ev:find("/node")
		local port = core.add_port(port_type, parent_node, diagram)

		-- Log "new-pin" event.
		report.event("NewPin", {
			diagram_id = diagram:id(),
			elem_type  = function() return port_type:attr("caption") end,
			parent_id  = function() return parent_node:id() end
		})
	end
	ev:delete()
end

function NewFreeBox(ev_in)
	local ev = utilities.get_event(ev_in, "NewFreeBoxEvent")	
	local diagram = utilities.current_diagram()
	local cooredinate_table = get_cooredinate_table(ev:attr("info"))
	local palette_free_box = ev:find("/paletteFreeBox")
	if diagram:attr_e("isReadOnly") ~= "true" then
		local direct_palette_element = palette_free_box:find("/type")
		if direct_palette_element:is_not_empty() then
			local node = core.add_free_node(direct_palette_element:find("/elemType"), diagram, cooredinate_table)
		else
			local node = core.add_free_node(palette_free_box:find("/elemType"), diagram, cooredinate_table)
		end
	end
	ev:delete()
end

function get_cooredinate_table(val)
	local grammer = re.compile[[grammer <-({[0-9-][0-9]*}';')*]]
	return re.match(val, lpeg.Ct(grammer))
end

function NewFreeLine(ev_in)
	local ev = utilities.get_event(ev_in, "NewFreeLineEvent")		
	local diagram = utilities.current_diagram()
	local cooredinate_table = get_free_line_cooredinate_table(ev:attr("info"))
	local palette_free_line = ev:find("/paletteFreeLine")
	if diagram:attr_e("isReadOnly") ~= "true" then
		local direct_palette_element = palette_free_line:find("/type")
		if direct_palette_element:is_not_empty() then
			local edge = core.add_free_edge(direct_palette_element:find("/elemType"), diagram, cooredinate_table)
		else
			local edge = core.add_free_edge(palette_free_line:find("/elemType"), diagram, cooredinate_table)
		end
	end
	ev:delete()
end

function get_free_line_cooredinate_table(val)
--hacks punkta vieta vajag back-slash
	local grammer = re.compile[[grammer <-([0-9-][0-9]*.({[0-9-][0-9]*}','{[0-9-][0-9]*}.)*)]]
	return re.match(val, lpeg.Ct(grammer))
end

function FreeBoxEdited()
	local ev = lQuery("FreeBoxEditedEvent")
	local coordinate_table = get_free_box_edited_cooredinate_table(ev:attr("info"))
	local free_box = ev:find("/element")
	core.set_free_box_coordinates(free_box, coordinate_table)
	utilities.execute_cmd("OkCmd", {graphDiagram = free_box:find("/graphDiagram")})
	d.delete_event(ev)
end

function get_free_box_edited_cooredinate_table(val)
--hacks punkta vieta vajag back-slash
	local grammer = re.compile[[grammer <-(({[0-9-][0-9]*}','{[0-9-][0-9]*}.)*)]]
	return re.match(val, lpeg.Ct(grammer))
end

function FreeLineEdited()
	local ev = lQuery("FreeLineEditedEvent")
	local coordinate_table = get_free_line_cooredinate_table(ev:attr("info"))
	local free_line = ev:find("/element")
	core.set_free_line_coordinates(free_line, coordinate_table)
	utilities.execute_cmd("OkCmd", {graphDiagram = free_line:find("/graphDiagram")})
	d.delete_event(ev)
end
