--[[

	OWL2 metamodelis
	
	Daudzkârðâ mantoðana aizstâta ar papildapakðklasçm - savâ starpâ savienotas ar 1:1 linku 'equivalent'
		Class
		Datatype
		NamedIndividual
		ObjectProperty
		DataProperty
	Piem., ClassExpression <-- Class --> Entity   ==   ClassExpression <-- Class --1:1-- ClassEntity --> Entity
	
	AnnotationValue --1:0..1-- IRI --0..1:1-- AnnotationSubject
	Individual <-- AnonymousIndividual --0..1:1-- AnnotationSubject & AnnotationValue
--]]

module(..., package.seeall)
require("core")
require("utilities")
mii_rep_obj = require("mii_rep_obj")

function load_owl2_domain()
	add_structure_of_ontologies()
	add_entities_literals_and_anonymous_individuals()
	add_entity_declarations()
	add_object_property_expressions()
	add_data_property_expressions()
	add_data_ranges()
	add_propositional_connectives_and_enumeration_of_individuals()
	add_restricting_object_property_expressions()
	add_restricting_the_cardinality_of_object_property_expressions()
	add_restricting_data_property_expressions()
	add_restricting_the_cardinality_of_data_property_expressions()
	add_the_axioms()
	add_the_class_axioms()
	add_object_property_axioms()
	add_axioms_defining_characteristics_of_object_properties()
	add_data_property_axioms()
	add_datatype_definitions()
	add_key_axioms()
	add_class_and_individual_equality_assertions()
	add_object_property_assertions()
	add_data_property_assertions()
	add_annotations_of_ontologies_and_axioms()
	add_annotations_of_iris_and_anonymous_individuals()
	add_domain_object()
	add_box_candidate()
end

-- Figure 1
function add_structure_of_ontologies()
	add_class("OWL#Ontology")
	add_class("OWL#Axiom")
	add_class("OWL#IRI")
	add_class("OWL#Annotation")
	add_class("OWL#Namespace")
	
	
	add_property("OWL#IRI", "value")
	add_property("OWL#IRI", "shortValue")
	
	add_property("OWL#Namespace", "prefix")
	add_property("OWL#Namespace", "IRIprefix")
	
	add_property("OWL#Ontology", "id")
	add_property("OWL#Axiom", "id")
	add_property("OWL#IRI", "id")
	add_property("OWL#Annotation", "id")
	add_property("OWL#Namespace", "id")
	
	add_link("OWL#Ontology", "ontologyDirectlyImports", 2, "OWL#Ontology", "/directlyImports", 2)
	add_link("OWL#Ontology", "ontologyImports", 2, "OWL#Ontology", "/imports", 2)
	
	add_link("OWL#Ontology", "ontologyOntologyIRI", 2, "OWL#IRI", "ontologyIRI", 1)
	add_link("OWL#Ontology", "ontologyVersionIRI", 2, "OWL#IRI", "versionIRI", 1)
	add_link("OWL#Ontology", "ontologyDirectlyImportsDocuments", 2, "OWL#IRI", "directlyImportsDocuments", 2)
	add_link("OWL#Ontology", "containingOntology", 2, "OWL#IRI", "iriInOntology", 2)
	
	add_link("OWL#Ontology", "ontology", 2, "OWL#Annotation", "ontologyAnnotations", 2)
	
	add_link("OWL#Ontology", "ontology", 2, "OWL#Axiom", "axioms", 2)
	
	add_link("OWL#Annotation", "annotation", 2, "OWL#Annotation", "annotationAnnotations", 2)
	
	add_link("OWL#Axiom", "axiom", 2, "OWL#Annotation", "axiomAnnotations", 2)
	
	add_link("OWL#IRI", "iri", 2, "OWL#Namespace", "namespace", 1)
	
	add_link("OWL#Ontology", "ontology", 2, "OWL#Namespace", "usedNamespace", 2)
end

-- Figure 2
function add_entities_literals_and_anonymous_individuals()
	add_class("OWL#ClassExpression")
	add_class("OWL#Entity")
	add_class("OWL#DataRange")
	add_class("OWL#Individual")
	
	add_class("OWL#Class")
	add_class("OWL#ClassEntity")				-- for 2nd superclass
	add_class("OWL#ObjectProperty")
	add_class("OWL#ObjectPropertyEntity")		-- for 2nd superclass
	add_class("OWL#DataProperty")
	add_class("OWL#DataPropertyEntity")		-- for 2nd superclass
	
	add_class("OWL#AnnotationProperty")
	add_class("OWL#Datatype")
	add_class("OWL#DatatypeEntity")			-- for 2nd superclass
	add_class("OWL#NamedIndividual")
	add_class("OWL#NamedIndividualEntity")		-- for 2nd superclass
	add_class("OWL#AnonymousIndividual")
	
	add_class("OWL#Literal")
	
	
	add_property("OWL#DataRange", "arity")
	add_property("OWL#AnonymousIndividual", "nodeID")
	add_property("OWL#Literal", "text")
	add_property("OWL#Literal", "language")
	
	add_property("OWL#ClassExpression", "id")
	add_property("OWL#Entity", "id")
	add_property("OWL#DataRange", "id")
	add_property("OWL#Individual", "id")
	add_property("OWL#ObjectProperty", "id")
	add_property("OWL#DataProperty", "id")
	add_property("OWL#Datatype", "id")
	
	set_super_class("OWL#Class", "OWL#ClassExpression")
	set_super_class("OWL#ClassEntity", "OWL#Entity")
	set_super_class("OWL#ObjectPropertyEntity", "OWL#Entity")
	set_super_class("OWL#DataPropertyEntity", "OWL#Entity")
	set_super_class("OWL#AnnotationProperty", "OWL#Entity")
	set_super_class("OWL#DatatypeEntity", "OWL#Entity")
	set_super_class("OWL#Datatype", "OWL#DataRange")
	set_super_class("OWL#NamedIndividualEntity", "OWL#Entity")
	set_super_class("OWL#NamedIndividual", "OWL#Individual")
	set_super_class("OWL#AnonymousIndividual", "OWL#Individual")
	
	
	add_link("OWL#Entity", "entity", 2, "OWL#IRI", "entityIRI", 3)
	add_link("OWL#Literal", "literal", 2, "OWL#Datatype", "datatype", 3)
	
	
	add_link("OWL#ClassEntity", "equivalent", 3, "OWL#Class", "equivalent", 3)
	add_link("OWL#DatatypeEntity", "equivalent", 3, "OWL#Datatype", "equivalent", 3)
	add_link("OWL#NamedIndividualEntity", "equivalent", 3, "OWL#NamedIndividual", "equivalent", 3)
	add_link("OWL#ObjectPropertyEntity", "equivalent", 3, "OWL#ObjectProperty", "equivalent", 3)
	add_link("OWL#DataPropertyEntity", "equivalent", 3, "OWL#DataProperty", "equivalent", 3)
