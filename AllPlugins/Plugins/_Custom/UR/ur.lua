module(..., package.seeall)

require("lua_tda")
require "core"
local OA = require("isObjectAttribute")
local t_to_p = require("tda_to_protege")
local MP = require("ManchesterParser")
local owl_specific = require("OWL_specific")
require "lpeg"
require "re"

function transformClassToAssociations()
	local class = utilities.active_elements()
	
	local OUTAssoc = class:find("/eStart")
	local INAssoc = class:find("/eEnd")
	-- local OUTAssoc = class:find("/eStart:has(/compartment:has(/compartType[id='Role'])/subCompartment/subCompartment:has(/compartType[id='Name']))")
	-- OUTAssoc = OUTAssoc:add(class:find("/eEnd:has(/compartment:has(/compartType[id='InvRole'])/subCompartment/subCompartment:has(/compartType[id='Name']))"))
	-- OUTAssoc = OUTAssoc:filter(function(assoc)
		-- return assoc:find("/compartment/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value") ~= ""
	-- end)
	
	-- local INAssoc = class:find("/eEnd:has(/compartment:has(/compartType[id='Role'])/subCompartment/subCompartment:has(/compartType[id='Name']))")
	-- INAssoc = INAssoc:add(class:find("/eStart:has(/compartment:has(/compartType[id='InvRole'])/subCompartment/subCompartment:has(/compartType[id='Name']))"))
	-- INAssoc = INAssoc:filter(function(assoc)
		-- return assoc:find("/compartment/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value") ~= ""
	-- end)
	

	-- OUTAssoc:each(function(obj)
		-- print(obj:find("/compartment/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value"))
	-- end)
	-- print(class:find("/eEnd"):find("/compartment:has(/compartType[id='Role'])/subCompartment/subCompartment:has(/compartType[id='Name'])"):first():attr("value"))
	-- print(class:find("/eStart"):find("/compartment:has(/compartType[id='InvRole'])/subCompartment/subCompartment:has(/compartType[id='Name'])"):last():attr("value"))
	local diagram = utilities.current_diagram()
	
	
	if OUTAssoc:size() == 1 and INAssoc:size() > 0 then
		INAssoc:each(function(assoc)

			local mulTableA = t_to_p.multiplicity_split(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Multiplicity'])"):attr("value"))
			local mulTableB = t_to_p.multiplicity_split(OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Multiplicity'])"):attr("value"))
			local minMul
			local maxMul
			if mulTableA["MinMax"]~= nil and mulTableA["MinMax"]["Min"] ~= nil and mulTableA["MinMax"]["Min"] == "0" then
				minMul = "0"
			end
			if mulTableB["MinMax"]~= nil and mulTableB["MinMax"]["Min"] ~= nil and mulTableB["MinMax"]["Min"] == "0" then
				minMul = "0"
			end
			
			if mulTableA["MinMax"]~= nil and mulTableA["MinMax"]["Max"] ~= nil and mulTableA["MinMax"]["Max"] == "*" then
				maxMul = "*"
			end
			if mulTableB["MinMax"]~= nil and mulTableB["MinMax"]["Max"] ~= nil and mulTableB["MinMax"]["Max"] == "*" then
				maxMul = "*"
			end
			
			if minMul ~= nil and maxMul ~= nil then
				assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Multiplicity'])"):attr("value", minMul .. ".." .. maxMul)
			elseif minMul ~= nil then
				if  mulTableA["MinMax"]~= nil and mulTableA["MinMax"]["Max"] ~= nil then 
					assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Multiplicity'])"):attr("value", minMul .. ".." .. mulTableA["MinMax"]["Max"])
				elseif mulTableA["Number"]~= nil then 
					assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Multiplicity'])"):attr("value", minMul .. ".." .. mulTableA["Number"])
				end
			elseif maxMul ~= nil then
				if mulTableA["MinMax"]~= nil and mulTableA["MinMax"]["Mix"] ~= nil then 
					assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Multiplicity'])"):attr("value",  mulTableA["MinMax"]["Mix"] .. ".." .. maxMul)
				elseif mulTableA["Number"]~= nil then 
					assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Multiplicity'])"):attr("value", mulTableA["Numbber"] .. ".." .. maxMul)
				end
			end
			
			assoc:remove_link("end", assoc:find("/end"))
			assoc:link("end", OUTAssoc:find("/end"))
			local annotations = OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])")
			-- assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment"):delete()
			utilities.copy_objects(annotations, assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])"))
			core.set_compartment_value(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment"), OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment"):attr("value"))
			core.set_compartment_value(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment:has(/compartType[id='AnnotationType'])"), OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment:has(/compartType[id='AnnotationType'])"):attr("value"))
			core.set_compartment_value(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment:has(/compartType[id='Namespace'])"), OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value"))
			core.set_compartment_value(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment:has(/compartType[id='ValueLanguage'])"), OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment:has(/compartType[id='ValueLanguage'])"):attr("value"))
			core.set_compartment_value(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment/subCompartment:has(/compartType[id='Value'])"), OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment/subCompartment:has(/compartType[id='Value'])"):attr("value"))
			core.set_compartment_value(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment/subCompartment:has(/compartType[id='Language'])"), OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])/subCompartment/subCompartment/subCompartment:has(/compartType[id='Language'])"):attr("value"))
			-- core.split_compart_value(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])"))
			-- assoc:find("/compartment:has(/compartType[id='Role'])"):link("subCompartment", annotations)
			log("New Association: name=" .. assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Name'])"):attr("value") .. " between classes: " .. OUTAssoc:find("/end/compartment:has(/compartType[id='Name'])"):attr("value") .. " and " .. assoc:find("/start/compartment:has(/compartType[id='Name'])"):attr("value"))
			core.update_compartment_input_from_value(assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Multiplicity'])"), assoc:find("/compartment:has(/compartType[id='Role'])/subCompartment/compartType[id='Multiplicity']"))
			utilities.refresh_element(assoc, diagram)

		end)
		local comment = OUTAssoc:find("/start/compartment:has(/compartType[id='Comment'])"):attr("value") .. OUTAssoc:find("/start/compartment:has(/compartType[id='ASFictitiousAnnotation'])"):attr("value")
		log("Deleted Class: name=" .. OUTAssoc:find("/start/compartment:has(/compartType[id='Name'])"):attr("value") .. ", comment=" .. comment)
		log("Deleted Association: name=" .. OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Name'])"):attr("value") .. ", comment=" .. OUTAssoc:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='ASFictitiousAnnotation'])"):attr("value"))
		OUTAssoc:find("/start"):delete()
		OUTAssoc:delete()
		
		utilities.execute_cmd("OkCmd", {graphDiagram = diagram})
	end
end

function tarnsformDataTypeNames()
	local diagram = utilities.current_diagram()
	--TypeDatatype
	diagram:find("/element:has(/elemType[id='DataType'])/compartment/subCompartment:has(/compartType[id='Name'])"):each(function(dataType)
		local dataTypeName = dataType:attr("value")
		if string.len(dataTypeName) > 12 and string.sub(dataTypeName, string.len(dataTypeName)-11) == "TypeDatatype" then
			dataType:attr("value", string.sub(dataTypeName, 1, string.len(dataTypeName)-8))
			core.update_compartment_input_from_value(dataType, dataType:find("/copartType"))
		end
	end)
	
	diagram:find("/element:has(/elemType[id='Class'])/compartment/subCompartment:has(/compartType[id='Attributes'])/subCompartment/subCompartment:has(/compartType[id='Type'])"):each(function(dataType)
		local dataTypeName = dataType:attr("value")
		if string.len(dataTypeName) > 12 and string.sub(dataTypeName, string.len(dataTypeName)-11) == "TypeDatatype" then
		    dataType:attr("value", string.sub(dataTypeName, 1, string.len(dataTypeName)-8))
			core.update_compartment_input_from_value(dataType, dataType:find("/copartType"))
		end
	end)
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='Class'])"), diagram)
	utilities.refresh_element(diagram:find("/element:has(/elemType[id='DataType'])"), diagram)
end
