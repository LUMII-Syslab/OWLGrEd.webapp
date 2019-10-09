module(..., package.seeall)
--require("configurator.const.diagramType")
--require("configurator")
dt = require("configurator.const.diagramType")
t = require("interpreter.tree")
--visualizeMM_types = require("Configurator.visualizeExporter_const")

function const()
	local specification_diagram_type = dt.diagramType_const(dt.specification_diagram_box, "specificationDgr", "Configurator")	
	--dt.diagramType_const(dt.diagramType_diagram_box, "diagramTypeDiagram", "")	
	local project_diagram_type = dt.project_diagram_const()
	dt.make_specification_project_diagrams(specification_diagram_type, project_diagram_type)	
	local instance_diagram_type = dt.instance_diagram_const()
	dt.make_instance_diagram_type(instance_diagram_type)
	local rep_diagram_type = dt.repository_diagram_const()
	dt.make_repository_diagram_type(rep_diagram_type)
	add_links_from_compartType_to_compartStyle()
	serialize.import_from_file(tda.GetRuntimePath() .. "\\lua\\Configurator\\const\\visualizeExporter_const.lua")
	lQuery.create("FirstCmdPtr")
	lQuery("HeadEngine"):attr({
			onOpenProjectEvent = "lua_engine#lua.interpreter.ProjectProcessing.project_opened",
			onCloseProjectEvent = "lua_engine#lua.interpreter.ProjectProcessing.project_close"
		})
	lQuery("GraphDiagramEngine"):attr({
			onPopUpElemSelectEvent = "lua_engine#lua.interpreter.PopUpElemSelect.PopUpElemSelect", 
			onToolbarElementSelectEvent = "lua_engine#lua.interpreter.ToolbarElementSelect.ToolbarElementSelect",
		
			--onPasteGraphClipboardEvent = "lua_engine#lua.interpreter.CutCopyPaste.Paste",
			--onCopyCutCollectionEvent = "lua_engine#lua.interpreter.CutCopyPaste.Cut",
			--onCopyCollectionEvent = "lua_engine#lua.interpreter.CutCopyPaste.Copy",
			
			onMoveLineStartPointEvent = "lua_engine#lua.interpreter.MoveLine.MoveLineStartPoint",
			onMoveLineEndPointEvent = "lua_engine#lua.interpreter.MoveLine.MoveLineEndPoint",
			
			onL2ClickEvent = "lua_engine#lua.interpreter.L2Click.L2Click",
			onLClickEvent = "lua_engine#lua.interpreter.LClick.LClick",
			onRClickEvent = "lua_engine#lua.interpreter.RClick.RClick",
			
			onNewLineEvent = "lua_engine#lua.interpreter.NewElement.NewLine",
			onNewBoxEvent = "lua_engine#lua.interpreter.NewElement.NewBox",
			onNewPinEvent = "lua_engine#lua.interpreter.NewElement.NewPin", 
			--onExecTransfEvent = "lua_engine#lua.interpreter.ExecTransf.ExecTransf", 
			onChangeParentEvent = "lua_engine#lua.interpreter.ChangeParent.ChangeParent", 
			--onOpenDgrEvent = "lua_engine#lua.utilities.do_nothing",
			onCloseDgrEvent = "lua_engine#lua.utilities.do_nothing", 
			--onOKStyleDialogEvent = "lua_engine#lua.configurator.configurator.OKStyleDialogEvent",
			onKeyDownEvent = "lua_engine#lua.interpreter.KeyDown.KeyDown",
			--onDeleteCollectionEvent = "lua_engine#lua.interpreter.Delete.Delete",

			onNewFreeBoxEvent = "lua_engine#lua.interpreter.NewElement.NewFreeBox",  
			--onNewFreeLineEvent = "lua_engine#lua.interpreter.NewElement.NewFreeLine", 
			onFreeBoxEditedEvent = "lua_engine#lua.interpreter.NewElement.FreeBoxEdited",
			--onActiveDgrEvent = "lua_engine#lua.utilities.do_nothing",
			onActivateDgrEvent = "lua_engine#lua.interpreter.ActivateDgr.ActivateDgr"
			--onFreeLineEditedEvent = "lua_engine#lua.interpreter.NewElement.FreeLineEdited"
		})
	lQuery.create("TreeEngine"):attr({
			["onPT#SelectEvent"] = "lua_engine#lua.interpreter.tree.Select",
			["onPT#ExpandEvent"] = "lua_engine#lua.interpreter.tree.Expand",
			["onPT#ColapseEvent"] = "lua_engine#lua.interpreter.tree.Colapse",
			["onPT#DoubleClickEvent"] = "lua_engine#lua.interpreter.tree.DoubleClick",
			["onPT#RightClickEvent"] = "lua_engine#lua.interpreter.tree.RightClick",
			["onPT#KeyDownEvent"] = "lua_engine#lua.interpreter.tree.KeyDown"
	})

--	lQuery("MultiUserEngine"):attr({onConvertToMultiUserProjectEvent = "main#convert_to_multiuser"})
	lQuery.create("ToolType", {caption = "Configurator", id = "Configurator"})
				:link("presentationElement", lQuery("Project"))
				:link("graphDiagramType", lQuery("GraphDiagramType"))
	--t.add_default_tree()
end

function add_links_from_compartType_to_compartStyle()
	lQuery("GraphDiagramType"):each(function(dgr_type)
		add_links_from_compartType_to_compartStyle__graphDiagramType(lQuery(dgr_type))	
	end)
end

function add_links_from_compartType_to_compartStyle__graphDiagramType(diagram_type)
	diagram_type:find("/elemType"):each(function(elem_type)
		add_links_from_compartType_to_compartStyle__elemType(lQuery(elem_type))
	end)
end

function add_links_from_compartType_to_compartStyle__elemType(elem_type)
	local elem_style = elem_type:find("/elemStyle")
	local compart_type = elem_type:find("/compartType")
	elem_style:find("/compartStyle"):each(function(compart_style)
		compart_style = lQuery(compart_style)
		compart_type:link("compartStyle", compartStyle)	
	end)
end

