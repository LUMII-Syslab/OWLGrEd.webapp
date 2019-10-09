module(..., package.seeall)
require "re"

function prefix_declaration()
	return re.compile(
		[[
			PrefixDeclaration	<-	'Prefix'
									'('
										(
											{:class: '' -> 'OWL#Namespace' :}
											{:attrs: PrefixExpression :}
										) -> {}
									')'
			PrefixExpression	<-	(
										{:prefix: PrefixName :}
										':=<'
										{:IRIprefix: IRIprefix :}
										'>'
									) -> {}
			PrefixName			<-	%iri_prefix*
			IRIprefix			<-	%iri_value+
		]],
		{
			iri_prefix = iri_prefix(),
			iri_value = iri_value()
		}
	)
end

function ontology()
	return re.compile(
		[[
			Ontology			<-	(
										{:class: {'Ontology'} -> 'OWL#%1' :}
										'('
										{:links: OntologyExpression :}
									) -> {}
			OntologyExpression	<-	(
										(
											{:ontologyIRI: ( %iri ) -> {} :}
											(
												' '
												{:versionIRI: ( %iri ) -> {} :}
											)?
										)?
									) -> {}
		]],
		{
			iri = iri()
		}
	)
end

function version()
	return re.compile(
		[[
			(
				{:versionIRI: ( %iri ) -> {} :}
			) -> {}
		]],
		{
			iri = iri()
		}
	)
end

function directly_imports_documents()
	return re.compile(
		[[
			(
				{:directlyImportsDocuments:
					(
						'Import(' %iri ')'
					) -> {}
				:}
			) -> {}
		]],
		{
			iri = iri()
		}
	)
end

function ontology_annotations()
	return re.compile(
		[[
			OntologyAnnotations	<-	(
										{:ontologyAnnotations:
											(
												%annotation
											) -> {}
										:}
									) -> {}
			Annotation			<-	%annotation
		]],
		{
			annotation = annotation()
		}
	)
end

function axiom()
	return re.compile(
		[[
			Axiom				<-	%declaration /
									%class_axiom /
									%object_property_axiom /
									%data_property_axiom /
									%datatype_definition /
									%has_key /
									%assertion /
									%annotation_axiom
		
			Annotation			<-	%annotation
			AnnotationValue		<-	%annotation_value
			AnnotationSubject	<-	%annotation_subject
			AnnotationProperty	<-	%annotation_property
									
			ClassExpression		<-	%class /
									%object_intersection_of /
									%object_union_of /
									%object_complement_of /
									%object_one_of /
									%object_x_values_from /
									%object_has_value /
									%object_has_self /
									%object_cardinality /
									%data_x_values_from /
									%data_has_value /
									%data_cardinality
			
			DataRange			<-	%datatype /
									%data_intersection_of /
									%data_union_of /
									%data_complement_of /
									%data_one_of /
									%datatype_restriction
			
			PrefixName			<-	%iri_prefix*
			IRIprefix			<-	%iri_value+
		]],
		{
			declaration = declaration(),
			class_axiom = class_axiom(),
			object_property_axiom = object_property_axiom(),
			data_property_axiom = data_property_axiom(),
			datatype_definition = datatype_definition(),
			has_key = has_key(),
			assertion = assertion(),
			annotation_axiom = annotation_axiom(),
			
			annotation = annotation(),
			annotation_value = annotation_value(),
			annotation_subject = annotation_subject(),
			annotation_property = annotation_property(),
			
			class = class(),
			object_intersection_of = object_intersection_of(),
			object_union_of = object_union_of(),
			object_complement_of = object_complement_of(),
			object_one_of = object_one_of(),
			object_x_values_from = object_x_values_from(),
			object_has_value = object_has_value(),
			object_has_self = object_has_self(),
			object_cardinality = object_cardinality(),
			data_x_values_from = data_x_values_from(),
			data_has_value = data_has_value(),
			data_cardinality = data_cardinality(),
			
			datatype = datatype(),
			data_intersection_of = data_intersection_of(),
			data_union_of = data_union_of(),
			data_complement_of = data_complement_of(),
			data_one_of = data_one_of(),
			datatype_restriction = datatype_restriction(),
			
			object_property_expression = object_property_expression(),
			object_property = object_property(),
			data_property_expression = data_property_expression(),
			data_property = data_property(),
			
			iri_prefix = iri_prefix(),
			iri_value = iri_value()
		}
	)
end

-----
-- Annotations

