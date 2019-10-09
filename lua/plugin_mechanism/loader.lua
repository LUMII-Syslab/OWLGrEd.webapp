module(..., package.seeall)

require "lfs"
require "set"

local utils = require "plugin_mechanism.utils"

--[[
Plugin structure:
  PluginName -- a directory in Plugins folder
    info.txt or info.lua -- contains a lua table with information about the plugin
      {
        id
        version
        dependencies = {   ???
          {id1, version},  ???
          {id2, version},  ???
          ...              ???
        }                  ???
      }
    load.lua --script for loading the plugin, returns true if load sucseeded, false and error message on fail
    unload.lua --script for unloading the plugin, must not depend on ony other custom files, because will be copied elswhere and called when the plugin is deleted from this dir
    updater.lua ??? --script that is called if the version of a leaded plugin is different from the version in the info.txt fail
    ... -- any other resources. Will be aviable for plugin at loadtime
--]]

----
-- utils
----

local Plugin_dir_path
local Plugin_data_dir_path
local Plugin_uninstall_dir_path
local Tool_plugin_dir_path
local Bin_plugin_dir_path

if tda.isWeb then
	Plugin_dir_path = tda.GetToolPath() .. "\\" .. "AllPlugins"
	Plugin_data_dir_path = tda.GetToolPath() .. "\\" .. "PluginData"
	Plugin_uninstall_dir_path = tda.GetToolPath() .. "\\" .. "AllPlugins"
else
	Plugin_dir_path = tda.GetProjectPath() .. "\\" .. "Plugins"
	Plugin_data_dir_path = tda.GetProjectPath() .. "\\" .. "PluginData"
	Plugin_uninstall_dir_path = tda.GetProjectPath() .. "\\" .. "PluginUninstalls"
	Tool_plugin_dir_path = tda.GetToolPath() .. "\\" .. "Plugins"
	Bin_plugin_dir_path = tda.GetRuntimePath() .. "\\" .. "Plugins"
end


function path_to_plugin(plugin_name)
  if tda.isWeb then
	return tda.FindPath(Plugin_dir_path, plugin_name)
  end
  return Plugin_dir_path .. "\\" .. plugin_name
end

function plugin_info_path(plugin_name)
  return path_to_plugin(plugin_name) .. "\\info.lua"
end

function plugin_info_path_txt(plugin_name)
  return path_to_plugin(plugin_name) .. "\\info.txt"
end

function plugin_load_script_path(plugin_name)
  return path_to_plugin(plugin_name) .. "\\load.lua"
end

function plugin_update_script_path(plugin_name)
  return path_to_plugin(plugin_name) .. "\\update.lua"
end

function plugin_original_unload_script_path(plugin_name)
  return path_to_plugin(plugin_name) .. "\\unload.lua"
end

function plugin_unload_script_path(plugin_name)
  if isWeb then
	return tda.FindPath(Plugin_uninstall_dir_path, plugin_name) .. "\\unload.lua"
  end
  return Plugin_uninstall_dir_path .. "\\" .. plugin_name .. "\\unload.lua"
end

function get_plugin_info(plugin_name)
  local f
  if not file_exists(plugin_info_path_txt(plugin_name)) then f = io.open(plugin_info_path(plugin_name), "r")
  else f = io.open(plugin_info_path_txt(plugin_name)) end
  local info = loadstring("return" .. f:read("*a"))()
  f:close()
  return info
end

function file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then io.close(f) return true else return false end
end

function is_plugin_valid(plugin_name)
  local plugin_valid = true
  local errors = {}
  
  --all necesary fails present
  local missing_files = set.new{}
  -- if not file_exists(plugin_info_path(plugin_name)) then missing_files:insert("info.lua") end
  if not file_exists(plugin_info_path_txt(plugin_name)) and not file_exists(plugin_info_path(plugin_name)) then missing_files:insert("info.txt") end
  if not file_exists(plugin_load_script_path(plugin_name)) then missing_files:insert("load.lua") end
  if not file_exists(plugin_original_unload_script_path(plugin_name)) then missing_files:insert("unload.lua") end
  
  if missing_files:size() ~= 0 then
    plugin_valid = false
    errors.missing_files = missing_files
  end
  
  --info.lua contains an info table {name = ..., version = ...}
  if not missing_files:member("info.txt") then
    local info, err = get_plugin_info(plugin_name)
    if not info then
      plugin_valid = false
      errors["info.txt"] = err
    elseif type(info) ~= "table" then
      plugin_valid = false
      errors["info.txt"] = "should contain a table {id = ..., version = ...}"
    elseif info.name ~= plugin_name then
      plugin_valid = false
      errors["info.txt"] = "name must be equal to the directory name"
    end
  end
  
  if plugin_valid then
    return true
  else
    log("error loading plugin", plugin_name)
    --log(dumptable(errors))
    return false, errors
  end
