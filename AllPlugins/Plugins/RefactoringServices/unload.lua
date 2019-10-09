require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
syncProfile = require "OWLGrEd_UserFields.syncProfile"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"

lQuery("PopUpElementType[id='TransformeToAttribute']"):delete()
lQuery("PopUpElementType[id='AttributeToAssociation']"):delete()
lQuery("PopUpElementType[id='AttributeToAttributeLink']"):delete()
lQuery("PopUpElementType[id='TrasformToSuperClass']"):delete()
lQuery("PopUpElementType[id='ForkToSuperClass']"):delete()
lQuery("PopUpElementType[id='AttributeToClassAttribute']"):delete()
lQuery("PopUpElementType[id='ConnectAttributeToDataType']"):delete()

return true
-- return false, error_string