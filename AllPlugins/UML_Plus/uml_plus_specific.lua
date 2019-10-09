module(..., package.seeall)

require("lua_tda")
require "core"
local t_to_p = require("tda_to_protege")
local owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"

function setImport(diagram)
	owl_fields_specific.setImportStyles(diagram)
end
