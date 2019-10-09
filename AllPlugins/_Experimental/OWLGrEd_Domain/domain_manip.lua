module(..., package.seeall)

require("mii_rep_obj")

function create_object(obj_table)
	if type(obj_table['class']) == "table" then
		return create_equivalent_objects(obj_table)
	end

	local class_name = obj_table['class']
	local attributes = obj_table['attrs']
	
	local object
	local object_id = mii_rep_obj.class.create(class_name):first_object_id_with_attr_val("id", attributes['id'])
	if object_id == 0 then
		object = lQuery.create(class_name, attributes)
	else
		object = lQuery(object_id)
	end
	
	return object
end

function create_equivalent_objects(obj_table)
	objects = lQuery("")
	for _, class_name in ipairs(obj_table['class']) do
		local temp_table = obj_table
		temp_table['class'] = class_name
		
		local object = create_object(temp_table)
		link_objects(objects, object, "equivalent")
		objects = objects:add(object)
	end
	
	return objects
end


-- iespçjams "equivalent" jâbût tikai pie object1 vai object2
-- optimize
function link_objects(object1, object2, link)
	local objects1 = object1:find("/equivalent"):add(object1)
	local objects2 = object2:find("/equivalent"):add(object2)
	
	objects1:link(link, objects2)
end