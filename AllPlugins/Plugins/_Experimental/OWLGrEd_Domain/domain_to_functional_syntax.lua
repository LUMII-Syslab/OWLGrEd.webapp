module(..., package.seeall)

axioms_table = {
	"OWL#Declaration",
	"OWL#ClassAxiom",
	"OWL#ObjectPropertyAxiom",
	"OWL#DataPropertyAxiom",
	"OWL#DatatypeDefinition",
	"OWL#HasKey",
	"OWL#Assertion",
	"OWL#AnnotationAxiom"
}

local axioms_string = ""

function export_ontology_to_functional_syntax(ontology)
	local axioms = ontology:find("/axioms")

	for _, axiom in pairs(axioms_table) do
		axioms_to_functional(lQuery(axioms:find("."..axiom)))
	end
	print (axioms_string)
	--local file = io.open("axioms.txt","w")
	io.output("axioms.txt")
	--file:write(axioms_sting)
	io.write(axioms_string)
	io.close()
end

function prefixes_to_functional(ontology)
	--
end

function axioms_to_functional(axioms)
	axioms:each(
		function(axiom)
			local str = render_instance(axiom)
			--print("\n"..str)
			axioms_string = axioms_string.."\n"..str
		end)
end

function render_instance(instance, from_declaration)
	local class_name = instance:get(1):class().name
	class_name = string.sub(sub_string_for_entity(class_name), 5)

	local is_entity = is_entity_class(class_name)
	local is_declaration = is_declaration_class(class_name)
	local is_facet_restriction = is_facet_restriction_class(class_name)
	local is_annotation_related = is_annotation_argument(class_name)
	local str

	--[[
	if from_declaration or not is_entity or not is_facet_restriction then
		str = class_name.."("
	else
		str = ""
	end
	]]

	if (is_annotation_related or is_facet_restriction or is_entity) and not from_declaration then
		str = ""
	else
		str = class_name.."("
	end

	if class_name == "IRI" then
		return render_iri(instance)
	end

	-- attribute for Object/Data Min/Max/Exact Cardinality axioms
	if class_name:sub(-11) == "Cardinality" then
		str = str..instance:attr("cardinality").." "
	end

	if class_name == "Literal" then
		if instance:attr("language") ~= "" then return '"'..instance:attr("text")..'"@'..instance:attr("language") end
		if instance:find("/datatype"):is_not_empty() then return '"'..instance:attr("text")..'"^^'..render_instance(instance:find("/datatype")) end
		return '"'..instance:attr("text")..'"'
	end

	if class_name == "AnonymousIndividual" then str = str..instance:attr("nodeID").." " end

	for _, link in pairs(links_of_class(class_name)) do
		if class_name == "HasKey" and link ~= "classExpression" then str = str.."(" end
		if class_name == "SubObjectPropertyOf" and link == "subObjectPropertyExpressions" and instance:find('/'..link):size() > 1 then
			str = str.."ObjectPropertyChain("
		end
		instance:find('/'..link):each(
			function(child)
				str = str..render_instance(child, is_declaration).." "
			end)
		if class_name == "SubObjectPropertyOf" and link == "subObjectPropertyExpressions" and instance:find('/'..link):size() > 1 then
			str = str:sub(1, str:len()-1)..") "
		end
		if class_name == "HasKey" and link ~= "classExpression" then
			if str:sub(-1) == " " then
				str = str:sub(1, str:len()-1)..") "
			else --this will happen when there are no object/data properties
				str = str..") " --e.g HasKey(:class () (:myDataProp))
			end
		end
	end

	str = string.sub(str, 1, string.len(str)-1)
	if (is_annotation_related or is_facet_restriction or is_entity) and not from_declaration then
		--
	else
		str = str..")"
	end
	--return string.sub(str, 1, string.len(str)-1)..")"
	return str
end

function render_iri(instance)
	local value = instance:attr("value")

	if instance:find("/namespace"):is_not_empty() then
		return value
	else
		return "<"..value..">"
	end
end

