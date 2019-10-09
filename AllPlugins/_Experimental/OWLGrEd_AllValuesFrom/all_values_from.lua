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
		if allValuesFrom:attr("value")=="true" then result = "+" end
	end
	return result
end

function setPrefixesPlusFromAllFaluesFrom(compartment, oldValue)
	local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	if compartment:attr("value") == "true" then 
		name:attr("input", "+" .. name:attr("value"))
	else
		name:attr("input", name:attr("value"))
	end
	utilities.refresh_element(name, utilities.current_diagram())
end