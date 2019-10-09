module(..., package.seeall)

require("lua_tda")
require "core"
local OA = require("isObjectAttribute")
local t_to_p = require("tda_to_protege")
local MP = require("ManchesterParser")
local owl_specific = require("OWL_specific")
require "lpeg"
require "re"

function connectAttributeToDataType()
	local class = utilities.active_elements()
	local diagram = utilities.current_diagram()
	class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)
	    local attrType= attribute:find("/subCompartment/subCompartment:has(/compartType[id='Type'])")
		local dataType = diagram:find("/element:has(/elemType[id='DataType']):has(/compartment/subCompartment:has(/compartType[id='Name'])[value='" .. attrType:attr("value") .. "'])")
		if dataType:is_not_empty() then
		    createDottedLinkClassDataType(class, dataType, diagram)
		end
	end)
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end

function  createDottedLinkClassDataType(class, dataType, diagram)
	local dt = class:find("/eEnd:has(/elemType[id='ConnectorDataType'])/start:has(/elemType[id='DataType'])")
	dt = dt:add(class:find("/eStart:has(/elemType[id='ConnectorDataType'])/end:has(/elemType[id='DataType'])"))
	dt = dt:filter(function(dType)
		return dataType:id() == dType:id()
	end)
	if dt:size() == 0 then  core.add_edge(lQuery("EdgeType[id='ConnectorDataType']"), class, dataType, diagram):link("elemStyle", lQuery("EdgeType[id='ConnectorDataType']/elemStyle"))   end 
end

function associationToAttribute()
    
	local association = utilities.active_elements()
	local classRole = association:find("/start")
	local role = association:find("/compartment:has(/compartType[id='Role'])")
	local classInvRole = association:find("/end")
	local invRole = association:find("/compartment:has(/compartType[id='InvRole'])")
	
	if role:find("/subCompartment:has(/compartType[id='Name'])"):is_not_empty() and role:find("/subCompartment:has(/compartType[id='Name'])"):attr("value")~="" then 
		cteateAttribute(classRole, role, classInvRole) 
	end
	if invRole:find("/subCompartment:has(/compartType[id='Name'])"):is_not_empty() and invRole:find("/subCompartment:has(/compartType[id='Name'])"):attr("value")~="" then 
		cteateAttribute(classInvRole, invRole, classRole) 
	end

	association:delete()
	diagram = utilities.current_diagram()
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end

function attributeToClassAttribute()

	local attributeLink = utilities.active_elements()
	local class = attributeLink:find("/start:has(/elemType[id='Class'])")
	class = class:add(attributeLink:find("/end:has(/elemType[id='Class'])"))
	local dataType = attributeLink:find("/start:has(/elemType[id='DataType'])")
	dataType = dataType:add(attributeLink:find("/end:has(/elemType[id='DataType'])"))
	
	if attributeLink:find("/compartment:has(/compartType[id='Name'])"):is_not_empty() and attributeLink:find("/compartment:has(/compartType[id='Name'])"):attr("value")~="" then 
		cteateAttributeFromLink(class, attributeLink, dataType) 
	end
	
	attributeLink:delete()
	diagram = utilities.current_diagram()
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end

function attributeListTolink()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.RefactoringServices.refactoringServices.close()")
  })
local ok_button = lQuery.create("D#Button", {
    caption = "Ok"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.RefactoringServices.refactoringServices.transformAttributesToLink()")
  })

  local form = lQuery.create("D#Form", {
    id = "Attributes"
    ,caption = "Attributes"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.RefactoringServices.refactoringServices.close()")
	,component = {
		lQuery.create("D#VerticalBox", {
			horizontalAlignment = -1
			,component = { 
				lQuery.create("D#ComboBox", {
				    id = "AttributeComboBox"
					,minimumWidth = 200
					,text = "All"
					,item = {
					    lQuery.create("D#Item", {
							value = "All"
						})
						,collectAttributesDataType()
					}
				})
			}
		})
		,ok_button
		-- ,close_button
    }
  })
  dialog_utilities.show_form(form)
end

function attributeList()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.RefactoringServices.refactoringServices.close()")
  })
