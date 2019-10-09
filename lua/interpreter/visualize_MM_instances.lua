module(...,package.seeall)

require "lQuery"
require "core"
d = require("dialog_utilities")

function visualizeCollection(coll, diagramName) --takes an lQuery collection, visualizes it (places boxes and interconnecting links)
	local diagramType = lQuery("GraphDiagramType[id=Instances]")
	if diagramName == nil or diagramName == "" then diagramName = "Instances" end
	local diagram = utilities.add_graph_diagram_to_graph_diagram_type(diagramName, diagramType)
	--local diagram = core.add_diagram("Instances", diagramType)
	coll:each(
		function(item)
			visualizeThing(item, diagram)
		end
	)
	print ("Boxes added, working on links now.")
	coll:each(
		function(item)
			drawAllLinks(item, diagram, false)
		end
	)
	utilities.execute_cmd("ActiveDgrCmd", {graphDiagram = diagram})
	utilities.execute_cmd("OkCmd")
	print ("Visualization finished.")
end

function visualizeThing(thing, diagram) --takes an lQuery collection containing exactly 1 thing, places a box for it in diagram
	local thingID = thing:id()
	local class = thing:get(1):class()
	local s = "" --string s is used to set the compartment that contains all of thing's property values
	for i, property in ipairs(class:property_list()) do
		if thing:attr(property) ~= nil then s = s..property..'="'..thing:attr(property)..'"\n' end
		if thing:attr(property) == nil then s = s..property..'=NOT_SET\n' end
	end
	local instanceTable =
	{
		Instance = {}
	}
	instanceTable.Instance[thingID] =
	{
		compartments =
		{
			Name =
			{
				repoID = thing:id()..'',
				repoClass = class.name
			},
			properties = s
		}
	}
	local t = core.add_elements_by_table(diagram, {}, instanceTable)
	--printTable(t,0)
	local elemID = t[thingID].objects[1].id
	return lQuery(elemID) --function returns the box it placed
end

function drawAllLinks(thing, diagram, drawThings) --takes an lQuery collection containing exactly 1 thing, draws all of its links in diagram.
--drawThings is true/false and says whether or not to add boxes for linked things that don't have boxes
	print (thing:id())
	local links = thing:get(1):class():link_list()
	for i, link in ipairs(links) do
		local linkedThing = thing:find("/"..link)
		if linkedThing:is_not_empty() then drawLink(thing, link, diagram, drawThings) end
	end
end

function drawLink(thing, link, diagram, drawThings) --takes an lQuery collection containing exactly 1 thing, draws specified link for it in diagram.
--drawThings is true/false and tells whether or not to draw boxes for the linked elements if they don't exist yet.
--function assumes there is something on the other end of the link
	--print ("    "..link)
	local linkType = lQuery(diagram):find("/graphDiagramType/elemType[id=MMLink]")
	local elementForThing = diagram:find("/element:has(/compartment/subCompartment[input="..thing:id().."])")
	local allLinkedThings = thing:find("/"..link)
	allLinkedThings:each(
		function(linkedThing)
			local elementForLinkedThing = diagram:find("/element:has(/compartment/subCompartment[input="..linkedThing:id().."])")
			if elementForLinkedThing:is_empty() and drawThings == true then --if there is no box and we need to draw new boxes, do so
				elementForLinkedThing = visualizeThing(linkedThing, diagram)
			end
			if elementForLinkedThing:is_not_empty() then --add link. Condition will fail if there was no box and drawThings is false, because then there is still no box
				--we need to check if the link is already there (for interactive visualization)
				local oldEdge = diagram:find("/element:has(/compartment:has(/compartType[id=Name])[input="..link.."]):has(/start:has(/compartment/subCompartment:has(/compartType[id=repoID])[input="..thing:id().."])):has(/end:has(/compartment/subCompartment:has(/compartType[id=repoID])[input="..linkedThing:id().."]))")
				if oldEdge:is_empty() then
					local edge = core.add_edge(linkType, elementForThing, elementForLinkedThing, diagram)
					local compartTable = {Name = link}
					core.add_compartments_by_table(edge, compartTable)
				end
			end
		end
	)
end

function openCollectionForm()
	local collectionForm = lQuery.create("D#Form",
	{
		id = "collectionForm",
		caption = "Specify the lQuery collection(-s)",
		editable = true,
		height = 300,
		width = 500,
		eventHandler = utilities.d_handler("Close", "lua_engine", "lua.visualizeMM.visualizeMM.closeCollectionForm()"),
		buttonClickOnClose = false,
		component =
		{
			lQuery.create("D#VerticalBox",
			{
				component =
				{
					lQuery.create("D#InputField",
					{
						id = "diagramNameSpecifier",
						editable = true
					}),
					lQuery.create("D#MultiLineTextBox",
					{
						enabled = true,
						id = "collectionSpecifier"
					}),
					lQuery.create("D#CheckBox",
					{
						id = "uniqueSpecifier",
						caption = "Unique?",
						checked = true,
						editable = true
					}),
					lQuery.create("D#Button",
					{
						id = "visualizeButton",
						caption = "Visualize collection",
						eventHandler = utilities.d_handler("Click", "lua_engine", "lua.visualizeMM.visualizeMM.visualize()"),
						enabled = true
					})
				}
			})
		}
	})
	d.show_form(collectionForm)
