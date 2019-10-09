module(..., package.seeall)

local MP = require("ManchesterParser")

function setContainerNameVisible(compartment,oldValue)
	local containerName= compartment:find("/element/compartment:has(/compartType[id='Name'])")
	if compartment:attr("value") == "true" then
		containerName:link("compartStyle",containerName:find("/compartType/compartStyle[id='NameInvisible']"))
	else
		containerName:link("compartStyle",containerName:find("/compartType/compartStyle[id='Name']"))
	end
end

function setUniqueContainerName(form)
	local name = form:find("/presentationElement/compartment:has(/compartType[id='Name'])")
	if name:attr("value") == nil or name:attr("value") == "" then
		local containerName = "Container_"
		local count = 1
		while lQuery("ElemType[id='Container']/element/compartment:has(/compartType[id='Name'])[value='" .. containerName .. count .. "']"):is_not_empty() do
			count = count + 1
		end
		name:attr("value", containerName .. count)
		name:attr("input", containerName .. count)
		utilities.refresh_element(form:find("/presentationElement"), utilities.current_diagram())
	end
end

function setPrefixesPlus(dataCompartType, dataCompartment, parsingCompartment)
	--izsaukt OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView(dataCompartType, dataCompartment, parsingCompartment)
	local result = ""
	if dataCompartment~=nil then
		local allValuesFrom = dataCompartment:find("/parentCompartment/subCompartment:has(/compartType[id='allValuesFrom'])")
		local noSchema = dataCompartment:find("/parentCompartment/subCompartment:has(/compartType[id='noSchema'])")
		if allValuesFrom:attr("value")=="true" then result = "+" end
		if noSchema:attr("value") == "true" then result = "!" end
	end
	return result
end

function setPrefixesPlusAttribute(dataCompartType, dataCompartment, parsingCompartment)
	--izsaukt OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView(dataCompartType, dataCompartment, parsingCompartment)
	local result = ""
	if dataCompartment~=nil then
		local allValuesFrom = dataCompartment:find("/element/compartment:has(/compartType[id='allValuesFrom'])")
		local noSchema = dataCompartment:find("/element/compartment:has(/compartType[id='noSchema'])")
		if allValuesFrom:attr("value")=="true" then result = "+" end
		if noSchema:attr("value") == "true" then result = "!" end
	end
	return result
end


function setPrefixesNoSchema(compartment, oldValue)
	local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "noSchema"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/parentCompartment")
		local allValuesFrom = parentCompartment:find("/subCompartment:has(/compartType[id='allValuesFrom'])")
		allValuesFrom:attr("value", "false")
		core.update_compartment_input_from_value(allValuesFrom)
		
		allValuesFrom:find("/component"):attr("checked", "false")
		if allValuesFrom:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			allValuesFrom:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		name:attr("input", "!" .. name:attr("value"))
	else
		name:attr("input", name:attr("value"))
	end
	utilities.refresh_element(name, utilities.current_diagram())
end

function setPrefixesNoSchemaAttribute(compartment, oldValue)
	local name = compartment:find("/element/compartment:has(/compartType[id='Name'])")
	
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "noSchema"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/element")
		local allValuesFrom = parentCompartment:find("/compartment:has(/compartType[id='allValuesFrom'])")
		allValuesFrom:attr("value", "false")
		core.update_compartment_input_from_value(allValuesFrom)
		
		allValuesFrom:find("/component"):attr("checked", "false")
		if allValuesFrom:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			allValuesFrom:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		name:attr("input", "!" .. name:attr("value"))
	else
		name:attr("input", name:attr("value"))
	end
	utilities.refresh_element(name, utilities.current_diagram())
end

function deleteCheckBoxCompartment(compartType, parentCompartment)
	local isFunc = parentCompartment:find("/subCompartment:has(/compartType[id='"..compartType.."'])")
	if isFunc:attr("value") == "true" then
		isFunc:attr("value", "false")
		core.update_compartment_input_from_value(isFunc)
		isFunc:find("/component"):attr("checked", "false")
		local cmd = utilities.create_command("D#Command", {info = "Refresh"})
		isFunc:link("command", cmd)
		utilities.execute_cmd_obj(cmd)
	end
