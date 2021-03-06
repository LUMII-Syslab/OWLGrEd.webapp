module("mii_rep_obj", package.seeall)

raapi = require("lua_raapi")


lQuery = require "lQuery"

local class_cache = {} -- cache for classes
setmetatable(class_cache, {__mode = "v"})

local object_cache = {} -- cache for objects
setmetatable(object_cache, {__mode = "v"})

objects = {}
function objects.filter_by_type(_, type_name)
  local cl = class_by_name(type_name)
  return cl:objects()
end

function objects.filter_by_attribute(_, name, value, relation)
  local classes = class_list()
  local results, result_count = {}, 0
  
  for _, cl in ipairs(classes) do
    if cl:has_property(name) then

      local it = raapi.getIteratorForAllClassObjects(cl.id)
      local obj = raapi.resolveIteratorFirst(it)
      while (obj) do

        if relation then -- paarbaude uz veertiibu
          if obj:get_property(name) == value then
            result_count = result_count + 1
            results[result_count] = obj
          end
        else
          result_count = result_count + 1
          results[result_count] = obj
        end

        obj = raapi.resolveIteratorNext(it)
      end
      raapi.freeIterator(it)

    end
  end
  -- log(result_count)
  return results
end

function objects.navigate(self, role_name)
  local navig_start = {}
  

  local classes = class_list()
  local result_count = 0
  
  for _, cl in ipairs(classes) do
    if cl:has_link(role_name) then

      local it = raapi.getIteratorForAllClassObjects(cl.id)
      local r = raapi.resolveIteratorFirst(it)
      while (r~=0) do
        local obj = object.new(r)
        local linked_objects = obj:get_linked_by(role_name)
        for j, o in ipairs(linked_objects) do
          result_count = result_count + 1
          navig_start[result_count] = obj
        end

        r = raapi.resolveIteratorNext(it)
      end
      raapi.freeIterator(it)

    end
  end

  
  local navig_res = lQuery.foldr(lQuery.map(navig_start, function(obj) return obj:get_linked_by(role_name) end),
                                {},
                                lQuery.merge)
  
  return navig_res
end

function objects.intersect_selectors(selfx, selector_array)
  local self=selfx
  local results = lQuery.eval(selector_array[1], self)
  
  for i, selector in ipairs(selector_array) do
    if i ~= 1 then
      results = lQuery.eval(selector, lQuery.new(results, self))
    end
  end
  return results
end

function objects.union_selectors(selfx, selector_array)
  local self=selfx
  local res = lQuery.foldr(lQuery.map(selector_array, function(selector) return lQuery.eval(selector, self) end),
                          {},
                          lQuery.merge)
  return res
end

function objects.filter_with_function(self, arg)
  local res = {}
  return res
end


function class_by_name(name)
  local id = raapi.findClass(name)
  assert(id ~= 0, "there is no class " .. name)
  return class.new(id)
end

local class_list_mt = {
  __tostring = function(list)
    local name_list = {}
    for i, class in ipairs(list) do
      name_list[i] = class.name
    end
    return table.concat(name_list, ", ") 
  end
}

function class_list (abbrev)
  local class_list = {}

  local it = raapi.getIteratorForClasses()
  local r = raapi.resolveIteratorFirst(it)
  while (r~=0) do
    table.insert(class_list, class.new(r))
    r = raapi.resolveIteratorNext(it)
  end
  raapi.freeIterator(it)
  
  setmetatable(class_list, class_list_mt)
  
  return class_list
end

class = {}
class.proto = {
  objects = function(selfx)
    local self=selfx
    local objects = {}

    local it = raapi.getIteratorForAllClassObjects(self.id)
    local r = raapi.resolveIteratorFirst(it)
    local i = 0
    while (r~=0) do
      i = i+1
      objects[i] = object.new(r)
      r = raapi.resolveIteratorNext(it)
    end
    raapi.freeIterator(it)

    
    return objects
  end
  
