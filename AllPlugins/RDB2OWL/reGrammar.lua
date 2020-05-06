module(..., package.seeall)

require("java")
require "lpeg"
require "re"
require "core"
specific = require "OWL_specific"
d = require("dialog_utilities") 
local errors = {}

function dbexprGrammar()
	local gr =  [[
		( {:Name: (( {:Name: [a-zA-Z0-9-_" ']* :} ){('')}? ('{' {:Namespace: [a-zA-Z0-9-_://#&.]* :} '}')?) -> {} :} )
{('')}? (':' {:Type: (( {:Type: [a-zA-Z0-9-_]* :} ){('')}? ('{' {:Namespace: [a-zA-Z0-9-_:#\\]* :} '}')?)  -> {} :} )?
{('')}? ('[' {:Multiplicity: [a-zA-Z0-9-_ ..*()]* :} ']')?
{('')}? (' {' {:IsFunctional: [func]* :} '}')?
{('')}? ('{' {:EquivalentProperties: (( {:ASFictitiousEquivalentProperties: (('=' {:EquivalentProperties: (( {:Expression: [a-zA-Z0-9-_]* :} )) -> {} :} )?-> {} (',' ('=' {:EquivalentProperties: (( {:Expression: [a-zA-Z0-9-_]* :} )) -> {} :} )?-> {})*  ) -> {} :})?)  -> {} :} '}')?
{('')}? ('{' {:SuperProperties: (( {:ASFictitiousSuperProperties: (('<' {:SuperProperties: (( {:Expression: [a-zA-Z0-9-_ ]* :} )) -> {} :} )? -> {} (',' ('<' {:SuperProperties: (( {:Expression: [a-zA-Z0-9-_ ]* :} )) -> {} :} )? -> {})*  ) -> {} :})?)  -> {} :} '}')?
{('')}? ('{' {:DisjointProperties: (( {:ASFictitiousDisjointProperties: (('<>' {:DisjointProperties: (( {:Expression: [a-zA-Z0-9-_]* :} )) -> {} :} )? -> {} (',' ('<>' {:DisjointProperties: (( {:Expression: [a-zA-Z0-9-_]* :} )) -> {} :} )? -> {})*  ) -> {} :})?)  -> {} :} '}')?
{('')}? ('\n' {:ASFictitiousAnnotation: (( {:Annotation: (( {:AnnotationType: [a-zA-Z0-9-_ ]* :} )
{('')}? ('{' {:Namespace: [^}]* :} '}')?
{('')}? ('(' {:ValueLanguage: (('"' {:Value: [^"]* :} '"')
{('')}? ('@' {:Language: [a-zA-Z0-9-_ ]* :} )?)  -> {} :} ')')?) -> {} :} )-> {} ('\n' ( {:Annotation: (( {:AnnotationType: [a-zA-Z0-9-_ ]* :} )
{('')}? ('{' {:Namespace: [^}]* :} '}')?
{('')}? ('(' {:ValueLanguage: (('"' {:Value: [^"]* :} '"')
{('')}? ('@' {:Language: [a-zA-Z0-9-_ ]* :} )?)  -> {} :} ')')?) -> {} :} )-> {})*  ) -> {} :} )?
{('')}? ('{' 
  {:DBExpr: 
	(
	  ( 
	    {:ASFictitiousDBExpr: 
		  (
		    ('{DB: ' {:DBExpr: ( {:DBExpr:(DBExpr_A) :} ) -> {} :} '}')? -> {} 
			(',' 
			  ('{DB: ' {:DBExpr: ( {:DBExpr:(DBExpr_A) :} ) -> {} :} '}')?-> {}
			)*  
		  ) -> {} 
		:}
	  )?
	) -> {} 
  :} 
'}')?
	DBExpr_A <- ({DBExpr_B ('{' DBExpr_A '}' DBExpr_A)* })
	DBExpr_B <- ({([^"{}"])*})
]]
	
	local pattern_name = "(DBExpr_A)"
	local clauses = [[
	
DBExpr_A <- ({DBExpr_B ('{' DBExpr_A '}' DBExpr_A)* })
DBExpr_B <- ({([^"{}"])*})
]]
	return pattern_name, clauses
end

function rdbtoowl(text)

	local grammar = re.compile([[
		--objectMap
		--dataMap
		--ontologyDBExpr
		--classMap
		
		gMain <- (space classMap !. %parse_fail)
		objectMap <- (tableExpr space PDecoration*)
		
		PDecoration <- ({%parse_Domain "?Domain" / %parse_Range "?Range"})
		
		
		dataMap <- (dataExpr space PDecoration*)
		
		
		
		ontologyDBExpr <- ((ontDBExprItem (%parse_semicolon ";" space ontDBExprItem)*)?)
		
		ontDBExprItem <- (funDefPlus / ({%parse_CMap "CMap"} %parse_roundBracketOpen "(" classMap %parse_roundBracketClose ")") / dbSpec)
		
		funDefPlus <- functionDef / aggrFDef
		dbSpec <- (%parse_DBRef "DBRef" %parse_roundBracketOpen "(" dbOptionSpec (space %parse_comma "," dbOptionSpec)* %parse_roundBracketClose ")")
		
		functionDef <- (fName %parse_roundBracketOpen "(" varList %parse_roundBracketClose ")" space %parse_equal "=" space functionBody)
		aggrFDef <- (aggrUserFName %parse_roundBracketOpen "(" aggrAgrList? %parse_roundBracketClose ")" space %parse_equal "=" space functionBody)
		dbOptionSpec <-((%parse_dbname 'dbname=' %parse_VarName VarName) / (%parse_alias 'alias=' %parse_VarName VarName) / (%parse_schema 'schema=' STRING) / 
						(%parse_public_table_prefix  'public_table_prefix=' STRING) /
						(%parse_jdbc_driver 'jdbc_driver=' STRING) / (%parse_connection_string 'connection_string=' STRING) / (%parse_aux 'aux=' INT) / 
						(%parse_default 'default=' INT) / (%parse_init_script 'init_script=' STRING) )
		
		varList <- (variable (space %parse_comma "," variable)*)
		functionBody <- dataExpr
		aggrAgrList <- (%parse_TExpr "@TExpr" space %parse_exclamation "!" space %parse_Col "@Col")
		ZEROONE <- %parse_0 "0" / %parse_1 "1"
		
		fDataExpr <- (tableExprPlain? %parse_point "." valueExprPlain (%parse_tick "^^" xsdRef)?) -> {}
		

		classMap <- (((defName space %parse_equal "=") space
					 tableExprExtUri space
					 CDecoration*) /  (
					 tableExprExtUri space
					 CDecoration*)
					)
		
		defName <- %parse_VarName VarName
		tableExpr <- (tRefList (%parse_semicolon ";" space tFilterExpr? (%parse_semicolon ";" space  colDefList)?)?)
		uriPattern <- (%parse_braceOpen "{" %parse_uri "uri" %parse_equal "=" %parse_roundBracketOpen "("  valueExpr (%parse_comma "," space valueExpr)* %parse_roundBracketClose ")" %parse_braceClose "}")
		CDecoration <- (%parse_Out "?Out" / %parse_In "?In" / %parse_NoMap "!NoMap" / %parse_SubClean "!SubClean" / %parse_question "?")
		
		tRefList <- (tRefItem (%parse_comma "," space tRefItem )*)
		tFilterExpr <- (filterOrExpr (space %parse_or "or" space filterOrExpr)*)
		colDefList <- ((colDef (%parse_comma "," space colDef )*)?)
		valueExpr <- (simpleExpr (space infixOp space simpleExpr)*)
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
		
		tRefItem <- ((( tNavigItem space tRefItemL?) / tRefItemL) space tExprTopSpec?)
		filterOrExpr <- (filterAndExpr (space {%parse_and "and"} space filterAndExpr)*)
		colDef <- (%parse_VarName VarName space %parse_equal "=" space valueExpr)
		simpleExpr <- functionCall / aggregateCall / valueExprPlain / space prefixOp space simpleExpr 
		infixOp <- %parse_plus "+" / %parse_minus "-" / %parse_mul "*" / %parse_division "/" / %parse_div "div" / %parse_mod "mod"
		
		tNavigItem <- (tNavigItemBase (space %parse_colon ":" space tNavigFilter)*)
		tRefItemL <- (nLinkExpr (space  tNavigItem space tRefItemL?)?)
		tExprTopSpec <- tTopFilter
		filterAndExpr <- ((%parse_not "not"? space filterItem))
		valueExprPlain <- sqlExpr / constantExpr / colRef / %parse_variable variable / (%parse_roundBracketOpen "(" tFilterExpr %parse_roundBracketClose ")")
		constantExpr <- INT / STRING
		functionCall <- (%parse_fName fName space %parse_roundBracketOpen "(" valueList %parse_roundBracketClose ")")
		prefixOp <- %parse_minus "-"
		aggregateCall <- (( aggrFName space %parse_roundBracketOpen "(" dataExpr orderList? %parse_roundBracketClose ")") / aggregateWrk)
		
		tNavigItemBase <- (tableExprPlain space aliasDef?)
		tNavigFilter <- (tFilterExpr / tTopFilter)
		nLinkExpr <- ((%parse_squareBracketOpen "[" valueList %parse_squareBracketClose "]")? space (%parse_doubleArrow "=>" / %parse_arrow  "->") space (%parse_squareBracketOpen "[" valueList %parse_squareBracketClose "]")?)
		tTopFilter <- (%parse_braceOpen "{" (%parse_first "first" / %parse_top "top" space INT space %parse_persent "persent"?) space orderList? %parse_braceClose "}")
		orderList <- (%parse_by "by" orderSpec (%parse_comma "," orderSpec)*)
		filterItem <- unarybinaryFilterItem / constantFilterItem / existsFilterItem
		INT <- %parse_number [0-9]+
		STRING <- ((%parse_apostrophe "'" %parse_string [^"'"]* %parse_apostrophe "'") / (%parse_quote '"' %parse_string [^'"']* %parse_quote '"'))
		colRef <-  compoundColRef / colName
		--variable <- (%parse_at "@" %parse_VarName VarName)
		variable <- ("@" %parse_VarName VarName)
		sqlExpr <- caseTwoOptions / caseManyOptions
		fName <- %parse_VarName VarName
		valueList <- (valueExpr (%parse_comma "," space valueExpr)*)
		aggrFName <- %parse_min "MIN" / %parse_max "MAX" / %parse_avg "AVG" / %parse_count "COUNT" / %parse_sum "SUM" / aggrUserFName
		dataExpr <- (tDataExpr / sDataExpr) 
		tDataExpr <- (%parse_squareBracketOpen "[" tableExprExtUri %parse_squareBracketPoint "]." simpleExpr (%parse_tick "^^" xsdRef)?)
		tableExprExtUri <- (tableExpr uriPattern?)
		sDataExpr <- (valueExpr (%parse_tick "^^" xsdRef)?) 
		xDataExpr <- (tableExpr %parse_exclamation "!" valueExpr)
		aggregateWrk <- (%parse_aggregate "@aggregate"  %parse_roundBracketOpen "(" xDataExpr %parse_comma "," valueExpr %parse_comma "," space valueExpr ("order" orderList)? %parse_roundBracketClose ")")
		
		tableExprPlain <- (simpleTableExpr / (%parse_roundBracketOpen "(" tableExprExt %parse_roundBracketClose ")"))
		aliasDef <- ClassMapRef / %parse_VarName VarName
		orderSpec <- (valueExpr space (%parse_asc "asc" / %parse_desc "desc")? space)
		unarybinaryFilterItem <- (valueExpr space((%parse_is "is" space %parse_not "not"? space %parse_null "null") / (binaryFilterOp space valueExpr ) / %parse_in2 "in" space %parse_roundBracketOpen "(" valueList %parse_roundBracketClose ")" / %parse_between "between" space simpleExpr space %parse_and "and" space simpleExpr ))
		constantFilterItem <- %parse_true "true" / %parse_false "false"
		existsFilterItem <- (%parse_exists "exists" space %parse_roundBracketOpen "(" tableExpr %parse_roundBracketClose ")")
		colName <- %parse_colName %parse_VarName VarName
		compoundColRef <- (tablePlusRefExpr %parse_point "." (colName / (%parse_roundBracketOpen "(" colRef %parse_roundBracketClose ")")))
		caseTwoOptions <- (%parse_case "case" space %parse_when "when" space tFilterExpr space %parse_then "then" space valueExpr space (%parse_else "else" space valueExpr space)? %parse_end "end")
		caseManyOptions <- (%parse_case "case" space valueExpr space (%parse_when "when" space valueExpr space %parse_then "then" space valueExpr)+ space (%parse_else "else" space valueExpr space)? %parse_end "end")
		aggrUserFName <- (%parse_aggrUserFName "@" %parse_VarName VarName)
		xsdRef <- ((XSD_TYPE_PREFIX)? %parse_VarName VarName)
		
		simpleTableExpr <- ClassMapRef / namedRef / tableUseExpr
		tableExprExt <- (tableExpr space (uriPattern / keyPattern)?)
		binaryFilterOp <- %parse_like "like" / %parse_lessEqual "<=" / %parse_moreEqual ">=" / %parse_equal2 "<>" / %parse_equal "=" / %parse_less "<" / %parse_more ">"
		tablePlusRefExpr <- ClassMapRef / namedRef / tableRefExpr
		tableRefExpr <- ((%parse_dbAliasRefExpr dbAlias %parse_doubleColon "::")? %parse_TableNameRefExpr VarName)
		XSD_TYPE_PREFIX <- %parse_xsd "xsd:"
		--ClassMapRef <- %parse_s "<s>" / %parse_t "<t>" / %parse_b "<b>"
		ClassMapRef <- "<s>" / "<t>" / %parse_b "<b>"
		
		namedRef <- (%parse_twoSquareBracketOpen "[" "[" %parse_namedRef defName %parse_twoSquareBracketClose "]" "]")
		tableUseExpr <- ((%parse_dbAlias dbAlias %parse_doubleColon "::")? %parse_TableName %parse_VarName VarName)
		keyPattern <- (%parse_braceOpen "{" %parse_key "key" %parse_equal "=" %parse_roundBracketOpen "("  valueExpr (%parse_comma "," valueExpr)* %parse_roundBracketClose ")" %parse_braceClose "}")
		
		dbAlias <- %parse_VarName VarName
		space <- %parse_space (" " / %nl)*
	]]
	, {  
		parse_fail = function (subject, current_pos, captures) 
			return false 
		end,
		parse_variable = function (message, current_pos) parse_variable_function (message, current_pos) return current_pos end,
		parse_fName = function (message, current_pos) parse_fName_function (message, current_pos) return current_pos end,
		parse_aggrUserFName = function (message, current_pos) parse_aggrUserFName_function (message, current_pos) return current_pos end,
		parse_namedRef = function (message, current_pos) parse_namedRef_function(message, current_pos) return current_pos end,
		parse_TableName = function (message, current_pos) parse_TableName_function(message, current_pos) return current_pos end,
		parse_TableNameRefExpr = function (message, current_pos) parse_TableNameRefExpr_function(message, current_pos) return current_pos end,
		parse_dbAlias = function (message, current_pos) parse_dbAlias_function (message, current_pos) return current_pos end,
		parse_dbAliasRefExpr = function (message, current_pos) parse_dbAliasRefExpr_function (message, current_pos) return current_pos end,
		parse_colName = function (message, current_pos) parse_colName_function (message, current_pos) return current_pos end,
		parse_point = function (message, current_pos) add_error_message(errors, current_pos, ".", 30) return current_pos end,
		parse_Domain  = function (message, current_pos) add_error_message(errors, current_pos, "?Domain", 90) return current_pos end,
		parse_by = function (message, current_pos) add_error_message(errors, current_pos, "by", 60) return current_pos end,
		parse_Range  = function (message, current_pos) add_error_message(errors, current_pos, "?Range", 90) return current_pos end,
		parse_order = function (message, current_pos) add_error_message(errors, current_pos, "order", 90) return current_pos end,
		parse_semicolon  = function (message, current_pos) add_error_message(errors, current_pos, ";", 30) return current_pos end,
		parse_CMap  = function (message, current_pos) add_error_message(errors, current_pos, "CMap", 90) return current_pos end,
		parse_roundBracketOpen  = function (message, current_pos) add_error_message(errors, current_pos, "(", 30) return current_pos end,
		parse_roundBracketClose  = function (message, current_pos) add_error_message(errors, current_pos, ")", 30) return current_pos end,
		parse_DBRef  = function (message, current_pos) add_error_message(errors, current_pos, "DBRef", 90) return current_pos end,
		parse_comma  = function (message, current_pos) add_error_message(errors, current_pos, ",", 30) return current_pos end,
		parse_equal  = function (message, current_pos) add_error_message(errors, current_pos, "=", 50) return current_pos end,
		parse_dbname  = function (message, current_pos) add_error_message(errors, current_pos, 'dbname=', 90) return current_pos end,
		parse_VarName = function (message, current_pos) add_error_message(errors, current_pos, "", 100) return current_pos end,
		parse_alias  = function (message, current_pos) add_error_message(errors, current_pos, 'alias=', 90) return current_pos end,
		parse_schema  = function (message, current_pos) add_error_message(errors, current_pos, 'schema=', 90) return current_pos end,
		parse_public_table_prefix   = function (message, current_pos) add_error_message(errors, current_pos, 'public_table_prefix=', 90) return current_pos end,
		parse_jdbc_driver  = function (message, current_pos) add_error_message(errors, current_pos, 'jdbc_driver=', 90) return current_pos end,
		parse_connection_string  = function (message, current_pos) add_error_message(errors, current_pos, 'connection_string=', 90) return current_pos end,
		parse_aux  = function (message, current_pos) add_error_message(errors, current_pos, 'aux=', 90) return current_pos end,
		parse_default  = function (message, current_pos) add_error_message(errors, current_pos, 'default=', 90) return current_pos end,
		parse_init_script  = function (message, current_pos) add_error_message(errors, current_pos, 'init_script=', 90) return current_pos end,
		parse_TExpr  = function (message, current_pos) add_error_message(errors, current_pos, "@TExpr", 70) return current_pos end,
		parse_exclamation  = function (message, current_pos) add_error_message(errors, current_pos, "!", 70) return current_pos end,
		parse_Col  = function (message, current_pos) add_error_message(errors, current_pos, "@Col", 70) return current_pos end,
		parse_0  = function (message, current_pos) add_error_message(errors, current_pos, "0", 30) return current_pos end,
		parse_1  = function (message, current_pos) add_error_message(errors, current_pos, "1", 30) return current_pos end,
		parse_tick  = function (message, current_pos) add_error_message(errors, current_pos, "^^", 30) return current_pos end,
		parse_braceOpen  = function (message, current_pos) add_error_message(errors, current_pos, "{", 30) return current_pos end,
		parse_uri  = function (message, current_pos) add_error_message(errors, current_pos, "uri", 30) return current_pos end,
		parse_braceClose  = function (message, current_pos) add_error_message(errors, current_pos, "}", 30) return current_pos end,
		parse_Out  = function (message, current_pos) add_error_message(errors, current_pos, "?Out", 100) return current_pos end,
		parse_In = function (message, current_pos) add_error_message(errors, current_pos, "?In", 100) return current_pos end,
		parse_NoMap  = function (message, current_pos) add_error_message(errors, current_pos, "!NoMap", 100) return current_pos end,
		parse_SubClean  = function (message, current_pos) add_error_message(errors, current_pos, "!SubClean", 100) return current_pos end,
		parse_question  = function (message, current_pos) add_error_message(errors, current_pos, "?", 100) return current_pos end,
		parse_or  = function (message, current_pos) add_error_message(errors, current_pos, "or", 50) return current_pos end,
		parse_and  = function (message, current_pos) add_error_message(errors, current_pos, "and", 50) return current_pos end,
		parse_plus  = function (message, current_pos) add_error_message(errors, current_pos, "+", 50) return current_pos end,
		parse_minus = function (message, current_pos) add_error_message(errors, current_pos, "-", 50) return current_pos end,
		parse_mul  = function (message, current_pos) add_error_message(errors, current_pos, "*", 50) return current_pos end,
		parse_division  = function (message, current_pos) add_error_message(errors, current_pos, "/", 50) return current_pos end,
		parse_div  = function (message, current_pos) add_error_message(errors, current_pos, "div", 50) return current_pos end,
		parse_mod  = function (message, current_pos) add_error_message(errors, current_pos, "mod", 50) return current_pos end,
		parse_colon  = function (message, current_pos) add_error_message(errors, current_pos, ":", 50) return current_pos end,
		parse_not  = function (message, current_pos) add_error_message(errors, current_pos, "not", 30) return current_pos end,
		parse_gridOpen  = function (message, current_pos) add_error_message(errors, current_pos, "(.", 30) return current_pos end,
		parse_gridClose  = function (message, current_pos) add_error_message(errors, current_pos, ".)", 30) return current_pos end,
		parse_squareBracketOpen  = function (message, current_pos) add_error_message(errors, current_pos, "[", 30) return current_pos end,
		parse_squareBracketClose   = function (message, current_pos) add_error_message(errors, current_pos, "]", 30) return current_pos end,
		parse_arrow   = function (message, current_pos) add_error_message(errors, current_pos, "->", 30) return current_pos end,
		parse_doubleArrow   = function (message, current_pos) add_error_message(errors, current_pos, "=>", 30) return current_pos end,
		parse_first   = function (message, current_pos) add_error_message(errors, current_pos, "first", 30) return current_pos end,
		parse_top   = function (message, current_pos) add_error_message(errors, current_pos, "top", 30) return current_pos end,
		parse_persent   = function (message, current_pos) add_error_message(errors, current_pos, "persent", 30) return current_pos end,
		parse_number  = function (message, current_pos) add_error_message(errors, current_pos, "", 50) return current_pos end,
		parse_apostrophe   = function (message, current_pos) add_error_message(errors, current_pos, "'", 50) return current_pos end,
		parse_string  = function (message, current_pos) add_error_message(errors, current_pos, "", 100) return current_pos end,
		parse_quote   = function (message, current_pos) add_error_message(errors, current_pos, '"', 50) return current_pos end,
		parse_at   = function (message, current_pos) add_error_message(errors, current_pos, "@", 70) return current_pos end,
		parse_min   = function (message, current_pos) add_error_message(errors, current_pos, "MIN", 70) return current_pos end,
		parse_max   = function (message, current_pos) add_error_message(errors, current_pos, "MAX", 70) return current_pos end,
		parse_avg   = function (message, current_pos) add_error_message(errors, current_pos, "AVG", 70) return current_pos end,
		parse_count   = function (message, current_pos) add_error_message(errors, current_pos, "COUNT", 70) return current_pos end,
		parse_sum   = function (message, current_pos) add_error_message(errors, current_pos, "SUM", 70) return current_pos end,
		parse_squareBracketPoint   = function (message, current_pos) add_error_message(errors, current_pos, "].", 30) return current_pos end,
		parse_aggregate   = function (message, current_pos) add_error_message(errors, current_pos, "@aggregate", 70) return current_pos end,
		parse_exclamation   = function (message, current_pos) add_error_message(errors, current_pos, "!", 60) return current_pos end,
		parse_asc   = function (message, current_pos) add_error_message(errors, current_pos, "asc", 60) return current_pos end,
		parse_desc   = function (message, current_pos) add_error_message(errors, current_pos, "desc", 60) return current_pos end,
		parse_is   = function (message, current_pos) add_error_message(errors, current_pos, "is", 60) return current_pos end,
		parse_null   = function (message, current_pos) add_error_message(errors, current_pos, "null", 60) return current_pos end,
		parse_between   = function (message, current_pos) add_error_message(errors, current_pos, "between", 60) return current_pos end,
		parse_true   = function (message, current_pos) add_error_message(errors, current_pos, "true", 60) return current_pos end,
		parse_false   = function (message, current_pos) add_error_message(errors, current_pos, "false", 60) return current_pos end,
		parse_exists   = function (message, current_pos) add_error_message(errors, current_pos, "exists", 60) return current_pos end,
		parse_case   = function (message, current_pos) add_error_message(errors, current_pos, "case", 60) return current_pos end,
		parse_when   = function (message, current_pos) add_error_message(errors, current_pos, "when", 60) return current_pos end,
		parse_then   = function (message, current_pos) add_error_message(errors, current_pos, "then", 60) return current_pos end,
		parse_else   = function (message, current_pos) add_error_message(errors, current_pos, "else", 60) return current_pos end,
		parse_end   = function (message, current_pos) add_error_message(errors, current_pos, "end", 60) return current_pos end,
		parse_less   = function (message, current_pos) add_error_message(errors, current_pos, "<", 60) return current_pos end,
		parse_more   = function (message, current_pos) add_error_message(errors, current_pos, ">", 60) return current_pos end,
		parse_lessEqual   = function (message, current_pos) add_error_message(errors, current_pos, "<=", 60) return current_pos end,
		parse_moreEqual   = function (message, current_pos) add_error_message(errors, current_pos, ">=", 60) return current_pos end,
		parse_equal2   = function (message, current_pos) add_error_message(errors, current_pos, "<>", 60) return current_pos end,
		parse_like   = function (message, current_pos) add_error_message(errors, current_pos, "like", 60) return current_pos end,
		parse_in2   = function (message, current_pos) add_error_message(errors, current_pos, "in", 60) return current_pos end,
		parse_xsd   = function (message, current_pos) add_error_message(errors, current_pos, "xsd:", 30) return current_pos end,	  
		parse_s  = function (message, current_pos) add_error_message(errors, current_pos, "<s>", 23) return current_pos end,
		parse_t  = function (message, current_pos) add_error_message(errors, current_pos, "<t>", 23) return current_pos end,
		parse_b  = function (message, current_pos) parse_b_function (message, current_pos) return current_pos end,
		parse_twoSquareBracketOpen   = function (message, current_pos) add_error_message(errors, current_pos, "[[", 30) return current_pos end,
		parse_twoSquareBracketClose  = function (message, current_pos) add_error_message(errors, current_pos, "]]", 30) return current_pos end,
		parse_doubleColon   = function (message, current_pos) add_error_message(errors, current_pos, "::", 30) return current_pos end,
		parse_key   = function (message, current_pos) add_error_message(errors, current_pos, "key", 30) return current_pos end,
		parse_space   = function (message, current_pos) add_error_message(errors, current_pos, " ", 100) return current_pos end,
	  }
	)
	local res = match_err(grammar, text)
end

function parse_variable_function (message, current_pos)
	lQuery("RR#FunctionDef[isAggregate!='true']"):each(function(obj)
		if string.find(message, obj:attr("fName"))~=nil then
			obj:find("/param"):each(function(param)
				add_error_message(errors, current_pos, "@" .. param:attr("pName"), 40)
			end)
		end
	end)
end

function parse_fName_function (message, current_pos) 
	lQuery("RR#FunctionDef[isAggregate!='true']"):each(function(obj)
		add_error_message(errors, current_pos, obj:attr("fName"), 40)
	end)
end

function parse_aggrUserFName_function (message, current_pos) 
	lQuery("RR#FunctionDef[isAggregate='true']"):each(function(obj)
		add_error_message(errors, current_pos, "@" .. obj:attr("fName"), 70)
	end)
end

function parse_namedRef_function(message, current_pos)
	local source
	source = utilities.current_diagram():find("/graphDiagramType/elemType[caption = 'Class']/compartType[caption='Name']/compartment")--atlasa visus klases vardus
	local current_diagram_id = utilities.current_diagram():id()--atrod aktivas diagramas id
	if source ~= nil then
		source = source:filter(function(compartment)--atstai tikai tas klases, kas ir aktivaa diagrammaa
		  return lQuery(compartment):find("/element/graphDiagram"):id() == current_diagram_id
		end)

		source:each(function(all_instance)
			local name = all_instance:attr("value")
			add_error_message(errors, current_pos, name, 20)
		end)
		
		--pievienot visus saisinajumus no citiem ClassMap
		source = utilities.current_diagram():find("/element:has(/elemType[id='Class'])/compartment/subCompartment:has(/compartType[id='DBExpr'])")
		source:each(function(dbexpr)
			local grammar = re.compile([[
				gMain <- ({VarName} space "=" space VarName)
				VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
				space <- (" " / %nl)*
			]])
			local place, defName = re.find(dbexpr:attr("value"), grammar)
			if defName~=nil then add_error_message(errors, current_pos, defName, 20) end
		end)
	end
	
	source = utilities.current_diagram():find("/element:has(/elemType[caption='Annotation'])")
	if source ~= nil and source:find("/compartment:has(/compartType[id='AnnotationType'])"):attr("value") == "DBExpr" then
	    source = source:find("/compartment/subCompartment:has(/compartType[id='Value'])")
	    source:each(function(val)
			local value = val:attr("value")
			local grammar = rdbtoowlDatabaseCMap()
			local data = re.match(value, grammar)
			for i, k in pairs(data) do
				add_error_message(errors, current_pos, k, 20)
			end
	    end)
	end
end

function parse_TableName_function(message, current_pos) 
	local source
	if string.sub(message, current_pos-2, current_pos-1)=="::" then 
		local grammar = re.compile([[
			gMain <- ({VarName} "::" !.) / ({VarName} "::" VarName !.)
			VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
		]])
		local place, defName = re.find(message, grammar)
		if defName~=nil then 
			-- local dbn = lQuery("RR#DBRef[dbAlias = '" .. defName .. "']"):attr("dbName")
			-- source = lQuery("RR#Table:has(/database[dbName='" .. dbn .. "'])")
			
			--source = lQuery("RR#Table:has(/database[dbAlias='" .. defName .. "'])")
			source = lQuery("RR#Table:has(/database[dbName='" .. defName .. "'])")
		end
	else
		local grammar = re.compile([[
			gMain <- (VarName "::" VarName)
			VarName <- {([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*}
		]])
		local place, defName = re.find(message, grammar)
		if defName==nil then
			--ja nav noradidt dbAlias, tad nemt tabulas, kas piesaistitas datubazes ar noradi uz RR#DBRef ar isDefaultDB='true'
			--lQuery("RR#DBRef[isDefaultDB='true']"):each(function(dbRef)
			lQuery("RR#Database[isDefaultDB=1]"):each(function(dbRef)
				if source == nil then
					source = lQuery("RR#Table:has(/database[dbName='" .. dbRef:attr("dbName") .. "'])")
				else
					source = source:add(lQuery("RR#Table:has(/database[dbName='" .. dbRef:attr("dbName") .. "'])"))
				end
			end)
			if lQuery("RR#Database"):size() == 1 then
				source = lQuery("RR#Table:has(/database[dbName='" .. lQuery("RR#Database"):attr("dbName") .. "'])")
			end
		end
	end
	if source~=nil and source:is_not_empty() then
		source:each(function(all_instance)
			local name = all_instance:attr("tName")
			add_error_message(errors, current_pos, name, 21)
		end)
	else add_error_message(errors, current_pos, "", 100)
	end
end

function parse_TableNameRefExpr_function(message, current_pos)
	local grammar = table_names_grammar()
	local place, tName = re.find(message, grammar)
	local alias
	if tName~=nil then
		for i, k in pairs(tName) do
			local grammar2 = re.compile([[
					gMain <- ((VarName "=")?(({VarName} "::" VarName)))
					VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
				]])
			local place, dbAlias = re.find(k, grammar2)
			if dbAlias~=nil then alias = dbAlias end
		end
		for i, k in pairs(tName) do
			local grammar2 = re.compile([[
					gMain <- ((VarName "=")?((VarName "::" {VarName}) / {VarName}))
					VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
				]])
			local place, tableName = re.find(k, grammar2)
			if alias==nil then add_error_message(errors, current_pos, tableName, 21) 
			else
				local len = string.len(message)
				if string.sub(message, len-1) == "::" and lQuery("RR#Table[tName='" .. tableName .. "']"):is_not_empty() then add_error_message(errors, current_pos, tableName, 21)
				else add_error_message(errors, current_pos, "", 100) end
			end
		end
	end
end

function parse_dbAliasRefExpr_function (message, current_pos) 
	local grammar = re.compile([[
		gMain <- ({VarName} "::" VarName)
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
	]])
	local place, defName = re.find(message, grammar)
	if defName~=nil then add_error_message(errors, current_pos, defName, 22) end
end

function parse_dbAlias_function (message, current_pos) 
	local grammar = re.compile([[
		gMain <- ({VarName} "::" VarName)
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
	]])
	local place, defName = re.find(message, grammar)
	if defName~=nil then add_error_message(errors, current_pos, defName, 22)
	else
		local source
		--source = lQuery("RR#DBRef")
		source = lQuery("RR#Database")
		source:each(function(all_instance)
			--local name = all_instance:attr("dbAlias")!!!!!!!
			local name = all_instance:attr("dbName")
			add_error_message(errors, current_pos, name, 22)
		end)
	end
end

function table_names_grammar()
	return re.compile([[
		classMap <- (((defName space "=") space tableExprExtUri space CDecoration*) /  (tableExprExtUri space CDecoration*))
		tableExpr <- tRefList (";" space tFilterExpr? (";" space colDefList)?)?
		uriPattern <- "{" "uri" "=" "(" valueExpr ("," space valueExpr)* ")" "}"
		CDecoration <- "?Out" / "?In" / "!NoMap" / "!SubClean" / "?"
		
		tRefList <- (tRefItem ("," space tRefItem )*)->{}
		tFilterExpr <- filterOrExpr (space "or" space filterOrExpr)*
		colDefList <- (colDef ("," space colDef )*)?
		valueExpr <- simpleExpr (space infixOp space simpleExpr)*
		VarName <- {([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*}
		VarName2 <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
		
		tRefItem <- (((tNavigItem space tRefItemL?) / tRefItemL ) space  tExprTopSpec?)
		filterOrExpr <- (filterAndExpr (space "and" space filterAndExpr)*)
		colDef <- (VarName space "=" space valueExpr)
		simpleExpr <- functionCall / aggregateCall / valueExprPlain / space prefixOp space simpleExpr 
		infixOp <- "+" / "-" / "*" / "/" / "div" / "mod"
		
		tNavigItem <- (tNavigItemBase  (space ":" space tNavigFilter)*)
		tRefItemL <- (nLinkExpr (space tNavigItem space tRefItemL?)?)
		tExprTopSpec <- tTopFilter
		filterAndExpr <- (("not"? space filterItem))
		valueExprPlain <- sqlExpr / constantExpr / colRef / variable / ("(" tFilterExpr ")")
		constantExpr <- INT / STRING
		functionCall <- (fName space "(" valueList ")")
		prefixOp <- "-"
		aggregateCall <- (( aggrFName space "(" dataExpr orderList? ")") / aggregateWrk)
		
		tNavigItemBase <- (tableExprPlain space aliasDef?)
		tNavigFilter <- (tFilterExpr / tTopFilter)
		nLinkExpr <- (("[" valueList "]")? space ("=>" / "->") space ("[" valueList "]")?)
		tTopFilter <- ("{" ("first" / "top" space INT space "persent"?) space orderList? "}")
		orderList <- ("by" orderSpec ("," orderSpec)*)
		filterItem <- unarybinaryFilterItem / constantFilterItem / existsFilterItem
		INT <- [0-9]+
		STRING <- (("'" [^"'"]* "'") / ('"' [^'"']* '"'))
		colRef <-  compoundColRef / colName
		variable <- ("@" VarName)
		sqlExpr <- caseTwoOptions / caseManyOptions
		fName <-  VarName
		valueList <- (valueExpr ("," space valueExpr)*)
		aggrFName <- "MIN" / "MAX" / "AVG" / "COUNT" / "SUM" / aggrUserFName
		dataExpr <- (tDataExpr / sDataExpr)
		tDataExpr <- ("[" tableExprExtUri "]." simpleExpr ("^^" xsdRef)?)
		tableExprExtUri <- (tableExpr uriPattern?)
		
		sDataExpr <- (valueExpr( "^^" xsdRef)?)	
		xDataExpr <- (tableExpr "!" valueExpr)
		aggregateWrk <- ("@aggregate"  "(" xDataExpr "," valueExpr "," space valueExpr ("order" orderList)? ")")
		
		tableExprPlain <- (simpleTableExpr / ("(" tableExprExt ")"))
		aliasDef <- ClassMapRef / VarName
		orderSpec <- (valueExpr space ("asc" / "desc")? space)
		unarybinaryFilterItem <- (valueExpr space(("is" space "not"? space "null") / (binaryFilterOp space valueExpr ) / "in" space "(" valueList ")" / "between" space simpleExpr space "and" space simpleExpr ))
		constantFilterItem <- "true" / "false"
		existsFilterItem <- ("exists" space "(" tableExpr ")")
		colName <- VarName
		compoundColRef <- (tablePlusRefExpr "." (colName / ("(" colRef ")")))
		caseTwoOptions <- ("case" space "when" space tFilterExpr space "then" space valueExpr space ("else" space valueExpr space)? "end")
		caseManyOptions <- ("case" space valueExpr space ("when" space valueExpr space "then" space valueExpr)+ space ("else" space valueExpr space)? "end")
		aggrUserFName <- ("@" VarName)
		xsdRef <- ((XSD_TYPE_PREFIX)? VarName)
		
		simpleTableExpr <- ClassMapRef / namedRef / tableUseExpr
		tableExprExt <- (tableExpr space (uriPattern / keyPattern)?) 
		binaryFilterOp <- "like" / "in" / "<=" / ">=" / "<>" / "=" / "<" / ">"
		tablePlusRefExpr <- ClassMapRef / namedRef / tableRefExpr
		tableRefExpr <- ((dbAlias "::")? VarName)
		XSD_TYPE_PREFIX <- "xsd:"
		ClassMapRef <- "<s>" / "<t>" / "<b>"
		
		namedRef <- ("[" "[" defName "]" "]")
		tableUseExpr <- {(dbAlias "::")? VarName}
		keyPattern <- ("{" "key" "=" "(" valueExpr ("," valueExpr)* ")" "}")
		HEX_DIGIT <- [0-9] / [A-F] / [a-f]
		defName <- VarName2
		dbAlias <- VarName
		space <- (" " / %nl)*
				]])
end

function parse_colNameDataMap_function(message, current_pos)
	--atrast klasi kurai pieder dotais atributs
	--atrast sis klases visas DBExpr izteiksmes
	--atrast visas tabulas
	
--	local class = utilities.current_diagram():find("/element:has(/elemType[id='Class'])"):first()--NOMAINIT
	local class = utilities.active_elements()
	local classDBExpr = class:find("/compartment:has(/compartType[id='ASFictitiousDBExpr'])/subCompartment")
	classDBExpr:each(function(obj)
		parse_colName_function (obj:attr("value"), current_pos) 
	end)
end

function parse_colNameObjectMap_function(message, current_pos)
	--atrast klasi kurai pieder dotais atributs
	--atrast sis klases visas DBExpr izteiksmes
	--atrast visas tabulas
	local grammar = re.compile([[
		gMain <- ({VarName} "[" !.)
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
	]])
	local place, tName = re.find(message, grammar)
	if tName~=nil then
		source = lQuery("RR#Column:has(/table[tName='" .. tName .. "'])")
		source:each(function(all_instance)
			local name = all_instance:attr("colName")
			if name~=nil then add_error_message(errors, current_pos, name, 20) end
		end)
	else
		local grammarDefName = re.compile([[
			gMain <- ("[" "[" {VarName} "]" "]")
			VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
			space <- (" " / %nl)*
		]])
		local placeDefName, defName = re.find(message, grammarDefName)
		local source
		local tableTable = {}
		if defName~=nil then
			local grammarDefName = re.compile([[
				gMain <- ("("? space "[" "[" {VarName} "]" "]" space ("<s>"/"<t>"/VarName)? ")"? space "[" !.)
				VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
				space <- (" " / %nl)*
			]])
			local placeDefName, defName = re.find(message, grammarDefName)
			
			if string.sub(message, string.len(message)) == "." then 
				local grammarAliasDef = re.compile([[
						tRefList <- (tNavigItemBase ("," space tNavigItemBase )*)->{}
						tNavigItemBase <- (namedRef space aliasDef?)->{}
						namedRef <- ("[" "[" {VarName}  "]" "]")
						ClassMapRef <- "<s>" / "<t>" / "<b>"
						aliasDef <- {ClassMapRef / VarName}
						VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
						space <- (" " / %nl)*
					]])
				local placeAliasDef, aliasDef = re.find(message, grammarAliasDef)
				if aliasDef~=nil then 
					local alias = string.sub(message, string.len(message)-1, string.len(message)-1)
					if alias==">" then alias = string.sub(message, string.len(message)-3, string.len(message)-1) end
					local tableN
					for i, k in pairs(aliasDef) do
						if k[2]==alias then tableN = k[1] end
					end
					source = utilities.current_diagram():find("/element:has(/elemType[id='Class'])")
					source = source:filter(function(elem)--atstai tikai tas klases, kas ir aktivaa diagrammaa
						return elem:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") == tableN
					end)
					source = source:find("/compartment/subCompartment:has(/compartType[id='DBExpr'])")
				end
			else
				local source2 = utilities.current_diagram():find("/element:has(/elemType[id='Class'])")
				source2 = source2:filter(function(elem)--atstai tikai tas klases, kas ir aktivaa diagrammaa
					return elem:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") == defName
				end)
				source2 = source2:find("/compartment/subCompartment:has(/compartType[id='DBExpr'])")
				if source==nil then source = source2
				else source = source:add(source2) end
			end
			source:each(function(dbexpr)
				local grammar = table_names_grammar()
				local tName = re.match(dbexpr:attr("value"), grammar)
				if tName~=nil then 
					if type(tName) ~= "table" then
						local grammar2 = re.compile([[
							gMain <- (VarName "="((VarName "::" {VarName}) / {VarName}))
							VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
						]])
						place, tableName = re.find(dbexpr:attr("value"), grammar2)
						if tableName~=nil then 
							if tableName~=nil then 
								table.insert(tableTable, tableName)
							end
						end
					else
						for i, k in pairs(tName) do
							local grammar2 = re.compile([[
								gMain <- ((VarName "=")? (VarName "::" {VarName}!.) / {VarName}!.)
								VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
							]])
							place, tableName = re.find(k, grammar2)
							if tableName~=nil then 
								table.insert(tableTable, tableName)
							end
						end
					end
				end
			end)

			if #tableTable~=0 then 
				for i, k in pairs(tableTable) do
					if source == nil then
						source = lQuery("RR#Column:has(/table[tName='" .. k .. "'])")
					else
						source = source:add(lQuery("RR#Column:has(/table[tName='" .. k .. "'])"))
					end
				end
			--ja tabulas ar nosaukumu tableTable nav, tad jamekle atbilstiba citos ClasMap-os
			else 
				local defNameTable = {}
				source = utilities.current_diagram():find("/element:has(/elemType[id='Class'])/compartment/subCompartment:has(/compartType[id='DBExpr'])")
				source:each(function(dbexpr)
					local grammar = re.compile([[
						gMain <- ({VarName} space "=" space {VarName})
						VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
						space <- (" " / %nl)*
					]])

					local place, dName, tableName = re.find(dbexpr:attr("value"), grammar)
					if dName~=nil then defNameTable[dName]=tableName end
				end)
				if defNameTable[defName]~=nil then
					source = lQuery("RR#Column:has(/table[tName='" .. defNameTable[defName] .. "'])")
				end
			end
			
			source:each(function(all_instance)
				local name = all_instance:attr("colName")
				if name~=nil then add_error_message(errors, current_pos, name, 20) end
			end)
		else
			local grammar = re.compile([[
				gMain <- ({"->" / "=>"})
			]])
			local ev = lQuery("D#Event")
			local component = ev:find("/source")
			local compart = component:find("/compartment")
			local role = compart:find("/parentCompartment/parentCompartment")
			if role:find("/compartType"):attr("id")~="Role" and role:find("/compartType"):attr("id")~="InvRole" then
				role = compart:find("/parentCompartment/parentCompartment/parentCompartment/parentCompartment")
			end
			local place, tName = re.find(message, grammar)
			if tName~=nil then--RANGE
				local element
				if get_tab_name():attr("caption")=="Direct" or role:find("/compartType"):attr("id")=="Role" then
					element = utilities.active_elements():find("/end")
				else
					element = utilities.active_elements():find("/start")
				end
				--local element = utilities.active_elements():find("/end")
				--local class = utilities.current_diagram():find("/element:has(/elemType[id='Class'])"):last()--NOMAINIT
				local classDBExpr = element:find("/compartment:has(/compartType[id='ASFictitiousDBExpr'])/subCompartment")
				
				classDBExpr:each(function(obj)
					parse_colName_function (obj:attr("value"), current_pos) 
				end)
			else--DOMAIN
				local element
				if get_tab_name():attr("caption")=="Direct" or role:find("/compartType"):attr("id")=="Role" then
					element = utilities.active_elements():find("/start")
				else
					element = utilities.active_elements():find("/end")
				end
				--local class = utilities.current_diagram():find("/element:has(/elemType[id='Class'])"):first()--NOMAINIT
				local classDBExpr = element:find("/compartment:has(/compartType[id='ASFictitiousDBExpr'])/subCompartment")
				classDBExpr:each(function(obj)
					parse_colName_function (obj:attr("value"), current_pos) 
				end)
			end
		end	
	end
end


function parse_colName_function (message, current_pos) 
	local grammar = table_names_grammar()
			
	local grammarDefName = re.compile([[
		gMain <- ("[" "[" {VarName} "]" "]")
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
	]])
	local place, tName = re.find(message, grammar)
	local placeDefName, defName = re.find(message, grammarDefName)
	local source
	local tableTable = {}
	if defName~=nil then
		if string.sub(message, string.len(message)) == "." then 
			local grammarAliasDef = re.compile([[
					tRefList <- (tNavigItemBase ("," space tNavigItemBase )*)->{}
					tNavigItemBase <- (namedRef space aliasDef?)->{}
					namedRef <- ("[" "[" {VarName}  "]" "]")
					ClassMapRef <- "<s>" / "<t>" / "<b>"
					aliasDef <- {ClassMapRef / VarName}
					VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
					space <- (" " / %nl)*
				]])
			local placeAliasDef, aliasDef = re.find(message, grammarAliasDef)
			if aliasDef~=nil then 
				local alias = string.sub(message, string.len(message)-1, string.len(message)-1)
				if alias==">" then alias = string.sub(message, string.len(message)-3, string.len(message)-1) end
				local tableN
				for i, k in pairs(aliasDef) do
					if k[2]==alias then tableN = k[1] end
				end
				source = utilities.current_diagram():find("/element:has(/elemType[id='Class'])")
				source = source:filter(function(elem)--atstai tikai tas klases, kas ir aktivaa diagrammaa
					return elem:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") == tableN
				end)
				source = source:find("/compartment/subCompartment:has(/compartType[id='DBExpr'])")
			end
		else
			local defNameTable = {}
			table.insert(defNameTable, defName)
			local messageLength = string.len(message)
			local len = 1
			while len<=messageLength do
				local placeDefName2, defName2 = re.find(message, grammarDefName, len)
				if defName~=nil then table.insert(defNameTable, defName2) end
				len = len+1
			end
			defNameTable = table_unique(defNameTable)
			for i, k in pairs(defNameTable) do 
				local source2 = utilities.current_diagram():find("/element:has(/elemType[id='Class'])")
				source2 = source2:filter(function(elem)--atstai tikai tas klases, kas ir aktivaa diagrammaa
					return elem:find("/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") == k
				end)
				source2 = source2:find("/compartment/subCompartment:has(/compartType[id='DBExpr'])")
				if source==nil then source = source2
				else source = source:add(source2) end
			end
		end
			source:each(function(dbexpr)
				local tName = re.match(dbexpr:attr("value"), grammar)
				if tName~=nil then 
					if type(tName) ~= "table" then
						local grammar2 = re.compile([[
							gMain <- (VarName "="((VarName "::" {VarName}) / {VarName}))
							VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
						]])
						place, tableName = re.find(dbexpr:attr("value"), grammar2)
						if tableName~=nil then 
							if tableName~=nil then 
								table.insert(tableTable, tableName)
							end
						end
					else
						for i, k in pairs(tName) do
							local grammar2 = re.compile([[
								gMain <- ((VarName "=")? (VarName "::" {VarName}!.) / {VarName}!.)
								VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
							]])
							place, tableName = re.find(k, grammar2)
							if tableName~=nil then 
								table.insert(tableTable, tableName)
							end
						end
					end
				end
			end)

			if #tableTable~=0 then 
				for i, k in pairs(tableTable) do
					if source == nil then
						source = lQuery("RR#Column:has(/table[tName='" .. k .. "'])")
					else
						source = source:add(lQuery("RR#Column:has(/table[tName='" .. k .. "'])"))
					end
				end
			--ja tabulas ar nosaukumu tableTable nav, tad jamekle atbilstiba citos ClasMap-os
			else 
				local defNameTable = {}
				source = utilities.current_diagram():find("/element:has(/elemType[id='Class'])/compartment/subCompartment:has(/compartType[id='DBExpr'])")
				source:each(function(dbexpr)
					local grammar = re.compile([[
						gMain <- ({VarName} space "=" space {VarName})
						VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
						space <- (" " / %nl)*
					]])

					local place, dName, tableName = re.find(dbexpr:attr("value"), grammar)
					if dName~=nil then defNameTable[dName]=tableName end
				end)
				if defNameTable[defName]~=nil then
					source = lQuery("RR#Column:has(/table[tName='" .. defNameTable[defName] .. "'])")
				end
			end
	elseif tName~=nil then 
		if type(tName) ~= "table" then
			local grammar2 = re.compile([[
				gMain <- (VarName "="((VarName "::" {VarName}) / {VarName}))
				VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
			]])
			place, tableName = re.find(message, grammar2)
			if tableName~=nil then 
				if source == nil then
					source = lQuery("RR#Column:has(/table[tName='" .. tableName .. "'])")
				else
					source = source:add(lQuery("RR#Column:has(/table[tName='" .. tableName .. "'])"))
				end
			end
		else
			--iziet visam tabulam un atrasto to kolonas
			for i, k in pairs(tName) do
				local grammar2 = re.compile([[
					gMain <- ((VarName "::" {VarName}!.) / {VarName}!.)
					VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
				]])
				place, tableName = re.find(k, grammar2)
				if tableName~=nil then 
					if source == nil then
						source = lQuery("RR#Column:has(/table[tName='" .. tableName .. "'])")
					else
						source = source:add(lQuery("RR#Column:has(/table[tName='" .. tableName .. "'])"))
					end
				end
			end
		end
	else add_error_message(errors, current_pos, "", 100) end
	if (tName~=nil or tableTable~=nil) and source~=nil then
		source:each(function(all_instance)
			local name = all_instance:attr("colName")
			if name~=nil then add_error_message(errors, current_pos, name, 20) end
		end)
	else add_error_message(errors, current_pos, "", 100) end
end

function parse_b_function(message, current_pos) 
	local grammar = re.compile([[
					aggrFName <- ({"MIN" / "MAX" / "AVG" / "COUNT" / "SUM" / aggrUserFName})
					aggrUserFName <- ("@" VarName)
					VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
				]])
	local place, dName = re.find(message, grammar)
	if dName~=nil then
		add_error_message(errors, current_pos, "<b>", 23)
	end
end

function rdbtoowlDataMap(text)

	local grammar = re.compile([[
		--objectMap
		--dataMap
		--ontologyDBExpr
		--classMap
		
		gMain <- (space dataMap !. %parse_fail)
		objectMap <- (tableExpr space PDecoration*)
		
		PDecoration <- ({%parse_Domain "?Domain" / %parse_Range "?Range"})
		
		
		dataMap <- (dataExpr space PDecoration*)
		
				
		ontologyDBExpr <- ((ontDBExprItem (%parse_semicolon ";" space ontDBExprItem)*)?)
		
		ontDBExprItem <- (funDefPlus / ({%parse_CMap "CMap"} %parse_roundBracketOpen "(" classMap %parse_roundBracketClose ")") / dbSpec)
		
		funDefPlus <- functionDef / aggrFDef
		dbSpec <- (%parse_DBRef "DBRef" %parse_roundBracketOpen "(" dbOptionSpec (space %parse_comma "," dbOptionSpec)* %parse_roundBracketClose ")")
		
		functionDef <- (fName %parse_roundBracketOpen "(" varList %parse_roundBracketClose ")" space %parse_equal "=" space functionBody)
		aggrFDef <- (aggrUserFName %parse_roundBracketOpen "(" aggrAgrList? %parse_roundBracketClose ")" space %parse_equal "=" space functionBody)
		dbOptionSpec <-((%parse_dbname 'dbname=' %parse_VarName VarName) / (%parse_alias 'alias=' %parse_VarName VarName) / (%parse_schema 'schema=' STRING) / 
						(%parse_public_table_prefix  'public_table_prefix=' STRING) /
						(%parse_jdbc_driver 'jdbc_driver=' STRING) / (%parse_connection_string 'connection_string=' STRING) / (%parse_aux 'aux=' INT) / 
						(%parse_default 'default=' INT) / (%parse_init_script 'init_script=' STRING) )
		
		varList <- (variable (space %parse_comma "," variable)*)
		functionBody <- dataExpr
		aggrAgrList <- (%parse_TExpr "@TExpr" space %parse_exclamation "!" space %parse_Col "@Col")
		ZEROONE <- %parse_0 "0" / %parse_1 "1"
		
		fDataExpr <- (tableExprPlain? %parse_point "." valueExprPlain (%parse_tick "^^" xsdRef)?) -> {}
		
		
		
		classMap <- (((defName space %parse_equal "=") space
					 tableExprExtUri space
					 CDecoration*) /  (
					 tableExprExtUri space
					 CDecoration*)
					)
		
		defName <- %parse_VarName VarName
		tableExpr <- (tRefList (%parse_semicolon ";" space tFilterExpr? (%parse_semicolon ";" space  colDefList)?)?)
		uriPattern <- (%parse_braceOpen "{" %parse_uri "uri" %parse_equal "=" %parse_roundBracketOpen "("  valueExpr (%parse_comma "," space valueExpr)* %parse_roundBracketClose ")" %parse_braceClose "}")
		CDecoration <- (%parse_Out "?Out" / %parse_In "?In" / %parse_NoMap "!NoMap" / %parse_SubClean "!SubClean" / %parse_question "?")
		
		tRefList <- (tRefItem (%parse_comma "," space tRefItem )*)
		tFilterExpr <- (filterOrExpr (space %parse_or "or" space filterOrExpr)*)
		colDefList <- ((colDef (%parse_comma "," space colDef )*)?)
		valueExpr <- (simpleExpr (space infixOp space simpleExpr)*)
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
		
		tRefItem <- ((( tNavigItem space tRefItemL?) / tRefItemL) space tExprTopSpec?)
		filterOrExpr <- (filterAndExpr (space {%parse_and "and"} space filterAndExpr)*)
		colDef <- (%parse_VarName VarName space %parse_equal "=" space valueExpr)
		simpleExpr <- functionCall / aggregateCall / valueExprPlain / space prefixOp space simpleExpr 
		infixOp <- %parse_plus "+" / %parse_minus "-" / %parse_mul "*" / %parse_division "/" / %parse_div "div" / %parse_mod "mod"
		
		tNavigItem <- (tNavigItemBase (space %parse_colon ":" space tNavigFilter)*)
		tRefItemL <- (nLinkExpr (space  tNavigItem space tRefItemL?)?)
		tExprTopSpec <- tTopFilter
		filterAndExpr <- ((%parse_not "not"? space filterItem))
		valueExprPlain <- sqlExpr / constantExpr / colRef / %parse_variable variable / (%parse_roundBracketOpen "(" tFilterExpr %parse_roundBracketClose ")")
		constantExpr <- INT / STRING
		functionCall <- (%parse_fName fName space %parse_roundBracketOpen "(" valueList %parse_roundBracketClose ")")
		prefixOp <- %parse_minus "-"
		aggregateCall <- (( aggrFName space %parse_roundBracketOpen "(" dataExpr orderList? %parse_roundBracketClose ")") / aggregateWrk)
		
		tNavigItemBase <- (tableExprPlain space aliasDef?)
		tNavigFilter <- (tFilterExpr / tTopFilter)
		nLinkExpr <- ((%parse_squareBracketOpen "[" valueList %parse_squareBracketClose "]")? space (%parse_doubleArrow "=>" / %parse_arrow  "->") space (%parse_squareBracketOpen "[" valueList %parse_squareBracketClose "]")?)
		tTopFilter <- (%parse_braceOpen "{" (%parse_first "first" / %parse_top "top" space INT space %parse_persent "persent"?) space orderList? %parse_braceClose "}")
		orderList <- (%parse_by "by" orderSpec (%parse_comma "," orderSpec)*)
		filterItem <- unarybinaryFilterItem / constantFilterItem / existsFilterItem
		INT <- %parse_number [0-9]+
		STRING <- ((%parse_apostrophe "'" %parse_string [^"'"]* %parse_apostrophe "'") / (%parse_quote '"' %parse_string [^'"']* %parse_quote '"'))
		colRef <-  compoundColRef / colName
		--variable <- (%parse_at "@" %parse_VarName VarName)
		variable <- ("@" %parse_VarName VarName)
		sqlExpr <- caseTwoOptions / caseManyOptions
		fName <- %parse_VarName VarName
		valueList <- (valueExpr (%parse_comma "," space valueExpr)*)
		aggrFName <- %parse_min "MIN" / %parse_max "MAX" / %parse_avg "AVG" / %parse_count "COUNT" / %parse_sum "SUM" / aggrUserFName
		dataExpr <- (tDataExpr / sDataExpr) 
		tDataExpr <- (%parse_squareBracketOpen "[" tableExprExtUri %parse_squareBracketPoint "]." simpleExpr (%parse_tick "^^" xsdRef)?)
		tableExprExtUri <- (tableExpr uriPattern?)
		sDataExpr <- (valueExpr (%parse_tick "^^" xsdRef)?) 
		xDataExpr <- (tableExpr %parse_exclamation "!" valueExpr)
		aggregateWrk <- (%parse_aggregate "@aggregate"  %parse_roundBracketOpen "(" xDataExpr %parse_comma "," valueExpr %parse_comma "," space valueExpr ("order" orderList)? %parse_roundBracketClose ")")
		
		tableExprPlain <- (simpleTableExpr / (%parse_roundBracketOpen "(" tableExprExt %parse_roundBracketClose ")"))
		aliasDef <- ClassMapRef / %parse_VarName VarName
		orderSpec <- (valueExpr space (%parse_asc "asc" / %parse_desc "desc")? space)
		unarybinaryFilterItem <- (valueExpr space((%parse_is "is" space %parse_not "not"? space %parse_null "null") / (binaryFilterOp space valueExpr ) / %parse_in2 "in" space %parse_roundBracketOpen "(" valueList %parse_roundBracketClose ")" / %parse_between "between" space simpleExpr space %parse_and "and" space simpleExpr ))
		constantFilterItem <- %parse_true "true" / %parse_false "false"
		existsFilterItem <- (%parse_exists "exists" space %parse_roundBracketOpen "(" tableExpr %parse_roundBracketClose ")")
		colName <- %parse_colName %parse_VarName VarName
		compoundColRef <- (tablePlusRefExpr %parse_point "." (colName / (%parse_roundBracketOpen "(" colRef %parse_roundBracketClose ")")))
		caseTwoOptions <- (%parse_case "case" space %parse_when "when" space tFilterExpr space %parse_then "then" space valueExpr space (%parse_else "else" space valueExpr space)? %parse_end "end")
		caseManyOptions <- (%parse_case "case" space valueExpr space (%parse_when "when" space valueExpr space %parse_then "then" space valueExpr)+ space (%parse_else "else" space valueExpr space)? %parse_end "end")
		aggrUserFName <- (%parse_aggrUserFName "@" %parse_VarName VarName)
		xsdRef <- ((XSD_TYPE_PREFIX)? %parse_VarName VarName)
		
		simpleTableExpr <- ClassMapRef / namedRef / tableUseExpr
		tableExprExt <- (tableExpr space (uriPattern / keyPattern)?)
		binaryFilterOp <- %parse_like "like" / %parse_in2 "in" / %parse_lessEqual "<=" / %parse_moreEqual ">=" / %parse_equal2 "<>" / %parse_equal "=" / %parse_less "<" / %parse_more ">"
		tablePlusRefExpr <- ClassMapRef / namedRef / tableRefExpr
		tableRefExpr <- ((%parse_dbAliasRefExpr dbAlias %parse_doubleColon "::")? %parse_TableNameRefExpr VarName)
		XSD_TYPE_PREFIX <- %parse_xsd "xsd:"
		ClassMapRef <- %parse_s "<s>" / "<t>" / "<b>"
		
		namedRef <- (%parse_twoSquareBracketOpen "[" "[" %parse_namedRef defName %parse_twoSquareBracketClose "]" "]")
		tableUseExpr <- ((%parse_dbAlias dbAlias %parse_doubleColon "::")? %parse_TableName %parse_VarName VarName)
		keyPattern <- (%parse_braceOpen "{" %parse_key "key" %parse_equal "=" %parse_roundBracketOpen "("  valueExpr (%parse_comma "," valueExpr)* %parse_roundBracketClose ")" %parse_braceClose "}")
		
		dbAlias <- %parse_VarName VarName
		space <- %parse_space (" " / %nl)*
	]]
	, {  
		parse_fail = function (subject, current_pos, captures) 
			return false 
		end,
		parse_variable = function (message, current_pos) parse_variable_function (message, current_pos) return current_pos end,
		parse_fName = function (message, current_pos) parse_fName_function (message, current_pos) return current_pos end,
		parse_aggrUserFName = function (message, current_pos) parse_aggrUserFName_function (message, current_pos) return current_pos end,
		parse_namedRef = function (message, current_pos) parse_namedRef_function(message, current_pos) return current_pos end,
		parse_TableName = function (message, current_pos) parse_TableName_function(message, current_pos) return current_pos end,
		parse_TableNameRefExpr = function (message, current_pos) parse_TableNameRefExpr_function(message, current_pos) return current_pos end,
		parse_dbAlias = function (message, current_pos) parse_dbAlias_function (message, current_pos) return current_pos end,
		parse_dbAliasRefExpr = function (message, current_pos) parse_dbAliasRefExpr_function (message, current_pos) return current_pos end,
		parse_colName = function (message, current_pos) parse_colNameDataMap_function (message, current_pos) return current_pos end,
		parse_point = function (message, current_pos) add_error_message(errors, current_pos, ".", 30) return current_pos end,
		parse_Domain  = function (message, current_pos) add_error_message(errors, current_pos, "?Domain", 90) return current_pos end,
		parse_by = function (message, current_pos) add_error_message(errors, current_pos, "by", 60) return current_pos end,
		parse_Range  = function (message, current_pos) add_error_message(errors, current_pos, "?Range", 90) return current_pos end,
		parse_order = function (message, current_pos) add_error_message(errors, current_pos, "order", 90) return current_pos end,
		parse_semicolon  = function (message, current_pos) add_error_message(errors, current_pos, ";", 30) return current_pos end,
		parse_CMap  = function (message, current_pos) add_error_message(errors, current_pos, "CMap", 90) return current_pos end,
		parse_roundBracketOpen  = function (message, current_pos) add_error_message(errors, current_pos, "(", 30) return current_pos end,
		parse_roundBracketClose  = function (message, current_pos) add_error_message(errors, current_pos, ")", 30) return current_pos end,
		parse_DBRef  = function (message, current_pos) add_error_message(errors, current_pos, "DBRef", 90) return current_pos end,
		parse_comma  = function (message, current_pos) add_error_message(errors, current_pos, ",", 30) return current_pos end,
		parse_equal  = function (message, current_pos) add_error_message(errors, current_pos, "=", 50) return current_pos end,
		parse_dbname  = function (message, current_pos) add_error_message(errors, current_pos, 'dbname=', 90) return current_pos end,
		parse_VarName = function (message, current_pos) add_error_message(errors, current_pos, "", 100) return current_pos end,
		parse_alias  = function (message, current_pos) add_error_message(errors, current_pos, 'alias=', 90) return current_pos end,
		parse_schema  = function (message, current_pos) add_error_message(errors, current_pos, 'schema=', 90) return current_pos end,
		parse_public_table_prefix   = function (message, current_pos) add_error_message(errors, current_pos, 'public_table_prefix=', 90) return current_pos end,
		parse_jdbc_driver  = function (message, current_pos) add_error_message(errors, current_pos, 'jdbc_driver=', 90) return current_pos end,
		parse_connection_string  = function (message, current_pos) add_error_message(errors, current_pos, 'connection_string=', 90) return current_pos end,
		parse_aux  = function (message, current_pos) add_error_message(errors, current_pos, 'aux=', 90) return current_pos end,
		parse_default  = function (message, current_pos) add_error_message(errors, current_pos, 'default=', 90) return current_pos end,
		parse_init_script  = function (message, current_pos) add_error_message(errors, current_pos, 'init_script=', 90) return current_pos end,
		parse_TExpr  = function (message, current_pos) add_error_message(errors, current_pos, "@TExpr", 70) return current_pos end,
		parse_exclamation  = function (message, current_pos) add_error_message(errors, current_pos, "!", 70) return current_pos end,
		parse_Col  = function (message, current_pos) add_error_message(errors, current_pos, "@Col", 70) return current_pos end,
		parse_0  = function (message, current_pos) add_error_message(errors, current_pos, "0", 30) return current_pos end,
		parse_1  = function (message, current_pos) add_error_message(errors, current_pos, "1", 30) return current_pos end,
		parse_tick  = function (message, current_pos) add_error_message(errors, current_pos, "^^", 30) return current_pos end,
		parse_braceOpen  = function (message, current_pos) add_error_message(errors, current_pos, "{", 30) return current_pos end,
		parse_uri  = function (message, current_pos) add_error_message(errors, current_pos, "uri", 30) return current_pos end,
		parse_braceClose  = function (message, current_pos) add_error_message(errors, current_pos, "}", 30) return current_pos end,
		parse_Out  = function (message, current_pos) add_error_message(errors, current_pos, "?Out", 100) return current_pos end,
		parse_In = function (message, current_pos) add_error_message(errors, current_pos, "?In", 100) return current_pos end,
		parse_NoMap  = function (message, current_pos) add_error_message(errors, current_pos, "!NoMap", 100) return current_pos end,
		parse_SubClean  = function (message, current_pos) add_error_message(errors, current_pos, "!SubClean", 100) return current_pos end,
		parse_question  = function (message, current_pos) add_error_message(errors, current_pos, "?", 100) return current_pos end,
		parse_or  = function (message, current_pos) add_error_message(errors, current_pos, "or", 50) return current_pos end,
		parse_and  = function (message, current_pos) add_error_message(errors, current_pos, "and", 50) return current_pos end,
		parse_plus  = function (message, current_pos) add_error_message(errors, current_pos, "+", 50) return current_pos end,
		parse_minus = function (message, current_pos) add_error_message(errors, current_pos, "-", 50) return current_pos end,
		parse_mul  = function (message, current_pos) add_error_message(errors, current_pos, "*", 50) return current_pos end,
		parse_division  = function (message, current_pos) add_error_message(errors, current_pos, "/", 50) return current_pos end,
		parse_div  = function (message, current_pos) add_error_message(errors, current_pos, "div", 50) return current_pos end,
		parse_mod  = function (message, current_pos) add_error_message(errors, current_pos, "mod", 50) return current_pos end,
		parse_colon  = function (message, current_pos) add_error_message(errors, current_pos, ":", 50) return current_pos end,
		parse_not  = function (message, current_pos) add_error_message(errors, current_pos, "not", 30) return current_pos end,
		parse_gridOpen  = function (message, current_pos) add_error_message(errors, current_pos, "(.", 30) return current_pos end,
		parse_gridClose  = function (message, current_pos) add_error_message(errors, current_pos, ".)", 30) return current_pos end,
		parse_squareBracketOpen  = function (message, current_pos) add_error_message(errors, current_pos, "[", 30) return current_pos end,
		parse_squareBracketClose   = function (message, current_pos) add_error_message(errors, current_pos, "]", 30) return current_pos end,
		parse_arrow   = function (message, current_pos) add_error_message(errors, current_pos, "->", 30) return current_pos end,
		parse_doubleArrow   = function (message, current_pos) add_error_message(errors, current_pos, "=>", 30) return current_pos end,
		parse_first   = function (message, current_pos) add_error_message(errors, current_pos, "first", 30) return current_pos end,
		parse_top   = function (message, current_pos) add_error_message(errors, current_pos, "top", 30) return current_pos end,
		parse_persent   = function (message, current_pos) add_error_message(errors, current_pos, "persent", 30) return current_pos end,
		parse_number  = function (message, current_pos) add_error_message(errors, current_pos, "", 50) return current_pos end,
		parse_apostrophe   = function (message, current_pos) add_error_message(errors, current_pos, "'", 50) return current_pos end,
		parse_string  = function (message, current_pos) add_error_message(errors, current_pos, "", 100) return current_pos end,
		parse_quote   = function (message, current_pos) add_error_message(errors, current_pos, '"', 50) return current_pos end,
		parse_at   = function (message, current_pos) add_error_message(errors, current_pos, "@", 70) return current_pos end,
		parse_min   = function (message, current_pos) add_error_message(errors, current_pos, "MIN", 70) return current_pos end,
		parse_max   = function (message, current_pos) add_error_message(errors, current_pos, "MAX", 70) return current_pos end,
		parse_avg   = function (message, current_pos) add_error_message(errors, current_pos, "AVG", 70) return current_pos end,
		parse_count   = function (message, current_pos) add_error_message(errors, current_pos, "COUNT", 70) return current_pos end,
		parse_sum   = function (message, current_pos) add_error_message(errors, current_pos, "SUM", 70) return current_pos end,
		parse_squareBracketPoint   = function (message, current_pos) add_error_message(errors, current_pos, "].", 30) return current_pos end,
		parse_aggregate   = function (message, current_pos) add_error_message(errors, current_pos, "@aggregate", 70) return current_pos end,
		parse_exclamation   = function (message, current_pos) add_error_message(errors, current_pos, "!", 60) return current_pos end,
		parse_asc   = function (message, current_pos) add_error_message(errors, current_pos, "asc", 60) return current_pos end,
		parse_desc   = function (message, current_pos) add_error_message(errors, current_pos, "desc", 60) return current_pos end,
		parse_is   = function (message, current_pos) add_error_message(errors, current_pos, "is", 60) return current_pos end,
		parse_null   = function (message, current_pos) add_error_message(errors, current_pos, "null", 60) return current_pos end,
		parse_between   = function (message, current_pos) add_error_message(errors, current_pos, "between", 60) return current_pos end,
		parse_true   = function (message, current_pos) add_error_message(errors, current_pos, "true", 60) return current_pos end,
		parse_false   = function (message, current_pos) add_error_message(errors, current_pos, "false", 60) return current_pos end,
		parse_exists   = function (message, current_pos) add_error_message(errors, current_pos, "exists", 60) return current_pos end,
		parse_case   = function (message, current_pos) add_error_message(errors, current_pos, "case", 60) return current_pos end,
		parse_when   = function (message, current_pos) add_error_message(errors, current_pos, "when", 60) return current_pos end,
		parse_then   = function (message, current_pos) add_error_message(errors, current_pos, "then", 60) return current_pos end,
		parse_else   = function (message, current_pos) add_error_message(errors, current_pos, "else", 60) return current_pos end,
		parse_end   = function (message, current_pos) add_error_message(errors, current_pos, "end", 60) return current_pos end,
		parse_less   = function (message, current_pos) add_error_message(errors, current_pos, "<", 60) return current_pos end,
		parse_more   = function (message, current_pos) add_error_message(errors, current_pos, ">", 60) return current_pos end,
		parse_lessEqual   = function (message, current_pos) add_error_message(errors, current_pos, "<=", 60) return current_pos end,
		parse_moreEqual   = function (message, current_pos) add_error_message(errors, current_pos, ">=", 60) return current_pos end,
		parse_equal2   = function (message, current_pos) add_error_message(errors, current_pos, "<>", 60) return current_pos end,
		parse_like   = function (message, current_pos) add_error_message(errors, current_pos, "like", 60) return current_pos end,
		parse_in2   = function (message, current_pos) add_error_message(errors, current_pos, "in", 60) return current_pos end,
		parse_xsd   = function (message, current_pos) add_error_message(errors, current_pos, "xsd:", 30) return current_pos end,	  
		parse_s  = function (message, current_pos) add_error_message(errors, current_pos, "<s>", 23) return current_pos end,
		parse_t  = function (message, current_pos) add_error_message(errors, current_pos, "<t>", 23) return current_pos end,
		parse_b  = function (message, current_pos) parse_b_function (message, current_pos) return current_pos end,
		parse_twoSquareBracketOpen   = function (message, current_pos) add_error_message(errors, current_pos, "[[", 30) return current_pos end,
		parse_twoSquareBracketClose  = function (message, current_pos) add_error_message(errors, current_pos, "]]", 30) return current_pos end,
		parse_doubleColon   = function (message, current_pos) add_error_message(errors, current_pos, "::", 30) return current_pos end,
		parse_key   = function (message, current_pos) add_error_message(errors, current_pos, "key", 30) return current_pos end,
		parse_space   = function (message, current_pos) add_error_message(errors, current_pos, " ", 100) return current_pos end,
	  }
	)
	local res = match_err(grammar, text)
end

function rdbtoowlObjectMap(text)

	local grammar = re.compile([[
		--objectMap
		--dataMap
		--ontologyDBExpr
		--classMap
		
		gMain <- (space objectMap !. %parse_fail)
		objectMap <- (tableExpr space PDecoration*)
		
		PDecoration <- ({%parse_Domain "?Domain" / %parse_Range "?Range"})
		
		
		dataMap <- (dataExpr space PDecoration*)
		
				
		ontologyDBExpr <- ((ontDBExprItem (%parse_semicolon ";" space ontDBExprItem)*)?)
		
		ontDBExprItem <- (funDefPlus / ({%parse_CMap "CMap"} %parse_roundBracketOpen "(" classMap %parse_roundBracketClose ")") / dbSpec)
		
		funDefPlus <- functionDef / aggrFDef
		dbSpec <- (%parse_DBRef "DBRef" %parse_roundBracketOpen "(" dbOptionSpec (space %parse_comma "," dbOptionSpec)* %parse_roundBracketClose ")")
		
		functionDef <- (fName %parse_roundBracketOpen "(" varList %parse_roundBracketClose ")" space %parse_equal "=" space functionBody)
		aggrFDef <- (aggrUserFName %parse_roundBracketOpen "(" aggrAgrList? %parse_roundBracketClose ")" space %parse_equal "=" space functionBody)
		dbOptionSpec <-((%parse_dbname 'dbname=' %parse_VarName VarName) / (%parse_alias 'alias=' %parse_VarName VarName) / (%parse_schema 'schema=' STRING) / 
						(%parse_public_table_prefix  'public_table_prefix=' STRING) /
						(%parse_jdbc_driver 'jdbc_driver=' STRING) / (%parse_connection_string 'connection_string=' STRING) / (%parse_aux 'aux=' INT) / 
						(%parse_default 'default=' INT) / (%parse_init_script 'init_script=' STRING) )
		
		varList <- (variable (space %parse_comma "," variable)*)
		functionBody <- dataExpr
		aggrAgrList <- (%parse_TExpr "@TExpr" space %parse_exclamation "!" space %parse_Col "@Col")
		ZEROONE <- %parse_0 "0" / %parse_1 "1"
		
		fDataExpr <- (tableExprPlain? %parse_point "." valueExprPlain (%parse_tick "^^" xsdRef)?) -> {}
		
		
		classMap <- (((defName space %parse_equal "=") space
					 tableExprExtUri space
					 CDecoration*) /  (
					 tableExprExtUri space
					 CDecoration*)
					)
		
		defName <- %parse_VarName VarName
		tableExpr <- (tRefList (%parse_semicolon ";" space tFilterExpr? (%parse_semicolon ";" space  colDefList)?)?)
		uriPattern <- (%parse_braceOpen "{" %parse_uri "uri" %parse_equal "=" %parse_roundBracketOpen "("  valueExpr (%parse_comma "," space valueExpr)* %parse_roundBracketClose ")" %parse_braceClose "}")
		CDecoration <- (%parse_Out "?Out" / %parse_In "?In" / %parse_NoMap "!NoMap" / %parse_SubClean "!SubClean" / %parse_question "?")
		
		tRefList <- (tRefItem (%parse_comma "," space tRefItem )*)
		tFilterExpr <- (filterOrExpr (space %parse_or "or" space filterOrExpr)*)
		colDefList <- ((colDef (%parse_comma "," space colDef )*)?)
		valueExpr <- (simpleExpr (space infixOp space simpleExpr)*)
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
		
		tRefItem <- ((( tNavigItem space tRefItemL?) / tRefItemL) space tExprTopSpec?)
		filterOrExpr <- (filterAndExpr (space {%parse_and "and"} space filterAndExpr)*)
		colDef <- (%parse_VarName VarName space %parse_equal "=" space valueExpr)
		simpleExpr <- functionCall / aggregateCall / valueExprPlain / space prefixOp space simpleExpr 
		infixOp <- %parse_plus "+" / %parse_minus "-" / %parse_mul "*" / %parse_division "/" / %parse_div "div" / %parse_mod "mod"
		
		tNavigItem <- (tNavigItemBase (space %parse_colon ":" space tNavigFilter)*)
		tRefItemL <- (nLinkExpr (space  tNavigItem space tRefItemL?)?)
		tExprTopSpec <- tTopFilter
		filterAndExpr <- ((%parse_not "not"? space filterItem))
		valueExprPlain <- sqlExpr / constantExpr / colRef / %parse_variable variable / (%parse_roundBracketOpen "(" tFilterExpr %parse_roundBracketClose ")")
		constantExpr <- INT / STRING
		functionCall <- (%parse_fName fName space %parse_roundBracketOpen "(" valueList %parse_roundBracketClose ")")
		prefixOp <- %parse_minus "-"
		aggregateCall <- (( aggrFName space %parse_roundBracketOpen "(" dataExpr orderList? %parse_roundBracketClose ")") / aggregateWrk)
		
		tNavigItemBase <- (tableExprPlain space aliasDef?)
		tNavigFilter <- (tFilterExpr / tTopFilter)
		nLinkExpr <- ((%parse_squareBracketOpen "[" valueList %parse_squareBracketClose "]")? space (%parse_doubleArrow "=>" / %parse_arrow  "->") space (%parse_squareBracketOpen "[" valueList %parse_squareBracketClose "]")?)
		tTopFilter <- (%parse_braceOpen "{" (%parse_first "first" / %parse_top "top" space INT space %parse_persent "persent"?) space orderList? %parse_braceClose "}")
		orderList <- (%parse_by "by" orderSpec (%parse_comma "," orderSpec)*)
		filterItem <- unarybinaryFilterItem / constantFilterItem / existsFilterItem
		INT <- %parse_number [0-9]+
		STRING <- ((%parse_apostrophe "'" %parse_string [^"'"]* %parse_apostrophe "'") / (%parse_quote '"' %parse_string [^'"']* %parse_quote '"'))
		colRef <-  compoundColRef / colName
		--variable <- (%parse_at "@" %parse_VarName VarName)
		variable <- ("@" %parse_VarName VarName)
		sqlExpr <- caseTwoOptions / caseManyOptions
		fName <- %parse_VarName VarName
		valueList <- (valueExpr (%parse_comma "," space valueExpr)*)
		aggrFName <- %parse_min "MIN" / %parse_max "MAX" / %parse_avg "AVG" / %parse_count "COUNT" / %parse_sum "SUM" / aggrUserFName
		dataExpr <- (tDataExpr / sDataExpr) 
		tDataExpr <- (%parse_squareBracketOpen "[" tableExprExtUri %parse_squareBracketPoint "]." simpleExpr (%parse_tick "^^" xsdRef)?)
		tableExprExtUri <- (tableExpr uriPattern?)
		sDataExpr <- (valueExpr (%parse_tick "^^" xsdRef)?) 
		xDataExpr <- (tableExpr %parse_exclamation "!" valueExpr)
		aggregateWrk <- (%parse_aggregate "@aggregate"  %parse_roundBracketOpen "(" xDataExpr %parse_comma "," valueExpr %parse_comma "," space valueExpr ("order" orderList)? %parse_roundBracketClose ")")
		
		tableExprPlain <- (simpleTableExpr / (%parse_roundBracketOpen "(" tableExprExt %parse_roundBracketClose ")"))
		aliasDef <- ClassMapRef / %parse_VarName VarName
		orderSpec <- (valueExpr space (%parse_asc "asc" / %parse_desc "desc")? space)
		unarybinaryFilterItem <- (valueExpr space((%parse_is "is" space %parse_not "not"? space %parse_null "null") / (binaryFilterOp space valueExpr ) / %parse_in2 "in" space %parse_roundBracketOpen "(" valueList %parse_roundBracketClose ")" / %parse_between "between" space simpleExpr space %parse_and "and" space simpleExpr ))
		constantFilterItem <- %parse_true "true" / %parse_false "false"
		existsFilterItem <- (%parse_exists "exists" space %parse_roundBracketOpen "(" tableExpr %parse_roundBracketClose ")")
		colName <- %parse_colName %parse_VarName VarName
		compoundColRef <- (tablePlusRefExpr %parse_point "." (colName / (%parse_roundBracketOpen "(" colRef %parse_roundBracketClose ")")))
		caseTwoOptions <- (%parse_case "case" space %parse_when "when" space tFilterExpr space %parse_then "then" space valueExpr space (%parse_else "else" space valueExpr space)? %parse_end "end")
		caseManyOptions <- (%parse_case "case" space valueExpr space (%parse_when "when" space valueExpr space %parse_then "then" space valueExpr)+ space (%parse_else "else" space valueExpr space)? %parse_end "end")
		aggrUserFName <- (%parse_aggrUserFName "@" %parse_VarName VarName)
		xsdRef <- ((XSD_TYPE_PREFIX)? %parse_VarName VarName)
		
		simpleTableExpr <- ClassMapRef / namedRef / tableUseExpr
		tableExprExt <- (tableExpr space (uriPattern / keyPattern)?)
		binaryFilterOp <- %parse_like "like" / %parse_in2 "in" / %parse_lessEqual "<=" / %parse_moreEqual ">=" / %parse_equal2 "<>" / %parse_equal "=" / %parse_less "<" / %parse_more ">"
		tablePlusRefExpr <- ClassMapRef / namedRef / tableRefExpr
		tableRefExpr <- ((%parse_dbAlias dbAlias %parse_doubleColon "::")? %parse_TableName VarName)
		XSD_TYPE_PREFIX <- %parse_xsd "xsd:"
		ClassMapRef <- %parse_s "<s>" / %parse_t "<t>" / "<b>"
		
		namedRef <- (%parse_twoSquareBracketOpen "[" "[" %parse_namedRef defName %parse_twoSquareBracketClose "]" "]")
		tableUseExpr <- ((%parse_dbAlias dbAlias %parse_doubleColon "::")? %parse_TableName %parse_VarName VarName)
		keyPattern <- (%parse_braceOpen "{" %parse_key "key" %parse_equal "=" %parse_roundBracketOpen "("  valueExpr (%parse_comma "," valueExpr)* %parse_roundBracketClose ")" %parse_braceClose "}")
		
		dbAlias <- %parse_VarName VarName
		space <- %parse_space (" " / %nl)*
	]]
	, {  
		parse_fail = function (subject, current_pos, captures) 
			return false 
		end,
		parse_variable = function (message, current_pos) parse_variable_function (message, current_pos) return current_pos end,
		parse_fName = function (message, current_pos) parse_fName_function (message, current_pos) return current_pos end,
		parse_aggrUserFName = function (message, current_pos) parse_aggrUserFName_function (message, current_pos) return current_pos end,
		parse_namedRef = function (message, current_pos) parse_namedRef_function(message, current_pos) return current_pos end,
		parse_TableName = function (message, current_pos) parse_TableName_function(message, current_pos) return current_pos end,
		parse_TableNameRefExpr = function (message, current_pos) parse_TableNameRefExpr_function(message, current_pos) return current_pos end,
		parse_dbAlias = function (message, current_pos) parse_dbAlias_function (message, current_pos) return current_pos end,
		parse_dbAliasRefExpr = function (message, current_pos) parse_dbAliasRefExpr_function (message, current_pos) return current_pos end,
		parse_colName = function (message, current_pos) parse_colNameObjectMap_function (message, current_pos) return current_pos end,
		parse_point = function (message, current_pos) add_error_message(errors, current_pos, ".", 30) return current_pos end,
		parse_Domain  = function (message, current_pos) add_error_message(errors, current_pos, "?Domain", 90) return current_pos end,
		parse_by = function (message, current_pos) add_error_message(errors, current_pos, "by", 60) return current_pos end,
		parse_Range  = function (message, current_pos) add_error_message(errors, current_pos, "?Range", 90) return current_pos end,
		parse_order = function (message, current_pos) add_error_message(errors, current_pos, "order", 90) return current_pos end,
		parse_semicolon  = function (message, current_pos) add_error_message(errors, current_pos, ";", 30) return current_pos end,
		parse_CMap  = function (message, current_pos) add_error_message(errors, current_pos, "CMap", 90) return current_pos end,
		parse_roundBracketOpen  = function (message, current_pos) add_error_message(errors, current_pos, "(", 30) return current_pos end,
		parse_roundBracketClose  = function (message, current_pos) add_error_message(errors, current_pos, ")", 30) return current_pos end,
		parse_DBRef  = function (message, current_pos) add_error_message(errors, current_pos, "DBRef", 90) return current_pos end,
		parse_comma  = function (message, current_pos) add_error_message(errors, current_pos, ",", 30) return current_pos end,
		parse_equal  = function (message, current_pos) add_error_message(errors, current_pos, "=", 50) return current_pos end,
		parse_dbname  = function (message, current_pos) add_error_message(errors, current_pos, 'dbname=', 90) return current_pos end,
		parse_VarName = function (message, current_pos) add_error_message(errors, current_pos, "", 100) return current_pos end,
		parse_alias  = function (message, current_pos) add_error_message(errors, current_pos, 'alias=', 90) return current_pos end,
		parse_schema  = function (message, current_pos) add_error_message(errors, current_pos, 'schema=', 90) return current_pos end,
		parse_public_table_prefix   = function (message, current_pos) add_error_message(errors, current_pos, 'public_table_prefix=', 90) return current_pos end,
		parse_jdbc_driver  = function (message, current_pos) add_error_message(errors, current_pos, 'jdbc_driver=', 90) return current_pos end,
		parse_connection_string  = function (message, current_pos) add_error_message(errors, current_pos, 'connection_string=', 90) return current_pos end,
		parse_aux  = function (message, current_pos) add_error_message(errors, current_pos, 'aux=', 90) return current_pos end,
		parse_default  = function (message, current_pos) add_error_message(errors, current_pos, 'default=', 90) return current_pos end,
		parse_init_script  = function (message, current_pos) add_error_message(errors, current_pos, 'init_script=', 90) return current_pos end,
		parse_TExpr  = function (message, current_pos) add_error_message(errors, current_pos, "@TExpr", 70) return current_pos end,
		parse_exclamation  = function (message, current_pos) add_error_message(errors, current_pos, "!", 70) return current_pos end,
		parse_Col  = function (message, current_pos) add_error_message(errors, current_pos, "@Col", 70) return current_pos end,
		parse_0  = function (message, current_pos) add_error_message(errors, current_pos, "0", 30) return current_pos end,
		parse_1  = function (message, current_pos) add_error_message(errors, current_pos, "1", 30) return current_pos end,
		parse_tick  = function (message, current_pos) add_error_message(errors, current_pos, "^^", 30) return current_pos end,
		parse_braceOpen  = function (message, current_pos) add_error_message(errors, current_pos, "{", 30) return current_pos end,
		parse_uri  = function (message, current_pos) add_error_message(errors, current_pos, "uri", 30) return current_pos end,
		parse_braceClose  = function (message, current_pos) add_error_message(errors, current_pos, "}", 30) return current_pos end,
		parse_Out  = function (message, current_pos) add_error_message(errors, current_pos, "?Out", 100) return current_pos end,
		parse_In = function (message, current_pos) add_error_message(errors, current_pos, "?In", 100) return current_pos end,
		parse_NoMap  = function (message, current_pos) add_error_message(errors, current_pos, "!NoMap", 100) return current_pos end,
		parse_SubClean  = function (message, current_pos) add_error_message(errors, current_pos, "!SubClean", 100) return current_pos end,
		parse_question  = function (message, current_pos) add_error_message(errors, current_pos, "?", 100) return current_pos end,
		parse_or  = function (message, current_pos) add_error_message(errors, current_pos, "or", 50) return current_pos end,
		parse_and  = function (message, current_pos) add_error_message(errors, current_pos, "and", 50) return current_pos end,
		parse_plus  = function (message, current_pos) add_error_message(errors, current_pos, "+", 50) return current_pos end,
		parse_minus = function (message, current_pos) add_error_message(errors, current_pos, "-", 50) return current_pos end,
		parse_mul  = function (message, current_pos) add_error_message(errors, current_pos, "*", 50) return current_pos end,
		parse_division  = function (message, current_pos) add_error_message(errors, current_pos, "/", 50) return current_pos end,
		parse_div  = function (message, current_pos) add_error_message(errors, current_pos, "div", 50) return current_pos end,
		parse_mod  = function (message, current_pos) add_error_message(errors, current_pos, "mod", 50) return current_pos end,
		parse_colon  = function (message, current_pos) add_error_message(errors, current_pos, ":", 50) return current_pos end,
		parse_not  = function (message, current_pos) add_error_message(errors, current_pos, "not", 30) return current_pos end,
		parse_gridOpen  = function (message, current_pos) add_error_message(errors, current_pos, "(.", 30) return current_pos end,
		parse_gridClose  = function (message, current_pos) add_error_message(errors, current_pos, ".)", 30) return current_pos end,
		parse_squareBracketOpen  = function (message, current_pos) add_error_message(errors, current_pos, "[", 30) return current_pos end,
		parse_squareBracketClose   = function (message, current_pos) add_error_message(errors, current_pos, "]", 30) return current_pos end,
		parse_arrow   = function (message, current_pos) add_error_message(errors, current_pos, "->", 30) return current_pos end,
		parse_doubleArrow   = function (message, current_pos) add_error_message(errors, current_pos, "=>", 30) return current_pos end,
		parse_first   = function (message, current_pos) add_error_message(errors, current_pos, "first", 30) return current_pos end,
		parse_top   = function (message, current_pos) add_error_message(errors, current_pos, "top", 30) return current_pos end,
		parse_persent   = function (message, current_pos) add_error_message(errors, current_pos, "persent", 30) return current_pos end,
		parse_number  = function (message, current_pos) add_error_message(errors, current_pos, "", 50) return current_pos end,
		parse_apostrophe   = function (message, current_pos) add_error_message(errors, current_pos, "'", 50) return current_pos end,
		parse_string  = function (message, current_pos) add_error_message(errors, current_pos, "", 100) return current_pos end,
		parse_quote   = function (message, current_pos) add_error_message(errors, current_pos, '"', 50) return current_pos end,
		parse_at   = function (message, current_pos) add_error_message(errors, current_pos, "@", 70) return current_pos end,
		parse_min   = function (message, current_pos) add_error_message(errors, current_pos, "MIN", 70) return current_pos end,
		parse_max   = function (message, current_pos) add_error_message(errors, current_pos, "MAX", 70) return current_pos end,
		parse_avg   = function (message, current_pos) add_error_message(errors, current_pos, "AVG", 70) return current_pos end,
		parse_count   = function (message, current_pos) add_error_message(errors, current_pos, "COUNT", 70) return current_pos end,
		parse_sum   = function (message, current_pos) add_error_message(errors, current_pos, "SUM", 70) return current_pos end,
		parse_squareBracketPoint   = function (message, current_pos) add_error_message(errors, current_pos, "].", 30) return current_pos end,
		parse_aggregate   = function (message, current_pos) add_error_message(errors, current_pos, "@aggregate", 70) return current_pos end,
		parse_exclamation   = function (message, current_pos) add_error_message(errors, current_pos, "!", 60) return current_pos end,
		parse_asc   = function (message, current_pos) add_error_message(errors, current_pos, "asc", 60) return current_pos end,
		parse_desc   = function (message, current_pos) add_error_message(errors, current_pos, "desc", 60) return current_pos end,
		parse_is   = function (message, current_pos) add_error_message(errors, current_pos, "is", 60) return current_pos end,
		parse_null   = function (message, current_pos) add_error_message(errors, current_pos, "null", 60) return current_pos end,
		parse_between   = function (message, current_pos) add_error_message(errors, current_pos, "between", 60) return current_pos end,
		parse_true   = function (message, current_pos) add_error_message(errors, current_pos, "true", 60) return current_pos end,
		parse_false   = function (message, current_pos) add_error_message(errors, current_pos, "false", 60) return current_pos end,
		parse_exists   = function (message, current_pos) add_error_message(errors, current_pos, "exists", 60) return current_pos end,
		parse_case   = function (message, current_pos) add_error_message(errors, current_pos, "case", 60) return current_pos end,
		parse_when   = function (message, current_pos) add_error_message(errors, current_pos, "when", 60) return current_pos end,
		parse_then   = function (message, current_pos) add_error_message(errors, current_pos, "then", 60) return current_pos end,
		parse_else   = function (message, current_pos) add_error_message(errors, current_pos, "else", 60) return current_pos end,
		parse_end   = function (message, current_pos) add_error_message(errors, current_pos, "end", 60) return current_pos end,
		parse_less   = function (message, current_pos) add_error_message(errors, current_pos, "<", 60) return current_pos end,
		parse_more   = function (message, current_pos) add_error_message(errors, current_pos, ">", 60) return current_pos end,
		parse_lessEqual   = function (message, current_pos) add_error_message(errors, current_pos, "<=", 60) return current_pos end,
		parse_moreEqual   = function (message, current_pos) add_error_message(errors, current_pos, ">=", 60) return current_pos end,
		parse_equal2   = function (message, current_pos) add_error_message(errors, current_pos, "<>", 60) return current_pos end,
		parse_like   = function (message, current_pos) add_error_message(errors, current_pos, "like", 60) return current_pos end,
		parse_in2   = function (message, current_pos) add_error_message(errors, current_pos, "in", 60) return current_pos end,
		parse_xsd   = function (message, current_pos) add_error_message(errors, current_pos, "xsd:", 30) return current_pos end,	  
		parse_s  = function (message, current_pos) add_error_message(errors, current_pos, "<s>", 23) return current_pos end,
		parse_t  = function (message, current_pos) add_error_message(errors, current_pos, "<t>", 23) return current_pos end,
		parse_b  = function (message, current_pos) parse_b_function (message, current_pos) return current_pos end,
		parse_twoSquareBracketOpen   = function (message, current_pos) add_error_message(errors, current_pos, "[[", 30) return current_pos end,
		parse_twoSquareBracketClose  = function (message, current_pos) add_error_message(errors, current_pos, "]]", 30) return current_pos end,
		parse_doubleColon   = function (message, current_pos) add_error_message(errors, current_pos, "::", 30) return current_pos end,
		parse_key   = function (message, current_pos) add_error_message(errors, current_pos, "key", 30) return current_pos end,
		parse_space   = function (message, current_pos) add_error_message(errors, current_pos, " ", 100) return current_pos end,
	  }
	)
	local res = match_err(grammar, text)
end

function rdbtoowlOntologyDBExpr(text)

	local grammar = re.compile([[
		--objectMap
		--dataMap
		--ontologyDBExpr
		--classMap
		
		gMain <- (space ontologyDBExpr !. %parse_fail)
		
		ontologyDBExpr <- ((ontDBExprItem (%parse_semicolon ";" space ontDBExprItem)*)?)
		
		ontDBExprItem <- (funDefPlus / ({%parse_CMap "CMap"} %parse_roundBracketOpen "(" classMap %parse_roundBracketClose ")") / dbSpec)
		
		funDefPlus <- functionDef / aggrFDef
		dbSpec <- (%parse_DBRef "DBRef" %parse_roundBracketOpen "(" dbOptionSpec (space %parse_comma "," space dbOptionSpec)* %parse_roundBracketClose ")")
		
		functionDef <- (fName %parse_roundBracketOpen "(" varList %parse_roundBracketClose ")" space %parse_equal "=" space functionBody)
		aggrFDef <- (aggrUserFName %parse_roundBracketOpen "(" aggrAgrList? %parse_roundBracketClose ")" space %parse_equal "=" space functionBody)
		dbOptionSpec <-((%parse_dbname 'dbname=' %parse_VarName VarName) / (%parse_alias 'alias=' %parse_VarName VarName) / (%parse_schema 'schema=' STRING) / 
						(%parse_public_table_prefix  'public_table_prefix=' STRING) /
						(%parse_jdbc_driver 'jdbc_driver=' STRING) / (%parse_connection_string 'connection_string=' STRING) / (%parse_aux 'aux=' INT) / 
						(%parse_default 'default=' INT) / (%parse_init_script 'init_script=' STRING) )
		
		varList <- (%parse_VarName variable (space %parse_comma "," %parse_VarName variable)*)
		functionBody <- dataExpr
		aggrAgrList <- (%parse_TExpr "@TExpr" space %parse_exclamation "!" space %parse_Col "@Col")
		ZEROONE <- %parse_0 "0" / %parse_1 "1"
		
		fDataExpr <- (tableExprPlain? %parse_point "." valueExprPlain (%parse_tick "^^" xsdRef)?) -> {}
		
		classMap <- (((defName space %parse_equal "=") space
					 tableExprExtUri space
					 CDecoration*) /  (
					 tableExprExtUri space
					 CDecoration*)
					)
		
		defName <- %parse_VarName VarName
		tableExpr <- (tRefList (%parse_semicolon ";" space tFilterExpr? (%parse_semicolon ";" space  colDefList)?)?)
		uriPattern <- (%parse_braceOpen "{" %parse_uri "uri" %parse_equal "=" %parse_roundBracketOpen "("  valueExpr (%parse_comma "," space valueExpr)* %parse_roundBracketClose ")" %parse_braceClose "}")
		CDecoration <- (%parse_Out "?Out" / %parse_In "?In" / %parse_NoMap "!NoMap" / %parse_SubClean "!SubClean" / %parse_question "?")
		
		tRefList <- (tRefItem (%parse_comma "," space tRefItem )*)
		tFilterExpr <- (filterOrExpr (space %parse_or "or" space filterOrExpr)*)
		colDefList <- ((colDef (%parse_comma "," space colDef )*)?)
		valueExpr <- (simpleExpr (space infixOp space simpleExpr)*)
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
		
		tRefItem <- ((( tNavigItem space tRefItemL?) / tRefItemL) space tExprTopSpec?)
		filterOrExpr <- (filterAndExpr (space {%parse_and "and"} space filterAndExpr)*)
		colDef <- (%parse_VarName VarName space %parse_equal "=" space valueExpr)
		simpleExpr <- functionCall / aggregateCall / valueExprPlain / space prefixOp space simpleExpr 
		infixOp <- %parse_plus "+" / %parse_minus "-" / %parse_mul "*" / %parse_division "/" / %parse_div "div" / %parse_mod "mod"
		
		tNavigItem <- (tNavigItemBase (space %parse_colon ":" space tNavigFilter)*)
		tRefItemL <- (nLinkExpr (space  tNavigItem space tRefItemL?)?)
		tExprTopSpec <- tTopFilter
		filterAndExpr <- ((%parse_not "not"? space filterItem))
		valueExprPlain <- sqlExpr / constantExpr / colRef / %parse_variable variable / (%parse_roundBracketOpen "(" tFilterExpr %parse_roundBracketClose ")")
		constantExpr <- INT / STRING
		functionCall <- (%parse_fName fName space %parse_roundBracketOpen "(" valueList %parse_roundBracketClose ")")
		prefixOp <- %parse_minus "-"
		aggregateCall <- (( aggrFName space %parse_roundBracketOpen "(" dataExpr orderList? %parse_roundBracketClose ")") / aggregateWrk)
		
		tNavigItemBase <- (tableExprPlain space aliasDef?)
		tNavigFilter <- (tFilterExpr / tTopFilter)
		nLinkExpr <- ((%parse_squareBracketOpen "[" valueList %parse_squareBracketClose "]")? space (%parse_doubleArrow "=>" / %parse_arrow  "->") space (%parse_squareBracketOpen "[" valueList %parse_squareBracketClose "]")?)
		tTopFilter <- (%parse_braceOpen "{" (%parse_first "first" / %parse_top "top" space INT space %parse_persent "persent"?) space orderList? %parse_braceClose "}")
		orderList <- (%parse_by "by" orderSpec (%parse_comma "," orderSpec)*)
		filterItem <- unarybinaryFilterItem / constantFilterItem / existsFilterItem
		INT <- %parse_number [0-9]+
		STRING <- ((%parse_apostrophe "'" %parse_string ('"'/[^"'"])* %parse_apostrophe "'") / (%parse_quote '"' %parse_string ("'"/[^'"'])* %parse_quote '"'))
		colRef <-  compoundColRef / colName
		--variable <- (%parse_at "@" %parse_VarName VarName)
		variable <- ("@" %parse_VarName VarName)
		sqlExpr <- caseTwoOptions / caseManyOptions
		fName <- %parse_VarName VarName
		valueList <- (valueExpr (%parse_comma "," space valueExpr)*)
		aggrFName <- %parse_min "MIN" / %parse_max "MAX" / %parse_avg "AVG" / %parse_count "COUNT" / %parse_sum "SUM" / aggrUserFName
		dataExpr <- (tDataExpr / sDataExpr) 
		tDataExpr <- (%parse_squareBracketOpen "[" tableExprExtUri %parse_squareBracketPoint "]." simpleExpr (%parse_tick "^^" xsdRef)?)
		tableExprExtUri <- (tableExpr uriPattern?)
		sDataExpr <- (valueExpr (%parse_tick "^^" xsdRef)?) 
		xDataExpr <- (tableExpr %parse_exclamation "!" valueExpr)
		aggregateWrk <- (%parse_aggregate "@aggregate"  %parse_roundBracketOpen "(" xDataExpr %parse_comma "," valueExpr %parse_comma "," space valueExpr ("order" orderList)? %parse_roundBracketClose ")")
		
		tableExprPlain <- (simpleTableExpr / (%parse_roundBracketOpen "(" tableExprExt %parse_roundBracketClose ")"))
		aliasDef <- ClassMapRef / %parse_VarName VarName
		orderSpec <- (valueExpr space (%parse_asc "asc" / %parse_desc "desc")? space)
		unarybinaryFilterItem <- (valueExpr space((%parse_is "is" space %parse_not "not"? space %parse_null "null") / (binaryFilterOp space valueExpr ) / %parse_in2 "in" space %parse_roundBracketOpen "(" valueList %parse_roundBracketClose ")" / %parse_between "between" space simpleExpr space %parse_and "and" space simpleExpr ))
		constantFilterItem <- %parse_true "true" / %parse_false "false"
		existsFilterItem <- (%parse_exists "exists" space %parse_roundBracketOpen "(" tableExpr %parse_roundBracketClose ")")
		colName <- %parse_colName %parse_VarName VarName
		compoundColRef <- (tablePlusRefExpr %parse_point "." (colName / (%parse_roundBracketOpen "(" colRef %parse_roundBracketClose ")")))
		caseTwoOptions <- (%parse_case "case" space %parse_when "when" space tFilterExpr space %parse_then "then" space valueExpr space (%parse_else "else" space valueExpr space)? %parse_end "end")
		caseManyOptions <- (%parse_case "case" space valueExpr space (%parse_when "when" space valueExpr space %parse_then "then" space valueExpr)+ space (%parse_else "else" space valueExpr space)? %parse_end "end")
		aggrUserFName <- (%parse_VarName "@" %parse_VarName VarName)
		xsdRef <- ((XSD_TYPE_PREFIX)? %parse_VarName VarName)
		
		simpleTableExpr <- ClassMapRef / namedRef / tableUseExpr
		tableExprExt <- (tableExpr space (uriPattern / keyPattern)?)
		binaryFilterOp <- %parse_like "like" / %parse_in2 "in" / %parse_lessEqual "<=" / %parse_moreEqual ">=" / %parse_equal2 "<>" / %parse_equal "=" / %parse_less "<" / %parse_more ">"
		tablePlusRefExpr <- ClassMapRef / namedRef / tableRefExpr
		tableRefExpr <- ((%parse_dbAliasRefExpr dbAlias %parse_doubleColon "::")? %parse_TableNameRefExpr VarName)
		XSD_TYPE_PREFIX <- %parse_xsd "xsd:"
		--ClassMapRef <- %parse_s "<s>" / %parse_t "<t>" / %parse_b "<b>"
		ClassMapRef <- "<s>" / "<t>" / %parse_b "<b>"
		
		namedRef <- (%parse_twoSquareBracketOpen "[" "[" %parse_namedRef defName %parse_twoSquareBracketClose "]" "]")
		tableUseExpr <- ((%parse_dbAlias dbAlias %parse_doubleColon "::")? %parse_TableName %parse_VarName VarName)
		keyPattern <- (%parse_braceOpen "{" %parse_key "key" %parse_equal "=" %parse_roundBracketOpen "("  valueExpr (%parse_comma "," valueExpr)* %parse_roundBracketClose ")" %parse_braceClose "}")
		
		dbAlias <- %parse_VarName VarName
		space <- %parse_space (" " / %nl)*
	]]
	, {  
		parse_fail = function (subject, current_pos, captures) 
			return false 
		end,
		parse_variable = function (message, current_pos) parse_variable_function (message, current_pos) return current_pos end,
		parse_fName = function (message, current_pos) parse_fName_function (message, current_pos) return current_pos end,
		parse_aggrUserFName = function (message, current_pos) parse_aggrUserFName_function (message, current_pos) return current_pos end,
		parse_namedRef = function (message, current_pos) parse_namedRef_function(message, current_pos) return current_pos end,
		parse_TableName = function (message, current_pos)  parse_TableName_function(message, current_pos) return current_pos end,
		parse_TableNameRefExpr = function (message, current_pos)  parse_TableNameRefExpr_function(message, current_pos) return current_pos end,
		parse_dbAlias = function (message, current_pos) parse_dbAlias_function (message, current_pos) return current_pos end,
		parse_dbAliasRefExpr = function (message, current_pos) parse_dbAliasRefExpr_function (message, current_pos) return current_pos end,
		parse_colName = function (message, current_pos) parse_colName_function (message, current_pos) return current_pos end,
		parse_point = function (message, current_pos) add_error_message(errors, current_pos, ".", 30) return current_pos end,
		parse_Domain  = function (message, current_pos) add_error_message(errors, current_pos, "?Domain", 90) return current_pos end,
		parse_by = function (message, current_pos) add_error_message(errors, current_pos, "by", 60) return current_pos end,
		parse_Range  = function (message, current_pos) add_error_message(errors, current_pos, "?Range", 90) return current_pos end,
		parse_order = function (message, current_pos) add_error_message(errors, current_pos, "order", 90) return current_pos end,
		parse_semicolon  = function (message, current_pos) add_error_message(errors, current_pos, ";", 30) return current_pos end,
		parse_CMap  = function (message, current_pos) add_error_message(errors, current_pos, "CMap", 90) return current_pos end,
		parse_roundBracketOpen  = function (message, current_pos) add_error_message(errors, current_pos, "(", 30) return current_pos end,
		parse_roundBracketClose  = function (message, current_pos) add_error_message(errors, current_pos, ")", 30) return current_pos end,
		parse_DBRef  = function (message, current_pos) add_error_message(errors, current_pos, "DBRef", 90) return current_pos end,
		parse_comma  = function (message, current_pos) add_error_message(errors, current_pos, ",", 30) return current_pos end,
		parse_equal  = function (message, current_pos) add_error_message(errors, current_pos, "=", 50) return current_pos end,
		parse_dbname  = function (message, current_pos) add_error_message(errors, current_pos, 'dbname=', 90) return current_pos end,
		parse_VarName = function (message, current_pos) add_error_message(errors, current_pos, "", 100) return current_pos end,
		parse_alias  = function (message, current_pos) add_error_message(errors, current_pos, 'alias=', 90) return current_pos end,
		parse_schema  = function (message, current_pos) add_error_message(errors, current_pos, 'schema=', 90) return current_pos end,
		parse_public_table_prefix   = function (message, current_pos) add_error_message(errors, current_pos, 'public_table_prefix=', 90) return current_pos end,
		parse_jdbc_driver  = function (message, current_pos) add_error_message(errors, current_pos, 'jdbc_driver=', 90) return current_pos end,
		parse_connection_string  = function (message, current_pos) add_error_message(errors, current_pos, 'connection_string=', 90) return current_pos end,
		parse_aux  = function (message, current_pos) add_error_message(errors, current_pos, 'aux=', 90) return current_pos end,
		parse_default  = function (message, current_pos) add_error_message(errors, current_pos, 'default=', 90) return current_pos end,
		parse_init_script  = function (message, current_pos) add_error_message(errors, current_pos, 'init_script=', 90) return current_pos end,
		parse_TExpr  = function (message, current_pos) add_error_message(errors, current_pos, "@TExpr", 70) return current_pos end,
		parse_exclamation  = function (message, current_pos) add_error_message(errors, current_pos, "!", 70) return current_pos end,
		parse_Col  = function (message, current_pos) add_error_message(errors, current_pos, "@Col", 70) return current_pos end,
		parse_0  = function (message, current_pos) add_error_message(errors, current_pos, "0", 30) return current_pos end,
		parse_1  = function (message, current_pos) add_error_message(errors, current_pos, "1", 30) return current_pos end,
		parse_tick  = function (message, current_pos) add_error_message(errors, current_pos, "^^", 30) return current_pos end,
		parse_braceOpen  = function (message, current_pos) add_error_message(errors, current_pos, "{", 30) return current_pos end,
		parse_uri  = function (message, current_pos) add_error_message(errors, current_pos, "uri", 30) return current_pos end,
		parse_braceClose  = function (message, current_pos) add_error_message(errors, current_pos, "}", 30) return current_pos end,
		parse_Out  = function (message, current_pos) add_error_message(errors, current_pos, "?Out", 100) return current_pos end,
		parse_In = function (message, current_pos) add_error_message(errors, current_pos, "?In", 100) return current_pos end,
		parse_NoMap  = function (message, current_pos) add_error_message(errors, current_pos, "!NoMap", 100) return current_pos end,
		parse_SubClean  = function (message, current_pos) add_error_message(errors, current_pos, "!SubClean", 100) return current_pos end,
		parse_question  = function (message, current_pos) add_error_message(errors, current_pos, "?", 100) return current_pos end,
		parse_or  = function (message, current_pos) add_error_message(errors, current_pos, "or", 50) return current_pos end,
		parse_and  = function (message, current_pos) add_error_message(errors, current_pos, "and", 50) return current_pos end,
		parse_plus  = function (message, current_pos) add_error_message(errors, current_pos, "+", 50) return current_pos end,
		parse_minus = function (message, current_pos) add_error_message(errors, current_pos, "-", 50) return current_pos end,
		parse_mul  = function (message, current_pos) add_error_message(errors, current_pos, "*", 50) return current_pos end,
		parse_division  = function (message, current_pos) add_error_message(errors, current_pos, "/", 50) return current_pos end,
		parse_div  = function (message, current_pos) add_error_message(errors, current_pos, "div", 50) return current_pos end,
		parse_mod  = function (message, current_pos) add_error_message(errors, current_pos, "mod", 50) return current_pos end,
		parse_colon  = function (message, current_pos) add_error_message(errors, current_pos, ":", 50) return current_pos end,
		parse_not  = function (message, current_pos) add_error_message(errors, current_pos, "not", 30) return current_pos end,
		parse_gridOpen  = function (message, current_pos) add_error_message(errors, current_pos, "(.", 30) return current_pos end,
		parse_gridClose  = function (message, current_pos) add_error_message(errors, current_pos, ".)", 30) return current_pos end,
		parse_squareBracketOpen  = function (message, current_pos) add_error_message(errors, current_pos, "[", 30) return current_pos end,
		parse_squareBracketClose   = function (message, current_pos) add_error_message(errors, current_pos, "]", 30) return current_pos end,
		parse_arrow   = function (message, current_pos) add_error_message(errors, current_pos, "->", 30) return current_pos end,
		parse_doubleArrow   = function (message, current_pos) add_error_message(errors, current_pos, "=>", 30) return current_pos end,
		parse_first   = function (message, current_pos) add_error_message(errors, current_pos, "first", 30) return current_pos end,
		parse_top   = function (message, current_pos) add_error_message(errors, current_pos, "top", 30) return current_pos end,
		parse_persent   = function (message, current_pos) add_error_message(errors, current_pos, "persent", 30) return current_pos end,
		parse_number  = function (message, current_pos) add_error_message(errors, current_pos, "", 50) return current_pos end,
		parse_apostrophe   = function (message, current_pos) add_error_message(errors, current_pos, "'", 50) return current_pos end,
		parse_string  = function (message, current_pos) add_error_message(errors, current_pos, "", 100) return current_pos end,
		parse_quote   = function (message, current_pos) add_error_message(errors, current_pos, '"', 50) return current_pos end,
		parse_at   = function (message, current_pos) add_error_message(errors, current_pos, "@", 70) return current_pos end,
		parse_min   = function (message, current_pos) add_error_message(errors, current_pos, "MIN", 70) return current_pos end,
		parse_max   = function (message, current_pos) add_error_message(errors, current_pos, "MAX", 70) return current_pos end,
		parse_avg   = function (message, current_pos) add_error_message(errors, current_pos, "AVG", 70) return current_pos end,
		parse_count   = function (message, current_pos) add_error_message(errors, current_pos, "COUNT", 70) return current_pos end,
		parse_sum   = function (message, current_pos) add_error_message(errors, current_pos, "SUM", 70) return current_pos end,
		parse_squareBracketPoint   = function (message, current_pos) add_error_message(errors, current_pos, "].", 30) return current_pos end,
		parse_aggregate   = function (message, current_pos) add_error_message(errors, current_pos, "@aggregate", 70) return current_pos end,
		parse_exclamation   = function (message, current_pos) add_error_message(errors, current_pos, "!", 60) return current_pos end,
		parse_asc   = function (message, current_pos) add_error_message(errors, current_pos, "asc", 60) return current_pos end,
		parse_desc   = function (message, current_pos) add_error_message(errors, current_pos, "desc", 60) return current_pos end,
		parse_is   = function (message, current_pos) add_error_message(errors, current_pos, "is", 60) return current_pos end,
		parse_null   = function (message, current_pos) add_error_message(errors, current_pos, "null", 60) return current_pos end,
		parse_between   = function (message, current_pos) add_error_message(errors, current_pos, "between", 60) return current_pos end,
		parse_true   = function (message, current_pos) add_error_message(errors, current_pos, "true", 60) return current_pos end,
		parse_false   = function (message, current_pos) add_error_message(errors, current_pos, "false", 60) return current_pos end,
		parse_exists   = function (message, current_pos) add_error_message(errors, current_pos, "exists", 60) return current_pos end,
		parse_case   = function (message, current_pos) add_error_message(errors, current_pos, "case", 60) return current_pos end,
		parse_when   = function (message, current_pos) add_error_message(errors, current_pos, "when", 60) return current_pos end,
		parse_then   = function (message, current_pos) add_error_message(errors, current_pos, "then", 60) return current_pos end,
		parse_else   = function (message, current_pos) add_error_message(errors, current_pos, "else", 60) return current_pos end,
		parse_end   = function (message, current_pos) add_error_message(errors, current_pos, "end", 60) return current_pos end,
		parse_less   = function (message, current_pos) add_error_message(errors, current_pos, "<", 60) return current_pos end,
		parse_more   = function (message, current_pos) add_error_message(errors, current_pos, ">", 60) return current_pos end,
		parse_lessEqual   = function (message, current_pos) add_error_message(errors, current_pos, "<=", 60) return current_pos end,
		parse_moreEqual   = function (message, current_pos) add_error_message(errors, current_pos, ">=", 60) return current_pos end,
		parse_equal2   = function (message, current_pos) add_error_message(errors, current_pos, "<>", 60) return current_pos end,
		parse_like   = function (message, current_pos) add_error_message(errors, current_pos, "like", 60) return current_pos end,
		parse_in2   = function (message, current_pos) add_error_message(errors, current_pos, "in", 60) return current_pos end,
		parse_xsd   = function (message, current_pos) add_error_message(errors, current_pos, "xsd:", 30) return current_pos end,	  
		parse_s  = function (message, current_pos) add_error_message(errors, current_pos, "<s>", 23) return current_pos end,
		parse_t  = function (message, current_pos) add_error_message(errors, current_pos, "<t>", 23) return current_pos end,
		parse_b  = function (message, current_pos) parse_b_function (message, current_pos) return current_pos end,
		parse_twoSquareBracketOpen   = function (message, current_pos) add_error_message(errors, current_pos, "[[", 30) return current_pos end,
		parse_twoSquareBracketClose  = function (message, current_pos) add_error_message(errors, current_pos, "]]", 30) return current_pos end,
		parse_doubleColon   = function (message, current_pos) add_error_message(errors, current_pos, "::", 30) return current_pos end,
		parse_key   = function (message, current_pos) add_error_message(errors, current_pos, "key", 30) return current_pos end,
		parse_space   = function (message, current_pos) add_error_message(errors, current_pos, " ", 100) return current_pos end,
	  }
	)
	local res = match_err(grammar, text)
end

function getTextMultiLine()
	local text = lQuery("Event/edited"):attr("text")
	if lQuery("Event/edited"):is_empty() then 
		text = lQuery("Event/inserted"):attr("text")
		if lQuery("Event/inserted"):is_empty() then
			text = ""
		end
	end
	return text, lengh
end

function getText()
	lQuery("Event/source"):log("id")
	--local text = lQuery("Event"):last():find("/source"):attr("text")
	--local text = lQuery("Event"):first():find("/source"):attr("text")
	local text = lQuery("Event/source"):attr("text")
	local lengh = tonumber(GetCursorPosition())
	if lengh==0 and string.len(text)>0 then lengh=string.len(text) end
	local line = nil
	local comma = string.find(GetCursorPosition(), ",")
	if comma~=nil then 
		line = string.sub(GetCursorPosition(), comma+1)
		lengh = tonumber(string.sub(GetCursorPosition(), 1, comma-1))
	end
	if line==nil then 
		text = string.sub(text, 1, lengh)
	else
		if string.find(text, "\n") == nil then
			lengh = string.len(text)
		elseif line == "0" then
			text = string.sub(text, 1, lengh)
		else
			local newLineCount = 0
			local textLength = 0
			local text2 = text
			while newLineCount~= tonumber(line) do
				textLength = textLength + string.find(text, "\n")
				text2 = string.sub(text2, string.find(text, "\n")+1)
				newLineCount = newLineCount + 1
			end
			textLength = textLength + lengh
			text = string.sub(text, 1, textLength)
			lengh = textLength
		end
	end
	return text, lengh
end

function getRDB2OWLclassMapMultiLineButton()
	local text = getTextMultiLine()
	rdbtoowl(text)
end

function getRDB2OWLdataMapMultiLineButton()
	local text = getTextMultiLine()
	rdbtoowlDataMap(text)
end

function getRDB2OWLobjectMapMultiLineButton()
	local text = getTextMultiLine()
	rdbtoowlObjectMap(text)
end

function getRDB2OWLclassMap()
	local text = getText()
	rdbtoowl(text)
end

function getRDB2OWLdataMap()
	local text = getText()
	rdbtoowlDataMap(text)
end

function getRDB2OWLobjectMap()
	local text = getText()
	rdbtoowlObjectMap(text)
end

function getRDB2OWLontologyDBExpr()
	local element = utilities.active_elements()
	if element:find("/compartment:has(/compartType[id='AnnotationType'])"):attr("value") == "DBExpr" then 
		local text = lQuery("Event"):last():find("/source"):attr("text")
		if text~=nil then rdbtoowlOntologyDBExpr(text) end
	end
end

--atjauno formu
function refreshForm(var, len)
  if lQuery("Event/edited"):is_not_empty() then 
	lQuery("Event/edited"):attr("text", var)
	lQuery("Event/edited/multiLineTextBox"):link("command", utilities.execute_cmd("D#Command", {info = "Refresh"}))
  elseif lQuery("Event/inserted"):is_not_empty() then 
	lQuery("Event/inserted"):attr("text", var)
	lQuery("Event/inserted/multiLineTextBox"):link("command", utilities.execute_cmd("D#Command", {info = "Refresh"}))
  else
	lQuery("D#Event"):find("/source"):attr("text", var)
	local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				lQuery("D#Event/source"):link("command", cmd)
				utilities.execute_cmd_obj(cmd)
	
	--lQuery("Event/source"):attr("text", var)
	--lQuery("Event/source"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
  end
  local cmd = utilities.create_command("D#MoveTextCursorCommand", {horizontalPosition = len})
   lQuery("D#Event/source"):link("command", cmd)
   utilities.execute_cmd_obj(cmd)
end

function match_err(grammar, text)
	errors = {} 
	return re.match(text, grammar) or displayEndings(text, errors)
end

--pievieno turpinajumu tabulai
function add_error_message(errors, pos, message, priority)
	local current_list = errors[pos] or {} -- current list of error messages at the given possition
	current_list[message]=priority
	errors[pos] = current_list
end

--atrod kursira poziciju
function GetCursorPosition()
  local position = lQuery("D#Event"):last():attr("info")
  return position
end

function removeUnnecessaryMessages(TermMessages)

	local endings = {}
	for pos, message in pairs(TermMessages) do
		if message~="" then
			table.insert(endings, message)
		end
	end
	return endings
end

function displayEndings(str, errors)
	-- print("{")
	-- for pos, messages in pairs(errors) do
		-- print('  ["' .. pos .. '"] = {')
		-- for pos2, message in pairs(messages) do
			-- print('    ["' .. pos2 .. '"] = ' .. message .. ",")
		-- end
		-- print("  },")
	-- end
	-- print("}")
	local changeCursore = false
	if lQuery("D#Event"):attr("eventName")=="MultiLineTextBoxChange" or (lQuery("D#Event"):attr("eventName")=="Change")  then
		if (GetCursorPosition()=="0" and lQuery("D#Event"):size()==1) then 
		else
			local line = nil
			local comma = string.find(GetCursorPosition(), ",")
			if comma~=nil then 
				line = string.sub(GetCursorPosition(), comma+1)
				-- lengh = tonumber(string.sub(GetCursorPosition(), 1, comma-1))
			end
			 local text = lQuery("Event/source"):attr("text")
			if lQuery("D#Event"):attr("eventName")=="MultiLineTextBoxChange" then
				text = str
			end
			local a, lengh = getText()

			---------------------------------
			local endings, ending_type, position = create_error_message2(str, errors, text, lengh)
			
			if ending_type == "terminal" then 
				local com
				--piedavajam logu ar iespejamiem turpinajumiem
					
				if lQuery("Event/source"):attr("outlineColor") == "255" then
					lQuery("Event/source"):attr({outlineColor = 536870911, hint = ""})
					local cmd = utilities.create_command("D#Command", {info = "Refresh"})
					lQuery("Event/source"):link("command", cmd)
					utilities.execute_cmd_obj(cmd)
						
					local cmd2 = utilities.create_command("D#MoveTextCursorCommand", {horizontalPosition = lengh})
					lQuery("Event/source"):link("command", cmd2)
					utilities.execute_cmd_obj(cmd2)
				end

				com = tda.ShowAutoCompletionOptions(endings)
				--ja tika izvelets turpinajums
				if com ~= nil then
					local beforCursor = string.sub(text, 1, lengh-position)
					local afterCursor = string.sub(text, lengh+1)
					local main = beforCursor .. endings[com+1] .. afterCursor
						
					refreshForm(main, string.len(beforCursor .. endings[com+1]))--atjaunojam formu
					changeCursore = true
				end
				return
			elseif ending_type == "error" then
				lQuery("Event/source"):attr({outlineColor = 255, hint = ""})
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				lQuery("Event/source"):link("command", cmd)
				utilities.execute_cmd_obj(cmd)
					
				local cmd2 = utilities.create_command("D#MoveTextCursorCommand", {horizontalPosition = lengh})
				lQuery("Event/source"):link("command", cmd2)
				utilities.execute_cmd_obj(cmd2)
				
				print( "ERROR: in a possotion " .. position .. ", possible follows are \n" .. table.concat(endings, "\n "))
				return
			elseif ending_type == "all_symbol" then
				--ja visa padota virkne tika izieta lidz kursora pozicijai
			
				local beforCursor
				local afterCursor
				local subString
				local subStringLength
				if position~=-1 then 
					subString = string.sub(text, position)
					subStringLength = string.len(subString)
					local label = 0
					for pos, messages in pairs(endings) do
						if string.sub(messages, 1, subStringLength)==subString then label = 1 end
					end
					if label == 1 then
						beforCursor = string.sub(text, 1, position-1)
						afterCursor = string.sub(text, lengh+1)
					else
						beforCursor = string.sub(text, 1, lengh)
						afterCursor = string.sub(text, lengh+1)
					end
				else
					beforCursor = string.sub(text, 1, lengh)
					afterCursor = string.sub(text, lengh+1)
				end
				
				local com

				if lQuery("Event/source"):attr("outlineColor") == "255" then
					lQuery("Event/source"):attr({outlineColor = 536870911, hint = ""})
					local cmd = utilities.create_command("D#Command", {info = "Refresh"})
					lQuery("Event/source"):link("command", cmd)
					utilities.execute_cmd_obj(cmd)
							
					local cmd2 = utilities.create_command("D#MoveTextCursorCommand", {horizontalPosition = lengh})
					lQuery("Event/source"):link("command", cmd2)
					utilities.execute_cmd_obj(cmd2)
				end
				--piedavajam logu ar iespejamiem turpinajumiem
				com = tda.ShowAutoCompletionOptions(endings)
				--ja tika izvelets turpinajums
				if com ~= nil then
					if string.sub(endings[com+1], 1, subStringLength)~=subString then 
						beforCursor = string.sub(text, 1, lengh)
						afterCursor = string.sub(text, lengh+1)
					end

					local main = beforCursor .. endings[com+1] .. afterCursor
					
					local newLineCount = 0
					if line~=nil and line~="0" and string.find(text, "\n")~=nil then
						
						local text2 = main
						while newLineCount~= tonumber(line) do
							text2 = string.sub(text2, string.find(text, "\n")+1)
							newLineCount = newLineCount + 1
						end
						main = text2
					end
					
					refreshForm(main, string.len(beforCursor .. endings[com+1]))--atjaunojam formu
					changeCursore = true
				end
			end
		end
	end
--	if changeCursore == true then
		local len = string.len(str)
		local cmd = utilities.create_command("D#MoveTextCursorCommand", {horizontalPosition = len})
		lQuery("D#Event/source"):link("command", cmd)
		utilities.execute_cmd_obj(cmd)
--	end
end

function create_error_message2(str, errors, text, lengh)

			local farthest_pos = -1--talaka pozicija
			local farthest_pos_prev = -1--iepriekstalaka pozicija (izmanto, ja tika rakstits nosaukuma sakums)
			local messages_to_report = {}
			
			--atrodam talako poziciju, kas ir ierakstita error tabulaa
			for pos, messages in pairs(errors) do
				if pos > farthest_pos then
					farthest_pos = pos
					messages_to_report = messages--turpinajumi, kas ir tekosajaa pozicijaa
				end
			end
			
			--atrod iepriekspedejo poziciju, kur bija cits neterminalis
			for pos, messages in pairs(errors) do	
				if (pos > farthest_pos_prev and farthest_pos_prev ~= farthest_pos and pos < farthest_pos) then
					farthest_pos_prev = pos
				end
			end
			
			local sakritibas = 0
			if farthest_pos_prev ~= -1 then
				for i=farthest_pos,1,-1 do 
					if errors[i]~=nil then
						for pos, message in pairs (errors[i]) do
							--ja sakumi sakrit un nesarkit viss vards
							local varrible = string.sub(text, i, farthest_pos-1)
							if lpeg.match(varrible, pos) and varrible ~= pos then 
								messages_to_report[pos] = message
								sakritibas = 1
							end
						end
					end
				end
			end
			 
			local TermMessages = {}--turpinajumi, ja sakam rakstit terminali
			--ja ir kluda, vai rakstas terminalis
			if lengh>=farthest_pos then 
				--nemam mainigo no kludas vietas lidz beigam
				local er = string.sub(text, farthest_pos, lengh)--!!!!!!!!!!!!!!!!!!
				local er_lenght = string.len(er)
				er = lpeg.P(er)
				
				local tb = {}
				--parbaudam, vai ir saderibas iespejamo turpinajumu tabulaa
				for pos, message in pairs (messages_to_report) do
					--if lpeg.match(er, pos) then table.insert (TermMessages, pos)  end
					if lpeg.match(er, pos) then tb[pos]=message end
				end
				TermMessages = getCompletionTable(tb)
				if TermMessages[1] ~= nil then
					return removeUnnecessaryMessages(TermMessages), "terminal", er_lenght
					--ja nebija sakritibu iespejamo turpinajumu tabulaa, tad ir kluda
				else
					local uniqueMessages = getCompletionTable(messages_to_report)
				
					--print( "ERROR: in a possotion " .. farthest_pos .. ", possible follows are \n" .. table.concat(uniqueMessages, "\n "))
					return uniqueMessages, "error", farthest_pos
				end
			end
			
			local uniqueMessages = getCompletionTable(messages_to_report)

			--ja visa padota virkne tika izieta lidz kursora pozicijai
			return removeUnnecessaryMessages(uniqueMessages), "all_symbol", farthest_pos_prev
end

function getCompletionTable(messages_to_report)
	local messages_to_report2= {}
	for pos, messages in pairs(messages_to_report) do
		table.insert(messages_to_report2, {pos, messages})
	end
	table.sort(messages_to_report2, function(x,y) return x[2] < y[2] end)
	uniqueMessages = {}
	for pos, message in pairs (messages_to_report2) do
	  table.insert(uniqueMessages, message[1])
	end
	return uniqueMessages
end

-- Count the number of times a value occurs in a table 
function table_count(tt, item)
  local count
  count = 0
  for ii,xx in pairs(tt) do
    if item == xx then count = count + 1 end
  end
  return count
end

function table_unique(tt)
	local newtable = {}
	for ii,xx in ipairs(tt) do
		if table_count(newtable, xx) == 0 then
			newtable[#newtable+1] = xx
		end
	end
	return newtable
end

function get_tab_name()
	local ev = lQuery("D#Event")
	local compart_type = ev:find("/source/container/propertyElement/propertyDiagram/compartType")
	local prop_diagram = get_first_property_diagram(compart_type)
	local form = prop_diagram:find("/component")
	local tab_name = form:find("/component.D#TabContainer/activeTab")
	return tab_name
end

function get_first_property_diagram(compart_type)
	local prop_row = compart_type:find("/propertyRow")
	local prop_diagram = prop_row:find("/propertyDiagram")
	if prop_diagram:is_empty() then
		prop_diagram = prop_row:find("/propertyTab/propertyDiagram")
	end
	local new_compart_type = prop_diagram:find("/compartType")
	if new_compart_type:is_empty() then
		return prop_diagram
	else
	return get_first_property_diagram(new_compart_type)
	end
end

function generateDatabaseInstances()
	local diagram = utilities.current_diagram()
	local anotations = diagram:find("/element:has(/elemType[id='Annotation'])")
	local dataTable = {}
	anotations:each(function(anotation)
		local value = anotation:find("/compartment/subCompartment:has(/compartType[id='Value'])"):attr("value")
		local grammar = rdbtoowlDatabase()
		local data = re.match(value, grammar)
		if data then 
			for i, k in pairs(data) do
				if k["dbname"]~= nil then 
					dataTable[k["dbname"]]=1
					--veidot, ja vel nav
					if lQuery("RR#Database[dbName='" .. k["dbname"] .. "']"):is_empty() then
						lQuery.create("RR#Database", {dbName=k["dbname"], jdbcDriver=k["jdbc_driver"], connection=k["connection_string"], schema=k["schema"], publicTablePrefix=k["public_table_prefix"], isDefaultDB=k["default"], dbAlias=k["alias"]})
					--citadi atjaunot informaciju
					else
						lQuery("RR#Database[dbName='" .. k["dbname"] .. "']"):attr("jdbcDriver", k["jdbc_driver"])
						lQuery("RR#Database[dbName='" .. k["dbname"] .. "']"):attr("connection", k["connection_string"])
						lQuery("RR#Database[dbName='" .. k["dbname"] .. "']"):attr("schema", k["schema"])
						lQuery("RR#Database[dbName='" .. k["dbname"] .. "']"):attr("publicTablePrefix", k["public_table_prefix"])
						lQuery("RR#Database[dbName='" .. k["dbname"] .. "']"):attr("isDefaultDB", k["default"])
						lQuery("RR#Database[dbName='" .. k["dbname"] .. "']"):attr("dbAlias", k["alias"])
					end
					local path

					if tda.isWeb then 
						path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "RDB2OWL") .. "/"
					else
						path = tda.GetProjectPath() .. "\\Plugins\\RDB2OWL\\"
					end
					assert(loadfile(path .. 'generate_and_run_load_db_schema.lua'))(k["dbname"], tda.GetProjectPath(), "RR#")
				end
			end
			--lQuery.create("RR#Database", {dbName=data["dbname"], jdbcDriver=data["jdbc_driver"], connection=data["connection_string"], schema=data["schema"], publicTablePrefix=data["public_table_prefix"], isDefaultDB=data["default"], dbAlias=data["alias"]})
		end
	end)
	--izdzest datubazes, kuriem nav anotaciju
	lQuery("RR#Database"):each(function(db)
		if dataTable[db:attr("dbName")]~=1 then 
			deleteDatabase(db)
		end
	end)
	--showMesageLogDatabeseInstance()
end

function deleteDatabase(database)
	database:find("/table/column"):delete()
	database:find("/table/column/pKey"):delete()
	database:find("/table/column/fKey"):delete()
	database:find("/table/pKey"):delete()
	database:find("/table/fKey"):delete()
	database:find("/table/view"):delete()
	database:find("/table"):delete()
	database:find("/DBFunction"):delete()
	database:delete()
end

function showMesageLogDatabeseInstance()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.RDB2OWL.reGrammar.close()")
  })

  local form = lQuery.create("D#Form", {
    id = "reGrammar"
    ,caption = "MsgBox"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.RDB2OWL.reGrammar.close()")
	,component = {
		lQuery.create("D#VerticalBox", {
			horizontalAlignment = -1
			--,minimumWidth = 800
			,component = { 
				lQuery.create("D#Label", { caption = "Database connection information refreshed."}) 
				,lQuery.create("D#Label", { caption = "To load/refresh database table and column information, close the project (exit OWLGrEd) and"}) 
				,lQuery.create("D#Label", { caption = "run file 'run_form.bat' from project's plugin RDB2OWL folder."}) 
			}
		})
		,close_button
    }
  })
  dialog_utilities.show_form(form)
end

function close()
  lQuery("D#Event"):delete()
  utilities.close_form("reGrammar")
end

function rdbtoowlDatabase(text)
	--  -> {}
	return re.compile([[
		gMain <- (space ontologyDBExpr !.)
		
		ontologyDBExpr <- ((ontDBExprItem (";" space ontDBExprItem)*)?)-> {}
		
		ontDBExprItem <- (funDefPlus / ("CMap" "(" classMap ")") / dbSpec)
		
		funDefPlus <- functionDef / aggrFDef
		dbSpec <- ("DBRef" "(" dbOptionSpec (space "," space dbOptionSpec)* ")") -> {}
		
		functionDef <- (fName "(" varList  ")" space  "=" space functionBody)
		aggrFDef <- (aggrUserFName  "(" aggrAgrList?  ")" space  "=" space functionBody)
		dbOptionSpec <-(( 'dbname='  {:dbname: VarName :}) / ( 'alias='  {:alias: VarName :}) / ( 'schema=' {:schema: STRING :}) / 
						(  'public_table_prefix=' {:public_table_prefix: STRING :}) /
						( 'jdbc_driver=' {:jdbc_driver: STRING :}) / ( 'connection_string=' {:connection_string: STRING :}) / ( 'aux=' {:aux: INT :}) / 
						( 'default=' {:default: INT :}) / ( 'init_script=' {:init_script: STRING :}) )
		
		varList <- ( variable (space  ","  variable)*)
		functionBody <- dataExpr
		aggrAgrList <- ( "@TExpr" space  "!" space  "@Col")
		ZEROONE <-  "0" /  "1"
		
		fDataExpr <- (tableExprPlain?  "." valueExprPlain ( "^^" xsdRef)?)
		
		
		classMap <- (((defName space "=") space tableExprExtUri space CDecoration*) /  (tableExprExtUri space CDecoration*))
		tableExpr <- tRefList (";" space tFilterExpr? (";" space colDefList)?)?
		uriPattern <- "{" "uri" "=" "(" valueExpr ("," space valueExpr)* ")" "}"
		CDecoration <- "?Out" / "?In" / "!NoMap" / "!SubClean" / "?"
		
		tRefList <- (tRefItem ("," space tRefItem )*)
		tFilterExpr <- filterOrExpr (space "or" space filterOrExpr)*
		colDefList <- (colDef ("," space colDef )*)?
		valueExpr <- simpleExpr (space infixOp space simpleExpr)*
		VarName <- {([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*}
		
		tRefItem <- (((tNavigItem space tRefItemL?) / tRefItemL ) space  tExprTopSpec?)
		filterOrExpr <- (filterAndExpr (space "and" space filterAndExpr)*)
		colDef <- (VarName space "=" space valueExpr)
		simpleExpr <- functionCall / aggregateCall / valueExprPlain / space prefixOp space simpleExpr 
		infixOp <- "+" / "-" / "*" / "/" / "div" / "mod"
		
		tNavigItem <- (tNavigItemBase  (space ":" space tNavigFilter)*)
		tRefItemL <- (nLinkExpr (space tNavigItem space tRefItemL?)?)
		tExprTopSpec <- tTopFilter
		filterAndExpr <- (("not"? space filterItem))
		valueExprPlain <- sqlExpr / constantExpr / colRef / variable / ("(" tFilterExpr ")")
		constantExpr <- INT / STRING
		functionCall <- (fName space "(" valueList ")")
		prefixOp <- "-"
		aggregateCall <- (( aggrFName space "(" dataExpr orderList? ")") / aggregateWrk)
		
		tNavigItemBase <- (tableExprPlain space aliasDef?)
		tNavigFilter <- (tFilterExpr / tTopFilter)
		nLinkExpr <- (("[" valueList "]")? space ("=>" / "->") space ("[" valueList "]")?)
		tTopFilter <- ("{" ("first" / "top" space INT space "persent"?) space orderList? "}")
		orderList <- ("by" orderSpec ("," orderSpec)*)
		filterItem <- unarybinaryFilterItem / constantFilterItem / existsFilterItem
		INT <- [0-9]+
		STRING <- (("'" {('"'/[^"'"])*} "'") / ('"' {("'"/[^'"'])*} '"'))
		colRef <-  compoundColRef / colName
		variable <- ("@" VarName)
		sqlExpr <- caseTwoOptions / caseManyOptions
		fName <-  VarName
		valueList <- (valueExpr ("," space valueExpr)*)
		aggrFName <- "MIN" / "MAX" / "AVG" / "COUNT" / "SUM" / aggrUserFName
		dataExpr <- (tDataExpr / sDataExpr)
		tDataExpr <- ("[" tableExprExtUri "]." simpleExpr ("^^" xsdRef)?)
		tableExprExtUri <- (tableExpr uriPattern?)
		
		sDataExpr <- (valueExpr( "^^" xsdRef)?)	
		xDataExpr <- (tableExpr "!" valueExpr)
		aggregateWrk <- ("@aggregate"  "(" xDataExpr "," valueExpr "," space valueExpr ("order" orderList)? ")")
		
		tableExprPlain <- (simpleTableExpr / ("(" tableExprExt ")"))
		aliasDef <- ClassMapRef / VarName
		orderSpec <- (valueExpr space ("asc" / "desc")? space)
		unarybinaryFilterItem <- (valueExpr space(("is" space "not"? space "null") / (binaryFilterOp space valueExpr ) / "in" space "(" valueList ")" / "between" space simpleExpr space "and" space simpleExpr ))
		constantFilterItem <- "true" / "false"
		existsFilterItem <- ("exists" space "(" tableExpr ")")
		colName <- VarName
		compoundColRef <- (tablePlusRefExpr "." (colName / ("(" colRef ")")))
		caseTwoOptions <- ("case" space "when" space tFilterExpr space "then" space valueExpr space ("else" space valueExpr space)? "end")
		caseManyOptions <- ("case" space valueExpr space ("when" space valueExpr space "then" space valueExpr)+ space ("else" space valueExpr space)? "end")
		aggrUserFName <- ("@" VarName)
		xsdRef <- ((XSD_TYPE_PREFIX)? VarName)
		
		simpleTableExpr <- ClassMapRef / namedRef / tableUseExpr
		tableExprExt <- (tableExpr space (uriPattern / keyPattern)?) 
		binaryFilterOp <- "like" / "in" / "<=" / ">=" / "<>" / "=" / "<" / ">"
		tablePlusRefExpr <- ClassMapRef / namedRef / tableRefExpr
		tableRefExpr <- ((dbAlias "::")? VarName)
		XSD_TYPE_PREFIX <- "xsd:"
		ClassMapRef <- "<s>" / "<t>" / "<b>"
		
		namedRef <- ("[" "[" defName "]" "]")
		tableUseExpr <- (dbAlias "::")? VarName
		keyPattern <- ("{" "key" "=" "(" valueExpr ("," valueExpr)* ")" "}")
		HEX_DIGIT <- [0-9] / [A-F] / [a-f]
		defName <- VarName
		dbAlias <- VarName
		space <- (" " / %nl)*
	]])
end

function rdbtoowlDatabaseCMap(text)
	--  -> {}
	return re.compile([[
		gMain <- (space ontologyDBExpr !.)
		
		ontologyDBExpr <- ((ontDBExprItem (";" space ontDBExprItem)*)?)-> {}
		
		ontDBExprItem <- (funDefPlus / ("CMap" "(" classMap ")") / dbSpec)
		
		funDefPlus <- functionDef / aggrFDef
		dbSpec <- ("DBRef" "(" dbOptionSpec (space "," space dbOptionSpec)* ")") 
		
		functionDef <- (fName "(" varList  ")" space  "=" space functionBody)
		aggrFDef <- (aggrUserFName  "(" aggrAgrList?  ")" space  "=" space functionBody)
		dbOptionSpec <-(( 'dbname='  VarName ) / ( 'alias='  VarName ) / ( 'schema=' STRING ) / 
						(  'public_table_prefix='  STRING ) /
						( 'jdbc_driver=' STRING) / ( 'connection_string='  STRING ) / ( 'aux=' INT ) / 
						( 'default=' INT ) / ( 'init_script=' STRING))
		
		varList <- ( variable (space  ","  variable)*)
		functionBody <- dataExpr
		aggrAgrList <- ( "@TExpr" space  "!" space  "@Col")
		ZEROONE <-  "0" /  "1"
		
		fDataExpr <- (tableExprPlain?  "." valueExprPlain ( "^^" xsdRef)?)
		
		
		classMap <- ((({defName} space "=") space tableExprExtUri space CDecoration*) /  (tableExprExtUri space CDecoration*))
		tableExpr <- tRefList (";" space tFilterExpr? (";" space colDefList)?)?
		uriPattern <- "{" "uri" "=" "(" valueExpr ("," space valueExpr)* ")" "}"
		CDecoration <- "?Out" / "?In" / "!NoMap" / "!SubClean" / "?"
		
		tRefList <- (tRefItem ("," space tRefItem )*)
		tFilterExpr <- filterOrExpr (space "or" space filterOrExpr)*
		colDefList <- (colDef ("," space colDef )*)?
		valueExpr <- simpleExpr (space infixOp space simpleExpr)*
		VarName <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
		
		tRefItem <- (((tNavigItem space tRefItemL?) / tRefItemL ) space  tExprTopSpec?)
		filterOrExpr <- (filterAndExpr (space "and" space filterAndExpr)*)
		colDef <- (VarName space "=" space valueExpr)
		simpleExpr <- functionCall / aggregateCall / valueExprPlain / space prefixOp space simpleExpr 
		infixOp <- "+" / "-" / "*" / "/" / "div" / "mod"
		
		tNavigItem <- (tNavigItemBase  (space ":" space tNavigFilter)*)
		tRefItemL <- (nLinkExpr (space tNavigItem space tRefItemL?)?)
		tExprTopSpec <- tTopFilter
		filterAndExpr <- (("not"? space filterItem))
		valueExprPlain <- sqlExpr / constantExpr / colRef / variable / ("(" tFilterExpr ")")
		constantExpr <- INT / STRING
		functionCall <- (fName space "(" valueList ")")
		prefixOp <- "-"
		aggregateCall <- (( aggrFName space "(" dataExpr orderList? ")") / aggregateWrk)
		
		tNavigItemBase <- (tableExprPlain space aliasDef?)
		tNavigFilter <- (tFilterExpr / tTopFilter)
		nLinkExpr <- (("[" valueList "]")? space ("=>" / "->") space ("[" valueList "]")?)
		tTopFilter <- ("{" ("first" / "top" space INT space "persent"?) space orderList? "}")
		orderList <- ("by" orderSpec ("," orderSpec)*)
		filterItem <- unarybinaryFilterItem / constantFilterItem / existsFilterItem
		INT <- [0-9]+
		STRING <- (("'" ('"'/[^"'"])* "'") / ('"' ("'"/[^'"'])* '"'))
		colRef <-  compoundColRef / colName
		variable <- ("@" VarName)
		sqlExpr <- caseTwoOptions / caseManyOptions
		fName <-  VarName
		valueList <- (valueExpr ("," space valueExpr)*)
		aggrFName <- "MIN" / "MAX" / "AVG" / "COUNT" / "SUM" / aggrUserFName
		dataExpr <- (tDataExpr / sDataExpr)
		tDataExpr <- ("[" tableExprExtUri "]." simpleExpr ("^^" xsdRef)?)
		tableExprExtUri <- (tableExpr uriPattern?)
		
		sDataExpr <- (valueExpr( "^^" xsdRef)?)	
		xDataExpr <- (tableExpr "!" valueExpr)
		aggregateWrk <- ("@aggregate"  "(" xDataExpr "," valueExpr "," space valueExpr ("order" orderList)? ")")
		
		tableExprPlain <- (simpleTableExpr / ("(" tableExprExt ")"))
		aliasDef <- ClassMapRef / VarName
		orderSpec <- (valueExpr space ("asc" / "desc")? space)
		unarybinaryFilterItem <- (valueExpr space(("is" space "not"? space "null") / (binaryFilterOp space valueExpr ) / "in" space "(" valueList ")" / "between" space simpleExpr space "and" space simpleExpr ))
		constantFilterItem <- "true" / "false"
		existsFilterItem <- ("exists" space "(" tableExpr ")")
		colName <- VarName
		compoundColRef <- (tablePlusRefExpr "." (colName / ("(" colRef ")")))
		caseTwoOptions <- ("case" space "when" space tFilterExpr space "then" space valueExpr space ("else" space valueExpr space)? "end")
		caseManyOptions <- ("case" space valueExpr space ("when" space valueExpr space "then" space valueExpr)+ space ("else" space valueExpr space)? "end")
		aggrUserFName <- ("@" VarName)
		xsdRef <- ((XSD_TYPE_PREFIX)? VarName)
		
		simpleTableExpr <- ClassMapRef / namedRef / tableUseExpr
		tableExprExt <- (tableExpr space (uriPattern / keyPattern)?) 
		binaryFilterOp <- "like" / "in" / "<=" / ">=" / "<>" / "=" / "<" / ">"
		tablePlusRefExpr <- ClassMapRef / namedRef / tableRefExpr
		tableRefExpr <- ((dbAlias "::")? VarName)
		XSD_TYPE_PREFIX <- "xsd:"
		ClassMapRef <- "<s>" / "<t>" / "<b>"
		
		namedRef <- ("[" "[" defName "]" "]")
		tableUseExpr <- (dbAlias "::")? VarName
		keyPattern <- ("{" "key" "=" "(" valueExpr ("," valueExpr)* ")" "}")
		HEX_DIGIT <- [0-9] / [A-F] / [a-f]
		defName <- VarName
		dbAlias <- VarName
		space <- (" " / %nl)*
	]])
end