end

function setPrefixesPlusFromAllFaluesFrom(compartment, oldValue)
	local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "allValuesFrom"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/parentCompartment")
		local noSchema = parentCompartment:find("/subCompartment:has(/compartType[id='noSchema'])")
		noSchema:attr("value", "false")
		core.update_compartment_input_from_value(noSchema)
		
		noSchema:find("/component"):attr("checked", "false")
		if noSchema:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			noSchema:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		name:attr("input", "+" .. name:attr("value"))
		-- parentCompartment:find("/subCompartment"):each(function(obj)
			-- print(obj:find("/compartType"):attr("id"), obj:attr("value"))
		-- end)
		
		
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Functional'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='InverseFunctional'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Symmetric'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Asymmetric'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Reflexive'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Irreflexive'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Transitive'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='PropertyChains'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])/subCompartment/component"), false)
		
		
		if parentCompartment:find("/subCompartment:has(/compartType[id='Functional'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='InverseFunctional'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Symmetric'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Asymmetric'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Reflexive'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Irreflexive'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Transitive'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousPropertyChains'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then
			deleteCompartmentsForm("- Functional\n- InverseFunctional\n- Symmetric\n- Asymmetric\n- Irreflexive\n- Reflexive\n- Transitive\n- EquivalentProperties\n- DisjointProperties\n- SuperProperties\n- PropertyChains")
			
			deleteCheckBoxCompartment('Functional', parentCompartment)
			deleteCheckBoxCompartment('InverseFunctional', parentCompartment)
			deleteCheckBoxCompartment('Symmetric', parentCompartment)
			deleteCheckBoxCompartment('Asymmetric', parentCompartment)
			deleteCheckBoxCompartment('Irreflexive', parentCompartment)
			deleteCheckBoxCompartment('Reflexive', parentCompartment)
			deleteCheckBoxCompartment('Transitive', parentCompartment)
			
			if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"))
				parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"))
				parentCompartment:find("/form/component[id='EquivalentProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"))
				parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"))
				parentCompartment:find("/form/component[id='DisjointProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"))
				parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"))
				parentCompartment:find("/form/component[id='SuperProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousPropertyChains'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousPropertyChains'])/subCompartment"))
				parentCompartment:find("/subCompartment:has(/compartType[id='PropertyChains'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='PropertyChains'])"))
				parentCompartment:find("/form/component[id='PropertyChains']/component[id='field']"):attr("text", "")
			end
		end
		
	else
		name:attr("input", name:attr("value"))
		
		local parentCompartment = compartment:find("/parentCompartment")
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Functional'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='InverseFunctional'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Symmetric'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Asymmetric'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Reflexive'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Irreflexive'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Transitive'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='PropertyChains'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])/subCompartment/component"), true)
	end
	utilities.refresh_element(name, utilities.current_diagram())
end