local ok_button = lQuery.create("D#Button", {
    caption = "Ok"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.RefactoringServices.refactoringServices.transformAttributesToAssociations()")
  })

  local form = lQuery.create("D#Form", {
    id = "Attributes"
    ,caption = "Attributes"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.RefactoringServices.refactoringServices.close()")
	,component = {
		lQuery.create("D#VerticalBox", {
			horizontalAlignment = -1
			,component = { 
				lQuery.create("D#ComboBox", {
				    id = "AttributeComboBox"
					,minimumWidth = 200
					,text = "All"
					,item = {
					    lQuery.create("D#Item", {
							value = "All"
						})
						,collectAttributes()
					}
				})
			}
		})
		,ok_button
		-- ,close_button
    }
  })
  dialog_utilities.show_form(form)
end

function collectAttributes()
    
	local class = utilities.active_elements()
	local diagram = class:find("/graphDiagram")
	local attributes = class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):map(
	  function(obj)
		
		local attribute_type = obj:find("/subCompartment:has(/compartType[id='Type'])"):attr("value")
		local isObjectAttribute = obj:find("/subCompartment:has(/compartType[id = 'isObjectAttribute'])")
	    local _, data_or_object_prop = OA.checkAttributeType(attribute_type, class:find("/graphDiagram"), isObjectAttribute, obj)
		
		if data_or_object_prop == "ObjectProperty" then 
			return {obj:attr("value"), obj:id()}
		end
	  end)
	
	-- values = lQuery.merge(values, value2)
	
	return lQuery.map(attributes, function(value) 
		return lQuery.create("D#Item", {
			value = value[1]
			,id = value[2]
		}) 
	end)
end

function collectAttributesDataType()
    
	local class = utilities.active_elements()
	local diagram = class:find("/graphDiagram")
	local attributes = class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):map(
	  function(obj)
		
		local attribute_type = obj:find("/subCompartment:has(/compartType[id='Type'])"):attr("value")
		local isObjectAttribute = obj:find("/subCompartment:has(/compartType[id = 'isObjectAttribute'])")
	    local _, data_or_object_prop = OA.checkAttributeType(attribute_type, class:find("/graphDiagram"), isObjectAttribute, obj)
		
		if data_or_object_prop == "DataProperty" then 
			return {obj:attr("value"), obj:id()}
		end
	  end)
	
	-- values = lQuery.merge(values, value2)
	
	return lQuery.map(attributes, function(value) 
		return lQuery.create("D#Item", {
			value = value[1]
			,id = value[2]
		}) 
	end)
end

function close()
  lQuery("D#Event"):delete()
  utilities.close_form("Attributes")
end

function transformAttributesToLink()
	local class = utilities.active_elements()
	local diagram = class:find("/graphDiagram")
	local attributes
	if lQuery("D#ComboBox[id='AttributeComboBox']"):attr("text") == "All" then
		attributes = class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
	else
		attributes = class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):filter(function(attrib)
			return attrib:id() == tonumber(lQuery("D#ComboBox[id='AttributeComboBox']/selected"):attr("id"))
		end)
	end
	attributes:each(function(attribute)
	    local attribute_type = attribute:find("/subCompartment:has(/compartType[id='Type'])"):attr("value")
		local isObjectAttribute = attribute:find("/subCompartment:has(/compartType[id = 'isObjectAttribute'])")
	    local _, data_or_object_prop = OA.checkAttributeType(attribute_type, class:find("/graphDiagram"), isObjectAttribute, attribute)
		
		if data_or_object_prop == "DataProperty" then 
			createAttributeLink(class, classFromType, diagram, attribute)
			attribute:delete()
		end
	end)
	core.make_compart_value_from_sub_comparts(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	core.set_parent_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	local input = core.build_compartment_input_from_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):attr("value"), class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):find("/compartType"), class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	if class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):size() == 0 then input = "" end
	core.set_compartment_input_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"), class:find("/compartment/compartType[id='ASFictitiousAttributes']"), input)
	utilities.refresh_element(class, diagram)
	close()
end

