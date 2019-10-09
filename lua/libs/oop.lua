module(..., package.seeall)
-- oo.new_class(table_with_local_props_and_functions, optional_super) --> returns new class
-- oo.is_subclass_of(sub_class, super_class) --> boolean
-- oo.get_class(object) --> class of the given object
-- oo.get_superclass(class) --> superclass of the given class
-- oo.is_instance_of(object, class) --> boolean
-- ClassName(table_with_local_props_and_methods) --> new class instance


local pairs        = pairs
local unpack       = unpack
local rawget       = rawget
local setmetatable = setmetatable
local getmetatable = getmetatable

function rawnew(class, object)
	return setmetatable(object or {}, class)
end

function init_class(class)
	if class == nil then class = {} end
	if class.__index == nil then class.__index = class end
	return class
end

-- returns new object
function new(class, ...)
	if class.__init then
		return class:__init(...)
	else
		return rawnew(class, ...)
	end
end

local MetaClass = { __call = new }

-- returns new class
function new_base_class(class)
	return setmetatable(init_class(class), MetaClass)
end


get_class = getmetatable

function is_base_class(class)
	return get_class(class) == MetaClass
end


ObjectCache = new_base_class({
	__mode = "k",
	__index = function(self, key)
		if key ~= nil then
			local value = rawget(self, "retrieve")
			if value then
				value = value(self, key)
			else
				value = rawget(self, "default")
			end
			rawset(self, key, value)
			return value
		end
	end
})

local DerivedClass = ObjectCache {
	retrieve = function(self, super)
		return new_base_class { __index = super, __call = new }
	end,
}


function new_class(class, super)
	if super then
		return DerivedClass[super](init_class(class))
	else
		return new_base_class(class)
	end
end

function is_class(class)
	local metaclass = get_class(class)
	if metaclass then
		return metaclass == rawget(DerivedClass, metaclass.__index) or
		       is_base_class(class)
	end
end

function get_superclass(class)
	local metaclass = get_class(class)
	if metaclass then
		return metaclass.__index
	end
end

function is_subclass_of(class, super)
	while class do
		if class == super then
			return true
		end
		class = get_superclass(class)
	end
	return false
end

function is_instance_of(object, class)
	return is_subclass_of(get_class(object), class)
end



-- shorthand
class = new_class
subclassof = is_subclass_of
classof = get_class
superclass = get_superclass
instanceof = is_instance_of