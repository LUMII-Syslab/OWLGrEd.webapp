local classExpressionGrammar = re.compile(
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
						  /((%parse_Self "Self") / (%parse_selfL "self")) 
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
	whitespace <- ((" " / %nl))
	]]
	, {  
		parse_fail = function (continuation, cur_pos) add_continuation(continuations,cur_pos, "", 10) return false end,
		parse_or = function (continuation, cur_pos) 
			if checkIfPropertyName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "or", 10)
			end
			return current_pos 
		end,
		parse_that = function (continuation, cur_pos) 
			if checkIfPropertyName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "that", 10)
			end
			return current_pos 
		end,
		parse_and = function (continuation, cur_pos) 
			if checkIfPropertyName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "and", 10)
			end
			return current_pos 
		end,
		parse_inverse = create_parse_fn("inverse", 10),
		parse_empty = create_parse_fn("", 10),
		parse_some = function (continuation, cur_pos)    
			if checkIfClassName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "some", 10)
			end
			return current_pos  end,
		parse_only = function (continuation, cur_pos)    
			if checkIfClassName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "only", 10)
			end
			return current_pos  end,
		parse_value = function (continuation, cur_pos)   
			if checkIfClassName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "value", 10)
			end
			return current_pos  end,
		parse_Self = function (continuation, cur_pos)    
			if checkIfClassName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "Self", 10)
			end
			return current_pos  end,
		parse_selfL = function (continuation, cur_pos)    
			if checkIfClassName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "self", 10)
			end
			return current_pos  end,
		parse_min = function (continuation, cur_pos) 
			if checkIfClassName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "min", 10)
			end
			return current_pos 
		end,
		parse_max = function (continuation, cur_pos) 
			if checkIfClassName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "max", 10)
			end
			return current_pos  end,
		parse_exactly = function (continuation, cur_pos)  
			if checkIfClassName(continuation, cur_pos) == false then 
				add_continuation(continuations,cur_pos, "exactly", 10)
			end
			return current_pos  end,
		parse_not = create_parse_fn("not", 10),
		parse_braceOpen = create_parse_fn("{", 10),
		parse_braceClose = create_parse_fn("}", 10),
		parse_roundBracketOpen = create_parse_fn("(", 10),
		parse_roundBracketClose = create_parse_fn(")", 10),
		parse_comma = create_parse_fn(",", 10),
		parse_integer = create_parse_fn("integer", 10),
		parse_decimal = create_parse_fn("decimal", 10),
		parse_float = create_parse_fn("float", 10),
		parse_string = create_parse_fn("string", 10),
		parse_squareBracketOpen = create_parse_fn("[", 10),
		parse_squareBracketClose = create_parse_fn("]", 10),
		parse_lessEqual = create_parse_fn("<=", 10),
		parse_less = create_parse_fn("<", 10),
		parse_moreEqual = create_parse_fn(">=", 10),
		parse_more = create_parse_fn(">", 10),
		parse_length = create_parse_fn("length", 10),
		parse_maxLength = create_parse_fn("maxLength", 10),
		parse_minLength = create_parse_fn("minLength", 10),
		parse_pattern = create_parse_fn("pattern", 10),
		parse_langPattern = create_parse_fn("langPattern", 10),
		parse_tick = create_parse_fn("^^", 10),
		parse_at = create_parse_fn("@", 10),
		parse_plus = create_parse_fn("+", 10),
		parse_minus = create_parse_fn("-", 10),
		parse_point = create_parse_fn(".", 10),
		parse_f = create_parse_fn("f", 10),
		parse_fU = create_parse_fn("F", 10),
		parse_e = create_parse_fn("e", 10),
		parse_eU = create_parse_fn("E", 10),
		parse_digit = create_parse_fn(" ", 10),
		parse_quote = create_parse_fn('"', 10),
		parse_slash = create_parse_fn([[\]], 10),
		parse_chars = create_parse_fn(" ", 10),
		parse_underscoreColon = create_parse_fn("_:", 10),

		pn_chars_base = re.compile("[A-Z] / [a-z] / [\128-\214] / [\216-\246] / [\248-\255]"), --replaced 192 with 128 to (hopefully) include Latvian characters
		pn_chars = re.compile("[A-Z] / [a-z] / [\128-\214] / [\216-\246] / [\248-\255] / '_' / '-' / [0-9]"),
		quotedStringChars = re.compile("[\1-\33] / [\35-\91] / [\93-\255]"), --32 is double quote ("), 92 is backslash (\)
		langTagChars = re.compile("[A-Z] / [a-z] / '-'"), --currently implemented like this. Doesn't match specification, that will be done later
		fullIRIChars = re.compile("[\33-\59] / '=' / [\63-\126] / [\128-\255]")
	}
)


