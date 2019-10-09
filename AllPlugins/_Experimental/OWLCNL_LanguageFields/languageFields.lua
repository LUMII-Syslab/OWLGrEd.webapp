module(..., package.seeall)

require("java")
require "core"
d = require("dialog_utilities") 
json = require ("reporter.dkjson")
OWL_specific = require("OWL_specific") 
OWL_CNL_specific = require("OWLCNL_LanguageFields.OWL_CNL_specific") 

function test_custom_row(row, compart, form)
	form:log("id")
	row:log("id")
	d.add_component_with_handler(row, 
	{minimumWidth = 200}, 
	"D#InputField", 
	{Change = "lua.utilities.test"})
	d.add_button(row, 
	{caption = "Next Form"}, 
	{Click = "lua.utilities.close_form"})
end


function isHiddenTrue()
    return "true"
end

function damainLuaTable()
	local luaTable = {
		[1]={
			["rowTitle"]="U",
			["makeFieldGroup"]="false",
			["isUniversal"]="true",
			["mainField"]="POS",
			["procInit"]="Void",
			["procLoad"]="Void",
			["procSave"]="Void",
			["type"]="Role",
			["HandleEvent"] = {
				["NounVerb"]={
					["Click"]="lua.OWLCNL_LanguageFields.languageFields.NounVerbUpdate"
				}
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="POS",
					["procValueUpdated"]="NounVerb",
					["fieldMode"]="Main",
					["fieldType"]="HRadioGroup",
					["caption"]="Type of predicate",
					["OWLCNL#ChoiceItemDef"]={
						["pType_Verb"]={
							["formValue"]="Verb",
							["isDefault"]="true"
						},
						["pType_Noun"]={
							["formValue"]="Noun",
							["isDefault"]="false"
						}
					}
				}
			}
		},
		[3]={
			["makeFieldGroup"]="true",
			["rowTitle"]="English",
			["languageName"]="English",
			["languageCode"]="en",
			["languageCodeGF"]="Eng",
			["isUniversal"]="false",
			["mainField"]="Eng_Predicate",
			["procInit"]="SetUpMainForm",
			["procLoad"]="LoadPropertyData",
			["procSave"]="SaveLanguageRow",
			["type"]="Role",
			["HandleEvent"] = {
				["PropertyUpdated"]={
					["FocusLost"]="lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"
				}
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="Eng_pType",
					["selectorPath"]="POS",
					["fieldMode"]="None"
				},
				[2]={
					["fieldName"]="Eng_Subject",
					--["fieldType"]="Label",
					["fieldType"]="TextBox",
					["fieldMode"]="Main",
					["caption"]="Subject",
					["isEnabled"]="true"
				},
				[3]={
					["fieldName"]="Eng_Predicate",
					["procValueUpdated"]="PropertyUpdated",
					["fieldMode"]="Main",
					["fieldType"]="TextBox",
					["caption"]="Predicate",
					["suffixValue"]="is",
				},
				[4]={
					["fieldName"]="Eng_Object_D",
					--["fieldType"]="Label",
					["fieldType"]="TextBox",
					["fieldMode"]="Main",
					["caption"]="Object",
					["isEnabled"]="true"
				},
				[5]={
					["fieldName"]="Eng_infinitive",
					["selectorPath"]="infinitive",
					["fieldMode"]="None"
				},
				[6]={
					["fieldName"]="Eng_participle",
					["selectorPath"]="participle",
					["fieldMode"]="None"
				},
				[7]={
					["fieldName"]="Eng_preposotion",
					["selectorPath"]="preposotion",
					["fieldMode"]="None"
				},
				[8]={
					["fieldName"]="Eng_voice",
					["selectorPath"]="voice",
					["fieldMode"]="None"
				},
				[9]={
					["fieldName"]="Eng_tence",
					["selectorPath"]="tence",
					["fieldMode"]="None"
				},
				[10]={
					["fieldName"]="Eng_singular",
					["selectorPath"]="singular",
					["fieldMode"]="None"
				},
				[11]={
					["fieldName"]="Eng_plural",
					["selectorPath"]="plural",
					["fieldMode"]="None"
				},
				[12]={
					["fieldName"]="Eng_gender",
					["selectorPath"]="gender",
					["fieldMode"]="None"
				}
			}
		},
		[4]={
			["makeFieldGroup"]="true",
			["rowTitle"]="Latvian",
			["languageName"]="Latviešu",
			["languageCode"]="lv",
			["languageCodeGF"]="Lav",
			["isUniversal"]="false",
			["mainField"]="LV_Predicate_D",
			["procInit"]="...",
			["procLoad"]="...",
			["procSave"]="...",
			["type"]="Role",
			["HandleEvent"] = {
				["PropertyUpdated"]={
					["FocusLost"]="lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"
				},
				["Subject_M_Updated"]={
					["Change"]="lua.OWLCNL_LanguageFields.languageFields.UpdateSubjectFields"
				},
				["ObjectUpdated"]={
					["Change"]="lua.OWLCNL_LanguageFields.languageFields.UpdateObjectFields"
				}
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="LV_pType",
					["selectorPath"]="POS",
				},
				[2]={
					["fieldName"]="LV_Subject_M",
					["fieldType"]="ComboBox",
					["fieldMode"]="Main",
					["caption"]="Subject",
					["procValueUpdated"]="Subject_M_Updated",
					["isEnabled"]="true"
				},
				[3]={
					["fieldName"]="LV_Predicate",
					["procValueUpdated"]="PropertyUpdated",
					["fieldMode"]="Main",
					["fieldType"]="TextBox",
					["caption"]="Predicate",
					["suffixValue"]="ir",
				},
				[4]={
					["fieldName"]="LV_Object_D",
					["fieldType"]="ComboBox",
					["fieldMode"]="Main",
					["caption"]="Object",
					["procValueUpdated"]="ObjectUpdated",
					["isEnabled"]="true"
				}
			}
		},
		[5]={
			["makeFieldGroup"]="false",
			["rowTitle"]="English",
			["languageName"]="English",
			["languageCode"]="en",
			["languageCodeGF"]="Eng",
			["isUniversal"]="false",
			["mainField"]="ENG_Predicate_C",
			["procInit"]="...",
			["procLoad"]="...",
			["procSave"]="...",
			["type"]="Class",
			["HandleEvent"] = {
				["PropertyUpdated"]={
					["FocusLost"]="lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"
				},
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="ENG_Predicate_C",
					["procValueUpdated"]="PropertyUpdated",
					["fieldMode"]="Main",
					["fieldType"]="TextBox",
					["caption"]="English",
				},
				[2]={
					["fieldName"]="Eng_singular",
					["selectorPath"]="entry.singular",
					["fieldMode"]="None"
				},
				[3]={
					["fieldName"]="Eng_plural",
					["selectorPath"]="entry.plural",
					["fieldMode"]="None"
				},
				[4]={
					["fieldName"]="Eng_gender",
					["selectorPath"]="entry.gender",
					["fieldMode"]="None"
				},
				[5]={
					["fieldName"]="Eng_label",
					["selectorPath"]="label",
					["fieldMode"]="None"
				},
				[6]={
					["fieldName"]="Eng_URI",
					["selectorPath"]="URI",
					["fieldMode"]="None"
				}
			}
		},
		[6]={
			["makeFieldGroup"]="false",
			["rowTitle"]="Latvian",
			["languageName"]="Latviešu",
			["languageCode"]="lv",
			["languageCodeGF"]="Lav",
			["isUniversal"]="false",
			["mainField"]="LV_Predicate_C",
			["procInit"]="...",
			["procLoad"]="...",
			["procSave"]="...",
			["type"]="Class",
			["HandleEvent"] = {
				["PropertyUpdated"]={
					["FocusLost"]="lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"
				},
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="LV_Predicate_C",
					["procValueUpdated"]="PropertyUpdated",
					["fieldMode"]="Main",
					["fieldType"]="TextBox",
					["caption"]="Latvian",
				},
				[2]={
					["fieldName"]="Eng_components",
					["selectorPath"]="entry.components",
					["fieldMode"]="None"
				},
				[3]={
					["fieldName"]="Eng_pattern",
					["selectorPath"]="entry.pattern",
					["fieldMode"]="None"
				},
				[4]={
					["fieldName"]="Eng_number",
					["selectorPath"]="entry.number",
					["fieldMode"]="None"
				},
				[5]={
					["fieldName"]="Eng_gender",
					["selectorPath"]="entry.gender",
					["fieldMode"]="None"
				},
				[6]={
					["fieldName"]="Eng_label",
					["selectorPath"]="label",
					["fieldMode"]="None"
				},
				[7]={
					["fieldName"]="Eng_URI",
					["selectorPath"]="URI",
					["fieldMode"]="None"
				}
			}
		},
		[7]={
			["makeFieldGroup"]="false",
			["rowTitle"]="English",
			["languageName"]="English",
			["languageCode"]="en",
			["languageCodeGF"]="Eng",
			["isUniversal"]="false",
			["mainField"]="ENG_Predicate_I",
			["procInit"]="...",
			["procLoad"]="...",
			["procSave"]="...",
			["type"]="Individual",
			["HandleEvent"] = {
				["PropertyUpdated"]={
					["FocusLost"]="lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"
				},
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="ENG_Predicate_I",
					["procValueUpdated"]="PropertyUpdated",
					["fieldMode"]="Main",
					["fieldType"]="TextBox",
					["caption"]="English",
				}
			}
		},
		[8]={
			["makeFieldGroup"]="false",
			["rowTitle"]="Latvian",
			["languageName"]="Latviešu",
			["languageCode"]="lv",
			["languageCodeGF"]="Lav",
			["isUniversal"]="false",
			["mainField"]="LV_Predicate_I",
			["procInit"]="...",
			["procLoad"]="...",
			["procSave"]="...",
			["type"]="Individual",
			["HandleEvent"] = {
				["PropertyUpdated"]={
					["FocusLost"]="lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"
				},
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="LV_Predicate_I",
					["procValueUpdated"]="PropertyUpdated",
					["fieldMode"]="Main",
					["fieldType"]="TextBox",
					["caption"]="Latvian",
				}
			}
		},
		[9]={
			["makeFieldGroup"]="false",
			["rowTitle"]="English",
			["languageName"]="English",
			["languageCode"]="en",
			["languageCodeGF"]="Eng",
			["isUniversal"]="false",
			["mainField"]="ENG_Predicate_A",
			["procInit"]="...",
			["procLoad"]="...",
			["procSave"]="...",
			["type"]="Attribute",
			["HandleEvent"] = {
				["PropertyUpdated"]={
					["FocusLost"]="lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"
				},
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="ENG_Predicate_A",
					["procValueUpdated"]="PropertyUpdated",
					["fieldMode"]="Main",
					["fieldType"]="TextBox",
					["caption"]="English",
				}
			}
		},
		[10]={
			["makeFieldGroup"]="false",
			["rowTitle"]="Latvian",
			["languageName"]="Latviešu",
			["languageCode"]="lv",
			["languageCodeGF"]="Lav",
			["isUniversal"]="false",
			["mainField"]="LV_Predicate_A",
			["procInit"]="...",
			["procLoad"]="...",
			["procSave"]="...",
			["type"]="Attribute",
			["HandleEvent"] = {
				["PropertyUpdated"]={
					["FocusLost"]="lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"
				},
			},
			["OWLCNL#FieldDef"] = {
				[1]={
					["fieldName"]="LV_Predicate_A",
					["procValueUpdated"]="PropertyUpdated",
					["fieldMode"]="Main",
					["fieldType"]="TextBox",
					["caption"]="Latvian",
				}
			}
		}
	}
	return luaTable