  ,first_object_id_with_attr_val = function(selfx, property_name, value)
    local self=selfx
    local property_id = self:property_id_by_name(property_name)
    local it = raapi.getIteratorForObjectsByAttributeValue(property_id, value)
    local r = raapi.resolveIteratorFirst(it)
    raapi.freeIterator(it)
    return r
  end

  ,has_property = function(selfx, property_name)
    local self = selfx
    if self.properties[property_name] then
      return true
    else
      return raapi.findAttribute(self.id, property_name) ~= 0
    end
  end
  
  ,property_id_by_name = function(selfx, property_name)
    local self=selfx
    if self.properties[property_name] then
      return self.properties[property_name]
    else
      local property_type_id = raapi.findAttribute(self.id, property_name)
      assert(property_type_id ~= 0, tostring(self.name) .. " doesn't have a property " .. property_name)
      self.properties[property_name] = property_type_id
      return property_type_id
    end
  end
  
  ,has_link = function(selfx, link_name, target_class_name)
    local self=selfx
    local result = false
    local link_type_id = 0
    
    if self.links[link_name] then
      link_type_id = self.links[link_name]
      result = true
    else
      link_type_id = raapi.findAssociationEnd(self.id, link_name)
      result = (link_type_id ~= 0)
    end
    
    -- TODO if speed problems, consider adding cache for link to target class existence
    if result == true and target_class_name then
--      local target_class = class.new(mii_rep.GetLinkTypeAttributes(link_type_id).object_type_id)
      local target_class = class.new(raapi.getTargetClass(link_type_id))
      result = class.create(target_class_name):is_subtype_of(target_class)
    end
    
    return result
  end
  
  ,link_id_by_name = function(selfx, link_name)
    local self=selfx
    if self.links[link_name] then
      return self.links[link_name]
    else
      local link_type_id = raapi.findAssociationEnd(self.id, link_name)
      assert(link_type_id ~= 0, tostring(self.name) .. " doesn't have a link " .. link_name)
      self.links[link_name] = link_type_id
      return link_type_id
    end
  end
  
  ,property_list = function(selfx)
    local self=selfx

    local property_name_list = {}
    setmetatable(property_name_list, {__tostring = function(list) return table.concat(list, ", ") end})

    local it = raapi.getIteratorForAllAttributes(self.id)
    local r = raapi.resolveIteratorFirst(it)
    local i = 0
    while (r~=0) do
      i = i+1
print("EXC1 ",r)
print("EXC2 ",raapi.getAttributeName(r))
      property_name_list[i] = raapi.getAttributeName(r)
      r = raapi.resolveIteratorNext(it)
    end
    raapi.freeIterator(it)

    return property_name_list
  end
  
	,link_list = function(selfx)
	  local self=selfx
	  local link_name_list = {}
	  setmetatable(link_name_list, {__tostring = function(list) return table.concat(list, ", ") end})

          local it = raapi.getIteratorForAllOutgoingAssociationEnds(self.id)
          local r = raapi.resolveIteratorFirst(it)
          local i = 0
          while (r~=0) do
            i = i+1
            link_name_list[i] = raapi.getRoleName(r)
            r = raapi.resolveIteratorNext(it)
          end
          raapi.freeIterator(it)


	  return link_name_list
	end

  ,is_subtype_of = function(selfx, supertype)
    local self=selfx
    return (self.id == supertype.id) or raapi.isDerivedClass(self.id, supertype.id)
  end
  
  ,reset_link_cache = function(selfx)
    local self=selfx
    self.links = {}

    local it = raapi.getIteratorForDirectSubClasses(self.id)
    local subclass_id = raapi.resolveIteratorFirst(it)
    while (subclass_id~=0) do
      class.new(subclass_id):reset_link_cache()
      subclass_id = raapi.resolveIteratorNext(it)
    end
    raapi.freeIterator(it)
  end
  
  ,reset_property_cache = function(selfx)
    local self=selfx
    self.properties = {}

