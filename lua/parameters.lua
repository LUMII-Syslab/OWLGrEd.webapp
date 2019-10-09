module(..., package.seeall)
local configurator = require("configurator.configurator")
local json = require ("reporter.dkjson")

local showClases = true

function parametersTable()
	return {
     [" - ontology export"] = true,
     ["ontology - ontology annotations"] = true,
     ["classes - classes"] = true,
     ["ontology - annotation property definitions"] = true,
     ["classes - class annotations"] = true,
     ["classes - keys"] = true,
     ["individuals - individuals"] = true,
     ["individuals - individual annotations"] = true,
     ["object properties - merge inverse object properties"] = true,
     ["object properties - object properties"] = true,
     ["object properties - sub object properties"] = true,
     ["object properties - equivalent object properties"] = true,
     ["object properties - disjoint object properties"] = true,
     ["object properties - property chains"] = true,
     ["object properties - is functional"] = true,
     ["object properties - is inverSefunctional"] = true,
     ["object properties - is symmetric"] = true,
     ["object properties - is asymmetric"] = true,
     ["object properties - is reflexive"] = true,
     ["object properties - is irreflexive"] = true,
     ["object properties - is transitive"] = true,
     ["object properties - object property annotations"] = true,
     ["data properties - data properties"] = true,
     ["data properties - sub data properties"] = true,
     ["data properties - equivalent data properties"] = true,
     ["data properties - disjoint data properties"] = true,
     ["data properties - is functional"] = true,
     ["data properties - data property annotations"] = true,
     ["classes - merge disjoint classes links"] = true,
     ["classes - mutualy disjoint classes larger then 2 as boxes"] = true,
     ["classes - pairs of disjoint classes as lines"] = true,
     ["classes - other disjoint classes as compartments"] = false,
     ["classes - merge equivalent classes links"] = true,
     ["classes - mutualy equivalent classes larger then 2 as boxes"] = true,
     ["classes - pairs of equivalent classes as lines"] = true,
     ["classes - other equivalent classes as compartments"] = false,
     ["individuals - merge different individuals links"] = true,
     ["individuals - mutualy different individuals larger then 2 as boxes"] = true,
     ["individuals - pairs of different individuals as lines"] = true,
     ["individuals - other different individuals as compartments"] = false,
     ["individuals - merge same individuals links"] = true,
     ["individuals - mutualy same individuals larger then 2 as boxes"] = true,
     ["individuals - pairs of same individuals as lines"] = true,
     ["individuals - other same individuals as compartments"] = false,
     ["individuals - class assertions"] = true,
     ["individuals - object property assertions"] = true,
     ["individuals - data property assertions"] = true,
     ["individuals - negative object property assertions"] = true,
     ["individuals - negative data property assertions"] = true,
     [" - subclass axioms"] = true,
     ["object properties - show subclass of cardinality restrictions as multiplicity"] = true,
     ["data properties - show subclass of cardinality restrictions as multiplicity"] = true,
     ["object properties - show subclass of some as line"] = true,
     ["object properties - show subclass of only as line"] = true,
     ["object properties - show subclass of min as line"] = true,
     ["object properties - show subclass of max as line"] = true,
     ["object properties - show subclass of exact as line"] = true,
     ["object properties - object property restrictions as lines"] = true,
     ["classes - anonymous subclasses as boxes"] = true,
     ["classes - make top classes subclass of thing"] = true,
     ["classes - make named classes subclass of corresponding anonymous unions"] = true,
     ["classes - merge subclass lines with forks"] = true,
     [" - subclass forks"] = true,
     ["classes - subclass lines"] = true,
     ["classes - other super class as text"] = false,
     ["classes - equivalent to and named class as subclass link"] = true,
     [" - add compartments to elements"] = true,
     ["data-type - data types"] = true,
     ["ontology - unexported axioms"] = true
}
end

function extraParametersTable()
	return {
		["disjoint classes as text"] = false,
		["equivalent classes as text"] = false,
		["same individuals as text"] = false,
		["different individuals as text"] = false,
		["disjoint classes show others as text"] = true,
		["equivalent classes show others as text"] = true,
		["same individuals show others as text"] = true,
		["different individuals show others as text"] = true,
		["subclasses as text"] = false,
		["subclasses graphicaly"] = true,
		["subclasses graphicaly as lines"] = true,
		["subclasses show others as text"] = true,
	}
end

function completeMetamodel()
	lQuery.model.add_class("OWL_PP#Parameter")
		lQuery.model.add_property("OWL_PP#Parameter", "name")
		lQuery.model.add_property("OWL_PP#Parameter", "defaultValue")
	lQuery.model.add_class("OWL_PP#ParamValue")
		lQuery.model.add_property("OWL_PP#ParamValue", "value")
	lQuery.model.add_class("OWL_PP#ParamProfile")
		lQuery.model.add_property("OWL_PP#ParamProfile", "name")
		lQuery.model.add_property("OWL_PP#ParamProfile", "isSystemProfile")
		
	lQuery.model.add_link("OWL_PP#Parameter", "parameter", "value", "OWL_PP#ParamValue")
	lQuery.model.add_link("OWL_PP#ParamProfile", "profile", "value", "OWL_PP#ParamValue")
	lQuery.model.add_link("OWL_PP#ParamProfile", "current", "toolType", "ToolType")
	
	lQuery.create("Tag", {key='advancedParametersShow', value = false}):link("type", lQuery("ToolType"))
	
	local parametersTable = parametersTable()
	for param, defaultValue in pairs(parametersTable) do
		lQuery.create("OWL_PP#Parameter", {name = param, defaultValue = defaultValue})
	end
	
	local extraParametersTable = extraParametersTable()
	for param, defaultValue in pairs(extraParametersTable) do
		lQuery.create("OWL_PP#Parameter", {name = param, defaultValue = defaultValue})
	end
	
	lQuery.create("OWL_PP#ParamProfile", {name='current', isSystemProfile=true}):link("toolType", lQuery("ToolType"))
	saveDefaultParametersToMetamodel()
	
	local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")

	-- get or create toolbar type
	local toolbarType = project_dgr_type:find("/toolbarType")
	if toolbarType:is_empty() then
	  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
	end
	
	local pl_manager_toolbar_el = lQuery.create("ToolbarElementType", {
	  toolbarType = toolbarType,
	  id = "OntologyImportParametersSets",
	  caption = "Ontology loading preferences",
	  picture = "parameters.bmp",
	  procedureName = "parameters.showForm()"
	})
	
	configurator.make_toolbar(project_dgr_type)
end

function selectAllHH()
	lQuery("D#Event/source/container/container/component/component[id='VerticalBox']/component[type='CheckBox']"):attr("checked", true)
	lQuery("D#Event/source/container/container/component/component[id='VerticalBox']"):each(function(vb)
		vb:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end)
end

function clearAllHH()
	lQuery("D#Event/source/container/container/component/component[id='VerticalBox']/component[type='CheckBox']"):attr("checked", false)
	lQuery("D#Event/source/container/container/component/component[id='VerticalBox']"):each(function(vb)
		vb:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end)
end