end

-- Figure 3
function add_entity_declarations()
	add_class("OWL#Declaration")
	
	set_super_class("OWL#Declaration", "OWL#Axiom")
	
	
	add_link("OWL#Declaration", "declaration", 2, "OWL#Entity", "entity", 3)
end

-- Figure 4
function add_object_property_expressions()
	add_class("OWL#InverseObjectProperty")
	add_class("OWL#ObjectPropertyExpression")
	
	set_super_class("OWL#ObjectProperty", "OWL#ObjectPropertyExpression")
	set_super_class("OWL#InverseObjectProperty", "OWL#ObjectPropertyExpression")
	
	
	add_link("OWL#InverseObjectProperty", "inverseObjectProperty", 2, "OWL#ObjectProperty", "objectProperty", 3)
end

-- Figure 5
function add_data_property_expressions()
	add_class("OWL#DataPropertyExpression")
	
	set_super_class("OWL#DataProperty", "OWL#DataPropertyExpression")
end

-- Figure 6
function add_data_ranges()
	add_class("OWL#DataComplementOf")
	add_class("OWL#DataUnionOf")
	add_class("OWL#DataOneOf")
	add_class("OWL#DatatypeRestriction")
	add_class("OWL#DataIntersectionOf")
	add_class("OWL#FacetRestriction")
	
	add_property("OWL#FacetRestriction", "id")
	
	set_super_class("OWL#DataComplementOf", "OWL#DataRange")
	set_super_class("OWL#DataUnionOf", "OWL#DataRange")
	set_super_class("OWL#DataOneOf", "OWL#DataRange")
	set_super_class("OWL#DatatypeRestriction", "OWL#DataRange")
	set_super_class("OWL#DataIntersectionOf", "OWL#DataRange")
	
	
	add_link("OWL#DataComplementOf", "dataComplement", 2, "OWL#DataRange", "dataRange", 3)
	add_link("OWL#DataUnionOf", "dataUnion", 2, "OWL#DataRange", "dataRanges", 4) -- 4 = 2N
	add_link("OWL#DataIntersectionOf", "dataIntersection", 2, "OWL#DataRange", "dataRanges", 4) -- 4 = 2N
	
	add_link("OWL#DataOneOf", "dataOneOf", 2, "OWL#Literal", "literals", 4)
	
	add_link("OWL#DatatypeRestriction", "datatypeRestriction", 2, "OWL#Datatype", "datatype", 3)
	add_link("OWL#DatatypeRestriction", "datatypeRestriction", 2, "OWL#FacetRestriction", "restrictions", 4)
	
	add_link("OWL#FacetRestriction", "facetRestriction", 2, "OWL#Literal", "restrictionValue", 3)
	add_link("OWL#FacetRestriction", "facetRestriction", 2, "OWL#IRI", "constrainingFacet", 3)
end

-- Figure 7
function add_propositional_connectives_and_enumeration_of_individuals()
	add_class("OWL#ObjectUnionOf")
	add_class("OWL#ObjectComplementOf")
	add_class("OWL#ObjectOneOf")
	add_class("OWL#ObjectIntersectionOf")
	
	set_super_class("OWL#ObjectUnionOf", "OWL#ClassExpression")
	set_super_class("OWL#ObjectComplementOf", "OWL#ClassExpression")
	set_super_class("OWL#ObjectOneOf", "OWL#ClassExpression")
	set_super_class("OWL#ObjectIntersectionOf", "OWL#ClassExpression")
	
	
	add_link("OWL#ObjectUnionOf", "objectUnionOf", 2, "OWL#ClassExpression", "classExpressions", 4) -- 4 = 2N
	add_link("OWL#ObjectComplementOf", "objectComplementOf", 2, "OWL#ClassExpression", "classExpression", 3)
	add_link("OWL#ObjectIntersectionOf", "objectIntersectionOf", 2, "OWL#ClassExpression", "classExpressions", 4) -- 4 = 2N
	add_link("OWL#ObjectOneOf", "objectOneOf", 2, "OWL#Individual", "individuals", 4)
end

