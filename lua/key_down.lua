module(..., package.seeall)

require("lQuery")
tda = require("lua_tda")

function interpret()
  local keyboard_combintion = lQuery("KeyDownEvent"):attr("info")
  log(keyboard_combintion)
  
  local active_diagram = lQuery("CurrentDgrPointer/graphDiagram")
  local active_elements = active_diagram:find("/collection/element")
  local shortcuts

  if active_elements:size() == 0 then
    shortcuts = active_diagram:find("/graphDiagramType/eKeyboardShortcut")
    
  elseif active_elements:size() == 1 then
    shortcuts = active_elements:eq(1):find("/elemType/keyboardShortcut")
    
  else
    shortcuts = active_diagram:find("/graphDiagramType/cKeyboardShortcut")
    
  end
  local proc_name = shortcuts:find("[key=" .. keyboard_combintion .. "]"):attr("procedure_name")
  if proc_name then
    if active_elements:size() == 1 then
      log(keyboard_combintion, proc_name, active_elements:get(1).id)
      tda.ExecuteOneArgumentTransformation(proc_name, active_elements:get(1).id)
    else
      tda.ExecuteTransformation(proc_name)
    end
    lQuery("Command"):log()
  else
    if keyboard_combintion == "1" then
      tda.ExecuteTransformation("lua_engine#lua.law_view.create_form()")
    end
  end
end