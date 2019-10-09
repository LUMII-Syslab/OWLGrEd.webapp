module(..., package.seeall)

require("lua_tda")
require "core"
require "set"


function aaa()
end

function merge_disjoint_into_fork()
	local fork = utilities.active_elements()
	disjoint_to_fork(fork)
end

function merge_disjoint_into_forks()
	local current_diagram = utilities.current_diagram()
	local forks = current_diagram:find("/element:has(/elemType[id='HorizontalFork'])")
	disjoint_to_fork(forks)
end

function disjoint_to_fork(forks)
	--forks = lQuery("Node:has(/elemType[id='HorizontalFork'])")
	--print(utilities.current_diagram():find("/element:has(/elemType[id='DisjointClasses'])"):size(), "DisjointClasses")
	
	forks_to_mark_disjoint = forks:filter(function(fork)
		return subclases_are_marked_disjoint_through_box(fork)
	end)
	
	--print(forks_to_mark_disjoint:size(), "forks_to_mark_disjoint")
	
	forks_to_mark_disjoint:each(function(fork)
		if fork:find("/compartment:has(/compartType[id='Disjoint'])"):is_empty() then
			lQuery.create("Compartment")
				:link("compartType", lQuery("ElemType[id='HorizontalFork']/compartType[id='Disjoint']"))
				:link("element", fork)
				:link("compartStyle", lQuery("ElemType[id='HorizontalFork']/compartType[id='Disjoint']/compartStyle"))
		end
		local disjointCompartment = fork:find("/compartment:has(/compartType[id='Disjoint'])")
		disjointCompartment:attr("value", true)
		local input = core.build_compartment_input_from_value("true", disjointCompartment:find("/compartType"), disjointCompartment)
		disjointCompartment:attr("input", input)
	end)

	utilities.refresh_element(forks_to_mark_disjoint, forks_to_mark_disjoint:find("/graphDiagram")) 
	local cmd = lQuery.create("OkCmd")
	cmd:link("graphDiagram", forks_to_mark_disjoint:find("/graphDiagram"))
	utilities.execute_cmd_obj(cmd)
end

function subclases_are_marked_disjoint_through_box(fork)
	local result = false
	local class_node = fork:find("/eStart:has(/elemType[id='AssocToFork'])/end"):unique()
	class_node = class_node:add(fork:find("/eEnd:has(/elemType[id='AssocToFork'])/start"):unique())
	local disjoint_box = class_node:find("/eEnd:has(/elemType[caption='Connector'])/start:has(/elemType[id='DisjointClasses'])")
	disjoint_box = disjoint_box:add(class_node:find("/eStart:has(/elemType[caption='Connector'])/end:has(/elemType[id='DisjointClasses'])"))
	disjoint_box:each(function(disjoint)
		local disjoint_class_nodes = disjoint:find("/eStart:has(/elemType[caption='Connector'])/end"):unique()
		disjoint_class_nodes = disjoint_class_nodes:add(disjoint:find("/eEnd:has(/elemType[caption='Connector'])/start"):unique())
		if set.equal(set.new(class_node:map(function(o) return o:id() end)), set.new(disjoint_class_nodes:map(function(o) return o:id()  end))) == true then
			result = true
			disjoint:delete()
		end
	end)
	return result
end

