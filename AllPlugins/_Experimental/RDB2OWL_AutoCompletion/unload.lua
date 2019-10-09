require("lQuery")
local utils = require "plugin_mechanism.utils"

-- delete toolbar element
lQuery("ToolbarElementType[id=RDB2OWLDatabase]"):delete()
lQuery("ToolbarElementType[id=RDB2OWLAutoCompletion]"):delete()

-- refresh project diagram
configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))

	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL_AutoCompletion.reGrammar.getRDB2OWLclassMap']"):delete()
	lQuery("ElemType[id='Class']/compartType/subCompartType/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL_AutoCompletion.reGrammar.getRDB2OWLdataMap']"):delete()
	lQuery("ElemType[id='Annotation']/compartType/subCompartType[id='Value']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL_AutoCompletion.reGrammar.getRDB2OWLontologyDBExpr']"):delete()
	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL_AutoCompletion.reGrammar.getRDB2OWLobjectMap']"):delete()
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType/subCompartType[id='DBExpr']/propertyRow"):find("/propertyEventHandler[procedureName='RDB2OWL_AutoCompletion.reGrammar.getRDB2OWLobjectMap']"):delete()
	
	lQuery("Translet[extensionPoint = 'procDecompose'][procedureName = 'RDB2OWL_AutoCompletion.reGrammar.dbexprGrammar']"):delete()
	
	lQuery("RR#Database"):delete()
	lQuery("RR#DBFunction"):delete()
	lQuery("RR#Table"):delete()
	lQuery("RR#View"):delete()
	lQuery("RR#PKey"):delete()
	lQuery("RR#Column"):delete()
	lQuery("RR#FKey"):delete()
	lQuery("RR#SQLDataType"):delete()
	--lQuery("RR#DBRef"):delete()
	lQuery("RR#FunctionDef"):delete()
	lQuery("RR#Param"):delete()
	

return true
-- return false, error_string