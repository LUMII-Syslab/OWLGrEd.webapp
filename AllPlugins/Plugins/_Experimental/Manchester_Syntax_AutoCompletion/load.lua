require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodel = require "Manchester_Syntax_AutoCompletion.completeMetamodel"


--complete metamodel
completeMetamodel.completeMetamodel()


return true
-- return false, error_string