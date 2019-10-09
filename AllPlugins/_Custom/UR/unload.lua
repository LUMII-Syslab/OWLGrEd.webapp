require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")

lQuery("PopUpElementType[id='TransformClassToAssociations']"):delete()

return true
-- return false, error_string