end

-- table with names of valid plugins from Plugins directory
function get_plugin_names(plugin_dir_path)
  local plugin_names = {}
  local subfolder_names = utils.get_subfolder_names(plugin_dir_path)
  
  for _, d in ipairs(subfolder_names) do
    if is_plugin_valid(d) then
      table.insert(plugin_names, d)
    end
  end
  
  return plugin_names
end

----
-- init
----

function create_plugin_registry_metamodel()
  lQuery.model.add_class("Plugin")
		lQuery.model.add_property("Plugin", "id")
		lQuery.model.add_property("Plugin", "version")
		lQuery.model.add_property("Plugin", "status")
end

function make_plugin_data_dir(plugin_name)
  lfs.mkdir(Plugin_data_dir_path)
  lfs.mkdir(Plugin_data_dir_path .. "\\" .. plugin_name)
end

function make_plugin_unload_dir(plugin_name)
  lfs.mkdir(Plugin_uninstall_dir_path)
  lfs.mkdir(Plugin_uninstall_dir_path .. "\\" .. plugin_name)
end

function initialize_plugin_mechanism()
  create_plugin_registry_metamodel()
  
  --make top level plugin dirs
  lfs.mkdir(Plugin_dir_path)
  lfs.mkdir(Plugin_data_dir_path)
  lfs.mkdir(Plugin_uninstall_dir_path)
end


----
-- loader
----

function load_plugin(plugin_name)
  -- check plugin validity (all necesary fails present)
  local plugin_info = get_plugin_info(plugin_name)
  log("--loading", plugin_info.name, "\n" .. dumptable(plugin_info))
  
  -- check plugin dependencies ???
  
  -- prepare environment for load script
  local old_path = package.path
  local old_cpath = package.cpath
  package.path = path_to_plugin(plugin_name) .. "\\?.lua;" .. old_path
  package.cpath = path_to_plugin(plugin_name) .. "\\?.dll;" .. old_cpath

  if tda.isWeb == nil then make_plugin_data_dir(plugin_name) end
  
  -- call load script
  local pcall_status, pcall_err_or_load_res, load_err = pcall(dofile, plugin_load_script_path(plugin_name))
  if pcall_status then
    if pcall_err_or_load_res then
      log("plugin loaded")
      -- copy unload script to unload script folder
    
	 if tda.isWeb == nil then 
		make_plugin_unload_dir(plugin_name) 
		utils.copy(plugin_original_unload_script_path(plugin_name), plugin_unload_script_path(plugin_name))
      end
      -- register plugin as loaded
	  if lQuery("Plugin[id='"..plugin_info.name.."']"):is_not_empty() then
		lQuery("Plugin[id='"..plugin_info.name.."']"):attr("status", "loaded")
	  else
		  lQuery.create("Plugin", {
			id = plugin_info.name,
			version = plugin_info.version,
			status = "loaded",
		  })
	  end
    else
      log("load error", load_err)
    end
  else
    log("load script error:", pcall_err_or_load_res)
  end
  
  --reset environment
  package.path = old_path
  package.cpath = old_cpath
  
  log("-----------")
end

function load_added_plugins()
  local names_of_loaded_plugins = set.new(lQuery("Plugin[status=loaded]"):map(function(p) return p:attr("id") end))
  local plugins_in_plugin_folder = set.new(get_plugin_names(Plugin_dir_path))
  
  if tda.isWeb then
	plugins_in_plugin_folder = set.new(lQuery("Plugin[status=added]"):map(function(p) return p:attr("id") end))
  end
  
  for plugin_name in pairs(plugins_in_plugin_folder - names_of_loaded_plugins) do
    load_plugin(plugin_name)
  end
end

----
-- unloader
----

function unload_plugin(plugin_name)
  log("--unloading", plugin_name)
  -- call the corresponding unload script from unload script folder
  local pcall_status, pcall_err_or_unload_res, unload_err = pcall(dofile, plugin_unload_script_path(plugin_name))
  if pcall_status then
    if pcall_err_or_unload_res then
      log("plugin unloaded")

	  if tda.isWeb == nil then
		  -- delete unload script
		  utils.delete(Plugin_uninstall_dir_path .. "\\" .. plugin_name)
      end
      -- remove plugin from registry
      lQuery("Plugin"):filter_attr_value_equals("id", plugin_name):delete()
    else
      log("unload error", unload_err)
    end
  else
    log("unload script error:", pcall_err_or_unload_res)
  end
  
  log("-----------")
