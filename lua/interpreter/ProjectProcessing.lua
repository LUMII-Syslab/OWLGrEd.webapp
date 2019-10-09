module(..., package.seeall)
require("utilities")
t = require("interpreter.tree")
report = require("reporter.report")
require("project_open_trace")
require("config_properties")
require "set"
local utils = require "plugin_mechanism.utils"
require("parameters") -- by SK
require("exportOntology") -- by SK

function file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then io.close(f) return true else return false end
end

function project_opened(ev_in)
parameters.config_OWL_PP() -- by SK
if not lQuery.model.class_exists("OWL_PP#ExportParameter") then
  exportOntology.exportParameterMetamodel() -- by SK
end
	local Plugin_dir_path = tda.GetProjectPath() .. "\\" .. "Plugins"
	local plugins_in_plugin_folder = set.new(get_plugin_names(Plugin_dir_path))
  
	local openProject = true
	local IncompatiblePlugins = {}
  
	for plugin_name in pairs(plugins_in_plugin_folder) do
		local plugin_info_path = Plugin_dir_path .. "\\" .. plugin_name .. "\\info.txt"
		local f
		if not file_exists(plugin_info_path) then f = io.open(Plugin_dir_path .. "\\" .. plugin_name .. "\\info.lua", "r")
		else f = io.open(plugin_info_path, "r") end
		local info = loadstring("return" .. f:read("*a"))()
		f:close()
		local plugin_version = info.version
		if(string.sub(plugin_version, 1, 2) == "0.") then plugin_version = string.sub(plugin_version, 3) end
		local configPlugin = config_properties.get_config_value(plugin_name)
		if(string.sub(configPlugin, 1, 2) == "0.") then configPlugin = string.sub(configPlugin, 3) end
		if config_properties.get_config_value(plugin_name) ~= nil and config_properties.get_config_value(plugin_name) > plugin_version then
			openProject = false
			table.insert(IncompatiblePlugins, {plugin_name, config_properties.get_config_value(plugin_name)})
		end
	end

	if openProject == true then
		-- project open trace - init metamodel
		project_open_trace.init_project_open_trace_metamodel()

		logging("ProjectOpen")
		local ev = utilities.get_event(ev_in, "Event")
		local str = ev:attr_e("info")
		local tool_type = lQuery("ToolType")
		local project = lQuery("Project")
		local diagram = project:find("/graphDiagram")
		local diagram_type = diagram:find("/graphDiagramType")
		if diagram_type:is_not_empty() then
			utilities.set_diagram_caption(diagram, str, true)
		end
		utilities.open_diagram(diagram)
		if lQuery("FirstCmdPtr"):size() == 0 then
			lQuery.create("FirstCmdPtr")
		end
		tool_type:find("/translet[extensionPoint = 'procOnOpen']"):each(function(translet)
			utilities.execute_translet(translet:attr("procedureName"))
		end)
		project_open_trace.add_project_open_trace_instance()
	else
		showPluginMessage(IncompatiblePlugins)
	end
end

function showPluginMessage(messages)
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.interpreter.ProjectProcessing.closePluginMessage()")
  })

  local form = lQuery.create("D#Form", {
    id = "PluginMessage"
    ,caption = "Incompatible plugin versions"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.interpreter.ProjectProcessing.closePluginMessage()")
	,component = {
		lQuery.create("D#VerticalBox", {
			id = "HorForm"
			,minimumWidth = 500
			,horizontalAlignment = -1
			,component = { 
				lQuery.create("D#Label", {caption = "Incompatible plugins detected:", minimumWidth = 100})
				,lQuery.create("D#Label", {caption = "", minimumWidth = 100})
				,lQuery.map(messages, function(message) 
					return lQuery.create("D#Label", {
						caption = message[1] .. ". Please update plugin to version " .. message[2] .. " or higher."
					}) 
				end)
				,lQuery.create("D#Label", {caption = "", minimumWidth = 100})
				,lQuery.create("D#Label", {caption = "Copy the plugin folder from (owlgred-root)/AvailablePlugins to (project-folder)/Plugins", minimumWidth = 100})
				,lQuery.create("D#Label", {caption = "(typically located under (owlgred-root)/Projects)", minimumWidth = 100})
			}
		})
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeForm"
        ,component = {
		  lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		  }
      })
    }
  })
  
	dialog_utilities.show_form(form)
end

function closePluginMessage()
  lQuery("D#Event"):delete()
  utilities.close_form("PluginMessage")
end

-- table with names of valid plugins from Plugins directory
function get_plugin_names(plugin_dir_path)
  local plugin_names = {}
  local subfolder_names = utils.get_subfolder_names(plugin_dir_path)
  
  for _, d in ipairs(subfolder_names) do
      table.insert(plugin_names, d)
  end
  
  return plugin_names
end

function project_close()
	logging("ProjectClose")
	local ev = lQuery("Event")
	local project = lQuery("Project")
	local proc_on_close = project:attr("procOnClose")
	if proc_on_close ~= "" then
		utilities.execute_translet(proc_on_close)
	end
end

function logging(event_type)
	report.event(event_type, {
		project_name = function() return lQuery("Project/graphDiagram"):attr("caption") end,
		tool_name = function() return lQuery("ToolType"):attr("caption") end,
		build_date = function() return lQuery("Project"):attr("build_date")	end,
		build_number = function() return lQuery("Project"):attr("build_number")	end,
		release_version = function() return lQuery("Project"):attr("release_version")	end,
	})
end
