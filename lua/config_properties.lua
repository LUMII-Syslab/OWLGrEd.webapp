module(..., package.seeall)

local config_file_name = "config"

local project_config_file_path = tda.GetProjectPath() .. "\\" .. config_file_name
local tool_config_file_path = tda.GetToolPath() .. "\\" .. config_file_name
local runtime_config_file_path = tda.GetRuntimePath() .. "\\" .. config_file_name

function get_local_config_value_table(config_file_path)
  local f = io.open(config_file_path, "r")
  if not f then
  	return {}
  else
  	local config_load_fn = loadstring("return" .. f:read("*a"))
  	f:close()
  	if not config_load_fn then
  		log("error loading config file")
  		return {}
  	else
  		local config_table = config_load_fn()
  		return config_table
  	end
  end
end

function merge_tables(result_table, t)
	for k, v in pairs(t) do
		result_table[k] = v
	end
	return result_table
end




function get_config_table()
	local runtime_config_properties = get_local_config_value_table(runtime_config_file_path)
	local tool_config_properties = get_local_config_value_table(tool_config_file_path)
	local project_config_properties = get_local_config_value_table(tool_config_file_path)

	return merge_tables(runtime_config_properties, merge_tables(tool_config_properties, project_config_properties))
end

function get_config_value_string(property_name)
	return tostring(get_config_value(property_name))
end

function get_config_value(property_name)
	local config_value = get_config_table()[property_name]
	if config_value ~= nil then
		return config_value
	else
		return ""
	end
end