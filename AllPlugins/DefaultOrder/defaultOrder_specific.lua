module(..., package.seeall)

require("lua_tda")
require "core"
local t_to_p = require("tda_to_protege")
local owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"


function recalculateDefaultOrderForAllDiagrams()
	lQuery("Project/graphDiagram/element/child:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		recalculateDefaultOrderForAllClasses(diagram)
	end)
end

function recalculateDefaultOrderForAllClasses(diagram)
	diagram:find("/element:has(/elemType[id='Class'])"):each(function(class)
		defaultOrder(nil, class)
	end)
	
	diagram:find("/element:has(/elemType[id='OntologyFragment'])"):each(function(el)
		el:find("/child"):each(function(dia)
			recalculateDefaultOrderForAllClasses(dia)
		end)
	end)
end

function defaultOrder(form, class)
	-- local ns_uri_table = t_to_p.make_global_ns_uri_table(utilities.current_diagram())
	local value = ""
	local elem = utilities.active_elements()
	if elem:is_empty() then elem = class end
	if class ~= nil then elem = class end

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
	-- lQuery("Tag[value='OWLGrEd_UserFields.axiom.axiom'][key='owlgred_export']"):attr("value", 'OWLGrEd_OBIS.axiom.axiom')
	-- copyViewNameOnClose(elem)
	-- copyReportNameOnClose(elem)
end

function orderAttributesByDefaultOrderInDiagram()
	local diagram = utilities.current_diagram()
	diagram:find("/element:has(/elemType[id='Class'])"):each(function(elem)
		orderAttributesByDefaultOrder(elem)
	end)
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='Class'])"), diagram)
	recalculateDefaultOrderForAllClasses(diagram)
end

function orderAttributesByDefaultOrderInClass()
	local diagram = utilities.current_diagram()
	local elem = utilities.active_elements()
	orderAttributesByDefaultOrder(elem)
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='Class'])"), diagram)
	defaultOrder(nil, elem)
end

function orderAttributesByDefaultOrderInSelectedClasses()
	local diagram = utilities.current_diagram()
	local elem = utilities.active_elements()
	elem:each(function(class)
		orderAttributesByDefaultOrder(class)
	end)
	
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='Class'])"), diagram)
	reComputeOrderAnnotationsInSelectedClasses()
end

function orderAttributesByDefaultOrder(elem)
	
		-- local compartment = elem:find("/compartment:has(/compartType[id='defaultOrder'])")
		-- if compartment:is_not_empty() then
			local attributes = elem:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
			
			local attributesTable = {}
			-- local attributesTable2 = {}
			attributes:each(function(attrib)
				attributesTable[attrib:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value")] = attrib
			end)
			elem:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):remove_link("subCompartment", elem:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"))
			
			-- for k, v in pairs(split(compartment:attr("value"), ",")) do
			-- for k, v in pairs(split("a3,a1,a2", ",")) do
				-- table.insert(attributesTable2, attributesTable[v])
				-- attributesTable[v] = nil
			-- end
			
			
			-- for k, v in pairsByKeys(attributesTable2) do
				-- v:link("parentCompartment", elem:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
				-- core.update_compartment_input_from_value(v, v:find("/copartType"))
			-- end
			
			for k, v in pairsByKeys(attributesTable) do
				v:link("parentCompartment", elem:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
				core.update_compartment_input_from_value(v, v:find("/copartType"))
			end
		-- end
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
 
function reComputeOrderAnnotationsInClass()
	local elem = utilities.active_elements()
	defaultOrder(nil, elem)
end

function reComputeOrderAnnotationsInDiagram()
	local diagram = utilities.current_diagram()
	recalculateDefaultOrderForAllClasses(diagram)
end

function reComputeOrderAnnotationsInSelectedClasses()
	local elem = utilities.active_elements()
	elem:each(function(class)
		defaultOrder(nil, class)
	end)
end

function calculateDafaultOrderOnDiagramSave(diagram)
	recalculateDefaultOrderForAllClasses(diagram)
end