    local it = raapi.getIteratorForDirectSubClasses(self.id)
    local subclass_id = raapi.resolveIteratorFirst(it)
    while (subclass_id~=0) do
      class.new(subclass_id):reset_property_cache()
      subclass_id = raapi.resolveIteratorNext(it)
    end
    raapi.freeIterator(it)
  end
}

class.proto.__index = class.proto
class.new = function(id)
  if class_cache[id] then
    return class_cache[id]
  else
if (id==0) then
print("CLASSNAME mii_rep_obj")
print(id)
		local traceback = debug.traceback()
		print("TRACE0:\n", traceback)
end
    local type_name = raapi.getClassName(id)
--print(type_name)
    assert(type_name ~= "", "class with id " .. id .. " doesn't exist")

    local cl = {}
    cl.id = id
    cl.name = type_name
    cl.properties = {}
    cl.links = {}
    setmetatable(cl, class.proto)
  
    class_cache[id] = cl
    return class_cache[id]
  end
end

class.create = function(class_name)
  local class_id = raapi.findClass(class_name)
  if  class_id == 0 then
    class_id = raapi.createClass(class_name)
  end
  return class.new(class_id)
end

local function construct_memoized_fn(fn)
  local cache = {}
  setmetatable(cache, {__mode = "v"})
  return function(o)
    if cache[o] then
      return cache[o]
    else
      local v = fn(o)
      cache[o] = v
      return v
    end
  end
end

object = {}
object.proto = {
  class = construct_memoized_fn(function(selfx)
    local self=selfx
    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = raapi.resolveIteratorFirst(it)
    raapi.freeIterator(it)
    return class.new(r)
  end)
  
  ,get_property = function(selfx, property_name)
    local self = selfx
    local value

    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end
    
--    if mii_rep.ObjectExists(self.id) and self:class():has_property(property_name) then
--      local property_type_id = self:class():property_id_by_name(property_name)
--      value = mii_rep.GetPropertyValue(self.id, property_type_id)
--    end

    if (r~=0) and self:class():has_property(property_name) then
      local property_type_id = self:class():property_id_by_name(property_name)
      value = raapi.getAttributeValue(self.id, property_type_id)
      -- by SK: MII_REP simulation: return "" for non-existing string values
      if (raapi.getAttributeType(property_type_id) == raapi.findPrimitiveDataType("String"))
        and (value == nil) then
          value = ""
      end  
    end
    
    return value
  end
  
  ,set_property = function(selfx, property_name, property_value)
    local self=selfx

    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end

    if (r~=0) then
      if not self:class():has_property(property_name) then
        -- create property type if it does not exist
        property_type_id = raapi.createAttribute(r, property_name, raapi.findPrimitiveDataType("String"))
        assert(property_type_id ~= 0, tostring(self.id) .. " failed to create a property " .. property_name)
      end
      local property_type_id =  self:class():property_id_by_name(property_name)
      raapi.setAttributeValue(self.id, property_type_id, tostring(property_value))
    end
    return self
  end
  
  ,get_linked_by = function(selfx, link_name)
    local self=selfx

    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end

    if (r~=0) then
      if not self:class():has_link(link_name) then
        return {}
      else
        local link_type_id = self:class():link_id_by_name(link_name)
      
        it = raapi.getIteratorForLinkedObjects(self.id, link_type_id)
        local linked_objects = {}
        r = raapi.resolveIteratorFirst(it)
        local i = 0
        while (r~=0) do
          i = i+1
          linked_objects[i] = object.new(r)
          r = raapi.resolveIteratorNext(it)
        end
        raapi.freeIterator(it)
      
        return linked_objects
      end
    else
      return {}
    end
  end
  
	,get_inv_linked_by = function(selfx, inv_link_name)
	        local self=selfx
		local results = {}

    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end

    if (r~=0) then

  		local obj_class = self:class()

