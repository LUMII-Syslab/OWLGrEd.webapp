module(..., package.seeall)
require("lQuery")

require("utilities")
d = require("dialog_utilities")

function diagram_types()
	return lQuery("GraphDiagramType"):map(function(gdt, i)
		return lQuery.create("D#Item", {value = gdt:attr("caption")}):get(1)
	end)
end

function create_form ()
  lua_mii_rep.DisableUndo()
  form = lQuery.create("D#Form", {
    caption = "TypeView"
    ,component = {
      lQuery.create("D#HorizontalBox", {
        component = {
          lQuery.create("D#ListBox", {
						preferredHeight = 90
						,item = diagram_types()
					})
					,lQuery.create("D#ListBox", {
						preferredHeight = 90
					})
					,lQuery.create("D#ListBox", {
						preferredHeight = 90
					})
        }
      })
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
        ,component = lQuery.create("D#Button", {
          caption = "Close"
          ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.utilities.close_form()")
        })
      })
    }
  })
  d.show_form(form)
end