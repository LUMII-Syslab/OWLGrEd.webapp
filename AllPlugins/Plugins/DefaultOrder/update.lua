require("lQuery")

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "DefaultOrder")
else
	path = tda.GetProjectPath() .. "\\Plugins\\DefaultOrder"
end

local plugin_name = "DefaultOrder"
local plugin_info_path = path .. "\\info.lua"
local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*a"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")


if current_version < "0.2" and current_version < plugin_version then
	lQuery.create("Translet", {extensionPoint='OnDiagramExport', procedureName='DefaultOrder.defaultOrder_specific.calculateDafaultOrderOnDiagramSave'}):link("type", lQuery("ToolType"))
end
			
return true
-- return false, error_string