function annotation()
	return re.compile(
		[[
			(
				{:class: {'Annotation'} -> 'OWL#%1' :}
				'('
				{:links:
						(
							(
								{:annotationAnnotations:
									(
										Annotation (' ' Annotation)*
									) -> {}
								:}
								' '
							)?
							{:annotationProperty: ( %annotation_property ) -> {} :}
							' '
							{:annotationValue: ( %annotation_value ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			annotation_property = annotation_property(),
			annotation_value = annotation_value()
		}
	)
end

function annotation_property()
	return re.compile(
		[[
			(
				{:class: '' -> 'OWL#AnnotationProperty' :}
				{:links: %entity_iri :}
			) -> {}
		]],
		{
			entity_iri = entity_iri()
		}
	)
end

function annotation_value()
	return re.compile(
		[[
			%literal /
			(
				{:class: '' -> 'OWL#AnnotationValue' :}
				{:links:
						(
							(
								{:iri: ( %iri ) -> {} :} /
								{:anonymousIndividual: ( %anonymous_individual ) -> {} :}
							)
						) -> {}
				:}
			) -> {}
		]],
		{
			literal = literal(),
			iri = iri(),
			anonymous_individual = anonymous_individual()
		}
	)
end

function annotation_subject()
	return re.compile(
		[[
			(
				{:class: '' -> 'OWL#AnnotationSubject' :}
				{:links:
					(
						(
							{:iri: ( %iri ) -> {} :} /
							{:anonymousIndividual: ( %anonymous_individual ) -> {} :}
						)
					) -> {}
				:}
			) -> {}
		]],
		{
			iri = iri(),
			anonymous_individual = anonymous_individual()
		}
	)
end
	
-----
-- Annotation Axioms

function annotation_axiom()
	return re.compile(
		[[
			%annotation_assertion /
			%sub_annotation_property_of /
			%annotation_property_domain /
			%annotation_property_range
		]],
		{
			annotation_assertion = annotation_assertion(),
			sub_annotation_property_of = sub_annotation_property_of(),
			annotation_property_domain = annotation_property_domain(),
			annotation_property_range = annotation_property_range()
		}
	)
end

function annotation_assertion()
	return re.compile(
		[[
			(
				{:class: {'AnnotationAssertion'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:annotationProperty: ( %annotation_property ) -> {} :}
						' '
						{:annotationSubject: ( %annotation_subject ) -> {} :}
						' '
						{:annotationValue: ( %annotation_value ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			annotation_property = annotation_property(),
			annotation_subject = annotation_subject(),
			annotation_value = annotation_value()
		}
	)
end

function sub_annotation_property_of()
	return re.compile(
		[[
			(
				{:class: {'SubAnnotationPropertyOf'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:subAnnotationProperty: ( %annotation_property ) -> {} :}
						' '
						{:superAnnotationProperty: ( %annotation_property ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			annotation_property = annotation_property()
		}
	)
end

function annotation_property_domain()
	return re.compile(
		[[
			(
				{:class: {'AnnotationPropertyDomain'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:annotationProperty: ( %annotation_property ) -> {} :}
						' '
						{:domain: ( %iri ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			annotation_property = annotation_property(),
			iri = iri()
		}
	)
end

function annotation_property_range()
	return re.compile(
		[[
			(
				{:class: {'AnnotationPropertyRange'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:annotationProperty: ( %annotation_property ) -> {} :}
						' '
						{:range: ( %iri ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			annotation_property = annotation_property(),
			iri = iri()
		}
	)
end

-----
-- Declaration

function declaration()
	return re.compile(
		[[
			(
				{:class: {'Declaration'} -> 'OWL#%1' :}
				'('
				{:links:
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						%entity
				:}
				')'
			) -> {}
		]],
		{
			entity = entity()
		}
	)
end

function entity()
	return re.compile(
		[[
			'Class('
					(
						{:entity: ( %class ) -> {} :}
					) -> {}
			')' /
			'Datatype('
					(
						{:entity: ( %datatype ) -> {} :}
					) -> {}
			')' /
			'DataProperty('
					(
						{:entity: ( %data_property ) -> {} :}
					) -> {}
			')' /
			'ObjectProperty('
					(
						{:entity: ( %object_property ) -> {} :}
					) -> {}
			')' /
			'AnnotationProperty('
					(
						{:entity: ( %annotation_property ) -> {} :}
					) -> {}
			')' /
			'NamedIndividual('
					(
						{:entity: ( %named_individual ) -> {} :}
					) -> {}
			')'
		]],
		{
			class = class(),
			datatype = datatype(),
			data_property = data_property(),
			object_property = object_property(),
			annotation_property = annotation_property(),
			named_individual = named_individual()
		}
	)
end

-----
-- Class Axioms

function class_axiom()
	return re.compile(
		[[
			%sub_class_of /
			%equivalent_classes /
			%disjoint_classes /
			%disjoint_union
		]],
		{
			sub_class_of = sub_class_of(),
			equivalent_classes = equivalent_classes(),
			disjoint_classes = disjoint_classes(),
			disjoint_union = disjoint_union(),
		}
	)
end

function sub_class_of()
	return re.compile(
		[[
			(
				{:class: {'SubClassOf'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:subClassExpression: ( ClassExpression ) -> {} :}
						' '
						{:superClassExpression: ( ClassExpression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function equivalent_classes()
	return re.compile(
		[[
			(
				{:class: {'EquivalentClasses'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:classExpressions: ( ClassExpression (' ' ClassExpression)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function disjoint_classes()
	return re.compile(
		[[
			(
				{:class: {'DisjointClasses'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:classExpressions: ( ClassExpression (' ' ClassExpression)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function disjoint_union()
	return re.compile(
		[[
			(
				{:class: {'DisjointUnion'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:class: ( %class ) -> {} :}
						' '
						{:disjointClassExpressions: ( ClassExpression (' ' ClassExpression)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			class = class()
		}
	)
end

-----
-- Object Property Axioms

function object_property_axiom()
	return re.compile(
		[[
			%sub_object_property_of /
			%object_property_domain /
			%object_property_range /
			%equivalent_object_properties /
			%disjoint_object_properties /
			%inverse_object_properties /
			%object_property_characteristic
		]],
		{
			sub_object_property_of = sub_object_property_of(),
			object_property_domain = object_property_domain(),
			object_property_range = object_property_range(),
			equivalent_object_properties = equivalent_object_properties(),
			disjoint_object_properties = disjoint_object_properties(),
			inverse_object_properties = inverse_object_properties(),
			object_property_characteristic = object_property_characteristic()
		}
	)
end

function sub_object_property_of()
	return re.compile(
		[[
			(
				{:class: {'SubObjectPropertyOf'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						(
							{:subObjectPropertyExpressions: ( %object_property_expression ) -> {} :}
							/
							'ObjectPropertyChain('
								{:subObjectPropertyExpressions: ( %object_property_expression (' ' %object_property_expression)* ) -> {} :}
							')'
						)
						' '
						{:superObjectPropertyExpression: ( %object_property_expression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

function object_property_domain()
	return re.compile(
		[[
			(
				{:class: {'ObjectPropertyDomain'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:objectPropertyExpression: ( %object_property_expression ) -> {} :}
						' '
						{:domain: ( ClassExpression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

function object_property_range()
	return re.compile(
		[[
			(
				{:class: {'ObjectPropertyRange'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:objectPropertyExpression: ( %object_property_expression ) -> {} :}
						' '
						{:range: ( ClassExpression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

function equivalent_object_properties()
	return re.compile(
		[[
			(
				{:class: {'EquivalentObjectProperties'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:objectPropertyExpressions: ( %object_property_expression (' ' %object_property_expression)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

function disjoint_object_properties()
	return re.compile(
		[[
			(
				{:class: {'DisjointObjectProperties'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:objectPropertyExpressions: ( %object_property_expression (' ' %object_property_expression)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

function inverse_object_properties()
	return re.compile(
		[[
			(
				{:class: {'InverseObjectProperties'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:objectPropertyExpression1: ( %object_property_expression ) -> {} :}
						' '
						{:objectPropertyExpression2: ( %object_property_expression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

function object_property_characteristic()
	return re.compile(
		[[
			(
				{:class:
					({
						'FunctionalObjectProperty' /
						'InverseFunctionalObjectProperty' /
						'ReflexiveObjectProperty' /
						'IrreflexiveObjectProperty' /
						'SymmetricObjectProperty' /
						'AsymmetricObjectProperty' /
						'TransitiveObjectProperty'
					}) -> 'OWL#%1'
				:}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:objectPropertyExpression: ( %object_property_expression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

-----
-- Data Property Axioms

function data_property_axiom()
	return re.compile(
		[[
			%sub_data_property_of /
			%data_property_domain /
			%data_property_range /
			%equivalent_data_properties /
			%disjoint_data_properties /
			%functional_data_property
		]],
		{
			sub_data_property_of = sub_data_property_of(),
			data_property_domain = data_property_domain(),
			data_property_range = data_property_range(),
			equivalent_data_properties = equivalent_data_properties(),
			disjoint_data_properties = disjoint_data_properties(),
			functional_data_property = functional_data_property()
		}
	)
end

function sub_data_property_of()
	return re.compile(
		[[
			(
				{:class: {'SubDataPropertyOf'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:subDataPropertyExpression: ( %data_property_expression ) -> {} :}
						' '
						{:superDataPropertyExpression: ( %data_property_expression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression()
		}
	)
end

function data_property_domain()
	return re.compile(
		[[
			(
				{:class: {'DataPropertyDomain'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:dataPropertyExpression: ( %data_property_expression ) -> {} :}
						' '
						{:domain: ( ClassExpression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression()
		}
	)
end

function data_property_range()
	return re.compile(
		[[
			(
				{:class: {'DataPropertyRange'} -> 'OWL#%1' :}
				'('
				{:links:
						(
							(
								{:axiomAnnotations:
									(
										Annotation (' ' Annotation)*
									) -> {}
								:}
								' '
							)?
							{:dataPropertyExpression: ( %data_property_expression ) -> {} :}
							' '
							{:range: ( DataRange ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression()
		}
	)
end

function equivalent_data_properties()
	return re.compile(
		[[
			(
				{:class: {'EquivalentDataProperties'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:dataPropertyExpressions: ( %data_property_expression (' ' %data_property_expression)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression()
		}
	)
end

function disjoint_data_properties()
	return re.compile(
		[[
			(
				{:class: {'DisjointDataProperties'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:dataPropertyExpressions: ( %data_property_expression (' ' %data_property_expression)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression()
		}
	)
end

function functional_data_property()
	return re.compile(
		[[
			(
				{:class: {'FunctionalDataProperty'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:dataPropertyExpression: ( %data_property_expression ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression()
		}
	)
end

-----
-- Datatype Definitions

function datatype_definition()
	return re.compile(
		[[
			(
				{:class: {'DatatypeDefinition'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:datatype: ( %datatype ) -> {} :}
						' '
						{:dataRange: ( DataRange ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			datatype = datatype()
		}
	)
end

-----
-- Has Key

function has_key()
	return re.compile(
		[[
			(
				{:class: {'HasKey'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:classExpression: ( ClassExpression ) -> {} :}
						' '
						'('
						(
							{:objectPropertyExpressions:
								(
									%object_property_expression (' ' %object_property_expression)*
								) -> {}
							:}
						)?
						')'
						' '
						'('
						(
							{:dataPropertyExpressions:
								(
									%data_property_expression (' ' %data_property_expression)*
								) -> {}
							:}
						)?
						')'
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression(),
			data_property_expression = data_property_expression()
		}
	)
end

-----
-- Assertions

function assertion()
	return re.compile(
		[[
			%same_individual /
			%different_individuals /
			%class_assertion /
			%object_property_assertion /
			%data_property_assertion
		]],
		{
			same_individual = same_individual(),
			different_individuals = different_individuals(),
			class_assertion = class_assertion(),
			object_property_assertion = object_property_assertion(),
			data_property_assertion = data_property_assertion()
		}
	)
end

function same_individual()
	return re.compile(
		[[
			(
				{:class: {'SameIndividual'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:individuals: ( %individual (' ' %individual)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			individual = individual()
		}
	)
end

function different_individuals()
	return re.compile(
		[[
			(
				{:class: {'DifferentIndividuals'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:individuals: ( %individual (' ' %individual)+ ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			individual = individual()
		}
	)
end

function class_assertion()
	return re.compile(
		[[
			(
				{:class: {'ClassAssertion'} -> 'OWL#%1' :}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:classExpression: ( ClassExpression ) -> {} :}
						' '
						{:individual: ( %individual ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			individual = individual()
		}
	)
end

function object_property_assertion()
	return re.compile(
		[[
			(
				{:class:
					({
						'ObjectPropertyAssertion' /
						'NegativeObjectPropertyAssertion'
					}) -> 'OWL#%1'
				:}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:objectPropertyExpression: ( %object_property_expression ) -> {} :}
						' '
						{:sourceIndividual: ( %individual ) -> {} :}
						' '
						{:targetIndividual: ( %individual ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression(),
			individual = individual()
		}
	)
end

function data_property_assertion()
	return re.compile(
		[[
			(
				{:class:
					({
						'DataPropertyAssertion' /
						'NegativeDataPropertyAssertion'
					}) -> 'OWL#%1'
				:}
				'('
				{:links:
					(
						(
							{:axiomAnnotations:
								(
									Annotation (' ' Annotation)*
								) -> {}
							:}
							' '
						)?
						{:dataPropertyExpression: ( %data_property_expression ) -> {} :}
						' '
						{:sourceIndividual: ( %individual ) -> {} :}
						' '
						{:targetValue: ( %literal ) -> {} :}
					) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression(),
			individual = individual(),
			literal = literal()
		}
	)
end

-----
-- Class Expressions

function class_expression()
	return re.compile(
		[[
			ClassExpression <-	%class /
								%object_intersection_of /
								%object_union_of /
								%object_complement_of /
								%object_one_of /
								%object_x_values_from /
								%object_has_value /
								%object_has_self /
								%object_cardinality /
								%data_x_values_from /
								%data_has_value /
								%data_cardinality
		]],
		{
			class = class(),
			object_intersection_of = object_intersection_of(),
			object_union_of = object_union_of(),
			object_complement_of = object_complement_of(),
			object_one_of = object_one_of(),
			object_x_values_from = object_x_values_from(),
			object_has_value = object_has_value(),
			object_has_self = object_has_self(),
			object_cardinality = object_cardinality(),
			data_x_values_from = data_x_values_from(),
			data_has_value = data_has_value(),
			data_cardinality = data_cardinality()
		}
	)
end

function class()
	return re.compile(
		[[
			(
				{:class: %owl_class :}
				{:links: %entity_iri :}
			) -> {}
		]],
		{
			owl_class = equivalent_class_list_pat("OWL#Class", "OWL#ClassEntity"),
			entity_iri = entity_iri()
		}
	)
end

function object_intersection_of()
	return re.compile(
		[[
			(
				{:class: {'ObjectIntersectionOf'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
						(
							{:classExpressions: ( ClassExpression (' ' ClassExpression)+ ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function object_union_of()
	return re.compile(
		[[
			(
				{:class: {'ObjectUnionOf'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
						(
							{:classExpressions: ( ClassExpression (' ' ClassExpression)+ ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function object_complement_of()
	return re.compile(
		[[
			(
				{:class: {'ObjectComplementOf'} -> 'OWL#%1' :}
				'('
				{:links:
						(
							{:classExpression: ( ClassExpression ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function object_one_of()
	return re.compile(
		[[
			(
				{:class: {'ObjectOneOf'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
						(
							{:individuals: ( %individual (' ' %individual)* ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			individual = individual()
		}
	)
end

function object_x_values_from()
	return re.compile(
		[[
			(
				{:class:
						({
							'ObjectSomeValuesFrom' /
							'ObjectAllValuesFrom'
						}) -> 'OWL#%1'
				:}
				'('
				{:links:
						(
							{:objectPropertyExpression: ( %object_property_expression ) -> {} :}
							' '
							{:classExpression: ( ClassExpression ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

function object_has_value()
	return re.compile(
		[[
			(
				{:class: {'ObjectHasValue'} -> 'OWL#%1' :}
				'('
				{:links:
						(
							{:objectPropertyExpression: ( %object_property_expression ) -> {} :}
							' '
							{:individual: ( %individual ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			individual = individual(),
			object_property_expression = object_property_expression()
		}
	)
end

function object_has_self()
	return re.compile(
		[[
			(
				{:class: {'ObjectHasSelf'} -> 'OWL#%1' :}
				'('
				{:links:
						(
							{:objectPropertyExpression: ( %object_property_expression ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression(),
		}
	)
end

function object_cardinality()
	return re.compile(
		[[
			(
				{:class:
						({
							'ObjectMinCardinality' /
							'ObjectMaxCardinality' /
							'ObjectExactCardinality'
						}) -> 'OWL#%1'
				:}
				'('
				{:attrs:
						(
							{:cardinality: [0-9]+ :}
						) -> {}
				:}
				' '
				{:links:
						(
							{:objectPropertyExpression: ( %object_property_expression ) -> {} :}
							(
								' '
								{:classExpression: ( ClassExpression ) -> {} :}
							)?
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			object_property_expression = object_property_expression()
		}
	)
end

function data_x_values_from()
	return re.compile(
		[[
			(
				{:class:
						({
							'DataSomeValuesFrom' /
							'DataAllValuesFrom'
						}) -> 'OWL#%1'
				:}
				{:sort: '' -> 'true' :}
				'('
				{:links:
						(
							{:dataPropertyExpressions: ( %data_property_expression ) -> {} :}
							' '
							{:dataRange: ( %data_range ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression(),
			data_range = data_range()
		}
	)
end

function data_has_value()
	return re.compile(
		[[
			(
				{:class: {'DataHasValue'} -> 'OWL#%1' :}
				'('
				{:links:
						(
							{:dataPropertyExpression: ( %data_property_expression ) -> {} :}
							' '
							{:literal: ( %literal ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression(),
			literal = literal()
		}
	)
end

function data_cardinality()
	return re.compile(
		[[
			(
				{:class:
						({
							'DataMinCardinality' /
							'DataMaxCardinality' /
							'DataExactCardinality'
						}) -> 'OWL#%1'
				:}
				'('
				{:attrs:
						(
							{:cardinality: [0-9]+ :}
						) -> {}
				:}
				' '
				{:links:
						(
							{:dataPropertyExpression: ( %data_property_expression ) -> {} :}
							(
								' '
								{:dataRange: ( %data_range ) -> {} :}
							)?
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			data_property_expression = data_property_expression(),
			data_range = data_range()
		}
	)
end

-----
-- Object Property Expressions

function object_property_expression()
	return re.compile(
		[[
			%object_property / %inverse_object_property
		]],
		{
			inverse_object_property = inverse_object_property(),
			object_property = object_property()
		}
	)
end

function object_property()
	return re.compile(
		[[
			(
				{:class: %owl_object_property :}
				{:links: %entity_iri :}
			) -> {}
		]],
		{
			owl_object_property = equivalent_class_list_pat("OWL#ObjectProperty", "OWL#ObjectPropertyEntity"),
			entity_iri = entity_iri()
		}
	)
end

function inverse_object_property()
	return re.compile(
		[[
			(
				{:class: 'ObjectInverseOf' -> 'OWL#InverseObjectProperty' :}
				'('
					{:links:
							(
								{:objectProperty: ( %object_property ) -> {} :}
							) -> {}
					:}
				')'
			) -> {}
		]],
		{
			object_property = object_property()
		}
	)
end

-----
-- Data Property Expressions

function data_property_expression()
	return re.compile(
		[[
			%data_property
		]],
		{
			data_property = data_property()
		}
	)
end

function data_property()
	return re.compile(
		[[
			(
				{:class: %owl_data_property :}
				{:links: %entity_iri :}
			) -> {}
		]],
		{
			owl_data_property = equivalent_class_list_pat("OWL#DataProperty", "OWL#DataPropertyEntity"),
			entity_iri = entity_iri()
		}
	)
end

function data_range()
	return re.compile(
		[[
			DataRange	<-	%datatype /
							%data_intersection_of /
							%data_union_of /
							%data_complement_of /
							%data_one_of /
							%datatype_restriction
		]],
		{
			datatype = datatype(),
			data_intersection_of = data_intersection_of(),
			data_union_of = data_union_of(),
			data_complement_of = data_complement_of(),
			data_one_of = data_one_of(),
			datatype_restriction = datatype_restriction()
		}
	)
end

function datatype()
	return re.compile(
		[[
			(
				{:class: %owl_datatype :}
				{:links: %entity_iri :}
			) -> {}
		]],
		{
			owl_datatype = equivalent_class_list_pat("OWL#Datatype", "OWL#DatatypeEntity"),
			entity_iri = entity_iri()
		}
	)
end

function data_intersection_of()
	return re.compile(
		[[
			(
				{:class: {'DataIntersectionOf'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
						(
							{:dataRanges: ( DataRange (' ' DataRange)+ ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function data_union_of()
	return re.compile(
		[[
			(
				{:class: {'DataUnionOf'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
						(
							{:dataRanges: ( DataRange (' ' DataRange)+ ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function data_complement_of()
	return re.compile(
		[[
			(
				{:class: {'DataComplementOf'} -> 'OWL#%1' :}
				'('
				{:links:
						(
							{:dataRange: ( DataRange ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]]
	)
end

function data_one_of()
	return re.compile(
		[[
			(
				{:class: {'DataOneOf'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
						(
							{:literals: ( %literal (' ' %literal)* ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			literal = literal()
		}
	)
end

function datatype_restriction()
	return re.compile(
		[[
			(
				{:class: {'DatatypeRestriction'} -> 'OWL#%1' :}
				{:sort: '' -> 'true' :}
				'('
				{:links:
						(
							{:datatype: ( %datatype ) -> {} :}
							{:restrictions: ( (' ' %facet_restriction)+ ) -> {} :}
						) -> {}
				:}
				')'
			) -> {}
		]],
		{
			datatype = datatype(),
			facet_restriction = facet_restriction()
		}
	)
end

function facet_restriction()
	return re.compile(
		[[
			(
				{:class: '' -> 'OWL#FacetRestriction' :}
				{:links:
						(
							{:constrainingFacet: ( %iri ) -> {} :}
							' '
							{:restrictionValue: ( %literal ) -> {} :}
						) -> {}
				:}
			) -> {}
		]],
		{
			iri = iri(),
			literal = literal()
		}
	)
end

-----

function literal()
	return re.compile(
		[[
			(
				{:class: '' -> 'OWL#Literal' :}
				{:attrs: %quoted_string :}
				(
					'^^'
					{:links:
							(
								{:datatype: ( %datatype ) -> {} :}
							) -> {}
					:}
				)?
			) -> {}
		]],
		{
			quoted_string = quoted_string(),
			datatype = datatype()
		}
	)
end

function individual()
	return re.compile(
		[[
			%anonymous_individual / %named_individual
		]],
		{
			anonymous_individual = anonymous_individual(),
			named_individual = named_individual()
		}
	)
end

function anonymous_individual()
	return re.compile(
		[[
			(
				{:class: '' -> 'OWL#AnonymousIndividual' :}
				{:attrs:
					(
						{:nodeID: ('_:' %iri_value+) :}
					) -> {}
				:}
			) -> {}
		]],
		{
			iri_value = iri_value()
		}
	)
end

function named_individual()
	return re.compile(
		[[
			(
				{:class: %owl_named_individual :}
				{:links: %entity_iri :}
			) -> {}
		]],
		{
			owl_named_individual = equivalent_class_list_pat("OWL#NamedIndividual", "OWL#NamedIndividualEntity"),
			entity_iri = entity_iri()
		}
	)
end

function entity_iri()
	return re.compile(
		[[
			(
				{:entityIRI: ( %iri ) -> {} :}
			) -> {}
		]],
		{
			iri = iri()
		}
	)
end

function iri()
	return re.compile(
		[[
			(
				{:class: '' -> 'OWL#IRI' :}
				{:attrs: %iri_attrs :}
			) -> {}
		]],
		{
			iri_attrs = iri_attrs()
		}
	)
end

function iri_attrs()
	return re.compile(
		[[
			(
				'<' {:prefix: (%iri_prefix / ':')* :} {:delim: '#' :} {:value: %iri_value* :} '>' /
				'<' {:value: %iri_value+ :} '>' /
				{:prefix: %iri_prefix* :} {:delim: ':' :} {:value: %iri_value* :}
			) -> {}
		]],
		{
			iri_prefix = iri_prefix(),
			iri_value = iri_value()
		}
	)
end

function quoted_string()
	return re.compile(
		[[
			(
				'"' {:text: %quoted_string_chars+ :} '"'
				(
					'@' {:language: ([A-Za-z]+) :}
				)?
			) -> {}
		]],
		{
			quoted_string_chars = quoted_string_chars()
		}
	)
end

----------

function equivalent_class_list_pat(...)
	local tmp = {}
	for _, class_name in ipairs{...} do
		table.insert(tmp, string.format("'' -> '%s' ", class_name))
	end
	return re.compile("(" .. table.concat(tmp) .. ") -> {}")
end

function iri_prefix()
	local s = "[A-Z] / [a-z] / [0-9] / [\192-\214] / [\216-\246] / [\248-\255] / [_] / [.] / [-] / [/]"
		--/ [\880-\893] / [\895-\8191] / [\8204-\8205] / [\8304-\8591] / [\11264-\12271] / [\12289-\55295] / [\63744-\64975] / [\65008-\65533] / [\65536-\983039]"
	return re.compile(s)
end

function iri_value()
	--local s = "[\1-\33] / [\35-\40] / [\42-\61] / [\63-\91] / [\93-\255]"
	local s = "[A-Z] / [a-z] / [0-9] / [\192-\214] / [\216-\246] / [\248-\255] / [_] / [.] / [-] / [/] / [:] / [+] / [#]"
	return re.compile(s)
end

function quoted_string_chars()
	local s = "[^\"]"
	return re.compile(s)
end

---------------
-- Old grammar

function load()
	return re.compile([[
		OntologyDocument	<-	(%nl)*
								(
									PrefixDeclaration* (%nl)*
									Ontology (%nl)*
								) -> {}
								!.
		
		PrefixDeclaration	<-	'Prefix'
								'('
								(
									{:class: '' -> 'OWL#Namespace' :}
									{:attrs: PrefixExpression :}
								) -> {}
								')' (%nl)*
		PrefixExpression	<-	(
									{:prefix: PrefixName :}
									':=<'
									{:IRIprefix: IRIprefix :}
									'>'
								) -> {}
		
		Ontology			<-	(
									{:class: {'Ontology'} -> 'OWL#%1' :}
									'('
									{:links: OntologyExpression :} (%nl)*
									')'
								) -> {}
		OntologyExpression	<-	(
									(
										{:ontologyIRI: ( %iri ) -> {} :}
										(
											(' ' / %nl)+
											{:versionIRI: ( %iri ) -> {} :}
										)?
									)?
									(%nl)*
									(
										{:directlyImportsDocuments:
											(
												DirectlyImportsDocuments
												(
													(%nl)*
													DirectlyImportsDocuments
												)*
											) -> {}
										:}
									)?
									(%nl)*
									(
										{:ontologyAnnotations:
											(
												%annotation
												(
													(%nl)*
													%annotation
												)*
											) -> {}
										:}
									)?
									(%nl)*
									(
										{:axioms:
											(
												Axiom
												(
													(%nl)*
													Axiom
												)*
											) -> {}
										:}
									)?
								) -> {}
								
		DirectlyImportsDocuments	<-	'Import(' %iri ')'
		
		
		
		Annotation			<-	%annotation
		AnnotationValue		<-	%annotation_value
		AnnotationSubject	<-	%annotation_subject
								
		Axiom				<-	(
									%declaration /
									%class_axiom /
									%object_property_axiom /
									%data_property_axiom /
									%datatype_definition /
									%has_key /
									%assertion /
									%annotation_axiom
								)
								
		ClassExpression		<-	%class /
								%object_intersection_of /
								%object_union_of /
								%object_complement_of /
								%object_one_of /
								%object_x_values_from /
								%object_has_value /
								%object_has_self /
								%object_cardinality /
								%data_x_values_from /
								%data_has_value /
								%data_cardinality
		
		DataRange			<-	%datatype /
								%data_intersection_of /
								%data_union_of /
								%data_complement_of /
								%data_one_of /
								%datatype_restriction
									
		AnnotationProperty	<-	%annotation_property
		
		PrefixName			<-	%iri_prefix*
		IRIprefix			<-	%iri_value+
	]],
	{
		annotation = annotation(),
		annotation_axiom = annotation_axiom(),
		annotation_property = annotation_property(),
		annotation_value = annotation_value(),
		annotation_subject = annotation_subject(),
		declaration = declaration(),
		class_axiom = class_axiom(),
		object_property_axiom = object_property_axiom(),
		data_property_axiom = data_property_axiom(),
		datatype_definition = datatype_definition(),
		has_key = has_key(),
		assertion = assertion(),
		class = class(),
		object_intersection_of = object_intersection_of(),
		object_union_of = object_union_of(),
		object_complement_of = object_complement_of(),
		object_one_of = object_one_of(),
		object_x_values_from = object_x_values_from(),
		object_has_value = object_has_value(),
		object_has_self = object_has_self(),
		object_cardinality = object_cardinality(),
		data_x_values_from = data_x_values_from(),
		data_has_value = data_has_value(),
		data_cardinality = data_cardinality(),
		object_property_expression = object_property_expression(),
		object_property = object_property(),
		data_property_expression = data_property_expression(),
		data_property = data_property(),
		datatype = datatype(),
		data_intersection_of = data_intersection_of(),
		data_union_of = data_union_of(),
		data_complement_of = data_complement_of(),
		data_one_of = data_one_of(),
		datatype_restriction = datatype_restriction(),
		individual = individual(),
		anonymous_individual = anonymous_individual(),
		named_individual = named_individual(),
		literal = literal(),
		entity_iri = entity_iri(),
		iri = iri(),
		iri_prefix = iri_prefix(),
		iri_value = iri_value()
	})
end