end

function loadLuaTable()
	local luaTable = damainLuaTable()
	--print(dumptable(luaTable))
	for i,k in next,luaTable,nil do
	-- for i, k in pairs(luaTable) do
		local LanguageRowDef = lQuery.create("OWLCNL#LanguageRowDef")
		local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
		for j, l in pairs(property_list) do
			LanguageRowDef:attr(l, k[l])
		end
		local FieldDefs = k["OWLCNL#FieldDef"]
		if FieldDefs~=nil then 
			--for j, l in next,FieldDefs,nil do
			for j, l in ipairs(FieldDefs) do
				--print(j, l)
				local FieldDef = lQuery.create("OWLCNL#FieldDef"):link("IPack", LanguageRowDef)
				local property_list = lQuery.model.property_list("OWLCNL#FieldDef")
				for u, v in pairs(property_list) do
					FieldDef:attr(v, l[v])
				end
				if l["fieldMode"]=="Main" then FieldDef:link("languageRowDef",LanguageRowDef) end
				local ChoiceItemDefs = l["OWLCNL#ChoiceItemDef"]
				if ChoiceItemDefs~=nil then 
					for u, v in pairs(ChoiceItemDefs) do
						local ChoiceItemDef = lQuery.create("OWLCNL#ChoiceItemDef"):link("fieldDef", FieldDef)
						local property_list = lQuery.model.property_list("OWLCNL#ChoiceItemDef")
						for r, s in pairs(property_list) do
							ChoiceItemDef:attr(s, v[s])
							--print("	", v[s])
						end
					end
				end
			end
		end
		local HandleEvents = k["HandleEvent"]
		if HandleEvents~=nil then 
			for j, l in pairs(HandleEvents) do
				local HandleEvent = lQuery.create("OWLCNL#EventHandlerDef"):link("languageRowDef", LanguageRowDef)
				HandleEvent:attr("eventName", j)
				for u, v in pairs(l) do
					HandleEvent:attr("eventType", u)
					HandleEvent:attr("procName", v)
				end
			end
		end
	end
end

