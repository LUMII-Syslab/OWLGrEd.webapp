module(..., package.seeall)

assert(require("lua_l0_core"))
assert(require("lQuery"))
assert(require("core"))

function set_compartment_value(compartment, value)
  local compartment_id = lQuery(compartment):id()
  lua_l0_core.set_compartment_value(compartment_id, value)
end

function set_compartment_value_without_specific_transformations(compartment, value)
  local compartment_id = lQuery(compartment):id()
  lua_l0_core.set_compartment_value_without_specific_transformations(compartment_id, value)
end

function create_compartment(parent, compartType, value)
  local parent_id = lQuery(parent):id()
  local compartType_id = lQuery(compartType):id()
  value = value or ""
  
  local new_compartment_id = lua_l0_core.create_compartment(parent_id, 
                                                            compartType_id, 
                                                            true,
                                                            value)
  core.reorder_child_compartments_according_to_type_order(parent)
  return lQuery(new_compartment_id)
end

function delete_compartment(compartment)
	core.delete_compartment(compartment)
end