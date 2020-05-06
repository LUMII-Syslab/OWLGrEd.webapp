require("lQuery")
require "core"
local plugin_name = "UML_Plus"

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "UML_Plus") .. "/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\UML_Plus\\"
end

local plugin_info_path = path .. "info.lua"

local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*a"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")

current_version = tonumber(string.sub(current_version, 3))
plugin_version = string.sub(plugin_version, 3)

--IsOrdered fiels is added to Association roles
if current_version < 2 then
		--add new profile
	local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
	local pathContextType = path .. "UML_Plus_IsOrdered.txt"
	
	completeMetamodelUserFields.loadAutoLoadProfile(pathContextType)
end

--view obis_hide_enum_text_form renamed to uml_hide_enum_text_form
--deleted empty views
if current_version < 3 then
	lQuery("AA#View[name='obis_hide_enum_text_form']"):attr("name", "uml_hide_enum_text_form")
	lQuery("Extension[id='obis_hide_enum_text_form']"):attr("id", "uml_hide_enum_text_form")
	
	lQuery("AA#View[name='obis_view']"):delete()
	lQuery("Extension[id='obis_view']"):delete()
	
	lQuery("AA#View[name='obis_text_patterns_invisible']"):delete()
	lQuery("Extension[id='obis_text_patterns_invisible']"):delete()
end

return true
-- return false, error_string