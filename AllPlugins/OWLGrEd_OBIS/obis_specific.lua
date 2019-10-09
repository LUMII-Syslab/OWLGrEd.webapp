module(..., package.seeall)

require("lua_tda")
require "core"
local t_to_p = require("tda_to_protege")
local owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"


function recalculateDefaultOrderForAllClasses()
	local diagrams = lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		diagram:find("/element:has(/elemType[id='Class'])"):each(function(class)
			defaultOrder(class)
		end)
	end)
end

function defaultOrder(class)
	-- local ns_uri_table = t_to_p.make_global_ns_uri_table(utilities.current_diagram())
	local value = ""
	local elem = utilities.active_elements()
	if elem:is_empty() then elem = class end
	elem:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(obj)
		local Namespace = obj:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
		local Name = obj:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value")
		if Name ~= nil then
			if value ~= "" then value = value .. "," end
			if Namespace~=nil and Namespace~="" then
				value = value .. Namespace .. ":"
			end
			value = value .. Name
		end
	end)
	local compartment = elem:find("/compartment:has(/compartType[id='defaultOrder'])")
	if compartment:is_empty() then
		compartment = lQuery.create("Compartment"):link("element", elem)
									:link("compartType", elem:find("/elemType/compartType[id='defaultOrder']"))
	end
	compartment:attr("value", value)
	lQuery("Tag[value='OWLGrEd_UserFields.axiom.axiom'][key='owlgred_export']"):attr("value", 'OWLGrEd_OBIS.axiom.axiom')
	copyViewNameOnClose(elem)
	copyReportNameOnClose(elem)
end

function replaceAxiom()
	lQuery("Tag[value='OWLGrEd_UserFields.axiom.axiom'][key='owlgred_export']"):attr("value", 'OWLGrEd_OBIS.axiom.axiom')
end

function copyNameOnClose(elem, compartType, subCompartType)
	local viewShortCompartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='" .. subCompartType .. "']")
	local viewASFictitious = elem:find("/compartment:has(/compartType[caption='" .. subCompartType .. "'])")
	local viewValue=""
	local viewInput = ""
	elem:find("/compartment/subCompartment:has(/compartType[id='".. compartType .. "'])"):each(function(view)
        local name = view:find("/subCompartment:has(/compartType[id='Name'])")
		if name:is_not_empty() then
			viewValue = viewValue .. name:attr("value") .. ","
			viewInput = viewInput .. name:attr("input") .. ","
		else
			local grammar2 = re.compile([[
							gMain <- ({VarName})
							VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
						]])
			local name = re.match(view:attr("value"), grammar2)
			viewValue = viewValue .. name .. ","
			viewInput = viewInput .. name .. ","
		end
	end)
	viewInput = string.sub(viewInput,1, string.len(viewInput)-1)
	viewASFictitious:attr("value", viewValue)
	viewASFictitious:attr("input", viewInput)
	local diagram = utilities.current_diagram()
	local cmd = lQuery.create("OkCmd")
			cmd:link("graphDiagram", diagram)
			utilities.execute_cmd_obj(cmd)
end

function findName(view)
	local name = view:find("/subCompartment:has(/compartType[id='Name'])")
	if name:is_not_empty() then
		return name:attr("value")
	else
		local grammar2 = re.compile([[
						gMain <- ({VarName})
						VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
					]])
		local name = re.match(view:attr("value"), grammar2)
		return name
	end
end

function findTarget(view)
	local target = view:find("/subCompartment:has(/compartType[id='Target'])")
	if target:is_not_empty() then
		return target:attr("value")
	else
		local grammar2 = re.compile([[
						gMain <- (VarName? "@" {VarName})
						VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
					]])
		local target = re.match(view:attr("value"), grammar2)
		return target
	end
end

function copyViewNameOnClose(elem)
	local viewShortCompartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='view_short']")
	local viewASFictitious = elem:find("/compartment:has(/compartType[caption='view_short'])")
	local viewValue=""
	local viewInput = ""
	
	local emptyViews = {}
	local withoutNameViews = {}
	local withName = {}
	
	elem:find("/compartment/subCompartment:has(/compartType[id='View'])"):each(function(view)
        local nameValue = findName(view)
		local targetValue = findTarget(view)
		
		if nameValue~=nil and nameValue~="" then
			table.insert(withName, view)
		elseif targetValue~=nil and targetValue~="" then
			table.insert(withoutNameViews, view)
		elseif view:attr("value")~="" then
			table.insert(emptyViews, view)
		end

	end)
	
	for i,v in pairs(emptyViews) do
		viewValue = viewValue .. "@,"
		viewInput = viewInput .. "@,"
	end
		
	for i,v in pairs(withoutNameViews) do
		local targetValue = findTarget(v)		
		viewValue = viewValue .. targetValue .. ","
		viewInput = viewInput .. targetValue .. ","
	end
	
	table.sort(withName, function (a,b)
      local nameA = findName(a)
      local nameB = findName(b)
	  return (nameA < nameB)
    end)
	
	for i,v in pairs(withName) do
		local nameValue = findName(v)
		local targetValue = findTarget(v)
		local value = nameValue
		if targetValue~=nil and targetValue~="" then value = value .. targetValue end
		viewValue = viewValue .. value .. ","
		viewInput = viewInput .. value .. ","
	end
	
	viewInput = string.sub(viewInput,1, string.len(viewInput)-1)
	viewASFictitious:attr("value", viewValue)
	viewASFictitious:attr("input", viewInput)
	local diagram = utilities.current_diagram()
	local cmd = lQuery.create("OkCmd")
			cmd:link("graphDiagram", diagram)
			utilities.execute_cmd_obj(cmd)