function selectAllHV()
	lQuery("D#Event/source/container/container/component[id='VerticalBox']/component[type='CheckBox']"):attr("checked", true)
	lQuery("D#Event/source/container/container/component[id='VerticalBox']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

function clearAllHV()
	lQuery("D#Event/source/container/container/component[id='VerticalBox']/component[type='CheckBox']"):attr("checked", false)
	lQuery("D#Event/source/container/container/component[id='VerticalBox']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

function saveDefaultParametersToMetamodel()
	local profile = lQuery("ToolType"):find("/current")
	local parameterTableFromCheckBox = parameterTableFromCheckBox()
	for parameterName, parentParameterName in pairs (parameterTableFromCheckBox) do
		local value = ""
		createParameterValue(value, parameterName, profile)
	end
	local parameterTableFromRadioButton = parameterTableFromRadioButton()
	for parameterName, parentParameterName in pairs (parameterTableFromRadioButton) do
		local value = ""
		createParameterValue(value, parameterName, profile)
	end
end

function saveCopiedParametersToMetamodel(copyProfile, profile)
	local parameterTableFromCheckBox = parameterTableFromCheckBox()
	for parameterName, parentParameterName in pairs (parameterTableFromCheckBox) do
		local value = profile:find("/value:has(/parameter[name='" .. parameterName .. "'])"):attr("value")
		createParameterValue(value, parameterName, copyProfile)
	end
	local parameterTableFromRadioButton = parameterTableFromRadioButton()
	for parameterName, parentParameterName in pairs (parameterTableFromRadioButton) do
		local value = profile:find("/value:has(/parameter[name='" .. parameterName .. "'])"):attr("value")
		createParameterValue(value, parameterName, copyProfile)
	end
end

function saveParametersToMetamodel()
	local profile = lQuery("ToolType"):find("/current")
	createParameterValueFromCheckBox(profile)
	createParameterValueFromRadioButton(profile)
end

function createParameterValueFromRadioButton(profile)
	local parameterTableFromRadioButton = parameterTableFromRadioButton()
	for parameterName, parentParameterName in pairs (parameterTableFromRadioButton) do
		local value = lQuery("D#RadioButton[id='" .. parameterName .. "']"):attr("selected")
		createParameterValue(value, parameterName, profile)
	end
end

function parameterTableFromCheckBox()
	return {
		["ontology - ontology annotations"] = 0,
		["ontology - unexported axioms"] = 0,
		["classes - classes"] = 0,
		["object properties - object properties"] = 0,
		["data properties - data properties"] = 0,
		["individuals - individuals"] = 0,
		["data-type - data types"] = 0,
		["ontology - annotation property definitions"] = 0,
		
		[" - subclass axioms"] = "classes - classes",
		["classes - merge disjoint classes links"] = "classes - classes",
		["classes - merge equivalent classes links"] = "classes - classes",
		["classes - keys"] = "classes - classes",
		["classes - class annotations"] = "classes - classes",
		["data properties - sub data properties"] = "data properties - data properties",
		["data properties - disjoint data properties"] = "data properties - data properties",
		["data properties - equivalent data properties"] = "data properties - data properties",
		["data properties - data property annotations"] = "data properties - data properties",
		["data properties - is functional"] = "data properties - data properties",
		["data properties - show subclass of cardinality restrictions as multiplicity"] = "data properties - data properties",
		["object properties - merge inverse object properties"] = "object properties - object properties",
		["object properties - sub object properties"] = "object properties - object properties",
		["object properties - disjoint object properties"] = "object properties - object properties",
		["object properties - equivalent object properties"] = "object properties - object properties",
		["object properties - property chains"] = "object properties - object properties",
		["object properties - object property annotations"] = "object properties - object properties",
		["object properties - is functional"] = "object properties - object properties",
		["object properties - is inverSefunctional"] = "object properties - object properties",
		["object properties - is symmetric"] = "object properties - object properties",
		["object properties - is asymmetric"] = "object properties - object properties",
		["object properties - is transitive"] = "object properties - object properties",
		["object properties - is reflexive"] = "object properties - object properties",
		["object properties - is irreflexive"] = "object properties - object properties",
		["object properties - show subclass of some as line"] = "object properties - object properties",
		["object properties - show subclass of only as line"] = "object properties - object properties",
		["object properties - show subclass of min as line"] = "object properties - object properties",
		["object properties - show subclass of max as line"] = "object properties - object properties",
		["object properties - show subclass of exact as line"] = "object properties - object properties",
		["object properties - show subclass of cardinality restrictions as multiplicity"] = "object properties - object properties",
		["individuals - merge same individuals links"] = "individuals - individuals",
		["individuals - merge different individuals links"] = "individuals - individuals",
		["individuals - individual annotations"] = "individuals - individuals",
		["individuals - class assertions"] = "individuals - individuals",
		["individuals - object property assertions"] = "individuals - individuals",
		["individuals - data property assertions"] = "individuals - individuals",
		["individuals - negative object property assertions"] = "individuals - individuals",
		["individuals - negative data property assertions"] = "individuals - individuals",
		
		["classes - make top classes subclass of thing"] = {" - subclass axioms", "classes - classes"},
		["classes - equivalent to and named class as subclass link"] = {" - subclass axioms", "classes - classes"},
		["classes - make named classes subclass of corresponding anonymous unions"] = {" - subclass axioms", "classes - classes"},
		["classes - anonymous subclasses as boxes"] = {" - subclass axioms", "classes - classes", "classes - classes"},
		["classes - mutualy disjoint classes larger then 2 as boxes"] = {"classes - merge disjoint classes links","classes - classes", "classes - pairs of disjoint classes as lines"},
		["classes - mutualy equivalent classes larger then 2 as boxes"] = {"classes - merge equivalent classes links","classes - classes", "classes - pairs of equivalent classes as lines"},
		["individuals - mutualy same individuals larger then 2 as boxes"] = {"individuals - merge same individuals links","individuals - individuals", "individuals - pairs of same individuals as lines"},
		["individuals - mutualy different individuals larger then 2 as boxes"] = {"individuals - merge different individuals links","individuals - individuals", "individuals - pairs of different individuals as lines"},
		
		["subclasses show others as text"] = true,
		["disjoint classes show others as text"] = true,
		["equivalent classes show others as text"] = true,
		["same individuals show others as text"] = true,
		["different individuals show others as text"] = true,
	}
end

function parameterTableFromRadioButton()
	return {
		["classes - pairs of disjoint classes as lines"] = {"classes - merge disjoint classes links", "classes - classes"},
		["classes - pairs of equivalent classes as lines"] = {"classes - merge equivalent classes links", "classes - classes"},
		["individuals - pairs of same individuals as lines"] = {"individuals - merge same individuals links", "individuals - individuals"},
		["individuals - pairs of different individuals as lines"] = {"individuals - merge different individuals links", "individuals - individuals"},
		["disjoint classes as text"] = {"classes - merge disjoint classes links", "classes - classes"},
		["equivalent classes as text"] = {"classes - merge equivalent classes links", "classes - classes"},
		["same individuals as text"] = {"individuals - merge same individuals links", "individuals - individuals"},
		["different individuals as text"] = {"individuals - merge different individuals links", "individuals - individuals"},
		["classes - merge subclass lines with forks"] = {" - subclass axioms", "classes - classes", "subclasses graphicaly"},
		["subclasses graphicaly"] = {" - subclass axioms", "classes - classes"},
		["subclasses graphicaly as lines"] = true,
		["subclasses as text"] = false,
	}
end

function parameterTableOrAnd()
	return {
		["classes - other super class as text"] = {["or"]={"subclasses as text", "subclasses show others as text"}, ["and"]={" - subclass axioms", "classes - classes"}},
		["classes - subclass lines"] = {["or"]={"subclasses graphicaly as lines", "classes - merge subclass lines with forks"}, ["and"]={" - subclass axioms", "classes - classes", "subclasses graphicaly"}},
		["classes - other disjoint classes as compartments"] = {["or"]={"disjoint classes as text", "disjoint classes show others as text"}, ["and"]={"classes - merge disjoint classes links", "classes - classes"}},
		["classes - other equivalent classes as compartments"] = {["or"]={"equivalent classes as text", "equivalent classes show others as text"}, ["and"]={"classes - merge equivalent classes links", "classes - classes"}},
		["individuals - other same individuals as compartments"] = {["or"]={"same individuals as text", "same individuals show others as text"}, ["and"]={"individuals - merge same individuals links", "individuals - individuals"}},
		["individuals - other different individuals as compartments"] = {["or"]={"different individuals as text", "different individuals show others as text"}, ["and"]={"individuals - merge different individuals links", "individuals - individuals"}}
	}
end

function createParameterValueFromCheckBox(profile)
	local parameterTableFromCheckBox = parameterTableFromCheckBox()
	for parameterName, parentParameterName in pairs (parameterTableFromCheckBox) do
		local value = lQuery("D#CheckBox[id='" .. parameterName .. "']"):attr("checked")
		createParameterValue(value, parameterName, profile)
	end
end

function createParameterValue(value, parameterName, profile)
	local parameter = lQuery("OWL_PP#Parameter[name='" .. parameterName .. "']")
	if value == "" then value = parameter:attr("defaultValue") end
	if profile:find("/value/parameter[name='" .. parameterName .. "']"):is_empty() then 
		lQuery.create("OWL_PP#ParamValue", {value = value})
			:link("profile", profile)
			:link("parameter", parameter)
	else
		profile:find("/value:has(/parameter[name='" .. parameterName .. "'])"):attr("value", value)
	end
end

function createParametersTable(profileName)
	if profileName==nil then profileName = lQuery("OWL_PP#ParamProfile[isSystemProfile='true']"):attr("name") end
	local profile = lQuery("OWL_PP#ParamProfile[name='" .. profileName .. "']")
	local parametersTable = parametersTable()
	local parameterTableFromCheckBox = parameterTableFromCheckBox()
	local parameterTableFromRadioButton = parameterTableFromRadioButton()
	local parametersTableForOntologyImport = {}
	for param, defaultValue in pairs(parametersTable) do
		local parentParameterName = nil
		local value = defaultValue
		if parameterTableFromCheckBox[param]~=nil then
			parentParameterName = parameterTableFromCheckBox[param]
		elseif parameterTableFromRadioButton[param]~=nil then
			parentParameterName = parameterTableFromRadioButton[param]
		end
		if  parentParameterName ~= nil then
			value = profile:find("/value:has(/parameter[name='" .. param .. "'])"):attr("value")
			if type(parentParameterName) == "string" then
				local parentParameterValue = profile:find("/value:has(/parameter[name='" .. parentParameterName .. "'])"):attr("value")
				if parentParameterValue=="false" then 
					value = false
				end
			elseif type(parentParameterName) == "table" then
				local label = 0
				for i, parentParameterNames in pairs (parentParameterName) do
					local parentParameterValue = profile:find("/value:has(/parameter[name='" .. parentParameterNames .. "'])"):attr("value")
					if parentParameterValue=="false" then 
						label = 1
						break
					end
				end
				if label == 1 then
					value = false
				end
			end
		end
		local parameterTableOrAnd = parameterTableOrAnd()
		if parameterTableOrAnd[param]~=nil then
			local OrAndTable = parameterTableOrAnd[param]
			local OrTable = OrAndTable["or"]
			local AndTable = OrAndTable["and"]
			-- print(dumptable(OrTable), "OrTable")
			-- print(dumptable(AndTable), "AndTable")
			for i, Or in pairs (OrTable) do
				local OrValue = profile:find("/value:has(/parameter[name='" .. Or .. "'])"):attr("value")
				if OrValue == "true" then value = true end
			end
			for i, And in pairs (AndTable) do
				local AndValue = profile:find("/value:has(/parameter[name='" .. And .. "'])"):attr("value")
				if AndValue == "false" then value = false end
			end
		end
		if param == "classes - equivalent to and named class as subclass link" then param = "classes - equivalent to 'and' named class as subclass link" end
		if value == "true" or value==true then value=true
		else value = false end
		--print(value, "333")
		if string.sub(param, 1, 2) ~= " -" then
			parametersTableForOntologyImport[param] = value
		end
		
	end
	--print(dumptable(parametersTableForOntologyImport))
	return parametersTableForOntologyImport
end

function loadParameterProfile()
	local selectedItem = lQuery("D#ListBox[id='ListBoxWithParametersProfiles']/selected")
	if selectedItem:is_not_empty() then
		local parameterProfileName = selectedItem:attr("value")
		local profile = lQuery("OWL_PP#ParamProfile[name='" .. parameterProfileName .. "']")
		lQuery("ToolType"):remove_link("current", lQuery("ToolType"):find("/current"))
		profile:link("toolType", lQuery("ToolType"))
		lQuery("OWL_PP#ParamProfile[isSystemProfile='true']"):attr("isSystemProfile", false)
		profile:attr("isSystemProfile", true)
		
		local verBox = lQuery("D#VerticalBox[id='VerticalBoxPropertyTabs']")
		verBox:find("/component"):delete()
		verBox:link("component", parametersTabs(profile))
		verBox:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
		closeLoadParameterProfileForm()	
		
		refreshListBoxParametersProfile()
	end
end

function updateParameterProfile()
	saveParametersToMetamodel()
	closeUpdateParameterProfileForm()
end

function saveAsNewParameterProfile()
	local parameterProfileName = lQuery("D#InputField[id='NewParameterProfileName']"):attr("text")
	local profile = lQuery.create("OWL_PP#ParamProfile", {name = parameterProfileName, isSystemProfile=false})
	createParameterValueFromCheckBox(profile)
	createParameterValueFromRadioButton(profile)
	refreshListBoxParametersProfile()
	closeSaveAsNewParameterProfile()
end

function copyParameterProfile()
	local selectedItem = lQuery("D#ListBox[id='ListBoxWithParametersProfiles']/selected")
	if selectedItem:is_not_empty() then
		local newParameterProfileName = lQuery("D#InputField[id='NewParameterProfileName']"):attr("text")
		local profile = lQuery("OWL_PP#ParamProfile[name='" .. newParameterProfileName .. "']")
		local copyProfile = lQuery.create("OWL_PP#ParamProfile", {name=newParameterProfileName, isSystemProfile=false})
		saveCopiedParametersToMetamodel(copyProfile, profile)
		refreshListBoxParametersProfile()
		closeSaveAsNewParameterProfile()
	end
end

function deleteParameterProfile()
	local selectedItem = lQuery("D#ListBox[id='ListBoxWithParametersProfiles']/selected")
	if selectedItem:is_not_empty() then
		local parameterProfileName = selectedItem:attr("value")
		local profile = lQuery("OWL_PP#ParamProfile[name='" .. parameterProfileName .. "']")
		profile:find("/value"):delete()
		profile:delete()
		refreshListBoxParametersProfile()
		closeDeleteParameterProfileForm()
	end
end

function refreshListBoxParametersProfile()
	local listBox = lQuery("D#ListBox[id='ListBoxWithParametersProfiles']")
	listBox:find("/item"):delete()
	local items = collectParameterProfiles()
	listBox:link("item", items)
	listBox:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

function parameterTableExtraCheckEnabled()
	return {
	["subclasses show others as text"] = {" - subclass axioms", "classes - classes"},
	["disjoint classes show others as text"] = {"classes - merge disjoint classes links", "classes - pairs of disjoint classes as lines", "classes - classes"},
	["equivalent classes show others as text"] = {"classes - classes", "classes - pairs of equivalent classes as lines", "classes - merge equivalent classes links"},
	["same individuals show others as text"] = {"individuals - individuals", "individuals - pairs of same individuals as lines", "individuals - merge same individuals links"},
	["different individuals show others as text"] = {"individuals - individuals","individuals - pairs of different individuals as lines", "individuals - merge different individuals links"},
	["subclasses as text"] = {"classes - classes", " - subclass axioms"},
	["subclasses graphicaly as lines"] = {"classes - classes", " - subclass axioms", "subclasses graphicaly"}
  }
end

function checkEnabledSchema()
	local enabled = false
	if lQuery("Plugin[id='OWLGrEd_Schema']"):is_not_empty() and lQuery("Plugin[id='OWLGrEd_Schema']"):attr("status") == "loaded" then
		enabled = true
	end
	return enabled
end

function checkEnabled(checkBoxId)
	local enabled = true
	
	local parameterTableFromCheckBox = parameterTableFromCheckBox()
	local parameterTableFromRadioButton = parameterTableFromRadioButton()
	local parameterTableExtraCheckEnabled = parameterTableExtraCheckEnabled()
	
	local parentParameterName = nil
	if parameterTableExtraCheckEnabled[checkBoxId]~=nil then
		parentParameterName = parameterTableExtraCheckEnabled[checkBoxId]
	elseif parameterTableFromCheckBox[checkBoxId]~=nil then
		parentParameterName = parameterTableFromCheckBox[checkBoxId]
	elseif parameterTableFromRadioButton[checkBoxId]~=nil then
		parentParameterName = parameterTableFromRadioButton[checkBoxId]
	end
	if  parentParameterName ~= nil then
		if type(parentParameterName) == "string" then
			local parentParameterValue = lQuery("D#CheckBox[id='" .. parentParameterName .. "']"):attr("checked")
			if parentParameterValue=="false" then 
				enabled = false
			end
		elseif type(parentParameterName) == "table" then
			local label = 0
			for i, parentParameterNames in pairs (parentParameterName) do
				local parentParameterValue = lQuery("D#CheckBox[id='" .. parentParameterNames .. "']"):attr("checked")
				if parentParameterValue=="false" then 
					label = 1
					break
				elseif lQuery("D#RadioButton[id='" .. parentParameterNames .. "']"):attr("selected") == "false" then label = 1
				end
			end
			if label == 1 then
				enabled = false
			end
		end
	end
	return enabled
end

function enabledParameterTable()
	return {
		["data properties - data properties"] = {"data properties - sub data properties", "data properties - equivalent data properties", "data properties - disjoint data properties", "data properties - is functional", "data properties - data property annotations", "data properties - show subclass of cardinality restrictions as multiplicity"}
		,["individuals - merge different individuals links"] = {"different individuals as text", "individuals - pairs of different individuals as lines", "individuals - mutualy different individuals larger then 2 as boxes", "different individuals show others as text"}
		,["individuals - merge same individuals links"] = {"same individuals as text", "individuals - pairs of same individuals as lines", "individuals - mutualy same individuals larger then 2 as boxes", "same individuals show others as text"}
		,["individuals - individuals"] = {"individuals - merge same individuals links", "individuals - merge different individuals links", "different individuals as text", "individuals - pairs of different individuals as lines", "individuals - mutualy different individuals larger then 2 as boxes", "different individuals show others as text", "same individuals as text", "individuals - pairs of same individuals as lines", "individuals - mutualy same individuals larger then 2 as boxes", "same individuals show others as text", "individuals - individual annotations", "individuals - class assertions", "individuals - object property assertions", "individuals - data property assertions", "individuals - negative object property assertions", "individuals - negative data property assertions"}
		,["object properties - object properties"] = {"object properties - merge inverse object properties", "object properties - sub object properties", "object properties - disjoint object properties", "object properties - equivalent object properties", "object properties - property chains", "object properties - object property annotations", "object properties - is functional", "object properties - is inverSefunctional", "object properties - is symmetric", "object properties - is asymmetric", "object properties - is transitive", "object properties - is reflexive", "object properties - is irreflexive", "object properties - show subclass of some as line", "object properties - show subclass of only as line", "object properties - show subclass of min as line", "object properties - show subclass of max as line", "object properties - show subclass of exact as line", "object properties - show subclass of cardinality restrictions as multiplicity"}
		,[" - subclass axioms"] = {"subclasses as text", "subclasses graphicaly", "subclasses graphicaly as lines", "classes - merge subclass lines with forks", "subclasses show others as text", "classes - make top classes subclass of thing", "classes - equivalent to and named class as subclass link", "classes - make named classes subclass of corresponding anonymous unions", "classes - anonymous subclasses as boxes"}
		,["classes - merge disjoint classes links"] = {"disjoint classes as text", "classes - pairs of disjoint classes as lines", "classes - mutualy disjoint classes larger then 2 as boxes", "disjoint classes show others as text"}
		,["classes - merge equivalent classes links"] = {"equivalent classes as text", "classes - pairs of equivalent classes as lines", "classes - mutualy equivalent classes larger then 2 as boxes", "equivalent classes show others as text"}
		,["classes - classes"] = {" - subclass axioms", "classes - merge disjoint classes links", "classes - merge equivalent classes links", "subclasses as text", "subclasses graphicaly", "subclasses graphicaly as lines", "classes - merge subclass lines with forks", "subclasses show others as text", "classes - make top classes subclass of thing", "classes - equivalent to and named class as subclass link", "classes - make named classes subclass of corresponding anonymous unions", "classes - anonymous subclasses as boxes", "disjoint classes as text", "classes - pairs of disjoint classes as lines", "classes - mutualy disjoint classes larger then 2 as boxes", "disjoint classes show others as text", "equivalent classes as text", "classes - pairs of equivalent classes as lines", "classes - mutualy equivalent classes larger then 2 as boxes", "equivalent classes show others as text", "classes - keys", "classes - class annotations"}
		,["subclasses as text"] = {"subclasses graphicaly as lines", "classes - merge subclass lines with forks"}
		,["subclasses graphicaly"] = {"subclasses graphicaly as lines", "classes - merge subclass lines with forks"}
		,["disjoint classes as text"] = {"classes - mutualy disjoint classes larger then 2 as boxes", "disjoint classes show others as text"}
		,["classes - pairs of disjoint classes as lines"] = {"classes - mutualy disjoint classes larger then 2 as boxes", "disjoint classes show others as text"}
		,["equivalent classes as text"] = {"classes - mutualy equivalent classes larger then 2 as boxes", "equivalent classes show others as text"}
		,["classes - pairs of equivalent classes as lines"] = {"classes - mutualy equivalent classes larger then 2 as boxes", "equivalent classes show others as text"}
		,["same individuals as text"] = {"individuals - mutualy same individuals larger then 2 as boxes", "same individuals show others as text"}
		,["individuals - pairs of same individuals as lines"] = {"individuals - mutualy same individuals larger then 2 as boxes", "same individuals show others as text"}
		,["different individuals as text"] = {"individuals - mutualy different individuals larger then 2 as boxes", "different individuals show others as text"}
		,["individuals - pairs of different individuals as lines"] = {"individuals - mutualy different individuals larger then 2 as boxes", "different individuals show others as text"}
	}
end

function enableFields()
	local checkedId = lQuery("D#Event/source"):attr("id")
	local enabledParameterTable = enabledParameterTable()
	local enabledParameterFields = enabledParameterTable[checkedId]
	local checked = lQuery("D#Event/source"):attr("checked")
	local fields
	for i, form in pairs(enabledParameterFields) do
		local field = lQuery("D#Component[id='" .. form .. "']")
		field:attr("enabled", checkEnabled(form))
		field:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

function enableFieldsAsText()
	local checkedId = lQuery("D#Event/source"):attr("id")
	local enabledParameterTable = enabledParameterTable()
	local enabledParameterFields = enabledParameterTable[checkedId]
	for i, form in pairs(enabledParameterFields) do
		local field = lQuery("D#Component[id='" .. form .. "']")
		field:attr("enabled", false)
		field:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

function enableFieldsGraphically()
	local checkedId = lQuery("D#Event/source"):attr("id")
	local enabledParameterTable = enabledParameterTable()
	local enabledParameterFields = enabledParameterTable[checkedId]
	for i, form in pairs(enabledParameterFields) do
		local field = lQuery("D#Component[id='" .. form .. "']")
		field:attr("enabled", true)
		field:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

function showForm()
	local pValueSet = lQuery("ToolType"):find("/current")
	show_window(pValueSet)
end

function show_window(pValueSet)
  showClases = true
  local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.close()")
  })
  local plus_button = lQuery.create("D#Button", {
    caption = "+"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.showAdvancedForm()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "visualization_parameters"
    ,caption = "Ontology loading preferences"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.close()")
    ,minimumWidth = 410
	,component = {
		lQuery.create("D#HorizontalBox",{
			id = "HorizontalAllForms"
			,component = {
				lQuery.create("D#VerticalBox",{
					id = "VerticalBoxPropertyTabs"
					,component = {
						parametersTabs(pValueSet)
					}
				})
				,advancedButtonsAutoShow()
				,advancedProfilesAutoShow()
			}})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
end

function advancedButtonsAutoShow()
	if lQuery("ToolType/tag[key='advancedParametersShow']"):attr("value") == "true" then
		return advancedButtons()
	end
end

function advancedProfilesAutoShow()
	if lQuery("ToolType/tag[key='advancedParametersShow']"):attr("value") == "true" then
		return advancedProfiles()
	end
end

function saveCheckBoxParameterShow(parameter)
	local event = lQuery("D#Event/source")
	saveCheckBoxParameter()
	local dependentParametersCheckBox = getDependentParameters(parameter,"checkBox")
	local dependentParametersRadioButton = getDependentParameters(parameter,"radioButton")
	for key, value in pairs(dependentParametersCheckBox) do
		local field = lQuery("D#Component[id='" .. value .. "']")
		field:attr("enabled",event:attr("checked"))
		field:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
	
	for key, value in pairs(dependentParametersRadioButton) do
		local field = lQuery("D#Component[id='" .. value .. "']")
		field:each(function(f)
			f:attr("enabled",event:attr("checked"))
			f:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
		end)
		
	end
end



function saveCheckBoxParameterShowDataTypes()
	saveCheckBoxParameterShow("showDataTypes")
end
function saveCheckBoxParameterShowUnloadedAxioms()
	saveCheckBoxParameterShow("showUnloadedAxioms")
end
function saveCheckBoxParameterShowClasses()
	saveCheckBoxParameterShow("showClasses")
end

function saveCheckBoxParameterShowSubclasses()
	saveCheckBoxParameterShow("showSubclasses")
end

function saveCheckBoxParameterShowDisjointClasses()
	saveCheckBoxParameterShow("showDisjointClasses")
end

function saveCheckBoxParametershowEquivalentClasses()
	saveCheckBoxParameterShow("showEquivalentClasses")
end

function saveCheckBoxParametershowClassAnnotations()
	saveCheckBoxParameterShow("showClassAnnotations")
end

function saveCheckBoxParametershowObjectProperties()
	saveCheckBoxParameterShow("showObjectProperties")
end

function saveCheckBoxParametershowObjectPropertyAnnotations()
	saveCheckBoxParameterShow("showObjectPropertyAnnotations")
end

function saveCheckBoxParametershowDataProperties()
	saveCheckBoxParameterShow("showDataProperties")
end

function saveCheckBoxParametershowDataPropertyAnnotations()
	saveCheckBoxParameterShow("showDataPropertyAnnotations")
end

function saveCheckBoxParametershowPropertyRestrictions()
	saveCheckBoxParameterShow("showPropertyRestrictions")
end

function saveCheckBoxParametershowPropertyRestrictionsGraphically()
	saveCheckBoxParameterShow("showPropertyRestrictionsGraphically")
end

function saveCheckBoxParametershowIndividuals()
	saveCheckBoxParameterShow("showIndividuals")
end

function saveCheckBoxParametershowSameIndividuals()
	saveCheckBoxParameterShow("showSameIndividuals")
end

function saveCheckBoxParametershowDifferentIndividuals()
	saveCheckBoxParameterShow("showDifferentIndividuals")
end

function saveCheckBoxParametershowIndividualAnnotations()
	saveCheckBoxParameterShow("showIndividualAnnotations")
end

function saveCheckBoxParameteruseContainersForSingleNodesOntoAnnotations()
	saveCheckBoxParameterShow("useContainersForSingleNodesOntoAnnotations")
end

function saveCheckBoxParameteruseContainersForSingleNodesDataTypes()
	saveCheckBoxParameterShow("useContainersForSingleNodesDataTypes")
end

function saveCheckBoxParameteruseContainersForSingleNodesAnnotPropDefs()
	saveCheckBoxParameterShow("useContainersForSingleNodesAnnotPropDefs")
end

function saveCheckBoxParameteruseContainersForSingleNodesIndividuals()
	saveCheckBoxParameterShow("useContainersForSingleNodesIndividuals")
end

function saveCheckBoxParameteruseContainersForSingleNodes()
	saveCheckBoxParameterShow("useContainersForSingleNodes")
end

function saveCheckBoxParametershowIndividualClassAssertions()
	saveCheckBoxParameterShow("showIndividualClassAssertions")
end

function getDependentParameters(parameter, parameterType)
	local dependentParameters = dependentParameters()
	return dependentParameters[parameter][parameterType]
end

function saveCheckBoxParameter()
	local checkBox = lQuery("D#Event/source"):last()
	local checkedId = checkBox:attr("id")
	local checked = checkBox:attr("checked")
	local pValueSet = lQuery("ToolType/current")
	local pValue = pValueSet:find("/pValue[pName = '" .. checkedId .. "']")
	pValue:attr("pValue", checked)
end

function saveRadioButtonParameterShow(parameter)
	local event = lQuery("D#Event/source")
	saveRadioButtonParameter()
	local enabled = false
	if parameter == "showDataPropertiesType" and event:attr("caption") == "As text" then enabled = true
	elseif parameter == "showDataPropertiesType" and event:attr("caption") == "Graphically" then enabled = false
	elseif event:attr("caption") == "Graphically" or event:attr("caption") == "As forks (if > 1)" then enabled = true end
	local dependentParametersCheckBox = getDependentParameters(parameter,"checkBox")
	local dependentParametersRadioButton = getDependentParameters(parameter,"radioButton")
	for key, value in pairs(dependentParametersCheckBox) do
		local field = lQuery("D#Component[id='" .. value .. "']")
		field:attr("enabled",enabled)
		field:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
	
	for key, value in pairs(dependentParametersRadioButton) do
		local field = lQuery("D#Component[id='" .. value .. "']")
		field:each(function(f)
			f:attr("enabled",enabled)
			f:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
		end)
		
	end
end

function saveRadioButtonParametershowSubclassesType()
	saveRadioButtonParameterShow("showSubclassesType")
end

function saveRadioButtonParametershowSubclassesGraphicsType()
	saveRadioButtonParameterShow("showSubclassesGraphicsType")
end

function saveRadioButtonParametershowDisjointClassesType()
	saveRadioButtonParameterShow("showDisjointClassesType")
end

function saveRadioButtonParametershowEquivalentClassesType()
	saveRadioButtonParameterShow("showEquivalentClassesType")
end

function saveRadioButtonParametershowObjectPropertiesType()
	saveRadioButtonParameterShow("showObjectPropertiesType")
end

function saveRadioButtonParametershowDataPropertiesType()
	saveRadioButtonParameterShow("showDataPropertiesType")
end

function saveRadioButtonParametershowSameIndividualsType()
	saveRadioButtonParameterShow("showSameIndividualsType")
end

function saveRadioButtonParametershowDataPropertiesType()
	saveRadioButtonParameterShow("showDataPropertiesType")
end

function saveRadioButtonParametershowDifferentIndividualsType()
	saveRadioButtonParameterShow("showDifferentIndividualsType")
end

function saveRadioButtonParametershowClassAssertionsType()
	saveRadioButtonParameterShow("showClassAssertionsType")
end

function saveRadioButtonParameter()
	local radioButton = lQuery("D#Event/source"):last()
	local radioButtonCaption = radioButton:attr("caption")
	local radioButtonId = radioButton:attr("id")
	local pValueSet = lQuery("ToolType/current")
	local pValue = pValueSet:find("/pValue[pName = '" .. radioButtonId .. "']")
	pValue:attr("pValue", radioButtonCaption)
end

function saveInputFieldParameter()
	local inputField = lQuery("D#Event/source")
	local inputFieldId = inputField:attr("id")
	local inputFieldText = inputField:attr("text")
	local pValueSet = lQuery("ToolType/current")
	local pValue = pValueSet:find("/pValue[pName = '" .. inputFieldId .. "']")
	pValue:attr("pValue", inputFieldText)
	-- print(inputFieldText)
end

function selectRadioButtonValue(id, caption, pValueSet)
	local pValue = pValueSet:find("/pValue[pName = '" .. id .. "']"):attr("pValue")
	if caption == pValue then return true else return false end
end

function parametersTabs(pValueSet)
 
	local tabs = lQuery.create("D#TabContainer", {
			component = {
				lQuery.create("D#Tab", {
					caption = "General"
					,horizontalAlignment = -1
					,verticalAlignment = -1
					,component = {
						lQuery.create("D#VerticalBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,component = {
								lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Ontology annotations"
											,id = "showOntoAnnotations"
											,checked = pValueSet:find("/pValue[pName = 'showOntoAnnotations']"):attr("pValue")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
									lQuery.create("D#VerticalBox", {
										horizontalAlignment = -1
										,id = "showSubclassesType"
										,component = {
											lQuery.create("D#RadioButton", {
												caption = "Show in Seed symbol"
												,enabled = false
												,leftMargin = 30
												,id = "showOntoAnnotationsInSeed"
												,selected = selectRadioButtonValue("showOntoAnnotationsInSeed", "Show in Seed symbol", pValueSet)
																			-- ,enabled = checkEnabled("subclasses as text")
												,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
											})
											,lQuery.create("D#RadioButton", {
												caption = "Show in diagram"
												,leftMargin = 30
												,id = "showOntoAnnotationsInSeed"
																			-- ,enabled = checkEnabled("subclasses graphicaly")
												,selected = selectRadioButtonValue("showOntoAnnotationsInSeed", "Show in diagram", pValueSet)
												,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
											})
										}
									})
																--,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									,lQuery.create("D#Column", {
										verticalAlignment = -1
										,component = {lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
									})
									}
								})
								
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Unvisualized axioms"
											-- ,enabled = false
											,id = "showUnloadedAxioms"
											,checked = pValueSet:find("/pValue[pName = 'showUnloadedAxioms']"):attr("pValue")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameterShowUnloadedAxioms()")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Show in Annotation symbol"
											-- ,enabled = false
											,enabled = chechIfEnabled(pValueSet, {"showUnloadedAxioms"})
											,leftMargin = 30
											,id = "showUnloadedAxioms InComment"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showUnloadedAxioms InComment']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Display on demand"
											-- ,enabled = false
											,enabled = chechIfEnabled(pValueSet, {"showUnloadedAxioms"})
											,leftMargin = 30
											,id = "showUnloadedAxioms DisplayOnDemand"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showUnloadedAxioms DisplayOnDemand']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Annotation property definitions"
											,id = "showAnnotationPropertyDefs"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showAnnotationPropertyDefs']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Data type definitions"
											,id = "showDataTypes"
											--,enabled = checkEnabled("data-type - data types")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameterShowDataTypes()")
											,checked = pValueSet:find("/pValue[pName = 'showDataTypes']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								-- ,lQuery.create("D#Row", {
									-- horizontalAlignment = -1
									-- ,component = {
										-- lQuery.create("D#CheckBox", {
											-- caption = "Link to attribute classes"
											-- ,enabled = chechIfEnabled(pValueSet, {"showDataTypes"})
											-- ,leftMargin = 30
											-- ,id = "showDataTypesLinkToAttributeClasses"
											-- ,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											-- ,checked = pValueSet:find("/pValue[pName = 'showDataTypesLinkToAttributeClasses']"):attr("pValue")
										-- })
										-- ,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									-- }
								-- })
								,lQuery.create("D#HorizontalBox", {
									-- horizontalAlignment = -1
									component = {
										lQuery.create("D#Label", {
											caption = "Show Annotations in"
										})
										,lQuery.create("D#InputField", {
											id = "showAnnotationsInLanguages"
											,minimumWidth = 70
											-- ,enabled = false
											,text = pValueSet:find("/pValue[pName = 'showAnnotationsInLanguages']"):attr("pValue")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveInputFieldParameter()")
										})
										,lQuery.create("D#Label", {caption = "languages"})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Show class expression as box if referenced at least"
											,enabled = false
											,id = "showClassExprsAsBoxByCountEnable"
											--,enabled = checkEnabled("data-type - data types")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showClassExprsAsBoxByCountEnable']"):attr("pValue")
										})
										,lQuery.create("D#InputField", {
											id = "showClassExprsAsBoxCount"
											,enabled = false
											,text = pValueSet:find("/pValue[pName = 'showClassExprsAsBoxCount']"):attr("pValue")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveInputFieldParameter()")
										})
										,lQuery.create("D#Label", {caption = "times"})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Create schema assertions for corresponding domain/range assertions"
											-- caption = "Add schema assertions to domain assertions"
											-- ,enabled = false
											,id = "addSchemaAssertionsToDomainAssertions"
											,enabled = checkEnabledSchema()
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'addSchemaAssertionsToDomainAssertions']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Automatically generate namespaces from entity URI"
											-- ,enabled = false
											,id = "AutomaticallyGenerateNamespacesFromEntityURI"
											,enabled = true
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'AutomaticallyGenerateNamespacesFromEntityURI']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Discard previous OWLGrEd version annotations"
											-- ,enabled = false
											,id = "DiscardPreviousOWLGrEdVersionAnnotations"
											,enabled = true
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'DiscardPreviousOWLGrEdVersionAnnotations']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
							}
						})
					}
				})
				,lQuery.create("D#Tab", {
					caption = "Classes"
					,horizontalAlignment = -1
					,verticalAlignment = -1
					,component = {
						lQuery.create("D#VerticalBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,component = {
								lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Show classes"
											,id = "showClasses"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameterShowClasses()")
											,checked = pValueSet:find("/pValue[pName = 'showClasses']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								
								,lQuery.create("D#GroupBox", {
									minimumWidth = 385
									,component = {
										lQuery.create("D#HorizontalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Subclasses"
													,id = "showSubclasses"
													,enabled = chechIfEnabled(pValueSet, {"showClasses"})
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameterShowSubclasses()")
													,checked = pValueSet:find("/pValue[pName = 'showSubclasses']"):attr("pValue")
												})
												,lQuery.create("D#VerticalBox", {
													horizontalAlignment = -1
													,verticalAlignment = -1
													,component = {
														lQuery.create("D#Row", {
															horizontalAlignment = -1
															,component = {
																lQuery.create("D#VerticalBox", {
																	horizontalAlignment = -1
																	,id = "showSubclassesType"
																	,component = {
																		lQuery.create("D#RadioButton", {
																			caption = "As text"
																			,id = "showSubclassesType"
																			,selected = selectRadioButtonValue("showSubclassesType", "As text", pValueSet)
																			,enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses"})
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowSubclassesType()")
																		})
																		,lQuery.create("D#RadioButton", {
																			caption = "Graphically"
																			,id = "showSubclassesType"
																			,enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses"})
																			,selected = selectRadioButtonValue("showSubclassesType", "Graphically", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowSubclassesType()")
																		})
																	}
																})
																--,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
																,lQuery.create("D#Column", {
																	verticalAlignment = -1
																	,component = {lQuery.create("D#Button", {caption = "..",enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																})
															}
														})
														
														,lQuery.create("D#GroupBox", {
															horizontalAlignment = -1
															,verticalAlignment = -1
															,leftMargin = 30
															,component = {
																lQuery.create("D#Row", {
																	horizontalAlignment = -1
																	,component = {
																		lQuery.create("D#VerticalBox", {
																			horizontalAlignment = -1
																			,id = "showSubclassesGraphicsType"
																			,component = {
																				lQuery.create("D#RadioButton", {
																					caption = "As lines"
																					--,leftMargin = 30
																					,id = "showSubclassesGraphicsType"
																					,enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses", "showSubclassesType"})
																					,selected = selectRadioButtonValue("showSubclassesGraphicsType", "As lines", pValueSet)
																					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowSubclassesGraphicsType()")
																				})
																				,lQuery.create("D#RadioButton", {
																					caption = "As forks (if > 1)"
																					--,leftMargin = 30
																					,id = "showSubclassesGraphicsType"
																					,enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses", "showSubclassesType"})
																					,selected = selectRadioButtonValue("showSubclassesGraphicsType", "As forks (if > 1)", pValueSet)
																					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowSubclassesGraphicsType()")
																				})
																			}
																		})
																		,lQuery.create("D#Column", {
																			verticalAlignment = -1
																			,component = {lQuery.create("D#Button", {caption = "..",enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses", "showSubclassesType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																		})
																	}
																})
																,lQuery.create("D#Row", {
																	horizontalAlignment = -1
																	,component = {
																		lQuery.create("D#CheckBox", {
																			leftMargin = 30
																			,caption = "Create Auto forks for Disjoint Subclasses"
																			,id = "showSubclassesAutoForksForDisjoint"
																			-- ,enabled = false
																			,enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses", "showSubclassesType", "showSubclassesGraphicsType"})
																			,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																			,checked = pValueSet:find("/pValue[pName = 'showSubclassesAutoForksForDisjoint']"):attr("pValue")
																		})
																		,lQuery.create("D#Button", {caption = "..",enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses", "showSubclassesType", "showSubclassesGraphicsType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
																	}
																})
																
														}})
														,lQuery.create("D#Button", {caption = "Extra items",enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses", "showSubclassesType"}), eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.subClassExtraItems()"), enabled = chechIfEnabled(pValueSet, {"showClasses", "showSubclasses"})})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#GroupBox", {
									minimumWidth = 385
									,component = {
										lQuery.create("D#HorizontalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Disjoint classes"
													,id = "showDisjointClasses"
													,enabled = chechIfEnabled(pValueSet, {"showClasses"})
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameterShowDisjointClasses()")
													,checked = pValueSet:find("/pValue[pName = 'showDisjointClasses']"):attr("pValue")
												})
												,lQuery.create("D#VerticalBox", {
													horizontalAlignment = -1
													,verticalAlignment = -1
													,component = {
														lQuery.create("D#Row", {
															horizontalAlignment = -1
															,component = {
																lQuery.create("D#VerticalBox", {
																	horizontalAlignment = -1
																	,id = "showDisjointClassesType"
																	,component = {
																		lQuery.create("D#RadioButton", {
																			caption = "As text"
																			,id = "showDisjointClassesType"
																			,enabled = chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses"})
																			,selected = selectRadioButtonValue("showDisjointClassesType", "As text", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowDisjointClassesType()")
																		})
																		,lQuery.create("D#RadioButton", {
																			caption = "Graphically"
																			,id = "showDisjointClassesType"
																			,enabled =  chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses"})
																			,selected = selectRadioButtonValue("showDisjointClassesType", "Graphically", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowDisjointClassesType()")
																		})
																}})
																,lQuery.create("D#Column", {
																	verticalAlignment = -1
																	,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																})
															}
														})
														
														,lQuery.create("D#Row", {
															component = {
																lQuery.create("D#CheckBox", {
																	caption = "Group as boxes (if > 2)"
																	,leftMargin = 20
																	--,enabled = false
																	,id = "showDisjointClassesGraphicsGroupAsBoxes"
																	,enabled =  chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses", "showDisjointClassesType"})
																	,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																	,checked = pValueSet:find("/pValue[pName = 'showDisjointClassesGraphicsGroupAsBoxes']"):attr("pValue")
																})
																,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses", "showDisjointClassesType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
															}
														})
														,lQuery.create("D#Row", {
															component = {
																lQuery.create("D#CheckBox", {
																	caption = "Hide information, if not presented graphically"
																	-- ,enabled = false
																	,leftMargin = 20
																	,id = "showDisjointClassesHideNotGraphical"
																	-- ,enabled =  chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses", "showDisjointClassesType"})
																	,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																	,checked = pValueSet:find("/pValue[pName = 'showDisjointClassesHideNotGraphical']"):attr("pValue")
																})
																,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses", "showDisjointClassesType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
															}
														})
														,lQuery.create("D#Row", {
															component = {
																lQuery.create("D#CheckBox", {
																	caption = "Use Disjoint mark at forks"
																	--,enabled = false
																	,id = "showDisjointClassesMarkAtForks"
																	,enabled =  chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses"})
																	,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																	,checked = pValueSet:find("/pValue[pName = 'showDisjointClassesMarkAtForks']"):attr("pValue")
																})
																,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showClasses", "showDisjointClasses"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
															}
														})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#GroupBox", {
									minimumWidth = 385
									,component = {
										lQuery.create("D#HorizontalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Equivalent classes"
													,id = "showEquivalentClasses"
													,enabled =  chechIfEnabled(pValueSet, {"showClasses"})
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowEquivalentClasses()")
													,checked = pValueSet:find("/pValue[pName = 'showEquivalentClasses']"):attr("pValue")
												})
												,lQuery.create("D#VerticalBox", {
													horizontalAlignment = -1
													,verticalAlignment = -1
													,component = {
														lQuery.create("D#Row", {
															horizontalAlignment = -1
															,component = {
																lQuery.create("D#VerticalBox", {
																	horizontalAlignment = -1
																	,id = "showEquivalentClassesType"
																	,component ={
																		lQuery.create("D#RadioButton", {
																			caption = "As text"
																			,id = "showEquivalentClassesType"
																			,enabled =  chechIfEnabled(pValueSet, {"showClasses", "showEquivalentClasses"})
																			,selected = selectRadioButtonValue("showEquivalentClassesType", "As text", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowEquivalentClassesType()")
																		})
																		,lQuery.create("D#RadioButton", {
																			caption = "Graphically"
																			,id = "showEquivalentClassesType"
																			,enabled =  chechIfEnabled(pValueSet, {"showClasses", "showEquivalentClasses"})
																			,selected = selectRadioButtonValue("showEquivalentClassesType", "Graphically", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowEquivalentClassesType()")
																		})
																	}
																})
																,lQuery.create("D#Column", {
																	verticalAlignment = -1
																	,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showClasses", "showEquivalentClasses"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																})
															}
														})
														,lQuery.create("D#Row", {
															component = {
																lQuery.create("D#CheckBox", {
																	caption = "Group as boxes (if > 2)"
																	,leftMargin = 20
																	,enabled =  chechIfEnabled(pValueSet, {"showClasses", "showEquivalentClasses", "showEquivalentClassesType"})
																	,id = "showEquivalentClassesGraphicsGroupAsBoxes"
																	,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																	,checked = pValueSet:find("/pValue[pName = 'showEquivalentClassesGraphicsGroupAsBoxes']"):attr("pValue")
																})
																,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showClasses", "showEquivalentClasses", "showEquivalentClassesType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
															}
														})
														,lQuery.create("D#Row", {
															component = {
																lQuery.create("D#CheckBox", {
																	caption = "Hide information, if not presented graphically"
																	,leftMargin = 20
																	-- ,enabled = false
																	-- ,enabled = chechIfEnabled(pValueSet, {"showClasses", "showEquivalentClasses", "showEquivalentClassesType"})
																	,id = "showEquivalentClassesHideNotGraphical"
																	,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																	,checked = pValueSet:find("/pValue[pName = 'showEquivalentClassesHideNotGraphical']"):attr("pValue")
																})
																,lQuery.create("D#Button", {caption = "..",enabled = chechIfEnabled(pValueSet, {"showClasses", "showEquivalentClasses", "showEquivalentClassesType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
															}
														})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Keys"
											,id = "showKeys"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showKeys']"):attr("pValue")
											,enabled = chechIfEnabled(pValueSet, {"showClasses"})
											,leftMargin = 10
										})
										,lQuery.create("D#Button", {caption = "..",enabled = chechIfEnabled(pValueSet, {"showClasses"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#GroupBox", {
									minimumWidth = 385
									,bottomMargin = 30
									,component = {
										lQuery.create("D#HorizontalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Annotations"
													,id = "showClassAnnotations"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowClassAnnotations()")
													,checked = pValueSet:find("/pValue[pName = 'showClassAnnotations']"):attr("pValue")
													,enabled = chechIfEnabled(pValueSet, {"showClasses"})
												})
												,lQuery.create("D#VerticalBox", {
													horizontalAlignment = -1
													,verticalAlignment = -1
													,component = {
														lQuery.create("D#Row", {
															horizontalAlignment = -1
															,component = {
																lQuery.create("D#VerticalBox", {
																	horizontalAlignment = -1
																	,id = "showClassAnnotationsType"
																	,component ={
																		lQuery.create("D#RadioButton", {
																			caption = "As text"
																			,id = "showClassAnnotationsType"
																			,enabled = chechIfEnabled(pValueSet, {"showClasses", "showClassAnnotations"})
																			,selected = selectRadioButtonValue("showClassAnnotationsType", "As text", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
																		})
																		,lQuery.create("D#RadioButton", {
																			caption = "Graphically"
																			,id = "showClassAnnotationsType"
																			,enabled = chechIfEnabled(pValueSet, {"showClasses", "showClassAnnotations"})
																			,selected = selectRadioButtonValue("showClassAnnotationsType", "Graphically", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
																		})
																	}
																})
																,lQuery.create("D#Column", {
																	verticalAlignment = -1
																	,component = {lQuery.create("D#Button", {caption = "..",enabled = chechIfEnabled(pValueSet, {"showClasses", "showClassAnnotations"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																})
															}
														})
														,lQuery.create("D#Row", {
															component = {
																lQuery.create("D#CheckBox", {
																	caption = "Enable special comment redesign"
																	,id = "showClassAnnotationsEnableSpecComments"
																	,enabled = chechIfEnabled(pValueSet, {"showClasses", "showClassAnnotations"})
																	--,enabled = checkEnabled("classes - mutualy equivalent classes larger then 2 as boxes")
																	,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																	,checked = pValueSet:find("/pValue[pName = 'showClassAnnotationsEnableSpecComments']"):attr("pValue")
																})
																,lQuery.create("D#Button", {caption = "..",enabled = chechIfEnabled(pValueSet, {"showClasses", "showClassAnnotations"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
															}
														})
													}
												})
											}
										})
								}})
							}
						})
					}
				})
				,lQuery.create("D#Tab", {
					caption = "Properties"
					,horizontalAlignment = -1
					,verticalAlignment = -1
					,component = {
						lQuery.create("D#GroupBox", {
							component = {
								lQuery.create("D#VerticalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Show object properties"
											,id = "showObjectProperties"
											,enabled = checkEnabled("object properties - object properties")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowObjectProperties()")
											,checked = pValueSet:find("/pValue[pName = 'showObjectProperties']"):attr("pValue")
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,leftMargin = 20
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#VerticalBox", {
															horizontalAlignment = -1
															,id = "showObjectPropertiesType"
															,component ={
																lQuery.create("D#RadioButton", {
																	caption = "As text"
																	,id = "showObjectPropertiesType"
																	,enabled =  chechIfEnabled(pValueSet, {"showObjectProperties"})
																	,selected = selectRadioButtonValue("showObjectPropertiesType", "As text", pValueSet)
																	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowObjectPropertiesType()")
																})
																,lQuery.create("D#RadioButton", {
																	caption = "Graphically"
																	,id = "showObjectPropertiesType"
																	,enabled =  chechIfEnabled(pValueSet, {"showObjectProperties"})
																	,selected = selectRadioButtonValue("showObjectPropertiesType", "Graphically", pValueSet)
																	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowObjectPropertiesType()")
																})
															}
														})
														,lQuery.create("D#Column", {
															verticalAlignment = -1
															,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showObjectProperties"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
														})
													}
												})
												,lQuery.create("D#Row", {
													component = {
														lQuery.create("D#CheckBox", {
															caption = "Merge inverse properties"
															,id = "showObjectPropertiesMergeInverse"
															,type = "CheckBox"
															,leftMargin = 20
															,enabled =  chechIfEnabled(pValueSet, {"showObjectProperties", "showObjectPropertiesType"})
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesMergeInverse']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showObjectProperties", "showObjectPropertiesType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#CheckBox", {
													caption = "Annotations"
													,id = "showObjectPropertyAnnotations"
													,type = "CheckBox"
													,enabled =  chechIfEnabled(pValueSet, {"showObjectProperties"})
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowObjectPropertyAnnotations()")
													,checked = pValueSet:find("/pValue[pName = 'showObjectPropertyAnnotations']"):attr("pValue")
												})
												,lQuery.create("D#GroupBox", {
													horizontalAlignment = -1
													,verticalAlignment = -1
													,leftMargin = 20
													,component = {
														lQuery.create("D#Row", {
															horizontalAlignment = -1
															,component = {
																lQuery.create("D#VerticalBox", {
																	horizontalAlignment = -1
																	,id = "showObjectPropertyAnnotationsType"
																	,component = {
																		lQuery.create("D#RadioButton", {
																			caption = "As text"
																			,id = "showObjectPropertyAnnotationsType"
																			,enabled =  chechIfEnabled(pValueSet, {"showObjectProperties", "showObjectPropertyAnnotations"})
																			,selected = selectRadioButtonValue("showObjectPropertyAnnotationsType", "As text", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
																		})
																		,lQuery.create("D#RadioButton", {
																			caption = "Graphically"
																			,id = "showObjectPropertyAnnotationsType"
																			,enabled =  chechIfEnabled(pValueSet, {"showObjectProperties", "showObjectPropertyAnnotations"})
																			,selected = selectRadioButtonValue("showObjectPropertyAnnotationsType", "Graphically", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
																		})
																	}
																})
																,lQuery.create("D#Column", {
																	verticalAlignment = -1
																	,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showObjectProperties", "showObjectPropertyAnnotations"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																})
															}
														})	
													}})
												,lQuery.create("D#Button", {caption = "Extra..", enabled =  chechIfEnabled(pValueSet, {"showObjectProperties"}),eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.extraItemsObjectProperties()")})
											}
										})
									}
								})
						}})
						,lQuery.create("D#GroupBox", {
							component = {
								lQuery.create("D#VerticalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Show data properties"
											,id = "showDataProperties"
											,enabled = checkEnabled("data properties - data properties")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowDataProperties()")
											,checked = pValueSet:find("/pValue[pName = 'showDataProperties']"):attr("pValue")
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,leftMargin = 20
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#VerticalBox", {
															horizontalAlignment = -1
															,id = "showDataPropertiesType"
															,component ={
																lQuery.create("D#RadioButton", {
																	caption = "As text"
																	,id = "showDataPropertiesType"
																	,enabled =  chechIfEnabled(pValueSet, {"showDataProperties"})
																	,selected = selectRadioButtonValue("showDataPropertiesType", "As text", pValueSet)
																	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowDataPropertiesType()") 
																})
																,lQuery.create("D#Row", {
																	component = {
																		lQuery.create("D#CheckBox", {
																			caption = "Link type to dataType"
																			,id = "showDataTypesLinkToAttributeClasses"
																			,type = "CheckBox"
																			,leftMargin = 20
																			,enabled =  chechIfEnabled(pValueSet, {"showDataProperties", "showDataPropertiesType"})
																			,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																			,checked = pValueSet:find("/pValue[pName = 'showDataTypesLinkToAttributeClasses']"):attr("pValue")
																		})
																		,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showObjectProperties", "showObjectPropertiesType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
																	}
																})
																,lQuery.create("D#RadioButton", {
																	caption = "Graphically"
																	,id = "showDataPropertiesType"
																	,enabled =  chechIfEnabled(pValueSet, {"showDataProperties"})
																	,selected = selectRadioButtonValue("showDataPropertiesType", "Graphically", pValueSet)
																	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowDataPropertiesType()")
																})
															}
														})
														,lQuery.create("D#Column", {
															verticalAlignment = -1
															,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showObjectProperties"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
														})
													}
												})
												
											}
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,leftMargin = 20
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Annotations"
													,id = "showDataPropertyAnnotations"
													,type = "CheckBox"
													,enabled =  chechIfEnabled(pValueSet, {"showDataProperties"})
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowDataPropertyAnnotations()")
													,checked = pValueSet:find("/pValue[pName = 'showDataPropertyAnnotations']"):attr("pValue")
												})
												,lQuery.create("D#VerticalBox", {
													horizontalAlignment = -1
													,verticalAlignment = -1
													,component = {
														lQuery.create("D#GroupBox", {
															horizontalAlignment = -1
															,verticalAlignment = -1
															,leftMargin = 20
															,component = {
																lQuery.create("D#Row", {
																	horizontalAlignment = -1
																	,component = {
																		lQuery.create("D#VerticalBox", {
																			horizontalAlignment = -1
																			,id = "showDataPropertiesAnnotationType"
																			,component ={
																				lQuery.create("D#RadioButton", {
																					caption = "As text"
																					,leftMargin = 20
																					,id = "showDataPropertiesAnnotationType"
																					,enabled =  chechIfEnabled(pValueSet, {"showDataProperties", "showDataPropertyAnnotations"})
																					,selected = selectRadioButtonValue("showDataPropertiesAnnotationType", "As text", pValueSet)
																					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
																				})
																				,lQuery.create("D#RadioButton", {
																					caption = "Graphically"
																					,leftMargin = 20
																					,id = "showDataPropertiesAnnotationType"
																					,enabled =  chechIfEnabled(pValueSet, {"showDataProperties", "showDataPropertyAnnotations"})
																					,selected = selectRadioButtonValue("showDataPropertiesAnnotationType", "Graphically", pValueSet)
																					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
																				})
																			}
																		})
																		,lQuery.create("D#Column", {
																			verticalAlignment = -1
																			,component = {lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																		})
																	}
																})
															}})
														
													}
												})
												,lQuery.create("D#Button", {caption = "Extra..", enabled =  chechIfEnabled(pValueSet, {"showObjectProperties"}),eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.extraItemsDataProperties()")})
											}
										})
									}
								})
						}})
						,lQuery.create("D#GroupBox", {
							minimumWidth = 425
							--,bottomMargin = 50
							,component = {
								lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Show property restrictions"
											,id = "showPropertyRestrictions"
											--,enabled = checkEnabled("data properties - data properties")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowPropertyRestrictions()")
											,checked = pValueSet:find("/pValue[pName = 'showPropertyRestrictions']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Object cardinality restrictions as multiplicities when possible"
											,leftMargin = 20
											,id = "showObjectCardinalityRestrictionsAsMultiplicity"
											,enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions"})
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showObjectCardinalityRestrictionsAsMultiplicity']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Data cardinality restrictions as multiplicities when possible"
											,leftMargin = 20
											,id = "showDataCardinalityRestrictionsAsMultiplicity"
											,enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions"})
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showDataCardinalityRestrictionsAsMultiplicity']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Show object property restrictions graphicaly"
											,leftMargin = 20
											,id = "showPropertyRestrictionsGraphically"
											,enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions"})
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowPropertyRestrictionsGraphically()")
											,checked = pValueSet:find("/pValue[pName = 'showPropertyRestrictionsGraphically']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "No restriction lines to Thing"
											,leftMargin = 50
											,id = "showPropertyRestrictionsGraphicallyNoLineToThing"
											,enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions", "showPropertyRestrictionsGraphically"})
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showPropertyRestrictionsGraphicallyNoLineToThing']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions", "showPropertyRestrictionsGraphically"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "No restriction lines to self"
											,leftMargin = 50
											,id = "showPropertyRestrictionsGraphicallyNoLineToSelf"
											,enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions", "showPropertyRestrictionsGraphically"})
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showPropertyRestrictionsGraphicallyNoLineToSelf']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions", "showPropertyRestrictionsGraphically"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									component = {
										lQuery.create("D#CheckBox", {
											caption = "Hide restrictions not presented graphically or as multiplicities"
											,leftMargin = 20
											,enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions"})
											,id = "showPropertyRestrictionsHideNotGraphical"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'showPropertyRestrictionsHideNotGraphical']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showPropertyRestrictions"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
						}})
					}
				})				
				,lQuery.create("D#Tab", {
					caption = "Individuals"
					,horizontalAlignment = -1
					,verticalAlignment = -1
					,component = {
						
						lQuery.create("D#Row", {
							horizontalAlignment = -1
							,component = {
								lQuery.create("D#CheckBox", {
									caption = "Show individuals"
									,id = "showIndividuals"
									,enabled = checkEnabled("individuals - individuals")
									,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowIndividuals()")
									,checked = pValueSet:find("/pValue[pName = 'showIndividuals']"):attr("pValue")
								})
								,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
							}
						})
						
						,lQuery.create("D#GroupBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							--,bottomMargin = 300
							,component = {
								lQuery.create("D#HorizontalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Same individuals"
											,id = "showSameIndividuals"
											,enabled =  chechIfEnabled(pValueSet, {"showIndividuals"})
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowSameIndividuals()")
											,checked = pValueSet:find("/pValue[pName = 'showSameIndividuals']"):attr("pValue")
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#VerticalBox", {
															horizontalAlignment = -1
															,id = "showSameIndividualsType"
															,component = {
																lQuery.create("D#RadioButton", {
																	caption = "As text"
																	,id = "showSameIndividualsType"
																	,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showSameIndividuals"})
																	,selected = selectRadioButtonValue("showSameIndividualsType", "As text", pValueSet)
																	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowSameIndividualsType()")
																})
																,lQuery.create("D#RadioButton", {
																	caption = "Graphically"
																	,id = "showSameIndividualsType"
																	,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showSameIndividuals"})
																	,selected = selectRadioButtonValue("showSameIndividualsType", "Graphically", pValueSet)
																	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowSameIndividualsType()")
																})
															}
														})
														,lQuery.create("D#Column", {
															verticalAlignment = -1
															,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showSameIndividuals"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
														})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Group as boxes (if > 2)"
															,leftMargin = 20
															,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showSameIndividuals", "showSameIndividualsType"})
															,id = "showSameIndividualsGraphicsGroupAsBoxes"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showSameIndividualsGraphicsGroupAsBoxes']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showSameIndividuals", "showSameIndividualsType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Hide information, if not presented graphically"
															,leftMargin = 20
															-- ,enabled = false
															-- ,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showSameIndividuals", "showSameIndividualsType"})
															,id = "showSameIndividualsHideNotGraphical"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showSameIndividualsHideNotGraphical']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = "..", enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showSameIndividuals", "showSameIndividualsType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
							}
						})
						,lQuery.create("D#GroupBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,component = {
								lQuery.create("D#HorizontalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Different individuals"
											,id = "showDifferentIndividuals"
											,enabled =  chechIfEnabled(pValueSet, {"showIndividuals"})
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowDifferentIndividuals()")
											,checked = pValueSet:find("/pValue[pName = 'showDifferentIndividuals']"):attr("pValue")
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#VerticalBox", {
															horizontalAlignment = -1
															,id = "showDifferentIndividualsType"
															,component = {
																lQuery.create("D#RadioButton", {
																	caption = "As text"
																	,id = "showDifferentIndividualsType"
																	,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showDifferentIndividuals"})
																	,selected = selectRadioButtonValue("showDifferentIndividualsType", "As text", pValueSet)
																	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowDifferentIndividualsType()")
																})
																,lQuery.create("D#RadioButton", {
																	caption = "Graphically"
																	,id = "showDifferentIndividualsType"
																	,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showDifferentIndividuals"})
																	,selected = selectRadioButtonValue("showDifferentIndividualsType", "Graphically", pValueSet)
																	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowDifferentIndividualsType()")
																})
															}
														})
														,lQuery.create("D#Column", {
															verticalAlignment = -1
															,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showDifferentIndividuals"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
														})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Group as boxes (if > 2)"
															,leftMargin = 20
															,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showDifferentIndividuals", "showDifferentIndividualsType"})
															,id = "showDifferentIndividualsGraphicsGroupAsBoxes"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showDifferentIndividualsGraphicsGroupAsBoxes']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showDifferentIndividuals", "showDifferentIndividualsType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Hide information, if not presented graphically"
															,leftMargin = 20
															-- ,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showDifferentIndividuals", "showDifferentIndividualsType"})
															-- ,enabled = false
															,id = "showDifferentIndividualsHideNotGraphical"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showDifferentIndividualsHideNotGraphical']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showDifferentIndividuals", "showDifferentIndividualsType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
							}
						})
						,lQuery.create("D#GroupBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,component = {
								lQuery.create("D#VerticalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#HorizontalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Annotations"
													,enabled =  chechIfEnabled(pValueSet, {"showIndividuals"})
													,id = "showIndividualAnnotations"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowIndividualAnnotations()")
													,checked = pValueSet:find("/pValue[pName = 'showIndividualAnnotations']"):attr("pValue")
												})
												,lQuery.create("D#VerticalBox", {
													horizontalAlignment = -1
													,verticalAlignment = -1
													,component = {
														lQuery.create("D#Row", {
															horizontalAlignment = -1
															,component = {
																lQuery.create("D#VerticalBox", {
																	horizontalAlignment = -1
																	,id = "showIndividualAnnotationType"
																	,component ={
																		lQuery.create("D#RadioButton", {
																			caption = "As text"
																			,id = "showIndividualAnnotationType"
																			,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualAnnotations"})
																			,selected = selectRadioButtonValue("showIndividualAnnotationType", "As text", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
																		})
																		,lQuery.create("D#RadioButton", {
																			caption = "Graphically"
																			,id = "showIndividualAnnotationType"
																			,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualAnnotations"})
																			,selected = selectRadioButtonValue("showIndividualAnnotationType", "Graphically", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
																		})
																	}
																})
																,lQuery.create("D#Column", {
																	verticalAlignment = -1
																	,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualAnnotations"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																})
															}
														})
													}
												})
											}
										})
									}
								})
							}
						})
						,lQuery.create("D#GroupBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,component = {
								lQuery.create("D#VerticalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#HorizontalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Class assertions"
													,id = "showIndividualClassAssertions"
													,enabled =  chechIfEnabled(pValueSet, {"showIndividuals"})
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParametershowIndividualClassAssertions()")
													,checked = pValueSet:find("/pValue[pName = 'showIndividualClassAssertions']"):attr("pValue")
												})
												,lQuery.create("D#VerticalBox", {
													horizontalAlignment = -1
													,verticalAlignment = -1
													,component = {
														lQuery.create("D#Row", {
															horizontalAlignment = -1
															,component = {
																lQuery.create("D#VerticalBox", {
																	horizontalAlignment = -1
																	,id = "showClassAssertionsType"
																	,component ={
																		lQuery.create("D#RadioButton", {
																			caption = "As text"
																			,id = "showClassAssertionsType"
																			,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualClassAssertions"})
																			,selected = selectRadioButtonValue("showClassAssertionsType", "As text", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowClassAssertionsType()")
																		})
																		,lQuery.create("D#RadioButton", {
																			caption = "Graphically"
																			,id = "showClassAssertionsType"
																			,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualClassAssertions"})
																			,selected = selectRadioButtonValue("showClassAssertionsType", "Graphically", pValueSet)
																			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParametershowClassAssertionsType()")
																		})
																	}
																})
																,lQuery.create("D#Column", {
																	verticalAlignment = -1
																	,component = {lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualClassAssertions"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
																})
															}
														})
														,lQuery.create("D#Row", {
															component = {
																lQuery.create("D#CheckBox", {
																	caption = "Keep text with graphics"
																	,leftMargin = 20
																	,id = "showClassAssertionsGraphicsKeepText"
																	,enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualClassAssertions", "showClassAssertionsType"})
																	,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
																	,checked = pValueSet:find("/pValue[pName = 'showClassAssertionsGraphicsKeepText']"):attr("pValue")
																})
																,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualClassAssertions", "showClassAssertionsType"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
															}
														})
														,lQuery.create("D#Button", {caption = "Extra..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals", "showIndividualClassAssertions"}), eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.classAssertionsExtraItems()")})
													}
												})
											}
										})
									}
								})
							}
						})
						,lQuery.create("D#GroupBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,bottomMargin = 50
							,minimumWidth = 400
							,component = {
								lQuery.create("D#VerticalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,rightMargin = 186
									,id = 'VerticalBox'
									,component = {
										lQuery.create("D#Row", {
											horizontalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Object property assertions"
													,id = "showIndividualsObjectPropertyAssertions"
													,type = "CheckBox"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
													,enabled =  chechIfEnabled(pValueSet, {"showIndividuals"})
													,checked = pValueSet:find("/pValue[pName = 'showIndividualsObjectPropertyAssertions']"):attr("pValue")
												})
												,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
											}
										})
										,lQuery.create("D#Row", {
											horizontalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Data property assertions"
													,id = "showIndividualsDataPropertyAssertions"
													,enabled =  chechIfEnabled(pValueSet, {"showIndividuals"})
													,type = "CheckBox"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
													,checked = pValueSet:find("/pValue[pName = 'showIndividualsDataPropertyAssertions']"):attr("pValue")
												})
												,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
											}
										})
										,lQuery.create("D#Row", {
											horizontalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Negative object property assertions"
													,id = "showIndividualsNegativeObjectPropertyAssertions"
													,enabled =  chechIfEnabled(pValueSet, {"showIndividuals"})
													,type = "CheckBox"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
													,checked = pValueSet:find("/pValue[pName = 'showIndividualsNegativeObjectPropertyAssertions']"):attr("pValue")
												})
												,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
											}
										})
										,lQuery.create("D#Row", {
											horizontalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Negative data property assertions"
													,id = "showIndividualsNegativeDataPropertyAssertions"
													,enabled =  chechIfEnabled(pValueSet, {"showIndividuals"})
													,type = "CheckBox"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
													,checked = pValueSet:find("/pValue[pName = 'showIndividualsNegativeDataPropertyAssertions']"):attr("pValue")
												})
												,lQuery.create("D#Button", {caption = "..",enabled =  chechIfEnabled(pValueSet, {"showIndividuals"}) ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
											}
										})
									}
								})
								,lQuery.create("D#HorizontalBox", {
									horizontalAlignment = 1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#Button", {
											caption = "Select all"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.selectAllHV()")
										})
										,lQuery.create("D#Button", {
											caption = "Clear all"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.clearAllHV()")
										})
									}
								})
							}
						})
					}
				})
				,lQuery.create("D#Tab", {
					caption = "Effects"
					,horizontalAlignment = -1
					,verticalAlignment = -1
					,component = {
						lQuery.create("D#VerticalBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,component = {
								lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Clone class boxes with"
											-- ,enabled = false
											,id = "cloneClassBoxesBySelfLines"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'cloneClassBoxesBySelfLines']"):attr("pValue")
										})
										,lQuery.create("D#InputField", {
											id = "cloneClassBoxesBySelfLinesCount"
											,maximumWidth = 50
											-- ,enabled = false
											,text = pValueSet:find("/pValue[pName = 'cloneClassBoxesBySelfLinesCount']"):attr("pValue")
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveInputFieldParameter()")
										})
										,lQuery.create("D#Label", {caption = "or more self-links"})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#GroupBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,minimumWidth = 425
									,bottomMargin = 280
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,id= 'VerticalBox'
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Create containers for single nodes"
															-- ,enabled = false
															,id = "useContainersForSingleNodes"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameteruseContainersForSingleNodes()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodes']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Ontology annotations" 
															,id = "useContainersForSingleNodesOntoAnnotations"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes"})
															,type = "CheckBox"
															,leftMargin = 30
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameteruseContainersForSingleNodesOntoAnnotations()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesOntoAnnotations']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Use separate container" 
															,id = "useContainersForSingleNodesOntoAnnotationsSeparate"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes", "useContainersForSingleNodesOntoAnnotations"})
															,type = "CheckBox"
															,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesOntoAnnotationsSeparate']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												-- ,lQuery.create("D#Row", {
													-- horizontalAlignment = -1
													-- ,component = {
														-- lQuery.create("D#CheckBox", {
															-- caption = "Unvisualized axioms"
															-- ,id = "useContainersForSingleNodesUnloadedAxioms"
															-- ,enabled = false
															-- ,type = "CheckBox"
															-- ,leftMargin = 30
															-- ,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															-- ,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesUnloadedAxioms']"):attr("pValue")
														-- })
														-- ,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													-- }
												-- })
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Data types"
															,id = "useContainersForSingleNodesDataTypes"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes"})
															,type = "CheckBox"
															,leftMargin = 30
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameteruseContainersForSingleNodesDataTypes()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesDataTypes']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Use separate container" 
															,id = "useContainersForSingleNodesDataTypesSeparate"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes", "useContainersForSingleNodesDataTypes"})
															,type = "CheckBox"
															,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesDataTypesSeparate']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Annotation property definitions"
															,id = "useContainersForSingleNodesAnnotPropDefs"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes"})
															,type = "CheckBox"
															,leftMargin = 30
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameteruseContainersForSingleNodesAnnotPropDefs()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesAnnotPropDefs']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Use separate container" 
															,id = "useContainersForSingleNodesAnnotPropDefsSeparate"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes", "useContainersForSingleNodesAnnotPropDefs"})
															,type = "CheckBox"
															,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesAnnotPropDefsSeparate']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "OWL individuals"
															,id = "useContainersForSingleNodesIndividuals"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes"})
															,type = "CheckBox"
															,leftMargin = 30
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameteruseContainersForSingleNodesIndividuals()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesIndividuals']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Use separate container" 
															,id = "useContainersForSingleNodesIndividualsSeparate"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes", "useContainersForSingleNodesIndividuals"})
															,type = "CheckBox"
															,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesIndividualsSeparate']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Group by classes" 
															,id = "useContainersForSingleNodesIndividualsGroupByClasses"
															,enabled = chechIfEnabled(pValueSet, {"useContainersForSingleNodes", "useContainersForSingleNodesIndividuals"})
															,type = "CheckBox"
															,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'useContainersForSingleNodesIndividualsGroupByClasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
							}
						})
					}
				})
				,lQuery.create("D#Tab", {
					caption = "Ontology module parameters"
					,horizontalAlignment = -1
					,verticalAlignment = -1
					,component = {
						lQuery.create("D#VerticalBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,component = {
								lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Direct asserted superclasses of module classes"
											-- ,enabled = false
											,id = "DirectAssertedSuperclassesOfModuleClasses"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'DirectAssertedSuperclassesOfModuleClasses']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Anonymous 'A or B' superclasses of module classes"
											-- ,enabled = false
											,id = "AnonymousSuperclassesOfModuleClasses"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'AnonymousSuperclassesOfModuleClasses']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Transitive superclasses"
											-- ,enabled = false
											,id = "TransitiveSuperclasses"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'TransitiveSuperclasses']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Direct asserted subclasses of module classes"
											-- ,enabled = false
											,id = "DirectAssertedSubclassesOfModuleClasses"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'DirectAssertedSubclassesOfModuleClasses']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Anonymous 'A and ..' subclasses of module classes"
											-- ,enabled = false
											,id = "AnonymousSubclassesOfModuleClasses"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'AnonymousSubclassesOfModuleClasses']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Transitive subclasses"
											-- ,enabled = false
											,id = "TransitiveSubclasses"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'TransitiveSubclasses']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								,lQuery.create("D#GroupBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,minimumWidth = 425
									--,bottomMargin = 280
									,caption = "Property range assertions"
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,id= 'VerticalBox'
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "For module classes"
															-- ,enabled = false
															,id = "PropertyRangeAssertionsForModuleClasses"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'PropertyRangeAssertionsForModuleClasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "For superclasses" 
															,id = "PropertyRangeAssertionsForModuleClassesForSuperclasses"
															-- ,enabled = false
															,type = "CheckBox"
															--,leftMargin = 30
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'PropertyRangeAssertionsForModuleClassesForSuperclasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "For subclasses" 
															,id = "PropertyRangeAssertionsForModuleClassesForSubclasses"
															-- ,enabled = false
															,type = "CheckBox"
															--,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'PropertyRangeAssertionsForModuleClassesForSubclasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#GroupBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,minimumWidth = 425
									--,bottomMargin = 280
									,caption = "Range classes for object properties"
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,id= 'VerticalBox'
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "At module classes"
															-- ,enabled = false
															,id = "RangeClassesForObjectPropertiesAtModuleClasses"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RangeClassesForObjectPropertiesAtModuleClasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "At superclasses" 
															,id = "RangeClassesForObjectPropertiesAtSuperclasses"
															-- ,enabled = false
															,type = "CheckBox"
															--,leftMargin = 30
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RangeClassesForObjectPropertiesAtSuperclasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "At subclasses" 
															,id = "RangeClassesForObjectPropertiesAtSubclasses"
															-- ,enabled = false
															,type = "CheckBox"
															--,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RangeClassesForObjectPropertiesAtSubclasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#GroupBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,minimumWidth = 425
									--,bottomMargin = 280
									,caption = "Restriction target classes for restrictions"
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,id= 'VerticalBox'
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "At module classes"
															-- ,enabled = false
															,id = "RestrictionTargetClassesForRestrictionsAtModuleClasses"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RestrictionTargetClassesForRestrictionsAtModuleClasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "At superclasses" 
															,id = "RestrictionTargetClassesForRestrictionsAtSuperclasses"
															-- ,enabled = false
															,type = "CheckBox"
															--,leftMargin = 30
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RestrictionTargetClassesForRestrictionsAtSuperclasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "At subclasses" 
															,id = "RestrictionTargetClassesForRestrictionsAtSubclasses"
															-- ,enabled = false
															,type = "CheckBox"
															--,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RestrictionTargetClassesForRestrictionsAtSubclasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#GroupBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,minimumWidth = 425
									,bottomMargin = 50
									,caption = "Restriction source classes for restrictions towards"
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,id= 'VerticalBox'
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Module classes"
															-- ,enabled = false
															,id = "RestrictionSourcetClassesForRestrictionsAtModuleClasses"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RestrictionSourcetClassesForRestrictionsAtModuleClasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Superclasses" 
															,id = "RestrictionSourcetClassesForRestrictionsAtSuperclasses"
															-- ,enabled = false
															,type = "CheckBox"
															--,leftMargin = 30
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RestrictionSourcetClassesForRestrictionsAtSuperclasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Subclasses" 
															,id = "RestrictionSourcetClassesForRestrictionsAtSubclasses"
															-- ,enabled = false
															,type = "CheckBox"
															--,leftMargin = 50
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'RestrictionSourcetClassesForRestrictionsAtSubclasses']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#CheckBox", {
											caption = "Show other properties in property domain/range/restriction"
											-- ,enabled = false
											,id = "ShowOtherPropertiesInPropertyDomainRangeRestriction"
											,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
											,checked = pValueSet:find("/pValue[pName = 'ShowOtherPropertiesInPropertyDomainRangeRestriction']"):attr("pValue")
										})
										,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
									}
								})
								}
						})
					}
				})
			}
		})
	return tabs
