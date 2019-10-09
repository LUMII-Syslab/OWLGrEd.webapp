module(..., package.seeall)

mii_rep_obj = require("mii_rep_obj")
selector_parser = require("lQuery_selector_parser")

-- --------
-- utilities
-- --------

---A generic iterator function, which can be used to seamlessly iterate over both table and arrays.
function each( object, callback, ...)
  local length = table.getn(object)
  
  for _, val in pairs(object) do
    local continue = callback(val, ...)
		if continue == false then
			break
		end
  end
  
  return object
end

---Filter items out of an array, by using a filter function.
function grep(elems, callback, inv)
  local ret = {}
  
  for i, elem in ipairs(elems) do
    if not(inv) ~= not(callback(elem, i)) then
      table.insert(ret, elem)
    end
  end
  
  return ret
end

---Translate all items in an array to another array of items.
function map(elems, callback, ...)
  local ret = {}
  
  for _, elem in ipairs(elems) do
    local value = callback(elem, ...)
    if value ~= nil then
      table.insert(ret, value)
    end
  end
  
  return ret
end

---Merge two arrays together.
function merge(first, second)
  for _, val in ipairs(second) do
    table.insert(first, val)
  end
  
  return first
end

function foldr(array, value, callback)
  for _, v in ipairs(array) do
      value = callback(value, v)
  end
  return value
end

function empty(array)
  return table.getn(array) == 0
end

function extend(...)
	local res = {}
	for _, t in ipairs({...}) do
		for key, val in pairs(t) do
			res[key] = val
		end
	end
	
	return res
end


function transitive_closure_helper(objects, expression_fn, result, visited)
  result = result or {}
  visited = visited or {}
  
  for _, o in ipairs(objects) do
    if not visited[o] then
      table.insert(result, o)
      visited[o] = true
      transitive_closure_helper(expression_fn(o), expression_fn, result, visited)
    end
  end
  
  return result
end

-- ------
-- core
-- ------

function new(expression, context)
  local lq = {}
  setmetatable(lq, lQuery.proto)
  lq.context = context or mii_rep_obj.objects
  lq.objects = {}
  if type(expression) == "string" then
    lq = lq:evalExp(expression)
  elseif getmetatable(expression) == mii_rep_obj.object.proto then
    lq.objects = {expression}
  elseif getmetatable(expression) == lQuery.proto then
    lq.objects = expression.objects
  elseif type(expression) == "number" then
    lq.objects = {mii_rep_obj.object.new(expression)}
  else -- assume array of objects
    lq.objects = expression
  end
  
  return lq
end

function set_attr_path_value(obj, path, attr_name, attr_value)
  
  if path then
    for _, obj in ipairs(new(obj):find(path).objects) do
      obj:set_property(attr_name, attr_value)
    end
  else
    obj:set_property(attr_name, attr_value)
  end
end

function get_attr_path_value(obj, attr_path, default)
  local parse_result = lQuery_selector_parser.parse_attr_selector(attr_path)
  if parse_result.path then
    obj = new(obj):find(parse_result.path).objects[1]
  end
  
  return get_attr_value(obj, parse_result.attr_name, default)
end

function get_attr_value(obj, attr_name, default)
  if obj then
    local retval = obj:get_property(attr_name)
    if retval then
      return retval
    else
      return default
    end
  else
    return default
  end
end

function attribute(selfx, v1, v2, v3)
    local self=selfx
    if type(v1) == "string" and type(v2) == "nil" then
      return get_attr_path_value(self.objects[1], v1, v3)
      
    elseif type(v1) == "table" and type(v2) == "nil" then
      for _, obj in ipairs(self.objects) do
        for key, value in pairs(v1) do
          new(obj):attr(key, value)
        end
      end
      return self
    elseif type(v1) == "string" and type(v2) == "function" then
      local parse_result = lQuery_selector_parser.parse_attr_selector(v1)
      local path = parse_result.path
      local attr_name = parse_result.attr_name
      
      for i, obj in ipairs(self.objects) do
        set_attr_path_value(obj, path, attr_name, v2(i, obj))
      end
      return self
    elseif type(v1) == "string" and getmetatable(v2) == mii_rep_obj.object.proto then
      self:link(v1, v2)
      return self
    elseif type(v1) == "string" and getmetatable(v2) == lQuery.proto then
      self:link(v1, v2)
      return self
    elseif type(v1) == "string" and type(v2) == "table" then
      for i, value in ipairs(v2) do
        self:attr(v1, value)
      end
      return self
    elseif type(v1) == "string" and type(v2) ~= "nil" then
      local parse_result = lQuery_selector_parser.parse_attr_selector(v1)
      local path = parse_result.path
      local attr_name = parse_result.attr_name
      
      for _, obj in ipairs(self.objects) do
        set_attr_path_value(obj, path, attr_name, v2)
      end
      return self
    else 
      return self
    end