function domainMetamodel()
	lQuery.model.add_class("OWLCNL#LanguageRowDef")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "makeFieldGroup")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "isUniversal")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "languageName")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "languageCode")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "languageCodeGF")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "rowTitle")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "procInit")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "procLoad")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "procSave")
		lQuery.model.add_property("OWLCNL#LanguageRowDef", "type")
	lQuery.model.add_class("OWLCNL#FieldDef")
		lQuery.model.add_property("OWLCNL#FieldDef", "selectorPath")
		lQuery.model.add_property("OWLCNL#FieldDef", "procValueUpdated")
		lQuery.model.add_property("OWLCNL#FieldDef", "fieldMode")
		lQuery.model.add_property("OWLCNL#FieldDef", "caption")
		lQuery.model.add_property("OWLCNL#FieldDef", "fieldType")
		lQuery.model.add_property("OWLCNL#FieldDef", "suffixValue")
		lQuery.model.add_property("OWLCNL#FieldDef", "isEnabled")
		lQuery.model.add_property("OWLCNL#FieldDef", "domainValue")
		lQuery.model.add_property("OWLCNL#FieldDef", "isAvailable")
		lQuery.model.add_property("OWLCNL#FieldDef", "value")
		lQuery.model.add_property("OWLCNL#FieldDef", "isEditable")
		lQuery.model.add_property("OWLCNL#FieldDef", "suffixFieldID")
	lQuery.model.add_class("OWLCNL#ChoiceItemDef")
		lQuery.model.add_property("OWLCNL#ChoiceItemDef", "domainValue")
		lQuery.model.add_property("OWLCNL#ChoiceItemDef", "formValue")
		lQuery.model.add_property("OWLCNL#ChoiceItemDef", "isDefault")
		lQuery.model.add_property("OWLCNL#ChoiceItemDef", "isAvailable")
	lQuery.model.add_class("OWLCNL#EventHandlerDef")
		lQuery.model.add_property("OWLCNL#EventHandlerDef", "eventName")
		lQuery.model.add_property("OWLCNL#EventHandlerDef", "procName")
		lQuery.model.add_property("OWLCNL#EventHandlerDef", "eventType")
	
	
	lQuery.model.add_class("OWLCNL#LanguageRow")
		lQuery.model.add_property("OWLCNL#LanguageRow", "makeFieldGroup")
		lQuery.model.add_property("OWLCNL#LanguageRow", "isUniversal")
		lQuery.model.add_property("OWLCNL#LanguageRow", "languageName")
		lQuery.model.add_property("OWLCNL#LanguageRow", "languageCode")
		lQuery.model.add_property("OWLCNL#LanguageRow", "languageCodeGF")
		lQuery.model.add_property("OWLCNL#LanguageRow", "rowTitle")
		lQuery.model.add_property("OWLCNL#LanguageRow", "procInit")
		lQuery.model.add_property("OWLCNL#LanguageRow", "procLoad")
		lQuery.model.add_property("OWLCNL#LanguageRow", "procSave")
		lQuery.model.add_property("OWLCNL#LanguageRow", "type")
	lQuery.model.add_class("OWLCNL#Field")
		lQuery.model.add_property("OWLCNL#Field", "selectorPath")
		lQuery.model.add_property("OWLCNL#Field", "procValueUpdated")
		lQuery.model.add_property("OWLCNL#Field", "fieldMode")
		lQuery.model.add_property("OWLCNL#Field", "caption")
		lQuery.model.add_property("OWLCNL#Field", "fieldType")
		lQuery.model.add_property("OWLCNL#Field", "suffixValue")
		lQuery.model.add_property("OWLCNL#Field", "isEnabled")
		lQuery.model.add_property("OWLCNL#Field", "domainValue")
		lQuery.model.add_property("OWLCNL#Field", "isAvailable")
		lQuery.model.add_property("OWLCNL#Field", "value")
		lQuery.model.add_property("OWLCNL#Field", "isEditable")
		lQuery.model.add_property("OWLCNL#Field", "suffixFieldID")
	lQuery.model.add_class("OWLCNL#Item")
		lQuery.model.add_property("OWLCNL#Item", "domainValue")
		lQuery.model.add_property("OWLCNL#Item", "formValue")
		lQuery.model.add_property("OWLCNL#Item", "isDefault")
		lQuery.model.add_property("OWLCNL#Item", "isAvailable")
	
	lQuery.model.add_link("OWLCNL#LanguageRow", "languageRow", "field", "OWLCNL#Field")
	
	lQuery.model.add_composition("OWLCNL#Item","item","field","OWLCNL#Field")
	
	lQuery.model.add_composition("OWLCNL#FieldDef","fieldDef","IPack","OWLCNL#LanguageRowDef")
	lQuery.model.add_composition("OWLCNL#EventHandlerDef","eventHandlerDef","languageRowDef","OWLCNL#LanguageRowDef")
	lQuery.model.add_composition("OWLCNL#ChoiceItemDef","choiceItemDef","fieldDef","OWLCNL#FieldDef")
	
	lQuery.model.add_link("OWLCNL#LanguageRowDef", "languageRowDef", "mainField", "OWLCNL#FieldDef")
end

function functionOnClose()
	lQuery("OWLCNL#Field"):delete()
	lQuery("OWLCNL#Item"):delete()
	lQuery("OWLCNL#LanguageRow"):delete()
	--print("functionOnClose")
end

--izveido noun/verb radio pogu
function noun_verb_row(row, compart, form)
	local value = compart:attr("value")
	if value == "" then compart:attr("value", "Verb") end
	
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='U'][type='Role']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
		
	makeLanguageRow(languageRow, languageRowRunTime, form, row, compart)
end

function findDomainAndRange(compartment)
	local range
	local domain
	local compartType = compartment:find("/compartType")
	local l = 0
	while l==0 do
		if compartType:attr("id")=="Role" or compartType:attr("id")=="InvRole" then l=1
		else
			compartType = compartType:find("/parentCompartType")
		end
	end
	--if get_tab_name():attr("caption")=="Direct" then
	if compartType:attr("id")=="InvRole" then
		domain = utilities.active_elements():find("/end")
		range = utilities.active_elements():find("/start")
		if utilities.active_elements():is_empty() then
			local element = compartment
			local l = 0
			while l==0 do
				if element:find("/parentCompartment"):is_not_empty() then element = element:find("/parentCompartment")
				else
					element = element:find("/element")
					l=1
				end
			end
			domain = element:find("/end")
			range = element:find("/start")
		end
	else
		domain = utilities.active_elements():find("/start")
		range = utilities.active_elements():find("/end")
		if utilities.active_elements():is_empty() then
			local element = compartment
			local l = 0
			while l==0 do
				if element:find("/parentCompartment"):is_not_empty() then element = element:find("/parentCompartment")
				else
					element = element:find("/element")
					l=1
				end
			end
			domain = element:find("/start")
			range = element:find("/end")
		end
	end
	return domain, range
end

function latvian_row_individual(row, compart, form)
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='Latvian'][type='Individual']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
	makeLanguageRow(languageRow, languageRowRunTime, form, row, compart)
end

function english_row_individual(row, compart, form)
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='English'][type='Individual']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
	makeLanguageRow(languageRow, languageRowRunTime, form, row, compart)
end

function latvian_row_attribute(row, compart, form)
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='Latvian'][type='Attribute']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
	makeLanguageRowAttribute(languageRow, languageRowRunTime, form, row, compart)
end

function english_row_attribute(row, compart, form)
	local parent = form:find("/presentationElement")
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='English'][type='Attribute']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
	makeLanguageRowAttribute(languageRow, languageRowRunTime, form, row, compart)
end

function latvian_row_class(row, compart, form)
	local parent = form:find("/presentationElement")
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='Latvian'][type='Class']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
	makeLanguageRow(languageRow, languageRowRunTime, form, row, compart)
end

function english_row_class(row, compart, form)
	local parent = form:find("/presentationElement")
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='English'][type='Class']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
	makeLanguageRow(languageRow, languageRowRunTime, form, row, compart)
end

function latvian_row_role(row, compart, form)
	local range
	local domain
	domain, range = findDomainAndRange(compart)
	
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='Latvian'][type='Role']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
	
	makeLanguageRow(languageRow, languageRowRunTime, form, row, compart, domain, range)
end

function english_row_role(row, compart, form)
	local range
	local domain
	domain, range = findDomainAndRange(compart)
	
	local languageRow = lQuery("OWLCNL#LanguageRowDef[rowTitle='English'][type='Role']")
	local languageRowRunTime = lQuery.create("OWLCNL#LanguageRow")
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#LanguageRowDef")
	for i, prop in pairs(property_list) do languageRowRunTime:attr(prop, languageRow:attr(prop)) end
	
	makeLanguageRow(languageRow, languageRowRunTime, form, row, compart, domain, range)
end

function getChoiceItems(fieldName,  fieldRunTime, choiceItemTable)
	local fieldValue
	fieldName = string.lower(fieldName)
	for i, fieldType in pairs(choiceItemTable) do
		if type(fieldType)=="table" then
			for j, ciTable in pairs(fieldType) do
				if ciTable[fieldName .. ".case"]~=nil then
					lQuery.create("OWLCNL#Item", {domainValue = ciTable[fieldName .. ".string"], formValue=ciTable[fieldName .. ".string"], isDefault=ciTable[fieldName .. ".default"], domainValue=ciTable[fieldName .. ".case"]}):link("field", fieldRunTime)
					if ciTable[fieldName .. ".default"]=='true' then fieldValue=ciTable[fieldName .. ".string"] end
				end
			end
		else
			fieldValue = choiceItemTable[fieldName]
		end
	end
	return fieldValue
end

