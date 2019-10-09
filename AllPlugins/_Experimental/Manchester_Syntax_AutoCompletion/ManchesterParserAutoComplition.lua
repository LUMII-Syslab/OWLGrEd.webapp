module(..., package.seeall)

require "re"
require "core"
local utils = require "plugin_mechanism.utils"

local errors = {}

function getClassExpression()
	local text = getText()
	classExpressionAutoComplition(text)
end

function getDataRangeExpression()
	local text = getText()
	dataRangeAutoComplition(text)
end
 
function classExpressionAutoComplition(text)
	local grammar = re.compile(
	[[
	expression <- (classExpression? !. %parse_fail)
	classExpression	<-(conjunction (whitespace+ %parse_or 'or' whitespace+ conjunction)*)
	conjunction	<-(
					(
					  %parse_class IRI whitespace+ %parse_that 'that' whitespace+ restriction
					  (whitespace+ %parse_and 'and' whitespace+ restriction)*
					) /
					(primary(whitespace+ %parse_and 'and' whitespace+ primary)*)
				   )
	restriction	<-	(
						(%parse_inverse 'inverse' %parse_roundBracketOpen '(' IRI %parse_roundBracketClose ')' whitespace+
						/%parse_inverse 'inverse' whitespace+ IRI whitespace+
						/%parse_empty '' IRI whitespace+)
						
						(
						  (((%parse_some "some") / (%parse_only "only")) whitespace+ somePrimary) 
						  /(%parse_value "value" whitespace+ (individual / literal)) 
						  /((%parse_Self "Self") / ("self")) 
						  /(
							  ((%parse_min "min") / (%parse_max "max") / (%parse_exactly "exactly")) 
							  whitespace+ nonNegInt (whitespace+ somePrimary)?
							)
						)
					)
	primary	<-	(
				  ((%parse_not 'not' whitespace+) (restriction / atomic)) 
				  /(restriction / atomic)
				)
	dataPrimary	<-(
					(
					  (%parse_not 'not' whitespace+)
					  (   datatypeRestriction /datatype / 
						(%parse_braceOpen '{' whitespace*  literalList whitespace* %parse_braceClose '}') /
						(%parse_roundBracketOpen '(' whitespace* dataRange whitespace* %parse_roundBracketClose ')')
					  )
					) /
					(
						datatypeRestriction / datatype / 
						(%parse_braceOpen '{' whitespace*  literalList whitespace* %parse_braceClose '}') /
						(%parse_roundBracketOpen '(' whitespace* dataRange whitespace* %parse_roundBracketClose ')')
					)
				  )
	somePrimary	<-(
					(%parse_braceOpen '{' whitespace* literalList whitespace* %parse_braceClose '}') /
					(%parse_braceOpen '{' whitespace* individualList whitespace* %parse_braceClose '}') /
					(%parse_roundBracketOpen '(' whitespace* unknownExpression whitespace* %parse_roundBracketClose ')') /
					restriction / datatypeRestriction / IRI
				  )
	atomic	<-	(
				  (%parse_class IRI) /
				  (%parse_braceOpen '{' whitespace* individualList whitespace* %parse_braceClose '}') /
				  (%parse_roundBracketOpen '(' whitespace* classExpression whitespace* %parse_roundBracketClose ')')
				)
	individualList <- (individual (%parse_comma ',' whitespace* individual)*)
	individual<-(IRI / blankNode)
	dataRange<-	(dataConjunction(whitespace+ %parse_or 'or' whitespace+ dataConjunction)*)
	dataConjunction	<-(dataPrimary(whitespace+ %parse_and 'and' whitespace+ dataPrimary)*)
	datatype<-((%parse_integer 'integer') /(%parse_decimal 'decimal') /(%parse_float 'float') /(%parse_string 'string') /(IRI))
	datatypeRestriction	<-( 
							datatype whitespace* %parse_squareBracketOpen '[' whitespace* dataRestriction
						    (whitespace* %parse_comma ',' whitespace* dataRestriction)*
							whitespace* %parse_squareBracketClose ']'
						  )
	dataRestriction	<- (facet whitespace* restrictionValue )
	facet <- ((%parse_lessEqual '<=')/(%parse_moreEqual '>=')/(%parse_less '<')/(%parse_more '>')/
			  (%parse_length 'length')/(%parse_maxLength 'maxLength')/(%parse_minLength 'minLength')/
			  (%parse_pattern 'pattern')/(%parse_langPattern 'langPattern')
			  )
	restrictionValue<- (literal)
	literalList	<-(literal (whitespace* %parse_comma ',' whitespace* literal)+)
	literal	<-(typedLiteral /stringLiteralWithLang /stringLiteralNoLang /floatLiteral /decimalLiteral /integerLiteral)
	typedLiteral<-(quotedString %parse_tick '^^' datatype)
	stringLiteralNoLang	<-(quotedString)
	stringLiteralWithLang <- (quotedString %parse_at '@' languageTag)
	integerLiteral<-(((%parse_plus '+') / (%parse_minus '-'))? digit+)
	decimalLiteral<-(((%parse_plus '+') / (%parse_minus '-'))? digit+ %parse_point '.' digit+)
	floatLiteral<-(((%parse_plus '+') / (%parse_minus '-'))? (digit+ %parse_point '.')? digit+ exponent ((%parse_f 'f') / (%parse_fU 'F')))
	exponent<-(((%parse_e 'e') / (%parse_eU 'E')) ((%parse_plus '+') / (%parse_minus '-'))? digit+)
	digit<-(%parse_digit [0-9])
	nonNegInt<-(digit+)
	quotedString<-(%parse_quote '"'
				   %parse_chars %quotedStringChars* (%parse_slash '\' ( (%parse_slash'\') / (%parse_quote '"')) %parse_chars %quotedStringChars*)*
				   %parse_quote '"'
				   )
	languageTag<-(%parse_chars %langTagChars*)
	IRI <-(fullIRI / abbreviatedIRI / simpleIRI)
	fullIRI <-(%parse_less '<' %parse_chars %fullIRIChars+ %parse_more '>' )
	abbreviatedIRI<-(localName %parse_braceOpen '{' prefix %parse_braceClose '}' )
	prefix <-(%parse_chars %pn_chars_base (%parse_chars %pn_chars / (%parse_point '.'))*)
	localName <-(((%parse_chars %pn_chars_base) / (%parse_chars '_') / %parse_digit '[0-9]') (%pn_chars / (%parse_point '.'))*)
	simpleIRI <-(localName)
	blankNode <-(%parse_underscoreColon '_:' localName)
	unknownExpression <-(unknownConjunction (whitespace+ %parse_or 'or' whitespace+ unknownConjunction)*)
	unknownConjunction <-(
						   (
							 %parse_class IRI whitespace+ %parse_that 'that' whitespace+ restriction
							 (whitespace+ %parse_and 'and' whitespace+ restriction)*
							) /
							(unknownPrimary(whitespace+ %parse_and 'and' whitespace+ unknownPrimary)*)
						  )
	unknownPrimary <- (
						((%parse_not 'not' whitespace+) /(%parse_empty ''))
						(restriction / datatypeRestriction /
						  (%parse_braceOpen '{' whitespace* literalList whitespace* %parse_braceClose '}') /
						  (%parse_braceOpen '{' whitespace* individualList whitespace* %parse_braceClose '}') /
						  (%parse_roundBracketOpen '(' whitespace* unknownExpression whitespace* %parse_roundBracketClose ')') /
							IRI
						)
					  )
	whitespace <- (%parse_space (" " / %nl))
	]]
	, {  
		parse_fail = function (subject, current_pos, captures) 
			add_error_message(errors, current_pos, "", 10) return false 
		end,
		parse_space = function (message, current_pos) add_error_message(errors, current_pos, "", 10) return current_pos end,
		parse_or = function (message, current_pos) 
			if checkIfPropertyName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "or", 10)
			end
			return current_pos 
		end,
		parse_that = function (message, current_pos) 
			if checkIfPropertyName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "that", 10)
			end
			return current_pos 
		end,
		parse_and = function (message, current_pos) 
			if checkIfPropertyName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "and", 10)
			end
			return current_pos 
		end,
		parse_inverse = function (message, current_pos) add_error_message(errors, current_pos, "inverse", 10) return current_pos end,
		parse_empty = function (message, current_pos) add_error_message(errors, current_pos, "", 10) return current_pos end,
		parse_some = function (message, current_pos)    
			if checkIfClassName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "some", 10)
			end
			return current_pos  end,
		parse_only = function (message, current_pos)    
			if checkIfClassName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "only", 10)
			end
			return current_pos  end,
		parse_value = function (message, current_pos)   
			if checkIfClassName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "value", 10)
			end
			return current_pos  end,
		parse_Self = function (message, current_pos)    
			if checkIfClassName(message, current_pos) == false and checkIfDataProperty(message, current_pos) == false then 
				add_error_message(errors, current_pos, "Self", 10)
			end
			return current_pos  end,
		parse_min = function (message, current_pos) 
			if checkIfClassName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "min", 10)
			end
			return current_pos 
		end,
		parse_max = function (message, current_pos) 
			if checkIfClassName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "max", 10)
			end
			return current_pos  end,
		parse_exactly = function (message, current_pos)  
			if checkIfClassName(message, current_pos) == false then 
				add_error_message(errors, current_pos, "exactly", 10)
			end
			return current_pos  end,
		parse_not = function (message, current_pos) add_error_message(errors, current_pos, "not", 10) return current_pos end,
		parse_braceOpen = function (message, current_pos) add_error_message(errors, current_pos, "{", 10) return current_pos end,
		parse_braceClose = function (message, current_pos) add_error_message(errors, current_pos, "}", 10) return current_pos end,
		parse_roundBracketOpen = function (message, current_pos) add_error_message(errors, current_pos, "(", 10) return current_pos end,
		parse_roundBracketClose = function (message, current_pos) add_error_message(errors, current_pos, ")", 10) return current_pos end,
		parse_comma = function (message, current_pos) add_error_message(errors, current_pos, ",", 10) return current_pos end,
		parse_integer = function (message, current_pos) add_error_message(errors, current_pos, "integer", 10) return current_pos end,
		parse_decimal = function (message, current_pos) add_error_message(errors, current_pos, "decimal", 10) return current_pos end,
		parse_float = function (message, current_pos) add_error_message(errors, current_pos, "float", 10) return current_pos end,
		parse_string = function (message, current_pos) add_error_message(errors, current_pos, "string", 10) return current_pos end,
		parse_squareBracketOpen = function (message, current_pos) add_error_message(errors, current_pos, "[", 10) return current_pos end,
		parse_squareBracketClose = function (message, current_pos) add_error_message(errors, current_pos, "]", 10) return current_pos end,
		parse_lessEqual = function (message, current_pos) add_error_message(errors, current_pos, "<=", 10) return current_pos end,
		parse_less = function (message, current_pos) add_error_message(errors, current_pos, "<", 10) return current_pos end,
		parse_moreEqual = function (message, current_pos) add_error_message(errors, current_pos, ">=", 10) return current_pos end,
		parse_more = function (message, current_pos) add_error_message(errors, current_pos, ">", 10) return current_pos end,
		parse_length = function (message, current_pos) add_error_message(errors, current_pos, "length", 10) return current_pos end,
		parse_maxLength = function (message, current_pos) add_error_message(errors, current_pos, "maxLength", 10) return current_pos end,
		parse_minLength = function (message, current_pos) add_error_message(errors, current_pos, "minLength", 10) return current_pos end,
		parse_pattern = function (message, current_pos) add_error_message(errors, current_pos, "pattern", 10) return current_pos end,
		parse_langPattern = function (message, current_pos) add_error_message(errors, current_pos, "langPattern", 10) return current_pos end,
		parse_tick = function (message, current_pos) add_error_message(errors, current_pos, "^^", 10) return current_pos end,
		parse_at = function (message, current_pos) add_error_message(errors, current_pos, "@", 10) return current_pos end,
		parse_plus = function (message, current_pos) add_error_message(errors, current_pos, "+", 10) return current_pos end,
		parse_minus = function (message, current_pos) add_error_message(errors, current_pos, "-", 10) return current_pos end,
		parse_point = function (message, current_pos) add_error_message(errors, current_pos, ".", 10) return current_pos end,
		parse_f = function (message, current_pos) add_error_message(errors, current_pos, "f", 10) return current_pos end,
		parse_fU = function (message, current_pos) add_error_message(errors, current_pos, "F", 10) return current_pos end,
		parse_e = function (message, current_pos) add_error_message(errors, current_pos, "e", 10) return current_pos end,
		parse_eU = function (message, current_pos) add_error_message(errors, current_pos, "E", 10) return current_pos end,
		parse_digit = function (message, current_pos) add_error_message(errors, current_pos, " ", 10) return current_pos end,
		parse_quote = function (message, current_pos) add_error_message(errors, current_pos, '"', 10) return current_pos end,
		parse_slash = function (message, current_pos) add_error_message(errors, current_pos, [[\]], 10) return current_pos end,
		parse_chars = function (message, current_pos) add_error_message(errors, current_pos, " ", 10) return current_pos end,
		parse_underscoreColon = function (message, current_pos) add_error_message(errors, current_pos, "_:", 10) return current_pos end,
		parse_class = function (message, current_pos) 
			add_error_message(errors, current_pos, "A", 100) 
			add_error_message(errors, current_pos, "B", 100) 
			add_error_message(errors, current_pos, "C", 100) 
			add_error_message(errors, current_pos, "D", 100) 
			return current_pos 
		end,
		
		
		pn_class = re.compile("'A' / 'B' / 'C' / 'D'"),
		pn_property = re.compile("'aa' / 'bb' / 'cc' / 'dd'"),
		pn_individual = re.compile("'ia' / 'ib' / 'ic' / 'id'"),
		pn_unknow = re.compile("'ua' / 'ub' / 'uc' / 'ud'"),
		
	--pn_chars_base = re.compile("[A-Z] / [a-z] / [\192-\214] / [\216-\246] / [\248-\255]"),
	pn_chars_base = re.compile("[A-Z] / [a-z] / [\128-\214] / [\216-\246] / [\248-\255]"), --replaced 192 with 128 to (hopefully) include Latvian characters
	--pn_chars = re.compile("[A-Z] / [a-z] / [\192-\214] / [\216-\246] / [\248-\255] / '_' / '-' / [0-9] / '\183'"),
	pn_chars = re.compile("[A-Z] / [a-z] / [\128-\214] / [\216-\246] / [\248-\255] / '_' / '-' / [0-9]"),
	quotedStringChars = re.compile("[\1-\33] / [\35-\91] / [\93-\255]"), --32 is double quote ("), 92 is backslash (\)
	--doubleQuote = re.compile("'\"'"), --there were some problems with including backslashes and double quotes directly in the grammar
	--backslash = re.compile("'\92'"),
	langTagChars = re.compile("[A-Z] / [a-z] / '-'"), --currently implemented like this. Doesn't match specification, that will be done later
	fullIRIChars = re.compile("[\33-\59] / '=' / [\63-\126] / [\128-\255]")
	  }
	)
	
	local res = match_err(grammar, text)