function setPrefixesPlusFromAllFaluesFromAttribute(compartment, oldValue)
	local name = compartment:find("/element/compartment:has(/compartType[id='Name'])")
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "allValuesFrom"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/element")
		local noSchema = parentCompartment:find("/compartment:has(/compartType[id='noSchema'])")
		noSchema:attr("value", "false")
		core.update_compartment_input_from_value(noSchema)
		
		noSchema:find("/component"):attr("checked", "false")
		if noSchema:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			noSchema:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		name:attr("input", "+" .. name:attr("value"))

		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='IsFunctional'])/component"), false)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='SuperProperties'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='DisjointProperties'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='EquivalentProperties'])/subCompartment/component"), false)
		
		
		if parentCompartment:find("/compartment:has(/compartType[id='IsFunctional'])"):attr("value") == "true" or
		parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then
			deleteCompartmentsForm("- IsFunctional\n- EquivalentProperties\n- DisjointProperties\n- SuperProperties\n- PropertyChains")
			
			deleteCheckBoxCompartment('IsFunctional', parentCompartment)
			
			if parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"))
				parentCompartment:find("/compartment:has(/compartType[id='EquivalentProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/compartment:has(/compartType[id='EquivalentProperties'])"))
				parentCompartment:find("/form/component[id='EquivalentProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"))
				parentCompartment:find("/compartment:has(/compartType[id='DisjointProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/compartment:has(/compartType[id='DisjointProperties'])"))
				parentCompartment:find("/form/component[id='DisjointProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"))
				parentCompartment:find("/compartment:has(/compartType[id='SuperProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/compartment:has(/compartType[id='SuperProperties'])"))
				parentCompartment:find("/form/component[id='SuperProperties']/component[id='field']"):attr("text", "")
			end
		end
		
	else
		name:attr("input", name:attr("value"))
		
		local parentCompartment = compartment:find("/element")
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='IsFunctional'])/component"), true)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='SuperProperties'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='DisjointProperties'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='EquivalentProperties'])/subCompartment/component"), true)
	end
	utilities.refresh_element(name, utilities.current_diagram())
end

function disableEnableProperty(obj, value)
	obj:attr("enabled", value)
	local cmd = utilities.create_command("D#Command", {info = "Refresh"})
	obj:link("command", cmd)
	utilities.execute_cmd_obj(cmd)
	obj:find("/container/component"):each(function(com)
		com:attr("enabled", value)
		local cmd = utilities.create_command("D#Command", {info = "Refresh"})
		com:link("command", cmd)
		utilities.execute_cmd_obj(cmd)
	end)
end

function setPrefixesNoSchemaDataProperty(compartment, oldValue)

	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "noSchema"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/parentCompartment")
		local allValuesFrom = parentCompartment:find("/subCompartment:has(/compartType[id='allValuesFrom'])")
		allValuesFrom:attr("value", "false")
		core.update_compartment_input_from_value(allValuesFrom)
		
		allValuesFrom:find("/component"):attr("checked", "false")
		if allValuesFrom:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			allValuesFrom:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
	else
		-- name:attr("input", name:attr("value"))
	end
	-- utilities.refresh_element(name, utilities.current_diagram())
end

function setPrefixesPlusFromAllFaluesFromDataProperty(compartment, oldValue)
	-- local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "allValuesFrom"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/parentCompartment")
		local noSchema = parentCompartment:find("/subCompartment:has(/compartType[id='noSchema'])")
		noSchema:attr("value", "false")
		core.update_compartment_input_from_value(noSchema)
		
		noSchema:find("/component"):attr("checked", "false")
		if noSchema:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			noSchema:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		
		
		parentCompartment:find("/form/component"):each(function(com)
			if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties(<)" or com:attr("id") == "DisjointProperties(<>)" then
				com:attr("enabled", false)
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				com:link("command", cmd)
				utilities.execute_cmd_obj(cmd)
				com:find("/component"):each(function(obj)
					obj:attr("enabled", false)
					local cmd = utilities.create_command("D#Command", {info = "Refresh"})
					obj:link("command", cmd)
					utilities.execute_cmd_obj(cmd)
					obj:find("/component"):each(function(obj2)
						obj2:attr("enabled", false)
						local cmd = utilities.create_command("D#Command", {info = "Refresh"})
						obj2:link("command", cmd)
						utilities.execute_cmd_obj(cmd)
					end)
				end)
			end
			
		end)
		
		if parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then
			deleteCompartmentsForm("- IsFunctional\n- EquivalentProperties\n- DisjointProperties\n- SuperProperties")
		end
		
		
		if parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):size() > 0 and  parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):attr("value") == "true" then
			local isFunc = parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):attr("value", "false")
			core.update_compartment_input_from_value(isFunc)
			isFunc:find("/component"):attr("checked", "false")
		end
		if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 then   
			deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"))
			parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"):attr("value", "")
			core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"))
			parentCompartment:find("/form/component[id='EquivalentProperties']/component[id='field']"):attr("text", "")
		end
		if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 then   
		    deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"))
			parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"):attr("value", "")
			core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"))
			parentCompartment:find("/form/component[id='DisjointProperties']/component[id='field']"):attr("text", "")
		end
		if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then   
		    deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"))
			parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"):attr("value", "")
			core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"))
			parentCompartment:find("/form/component[id='SuperProperties']/component[id='field']"):attr("text", "")
		end
		
		-- name:attr("input", "+" .. name:attr("value"))
	else
		-- name:attr("input", name:attr("value"))
		local parentCompartment = compartment:find("/parentCompartment")
		parentCompartment:find("/form/component"):each(function(com)
			if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties(<)" or com:attr("id") == "DisjointProperties(<>)" then
				com:attr("enabled", true)
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				com:link("command", cmd)
				utilities.execute_cmd_obj(cmd)
				
				com:find("/component"):each(function(obj)
					obj:attr("enabled", true)
					local cmd = utilities.create_command("D#Command", {info = "Refresh"})
					obj:link("command", cmd)
					utilities.execute_cmd_obj(cmd)
					
					obj:find("/component"):each(function(obj2)
						obj2:attr("enabled", true)
						local cmd = utilities.create_command("D#Command", {info = "Refresh"})
						obj2:link("command", cmd)
						utilities.execute_cmd_obj(cmd)
					end)
				end)
			end
		end)
	end

	-- utilities.refresh_element(name, utilities.current_diagram())