function makeLanguageRowAttribute(LanguageRowDef, languageRowRunTime, form, row, compartment)
	--RUNTIME lauks
	
	local parent = form:find("/presentationElement")
	local compart_type = utilities.get_property_row_from_row(row):find("/compartType")
	
	
	local fieldDef = LanguageRowDef:find("/fieldDef")
	--row:link("compartType", )
	local fieldRunTime = lQuery.create("OWLCNL#Field"):link("languageRow", languageRowRunTime)
	--parkopejam visu no definicijas dalas
	local property_list = lQuery.model.property_list("OWLCNL#FieldDef")
	for i, prop in pairs(property_list) do fieldRunTime:attr(prop, fieldDef:attr(prop)) end
		
	local row2 = row
	local column = d.add_component(row2, {},"D#Column")
	local compartmentId = parent:id()
	if compartment~=nil then compartmentId = compartment:id() end
	d.add_component(column, {id = compartmentId, caption = fieldDef:attr("caption"), minimumWidth = 100},"D#Label")
	
	local value = ""
	--if compartment~=nil then value = compartment:attr("value") end
	if compartment~=nil and compartment:find("/tag[key='CNL_JSON']"):is_not_empty() then 
		local tagTable = json.decode(compartment:find("/tag[key='CNL_JSON']"):attr("value"))
		value = tagTable["label_gen"]
	end
	local column = d.add_component(row2, {},"D#Column")
	local newField = d.add_component(column, {id = compartmentId, minimumWidth = 250, text = value}, "D#InputField")
	
	if fieldDef:attr("caption") == "English" then
		local Properties =  require("interpreter.Properties")
		Properties.set_as_first_respondent(newField)
	end
	
	local EventHandlerDef = lQuery("OWLCNL#EventHandlerDef[eventName='" .. fieldDef:attr("procValueUpdated") .. "']")
	if EventHandlerDef:is_not_empty() then
		local eventType = EventHandlerDef:attr("eventType")
		local procName = EventHandlerDef:attr("procName")
		d.add_event_handlers(newField, {[eventType] = procName})
	end

	if compartment~=nil then newField:link("compartment", compartment) end
	newField:link("compartType", compart_type)
	fieldRunTime:attr("fieldID", newField:id())
	
	local newSuffixField = d.add_component(column, {caption = ""},"D#Label")
	fieldRunTime:attr("suffixFieldID", newSuffixField:id())
end

function makeLanguageRow(LanguageRowDef, languageRowRunTime, form, row, compartment, domain, range)
	field = row
	--ja ir grupa
	if LanguageRowDef:attr("makeFieldGroup")=="true" then
		field = d.add_component(row, {caption = LanguageRowDef:attr("rowTitle"), horizontalSpan=3, bottomMargin=8},"D#GroupBox")
	end
	
	local parent = compartment:find("/parentCompartment")--Role
	local nounVerb = parent:find("/subCompartment:has(/compartType[id='CNL_NounVerb'])")
	local nounVerbValue = nounVerb:attr("value")
	if nounVerbValue~=nil then nounVerbValue=string.lower(nounVerbValue) else nounVerbValue = "" end
	 
	local subject
	local subjectField
	local object
	local objectField
	local jsonStringCalculateValences
	if LanguageRowDef:attr("rowTitle")~="U" then 	
		if domain==nil then subject="" 
		--else subject = domain:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") end
		else 	
			subjectField = domain:find("/compartment:has(/compartType[id='CNL_" .. LanguageRowDef:attr("rowTitle") .. "'])")
			subject = subjectField:attr("value") 
		end
		if range==nil then object="" 
		--else object = range:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") end
		else 
			objectField = range:find("/compartment:has(/compartType[id='CNL_" .. LanguageRowDef:attr("rowTitle") .. "'])")
			object = objectField:attr("value")
		end
		--ja ir jauna instance
		--if compartment:find("/tag[key='CNL_JSON']"):is_empty() then
			saveStructureToTag(nounVerbValue, languageRowRunTime:attr("languageCode"), subject, object, compartment, languageRowRunTime:attr("type"), subjectField, objectField)
		--end
		if languageRowRunTime:attr("languageCode")=="en" and nounVerb:attr("value")=="Verb" then
		elseif languageRowRunTime:attr("type")=="Role" or nounVerb:attr("value")=="Noun" then
			--	print(string.lower(nounVerb:attr("value")),languageRowRunTime:attr("languageCode"), subject, object, "QQQQQQQQQQQQQQQQQQQQQQQ")
			-- print(compartment:find("/tag[key='CNL_JSON']"):attr("value"))
			local tagTable = json.decode(compartment:find("/tag[key='CNL_JSON']"):attr("value"))
			if tagTable["element"]=="objectProperty" and (tagTable["subject.entry.components"]~="" and tagTable["subject"]~="") and (tagTable["object.entry.components"]~="" and tagTable["object"]~="") then
				jsonStringCalculateValences = calculateValences(compartment:find("/tag[key='CNL_JSON']"):attr("value"))--Role
			end
			--print("OOOOO", dumptable(json.decode(jsonStringCalculateValences)), "OOOOO")
		end
	end
	--pa visiem fieldDef laukiem, izveidojam fieldDefRunTime laukus un ipasibu dialoga laukus
	LanguageRowDef:find("/fieldDef"):each(function(fieldDef)
		local fieldType = fieldDef:attr("fieldType")
		
		--RUNTIME lauks
		local fieldRunTime = lQuery.create("OWLCNL#Field"):link("languageRow", languageRowRunTime)
		--parkopejam visu no definicijas dalas
		local property_list = lQuery.model.property_list("OWLCNL#FieldDef")
		for i, prop in pairs(property_list) do fieldRunTime:attr(prop, fieldDef:attr(prop)) end
		--for i, prop in pairs(property_list) do print(fieldRunTime:attr(prop)) end
		
		if fieldType=="HRadioGroup" then
			--fieldId=row id
			fieldRunTime:attr("fieldID", field:id())

			local column = d.add_component(field, {},"D#Column")
			d.add_component(column, {caption = fieldDef:attr("caption"), minimumWidth = 100},"D#Label")
			column = d.add_component(field, {},"D#Column")
			choiceItemRow = d.add_component(column, {horizontalAlignment = -1},"D#Row")
			fieldDef:find("/choiceItemDef"):each(function(choiceItemDef)
				local value = compartment:attr("value")
				local selectedValue = false
				if choiceItemDef:attr("formValue")==value then selectedValue = true end
				local newField = d.add_component(choiceItemRow, {caption = choiceItemDef:attr("formValue"), selected = selectedValue}, "D#RadioButton")
				
				local EventHandlerDef = lQuery("OWLCNL#EventHandlerDef[eventName='" .. fieldDef:attr("procValueUpdated") .. "']")
				if EventHandlerDef:is_not_empty() then
					local eventType = EventHandlerDef:attr("eventType")
					local procName = EventHandlerDef:attr("procName")
					d.add_event_handlers(newField, {[eventType] = procName})
				end
				newField:link("compartment", compartment)
			end)
		else
			local value
			if jsonStringCalculateValences~=nil then  value = getChoiceItems(fieldDef:attr("caption"), fieldRunTime, json.decode(jsonStringCalculateValences)) end
			--veidod laukus tikai main laukiem
			if fieldDef:attr("fieldMode")=="Main" then
				if (value =="" or value ==nil) and fieldDef:attr("caption") == "Subject" then 
					value = domain:find("/compartment:has(/compartType[id='CNL_"..LanguageRowDef:attr("rowTitle").."'])"):attr("value")
				end
				if (value ==""or value ==nil) and fieldDef:attr("caption") == "Object" then 
					value = range:find("/compartment:has(/compartType[id='CNL_"..LanguageRowDef:attr("rowTitle").."'])"):attr("value")
				end
				if fieldDef:attr("caption") == "Predicate" or  value ==nil  then 
					value=compartment:attr("value")
				end
				local row2
				if LanguageRowDef:find("/fieldDef[fieldMode='Main']"):size() == 1 then row2  = row else
					row2 = d.add_component(field, {horizontalAlignment = -1},"D#Row")
				end
				local column = d.add_component(row2, {},"D#Column")
				d.add_component(column, {id = compartment:id(), caption = fieldDef:attr("caption"), minimumWidth = 100},"D#Label")
				if fieldType=="Label" then 
					local column = d.add_component(row2, {horizontalAlignment = -1},"D#Column")
					local newField= d.add_component(column, {caption = value, horizontalAlignment = -1}, "D#" .. fieldType)
					fieldRunTime:attr("fieldID", newField:id())
				elseif fieldType=="TextBox" then 
					
					local isReadOnly = false
					if fieldDef:attr("isEnabled")=="true" then isReadOnly = true end
					--print(isReadOnly, "isReadOnly")
					local column = d.add_component(row2, {},"D#Column")
					local newField = d.add_component(column, {id = compartment:id(), minimumWidth = 250, maximumWidth = 250, text = value, readOnly=isReadOnly}, "D#InputField")
					if fieldDef:attr("caption") == "English" or (languageRowRunTime:attr("languageCode")=="en" and fieldDef:attr("caption") == "Predicate") then
						local Properties =  require("interpreter.Properties")
						Properties.set_as_first_respondent(newField)
					end
					local EventHandlerDef = lQuery("OWLCNL#EventHandlerDef[eventName='" .. fieldDef:attr("procValueUpdated") .. "']")
					if EventHandlerDef:is_not_empty() then
						local eventType = EventHandlerDef:attr("eventType")
						local procName = EventHandlerDef:attr("procName")
						d.add_event_handlers(newField, {[eventType] = procName})
					end

					--d.add_event_handlers(newField, {FocusLost = "lua.OWLCNL_LanguageFields.languageFields.UpdateDetailsFields"})
					if fieldDef:attr("caption") ~= "Subject" and fieldDef:attr("caption") ~= "Object" then
						newField:link("compartment", compartment)
					end
					fieldRunTime:attr("fieldID", newField:id())
				elseif fieldType=="CheckBox" or fieldType=="ComboBox" then 
					local column = d.add_component(row2, {},"D#Column")
					local isReadOnly = true
					
					if fieldDef:attr("isEnabled")=="true" then isReadOnly = false end
					--print(isReadOnly, "isReadOnly")
					local newField= d.add_component(column, {id = compartment:id(), minimumWidth = 250,maximumWidth = 250, text = value, editable=isReadOnly}, "D#" .. fieldType)
					
					local EventHandlerDef = lQuery("OWLCNL#EventHandlerDef[eventName='" .. fieldDef:attr("procValueUpdated") .. "']")
					if EventHandlerDef:is_not_empty() then
						local eventType = EventHandlerDef:attr("eventType")
						local procName = EventHandlerDef:attr("procName")
						d.add_event_handlers(newField, {[eventType] = procName})
					end
					
					fieldRunTime:find("/item"):each(function(item)
						local itemF =  d.add_item_to_box(newField, item:attr("formValue"))
						itemF:attr("id", item:attr("domainValue"))
						if item:attr("isDefault")=="true" then
							d.set_selected_item_in_list_box(newField, itemF)
							local t = {["predicate.entry." .. string.lower(fieldDef:attr("caption"))] = item:attr("domainValue")}
							saveJSONtoTag(compartment, json.encode(t))
						end
					end)
					fieldRunTime:attr("fieldID", newField:id())
				end
				--suffix
				local suffix = ""
				if nounVerb:attr("value")=="Noun" then suffix = fieldDef:attr("suffixValue") end
				local column = d.add_component(row2, {},"D#Column")
				local newSuffixField = d.add_component(column, {caption = suffix},"D#Label")
				fieldRunTime:attr("suffixFieldID", newSuffixField:id())
			end
		end
	end)