end

function extraItemsDataProperties()
	local pValueSet = lQuery("ToolType/current")
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeExtraItemsDataProperties()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "extraItemsDataProperties"
    ,caption = "extraItemsDataProperties"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeExtraItemsDataProperties()")
	-- ,minimumWidth = 410
	--,minimumHeight=600
	,component = {
		lQuery.create("D#GroupBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							--,bottomMargin = 350
							,component = {
								lQuery.create("D#VerticalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,id= 'VerticalBox'
									,component = {
										lQuery.create("D#Row", {
											horizontalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Superproperties" 
													,id = "showDataPropertiesSuperProperties"
													,type = "CheckBox"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
													,checked = pValueSet:find("/pValue[pName = 'showDataPropertiesSuperProperties']"):attr("pValue")
												})
												,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
											}
										})
										,lQuery.create("D#Row", {
											horizontalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Disjoint properties" 
													,id = "showDataPropertiesDisjointProperties"
													,type = "CheckBox"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
													,checked = pValueSet:find("/pValue[pName = 'showDataPropertiesDisjointProperties']"):attr("pValue")
												})
												,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
											}
										})
										,lQuery.create("D#Row", {
											horizontalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Equivalent properties" 
													,id = "showDataPropertiesEquivalentProperties"
													,type = "CheckBox"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
													,checked = pValueSet:find("/pValue[pName = 'showDataPropertiesEquivalentProperties']"):attr("pValue")
												})
												,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
											}
										})
										,lQuery.create("D#Row", {
											horizontalAlignment = -1
											,component = {
												lQuery.create("D#CheckBox", {
													caption = "Is functional"
													,id = "showDataPropertiesIsFunctional"
													,type = "CheckBox"
													,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
													,checked = pValueSet:find("/pValue[pName = 'showDataPropertiesIsFunctional']"):attr("pValue")
												})
												,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
											}
										})
									}
								})
								,lQuery.create("D#HorizontalBox", {
									horizontalAlignment = 1
									--,minimumWidth = 370
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#Button", {
											caption = "Select all"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.selectAllHV()")
										})
										,lQuery.create("D#Button", {
											caption = "Clear all"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.clearAllHV()")
										})
									}
								})
							}
						})

		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)

