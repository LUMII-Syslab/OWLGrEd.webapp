module(..., package.seeall)

require "lpeg"
require "core"
tda = require "tda_to_protege"
specific = require "OWL_specific"

--OWL specific parsers

--functions returns all datatypes
function get_data_types()
	return lpeg.C("ENTITIES") + lpeg.C("ENTITY") + lpeg.C("ID") + lpeg.C("IDREFS") + lpeg.C("IDREF")  + lpeg.C("Literal") + lpeg.C("NCName") +
	lpeg.C("NMToken") + lpeg.C("NOTATION") + lpeg.C("Name") + lpeg.C("QName") + lpeg.C("XMLLiteral") + lpeg.C("anySimpleType") + lpeg.C("anyType") +
	lpeg.C("anyURI") + lpeg.C("base64Binary") + lpeg.C("boolean") + lpeg.C("byte") + lpeg.C("dateTimeStamp") + lpeg.C("dateTime") + lpeg.C("date") +
	lpeg.C("decimal") + lpeg.C("double") + lpeg.C("duration") + lpeg.C("float") + lpeg.C("gDay") + lpeg.C("gMontYear") + lpeg.C("gMonth") +
	lpeg.C("gYearMonth") + lpeg.C("gYear") + lpeg.C("hexBinary") + lpeg.C("integer") + lpeg.C("int") + lpeg.C("language") + lpeg.C("long") +
	lpeg.C("negativeInteger") + lpeg.C("nonNegativeInteger") + lpeg.C("nonPositiveInteger") + lpeg.C("normalizedString") + lpeg.C("positiveInteger") + 
	lpeg.C("short") + lpeg.C("string") + lpeg.C("time") + lpeg.C("token") + lpeg.C("unsignedByte") + lpeg.C("unsignedInt") + lpeg.C("unsignedLong") + 
	lpeg.C("unsignedShort") + get_user_defined_data_types()
end

function get_user_defined_data_types()
	local result = ""
	utilities.current_diagram():find("/element:has(/elemType[id = 'DataType'])"):each(function(data_type)
		local name = data_type:find("/compartment/subCompartment:has(/compartType[id = 'Name'])"):attr_e("value")
		if result == "" then
			result = lpeg.C(name)
		else
			result = result + lpeg.C(name)
		end
	end)
return result
end

function new_manchester_parser(compart)
	local str = compart:attr_e("value")
	if str == "" then
		return "-1", str
	end

