module(..., package.seeall)

local json = require("reporter.dkjson")

require("mii_rep_obj")



function get_selection_classes(lQuery_selection)
  local classes = {}
  local tmp = {}
  lQuery_selection:each(function(obj)
		obj = obj:get(1)
    local class = obj:class()
    if not tmp[class.id] then
      tmp[class.id] = true
      table.insert(classes, class)
    end
  end)
  return classes
end

function property_type_name_list(lQuery_selection)
  local results = {}
  local tmp = {}
  local classes = get_selection_classes(lQuery_selection)
  
  lQuery.each(classes, function(class)
    for _, property_name in ipairs(class:property_list()) do
      if not tmp[property_name] then
        tmp[property_name] = true
        table.insert(results, property_name)
      end
    end
  end)
  
  table.sort(results)
  
  return results
end

function class_name_list(lQuery_selection)
  local results = {}
  local tmp = {}
  local classes = get_selection_classes(lQuery_selection)
  
  lQuery.each(classes, function(class)
    if not tmp[class.name] then
      tmp[class.name] = true
      table.insert(results, class.name)
    end
  end)
  
  table.sort(results)
  
  return results
end

function link_type_name_list(lQuery_selection)
  local results = {}
  local tmp = {}
  local classes = get_selection_classes(lQuery_selection)
  
  lQuery.each(classes, function(class)
    for _, link_name in ipairs(class:link_list()) do
      if not tmp[link_name] then
        tmp[link_name] = true
        table.insert(results, link_name)
      end
    end
  end)
  
  table.sort(results)
  
  return results
end

function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
    function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

local merge_function = {
  union = function(lQuery_selection_array)
    local tmp = {}
    local results = {}
    lQuery.each(lQuery_selection_array, function(lQuery_selection)
      lQuery_selection:each(function(obj)
				obj = obj:get(1)
        if not tmp[obj.id] then
          tmp[obj.id] = true
          table.insert(results, obj)
        end
      end)
    end)
    return lQuery(results)
  end
  
  ,intersection = function(lQuery_selection_array)
    local tmp = {}
    local results = {}
    
    local tmp_array = lQuery.map(lQuery_selection_array, function(lQuery_selection)
      local tmp = {}
      lQuery_selection:each(function(_, obj)
        tmp[obj.id] = true
      end)
      return tmp
    end)
    
    lQuery.each(lQuery_selection_array, function(_, lQuery_selection)
      lQuery_selection:each(function(_, obj)
        local present_in_all = true
        for _, t in pairs(tmp_array) do
          if not t[obj.id] then
            present_in_all = false
            break
          end
        end
      
        if present_in_all and not tmp[obj.id] then
          tmp[obj.id] = true
          table.insert(results, obj)
        end
      end)
    end)
    return lQuery(results)
  end
}


function sleep(sec)
	require "socket"
    socket.select(nil, nil, sec)
end

function get_ids(query)
  local contexts = query.contexts
  local filter = query.filter
  local merge_fn_name = query.merge_fn_name or "union"
  
  
  local selection 
  if contexts then
    local selections = lQuery.map(contexts, function(context)
      local repo_objects = lQuery.map(context.context_ids, function(id) return mii_rep_obj.object.new(id) end)
      return lQuery(repo_objects):find(context.selector)
    end)
    local merged_selection = merge_function[merge_fn_name](selections)
    if filter and filter ~= "" then
      selection = merged_selection:filter(filter)
    else
      selection = merged_selection
    end
  else
    selection = lQuery(filter)
  end
	
  local result_table = {
    guid = math.random(1000)
    ,objects = selection:map(function(obj) 
                                 local prop_table = obj:get(1):get_property_table()
                                 prop_table["__mii_rep_id"] = obj:id() -- a hack, but I don't know how to do it better
                                 return prop_table
                               end)
    ,queryResultItems = selection:map(function(obj) return obj:id() end)
    ,queryResultTypes = class_name_list(selection)
    ,queryResultItemProperties = property_type_name_list(selection)
    ,queryResultItemOutgoingLinks = link_type_name_list(selection)
    ,resultItemCount = selection:length()
    ,is_empty = selection:is_empty()
  }
  -- log("answer", dumptable(result_table))
  
  return result_table
end


function get_values_of_paths(object_id, paths)
  local lq = lQuery(object_id)
  
  local results = {}
  for attr_field, attr_path in ipairs(paths) do
    results[attr_field] = lq:find(attr_path)
  end
  
  return results
end

function get_attr_values(query)
  local object_ids = query.object_ids or {}
  local attr_paths = query.attr_paths or {}
  
  local result_table = {
    attr_values = lQuery.map(object_ids, get_values_of_paths, attr_paths)
  }
  -- log("answer", dumptable(result_table))
  
  return result_table
end



local query_dispatch_table = {
  get_ids = get_ids,
  get_attr_values = get_attr_values
}

function handler(req, res)
	log("** lQuery **")
    -- sleep(math.random(2))
    local query_str = string.sub(url_decode(res.req.parsed_url.query), 2) -- sub to remove starting &
    -- log("raw", dumptable(req))
    local query = json.decode(query_str)
    
    -- log("query", dumptable(query))
    
    local query_type = query.type or "get_ids"
    
    local raw_query_results = query_dispatch_table[query_type](query)
    -- log("--raw results", raw_query_results)

    -- log(dumptable(raw_query_results))

    res.content = json.encode(raw_query_results)
end