end

function extraItemsObjectProperties()
	local pValueSet = lQuery("ToolType/current")
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeExtraItemsObjectProperties()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "extraItemsObjectProperties"
    ,caption = "extraItemsObjectProperties"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeExtraItemsObjectProperties()")
	-- ,minimumWidth = 410
	--,minimumHeight=600
	,component = {
				lQuery.create("D#GroupBox", {
							horizontalAlignment = -1
							,verticalAlignment = -1
							,minimumWidth = 385
							,component = {
								lQuery.create("D#HorizontalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,id = 'VerticalBox'
											,verticalAlignment = -1
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Superproperties"
															,id = "showObjectPropertiesSuperProperties"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesSuperProperties']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Disjoint properties"
															,id = "showObjectPropertiesDisjointProperties"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesDisjointProperties']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,id = 'VerticalBox'
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Equivalent properties"
															,id = "showObjectPropertiesEquivalentProperties"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesEquivalentProperties']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Property chains"
															,id = "showObjectPropertiesPropertyChains"
															,type = "CheckBox"
															-- ,enabled = false
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesPropertyChains']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#HorizontalBox", {
									horizontalAlignment = 1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#Button", {
											caption = "Select all"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.selectAllHH()")
										})
										,lQuery.create("D#Button", {
											caption = "Clear all"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.clearAllHH()")
										})
									}
								})
							}
						})
						,lQuery.create("D#GroupBox", {
							horizontalAlignment = -1
							,minimumWidth = 385
							,verticalAlignment = -1
							,component = {
								lQuery.create("D#HorizontalBox", {
									horizontalAlignment = -1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,id = 'VerticalBox'
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Is functional"
															,id = "showObjectPropertiesIsFunctional"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesIsFunctional']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Is inverse functional"
															,id = "showObjectPropertiesIsInverseFunctional"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesIsInverseFunctional']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Is symmetric"
															,id = "showObjectPropertiesIsSymmetric"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesIsSymmetric']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Is asymmetric"
															,id = "showObjectPropertiesIsAsymmetric"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesIsAsymmetric']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
										,lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,verticalAlignment = -1
											,id = 'VerticalBox'
											,leftMargin = 25
											,rightMargin = 42
											,component = {
												lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Is transitive"
															,id = "showObjectPropertiesIsTransitive"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesIsTransitive']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Is reflexive"
															,id = "showObjectPropertiesIsReflexive"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesIsReflexive']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
												,lQuery.create("D#Row", {
													horizontalAlignment = -1
													,component = {
														lQuery.create("D#CheckBox", {
															caption = "Is irreflexive"
															,id = "showObjectPropertiesIsIrreflexive"
															,type = "CheckBox"
															,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
															,checked = pValueSet:find("/pValue[pName = 'showObjectPropertiesIsIrreflexive']"):attr("pValue")
														})
														,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
													}
												})
											}
										})
									}
								})
								,lQuery.create("D#HorizontalBox", {
									horizontalAlignment = 1
									,verticalAlignment = -1
									,component = {
										lQuery.create("D#Button", {
											caption = "Select all"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.selectAllHH()")
										})
										,lQuery.create("D#Button", {
											caption = "Clear all"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.clearAllHH()")
										})
									}
								})
							}
						})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
