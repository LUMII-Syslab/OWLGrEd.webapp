require "lQuery"
require "utilities"
require "serialize"
local utils = require "plugin_mechanism.utils"

--import all that could be exported from the source (all except toolbar)
serialize.import_from_file(tda.GetRuntimePath() .. "\\lua\\Configurator\\const\\visualizeExporter_const.lua")

--create types for the toolbar element and the toolbar itself, link everything properly
local visToolbarType = lQuery.create("ToolbarType")
local visToolbarElementType = lQuery.create("ToolbarElementType", {
	id = "visualizeInstances",
	caption = "Visualize metamodel instances",
	picture = "1asdDataElement.bmp",
	procedureName = "visualizeMM.visualizeMM.openCollectionForm",
	toolbarType = visToolbarType
})

--first, link the toolbar type to all graph diagram types, so the button is always available
lQuery("GraphDiagramType"):each(
	function(grDType)
		grDType:link("toolbarType", visToolbarType)
		local diagrams = grDType:find("/graphDiagram")
		diagrams:each( --this block adds the toolbar and element to all already existing diagrams
			function(diagram)
				local toolbar = diagram:find("/toolbar") --each diagram can only have 1 toolbar, no more. Thus we need to add to the existing one
				if toolbar:is_empty() then --it seems that this is needed for specification diagrams - they seem not to have toolbars
					toolbar = lQuery.create("Toolbar", {graphDiagram = diagram})
				end
				if toolbar:find("/toolbarElement:has(/type[id=visualizeInstances])"):is_empty() then --if the toolbar doesn't already have the element, add it
					lQuery.create("ToolbarElement",{
						type = visToolbarElementType,
						toolbar = toolbar,
						caption = "Visualize metamodel instances",
						picture = "1asdDataElement.bmp",
						procedureName = "visualizeMM.visualizeMM.openCollectionForm",
					})
				end
				--utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram}) --refresh the diagrams after all is done
			end
		)
		utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagrams})
	end
)

utilities.add_tag(lQuery("GraphDiagramType[id=Instances]"), "IsTreeNode", "true", true)

return true
