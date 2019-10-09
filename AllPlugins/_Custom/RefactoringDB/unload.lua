require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")

lQuery("PopUpElementType[id='transform_property_names']"):delete()
lQuery("PopUpElementType[id='orderAttributesDiagramm']"):delete()
lQuery("PopUpElementType[id='orderAttributesClass']"):delete()

return true
-- return false, error_string