end

function unload_deleted_plugins()
  local names_of_loaded_plugins = set.new(lQuery("Plugin[status=loaded]"):add(lQuery("Plugin[status=unloaded]")):map(function(p) return p:attr("id") end))
  local plugins_in_plugin_folder = set.new(get_plugin_names(Plugin_dir_path))
  
  if tda.isWeb then 
	plugins_in_plugin_folder = set.new(lQuery("Plugin[status=unloaded]"):map(function(p) return p:attr("id") end))
  end
  
  for plugin_name in pairs(names_of_loaded_plugins - plugins_in_plugin_folder) do
    unload_plugin(plugin_name)
  end
end


----
-- updater
----

function update_plugin(plugin_instance)
  local plugin_name = plugin_instance:attr("id")
  local current_version = plugin_instance:attr("version")

  -- check plugin validity (all necesary fails present)
  local plugin_info = get_plugin_info(plugin_name)
  log("--checking if plugin", plugin_info.name, "needs update")
  log("-- current version", current_version, "version in info.txt", plugin_info.version)

  if current_version ~= plugin_info.version then
    log("-- versions do not match, trying to call update")

    -- check plugin dependencies ???
    
    -- prepare environment for load script
    local old_path = package.path
    local old_cpath = package.cpath
    package.path = path_to_plugin(plugin_name) .. "\\?.lua;" .. old_path
    package.cpath = path_to_plugin(plugin_name) .. "\\?.dll;" .. old_cpath

    -- call load script
    local pcall_status, pcall_err_or_load_res, load_err = pcall(dofile, plugin_update_script_path(plugin_name))
    if pcall_status then
      if pcall_err_or_load_res then
        log("plugin updated to version", plugin_info.version)

        -- register new version of plugin
        plugin_instance:attr({
          version = plugin_info.version,
        })
      else
        log("update error", load_err)
      end
    else
      log("update script error:", pcall_err_or_load_res)
    end

      --reset environment
    package.path = old_path
    package.cpath = old_cpath
    
  else
    log("-- versions match, no update needed")
  end

  log("-----------")
end

function update_existing_to_newest_version()
  local loaded_plugin_instances
  if tda.isWeb then 
	loaded_plugin_instances = lQuery("Plugin[status=updated]") 
  else 
	loaded_plugin_instances = lQuery("Plugin[status=loaded]")
  end

  for plugin_instance in loaded_plugin_instances do
    update_plugin(plugin_instance)
  end
end


----
-- Plugin manager
----

function copy_missing_plugins_from_tool_or_bin()
  local project_plugins = set.new(utils.get_subfolder_names(Plugin_dir_path))
  
  local tool_plugins = set.new(utils.get_subfolder_names(Tool_plugin_dir_path))
  local bin_plugins = set.new(utils.get_subfolder_names(Bin_plugin_dir_path))
  
  -- copy missing from tool
  for plugin_name in pairs(tool_plugins - project_plugins) do
    utils.copy(Tool_plugin_dir_path .. "\\" .. plugin_name, Plugin_dir_path .. "\\" .. plugin_name)
  end
  
  -- copy missing from bin
  for plugin_name in pairs((bin_plugins - tool_plugins) - project_plugins) do
    utils.copy(Bin_plugin_dir_path .. "\\" .. plugin_name, Plugin_dir_path .. "\\" .. plugin_name)
  end
end

-- loads new plugins and unloads deleted plugins
function refresh_plugins()
  local update_tool = require ("update_tool")
  update_tool.update_project_or_tool()
	
  initialize_plugin_mechanism()

  if tda.isWeb == nil then copy_missing_plugins_from_tool_or_bin() end
  
  unload_deleted_plugins()
  load_added_plugins()
  update_existing_to_newest_version()
end


-- register plugin loader to work at project startup
function register_plugin_loader()
  -- get or create ToolType
  local tool_type = lQuery("ToolType")
  if tool_type:is_empty() then
    tool_type = lQuery.create("ToolType", {
      root = lQuery("GraphDiagramType[id=projectDiagram]")
    })
  end
  
  -- add translet for calling plugin refresh on project open
  utilities.add_translet_if_missing(tool_type, "procOnOpen", "plugin_mechanism.loader.refresh_plugins()")
end

return {
  refresh_plugins = refresh_plugins,
  register_plugin_loader = register_plugin_loader,
  unload_plugin = unload_plugin,
  load_plugin = load_plugin,
}