  		it = raapi.getIteratorForAllOutgoingAssociationEnds(obj_class.id)
  		local link_type_id = raapi.resolveIteratorFirst(it)
  		while (link_type_id) do
		  local inv_link_type_id = raapi.getInverseAssociationEnd(link_type_id)
  		  local inv_link_type_name = raapi.getRoleName(inv_link_type_id)

  			if (inv_link_name == inv_link_type_name) then
  			        local it2 = raapi.getIteratorForLinkedObjects(self.id, link_type_id)
  			        local r2 = raapi.resolveIteratorFirst(it2)
  			        while (r2~=0) do  	      
  				  table.insert(results, object.new(r2))
  				  r2 = raapi.resolveIteratorNext(it2)
	  	                end
	  	                raapi.freeIterator(it2)
  			end

  		  link_type_id = raapi.resolveIteratorNext(it)
  		end
  		raapi.freeIterator(it)
    end
    
    return results
  end

  ,add_link = function(selfx, link_name, obj, after_obj)
    local self=selfx
    -- NOTE if speed problems you can add extra cache in has_link
    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end

    if (r~=0) and self:class():has_link(link_name, obj:class().name) then

      local link_type_id = self:class():link_id_by_name(link_name)
      
  		if after_obj and self:exists_link(link_name, after_obj) then
  			local currently_linked = self:get_linked_by(link_name)
  			
  			for _, o in ipairs(currently_linked) do
  			   raapi.deleteLink(self.id, o.id, link_type_id)
  			end

  			for _, o in ipairs(currently_linked) do
  				raapi.createLink(self.id, o.id, link_type_id)
  				if after_obj == o then
  					raapi.createLink(self.id, obj.id, link_type_id)
  				end
  			end
  		else
  			raapi.createLink(self.id, obj.id, link_type_id)
  		end
    end

    return self
  end
	
	,exists_link = function(selfx, link_name, obj)
    local self=selfx
    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end

    if (r~=0) and self:class():has_link(link_name) then
  		local link_type_id = self:class():link_id_by_name(link_name)
  		return raapi.linkExists(self.id, obj.id, link_type_id)
    else
      return false
    end
	end
  
  ,remove_link = function(selfx, link_name, obj)
    local self=selfx
    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end
    if (r~=0) then
      local link_type_id = self:class():link_id_by_name(link_name)
      
      if obj then
        obj_id = obj.id
      else
        obj_id = 0
      end
      
      raapi.deleteLink(self.id, obj_id, link_type_id)
    end

    return self
  end
  
  ,has_type = function (selfx, type_name)
    local self=selfx
    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end
    if (r~=0) then
      return self:class():is_subtype_of(class_by_name(type_name))
    else
      return false
    end
  end
  
  ,delete = function (selfx)
    local self=selfx
    object_cache[self.id] = nil -- delete object from cache
    raapi.deleteObject(self.id)
  end

	,attr = function (selfx, attr_name)
    local self=selfx
    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end
    if (r~=0) then
		  return lQuery.new(self):attr(attr_name)
    end
	end
	
	,get_property_table = function(selfx)
    local self=selfx
    local result = {}
    local it = raapi.getIteratorForDirectObjectClasses(self.id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end

    if (r~=0) then
      local class = self:class()
      local class_property_list = class:property_list()
      for _, property_name in ipairs(class_property_list) do
        local value = self:get_property(property_name)
        if value ~= "" then
          result[property_name] = value
        end
      end
    end

    return result
  end

  ,property_key_val_pairs = function(selfx)
    local self=selfx
    return coroutine.wrap(function ()
      local property_list = {}
      local it = raapi.getIteratorForDirectObjectClasses(self.id)
      local r = 0
      if it ~= 0 then
        r = raapi.resolveIteratorFirst(it)
        raapi.freeIterator(it)
      end

      if (r~=0) then property_list = self:class():property_list() end
      for _, property_name in ipairs(property_list) do
        coroutine.yield(property_name, self:get_property(property_name) or "")
      end
    end)
  end
}
object.proto.__index = function(selfx, index)
        local self=selfx
	if object.proto[index] then
		return object.proto[index]
	end