function transformAttributesToAssociations()
	local class = utilities.active_elements()
	local diagram = class:find("/graphDiagram")
	local attributes
	if lQuery("D#ComboBox[id='AttributeComboBox']"):attr("text") == "All" then
		attributes = class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
	else
		attributes = class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):filter(function(attrib)
			return attrib:id() == tonumber(lQuery("D#ComboBox[id='AttributeComboBox']/selected"):attr("id"))
		end)
	end
	attributes:each(function(attribute)
	    local attribute_type = attribute:find("/subCompartment:has(/compartType[id='Type'])"):attr("value")
		local isObjectAttribute = attribute:find("/subCompartment:has(/compartType[id = 'isObjectAttribute'])")
	    local _, data_or_object_prop = OA.checkAttributeType(attribute_type, class:find("/graphDiagram"), isObjectAttribute, attribute)
		
		if data_or_object_prop == "ObjectProperty" then 
			createAssociation(class, classFromType, diagram, attribute)
			attribute:delete()
		end
	end)
	core.make_compart_value_from_sub_comparts(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	core.set_parent_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	local input = core.build_compartment_input_from_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):attr("value"), class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):find("/compartType"), class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	if class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):size() == 0 then input = "" end
	core.set_compartment_input_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"), class:find("/compartment/compartType[id='ASFictitiousAttributes']"), input)
	utilities.refresh_element(class, diagram)
	close()
end

function attributeToAttributeLink()
	attributeListTolink()
end

function attributeToAssociation()
	attributeList()
	-- local class = utilities.active_elements()
	-- local diagram = class:find("/graphDiagram")
	-- local attributes = class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
	-- attributes:each(function(attribute)
	    -- local attribute_type = attribute:find("/subCompartment:has(/compartType[id='Type'])"):attr("value")
		-- local isObjectAttribute = attribute:find("/subCompartment:has(/compartType[id = 'isObjectAttribute'])")
	    -- local _, data_or_object_prop = OA.checkAttributeType(attribute_type, class:find("/graphDiagram"), isObjectAttribute, attribute)
		
		-- if data_or_object_prop == "ObjectProperty" then 
			-- createAssociation(class, classFromType, diagram, attribute)
			-- attribute:delete()
		-- end
	-- end)
	-- core.make_compart_value_from_sub_comparts(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	-- core.set_parent_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	-- local input = core.build_compartment_input_from_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):attr("value"), class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):find("/compartType"), class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
	-- if class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):size() == 0 then input = "" end
	-- core.set_compartment_input_value(class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"), class:find("/compartment/compartType[id='ASFictitiousAttributes']"), input)
	-- utilities.refresh_element(class, diagram)
end

function ObjectPropertyRestrictionToSuperClass()
	local restriction = utilities.active_elements()
	local classRole = restriction:find("/start")
	local classInvRole = restriction:find("/end")
	local classInvRoleName = classInvRole:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value")
	if classInvRoleName == nil or classInvRoleName == "" then
		classInvRoleName = classInvRole:find("/compartment/subCompartment:has(/compartType[id='EquivalentClasses'])"):first():attr("value")
		if string.sub(classInvRoleName, 1, 1) ~= "(" then classInvRoleName = "(" .. classInvRoleName .. ")" end
	end
	local role = restriction:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Role'])")
	if role:attr("value")~="" then 
		local value = role:attr("value")
		if  restriction:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='IsInverse'])"):attr("value") == "true" then 
			value = "inverse " .. value
		end
		if restriction:find("/compartment:has(/compartType[id='Some'])"):attr("value") == "true" then 
		    value = value .. " some "
		else
		    value = value .. " only "
		end
		value = value .. classInvRoleName
		cteateSuperClass(classRole, value, classInvRole) 
		local multiplicity = restriction:find("/compartment:has(/compartType[id='Multiplicity'])"):attr("value")
		if multiplicity~=nil and multiplicity~="" then
			value = role:attr("value")
			if  restriction:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='IsInverse'])"):attr("value") == "true" then 
				value = "inverse " .. value
			end
			local res = t_to_p.multiplicity_split(multiplicity)
			if res["MinMax"]~=nil then
				if res["MinMax"]["Min"]~= nil and res["MinMax"]["Min"]~= "0" then
					cteateSuperClass(classRole, value .. " min " .. res["MinMax"]["Min"] .. " " .. classInvRoleName, classInvRole) 
				end
				if res["MinMax"]["Max"]~= nil and res["MinMax"]["Max"]~= "*" then
					cteateSuperClass(classRole, value .. " max " .. res["MinMax"]["Max"] .. " " .. classInvRoleName, classInvRole) 
				end
			end
			if res["Number"]~= nil and res["Number"]~= "*" and res["Number"]~= "0" then
				cteateSuperClass(classRole, value .. " exactly " .. res["Number"] .. " " .. classInvRoleName, classInvRole) 
			end
		end
	end
	
	restriction:delete()
	diagram = utilities.current_diagram()
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end

