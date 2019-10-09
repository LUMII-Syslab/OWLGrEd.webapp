module(..., package.seeall)

prefix = ""

function prefixChanged ()
end

function askForPrefix ()
  form = lQuery.create("D#Form", {
    caption = "Prefix for classes"
    ,component = {
      lQuery.create("D#HorizontalBox", {
        component = {
          lQuery.create("D#Label", {
             caption = "Prefix:"
          })
          ,lQuery.create("D#TextBox", {
            eventHandler = utilities.d_handler("Change", "lua_engine", "lua.mmd.prefixChanged")
          })
        }
      })
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
        ,component = lQuery.create("D#Button", {
          caption = "OK",
          closeOnClick = true,
          deleteOnClick = false
        })
      })
    }
  })

  utilities.execute_cmd("D#Command", {info="ShowModal", receiver=form})

  local textBox = form:find("/component/component"):eq(2)
  prefix = textBox:attr("text")

  utilities.execute_cmd("D#Command", {info="Delete", receiver=form})
end


function get_compart_val(compartment)
  return lQuery(compartment):attr("value")
end

function get_comparts(parent, type_id)
  return lQuery(parent):find("/subCompartment, /compartment"):find(":has(/compartType[id='" .. type_id .. "'])")
end



function genMMD()

print("getMMD");
  --askForPrefix()
  --prefix = "TDAKernel::"

  local export_file = io.open(tda.GetProjectPath().."\\GeneratedMetamodel.mmd", "w")

  export_file:write("MMDefStart;\n");

  local current_diagram = utilities.current_diagram()

  local classes = current_diagram:find("/element:has(/elemType[id='Class'])")

  classes:each(function(c)
    c = lQuery(c)

    local name = c:find("/compartment:has(/compartType[id='Name'])"):attr("value")
    name = prefix..name;

    export_file:write("  class "..name..";\n")
	
    local attrs = c:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
    attrs:log():each(function(a)
      local attrName = a:find("/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
      local attrType = a:find("/subCompartment:has(/compartType[id='Type'])"):attr("value")        
      if not (attrName == nil) and not (attrType == nil) and not (attrName=="") and not (attrType=="") then
        export_file:write("    attr "..name.."."..attrName..":"..attrType..";\n")
      end
    end)
  end)

  classes:each(function(c)
    c = lQuery(c)

    local name = c:find("/compartment:has(/compartType[id='Name'])"):attr("value")
    name = prefix..name;

    local generalizations = c:find("/eStart:has(/elemType[id='Generalization'])")
    generalizations:each(function(e)
      e = lQuery(e)
      local superClass = e:find("/end")
      local superClassName = prefix..superClass:find("/compartment:has(/compartType[id='Name'])"):attr("value")
      export_file:write("    rel "..name..".subClassOf."..superClassName..";\n")
    end)

    local generalizations2 = c:find("/eStart:has(/elemType[id='AssocToFork'])")
    generalizations2:each(function(e)
      e = lQuery(e)
      local fork = e:find("/end");
      local topEdge = fork:find("/eStart:has(/elemType[id='GeneralizationToFork'])")
      superClass = topEdge:find("/end")
      local superClassName = prefix..superClass:find("/compartment:has(/compartType[id='Name'])"):attr("value")
      export_file:write("    rel "..name..".subClassOf."..superClassName..";\n")
    end)

    local generalizations3 = c:find("/eEnd:has(/elemType[id='AssocToFork'])")
    generalizations3:each(function(e)
      e = lQuery(e)
      local fork = e:find("/start");
      local topEdge = fork:find("/eStart:has(/elemType[id='GeneralizationToFork'])")
      superClass = topEdge:find("/end")
      local superClassName = prefix..superClass:find("/compartment:has(/compartType[id='Name'])"):attr("value")
      export_file:write("    rel "..name..".subClassOf."..superClassName..";\n")
    end)

  end)

  local associations = current_diagram:find("/element:has(/elemType[id='Association'])")

  associations:each(function(c)
    c = lQuery(c)
    local role = c:find("/compartment:has(/compartType[id = 'Role'])")
    local inv_role = c:find("/compartment:has(/compartType[id = 'InvRole'])")

    local class1 = c:find("/start/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
    local class2 = c:find("/end/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")

    local card2 = role:find("/subCompartment:has(/compartType[id = 'Multiplicity'])"):attr("value")
    local card1 = inv_role:find("/subCompartment:has(/compartType[id = 'Multiplicity'])"):attr("value")

    if (card1 == "") or (card1 == nil) then
      card1 = "*"
    end

    if (card2 == "") or (card2 == nil) then
      card2 = "*"
    end


    local role2 = role:find("/subCompartment/subCompartment:has(/compartType[id = 'Name'])"):attr("value")
    local role1 = inv_role:find("/subCompartment/subCompartment:has(/compartType[id = 'Name'])"):attr("value")

    if (role1 == "") or (role1 == nil) then
      role1 = class1:sub(1,1):lower()..class1:sub(2)
    end

    if (role2 == "") or (role2 == nil) then
      role2 = class2:sub(1,1):lower()..class2:sub(2)
    end

    local compos2 = role:find("/subCompartment:has(/compartType[id = 'IsComposition'])"):log("value"):attr("value")
    local compos1 = inv_role:find("/subCompartment:has(/compartType[id = 'IsComposition'])"):log("value"):attr("value")

    if (compos1 == "") or (compos1 == nil) then
      compos1 = "false"
    end

    if (compos2 == "") or (compos2 == nil) then
      compos2 = "false"
    end

    class1 = prefix..class1;
    class2 = prefix..class2;

    if (compos1 == "true") then
      export_file:write("  compos "..class1..".["..card1.."]"..role1.."/"..role2.."["..card2.."]."..class2..";\n");
    elseif (compos2 == "true") then
      export_file:write("  compos "..class2..".["..card2.."]"..role2.."/"..role1.."["..card1.."]."..class1..";\n");
    else
      export_file:write("  assoc "..class1..".["..card1.."]"..role1.."/"..role2.."["..card2.."]."..class2..";\n");
    end

  end)
  export_file:write("MMDefEnd;\n")
  export_file:close()

end
