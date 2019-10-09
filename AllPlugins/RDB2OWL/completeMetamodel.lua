module(..., package.seeall)

require("lua_tda")

function completeMetamodel()
	lQuery.model.add_class("D#MoveTextCursorCommand")
	lQuery.model.add_property("D#MoveTextCursorCommand", "row")
	lQuery.model.add_property("D#MoveTextCursorCommand", "horizontalPosition")
	lQuery.model.set_super_class("D#MoveTextCursorCommand", "D#Command")
	
	local prEH1  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLclassMap"})
	local prEH2  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLdataMap"})
	local prEH3  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLobjectMap"})
	local prEH4  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLobjectMap"})
	local prEH5  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLontologyDBExpr"})
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):link("propertyEventHandler", prEH1)
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):link("propertyEventHandler", prEH2)
	lQuery("ElemType[id='Annotation']/compartType/subCompartType[id='Value']/propertyRow"):link("propertyEventHandler", prEH5)
	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):link("propertyEventHandler", prEH3)
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):link("propertyEventHandler", prEH4)

	local prEH6  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLclassMapMultiLineButton"})
	local prEH7  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLdataMapMultiLineButton"})
	local prEH8  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLobjectMapMultiLineButton"})
	local prEH9  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLobjectMapMultiLineButton"})
	lQuery("ElemType[id='Class']/compartType[caption='DBExpr']/propertyRow"):link("propertyEventHandler", prEH6)
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):link("propertyEventHandler", prEH7)
	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):link("propertyEventHandler", prEH8)
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):link("propertyEventHandler", prEH9)
	
	-- local compartType = lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']")
    -- lQuery.create("Translet", {extensionPoint = 'procDecompose', procedureName = 'RDB2OWL.reGrammar.dbexprGrammar'}):link("type", compartType)

	local compartType = lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']")
	lQuery.create("Translet", {extensionPoint = 'procGetPattern', procedureName = 'RDB2OWL.reGrammar.dbexprGrammar'}):link("type", compartType)
	
	-----------------------
	--Metamodela jaunas klases
	lQuery.model.add_class("RR#Database")
		lQuery.model.add_property("RR#Database", "dbName")
		lQuery.model.add_property("RR#Database", "jdbcDriver")
		lQuery.model.add_property("RR#Database", "connection")
		lQuery.model.add_property("RR#Database", "schema")
		lQuery.model.add_property("RR#Database", "publicTablePrefix")
		lQuery.model.add_property("RR#Database", "dbref")
		lQuery.model.add_property("RR#Database", "dbAlias")
		lQuery.model.add_property("RR#Database", "isDefaultDB")
	lQuery.model.add_class("RR#DBFunction")
		lQuery.model.add_property("RR#DBFunction", "fName")
		lQuery.model.add_property("RR#DBFunction", "isAggregate")
		lQuery.model.add_property("RR#DBFunction", "hasXSDRef")
	lQuery.model.add_class("RR#Table")
		lQuery.model.add_property("RR#Table", "tName")
		lQuery.model.add_property("RR#Table", "isDefault")
		lQuery.model.add_property("RR#Table", "typeName")
	lQuery.model.add_class("RR#View")
		lQuery.model.add_property("RR#View", "tName")
	lQuery.model.add_class("RR#PKey")
	lQuery.model.add_class("RR#Column")
		lQuery.model.add_property("RR#Column", "colName")
	lQuery.model.add_class("RR#FKey")
		
	
	lQuery.model.add_class("RR#FunctionDef")
		lQuery.model.add_property("RR#FunctionDef", "fName")
		lQuery.model.add_property("RR#FunctionDef", "isAggregate")
		lQuery.model.add_property("RR#FunctionDef", "hasXSDRef")
	
	lQuery.model.add_class("RR#Param")
		lQuery.model.add_property("RR#Param", "pName")
		
	lQuery.model.add_composition("RR#FunctionDef","functionDef","param","RR#Param")
	
	lQuery.model.add_composition("RR#DBFunction","DBFunction","database","RR#Database")
	lQuery.model.add_composition("RR#Table","table","database","RR#Database")

	lQuery.model.add_composition("RR#View","view","table","RR#Table")
	lQuery.model.add_composition("RR#Column","column","table","RR#Table")
	
	lQuery.model.add_composition("RR#PKey","pKey","table","RR#Table")
	lQuery.model.add_composition("RR#PKey","pKey","column","RR#Column")
	
	lQuery.model.add_composition("RR#FKey","fKey","target","RR#Table")
	lQuery.model.add_composition("RR#FKey","fKey","column","RR#Column")
	
	readUseAutoCompletion()
	-----------------------------------------------
	--testa dati
	--[[
	lQuery.create("RR#FunctionDef", {fName="function1", param = {
		lQuery.create("RR#Param", {pName="p1_fun1"})
		,lQuery.create("RR#Param", {pName="p2_fun1"})
		}})
	lQuery.create("RR#FunctionDef", {fName="function2", param = {
		lQuery.create("RR#Param", {pName="p1_fun2"})
		,lQuery.create("RR#Param", {pName="p2_fun2"})
		}})
	lQuery.create("RR#FunctionDef", {fName="agr_function1", isAggregate=true, param = {
		lQuery.create("RR#Param", {pName="p1_agrfun1"})
		,lQuery.create("RR#Param", {pName="p2_agrfun1"})
		}})
	
	lQuery.create("RR#Database", {dbName="D1", dbAlias="Ref1", isDefaultDB=1, table={
		lQuery.create("RR#Table", {tName="TableAAA", column={
			lQuery.create("RR#Column", {colName="ColA1"})
			,lQuery.create("RR#Column", {colName="ColA2"})}
		})
		,lQuery.create("RR#Table", {tName="TableBBB", column={
			lQuery.create("RR#Column", {colName="ColB1"})
			,lQuery.create("RR#Column", {colName="ColB2"})}
		})
		,lQuery.create("RR#Table", {tName="TableCCC"})
		}})


	lQuery.create("RR#Database", {dbName="MiniUniv", dbAlias="RefMiniUniv", isDefaultDB=1, table={
		lQuery.create("RR#Table", {tName="XTeacher", column={
			lQuery.create("RR#Column", {colName="TName"})
			,lQuery.create("RR#Column", {colName="Level"})
			,lQuery.create("RR#Column", {colName="IDCode"})
			,lQuery.create("RR#Column", {colName="AutoID"})
			}
		})
		,lQuery.create("RR#Table", {tName="XStudent", column={
			lQuery.create("RR#Column", {colName="SName"})
			,lQuery.create("RR#Column", {colName="IDCode"})
			}})
		,lQuery.create("RR#Table", {tName="XCourse", column={
			lQuery.create("RR#Column", {colName="CName"})
			,lQuery.create("RR#Column", {colName="isRequired"})
			}})
		,lQuery.create("RR#Table", {tName="XProgram", column={
			lQuery.create("RR#Column", {colName="PName"})
			}})
		}})
	--]]
