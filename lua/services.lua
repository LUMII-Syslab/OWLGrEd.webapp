module(...,package.seeall)

require "lQuery"
local OP = require "isObjectAttribute"

function showServices()
  local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.services.close()")
  })
  local ok_button = lQuery.create("D#Button", {
    caption = "Ok"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.services.executeService()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "Services"
    ,caption = "Services"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.services.close()")
    ,minimumWidth = 410
	,component = {
		lQuery.create("D#HorizontalBox",{
			id = "HorizontalAllForms"
			,component = {
				lQuery.create("D#VerticalBox", {
					horizontalAlignment = -1
					,id = "ServicesBox"
					,component = {
						lQuery.create("D#RadioButton", {
							caption = "Recalculate attribute type (object/data attribute) "
							,id = "Recalculate_attribute_type"
							,selected = "true"
						})
					}
				})
			}})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {ok_button, close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
	
end

function executeService()
	if lQuery("D#RadioButton[id='Recalculate_attribute_type']"):attr("selected") == "true" then
		OP.setIsObjectAttributeForAllAttribute()
	end
	close()
end


function close()
	lQuery("D#Event"):delete()
	utilities.close_form("Services")
end
