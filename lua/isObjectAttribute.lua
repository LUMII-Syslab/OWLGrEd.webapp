module(...,package.seeall)

require "re"
require "tda_to_protege"
require "lQuery"
require "core"
local MP = require "ManchesterParser"

function checkAttributeType(attrType, diagram, isObjectAttribute, attr)
	if attrType == nil then attrType = "" end
	local t = tda_to_protege.make_global_ns_uri_table(diagram)
	local funcSin, objectOrData = MP.generateAttributeType(attrType, diagram, t)
	local elem = core.get_compartment_element(attr)
		
	--ja ir viennozimigi nosakams
	if objectOrData~=nil then
		--ja isObjectAttribute vertiva sakrit ar KJ funkcijas atgriezto
		if (objectOrData == "ObjectProperty" and isObjectAttribute:attr("value") == "true") or (objectOrData == "DataProperty" and isObjectAttribute:attr("value") ~= "true") then
			--return funcSin, objectOrData
		--ja isObjectAttribute vertiva NEsakrit ar KJ funkcijas atgriezto
		else
			log("isObjectAttribute value was ignored in Class '" .. elem:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") .. "', attribute '" .. attr:find("/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value") .. "'")
			--return nil, nil -- + kluda
		end
		return funcSin, objectOrData
	--ja nav viennozimigi saprotams nemt isObjectAttribute vertibu
	else
		funcSin, objectOrData = MP.generateAttributeType(attrType, diagram, t, nil, nil, isObjectAttribute)
		return funcSin, objectOrData
	end
end

function createAttributeTypeValue(attributeType, attributeNs)
	local attributeValue = attributeType:attr("value")

	local OWL_specific  = require("OWL_specific")
	local defaultTypes = OWL_specific.default_types()
	local isDefaultType = false
	for _,dtype in pairs(defaultTypes) do
		if dtype==attributeType:attr("value") then
			isDefaultType = true
			break
		end
	end
	if isDefaultType == false and attributeNs:is_not_empty() and attributeNs:attr("value")~="" and string.sub(attributeType:attr("value"), 1, 1)~= "(" then
		attributeValue = "(" .. attributeValue .. "{" .. attributeNs:attr("value") .. "})"
	end
	
	return attributeValue
end

function setIsObjectAttributeOnTypeChange(attributeType, oldValue)
	if oldValue~=nil then
		local attribute = attributeType:find("/parentCompartment/parentCompartment")
		local attributeNs = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Namespace'])")
		local attributeValue = createAttributeTypeValue(attributeType, attributeNs)

		setIsObjectAttribute(attributeType, attribute, attributeValue)
	end
end

function setIsObjectAttributeOnTypeNamespaceChange(attributeTypeNamespace, oldValue)
	if oldValue~=nil then
		local attribute = attributeTypeNamespace:find("/parentCompartment/parentCompartment")
		local attributeType = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Type'])")
		local attributeValue = createAttributeTypeValue(attributeType, attributeTypeNamespace)
		
		setIsObjectAttribute(attributeType, attribute, attributeValue)
	end
end

function findMainDiagram(diagram)
	local dia = diagram
	while(dia:find("/parent:has(/elemType[id='OntologyFragment'])/graphDiagram"):is_not_empty()) do dia = dia:find("/parent/graphDiagram") end
	return dia
end

function findAllClasses(diagram)
	local classes = diagram:find("/element:has(/elemType[id='Class'])")
	diagram:find("/element:has(/elemType[id='OntologyFragment'])/child"):each(function(fragment)
		classes = classes:add(findAllClasses(fragment))
	end)
	return classes
end

function findAllDataTypes(diagram)
	local dataTypes = diagram:find("/element:has(/elemType[id='DataType'])")
	diagram:find("/element:has(/elemType[id='OntologyFragment'])/child"):each(function(fragment)
		dataTypes = dataTypes:add(findAllClasses(fragment))
	end)
	return dataTypes
end

function setIsObjectAttributeForAllAttribute(diagram, t, classList, datatypeList)
	-- print("Start")
	if diagram == nil then diagram = utilities.current_diagram() end
	local mainDiagram = findMainDiagram(diagram)
	if t == nil then t = tda_to_protege.make_global_ns_uri_table(mainDiagram) end
	if classList == nil then 
		local classes = findAllClasses(mainDiagram)
		classList = MP.getAllClasses(classes) 
	end
	if datatypeList == nil then 
		local dataTypes = findAllDataTypes(mainDiagram)
		datatypeList = MP.getAllDatatypes(dataTypes) 
	end
	diagram:find("/element:has(/elemType[id='OntologyFragment'])/child"):each(function(ontologyFragment)
		setIsObjectAttributeForAllAttribute(ontologyFragment, t, classList, datatypeList);
	end)
	diagram:find("/element:has(/elemType[id='Class'])/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)
		if attribute:find("/subCompartment"):is_empty() then 
			core.split_compart_value(attribute, true)	
		end
		local attributeType = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Type'])")
		local attributeNs = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Namespace'])")
		local attributeValue = createAttributeTypeValue(attributeType, attributeNs)
		if attributeValue == nil then attributeValue = "" end
		
		local funcSin, objectOrData = MP.generateAttributeType(attributeValue, diagram, t, classList, datatypeList)
		if objectOrData~=nil then
			local compartType = attribute:find("/compartType/subCompartType[id='isObjectAttribute']")
			isObjectAttribute = core.create_missing_compartment(attribute, attribute:find("/compartType"), compartType)	
			local value
			if objectOrData == "ObjectProperty" then
				value = true
			else
				value = false
			end
			isObjectAttribute:attr("value", value)
			isObjectAttribute:attr("input", value)
		end
	end)
	-- print("End")
end

--onOpen
function setIsObjectAttributeOnOpen(attributesForm)
	local diagram = utilities.current_diagram()
	local mainDiagram = findMainDiagram(diagram)
	local t = tda_to_protege.make_global_ns_uri_table(mainDiagram)
	
	local classes = findAllClasses(mainDiagram)
	local classList = MP.getAllClasses(classes) 

	local dataTypes = findAllDataTypes(mainDiagram)
	local datatypeList = MP.getAllDatatypes(dataTypes) 

	utilities.active_elements():find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)
	  if attribute:find("/subCompartment"):size() > 1 and attribute:find("/subCompartment:has(/compartType[id='Type'])"):size() > 0 then
		
		local attributeType = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Type'])")
	
		local attributeNs = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Namespace'])")
		local attributeValue = createAttributeTypeValue(attributeType, attributeNs)
		local isObjectAttribute = attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])")
		
		local funcSin, objectOrData = MP.generateAttributeType(attributeValue, diagram, t, classList, datatypeList)
		-- print("ON OPEN ", funcSin, objectOrData)
		if objectOrData~=nil then
			--if isObjectAttribute:is_empty() then 
				local compartType = attribute:find("/compartType/subCompartType[id='isObjectAttribute']")
				isObjectAttribute = core.create_missing_compartment(attribute, attribute:find("/compartType"), compartType)
				local component = attributesForm:find("/focused/container/container/component[id='isObjectAttribute']/component/component[id='field']")
				isObjectAttribute:link("component", component)
			--end
				local value
				if objectOrData == "ObjectProperty" then
					value = true
				else
					value = false
				end
				isObjectAttribute:attr("value", value)
				isObjectAttribute:attr("input", value)
				isObjectAttribute:find("/component"):attr("checked", isObjectAttribute:attr("value"))
				--isObjectAttribute:find("/component"):attr("enabled", false)
				--isObjectAttribute:find("/component"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
			--end
		end
		-- print(objectOrData, "objectOrData")
		-- print(funcSin, "funcSin")
	  end
	end)
	--[[
	local attributeType = attributesForm:find("/focused/compartment/parentCompartment/parentCompartment/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Type'])")
	local diagram = utilities.current_diagram()

	local attribute = attributesForm:find("/focused/compartment/parentCompartment/parentCompartment")
	if attribute:is_not_empty() and attributeType:is_not_empty() then
		local attributeNs = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Namespace'])")
		local attributeValue = createAttributeTypeValue(attributeType, attributeNs)
		local isObjectAttribute = attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])")
		local t = tda_to_protege.make_global_ns_uri_table(diagram)
		
		local funcSin, objectOrData = MP.generateAttributeType(attributeValue, diagram, t)
		-- print("ON OPEN ", funcSin, objectOrData)
		if objectOrData~=nil then
			--if isObjectAttribute:is_empty() then 
				local compartType = attribute:find("/compartType/subCompartType[id='isObjectAttribute']")
				isObjectAttribute = core.create_missing_compartment(attribute, attribute:find("/compartType"), compartType)
				local component = attributesForm:find("/focused/container/container/component[id='isObjectAttribute']/component/component[id='field']")
				isObjectAttribute:link("component", component)
			--end
				local value
				if objectOrData == "ObjectProperty" then
					value = true
				else
					value = false
				end
				isObjectAttribute:attr("value", value)
				isObjectAttribute:attr("input", value)
				isObjectAttribute:find("/component"):attr("checked", isObjectAttribute:attr("value"))
				--isObjectAttribute:find("/component"):attr("enabled", false)
				--isObjectAttribute:find("/component"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
			--end
		end
		--print(objectOrData, "objectOrData")
		--print(funcSin, "funcSin")
	end--]]