end

function findDefaultSubjectObjectItem(jsonReturnValueLvNoun)
	local choiceItemTable = json.decode(jsonReturnValueLvNoun)
	local subject, object
	for i, fieldType in pairs(choiceItemTable) do
		for j, ciTable in pairs(fieldType) do
			if ciTable["subject.case"]~=nil then
				subject = ciTable["subject.string"]
			elseif ciTable["object.case"]~=nil then
				object = ciTable["object.string"]
			end
		end
	end
	local luaTable = {
		["subject"] = subject,
		["object"] = object
	}
	return json.encode(luaTable)
end

function UpdateSubjectFields()
	local ev = lQuery("D#Event")
	local component = ev:find("/source")
	local value = component:attr("text")
	local compartmentId = tonumber(component:attr("id"))
	local compartment = lQuery("Compartment"):filter(function(comp)
		return comp:id() == compartmentId
	end)
	local selectedItem = component:find("/selected")
	local case = selectedItem:attr("id")
	local tagValue = compartment:find("/tag[key='CNL_JSON']"):attr("value")
	local tagTable = json.decode(tagValue)
	tagTable["predicate.entry.subject"] = case

	compartment:find("/tag[key='CNL_JSON']"):attr("value", json.encode(tagTable))
	
end

function UpdateObjectFields()
	local ev = lQuery("D#Event")
	local component = ev:find("/source")
	local value = component:attr("text")
	local compartmentId = tonumber(component:attr("id"))
	local compartment = lQuery("Compartment"):filter(function(comp)
		return comp:id() == compartmentId
	end)
	local selectedItem = component:find("/selected")
	local case = selectedItem:attr("id")
	local tagValue = compartment:find("/tag[key='CNL_JSON']"):attr("value")
	local tagTable = json.decode(tagValue)
	tagTable["predicate.entry.object"] = case

	compartment:find("/tag[key='CNL_JSON']"):attr("value", json.encode(tagTable))
end

function saveJSONtoTagReplace(compartment, value)
	local luaTable = {}
	
	local tagValue = compartment:find("/tag[key='CNL_JSON']"):attr("value")
	local tagTable = json.decode(tagValue)
	local valueTable = json.decode(value)
	if tagTable["element"]=="objectProperty" then
		for i, k in pairs(tagTable) do
			--tagTable[i]=k
			--if i~= "predicate.entry" then 
				if string.sub(i, 1, 6)=="entry." then luaTable["predicate." .. i]=k 
				--else
				elseif tagTable[string.sub(i, 11)]==nil then
					luaTable[i]=k 
				end
			--end
		end
		--print(dumptable(luaTable))
		local compartmentTagValue = json.encode(luaTable)
		if valueTable["entry.preposition"]==nil then 
			--luaTable["predicate.entry.preposition"]=nil
			compartmentTagValue = json.encode(luaTable)
			local len = string.len(compartmentTagValue)
			compartmentTagValue = string.sub(compartmentTagValue, 1, len-1)
			compartmentTagValue = compartmentTagValue .. [[,"predicate.entry.preposition":null}]]
		end
		
		compartment:find("/tag[key='CNL_JSON']"):attr("value", compartmentTagValue)
	end
end

function saveJSONtoTag(compartment, value)
	if compartment:find("/tag[key='CNL_JSON']"):is_empty() then
		lQuery.create("Tag", {key='CNL_JSON', value=value}):link("thing", compartment)
	else
		local tagValue = compartment:find("/tag[key='CNL_JSON']"):attr("value")
		local tagTable = json.decode(tagValue)
		local valueTable = json.decode(value)
		for i, k in pairs(valueTable) do
			tagTable[i]=k
		end
		compartment:find("/tag[key='CNL_JSON']"):attr("value", json.encode(tagTable))
	end
end

function anywhere (p)
  return lpeg.P{ p + 1 * lpeg.V(1) }
end
--[[
--Eng noun
{
	["language"]="",
	["POS"]="",
	["subject"]="",
	["object"]="",
	["singular"]="",
	["plural"]="",
	["gender"]="",
	["label"]="",
	["URI"]="",
}
--Lv noun
{
	["language"]="",
	["POS"]="",
	["subject"]="",
	["object"]="",
	["components"]="",
	["pattern"]="",
	["number"]="",
	["gender"]="",
	["label"]="",
	["URI"]="",
}

--Lv verb
{
	["language"]="",
	["POS"]="",
	["subject"]="",
	["object"]="",
	["predicate.entry.infinitive"]="",
	["predicate.entry.present"]="",
	["predicate.entry.past"]="",
	["predicate.entry.voice"]="",
	["predicate.entry.tense"]="",
	["predicate.entry.subject"]="",
	["predicate.entry.object"]="",
	["subject.entry.components"]="",
	["subject.entry.pattern"]="",
	["subject.entry.number"]="",
	["subject.entry.gender"]="",
	["object.entry.components"]="",
	["object.entry.pattern"]="",
	["object.entry.number"]="",
	["object.entry.gender"]="",
}

--Eng verb
{
	["language"]="",
	["POS"]="",
	["subject"]="",
	["object"]="",
	["infinitive"]="",
	["present"]="",
	["participle"]="",
	["preposition"]="",
	["voice"]="",
	["tense"]="",
	["label"]="",
	["URI"]="",
}--]]