function superClassToRestriction()
	local class = utilities.active_elements()
	local diagram = class:find("/graphDiagram")
	local superClasses = class:find("/compartment/subCompartment:has(/compartType[id='SuperClasses'])/subCompartment")
	local multTable = {}
	superClasses:each(function(superClass)
		local parseResult = superClassRestrictionGrammar(superClass:attr("value"))
		if parseResult~= nil then
			
			local classFromExpr = diagram:find("/element:has(/elemType[id='Class']):has(/compartment:has(/compartType[id='Name'])[value='" .. parseResult["expression"] .. "'])")
			if classFromExpr:is_not_empty() then
				if multTable[parseResult["property"] .. parseResult["expression"]] == nil then 
					multTable[parseResult["property"] .. parseResult["expression"]] = {}
				end
				multTable[parseResult["property"] .. parseResult["expression"]][parseResult["restriction"]["keyWord"]] = parseResult["restriction"]["number"] or "NOT"
				multTable[parseResult["property"] .. parseResult["expression"]]["property"] = parseResult["property"]
				multTable[parseResult["property"] .. parseResult["expression"]]["expression"] = parseResult["expression"]
				multTable[parseResult["property"] .. parseResult["expression"]]["class"] = class
				multTable[parseResult["property"] .. parseResult["expression"]]["classFromExpr"] = classFromExpr
				multTable[parseResult["property"] .. parseResult["expression"]]["inverse"] = parseResult["inverse"]
				superClass:find("/parentCompartment"):delete()
				core.make_compart_value_from_sub_comparts(class:find("/compartment:has(/compartType[id='ASFictitiousSuperClasses'])"))
			end
			classFromExpr = diagram:find("/element:has(/elemType[id='Class'])"):filter(function(elem)
				local value = elem:find("/compartment/subCompartment:has(/compartType[id='EquivalentClasses'])"):first():attr("value")
				if value ~= nil and (elem:find("/compartment:has(/compartType[id='Name'])"):attr("value") == nil or elem:find("/compartment:has(/compartType[id='Name'])"):attr("value") == "") then return value == parseResult["expression"] or "(" .. value .. ")" == parseResult["expression"] end
			end)
			if classFromExpr:is_not_empty() then
				if multTable[parseResult["property"] .. parseResult["expression"]] == nil then 
					multTable[parseResult["property"] .. parseResult["expression"]] = {}
				end
				multTable[parseResult["property"] .. parseResult["expression"]][parseResult["restriction"]["keyWord"]] = parseResult["restriction"]["number"] or "NOT"
				multTable[parseResult["property"] .. parseResult["expression"]]["property"] = parseResult["property"]
				multTable[parseResult["property"] .. parseResult["expression"]]["expression"] = parseResult["expression"]
				multTable[parseResult["property"] .. parseResult["expression"]]["class"] = class
				multTable[parseResult["property"] .. parseResult["expression"]]["classFromExpr"] = classFromExpr
				multTable[parseResult["property"] .. parseResult["expression"]]["inverse"] = parseResult["inverse"]
				superClass:find("/parentCompartment"):delete()
				core.make_compart_value_from_sub_comparts(class:find("/compartment:has(/compartType[id='ASFictitiousSuperClasses'])"))
			end
		end
	end)

	for k, v in pairs(multTable) do
		createRestriction2(v, diagram)
	end
	
	if class:find("/compartment/subCompartment:has(/compartType[id='SuperClasses'])"):size() == 0 then input = "" end
	core.set_compartment_input_value(class:find("/compartment:has(/compartType[id='ASFictitiousSuperClasses'])"), class:find("/compartment/compartType[id='ASFictitiousSuperClasses']"), input)
	
	
	utilities.refresh_element(class, diagram)