--terminals
	local SpaceO = (lpeg.S(" \n\t") + lpeg.C('\\') * lpeg.C('n')) ^ 0
	local Space = (lpeg.S(" \n\t") + lpeg.C('\\') * lpeg.C('n')) ^ 1
	local SpaceEnd = Space + -lpeg.P(1)
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.S("āēīūčģķļņšž") + lpeg.S("ĀĒĪŪČĢĶĻŅŠŽ") + lpeg.S("_-&.")
	local LetterDigit = Letter + lpeg.R("09")
	local String = lpeg.C(LetterDigit * (LetterDigit) ^ 0)
	local Number = lpeg.C(lpeg.R("09")^1 * lpeg.R("09") ^ 0)
	local zero = lpeg.C("0")
	local nonZero = lpeg.R("19")
	local digit = zero + nonZero
	local digits = digit * digit ^ 0
	local positiveInteger = nonZero * digit ^ 0
	local nonNegativeInteger = Number --(zero + positiveInteger) ^ 1
	local Min = lpeg.C("min")
	local Max = lpeg.C("max")
	local Exactly = lpeg.C("exactly")
	local min_max_exactly = cg(Min + Max + Exactly, "Cardinality") * Space
	local Some = lpeg.C("some")
	local Only = lpeg.C("only")
	local Self = lpeg.C("Self") * SpaceEnd
	local Value = lpeg.P("value")
	local inverse = lpeg.P("inverse") * Space
	local Not = lpeg.P("not")
	local And = lpeg.C("and") 
	local Or = lpeg.C("or")
	local open = lpeg.P("(") * SpaceO
	local close = SpaceO * lpeg.P(")")
	local openB = lpeg.P("{") * SpaceO
	local closeB = SpaceO * lpeg.P("}")
	local openSq = lpeg.P("[") * SpaceO
	local closeSq = SpaceO * lpeg.P("]")
	local that = lpeg.P("that") * Space
	local IRI = String --+ lpeg.C(lpeg.C("<") * String * lpeg.C(">"))
	local ns = SpaceO * cg(openB * String * closeB * SpaceEnd + lpeg.Cc("") * SpaceO, "Namespace")
	
	local dataType = cg(ct(cg(get_data_types(), "Value") * ns), "DataType") 
	local quotedString = cg(lpeg.C(lpeg.C('"') * String * lpeg.C('"')), "QuotedString")
	local typedLiteral = ct(quotedString * SpaceO * lpeg.P("^^") * SpaceO * dataType)
	local stringLiteralNoLanguage = ct(quotedString)
	local stringLiteralWithLanguage = ct(quotedString * Space * lpeg.P("@")) --* cg(String, "Language") * Space
	local plusMinus = (lpeg.C("+") + lpeg.C("-")) 
	local plusMinusO = plusMinus ^ -1
	local point = lpeg.C(".")
	local exponent = lpeg.C((lpeg.C("e") + lpeg.C("E")) * SpaceO * plusMinus * SpaceO * digits)
	local integerLiteral = ct_cg(lpeg.C(plusMinusO * digits), "Value")
	local floatingPointLiteral = ct_cg(lpeg.C(plusMinusO * SpaceO * ((digits * (point * digits) ^ -1 * SpaceO * exponent ^ -1) + (point * digits * SpaceO * exponent ^ -1))), "Value") * SpaceO * (lpeg.C("f") + lpeg.C("F"))
	local decimalLiteral = ct_cg(lpeg.C(plusMinusO * SpaceO * digits * point * digits), "Value")
	local literal = ct(lpeg.P(cg(typedLiteral, "TypedLiteral") + cg(stringLiteralWithLanguage, "WithLanguage") + cg(stringLiteralNoLanguage, "NoLanguage") + cg(floatingPointLiteral, "Floating") + cg(decimalLiteral, "Decimal") + cg(integerLiteral, "Integer")))
	local individual = ct(cg(IRI, "Individ") * SpaceO * ns) 
	local comma = lpeg.S(",") * SpaceO
	local individualList = ct(individual * (comma * individual) ^ 0)
	local literalList = cg_ct(literal * (comma * literal) ^ 0, "LiteralList")
	local facet = cg(lpeg.C("length") + lpeg.C("minLength") + lpeg.C("maxLength") + lpeg.C("pattern") + lpeg.C("langPattern") + lpeg.C(">=") + lpeg.C(">") + lpeg.C("<=") + lpeg.C("<"), "Facet") * SpaceO
	local restrictionValue = cg(literal, "RestrictionValue") * SpaceO
	local dataTypeRestriction = cg_ct(dataType * SpaceO * openSq * ct(facet * restrictionValue) * ct(comma * facet * restrictionValue) ^ 0 * closeSq, "DataTypeRestriction")