function saveStructureToTag(pos, language, subject, object, compartment, lrtype, subjectField, objectField)
	local element,subjectPattern,objectPattern, subjectNumber, objectNumber, subjectGender, objectGender = "","","","","","",""
	if predicate==nil then predicate="" end
	local calculateValencesTable
	
	if compartment:find("/tag[key='CNL_JSON']"):is_not_empty() then
		local tagTable = json.decode(compartment:find("/tag[key='CNL_JSON']"):attr("value"))
		predicate = tagTable["label"]
	end
	
	if lrtype == "Role" then 
		element="objectProperty"
		if subjectField:find("/tag[key='CNL_JSON']"):is_not_empty() then
			local tagTable = json.decode(subjectField:find("/tag[key='CNL_JSON']"):attr("value"))
			subjectPattern = tagTable["entry.pattern"]
			subjectNumber = tagTable["entry.number"]
			subjectGender = tagTable["entry.gender"]
			subjectComponents = tagTable["entry.components"]
		end
		if objectField:find("/tag[key='CNL_JSON']"):is_not_empty() then
			local tagTable = json.decode(objectField:find("/tag[key='CNL_JSON']"):attr("value"))
			objectPattern = tagTable["entry.pattern"]
			objectNumber = tagTable["entry.number"]
			objectGender = tagTable["entry.gender"]
			objectComponents = tagTable["entry.components"]
		end
		if language == "lv" then 
			if subject=="" then subjectComponents="" end
			if object=="" then objectComponents="" end
			calculateValencesTable = {
				["language"]=language,
				["POS"]=pos,
				--["predicate.entry"]="null",
				-- ["subject.entry.components"]=subject,
				["subject.entry.components"]=subjectComponents,
				["subject.entry.pattern"]=subjectPattern,
				["subject.entry.number"]=subjectNumber,
				["subject.entry.gender"]=subjectGender,
				-- ["object.entry.components"]=object,
				["object.entry.components"]=objectComponents,
				["object.entry.pattern"]=objectPattern,
				["object.entry.number"]=objectNumber,
				["object.entry.gender"]=objectGender,
				["element"]=element
			}
		else
			calculateValencesTable = {
				["language"]=language,
				["POS"]=pos,
				["subject"]=subject,
				["object"]=object,
				["element"]=element
			}
		end
		
	elseif lrtype == "Class" then 
		element="class"
		calculateValencesTable = {
			["language"]=language,
			["element"]=element,
			--["label"]=predicate,
		}
	elseif lrtype == "Individual" then 
		element="individual"
		calculateValencesTable = {
			["language"]=language,
			["element"]=element,
			--["label"]=predicate,
		}
	elseif lrtype == "Attribute" then 
		element="dataProperty"
		calculateValencesTable = {
			["language"]=language,
			["element"]=element,
			--["label"]=predicate,
		}
	end
	--saglabāt strukturu tag-a
	--if subject==nil then subject="students" end
	saveJSONtoTag(compartment, json.encode(calculateValencesTable))
end

function calculateValences(tagJsonString)
	-- print("calculateValences")
	-- print(dumptable(json.decode(tagJsonString)))
	local class_name = 'lv.lumii.owlgred.cnl.Dispatcher'
	local public_static_method_name = 'calculateValences'
	local jsonReturnValue =java.call_static_class_method(class_name, public_static_method_name, tagJsonString)
	return jsonReturnValue
end