function links_of_class(class_name)
	local link_table = {

	-- axioms
		Declaration = {
			"entity"
		},
		DatatypeDefinition = {
			"datatype",
			"dataRange"
		},
		HasKey = {
			"classExpression",
			"objectPropertyExpressions",
			"dataPropertyExpressions"
		},

	-- class axioms
		SubClassOf = {
			"subClassExpression",
			"superClassExpression"
		},
		DisjointUnion = {
			"class",
			"disjointClassExpressions"
		},
		DisjointClasses = {
			"classExpressions"
		},
		EquivalentClasses = {
			"classExpressions"
		},

	-- object property axioms
		ObjectPropertyRange = {
			"objectPropertyExpression",
			"range"
		},
		ObjectPropertyDomain = {
			"objectPropertyExpression",
			"domain"
		},
		TransitiveObjectProperty = {
			"objectPropertyExpression"
		},
		IrreflexiveObjectProperty = {
			"objectPropertyExpression"
		},
		ReflexiveObjectProperty = {
			"objectPropertyExpression"
		},
		AsymmetricObjectProperty = {
			"objectPropertyExpression"
		},
		SymmetricObjectProperty = {
			"objectPropertyExpression"
		},
		InverseFunctionalObjectProperty = {
			"objectPropertyExpression"
		},
		FunctionalObjectProperty = {
			"objectPropertyExpression"
		},
		InverseObjectProperties = {
			"objectPropertyExpression1",
			"objectPropertyExpression2"
		},
		DisjointObjectProperties = {
			"objectPropertyExpressions"
		},
		SubObjectPropertyOf = {
			"subObjectPropertyExpressions",
			"superObjectPropertyExpression"
		},
		EquivalentObjectProperties = {
			"objectPropertyExpressions"
		},

	-- data property axioms
		DataPropertyDomain = {
			"dataPropertyExpression",
			"domain"
		},
		DataPropertyRange = {
			"dataPropertyExpression",
			"range"
		},
		FunctionalDataProperty = {
			"dataPropertyExpression"
		},
		EquivalentDataProperties = {
			"dataPropertyExpressions"
		},
		DisjointDataProperties = {
			"dataPropertyExpressions"
		},
		SubDataPropertyOf = {
			"subDataPropertyExpression",
			"superDataPropertyExpression"
		},

	-- assertion axioms
		NegativeDataPropertyAssertion = {
			"dataPropertyExpression",
			"sourceIndividual",
			"targetValue"
		},
		DataPropertyAssertion = {
			"dataPropertyExpression",
			"sourceIndividual",
			"targetValue"
		},
		NegativeObjectPropertyAssertion = {
			"objectPropertyExpression",
			"sourceIndividual",
			"targetIndividual"
		},
		ObjectPropertyAssertion = {
			"objectPropertyExpression",
			"sourceIndividual",
			"targetIndividual"
		},
		ClassAssertion = {
			"classExpression",
			"individual"
		},
		DifferentIndividuals = {
			"individuals"
		},
		SameIndividual = {
			"individuals"
		},

	-- annotation axioms
		AnnotationAssertion = {
			"annotationProperty",
			"annotationSubject",
			"annotationValue"
		},
		AnnotationPropertyDomain = {
			"annotationProperty",
			"domain"
		},
		AnnotationPropertyRange = {
			"annotationProperty",
			"range"
		},
		SubAnnotationPropertyOf = {
			"subAnnotationProperty",
			"superAnnotationProperty"
		},
		AnnotationSubject = {
			"iri, /anonymousIndividual"
		},

	-- entities
		Class = {
			"equivalent, /equivalent/entityIRI"
		},
		ObjectProperty = {
			"equivalent, /equivalent/entityIRI"
		},
		DataProperty = {
			"equivalent, /equivalent/entityIRI"
		},
		Datatype = {
			"equivalent, /equivalent/entityIRI"
		},
		NamedIndividual = {
			"equivalent, /equivalent/entityIRI"
		},
		AnnotationProperty = {
			"entityIRI"
		},

	-- class expressions
		ObjectIntersectionOf = {
			"classExpressions"
		},
		ObjectUnionOf = {
			"classExpressions"
		},
		ObjectComplementOf = {
			"classExpression"
		},
		ObjectOneOf = {
			"individuals"
		},
		ObjectSomeValuesFrom = {
			"objectPropertyExpression",
			"classExpression"
		},
		ObjectAllValuesFrom = {
			"objectPropertyExpression",
			"classExpression"
		},
		ObjectHasValue = {
			"objectPropertyExpression",
			"individual"
		},
		ObjectHasSelf = {
			"objectPropertyExpression"
		},
		ObjectMinCardinality = {
			"objectPropertyExpression",
			"classExpression"
		},
		ObjectMaxCardinality = {
			"objectPropertyExpression",
			"classExpression"
		},
		ObjectExactCardinality = {
			"objectPropertyExpression",
			"classExpression"
		},
		DataSomeValuesFrom = {
			"dataPropertyExpression",
			"dataRange"
		},
		DataAllValuesFrom = {
			"dataPropertyExpression",
			"dataRange"
		},
		DataHasValue = {
			"dataPropertyExpression",
			"literal"
		},
		DataMinCardinality = {
			"dataPropertyExpression",
			"classExpression"
		},
		DataMaxCardinality = {
			"dataPropertyExpression",
			"classExpression"
		},
		DataExactCardinality = {
			"dataPropertyExpression",
			"classExpression"
		},

	-- data range expressions
		DataComplementOf = {
			"dataRange"
		},
		DataIntersectionOf = {
			"dataRanges"
		},
		DatatypeRestriction = {
			"datatype",
			"restrictions"
		},
		DataOneOf = {
			"literals"
		},
		DataUnionOf = {
			"dataRanges"
		},

	-- other things
		FacetRestriction = {
			"constrainingFacet",
			"restrictionValue"
		},
		InverseObjectProperty = {
			"objectProperty"
		}
	}

	if link_table[class_name] == nil then
		print ("***"..class_name.."***")
		return {}
	end
	return link_table[class_name]
