module(..., package.seeall)

require "mii_rep_obj"

function export_as_table (object, area_description, already_exported)
  add_table_representation(object, area_description, already_exported)
  return object.id
end

local property_list_cache = {}
function add_table_representation (object, area_description, already_exported)
  already_exported = already_exported or {}
  
  local id = object.id
  if already_exported[id] then 
    return already_exported[id]
  else
    --representation
	  local export_result = {
	    class = object:class().name
	    ,properties = {}
	    ,links = {}
	  }
	  
    already_exported[id] = export_result
	  
	   local self_class = object:class()
	  
	  --save properties
	  if not (property_list_cache[self_class]) then
	    property_list_cache[self_class] = self_class:property_list()
	  end
	  
	  local properties = property_list_cache[self_class]
	  for i,v in ipairs(properties) do
	    export_result.properties[v] = object:attr(v)
	  end
	  
	  local tmp = function (class_name, link_table)
	    if self_class:is_subtype_of(mii_rep_obj.class_by_name(class_name)) then
	      for link_name, export_function in pairs(link_table) do
	        local linked_objects = object:get_linked_by(link_name)
	        if not (table.maxn(linked_objects) == 0) then
      	    export_result.links[link_name] = lQuery.map(linked_objects, function(obj) 
      	        return export_function(obj, area_description, already_exported)
      	      end)
      	  end
    	  end
    	end
	  end
	  
    for class_name, link_table in pairs(area_description.include) do
      tmp(class_name, link_table)
    end
	  
	  for class_name, link_table in pairs(area_description.border) do
	    tmp(class_name, link_table)
	  end
	end
end

local selector_cache = {}

function selector_mem_fn(fn)
  return function(o)
    o = lQuery(o)
    local sel = selector_cache[o:id()]
    if not sel then
      sel = fn(o)
      selector_cache[o:id()] = sel
    end
    return sel
  end
end

selector_generator = {
  graphDiagramType = selector_mem_fn(function(object)
    return "GraphDiagramType[id=" .. lQuery(object):attr("id") .. "]"
  end)
  
  ,graphDiagramStyle = selector_mem_fn(function(object)
    local graphDiagramStyle = lQuery(object)
    return selector_generator.graphDiagramType(graphDiagramStyle:find("/graphDiagram:first/graphDiagramType")) ..
      "/graphDiagramStyle[id=" .. graphDiagramStyle:attr("id") .. "]"
  end)
  
  ,elemType = selector_mem_fn(function(object)
    local elemType = lQuery(object)
    return selector_generator.graphDiagramType(elemType:find("/graphDiagramType")) ..
      "/elemType[id=" .. elemType:attr("id") .. "]"
  end)
  
  ,elemStyle = selector_mem_fn(function(object)
    local elemStyle = lQuery(object)
    return selector_generator.elemType(elemStyle:find("/elemType")) ..
      "/elemStyle[id=" .. elemStyle:attr("id") .. "]"
  end)
  
  ,compartType = selector_mem_fn(function(object)
    local compartType = lQuery(object)
    local id = compartType:attr("id")
    if compartType:find("/parentCompartType"):is_not_empty() then
      return selector_generator.compartType(compartType:find("/parentCompartType")) ..
        "/subCompartType[id=" .. id .. "]"
    elseif compartType:find("/elemType"):is_not_empty() then
      return selector_generator.elemType(compartType:find("/elemType")) ..
        "/compartType[id=" .. id .. "]"
    else
      error("\nCompartType without a parent", compartType:attr("id"), compartType:id())
    end
  end)
  
  ,compartStyle = selector_mem_fn(function(object)
    local compartStyle = lQuery(object)
    return selector_generator.compartType(compartStyle:find("/compartType")) ..
      "/compartStyle[id=" .. compartStyle:attr("id") .. "]"
  end)
}

function make_exporter(export_functiotion)
  return function(object, area_description, already_exported)
    if not(already_exported[object.id]) then
      already_exported[object.id] = export_functiotion(object, area_description, already_exported)
    end
    return object.id
  end
end

export_spec = {
  border = {
    GraphDiagram = {
      graphDiagramType = make_exporter(selector_generator.graphDiagramType)
      ,graphDiagramStyle = make_exporter(selector_generator.graphDiagramStyle)
    }
    ,Element = {
      elemType = make_exporter(selector_generator.elemType)
      ,elemStyle = make_exporter(selector_generator.elemStyle)
    }
    ,Compartment = {
      compartType = make_exporter(selector_generator.compartType)
      ,compartStyle = make_exporter(selector_generator.compartStyle)
    }
  }
  
  ,include = {
    GraphDiagram = {
      element = export_as_table
    }
    ,Element = {
      compartment = export_as_table
      ,target = export_as_table
    }
    ,Edge = {
      start = export_as_table
      ,["end"] = export_as_table
    }
    ,Node = {
      component = export_as_table
      ,port = export_as_table
    }
    ,Compartment = {
      subCompartment = export_as_table
    }
  }
}