local dataRangeGrammar = re.compile(
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
	whitespace			<-	( (" " / %nl))
]], {  
		parse_fail = function (subject, current_pos, captures) 
			return false 
		end,
		parse_or = create_parse_fn("or", 10),
		parse_that = create_parse_fn("that", 10),
		parse_and = create_parse_fn("and", 10),
		parse_inverse = create_parse_fn("inverse", 10),
		parse_empty = create_parse_fn(" ", 10),
		parse_some = create_parse_fn("some", 10),
		parse_only = create_parse_fn("only", 10),
		parse_value = create_parse_fn("value", 10),
		parse_Self = create_parse_fn("Self", 10),
		parse_selfL = create_parse_fn("self", 10),
		parse_min = create_parse_fn("min", 10),
		parse_max = create_parse_fn("max", 10),
		parse_exactly = create_parse_fn("exactly", 10),
		parse_not = create_parse_fn("not", 10),
		parse_braceOpen = create_parse_fn("{", 10),
		parse_braceClose = create_parse_fn("}", 10),
		parse_roundBracketOpen = create_parse_fn("(", 10),
		parse_roundBracketClose = create_parse_fn(")", 10),
		parse_comma = create_parse_fn(",", 10),
		parse_integer = create_parse_fn("integer", 10),
		parse_decimal = create_parse_fn("decimal", 10),
		parse_float = create_parse_fn("float", 10),
		parse_string = create_parse_fn("string", 10),
		parse_squareBracketOpen = create_parse_fn("[", 10),
		parse_squareBracketClose = create_parse_fn("]", 10),
		parse_lessEqual = create_parse_fn("<=", 10),
		parse_less = create_parse_fn("<", 10),
		parse_moreEqual = create_parse_fn(">=", 10),
		parse_more = create_parse_fn(">", 10),
		parse_length = create_parse_fn("length", 10),
		parse_maxLength = create_parse_fn("maxLength", 10),
		parse_minLength = create_parse_fn("minLength", 10),
		parse_pattern = create_parse_fn("pattern", 10),
		parse_langPattern = create_parse_fn("langPattern", 10),
		parse_tick = create_parse_fn("^^", 10),
		parse_at = create_parse_fn("@", 10),
		parse_plus = create_parse_fn("+", 10),
		parse_minus = create_parse_fn("-", 10),
		parse_point = create_parse_fn(".", 10),
		parse_f = create_parse_fn("f", 10),
		parse_fU = create_parse_fn("F", 10),
		parse_e = create_parse_fn("e", 10),
		parse_eU = create_parse_fn("E", 10),
		parse_digit = create_parse_fn(" ", 10),
		parse_quote = create_parse_fn('"', 10),
		parse_slash = create_parse_fn([[\]], 10),
		parse_chars = create_parse_fn(" ", 10),
		parse_underscoreColon = create_parse_fn("_:", 10),
		
		pn_chars_base = re.compile("[A-Z] / [a-z] / [\128-\214] / [\216-\246] / [\248-\255]"), --replaced 192 with 128 to (hopefully) include Latvian characters
		pn_chars = re.compile("[A-Z] / [a-z] / [\128-\214] / [\216-\246] / [\248-\255] / '_' / '-' / [0-9]"),
		quotedStringChars = re.compile("[\1-\33] / [\35-\91] / [\93-\255]"), --32 is double quote ("), 92 is backslash (\)
		langTagChars = re.compile("[A-Z] / [a-z] / '-'"), --currently implemented like this. Doesn't match specification, that will be done later
		fullIRIChars = re.compile("[\33-\59] / '=' / [\63-\126] / [\128-\255]")
	}
)