end

function up_links_of_class(class_name)
	local link_table =
	{
		-- axioms
		Declaration =
		{
			"ontology"
		},
		DatatypeDefinition =
		{
			"ontology"
		},
		HasKey =
		{
			"ontology"
		},

		-- class expressions
		SubClassOf =
		{
			"ontology"
		},
		DisjointUnion =
		{
			"ontology"
		},
		DisjointClasses =
		{
			"ontology"
		},
		EquivalentClasses =
		{
			"ontology"
		},

		-- object property axioms
		ObjectPropertyRange =
		{
			"ontology"
		},
		ObjectPropertyDomain =
		{
			"ontology"
		},
		TransitiveObjectProperty =
		{
			"ontology"
		},
		IrreflexiveObjectProperty =
		{
			"ontology"
		},
		ReflexiveObjectProperty =
		{
			"ontology"
		},
		AsymmetricObjectProperty =
		{
			"ontology"
		},
		SymmetricObjectProperty =
		{
			"ontology"
		},
		InverseFunctionalObjectProperty =
		{
			"ontology"
		},
		FunctionalObjectProperty =
		{
			"ontology"
		},
		InverseObjectProperties =
		{
			"ontology"
		},
		DisjointObjectProperties =
		{
			"ontology"
		},
		SubObjectPropertyOf =
		{
			"ontology"
		},
		EquivalentObjectProperties =
		{
			"ontology"
		},

		-- data property axioms
		DataPropertyDomain =
		{
			"ontology"
		},
		DataPropertyRange =
		{
			"ontology"
		},
		FunctionalDataProperty =
		{
			"ontology"
		},
		EquivalentDataProperties =
		{
			"ontology"
		},
		DisjointDataProperties =
		{
			"ontology"
		},
		SubDataPropertyOf =
		{
			"ontology"
		},

		-- assertion axioms
		NegativeDataPropertyAssertion =
		{
			"ontology"
		},
		DataPropertyAssertion =
		{
			"ontology"
		},
		NegativeObjectPropertyAssertion =
		{
			"ontology"
		},
		ObjectPropertyAssertion =
		{
			"ontology"
		},
		ClassAssertion =
		{
			"ontology"
		},
		DifferentIndividuals =
		{
			"ontology"
		},
		SameIndividual =
		{
			"ontology"
		},

		-- annotation axioms
		AnnotationAssertion =
		{
			"ontology"
		},
		AnnotationPropertyDomain =
		{
			"ontology"
		},
		AnnotationPropertyRange =
		{
			"ontology"
		},
		SubAnnotationPropertyOf =
		{
			"ontology"
		},
		AnnotationSubject =
		{
			"ontology"
		},

		-- entities
		Class =
		{
			"disjointUnionClass",
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectProperty =
		{
			"transitiveObjectProperty",
			"objectExactCardinality",
			"objectHasSelf",
			"objectPropertyAssertion",
			"objectAllValuesFrom",
			"hasKey",
			"objectMaxCardinality",
			"objectSomeValuesFrom",
			"negativeObjectPropertyAssertion",
			"objectHasValue",
			"irreflexiveObjectProperty",
			"reflexiveObjectProperty",
			"asymmetricObjectProperty",
			"symmetricObjectProperty",
			"inverseFunctionalObjectProperty",
			"functionalObjectProperty",
			"inverseObjectPropertiesAxiom1",
			"inverseObjectPropertiesAxiom2",
			"objectPropertyDomain",
			"objectPropertyRange",
			"disjointObjectProperties",
			"subObjectPropertyAxiom",
			"superObjectPropertyAxiom",
			"equivalentObjectProperties",
			"objectMinCardinality"
		},
		DataProperty =
		{
			"dataExactCardinality",
			"dataMinCardinality",
			"dataMaxCardinality",
			"dataAllValuesFrom",
			"dataHasValue",
			"dataSomeValuesFrom",
			"negativeDataPropertyAssertion",
			"dataPropertyRange",
			"dataPropertyDomain",
			"functionalDataProperty",
			"equivalentDataProperties",
			"hasKey",
			"disjointDataProperties",
			"dataPropertyAssertion",
			"subDataPropertyAxiom",
			"superDataPropertyAxiom"
		},
		Datatype =
		{
			"datatypeRestriction",
			"literal",
			"definition",
			"dataAllValuesFrom",
			"dataExactCardinality",
			"dataMinCardinality",
			"dataMaxCardinality",
			"dataSomeValuesFrom",
			"dataPropertyRange",
			"dataPropertyDomain",
			"dataComplement",
			"dataUnion",
			"dataIntersection"
		},
		NamedIndividual =
		{
			"negativeDataPropertyAssertionWithSource",
			"dataPropertyAssertionWithSource",
			"negativeObjectPropertyAssertionWithTarget",
			"negativeObjectPropertyAssertionWithSource",
			"objectPropertyAssertionWithTarget",
			"objectPropertyAssertionWithSource",
			"classAssertion",
			"differentIndividuals",
			"sameIndividual",
			"objectOneOf",
			"objectHasValue"
		},
		AnnotationProperty =
		{
			"annotation",
			"superAnnotationPropertyAxiom",
			"subAnnotationPropertyAxiom",
			"annotationPropertyDomain",
			"annotationPropertyRange",
			"annotationAssertion"
		},

		-- class expressions
		ObjectIntersectionOf =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectUnionOf =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectComplementOf =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectOneOf =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectSomeValuesFrom =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectAllValuesFrom =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectHasValue =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectHasSelf =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectMinCardinality =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectMaxCardinality =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		ObjectExactCardinality =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		DataSomeValuesFrom =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		DataAllValuesFrom =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		DataHasValue =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		DataMinCardinality =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		DataMaxCardinality =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},
		DataExactCardinality =
		{
			"superClassAxiom",
			"subClassAxiom",
			"equivalentClasses",
			"disjointClasses",
			"disjointUnion",
			"objectPropertyDomain",
			"objectPropertyRange",
			"hasKey",
			"objectUnionOf",
			"objectComplementOf",
			"objectIntersectionOf",
			"classAssertion",
			"objectAllValuesFrom",
			"objectSomeValuesFrom",
			"dataPropertyDomain",
			"objectMaxCardinality",
			"objectMinCardinality",
			"objectExactCardinality"
		},

		--data range expressions
		DataComplementOf =
		{
			"dataAllValuesFrom",
			"dataExactCardinality",
			"dataMinCardinality",
			"dataMaxCardinality",
			"dataSomeValuesFrom",
			"dataPropertyRange",
			"dataPropertyDomain",
			"dataComplement",
			"dataUnion",
			"dataIntersection"
		},
		DataIntersectionOf =
		{
			"dataAllValuesFrom",
			"dataExactCardinality",
			"dataMinCardinality",
			"dataMaxCardinality",
			"dataSomeValuesFrom",
			"dataPropertyRange",
			"dataPropertyDomain",
			"dataComplement",
			"dataUnion",
			"dataIntersection"
		},
		DatatypeRestriction =
		{
			"dataAllValuesFrom",
			"dataExactCardinality",
			"dataMinCardinality",
			"dataMaxCardinality",
			"dataSomeValuesFrom",
			"dataPropertyRange",
			"dataPropertyDomain",
			"dataComplement",
			"dataUnion",
			"dataIntersection"
		},
		DataOneOf =
		{
			"dataAllValuesFrom",
			"dataExactCardinality",
			"dataMinCardinality",
			"dataMaxCardinality",
			"dataSomeValuesFrom",
			"dataPropertyRange",
			"dataPropertyDomain",
			"dataComplement",
			"dataUnion",
			"dataIntersection"
		},
		DataUnionOf =
		{
			"dataAllValuesFrom",
			"dataExactCardinality",
			"dataMinCardinality",
			"dataMaxCardinality",
			"dataSomeValuesFrom",
			"dataPropertyRange",
			"dataPropertyDomain",
			"dataComplement",
			"dataUnion",
			"dataIntersection"
		},

		-- other things
		FacetRestriction =
		{
			"datatypeRestriction"
		},
		InverseObjectProperty =
		{

		}
	}

	if link_table[class_name] == nil then
		print ("***"..class_name.."***")
		return {}
	end
	return link_table[class_name]