end

function onAttributeOpen(form)
	local attribute = form:find("/presentationElement")
	local allValuesFrom = attribute:find("/subCompartment:has(/compartType[id='allValuesFrom'])")

	if allValuesFrom:size() > 0 and allValuesFrom:attr("value") == "true" then
		form:find("/component"):each(function(com)
			if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties(<)" or com:attr("id") == "DisjointProperties(<>)" then
				com:attr("enabled", false)

				com:find("/component"):each(function(obj)
					obj:attr("enabled", false)

					obj:find("/component"):each(function(obj2)
						obj2:attr("enabled", false)
					end)
				end)
			end
		end)
	end
end

function disablePropertiesOnOpen(form)
	if form:find("/component[id='TabContainer']/component[caption='Direct']/component/component/component/compartment:has(/compartType[id='allValuesFrom'])"):attr("value") == "true" then
		form:find("/component[id='TabContainer']/component[caption='Direct']/component"):each(function(com)
			local compartType = com:attr("id")
			if compartType == "EquivalentProperties(=)" or compartType == "SuperProperties(<)" or compartType == "DisjointProperties(<>)" or compartType == "PropertyChains" then 
				com:attr("enabled", false)
				com:find("/component/component"):each(function(obj)
					obj:attr("enabled", false)
				end)
			end
			com:find("/component/component"):each(function(obj)
				local compartType = obj:find("/compartment/compartType"):attr("id")
				if compartType == "Transitive" or compartType == "Irreflexive" or compartType == "Reflexive" or compartType == "Asymmetric" or compartType == "Symmetric" or compartType == "InverseFunctional" or compartType == "Functional" then
					obj:attr("enabled", false)
				end
			end)
		end)
	end
	if form:find("/component[id='TabContainer']/component[caption='Inverse']/component/component/component/compartment:has(/compartType[id='allValuesFrom'])"):attr("value") == "true" then
		form:find("/component[id='TabContainer']/component[caption='Inverse']/component"):each(function(com)
			local compartType = com:attr("id")
			if compartType == "EquivalentProperties(=)" or compartType == "SuperProperties(<)" or compartType == "DisjointProperties(<>)" or compartType == "PropertyChains" then 
				com:attr("enabled", false)
				com:find("/component/component"):each(function(obj)
					obj:attr("enabled", false)
				end)
			end
			com:find("/component/component"):each(function(obj)
				local compartType = obj:find("/compartment/compartType"):attr("id")
				if compartType == "Transitive" or compartType == "Irreflexive" or compartType == "Reflexive" or compartType == "Asymmetric" or compartType == "Symmetric" or compartType == "InverseFunctional" or compartType == "Functional" then
					obj:attr("enabled", false)
				end
			end)
		end)
	end