end

lQuery = {}
lQuery.proto = {
	__call = function(lq, _, current_obj)
		local i = (current_obj and current_obj.i or 0) + 1
		local next_obj = lq.objects[i]
		if next_obj then
		  local res = new(next_obj) --wrap object in lQuery
			res.i = i
			return res, i
		end
	end
	
  ,evalExp = function(self, selector_string)
    local result
    if selector_string ~= "" then
      local parse_tree = selector_parser.parse(selector_string)
      
      result = eval(parse_tree, self.context)
    else
      result = self.objects
    end
    self.objects = result
    -- log(result[1])
    return self
  end
  
  -- ------
  -- private functions
  -- ------
  
  ,filter_by_type = function(self, type_name)
    return grep(self.objects, function(obj)
        return obj:has_type(type_name)
      end)
  end
  
  ,filter_by_attribute = function(self, name_or_path, value, relation)
    return grep(self.objects, function(obj)
        local attr_value = get_attr_path_value(obj, name_or_path)
        if attr_value then
          if relation then
            if relation == "=" then
              return attr_value == value
            elseif relation == "!=" then
              return attr_value ~= value
            elseif relation == "^=" then
              return not not string.find(attr_value, "^"..value)
            elseif relation == "$=" then
              return not not string.find(attr_value, value.."$")
            elseif relation == "*=" then
              return not not string.find(attr_value, value)
            else
              return true
            end
          else
            return true
          end
        else
          return false
        end
      end)
  end
  
  ,intersect_selectors = function(self, selector_array)
    local res = eval(selector_array[1], self)
    
    for i, selector in ipairs(selector_array) do
      if i ~= 1 then
        res = eval(selector, new(res, self))
      end
    end
    return res
  end
  
  ,union_selectors = function(self, selector_array)
    local res = foldr(map(selector_array, function(selector) return eval(selector, self) end),
                      {}, 
                      merge)
    return res
  end
  
  ,navigate = function(self, role_name)
    local navig_start = self.objects
    
    local navig_res = foldr(map(navig_start, function(obj) return obj:get_linked_by(role_name) end),
                            {},
                            merge)
    
    return navig_res
  end
  
	,navigate_by_inv = function(self, inv_role_name)
    local navig_start = self.objects
    
    local navig_res = foldr(map(navig_start, function(obj) return obj:get_inv_linked_by(inv_role_name) end),
                            {},
                            merge)
    
    return navig_res
  end

  ,transitive_closure = function(self, selector)
    return new(transitive_closure_helper(self.objects,
                                         function(o)
                                           return new(o):find(selector).objects
                                          end),
               self)
  end
  
  ,filter_with_function = function(self, function_name, argument_string)
    local res = {}
    
    if function_name == "first" then
      table.insert(res, self.objects[1])
    elseif function_name == "last" then
      table.insert(res, self.objects[table.getn(self.objects)])
    elseif function_name == "eq" then
      table.insert(res, self.objects[tonumber(argument_string)])
    elseif function_name == "not" then
      local parse_tree = selector_parser.parse(argument_string)
      res = grep(self.objects, function (obj)
                -- return empty(new({obj}):evalExp(argument_string).objects)
                result = eval(parse_tree, new(obj))
                return empty(result)
              end)
    elseif function_name == "has" then
      local parse_tree = selector_parser.parse(argument_string)
      res = grep(self.objects, function (obj)
                -- return empty(new({obj}):evalExp(argument_string).objects)
                result = eval(parse_tree, new(obj))
                return not empty(result)
              end)
    end
    
    return res
  end
  
  
  -- ------
  -- trait mixins, public
  -- ------
  ,mixin = function(self, traits)
    for name, trait in pairs(traits) do
      self[name] = trait
    end
    return self
  end
  
  
  -- ------
  -- Object Accessors, public
  -- ------
  ,each = function(self, fn, ...)
    each(map(self.objects, function(o)return new(o, self)end), fn, ...)
    return self
  end
  
  ,length = function(self)
    return table.getn(self.objects)
  end
  
  ,size = function(self)
    return table.getn(self.objects)
  end
  
  ,eq = function(self, position)
    return new({self.objects[position]}, self)
  end
  
	,first = function(self)
		return self:eq(1)
	end
	
	,last = function(self)
		return self:eq(self:length())
	end
	
  ,get = function(self, index)
    if index then
      return self.objects[index]
    else
      return self.objects
    end
  end
  
  ,unique = function(self)
    local results = {}
    local tmp = {}
    self:each(function(obj)
      if not tmp[obj:id()] then
        tmp[obj:id()] = true
        table.insert(results, obj:get(1))
      end
    end)
    return new(results)
  end

  ,get_position = function(self, elem)
    local elem_id

    if getmetatable(elem) == lQuery.proto then
      elem_id = elem:id()
    elseif getmetatable(elem) == mii_rep_obj.object.proto then
      elem_id = elem.id
    else
      return
    end

    for i, obj in ipairs(self.objects) do
      if obj.id == elem_id then
        return i
      end
    end
    
    return
  end
  
  -- ------
  -- traversing, public
  -- ------
  ,filter = function(self, expr, ...)
    if type(expr) == "string" then
      return new(expr, self)
    elseif type(expr) == "function" then
      local res = {}
      for o in self do
        if expr(o, ...) then
          table.insert(res, o.objects[1])
        end
      end
      return new(res, self)
    else
      return self
    end
  end
  
  ,filter_attr_value_equals = function(self, attr_name, value)
    return new(self:filter_by_attribute(attr_name, value, "="), self)
  end
  
	,filter_has_links_to_all = function(self, link_name, linked)
	  assert(type(link_name) == "string", "link name must be string")
		linked = new(linked) -- in case linked is a selector string or mii_rep object
		return self:filter(function(lq)
		                     local obj = lq.objects[1]
												 local is_linked_to_all = true
												 linked:each(function(linked_obj)
																				if not obj:exists_link(link_name, linked_obj:get(1)) then
																					is_linked_to_all = false
																					return false
																				end
																			end)
													return is_linked_to_all
											 end)
	end

	,filter_has_links_to_some = function(self, link_name, linked)
		linked = new(linked) -- in case linked is a selector string or mii_rep object
		return self:filter(function(lq)
		                     local obj = lq.objects[1]
												 local is_linked_to_some = false
												 linked:each(function(linked_obj)
																				if obj:exists_link(link_name, linked_obj:get(1)) then
																					is_linked_to_some = true
																					return false
																				end
																			end)
													return is_linked_to_some
											 end)
	end

  ,map = function(self, callback, ...)
    local res = map(map(self.objects, function(o)return new(o, self)end), callback, ...)
    -- return new(res, self)
    return res
  end
  
  -- ,not = function(self, expression)
  --   return new(grep(self.objects, expr, true), self)
  -- end
  
  ,add = function(self, expression)
    local addition = new(expression)
    return new(merge(merge({}, self.objects), addition.objects), self)
  end
  
  ,remove = function(self, expression)
    local objects_to_remove = (type(expression) == "string") and self:find(expression) or new(expression)
    
    local results = {}
    local tmp = {}

    objects_to_remove:each(function(obj)
      tmp[obj:id()] = true
    end)
    
    self:each(function(obj)
      if not tmp[obj:id()] then
        table.insert(results, obj:get(1))
      end
    end)

    return new(results, self)
  end

  ,find = function(self, selector)
    return new(selector, self)
  end
  
  ,back = function(self)
		return self.checkpoint or self.context
	end
	
	,set_checkpoint = function(self, lq)
		self.checkpoint = lq
		return self
	end
	
  -- ------
  -- manipulation, public
  -- ------
  ,link = function(self, v1, v2, after)
    if type(v1) == "string" and type(v2) == "nil" then
      return new(self.objects[1]:get_linked_by(v1), self)
    else
      local object_after_which_to_insert = nil
      if after then
			  object_after_which_to_insert = new(after, self):last():get(1)
      end
      
	    if type(v1) == "string" and getmetatable(v2) == mii_rep_obj.object.proto then
	      for _, obj in ipairs(self.objects) do
	        obj:add_link(v1, v2, object_after_which_to_insert)
	      end
	    elseif type(v1) == "string" and getmetatable(v2) == lQuery.proto then
	      for _, start_obj in ipairs(self.objects) do
	        for _, end_obj in ipairs(v2.objects) do
	          start_obj:add_link(v1, end_obj, object_after_which_to_insert)
	        end
	      end
	    elseif type(v1) == "string" and type(v2) == "table" then
	      for _, start_obj in ipairs(self.objects) do
	        for _, end_obj in ipairs(v2) do
	          new(start_obj):link(v1, end_obj, object_after_which_to_insert)
	        end
	      end
	    elseif type(v1) == "string" and type(v2) == "function" then
	      for i, obj in ipairs(self.objects) do
	        new(obj):link(v1, v2(i, obj), object_after_which_to_insert)
	      end
	    elseif type(v1) == "table" and type(v2) == "nil" then
	      for key, v in pairs(v1) do
	        self:link(key, v, object_after_which_to_insert)
	      end
	    end
		end
    return self
  end

  ,remove_link = function(self, link_name, v)
    if type(v) == "nil" or getmetatable(v) == mii_rep_obj.object.proto then
      for _, obj in ipairs(self.objects) do
        obj:remove_link(link_name, v)
      end
    elseif getmetatable(v) == lQuery.proto then
      for _, start_obj in ipairs(self.objects) do
        for _, end_obj in ipairs(v.objects) do
          start_obj:remove_link(link_name, end_obj)
        end
      end
    elseif type(v) == "table" then
      for _, start_obj in ipairs(self.objects) do
        for _, end_obj in ipairs(v) do
          start_obj:remove_link(link_name, end_obj)
        end
      end
    end
    
    return self
  end
  
  ,delete = function(self)
    for _, obj in ipairs(self.objects) do
      obj:delete()
    end
    
    -- TODO is there a way to ensure that it is deleted in all other collections?
    self.objects = {}

    return nil
  end
  
  ,sort_linked = function(self, link_name, f)
    local linked = self:link(link_name)
    self:remove_link(link_name, linked)
    table.sort(linked.objects, f)
    self:link(link_name, linked)
    return self
  end
  -- ------
  -- attributes, public
  -- ------
  ,attr = function (self, v1, v2) return attribute(self, v1, v2, nil) end
  ,attr_e = function (self, v1, v2) return attribute(self, v1, v2, "") end

  -- ------
  -- tests, public
  -- ------
  ,is_empty = function(self)
    return table.getn(self.objects) == 0
  end

	,is_not_empty = function(self)
    return not self:is_empty()
  end
	
  -- ------
  -- combinators, public
  -- ------

	-- returns the result of the function.
	-- This is useful for making your own jQuery methods like filters or traverses
	,into = function(self, fn, ...)
    return fn(self, ...)
  end

	-- executes the function for side effects,
	-- then returns the original selection.
	-- This is useful for making your own jQuery methods that "chain" fluently
	,tap = function(self, fn, ...)
		fn(self, ...)
		
		return self
	end

	-- always return the selection.
	-- It will execute the function if the selection is not empty.
	-- This is useful for eliminating selection checks in method
	,ergo = function(self, fn, ...)
		if self:is_not_empty() then
			fn(self, ...)
		end
		
		return self
	end

  -- ------
  -- msc, public
  -- ------
  ,copy_attrs_from = function(self, source_elem)
    local result = {}
    local class = source_elem:get(1):class()
    local class_property_list = class:property_list()
    for _, property_name in ipairs(class_property_list) do
    	local value = source_elem:attr(property_name)
    	if value ~= "" then
    		result[property_name] = value
    	end
    end
    self:attr(result)
    return self
  end

  ,assert_not_empty = function(self, message)
    message = message or "assertion failed, lQuery is empty!"
    if self:is_empty() then
      error(message, 2)
    end
    return self
  end
  
  ,to_s = function(self, attr_list)
    local max_name_length = foldr(attr_list, 0, 
                                function(max, attr_name)
                                  local current_len = attr_name:len()
                                  if current_len > max then return current_len
                                  else return max
                                  end
                                end)
    
    local decorated_name_list = {}
    for i, name in ipairs(attr_list) do
      decorated_name_list[name] = string.rep(" ", max_name_length - name:len()) .. name
    end
    
    local s = table.concat(map(self.objects, 
      function(obj) 
        if mii_rep_obj.exists_object_with_repo_id(obj.id) then
          return obj:class().name .. " : " .. obj.id .. "\n" .. table.concat(map(attr_list, 
            function(attr_name) 
              local prop_value = get_attr_path_value(obj, attr_name, "")
              if prop_value ~= nil then
                return decorated_name_list[attr_name] .. " = " ..  prop_value
              else
                return ""
              end
            end), "\n\n")
        else
          return "! object " .. obj.id .. " missing"
        end
      end), "\n\n")
    local dimension_name = (self:size() == 1) and " instance" or " instances"
    return s .. "\n---\n" .. self:size() .. dimension_name .. "\n---\n"
  end
  
  ,log = function(self, attr_list, ...)
    attr_list = attr_list or {}
		if type(attr_list) ~= "table" then
			local first_key = nil
			first_key, attr_list = attr_list, {...}
			
			table.insert(attr_list, first_key)
		end

   	log(self:to_s(attr_list))

    return self
  end
  
  ,id = function(self)
    local first_obj = self:get(1)
    if first_obj then
      return first_obj.id
    else
      return nil
    end
  end
}
lQuery.proto.__index = function(self, key)
  if key == "checkpoint" then
    return nil
  elseif lQuery.proto[key] then
    return lQuery.proto[key]
  else
    local inherited = self.context[key]
    self[key] = inherited
    return inherited
  end