end

function superClassRestrictionGrammar(str)
	local gramar = [[
		main <- ({:inverse: "inverse ":}? {:property: string:} space {:restriction: keyWord:} space {:expression: expression:} !.) -> {}
		space <- (" ")+
		keyWord <- ({:keyWord: "some":} / {:keyWord: "only":} / ({:keyWord: numericKeyWord:} space {:number: number:}))->{}
		numericKeyWord <- ("min" / "max" / "exactly") 
		number <- ([0-9]+)
		string <- ([a-zA-Z] ([a-zA-Z] / [0-9] / "_" / "{" / "}")*)
		expression <- (string / ("(" expression (space expression)* ")"))
	]]
	return re.match(str, gramar)
end

function  createCompartmentsWithSameStructure(compartType, parent, roleCompartment)
    local value = ""
	if compartType:find("/subCompartType"):is_empty() then value = roleCompartment:attr("value") end
	local compartment = core.add_compartment(compartType, parent, value)
	local input = core.build_compartment_input_from_value(value, compartType, compartment)
	compartment:attr("input", input)
	
	if compartType:find("/subCompartType"):is_not_empty() then
	    compartType:find("/subCompartType"):each(function(subCompartType)
		    createCompartmentsWithSameStructure(subCompartType, compartment, roleCompartment:find("/subCompartment:has(/compartType[id = '" .. subCompartType:attr("id") .. "'])"))
		end)
	end
	
end

function createCompartmentsWithASFictitious(compartType, parent, roleCompartment, isRole)
    local compartment = core.add_compartment(compartType, parent, "")	
    local compartmentASFictitious = core.add_compartment(compartType:find("/subCompartType"), compartment, "")
	
	local roleExpressions = roleCompartment:find("/subCompartment")
	
	local roleCompartType
	local roleCompart
	local roleCompartTypeT = roleCompartment:find("/compartType")
	local roleCompartmentT= roleCompartment

	while roleCompartTypeT:is_not_empty() do
		roleCompartType = roleCompartTypeT
		roleCompart = roleCompartmentT:filter(function(obj)
			return obj:find("/compartType"):id() == roleCompartType:id()
		end)
		roleCompartmentT = roleCompartmentT:find("/subCompartment")
		roleCompartTypeT = roleCompartTypeT:find("/subCompartType")
    end
	
	-- local roleCompart = roleCompartType:find("/compartment"):filter(function(filCom)
		-- local roleCompartElem = core.get_compartment_element(filCom)
	    -- return roleCompartElem:id() == core.get_compartment_element(roleCompartment):id()
	-- end)

	roleCompart:each(function(rc)
	    -- local compartmentRC = core.add_compartment(compartmentASFictitious:find("/compartType/subCompartType"), compartmentASFictitious, "")	
		-- local compartmentExr = core.add_compartment(compartmentRC:find("/compartType/subCompartType"), compartmentRC, rc:attr("value"))	
		local ct = compartmentASFictitious:find("/compartType/subCompartType")
		local c = compartmentASFictitious
		while ct:is_not_empty() do
			if ct:find("/subCompartType"):is_empty() then
			    c = core.add_compartment(ct, compartmentASFictitious, rc:attr("value"))	
			else
			    c = core.add_compartment(ct, compartmentASFictitious, "")	
			end
			compartmentASFictitious = c
			ct = ct:find("/subCompartType")
		end
	end)
end