end

function closeCollectionForm()
	lQuery("D#Event"):delete()
	utilities.close_form("collectionForm")
end

function closeLinkForm()
	lQuery("D#Event"):delete()
	utilities.close_form("linkForm")
end

function visualize()
	--lQuery("D#TextLine[text=G]"):delete()
	local allCollections = lQuery("D#MultiLineTextBox[id=collectionSpecifier]/textLine")
	--[
	local collection = lQuery("D#Form"):remove(lQuery("D#Form")) --any class works, we just need an empty collection here
	allCollections:each( --add the collections that match all the given lQuery strings to collection
		function(item)
			local collectionString = item:attr("text")
			--print (collectionString)
			if collectionString ~= "" then collection = collection:add(lQuery(collectionString)) end
		end
	)
	--local collection = lQuery(allCollections:get(1):attr("text"))
	local uniqueCheckBox = lQuery("D#CheckBox[id=uniqueSpecifier]")
	if uniqueCheckBox:attr("checked") == true then collection = collection:unique() end
	local diagramName = lQuery("D#InputField[id=diagramNameSpecifier]"):attr("text")
	visualizeCollection(lQuery(collection), diagramName)
	closeCollectionForm()
end

function drawLinksContextCommand()
	print ("Drawing new links.")
	local activeElements = utilities.active_elements()
	local diagram = utilities.current_diagram()
	activeElements:each(
		function(thing)
			local thingID = thing:find("/compartment/subCompartment:has(/compartType[id=repoID])"):attr("input")
			drawAllLinks(lQuery(tonumber(thingID)),diagram,true) --tonumber is needed because thingID is string
		end
	)
	--utilities.execute_cmd("ActiveDgrCmd", {graphDiagram = diagram})
	--utilities.execute_cmd("OkCmd")
	utilities.refresh_active_diagram()
	print ("All links added.")
end

function openLinkForm()
	local activeElements = utilities.active_elements()
	local linkChoiceForm = lQuery.create("D#Form",
	{
		id = "linkForm",
		caption = "Which links will be drawn?",
		editable = true,
		eventHandler = utilities.d_handler("Close", "lua_engine", "lua.visualizeMM.visualizeMM.closeLinkForm()"),
		buttonClickOnClose = false,
		component =
		{
			lQuery.create("D#VerticalBox",
			{
				component =
				{
					lQuery.create("D#CheckBox",
					{
						id = "drawNew",
						caption = "Draw new boxes",
						checked = true,
						editable = true
					}),
					lQuery.create("D#VerticalBox",
					{
						id = "linkCheckBoxContainer"
					}),
					lQuery.create("D#Button",
					{
						id = "linkButton",
						caption = "Draw selected links",
						eventHandler = utilities.d_handler("Click", "lua_engine", "lua.visualizeMM.visualizeMM.drawSelectedLinks()"),
						enabled = true
					})
				}
			})
		}
	})
	local activeID = tonumber(activeElements:find("/compartment/subCompartment:has(/compartType[id=repoID])"):attr("input"))
	local linkList = lQuery(activeID):get(1):class():link_list()
	for i, link in ipairs(linkList) do
		if lQuery(activeID):find("/"..link):is_not_empty() then
			local checkBox = lQuery.create("D#CheckBox",
			{
				caption = link..":  "..lQuery(activeID):find("/"..link):get(1):class().name,
				id = link,
				checked = true,
				editable = true
			})
			lQuery("D#VerticalBox[id=linkCheckBoxContainer]"):link("component", checkBox)
		end
	end
	d.show_form(linkChoiceForm)
end

function drawSelectedLinks()
	print ("Drawing selected links.")
	local activeElements = utilities.active_elements() --the element from which the function was called
	local diagram = utilities.current_diagram() --current diagram
	local drawNewBoxes = lQuery("D#CheckBox[id=drawNew]"):attr("checked") --shows whether or not to draw new boxes
	if drawNewBoxes == "true" then drawNewBoxes = true else drawNewBoxes = false end --previous line returns string. Need boolean.
	local activeID = activeElements:find("/compartment/subCompartment:has(/compartType[id=repoID])"):attr("input") --the repository ID of whatever we're drawing links for
	local activeThing = lQuery(tonumber(activeID)) --the thing for which links are being drawn
	lQuery("D#VerticalBox[id=linkCheckBoxContainer]/component"):each(
		function(linkCheckBox)
			if linkCheckBox:attr("checked") == "true" then
				local linkName = linkCheckBox:attr("id")
				drawLink(activeThing, linkName, diagram, drawNewBoxes)
				--addedThings = addedThings:add(activeThing:find("/"..linkName))
			end
		end
	)
	closeLinkForm()
	utilities.refresh_active_diagram()
	print ("Selected links added.")
end
