require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"

lQuery("ToolType"):find("/tag[key = 'DefaultMaxCardinality1']"):attr("value", 1)
-- print(lQuery("ToolType"):find("/tag[key = 'DefaultMaxCardinality1']"):attr("value"))

return true
-- return false, error_string