end


function onAttributeLinkOpen(form)
	local attribute = form:find("/presentationElement")
	local allValuesFrom = attribute:find("/compartment:has(/compartType[id='allValuesFrom'])")

	if allValuesFrom:size() > 0 and allValuesFrom:attr("value") == "true" then
		form:find("/component"):each(function(com)
			if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties" or com:attr("id") == "DisjointProperties" then
				com:attr("enabled", false)

				com:find("/component"):each(function(obj)
					obj:attr("enabled", false)

					obj:find("/component"):each(function(obj2)
						obj2:attr("enabled", false)
					end)
				end)
			end
		end)
	end
end

function deleteCompartment(compartment)
  local parent_compartment = compartment:find("/parentCompartment")
  
  deleteSubCompartments(compartment)
  
  if not parent_compartment:is_empty() then
    core.update_compartment_value_from_subcompartments(parent_compartment)
  end
end

function deleteSubCompartments(compartment)
	compartment:find("/subCompartment"):each(function(com)
		deleteSubCompartments(com)
	end)
	compartment:delete()
end

function deleteCompartmentsForm(text)
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Schema.schema.closeDeleteCompartment()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "deteleCompartments"
    ,caption = "Warning"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Schema.schema.closeDeleteCompartment()")
    ,minimumWidth = 300
    ,maximumWidth = 300
    ,prefferedWidth = 300
	,component = {
		lQuery.create("D#VerticalBox",{
			id = "HorizontalAllForms"
			
			,component = {
				lQuery.create("D#VerticalBox", {
					horizontalAlignment = -1
					,component = {
						lQuery.create("D#Label", {caption = "The following properties will be deleted:"})
						,lQuery.create("D#Label", {caption = text})
					}
				})
			}})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
end

function exportParametersForm()

	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Schema.schema.close()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "ontology_export_preferences"
    ,caption = "Ontology export options"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Schema.schema.close()")
    ,minimumWidth = 410
	,component = {
		lQuery.create("D#HorizontalBox",{
			id = "HorizontalAllForms"
			,component = {
				lQuery.create("D#VerticalBox", {
					component = {
						lQuery.create("D#GroupBox",{
							caption = "Schema export type"
							,component = {
								lQuery.create("D#VerticalBox",{
									id = "VerticalBox"
									,component = {
										lQuery.create("D#Row", {
											horizontalAlignment = -1
											,topMargin = 5
											,component = {
											lQuery.create("D#VerticalBox", {
												horizontalAlignment = -1
												,id = "schemaExtension"
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Weak schema closure"
														-- ,enabled = false
														-- ,leftMargin = 30
														,id = "schemaExtension"
														,selected = selectRadioButtonValue("schemaExtension", "Weak schema closure")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Schema.schema.saveRadioButtonParameter()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Strict schema closure"
														-- ,leftMargin = 30
														,id = "schemaExtension"
														,selected = selectRadioButtonValue("schemaExtension", "Strict schema closure")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Schema.schema.saveRadioButtonParameter()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Standard (non-shema) ontology only"
														-- ,leftMargin = 30
														,id = "schemaExtension"
														,selected = selectRadioButtonValue("schemaExtension", "Standard (non-shema) ontology only")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Schema.schema.saveRadioButtonParameter()")
													})
												}
											})}
										})
										,lQuery.create("D#Row", {
											horizontalAlignment = -1
											,topMargin = 10
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Include schema assertions in annotation form"
													,id = "includeSchemaAssertionsInAnnotationForm"
													,checked = lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue")
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()")
												})
												
											}
										})
									}
								})
							}
						})
						,lQuery.create("D#GroupBox",{
							caption = "Schema closure extensions"
							,topMargin = 10
							,component = {
								lQuery.create("D#VerticalBox",{
									id = "VerticalBox"
									,component = {
										lQuery.create("D#Row", {
											horizontalAlignment = -1
											,topMargin = 5
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Explicit sub-properties"
													,id = "explicitSubProperties"
													,checked = lQuery("OWL_PP#ExportParameter[pName = 'explicitSubProperties']"):attr("pValue")
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()")
												})
												
											}
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,leftMargin = 30
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Enable inverse property reasoning"
													,id = "enableInversePropertyResoning"
													,checked = lQuery("OWL_PP#ExportParameter[pName = 'enableInversePropertyResoning']"):attr("pValue")
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()")
												})
												
											}
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,leftMargin = 30
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Extend by initial chain properties"
													,id = "extendByInitialChainProperties"
													,checked = lQuery("OWL_PP#ExportParameter[pName = 'extendByInitialChainProperties']"):attr("pValue")
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()")
												})
												
											}
										})
										,lQuery.create("D#Row", {
											horizontalAlignment = -1
											,topMargin = 10
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Existential assertions (some values from, min cardinality, has values ..)"
													,id = "existentialAssertions"
													,checked = lQuery("OWL_PP#ExportParameter[pName = 'existentialAssertions']"):attr("pValue")
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()")
												})
												
											}
										})
									}
								})
							}
						})
					}
				})
				
			}})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
	
