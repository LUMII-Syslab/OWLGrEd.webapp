module(..., package.seeall)

require("lua_tda")

function completeMetamodel()
	lQuery.model.add_class("D#MoveTextCursorCommand")
	lQuery.model.add_property("D#MoveTextCursorCommand", "row")
	lQuery.model.add_property("D#MoveTextCursorCommand", "horizontalPosition")
	lQuery.model.set_super_class("D#MoveTextCursorCommand", "D#Command")
	
	local prEH1  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression"})
	local prEH2  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression"})
	local prEH3  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression"})
	lQuery("ElemType[id='Class']/compartType[id='ASFictitiousEquivalentClasses']/subCompartType/subCompartType/propertyRow"):link("propertyEventHandler", prEH1)
	lQuery("ElemType[id='Class']/compartType[id='ASFictitiousSuperClasses']/subCompartType/subCompartType/propertyRow"):link("propertyEventHandler", prEH2)
	lQuery("ElemType[id='Class']/compartType[id='ASFictitiousDisjointClasses']/subCompartType/subCompartType/propertyRow"):link("propertyEventHandler", prEH3)

	local prEH4  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression"})
	local prEH5  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression"})
	local prEH6  = lQuery.create("PropertyEventHandler", {eventType = "onChange", procedureName = "Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression"})
	lQuery("ElemType[id='Class']/compartType[id='ASFictitiousEquivalentClasses']/subCompartType/subCompartType/subCompartType/subCompartType/propertyRow"):link("propertyEventHandler", prEH4)
	lQuery("ElemType[id='Class']/compartType[id='ASFictitiousDisjointClasses']/subCompartType/subCompartType/subCompartType/subCompartType/propertyRow"):link("propertyEventHandler", prEH5)
	lQuery("ElemType[id='Class']/compartType[id='ASFictitiousSuperClasses']/propertyRow"):link("propertyEventHandler", prEH6)
end