diagram_only_export_spec = {
  border = {
    GraphDiagram = {
      graphDiagramType = make_exporter(selector_generator.graphDiagramType)
      ,graphDiagramStyle = make_exporter(selector_generator.graphDiagramStyle)
    }
    ,Element = {
      elemType = make_exporter(selector_generator.elemType)
      ,elemStyle = make_exporter(selector_generator.elemStyle)
    }
    ,Compartment = {
      compartType = make_exporter(selector_generator.compartType)
      ,compartStyle = make_exporter(selector_generator.compartStyle)
    }
  }
  
  ,include = {
    GraphDiagram = {
      element = export_as_table
    }
    ,Element = {
      compartment = export_as_table
    }
    ,Edge = {
      start = export_as_table
      ,["end"] = export_as_table
    }
    ,Node = {
      component = export_as_table
      ,port = export_as_table
    }
    ,Compartment = {
      subCompartment = export_as_table
    }
  }
}

function import(deserialized_structure, start_id, get_object_fn)
  local old_id_to_new_obj_mapping = {}
  
  local function recreate_object(old_object_id)
    if old_id_to_new_obj_mapping[old_object_id] then
      return old_id_to_new_obj_mapping[old_object_id]
    else
      local representation = deserialized_structure[old_object_id]
      if type(representation) == "string" then --assmu lQuery selector
        local obj = get_object_fn(representation)
        if not obj then
          error("missing object " .. representation, 4)
        end
        --save mapping from old id to new id
        old_id_to_new_obj_mapping[old_object_id] = obj
        
        return obj
      else -- asseme table
        --create object
        local obj = mii_rep_obj.create_object(representation.class)
      
        --save mapping from old id to new id
        old_id_to_new_obj_mapping[old_object_id] = obj
      
        --set properties
        for property_name, property_value in pairs(representation.properties) do
          obj:set_property(property_name, property_value)
        end
      
        --add links
        for link_name, list_of_linked_obj_ids in pairs(representation.links) do
          for _, linked_obj_id in ipairs(list_of_linked_obj_ids) do
            obj:add_link(link_name, recreate_object(linked_obj_id))
          end
        end
        return obj
      end
    end
  end
  
  
  -- find missing references
  local missing_references = {}
  for k, v in pairs(deserialized_structure) do
    if type(v) == "string" then
      local obj = lQuery(v):get(1) 
      if obj then
        old_id_to_new_obj_mapping[k] = obj
      else
        table.insert(missing_references, v)
      end
    end
  end
  
  if table.getn(missing_references) == 0 then
    recreate_object(start_id)
    return old_id_to_new_obj_mapping[start_id]
  else
    log("\nImport failed. Missing references:\n\t" .. table.concat(missing_references, "\n\t"))
    return lQuery{}
  end
  
  
  -- for old_object_id, _ in pairs(deserialized_structure) do
  --   recreate_object(old_object_id)
  -- end
  
  
end

function string_representation (objects_to_export, export_spec)
  local function dump_to_string (o, indent)
    function tabs(i)
      return string.rep("  ", i)   -- Dots space by a space
    end

    indent = indent or 1
    if type(o) == "number" then
      return tostring(o)
    elseif type(o) == "string" then
      return string.format("%q", o)
    elseif type(o) == "table" then
      local tmp = {}

      for k,v in pairs(o) do
        local value_representation = dump_to_string(v, indent + 1)
        if value_representation ~= "\"\"" then
          if type(k) == "number" then
            table.insert(tmp,  "[" .. k .. "] = " .. value_representation)
          else
            table.insert(tmp,  "[\"" .. k .. "\"] = " .. value_representation)
          end
        end
      end
      return "{\n" .. tabs(indent) .. table.concat(tmp, ",\n" .. tabs(indent)) .. "\n" .. tabs(indent - 1) .. "}"
    else
      error("cannot serialize a " .. type(o))
    end
  end

  local lQuery_objects = lQuery(objects_to_export)
  local table_representation = {}
  
  lQuery.each(lQuery_objects.objects, function(o)
    add_table_representation(o, export_spec, table_representation)
  end)
  
  return "return " .. dump_to_string(table_representation) .. ", " .. objects_to_export:get(1).id
end

function save_to_file(objects_to_export, export_spec, file_name)
  local export_string = string_representation(objects_to_export, export_spec)
  
  local export_file = io.open(file_name, "w")
  export_file:write(export_string)
  export_file:close()
end

function import_from_file(file_name, get_object_fn)
  local table_representation, start_id = dofile(file_name)
  local new_start_obj = import(table_representation, start_id, get_object_fn or function(str) return lQuery(str):get(1) end)
  return new_start_obj
end

return {
  save_to_file = save_to_file
  ,import_from_file = import_from_file
  ,export_as_table = export_as_table
  ,make_exporter = make_exporter
  ,diagram_only_export_spec = diagram_only_export_spec
  ,export_spec = export_spec
}