function split_fork_disjoint()
	local current_diagram = utilities.current_diagram()
	--local disjointClasses = lQuery(current_diagram):find("/collection/element:has(/elemType[id='DisjointClasses'])")
	local disjointClasses = utilities.active_elements()
	--katrai iezimetai kastei
	disjointClasses:each(function(disjointClass)
		local result = false
		--atrast visus forkus, kas ar to ir saistiti caur klasi
		local forks = disjointClass:find("/eStart:has(/elemType[caption='Connector'])/end:has(/elemType[id='Class'])/eStart:has(/elemType[id='AssocToFork'])/end"):unique()
		forks = forks:add(disjointClass:find("/eEnd:has(/elemType[caption='Connector'])/start:has(/elemType[id='Class'])/eStart:has(/elemType[id='AssocToFork'])/end"):unique())
		forks = forks:add(disjointClass:find("/eEnd:has(/elemType[caption='Connector'])/start:has(/elemType[id='Class'])/eEnd:has(/elemType[id='AssocToFork'])/start"):unique())
		forks = forks:add(disjointClass:find("/eStart:has(/elemType[caption='Connector'])/end:has(/elemType[id='Class'])/eEnd:has(/elemType[id='AssocToFork'])/start"):unique())
		--atrast visas klases, kas  ir saistiti ar disjointClasses kasti
		local disjoint_clases = disjointClass:find("/eStart:has(/elemType[caption='Connector'])/end:has(/elemType[id='Class'])"):unique()
		disjoint_clases = disjoint_clases:add(disjointClass:find("/eEnd:has(/elemType[caption='Connector'])/start:has(/elemType[id='Class'])"):unique())
		
		forks:each(function(fork)
			local fork_classes = fork:find("/eStart:has(/elemType[id='AssocToFork'])/end"):unique()
			fork_classes = fork_classes:add(fork:find("/eEnd:has(/elemType[id='AssocToFork'])/start"):unique())
			
			-- if set.subset(set.new(disjoint_clases:map(function(o) return o:id() end)), set.new(fork_classes:map(function(o) return o:id()  end))) == true then
				-- result = true
			-- end
			
			local a = set.intersection(set.new(disjoint_clases:map(function(o) return o:id() end)), set.new(fork_classes:map(function(o) return o:id()  end)))
			if set.equal(a, set.new(disjoint_clases:map(function(o) return o:id() end))) == true then 
				result = true
			end
			
			if result == true then
				--izveidot forku ar disjoint
				local horizontal_fork = lQuery("NodeType[id='HorizontalFork']")
				local hor_fork = core.add_node(horizontal_fork, current_diagram)
				--disjoint
				local disjoint_comp = core.add_compartment(horizontal_fork:find("/compartType[id='Disjoint']"), hor_fork, true)
				local input = core.build_compartment_input_from_value("true", horizontal_fork:find("/compartType[id='Disjoint']"), disjoint_comp)
				disjoint_comp:attr("input", input)
				
				disjoint_clases:find("/eStart:has(/elemType[id='AssocToFork'])"):filter(function(assocToFork)
					return assocToFork:find("/end"):id() == fork:id()
				end):delete()
				disjoint_clases:find("/eEnd:has(/elemType[id='AssocToFork'])"):filter(function(assocToFork)
					return assocToFork:find("/start"):id() == fork:id()
				end):delete()
				
				
				-- disjoint_clases:find("/eStart:has(/elemType[id='AssocToFork'])"):delete()
				-- disjoint_clases:find("/eEnd:has(/elemType[id='AssocToFork'])"):delete()
				
				disjoint_clases:each(function(class)
					core.add_edge(lQuery("EdgeType[id='AssocToFork']"), hor_fork, class, current_diagram)
				end)
				
				local superClasses = fork:find("/eEnd:has(/elemType[id='GeneralizationToFork'])/start"):unique()
				superClasses = superClasses:add(fork:find("/eStart:has(/elemType[id='GeneralizationToFork'])/end"):unique())
				
				superClasses:each(function(class)
					core.add_edge(lQuery("EdgeType[id='GeneralizationToFork']"), hor_fork, class, current_diagram)
				end)
				if set.equal(set.new(disjoint_clases:map(function(o) return o:id() end)), set.new(fork_classes:map(function(o) return o:id()  end))) == true then
					fork:delete()
				end
				disjointClass:delete()
			end
		end)
	end)
	utilities.execute_cmd("OkCmd", {graphDiagram = current_diagram})	
end


function add_keyboard_shortcut_to_disjoint_clases()
	lQuery.create("KeyboardShortcut", {key="Ctrl E", procedureName="disjoint_to_fork.split_fork_disjoint"}):link("elemType", lQuery("ElemType[id='DisjointClasses']"))
end


