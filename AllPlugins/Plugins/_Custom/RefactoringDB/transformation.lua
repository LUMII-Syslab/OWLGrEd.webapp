module(..., package.seeall)

require("core")

function transform_property_names()
	local diagram = utilities.current_diagram()
	diagram:find("/element:has(/elemType[id='Class'])"):each(function(elem)
		local elemName = elem:find("/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value")
		elem:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"):each(function(attribute)
		    local attributeName = attribute:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			if stringStarts(attributeName:attr("value"), elemName .. "_") then 
				attributeName:attr("value", string.sub(attributeName:attr("value"), string.len(elemName .. "_")+1))
			end
			core.update_compartment_input_from_value(attributeName, attributeName:find("/copartType"))
		end)

		elem:find("/eStart/compartment:has(/compartType[id='Role'])"):each(function(role)
			local roleName = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			if stringStarts(roleName:attr("value"), elemName .. "_") then
				roleName:attr("value", string.sub(roleName:attr("value"), string.len(elemName .. "_")+1))
				core.update_compartment_input_from_value(roleName, roleName:find("/copartType"))
			end
		end)
		
		elem:find("/eEnd/compartment:has(/compartType[id='InvRole'])"):each(function(role)
			local roleName = role:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
			if stringStarts(roleName:attr("value"), elemName .. "_") then
				roleName:attr("value", string.sub(roleName:attr("value"), string.len(elemName .. "_")+1))
				core.update_compartment_input_from_value(roleName, roleName:find("/copartType"))
			end
		end)
	end)
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='Class'])"), diagram)
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='Association'])"), diagram)
	print("END of transformation")
end

function stringStarts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function orderAttributes(elem)
	local attributes = elem:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
	local attributesTable = {}
	attributes:each(function(attrib)
		attributesTable[attrib:find("/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])"):attr("value")] = attrib
	end)
	
	elem:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"):remove_link("subCompartment", elem:find("/compartment/subCompartment:has(/compartType[id='Attributes'])"))
	for k, v in pairsByKeys(attributesTable) do
		v:link("parentCompartment", elem:find("/compartment:has(/compartType[id='ASFictitiousAttributes'])"))
		core.update_compartment_input_from_value(v, v:find("/copartType"))
	end
end

function orderAttributesDiagramm()
	local diagram = utilities.current_diagram()
	diagram:find("/element:has(/elemType[id='Class'])"):each(function(elem)
		orderAttributes(elem)
	end)
	
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='Class'])"), diagram)
end

function orderAttributesClass()
	local elem = utilities.active_elements()
	orderAttributes(elem)
	utilities.refresh_element(elem, utilities.current_diagram())
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