module(..., package.seeall)

require("mii_rep_obj")

-- object - lQuery collection with object to serialise
-- properties - list of property names to include or "*" to include all
-- links - list of link names to include or "*" to include all
function object_to_table(object, properties, links, context_paths)
	local class = object:get(1):class()
	local result = {
										class_name = class.name,
										rep_id = object:id(),
										-- properties = {},
										-- links = {},
									}
	for _, v in ipairs(class:property_list()) do
    if (properties == "*") or (type(properties) == "table") and properties[v] then
			if not result.properties then result.properties = {} end
			result.properties[v] = object:attr(v)
		end
  end
	
	for _, v in ipairs(class:link_list()) do
    if (links == "*") or (type(links) == "table") and links[v] then
			if not result.links then result.links = {} end
			local linked = object:link(v):map(object_to_table, properties, {}, context_paths)
			if #linked == 1 then
				result.links[v] = linked[1]
			elseif #linked > 1 then
				result.links[v] = linked
			end
		end
  end
		
	for class_name, paths in pairs(context_paths or {}) do
		if class:is_subtype_of(mii_rep_obj.class_by_name(class_name)) then
			for _, path in ipairs(paths) do
				if not result.context then result.context = {} end
				local path_result = object:find(path)
				if getmetatable(path_result) then path_result = object_to_table(path_result, properties, {}, context_paths) end
				result.context[path] = path_result
			end
		end
	end
	
	return result
end

function log_event_and_command(event_or_command)
	local event_or_command = lQuery(event_or_command)

	--print(dumptable(object_to_table(event_or_command)))
end
