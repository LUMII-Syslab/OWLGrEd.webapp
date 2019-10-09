require("lQuery")
local utils = require "plugin_mechanism.utils"

	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='EquivalentProperties']/subCompartType/subCompartType/subCompartType/propertyRow"):find("/propertyEventHandler[procedureName='Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression']"):delete()
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='SuperProperties']/subCompartType/subCompartType/subCompartType/propertyRow"):find("/propertyEventHandler[procedureName='Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression']"):delete()
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='DisjointProperties']/subCompartType/subCompartType/subCompartType/propertyRow"):find("/propertyEventHandler[procedureName='Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression']"):delete()

	
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='EquivalentProperties']/subCompartType/propertyRow"):find("/propertyEventHandler[procedureName='Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression']"):delete()
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='SuperProperties']/subCompartType/propertyRow"):find("/propertyEventHandler[procedureName='Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression']"):delete()
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='DisjointProperties']/subCompartType/propertyRow"):find("/propertyEventHandler[procedureName='Manchester_Syntax_AutoCompletion.ManchesterParserAutoComplition.getClassExpression']"):delete()

return true
-- return false, error_string