-- Figure 8
function add_restricting_object_property_expressions()
	add_class("OWL#ObjectAllValuesFrom")
	add_class("OWL#ObjectHasSelf")
	add_class("OWL#ObjectHasValue")
	add_class("OWL#ObjectSomeValuesFrom")
	
	set_super_class("OWL#ObjectAllValuesFrom", "OWL#ClassExpression")
	set_super_class("OWL#ObjectHasSelf", "OWL#ClassExpression")
	set_super_class("OWL#ObjectHasValue", "OWL#ClassExpression")
	set_super_class("OWL#ObjectSomeValuesFrom", "OWL#ClassExpression")
	
	
	add_link("OWL#ObjectAllValuesFrom", "objectAllValuesFrom", 2, "OWL#ClassExpression", "classExpression", 3)
	add_link("OWL#ObjectAllValuesFrom", "objectAllValuesFrom", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#ObjectSomeValuesFrom", "objectSomeValuesFrom", 2, "OWL#ClassExpression", "classExpression", 3)
	add_link("OWL#ObjectSomeValuesFrom", "objectSomeValuesFrom", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#ObjectHasSelf", "objectHasSelf", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#ObjectHasValue", "objectHasValue", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	add_link("OWL#ObjectHasValue", "objectHasValue", 2, "OWL#Individual", "individual", 3)
end

-- Figure 9
function add_restricting_the_cardinality_of_object_property_expressions()
	add_class("OWL#ObjectMaxCardinality")
	add_class("OWL#ObjectMinCardinality")
	add_class("OWL#ObjectExactCardinality")
	
	add_property("OWL#ObjectMaxCardinality", "cardinality")
	add_property("OWL#ObjectMinCardinality", "cardinality")
	add_property("OWL#ObjectExactCardinality", "cardinality")
	
	
	set_super_class("OWL#ObjectMaxCardinality", "OWL#ClassExpression")
	set_super_class("OWL#ObjectMinCardinality", "OWL#ClassExpression")
	set_super_class("OWL#ObjectExactCardinality", "OWL#ClassExpression")
	
	
	add_link("OWL#ObjectMaxCardinality", "objectMaxCardinality", 2, "OWL#ClassExpression", "classExpression", 1)
	add_link("OWL#ObjectMaxCardinality", "objectMaxCardinality", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#ObjectMinCardinality", "objectMinCardinality", 2, "OWL#ClassExpression", "classExpression", 1)
	add_link("OWL#ObjectMinCardinality", "objectMinCardinality", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#ObjectExactCardinality", "objectExactCardinality", 2, "OWL#ClassExpression", "classExpression", 1)
	add_link("OWL#ObjectExactCardinality", "objectExactCardinality", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
end

-- Figure 10
function add_restricting_data_property_expressions()
	add_class("OWL#DataSomeValuesFrom")
	add_class("OWL#DataAllValuesFrom")
	add_class("OWL#DataHasValue")
	
	set_super_class("OWL#DataSomeValuesFrom", "OWL#ClassExpression")
	set_super_class("OWL#DataAllValuesFrom", "OWL#ClassExpression")
	set_super_class("OWL#DataHasValue", "OWL#ClassExpression")
	
	
	add_ordered_link("OWL#DataSomeValuesFrom", "dataSomeValuesFrom", 2, false, "OWL#DataPropertyExpression", "dataPropertyExpressions", 4, true)
	add_link("OWL#DataSomeValuesFrom", "dataSomeValuesFrom", 2, "OWL#DataRange", "dataRange", 3)
	
	add_ordered_link("OWL#DataAllValuesFrom", "dataAllValuesFrom", 2, false, "OWL#DataPropertyExpression", "dataPropertyExpressions", 4, true)
	add_link("OWL#DataAllValuesFrom", "dataAllValuesFrom", 2, "OWL#DataRange", "dataRange", 3)
	
	add_link("OWL#DataHasValue", "dataHasValue", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
	add_link("OWL#DataHasValue", "dataHasValue", 2, "OWL#Literal", "literal", 3)
end

-- Figure 11
function add_restricting_the_cardinality_of_data_property_expressions()
	add_class("OWL#DataMaxCardinality")
	add_class("OWL#DataMinCardinality")
	add_class("OWL#DataExactCardinality")
	
	add_property("OWL#DataMaxCardinality", "cardinality")
	add_property("OWL#DataMinCardinality", "cardinality")
	add_property("OWL#DataExactCardinality", "cardinality")
	
	
	set_super_class("OWL#DataMaxCardinality", "OWL#ClassExpression")
	set_super_class("OWL#DataMinCardinality", "OWL#ClassExpression")
	set_super_class("OWL#DataExactCardinality", "OWL#ClassExpression")
	
	
	add_link("OWL#DataMaxCardinality", "dataMaxCardinality", 2, "OWL#DataRange", "dataRange", 1)
	add_link("OWL#DataMaxCardinality", "dataMaxCardinality", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
	
	add_link("OWL#DataMinCardinality", "dataMinCardinality", 2, "OWL#DataRange", "dataRange", 1)
	add_link("OWL#DataMinCardinality", "dataMinCardinality", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
	add_link("OWL#DataExactCardinality", "dataExactCardinality", 2, "OWL#DataRange", "dataRange", 1)
	add_link("OWL#DataExactCardinality", "dataExactCardinality", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
end

-- Figure 12
function add_the_axioms()
	add_class("OWL#ClassAxiom")
	add_class("OWL#ObjectPropertyAxiom")
	add_class("OWL#DataPropertyAxiom")
	add_class("OWL#DatatypeDefinition")
	add_class("OWL#HasKey")
	add_class("OWL#Assertion")
	add_class("OWL#AnnotationAxiom")
	
	set_super_class("OWL#ClassAxiom", "OWL#Axiom")
	set_super_class("OWL#ObjectPropertyAxiom", "OWL#Axiom")
	set_super_class("OWL#DataPropertyAxiom", "OWL#Axiom")
	set_super_class("OWL#DatatypeDefinition", "OWL#Axiom")
	set_super_class("OWL#HasKey", "OWL#Axiom")
	set_super_class("OWL#Assertion", "OWL#Axiom")
	set_super_class("OWL#AnnotationAxiom", "OWL#Axiom")
end

-- Figure 13
function add_the_class_axioms()
	add_class("OWL#SubClassOf")
	add_class("OWL#EquivalentClasses")
	add_class("OWL#DisjointClasses")
	add_class("OWL#DisjointUnion")
	
	set_super_class("OWL#SubClassOf", "OWL#ClassAxiom")
	set_super_class("OWL#EquivalentClasses", "OWL#ClassAxiom")
	set_super_class("OWL#DisjointClasses", "OWL#ClassAxiom")
	set_super_class("OWL#DisjointUnion", "OWL#ClassAxiom")
	
	
	add_link("OWL#SubClassOf", "superClassAxiom", 2, "OWL#ClassExpression", "subClassExpression", 3)
	add_link("OWL#SubClassOf", "subClassAxiom", 2, "OWL#ClassExpression", "superClassExpression", 3)
	
	add_link("OWL#EquivalentClasses", "equivalentClasses", 2, "OWL#ClassExpression", "classExpressions", 4) -- 4 = 2N
	
	add_link("OWL#DisjointClasses", "disjointClasses", 2, "OWL#ClassExpression", "classExpressions", 4) -- 4 = 2N
	
	add_link("OWL#DisjointUnion", "disjointUnion", 2, "OWL#ClassExpression", "disjointClassExpressions", 4) -- 4 = 2N
	add_link("OWL#DisjointUnion", "disjointUnionClass", 2, "OWL#Class", "class", 3)
end

-- Figure 14
function add_object_property_axioms()
	add_class("OWL#EquivalentObjectProperties")
	add_class("OWL#SubObjectPropertyOf")
	add_class("OWL#DisjointObjectProperties")
	add_class("OWL#ObjectPropertyDomain")
	add_class("OWL#ObjectPropertyRange")
	add_class("OWL#InverseObjectProperties")
	
	set_super_class("OWL#EquivalentObjectProperties", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#SubObjectPropertyOf", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#DisjointObjectProperties", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#ObjectPropertyDomain", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#ObjectPropertyRange", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#InverseObjectProperties", "OWL#ObjectPropertyAxiom")
	
	
	add_link("OWL#EquivalentObjectProperties", "equivalentObjectProperties", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpressions", 4) -- 4 = 2N
	
	add_ordered_link("OWL#SubObjectPropertyOf", "superObjectPropertyAxiom", 2, false, "OWL#ObjectPropertyExpression", "subObjectPropertyExpressions", 4, true)
	add_link("OWL#SubObjectPropertyOf", "subObjectPropertyAxiom", 2, "OWL#ObjectPropertyExpression", "superObjectPropertyExpression", 3)
	
	add_link("OWL#DisjointObjectProperties", "disjointObjectProperties", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpressions", 4) -- 4 = 2N
	
	add_link("OWL#ObjectPropertyDomain", "objectPropertyDomain", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	add_link("OWL#ObjectPropertyDomain", "objectPropertyDomain", 2, "OWL#ClassExpression", "domain", 3)
	
	add_link("OWL#ObjectPropertyRange", "objectPropertyRange", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	add_link("OWL#ObjectPropertyRange", "objectPropertyRange", 2, "OWL#ClassExpression", "range", 3)
	
	add_link("OWL#InverseObjectProperties", "inverseObjectPropertiesAxiom1", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression1", 3)
	add_link("OWL#InverseObjectProperties", "inverseObjectPropertiesAxiom2", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression2", 3)
end

-- Figure 15
function add_axioms_defining_characteristics_of_object_properties()
	add_class("OWL#FunctionalObjectProperty")
	add_class("OWL#InverseFunctionalObjectProperty")
	add_class("OWL#SymmetricObjectProperty")
	add_class("OWL#AsymmetricObjectProperty")
	add_class("OWL#ReflexiveObjectProperty")
	add_class("OWL#IrreflexiveObjectProperty")
	add_class("OWL#TransitiveObjectProperty")
	
	set_super_class("OWL#FunctionalObjectProperty", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#InverseFunctionalObjectProperty", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#SymmetricObjectProperty", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#AsymmetricObjectProperty", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#ReflexiveObjectProperty", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#IrreflexiveObjectProperty", "OWL#ObjectPropertyAxiom")
	set_super_class("OWL#TransitiveObjectProperty", "OWL#ObjectPropertyAxiom")
	
	
	add_link("OWL#FunctionalObjectProperty", "functionalObjectProperty", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#InverseFunctionalObjectProperty", "inverseFunctionalObjectProperty", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#SymmetricObjectProperty", "symmetricObjectProperty", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#AsymmetricObjectProperty", "asymmetricObjectProperty", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#ReflexiveObjectProperty", "reflexiveObjectProperty", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#IrreflexiveObjectProperty", "irreflexiveObjectProperty", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	
	add_link("OWL#TransitiveObjectProperty", "transitiveObjectProperty", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
end

-- Figure 16
function add_data_property_axioms()
	add_class("OWL#SubDataPropertyOf")
	add_class("OWL#DisjointDataProperties")
	add_class("OWL#EquivalentDataProperties")
	add_class("OWL#FunctionalDataProperty")
	add_class("OWL#DataPropertyDomain")
	add_class("OWL#DataPropertyRange")
	
	set_super_class("OWL#SubDataPropertyOf", "OWL#DataPropertyAxiom")
	set_super_class("OWL#DisjointDataProperties", "OWL#DataPropertyAxiom")
	set_super_class("OWL#EquivalentDataProperties", "OWL#DataPropertyAxiom")
	set_super_class("OWL#FunctionalDataProperty", "OWL#DataPropertyAxiom")
	set_super_class("OWL#DataPropertyDomain", "OWL#DataPropertyAxiom")
	set_super_class("OWL#DataPropertyRange", "OWL#DataPropertyAxiom")
	
	
	add_link("OWL#SubDataPropertyOf", "superDataPropertyAxiom", 2, "OWL#DataPropertyExpression", "subDataPropertyExpression", 3)
	add_link("OWL#SubDataPropertyOf", "subDataPropertyAxiom", 2, "OWL#DataPropertyExpression", "superDataPropertyExpression", 3)
	
	add_link("OWL#DisjointDataProperties", "disjointDataProperties", 2, "OWL#DataPropertyExpression", "dataPropertyExpressions", 4) -- 4 = 2N
	
	add_link("OWL#EquivalentDataProperties", "equivalentDataProperties", 2, "OWL#DataPropertyExpression", "dataPropertyExpressions", 4) -- 4 = 2N
	
	add_link("OWL#FunctionalDataProperty", "functionalDataProperty", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
	
	add_link("OWL#DataPropertyDomain", "dataPropertyDomain", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
	add_link("OWL#DataPropertyDomain", "dataPropertyDomain", 2, "OWL#ClassExpression", "domain", 3)
	
	add_link("OWL#DataPropertyRange", "dataPropertyRange", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
	add_link("OWL#DataPropertyRange", "dataPropertyRange", 2, "OWL#DataRange", "range", 3)
end

-- Figure 17
function add_datatype_definitions()
	add_link("OWL#DatatypeDefinition", "datatypeDefinition", 2, "OWL#DataRange", "dataRange", 3)
	
	add_link("OWL#DatatypeDefinition", "definition", 2, "OWL#Datatype", "datatype", 3)
end

-- Figure 18
function add_key_axioms()
	add_link("OWL#HasKey", "hasKey", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpressions", 2)
	
	add_link("OWL#HasKey", "hasKey", 2, "OWL#DataPropertyExpression", "dataPropertyExpressions", 2)
	
	add_link("OWL#HasKey", "hasKey", 2, "OWL#ClassExpression", "classExpression", 3)
end

-- Figure 19
function add_class_and_individual_equality_assertions()
	add_class("OWL#SameIndividual")
	add_class("OWL#DifferentIndividuals")
	add_class("OWL#ClassAssertion")
	
	set_super_class("OWL#SameIndividual", "OWL#Assertion")
	set_super_class("OWL#DifferentIndividuals", "OWL#Assertion")
	set_super_class("OWL#ClassAssertion", "OWL#Assertion")
	
	
	add_link("OWL#SameIndividual", "sameIndividual", 2, "OWL#Individual", "individuals", 4) -- 4 = 2N
	
	add_link("OWL#DifferentIndividuals", "differentIndividuals", 2, "OWL#Individual", "individuals", 4) -- 4 = 2N
	
	add_link("OWL#ClassAssertion", "classAssertion", 2, "OWL#Individual", "individual", 3)
	add_link("OWL#ClassAssertion", "classAssertion", 2, "OWL#ClassExpression", "classExpression", 3)
end

-- Figure 20
function add_object_property_assertions()
	add_class("OWL#ObjectPropertyAssertion")
	add_class("OWL#NegativeObjectPropertyAssertion")
	
	set_super_class("OWL#ObjectPropertyAssertion", "OWL#Assertion")
	set_super_class("OWL#NegativeObjectPropertyAssertion", "OWL#Assertion")
	
	
	add_link("OWL#ObjectPropertyAssertion", "objectPropertyAssertion", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	add_link("OWL#ObjectPropertyAssertion", "objectPropertyAssertionWithSource", 2, "OWL#Individual", "sourceIndividual", 3)
	add_link("OWL#ObjectPropertyAssertion", "objectPropertyAssertionWithTarget", 2, "OWL#Individual", "targetIndividual", 3)
	
	add_link("OWL#NegativeObjectPropertyAssertion", "negativeObjectPropertyAssertion", 2, "OWL#ObjectPropertyExpression", "objectPropertyExpression", 3)
	add_link("OWL#NegativeObjectPropertyAssertion", "negativeObjectPropertyAssertionWithSource", 2, "OWL#Individual", "sourceIndividual", 3)
	add_link("OWL#NegativeObjectPropertyAssertion", "negativeObjectPropertyAssertionWithTarget", 2, "OWL#Individual", "targetIndividual", 3)
end

-- Figure 21
function add_data_property_assertions()
	add_class("OWL#DataPropertyAssertion")
	add_class("OWL#NegativeDataPropertyAssertion")
	
	set_super_class("OWL#DataPropertyAssertion", "OWL#Assertion")
	set_super_class("OWL#NegativeDataPropertyAssertion", "OWL#Assertion")
	
	
	add_link("OWL#DataPropertyAssertion", "dataPropertyAssertion", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
	add_link("OWL#DataPropertyAssertion", "dataPropertyAssertionWithSource", 2, "OWL#Individual", "sourceIndividual", 3)
	add_link("OWL#DataPropertyAssertion", "dataPropertyAssertionWithTarget", 2, "OWL#Literal", "targetValue", 3)
	
	add_link("OWL#NegativeDataPropertyAssertion", "negativeDataPropertyAssertion", 2, "OWL#DataPropertyExpression", "dataPropertyExpression", 3)
	add_link("OWL#NegativeDataPropertyAssertion", "negativeDataPropertyAssertionWithSource", 2, "OWL#Individual", "sourceIndividual", 3)
	add_link("OWL#NegativeDataPropertyAssertion", "negativeDataPropertyAssertionWithTarget", 2, "OWL#Literal", "targetValue", 3)
end

-- Figure 22
function add_annotations_of_ontologies_and_axioms()
	add_class("OWL#AnnotationValue")
	
	add_property("OWL#AnnotationValue", "id")
	
	set_super_class("OWL#Literal", "OWL#AnnotationValue")
	
	
	add_link("OWL#Annotation", "annotation", 2, "OWL#AnnotationProperty", "annotationProperty", 3)
	add_link("OWL#Annotation", "annotation", 2, "OWL#AnnotationValue", "annotationValue", 3)
	
	
	add_link("OWL#IRI", "iri", 1, "OWL#AnnotationValue", "annotationValue", 3)
	add_link("OWL#AnonymousIndividual", "anonymousIndividual", 1, "OWL#AnnotationValue", "annotationValue", 3)
end

-- Figure 23
function add_annotations_of_iris_and_anonymous_individuals()
	add_class("OWL#SubAnnotationPropertyOf")
	add_class("OWL#AnnotationPropertyRange")
	add_class("OWL#AnnotationPropertyDomain")
	add_class("OWL#AnnotationAssertion")
	add_class("OWL#AnnotationSubject")
	
	add_property("OWL#AnnotationSubject", "id")
	
	set_super_class("OWL#SubAnnotationPropertyOf", "OWL#AnnotationAxiom")
	set_super_class("OWL#AnnotationPropertyRange", "OWL#AnnotationAxiom")
	set_super_class("OWL#AnnotationPropertyDomain", "OWL#AnnotationAxiom")
	set_super_class("OWL#AnnotationAssertion", "OWL#AnnotationAxiom")
	
	
	add_link("OWL#SubAnnotationPropertyOf", "superAnnotationPropertyAxiom", 2, "OWL#AnnotationProperty", "subAnnotationProperty", 3)
	add_link("OWL#SubAnnotationPropertyOf", "subAnnotationPropertyAxiom", 2, "OWL#AnnotationProperty", "superAnnotationProperty", 3)
	
	add_link("OWL#AnnotationPropertyRange", "annotationPropertyRange", 2, "OWL#AnnotationProperty", "annotationProperty", 3)
	add_link("OWL#AnnotationPropertyRange", "annotationPropertyRange", 2, "OWL#IRI", "range", 3)
	
	add_link("OWL#AnnotationPropertyDomain", "annotationPropertyDomain", 2, "OWL#AnnotationProperty", "annotationProperty", 3)
	add_link("OWL#AnnotationPropertyDomain", "annotationPropertyDomain", 2, "OWL#IRI", "domain", 3)
	
	add_link("OWL#AnnotationAssertion", "annotationAssertion", 2, "OWL#AnnotationSubject", "annotationSubject", 3)
	add_link("OWL#AnnotationAssertion", "annotationAssertion", 2, "OWL#AnnotationValue", "annotationValue", 3)
	add_link("OWL#AnnotationAssertion", "annotationAssertion", 2, "OWL#AnnotationProperty", "annotationProperty", 3)
	
	
	add_link("OWL#IRI", "iri", 1, "OWL#AnnotationSubject", "annotationSubject", 3)
	add_link("OWL#AnonymousIndividual", "anonymousIndividual", 1, "OWL#AnnotationSubject", "annotationSubject", 3)
end

-- DomainObject
function add_domain_object()
	add_class("OWL#DomainObject")
	
	set_super_class("OWL#Ontology", "OWL#DomainObject")
	set_super_class("OWL#IRI", "OWL#DomainObject")
	set_super_class("OWL#Entity", "OWL#DomainObject")
	set_super_class("OWL#Axiom", "OWL#DomainObject")
	set_super_class("OWL#ClassExpression", "OWL#DomainObject")
	set_super_class("OWL#ObjectPropertyExpression", "OWL#DomainObject")
	set_super_class("OWL#DataPropertyExpression", "OWL#DomainObject")
	set_super_class("OWL#Individual", "OWL#DomainObject")
	set_super_class("OWL#AnnotationValue", "OWL#DomainObject")
	
	add_link("OWL#DomainObject", "mapped", 2, "PresentationElement", "map", 2)
	add_link("OWL#DomainObject", "mappedC", 2, "PresentationElement", "mapC", 2)
end

function add_box_candidate()
	add_class("OWL#BoxCandidate")
	
	add_property("OWL#BoxCandidate", "useCount")
	
	add_link("OWL#BoxCandidate", "boxCandidate", 1, "OWL#ClassExpression", "classExpression", 1)
end

------------------------------------

function add_and_fill_parameters()
	add_parameters_domain()
	create_default_param_profile()
end

function add_parameters_domain()
	add_class("P_OWL#ParamProfile")
	add_class("P_OWL#InstructionInProfile")
	add_class("P_OWL#Instruction")
	add_class("P_OWL#InstructionItem")
	
	add_property("P_OWL#ParamProfile", "name")
	add_property("P_OWL#ParamProfile", "selected")
	
	add_property("P_OWL#InstructionInProfile", "textValue")
	
	add_property("P_OWL#Instruction", "id")
	add_property("P_OWL#Instruction", "isCustom")
	add_property("P_OWL#Instruction", "defaultIndex")
	add_property("P_OWL#Instruction", "type")
	
	add_property("P_OWL#InstructionItem", "title")
	add_property("P_OWL#InstructionItem", "index")
	add_property("P_OWL#InstructionItem", "itemProc")
	
	add_composition("P_OWL#InstructionItem", "item", "instruction", "P_OWL#Instruction")
	
	add_link("P_OWL#InstructionInProfile", "selector", 2, "P_OWL#InstructionItem", "selected", 1)
	add_link("P_OWL#InstructionInProfile", "instructionInProfile", 2, "P_OWL#Instruction", "instruction", 3)
	add_link("P_OWL#InstructionInProfile", "instructionInProfile", 2, "P_OWL#ParamProfile", "profile", 3)
end

function create_default_param_profile()
	local param_profile = lQuery.create("P_OWL#ParamProfile", {name = "Default", selected = "true"})
	select_parameters(param_profile)
end

function select_parameters(param_profile)
	local class_annotations = lQuery.create("P_OWL#Instruction", {id = "Class Annotations"})
	add_instruction_value(class_annotations, 0)
	add_instruction_value(class_annotations, 1)
	add_instruction_value(class_annotations, -1)
	param_profile:link("instructionInProfile", get_instruction(class_annotations, 1))
	
	local op_annotations = lQuery.create("P_OWL#Instruction", {id = "Object Properties Annotations"})
	add_instruction_value(op_annotations, 0)
	add_instruction_value(op_annotations, 1)
	add_instruction_value(op_annotations, -1)
	param_profile:link("instructionInProfile", get_instruction(op_annotations, 0))
	
	local dp_annotations = lQuery.create("P_OWL#Instruction", {id = "Data Properties Annotations"})
	add_instruction_value(dp_annotations, 0)
	add_instruction_value(dp_annotations, 1)
	add_instruction_value(dp_annotations, -1)
	param_profile:link("instructionInProfile", get_instruction(dp_annotations, 0))
	
	local individuals_annotations = lQuery.create("P_OWL#Instruction", {id = "Individuals Annotations"})
	add_instruction_value(individuals_annotations, 0)
	add_instruction_value(individuals_annotations, 1)
	add_instruction_value(individuals_annotations, -1)
	param_profile:link("instructionInProfile", get_instruction(individuals_annotations, 0))
	
	local box_creation = lQuery.create("P_OWL#Instruction", {id = "Box Creation Threshold"})
	local bc_inst_in_profile = lQuery.create("P_OWL#InstructionInProfile", {textValue = "2"})
	bc_inst_in_profile:link("instruction", box_creation)
	param_profile:link("instructionInProfile", bc_inst_in_profile)

	local class_restrictions = lQuery.create("P_OWL#Instruction", {id = "Class Restrictions"})
	add_instruction_value(class_restrictions, 0)
	add_instruction_value(class_restrictions, 1)
	add_instruction_value(class_restrictions, -1)
	param_profile:link("instructionInProfile", get_instruction(class_restrictions, 1))
	
	local cl_target_box = lQuery.create("P_OWL#Instruction", {id = "Class Restrictions Target Box"})
	add_instruction_value(cl_target_box, 0)
	add_instruction_value(cl_target_box, 1)
	add_instruction_value(cl_target_box, 2)
	add_instruction_value(cl_target_box, -1)
	param_profile:link("instructionInProfile", get_instruction(cl_target_box, 0))
	
	local cl_fork = lQuery.create("P_OWL#Instruction", {id = "Class Restrictions Fork"})
	add_instruction_value(cl_fork, 0)
	add_instruction_value(cl_fork, 1)
	add_instruction_value(cl_fork, 2)
	add_instruction_value(cl_fork, -1)
	param_profile:link("instructionInProfile", get_instruction(cl_fork, 0))
	
	local cl_extra_thing = lQuery.create("P_OWL#Instruction", {id = "Class Restrictions Extra Thing"})
	add_instruction_value(cl_extra_thing, 0)
	add_instruction_value(cl_extra_thing, 1)
	param_profile:link("instructionInProfile", get_instruction(cl_extra_thing, 1))
	
	local cl_extra_unions = lQuery.create("P_OWL#Instruction", {id = "Class Restrictions Unions"})
	add_instruction_value(cl_extra_unions, 0)
	add_instruction_value(cl_extra_unions, 1)
	param_profile:link("instructionInProfile", get_instruction(cl_extra_unions, 1))
	
	local cl_extra_and_named = lQuery.create("P_OWL#Instruction", {id = "Class Restrictions And Named"})
	add_instruction_value(cl_extra_and_named, 0)
	add_instruction_value(cl_extra_and_named, 1)
	param_profile:link("instructionInProfile", get_instruction(cl_extra_and_named, 1))
	
	local cl_extra_and_named_source = lQuery.create("P_OWL#Instruction", {id = "Class Restrictions And Named Source"})
	add_instruction_value(cl_extra_and_named_source, 0)
	add_instruction_value(cl_extra_and_named_source, 1)
	add_instruction_value(cl_extra_and_named_source, 2)
	add_instruction_value(cl_extra_and_named_source, -1)
	param_profile:link("instructionInProfile", get_instruction(cl_extra_and_named_source, 0))
	
	
	local property_restrictions = lQuery.create("P_OWL#Instruction", {id = "Property Restrictions"})
	add_instruction_value(property_restrictions, 0)
	add_instruction_value(property_restrictions, 1)
	add_instruction_value(property_restrictions, -1)
	param_profile:link("instructionInProfile", get_instruction(property_restrictions, 1))
	
	local pr_target_box = lQuery.create("P_OWL#Instruction", {id = "Property Restrictions Target Box"})
	add_instruction_value(pr_target_box, 0)
	add_instruction_value(pr_target_box, 1)
	add_instruction_value(pr_target_box, 2)
	add_instruction_value(pr_target_box, -1)
	param_profile:link("instructionInProfile", get_instruction(pr_target_box, 0))
	
	
	local disjoint_classes = lQuery.create("P_OWL#Instruction", {id = "Disjoint Classes"})
	add_instruction_value(disjoint_classes, 0)
	add_instruction_value(disjoint_classes, 1)
	add_instruction_value(disjoint_classes, -1)
	param_profile:link("instructionInProfile", get_instruction(disjoint_classes, 0))
	
	local dj_fork = lQuery.create("P_OWL#Instruction", {id = "Disjoint Classes Fork"})
	add_instruction_value(dj_fork, 0)
	add_instruction_value(dj_fork, 1)
	add_instruction_value(dj_fork, -1)
	param_profile:link("instructionInProfile", get_instruction(dj_fork, 1))
	
	local dj_group_binary = lQuery.create("P_OWL#Instruction", {id = "Disjoint Classes Group Binary"})
	add_instruction_value(dj_group_binary, 0)
	add_instruction_value(dj_group_binary, 1)
	add_instruction_value(dj_group_binary, -1)
	param_profile:link("instructionInProfile", get_instruction(dj_group_binary, 1))
	
	local dj_target = lQuery.create("P_OWL#Instruction", {id = "Disjoint Classes Target"})
	add_instruction_value(dj_target, 0)
	add_instruction_value(dj_target, 1)
	add_instruction_value(dj_target, 2)
	add_instruction_value(dj_target, -1)
	param_profile:link("instructionInProfile", get_instruction(dj_target, 0))
	
	
	local equivalent_classes = lQuery.create("P_OWL#Instruction", {id = "Equivalent Classes"})
	add_instruction_value(equivalent_classes, 0)
	add_instruction_value(equivalent_classes, 1)
	add_instruction_value(equivalent_classes, -1)
	param_profile:link("instructionInProfile", get_instruction(equivalent_classes, 0))
	
	local eq_group_binary = lQuery.create("P_OWL#Instruction", {id = "Equivalent Classes Group Binary"})
	add_instruction_value(eq_group_binary, 0)
	add_instruction_value(eq_group_binary, 1)
	add_instruction_value(eq_group_binary, -1)
	param_profile:link("instructionInProfile", get_instruction(eq_group_binary, 1))
	
	
	local object_properties = lQuery.create("P_OWL#Instruction", {id = "Object Properties"})
	add_instruction_value(object_properties, 0)
	add_instruction_value(object_properties, 1)
	add_instruction_value(object_properties, -1)
	param_profile:link("instructionInProfile", get_instruction(object_properties, 1))
	
	local op_merge = lQuery.create("P_OWL#Instruction", {id = "Object Properties Merge"})
	add_instruction_value(op_merge, 0)
	add_instruction_value(op_merge, 1)
	add_instruction_value(op_merge, -1)
	param_profile:link("instructionInProfile", get_instruction(op_merge, 1))
	
	
	local class_assertions = lQuery.create("P_OWL#Instruction", {id = "Class Assertions"})
	add_instruction_value(class_assertions, 0)
	add_instruction_value(class_assertions, 1)
	add_instruction_value(class_assertions, -1)
	param_profile:link("instructionInProfile", get_instruction(class_assertions, 1))
	
	local cl_assertions_text = lQuery.create("P_OWL#Instruction", {id = "Class Assertions Text"})
	add_instruction_value(cl_assertions_text, 0)
	add_instruction_value(cl_assertions_text, 1)
	add_instruction_value(cl_assertions_text, -1)
	param_profile:link("instructionInProfile", get_instruction(cl_assertions_text, 0))
	
	local cl_assertions_class = lQuery.create("P_OWL#Instruction", {id = "Class Assertions Class"})
	add_instruction_value(cl_assertions_class, 0)
	add_instruction_value(cl_assertions_class, 1)
	add_instruction_value(cl_assertions_class, 2)
	add_instruction_value(cl_assertions_class, -1)
	param_profile:link("instructionInProfile", get_instruction(cl_assertions_class, 0))
	
	
	local same_individuals = lQuery.create("P_OWL#Instruction", {id = "Same Individuals"})
	add_instruction_value(same_individuals, 0)
	add_instruction_value(same_individuals, 1)
	add_instruction_value(same_individuals, -1)
	param_profile:link("instructionInProfile", get_instruction(same_individuals, 0))
	
	
	local different_individuals = lQuery.create("P_OWL#Instruction", {id = "Different Individuals"})
	add_instruction_value(different_individuals, 0)
	add_instruction_value(different_individuals, 1)
	add_instruction_value(different_individuals, -1)
	param_profile:link("instructionInProfile", get_instruction(different_individuals, 1))
end


function add_instruction_value(instruction, index)
	local instruction_item = lQuery.create("P_OWL#InstructionItem", {index = index})
	instruction:link("item", instruction_item)
end

function get_instruction(instruction, index)
	local instr_in_profile = lQuery.create("P_OWL#InstructionInProfile")
	instr_in_profile:link("instruction", instruction)
	local instruction_item = lQuery(instruction):find("/item[index = "..index.."]")
	instr_in_profile:link("selected", instruction_item)
	
	return instr_in_profile
end

------------------------------------

function add_class(class_name)
	lQuery.model.add_class(class_name)
end

function set_super_class(class_name, super_class_name)
	lQuery.model.set_super_class(class_name, super_class_name)
end

function add_property(class_name, property_name)
	lQuery.model.add_property(class_name, property_name)
end

function add_composition(start_class_name, start_role_name, end_role_name, end_class_name)
	lQuery.model.add_composition(start_class_name, start_role_name, end_role_name, end_class_name)
end

function add_link(start_class, start_role, start_cardinality, end_class, end_role, end_cardinality)
	mii_rep_obj.CreateLinkType({
		start_class_name = start_class,
		start_role_name = start_role,
		start_cardinality = start_cardinality,
		
		end_class_name = end_class,
		end_role_name = end_role,
		end_cardinality = end_cardinality
	})
end

function add_ordered_link(start_class, start_role, start_cardinality, start_is_ordered, end_class, end_role, end_cardinality, end_is_ordered)
	mii_rep_obj.CreateLinkType({
		start_class_name = start_class,
		start_role_name = start_role,
		start_cardinality = start_cardinality,
		start_is_ordered = start_is_ordered,
		
		end_class_name = end_class,
		end_role_name = end_role,
		end_cardinality = end_cardinality,
		end_is_ordered = end_is_ordered
	})
end