end

function setIsObjectAttribute(attributeType,attribute, attributeValue)
	local diagram = utilities.current_diagram()
	local mainDiagram = findMainDiagram(diagram)
	local t = tda_to_protege.make_global_ns_uri_table(mainDiagram)
	
	local classes = findAllClasses(mainDiagram)
	local classList = MP.getAllClasses(classes) 

	local dataTypes = findAllDataTypes(mainDiagram)
	local datatypeList = MP.getAllDatatypes(dataTypes)
	
	if attribute:is_not_empty() and attributeType:is_not_empty() then
		if diagram:find("/parent"):is_not_empty() then diagram = diagram:find("/parent/graphDiagram") end
		local funcSin, objectOrData = MP.generateAttributeType(attributeValue, diagram, t, classList, datatypeList)
		local isObjectAttribute = attribute:find("/subCompartment:has(/compartType[id='isObjectAttribute'])")
		if objectOrData~=nil then
			if isObjectAttribute:is_empty() then 
				local compartType = attribute:find("/compartType/subCompartType[id='isObjectAttribute']")
				isObjectAttribute = core.create_missing_compartment(attribute, attribute:find("/compartType"), compartType)
				local component = lQuery("Event/source/container/container/component[id='isObjectAttribute']/component/component[id='field']")
				isObjectAttribute:link("component", component)
			end
			local value
			if objectOrData == "ObjectProperty" then
				value = true
			else
				value = false
			end
			isObjectAttribute:attr("value", value)
			isObjectAttribute:attr("input", value)
			isObjectAttribute:find("/component"):attr("checked", isObjectAttribute:attr("value"))
			isObjectAttribute:find("/component"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
		end
		--print(objectOrData, isObjectAttribute:size())
		--print(funcSin)
	end
end

function isObjectAttributeWarning(isObjectAttribute)
	
	
	local attribute = isObjectAttribute:find("/parentCompartment")
	local attributeNs = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Namespace'])")
	local attributeType = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Type'])")
	local attributeValue = createAttributeTypeValue(attributeType, attributeNs)

	local diagram = utilities.current_diagram()
	if attribute:is_not_empty() and attributeType:is_not_empty() then
		local diagram = utilities.current_diagram()
		local mainDiagram = findMainDiagram(diagram)
		local t = tda_to_protege.make_global_ns_uri_table(mainDiagram)
		
		local classes = findAllClasses(mainDiagram)
		local classList = MP.getAllClasses(classes) 

		local dataTypes = findAllDataTypes(mainDiagram)
		local datatypeList = MP.getAllDatatypes(dataTypes)
		
		local funcSin, objectOrData = MP.generateAttributeType(attributeValue, diagram, t, classList, datatypeList)
		local isObjectAttributeValue
		if objectOrData~=nil then
			if objectOrData == "ObjectProperty" then
				isObjectAttributeValue = "true"
			else
				isObjectAttributeValue = "false"
			end 
			if isObjectAttribute:attr("value")~= isObjectAttributeValue then
				showIsObjectAttributeWarning()
			end
		end
	end
end

function showIsObjectAttributeWarning()
	local close_button = lQuery.create("D#Button", {
		caption = "Ok"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.isObjectAttribute.closeIsObjectAttributeWarning()")
	})
  
	local form = lQuery.create("D#Form", {
		id = "closeIsObjectAttributeWarning"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = create_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.isObjectAttribute.closeIsObjectAttributeWarning()")
		,component = {
			lQuery.create("D#VerticalBox",{
				component = {
					lQuery.create("D#Label", {caption = "IsObjectAttribute value is incorrect"})
				}
			})
			,lQuery.create("D#HorizontalBox", {
			id = "closeButton"
			,component = {close_button}})
		}
	})
	dialog_utilities.show_form(form)
end

function closeIsObjectAttributeWarning()
	lQuery("D#Event"):delete()
    utilities.close_form("closeIsObjectAttributeWarning")
end