end


function close()
  
	lQuery("D#Event"):delete()
	utilities.close_form("ontology_export_preferences")
end

function closeDeleteCompartment()
	lQuery("D#Event"):delete()
	utilities.close_form("deteleCompartments")

end

function selectRadioButtonValue(id, caption)	
	local pValue = lQuery("OWL_PP#ExportParameter[pName = '" .. id .. "']"):attr("pValue")
	if caption == pValue then return true else return false end
end

function saveRadioButtonParameter()
	local radioButton = lQuery("D#Event/source"):last()
	local radioButtonCaption = radioButton:attr("caption")
	local radioButtonId = radioButton:attr("id")
	local pValue = lQuery("OWL_PP#ExportParameter[pName = '" .. radioButtonId .. "']")
	pValue:attr("pValue", radioButtonCaption)
	setExportAxioms()
end

function saveCheckBoxParameter()
	local checkBox = lQuery("D#Event/source"):last()
	local checkedId = checkBox:attr("id")
	local checked = checkBox:attr("checked")
	local pValue = lQuery("OWL_PP#ExportParameter[pName = '" .. checkedId .. "']")
	pValue:attr("pValue", checked)
	setExportAxioms()
end

function setExportAxioms()
	if lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "false" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") == "Standard (non-shema) ontology only" then

		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
ObjectPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
DataPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])


		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyDomain([/allValuesFrom != 'true']/Name:$getUri(/Name /Namespace) $getClassExpr(/end))
DataPropertyDomain([/allValuesFrom != 'true']/Name:$getUri(/Name /Namespace) $getClassExpr(/start))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

	lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]])

		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]])


		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(<http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(<http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
		end
	elseif lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "true" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") == "Standard (non-shema) ontology only" then

		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/noSchema != 'true'][/noSchema != '!'] <http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
DataPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])


		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../noSchema != 'true'][/../../noSchema != '+']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyDomain([/allValuesFrom != 'true']/Name:$getUri(/Name /Namespace) $getClassExpr(/end))
DataPropertyDomain([/allValuesFrom != 'true']/Name:$getUri(/Name /Namespace) $getClassExpr(/start))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

		lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) ?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/start))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]])

		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]])


		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
		end
		
	elseif lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "true" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") ~= "Standard (non-shema) ontology only" then
		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/noSchema != 'true'][/noSchema != '!'] <http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../noSchema != 'true'][/../../noSchema != '+']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

		lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) ?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/start))]])

		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/end))]])

		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
		end
		
	elseif lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "false" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") ~= "Standard (non-shema) ontology only" then
		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]])

		lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]])

		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]])

		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		
		if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(<http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(<http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
		end
	end
end