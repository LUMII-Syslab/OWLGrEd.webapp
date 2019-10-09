require("lQuery")


local plugin_name = "OWLGrEd_Schema"
local plugin_info_path = tda.GetProjectPath() .. "\\" .. "Plugins" .. "\\" .. plugin_name .. "\\info.lua"
local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*a"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")


if current_version < "0.5" and current_version < plugin_version then
	lQuery("PopUpElementType[id='VisualMetrics']"):delete()

	lQuery("GraphDiagramType[id='OWL']/rClickEmpty"):link("popUpElementType",lQuery.create("PopUpElementType", {id = "VisualMetrics", caption = "Evaluate Quality", nr = 40, procedureName = "VisualMetrics.visualMetrics.showDialog", visibility = true}))
end
			
return true
-- return false, error_string