function cteateAttributeFromLink(class, attributeLink, dataType)
	local attributes = class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])")
	local attribute = core.add_compartment(attributes:find("/compartType/subCompartType[id='Attributes']"), attributes, "")
	
	attribute:find("/compartType/subCompartType"):each(function(compartType)
		if attributeLink:find("/elemType/compartType[id='" .. compartType:attr("id").. "']"):is_not_empty() then
			if compartType:find("/subCompartType"):is_empty() then 
				local value = attributeLink:find("/compartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):attr("value")
				local comp = core.add_compartment(compartType, attribute, value)	
				local input = core.build_compartment_input_from_value(value, compartType, comp)
				comp:attr("input", input)
			elseif compartType:find("/subCompartType"):size() ~= 1 or (compartType:find("/subCompartType"):size() == 1 and string.find(compartType:find("/subCompartType"):attr("id"), "ASFictitious")==nil) then
			 if attributeLink:find("/compartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):is_not_empty() then 
			  createCompartmentsWithSameStructure(compartType, attribute, attributeLink:find("/compartment:has(/compartType[id='" .. compartType:attr("id").. "'])"))
			 end	
			else
			 if attributeLink:find("/compartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):is_not_empty() then 
			   createCompartmentsWithASFictitious(compartType, attribute, attributeLink:find("/compartment:has(/compartType[id='" .. compartType:attr("id").. "'])"))
			 end
			end
		end
		if compartType:attr("id") == "Type" then
			local compartmentType = core.add_compartment(compartType, attribute, "")
			local compartmentTypeType = core.add_compartment(compartType:find("/subCompartType[id='Type']"), compartmentType, dataType:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value"))
			local compartmentTypeType = core.add_compartment(compartType:find("/subCompartType[id='Namespace']"), compartmentType, dataType:find("/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
		end
		if compartType:attr("id") == "isObjectAttribute" then
			local compartmentIsObjectAttribute = core.add_compartment(compartType, attribute, "false")
		end
	end)
	
    core.make_compart_value_from_sub_comparts(attribute)
    core.make_compart_value_from_sub_comparts(attributes)
	core.set_parent_value(attributes)
end

function cteateAttribute(class, role, classInvRole)
    local attributes = class:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])")
	local attribute = core.add_compartment(attributes:find("/compartType/subCompartType[id='Attributes']"), attributes, "")

	attribute:find("/compartType/subCompartType"):each(function(compartType)
		if role:find("/compartType/subCompartType[id='" .. compartType:attr("id").. "']"):is_not_empty() then
			if compartType:find("/subCompartType"):is_empty() then 
				local value = role:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):attr("value")
				if lQuery("ToolType/tag[key = 'DefaultMaxCardinality1']"):attr("value") == "1" and compartType:attr("id") == "Multiplicity" and value ~= nil and value~="" and string.find(value, "..")==nil then 
					value = value .. "..*"
				end
				local comp = core.add_compartment(compartType, attribute, value)	
				local input = core.build_compartment_input_from_value(value, compartType, comp)
				comp:attr("input", input)
			elseif compartType:find("/subCompartType"):size() ~= 1 or (compartType:find("/subCompartType"):size() == 1 and string.find(compartType:find("/subCompartType"):attr("id"), "ASFictitious")==nil) then
			 if role:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):is_not_empty() then 
			  createCompartmentsWithSameStructure(compartType, attribute, role:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"))
			 end	
			else
			 if role:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):is_not_empty() then 
			   createCompartmentsWithASFictitious(compartType, attribute, role:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"))
			 end
			end
		end
		if compartType:attr("id") == "Type" then
			local compartmentType = core.add_compartment(compartType, attribute, "")
			local compartmentTypeType = core.add_compartment(compartType:find("/subCompartType[id='Type']"), compartmentType, classInvRole:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value"))
			local compartmentTypeType = core.add_compartment(compartType:find("/subCompartType[id='Namespace']"), compartmentType, classInvRole:find("/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
		end
		if compartType:attr("id") == "isObjectAttribute" then
			local compartmentIsObjectAttribute = core.add_compartment(compartType, attribute, "true")
		end
		if compartType:attr("id") == "IsFunctional" then
			local compartmentIsObjectAttribute = core.add_compartment(compartType, attribute, role:find("/subCompartment:has(/compartType[id='Functional'])"):attr("value"))
		end
	end)
	
    core.make_compart_value_from_sub_comparts(attribute)
    core.make_compart_value_from_sub_comparts(attributes)
	core.set_parent_value(attributes)
end

function createAttributeLink(class, classFromType, diagram, attribute)
--if dataType exists
	local attribute_typeType = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Type'])"):attr("value")
	local attribute_typeNamespace = attribute:find("/subCompartment:has(/compartType[id='Type'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
	local dataType = diagram:find("/element:has(/elemType[id='DataType']):has(/compartment/subCompartment:has(/compartType[id='Name'])[value='" .. attribute_typeType .. "'])")
	local attributeLink = core.add_edge(lQuery("EdgeType[id='Attribute']"), class, dataType, diagram):link("elemStyle", lQuery("EdgeType[id='Attribute']/elemStyle"))
	if dataType:is_not_empty() then
		attributeLink:find("/elemType/compartType"):each(function(compartType)
			if compartType:find("/subCompartType"):is_empty() then 
				local value = attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):attr("value")
				local comp = core.add_compartment(compartType, attributeLink, value)	
				local input = core.build_compartment_input_from_value(value, compartType, comp)
				comp:attr("input", input)
			elseif compartType:find("/subCompartType"):size() ~= 1 or (compartType:find("/subCompartType"):size() == 1 and string.find(compartType:find("/subCompartType"):attr("id"), "ASFictitious")==nil) then
				if attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):is_not_empty() then 
					createCompartmentsWithSameStructure(compartType, attributeLink, attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"))
				end
			else
				if attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):is_not_empty() then
					createCompartmentsWithASFictitious(compartType, attributeLink, attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"))
				end
			end
		end)
		utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
	end
end

function createAssociation(class, classFromType, diagram, attribute)
	local attribute_type = attribute:find("/subCompartment:has(/compartType[id='Type'])"):attr("value")
	local classFromType = diagram:find("/element:has(/elemType[id='Class']):has(/compartment:has(/compartType[id='Name'])[value='" .. attribute_type .. "'])")
	local association = core.add_edge(lQuery("EdgeType[id='Association']"), class, classFromType, diagram):link("elemStyle", lQuery("EdgeType[id='Association']/elemStyle[id='Association_direct']"))
	local role = core.add_compartment(lQuery("EdgeType[id='Association']/compartType[id='Role']"), association, "")
	role:attr("isGroup", "true")
	local invrole = core.add_compartment(lQuery("EdgeType[id='Association']/compartType[id='InvRole']"), association, "")
	invrole:attr("isGroup", "true")

	role:find("/compartType/subCompartType"):each(function(compartType)
		if attribute:find("/compartType/subCompartType[id='" .. compartType:attr("id").. "']"):is_not_empty() then
			if compartType:find("/subCompartType"):is_empty() then 
				local value = attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):attr("value")
				if lQuery("ToolType/tag[key = 'DefaultMaxCardinality1']"):attr("value") == "1" and compartType:attr("id") == "Multiplicity" and (value == nil or value=="") then 
					value = "0..1"
				end
				local comp = core.add_compartment(compartType, role, value)	
				local input = core.build_compartment_input_from_value(value, compartType, comp)
				comp:attr("input", input)
			elseif compartType:find("/subCompartType"):size() ~= 1 or (compartType:find("/subCompartType"):size() == 1 and string.find(compartType:find("/subCompartType"):attr("id"), "ASFictitious")==nil) then
			   if attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):is_not_empty() then 
				createCompartmentsWithSameStructure(compartType, role, attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"))
			   end
			else
			   if attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"):is_not_empty() then
				createCompartmentsWithASFictitious(compartType, role, attribute:find("/subCompartment:has(/compartType[id='" .. compartType:attr("id").. "'])"))
			   end
			end
		end

		if compartType:attr("id") == "Functional" then
			local compartmentIsObjectAttribute = core.add_compartment(compartType, role, attribute:find("/subCompartment:has(/compartType[id='IsFunctional'])"):attr("value"))
		end
	end)
	
    core.make_compart_value_from_sub_comparts(role)
    core.set_parent_value(role)
	
	utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
end

function createRestrictionMultiplisity(parseResult, restriction)
	if parseResult["exactly"]~=nil then
	    core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Multiplicity']"), restriction, parseResult["exactly"])
	end
	local mul = ""
	if parseResult["min"]~=nil and parseResult["min"]~="0" then mul = parseResult["min"] end
	if parseResult["max"]~=nil and parseResult["max"]~="*" then 
		if mul~="" then mul = mul .. ".." .. parseResult["max"]
		else mul = parseResult["max"] end
	end
	if mul~="" then 
		core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Multiplicity']"), restriction, mul)
	end
end

function createRestriction2(parseResult, diagram)
	local restriction = createNewRestriction2(parseResult, diagram)
	if parseResult["only"]~=nil then
		core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Only']"), restriction, "true")
	end
	if parseResult["some"]~=nil then
		core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Some']"), restriction, "true")
	end
	createRestrictionMultiplisity(parseResult, restriction)
end

function createRestriction(class, classFromExpr, parseResult, diagram)
	if parseResult["restriction"]["keyWord"] == "only" then
		local restriction = createNewRestriction(class, classFromExpr, parseResult, diagram)
		core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Only']"), restriction, "true")
	end
	if parseResult["restriction"]["keyWord"] == "some" then
	    local restriction = createNewRestriction(class, classFromExpr, parseResult, diagram)
		core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Some']"), restriction, "true")
	end
end

function createNewRestriction2(parseResult, diagram)
	local restriction = core.add_edge(lQuery("EdgeType[id='Restriction']"), parseResult["class"], parseResult["classFromExpr"], diagram)
	local name  = core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Name']"), restriction, "")
	local role  = core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Name']/subCompartType[id='Role']"), name, parseResult["property"])
	if parseResult["inverse"]~=nil then
		core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Name']/subCompartType[id='IsInverse']"), name, "true")
		owl_specific.set_restriction_role(role)
	end
	return restriction
end
function createNewRestriction(class, classFromExpr, parseResult, diagram)
	local restriction = core.add_edge(lQuery("EdgeType[id='Restriction']"), class, classFromExpr, diagram)
	local name  = core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Name']"), restriction, "")
	local role  = core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Name']/subCompartType[id='Role']"), name, parseResult["property"])
	if parseResult["inverse"]~=nil then
		core.add_compartment(lQuery("EdgeType[id='Restriction']/compartType[id='Name']/subCompartType[id='IsInverse']"), name, "true")
		owl_specific.set_restriction_role(role)
	end
	return restriction
end

function cteateSuperClass(class, role, classInvRole)
    
	local superClases = class:find("/compartment:has(/compartType[id='ASFictitiousSuperClasses'])")
	local superClass = core.add_compartment(superClases:find("/compartType/subCompartType[id='SuperClasses']"), superClases, "")

	local expression = core.add_compartment(superClass:find("/compartType/subCompartType[id='Expression']"), superClass, role)
	local input = core.build_compartment_input_from_value(role, superClass:find("/compartType/subCompartType[id='Expression']"), expression)
	expression:attr("input", input)
	
	core.make_compart_value_from_sub_comparts(superClass)
    core.make_compart_value_from_sub_comparts(superClases)
	core.set_parent_value(superClass)

	-- diagram = utilities.current_diagram()
	-- utilities.execute_cmd("OkCmd", {graphDiagram = diagram})	
end

function forkToSuperClass()
	local class = utilities.active_elements()
	local subClasses = class:find("/eEnd/start/eEnd/start")
	local className =  class:find("/compartment:has(/compartType[id='Name'])"):attr("value")
	if className == nil or className == "" then
		className = class:find("/compartment/subCompartment:has(/compartType[id='EquivalentClasses'])/subCompartment/subCompartment"):attr("value")
	end
	if className ~= nil and className ~= "" then
		subClasses:each(function(subC)
			cteateSuperClass(subC, className, "")
		end)
		class:find("/eEnd/start/eEnd"):delete()
		class:find("/eEnd/start"):delete()
		class:find("/eEnd"):delete()
		local diagram = class:find("/graphDiagram")
		utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
	end
end