end

function dataRangeAutoComplition(text)
	local grammar = re.compile(
	[[
	grammarDataRange <- ((%parse_roundBracketOpen '(' dataRange %parse_roundBracketClose ')') / dataRange)
	dataRange			<-	(
								dataConjunction
								(whitespace+ %parse_or 'or' whitespace+ dataConjunction)*
							)
	dataConjunction		<-	(
								dataPrimary
								(whitespace+ %parse_and 'and' whitespace+ dataPrimary)*
							)
	dataPrimary			<-	(
								(
									(%parse_not 'not' whitespace+)
									(
										(
											datatypeRestriction
										) /
										(
											datatype
										) /
										(
											%parse_braceOpen '{' whitespace* literalList whitespace* %parse_braceClose '}'
										) /
										(
											%parse_roundBracketOpen '(' whitespace* dataRange whitespace* %parse_roundBracketClose ')'
										)
									)
								) /
								(
									(
										(
											datatypeRestriction
										) /
										(
											datatype
										) /
										(
											%parse_braceOpen '{' whitespace* literalList whitespace* %parse_braceClose '}'
										) /
										(
											%parse_roundBracketOpen '(' whitespace* {:dataRange: dataRange :} whitespace*  %parse_roundBracketClose ')'
										)
									)
								)
							)
	datatype			<-	(
								(
									%parse_integer 'integer'
								) /
								(
									%parse_decimal 'decimal'
								) /
								(
									%parse_float 'float'
								) /
								(
									%parse_string 'string'
								) /
								(
									IRI
								)
							)
	datatypeRestriction	<-	(
								datatype
								whitespace* %parse_squareBracketOpen '[' whitespace*
								dataRestriction
								(whitespace* %parse_comma ',' whitespace* dataRestriction)*
								whitespace* %parse_squareBracketClose ']'
							)
	dataRestriction		<-	(
								facet
								whitespace*
								restrictionValue
							)
	facet				<- 	(
								(%parse_lessEqual '<=')/
								(%parse_moreEqual '>=')/
								(%parse_less '<')/
								(%parse_more '>')/
								(%parse_length 'length')/
								(%parse_maxLength 'maxLength')/
								(%parse_minLength 'minLength')/
								(%parse_pattern 'pattern')/
								(%parse_langPattern 'langPattern')
							)
	restrictionValue	<- 	(
								literal
							)
	literalList			<-	(
								literal
								(whitespace* %parse_comma ',' whitespace* literal)+
							)
	literal				<-	(
								typedLiteral /
								stringLiteralWithLang /
								stringLiteralNoLang /
								floatLiteral /
								decimalLiteral /
								integerLiteral
							)
	typedLiteral		<-	(
								quotedString
								%parse_tick '^^'
								datatype
							)
	stringLiteralNoLang	<-	(
								quotedString
							)
	stringLiteralWithLang <- (
								quotedString
								%parse_at '@'
								languageTag
							)
	integerLiteral		<-	(
								 ((%parse_plus '+') / (%parse_minus '-'))? digit+
							)
	decimalLiteral		<-	(
								((%parse_plus '+') / (%parse_minus '-'))? digit+ %parse_point '.' digit+
							)
	floatLiteral		<-	(
								(%parse_plus '+') / (%parse_minus '-')? (digit+ '.')? digit+ exponent ((%parse_f 'f') / (%parse_fU 'F'))
							)
	exponent			<-	(
								((%parse_e 'e') / (%parse_eU 'E')) ((%parse_plus '+') / (%parse_minus '-'))? digit+
							)
	digit				<-	(
								%parse_digit [0-9]
							)
	quotedString		<-	(
								%parse_quote '"'
								%parse_chars %quotedStringChars* (%parse_slash '\' ( (%parse_slash'\') / (%parse_quote '"')) %parse_chars %quotedStringChars*)*
								%parse_quote '"'
							)
	languageTag			<-	(
								%parse_chars %langTagChars*
							)
	IRI					<-	(
								fullIRI / abbreviatedIRI / simpleIRI
							)
	fullIRI				<-	(
								%parse_less '<'
								%parse_chars %fullIRIChars+
								%parse_more '>'
							)
	abbreviatedIRI		<-	(
								localName
								%parse_braceOpen '{'
								prefix
								%parse_braceClose '}'
							)
	prefix				<-	(
								%parse_chars %pn_chars_base (%parse_chars %pn_chars / (%parse_point '.'))*
							)
	localName			<-	(
								((%parse_chars %pn_chars_base) / (%parse_chars '_') / %parse_digit '[0-9]') (%parse_chars %pn_chars / (%parse_point '.'))*
							)
	simpleIRI			<-	(
								localName
							)
	blankNode			<-	(
								%parse_underscoreColon '_:' localName
							)
	whitespace			<-	(%parse_space (" " / %nl))
]], {  
		parse_fail = function (subject, current_pos, captures) 
			return false 
		end,
		parse_space = function (message, current_pos) add_error_message(errors, current_pos, " ", 10) return current_pos end,
		parse_or = function (message, current_pos) add_error_message(errors, current_pos, "or", 10) return current_pos end,
		parse_that = function (message, current_pos) add_error_message(errors, current_pos, "that", 10) return current_pos end,
		parse_and = function (message, current_pos) add_error_message(errors, current_pos, "and", 10) return current_pos end,
		parse_inverse = function (message, current_pos) add_error_message(errors, current_pos, "inverse", 10) return current_pos end,
		parse_empty = function (message, current_pos) add_error_message(errors, current_pos, " ", 10) return current_pos end,
		parse_some = function (message, current_pos) add_error_message(errors, current_pos, "some", 10) return current_pos end,
		parse_only = function (message, current_pos) add_error_message(errors, current_pos, "only", 10) return current_pos end,
		parse_value = function (message, current_pos) add_error_message(errors, current_pos, "value", 10) return current_pos end,
		parse_Self = function (message, current_pos) add_error_message(errors, current_pos, "Self", 10) return current_pos end,
		parse_min = function (message, current_pos) add_error_message(errors, current_pos, "min", 10) return current_pos end,
		parse_max = function (message, current_pos) add_error_message(errors, current_pos, "max", 10) return current_pos end,
		parse_exactly = function (message, current_pos) add_error_message(errors, current_pos, "exactly", 10) return current_pos end,
		parse_not = function (message, current_pos) add_error_message(errors, current_pos, "not", 10) return current_pos end,
		parse_braceOpen = function (message, current_pos) add_error_message(errors, current_pos, "{", 10) return current_pos end,
		parse_braceClose = function (message, current_pos) add_error_message(errors, current_pos, "}", 10) return current_pos end,
		parse_roundBracketOpen = function (message, current_pos) add_error_message(errors, current_pos, "(", 10) return current_pos end,
		parse_roundBracketClose = function (message, current_pos) add_error_message(errors, current_pos, ")", 10) return current_pos end,
		parse_comma = function (message, current_pos) add_error_message(errors, current_pos, ",", 10) return current_pos end,
		parse_integer = function (message, current_pos) add_error_message(errors, current_pos, "integer", 10) return current_pos end,
		parse_decimal = function (message, current_pos) add_error_message(errors, current_pos, "decimal", 10) return current_pos end,
		parse_float = function (message, current_pos) add_error_message(errors, current_pos, "float", 10) return current_pos end,
		parse_string = function (message, current_pos) add_error_message(errors, current_pos, "string", 10) return current_pos end,
		parse_squareBracketOpen = function (message, current_pos) add_error_message(errors, current_pos, "[", 10) return current_pos end,
		parse_squareBracketClose = function (message, current_pos) add_error_message(errors, current_pos, "]", 10) return current_pos end,
		parse_lessEqual = function (message, current_pos) add_error_message(errors, current_pos, "<=", 10) return current_pos end,
		parse_less = function (message, current_pos) add_error_message(errors, current_pos, "<", 10) return current_pos end,
		parse_moreEqual = function (message, current_pos) add_error_message(errors, current_pos, ">=", 10) return current_pos end,
		parse_more = function (message, current_pos) add_error_message(errors, current_pos, ">", 10) return current_pos end,
		parse_length = function (message, current_pos) add_error_message(errors, current_pos, "length", 10) return current_pos end,
		parse_maxLength = function (message, current_pos) add_error_message(errors, current_pos, "maxLength", 10) return current_pos end,
		parse_minLength = function (message, current_pos) add_error_message(errors, current_pos, "minLength", 10) return current_pos end,
		parse_pattern = function (message, current_pos) add_error_message(errors, current_pos, "pattern", 10) return current_pos end,
		parse_langPattern = function (message, current_pos) add_error_message(errors, current_pos, "langPattern", 10) return current_pos end,
		parse_tick = function (message, current_pos) add_error_message(errors, current_pos, "^^", 10) return current_pos end,
		parse_at = function (message, current_pos) add_error_message(errors, current_pos, "@", 10) return current_pos end,
		parse_plus = function (message, current_pos) add_error_message(errors, current_pos, "+", 10) return current_pos end,
		parse_minus = function (message, current_pos) add_error_message(errors, current_pos, "-", 10) return current_pos end,
		parse_point = function (message, current_pos) add_error_message(errors, current_pos, ".", 10) return current_pos end,
		parse_f = function (message, current_pos) add_error_message(errors, current_pos, "f", 10) return current_pos end,
		parse_fU = function (message, current_pos) add_error_message(errors, current_pos, "F", 10) return current_pos end,
		parse_e = function (message, current_pos) add_error_message(errors, current_pos, "e", 10) return current_pos end,
		parse_eU = function (message, current_pos) add_error_message(errors, current_pos, "E", 10) return current_pos end,
		parse_digit = function (message, current_pos) add_error_message(errors, current_pos, " ", 10) return current_pos end,
		parse_quote = function (message, current_pos) add_error_message(errors, current_pos, '"', 10) return current_pos end,
		parse_slash = function (message, current_pos) add_error_message(errors, current_pos, [[\]], 10) return current_pos end,
		parse_chars = function (message, current_pos) add_error_message(errors, current_pos, " ", 10) return current_pos end,
		parse_underscoreColon = function (message, current_pos) add_error_message(errors, current_pos, "_:", 10) return current_pos end,
		
	--pn_chars_base = re.compile("[A-Z] / [a-z] / [\192-\214] / [\216-\246] / [\248-\255]"),
	pn_chars_base = re.compile("[A-Z] / [a-z] / [\128-\214] / [\216-\246] / [\248-\255]"), --replaced 192 with 128 to (hopefully) include Latvian characters
	--pn_chars = re.compile("[A-Z] / [a-z] / [\192-\214] / [\216-\246] / [\248-\255] / '_' / '-' / [0-9] / '\183'"),
	pn_chars = re.compile("[A-Z] / [a-z] / [\128-\214] / [\216-\246] / [\248-\255] / '_' / '-' / [0-9]"),
	quotedStringChars = re.compile("[\1-\33] / [\35-\91] / [\93-\255]"), --32 is double quote ("), 92 is backslash (\)
	--doubleQuote = re.compile("'\"'"), --there were some problems with including backslashes and double quotes directly in the grammar
	--backslash = re.compile("'\92'"),
	langTagChars = re.compile("[A-Z] / [a-z] / '-'"), --currently implemented like this. Doesn't match specification, that will be done later
	fullIRIChars = re.compile("[\33-\59] / '=' / [\63-\126] / [\128-\255]")
	  }
	)
	
	local res = match_err(grammar, text)
end


function parseName(message)
	local grammar = re.compile([[
		gMain <- ({String} Space !.)
					String <- ([A-Za-z] / "_") ([A-Za-z] / "_" / [0-9])*
					Space <-  (" " / %nl)
				]])
	local place, name = re.find(message, grammar)
	return name
end

function checkIfClassName(message, current_pos)
	isClassName = false
	
	local name = parseName(message)
	local diagram = utilities.current_diagram()
	local clasNames = diagram:find("/element:has(/elemType[id='Class'])/compartment/subCompartment:has(/compartType[id='Name'])")
	clasNames:each(function(obj)
		if name == obj:attr("value") then isClassName = true end
	end)
	return isClassName
end

function checkIfPropertyName(message, current_pos)
	isPropertyName = false
	
	local name = parseName(message)
	local diagram = utilities.current_diagram()
	local propertyNames = diagram:find("/element:has(/elemType[id='Class'])/compartment/subCompartment/subCompartment/subCompartment:has(/compartType[id='Name'])")
		:add(diagram:find("/element:has(/elemType[id='Association'])/compartment/subCompartment/subCompartment:has(/compartType[id='Name'])"))
	propertyNames:each(function(obj)
		if name == obj:attr("value") then isPropertyName = true end
	end)
	return isPropertyName
end

function checkIfDataProperty(message, current_pos)
	isDataProprty = false
	
	local name = parseName(message)
	local diagram = utilities.current_diagram()
	local propertyNames = diagram:find("/element:has(/elemType[id='Class'])/compartment/subCompartment/subCompartment/subCompartment:has(/compartType[id='Name'])")
	propertyNames:each(function(obj)
		if name == obj:attr("value") then isDataProprty = true end
	end)
	return isDataProprty
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

--atjauno formu
function refreshForm(var)
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

function displayEndings(str, errors)
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

function removeUnnecessaryMessages(TermMessages)

	local endings = {}
	for pos, message in pairs(TermMessages) do
		if message~="" then
			table.insert(endings, message)
		end
	end
	return endings
end