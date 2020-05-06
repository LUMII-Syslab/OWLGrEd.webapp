module(..., package.seeall)

require("config_properties")

function update_project_or_tool()
	local tool_version = config_properties.get_config_value("config_version")

	if tool_version > lQuery("Project"):attr("version") then
		update_version(lQuery("Project"):attr("version"), tool_version)
		lQuery("Project"):attr({version = tool_version})
	end
end

function update_version(curent_version, tool_version)
	-- export axioms changes
	if curent_version < "1.6.5.4" and tool_version >= "1.6.5.4" then
		local p = require("parameters")
		p.config_OWL_PP()

		local e = require("exportOntology")
		e.exportParameterMetamodel()
		log("Project updated to version 1.6.5.4")
	end
	-- export axioms changes
	if curent_version < "1.6.5.5" and tool_version >= "1.6.5.5" then
		local e = require("exportOntology")
		e.configExportTags()
		log("Project updated to version 1.6.5.5")
	end
	
	-- tool and plugin versions as annotations in export/import
	if curent_version < "1.6.9.3" and tool_version >= "1.6.9.3" then
		if lQuery("OWL_PP#Parameter[pName = 'DiscardPreviousOWLGrEdVersionAnnotations']"):size() == 0 then
			local defaultSet = lQuery("OWL_PP#PValueSet[isDefaultSet='true']")

			local parameter = lQuery.create("OWL_PP#Parameter", {pName = "DiscardPreviousOWLGrEdVersionAnnotations"})
			lQuery.create("OWL_PP#PValue", {pName = "DiscardPreviousOWLGrEdVersionAnnotations", pValue = "true"})
				:link("parameter", parameter)
				:link("pValueSet", defaultSet)
			
			log("Project updated to version 1.6.9.3")
		end
	end
	
	-- export parameter metamodel and form
	if curent_version < "1.6.9.4" and tool_version >= "1.6.9.4" then
		local e = require("exportOntology")
		e.exportParameterMetamodel()
			
		log("Project updated to version 1.6.9.4")
	end
	
	--export axioms change
	if curent_version < "1.6.9.5" and tool_version >= "1.6.9.5" then
		lQuery("ElemType[id='AnnotationProperty']/compartType[id='Comment']/tag[key='ExportAxiom']"):attr("value", [[AnnotationAssertion(rdfs:comment /../Name:$getUri(/Name /Namespace) "$value")]])
			
		log("Project updated to version 1.6.9.5")
	end
	
	--services context menu
	if curent_version < "1.6.9.6" and tool_version >= "1.6.9.6" then
		
		lQuery("PopUpElementType[id='Recalculate isObjectAttribute']"):delete()
		
		lQuery.create("PopUpElementType", {id="Services", caption="Services", nr=8, visibility=true, procedureName="services.showServices"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))
		
		log("Project updated to version 1.6.9.6")
	end
	
end