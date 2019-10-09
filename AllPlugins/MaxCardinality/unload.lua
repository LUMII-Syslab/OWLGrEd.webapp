require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
lQuery("ToolType"):find("/tag[key = 'DefaultMaxCardinality1']"):attr("value", 0)

return true
-- return false, error_string