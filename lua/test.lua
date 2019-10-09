require "prettyprint"
dumptable = prettyprint.dumptable

mii_rep = require("mii_rep_obj")
tda = require("lua_tda")
-- log(mii_rep.class_list())

lQuery = require("lQuery")

print("this is test")


-- log(table.concat(lQuery.map(mii_rep.class_list("elemt"), function(cl) return cl.name end), ", "))

-- lQuery("Compartment"):log()
-- lQuery("Compartment"):log({"input", "value"})

-- log(lQuery("ElemType"):length())
-- log(lQuery("ElemType"):find("NodeType"):length())
-- log(lQuery("ElemType"):find("[id=class]"):length())
-- log(lQuery("ElemType"):find("/compartType"):length())
-- log(lQuery("ElemType"):find("NodeType/compartType"):length())

-- log(lQuery("CompartType"):find("[caption=Name]"):length())
-- log(lQuery("ElemType"):find("NodeType/compartType[caption=Name]"):length())

-- log(lQuery("NodeType"):find("[caption=Class]"):length())
-- log(lQuery("ElemType"):find("NodeType[caption=Class]"):length())
-- log(lQuery("ElemType"):find("/compartType[caption=Name]/compartment"):length())

-- log(lQuery("CompartType"):find("[id=Name]"):length())
-- log(lQuery("CompartType[id=Name]"):length())
-- log(lQuery("CompartType[id=Name]/compartment"):length())
-- log(lQuery("CompartType[id=Name]"):find("/compartment"):length())
-- log(lQuery("CompartType[id=Name]"):find("/compartment[input=aoe]"):length())
-- log(lQuery("CompartType[id=Name]/compartment"):find("[input=aoe]"):length())
-- log(lQuery("CompartType[id=Name]/compartment[input=aoe]"):length())

-- lQuery("[id]"):log()
-- lQuery("[id=class]"):log()
-- lQuery("ElemType/compartType/compartment"):log()

-- log(lQuery("ElemType"):length())
-- log(lQuery("ElemType"):find("NodeType"):length())
-- log(lQuery("ElemType"):find("EdgeType"):length())
-- log(lQuery("ElemType"):find("NodeType,EdgeType"):length())
-- log(lQuery("NodeType,EdgeType"):length())

-- log(lQuery("GraphDiagramType"):find("/elemType.PortType"):length())
-- log(lQuery("NodeType:first"):length())

-- log( lQuery("NodeType"):to_s({"id", "caption"}))
-- log(lQuery("NodeType"):attr("id"))
-- lQuery("NodeType"):attr({id = "humm"})
-- lQuery("NodeType"):attr("caption", function(i, obj) return string.upper(obj:get_property("caption")) end)
-- log( lQuery("NodeType"):to_s({"id", "caption"}))

-- log( lQuery("NodeType:first"):to_s({"id", "caption"}))
-- log( lQuery("NodeType:last"):to_s({"id", "caption"}))
-- log( lQuery("Port:first"):length())
-- log( lQuery("Port:last"):length())

-- log( lQuery("NodeType:not([id=box],[id=NewNode])"):to_s({"id", "caption"}))
-- log( lQuery("NodeType"):to_s({"id", "caption"}))
-- log( lQuery("NodeType:not(/compartType)"):to_s({"id", "caption"}))

-- log( lQuery("NodeType:has(/compartType)"):to_s({"id", "caption"}))
-- log( lQuery("NodeType:has([id=NewNode])"):to_s({"id", "caption"}))
-- 
-- log( lQuery("NodeType[id!=NewNode]"):to_s({"id", "caption"}))
-- log("--\n")
-- log( lQuery("NodeType[id*=No]"):to_s({"id", "caption"}))
-- log("--\n")
-- log( lQuery("NodeType[id^=N]"):to_s({"id", "caption"}))
-- log("--\n")
-- log( lQuery("NodeType[id$=e]"):to_s({"id", "caption"}))
-- 
-- log("--\n")
-- log( lQuery("NodeType[id$=e]"):eq(4):to_s({"id", "caption"}))
-- 
-- cmd = mii_rep.create_object("CloseDgrCmd")
-- lQuery("GraphDiagram[caption=aoe]"):link("command", cmd)
-- tda.EnqueueCommand(cmd.id)
-- 
-- lQuery("GraphDiagram[caption=aoe]")
--   :link("command", lQuery.create("CloseDgrCmd"):enque())
--   
-- lQuery("GraphDiagram")
--   :link("command", function()return lQuery.create("CloseDgrCmd"):enque() end)
-- log("---")
-- lQuery("Command"):log({"info"})
-- lQuery("OkCmd/graphDiagram"):log({"caption"})
-- lQuery("OkCmd/element"):log()
