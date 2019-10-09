module(..., package.seeall)

function load()
  local class = lQuery.model.add_class
  local attr = lQuery.model.add_property
  local link = lQuery.model.add_link
  local compos = lQuery.model.add_composition
  local super_class = lQuery.model.set_super_class
  
  class("PT#Diagram")
    attr("PT#Diagram", "width")

  class("PT#NodeParent")
    attr("PT#NodeParent", "showChildIcons")

  class("PT#Tab")
    super_class("PT#Tab", "PT#NodeParent")
    attr("PT#Tab", "caption")
    attr("PT#Tab", "isVisible")
    compos("PT#Tab", "tab", "diagram", "PT#Diagram")

  class("PT#DefaultTree")
    super_class("PT#DefaultTree", "PT#Tab")

  class("PT#Node")
    super_class("PT#Node", "PT#NodeParent")
    attr("PT#Node", "caption")
    attr("PT#Node", "expandable")
    attr("PT#Node", "isExpanded")
    attr("PT#Node", "selected")
    attr("PT#Node", "iconPath")
    attr("PT#Node", "font")
    attr("PT#Node", "bgdColor")
    compos("PT#Node", "child", "parent", "PT#NodeParent")

  --events
  class("PT#Event")
    super_class("PT#Event", "Event")
    link("PT#Event", "event", "node", "PT#Node")

  class("PT#SelectEvent")
    super_class("PT#SelectEvent", "PT#Event")

  class("PT#ExpandEvent")
    super_class("PT#ExpandEvent", "PT#Event")

  class("PT#ColapseEvent")
    super_class("PT#ColapseEvent", "PT#Event")

  class("PT#DoubleClickEvent")
    super_class("PT#DoubleClickEvent", "PT#Event")

  class("PT#RightClickEvent")
    super_class("PT#RightClickEvent", "PT#Event")

  class("PT#KeyDownEvent")
    super_class("PT#KeyDownEvent", "PT#Event")

  --cmd
  class("PT#Cmd")
    super_class("PT#Cmd", "Command")
    link("PT#Cmd", "cmd", "node", "PT#Node")

  class("PT#SelectCmd")
    super_class("PT#SelectCmd", "PT#Cmd")

  class("PT#ExpandCmd")
    super_class("PT#ExpandCmd", "PT#Cmd")

  class("PT#ColapseCmd")
    super_class("PT#ColapseCmd", "PT#Cmd")

  class("PT#RefreshCmd")
    super_class("PT#RefreshCmd", "PT#Cmd")
    link("PT#RefreshCmd", "refreshCmd", "nodeParent", "PT#NodeParent")

  class("PT#PopUpCmd")
    super_class("PT#PopUpCmd", "PT#Cmd")
    link("PT#PopUpCmd", "pt_PopUpCmd", "popUpDiagram", "PopUpDiagram")
end

-- mm = require("metamodel")
-- PT = mm.package("PT#")
-- 
-- PT.Diagram {
--   width = mm.Integer,
--   
--   tab = {"*", PT.Tab, PT.diagram, mm.composition},
-- }
-- 
-- 
-- PT.NodeParent {
--   showChildIcons = mm.Boolean,
--   
--   child = {"*", PT.Node, PT.parent},
--   refreshCmd = {1, PT.RefreshCmd, PT.nodeParent},
-- }
-- 
-- 
-- PT.Tab {
--   PT.NodeParent,
--   
--   caption = mm.String,
--   isVisible = mm.Boolean,
--   
--   diagram = {1, PT.Diagram, PT.tab},
-- }
-- 
-- PT.DefaultTreeTab {
--   PT.Tab,
-- }
-- 
-- mm.instantiate(PT)