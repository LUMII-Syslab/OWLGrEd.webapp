module(...,package.seeall)

require "re"
require "tda_to_protege"
require "lQuery"
--the function make_global_ns_uri_table takes a diagram. Is it safe to always pass the current diagram?
--local namespaceURITable = tda_to_protege.make_global_ns_uri_table(lQuery("CurrentDgrPointer/graphDiagram"))

--given as a function because this file requires tda_to_protege and vice versa. Making this a local variable produces errors
-- function namespaceURITable()
-- 	--return tda_to_protege.ns_uri_table
-- 	return tda_to_protege.make_global_ns_uri_table(utilities.current_diagram())
-- end

local namespaceURITable -- will be assigned by init_namespaceURITable
function init_namespaceURITable(t)
	-- local t = tda_to_protege.make_global_ns_uri_table(diagram)
	namespaceURITable = function()
		return t
	end
end


local classExpressionGrammar = [[
	expression			<-	(
								whitespace*
								classExpression?
								!.
							)
	classExpression		<-	(
								{:grammarProduction: '' -> "disjunction" :}
								conjunction
								(whitespace+ 'or' whitespace+ conjunction)*
							) -> {}
	conjunction			<-	(
								(
									{:grammarProduction: '' -> "conjunctionWithRestrictions" :}
									{:class: IRI :}
									whitespace+ 'that' whitespace+
									restriction
									(whitespace+ 'and' whitespace+ restriction)*
								) /
								(
									{:grammarProduction: '' -> "conjunctionNoRestrictions" :}
									primary
									(whitespace+ 'and' whitespace+ primary)*
								)
							) -> {}
	restriction			<-	(
								(
									(
										{:inverse: ('inverse' whitespace+) -> "true" :}
										'('
										{:property: IRI :}
										')'
										whitespace+
									) /
									(	{:inverse: ('inverse' whitespace+) -> "true" :}
										{:property: IRI :}
										whitespace+
									) /
									(
										{:inverse: '' -> "false" :}
										{:property: IRI :}
										whitespace+
									)
								)
								(
									(
										{:keyword: ("some" / "only") :}
										whitespace+
										{:value: somePrimary :}
									) /
									(
										{:keyword: "value" :}
										whitespace+
										{:value: ( stringLiteralNoLangBool / individual / literal) :}
									) /
									(
										{:keyword: ("Self" / "self") -> "Self" :}
									) /
									(
										{:keyword: ("min" / "max" / "exactly") :}
										whitespace+
										{:count: nonNegInt :}
										(whitespace+ {:value: somePrimary :})?
									)
								)
							) -> {}
	primary				<-	(
								(
									{:negation: ('not' whitespace+) -> "true" :}
									(
										(
											{:primaryType: '' -> "restriction" :}
											{:primary: restriction :}
										) /
										(
											{:primaryType: '' -> "atomic" :}
											{:primary: atomic :}
										)
									)
								) /
								(
									{:negation: '' -> "false" :}
									(
										(
											{:primaryType: '' -> "restriction" :}
											{:primary: restriction :}
										) /
										(
											{:primaryType: '' -> "atomic" :}
											{:primary: atomic :}
										)
									)
								)
							) -> {}
	dataPrimary			<-	(
								(
									{:negation: ('not' whitespace+) -> "true" :}
									(
										(
											{:dataPrimaryType: '' -> "datatypeRestriction" :}
											{:restriction: datatypeRestriction :}
										) /
										(
											{:dataPrimaryType: '' -> "datatype" :}
											{:datatype: datatype :}
										) /
										(
											{:dataPrimaryType: '' -> "literalList" :}
											'{' whitespace* {:literalList: literalList :} whitespace* '}'
										) /
										(
											{:dataPrimaryType: '' -> "dataRange" :}
											'(' whitespace* {:dataRange: dataRange :} whitespace* ')'
										)
									)
								) /
								(
									{:negation: '' -> "false" :}
									(
										(
											{:dataPrimaryType: '' -> "datatypeRestriction" :}
											{:restriction: datatypeRestriction :}
										) /
										(
											{:dataPrimaryType: '' -> "datatype" :}
											{:datatype: datatype :}
										) /
										(
											{:dataPrimaryType: '' -> "literalList" :}
											'{' whitespace* {:literalList: literalList :} whitespace* '}'
										) /
										(
											{:dataPrimaryType: '' -> "dataRange" :}
											'(' whitespace* {:dataRange: dataRange :} whitespace* ')'
										)
									)
								)
							) -> {}
	somePrimary			<-	(
								(
									{:unknownPrimaryType: '' -> "literalList" :}
									'{' whitespace* {:list: literalList :} whitespace* '}'
								) /
								(
									{:unknownPrimaryType: '' -> "individualList" :}
									'{' whitespace* {:list: individualList :} whitespace* '}'
								) /
								(
									{:unknownPrimaryType: '' -> "expression" :}
									'(' whitespace* {:expression: unknownExpression :} whitespace* ')'
								) /
								(
									{:unknownPrimaryType: '' -> "restriction" :}
									{:restriction: restriction :}
								) /
								(
									{:unknownPrimaryType: '' -> "datatypeRestriction" :}
									{:restriction: datatypeRestriction :}
								) /
								(
									{:unknownPrimaryType: '' -> "IRI" :}
									{:IRI: IRI :}
								)
							) -> {}
	atomic				<-	(
								(
									{:atomType: '' -> "class" :}
									{:class: IRI :}
								) /
								(
									{:atomType: '' -> "individualList" :}
									'{' whitespace*
									{:list: individualList :}
									whitespace* '}'
								) /
								(
									{:atomType: '' -> "expression" :}
									'(' whitespace*
									{:expression: classExpression :}
									whitespace* ')'
								)
							) -> {}
	individualList		<-	(
								individual
								(',' whitespace* individual)*
							) -> {}
	individual			<-	(
								(
									{:individualType: '' -> "IRI" :}
									{:individual: IRI :}
								) /
								(
									{:individualType: '' -> "blank" :}
									{:individual: blankNode :}
								)
							) -> {}
	dataRange			<-	(
								{:grammarProduction: '' -> "dataDisjunction" :}
								dataConjunction
								(whitespace+ 'or' whitespace+ dataConjunction)*
							) -> {}
	dataConjunction		<-	(
								{:grammarProduction: '' -> "dataConjunction" :}
								dataPrimary
								(whitespace+ 'and' whitespace+ dataPrimary)*
							) -> {}
	datatype			<-	(
								(
									{:type: '' -> "IRI" :}
									{:value: IRI :}
								) /
								(
									{:type: '' -> "predefined" :}
									{:value: 'integer' :}
								) /
								(
									{:type: '' -> "predefined" :}
									{:value: 'decimal' :}
								) /
								(
									{:type: '' -> "predefined" :}
									{:value: 'float' :}
								) /
								(
									{:type: '' -> "predefined" :}
									{:value: 'string' :}
								)

							) -> {}
	datatypeRestriction	<-	(
								{:datatype: datatype :}
								whitespace* '[' whitespace*
								dataRestriction
								(whitespace* ',' whitespace* dataRestriction)*
								whitespace* ']'
							) -> {}
	dataRestriction		<-	(
								{:facet: facet :}
								whitespace*
								{:value: restrictionValue :}
							) -> {}
	facet				<- 	(
								'<='/
								'<'/
								'>='/
								'>'/
								'length'/
								'maxLength'/
								'minLength'/
								'pattern'/
								'langPattern'
							)
	restrictionValue	<- 	(
								literal
							)
	literalList			<-	(
								literal
								(whitespace* ',' whitespace* literal)+
							) -> {}
	literal				<-	(
								typedLiteral /
								stringLiteralWithLang /
								stringLiteralNoLang /
								floatLiteral /
								decimalLiteral /
								integerLiteral
							)
	typedLiteral		<-	(
								{:type: '' -> "typed" :}
								{:value: quotedString :}
								'^^'
								{:datatype: datatype :}
							) -> {}
	stringLiteralNoLang	<-	(
								{:type: '' -> "stringNoLang" :}
								{:value: quotedString :}
							) -> {}
	stringLiteralNoLangBool	<-	(
								{:type: '' -> "stringNoLang" :}
								{:value: (true / false) :}
							) -> {}
	true					<- 'true' -> '"true"'
	false					<- 'false' -> '"false"'
	stringLiteralWithLang <- (
								{:type: '' -> "stringWithLang" :}
								{:value: quotedString :}
								'@'
								{:language: languageTag :}
							) -> {}
	integerLiteral		<-	(
								{:type: '' -> "integer" :}
								{:value: ('+' / '-')? digit+ :}
							) -> {}
	decimalLiteral		<-	(
								{:type: '' -> "decimal" :}
								{:value: ('+' / '-')? digit+ '.' digit+ :}
							) -> {}
	floatLiteral		<-	(
								{:type: '' -> "float" :}
								{:value: ('+' / '-')? (digit+ '.')? digit+ exponent ('f' / 'F'):}
							) -> {}
	exponent			<-	(
								('e' / 'E') ('+' / '-')? digit+
							)
	digit				<-	(
								[0-9]
							)
	nonNegInt			<-	(
								digit+
							)
	quotedString		<-	(
								'"'
								%quotedStringChars* ('\' ('\' / '"') %quotedStringChars*)*
								'"'
							)
	languageTag			<-	(
								%langTagChars*
							)
	IRI					<-	(
								(
									{:IRItype: '' -> "fullIRI" :}
									{:value: fullIRI :}
								) /
								(
									{:IRItype: '' -> "abbreviatedIRI" :}
									{:value: abbreviatedIRI :}
								) /
								(
									{:IRItype: '' -> "fullNamespaceIRI" :}
									{:value: fullNamespaceIRI :}
								) /
								(
									{:IRItype: '' -> "simpleIRI" :}
									{:value: simpleIRI :}
								)
							) -> {}
	fullIRI				<-	(
								'<'
								%fullIRIChars+
								'>'
							)
	abbreviatedIRI		<-	(
								{:name: localName :}
								'{'
								{:prefix: prefix :}
								'}'
							) -> {}
	fullNamespaceIRI		<-	(
								{:name: localName :}
								'{'
								{:prefix: prefixNamespace :}
								'}'
							) -> {}
	prefix				<-	(
								%pn_chars_base (%pn_chars / '.' / '/' / ':')*
							)
	prefixNamespace				<-	(
								%pn_chars_base (%pn_chars / '.' / '/' / ':')*
							)
	localName			<-	(
								(%pn_chars_base / '_' / '[0-9]') (%pn_chars / '.')*
							)
	simpleIRI			<-	(
								localName
							)
	blankNode			<-	(
								'_:' localName
							)
	unknownExpression	<-	(
								{:grammarProduction: '' -> "unknownDisjunction" :}
								unknownConjunction
								(whitespace+ 'or' whitespace+ unknownConjunction)*
							) -> {}
	unknownConjunction	<-	(
								(
									{:grammarProduction: '' -> "conjunctionWithRestrictions" :}
									{:class: IRI :}
									whitespace+ 'that' whitespace+
									restriction
									(whitespace+ 'and' whitespace+ restriction)*
								) /
								(
									{:grammarProduction: '' -> "unknownConjunction" :}
									unknownPrimary
									(whitespace+ 'and' whitespace+ unknownPrimary)*
								)
							) -> {}
	unknownPrimary		<-	(
								(
									(
										{:negation: ('not' whitespace+) -> "true" :}
									) /
									(
										{:negation: '' -> "false" :}
									)
								)
								(
									(
										{:unknownPrimaryType: '' -> "restriction" :}
										{:restriction: restriction :}
									) /
									(
										{:unknownPrimaryType: '' -> "datatypeRestriction" :}
										{:restriction: datatypeRestriction :}
									) /
									(
										{:unknownPrimaryType: '' -> "literalList" :}
										'{' whitespace* {:list: literalList :} whitespace* '}'
									) /
									(
										{:unknownPrimaryType: '' -> "individualList" :}
										'{' whitespace* {:list: individualList :} whitespace* '}'
									) /
									(
										{:unknownPrimaryType: '' -> "expression" :}
										'(' whitespace*{:expression: unknownExpression :} whitespace* ')'
									) /
									(
										{:unknownPrimaryType: '' -> "IRI" :}
										{:IRI: IRI:}
									)
								)
							) -> {}
	whitespace			<-	(
								%s
							)
]]

local dataRangeGrammar =--added expression as the starting rule
[[
	expression			<-	(
								dataRange?
								!.
							)
	dataRange			<-	(
								{:grammarProduction: '' -> "dataDisjunction" :}
								dataConjunction
								(whitespace+ 'or' whitespace+ dataConjunction)*
							) -> {}
	dataConjunction		<-	(
								{:grammarProduction: '' -> "dataConjunction" :}
								dataPrimary
								(whitespace+ 'and' whitespace+ dataPrimary)*
							) -> {}
	dataPrimary			<-	(
								(
									{:negation: ('not' whitespace+) -> "true" :}
									(
										(
											{:dataPrimaryType: '' -> "datatypeRestriction" :}
											{:restriction: datatypeRestriction :}
										) /
										(
											{:dataPrimaryType: '' -> "datatype" :}
											{:datatype: datatype :}
										) /
										(
											{:dataPrimaryType: '' -> "literalList" :}
											'{' whitespace* {:literalList: literalList :} whitespace* '}'
										) /
										(
											{:dataPrimaryType: '' -> "dataRange" :}
											'(' whitespace* {:dataRange: dataRange :} whitespace* ')'
										)
									)
								) /
								(
									{:negation: '' -> "false" :}
									(
										(
											{:dataPrimaryType: '' -> "datatypeRestriction" :}
											{:restriction: datatypeRestriction :}
										) /
										(
											{:dataPrimaryType: '' -> "datatype" :}
											{:datatype: datatype :}
										) /
										(
											{:dataPrimaryType: '' -> "literalList" :}
											'{' whitespace* {:literalList: literalList :} whitespace* '}'
										) /
										(
											{:dataPrimaryType: '' -> "dataRange" :}
											'(' whitespace* {:dataRange: dataRange :} whitespace* ')'
										)
									)
								)
							) -> {}
	datatype			<-	(
								(
									{:type: '' -> "IRI" :}
									{:value: IRI :}
								) /
								(
									{:type: '' -> "predefined" :}
									{:value: 'integer' :}
								) /
								(
									{:type: '' -> "predefined" :}
									{:value: 'decimal' :}
								) /
								(
									{:type: '' -> "predefined" :}
									{:value: 'float' :}
								) /
								(
									{:type: '' -> "predefined" :}
									{:value: 'string' :}
								)

							) -> {}
	datatypeRestriction	<-	(
								{:datatype: datatype :}
								whitespace* '[' whitespace*
								dataRestriction
								(whitespace* ',' whitespace* dataRestriction)*
								whitespace* ']'
							) -> {}
	dataRestriction		<-	(
								{:facet: facet :}
								whitespace*
								{:value: restrictionValue :}
							) -> {}
	facet				<- 	(
								'<='/
								'<'/
								'>='/
								'>'/
								'length'/
								'maxLength'/
								'minLength'/
								'pattern'/
								'langPattern'
							)
	restrictionValue	<- 	(
								literal
							)
	literalList			<-	(
								literal
								(whitespace* ',' whitespace* literal)+
							) -> {}
	literal				<-	(
								typedLiteral /
								stringLiteralWithLang /
								stringLiteralNoLang /
								floatLiteral /
								decimalLiteral /
								integerLiteral
							)
	typedLiteral		<-	(
								{:type: '' -> "typed" :}
								{:value: quotedString :}
								'^^'
								{:datatype: datatype :}
							) -> {}
	stringLiteralNoLang	<-	(
								{:type: '' -> "stringNoLang" :}
								{:value: quotedString :}
							) -> {}
	stringLiteralWithLang <- (
								{:type: '' -> "stringWithLang" :}
								{:value: quotedString :}
								'@'
								{:language: languageTag :}
							) -> {}
	integerLiteral		<-	(
								{:type: '' -> "integer" :}
								{:value: ('+' / '-')? digit+ :}
							) -> {}
	decimalLiteral		<-	(
								{:type: '' -> "decimal" :}
								{:value: ('+' / '-')? digit+ '.' digit+ :}
							) -> {}
	floatLiteral		<-	(
								{:type: '' -> "float" :}
								{:value: ('+' / '-')? (digit+ '.')? digit+ exponent ('f' / 'F'):}
							) -> {}
	exponent			<-	(
								('e' / 'E') ('+' / '-')? digit+
							)
	digit				<-	(
								[0-9]
							)
	quotedString		<-	(
								'"'
								%quotedStringChars* ('\' ('\' / '"') %quotedStringChars*)*
								'"'
							)
	languageTag			<-	(
								%langTagChars*
							)
	IRI					<-	(
								(
									{:IRItype: '' -> "fullIRI" :}
									{:value: fullIRI :}
								) /
								(
									{:IRItype: '' -> "abbreviatedIRI" :}
									{:value: abbreviatedIRI :}
								) /
								(
									{:IRItype: '' -> "fullNamespaceIRI" :}
									{:value: fullNamespaceIRI :}
								) /
								(
									{:IRItype: '' -> "simpleIRI" :}
									{:value: simpleIRI :}
								)
							) -> {}
	fullIRI				<-	(
								'<'
								%fullIRIChars+
								'>'
							)
	abbreviatedIRI		<-	(
								{:name: localName :}
								'{'
								{:prefix: prefix :}
								'}'
							) -> {}
	fullNamespaceIRI		<-	(
								{:name: localName :}
								'{'
								{:prefix: prefixNamespace :}
								'}'
							) -> {}
	prefix				<-	(
								%pn_chars_base (%pn_chars / '.' / '/' / ':')*
							)
	prefixNamespace				<-	(
								%pn_chars_base (%pn_chars / '.' / '/' / ':')*
							)
	localName			<-	(
								(%pn_chars_base / '_' / '[0-9]') (%pn_chars / '.')*
							)
	simpleIRI			<-	(
								localName
							)
	blankNode			<-	(
								'_:' localName
							)
	whitespace			<-	(
								%s
							)
]]

local classTable =
{
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

local recognizedPrefixList = {"owl2xml", "XMLSchema", "owl", "rdfs", "xsd", "rdf", "xml"}

local builtInDatatypePrefixes =
{
	Literal = "rdfs",
	NCName = "xsd",
	NMTOKEN = "xsd",
	Name = "xsd",
	PlainLiteral = "rdf",
	XMLLiteral = "rdf",
	anyURI = "xsd",
	base64Binary = "xsd",
	boolean = "xsd",
	byte = "xsd",
	dateTime = "xsd",
	dateTimeStamp = "xsd",
	decimal = "xsd",
	double = "xsd",
	float = "xsd",
	hexBinary = "xsd",
	int = "xsd",
	integer = "xsd",
	language = "xsd",
	long = "xsd",
	negativeInteger = "xsd",
	nonNegativeInteger = "xsd",
	nonPositiveInteger = "xsd",
	normalizedString = "xsd",
	positiveInteger = "xsd",
	rational = "owl",
	real = "owl",
	short = "xsd",
	string = "xsd",
	token = "xsd",
	unsignedByte = "xsd",
	unsignedInt = "xsd",
	unsignedLong = "xsd",
	unsignedShort = "xsd",
	date = "xsd",
	time = "xsd"
}

function recognizedPrefix(s)
	for i, prefix in ipairs(recognizedPrefixList) do if s == prefix then return true end end
	return false
end

function printTable(t,indent) --used as test function, not necessary in the final version. Prints a table along with any subtables it may have
--can be used to examine the structure of tables re creates when given the grammar (see end of file for structure description)
	for k,v in pairs(t) do
		if type(v) == "table" then
			s = ""
			for i = 1, indent do s = s.." " end
			print (s..k..": ")
			printTable(v,indent+2)
		else
			s = ""
			for i = 1, indent do s = s.." " end
			print(s..k..": "..v)
		end
	end
end

function generateExpression(t)
	if #t == 1 then --this handles the situation when the expression consists of a single class and we need its declaration expression
		if #(t[1]) == 1 then
			if t[1][1].negation == "false" and t[1][1].primaryType == "atomic" and t[1][1].primary.atomType == "class" then return "Declaration(Class("..generateIRI(t[1][1].primary.class).."))" end
		end
	end
	return generateDisjunction(t)
end

function generateDisjunction(t)
	if t.grammarProduction == "disjunction" then
		if #t == 1 then return generateConjunction(t[1]) end
		s = "ObjectUnionOf("
		for i, conjunction in ipairs(t) do s = s..generateConjunction(t[i])..' ' end
		s = s:sub(1,s:len()-1)
		return s..")"
	end
end

function generateConjunction(t)
	local s = ""
	if t.grammarProduction == "conjunctionWithRestrictions" then
		s = "ObjectIntersectionOf("..generateIRI(t.class)
		for i, restriction in ipairs(t) do s = s..' '..generateRestriction(t[i]) end
		s = s..")"
	else
		if #t == 1 then return generatePrimary(t[1]) end
		s = "ObjectIntersectionOf("
		for i, primary in ipairs(t) do s = s..generatePrimary(t[i])..' ' end
		s = s:sub(1,s:len()-1)..")"
	end
	return s
end

function generatePrimary(t)
	s = ""
	if t.negation == "true" then s = "ObjectComplementOf(" end
	if t.primaryType == "restriction" then s = s..generateRestriction(t.primary) elseif t.primaryType == "atomic" then s = s..generateAtomic(t.primary) end
	if t.negation == "true" then s = s..")" end
	return s
end

function generateRestriction(t)
	if t.keyword == "some" then
		if t.inverse == "true" or isObjectProperty(t.property) or isPrimary(t.value) then
			if t.inverse == "true" then return "ObjectSomeValuesFrom(ObjectInverseOf("..generateIRI(t.property)..') '..generateUOPrimary(t.value)..')'
			else return "ObjectSomeValuesFrom("..generateIRI(t.property)..' '..generateUOPrimary(t.value)..')'
			end
		else return "DataSomeValuesFrom("..generateIRI(t.property)..' '..generateUDPrimary(t.value)..')'
		end
	elseif t.keyword == "only" then
		if t.inverse == "true" or isObjectProperty(t.property) or isPrimary(t.value) then
			if t.inverse == "true" then return "ObjectAllValuesFrom(ObjectInverseOf("..generateIRI(t.property)..') '..generateUOPrimary(t.value)..')'
			else return "ObjectAllValuesFrom("..generateIRI(t.property)..' '..generateUOPrimary(t.value)..')'
			end
		else return "DataAllValuesFrom("..generateIRI(t.property)..' '..generateUDPrimary(t.value)..')'
		end
	elseif t.keyword == "value" then
		if t.inverse == "true" then return "ObjectHasValue(ObjectInverseOf("..generateIRI(t.property)..') '..generateIndividual(t.value)..')'
		else
			if isObjectProperty(t.property) or isIndividual(t.value) then return "ObjectHasValue("..generateIRI(t.property)..' '..generateIndividual(t.value)..')'
			else return "DataHasValue("..generateIRI(t.property)..' '..generateLiteral(t.value)..')'
			end
		end
	elseif t.keyword == "Self" then
		if t.inverse == "true" then return "ObjectHasSelf(ObjectInverseOf ("..generateIRI(t.property)..'))'
		else return "ObjectHasSelf("..generateIRI(t.property)..')' end
	elseif t.keyword == "min" then
		if t.inverse == "true" or isObjectProperty(t.property) or (t.value ~= nil and isPrimary(t.value)) then
			local s = "ObjectMinCardinality("
			s = s..t.count..' '
			if t.inverse == "true" then s = s.."ObjectInverseOf(" end
			s = s..generateIRI(t.property)
			if t.inverse == "true" then s = s..')' end
			if t.value ~= nil then s = s..' '..generateUOPrimary(t.value) end
			s = s..')'
			return s
		else
			local s = "DataMinCardinality("
			s = s..t.count..' '..generateIRI(t.property)
			if t.value ~= nil then s = s..' '..generateUDPrimary(t.value) end
			s = s..')'
			return s
		end
	elseif t.keyword == "max" then
		if t.inverse == "true" or isObjectProperty(t.property) or (t.value ~= nil and isPrimary(t.value)) then
			local s = "ObjectMaxCardinality("
			s = s..t.count..' '
			if t.inverse == "true" then s = s.."ObjectInverseOf(" end
			s = s..generateIRI(t.property)
			if t.inverse == "true" then s = s..')' end
			if t.value ~= nil then s = s..' '..generateUOPrimary(t.value) end
			s = s..')'
			return s
		else
			local s = "DataMaxCardinality("
			s = s..t.count..' '..generateIRI(t.property)
			if t.value ~= nil then s = s..' '..generateUDPrimary(t.value) end
			s = s..')'
			return s
		end
	elseif t.keyword == "exactly" then
		if t.inverse == "true" or isObjectProperty(t.property) or (t.value ~= nil and isPrimary(t.value)) then
			local s = "ObjectExactCardinality("
			s = s..t.count..' '
			if t.inverse == "true" then s = s.."ObjectInverseOf(" end
			s = s..generateIRI(t.property)
			if t.inverse == "true" then s = s..')' end
			if t.value ~= nil then s = s..' '..generateUOPrimary(t.value) end
			s = s..')'
			return s
		else
			local s = "DataExactCardinality("
			s = s..t.count..' '..generateIRI(t.property)
			if t.value ~= nil then s = s..' '..generateUDPrimary(t.value) end
			s = s..')'
			return s
		end
	end
end

function generateIRI(t)
	--[[if t.IRItype == "simpleIRI" and t.value == "Thing" or t.value == "Nothing" then return "owl:"..t.value end
	if t.IRItype == "simpleIRI" then
		if builtInDatatypePrefixes[t.value] ~= nil then return builtInDatatypePrefixes[t.value]..":"..t.value end
		return '<'..namespaceURITable()[""]..t.value..'>'
	end
	if t.IRItype == "fullIRI" then return t.value end
	if not recognizedPrefix(t.value.prefix) then
		return '<'..namespaceURITable()[""]..t.value.name..'>'
		end
	return t.value.prefix..":"..t.value.name]]
	if t.IRItype == "simpleIRI" then
		if t.value == "Thing" or t.value == "Nothing" then return makeFullIRI(namespaceURITable()["owl"], t.value) end --Thing and Nothing must become owl:Thing and owl:Nothing
		local namespace = ""
		local prefix = builtInDatatypePrefixes[t.value]
		if prefix == nil then namespace = namespaceURITable()[""]
		else namespace = namespaceURITable()[prefix]
		end
		return makeFullIRI(namespace,t.value)
	elseif t.IRItype == "abbreviatedIRI" then
		if namespaceURITable()[t.value.prefix] == nil then 
			if string.find(t.value.prefix, ":")~= nil and string.find(t.value.prefix, "//")~= nil then return makeFullIRI(t.value.prefix, t.value.name) end
			return makeFullIRI(namespaceURITable()[""],t.value.name)
		else return makeFullIRI(namespaceURITable()[t.value.prefix],t.value.name)
		end
	elseif t.IRItype == "fullIRI" then
		return t.value
	end
end

function generateDataTypeIRI(t)
	if t.IRItype == "simpleIRI" then
		if t.value == "Thing" or t.value == "Nothing" then return makeFullIRI(namespaceURITable()["owl"], t.value) end --Thing and Nothing must become owl:Thing and owl:Nothing
		local namespace = ""
		local prefix = builtInDatatypePrefixes[t.value]
		if prefix == nil and utilities.current_diagram():find("/element:has(/elemType[id='DataType'])/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") == t.value then 
			prefix = utilities.current_diagram():find("/element:has(/elemType[id='DataType'])/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
		end
		if prefix == nil then namespace = namespaceURITable()[""]
		else namespace = namespaceURITable()[prefix]
		end
		return makeFullIRI(namespace,t.value)
	elseif t.IRItype == "abbreviatedIRI" then
		if namespaceURITable()[t.value.prefix] == nil then 
			if string.find(t.value.prefix, ":")~= nil and string.find(t.value.prefix, "//")~= nil then return makeFullIRI(t.value.prefix, t.value.name) end
			return makeFullIRI(namespaceURITable()[""],t.value.name)
		else return makeFullIRI(namespaceURITable()[t.value.prefix],t.value.name)
		end
	elseif t.IRItype == "fullIRI" then
		return t.value
	end
end

function makeFullIRI(namespace, value)
	if string.sub(namespace, string.len(namespace)) ~= "#" then return '<'..namespace.. "#" ..value..'>' end
	return '<'..namespace..value..'>'
end

function generateAtomic(t)
	if t.atomType == "class" then return generateIRI(t.class)
	elseif t.atomType == "individualList" then return generateIndividualList(t.list)
	elseif t.atomType == "expression" then return generateDisjunction(t.expression)
	end
end

function generateIndividualList(t)
	local s = "ObjectOneOf("
	for i, individual in ipairs(t) do s = s..generateIndividual(t[i])..' ' end
	s = s:sub(1,s:len()-1)
	s = s..")"
	return s
end

function generateIndividual(t)
	if t.individualType == "IRI" then return generateIRI(t.individual)
	elseif t.individualType == "blank" then return t.individual
	end
end

function generateDataPrimary(t)
	local s = ""
	if t.negation == "true" then s = "DataComplementOf(" end
	if t.dataPrimaryType == "datatype" then s = s..generateDatatype(t.datatype)
	elseif t.dataPrimaryType == "datatypeRestriction" then s = s..generateDatatypeRestriction(t.restriction)
	elseif t.dataPrimaryType == "literalList" then s = s..generateLiteralList(t.literalList)
	elseif t.dataPrimaryType == "dataRange" then s = s..generateDataRange(t.dataRange)
	elseif t.primaryType == "atomic" then s = s..generateDatatype(t.primary.class) --this happens when a classExpression turns out to be a data expression
	end
	if t.negation == "true" then s = s..")" end
	return s
end

function generateDatatype(t)
	--if t.type == "predefined" then return "xsd:"..t.value end
	if t.type == "predefined" then return makeFullIRI(namespaceURITable()["xsd"],t.value) end
	if t.type == nil then return generateIRI(t) end --this happens when a classExpression turns out to be a data expression
	

	-- print("t value ")
	-- print(dumptable(t.value))


	-- if (t.value.name == "date") then
 -- 		print("bb ", generateIRI(t.value))

 -- 	end

	return generateDataTypeIRI(t.value)
end

function generateDatatypeRestriction(t)
	local s = "DatatypeRestriction("
	s = s..generateDatatype(t.datatype)
	for i, restriction in ipairs(t) do s = s..' '..generateDataRestriction(t[i]) end
	s = s..')'
	return s
end

function generateDataRestriction(t)
	local s = ""
	local facetIRIs = {}
	facetIRIs[">"] = makeFullIRI(namespaceURITable()["xsd"],"minExclusive")
	facetIRIs[">="] = makeFullIRI(namespaceURITable()["xsd"],"minInclusive")
	facetIRIs["<"] = makeFullIRI(namespaceURITable()["xsd"],"maxExclusive")
	facetIRIs["<="] = makeFullIRI(namespaceURITable()["xsd"],"maxInclusive")
	facetIRIs["langPattern"] = makeFullIRI(namespaceURITable()["rdf"],"langPattern")
	facetIRIs["length"] = makeFullIRI(namespaceURITable()["xsd"],"length")
	facetIRIs["minLength"] = makeFullIRI(namespaceURITable()["xsd"],"minLength")
	facetIRIs["maxLength"] = makeFullIRI(namespaceURITable()["xsd"],"maxLength")
	facetIRIs["pattern"] = makeFullIRI(namespaceURITable()["xsd"],"pattern")
	--[[if t.facet == ">" then s = s.."xsd:maxExclusive "
	elseif t.facet == ">=" then s = s.."xsd:maxInclusive "
	elseif t.facet == "<" then s = s.."xsd:minExclusive "
	elseif t.facet == "<=" then s = s.."xsd:minInclusive "
	elseif t.facet == "langPattern" then s = s.."rdf:langPattern "
	elseif t.facet == "length" or t.facet == "minLength" or t.facet == "maxLength" or t.facet == "pattern" then s = s.."xsd:"..t.facet.." "
	end]]
	s = facetIRIs[t.facet]..' '
	s = s..generateLiteral(t.value)
	return s
end

function generateLiteral(t)
	if t.type == "stringNoLang" then return t.value end
	if t.type == "stringWithLang" then return t.value..'@'..t.language end
	if t.type == "typed" then return t.value..'^^'..generateDatatype(t.datatype) end
	return '"'..t.value..'"^^'..makeFullIRI(namespaceURITable()["xsd"],t.type)
end

function generateLiteralList(t)
	local s = "DataOneOf("
	for i, literal in ipairs(t) do s = s..generateLiteral(t[i])..' ' end
	s = s:sub(1,s:len()-1)
	s = s..")"
	return s
end

function generateDataRange(t)
	if t.grammarProduction == "dataDisjunction" or t.grammarProduction == "disjunction" then
		if #t == 1 then return generateDataConjunction(t[1]) end
		s = "DataUnionOf("
		for i, dataConjunction in ipairs(t) do s = s..generateDataConjunction(t[i])..' ' end
		s = s:sub(1,s:len()-1)
		return s..")"
	end
end

function generateDataConjunction(t)
	if #t == 1 then return generateDataPrimary(t[1]) end
	s = "DataIntersectionOf("
	for i, dataPrimary in ipairs(t) do s = s..generateDataPrimary(t[i])..' ' end
	s = s:sub(1,s:len()-1)
	return s..")"
end

function generateUOPrimary(t) --this is for when the unknownPrimary is a primary
	if t.unknownPrimaryType == "individualList" then return generateIndividualList(t.list) end
	if t.unknownPrimaryType == "restriction" then return generateRestriction(t.restriction) end
	if t.unknownPrimaryType == "expression" then return generateDisjunction(convertToClassExpression(t.expression)) end
	if t.unknownPrimaryType == "IRI" then return generateIRI(t.IRI) end
end

function generateUDPrimary(t) --this is for when the unknownPrimary is a dataPrimary
	if t.unknownPrimaryType == "literalList" then return generateLiteralList(t.list) end
	if t.unknownPrimaryType == "datatypeRestriction" then return generateDatatypeRestriction(t.restriction) end
	if t.unknownPrimaryType == "expression" then return generateDataRange(convertToDataExpression(t.expression)) end
	if t.unknownPrimaryType == "IRI" then return generateIRI(t.IRI) end
end

function isObjectProperty(t) --takes a table obtained as IRI from the grammar. Checks if it is an object property shown in the ontology.
	local result = false
	if t.IRItype == "simpleIRI" then
		lQuery("Element:has(/elemType[id=Association])"):each(
			function(association)
				roleName = association:find("/compartment:has(/compartType[id=Role])/subCompartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Name])"):attr("input")
				invRoleName = association:find("/compartment:has(/compartType[id=InvRole])/subCompartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Name])"):attr("input")
				if roleName == t.value or invRoleName == t.value then 
					result = true 
					return
				end
			end
		)
	elseif t.IRItype == "abbreviatedIRI" then
		lQuery("Element:has(/elemType[id=Association])"):each(
			function(association)
				roleName = association:find("/compartment:has(/compartType[id=Role])/subCompartment:has(/compartType[id=Name])"):attr("input")
				invRoleName = association:find("/compartment:has(/compartType[id=InvRole])/subCompartment:has(/compartType[id=Name])"):attr("input")
				if roleName == t.value.name..'{'..t.value.prefix..'}' or invRoleName == t.value.name..'{'..t.value.prefix..'}' then 
					result = true 
					return 
				end
			end
		)
	elseif t.IRItype == "fullIRI" then
		local ontologyIRI = lQuery("CurrentDgrPointer/graphDiagram"):attr("caption")
		lQuery("Element:has(/elemType[id=Association])"):each(
			function(association)
				roleName = association:find("/compartment:has(/compartType[id=Role])/subCompartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Name])"):attr("input")
				invRoleName = association:find("/compartment:has(/compartType[id=InvRole])/subCompartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Name])"):attr("input")
				if '<'..ontologyIRI..'#'..roleName..'>' == t.value or '<'..ontologyIRI..'#'..invRoleName..'>' == t.value then 
					result = true 
					return
				end
			end
		)
	end
	return result
end

function isPrimary(t) --gets a primary table. Returns true if it's an object primary, false if it's a data primary.
	if t.unknownPrimaryType == "individualList" or t.unknownPrimaryType == "restriction" then return true end
	if t.unknownPrimaryType == "IRI" and not (isDatatype(t.IRI)) then return true end
	if t.unknownPrimaryType == "expression" then return isClassExpression(t.expression) end
	return false
end

function isClassExpression(t) --gets an unknown expression table. If the expression contains any conjunctions with restrictions, it must be a
--class expression. Otherwise, returns true/false based on the first subexpression that can be definitively identified as a class/data expression
	for i, conjunction in ipairs(t) do
		if conjunction.grammarProduction == "conjunctionWithRestrictions" then return true end
	end
	for i, conjunction in ipairs(t) do
		if conjunction.grammarProduction == "unknownConjunction" and isObjectConjunction(conjunction) then return true end
		if conjunction.grammarProduction == "unknownConjunction" and isDataConjunction(conjunction) then return false end
	end
	return false
end

function isObjectConjunction(t)
	for i, primary in ipairs(t) do
		if primary.unknownPrimaryType == "restriction" or primary.unknownPrimaryType == "individualList" then return true end
	end
	for i, primary in ipairs(t) do
		if primary.unknownPrimaryType == "expression" then return isClassExpression(primary) end
	end
	for i, primary in ipairs(t) do
		if primary.unknownPrimaryType == "IRI" and not isDatatype(primary.IRI) then return true end
	end
	return false
end

function isDataConjunction(t)
	for i, primary in ipairs(t) do
		if primary.unknownPrimaryType == "datatypeRestriction" or primary.unknownPrimaryType == "literalList" then return true end
	end
	for i, primary in ipairs(t) do
		if primary. unknownPrimaryType == "expression" then return not(isClassExpression(primary)) end
	end
	for i, primary in ipairs(t) do
		if primary.unknownPrimaryType == "IRI" and isDatatype(primary.IRI) then return true end
	end
	return false
end

function isDatatype(t) --the function is passed an IRI table. If it's a simpleIRI with a value integer, decimal, float or string, it's a datatype
	--otherwise, check all datatypes defined in the ontology.
	--if t.value == "integer" or t.value == "float" or t.value == "decimal" or t.value == "string" then return true end
	if isPredefinedDatatype(t) then return true end
	local isDType = false
	if t.IRItype == "simpleIRI" then
		lQuery("Element:has(/elemType[id=DataType])/compartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Name])"):each(
			function(compartment)
				if compartment:attr("input") == t.value then
					isDType = true
					return true
				end
			end
		)
	elseif t.IRItype == "abbreviatedIRI" then
		lQuery("Element:has(/elemType[id=DataType])/compartment:has(/compartType[id=Name])"):each(
			function(compartment)
				if compartment:attr("input") == t.value.name..'{'..t.value.prefix..'}' then
					isDType = true
					return true
				end
			end
		)
	elseif t.IRItype == "fullIRI" then
		local ontologyIRI = lQuery("CurrentDgrPointer/graphDiagram"):attr("caption")
		lQuery("Element:has(/elemType[id=DataType])/compartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Name])"):each(
			function(compartment)
				if '<'..ontologyIRI..'#'..compartment:attr("input")..'>' == t.value then
					isDType = true
					return true
				end
			end
		)
	end
	return isDType
end

function isIndividual(t)
	if t.individualType == nil then return false end
	return true
end

function parseClassExpression(expression, diagram, t)
	if expression == "" then return nil end
	init_namespaceURITable(t)

	local s = dropWhitespaces(expression) --whitespaces before commas are a bit difficult to handle, remove them
	local g = re.compile(classExpressionGrammar,classTable)
	local t = g:match(s)

	--if type(t) == "table" then printTable(t,0) end
	if t == nil then return nil else return generateDisjunction(t) end
end

function parseSchemaExpression(expression, classFullName)
	if expression == "" then return nil end

	local propertyTable = {}
	
	local s = dropWhitespaces(expression) --whitespaces before commas are a bit difficult to handle, remove them
	local g = re.compile(classExpressionGrammar,classTable)
	local t = g:match(s)
	-- print(dumptable(t), #t, #t[1])
	if #t == 1 then
		for i, j in ipairs(t[1]) do 
			if (t[1][i]["negation"] == nil or t[1][i]["negation"] == "false") and t[1][i]["primaryType"]~= nil and t[1][i]["primaryType"] == "restriction" then
				if t[1][i]["primary"]~= nil and t[1][i]["primary"]["keyword"]~= nil then 
					if t[1][i]["primary"]["keyword"] == "some" or t[1][i]["primary"]["keyword"] == "value" or t[1][i]["primary"]["keyword"] == "Self" then
						table.insert(propertyTable, t[1][i]["primary"]["property"]["value"])
					elseif (t[1][i]["primary"]["keyword"] == "min" or t[1][i]["primary"]["keyword"] == "exactly") and t[1][i]["primary"]["count"] ~= nil and tonumber(t[1][i]["primary"]["count"]) > 0 then
						table.insert(propertyTable, t[1][i]["primary"]["property"]["value"])
					end
				end
			end
		end
	-- multiple OR
	elseif #t > 1 then
	-- TODO
	end
	return propertyTable
end

function parseDatatypeRestriction(s, diagram, t)
	if s == "" then return nil end
	init_namespaceURITable(t)
	local g = re.compile(dataRangeGrammar, classTable)
	local t = g:match(s)
	--if t ~= nil then printTable(t,0) end
	--if t == nil then return nil else return generateDatatypeRestriction(t) end
	-- print(dumptable(t), generateDataRange(t))
	if t == nil then return nil else return generateDataRange(t) end
end


function convertToClassExpression(t) --takes an unknown expression table and converts it to a class expression table
	t.grammarProduction = "disjunction"
	for i, conjunction in ipairs(t) do conjunction = convertToObjectConjunction(conjunction) end
	return t
end

function convertToObjectConjunction(t)
	if t.grammarProduction == "unknownConjunction" then
		t.grammarProduction = "conjunctionNoRestrictions"
		for i, primary in ipairs(t) do primary = convertToObjectPrimary(primary) end
	end
	return t
end

function convertToObjectPrimary(t)
	if t.unknownPrimaryType == "restriction" then
		t.primaryType = "restriction"
		t.unknownPrimaryType = nil
		t.primary = t.restriction
		t.restriction = nil
		return t
	elseif t.unknownPrimaryType == "individualList" then
		t.primaryType = "atomic"
		t.primary =
		{
			atomType = "individualList",
			list = t.list
		}
		t.list = nil
		t.unknownPrimaryType = nil
		return t
	elseif t.unknownPrimaryType == "expression" then
		t.primaryType = "atomic"
		t.primary =
		{
			atomType = "expression",
			expression = convertToClassExpression(t.expression)
		}
		t.expression = nil
		t.unknownPrimaryType = nil
		return t
	elseif t.unknownPrimaryType == "IRI" then
		t.primaryType = "atomic"
		t.primary =
		{
			atomType = "class",
			class = t.IRI
		}
		t.IRI = nil
		t.unknownPrimaryType = nil
		return t
	end
end

function convertToDataExpression(t) --takes an unknown expression table and converts it to a data expression table
	t.grammarProduction = "dataDisjunction"
	for i, conjunction in ipairs(t) do conjunction = convertToDataConjunction(conjunction) end
	return t
end

function convertToDataConjunction(t)
	t.grammarProduction = "dataConjunction"
	for i, primary in ipairs(t) do primary = convertToDataPrimary(primary) end
	return t
end

function convertToDataPrimary(t)
	if t.unknownPrimaryType == "datatypeRestriction" then
		t.dataPrimaryType = "datatypeRestriction"
		t.unknownPrimaryType = nil
		return t
	elseif t.unknownPrimaryType == "literalList" then
		t.dataPrimaryType = "literalList"
		t.unknownPrimaryType = nil
		t.literalList = t.list
		t.list = nil
		return t
	elseif t.unknownPrimaryType == "expression" then
		t.dataPrimaryType = "dataRange"
		t.unknownPrimaryType = nil
		t.dataRange = convertToDataExpression(t.expression)
		t.expression = nil
		return t
	elseif t.unknownPrimaryType == "IRI" then
		t.dataPrimaryType = "datatype"
		t.datatype = t.IRI
		t.unknownPrimaryType = nil
		t.IRI = nil
		return t
	end
end

function dropWhitespaces(expression)
	local s = expression
	s = s:gsub(" ,", ",")
	s = s:gsub("\n,", ",")
	s = s:gsub("\t,", ",")
	if s ~= expression then s = dropWhitespaces(s) end
	return s
end

function verifyManchester(compartment)
	print ("*******")
	print (compartment:find("/compartType"):attr("id"))
	print ("Input", compartment:attr("input"))
	print ("Value", compartment:attr("value"))
	print ("*******")
	compartment:find("/parentCompartment/parentCompartment/component"):attr({outlineColor = 255, hint = "hint"})
end

local d = require("dialog_utilities")
function color(compartment)
	if compartment:attr("input") ~= "" then
		--[[print ("&&&&&&&&&&&&&")
		lQuery("ElemType[id=Class]/compartType"):each(
			function (elt)
				print ("##########")
				print (elt:attr("id"))
				if elt:find("/component"):is_not_empty() then print (elt:find("/component"):get(1):class().name())
			end
		)
		print ("&&&&&&&&&&&&&")]]
		local comp = compartment:find("/component")
		--comp:attr({outlineColor = 255, hint = "hint"})
		comp:find("/container/container/component/component"):each(
			function(component)
				print ("***************")
				print ("Component:", component:get(1):class().name, component:attr("id"))
				print ("Compartment:", component:find("/compartment/compartType"):attr("id"))
				print ("***************")
				--component:log("id")
				component:attr({outlineColor = 255, hint = "hint"})
				d.refresh_form_component(component)
				--print ("something something")
			end
		)
		--d.refresh_form_component(comp)
	end
end


--this part handles attribute types - determines whether the type is an object expression (and the attribute is an ObjectProperty) or a data expression (and the attribute is a DatatypeProperty).
local IRIlist = {} --this table will contain all IRIs in the currently processed attribute type expression

function generateAttributeType(attrType, diagram, t, classList, datatypeList, isObjectAttribute)
	
	-- print(dumptable(datatypeList), "")
	if isObjectAttribute~=nil then
		if isObjectAttribute:attr("value") == "true" then
			local attrAsObjProp = parseClassExpression(attrType, diagram, t)
			return attrAsObjProp, "ObjectProperty"
		else
			local attrAsDataProp = parseDatatypeRestriction(attrType, diagram, t)
			return attrAsDataProp, "DataProperty"
		end
	end
	
	--attempt both parsers
	local attrAsObjProp = parseClassExpression(attrType, diagram, t)
	local attrAsDataProp = parseDatatypeRestriction(attrType, diagram, t)

	--if neither parsing succeeded, the expression is incorrect.
	if attrAsObjProp == nil and attrAsDataProp == nil then return nil, nil end

	--if only one parsing succeeded, that's the kind of expression to use.
	if attrAsObjProp ~= nil and attrAsDataProp == nil then return attrAsObjProp, "ObjectProperty" end
	if attrAsObjProp == nil and attrAsDataProp ~= nil then return attrAsDataProp, "DataProperty" end

	--if both parsings succeeded, the expression is a mix of conjunctions/disjunctions. Return based on the first IRI that can be conclusively identified as a class or datatype.
	if classList == nil then classList = getAllClasses(diagram:find("/element:has(/elemType[id=Class])")) end
	if datatypeList == nil then datatypeList = getAllDatatypes(diagram:find("/element:has(/elemType[id=DataType])")) end
	--parse the type expression again, but do not generate functional syntax from the parser-returned table
	init_namespaceURITable(t)

	local s = dropWhitespaces(attrType) --whitespaces before commas are a bit difficult to handle, remove them
	local g = re.compile(classExpressionGrammar,classTable)
	local tt = g:match(s)
	--at this point, t contains the parser-returned table. We need to get all IRI subtables from it and match them against the known classes and datatypes
	IRIlist = {}
	getAllIRIs(tt)
	for i, tab in pairs(IRIlist) do --if the expression mentions one of the predefined datatypes, it's a datatype expression
		--if tab.IRItype == "simpleIRI" and (tab.value == "integer" or tab.value == "decimal" or tab.value == "float" or tab.value == "string") then return attrAsDataProp, "DataProperty" end
		if isPredefinedDatatype(tab) then return attrAsDataProp, "DataProperty" end
	end

	for i, tab in pairs(IRIlist) do --go through all IRIs in the table. Return value based on the first IRI that can definitely be identified
		local thisIRI = generateIRI(tab)
		for i, classTab in pairs(classList) do
			if thisIRI == generateIRI(classTab) then return attrAsObjProp, "ObjectProperty" end
		end

		for i, datatypeTab in pairs(datatypeList) do
			if thisIRI == generateIRI(datatypeTab) then return attrAsDataProp, "DataProperty" end
		end
	end

	--if no IRI can be identified, assume data property
	return attrAsDataProp, "DataProperty"

end

function getAllClasses(classesAll) --function returns a table with all class names/namespaces in the given diagram. Returns the same kind of table that the parser returns, to work with generateIRI.
	local classes = {}
	classesAll:each(
		function(class)
			className = class:find("/compartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Name])"):attr("value")
			classNamespace = class:find("/compartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Namespace])"):attr("value")
			local IRItable = {}
			if classNamespace == nil or classNamespace == "" then
				IRItable.IRItype = "simpleIRI"
				IRItable.value = className
			else
				IRItable.IRItype = "abbreviatedIRI"
				IRItable.value = {name = className, prefix = classNamespace}
			end
			table.insert(classes, IRItable)
		end
	)
	-- print(dumptable(classes))
	return classes
end

function getAllDatatypes(dataTypesAll) --function returns a table with all datatype names/namespaces in the given diagram. Returns the same kind of table that the parser returns, to work with generateIRI.
	local datatypes = {}
	-- diagram:find("/element:has(/elemType[id=DataType])"):each(
	dataTypesAll:each(
		function(dt)
			DTName = dt:find("/compartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Name])"):attr("value")
			DTNamespace = dt:find("/compartment:has(/compartType[id=Name])/subCompartment:has(/compartType[id=Namespace])"):attr("value")
			local IRItable = {}
			if DTNamespace == nil or DTNamespace == "" then
				IRItable.IRItype = "simpleIRI"
				IRItable.value = DTName
			else
				IRItable.IRItype = "abbreviatedIRI"
				IRItable.value = {name = DTName, prefix = DTNamespace}
			end
			table.insert(datatypes, IRItable)
		end
	)
	return datatypes
end

function getAllIRIs(t) --function receives a table generated by the OWL Manchester parser, adds all IRI subtables in it to the global IRIlist table
	if t.IRItype ~= nil then table.insert(IRIlist, t)
	else
		for i, tab in pairs(t) do if type(tab) == "table" then getAllIRIs(tab) end end
	end
end

function isPredefinedDatatype(t) --function receives an IRI table from the Manchester syntax parser. Returns true iff the IRI is a predefined datatype in OWLGrEd (datatype list is made manually)
--function uses the builtInDatatypePrefixes table - that contains the predefined datatypes and their prefixes
	if t.IRItype == "simpleIRI" then
		if builtInDatatypePrefixes[t.value] ~= nil then return true else return false end
	end
	if t.IRItype == "abbreviatedIRI" then
		if builtInDatatypePrefixes[t.value.name] ~= nil and builtInDatatypePrefixes[t.value.name] == builtInDatatypePrefixes[t.value.prefix] then  return true else return false end
	end
	if t.IRItype == "fullIRI" then
		for name, prefix in pairs(builtInDatatypePrefixes) do
			if makeFullIRI(namespaceURITable()[prefix], name) == t.value then return true else return false end --generate full IRIs for all predefined datatypes, compare them with the one we're checking
		end
	end
end

--end attribute type handling