end

function copyReportNameOnClose(elem)
	copyNameOnClose(elem, "Report", "report_short")
end

function copyName(compartment, value, compartTypeValue, subCompartType)
    local compartType = compartment:find("/compartType")
	local class = compartment:find("/parentCompartment/parentCompartment/element")

	local viewShortCompartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='" .. subCompartType .. "']")
	local viewASFictitious = class:find("/compartment:has(/compartType[caption='" .. subCompartType .. "'])")
	local viewValue=""
	local viewInput = ""
	--class:find("/compartment/subCompartment:has(/compartType[id='view_short'])"):delete()
	class:find("/compartment/subCompartment:has(/compartType[id='" .. compartTypeValue .. "'])"):each(function(view)
	    -- local viewShort = lQuery.create("Compartment"):link("compartType", viewShortCompartType)
		                                              -- :link("parentCompartment", viewASFictitious)
        local name = view:find("/subCompartment:has(/compartType[id='Name'])")
		viewValue = viewValue .. name:attr("value") .. ","
		viewInput = viewInput .. name:attr("input") .. ","
	end)
	viewInput = string.sub(viewInput,1, string.len(viewInput)-1)
	viewASFictitious:attr("value", viewValue)
	viewASFictitious:attr("input", viewInput)
end

function copyViewName(compartment, value)
	local compartType = compartment:find("/compartType")
	local class = compartment:find("/parentCompartment/parentCompartment/element")
	
	copyViewNameOnClose(class)
	
	--[[local viewShortCompartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='view_short']")
	local viewASFictitious = class:find("/compartment:has(/compartType[caption='view_short'])")
	local viewValue=""
	local viewInput = ""
	--class:find("/compartment/subCompartment:has(/compartType[id='view_short'])"):delete()
	
	local views = class:find("/compartment/subCompartment:has(/compartType[id='View'])")
	
	
	
	class:find("/compartment/subCompartment:has(/compartType[id='View'])"):each(function(view)
	    -- local viewShort = lQuery.create("Compartment"):link("compartType", viewShortCompartType)
		                                              -- :link("parentCompartment", viewASFictitious)
        local name = view:find("/subCompartment:has(/compartType[id='Name'])")
		viewValue = viewValue .. name:attr("value") .. ","
		viewInput = viewInput .. name:attr("input") .. ","
	end)
	viewInput = string.sub(viewInput,1, string.len(viewInput)-1)
	viewASFictitious:attr("value", viewValue)
	viewASFictitious:attr("input", viewInput)
	
	
	copyName(compartment, value, "View", "view_short")--]]
end

function copyReportName(compartment, value)
	copyName(compartment, value, "Report", "report_short")
end

function copyViewMarking(compartment, value)
	local compartType = compartment:find("/compartType")
	local class = compartment:find("/parentCompartment/parentCompartment/element")
	copyViewNameOnClose(class)
end

function setImport(diagram)
	local elements = diagram:find("/element:has(/elemType[id='Class'])"):each(function(elem)
		copyViewNameOnClose(elem)
		copyReportNameOnClose(elem)
	end)
	owl_fields_specific.setImportStyles(diagram)
end

function orderAttributesByDefaultOrder()
	local diagram = utilities.current_diagram()
	diagram:find("/element:has(/elemType[id='Class'])"):each(function(elem)
		local compartment = elem:find("/compartment:has(/compartType[id='defaultOrder'])")
		if compartment:is_not_empty() then
			local attributes = elem:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
			
			local attributesTable = {}
			local attributesTable2 = {}
			attributes:each(function(attrib)
				attributesTable[attrib:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value")] = attrib
			end)
			
			elem:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):remove_link("subCompartment", elem:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"))
			
			for k, v in pairs(split(compartment:attr("value"), ",")) do
				table.insert(attributesTable2, attributesTable[v])
				attributesTable[v] = nil
			end
			
			
			for k, v in pairsByKeys(attributesTable2) do
				v:link("parentCompartment", elem:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
				core.update_compartment_input_from_value(v, v:find("/copartType"))
			end
			
			for k, v in pairsByKeys(attributesTable) do
				v:link("parentCompartment", elem:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
				core.update_compartment_input_from_value(v, v:find("/copartType"))
			end
		end
	end)
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='Class'])"), diagram)
	recalculateDefaultOrderForAllClasses()
end

function split (s, sep)
    sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = lpeg.Ct(elem * (sep * elem)^0)
  return lpeg.match(p, s)
end

function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
 end