end

lQuery.proto.__tostring = function(self)
  return string.format("<lQuery collection with %d object(-s)>", self:size())
end

function eval (parse_tree, context)
  -- log(dumptable(parse_tree))
  local result = {}
  local function_name, arg = parse_tree.function_name, parse_tree.arg

  if function_name == "filter_by_type" then
    if not arg.any_type then
      result = context.filter_by_type(context, arg.type_name)
    else
      result = context
    end
  elseif function_name == "filter_by_attribute" then
    result = context.filter_by_attribute(context, arg.attr_name or arg.attr_path, arg.value, arg.relation)
  elseif function_name == "navigate" then
    result = context.navigate(context, arg.role_name)
	elseif function_name == "inv_navigate" then
	  result = context.navigate_by_inv(context, arg.role_name)
  elseif function_name == "intersect_selectors" then
    result = context.intersect_selectors(context, arg)
  elseif function_name == "union_selectors" then
    result = context.union_selectors(context, arg)
  elseif function_name == "filter_with_function" then
    result = context.filter_with_function(context, arg.function_name, arg.argument_string)
  else
    log("unimplemented selector", function_name)
    result = context
  end
  
  return result
end

function create (class_name, properties)
  return new(mii_rep_obj.create_object(class_name)):attr(properties)
end