--non-terminals
	local Conjunction = lpeg.V"Conjunction"
	local Expr = lpeg.V"Expr"
	local Restrictions = lpeg.V"Restrictions"
	local NegativeRestriction = lpeg.V"NegativeRestriction"
	local Restriction = lpeg.V"Restriction"	
	local Atomics = lpeg.V"Atomics"
	local NegativeFullAtomic = lpeg.V"NegativeFullAtomic"
	local FullAtomic = lpeg.V"FullAtomic"
	local Atomic = lpeg.V"Atomic"
	local BothPrimaries = lpeg.V"BothPrimaries"
	local Primaries = lpeg.V"Primaries"
	local DataPrimaries = lpeg.V"DataPrimaries"
	local Primary = lpeg.V"Primary"
	local DataPrimary = lpeg.V"DataPrimary"
	local NegativePrimary = lpeg.V"NegativePrimary"
	local NegativeDataPrimary = lpeg.V"NegativeDataPrimary"
	local FullAtomic = lpeg.V"FullAtomic"
	local SingleAtomic = lpeg.V"SingleAtomic"
	local ComplexAtomic = lpeg.V"ComplexAtomic"
	local FullDataAtomic = lpeg.V"FullDataAtomic"
	local SingleDataAtomic = lpeg.V"SingleDataAtomic"
	local ComplexDataAtomic = lpeg.V"ComplexDataAtomic"
	local DataExpression = lpeg.V"DataExpression"
	local NotComplexDataExpression = lpeg.V"NotComplexDataExpression"	
	local DataRange = lpeg.V"DataRange"
	local NegativeSingleDataAtomic = lpeg.V"NegativeSingleDataAtomic"
	local NegativeComplexDataAtomic = lpeg.V"NegativeComplexDataAtomic"
	local Literal = lpeg.V"Literal"
	local Individual = lpeg.V"Individual"
	local PropertyIRI = lpeg.V"PropertyIRI"
	local InverseProperty = lpeg.V"InverseProperty"
	local ClassExpr = lpeg.V"ClassExpr"
	local That = lpeg.V"That"
	--local A = lpeg.V"A"

	local G = lpeg.P{
		Expr,
		Expr = ct(ct(Conjunction) * ((And + Or) * ct(Space * (That + Restrictions + NegativeFullAtomic + SingleAtomic) + SpaceO * ComplexAtomic)) ^ 0);
		Conjunction = That + Restrictions + Atomics;
		Restrictions = NegativeRestriction + Restriction;
		NegativeRestriction = cg(Not * Space * ct(ct(Restriction)), "Negation");
		Restriction = 
			cg(ct(InverseProperty * min_max_exactly * cg(nonNegativeInteger, "Number") * (Primaries - (Space * (And + Or)) + SpaceO)), "CardinalityExpression")
			+ cg(ct(InverseProperty), "SelfExpression") * Self
			+ cg(ct(InverseProperty * cg((Some + Only), "Cardinality") * Primaries), "SomeExpression")
			+ cg(ct(InverseProperty * cg(Value, "Value") * cg(individual, "Individual")), "ValueExpression")
			
			+ cg(ct(PropertyIRI * min_max_exactly * cg(nonNegativeInteger, "Number") * (BothPrimaries - (Space * (And + Or)) + SpaceO)), "CardinalityExpression")
			+ cg(ct(PropertyIRI), "SelfExpression") * Self
			+ cg(ct(PropertyIRI * cg((Some + Only), "Cardinality") * BothPrimaries), "SomeExpression")
			+ cg(ct(PropertyIRI * Value * (Literal * -(Letter) + Individual)), "ValueExpression");
		
		--NegativeRestriction = cg(Not * SpaceO * ct(ct(Space * (Restriction + ClassExpr) + SpaceO * Atomic)), "Negation");

		Atomics = NegativeFullAtomic + FullAtomic;
		NegativeFullAtomic = cg(Not * (SpaceO * ct(ct(SingleAtomic)) + SpaceO * ct(ct(ComplexAtomic))), "Negation");

		BothPrimaries = Primaries + DataPrimaries;
		
		DataPrimaries = NegativeDataPrimary + DataPrimary;
		NegativeDataPrimary = cg(Space * Not * ct_cg(Space * ct(SingleDataAtomic) + SpaceO * ct(ComplexDataAtomic), "DataPrimary"), "Negation");
		DataPrimary = cg(Space * ct(ComplexDataAtomic) + SpaceO * ct(SingleDataAtomic), "DataPrimary");

		FullDataAtomic = SingleDataAtomic + ComplexDataAtomic;
		SingleDataAtomic = dataTypeRestriction + dataType * -(LetterDigit);--  * SpaceEnd;
		ComplexDataAtomic = (open * DataRange * close + openB * literalList * closeB) * SpaceO;

		NegativeSingleDataAtomic = cg(Not * Space * ct(SingleDataAtomic), "Negation");
		NegativeComplexDataAtomic = cg(Not * SpaceO * ct(ComplexDataAtomic), "Negation");
		
		DataRange = cg(ct(ct(DataExpression) * SpaceO * ((And + Or) * ct_cg(Space * NotComplexDataExpression + SpaceO * ct(ComplexDataAtomic), "DataPrimary")) ^ 0 * SpaceO), "DataRange");
		DataExpression = cg(NotComplexDataExpression + ct(ComplexDataAtomic), "DataPrimary") * SpaceO;
		NotComplexDataExpression = ct(NegativeSingleDataAtomic + NegativeComplexDataAtomic + dataTypeRestriction + dataType * SpaceO) * SpaceO;

		Primaries = NegativePrimary + Primary;
		NegativePrimary = cg(Space * Not * ct_cg(Space * ct(cg_ct(Restriction, "PrimaryExpression") + SingleAtomic) + SpaceO * ct(ComplexAtomic), "Primary"), "Negation");
		Primary = cg(ct(Space * SingleAtomic + SpaceO * cg(ct(ComplexAtomic), "PrimaryExpression")), "Primary");

		FullAtomic = SingleAtomic + ComplexAtomic;
		SingleAtomic = ClassExpr;
		ClassExpr = cg(ct(cg(String, "Class") * ns), "ClassExpression");
		ComplexAtomic = (openB * cg(individualList, "IndividualList") * closeB + cg(open * Expr * close, "Paranthesis")) * SpaceO;

		Literal = Space * cg(literal, "Literal");
		Individual = Space * cg(individual, "Individual");

		InverseProperty = inverse * cg(IRI, "InverseProperty") * ns;
		PropertyIRI = cg(IRI, "PropertyValue") * ns;
		That = cg(ct(ClassExpr * that * cg(Expr, "Restriction")), "That");
	}
	G = SpaceO * G * -1
	local res = lpeg.match(G, str)

	return res, str
