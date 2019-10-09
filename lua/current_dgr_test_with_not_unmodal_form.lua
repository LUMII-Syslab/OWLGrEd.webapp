module(..., package.seeall)
d = require("dialog_utilities")

function show_form()
    local close_button = lQuery.create("D#Button", {
        caption = "Close"
        ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.current_dgr_test_with_not_unmodal_form.close()")
    })
    
    local form = lQuery.create("D#Form", {
        id = "unmodal_test"
        ,caption = "not modal test"
        ,buttonClickOnClose = false        
        ,cancelButton = close_button
        ,defaultButton = close_button
        ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.current_dgr_test_with_not_unmodal_form.close()")
        ,component = {
            lQuery.create("D#VerticalBox", {
                component = lQuery.create("D#Button", {
                                                        caption = "log current diagram"
                                                        ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.current_dgr_test_with_not_unmodal_form.log_current_diagram()")
                            })
            })
            ,lQuery.create("D#HorizontalBox", {
                horizontalAlignment = 1
                ,topMargin = 20
                ,component = close_button
            })
        }
    }) 
    d.execute_d_command(form, "Show")
end

function close()
  lQuery("D#Event"):delete()
  utilities.close_form("unmodal_test")
end

function log_current_diagram()
  lQuery("D#Event"):delete()
  local cdp = lQuery("CurrentDgrPointer"):log()
  local dgr = cdp:find("/graphDiagram")
  if dgr:is_empty() then
    log("no diagrama connected to CurrentDgrPointer")
  else
    dgr:log{"caption"}
  end
end