end

function classAssertionsExtraItems()
	local pValueSet = lQuery("ToolType/current")
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeClassAssertionsExtraItems()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "classAssertionsExtraItems"
    ,caption = "classAssertionsExtraItems"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeClassAssertionsExtraItems()")
	-- ,minimumWidth = 410
	--,minimumHeight=600
	,component = {
		lQuery.create("D#HorizontalBox",{
			id = "HorizontalAllForms"
			,component = {
				lQuery.create("D#VerticalBox",{
					id = "VerticalBoxPropertyTabs"
					,horizontalAlignment = -1
					,component = {
						lQuery.create("D#GroupBox", {
							--minimumWidth = 385
							component = {
								lQuery.create("D#Label", {caption = "Create box for class expression in class assertion"})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,id = "showIndividualClassAssertionsCreateClassBox"
											,component = {
												lQuery.create("D#RadioButton", {
													caption = "No"
													,id = "showIndividualClassAssertionsCreateClassBox"
													,enabled = false
													,selected = selectRadioButtonValue("showIndividualClassAssertionsCreateClassBox", "No", pValueSet)
													,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
													})
												,lQuery.create("D#RadioButton", {
													caption = "Yes"
													,id = "showIndividualClassAssertionsCreateClassBox"
													,enabled = false
													,selected = selectRadioButtonValue("showIndividualClassAssertionsCreateClassBox", "Yes", pValueSet)
													,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
												})
												,lQuery.create("D#RadioButton", {
													caption = "Create if multiple use"
													,id = "showIndividualClassAssertionsCreateClassBox"
													,enabled = false
													,selected = selectRadioButtonValue("showIndividualClassAssertionsCreateClassBox", "Create if multiple use", pValueSet)
													,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
												})
											}
										})
																--,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
										,lQuery.create("D#Column", {
											verticalAlignment = -1
											,component = {lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
										})
									}
								})
	
							}
						})
					}
				})

			}})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