	local obj_wrapped_in_lQuery = lQuery.new(self)
	local tmp_lQuery_proto_fn = obj_wrapped_in_lQuery[index]
	if tmp_lQuery_proto_fn then
		return function(_, ...)
			return tmp_lQuery_proto_fn(obj_wrapped_in_lQuery, ...)
		end
	end
end
object.new = function(id)
  if object_cache[id] then
    return object_cache[id]
  else
    local it = raapi.getIteratorForDirectObjectClasses(id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end

    if (r==0) then
		local traceback = debug.traceback()
		print("ERROR r==0", traceback)
    end
    assert(r~=0, "object " .. id .. " doesn't exist" .. r .. " "..it)
    local obj = {}
    obj.id = id
  
    setmetatable(obj, object.proto)
    object_cache[id] = obj
    return object_cache[id]
  end
end

function exists_object_with_repo_id (repo_id)
    local it = raapi.getIteratorForDirectObjectClasses(repo_id)
    local r = 0
    if it ~= 0 then
      r = raapi.resolveIteratorFirst(it)
      raapi.freeIterator(it)
    end

  return r~=0
end

function create_object (class_name)
  local class_id = raapi.findClass(class_name)
  assert(class_id ~= 0, "class " .. class_name .. " dosn't exists")
  return object.new(raapi.createObject(class_id))
end


-- functions for creating types
function add_class(class_name)
	local class_id = raapi.findClass(class_name)
	if class_id == 0 then
		class_id = raapi.createClass(class_name)
	end
	assert(class_id ~= 0, "couldnt't create class " .. class_name)
end

function table_to_occurence_table(t)
  local result = {}
  for k, v in pairs(t) do
    result[v] = true
  end
  return result
end

function get_direct_link_type_ids(type_id)
  local results = {}

  local it = raapi.getIteratorForDirectOutgoingAssociationEnds(type_id)
  local r = raapi.resolveIteratorFirst(it)
  while (r~=0) do
    table.insert(results, r)

    r = raapi.resolveIteratorNext(it)
  end
  raapi.freeIterator(it)

  return results
end

function delete_direct_link_types(type_id)
  local link_type_ids = get_direct_link_type_ids(type_id)
  
  for _, link_type_id in ipairs(link_type_ids) do
    local status = raapi.deleteAssociation(link_type_id)
    log("-----", status)
    -- assert(status ~= 0, "failed to delete link type " .. link_type_id .. " : " .. mii_rep.GetTypeName(link_type_id))
    -- status = mii_rep.DeleteLinkType(mii_rep.GetInverseLinkTypeId(link_type_id))
    -- assert(status == 0, "failed to delete inverse link type " .. link_type_id)
  end
end

function delete_instances(type_id)
  local objects = class.new(type_id):objects()
  for _, o in ipairs(objects) do
    o:delete()
  end
end

function delete_class(class_name, with_subclasses)
  local class_id = raapi.findClass(class_name)
	if class_id ~= 0 then
	  local function delete_type_with_subtypes(type_id)
			if with_subclasses then
			   local it = raapi.getIteratorForDirectSubClasses(type_id)
			   local r = raapi.resolveIteratorFirst(it)
			   while (r~=0) do
 	                     delete_type_with_subtypes(r)
			     r = raapi.resolveIteratorNext(it)
			   end
			   raapi.freeIterator(it)
			else
			   local it = raapi.getIteratorForDirectSubClasses(type_id)
			   local r = raapi.resolveIteratorFirst(it)
			   while (r~=0) do
	                     remove_super_class(raapi.getClassName(r))
			     r = raapi.resolveIteratorNext(it)
			   end
			   raapi.freeIterator(it)
			end
		
			delete_instances(type_id)
			delete_direct_link_types(type_id)
      
			status = raapi.deleteClass(type_id)
			assert(status ~= 0, "couldnt't delete class " .. class_name)
      
			class_cache[type_id] = nil
		end
    
    delete_type_with_subtypes(class_id)
	end
end

function set_super_class(class_name, super_class_name)
	local class_id = raapi.findClass(class_name)
	assert(class_id ~= 0, "class " .. class_name .. " dosn't exists")
	
	local super_class_id = raapi.findClass(super_class_name)
	assert(super_class_id ~= 0, "class " .. super_class_name .. " dosn't exists")

        local it = raapi.getIteratorForDirectSuperClasses(class_id)
        local r = raapi.resolveIteratorFirst(it)
        while (r~=0) do
          raapi.deleteGeneralization(class_id, r)
          r = raapi.resolveIteratorNext(it)
        end
        raapi.freeIterator(it)

        raapi.createGeneraliation(class_id, super_class_id)
end

function remove_super_class(class_name)
	local class_id = raapi.findClass(class_name)
	assert(class_id ~= 0, "class " .. class_name .. " dosn't exists")

        local it = raapi.getIteratorForDirectSuperClasses(class_id)
        local r = raapi.resolveIteratorFirst(it)
        while (r~=0) do
          raapi.deleteGeneralization(class_id, r)
          r = raapi.resolveIteratorNext(it)
        end
        raapi.freeIterator(it)	
end

property_base_type = {
        string = 0,
       integer = 1,
         float = 2,
       boolean = 3,
    hyper_text = 4,
     date_time = 5,
    expression = 6,
   enumeration = 7,
  resource_ref = 99
}

function add_property(class_name, property_name, property_type)
  property_type = property_type or property_base_type.string
	local class_id = raapi.findClass(class_name)
	assert(class_id ~= 0, "class " .. class_name .. " dosn't exists")
	local property_type_id = raapi.findAttribute(class_id, property_name)
	if property_type_id == 0 then
		-- create property type if it does not exist
		local base_type_name = "String"
		if (property_type == 1) then base_type_name = "Integer" end
		if (property_type == 2) then base_type_name = "Float" end
		if (property_type == 3) then base_type_name = "Boolean" end
		local base_type_id = raapi.findPrimitiveDataType(base_type_name)
		property_type_id = raapi.createAttribute(class_id, property_name, base_type_id)
		assert(property_type_id ~= 0, "couldn't create a property " .. property_name .. " for class " .. class_name)
	end
end

function delete_property(class_name, property_name)
	local class_id = raapi.findClass(class_name)
	assert(class_id ~= 0, "class " .. class_name .. " dosn't exists")
	
	local property_type_id = raapi.findAttribute(class_id, property_name)
  if property_type_id ~= 0 then
    local c = class.new(class_id)
    c:reset_property_cache()
    --delete property from all instances
    local objects = c:objects()
    for _, o in ipairs(objects) do
      raapi.deleteAttributeValue(o["id"], property_type_id)
    end
    
    status = raapi.deleteAttribute(property_type_id)
    assert(status ~= 0, "couldn't delete a property " .. property_name .. " from class " .. class_name)
	end
end

local link_type_constants = {
  Card_01 = 1,
  Card_0N = 2,
   Card_1 = 3,
  Card_1N = 4,
  
               Role_Group = 1,
              Role_Member = 11,
           Role_Aggregate = 2,
                Role_Part = 12,
    Role_DependentPartner = 3,
  Role_IndependentPartner = 4
}

function CreateLinkType(params)
  local description = params.description or ""
  
  local start_class_name = assert(params.start_class_name)
  local start_role_name = assert(params.start_role_name)
  local start_cardinality = params.start_cardinality or link_type_constants.Card_0N
  local start_role = params.start_role or link_type_constants.Role_IndependentPartner
  local start_is_ordered = params.start_is_ordered
  
  local end_class_name = assert(params.end_class_name)
  local end_role_name = assert(params.end_role_name)
  local end_cardinality = params.end_cardinality or link_type_constants.Card_0N
  local end_role = params.end_role or link_type_constants.Role_IndependentPartner
  local end_is_ordered = params.end_is_ordered
  
  
  
  local start_class_id = raapi.findClass(start_class_name)
	assert(start_class_id ~= 0, "failed to create link type: class " .. start_class_name .. " dosn't exists")
  
  local end_class_id = raapi.findClass(end_class_name)
	assert(end_class_id ~= 0, "failed to create link type: class " .. end_class_name .. " dosn't exists")
  
  local link_type_id = raapi.findAssociationEnd(start_class_id, end_role_name)
	local inv_link_type_id = raapi.findAssociationEnd(end_class_id, start_role_name)
  
  
  if link_type_id == 0 and inv_link_type_id == 0 then
    -- create property type if it does not exist
    local link_type_id = raapi.createAssociation(start_class_id, end_class_id, start_role_name,
                           end_role_name, false);
    
		assert(link_type_id ~= 0, "failed to create link type: " .. start_class_name .. "." .. start_role_name .. "/".. end_role_name .. "." .. end_class_name)
	elseif link_type_id ~= 0 and inv_link_type_id ~= 0 then
		if link_type_id ~= raapi.getInverseAssociationEnd(inv_link_type_id) or 
			 inv_link_type_id ~= raapi.getInverseAssociationEnd(link_type_id) then
			error("failed to create link type: there already is a link type " .. start_class_name .. "." .. start_role_name .. "/".. end_role_name .. "." .. end_class_name)
		end
		-- link already exists
	elseif link_type_id ~= 0 then
		error("failed to create link type " .. start_class_name .. "." .. end_role_name .. ":" .. end_class_name ..
		        " , because there is a link type " .. start_class_name .. "." .. end_role_name)
	elseif inv_link_type_id ~= 0 then
		error("failed to create link type " .. end_class_name .. "." .. start_role_name .. ":" .. start_class_name ..
		        " , because there is a link type " .. end_class_name .. "." .. start_role_name)
	else
		error("failed to create link type: couldn't create link type " .. start_class_name .. "." .. start_role_name .. "/".. end_role_name .. "." .. end_class_name)
	end
end

function add_link(start_class_name, start_role_name, end_role_name, end_class_name)
  CreateLinkType({
    start_class_name = start_class_name,
    start_role_name = start_role_name,
    start_is_ordered = true,
    
    end_role_name = end_role_name,
    end_class_name = end_class_name,
    -- end_is_ordered = true
  })
end

function add_composition(start_class_name, start_role_name, end_role_name, end_class_name)
  CreateLinkType({
    start_class_name = start_class_name,
    start_role_name = start_role_name,
    start_is_ordered = true,
    
    end_role_name = end_role_name,
    end_class_name = end_class_name,
    -- end_is_ordered = true,
    end_role = link_type_constants.Role_Aggregate,
  })
end

function delete_link(start_class_name, end_role_name)
	local start_class_id = raapi.findClass(start_class_name)
	assert(start_class_id ~= 0, "failed to delete link type: class " .. start_class_name .. " dosn't exists")
	local link_type_id = raapi.findAssociationEnd(start_class_id, end_role_name)
	local inv_link_type_id = raapi.getInverseAssociationEnd(link_type_id)
	if link_type_id ~= 0 then
	  --delete property from all instances
	  local c = class.new(start_class_id)
	  c:reset_link_cache()
	  class.new(raapi.getTargetClass(link_type_id)):reset_link_cache()
	  
	  
--		local objects = c:objects()
--		for _, o in ipairs(objects) do
--			raapi.deleteLink for all connected objects  mii_rep.DeleteLink(link_type_id, o.id, 0)
--		end
		status = raapi.deleteAssociation(link_type_id)
		
		assert(status ~= 0, "failed to delete link type: " .. start_class_name .. "/" .. end_role_name)
	end
end

function class_exists(class_name)
	local class_id = raapi.findClass(class_name)
	if class_id == 0 then
		return false
	else
		return true
	end
end