lib = {
  each    = each
  ,grep   = grep
  ,map    = map
  ,merge  = merge
  ,foldr  = foldr
  ,extend  = extend

  ,new    = new
  ,create = create

  ,empty  = function() return new({}) end -- returns lQuery collection with no elements
  
  ,eval   = eval

	,model 	= {
		add_class = mii_rep_obj.add_class
		,set_super_class = mii_rep_obj.set_super_class
		,add_property = mii_rep_obj.add_property
		,add_link = mii_rep_obj.add_link
		,add_composition = mii_rep_obj.add_composition
		,property_list = function(class_name) return mii_rep_obj.class.create(class_name):property_list() end
		,link_list = function(class_name) return mii_rep_obj.class.create(class_name):link_list() end
		
		,has_link = function(class_name, link_name, optional_target_class_name)
		              return mii_rep_obj.class.create(class_name):has_link(link_name, optional_target_class_name)
		            end
		,has_property = function(class_name, property_name)
		                  return mii_rep_obj.class.create(class_name):has_property(property_name)
		                end
		
		,delete_class = mii_rep_obj.delete_class --class_name
		,remove_super_class = mii_rep_obj.remove_super_class --class_name
		,delete_property = mii_rep_obj.delete_property --class_name, property_name
		,delete_link = mii_rep_obj.delete_link --class_name, outgoing_link_name
		,class_exists = mii_rep_obj.class_exists --class_name, outgoing_link_name
	}
	
	,exists_object_with_repo_id = mii_rep_obj.exists_object_with_repo_id
	,not_exists_object_with_repo_id = function(repo_id) return not mii_rep_obj.exists_object_with_repo_id(repo_id) end
}

setmetatable(lib, {__call = function(_, ...) return new(...) end})
return lib