end

function is_entity_class(class_name)
	local entity_classes = {
		"Class",
		"ObjectProperty",
		"DataProperty",
		"Datatype",
		"NamedIndividual"
	}

	if string.sub(class_name, -6) == "Entity" and string.len(class_name) > 10 then
		return true
	end

	for _, name in pairs(entity_classes) do
		if name == class_name then
			return true
		end
	end

	return false
end

function is_declaration_class(class_name)
	if class_name == "Declaration" then
		return true
	else
		return false
	end
end

function is_facet_restriction_class(class_name)
	if class_name == "FacetRestriction" then return true else return false end
end

function is_annotation_argument(class_name)
	if class_name == "AnnotationProperty" or class_name == "AnnotationSubject" then return true else return false end
end

function sub_string_for_entity(class_name)
	if string.sub(class_name, -6) == "Entity" and string.len(class_name) > 10 then
		return string.sub(class_name, 1, -7)
	else
		return class_name
	end
end

function delete_object(domain_obj)
	local class = domain_obj:get(1):class().name
	class = class:sub(5) --all domain class names have a prefix OWL#. We don't need it here

	if domain_obj:find("/map"):is_not_empty() then --check for /map link. Don't delete the object if it has one
		print (class.." object in use (has /map link).", domain_obj:attr("id"))
		return
	end

	local downLinks = links_of_class(class)
	local upLinks = up_links_of_class(class)

	for i, link in ipairs(upLinks) do --if the object has any uplinks, don't delete it
		if domain_obj:find("/"..link):is_not_empty() then
			print (class.." object in use (has /"..link.." link).", domain_obj:attr("id"))
			return
		end
	end

	local downObjects = lQuery("") --collect all objects that can be reached with downlinks
	for i, link in ipairs(downLinks) do
		downObjects = downObjects:add(domain_obj:find("/"..link))
	end

	domain_obj:delete() --delete the object itself. This needs to be done before the down object deletion, because otherwise they would have uplinks to domain_obj
	print (class.." object deleted successfully.")

	downObjects:each( --attempt to delete all down objects with this function. Don't just :delete(), because they could have uplinks to things other than domain_obj
		function(obj)
			delete_object(obj)
		end
	)
end