function UpdateDetailsFields()
	local ev = lQuery("D#Event")
	local component = ev:find("/source")
	local compart = component:find("/compartment")
	local compartType = component:find("/compartType")
	local parent2 = lQuery("Compartment"):filter(function(comp)
		return comp:id() == tonumber(component:attr("id"))
	end)
	if value~="" and compart:is_empty() then
		compart = core.create_missing_compartment(parent2, parent2:find("/compartType"), compartType)

		--izveidot tag strukturu	

		calculateValencesTable = {
			["element"]="dataProperty",
		}
		saveJSONtoTag(compart, json.encode(calculateValencesTable))
	end
	if value~="" and compart:is_not_empty() then
		local value = component:attr("text")
		compart:attr("value", value)
		
		calculateValencesTable = {
			["element"]="dataProperty",
		}
		--saveJSONtoTag(compart, json.encode(calculateValencesTable))

		local parent = compart:find("/parentCompartment")
		local pos = parent:find("/subCompartment:has(/compartType[id='CNL_NounVerb'])"):attr("value")
		if pos == nil then pos = "" end
		local language
		local languageFull
		if compart:find("/compartType"):attr("id")=="CNL_English" then 
			language="en"
			languageFull = "English"
		elseif compart:find("/compartType"):attr("id")=="CNL_Latvian" then 
			language="lv"
			languageFull = "Latvian" 
		end
		
		calculateParametersOnFocusLost(value, compart, string.lower(pos), language)
		if language=="en" and pos=="Verb" then
		else
			local tagTable = json.decode(compart:find("/tag[key='CNL_JSON']"):attr("value"))
			if tagTable["element"]=="objectProperty" and (tagTable["subject.entry.components"]~="" or tagTable["subject"]~="") and (tagTable["object.entry.components"]~="" or tagTable["object"]~="") then
				jsonStringCalculateValences = calculateValences(compart:find("/tag[key='CNL_JSON']"):attr("value"))
				changeSubjectObjectChoiceItems(compart, jsonStringCalculateValences)
			end
		end
		----------------
		local tagTable = json.decode(compart:find("/tag[key='CNL_JSON']"):attr("value"))
		local uri_gen = tagTable["URI_gen"]
		local name
		if tagTable["element"]=="class" then name = compart:find("/element/compartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		elseif tagTable["element"]=="individual" then name = compart:find("/element/compartment/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		else
		name = compart:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Name'])")
		end
		if name:is_empty() then
			local nameCompartType = compart:find("/parentCompartment/compartType/subCompartType[id='Name']")
			local name_name = lQuery.create("Compartment")
				:link("parentCompartment", compart:find("/parentCompartment"))
				:link("compartType", nameCompartType)
			nameCompartType = nameCompartType:find("/subCompartType[id='Name']")
			name = lQuery.create("Compartment")
				:link("parentCompartment", name_name)
				:link("compartType", nameCompartType)
				:link("component", component:find("/container/container/container/component[id='Name']/component[id='field']"))
		end
		local diagram = utilities.current_diagram()
		local OWL_element = diagram:find("/source")
		local generateNames = OWL_element:find("/compartment:has(/compartType[id='URI_Gen_Language'])")
		if generateNames:attr("value")~="" and languageFull == generateNames:attr("value") then
			if uri_gen~="" then
				name:attr("value", uri_gen)
				name:attr("input", uri_gen)

				core.set_parent_value(name)

				name:find("/component"):attr("text", uri_gen)
				OWL_specific.set_class_name(name)

				utilities.refresh_form_component(name:find("/component"))
			end
		end
		
		-- if language=="en" and name:attr("value")=="" and generateNames:attr("value")=="true" then
			
		-- end
		if tagTable["element"]=="dataProperty" then
			OWL_CNL_specific.set_attr_display_label(name)
		else
			OWL_CNL_specific.set_display_label(name)
		end
		local cmd = lQuery.create("OkCmd")
		cmd:link("graphDiagram", diagram)
		utilities.execute_cmd_obj(cmd)
	end
end

function changeSubjectObjectChoiceItems(compartment, jsonTable)
	changeFieldItems(compartment, jsonTable, "Subject")
	changeFieldItems(compartment, jsonTable, "Object")
end

function changeFieldItems(compartment, jsonTable, fieldName)
	local componentId= compartment:find("/component"):id()
	local field = lQuery("OWLCNL#Field[fieldID='" .. componentId .. "']")
	
	local languageRow = field:find("/languageRow")
	local item = field:find("/item")
	
	local fieldRunTime = languageRow:find("/field[caption='" .. fieldName .. "']")
	
	--izdzest Item laukus
	fieldRunTime:find("/item"):delete()
	
	local subjectFieldId = languageRow:find("/field[caption='" .. fieldName .. "']"):attr("fieldID")
	local subjectField = lQuery("D#ComboBox"):filter(function(label)
		return label:id() == tonumber(subjectFieldId)
	end)
	
	--izdzest Property dialoga itemus
	subjectField:find("/item"):delete()
	
	--izveidod jaunus item laukus
	getChoiceItems(fieldRunTime:attr("caption"), fieldRunTime, json.decode(jsonTable))
	--izveidod jaunus Property dialoga itemus
	fieldRunTime:find("/item"):each(function(item)
		local itemF =  d.add_item_to_box(subjectField, item:attr("formValue"))
		itemF:attr("id", item:attr("domainValue"))
		if item:attr("isDefault")=="true" then
			d.set_selected_item_in_list_box(subjectField, itemF)
			local t = {["predicate.entry." .. string.lower(fieldName)] = item:attr("domainValue")}
			saveJSONtoTag(compartment, json.encode(t))
		end
	end)
	--atjaunot laukus
	if subjectField:is_not_empty() then subjectField:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"})) end
end

function calculateParametersOnFocusLost(predicate, compartment, pos, lang)
	--if compartment:attr("value")~="" then
		local tagTable = json.decode(compartment:find("/tag[key='CNL_JSON']"):attr("value"))

		local element = tagTable["element"]
		local luaTableForEncode = {
		   ["element"]=element,
		   ["language"]=lang,                
		   ["label"]=predicate,             
		   ["POS"]=pos
		}

		local jsonStringEncoding = json.encode(luaTableForEncode)
		
		local class_name = 'lv.lumii.owlgred.cnl.Dispatcher'
		local public_static_method_name = 'calculateParameters'
		
		local jsonReturnValue =java.call_static_class_method(class_name, public_static_method_name, jsonStringEncoding)
		
		local t = json.decode(jsonReturnValue)
		local luaReturnTable = json.decode(jsonReturnValue)
		local label_gen = luaReturnTable["label_gen"]
		if label_gen~=compartment:attr("value") then
			compartment:attr("value", label_gen)
			
			local component = compartment:find("/component")
			component:attr("text", label_gen)
			component:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
		end
		-- local luaTable = {}
		-- for i, k in pairs(luaReturnTable) do
			-- if i~= "predicate.entry" then 
				-- if string.find(i, "entry.")~=nil then luaTable["predicate." .. i]=k 
				-- else
					-- luaTable[i]=k 
				-- end
			-- end
		-- end
		
		--jasaglaba atgriezta vertiba compartmenta tag-a
		saveJSONtoTag(compartment, jsonReturnValue)
		--saveJSONtoTag(compartment, json.encode(luaTable))
		saveJSONtoTagReplace(compartment, jsonReturnValue)
		--compartment:find("/tag[key='CNL_JSON']"):attr("value", json.encode(luaTable))

		 --saveJSONtoTag(compartment, json.encode(luaReturnTable2))
		--------------------------------------------------------------------
		--jaatzime Field lauki ar isAvailable
		for i, k in pairs(luaReturnTable) do
			local pathTable = split(i, ".")
			local l = #pathTable
			lQuery("OWLCNL#Field[caption='" .. pathTable[l] .. "']"):attr("isAvailable", true)
			--for j, l in pairs(pathTable) do
				
			--end
		end
		--------------------------------------------------------------------
	--end
end

function split (s, sep)
    sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = lpeg.Ct(elem * (sep * elem)^0)
  return lpeg.match(p, s)
end

function getSubjectObject(fieldName, choiceItemTable)
	local fieldValue
	fieldName = string.lower(fieldName)
	for i, fieldType in pairs(choiceItemTable) do
		if type(fieldType)=="table" then
			for j, ciTable in pairs(fieldType) do
				if ciTable[fieldName .. ".case"]~=nil then
					if ciTable[fieldName .. ".default"]=='true' then fieldValue=ciTable[fieldName .. ".string"] end
				end
			end
		else
			fieldValue = choiceItemTable[fieldName]
		end
	end
	return fieldValue
end

function NounVerbUpdate()
	local ev = lQuery("D#Event")
	local caption = ev:find("/source"):attr("caption")
	local component = ev:find("/source")
	local compart = component:find("/compartment")
	local parent = compart:find("/parentCompartment")
	local english = parent:find("/subCompartment:has(/compartType[id='CNL_English'])")
	local latvian = parent:find("/subCompartment:has(/compartType[id='CNL_Latvian'])")
	
	compart:attr("value", caption)
	
	--izdzest tagu
	english:find("/tag[key='CNL_JSON']"):delete()
	latvian:find("/tag[key='CNL_JSON']"):delete()
	
	local domain, range = findDomainAndRange(compart)
	--local object = range:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
	local objectField = range:find("/compartment:has(/compartType[id='CNL_English'])")
	local object = range:find("/compartment:has(/compartType[id='CNL_English'])"):attr("value")

	local objectFieldLV = range:find("/compartment:has(/compartType[id='CNL_Latvian'])")
	local objectLV = range:find("/compartment:has(/compartType[id='CNL_Latvian'])"):attr("value")
	
	--local subject = domain:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
	local subjectField = domain:find("/compartment:has(/compartType[id='CNL_English'])")
	local subject = domain:find("/compartment:has(/compartType[id='CNL_English'])"):attr("value")
	local subjectFieldLV = domain:find("/compartment:has(/compartType[id='CNL_Latvian'])")
	local subjectLV = domain:find("/compartment:has(/compartType[id='CNL_Latvian'])"):attr("value")
	
	saveStructureToTag(string.lower(caption),"en", subject, object, english, "Role", subjectField, objectField)
	saveStructureToTag(string.lower(caption),"lv", subjectLV, objectLV, latvian, "Role", subjectFieldLV, objectFieldLV)
	
	local suffixEng = ""
	local suffixLv = ""
	
	calculateParametersOnFocusLost(english:attr("value"), english, string.lower(caption), "en")
	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	--if caption~="Verb" then calculateParametersOnFocusLost(english:attr("value"), english, string.lower(caption), "en") end
	calculateParametersOnFocusLost(latvian:attr("value"), latvian, string.lower(caption), "lv")
	
	local jsonReturnValueEn
	local jsonReturnValueLv
	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	local tagTable = json.decode(english:find("/tag[key='CNL_JSON']"):attr("value"))
	if tagTable["element"]=="objectProperty" and (tagTable["subject.entry.components"]~="" and tagTable["subject"]~="") and (tagTable["object.entry.components"]~="" and tagTable["object"]~="") then
		if caption~="Verb" then jsonReturnValueEn = calculateValences(english:find("/tag[key='CNL_JSON']"):attr("value")) end
	end
	local tagTable = json.decode(latvian:find("/tag[key='CNL_JSON']"):attr("value"))
	if tagTable["element"]=="objectProperty" and (tagTable["subject.entry.components"]~="" and tagTable["subject"]~="") and (tagTable["object.entry.components"]~="" and tagTable["object"]~="") then
		jsonReturnValueLv = calculateValences(latvian:find("/tag[key='CNL_JSON']"):attr("value"))
	end
	if jsonReturnValueEn~=nil then object = getSubjectObject("Object", json.decode(jsonReturnValueEn)) end
	if jsonReturnValueEn~=nil then subject = getSubjectObject("Subject", json.decode(jsonReturnValueEn)) end
	

	if caption=="Noun" then
		--uzstadit sufiksu
		local componentId= english:find("/component"):id()
		local field = lQuery("OWLCNL#Field[fieldID='" .. componentId .. "']")
		local languageRow = field:find("/languageRow")

		suffixEng = field:attr("suffixValue")

		local componentId= latvian:find("/component"):id()
		local field = lQuery("OWLCNL#Field[fieldID='" .. componentId .. "']")
		local languageRow = field:find("/languageRow")

		suffixLv = field:attr("suffixValue")
	end
	
	local componentId= english:find("/component"):id()
	local field = lQuery("OWLCNL#Field[fieldID='" .. componentId .. "']")
	local languageRow = field:find("/languageRow")
	
	--suffix
	local suffixField = lQuery("D#Label"):filter(function(label)
		return label:id() == tonumber(field:attr("suffixFieldID"))
	end)
	suffixField:attr("caption", suffixEng)
	suffixField:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	--subject En
	local subjectFieldId = languageRow:find("/field[caption='Subject']"):attr("fieldID")
	local subjectField = lQuery("D#InputField"):filter(function(label)
		return label:id() == tonumber(subjectFieldId)
	end)
	--print(subject)
	subjectField:attr("text", subject)
	subjectField:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	--object en
	local objectFieldId = languageRow:find("/field[caption='Object']"):attr("fieldID")
	local objectField = lQuery("D#InputField"):filter(function(label)
		return label:id() == tonumber(objectFieldId)
	end)
	objectField:attr("text", object)
	objectField:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	--preditate, nometam vertibu en
	local PredicateFieldId = languageRow:find("/field[caption='Predicate']"):attr("fieldID")
	local PredicateField = lQuery("D#InputField"):filter(function(label)
		return label:id() == tonumber(PredicateFieldId)
	end)
	PredicateField:attr("text", "")
	PredicateField:find("/compartment"):attr("value", "")
	PredicateField:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	---------LV
	local componentId= latvian:find("/component"):id()
	local field = lQuery("OWLCNL#Field[fieldID='" .. componentId .. "']")
	local languageRow = field:find("/languageRow")
	
	--suffix
	local suffixField = lQuery("D#Label"):filter(function(label)
		return label:id() == tonumber(field:attr("suffixFieldID"))
	end)
	suffixField:attr("caption", suffixLv)
	suffixField:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	local PredicateFieldId = languageRow:find("/field[caption='Predicate']"):attr("fieldID")
	local PredicateField = lQuery("D#InputField"):filter(function(label)
		return label:id() == tonumber(PredicateFieldId)
	end)
	PredicateField:attr("text", "")
	PredicateField:find("/compartment"):attr("value", "")
	PredicateField:link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	if jsonReturnValueLv~= nil then changeSubjectObjectChoiceItems(latvian, jsonReturnValueLv) end
	
end

function set_display_label_and_CNL_JSON_tag_for_all_elements(diagram)
	local OWL_CNL_specific = require ("OWLCNL_LanguageFields.OWL_CNL_specific")
	
	local clases = diagram:find("/element:has(/elemType[id='Class'])")
	clases:each(function(class)
		--katrai valodai
		local en_compartment = class:find("/compartment:has(/compartType[id='CNL_English'])")
		calculate_CNL_JSON_tag_on_ontology_import("en", en_compartment, "Class", "", "", "", "", "")
		local lv_compartment = class:find("/compartment:has(/compartType[id='CNL_Latvian'])")
		calculate_CNL_JSON_tag_on_ontology_import("lv", lv_compartment, "Class", "", "", "", "", "")
		
		--Atributi
		local attributes = class:find("/subCompartment/subCompartment:has(/compartType[id='Attributes'])")
		attributes:each(function(attribute)
			local en_compartment = attributes:find("/subCompartment:has(/compartType[id='CNL_English'])")
			calculate_CNL_JSON_tag_on_ontology_import("en", en_compartment, "Attribute", "", "", "", "", "")

			local lv_compartment = attributes:find("/subCompartment:has(/compartType[id='CNL_Latvian'])")
			calculate_CNL_JSON_tag_on_ontology_import("lv", lv_compartment, "Attribute", "", "", "", "", "")
		end)
	end)
	
	local objects = diagram:find("/element:has(/elemType[id='Object'])")
	objects:each(function(object)
		--katrai valodai
		local en_compartment = object:find("/compartment:has(/compartType[id='CNL_English'])")
		calculate_CNL_JSON_tag_on_ontology_import("en", en_compartment, "Individual", "", "", "", "", "")

		local lv_compartment = object:find("/compartment:has(/compartType[id='CNL_Latvian'])")
		calculate_CNL_JSON_tag_on_ontology_import("lv", lv_compartment, "Individual", "", "", "", "", "")
	end)
	
	--associations
	local associations = diagram:find("/element:has(/elemType[id='Association'])")
	associations:each(function(association)
		--role
		local role = association:find("/compartment:has(/compartType[id='Role'])")
		CNL_JSON_tag_for_role(role)
		
		--invRole
		local invrole = association:find("/compartment:has(/compartType[id='InvRole'])")
		CNL_JSON_tag_for_role(invrole)
	end)
		
	
	OWL_CNL_specific.set_display_label_for_all_elements(diagram)
end

function CNL_JSON_tag_for_role(role)
	local nounVerb = role:find("/subCompartment:has(/compartType[id='CNL_NounVerb'])"):attr("value")
	if nounVerb=="" then nounVerb = "Verb" end
	local compart = role:find("/subCompartment:has(/compartType[id='CNL_English'])")
	local range, domain, subject, subjectField, object, objectField
	domain, range = findDomainAndRange(compart)
	if domain==nil then subject="" 
	--else subject = domain:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") end
	else 	
		subjectField = domain:find("/compartment:has(/compartType[id='CNL_English'])")
		subject = subjectField:attr("value") 
	end
	if range==nil then object="" 
	--else object = range:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") end
	else 
		objectField = range:find("/compartment:has(/compartType[id='CNL_English'])")
		object = objectField:attr("value")
	end
	
	--katrai valodai
	local en_compartment = role:find("/subCompartment:has(/compartType[id='CNL_English'])")
	calculate_CNL_JSON_tag_on_ontology_import("en", en_compartment, "Role", string.lower(nounVerb), subject, object, subjectField, objectField)
	
	
	local compart = role:find("/subCompartment:has(/compartType[id='CNL_Latvian'])")
	
	local range, domain, subject, subjectField, object, objectField
	domain, range = findDomainAndRange(compart)
	if domain==nil then subject="" 
	--else subject = domain:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") end
	else 	
		subjectField = domain:find("/compartment:has(/compartType[id='CNL_Latvian'])")
		subject = subjectField:attr("value") 
	end
	if range==nil then object="" 
	--else object = range:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") end
	else 
		objectField = range:find("/compartment:has(/compartType[id='CNL_Latvian'])")
		object = objectField:attr("value")
	end
	
	local lv_compartment = role:find("/subCompartment:has(/compartType[id='CNL_Latvian'])")
	calculate_CNL_JSON_tag_on_ontology_import("lv", lv_compartment, "Role", string.lower(nounVerb), subject, object, subjectField, objectField)
end

function calculate_CNL_JSON_tag_on_ontology_import(language, compartment, compartType, pos, subject, object, subjectField, objectField)
	--izveidot CNL_JSON tagu
	saveStructureToTag(pos, language, subject, object, compartment, compartType, subjectField, objectField)
	calculateParametersOnFocusLost(compartment:attr("value"), compartment, pos, language)
	if language=="lv" then
		local tagTable = json.decode(compartment:find("/tag[key='CNL_JSON']"):attr("value"))
		if tagTable["element"]=="objectProperty" and tagTable["subject.entry.components"]~="" and tagTable["object.entry.components"]~="" then
			local tcv = {
						  POS = pos,
						  language = language,
						  ["object.entry.components"] = tagTable["object.entry.components"],
						  ["object.entry.gender"] = tagTable["object.entry.gender"],
						  ["object.entry.number"] = tagTable["object.entry.number"],
						  ["object.entry.pattern"] = tagTable["object.entry.pattern"],

						  ["subject.entry.components"] = tagTable["subject.entry.components"],
						  ["subject.entry.gender"] = tagTable["subject.entry.gender"],
						  ["subject.entry.number"] = tagTable["subject.entry.number"],
						  ["subject.entry.pattern"] = tagTable["subject.entry.pattern"]
						}
			jsonStringCalculateValences = calculateValences(json.encode(tcv))
			local pes, peo = "nominative", "nominative"
			
			for i, fieldType in pairs(json.decode(jsonStringCalculateValences)) do
				if type(fieldType)=="table" then
					for j, ciTable in pairs(fieldType) do
						if ciTable["subject.string"]==string.lower(subject) then
							pes = ciTable["subject.case"]
						end
						if ciTable["object.string"]==string.lower(object) then
							peo = ciTable["object.case"]
						end
					end
				end
			end
			local t = {
				["predicate.entry.object"] = pes,
				["predicate.entry.subject"] = peo
			}
			saveJSONtoTag(compartment, json.encode(t))
		end
	end
end