end

function ct(pattern)
	return lpeg.Ct(pattern)
end

function cg(pattern, pattern_name)
	return lpeg.Cg(pattern, pattern_name)
end

function ct_cg(pattern, pattern_name)
	return ct(cg(pattern, pattern_name))
end

function cg_ct(pattern, pattern_name)
	return cg(ct(pattern), pattern_name)
end

function split (s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)

  local p = lpeg.Ct(elem * (sep * elem)^0)   -- make a table capture
  return lpeg.match(p, s)
end


function check_validity(compart)
	log("check validityyy")
	log("value " .. compart:attr_e("input"))
	local res = Manchester_parser(compart:attr("input"))
	--log(dumptable(res))
	local buls = "false"
	if res ~= nil then 
		log("syntax is correct")
		local all_prop_names = tda.get_all_property_names()
		local all_attr_names = tda.get_all_attr_names()
		for i, tmp_obj_prop in pairs(res) do
			if tmp_obj_prop['ObjectProp'] ~= nil or tmp_obj_prop['ClassObjectProp'] ~= nil then
				if tmp_obj_prop['ClassObjectProp'] ~= nil then
					local tmp_obj = tmp_obj_prop['ClassObjectProp']['Property']
					local tmp_class = tmp_obj_prop['ClassObjectProp']['Class']
					local bulss = is_class_with_attr(tmp_class, tmp_obj, "CurrentDgrPointer/graphDiagram/element:has(/elemType[id = 'Class'])",
					"/compartment/subCompartment:has(/compartType[id = 'Class'])", "/compartment/subCompartment/subCompartment:has(/compartType[id = 'Name'])", 0)
					if bulss == "false" then
						bulss = is_class_with_attr(tmp_class, tmp_obj, "CurrentDgrPointer/graphDiagram/element:has(/elemType[id = 'Association'])",
						"/start/compartment/subCompartment:has(/compartType[id = 'Class'])", "/compartment:has(/compartType[id = 'Name'])", 1)
						if bulss == "false" then
							bulss = is_class_with_attr(tmp_class, tmp_obj, "CurrentDgrPointer/graphDiagram/element:has(/elemType[id = 'Association'])",
							"/end/compartment/subCompartment:has(/compartType[id = 'Class'])", "/compartment:has(/compartType[id = 'InvName'])", 1)
						end
					end
					buls = bulss
				else
					if tmp_obj_prop['ObjectProp'] ~= nil then
						local tmp_obj = tmp_obj_prop['ObjectProp']
						buls = tda.is_single_attr(all_prop_names, tmp_obj)
						if buls == "false" or buls == "nil" then
							local tmp_buls = tda.is_single_attr(all_attr_names, tmp_obj)
							if tmp_buls == "true" or (buls == "nil" and tmp_buls == "false") then 
								buls = tmp_buls
							end
						end
					end
				end
			end
		end
	else
		return "Syntax error"
	end
		--log("semantic is " .. buls)
		log("ok")
	return ""
end

function is_class_with_attr(tmp_class, tmp_obj, path_to_element, path_to_element_name, path_to_prop_name, tail)
	local buls = "false"
	lQuery(path_to_element):each(function(elem, i)
		elem = lQuery(elem)
		local elem_name = elem:find(path_to_element_name):attr("input")
		if elem_name == tmp_class then
			elem:find(path_to_prop_name):each(function(attribute, i)
				attribute = lQuery(attribute)
				local len = string.len(attribute:attr("input"))
				local tmp_attr = string.sub(attribute:attr("input"), 1, len-tail)
				if tmp_attr == tmp_obj then
					buls = "true"
					return false
				end
			end)
			return false
		end
	end)
	return buls
end

function add_axioms(table)
end

function check_syntax(compart)
--get active compartment
--apply syntax checker function
--if incorrect, block the field and mark it red
	log("check syntaxx")
	local field = compart:find("/component"):log()
	if field:attr("text") == "aa" then 
		return ""
	else
		return "false"
	end	
end