end

function subClassExtraItems()
	
	local pValueSet = lQuery("ToolType/current")
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeSubClassExtraItems()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "subClassExtraItemsForm"
    ,caption = "subClassExtraItemsForm"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeSubClassExtraItems()")
	-- ,minimumWidth = 410
	--,minimumHeight=600
	,component = {
		lQuery.create("D#HorizontalBox",{
			id = "HorizontalAllForms"
			,component = {
				lQuery.create("D#VerticalBox",{
					id = "VerticalBoxPropertyTabs"
					,horizontalAlignment = -1
					,component = {
						lQuery.create("D#Row", {
							component = {
								lQuery.create("D#CheckBox", {
									caption = "Mark top-level named classes as subclasses of 'Thing'"
									,id = "showSubclassesTopNamedToThing"
									,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
									,checked = pValueSet:find("/pValue[pName = 'showSubclassesTopNamedToThing']"):attr("pValue")
								})
								,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
							}
						})
						,lQuery.create("D#Row", {
							component = {
								lQuery.create("D#CheckBox", {
									caption = "Draw subclass relations to named class A from expression 'A and ...'"
									-- ,enabled = false
									,id = "showSubclassesFromAndNamed"
									,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
									,checked = pValueSet:find("/pValue[pName = 'showSubclassesFromAndNamed']"):attr("pValue")
								})
								,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
							}
						})
						,lQuery.create("D#Row", {
							component = {
								lQuery.create("D#CheckBox", {
									caption = "Draw subclass relations from named classes to their union"
									,id = "showSubclassesToUnionOfNamed"
									-- ,enabled = false
									,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
									,checked = pValueSet:find("/pValue[pName = 'showSubclassesToUnionOfNamed']"):attr("pValue")
								})
								,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
							}
						})
						,lQuery.create("D#Row", {
							component = {
								lQuery.create("D#CheckBox", {
									caption = "Hide subclass information, if not presented graphically"
									,id = "showSubclassesHideNotGraphical"
									-- ,enabled = false
									,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.saveCheckBoxParameter()")
									,checked = pValueSet:find("/pValue[pName = 'showSubclassesHideNotGraphical']"):attr("pValue")
								})
								,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
							}
						})
						,lQuery.create("D#GroupBox", {
							--minimumWidth = 385
							component = {
								lQuery.create("D#Label", {caption = "Create anonymous subclasses as box"})
								,lQuery.create("D#Row", {
									horizontalAlignment = -1
									,component = {
										lQuery.create("D#VerticalBox", {
											horizontalAlignment = -1
											,id = "showSubclassesCreateTarget"
											,component = {
												lQuery.create("D#RadioButton", {
													caption = "No"
													,id = "showSubclassesCreateTarget"
													-- ,enabled = false
													,selected = selectRadioButtonValue("showSubclassesCreateTarget", "No", pValueSet)
													,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
													})
												,lQuery.create("D#RadioButton", {
													caption = "Yes"
													,id = "showSubclassesCreateTarget"
													-- ,enabled = false
													,selected = selectRadioButtonValue("showSubclassesCreateTarget", "Yes", pValueSet)
													,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
												})
												,lQuery.create("D#RadioButton", {
													caption = "Create if multiple use"
													,id = "showSubclassesCreateTarget"
													,enabled = false
													,selected = selectRadioButtonValue("showSubclassesCreateTarget", "Create if multiple use", pValueSet)
													,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveRadioButtonParameter()")
												})
											}
										})
																--,lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})
										,lQuery.create("D#Column", {
											verticalAlignment = -1
											,component = {lQuery.create("D#Button", {caption = ".." ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.customRuleForm()")})}
										})
									}
								})
	
							}
						})
					}
				})

			}})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
end

function customRuleForm()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeCustomRuleForm()")
  })
  local save_button = lQuery.create("D#Button", {
    caption = "Save"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeCustomRuleForm()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "customRuleForm"
    ,caption = "customRuleForm"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeCustomRuleForm()")
	-- ,minimumWidth = 410
	--,minimumHeight=600
	,component = {
		lQuery.create("D#HorizontalBox",{
			id = "HorizontalAllForms"
			,component = {
				lQuery.create("D#VerticalBox",{
					id = "VerticalBoxPropertyTabs"
					,horizontalAlignment = -1
					,minimumWidth = 200
					,component = {
						lQuery.create("D#Label", {caption = "Rule:"})
						,lQuery.create("D#ComboBox")
						,lQuery.create("D#Label", {caption = "Parameter:"})
						,lQuery.create("D#InputField")
						
					}
				})

			}})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {--save_button, 
			close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
end

function advancedButtons()
	local buttons = lQuery.create("D#VerticalBox", {
			horizontalAlignment = 1
			,id = "VerticalBoxAdvancedButtonsForm"
			,leftMargin = 10
			,component = {
				  lQuery.create("D#Label", {
					caption = "Saved parameter sets"
					,bottomMargin = 100
				  })
				  ,lQuery.create("D#Button", {
					caption = "<- Load"
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.loadParameterProfileForm()")
				  })
				  ,lQuery.create("D#Button", {
					caption = "Update ->"
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.updateParameterProfileForm()")
				  })
				  ,lQuery.create("D#Button", {
					caption = "Save as new ->"
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveAsNewParameterProfileForm()")
				  })
				  ,lQuery.create("D#Button", {
					caption = "Copy"
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.copyParameterProfileForm()")
				  })
				  ,lQuery.create("D#Button", {
					caption = "Delete"
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.deleteParameterProfileForm()")
					,bottomMargin = 300
				  })
			}
		})
	return buttons
end

function advancedProfiles()
	local profiles = lQuery.create("D#VerticalBox", {
			horizontalAlignment = 1
			,id = "VerticalBoxAdvancedParametersForm"
			,leftMargin = 15
			,minimumWidth = 200
			,component = {
				lQuery.create("D#ListBox", {
					id = 'ListBoxWithParametersProfiles'
					,topMargin = 30
					,item = collectParameterProfiles()
				})
				,lQuery.create("D#Row", {
					horizontalAlignment = -1
					,component = {
						lQuery.create("D#CheckBox", {
							id = 'AutoShowAdvanced'
							,checked = lQuery("ToolType/tag[key='advancedParametersShow']"):attr("value")
							,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.parameters.setAdvancedParametersTag()")
						})
						,lQuery.create("D#Label", {caption = 'Autoshow advanced'})
					}
				})
			}
		})
	return profiles
end

function setAdvancedParametersTag()
	lQuery("ToolType/tag[key='advancedParametersShow']"):attr("value", lQuery("D#Event/source"):attr("checked"))
end

function showAdvancedForm()
	local allForms = lQuery("D#HorizontalBox[id='HorizontalAllForms']")
	if allForms:find("/component[id='VerticalBoxAdvancedButtonsForm']"):is_empty() and allForms:find("/component[id='VerticalBoxAdvancedParametersForm']"):is_empty() then
		allForms:link("component", advancedButtons())
		allForms:link("component", advancedProfiles())
		allForms:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	else
		allForms:find("/component[id='VerticalBoxAdvancedButtonsForm']"):delete()
		allForms:find("/component[id='VerticalBoxAdvancedParametersForm']"):delete()
		allForms:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

function collectParameterProfiles()
	local values = lQuery("OWL_PP#ParamProfile"):map(function(obj)
		if obj:attr("isSystemProfile")~="true" then
			return lQuery(obj):attr("name")
		end
	end)  
		
	return lQuery.map(values, function(value) 
		return lQuery.create("D#Item", {
			value = value
		}) 
	end)
end

function saveAsNewParameterProfileForm()
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeSaveAsNewParameterProfile()")
	})
	local ok_button = lQuery.create("D#Button", {
		caption = "Ok"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.saveAsNewParameterProfile()")
	})
	local form = newParameterProfileForm(close_button, ok_button)
	dialog_utilities.show_form(form)
end

function copyParameterProfileForm()
	local selectedItem = lQuery("D#ListBox[id='ListBoxWithParametersProfiles']/selected")
	if selectedItem:is_not_empty() then
		local close_button = lQuery.create("D#Button", {
			caption = "Close"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeSaveAsNewParameterProfile()")
		})
		local ok_button = lQuery.create("D#Button", {
			caption = "Ok"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.copyParameterProfile()")
		})
		local form = newParameterProfileForm(close_button, ok_button)
		dialog_utilities.show_form(form)
	end
end

function loadParameterProfileForm()
	local selectedItem = lQuery("D#ListBox[id='ListBoxWithParametersProfiles']/selected")
	if selectedItem:is_not_empty() then
		local yes_button = lQuery.create("D#Button", {
			caption = "Yes"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.loadParameterProfile()")
		})
		local no_button = lQuery.create("D#Button", {
			caption = "No"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeLoadParameterProfileForm()")
		})
		local form = lQuery.create("D#Form", {
			id = "LoadParameterProfile"
			,caption = "Load parameter profile"
			,buttonClickOnClose = false
			,cancelButton = no_button
			,defaultButton = yes_button
			,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeLoadParameterProfileForm()")
			,horizontalAlignment = 1
			,component = {
				lQuery.create("D#HorizontalBox", {component = {
					lQuery.create("D#Label", {caption = "Overwrite current parameters set?"})}
				})
				,lQuery.create("D#HorizontalBox", {component={yes_button ,no_button}})
			}
		})
		dialog_utilities.show_form(form)
	end
end

function updateParameterProfileForm()
		local yes_button = lQuery.create("D#Button", {
			caption = "Yes"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.updateParameterProfile()")
		})
		local no_button = lQuery.create("D#Button", {
			caption = "No"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeUpdateParameterProfileForm()")
		})
		local form = lQuery.create("D#Form", {
			id = "UpdateParameterProfile"
			,caption = "Update parameter profile"
			,buttonClickOnClose = false
			,cancelButton = no_button
			,defaultButton = yes_button
			,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeUpdateParameterProfileForm()")
			,horizontalAlignment = 1
			,component = {
				lQuery.create("D#HorizontalBox", {component = {
					lQuery.create("D#Label", {caption = "Overwrite parameters set?"})}
				})
				,lQuery.create("D#HorizontalBox", {component={yes_button ,no_button}})
			}
		})
		dialog_utilities.show_form(form)
end

function deleteParameterProfileForm()
	local selectedItem = lQuery("D#ListBox[id='ListBoxWithParametersProfiles']/selected")
	if selectedItem:is_not_empty() then
		local yes_button = lQuery.create("D#Button", {
			caption = "Yes"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.deleteParameterProfile()")
		})
		local no_button = lQuery.create("D#Button", {
			caption = "No"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.parameters.closeDeleteParameterProfileForm()")
		})
		local form = lQuery.create("D#Form", {
			id = "DeleteParameterProfile"
			,caption = "Delete parameter profile"
			,buttonClickOnClose = false
			,cancelButton = no_button
			,defaultButton = yes_button
			,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeDeleteParameterProfileForm()")
			,horizontalAlignment = 1
			,component = {
				lQuery.create("D#HorizontalBox", {component = {
					lQuery.create("D#Label", {caption = "Delete parameters set?"})}
				})
				,lQuery.create("D#HorizontalBox", {component={yes_button ,no_button}})
			}
		})
		dialog_utilities.show_form(form)
	end
end

function newParameterProfileForm(close_button, ok_button)
	local form = lQuery.create("D#Form", {
		id = "NewParameterProfile"
		,caption = "New parameter profile name"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = ok_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.parameters.closeSaveAsNewParameterProfile()")
		,horizontalAlignment = 1
		,component = {
			lQuery.create("D#InputField", {id="NewParameterProfileName", text = ""})
			,lQuery.create("D#HorizontalBox", {component={ok_button ,close_button}})
		}
	})
	return form
end

function closeLoadParameterProfileForm()
  lQuery("D#Event"):delete()
  utilities.close_form("LoadParameterProfile")
end

function closeUpdateParameterProfileForm()
  lQuery("D#Event"):delete()
  utilities.close_form("UpdateParameterProfile")
end

function closeDeleteParameterProfileForm()
  lQuery("D#Event"):delete()
  utilities.close_form("DeleteParameterProfile")
end

function closeSaveAsNewParameterProfile()
  lQuery("D#Event"):delete()
  utilities.close_form("NewParameterProfile")
end

function closeCustomRuleForm()
  lQuery("D#Event"):delete()
  utilities.close_form("customRuleForm")
end

function closeSubClassExtraItems()
  lQuery("D#Event"):delete()
  utilities.close_form("subClassExtraItemsForm")
end

function closeClassAssertionsExtraItems()
  lQuery("D#Event"):delete()
  utilities.close_form("classAssertionsExtraItems")
end

function closeExtraItemsObjectProperties()
  lQuery("D#Event"):delete()
  utilities.close_form("extraItemsObjectProperties")
end

function closeExtraItemsDataProperties()
  lQuery("D#Event"):delete()
  utilities.close_form("extraItemsDataProperties")
end

function close()
  -- local allForms = lQuery("D#HorizontalBox[id='HorizontalAllForms']")
  -- if allForms:find("/component[id='VerticalBoxAdvancedButtonsForm']"):is_empty() and allForms:find("/component[id='VerticalBoxAdvancedParametersForm']"):is_empty() and lQuery("ToolType/tag[key='advancedParametersShow']"):attr("value") == "false" then
	-- saveParametersToMetamodel()
  -- end
  lQuery("D#Event"):delete()
  utilities.close_form("visualization_parameters")
  
  --createParametersTable(lQuery("OWL_PP#ParamProfile[isSystemProfile='true']"):attr("name"))
  -- createParametersTable()
  
	createJSONParameterTable()
end

function createJSONParameterTable()
	local parameterTable = {}
	local pValueSet = lQuery("ToolType/current")
	local pValues = pValueSet:find("/pValue"):each(function(pValue)
		local parameter = {}
		parameter["pValue"] = pValue:attr("pValue")
		parameter["procName"] = pValue:attr("procName")
		parameter["strParam"] = pValue:attr("strParam")
		parameterTable[pValue:attr("pName")] = parameter
	end)
	
--	print(json.encode(parameterTable))
	local jsonParameterTable = json.encode(parameterTable)
	return parameterTable
end

function chechIfEnabled(pValueSet, dependsOn)
	local enabled = true
	for key, value in pairs(dependsOn) do
		-- print(pValueSet:find("/pValue[pName = '" .. value .. "']"):attr("pValue"))
		if value == "showDataPropertiesType" and pValueSet:find("/pValue[pName = '" .. value .. "']"):attr("pValue") == "Graphically" then  enabled = false 
		elseif value == "showDataPropertiesType" and pValueSet:find("/pValue[pName = '" .. value .. "']"):attr("pValue") == "As text" then enabled = true 
		elseif pValueSet:find("/pValue[pName = '" .. value .. "']"):attr("pValue") == "false" or pValueSet:find("/pValue[pName = '" .. value .. "']"):attr("pValue") == "As text" then enabled = false end
	end
	return enabled
end

function dependentParameters()
	local depPar = {
		["showClasses"] = {
			["checkBox"] = {"showSubclasses", "showSubclassesAutoForksForDisjoint", "showDisjointClasses", "showDisjointClassesGraphicsGroupAsBoxes", "showDisjointClassesHideNotGraphical", "showDisjointClassesMarkAtForks", "showEquivalentClasses", "showEquivalentClassesGraphicsGroupAsBoxes", "showEquivalentClassesHideNotGraphical", "showKeys", "showClassAnnotations", "showClassAnnotationsEnableSpecComments"},
			["radioButton"] = {"showSubclassesType", "showSubclassesGraphicsType", "showDisjointClassesType", "showEquivalentClassesType", "showClassAnnotationsType"}
		},
		["showSubclasses"] = {
			["checkBox"] = {"showSubclassesAutoForksForDisjoint"},
			["radioButton"] = {"showSubclassesType", "showSubclassesGraphicsType",}
		},
		["showDisjointClasses"] = {
			["checkBox"] = {"showDisjointClassesGraphicsGroupAsBoxes", "showDisjointClassesHideNotGraphical", "showDisjointClassesMarkAtForks"},
			["radioButton"] = {"showDisjointClassesType",}
		},
		["showEquivalentClasses"] = {
			["checkBox"] = {"showEquivalentClassesGraphicsGroupAsBoxes", "showEquivalentClassesHideNotGraphical"},
			["radioButton"] = {"showEquivalentClassesType"}
		},
		["showClassAnnotations"] = {
			["checkBox"] = {"showClassAnnotationsEnableSpecComments"},
			["radioButton"] = {"showClassAnnotationsType"}
		},
		["showSubclassesType"] = {
			["checkBox"] = {"showSubclassesAutoForksForDisjoint"},
			["radioButton"] = {"showSubclassesGraphicsType"}
		},
		["showSubclassesGraphicsType"] = {
			["checkBox"] = {"showSubclassesAutoForksForDisjoint"},
			["radioButton"] = {}
		},
		["showDisjointClassesType"] = {
			["checkBox"] = {"showDisjointClassesGraphicsGroupAsBoxes", "showDisjointClassesHideNotGraphical"},
			["radioButton"] = {}
		},
		["showEquivalentClassesType"] = {
			["checkBox"] = {"showEquivalentClassesGraphicsGroupAsBoxes", "showEquivalentClassesHideNotGraphical"},
			["radioButton"] = {}
		},
		["showObjectProperties"] = {
			["checkBox"] = {"showObjectPropertiesMergeInverse", "showObjectPropertyAnnotations"},
			["radioButton"] = {"showObjectPropertiesType", "showObjectPropertyAnnotationsType"}
		},
		["showObjectPropertiesType"] = {
			["checkBox"] = {"showObjectPropertiesMergeInverse"},
			["radioButton"] = {}
		},
		["showObjectPropertyAnnotations"] = {
			["checkBox"] = {},
			["radioButton"] = {"showObjectPropertyAnnotationsType"}
		},
		["showDataProperties"] = {
			["checkBox"] = {"showDataPropertyAnnotations", "showDataTypesLinkToAttributeClasses"},
			["radioButton"] = {"showDataPropertiesAnnotationType", "showDataPropertiesType"}
		},
		["showDataPropertiesType"] = {
			["checkBox"] = {"showDataTypesLinkToAttributeClasses"},
			["radioButton"] = {}
		},
		["showDataPropertyAnnotations"] = {
			["checkBox"] = {},
			["radioButton"] = {"showDataPropertiesAnnotationType"}
		},
		["showPropertyRestrictions"] = {
			["checkBox"] = {"showObjectCardinalityRestrictionsAsMultiplicity", "showDataCardinalityRestrictionsAsMultiplicity", "showPropertyRestrictionsGraphically", "showPropertyRestrictionsGraphicallyNoLineToThing", "showPropertyRestrictionsGraphicallyNoLineToSelf", "showPropertyRestrictionsHideNotGraphical", },
			["radioButton"] = {}
		},
		["showPropertyRestrictionsGraphically"] = {
			["checkBox"] = {"showPropertyRestrictionsGraphicallyNoLineToThing", "showPropertyRestrictionsGraphicallyNoLineToSelf" },
			["radioButton"] = {}
		},
		["showIndividuals"] = {
			["checkBox"] = {"showSameIndividuals", "showSameIndividualsGraphicsGroupAsBoxes", "showSameIndividualsHideNotGraphical", "showDifferentIndividuals", "showDifferentIndividualsGraphicsGroupAsBoxes", "showDifferentIndividualsHideNotGraphical", "showIndividualAnnotations", "showIndividualClassAssertions", "showClassAssertionsGraphicsKeepText", "showIndividualsObjectPropertyAssertions", "showIndividualsDataPropertyAssertions", "showIndividualsNegativeObjectPropertyAssertions", "showIndividualsNegativeDataPropertyAssertions"},
			["radioButton"] = {"showSameIndividualsType", "showDifferentIndividualsType", "showIndividualAnnotationType", "showClassAssertionsType"}
		},
		["showSameIndividuals"] = {
			["checkBox"] = {"showSameIndividualsGraphicsGroupAsBoxes", "showSameIndividualsHideNotGraphical" },
			["radioButton"] = {"showSameIndividualsType"}
		},
		["showSameIndividualsType"] = {
			["checkBox"] = {"showSameIndividualsGraphicsGroupAsBoxes", "showSameIndividualsHideNotGraphical" },
			["radioButton"] = {}
		},
		["showDifferentIndividuals"] = {
			["checkBox"] = {"showDifferentIndividualsGraphicsGroupAsBoxes", "showDifferentIndividualsHideNotGraphical"},
			["radioButton"] = {"showDifferentIndividualsType"}
		},
		["showDifferentIndividualsType"] = {
			["checkBox"] = {"showDifferentIndividualsGraphicsGroupAsBoxes", "showDifferentIndividualsHideNotGraphical"},
			["radioButton"] = {}
		},
		["showIndividualAnnotations"] = {
			["checkBox"] = {},
			["radioButton"] = {"showIndividualAnnotationType"}
		},
		["showIndividualClassAssertions"] = {
			["checkBox"] = {"showClassAssertionsGraphicsKeepText"},
			["radioButton"] = {"showClassAssertionsType"}
		},
		["showClassAssertionsType"] = {
			["checkBox"] = {"showClassAssertionsGraphicsKeepText"},
			["radioButton"] = {}
		}, 
		["showUnloadedAxioms"] = {
			["checkBox"] = {"showUnloadedAxioms InComment", "showUnloadedAxioms DisplayOnDemand"},
			["radioButton"] = {}
		},
		["showDataTypes"] = {
			["checkBox"] = {"showDataTypesLinkToAttributeClasses"},
			["radioButton"] = {}
		}, 
		["useContainersForSingleNodes"] = {
			["checkBox"] = {"useContainersForSingleNodesOntoAnnotations", "useContainersForSingleNodesOntoAnnotationsSeparate", "useContainersForSingleNodesDataTypes", "useContainersForSingleNodesDataTypesSeparate", "useContainersForSingleNodesAnnotPropDefs", "useContainersForSingleNodesAnnotPropDefsSeparate", "useContainersForSingleNodesIndividuals", "useContainersForSingleNodesIndividualsSeparate", "useContainersForSingleNodesIndividualsGroupByClasses"},
			["radioButton"] = {}
		}, 
		["useContainersForSingleNodesOntoAnnotations"] = {
			["checkBox"] = {"useContainersForSingleNodesOntoAnnotationsSeparate"},
			["radioButton"] = {}
		},
		["useContainersForSingleNodesDataTypes"] = {
			["checkBox"] = {"useContainersForSingleNodesDataTypesSeparate"},
			["radioButton"] = {}
		}, 
		["useContainersForSingleNodesAnnotPropDefs"] = {
			["checkBox"] = {"useContainersForSingleNodesAnnotPropDefsSeparate"},
			["radioButton"] = {}
		}, 
		["useContainersForSingleNodesIndividuals"] = {
			["checkBox"] = {"useContainersForSingleNodesIndividualsSeparate", "useContainersForSingleNodesIndividualsGroupByClasses"},
			["radioButton"] = {}
		}, 
	}
	
	return depPar

end

function config_OWL_PP()
	--delete previous OWL_PP# version
	lQuery.model.delete_class("OWL_PP#ParamValue")
	lQuery.model.delete_class("OWL_PP#Parameter")
	lQuery.model.delete_class("OWL_PP#ParamProfile")

	--create OWL_PP#
	lQuery.model.add_class("OWL_PP#PValue")
	lQuery.model.add_class("OWL_PP#PValueSet")
	lQuery.model.add_class("OWL_PP#Parameter")
	lQuery.model.add_class("OWL_PP#ParamProcedure")

	lQuery.model.add_property("OWL_PP#PValue", "pName")
	lQuery.model.add_property("OWL_PP#PValue", "pValue")
	lQuery.model.add_property("OWL_PP#PValue", "procName")
	lQuery.model.add_property("OWL_PP#PValue", "strParam")

	lQuery.model.add_property("OWL_PP#PValueSet", "sName")
	lQuery.model.add_property("OWL_PP#PValueSet", "isDefaultSet")

	lQuery.model.add_property("OWL_PP#Parameter", "pName")
	lQuery.model.add_property("OWL_PP#Parameter", "defaultValue")

	lQuery.model.add_property("OWL_PP#ParamProcedure", "procName")
	lQuery.model.add_property("OWL_PP#ParamProcedure", "orderIndex")

	lQuery.model.add_composition("OWL_PP#ParamProcedure", "paramProcedure", "parameter", "OWL_PP#Parameter")
	lQuery.model.add_composition("OWL_PP#PValue", "pValue", "pValueSet", "OWL_PP#PValueSet")

	lQuery.model.add_link("OWL_PP#Parameter", "parameter", "pValue", "OWL_PP#PValue")
	lQuery.model.add_link("OWL_PP#ParamProcedure", "paramProcedure", "pValue", "OWL_PP#PValue")

	lQuery.model.add_link("OWL_PP#PValueSet", "current", "toolType", "ToolType")

	--import parameters with default values
	local parameterTable = {
		showOntoAnnotations = "true",
		showOntoAnnotationsInSeed = "Show in diagram",
		showOntoAnnotationsInDgr = "true",
		showUnloadedAxioms = "true",
		-- showUnloadedAxioms InComment = "false",
		-- showUnloadedAxioms DisplayOnDemand = "true",
		showAnnotationPropertyDefs = "true",
		showDataTypes = "true",
		showDataTypesLinkToAttributeClasses = "false",
		showClassExprsAsBoxByCountEnable = "true",
		showClassExprsAsBoxCount = "true",
		showAnnotationsInLanguages = "",
		addSchemaAssertionsToDomainAssertions = "true",
		showClasses = "true",
		showSubclasses = "true",
		showSubclassesType = "Graphically",
		showSubclassesGraphicsType = "As forks (if > 1)",
		showSubclassesAutoForksForDisjoint = "false",
		showSubclassesTopNamedToThing = "true",
		showSubclassesFromAndNamed = "false",
		showSubclassesToUnionOfNamed = "false",
		showSubclassesHideNotGraphical = "false",
		showSubclassesCreateTarget = "No",
		showDisjointClasses = "true",
		showDisjointClassesType = "Graphically",
		showDisjointClassesGraphicsGroupAsBoxes = "true",
		showDisjointClassesHideNotGraphical = "false",
		showDisjointClassesMarkAtForks = "true",
		showEquivalentClasses = "true",
		showEquivalentClassesType = "Graphically",
		showEquivalentClassesGraphicsGroupAsBoxes = "true",
		showEquivalentClassesHideNotGraphical = "false",
		showKeys = "true",
		showClassAnnotations = "true",
		showClassAnnotationsType = "As text",
		showClassAnnotationsEnableSpecComments = "true",
		cloneClassBoxesBySelfLines = "true",
		cloneClassBoxesBySelfLinesCount = "5",
		useContainersForSingleNodes = "true",
		useContainersForSingleNodesOntoAnnotations = "true",
		useContainersForSingleNodesOntoAnnotationsSeparate = "true",
		useContainersForSingleNodesUnloadedAxioms = "true",
		useContainersForSingleNodesDataTypes = "true",
		useContainersForSingleNodesDataTypesSeparate = "false",
		useContainersForSingleNodesAnnotPropDefs = "true",
		useContainersForSingleNodesAnnotPropDefsSeparate = "false",
		useContainersForSingleNodesIndividuals = "true",
		useContainersForSingleNodesIndividualsSeparate = "true",
		useContainersForSingleNodesIndividualsGroupByClasses = "true",
		showObjectProperties = "true",
		showObjectPropertiesType = "Graphically",
		showObjectPropertiesMergeInverse = "true",
		showObjectPropertyAnnotations = "true",
		showObjectPropertyAnnotationsType = "As text",
		showObjectPropertiesSuperProperties = "true",
		showObjectPropertiesDisjointProperties = "true",
		showObjectPropertiesEquivalentProperties = "true",
		showObjectPropertiesPropertyChains = "true",
		showObjectPropertiesIsFunctional = "true",
		showObjectPropertiesIsInverseFunctional = "true",
		showObjectPropertiesIsSymmetric = "true",
		showObjectPropertiesIsAsymmetric = "true",
		showObjectPropertiesIsTransitive = "true",
		showObjectPropertiesIsReflexive = "true",
		showObjectPropertiesIsIrreflexive = "true",
		showDataProperties = "true",
		showDataPropertiesType = "As text",
		showDataPropertyAnnotations = "true",
		showDataPropertiesAnnotationType = "As text",
		showDataPropertiesSuperProperties = "true",
		showDataPropertiesDisjointProperties = "true",
		showDataPropertiesEquivalentProperties = "true",
		showDataPropertiesIsFunctional = "true",
		showPropertyRestrictions = "true",
		showObjectCardinalityRestrictionsAsMultiplicity = "true",
		showDataCardinalityRestrictionsAsMultiplicity = "true",
		showPropertyRestrictionsGraphically = "true",
		showPropertyRestrictionsGraphicallyNoLineToThing = "true",
		showPropertyRestrictionsGraphicallyNoLineToSelf = "true",
		showPropertyRestrictionsHideNotGraphical = "false",
		showIndividuals = "true",
		showSameIndividuals = "true",
		showSameIndividualsType = "Graphically",
		showSameIndividualsGraphicsGroupAsBoxes = "true",
		showSameIndividualsHideNotGraphical = "false",
		showDifferentIndividuals = "true",
		showDifferentIndividualsType = "Graphically",
		showDifferentIndividualsGraphicsGroupAsBoxes = "true",
		showDifferentIndividualsHideNotGraphical = "false",
		showIndividualAnnotations = "true",
		showIndividualAnnotationType = "As text",
		showClassAssertionsType = "Graphically",
		showClassAssertionsGraphicsKeepText = "true",
		showIndividualClassAssertions = "true",
		showIndividualClassAssertionsCreateClassBox = "true",
		showIndividualsObjectPropertyAssertions = "true",
		showIndividualsDataPropertyAssertions = "true",
		showIndividualsNegativeObjectPropertyAssertions = "true",
		showIndividualsNegativeDataPropertyAssertions = "true",
		DirectAssertedSuperclassesOfModuleClasses = "true",
		AnonymousSuperclassesOfModuleClasses = "true",
		TransitiveSuperclasses = "true",
		DirectAssertedSubclassesOfModuleClasses = "true",
		AnonymousSubclassesOfModuleClasses = "true",
		TransitiveSubclasses = "true",
		PropertyRangeAssertionsForModuleClasses = "true",
		PropertyRangeAssertionsForModuleClassesForSuperclasses = "true",
		PropertyRangeAssertionsForModuleClassesForSubclasses = "true",
		RangeClassesForObjectPropertiesAtModuleClasses = "true",
		RangeClassesForObjectPropertiesAtSuperclasses = "true",
		RangeClassesForObjectPropertiesAtSubclasses = "true",
		RestrictionTargetClassesForRestrictionsAtModuleClasses = "true",
		RestrictionTargetClassesForRestrictionsAtSuperclasses = "true",
		RestrictionTargetClassesForRestrictionsAtSubclasses = "true",
		RestrictionSourcetClassesForRestrictionsAtModuleClasses = "false",
		RestrictionSourcetClassesForRestrictionsAtSuperclasses = "false",
		RestrictionSourcetClassesForRestrictionsAtSubclasses = "false",
		ShowOtherPropertiesInPropertyDomainRangeRestriction  = "false",
		AutomaticallyGenerateNamespacesFromEntityURI  = "true",
		DiscardPreviousOWLGrEdVersionAnnotations  = "true"
	}

	--delete previous parameter set
	lQuery("OWL_PP#PValueSet"):delete()
	lQuery("OWL_PP#Parameter"):delete()
	lQuery("OWL_PP#PValue"):delete()

	--create default parameter set
	local defaultSet = lQuery.create("OWL_PP#PValueSet", {sName="Default", isDefaultSet=true})
		:link("toolType", lQuery("ToolType"))

	--fill dafault parameter set
	for i,v in pairs(parameterTable) do
		local parameter = lQuery.create("OWL_PP#Parameter", {pName = i})
		lQuery.create("OWL_PP#PValue", {pName = i, pValue = v})
			:link("parameter", parameter)
			:link("pValueSet", defaultSet)
	end
	
	local parameter = lQuery.create("OWL_PP#Parameter", {pName = i})
	lQuery.create("OWL_PP#PValue", {pName = "showUnloadedAxioms InComment", pValue = "false"})
			:link("parameter", parameter)
			:link("pValueSet", defaultSet)
	local parameter = lQuery.create("OWL_PP#Parameter", {pName = i})
	lQuery.create("OWL_PP#PValue", {pName = "showUnloadedAxioms DisplayOnDemand", pValue = "true"})
			:link("parameter", parameter)
			:link("pValueSet", defaultSet)
			
			
	if lQuery("ToolType"):find("/tag[key='DefaultMaxCardinality1']"):size() == 0 then		
		lQuery.create("Tag", {key = "DefaultMaxCardinality1", value = 0})
			:link("type", lQuery("ToolType"))
	end
end