end

function onOffAutoCompletion()
	local path

	if tda.isWeb then 
		path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "RDB2OWL")
	else
		path = tda.GetProjectPath() .. "\\Plugins\\RDB2OWL"
	end
	
	local f = assert(io.open(path .. "\\config.txt", "r"))
    local t = f:read("*a")
	f:close()
	local pat = lpeg.P("useautocompletion") * lpeg.S(" \n\t") ^ 0 * lpeg.P("=") * lpeg.S(" \n\t") ^ 0 * lpeg.C(lpeg.R("09"))
	local pat = anywhere(pat)
	local useautocompletion = lpeg.match(pat, t)
	
	local f = assert(io.open(path .. "\\config.txt", "w"))
	if useautocompletion == "1" then 
		addRemoveAutoCompletion("0")
		f:write("useautocompletion = 0")
	else 
		addRemoveAutoCompletion("1")
		f:write("useautocompletion = 1")
	end
	f:close()
end

function readUseAutoCompletion()
	local path

	if tda.isWeb then 
		path = tda.FindPath(tda.GetToolPath() .. "\\AllPlugins", "RDB2OWL")
	else
		path = tda.GetProjectPath() .. "\\Plugins\\RDB2OWL"
	end
	
	local f = assert(io.open(path .. "\\config.txt", "r"))
    local t = f:read("*a")
	f:close()
	local pat = lpeg.P("useautocompletion") * lpeg.S(" \n\t") ^ 0 * lpeg.P("=") * lpeg.S(" \n\t") ^ 0 * lpeg.C(lpeg.R("09"))
	local pat = anywhere(pat)
	local useautocompletion = lpeg.match(pat, t)
	addRemoveAutoCompletion(useautocompletion)
end

function addRemoveAutoCompletion(useautocompletion)
	if useautocompletion=="1" then 
		local prEH1  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLclassMap"})
		local prEH2  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLdataMap"})
		local prEH3  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLobjectMap"})
		local prEH4  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLobjectMap"})
		local prEH5  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLontologyDBExpr"})
		lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):link("propertyEventHandler", prEH1)
		lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):link("propertyEventHandler", prEH2)
		lQuery("ElemType[id='Annotation']/compartType/subCompartType[id='Value']/propertyRow"):link("propertyEventHandler", prEH5)
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):link("propertyEventHandler", prEH3)
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):link("propertyEventHandler", prEH4)

		local prEH6  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLclassMapMultiLineButton"})
		local prEH7  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLdataMapMultiLineButton"})
		local prEH8  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLobjectMapMultiLineButton"})
		local prEH9  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "RDB2OWL.reGrammar.getRDB2OWLobjectMapMultiLineButton"})
		lQuery("ElemType[id='Class']/compartType[caption='DBExpr']/propertyRow"):link("propertyEventHandler", prEH6)
		lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):link("propertyEventHandler", prEH7)
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):link("propertyEventHandler", prEH8)
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):link("propertyEventHandler", prEH9)
	
	elseif useautocompletion=="0" then 
		lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLclassMap']"):delete()
		lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLdataMap']"):delete()
		lQuery("ElemType[id='Annotation']/compartType/subCompartType[id='Value']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLontologyDBExpr']"):delete()
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLobjectMap']"):delete()
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLobjectMap']"):delete()
	
		lQuery("ElemType[id='Class']/compartType[caption='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLclassMapMultiLineButton']"):delete()
		lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLdataMapMultiLineButton']"):delete()
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLobjectMapMultiLineButton']"):delete()
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[caption='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL.reGrammar.getRDB2OWLobjectMapMultiLineButton']"):delete()
	
	end
end

function anywhere (p)
  return lpeg.P{ p + 1 * lpeg.V(1) }
end