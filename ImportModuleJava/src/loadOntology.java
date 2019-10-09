import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.swing.JOptionPane;

import org.apache.commons.io.FileUtils;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.io.OWLOntologyDocumentSource;
import org.semanticweb.owlapi.io.StreamDocumentSource;
import org.semanticweb.owlapi.manchestersyntax.renderer.ManchesterOWLSyntaxOWLObjectRendererImpl;
import org.semanticweb.owlapi.model.HasIRI;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.MissingImportHandlingStrategy;
import org.semanticweb.owlapi.model.OWLAnnotation;
import org.semanticweb.owlapi.model.OWLAnnotationAssertionAxiom;
import org.semanticweb.owlapi.model.OWLAnnotationProperty;
import org.semanticweb.owlapi.model.OWLAnnotationPropertyDomainAxiom;
import org.semanticweb.owlapi.model.OWLAnnotationPropertyRangeAxiom;
import org.semanticweb.owlapi.model.OWLAxiom;
import org.semanticweb.owlapi.model.OWLCardinalityRestriction;
import org.semanticweb.owlapi.model.OWLClass;
import org.semanticweb.owlapi.model.OWLClassAssertionAxiom;
import org.semanticweb.owlapi.model.OWLClassExpression;
import org.semanticweb.owlapi.model.OWLDataAllValuesFrom;
import org.semanticweb.owlapi.model.OWLDataFactory;
import org.semanticweb.owlapi.model.OWLDataProperty;
import org.semanticweb.owlapi.model.OWLDataPropertyAssertionAxiom;
import org.semanticweb.owlapi.model.OWLDataPropertyDomainAxiom;
import org.semanticweb.owlapi.model.OWLDataPropertyRangeAxiom;
import org.semanticweb.owlapi.model.OWLDatatype;
import org.semanticweb.owlapi.model.OWLDatatypeDefinitionAxiom;
import org.semanticweb.owlapi.model.OWLDifferentIndividualsAxiom;
import org.semanticweb.owlapi.model.OWLDisjointClassesAxiom;
import org.semanticweb.owlapi.model.OWLDisjointDataPropertiesAxiom;
import org.semanticweb.owlapi.model.OWLDisjointObjectPropertiesAxiom;
import org.semanticweb.owlapi.model.OWLDocumentFormat;
import org.semanticweb.owlapi.model.OWLEntity;
import org.semanticweb.owlapi.model.OWLEquivalentClassesAxiom;
import org.semanticweb.owlapi.model.OWLEquivalentDataPropertiesAxiom;
import org.semanticweb.owlapi.model.OWLEquivalentObjectPropertiesAxiom;
import org.semanticweb.owlapi.model.OWLHasKeyAxiom;
import org.semanticweb.owlapi.model.OWLImportsDeclaration;
import org.semanticweb.owlapi.model.OWLIndividual;
import org.semanticweb.owlapi.model.OWLInverseObjectPropertiesAxiom;
import org.semanticweb.owlapi.model.OWLLiteral;
import org.semanticweb.owlapi.model.OWLNamedIndividual;
import org.semanticweb.owlapi.model.OWLNegativeDataPropertyAssertionAxiom;
import org.semanticweb.owlapi.model.OWLNegativeObjectPropertyAssertionAxiom;
import org.semanticweb.owlapi.model.OWLObjectProperty;
import org.semanticweb.owlapi.model.OWLObjectPropertyAssertionAxiom;
import org.semanticweb.owlapi.model.OWLObjectPropertyDomainAxiom;
import org.semanticweb.owlapi.model.OWLObjectPropertyExpression;
import org.semanticweb.owlapi.model.OWLObjectPropertyRangeAxiom;
import org.semanticweb.owlapi.model.OWLObjectSomeValuesFrom;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyCreationException;
import org.semanticweb.owlapi.model.OWLOntologyLoaderConfiguration;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.semanticweb.owlapi.model.OWLProperty;
import org.semanticweb.owlapi.model.OWLSameIndividualAxiom;
import org.semanticweb.owlapi.model.OWLSubClassOfAxiom;
import org.semanticweb.owlapi.model.OWLSubDataPropertyOfAxiom;
import org.semanticweb.owlapi.model.OWLSubObjectPropertyOfAxiom;
import org.semanticweb.owlapi.model.OWLObjectAllValuesFrom;
import org.semanticweb.owlapi.model.OWLSubPropertyChainOfAxiom;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;

public class loadOntology {
	public static ArrayList<String> unexported = new ArrayList<String>();
	public static Boolean avf = false;
	public static Boolean cont = false;
	public static Boolean defaultMaxCardinality = false;
	public static JsonObject preferences;
	
	public static void main(String[] args) throws OWLOntologyCreationException {
		//String ontologyPath = "E:/Darbs/Ontologijas/company.owl";
	
        String lines;
		try {
			//lines = FileUtils.readFileToString(new File("C:/Users/Julija/Desktop/ontology2.txt"));
			lines = FileUtils.readFileToString(new File("C:/Users/Julija/Desktop/Darbs/ImportaModulis/ontology2.txt"), "UTF-8"); //darba portativais
			
			//lines = FileUtils.readFileToString(new File("C:/Users/user/Desktop/ontology2.txt"));//darba dators
			//System.out.println(lines);
			//System.out.println(importOntologies(lines.replace("\n", "\\n")));
			
			importOntologies(lines);
			
		} catch (IOException e) {
			
			e.printStackTrace();
		}
        
        
        
        //String a = "Ontology(<http://lumii.lv/ontologies/B.owl>\nAnnotationAssertion(\n<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForClass_ShowAnnotation_InField>\n<http://rdb2owl.lumii.lv/2012/1.0/rdb2owl#DBExpr>\n\"ASFictitiousDBExpr/DBExpr/DBExpr\")\nAnnotationAssertion(\n<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForAttr_ShowAnnotation_InField>\n<http://rdb2owl.lumii.lv/2012/1.0/rdb2owl#DBExpr>\n\"DBExpr/ASFictitiousDBExpr/DBExpr/DBExpr\")\nAnnotationAssertion(\n<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForRole_ShowAnnotation_InField>\n<http://rdb2owl.lumii.lv/2012/1.0/rdb2owl#DBExpr>\n\"DBExpr/ASFictitiousDBExpr/DBExpr/DBExpr\")\nAnnotationAssertion(\n<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForRole_ShowAnnotation_InField>\n<http://rdb2owl.lumii.lv/2012/1.0/rdb2owl#DBExpr>\n\"DBExpr/ASFictitiousDBExpr/DBExpr/DBExpr\")\nAnnotationAssertion(\n<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForIndiv_ShowAnnotation_InField>\n<http://rdb2owl.lumii.lv/2012/1.0/rdb2owl#DBExpr>\n\"ASFictitiousDBExpr/DBExpr/DBExpr\")\nAnnotationAssertion(\nAnnotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_RequireValue> \"true\")\nAnnotation(<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ShowAnnotation_CreateValue> \"true\")\n<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#ForClass_ShowAnnotation_InField>\n<http://obis.lumii.lv/2013/01/obis#isEnumerated>\n\"isEnumerated\"))";
        
        //importOntologies(argd);
	}
	
	public static String importOntologies (String args) throws OWLOntologyCreationException, MalformedURLException, IOException {
		
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		
		Gson gson = new Gson();
		JsonElement element = gson.fromJson (args, JsonElement.class);
		JsonObject jsonObj = element.getAsJsonObject();
		
		JsonObject extensions = jsonObj.getAsJsonObject("extensions");
		JsonPrimitive allvaluesfrom = extensions.getAsJsonPrimitive("allValuesFrom");
		JsonPrimitive container = extensions.getAsJsonPrimitive("container");
		JsonPrimitive defaultMaxCard = extensions.getAsJsonPrimitive("defaultMaxCardinality");
		
		//ontology import preferences
		preferences = jsonObj.getAsJsonObject("preferences");
		// >>> null checks by SK
		if ((allvaluesfrom!=null) && (allvaluesfrom.toString().equals("true"))) avf = true;
		if((container!=null) && container.toString().equals("true")) cont = true;
		if((defaultMaxCard!=null) && defaultMaxCard.toString().equals("\"1\"")) defaultMaxCardinality = true;
		// <<< null checks by SK
		//userFields axioms
		JsonObject custom_render_spec = jsonObj.getAsJsonObject("custom_render_spec");
		JsonPrimitive axioms = custom_render_spec.getAsJsonPrimitive("axioms");
		JsonPrimitive prefixes = custom_render_spec.getAsJsonPrimitive("prefixes");
		String[] prefixesArrayT = prefixes.getAsString().split("\n");
		ArrayList<String> prefixesArray = new ArrayList<String>();
		for (String s : prefixesArrayT){
			prefixesArray.add(s);
		}
		prefixesArray.add("Prefix(owl:=<http://www.w3.org/2002/07/owl#>)");

		OWLOntologyManager manager = OWLManager.createOWLOntologyManager();
		//Imports should not be considered
		OWLOntologyLoaderConfiguration config = new OWLOntologyLoaderConfiguration();
		config = config.setMissingImportHandlingStrategy(MissingImportHandlingStrategy.SILENT);
		String userFieldsAxioms = "Ontology(<http://lumii.lv/ontologies/UserFields.owl>\n" + axioms.getAsString() +")";
		
		InputStream in = new ByteArrayInputStream( userFieldsAxioms.getBytes() );
		OWLOntology ontologyUserFieldsAxioms = manager.loadOntologyFromOntologyDocument(in);
		
		ontologyUserFieldsAxioms.getAxioms();
		
		ArrayList<UserFieldsParameter> userFieldsParameters = new ArrayList<UserFieldsParameter>();
		
		for (OWLAxiom axiom : ontologyUserFieldsAxioms.getAxioms()){
			if (axiom.getAxiomType().toString().equals("AnnotationAssertion")){
				OWLAnnotationAssertionAxiom aa = (OWLAnnotationAssertionAxiom) axiom;
				int delimeter = aa.getSubject().toString().indexOf("#");
				String name = aa.getSubject().toString().substring(delimeter+1);
				String namespace = aa.getSubject().toString().substring(0, delimeter-1);
				
				String requireValue = null;
				String createValue = null;
				
				for (OWLAnnotation annot : axiom.getAnnotations()){
					String annotationPropety = annot.getProperty().getIRI().getShortForm();
					if(annotationPropety.equals("ShowAnnotation_CreateValue")) createValue = annot.getValue().toString().substring(1, annot.getValue().toString().length()-1);
					if(annotationPropety.equals("ShowAnnotation_RequireValue")) requireValue = annot.getValue().toString().substring(1, annot.getValue().toString().length()-1);
				}
				userFieldsParameters.add(new UserFieldsParameter(aa.getProperty().getIRI().getShortForm().toString(),  name,  namespace, aa.getValue().toString().substring(1, aa.getValue().toString().length()-1), requireValue, createValue));
			}
		}
        
		String ontologyPath = jsonObj.getAsJsonPrimitive("ontology_path").toString().replace("\"", "").replace("\n\n", "\n");
        
        OWLOntologyDocumentSource source = new StreamDocumentSource(new FileInputStream(ontologyPath));
        try{
        OWLOntology componentontology = manager.loadOntologyFromOntologyDocument(source, config);
        manager.getOntologyLoaderConfiguration();
        //a.getPrefixName2PrefixMap();
       
        OWLDocumentFormat format = manager.getOntologyFormat(componentontology);
        Map<String, String> prefixesMap = format.asPrefixOWLOntologyFormat().getPrefixName2PrefixMap();
     
        boolean needToPutNS = false;
       Map<String, String> pm = new HashMap<String, String>();
       for (Map.Entry<String, String> entry : prefixesMap.entrySet())
	   {
		   pm.put(entry.getKey(), entry.getValue());
	   }
       for(Iterator<Map.Entry<String, String>> it = pm.entrySet().iterator(); it.hasNext(); ) {
    	      Map.Entry<String, String> entry = it.next();
    	      if(componentontology.getOntologyID().getOntologyIRI().isPresent()){
    	      if(entry.getValue().equals(componentontology.getOntologyID().getOntologyIRI().get().toString())) {
    	    	  needToPutNS = true;
    	    	  it.remove();
    	    	// pm.put("ffffff:", entry.getValue()+5);
    	      }}
    	    }
       if(needToPutNS == true) pm.put(":", componentontology.getOntologyID().getOntologyIRI().get().toString());
        ArrayList<Ontology> ontologies = new ArrayList<Ontology>();
        Set<OWLAxiom> set = new HashSet<OWLAxiom>();
        JsonArray signature = jsonObj.getAsJsonArray("signature");
        if(signature != null){

	        Set<OWLEntity> entities = new HashSet<OWLEntity>();
	        //cauri visam klasem
	        for(OWLClass cl: componentontology.getClassesInSignature()){
	        	
	        	//ja klase ir jaatlasa modulii
	        	if(signature.getAsString().contains(cl.getIRI().getShortForm())){
	        		entities.add(cl);
	        		//tiesas objectPropertijas
	        		objectPropertiesForModule(componentontology, entities, set, cl, "PropertyRangeAssertionsForModuleClasses", "RangeClassesForObjectPropertiesAtModuleClasses", preferences);

	        		//virsklases
					superClassesForModule(componentontology, entities, set, cl, preferences, "moduleClass");
					
					//apaksklases
					subClassesForModule(componentontology, entities, set, cl, preferences, "moduleClass");

	        	}
	        }
			
			//klases atributi
			for(OWLDataProperty dp : componentontology.getDataPropertiesInSignature()){
				for (OWLDataPropertyDomainAxiom dpda: componentontology.getDataPropertyDomainAxioms(dp)){
					if(dpda.getDomain().getClassExpressionType().toString().equals("Class") && entities.contains(dpda.getDomain())) {
						entities.add(dp);
					}
				}
			}

			//individi
			for(OWLNamedIndividual indivudual: componentontology.getIndividualsInSignature()){
				for (OWLClassAssertionAxiom caa: componentontology.getClassAssertionAxioms(indivudual)){
					if(entities.contains(caa.getClassExpression())) {
						entities.add(indivudual);
					}
				}
	        }
			
			ArrayList<String> axiomTypes = new ArrayList<String>();
					axiomTypes.add("Declaration");
					axiomTypes.add("DataPropertyRange");
					axiomTypes.add("EquivalentDataProperties");
					axiomTypes.add("SubDataPropertyOf");
					axiomTypes.add("DisjointDataProperties");
					axiomTypes.add("HasKey");
					axiomTypes.add("ClassAssertion");
					axiomTypes.add("EquivalentObjectProperties");
					axiomTypes.add("SubObjectPropertyOf");
					axiomTypes.add("FunctionalObjectProperty");
					axiomTypes.add("InverseFunctionalObjectProperty");
					axiomTypes.add("SymmetricObjectProperty");
					axiomTypes.add("AsymmetricObjectProperty");
					axiomTypes.add("TransitiveObjectProperty");
					axiomTypes.add("ReflexiveObjectProperty");
					axiomTypes.add("IrrefexiveObjectProperty");
					axiomTypes.add("DisjointObjectProperties");
					axiomTypes.add("SubPropertyChainOf");
					axiomTypes.add("DataPropertyAssertion");
					axiomTypes.add("NegativeDataPropertyAssertion");
					axiomTypes.add("NegativeObjectPropertyAssertion");
					axiomTypes.add("FunctionalDataProperty");
					
			OWLDataFactory df = manager.getOWLDataFactory();

			for(OWLAxiom axiom : componentontology.getAxioms()){
				if(axiomTypes.contains(axiom.getAxiomType().toString())){
					for(OWLEntity en : entities){
						if(axiom.containsEntityInSignature(en)) {
							set.add(axiom);
						}
					}
				} else if(axiom.getAxiomType().toString().equals("AnnotationAssertion")) {
					OWLAnnotationAssertionAxiom aa = (OWLAnnotationAssertionAxiom) axiom;
					if( entities.toString().contains(aa.getSubject().toString())) {
						set.add(axiom);
					}
	        	} else if(axiom.getAxiomType().toString().equals("DataPropertyDomain")) {
					OWLDataPropertyDomainAxiom domain = (OWLDataPropertyDomainAxiom)axiom;
					
					if(domain.getDomain().getClassesInSignature().size() == 1 && entities.containsAll(domain.getDomain().getClassesInSignature())){
						set.add(axiom);
					}
	        	} else if(axiom.getAxiomType().toString().equals("DisjointClasses")) {
	        		OWLDisjointClassesAxiom dis = (OWLDisjointClassesAxiom) axiom;
	        		Set<OWLClassExpression> disSet = new HashSet<OWLClassExpression>();
	        		for(OWLClassExpression d : dis.getClassExpressions()){
	        			if(d.getClassExpressionType().toString().equals("Class") && entities.contains((OWLClass) d)){
	        				disSet.add(d);
	        			}
	        			if (disSet.size()>1){
	        				OWLDisjointClassesAxiom dca = df.getOWLDisjointClassesAxiom(disSet);
	        				set.add(dca);
	        			}
	        		}
	        	} else if(axiom.getAxiomType().toString().equals("EquivalentClasses")) {
	        		OWLEquivalentClassesAxiom dis = (OWLEquivalentClassesAxiom) axiom;
	        		Set<OWLClassExpression> disSet = new HashSet<OWLClassExpression>();
	        		for(OWLClassExpression d : dis.getClassExpressions()){
	        			if(d.getClassExpressionType().toString().equals("Class") && entities.contains((OWLClass) d)){
	        				disSet.add(d);
	        			}
	        			if(d.getClassExpressionType().toString().equals("ObjectComplementOf")) set.add(dis);
	        		}
	        		if (disSet.size()>1){
        				OWLEquivalentClassesAxiom dca = df.getOWLEquivalentClassesAxiom(disSet);
        				set.add(dca);
        			}
	        	} else if(axiom.getAxiomType().toString().equals("SameIndividual")) {
	        		 OWLSameIndividualAxiom dis = (OWLSameIndividualAxiom) axiom;
		        		Set<OWLNamedIndividual> disSet = new HashSet<OWLNamedIndividual>();
		        		for(OWLNamedIndividual d : dis.getIndividualsInSignature()){
		        			if(entities.contains((OWLNamedIndividual) d)){
		        				disSet.add(d);
		        			}
		        			if (disSet.size()>1){
		        				OWLSameIndividualAxiom dca = df.getOWLSameIndividualAxiom(disSet);
		        				set.add(dca);
		        			}
		        		}
		        } else if(axiom.getAxiomType().toString().equals("DifferentIndividuals")) {
	        		 OWLDifferentIndividualsAxiom dis = (OWLDifferentIndividualsAxiom) axiom;
		        		Set<OWLNamedIndividual> disSet = new HashSet<OWLNamedIndividual>();
		        		for(OWLNamedIndividual d : dis.getIndividualsInSignature()){
		        			if(entities.contains((OWLNamedIndividual) d)){
		        				disSet.add(d);
		        			}
		        			if (disSet.size()>1){
		        				OWLDifferentIndividualsAxiom dca = df.getOWLDifferentIndividualsAxiom(disSet);
		        				set.add(dca);
		        			}
		        		}
		        } else if(axiom.getAxiomType().toString().equals("SubClassOf")){
		        	ArrayList<String> subClassOfAxiomTypes = new ArrayList<String>();
		        	subClassOfAxiomTypes.add("ObjectMinCardinality");
		        	subClassOfAxiomTypes.add("ObjectMaxCardinality");
		        	subClassOfAxiomTypes.add("ObjectExactCardinality");
		        	subClassOfAxiomTypes.add("DataMinCardinality");
		        	subClassOfAxiomTypes.add("DataMaxCardinality");
		        	subClassOfAxiomTypes.add("DataExactCardinality");
					
		        	OWLSubClassOfAxiom subClass = (OWLSubClassOfAxiom) axiom;
		        	if(subClassOfAxiomTypes.contains(subClass.getSuperClass().getClassExpressionType().toString())){
		        		OWLCardinalityRestriction c = (OWLCardinalityRestriction)subClass.getSuperClass();
		        		for(OWLObjectProperty pr :c.getProperty().getObjectPropertiesInSignature()){
		        		if(entities.contains(pr)) set.add(axiom);}
		        	}
		        } else if(axiom.getAxiomType().toString().equals("InverseObjectProperties")){
		        	OWLInverseObjectPropertiesAxiom inv = (OWLInverseObjectPropertiesAxiom) axiom;
		        	if(entities.contains(inv.getFirstProperty()) && entities.contains(inv.getSecondProperty())) set.add(axiom);
		        } else if(axiom.getAxiomType().toString().equals("ObjectPropertyAssertion")){
		        	OWLObjectPropertyAssertionAxiom opa = (OWLObjectPropertyAssertionAxiom) axiom;
		        	if(entities.contains(opa.getObject()) && entities.contains(opa.getSubject())) set.add(axiom);
		        }
			}
	       
	       IRI iri = componentontology.getOntologyID().getOntologyIRI().get();
	       manager.removeOntology(componentontology);
	       componentontology = manager.createOntology(iri);
	       manager.addAxioms(componentontology, set);
	      // manager.removeAxioms(componentontology, set);
	      /* 
	        SyntacticLocalityModuleExtractor aa = new SyntacticLocalityModuleExtractor(manager, componentontology, ModuleType.TOP);
	        manager.removeOntology(componentontology);
	        componentontology = aa.extractAsOntology(moduleSignature, iri);*/
        }
        
        for(OWLOntology ont : componentontology.getImportsClosure()){
        	unexported = new ArrayList<String>();
        	if(!ont.getOntologyID().isAnonymous()) prefixesArray.add("Prefix("+ont.getOntologyID().getOntologyIRI().get().getShortForm().toString()+":=<"+ont.getOntologyID().getOntologyIRI().get()+"#>)");
        	String[] array = prefixesArray.toArray(new String[prefixesArray.size()]);
        	ontologies.add(importOntology(m, preferences, userFieldsParameters, ont, array, pm, ontologies));
        }
        
        SerializeToJSON json1 = new SerializeToJSON(preferences);
        String ontoName = "";
        if(!componentontology.getOntologyID().isAnonymous())ontoName = componentontology.getOntologyID().getOntologyIRI().get().toString();
        else {
        	for (Map.Entry<String, String> entry : prefixesMap.entrySet())
			{
			    if(entry.getKey().equals(":")){
			    	ontoName = entry.getValue();
			    	break;
			    }
			}
        	if(ontoName.endsWith("#")){
        		ontoName = ontoName.substring(0, ontoName.length()-1);
        	}
        }
        String jsonStructure = json1.serializeToJSON(ontologies, ontoName).toString();
        String findStr = "]";
        int lastIndex = 0;

        while(lastIndex != -1){

            lastIndex = jsonStructure.indexOf(findStr,lastIndex);

            if(lastIndex != -1){
                lastIndex += findStr.length();
            }
        }
        
        jsonStructure = jsonStructure.replaceAll("\"([A-Za-z0-9_-]*)\":\\[\\]", "\"$1\":{}");
        jsonStructure = jsonStructure.replaceAll("\"([A-Za-z0-9_-]*)\":\\[", "\"$1\":{");
        jsonStructure = jsonStructure.replaceAll("\\}\\]\\}", "\\}\\}\\}");
        jsonStructure = jsonStructure.replaceAll("\\}\\],", "\\}\\},");
        jsonStructure = jsonStructure.replaceAll("\\]\\}\\},", "\\}\\}\\},");
        jsonStructure = jsonStructure.replaceAll("\"([A-Za-z0-9_-]*)\":", "[\"$1\"]=");
       // System.out.println(jsonStructure);
        return jsonStructure; 
        } catch (OWLOntologyCreationException o) {
        	JOptionPane.showMessageDialog(null,  o.getMessage(), "Ontology load error", JOptionPane.INFORMATION_MESSAGE);
        }
		return null;
	} 
	
	public static Ontology importOntology(ManchesterOWLSyntaxOWLObjectRendererImpl  m, JsonObject preferences,
			ArrayList<UserFieldsParameter> userFieldsParameters, OWLOntology componentontology, String[] prefixesArray, 
			Map<String, String> prefixesMap, ArrayList<Ontology> ontologies) throws OWLOntologyCreationException {

		Set <OWLClass> classes = componentontology.getClassesInSignature();
        String ontologyNameShort = "";
        String ontologyName = "";
        if (!componentontology.getOntologyID().isAnonymous()){
        	ontologyNameShort = componentontology.getOntologyID().getOntologyIRI().get().getShortForm().toString();
        	if(ontologyNameShort.startsWith("<http:")) ontologyNameShort = "";
        	ontologyName = componentontology.getOntologyID().getOntologyIRI().get().toString();
        	if(ontologyNameShort.endsWith("#")) {
        		if(ontologyName.substring(0, ontologyName.length()-1).lastIndexOf("#") != -1) ontologyNameShort = ontologyName.substring(ontologyName.substring(0, ontologyName.length()-1).lastIndexOf("#")+1, ontologyName.length()-1);
        		else ontologyNameShort = "";
        	};
        	if(ontologyNameShort.endsWith("/")) {
        		if(ontologyName.substring(0, ontologyName.length()-1).lastIndexOf("/") != -1) ontologyNameShort = ontologyName.substring(ontologyName.substring(0, ontologyName.length()-1).lastIndexOf("/")+1, ontologyName.length()-1);
        		else ontologyNameShort = "";
        	};
        	if(ontologyNameShort.endsWith(".owl")){
        		ontologyNameShort = ontologyNameShort.substring(0, ontologyNameShort.length()-4);
        	}
        	
        } else {
        	for (Map.Entry<String, String> entry : prefixesMap.entrySet())
			{
			    if(entry.getKey().equals(":")){
			    	ontologyName = entry.getValue();
			    	break;
			    }
			}
        	if(ontologyName.endsWith("#")){
        		ontologyName = ontologyName.substring(0, ontologyName.length()-1);
        	}
        }
        Ontology ontology = new Ontology(ontologyNameShort, ontologyName, 
        		String.valueOf(componentontology.getAxiomCount()), String.valueOf(componentontology.getLogicalAxiomCount()));
        
  
        ArrayList<String> imports = new ArrayList<String>();
        for(OWLImportsDeclaration ont : componentontology.getImportsDeclarations()){
        	String ontoName = ont.getIRI().getShortForm().toString();
        	if(ontoName.endsWith(".owl")){
        		ontoName = ontoName.substring(0, ontoName.length()-4);
        	}
        	imports.add(ontoName);
        }
        ontology.setImports(imports);
        
        ArrayList<Box> boxes = new ArrayList<Box>();
        ArrayList<Line> lines = new ArrayList<Line>();
        
        
       
        //box.setContainer(container);
        /*if (getPreferenceParameterProcName("useContainersForSingleNodes", preferences).equals("")) {
      	    if (getPreferenceParameterValue("useContainersForSingleNodes", preferences).equals("true")){
      	    	 Box container = getContainer("Container_for_single_nodes", boxes, boxes);
      	    	// boxes.add(container);
      	    }
      	} else {
      		//TODO
      	}*/
        
        
        Set <OWLDataProperty> dataProperties = componentontology.getDataPropertiesInSignature();
        
        //DataTypes
      	if (getPreferenceParameterProcName("showDataTypes", preferences).equals("")) {
      	    if (getPreferenceParameterValue("showDataTypes", preferences).equals("true")){
      	    	createOntologyDataTypes(componentontology, boxes, false, preferences, prefixesArray, prefixesMap, ontologies);
      	    }
      	} else {
      		createOntologyDataTypes(componentontology, boxes, true, preferences, prefixesArray, prefixesMap, ontologies);
      	}

        //Classes
        if (getPreferenceParameterProcName("showClasses", preferences).equals("")) {
        	if (getPreferenceParameterValue("showClasses", preferences).equals("true")) {
		        for (OWLClass co : classes) {
		        	createClass(co, boxes, dataProperties, componentontology, preferences, prefixesArray, prefixesMap);
		        }
        	}
        } else {
        	for (OWLClass co : classes) {
	        	if (calculateParameterProcedure("showClasses", preferences).equals("true")) createClass(co, boxes, dataProperties, componentontology, preferences, prefixesArray, prefixesMap);
	        }
        }
        
       //Anonymous Classes from sub Classes
        if (getPreferenceParameterProcName("showClasses", preferences).equals("")) {
        	if (getPreferenceParameterValue("showClasses", preferences).equals("true")) {
		        for (OWLClass co : classes) {
		        	createAnonymousClasses(co, boxes, componentontology, preferences, lines);
		        }
        	}
        } else {
        	for (OWLClass co : classes) {
	        	if (calculateParameterProcedure("showClasses", preferences).equals("true")) createAnonymousClasses(co, boxes, componentontology, preferences, lines);
	        }
        }
        
       //domain and range for object properties if show Graphically
       if (getPreferenceParameterProcName("showObjectProperties", preferences).equals("")){
	        if (getPreferenceParameterValue("showObjectProperties", preferences).equals("true") && getPreferenceParameterValue("showObjectPropertiesType", preferences).equals("Graphically")) {
		        for (OWLObjectProperty op: componentontology.getObjectPropertiesInSignature()) {
		        	createAnonymousClassFromObjectPropertyDomainAndRange(componentontology, op, boxes,lines, preferences);
		    	}
			}
        } else {
		     for (OWLObjectProperty op: componentontology.getObjectPropertiesInSignature()) {
	        	if (calculateParameterProcedure("showObjectProperties", preferences).equals("true")) {
	        		createAnonymousClassFromObjectPropertyDomainAndRange(componentontology, op, boxes, lines, preferences);
	        	}
	        }
        }

       //domain for data properties if show
       if (getPreferenceParameterProcName("showDataProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showDataProperties", preferences).equals("true")) {
				for (OWLDataProperty dp: dataProperties){
			       	String domainName = "";
			       	ArrayList<String> domains = new ArrayList<String>();
					for (OWLDataPropertyDomainAxiom dpda: componentontology.getDataPropertyDomainAxioms(dp)){
						domains.add(m.render(dpda.getDomain()).replace("\n", "\\n"));
						if (domainName == "") domainName = m.render(dpda.getDomain()).replace("\n", "\\n");
			       		else domainName = domainName + " and " + m.render(dpda.getDomain()).replace("\n", "\\n");
			       	}
					if(!domainName.equals("")) {
						Class newClass = createAnonymousClass(boxes, domainName, domains);
						
						if (getPreferenceParameterProcName("showSubclassesToUnionOfNamed", preferences).equals("")) {
				    		if (getPreferenceParameterValue("showSubclassesToUnionOfNamed", preferences).equals("true")){
				    			createObjectUnionOfGeneralizationFromDomainDataProperty(componentontology, dp,  boxes, lines, newClass);
				    		}
				    	} else if (calculateParameterProcedure("showSubclassesToUnionOfNamed", preferences).equals("true")) {
				    		createObjectUnionOfGeneralizationFromDomainDataProperty(componentontology, dp,  boxes, lines, newClass);
				    	}  
						if (getPreferenceParameterProcName("showSubclassesFromAndNamed", preferences).equals("")) {
				    		if (getPreferenceParameterValue("showSubclassesFromAndNamed", preferences).equals("true")){
				    			createObjectIntersectionOfGeneralizationFromDomainDataProperty(componentontology, dp,  boxes, lines, newClass);
				    		}
				    	} else if (calculateParameterProcedure("showSubclassesFromAndNamed", preferences).equals("true")) {
				    		createObjectIntersectionOfGeneralizationFromDomainDataProperty(componentontology, dp,  boxes, lines, newClass);
				    	}  
					} else {
						unexported.add(componentontology.getDataPropertyDomainAxioms(dp).toString());
					}
		        }
			}
		} else {
			for (OWLDataProperty dp : dataProperties) {
				if (calculateParameterProcedure("showDataProperties", preferences).equals("true")) {
					String domainName = "";
					for (OWLDataPropertyDomainAxiom dpda: componentontology.getDataPropertyDomainAxioms(dp)){
			       		if (domainName == "") domainName = m.render(dpda.getDomain()).replace("\n", "\\n");
			       		else domainName = domainName + "and " + m.render(dpda.getDomain()).replace("\n", "\\n");
			       	}
					createAnonymousClass(boxes, domainName);
				}
	    	}		
		}
        
        //Anonymous classes
       for (OWLAxiom ax : componentontology.getAxioms()){
			if(ax.getAxiomType().toString().equals("SubClassOf")){
				OWLSubClassOfAxiom subClass = (OWLSubClassOfAxiom) ax;
				Class newClass = createAnonymousClass(boxes, m.render(subClass.getSubClass()));
				if (newClass!=null){
					ArrayList<Compartment> compartments = newClass.getCompartments();
					ArrayList<Compartment> superClasses = new ArrayList<Compartment>();
					Compartment ASFictitiousClasses = createCompartment("ASFictitiousSuperClasses", "");
					ASFictitiousClasses.setIsMultiline(true);
					ASFictitiousClasses.setSubCompartments(superClasses);
					compartments.add(ASFictitiousClasses);
					String expression = m.render(subClass.getSuperClass()).replace("\n", "\\n");
					Compartment newSuperClass = new Compartment("SuperClasses", "");
					Compartment newExpression = new Compartment("Expression", expression);
					newSuperClass.setSubCompartment(newExpression);
					superClasses.add(newSuperClass);
					
					if (getPreferenceParameterProcName("showSubclassesToUnionOfNamed", preferences).equals("")) {
			    		if (getPreferenceParameterValue("showSubclassesToUnionOfNamed", preferences).equals("true")){
			    			createObjectUnionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClass.getSubClass(),  boxes, lines, newClass);
			    		}
			    	} else if (calculateParameterProcedure("showSubclassesToUnionOfNamed", preferences).equals("true")) {
			    		createObjectUnionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClass.getSubClass(),  boxes, lines, newClass);
			    	} 
					if (getPreferenceParameterProcName("showSubclassesFromAndNamed", preferences).equals("")) {
			    		if (getPreferenceParameterValue("showSubclassesFromAndNamed", preferences).equals("true")){
			    			createObjectIntersectionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClass.getSubClass(),  boxes, lines, newClass);
			    		}
			    	} else if (calculateParameterProcedure("showSubclassesFromAndNamed", preferences).equals("true")) {
			    		createObjectIntersectionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClass.getSubClass(),  boxes, lines, newClass);
			    	}  
				}
	       	}
	    }
       
       //for individual class assertions
       if (getPreferenceParameterProcName("showIndividualClassAssertionsCreateClassBox", preferences).equals("")) {
       	if (getPreferenceParameterValue("showIndividualClassAssertionsCreateClassBox", preferences).equals("Yes")) {
       		for(OWLNamedIndividual indivudual: componentontology.getIndividualsInSignature()){
     	       for (OWLClassAssertionAxiom caa: componentontology.getClassAssertionAxioms(indivudual)){
     	    	   createAnonymousClass(boxes, m.render(caa.getClassExpression()));
     			}
            }
       	}else if(getPreferenceParameterValue("showSubclassesCreateTarget", preferences).equals("Create if multiple use") && 
				getPreferenceParameterValue("showClassExprsAsBoxByCountEnable", preferences).equals("true")){
       		for(OWLNamedIndividual indivudual: componentontology.getIndividualsInSignature()){
      	       for (OWLClassAssertionAxiom caa: componentontology.getClassAssertionAxioms(indivudual)){
      	    	 if(Integer.parseInt(getPreferenceParameterValue("showClassExprsAsBoxCount", preferences)) <= countReferencesTimes(caa.getClassExpression().getClassesInSignature(), componentontology, caa.getClassExpression().toString()))createAnonymousClass(boxes, m.render(caa.getClassExpression()));
      		   }
           }
       	}
       } else {
    	   for(OWLNamedIndividual indivudual: componentontology.getIndividualsInSignature()){
     	       for (OWLClassAssertionAxiom caa: componentontology.getClassAssertionAxioms(indivudual)){
     	    	  if (calculateParameterProcedure("showIndividualClassAssertionsCreateClassBox", preferences).equals("Yes"))  {
     	    		 if(Integer.parseInt(getPreferenceParameterValue("showClassExprsAsBoxCount", preferences)) <= countReferencesTimes(caa.getClassExpression().getClassesInSignature(), componentontology, caa.getClassExpression().toString()))createAnonymousClass(boxes, m.render(caa.getClassExpression()));
     		        }
     			}
            } 
       }

        //Thing
        if (getPreferenceParameterProcName("showSubclassesTopNamedToThing", preferences).equals("")) {
        	if (getPreferenceParameterValue("showSubclassesTopNamedToThing", preferences).equals("true")) {
		       createThingClass(boxes, lines, componentontology);
        	}
        } else {
	        if (calculateParameterProcedure("showSubclassesTopNamedToThing", preferences).equals("true"))  createThingClass(boxes, lines, componentontology);
        }
        
      //Associations
        if (getPreferenceParameterProcName("showObjectProperties", preferences).equals("")){
	        if (getPreferenceParameterValue("showObjectProperties", preferences).equals("true") && getPreferenceParameterValue("showObjectPropertiesType", preferences).equals("Graphically")) {
		        Set <OWLObjectProperty> objectProperties = componentontology.getObjectPropertiesInSignature();
		        for (OWLObjectProperty op: objectProperties) {
		        	createAssociation(lines, componentontology, boxes, op, preferences, userFieldsParameters, prefixesArray, prefixesMap);
		    	}
			}
        } else {
        	 Set <OWLObjectProperty> objectProperties = componentontology.getObjectPropertiesInSignature();
		     for (OWLObjectProperty op: objectProperties) {
	        	if (calculateParameterProcedure("showObjectProperties", preferences).equals("true")) createAssociation(lines, componentontology, boxes, op, preferences, userFieldsParameters, prefixesArray, prefixesMap);
	        }
        }

		ontology.setBoxes(boxes);
		ontology.setLines(lines);
        
		ArrayList<Box> needToBeAddedToBoxes = new ArrayList<Box>();

		//for(Box box: boxes){
		for (Iterator<Box> iterbox = boxes.listIterator(); iterbox.hasNext(); ){
			Box box = iterbox.next();
			if(box.getType().equals("Class")){
				
				createClassAttributes(dataProperties, (Class) box, componentontology, box.getCompartments(), preferences, lines, needToBeAddedToBoxes, userFieldsParameters, prefixesArray, prefixesMap, boxes);
				
				//subClasses
				if (getPreferenceParameterProcName("showSubclasses", preferences).equals("")) {
	        		if (getPreferenceParameterValue("showSubclasses", preferences).equals("true")){
		        		if (getPreferenceParameterValue("showSubclassesType", preferences).equals("As text")) createSuperClassesAsText((Class) box, componentontology, box.getCompartments(), false, preferences);
		        		else if (getPreferenceParameterValue("showSubclassesType", preferences).equals("Graphically")) createSuperClassGeneralizations((Class) box, boxes, lines, componentontology, false, preferences);
	        		}
	        	} else {
	        		createSuperClassesAsText((Class) box, componentontology, box.getCompartments(), true, preferences);
	        		createSuperClassGeneralizations((Class) box, boxes, lines, componentontology, true, preferences);
	        	}
				
				//equivalentCLasses
				if (getPreferenceParameterProcName("showEquivalentClasses", preferences).equals("")) {
					if (getPreferenceParameterValue("showEquivalentClasses", preferences).equals("true")) {
		        		if (getPreferenceParameterValue("showEquivalentClassesType", preferences).equals("As text")) createEquivalentClassesAsText((Class) box, componentontology, box.getCompartments(), false, null);
		        		else if (getPreferenceParameterValue("showEquivalentClassesType", preferences).equals("Graphically")) createEquivalentClassesGraphically((Class) box, boxes, lines, componentontology, false, preferences, prefixesArray, prefixesMap);
		        	}
				} else {
					createEquivalentClassesAsText((Class) box, componentontology, box.getCompartments(), true, preferences);
	        		createEquivalentClassesGraphically((Class) box, boxes, lines, componentontology, true, preferences, prefixesArray, prefixesMap);
				}
				
				//disjointCLasses
				if (getPreferenceParameterProcName("showDisjointClasses", preferences).equals("")){
		        	if (getPreferenceParameterValue("showDisjointClasses", preferences).equals("true")) {
		        		if (getPreferenceParameterValue("showDisjointClassesType", preferences).equals("As text")) createDisjointClassesAsText((Class) box, componentontology, box.getCompartments(), false, null);
		        		else if (getPreferenceParameterValue("showDisjointClassesType", preferences).equals("Graphically")) createDisjointClassesGraphically((Class) box, boxes, lines, componentontology, false, preferences, prefixesArray, prefixesMap);
		        	}
				} else {
					createDisjointClassesAsText((Class) box, componentontology, box.getCompartments(), true, preferences);
					createDisjointClassesGraphically((Class) box, boxes, lines, componentontology, true, preferences, prefixesArray,  prefixesMap);
				}
				
	        	//container
	        	Class c = (Class) box;
	        	OWLClass co = c.getOwlClass();
	        	if(co != null) {
	        		Boolean removeFromBoxes = createContainerFromAnnotationAxiom(componentontology.getAnnotationAssertionAxioms(co.getIRI()),  componentontology, boxes, needToBeAddedToBoxes, box, ontologies, iterbox);
	        		if(removeFromBoxes == true)iterbox.remove();
	        	}
	        	
	        	//class Annotations
	        	if (getPreferenceParameterProcName("showClassAnnotations", preferences).equals("")){
					if (getPreferenceParameterValue("showClassAnnotations", preferences).equals("true")) {
		        		if (getPreferenceParameterValue("showClassAnnotationsType", preferences).equals("As text")) createClassAnnotationsAsText((Class) box, componentontology, box.getCompartments(), false, preferences, userFieldsParameters, prefixesArray, prefixesMap);
		        		else if (getPreferenceParameterValue("showClassAnnotationsType", preferences).equals("Graphically")) createClassAnnotationsGraphically((Class) box, componentontology, needToBeAddedToBoxes, lines, false, preferences, userFieldsParameters, prefixesArray, prefixesMap);
		        	}
	        	} else {
	        		createClassAnnotationsAsText((Class) box, componentontology, box.getCompartments(), true, preferences, userFieldsParameters, prefixesArray, prefixesMap);
	        		createClassAnnotationsGraphically((Class) box, componentontology, needToBeAddedToBoxes, lines, true, preferences, userFieldsParameters, prefixesArray, prefixesMap);
				}
			}
		}

		
		//Generalizations to Thing
        if (getPreferenceParameterProcName("showSubclassesTopNamedToThing", preferences).equals("")) {
        	if (getPreferenceParameterValue("showSubclassesTopNamedToThing", preferences).equals("true")) {
		       createThingGeneralizations(boxes, lines, componentontology);
        	}
        } else {
	        if (calculateParameterProcedure("showSubclassesTopNamedToThing", preferences).equals("true"))  createThingGeneralizations(boxes, lines, componentontology);;
        }
		
		//Object property restrictions
	    if (getPreferenceParameterProcName("showPropertyRestrictionsGraphically", preferences).equals("")){
				if (getPreferenceParameterValue("showPropertyRestrictionsGraphically", preferences).equals("true")) {
					for (OWLClass classAxiom : componentontology.getClassesInSignature()) {
						for (OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSubClass(classAxiom)) {
							Boolean createSuperClass = true;
							if(subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectAllValuesFrom") && avf == true){
								OWLObjectAllValuesFrom davf = (OWLObjectAllValuesFrom) subClassAxiom.getSuperClass();
								for(OWLAnnotationAssertionAxiom aa: componentontology.getAnnotationAssertionAxioms(davf.getProperty().asOWLObjectProperty().getIRI())){
									if(aa.getProperty().getIRI().getShortForm().toString().equals("schema") && aa.getSubject().toString().equals(davf.getProperty().asOWLObjectProperty().getIRI().toString())){
										createSuperClass = false;
									}
								}
							}
							if(createSuperClass)createRestriction(subClassAxiom, componentontology, lines, preferences, boxes, prefixesArray, prefixesMap);
				       	}
			       	}
				}
		} else {
					
	    }
		
		if (getPreferenceParameterProcName("showObjectPropertiesMergeInverse", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectProperties", preferences).equals("true") && getPreferenceParameterValue("showObjectPropertiesType", preferences).equals("Graphically") && getPreferenceParameterValue("showObjectPropertiesMergeInverse", preferences).equals("true")){
				for (Line line : lines) {
				    if(line.getType().equals("Association")){
						mergeInverseAssociation(line, lines, componentontology);
					}
				}
				removeInverseAssociations(lines);
			}
		} else {
			//TODO: merge inverse from procName value
		}

		//Individuals
		if (getPreferenceParameterProcName("showIndividuals", preferences).equals("")){
			if (getPreferenceParameterValue("showIndividuals", preferences).equals("true")) {
				for (OWLNamedIndividual indivudual: componentontology.getIndividualsInSignature()){
		        	Individual newIndividual = createIndividual(indivudual, boxes, preferences, componentontology, prefixesArray, prefixesMap);
		        	//container
		        	Boolean removeFromBoxes = createContainerFromAnnotationAxiom(componentontology.getAnnotationAssertionAxioms(indivudual.getIRI()),  componentontology, boxes, needToBeAddedToBoxes, (Box) newIndividual, ontologies, null);
		        	if(removeFromBoxes == true) boxes.remove(newIndividual);
				}
        	}
    	} else {
    		for (OWLNamedIndividual indivudual: componentontology.getIndividualsInSignature()) {
	        	if (calculateParameterProcedure("showIndividuals", preferences).equals("true")) createIndividual(indivudual, boxes, preferences, componentontology, prefixesArray,  prefixesMap);
	        }
		}
		
		boxes.addAll(needToBeAddedToBoxes);
		needToBeAddedToBoxes = new ArrayList<Box>();
		
		//For individuals
		//for all boxes from all ontologies

		//for(Ontology onto : ontologies){		
			
			//for(Box box: onto.getBoxes()){
			for(Box box: boxes){
				if(box.getType().equals("Object")){
					//IndividualClassAssertions
					if (getPreferenceParameterProcName("showIndividualClassAssertions", preferences).equals("")) {
		        		if (getPreferenceParameterValue("showIndividualClassAssertions", preferences).equals("true")){
			        		if (getPreferenceParameterValue("showClassAssertionsType", preferences).equals("As text") || (getPreferenceParameterValue("showClassAssertionsType", preferences).equals("Graphically") && getPreferenceParameterValue("showClassAssertionsGraphicsKeepText", preferences).equals("true"))) createIndividualClassAssertionsAsText((Individual) box, componentontology, box.getCompartments(), false, null);
			        		if (getPreferenceParameterValue("showClassAssertionsType", preferences).equals("Graphically")) createIndividualClassAssertionsGraphically((Individual) box, boxes, lines, componentontology, false, null);
		        		}
		        	} else {
		        		createIndividualClassAssertionsAsText((Individual) box, componentontology, box.getCompartments(), true, preferences);
		        		createIndividualClassAssertionsGraphically((Individual) box, boxes, lines, componentontology, true, preferences);
		        	}
					//Same individual
					if (getPreferenceParameterProcName("showSameIndividuals", preferences).equals("")) {
		        		if (getPreferenceParameterValue("showSameIndividuals", preferences).equals("true")){
			        		if (getPreferenceParameterValue("showSameIndividualsType", preferences).equals("As text")) createSameIndividualsAsText((Individual) box, componentontology, box.getCompartments(), false, preferences, prefixesArray, prefixesMap);
			        		else if (getPreferenceParameterValue("showSameIndividualsType", preferences).equals("Graphically")) createSameIndividualsGraphically((Individual) box, boxes, lines, componentontology, false, preferences, prefixesArray, prefixesMap);
		        		}
		        	} else {
		        		createSameIndividualsAsText((Individual) box, componentontology, box.getCompartments(), true, preferences, prefixesArray, prefixesMap);
		        	}
					//Different individual
					if (getPreferenceParameterProcName("showDifferentIndividuals", preferences).equals("")) {
		        		if (getPreferenceParameterValue("showDifferentIndividuals", preferences).equals("true")){
			        		if (getPreferenceParameterValue("showDifferentIndividualsType", preferences).equals("As text")) createDifferentIndividualsAsText((Individual) box, componentontology, box.getCompartments(), false, preferences, prefixesArray, prefixesMap);
			        		else if (getPreferenceParameterValue("showDifferentIndividualsType", preferences).equals("Graphically")) createDifferentIndividualsGraphically((Individual) box, boxes, lines, componentontology, false, preferences, prefixesArray, prefixesMap);
		        		}
		        	} else {
		        		createDifferentIndividualsAsText((Individual) box, componentontology, box.getCompartments(), true, preferences, prefixesArray, prefixesMap);
		        	}
					//individual Annotations
					
		        	if (getPreferenceParameterProcName("showIndividualAnnotations", preferences).equals("")){
						if (getPreferenceParameterValue("showIndividualAnnotations", preferences).equals("true")) {
			        		if (getPreferenceParameterValue("showIndividualAnnotationType", preferences).equals("As text")) createIndividualAnnotationsAsText((Individual) box, componentontology, box.getCompartments(), false, preferences, userFieldsParameters, prefixesArray, prefixesMap);
			        		else if (getPreferenceParameterValue("showIndividualAnnotationType", preferences).equals("Graphically")) createIndividualAnnotationsGraphically((Individual) box, componentontology, needToBeAddedToBoxes, lines, false, preferences, userFieldsParameters, prefixesArray, prefixesMap);
			        	}
		        	} else {
		        		createIndividualAnnotationsAsText((Individual) box, componentontology, box.getCompartments(), true, preferences, userFieldsParameters, prefixesArray, prefixesMap);
		        		createIndividualAnnotationsGraphically((Individual) box, componentontology, needToBeAddedToBoxes, lines, true, preferences, userFieldsParameters, prefixesArray, prefixesMap);
					}
		        	
		        	
				}
			}
		//}
		//individuals links
		if (getPreferenceParameterProcName("showIndividualsObjectPropertyAssertions", preferences).equals("")){
			if (getPreferenceParameterValue("showIndividualsObjectPropertyAssertions", preferences).equals("true")) {
				for (Box box: boxes){
					if(box.getType().equals("Object")){
						Individual individual = (Individual) box;
						createIndividualLinks(individual, boxes, lines, preferences, componentontology, prefixesArray, prefixesMap, "showIndividualsObjectPropertyAssertions");
					}
				}
        	}
    	} else {
    		
		}
		//individuals links
		if (getPreferenceParameterProcName("showIndividualsNegativeObjectPropertyAssertions", preferences).equals("")){
			if (getPreferenceParameterValue("showIndividualsNegativeObjectPropertyAssertions", preferences).equals("true")) {
				for (Box box: boxes){
					if(box.getType().equals("Object")){
						Individual individual = (Individual) box;
						createIndividualLinks(individual, boxes, lines, preferences, componentontology, prefixesArray, prefixesMap, "showIndividualsNegativeObjectPropertyAssertions");
					}
				}
		   }
		} else {
		    		
		}
		
		
		//Ontology  annatations
		if (getPreferenceParameterProcName("showOntoAnnotations", preferences).equals("")) {
    		if (getPreferenceParameterValue("showOntoAnnotations", preferences).equals("true")){
        		if (getPreferenceParameterValue("showOntoAnnotationsInSeed", preferences).equals("Show in Seed symbol")) /*createOntologyAnnotationsInSeedSymbol(componentontology, boxes, false, null)*/;
        		else if (getPreferenceParameterValue("showOntoAnnotationsInSeed", preferences).equals("Show in diagram")) createOntologyAnnotationsInDiagram(componentontology, boxes, false, preferences, prefixesArray, prefixesMap);
    		}
    	} else {
    		//createOntologyAnnotationsInSeedSymbol((Individual) box, componentontology, box.getCompartments(), true, preferences);
    		createOntologyAnnotationsInDiagram(componentontology, boxes, true, preferences, prefixesArray, prefixesMap);
    	}
		
		//Annotation properties
		
		if (getPreferenceParameterProcName("showAnnotationPropertyDefs", preferences).equals("")) {
    		if (getPreferenceParameterValue("showAnnotationPropertyDefs", preferences).equals("true")){
    			createOntologyAnnotationProperties(componentontology, boxes, false, preferences, prefixesArray, prefixesMap, ontologies);
    		}
    	} else {
    		createOntologyAnnotationProperties(componentontology, boxes, true, preferences, prefixesArray, prefixesMap, ontologies);
    	}
		
		
		
		boxes.addAll(needToBeAddedToBoxes);
		
		//SubClasses as forks
		if (getPreferenceParameterProcName("showSubclassesGraphicsType", preferences).equals("")) {
		    if (getPreferenceParameterValue("showSubclassesGraphicsType", preferences).equals("As forks (if > 1)")){
		    	createSubClassesAsForks(lines, boxes, false, null);
		    }
		} else {
			createSubClassesAsForks(lines, boxes, true, preferences);
		}
		
		//showDisjointClassesMarkAtForks
		if (getPreferenceParameterProcName("showDisjointClassesMarkAtForks", preferences).equals("")) {
			if (getPreferenceParameterValue("showDisjointClassesMarkAtForks", preferences).equals("true")){
				createDisjointClassesMarkAtForks(boxes, lines, componentontology, false, preferences);
			}
		} else {
			createDisjointClassesMarkAtForks(boxes, lines, componentontology, true, preferences);
		}
		
		//Disjoint Classes Graphics Group As Boxes
		if (getPreferenceParameterProcName("showDisjointClassesGraphicsGroupAsBoxes", preferences).equals("")) {
			if (getPreferenceParameterValue("showDisjointClassesGraphicsGroupAsBoxes", preferences).equals("true") && getPreferenceParameterValue("showDisjointClassesType", preferences).equals("Graphically")){
				createDisjointOrEquivalentClassesGraphicsAsBoxes(lines, boxes, false, null, "Disjoint", componentontology);
			}
		} else {
			createDisjointOrEquivalentClassesGraphicsAsBoxes(lines, boxes, true, preferences, "Disjoint", componentontology);
		}
		
		//Equivalent Classes Graphics Group As Boxes
		if (getPreferenceParameterProcName("showEquivalentClassesGraphicsGroupAsBoxes", preferences).equals("")) {
			if (getPreferenceParameterValue("showEquivalentClassesGraphicsGroupAsBoxes", preferences).equals("true") && getPreferenceParameterValue("showEquivalentClassesType", preferences).equals("Graphically")){
				createDisjointOrEquivalentClassesGraphicsAsBoxes(lines, boxes, false, null, "EquivalentClass", componentontology);
			}
		} else {
			createDisjointOrEquivalentClassesGraphicsAsBoxes(lines, boxes, true, preferences, "EquivalentClass", componentontology);
		}
		
		//show Same Individuals Graphics Group As Boxes
		if (getPreferenceParameterProcName("showSameIndividualsGraphicsGroupAsBoxes", preferences).equals("")) {
			if (getPreferenceParameterValue("showSameIndividualsGraphicsGroupAsBoxes", preferences).equals("true")){
				createSameAsOrDifferentIndividualsGraphicsAsBoxes(lines, boxes, false, null, "SameAsIndivid", componentontology, prefixesArray, prefixesMap);
			}
		} else {
			createSameAsOrDifferentIndividualsGraphicsAsBoxes(lines, boxes, true, preferences, "SameAsIndivid", componentontology, prefixesArray, prefixesMap);
		}
		
		//show Different Individuals Graphics Group As Boxes
		if (getPreferenceParameterProcName("showDifferentIndividualsGraphicsGroupAsBoxes", preferences).equals("")) {
			if (getPreferenceParameterValue("showDifferentIndividualsGraphicsGroupAsBoxes", preferences).equals("true")){
				createSameAsOrDifferentIndividualsGraphicsAsBoxes(lines, boxes, false, null, "DifferentIndivid", componentontology, prefixesArray, prefixesMap);
			}
		} else {
			createSameAsOrDifferentIndividualsGraphicsAsBoxes(lines, boxes, true, preferences, "DifferentIndivid", componentontology, prefixesArray, prefixesMap);
		}
		
		// showSubclassesAutoForksForDisjoint
		if (getPreferenceParameterProcName("showSubclassesAutoForksForDisjoint", preferences).equals("")) {
			if (getPreferenceParameterValue("showSubclassesAutoForksForDisjoint", preferences).equals("true")){
				createSubclassesAutoForksForDisjoint(lines, boxes, false, null, componentontology);
			}
		} else {
			createSubclassesAutoForksForDisjoint(lines, boxes, true, preferences, componentontology);
		}
		
		//Object Complement Of
		for (Box box :  boxes) {
        	if (box.getType().equals("Class")){
				Class clazz = (Class) box;
        		for ( OWLEquivalentClassesAxiom eq : componentontology.getEquivalentClassesAxioms(clazz.getOwlClass())){
	        		for ( OWLClassExpression clexpr : eq.getClassExpressions()){
	            		if (clexpr.getComplementNNF().getClassExpressionType().toString().equals("Class")){
	            			for (Box tbox :  boxes){
	            				if (tbox.getType().equals("Class")){
	            					Class tclazz = (Class) tbox;
	            					if (tclazz.getName().equals(m.render(clexpr.getComplementNNF()).toString())){
	            						
	            						Boolean sameNamespace = true;
		            					if(tclazz.getNamespace() != null){
			            					for(OWLEntity sig : clexpr.getComplementNNF().getSignature()){
			            						if(!sig.getIRI().getNamespace().toString().equals(tclazz.getNamespace())){
			            							sameNamespace = false;
			            						}
			            					}
		            					}
	            						if(sameNamespace == true){
		            						Line eqClases = new Line(box, tclazz, "ComplementOf");

		        	            			lines.add(eqClases);
		        	            			ArrayList<Compartment> equivalentClassCompartemts = new ArrayList<Compartment>();
		        	            			eqClases.setCompartments(equivalentClassCompartemts);
		        	            			equivalentClassCompartemts.add(createCompartment("Label", "complementOf"));
		        	            			
		            						//Annotation
		            						for (OWLAnnotation annotationAxiom : eq.getAnnotations()) {
		            							createAnnotationCompartmentsFromAnnotations(equivalentClassCompartemts, annotationAxiom, prefixesArray, prefixesMap);
		            				    	}
	        	            			} else {
	        	            				unexported.add(eq.toString());
	        	            			}
	            					}
	            				}
	            			}
	            		}
	            	}
				}
        	}
        }
		
		//conteiner for single nodes
		needToBeAddedToBoxes = new ArrayList<Box>();
		for(Box box : boxes){
			if(box.getType().equals("DataType")){
				if (box.getContainer() == null && getPreferenceParameterValue("useContainersForSingleNodes", preferences).equals("true") 
						&& getPreferenceParameterValue("useContainersForSingleNodesDataTypes", preferences).equals("true")){
					String containerName = "";
					if(!getPreferenceParameterValue("useContainersForSingleNodesDataTypesSeparate", preferences).equals("true")){
						containerName = "Container_for_single_nodes";
			        } else {
			        	containerName = "Container_for_dataTypes";
			        }
					Boolean hasLine = false;
					for(Line line : lines){
						if(line.getSource().equals(box) || line.getTarget().equals(box)) {
							hasLine = true;
							break;
						}
					}
					if(hasLine == false){
						Box container = getContainer(containerName, boxes, needToBeAddedToBoxes);
				        box.setContainer(container);
				        container.setElemCount(container.getElemCount() + 1);
					}
				}			
			}
			if(box.getType().equals("Object")){
				if (box.getContainer() == null && getPreferenceParameterValue("useContainersForSingleNodes", preferences).equals("true") 
						&& getPreferenceParameterValue("useContainersForSingleNodesIndividuals", preferences).equals("true")){
					String containerName = "";
					if(getPreferenceParameterValue("useContainersForSingleNodesIndividualsGroupByClasses", preferences).equals("true")){
						for(Compartment c : box.getCompartments()){
							if(c.getType().equals("Title")){
								for(Compartment c1 : c.getSubCompartments()){
									if(c1.getType().equals("ClassName")){
										containerName = "Container_for_" + c1.getValue();
										break;
									}
								}
								break;
							}
						}
						if(containerName == ""){
							if(getPreferenceParameterValue("useContainersForSingleNodesIndividualsSeparate", preferences).equals("true")) containerName = "Container_for_Individuals";
							else {
					        	containerName = "Container_for_Individuals";
					        }
						}
			        } else if(!getPreferenceParameterValue("useContainersForSingleNodesIndividualsSeparate", preferences).equals("true")){
						containerName = "Container_for_single_nodes";
			        } else {
			        	containerName = "Container_for_Individuals";
			        }
					Boolean hasLine = false;
					for(Line line : lines){
						if(line.getSource().equals(box) || line.getTarget().equals(box)) {
							hasLine = true;
							break;
						}
					}
					if(hasLine == false){
						Box container = getContainer(containerName, boxes, needToBeAddedToBoxes);
				        box.setContainer(container);
				        container.setElemCount(container.getElemCount() + 1);
					}
				}			
			}
			if(box.getType().equals("Class") && getPreferenceParameterValue("cloneClassBoxesBySelfLines", preferences).equals("true")){
				ArrayList<Line> classLines = new ArrayList<Line>();
				for(Line line : lines){
					if(line.getSource().equals(box) && line.getTarget().equals(box)) {
						classLines.add(line);
					}
				}
				int counter = Integer.parseInt(getPreferenceParameterValue("cloneClassBoxesBySelfLinesCount", preferences));
				if(classLines.size() >= counter){
					//create a clone class
					Class clazz = (Class) box;
					Class newClass = new Class("Class", clazz.getName());
			    	newClass.setOwlClass(clazz.getOwlClass());
			    	newClass.setNamespace(clazz.getNamespace());
			    	//check container
			    	newClass.setContainer(clazz.getContainer());
	
			    	needToBeAddedToBoxes.add(newClass);
			    	
			    	ArrayList<Compartment> compartments = new ArrayList<Compartment>();
			    	//createCompartments
			    	Compartment newCompartment = createNameStructure(clazz.getName(), namespaceValue(prefixesArray, clazz.getNamespace(), prefixesMap));
					compartments.add(newCompartment);
			    	
			    	//add class compartments array
			    	newClass.setCompartments(compartments);

					//transfer link
			    	for(Line line : classLines){
						if(line.getSource().equals(box) && line.getTarget().equals(box)) {
							line.setSource(newClass);
						}
					}
				}
			}
		}
		
		if (getPreferenceParameterProcName("showUnloadedAxioms", preferences).equals("")) {
        	if (getPreferenceParameterValue("showUnloadedAxioms", preferences).equals("true")) {
        		if (getPreferenceParameterProcName("showUnloadedAxioms DisplayOnDemand", preferences).equals("")) {
                	if (getPreferenceParameterValue("showUnloadedAxioms DisplayOnDemand", preferences).equals("true")) {
                		ontology.setUnexported(unexported);	
                	}
                } else {
                	
                }
        		if (getPreferenceParameterProcName("showUnloadedAxioms InComment", preferences).equals("")) {
                	if (getPreferenceParameterValue("showUnloadedAxioms InComment", preferences).equals("true") && unexported.size() != 0) {
                		String un = "";
            			for(String st : unexported){
            				if(un.equals("")){
            					if(!st.equals("[]")) un = st;
            				} else {
            					if(!st.equals("[]")) un = un + " \n" + st;
            				}
            			}
            			if (!un.equals("")){
	                		Box newAnnotation = new Box("Annotation");
	            			boxes.add(newAnnotation);
	            			ArrayList<Compartment> annatationCompartments = new ArrayList<Compartment>();
	            			newAnnotation.setCompartments(annatationCompartments);
	            			Set<String> hs = new HashSet<>();
	            			hs.addAll(unexported);
	            			unexported.clear();
	            			unexported.addAll(hs);
	            			
	            			createAnnotationCompartments("unexported_axioms", un, "", annatationCompartments, "", null);
	            			
	            			if (newAnnotation.getContainer() == null && getPreferenceParameterValue("useContainersForSingleNodes", preferences).equals("true") 
	        						&& getPreferenceParameterValue("useContainersForSingleNodesOntoAnnotations", preferences).equals("true")){
	        					if(!getPreferenceParameterValue("useContainersForSingleNodesOntoAnnotationsSeparate", preferences).equals("true")){
	        						Box container = getContainer("Container_for_single_nodes", boxes, boxes);
	        						newAnnotation.setContainer(container);
	        						container.setElemCount(container.getElemCount() + 1);
	        			        } else {
	        			        	Box container = getContainer("Container_for_ontology_annotations", boxes, boxes);
	        			        	newAnnotation.setContainer(container);
	        			        	container.setElemCount(container.getElemCount() + 1);
	        			        }
	        				}
	            		}
                	}
                } else {
                	
                }
        	}
        } else {
        	
        }
		boxes.addAll(needToBeAddedToBoxes);
		for (Iterator<Box> iter = boxes.listIterator(); iter.hasNext(); ) {
		    Box box = iter.next();
		    
		    if(box.getType().equals("Container") && box.getElemCount() < 2){
		    	for(Box b : boxes){
		    		if(b.getContainer() == box) {
		    			b.setContainer(null);
		    			break;
		    		}
		    	}
		    	iter.remove();
		    }
				

		}
		return ontology;
	}
	
	public static String createMultiplisityValue(String minC, String maxC){
		String cardinality = "";
		if (minC!="" && maxC!="") {
			if(Integer.parseInt(minC)> Integer.parseInt(maxC)) return "";
			if(minC.equals(maxC)) return maxC;
			cardinality = minC + ".." + maxC;
		}
		else if(minC=="" && maxC!="") {
			if(maxC.equals("0")) return "0";
			cardinality = "0.." + maxC;
		}
		else if(minC!="" && maxC=="") cardinality = minC + "..*";
		//if(defaultMaxCardinality== true && cardinality == "") cardinality ="0..*"; 
		return  cardinality;
	}
	
	public static Boolean createRestrictionMultiplisity(OWLOntology componentontology, ArrayList<Line> lines, ArrayList<Compartment> compartments, String role, String namespace, Class source, Class target, OWLObjectProperty op){
		Boolean associationExists = false;
		Boolean multiplisityCreated = false;
		
		for(Line line : lines){
			if (line.getSource() != null &&  line.getTarget() != null) {
				if(line.getType().equals("Association") && line.getSource().equals(source) && line.getTarget().equals(target)){
					Association association = (Association) line;
					if(association.getName().equals(role) && (association.getNamespace() == null || namespace.equals("") || association.getNamespace().equals(namespace))){
						associationExists = true;
						break;
					}
				}
			}
		}
		
		if(!associationExists){
			String minC = "";
			String maxC = "";
			for (OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSubClass(source.getOwlClass())) {
				if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty()){
					
					ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
					if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(op)&& subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectExactCardinality") && subClassAxiom.getSuperClass().getClassesInSignature().contains(target.getOwlClass())){
						OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClassAxiom.getSuperClass();
						String cardinality = Integer.toString(cr.getCardinality());
						//if (defaultMaxCardinality == true && !cardinality.isEmpty() && !cardinality.equals("")) cardinality = cardinality + "..*";
						Compartment multiplisity = createCompartment("Multiplicity", cardinality);
						compartments.add(multiplisity);
						multiplisityCreated = true;
					}
				//	if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(op) && m.render(subClassAxiom).contains(" min ") && subClassAxiom.getSuperClass().getClassesInSignature().contains(target.getOwlClass())){
					if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(op) && subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectMinCardinality") && subClassAxiom.getSuperClass().getClassesInSignature().contains(target.getOwlClass())){
						OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClassAxiom.getSuperClass();
						minC = Integer.toString(cr.getCardinality());
					}
					if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(op) && subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectMaxCardinality") && subClassAxiom.getSuperClass().getClassesInSignature().contains(target.getOwlClass())){
						OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClassAxiom.getSuperClass();
						maxC = Integer.toString(cr.getCardinality());
					}
				}
		    }
			
			String cardinality = createMultiplisityValue(minC, maxC);
			if(cardinality!=""){
				Compartment multiplisity = createCompartment("Multiplicity", cardinality);
				compartments.add(multiplisity);
				multiplisityCreated = true;
			}
		}
		return multiplisityCreated;
	}
	
	public static void createMultiplisity(OWLOntology componentontology, Association association, ArrayList<Compartment> compartments){
		if (association.getSource() != null &&  association.getTarget() != null){
			Class sourceClass = (Class) association.getSource();
			OWLClass source = sourceClass.getOwlClass();
			Class targetClass = (Class) association.getTarget();
			OWLClass target = targetClass.getOwlClass();
			
			String minC = "";
			String maxC = "";
			
			for (OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSubClass(source)) {
				if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty()){
					ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
					//if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(association) && m.render(subClassAxiom).contains("exactly") && subClassAxiom.getSuperClass().getClassesInSignature().contains(target)){
					//if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(association.getOwlObjectProperty())&& m.render(subClassAxiom).contains(" exactly ") && subClassAxiom.getSuperClass().getClassesInSignature().contains(target)){
					if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(association.getOwlObjectProperty())&& m.render(subClassAxiom).contains(" exactly ")){
							
						OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClassAxiom.getSuperClass();
						String cardinality = Integer.toString(cr.getCardinality());
						//if (defaultMaxCardinality == true && !cardinality.isEmpty() && !cardinality.equals("")) cardinality = cardinality + "..*";
						Compartment multiplisity = createCompartment("Multiplicity", cardinality);
						compartments.add(multiplisity);
					}
					
					if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(association.getOwlObjectProperty()) && m.render(subClassAxiom).contains(" min ") ){
						OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClassAxiom.getSuperClass();
						minC = Integer.toString(cr.getCardinality());
					}
					if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty() && subClassAxiom.getObjectPropertiesInSignature().contains(association.getOwlObjectProperty()) && m.render(subClassAxiom).contains(" max ") ){
						OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClassAxiom.getSuperClass();
						maxC = Integer.toString(cr.getCardinality());
					}
				}
		    }
			
			String cardinality = createMultiplisityValue(minC, maxC);
			
			if(cardinality!=""){
				Compartment multiplisity = createCompartment("Multiplicity", cardinality);
				compartments.add(multiplisity);
			}
		}
	}
	
	
	public static void createRestriction(OWLSubClassOfAxiom subClassAxiom, OWLOntology componentontology, ArrayList<Line> lines, JsonObject preferences, ArrayList<Box> boxes, String[] prefixesArray, Map<String, String> prefixesMap){
		if (!subClassAxiom.getObjectPropertiesInSignature().isEmpty()){
			
			ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl(); 
			//if (m.render(subClassAxiom.getSuperClass()).contains(" some ") && subClassAxiom.getSuperClass().getClassesInSignature().size() < 2) {
			if (subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectSomeValuesFrom") && subClassAxiom.getSuperClass().getClassesInSignature().size() < 2) {
				OWLObjectSomeValuesFrom r = (OWLObjectSomeValuesFrom) subClassAxiom.getSuperClass();
     			 if (!subClassAxiom.getSubClass().isAnonymous() && !r.getFiller().isAnonymous()){
     				 Class sourse =  findClass(boxes, (OWLClass) subClassAxiom.getSubClass());
	        		 Class target =  findClass(boxes, (OWLClass) r.getFiller());
     				Boolean createRestriction = false;
	        		 if (getPreferenceParameterProcName("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("")) {
     		    		if (!getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("true") || ((getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("true") && !target.getName().equals("Thing")))){
     		    			 createRestriction = true;
     		    		}
     		    	}
	        		 if (getPreferenceParameterProcName("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("")) {
	     		    		if (!getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("true") || ((getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("true") && !target.getName().equals("Thing")))){
	     		    			 createRestriction = true;
	     		    		}
	     		    	}
     				 
     				if(createRestriction){
     					String role = r.getProperty().getNamedProperty().asOWLObjectProperty().getIRI().getShortForm();
		         		 
     					 Boolean alreadyExists = false;
     					 for (Line line : lines){
     						if(line.getType().equals("Restriction") && line.getSource().equals(sourse) && line.getTarget().equals(target)) {
     							for(Compartment c : line.getCompartments()){
     								if(c.getType().equals("Name")){
     									for(Compartment namec : c.getSubCompartments()){
     										if(namec.getType().equals("Role") && namec.getValue().equals(role)) alreadyExists = true;
     									}
     								}
     							}
     						}
     					 }
     					 ArrayList<Compartment> compartments = new ArrayList<Compartment>();
		        		 String namespace = "";
		         		 if ((!componentontology.getOntologyID().isAnonymous() 
		         				 && !r.getProperty().getNamedProperty().asOWLObjectProperty().getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
		         				 && !r.getProperty().getNamedProperty().asOWLObjectProperty().getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))
		         				 || (componentontology.getOntologyID().isAnonymous() 
		         						 && !r.getProperty().getNamedProperty().asOWLObjectProperty().getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = r.getProperty().asOWLObjectProperty().getIRI().getNamespace();
		         		 namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		         		 
		        		 Line restriction = checkForRestriction(lines, sourse, target, compartments, role, namespace, m, m.render(r.getProperty()).contains("inverse "));
		        		 if(restriction!= null){
			        		 if(restriction.getCompartments() != null) compartments = restriction.getCompartments();
			        	     compartments.add(createCompartment("Some", "true"));
			        	     restriction.setCompartments(compartments);
		        	     
			        	     //multiplisity
			        	     Boolean multiplisityCreated = createRestrictionMultiplisity(componentontology, lines, compartments,  role, namespace,  sourse,  target,  r.getProperty().getNamedProperty().asOWLObjectProperty());
			        	     if(alreadyExists == false)lines.add(restriction);
		        	     } else {unexported.add(r.toString());}
     				}
     			}   
			}
			//if (m.render(subClassAxiom.getSuperClass()).contains(" only ") && subClassAxiom.getSuperClass().getClassesInSignature().size() < 2) {
			if (subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectAllValuesFrom") && subClassAxiom.getSuperClass().getClassesInSignature().size() < 2) {
				OWLObjectAllValuesFrom r = (OWLObjectAllValuesFrom) subClassAxiom.getSuperClass();
        		 if (!subClassAxiom.getSubClass().isAnonymous() && !r.getFiller().isAnonymous()){
        			 Class sourse =  findClass(boxes, (OWLClass) subClassAxiom.getSubClass());
	        		 Class target =  findClass(boxes, (OWLClass) r.getFiller());
	        		 Boolean createRestriction = false;
	        		 if (getPreferenceParameterProcName("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("")) {
     		    		if (!getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("true") || ((getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("true") && !target.getName().equals("Thing")))){
     		    			 createRestriction = true;
     		    		}
     		    	}
	        		 if (getPreferenceParameterProcName("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("")) {
	     		    		if (!getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("true") || ((getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("true") && !target.getName().equals("Thing")))){
	     		    			 createRestriction = true;
	     		    		}
	     		    	}
     				 
     				if(createRestriction){
     					String role = r.getProperty().getNamedProperty().asOWLObjectProperty().getIRI().getShortForm();
		         		 
     					Boolean alreadyExists = false;
    					 for (Line line : lines){
    						if(line.getType().equals("Restriction") && line.getSource().equals(sourse) && line.getTarget().equals(target)) {
     							for(Compartment c : line.getCompartments()){
     								if(c.getType().equals("Name")){
     									for(Compartment namec : c.getSubCompartments()){
     										if(namec.getType().equals("Role") && namec.getValue().equals(role)) alreadyExists = true;
     									}
     								}
     							}
     						}
    					 }
     					 ArrayList<Compartment> compartments = new ArrayList<Compartment>();
		        		 String namespace = "";
		         		 if ((!componentontology.getOntologyID().isAnonymous() 
		         				 && !r.getProperty().getNamedProperty().asOWLObjectProperty().getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
		         				 && !r.getProperty().getNamedProperty().asOWLObjectProperty().getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
		         				 ||(componentontology.getOntologyID().isAnonymous()
		         						 && !r.getProperty().getNamedProperty().asOWLObjectProperty().getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = r.getProperty().asOWLObjectProperty().getIRI().getNamespace();
		         	     
		         	     namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		        		 Line restriction = checkForRestriction(lines, sourse, target, compartments, role, namespace, m ,m.render(r.getProperty()).contains("inverse "));
		        		 if(restriction != null){
			        		 if(alreadyExists == false)lines.add(restriction);
			        		 if(restriction.getCompartments() != null) compartments = restriction.getCompartments();
			        		 compartments.add(createCompartment("Only", "true"));
			        	     restriction.setCompartments(compartments);
			        	     //multiplisity
			        	     createRestrictionMultiplisity(componentontology, lines, compartments,  role, namespace,  sourse,  target,  r.getProperty().getNamedProperty().asOWLObjectProperty());
		        		 } else {
		        			 unexported.add(r.toString());
		        		 }
     				}
     			}
			}	
			//if ((m.render(subClassAxiom.getSuperClass()).contains(" exactly ") || m.render(subClassAxiom.getSuperClass()).contains(" min ") || m.render(subClassAxiom.getSuperClass()).contains(" max ") ) && subClassAxiom.getSuperClass().getClassesInSignature().size() < 2) {
			if ((subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectExactCardinality") || subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectMinCardinality") 
					||subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectMaxCardinality") ) && subClassAxiom.getSuperClass().getClassesInSignature().size() < 2) {
				OWLCardinalityRestriction r = (OWLCardinalityRestriction) subClassAxiom.getSuperClass();
       		 if (!subClassAxiom.getSubClass().isAnonymous()){
       			 	 Class sourse =  findClass(boxes, (OWLClass) subClassAxiom.getSubClass());
	        		 Class target =  findClass(boxes, (OWLClass) r.getFiller());
	        		 
	        		 Boolean createRestriction = false;
	        		 if (getPreferenceParameterProcName("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("")) {
     		    		if (!getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("true") || ((getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToThing", preferences).equals("true") && target != null && !target.getName().equals("Thing")))){
     		    			 createRestriction = true;
     		    		}
     		    	}
	        		 if (getPreferenceParameterProcName("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("")) {
	     		    		if (!getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("true") || ((getPreferenceParameterValue("showPropertyRestrictionsGraphicallyNoLineToSelf", preferences).equals("true") && target != null && !target.getName().equals("Thing")))){
	     		    			 createRestriction = true;
	     		    		}
	     		    }
	        		 if (createRestriction == true){
	        		 String property = m.render(r.getProperty());
    				 if (property.startsWith(" inverse (")) {
    						property = property.substring(10, property.length()-1);
    				 }
    				  if(!checkIfAssociationExists(sourse, target, property, lines, componentontology) &&
    						  getPreferenceParameterProcName("showObjectPropertiesType", preferences).equals("") &&
								getPreferenceParameterValue("showObjectPropertiesType", preferences).equals("Graphically")){
    					  Boolean alreadyExists = false;
    					  String role = property;
    					  for (Line line : lines){
     						if(line.getType().equals("Restriction") && line.getSource().equals(sourse) && line.getTarget().equals(target)) {
     							for(Compartment c : line.getCompartments()){
     								if(c.getType().equals("Name")){
     									for(Compartment namec : c.getSubCompartments()){
     										if(namec.getType().equals("Role") && namec.getValue().equals(role)) alreadyExists = true;
     									}
     								}
     							}
     						}
     					 }
    					  ArrayList<Compartment> compartments = new ArrayList<Compartment>();
		        		 String namespace = "";
		         		 
		         		 
		         	     namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		        		 Line restriction = checkForRestriction(lines, sourse, target, compartments, role, namespace, m, m.render(r.getProperty()).contains("inverse "));
		        		 if(restriction != null){
			        		 if(restriction.getCompartments() != null) compartments = restriction.getCompartments();
			        		 if(alreadyExists == false)lines.add(restriction);
			        	     //multiplisity
			        	     Set<OWLObjectProperty> opset = subClassAxiom.getSuperClass().getObjectPropertiesInSignature();
			        	     OWLObjectProperty op = null;
			        	     for(OWLObjectProperty o : opset){
			        	    	 op = o;
			        	     }
			        	     restriction.setCompartments(compartments);
			        	     createRestrictionMultiplisity(componentontology, lines, compartments,  role, namespace, sourse,  target, op);
		        		 } else {
		        			 unexported.add(r.toString());
		        		 }
    				}
	        		 }
    			}
			}	
		}
	}
	
	public static Boolean checkIfAssociationExists(Class sourse, Class target, String property, ArrayList<Line> lines, OWLOntology componentontology){
		for(OWLObjectProperty op : componentontology.getObjectPropertiesInSignature()){
			Boolean prapertyTarget = false;
			Boolean propertySourse = false;
			for(OWLObjectPropertyDomainAxiom opd : componentontology.getObjectPropertyDomainAxioms(op)){
				if(opd.containsEntityInSignature(sourse.getOwlClass())) {
					prapertyTarget = true;
					break;
				}
			}
			for(OWLObjectPropertyRangeAxiom opd : componentontology.getObjectPropertyRangeAxioms(op)){
				if(opd.containsEntityInSignature(target.getOwlClass())) {
					propertySourse = true;
					break;
				}
			}

			if(op.getIRI().getShortForm().equals(property) 
					&& prapertyTarget == true
					&& propertySourse == true){
				return true;
			}
			//componentontology.getObjectPropertyDomainAxioms(op).c;
			//sourse.getOwlClass();
		}
		/*for (Line line : lines){
			if(line.getType().equals("Association")){
				Association assoc = (Association) line;
				if(assoc.getName().equals(property) && assoc.getSource().equals(sourse) && assoc.getTarget().equals(target)) return true;
			}
		}*/
		return false;
	}
	
	public static Line checkForRestriction(ArrayList<Line> lines, Box source, Box target, ArrayList<Compartment> compartments, String role, String namespace, ManchesterOWLSyntaxOWLObjectRendererImpl  m,  Boolean containsInverse){
		for (Line line : lines){
			if(line.getType().equals("Restriction") && line.getSource().equals(source) && line.getTarget().equals(target)) {
				for(Compartment c : line.getCompartments()){
					if(c.getType().equals("Name")){
						for(Compartment namec : c.getSubCompartments()){
							if(namec.getType().equals("Role") && namec.getValue().equals(role)) return line;
						}
					}
				}
			}
		}
		//name
		 Compartment newCompartment = createCompartment("Name", "");
	    //Name Namespace
	    ArrayList<Compartment> subCompartments = new ArrayList<Compartment>();
	    subCompartments.add(createCompartment("Role", role));
	    subCompartments.add(createCompartment("Namespace", namespace));
	    newCompartment.setSubCompartments(subCompartments);
	    // isInverse
	    compartments.add(newCompartment);

	    if (containsInverse){
	    	subCompartments.add(createCompartment("IsInverse", "true"));
	     }
	    
		Line line = new Line(source, target, "Restriction");
		return line; 
	}
	
	public static Class findClass(ArrayList<Box> boxes, OWLClass owlClass){
		for (Box box : boxes){
			if (box.getType().equals("Class")){
				Class c= (Class) box;
				if (c.getOwlClass()!= null && c.getOwlClass().equals(owlClass)) return c;
			}
		}
		return null;
	}
	
	public static void createThingGeneralizations(ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology){
		Box thing = null;
		for(Box box : boxes){
			if(box.getType().equals("Class")){
				Class t = (Class) box;
				if (t.getName().equals("Thing")) {thing = box; break;}
			}
		}
		
		for(Box box : boxes){
			Boolean hasGeneralization = false;
			Boolean isNamedClass = false;
			Boolean isThing = false;
			if(box.getType().equals("Class")){
				Class c = (Class) box;
				if(c.getName().equals("Thing")){
					isThing = true;
				}
				for (OWLClass co : componentontology.getClassesInSignature()){
					if (co.getIRI().getShortForm().equals(c.getName()) && (c.getNamespace() == null || co.getIRI().getNamespace().toString().equals(c.getNamespace()))) {isNamedClass = true; break;}
				}
				
				for(Line line : lines){
					//has Generalization to named class
					if(line.getType().equals("Generalization") && line.getSource() != null && line.getSource().equals(box)){
						Class clazz = (Class) line.getTarget();
						if(clazz != null){
						for(OWLClass owlClass :componentontology.getClassesInSignature()){
							if(owlClass.getIRI().getShortForm().equals(clazz.getName()) && (clazz.getNamespace() == null || owlClass.getIRI().getNamespace().toString().equals(clazz.getNamespace()))){
								hasGeneralization = true;
								break;
							}
						}}
					}
				}
			}
			
			if (isThing == false && hasGeneralization==false && isNamedClass == true){
				Line generalization = new Line( box, thing, "Generalization");
		    	lines.add(generalization);
			}
		}
	}
	
	public static void createThingClass(ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology){
		for (OWLClass co : componentontology.getClassesInSignature()){
			if (co.getIRI().getShortForm().equals("Thing")) return;
		}
		
		Class thing = new Class("Class", "Thing");
		boxes.add(thing);
		
		ArrayList<Compartment> compartments = new ArrayList<Compartment>();

    	//add class compartments array
		thing.setCompartments(compartments);
		
		//Name
		Compartment newCompartment = createNameStructure("Thing", "");
		compartments.add(newCompartment);
	}
	
	public static Class createClass(OWLClass co, ArrayList<Box> boxes, Set<OWLDataProperty> dataProperties, OWLOntology componentontology, JsonObject preferences, String[] prefixesArray, Map<String, String> prefixesMap){
		Class newClass = new Class("Class", co.getIRI().getShortForm().toString());
    	newClass.setOwlClass(co);
    	newClass.setNamespace(co.getIRI().getNamespace().toString());

    	boxes.add(newClass);
    	
    	//container
    	if(co != null) {
    		 createContainerFromAnnotationAxiom(componentontology.getAnnotationAssertionAxioms(co.getIRI()),  componentontology, boxes, boxes, newClass, null, null);
    	}

    	ArrayList<Compartment> compartments = new ArrayList<Compartment>();
    	
    	createClassCompartments(newClass, co, compartments, componentontology, preferences, prefixesArray, prefixesMap);
    	
    	//add class compartments array
    	newClass.setCompartments(compartments);
    	return newClass;
	}
	
	public static Integer countReferencesTimes(Set<OWLClass> classesinSignature, OWLOntology componentontology, String axiom){
		Integer count = 0;
		
		Set<OWLAxiom> axioms = null;
		for( OWLClass c : classesinSignature){
			if(axioms == null) axioms = componentontology.getReferencingAxioms(c);
			else axioms.retainAll(componentontology.getReferencingAxioms(c));
		} 
		for(OWLAxiom a : axioms){
			if(a.toString().contains(axiom)) count = count +1;
		}	
		return count;
	}
	
	public static void createAnonymousClasses(OWLClass co,  ArrayList<Box> boxes,  OWLOntology componentontology, JsonObject preferences, ArrayList<Line> lines){
		ManchesterOWLSyntaxOWLObjectRendererImpl  mParser =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
    	if (getPreferenceParameterProcName("showSubclasses", preferences).equals("")) {
    		if (getPreferenceParameterValue("showSubclasses", preferences).equals("true")){
        		if (getPreferenceParameterValue("showSubclassesType", preferences).equals("Graphically") && (getPreferenceParameterValue("showSubclassesCreateTarget", preferences).equals("Yes"))) {
        			for (OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSuperClass(co)) {
        				createAnonymousClass(boxes, mParser.render(subClassAxiom.getSubClass()).replace("\n", "\\n"));
        	    	}
        			
            		for (OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSubClass(co)) {
            			//if only classes in Union
            			Boolean onlyClasses = true;
            			for (OWLEntity entity : subClassAxiom.getSuperClass().getSignature()){
            				if(!entity.getEntityType().toString().equals("Class")){
            					onlyClasses = false;
            					break;
            				}
            			}
            			if((subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectUnionOf") ||subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectIntersectionOf")) && onlyClasses == true) {
            				Class newClass = createAnonymousClass(boxes, mParser.render(subClassAxiom.getSuperClass()).replace("\n", "\\n"));
            				if (getPreferenceParameterProcName("showSubclassesToUnionOfNamed", preferences).equals("")) {
        			    		if (getPreferenceParameterValue("showSubclassesToUnionOfNamed", preferences).equals("true")){
        			    			createObjectUnionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClassAxiom.getSuperClass(),  boxes, lines, newClass);
        			    		}
        			    	} else if (calculateParameterProcedure("showSubclassesToUnionOfNamed", preferences).equals("true")) {
        			    		createObjectUnionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClassAxiom.getSuperClass(),  boxes, lines, newClass);
        			    	} 
        					if (getPreferenceParameterProcName("showSubclassesFromAndNamed", preferences).equals("")) {
        			    		if (getPreferenceParameterValue("showSubclassesFromAndNamed", preferences).equals("true")){
        			    			createObjectIntersectionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClassAxiom.getSuperClass(),  boxes, lines, newClass);
        			    		}
        			    	} else if (calculateParameterProcedure("showSubclassesFromAndNamed", preferences).equals("true")) {
        			    		createObjectIntersectionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClassAxiom.getSuperClass(),  boxes, lines, newClass);
        			    	}  
            			}
            	    }
        		} else if(getPreferenceParameterValue("showSubclassesType", preferences).equals("Graphically") &&
        				getPreferenceParameterValue("showSubclassesCreateTarget", preferences).equals("Create if multiple use") && 
						getPreferenceParameterValue("showClassExprsAsBoxByCountEnable", preferences).equals("true")){
        			for (OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSuperClass(co)) {
        				if(Integer.parseInt(getPreferenceParameterValue("showClassExprsAsBoxCount", preferences)) <= countReferencesTimes(subClassAxiom.getSubClass().getClassesInSignature(), componentontology, subClassAxiom.getSubClass().toString()))createAnonymousClass(boxes, mParser.render(subClassAxiom.getSubClass()).replace("\n", "\\n"));
        	    	}
        			
        			
        			for (OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSubClass(co)) {
            			//if only classes in Union
            			Boolean onlyClasses = true;
            			for (OWLEntity entity : subClassAxiom.getSuperClass().getSignature()){
            				if(!entity.getEntityType().toString().equals("Class")){
            					onlyClasses = false;
            					break;
            				}
            			}
            			if((subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectUnionOf") || subClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectIntersectionOf")) && onlyClasses == true) {
            				if(Integer.parseInt(getPreferenceParameterValue("showClassExprsAsBoxCount", preferences)) <= countReferencesTimes(subClassAxiom.getSuperClass().getClassesInSignature(), componentontology, subClassAxiom.getSuperClass().toString())){
	            				Class newClass = createAnonymousClass(boxes, mParser.render(subClassAxiom.getSuperClass()).replace("\n", "\\n"));
	            				if (getPreferenceParameterProcName("showSubclassesToUnionOfNamed", preferences).equals("")) {
	        			    		if (getPreferenceParameterValue("showSubclassesToUnionOfNamed", preferences).equals("true")){
	        			    			createObjectUnionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClassAxiom.getSuperClass(),  boxes, lines, newClass);
	        			    		}
	        			    	} else if (calculateParameterProcedure("showSubclassesToUnionOfNamed", preferences).equals("true")) {
	        			    		createObjectUnionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClassAxiom.getSuperClass(),  boxes, lines, newClass);
	        			    	} 
	        					if (getPreferenceParameterProcName("showSubclassesFromAndNamed", preferences).equals("")) {
	        			    		if (getPreferenceParameterValue("showSubclassesFromAndNamed", preferences).equals("true")){
	        			    			createObjectIntersectionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClassAxiom.getSuperClass(),  boxes, lines, newClass);
	        			    		}
	        			    	} else if (calculateParameterProcedure("showSubclassesFromAndNamed", preferences).equals("true")) {
	        			    		createObjectIntersectionOfGeneralizationFromDomaininAnonymousClass(componentontology, subClassAxiom.getSuperClass(),  boxes, lines, newClass);
	        			    	}
        					}
            			}
            	    }
        		}
    		}
    	} else {
    		for (OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSuperClass(co)) {
    			if (calculateParameterProcedure("showSubclasses", preferences).equals("true") && calculateParameterProcedure("showSubclassesType", preferences).equals("Graphically")) createAnonymousClass(boxes, mParser.render(subClassAxiom.getSubClass()).replace("\n", "\\n"));
	    	}
    	}
	}
	
	public static Class createAnonymousClass(ArrayList<Box> boxes, String subClassName, ArrayList<String> eqClasesName){
		Boolean createAnonymousClass = true;
		for (Box box : boxes){
			if (box.getType().equals("Class")){
				Class clazz = (Class) box;
				if (clazz.getName().equals(subClassName)){
					createAnonymousClass = false;
					break;
					
				}
			}
		}
		if (createAnonymousClass && !subClassName.equals("")){
			Class newClass = new Class("Class", subClassName);
	    	boxes.add(newClass);
	    	newClass.setName(subClassName);
	    	ArrayList<Compartment> compartments = new ArrayList<Compartment>();
	    	newClass.setCompartments(compartments);
	    	ArrayList<Compartment> equivalentClasses = new ArrayList<Compartment>();    	
	    	Compartment newClasses = createCompartment("EquivalentClasses", "");
	    	equivalentClasses.add(newClasses);
	       	Compartment ASFictitiousClass = createCompartment("ASFictitiousEquivalentClass", "");
	       	ASFictitiousClass.setIsMultiline(true);
	        newClasses.setSubCompartment(ASFictitiousClass);
	       	ArrayList<Compartment> newClasses2 = new ArrayList<Compartment>();
	       	ASFictitiousClass.setSubCompartments(newClasses2);
	       	//for(String eqClN : eqClasesName){
	       		Compartment newClass2 = createCompartment("EquivalentClass", "");
	       		newClasses2.add(newClass2);

	       		Compartment newExpression = new Compartment("Expression", subClassName);
	       		newClass2.setSubCompartment(newExpression);
	       	//}
	    	//createMultiLineCompartments(equivalentClasses, subClassName, "EquivalentClasses", "ASFictitiousEquivalentClass", "EquivalentClass", "Expression");
	    	createASFictitiousForMultiLineCompartments(equivalentClasses, compartments, "ASFictitiousEquivalentClasses"); 
	    	return newClass;
		}
		return null;
	}
	
	public static Class createAnonymousClass(ArrayList<Box> boxes, String subClassName){
		Boolean createAnonymousClass = true;
		for (Box box : boxes){
			if (box.getType().equals("Class")){
				Class clazz = (Class) box;
				if (clazz.getName().equals(subClassName)){
					createAnonymousClass = false;
					break;
					
				}
			}
		}
		if (createAnonymousClass && !subClassName.equals("")){
			Class newClass = new Class("Class", subClassName);
	    	boxes.add(newClass);
	    	newClass.setName(subClassName);
	    	ArrayList<Compartment> compartments = new ArrayList<Compartment>();
	    	newClass.setCompartments(compartments);
	    	ArrayList<Compartment> equivalentClasses = new ArrayList<Compartment>();    	
	    	createMultiLineCompartments(equivalentClasses, subClassName, "EquivalentClasses", "ASFictitiousEquivalentClass", "EquivalentClass", "Expression");
	    	createASFictitiousForMultiLineCompartments(equivalentClasses, compartments, "ASFictitiousEquivalentClasses"); 
	    	return newClass;
		}
		return null;
	}
	
	public static void createObjectUnionOfGeneralizationFromDomainAndRange(ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass, OWLClass classInDomain){
		if(newClass != null){
			for(Box box : boxes){
				if(box.getType().equals("Class")){
					Class c = (Class) box;
					if (c.getName().equals(classInDomain.getIRI().getShortForm()) && (c.getNamespace() == null || classInDomain.getIRI().getNamespace().toString().equals(c.getNamespace()))){
						Boolean generalizationWExists = false;
						for(Line line :lines){
							if(line.getType().equals("Generalization") && line.getSource().equals(box) && line.getTarget().equals(newClass)) generalizationWExists = true;
						}
						if(generalizationWExists != true){
							Line generalization = new Line(box, newClass, "Generalization");
							lines.add(generalization);
						}
					}
				}
			}
		}
	}
	
	public static void createObjectIntersectionOfGeneralizationFromDomainAndRange(ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass, OWLClass classInDomain){
		for(Box box : boxes){
			if(box.getType().equals("Class")){
				Class c = (Class) box;
				if (c.getName().equals(classInDomain.getIRI().getShortForm()) && (c.getNamespace() == null || classInDomain.getIRI().getNamespace().toString().equals(c.getNamespace()))){
					Boolean generalizationWExists = false;
					for(Line line :lines){
						if(line.getType().equals("Generalization") && line.getSource().equals(newClass) && line.getTarget().equals(box)) generalizationWExists = true;
					}
					if(generalizationWExists != true){
						Line generalization = new Line(newClass, box, "Generalization");
						lines.add(generalization);
					}
					
				}
			}
		}
	}
	
	public static void createObjectIntersectionOfGeneralizationFromDomaininObjectProperty(OWLOntology componentontology, OWLObjectProperty op,  ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass){
		//if prorerty has one domain and its ClassExpressionType == ObjectIntersectionOf then create
		if (componentontology.getObjectPropertyDomainAxioms(op).size() == 1){
			for (OWLObjectPropertyDomainAxiom opd: componentontology.getObjectPropertyDomainAxioms(op)){
				if(opd.getDomain().getClassExpressionType().toString().equals("ObjectIntersectionOf")){
					for(OWLClassExpression classInDomain : opd.getDomain().asConjunctSet()){
						if(classInDomain.getClassExpressionType().toString().equals("Class")){
							OWLClass c = (OWLClass) classInDomain;
							createObjectIntersectionOfGeneralizationFromDomainAndRange(boxes, lines, newClass, c);
						}
					}
				}
			}
		}
	}
	
	public static void createObjectIntersectionOfGeneralizationFromDomainDataProperty(OWLOntology componentontology, OWLDataProperty op,  ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass){
		//if prorerty has one domain and its ClassExpressionType == ObjectIntersectionOf then create
		if (componentontology.getDataPropertyDomainAxioms(op).size() == 1){
			for (OWLDataPropertyDomainAxiom opd: componentontology.getDataPropertyDomainAxioms(op)){
				if(opd.getDomain().getClassExpressionType().toString().equals("ObjectIntersectionOf")){
					for(OWLClassExpression classInDomain : opd.getDomain().asConjunctSet()){
						if(classInDomain.getClassExpressionType().toString().equals("Class")){
							OWLClass c = (OWLClass) classInDomain;
							createObjectIntersectionOfGeneralizationFromDomainAndRange(boxes, lines, newClass, c);
						}
					}
				}
			}
		}
	}
	
	public static void createObjectIntersectionOfGeneralizationFromRangeInObjectProperty(OWLOntology componentontology, OWLObjectProperty op,  ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass){
		//if prorerty has one domain and its ClassExpressionType == ObjectIntersectionOf then create
		if (componentontology.getObjectPropertyRangeAxioms(op).size() == 1){
			for (OWLObjectPropertyRangeAxiom opd: componentontology.getObjectPropertyRangeAxioms(op)){
				if(opd.getRange().getClassExpressionType().toString().equals("ObjectIntersectionOf")){
					for(OWLClassExpression classInDomain : opd.getRange().asConjunctSet()){
						if(classInDomain.getClassExpressionType().toString().equals("Class")){
							OWLClass c = (OWLClass) classInDomain;
							createObjectIntersectionOfGeneralizationFromDomainAndRange(boxes, lines, newClass, c);
						}
					}
				}
			}
		}
	}
	
	
	public static void createObjectUnionOfGeneralizationFromDomaininObjectProperty(OWLOntology componentontology, OWLObjectProperty op,  ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass){
		//if prorerty has one domain and its ClassExpressionType == ObjectUnionOf then create
		if (componentontology.getObjectPropertyDomainAxioms(op).size() == 1){
			for (OWLObjectPropertyDomainAxiom opd: componentontology.getObjectPropertyDomainAxioms(op)){
				if(opd.getDomain().getClassExpressionType().toString().equals("ObjectUnionOf")){
					for(OWLClass classInDomain : opd.getDomain().getClassesInSignature()){
						createObjectUnionOfGeneralizationFromDomainAndRange(boxes, lines, newClass, classInDomain);
					}
				}
			}
		}
	}
	
	public static void createObjectUnionOfGeneralizationFromDomainDataProperty(OWLOntology componentontology, OWLDataProperty op,  ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass){
		//if prorerty has one domain and its ClassExpressionType == ObjectUnionOf then create
		if (componentontology.getDataPropertyDomainAxioms(op).size() == 1){
			for (OWLDataPropertyDomainAxiom opd: componentontology.getDataPropertyDomainAxioms(op)){
				if(opd.getDomain().getClassExpressionType().toString().equals("ObjectUnionOf")){
					for(OWLClass classInDomain : opd.getDomain().getClassesInSignature()){
						createObjectUnionOfGeneralizationFromDomainAndRange(boxes, lines, newClass, classInDomain);
					}
				}
			}
		}
	}
	
	public static void createObjectUnionOfGeneralizationFromRangeInObjectProperty(OWLOntology componentontology, OWLObjectProperty op,  ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass){
		//if prorerty has one domain and its ClassExpressionType == ObjectUnionOf then create
		if (componentontology.getObjectPropertyRangeAxioms(op).size() == 1){
			for (OWLObjectPropertyRangeAxiom opd: componentontology.getObjectPropertyRangeAxioms(op)){
				if(opd.getRange().getClassExpressionType().toString().equals("ObjectUnionOf")){
					for(OWLClass classInDomain : opd.getRange().getClassesInSignature()){
						createObjectUnionOfGeneralizationFromDomainAndRange(boxes, lines, newClass, classInDomain);
					}
				}
			}
		}
	}
	
	public static void createObjectUnionOfGeneralizationFromDomaininAnonymousClass(OWLOntology componentontology, OWLClassExpression classExpression,  ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass){
		if (classExpression.getClassExpressionType().toString().equals("ObjectUnionOf")){
			for(OWLClassExpression entity :classExpression.asDisjunctSet()){
				if(entity.getClassExpressionType().toString().equals("Class")){
					OWLClass c = (OWLClass) entity;
					createObjectUnionOfGeneralizationFromDomainAndRange(boxes, lines, newClass, c);
				}
			}
			
		}
	}
	
	public static void createObjectIntersectionOfGeneralizationFromDomaininAnonymousClass(OWLOntology componentontology, OWLClassExpression classExpression,  ArrayList<Box> boxes, ArrayList<Line> lines, Class newClass){
		if (classExpression.getClassExpressionType().toString().equals("ObjectIntersectionOf")){
			for(OWLClassExpression entity :classExpression.asConjunctSet()){
				if(entity.getClassExpressionType().toString().equals("Class")){
					OWLClass c = (OWLClass) entity;
					createObjectIntersectionOfGeneralizationFromDomainAndRange(boxes, lines, newClass, c);
				}
			}
			
		}
	}
	
	public static void createAnonymousClassFromObjectPropertyDomainAndRange(OWLOntology componentontology, OWLObjectProperty op,  ArrayList<Box> boxes, ArrayList<Line> lines, JsonObject preferences){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		//ManchesterOWLSyntaxPrefixNameShortFormProvider mm = new ManchesterOWLSyntaxPrefixNameShortFormProvider(componentontology);
		
		String domainName = "";
		String rangeName = "";
		ArrayList<String> domains = new ArrayList<String>();
		ArrayList<String> ranges = new ArrayList<String>();
		//System.out.println(componentontology.getObjectPropertyDomainAxioms(op));
		for (OWLObjectPropertyDomainAxiom opd: componentontology.getObjectPropertyDomainAxioms(op)){
			
			Set<OWLAxiom> axioms = null;
			for( OWLClass c : opd.getDomain().getClassesInSignature()){
				if(axioms == null) axioms = componentontology.getReferencingAxioms(c);
				else axioms.retainAll(componentontology.getReferencingAxioms(c));
			}
			Integer count = 0;
			for(OWLAxiom a : axioms){
				if(a.toString().contains(opd.getDomain().toString())) count = count +1;
			}
			domains.add( m.render(opd.getDomain()).replace("\n", "\\n"));
			if(domainName == "") domainName = m.render(opd.getDomain()).replace("\n", "\\n");
			else domainName = domainName + " and " +  m.render(opd.getDomain()).replace("\n", "\\n");
    	}
		//System.out.println(domainName);
		if (domainName!="") {
			Class newClass = createAnonymousClass(boxes, domainName, domains);
			if (getPreferenceParameterProcName("showSubclassesToUnionOfNamed", preferences).equals("")) {
	    		if (getPreferenceParameterValue("showSubclassesToUnionOfNamed", preferences).equals("true")){
	    			createObjectUnionOfGeneralizationFromDomaininObjectProperty(componentontology, op,  boxes, lines, newClass);
	    		}
	    	} else if (calculateParameterProcedure("showSubclassesToUnionOfNamed", preferences).equals("true")) {
	    		createObjectUnionOfGeneralizationFromDomaininObjectProperty(componentontology, op,  boxes, lines, newClass);
	    	} 
			if (getPreferenceParameterProcName("showSubclassesFromAndNamed", preferences).equals("")) {
	    		if (getPreferenceParameterValue("showSubclassesFromAndNamed", preferences).equals("true")){
	    			createObjectIntersectionOfGeneralizationFromDomaininObjectProperty(componentontology, op,  boxes, lines, newClass);
	    		}
	    	} else if (calculateParameterProcedure("showSubclassesFromAndNamed", preferences).equals("true")) {
	    		createObjectIntersectionOfGeneralizationFromDomaininObjectProperty(componentontology, op,  boxes, lines, newClass);
	    	}  
		}
		
    	for (OWLObjectPropertyRangeAxiom opr: componentontology.getObjectPropertyRangeAxioms(op)){
    		ranges.add(m.render(opr.getRange()).replace("\n", "\\n"));
    		if(rangeName == "") rangeName = m.render(opr.getRange()).replace("\n", "\\n");
			else rangeName = rangeName + " and " +  m.render(opr.getRange()).replace("\n", "\\n");
    	}
    	if (rangeName!="") {
    		Class newClass = createAnonymousClass(boxes, rangeName, ranges);
    		if (getPreferenceParameterProcName("showSubclassesToUnionOfNamed", preferences).equals("")) {
	    		if (getPreferenceParameterValue("showSubclassesToUnionOfNamed", preferences).equals("true")){
	    			createObjectUnionOfGeneralizationFromRangeInObjectProperty(componentontology, op,  boxes, lines, newClass);
	    		}
	    	} else if (calculateParameterProcedure("showSubclassesToUnionOfNamed", preferences).equals("true")) {
	    		createObjectUnionOfGeneralizationFromRangeInObjectProperty(componentontology, op,  boxes, lines, newClass);
	    	}  
    		if (getPreferenceParameterProcName("showSubclassesFromAndNamed", preferences).equals("")) {
	    		if (getPreferenceParameterValue("showSubclassesFromAndNamed", preferences).equals("true")){
	    			createObjectIntersectionOfGeneralizationFromRangeInObjectProperty(componentontology, op,  boxes, lines, newClass);
	    		}
	    	} else if (calculateParameterProcedure("showSubclassesFromAndNamed", preferences).equals("true")) {
	    		createObjectIntersectionOfGeneralizationFromRangeInObjectProperty(componentontology, op,  boxes, lines, newClass);
	    	}  
    	}
	}
	
	public static void createAssociation(ArrayList<Line> lines, OWLOntology componentontology, ArrayList<Box> boxes, OWLObjectProperty op, JsonObject preferences, 
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap){ 	

			if(componentontology.getObjectPropertyDomainAxioms(op).isEmpty() && componentontology.getObjectPropertyRangeAxioms(op).isEmpty() && avf == true){
				//atlasit aksiomas kur ir dota propertija
				for(OWLAxiom axiom : componentontology.getReferencingAxioms(op)){
					if(axiom.getAxiomType().toString().equals("SubClassOf")){
						OWLSubClassOfAxiom subClassOf = (OWLSubClassOfAxiom) axiom;
						if(subClassOf.getSuperClass().getClassExpressionType().toString().equals("ObjectAllValuesFrom")){
							for(OWLAnnotationAssertionAxiom aaa : componentontology.getAnnotationAssertionAxioms(op.getIRI())){
								String value = "<" + aaa.getValue().toString() + ">";
								if(aaa.getProperty().getIRI().getShortForm().toString().equals("schema") && value.equals(subClassOf.getSubClass().toString())){
									Association newAssociation = new Association("Association", op); 
									String sourceName = subClassOf.getSubClass().asOWLClass().getIRI().getShortForm();
									String sourceNamespace = subClassOf.getSubClass().asOWLClass().getIRI().getNamespace();
									
									OWLObjectAllValuesFrom oavf = (OWLObjectAllValuesFrom) subClassOf.getSuperClass();
									
									String targetName = oavf.getFiller().asOWLClass().getIRI().getShortForm();
									String targetNamespace = oavf.getFiller().asOWLClass().getIRI().getNamespace();
									
									for(Box b : boxes){
										if(b.getType().equals("Class")){
											Class c = (Class) b;
											if(c.getName().equals(targetName) && c.getNamespace().equals(targetNamespace)) newAssociation.setTarget(c);
											if(c.getName().equals(sourceName) && c.getNamespace().equals(sourceNamespace)) newAssociation.setSource(c);
										}
									}
									if(newAssociation.getSource() != null && newAssociation.getTarget() != null){
										lines.add(newAssociation);
										createAssociationCompartments(newAssociation, op, componentontology, boxes, lines, preferences, userFieldsParameter, prefixesArray, prefixesMap);
									}
								}
							}
						}
					}
				}
				//atstat tikai subClassOf aksiomas
			} else {
				Association newAssociation = new Association("Association", op); 
				
				createAssociationCompartments(newAssociation, op, componentontology, boxes, lines, preferences, userFieldsParameter, prefixesArray, prefixesMap);
				if(newAssociation.getSource() != null && newAssociation.getTarget() != null){
					lines.add(newAssociation);
				}
			}
	}
	
	public static void createClassCompartments(Class newClass, OWLClass co, ArrayList<Compartment> compartments,  OWLOntology componentontology, JsonObject preferences, String[] prefixesArray, Map<String, String> prefixesMap){
		//Name
		String namespace = "";		
		if ((!componentontology.getOntologyID().isAnonymous() 
				&& !co.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
				&& !co.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
				||(componentontology.getOntologyID().isAnonymous()
						&& !co.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = co.getIRI().getNamespace();
		namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		Compartment newCompartment = createNameStructure(co.getIRI().getShortForm().toString(), namespace);
		compartments.add(newCompartment);
		
		//Keys
		 ArrayList<Compartment> keys = new ArrayList<Compartment>();
		if (getPreferenceParameterProcName("showKeys", preferences).equals("")) {
    		if (getPreferenceParameterValue("showKeys", preferences).equals("true")){
    			for(OWLHasKeyAxiom ka : componentontology.getHasKeyAxioms(co)){
    	        	createKeys(keys, ka);
    	        }
    		}
    	} else {
    		for(OWLHasKeyAxiom ka : componentontology.getHasKeyAxioms(co)){
    			if (calculateParameterProcedure("showKeys", preferences).equals("true")) createKeys(keys, ka);
	    	}
    	}   
		createASFictitiousForMultiLineCompartments(keys, compartments, "ASFictitiousKeys"); 
	}
	
	public static void createKeys(ArrayList<Compartment> keys, OWLHasKeyAxiom ka){
		//2 varianti
		/*Compartment keys1 = createCompartment("Keys", "");
    	keys.add(keys1);
    	ArrayList<Compartment> asfkeyArray = new ArrayList<Compartment>();
    	keys1.setSubCompartments(asfkeyArray);
    	Compartment asfkey = createCompartment("ASFictitiousKey", "");
    	asfkey.setIsMultiline(true);
    	asfkeyArray.add(asfkey);
    	ArrayList<Compartment> keyArray = new ArrayList<Compartment>();
    	asfkey.setSubCompartments(keyArray);
    	
    	for (OWLDataProperty dp : ka.getDataPropertiesInSignature()){
    		Compartment key = createCompartment("Key", "");
        	keyArray.add(key);
        	ArrayList<Compartment> keyCompartments= new ArrayList<Compartment>();
        	key.setSubCompartments(keyCompartments);
        	keyCompartments.add(createCompartment("Property", dp.getIRI().getShortForm()));
    	}
    	
    	for (OWLObjectProperty dp : ka.getObjectPropertiesInSignature()){
    		Compartment key = createCompartment("Key", "");
        	keyArray.add(key);
        	ArrayList<Compartment> keyCompartments= new ArrayList<Compartment>();
        	key.setSubCompartments(keyCompartments);
        	keyCompartments.add(createCompartment("Property", dp.getIRI().getShortForm()));
    	}*/
		
		for (OWLDataProperty dp : ka.getDataPropertiesInSignature()){
        	createKey(keys, dp.getIRI().getShortForm());
		}
		for (OWLObjectProperty dp : ka.getObjectPropertiesInSignature()){
        	createKey(keys, dp.getIRI().getShortForm());
		}
		
	}
	
	public static void createKey(ArrayList<Compartment> keys, String property){
		Compartment keys1 = createCompartment("Keys", "");
    	keys.add(keys1);
    	ArrayList<Compartment> asfkeyArray = new ArrayList<Compartment>();
    	keys1.setSubCompartments(asfkeyArray);
    	Compartment asfkey = createCompartment("ASFictitiousKey", "");
    	asfkey.setIsMultiline(true);
    	asfkeyArray.add(asfkey);
    	ArrayList<Compartment> keyArray = new ArrayList<Compartment>();
    	asfkey.setSubCompartments(keyArray);
    	Compartment key = createCompartment("Key", "");
    	keyArray.add(key);
    	ArrayList<Compartment> keyCompartments= new ArrayList<Compartment>();
    	key.setSubCompartments(keyCompartments);
    	keyCompartments.add(createCompartment("Property", property));
	}
	
	public static Individual createIndividual(OWLNamedIndividual individual, ArrayList<Box> boxes, JsonObject preferences, OWLOntology componentontology, String[] prefixesArray, Map<String, String> prefixesMap){
		Individual newIndividual = new Individual(individual, "Object");
		boxes.add(newIndividual);
		
		ArrayList<Compartment> individualCompartments = new ArrayList<Compartment>();
		newIndividual.setCompartments(individualCompartments);
		
		Compartment title = createCompartment("Title", "");
		individualCompartments.add(title);
		
		ArrayList<Compartment> titleCompartments = new ArrayList<Compartment>();
		title.setSubCompartments(titleCompartments);
		
		//Name
		String namespace = "";
		if ((!componentontology.getOntologyID().isAnonymous() 
				&& !individual.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
				&& !individual.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) || (componentontology.getOntologyID().isAnonymous()
						&& !individual.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = individual.getIRI().getNamespace();
		namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		Compartment newCompartment = createNameStructure(individual.getIRI().getShortForm().toString(), namespace);
		titleCompartments.add(newCompartment);
		
		//DataPropertyAssertion
		if (getPreferenceParameterProcName("showIndividualsDataPropertyAssertions", preferences).equals("")) {
    		if (getPreferenceParameterValue("showIndividualsDataPropertyAssertions", preferences).equals("true")){
    			createDataPropertyAssertions(individual,individualCompartments, preferences, componentontology, false);
    		}
    	} else {
    		createDataPropertyAssertions(individual,individualCompartments, preferences, componentontology, true);
    	}
		
		//NegativeDataPropertyAssertion
		if (getPreferenceParameterProcName("showIndividualsNegativeDataPropertyAssertions", preferences).equals("")) {
		     if (getPreferenceParameterValue("showIndividualsNegativeDataPropertyAssertions", preferences).equals("true")){
		    	createNegativeDataPropertyAssertions(individual,individualCompartments, preferences, componentontology, false);
		     }
		} else {
		    createNegativeDataPropertyAssertions(individual,individualCompartments, preferences, componentontology, true);
		}
		
		return newIndividual;
	}
	
	public static void createIndividualLinks(Individual box, ArrayList<Box> boxes, ArrayList<Line> lines,JsonObject preferences, OWLOntology componentontology, String[] prefixesArray,
			Map<String, String> prefixesMap, String linkType){
		ManchesterOWLSyntaxOWLObjectRendererImpl m  = new ManchesterOWLSyntaxOWLObjectRendererImpl();
		OWLIndividual individual = box.getIndividual();
		if (linkType.equals("showIndividualsObjectPropertyAssertions")){
			for (OWLObjectPropertyAssertionAxiom obpras : componentontology.getObjectPropertyAssertionAxioms(individual)){
				for(Box b : boxes){
					if(b.getType().equals("Object")){
						Individual i = (Individual) b;
						if(i.getIndividual().equals(obpras.getObject())){
							Line line = new Line(box, i, "Link");
							lines.add(line);
							String namespace = "";
							if ((!componentontology.getOntologyID().isAnonymous() && 
									!((HasIRI) obpras.getProperty()).getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
									&& !((HasIRI) obpras.getProperty()).getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
									|| (componentontology.getOntologyID().isAnonymous()
											&& !((HasIRI) obpras.getProperty()).getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = ((HasIRI) obpras.getProperty()).getIRI().getNamespace();
							namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
							createIndividualLinkCompartments(line, false, m.render(obpras.getProperty()), namespace);
						}
					}
				}
			}
		}
		if(linkType.equals("showIndividualsNegativeObjectPropertyAssertions")){
			for (OWLNegativeObjectPropertyAssertionAxiom obpras : componentontology.getNegativeObjectPropertyAssertionAxioms(individual)){
				for(Box b : boxes){
					if(b.getType().equals("Object")){
						Individual i = (Individual) b;
						if(i.getIndividual().equals(obpras.getObject())){
							Line line = new Line(box, i, "Link");
							lines.add(line);
							String namespace = "";
							if ((!componentontology.getOntologyID().isAnonymous() 
									&& !((HasIRI) obpras.getProperty()).getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
									&& !((HasIRI) obpras.getProperty()).getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
									|| (componentontology.getOntologyID().isAnonymous()
											&& !((HasIRI) obpras.getProperty()).getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = ((HasIRI) obpras.getProperty()).getIRI().getNamespace();
							namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
							createIndividualLinkCompartments(line, true, m.render(obpras.getProperty()), namespace);
						}
					}
				}
			}
		}
	}
	
	public static void createIndividualLinkCompartments(Line line, Boolean inNegative, String property, String namespace){
		ArrayList<Compartment> compartmentList = new ArrayList<Compartment>();
		line.setCompartments(compartmentList);
		
		Compartment direct = createCompartment("Direct", "");
		compartmentList.add(direct);
		
		ArrayList<Compartment> compartmentListDirect = new ArrayList<Compartment>();
		direct.setSubCompartments(compartmentListDirect);
		
		compartmentListDirect.add(createCompartment("IsNegativeAssertion", inNegative.toString()));
		compartmentListDirect.add(createCompartment("Property", property));
		compartmentListDirect.add(createCompartment("Namespace", namespace));
	}
	
	public static void createClassAttributes(Set<OWLDataProperty> dataProperties, Class newClass, OWLOntology componentontology, ArrayList<Compartment> compartments, JsonObject preferences,
			ArrayList<Line> lines, ArrayList<Box> boxes, ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap, ArrayList<Box> boxesExisting){
		//Attributes

		//dataProperty + objectProperty(as text)
		
		ArrayList<Compartment> attributes = new ArrayList<Compartment>();
    	
		//dataProperties
		if (getPreferenceParameterProcName("showDataProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showDataProperties", preferences).equals("true")) {
				if (getPreferenceParameterProcName("showDataPropertiesType", preferences).equals("")){
					if (getPreferenceParameterValue("showDataPropertiesType", preferences).equals("Graphically") && getPreferenceParameterValue("showDataTypes", preferences).equals("true")){
						for (OWLDataProperty dp : dataProperties) {
							createDataPropertyAttributeGraphically(dp, componentontology, newClass, attributes, preferences, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap, boxesExisting);
						}
					} else {
						for (OWLDataProperty dp : dataProperties) {
							createDataPropertyAttribute(dp, componentontology, newClass, attributes, preferences, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap, boxesExisting);
							createDataPropertyAttributeAllValuesFrom(dp, componentontology, newClass, attributes, preferences, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap);
						}
					}
				}
			}
		} else {
			for (OWLDataProperty dp : dataProperties) {
				if (calculateParameterProcedure("showDataProperties", preferences).equals("true")) createDataPropertyAttribute(dp, componentontology, newClass, attributes, preferences, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap, boxesExisting);
	    	}		
		}
		
		//ObjectProperties
		if (getPreferenceParameterProcName("showObjectPropertiesType", preferences).equals("")){
			if(getPreferenceParameterValue("showObjectPropertiesType", preferences).equals("As text")){
				//find all object properties where domain == given class
				Set <OWLObjectProperty> objectProperties = componentontology.getObjectPropertiesInSignature();
		        for (OWLObjectProperty op: objectProperties) {
		        	createObjectPropertyAttribute(op, componentontology, newClass, attributes, preferences, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap);
		        	createObjectPropertyAttributeAllValuesFrom(op, componentontology, newClass, attributes, preferences, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap);
		        }
			}
		} else {
			//find all object properties where domain == given class
			Set <OWLObjectProperty> objectProperties = componentontology.getObjectPropertiesInSignature();
			for (OWLObjectProperty op: objectProperties) {
				if (calculateParameterProcedure("showObjectPropertiesType", preferences).equals("As text")) createObjectPropertyAttribute(op, componentontology, newClass, attributes, preferences, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap);
	    	}
		}
		
    	//create attributes compartment
    	if (!attributes.isEmpty()){
    		Compartment ASFictitiousAttributes = createCompartment("ASFictitiousAttributes", "");
    		ASFictitiousAttributes.setIsMultiline(true);
    		ASFictitiousAttributes.setSubCompartments(attributes);
    		compartments.add(ASFictitiousAttributes);
    	}
	}
	
	public static void createDataPropertyAttributeGraphically(OWLDataProperty dp, OWLOntology componentontology, Class newClass, ArrayList<Compartment> attributes, JsonObject preferences, ArrayList<Line> lines, 
			ArrayList<Box> boxes, ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap, ArrayList<Box> boxesExisting){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		String domainName = "";
		String domainNamespace = "";
		for (OWLDataPropertyDomainAxiom dpda: componentontology.getDataPropertyDomainAxioms(dp)){
			//domainNamespace = dpda.getDomain().
			if(dpda.getDomain().getSignature().size() == 1) {
				domainNamespace = dpda.getDomain().asOWLClass().getIRI().getNamespace();
			}
			if(domainName == "") domainName = m.render(dpda.getDomain()).replace("\n", "\\n");
			else domainName = domainName + " and " + m.render(dpda.getDomain()).replace("\n", "\\n");
		}
		if(domainName == "") domainName = "Thing";
		
		for(OWLAnnotationAssertionAxiom aa : componentontology.getAnnotationAssertionAxioms(dp.getIRI())){
			if(aa.getProperty().getIRI().getShortForm().toString().equals("schema") && avf == true){
				domainName = "";
			}
		}
		if(newClass.getName().equals(domainName) && (newClass.getNamespace() == null || domainNamespace == "" || newClass.getNamespace().equals(domainNamespace))) {
    	    for (OWLDataPropertyRangeAxiom dpra: componentontology.getDataPropertyRangeAxioms(dp)){
    	    	//showDataTypesLinkToAttributeClasses
    	    	if(dpra.getRange().isDatatype()){
	    	    	String rangeName = dpra.getRange().asOWLDatatype().getIRI().getShortForm();
	    	    	String rangeNamespace = namespaceValue(prefixesArray, dpra.getRange().asOWLDatatype().getIRI().getNamespace(), prefixesMap);
    	    		//ja ir japiesaista klases pie datu tipiem:
	    	    	//if (getPreferenceParameterProcName("showDataTypesLinkToAttributeClasses", preferences).equals("") && getPreferenceParameterProcName("showDataPropertiesType", preferences).equals("")) {
					 //   if (getPreferenceParameterValue("showDataTypesLinkToAttributeClasses", preferences).equals("true") && getPreferenceParameterValue("showDataPropertiesType", preferences).equals("As text")){
					    	Boolean dtExist = false;
					    	//iziet cauri visam kastem
					    	for(Box b: boxesExisting){
					    		//atstat tikai datu tipus	
			    	    		if(b.getType().equals("DataType")){
			    	    			for(Compartment c: b.getCompartments()){
			    	    				if(c.getType().equals("Name")){
			    	    					//salidzinat name un namespace
			    	    					Boolean namesEquals = false;
			    	    					Boolean namespacesEquals = false;
			    	    					for(Compartment nc: c.getSubCompartments()){
			    	    						if(nc.getType().equals("Name") && nc.getValue().equals(rangeName)) namesEquals = true;
			    	    						if(nc.getType().equals("Namespace") && nc.getValue().equals(rangeNamespace)) namespacesEquals = true;
			    	    					}
			    	    					//ja sakrit un ja vel nav izveidota - izveidot saiti
			    	    					if(namesEquals == true && namespacesEquals == true) {//createDataTypeClasslink(lines, newClass, b);
			    	    					
				    	    					String namespace = "";
	
				    	    					if ((!componentontology.getOntologyID().isAnonymous() 
				    	    							&& !dp.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
				    	    							&& !dp.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
				    	    							|| (componentontology.getOntologyID().isAnonymous()
				    	    									&& !dp.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = dp.getIRI().getNamespace();
				    	    					namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
				    	    		    	    createAttributeLink(dp, componentontology, newClass, b, lines, prefixesArray, prefixesMap, preferences, userFieldsParameter);
				    	    		    	    dtExist = true;
			    	    					}
			    	    				}
			    	    			}
			    	    		}
			    	    	}
    	    	//}}
					    if(dtExist == false) createDataPropertyAttribute(dp, componentontology, newClass, attributes, preferences, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap, boxesExisting);
    	    	}
        	} 

    	    
        }
	}
	
	public static void createDataPropertyAttribute(OWLDataProperty dp, OWLOntology componentontology, Class newClass, ArrayList<Compartment> attributes, JsonObject preferences, ArrayList<Line> lines, 
			ArrayList<Box> boxes, ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap, ArrayList<Box> boxesExisting){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		String domainName = "";
		String domainNamespace = "";
		for (OWLDataPropertyDomainAxiom dpda: componentontology.getDataPropertyDomainAxioms(dp)){
			//domainNamespace = dpda.getDomain().
			if(dpda.getDomain().getSignature().size() == 1) {
				domainNamespace = dpda.getDomain().asOWLClass().getIRI().getNamespace();
			}
			if(domainName == "") domainName = m.render(dpda.getDomain()).replace("\n", "\\n");
			else domainName = domainName + " and " + m.render(dpda.getDomain()).replace("\n", "\\n");
		}
		if(domainName == "") domainName = "Thing";
		
		/*for(OWLAnnotationAssertionAxiom aa : componentontology.getAnnotationAssertionAxioms(dp.getIRI())){
			if(aa.getProperty().getIRI().getShortForm().toString().equals("schema") && avf == true){
				domainName = "";
			}
		}*/
		if(newClass.getName().equals(domainName) && (newClass.getNamespace() == null || domainNamespace == "" || newClass.getNamespace().equals(domainNamespace))) {
			String type = null;
			String typeNamespace = "";
    	    for (OWLDataPropertyRangeAxiom dpra: componentontology.getDataPropertyRangeAxioms(dp)){
    	    	//showDataTypesLinkToAttributeClasses
    	    	if(dpra.getRange().isDatatype()){
	    	    	String rangeName = dpra.getRange().asOWLDatatype().getIRI().getShortForm();
	    	    	String rangeNamespace = namespaceValue(prefixesArray, dpra.getRange().asOWLDatatype().getIRI().getNamespace(), prefixesMap);
    	    		//ja ir japiesaista klases pie datu tipiem:
	    	    	if (getPreferenceParameterProcName("showDataTypesLinkToAttributeClasses", preferences).equals("") && getPreferenceParameterProcName("showDataPropertiesType", preferences).equals("")) {
					    if (getPreferenceParameterValue("showDataTypesLinkToAttributeClasses", preferences).equals("true") && getPreferenceParameterValue("showDataPropertiesType", preferences).equals("As text")){
					    	
					    	//iziet cauri visam kastem
					    	for(Box b: boxesExisting){
					    		//atstat tikai datu tipus	
			    	    		if(b.getType().equals("DataType")){
			    	    			for(Compartment c: b.getCompartments()){
			    	    				if(c.getType().equals("Name")){
			    	    					//salidzinat name un namespace
			    	    					Boolean namesEquals = false;
			    	    					Boolean namespacesEquals = false;
			    	    					for(Compartment nc: c.getSubCompartments()){
			    	    						if(nc.getType().equals("Name") && nc.getValue().equals(rangeName)) namesEquals = true;
			    	    						if(nc.getType().equals("Namespace") && nc.getValue().equals(rangeNamespace)) namespacesEquals = true;
			    	    					}
			    	    					//ja sakrit un ja vel nav izveidota - izveidot saiti
			    	    					if(namesEquals == true && namespacesEquals == true) createDataTypeClasslink(lines, newClass, b);
			    	    				}
			    	    			}
			    	    		}
			    	    	}
    	    	}}}
    	    	//showDataTypesLinkToAttributeClasses
    	    	type = m.render(dpra.getRange());
    	    	//System.out.println(dpra.getRange());
    	    	if(dpra.getRange().isDatatype()) typeNamespace  = dpra.getRange().asOWLDatatype().getIRI().getNamespace();
    	    	if (!dpra.getRange().isDatatype() && !type.startsWith("(")) type = "(" + type + ")";
        	} 

    	    String typeNamespaceShort = namespaceValue(prefixesArray, typeNamespace, prefixesMap);
    	    ArrayList<String> xsdTypes =defaultXSDtypes();
    	    if(typeNamespaceShort.equals("xsd")){
    	    	if(xsdTypes.contains(type))typeNamespaceShort = "";
    	    	else typeNamespaceShort = "xsd";
    	    }
    	    String namespace = "";

			if ((!componentontology.getOntologyID().isAnonymous() 
					&& !dp.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
					&& !dp.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
					|| (componentontology.getOntologyID().isAnonymous()
							&& !dp.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = dp.getIRI().getNamespace();
			namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
    	    createClassAttribute(attributes, dp.getIRI().getShortForm().toString(), namespace, type, typeNamespaceShort, "DataProperty", preferences, dp, componentontology, newClass, lines, boxes, userFieldsParameter, prefixesArray,  prefixesMap, false);
        }
	}
	
	public static void createDataTypeClasslink(ArrayList<Line> lines, Box clazz, Box dataType){
		Boolean exists = false;
		for(Line line : lines){
			if(line.getType().equals("ConnectorDataType") && line.getSource().equals(clazz) && line.getTarget().equals(dataType)){
				exists = true;
				break;
			}
		}
		if(exists != true){
			Line line = new Line(clazz, dataType, "ConnectorDataType");
			lines.add(line);
		}
	}
	
	public static ArrayList<String> defaultXSDtypes(){
		ArrayList<String> xsdTypes = new ArrayList<String>();
		xsdTypes.add("NCName");
		xsdTypes.add("NMTOKEN");
		xsdTypes.add("Name");
		xsdTypes.add("anyURI");
		xsdTypes.add("base64Binary");
		xsdTypes.add("boolean");
		xsdTypes.add("byte");
		xsdTypes.add("dateTime");
		xsdTypes.add("dataTimeStamp");
		xsdTypes.add("decimal");
		xsdTypes.add("double");
		xsdTypes.add("float");
		xsdTypes.add("hexBinary");
		xsdTypes.add("int");
		xsdTypes.add("integer");
		xsdTypes.add("language");
		xsdTypes.add("long");
		xsdTypes.add("negativeInteger");
		xsdTypes.add("nonNegativeInteger");
		xsdTypes.add("nonPositiveInteger");
		xsdTypes.add("normalizedString");
		xsdTypes.add("positiveInteger");
		xsdTypes.add("short");
		xsdTypes.add("string");
		xsdTypes.add("token");
		xsdTypes.add("unsignedByte");
		xsdTypes.add("unsignedInt");
		xsdTypes.add("unsignedLong");
		xsdTypes.add("unsignedShort");
		xsdTypes.add("date");
		xsdTypes.add("time");

		return xsdTypes;
	}
	
	public static void createDataPropertyAttributeAllValuesFrom(OWLDataProperty dp, OWLOntology componentontology, Class newClass, ArrayList<Compartment> attributes, JsonObject preferences, ArrayList<Line> lines, 
			ArrayList<Box> boxes, ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap){
		ManchesterOWLSyntaxOWLObjectRendererImpl m = new ManchesterOWLSyntaxOWLObjectRendererImpl();
		// schema is, domain no = +
		// schema no, domain is = !
		// schema is, domain is = 
		if(avf == true){
			for(OWLAnnotationAssertionAxiom aa : componentontology.getAnnotationAssertionAxioms(dp.getIRI())){
				if(aa.getProperty().getIRI().getShortForm().toString().equals("schema") && 
						aa.getValue().asIRI().get().getShortForm().equals(newClass.getName()) &&
						(newClass.getNamespace() == null || aa.getValue().asIRI().get().getNamespace().toString().equals(newClass.getNamespace()))
						&& componentontology.getDataPropertyDomainAxioms(dp).isEmpty()){
					String type = null;
					for(OWLSubClassOfAxiom subClass : componentontology.getSubClassAxiomsForSubClass(newClass.getOwlClass())){
						if(subClass.getSuperClass().getClassExpressionType().toString().equals("DataAllValuesFrom")){
							OWLDataAllValuesFrom davf = (OWLDataAllValuesFrom) subClass.getSuperClass();
							if(dp.equals(davf.getProperty())){
								type = m.render(davf.getFiller());
							}
						}
					} 
			    	String namespace = "";
				    if ((!componentontology.getOntologyID().isAnonymous() 
				    		&& !dp.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
				    		&& !dp.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
				    		|| (componentontology.getOntologyID().isAnonymous() 
				    				&& !dp.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = dp.getIRI().getNamespace();
				    namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
			    	createClassAttribute(attributes, dp.getIRI().getShortForm().toString(), namespace, type,"", "DataProperty", preferences, dp, componentontology, newClass, lines, boxes, userFieldsParameter, prefixesArray,  prefixesMap, true);      
				}
			}
		}
	}
	
	public static void createObjectPropertyAttributeAllValuesFrom(OWLObjectProperty dp, OWLOntology componentontology, Class newClass, ArrayList<Compartment> attributes, JsonObject preferences, ArrayList<Line> lines, 
			ArrayList<Box> boxes, ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap){
		ManchesterOWLSyntaxOWLObjectRendererImpl m = new ManchesterOWLSyntaxOWLObjectRendererImpl();
		if(avf == true){
			for(OWLAnnotationAssertionAxiom aa : componentontology.getAnnotationAssertionAxioms(dp.getIRI())){
				if(aa.getProperty().getIRI().getShortForm().toString().equals("schema") 
						&& aa.getValue().asIRI().get().getShortForm().equals(newClass.getName())
						&& (newClass.getNamespace() == null || aa.getValue().asIRI().get().getNamespace().toString().equals(newClass.getNamespace()))
						&& componentontology.getObjectPropertyDomainAxioms(dp).isEmpty()){
					String type = null;
					for(OWLSubClassOfAxiom subClass : componentontology.getSubClassAxiomsForSubClass(newClass.getOwlClass())){
						if(subClass.getSuperClass().getClassExpressionType().toString().equals("ObjectAllValuesFrom")){
							OWLObjectAllValuesFrom davf = (OWLObjectAllValuesFrom) subClass.getSuperClass();
							if(dp.equals(davf.getProperty())){
								type = m.render(davf.getFiller());
							}
						}
					} 
			    	String namespace = "";
				    if ((!componentontology.getOntologyID().isAnonymous() 
				    		&& !dp.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
				    		&& !dp.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))
				    		|| (componentontology.getOntologyID().isAnonymous() 
				    				&& !dp.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = dp.getIRI().getNamespace();
				    namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
				    createClassAttribute(attributes, dp.getIRI().getShortForm().toString(), namespace, type, "", "ObjectProperty", preferences, dp, componentontology, newClass, lines, boxes, userFieldsParameter, prefixesArray,  prefixesMap, true);      
				}
			}
		}
	}
	
	public static void createObjectPropertyAttribute(OWLObjectProperty op, OWLOntology componentontology, Class newClass, ArrayList<Compartment> attributes, JsonObject preferences, ArrayList<Line> lines,
			ArrayList<Box> boxes, ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		for(OWLObjectPropertyDomainAxiom opda: componentontology.getObjectPropertyDomainAxioms(op)){
			String domainNamespace = "";
			if(opda.getDomain().getSignature().size() == 1){
				domainNamespace = opda.getDomain().asOWLClass().getIRI().getNamespace();
			}
			if (newClass.getName().equals(m.render(opda.getDomain()).replace("\n", "\\n")) && (
					newClass.getNamespace() == null || domainNamespace.equals("") || newClass.getNamespace().equals(domainNamespace))) {
    	        String type = null;
				for (OWLObjectPropertyRangeAxiom opra: componentontology.getObjectPropertyRangeAxioms(op)) {
		    		type = m.render(opra.getRange()).replace("\n", "\\n");
		    		if (!opra.getRange().isClassExpressionLiteral() && !type.startsWith("(")) type = "(" + type + ")";
		    	}
				String namespace = "";
				if ((!componentontology.getOntologyID().isAnonymous() 
						&& !op.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
						&& !op.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))
						|| (componentontology.getOntologyID().isAnonymous() 
								&& !op.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = op.getIRI().getNamespace();
				namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
				createClassAttribute(attributes, op.getIRI().getShortForm().toString(), namespace, type, "", "ObjectProperty", preferences, op, componentontology, newClass, lines, boxes, userFieldsParameter, prefixesArray, prefixesMap, false);
			}
	    }
	}
	
	public static void createAttributeLink(OWLDataProperty property, OWLOntology componentontology, Class newClass, Box b, ArrayList<Line> lines, String[] prefixesArray, 
			Map<String, String> prefixesMap, JsonObject preferences, ArrayList<UserFieldsParameter> userFieldsParameter){
		
		Line line = new Line(newClass, b, "Attribute");
		lines.add(line);
		
		String namespace = "";
		
		if ((!componentontology.getOntologyID().isAnonymous() 
				&& !property.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
				&& !property.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
				|| (componentontology.getOntologyID().isAnonymous()
						&& !property.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = property.getIRI().getNamespace();
		namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		
		
		//Attribute compartments
				ArrayList<Compartment> attrCompartments = new ArrayList<Compartment>();
		        line.setCompartments(attrCompartments);
		        //Name
				Compartment newAttrCompartment = createNameStructure(property.getIRI().getShortForm(), namespace);
		        attrCompartments.add(newAttrCompartment);
		        
		        //Rest compartments
		        createAttributeDataPropertyCompartments(attrCompartments, componentontology,  preferences,  (OWLProperty)property, newClass);
	
		        //Annotation
		        if (getPreferenceParameterProcName("showDataPropertyAnnotations", preferences).equals("")){
					if (getPreferenceParameterValue("showDataPropertyAnnotations", preferences).equals("true")) {
						//if (getPreferenceParameterValue("showDataPropertyAnnotations", preferences).equals("As text")) {
		        			createAttributeAnnotationsAsText((OWLDataProperty) property, componentontology, attrCompartments, false, preferences, userFieldsParameter, prefixesArray, prefixesMap, false, newClass.getName());
		        		//}
		        		// attribute Annotations Graphically
		        		//else if (getPreferenceParameterValue("showDataPropertiesAnnotationType", preferences).equals("Graphically")) createAttributeAnnotationsGraphically((OWLDataProperty) property, componentontology, attrCompartments, newClass, lines, boxes, false, null, userFieldsParameter, prefixesArray, prefixesMap, isAllValuesFrom, newClass.getName());
		        	}
		    	} else {
		    		//TODO attribute Annotations by procName
		    		//createClassAnnotationsAsText((Class) box, componentontology, box.getCompartments(), true, preferences);
		    		//createClassAnnotationsGraphically((Class) box, componentontology, needToBeAddedToBoxes, lines, true, preferences);
				}
	}
	
	public static void createClassAttribute(ArrayList<Compartment> attributes, String name, String namespace, String type, String typeNamespace, String attributeType, 
			JsonObject preferences, OWLProperty property, OWLOntology componentontology, Class newClass, ArrayList<Line> lines, ArrayList<Box> boxes, 
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap, Boolean isAllValuesFrom){
		Compartment attribute = new Compartment("Attributes", "");
		attributes.add(attribute);
		//Attribute compartments
		ArrayList<Compartment> attrCompartments = new ArrayList<Compartment>();
        	
        //Name
		Compartment newAttrCompartment = createNameStructure(name, namespace);
        attrCompartments.add(newAttrCompartment);

        //Type range
        if (type != null){
	        Compartment newAttrCompartmentType = createCompartment("Type", "");
	        Compartment newAttrCompartmentType2 = createCompartment("Type", type);
	        Compartment newAttrCompartmentTypeNamespace = createCompartment("Namespace", typeNamespace);
	        attrCompartments.add(newAttrCompartmentType);
	        ArrayList<Compartment> typeCompartments = new ArrayList<Compartment>();
	        typeCompartments.add(newAttrCompartmentType2);
	        typeCompartments.add(newAttrCompartmentTypeNamespace);
	        newAttrCompartmentType.setSubCompartments(typeCompartments);
        }
        
        //AllValuesFrom
        if(isAllValuesFrom)attrCompartments.add(createCompartment("allValuesFrom", "true"));
        
        //noSchema
        if(avf == true && isAllValuesFrom != true && !getPreferenceParameterValue("addSchemaAssertionsToDomainAssertions", preferences).equals("true")){
	        Boolean isSchema = false;
        	for(OWLAnnotationAssertionAxiom aa : componentontology.getAnnotationAssertionAxioms(property.getIRI())){
				if(aa.getProperty().getIRI().getShortForm().toString().equals("schema")){
					isSchema = true;
				}
			}
        	if(isSchema != true) attrCompartments.add(createCompartment("noSchema", "true"));
        }
        //Rest compartments
        if (attributeType == "DataProperty") {
        	createAttributeDataPropertyCompartments(attrCompartments, componentontology,  preferences,  property, newClass);
        } else {
        	createAttributeObjectPropertyCompartments(attrCompartments, componentontology,  preferences,  property, newClass);
        }
        //Annotation
        if (getPreferenceParameterProcName("show" + attributeType + "Annotations", preferences).equals("")){
			if (getPreferenceParameterValue("show" + attributeType + "Annotations", preferences).equals("true")) {
				if (attributeType.equals("DataProperty")) attributeType = "showDataPropertiesAnnotationType";
				else attributeType = "showObjectPropertyAnnotationsType";
				if (getPreferenceParameterValue(attributeType, preferences).equals("As text")) {
        			if (attributeType.equals("showObjectPropertyAnnotationsType")) createAssociationAnnotationsAsText((OWLObjectProperty) property, componentontology, attrCompartments, false, preferences, userFieldsParameter, prefixesArray, prefixesMap, isAllValuesFrom, newClass.getName());
        			else createAttributeAnnotationsAsText((OWLDataProperty) property, componentontology, attrCompartments, false, preferences, userFieldsParameter, prefixesArray, prefixesMap, isAllValuesFrom, newClass.getName());
        		}
        		// attribute Annotations Graphically
        		else if (getPreferenceParameterValue("showDataPropertiesAnnotationType", preferences).equals("Graphically")) createAttributeAnnotationsGraphically((OWLDataProperty) property, componentontology, attrCompartments, newClass, lines, boxes, false, preferences, userFieldsParameter, prefixesArray, prefixesMap, isAllValuesFrom, newClass.getName());
        	}
    	} else {
    		//TODO attribute Annotations by procName
    		//createClassAnnotationsAsText((Class) box, componentontology, box.getCompartments(), true, preferences);
    		//createClassAnnotationsGraphically((Class) box, componentontology, needToBeAddedToBoxes, lines, true, preferences);
		}
        
        attribute.setSubCompartments(attrCompartments);
	}
	
	public static void createAttributeObjectPropertyCompartments(ArrayList<Compartment> attrCompartments, OWLOntology componentontology, JsonObject preferences, OWLProperty property, Class newClass){
		//Super properties
        if (getPreferenceParameterProcName("showObjectPropertiesSuperProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertiesSuperProperties", preferences).equals("true")) {
        		createSubProperties(false, componentontology, property.asOWLObjectProperty(), null, attrCompartments);
        	}
    	} else {
    		createSubProperties(true, componentontology, property.asOWLObjectProperty(), preferences, attrCompartments);
		}
        
        //equivalent properties
        if (getPreferenceParameterProcName("showObjectPropertiesEquivalentProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertiesEquivalentProperties", preferences).equals("true")) {
        		createDataPropertyEquivalentObjectProperty((OWLObjectProperty) property, componentontology, attrCompartments, false, null);
        	}
    	} else {
    		createDataPropertyEquivalentObjectProperty((OWLObjectProperty) property, componentontology, attrCompartments, true, preferences);	
		}
        
        //disjoint properties
        if (getPreferenceParameterProcName("showObjectPropertiesDisjointProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertiesDisjointProperties", preferences).equals("true")) {
				createDataPropertyDisjointObjectProperty((OWLObjectProperty) property, componentontology, attrCompartments, false, null);
        	}
    	} else {
    		createDataPropertyDisjointObjectProperty((OWLObjectProperty) property, componentontology, attrCompartments, true, preferences);	
		}
        
        //is functional
        if (getPreferenceParameterProcName("showObjectPropertiesIsFunctional", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertiesIsFunctional", preferences).equals("true")) {
				OWLObjectProperty dp = (OWLObjectProperty) property;
				if (!componentontology.getFunctionalObjectPropertyAxioms(dp).isEmpty())createObjectPropertyCompartments(attrCompartments, "IsFunctional", "showObjectPropertiesIsFunctional", false, null);
        	}
    	} else {
    		createObjectPropertyCompartments(attrCompartments, "IsFunctional", "showObjectPropertiesIsFunctional", true, preferences);
    	}
        
      //multiplisity
        if (getPreferenceParameterProcName("showPropertyRestrictions", preferences).equals("") && getPreferenceParameterProcName("showObjectCardinalityRestrictionsAsMultiplicity", preferences).equals("")){
			if (getPreferenceParameterValue("showPropertyRestrictions", preferences).equals("true") && getPreferenceParameterValue("showObjectCardinalityRestrictionsAsMultiplicity", preferences).equals("true")) {
				OWLObjectProperty op = (OWLObjectProperty) property;
				createObjectPropertyAsTextMultiplisity(op, newClass, attrCompartments, componentontology);
        	}
    	} else {
    		
    	}
	}
	
	public static void createAttributeDataPropertyCompartments(ArrayList<Compartment> attrCompartments, OWLOntology componentontology, JsonObject preferences, OWLProperty property, Class newClass){
		//Super properties
        if (getPreferenceParameterProcName("showDataPropertiesSuperProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showDataPropertiesSuperProperties", preferences).equals("true")) {
        		createDataPropertySuperProperty((OWLDataProperty) property, componentontology, attrCompartments, false, null);
        	}
    	} else {
    		createDataPropertySuperProperty((OWLDataProperty) property, componentontology, attrCompartments, true, preferences);	
		}
        
        //equivalent properties
        if (getPreferenceParameterProcName("showDataPropertiesEquivalentProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showDataPropertiesEquivalentProperties", preferences).equals("true")) {
        		createDataPropertyEquivalentProperty((OWLDataProperty) property, componentontology, attrCompartments, false, null);
        	}
    	} else {
    		createDataPropertyEquivalentProperty((OWLDataProperty) property, componentontology, attrCompartments, true, preferences);	
		}
        
        //disjoint properties
        if (getPreferenceParameterProcName("showDataPropertiesDisjointProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showDataPropertiesDisjointProperties", preferences).equals("true")) {
        		createDataPropertyDisjointProperty((OWLDataProperty) property, componentontology, attrCompartments, false, null);
        	}
    	} else {
    		createDataPropertyDisjointProperty((OWLDataProperty) property, componentontology, attrCompartments, true, preferences);	
		}
        
        //is functional
        if (getPreferenceParameterProcName("showDataPropertiesIsFunctional", preferences).equals("")){
			if (getPreferenceParameterValue("showDataPropertiesIsFunctional", preferences).equals("true")) {
				OWLDataProperty dp = (OWLDataProperty) property;
				if (!componentontology.getFunctionalDataPropertyAxioms(dp).isEmpty()) createObjectPropertyCompartments(attrCompartments, "IsFunctional", "showDataPropertiesIsFunctional", false, null);
        	}
    	} else {
    		createObjectPropertyCompartments(attrCompartments, "IsFunctional", "showDataPropertiesIsFunctional", true, preferences);
    	}
        
        //multiplisity
        if (getPreferenceParameterProcName("showPropertyRestrictions", preferences).equals("") && getPreferenceParameterProcName("showDataCardinalityRestrictionsAsMultiplicity", preferences).equals("")){
			if (getPreferenceParameterValue("showPropertyRestrictions", preferences).equals("true") && getPreferenceParameterValue("showDataCardinalityRestrictionsAsMultiplicity", preferences).equals("true")) {
				OWLDataProperty dp = (OWLDataProperty) property;
				createDataPropertyMultiplisity(dp, newClass, attrCompartments, componentontology);
        	}
    	} else {
    		
    	}
        
        //allValuesFrom
      // attrCompartments.add(createCompartment("allValuesFrom", "true"));
      		
	}
	
	public static void createObjectPropertyAsTextMultiplisity(OWLObjectProperty op, Class newClass, ArrayList<Compartment> attrCompartments, OWLOntology componentontology){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		String minC = "";
		String maxC = "";
		
		for(OWLSubClassOfAxiom subClass: componentontology.getSubClassAxiomsForSubClass(newClass.getOwlClass())){
			if (!subClass.getObjectPropertiesInSignature().isEmpty() && subClass.getObjectPropertiesInSignature().contains(op) && m.render(subClass).contains("exactly")){
				OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClass.getSuperClass();
				String cardinality = Integer.toString(cr.getCardinality());
				if (defaultMaxCardinality == true && !cardinality.isEmpty() && cardinality.equals("0")) cardinality = "0..1";
				Compartment multiplisity = createCompartment("Multiplicity", cardinality);
				attrCompartments.add(multiplisity);
			}
			if (!subClass.getObjectPropertiesInSignature().isEmpty() && subClass.getObjectPropertiesInSignature().contains(op) && m.render(subClass).contains("min")){
				OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClass.getSuperClass();
				minC = Integer.toString(cr.getCardinality());
			}
			if (!subClass.getObjectPropertiesInSignature().isEmpty() && subClass.getObjectPropertiesInSignature().contains(op) && m.render(subClass).contains("max")){
				OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClass.getSuperClass();
				maxC = Integer.toString(cr.getCardinality());
			}
		}
		
		if(defaultMaxCardinality == true && minC.equals("0") && maxC.equals("0")){maxC = "1"; minC = "0";}
		if(defaultMaxCardinality == true && minC.equals("") && maxC.equals("0")) {maxC = "1"; minC = "0";}
		if(defaultMaxCardinality == true && minC.equals("") && maxC.equals(""))  {maxC = "1"; minC = "0";}
		if(defaultMaxCardinality == true && !minC.equals("") && !maxC.equals("") && Integer.parseInt(minC) > Integer.parseInt(maxC))  {maxC = "1"; minC = "0";}
		
		String cardinality = createMultiplisityValue(minC, maxC);
		if(cardinality!=""){
			Compartment multiplisity = createCompartment("Multiplicity", cardinality);
			attrCompartments.add(multiplisity);
		}
	}
	
	public static String getTypeFromMultiplisity(OWLCardinalityRestriction cr){
		String type = "";
		for(OWLDatatype dataType : cr.getFiller().getDatatypesInSignature()){
			type = dataType.getIRI().getShortForm();
		}
		return type;
	}
	
	public static void createDataPropertyMultiplisity(OWLDataProperty dp, Class newClass, ArrayList<Compartment> attrCompartments, OWLOntology componentontology){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		String minC = "";
		String maxC = "";
		String type = "";
		Boolean typeExists = false;
		for (Compartment c: attrCompartments){
			if(c.getType().equals("Type")) {
				typeExists = true;
				break;
			}
		}
		//
		for(OWLSubClassOfAxiom subClass: componentontology.getSubClassAxiomsForSubClass(newClass.getOwlClass())){
			//if (!subClass.getDataPropertiesInSignature().isEmpty() && subClass.getDataPropertiesInSignature().contains(dp) && m.render(subClass).contains("exactly")){
			if (!subClass.getDataPropertiesInSignature().isEmpty() && subClass.getDataPropertiesInSignature().contains(dp) && subClass.getSuperClass().getClassExpressionType().toString().equals("DataExactCardinality")){
				OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClass.getSuperClass();
				String cardinality = Integer.toString(cr.getCardinality());
				if (defaultMaxCardinality == true && !cardinality.isEmpty() && cardinality.equals("0")) cardinality = "0..1";
				Compartment multiplisity = createCompartment("Multiplicity", cardinality);
				attrCompartments.add(multiplisity);
				if(typeExists == false) type = getTypeFromMultiplisity(cr);
			}
			//if (!subClass.getDataPropertiesInSignature().isEmpty() && subClass.getDataPropertiesInSignature().contains(dp) && m.render(subClass).contains("min")){
			if (!subClass.getDataPropertiesInSignature().isEmpty() && subClass.getDataPropertiesInSignature().contains(dp) && subClass.getSuperClass().getClassExpressionType().toString().equals("DataMinCardinality")){
				OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClass.getSuperClass();
				minC = Integer.toString(cr.getCardinality());
				if(typeExists == false) type = getTypeFromMultiplisity(cr);
			}
			//if (!subClass.getDataPropertiesInSignature().isEmpty() && subClass.getDataPropertiesInSignature().contains(dp) && m.render(subClass).contains("max")){
			if (!subClass.getDataPropertiesInSignature().isEmpty() && subClass.getDataPropertiesInSignature().contains(dp) && subClass.getSuperClass().getClassExpressionType().toString().equals("DataMaxCardinality")){
				OWLCardinalityRestriction cr = (OWLCardinalityRestriction) subClass.getSuperClass();
				maxC = Integer.toString(cr.getCardinality());
				if(typeExists == false) type = getTypeFromMultiplisity(cr);
			}
		}

		if(defaultMaxCardinality == true && minC.equals("0") && maxC.equals("0")){maxC = "1"; minC = "0";}
		if(defaultMaxCardinality == true && minC.equals("") && maxC.equals("0")) {maxC = "1"; minC = "0";}
		if(defaultMaxCardinality == true && minC.equals("") && maxC.equals(""))  {maxC = "1"; minC = "0";}
		if(defaultMaxCardinality == true && !minC.equals("") && !maxC.equals("") && Integer.parseInt(minC) > Integer.parseInt(maxC))  {maxC = "1"; minC = "0";}

		String cardinality = createMultiplisityValue(minC, maxC);
		
		if(cardinality!=""){
			Compartment multiplisity = createCompartment("Multiplicity", cardinality);
			attrCompartments.add(multiplisity);
		}
		if(typeExists == false) {
			Compartment typeC = createCompartment("Type", type);
			attrCompartments.add(typeC);
		}
	}
	
	public static void createAssociationCompartments(Association newAssociation,  OWLObjectProperty op, OWLOntology componentontology, ArrayList<Box> boxes, ArrayList<Line> lines, JsonObject preferences,
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap){
		newAssociation.setName(op.getIRI().getShortForm().toString());
		newAssociation.setNamespace(op.getIRI().getNamespace().toString());
		//find source and target
		if(newAssociation.getSource() == null)setAssociationSource(componentontology, boxes, newAssociation, op, preferences);
		Compartment allValuesFrom = null;
		if(newAssociation.getTarget() == null) allValuesFrom = setAssociationTarget(componentontology, boxes, newAssociation, op, preferences);
		else allValuesFrom = new Compartment("allValuesFrom", "true");
		//compartment structure
		
		ArrayList<Compartment> compartments = new ArrayList<Compartment>();
		
		Compartment newCompartment = createCompartment("Role", "");
		compartments.add(newCompartment);
		
		ArrayList<Compartment> newSubCompartments = new ArrayList<Compartment>();
		Boolean isAllValuesFrom = false;
		if(allValuesFrom != null) {
			newSubCompartments.add(allValuesFrom);
			isAllValuesFrom = true;
		} else {
			if(avf == true && !getPreferenceParameterValue("addSchemaAssertionsToDomainAssertions", preferences).equals("true")){
		        Boolean isSchema = false;
	        	for(OWLAnnotationAssertionAxiom aa : componentontology.getAnnotationAssertionAxioms(op.getIRI())){
					if(aa.getProperty().getIRI().getShortForm().toString().equals("schema")){
						isSchema = true;
					}
				}
	        	if(isSchema != true) newSubCompartments.add(createCompartment("noSchema", "true"));
	        }
		}
		String namespace = "";
		if ((!componentontology.getOntologyID().isAnonymous() 
				&& !op.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
				&& !op.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))
				||(componentontology.getOntologyID().isAnonymous() 
						&& !op.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = op.getIRI().getNamespace();
		
		namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		Compartment newSubCompartment = createNameStructure(op.getIRI().getShortForm().toString(), namespace);	
		newSubCompartments.add(newSubCompartment);
		
		newCompartment.setSubCompartments(newSubCompartments);

		//Annotations
		if (getPreferenceParameterProcName("showObjectPropertyAnnotations", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertyAnnotations", preferences).equals("true")) {
        		String source = "";
        		if((Class) newAssociation.getSource() != null) source = ((Class) newAssociation.getSource()).getName();
				if (getPreferenceParameterValue("showObjectPropertyAnnotationsType", preferences).equals("As text")) createAssociationAnnotationsAsText(newAssociation.getOwlObjectProperty(), componentontology, newSubCompartments, false, preferences, userFieldsParameter, prefixesArray, prefixesMap, isAllValuesFrom, source);
        		else if (getPreferenceParameterValue("showObjectPropertyAnnotationsType", preferences).equals("Graphically")) createAssociationAnnotationsGraphically(newAssociation.getOwlObjectProperty(), newAssociation, componentontology, lines, boxes,  false, preferences, userFieldsParameter, newSubCompartments, prefixesArray, prefixesMap, isAllValuesFrom, ((Class) newAssociation.getSource()).getName());
        	}
    	} else {
    		createAssociationAnnotationsAsText(newAssociation.getOwlObjectProperty(), componentontology, newSubCompartments, true, preferences, userFieldsParameter, prefixesArray, prefixesMap, isAllValuesFrom, ((Class) newAssociation.getSource()).getName());
    		createAssociationAnnotationsGraphically(newAssociation.getOwlObjectProperty(), newAssociation, componentontology, lines, boxes,  true, preferences, userFieldsParameter, newSubCompartments, prefixesArray, prefixesMap, isAllValuesFrom, ((Class) newAssociation.getSource()).getName());
		}
		
		
		//super properties
		if (getPreferenceParameterProcName("showObjectPropertiesSuperProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertiesSuperProperties", preferences).equals("true")) {
        		createSubProperties(false, componentontology, op, null, newSubCompartments);
        	}
    	} else {
    		createSubProperties(true, componentontology, op, preferences, newSubCompartments);
		}
		
		//disjoint properties
		if (getPreferenceParameterProcName("showObjectPropertiesDisjointProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertiesDisjointProperties", preferences).equals("true")) {
		       	createDisjointObjectProperties(false, componentontology, op, null, newSubCompartments);
		    }
		} else {
			createDisjointObjectProperties(true, componentontology, op, preferences, newSubCompartments);
	    }
		
		//equivalent properties
		if (getPreferenceParameterProcName("showObjectPropertiesEquivalentProperties", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertiesEquivalentProperties", preferences).equals("true")) {
				createEquivalentObjectProperties(false, componentontology, op, null, newSubCompartments);
			}
		} else {
			createEquivalentObjectProperties(true, componentontology, op, preferences, newSubCompartments);
		}
		
		//Multiplicity 
		if (getPreferenceParameterProcName("showObjectCardinalityRestrictionsAsMultiplicity", preferences).equals("")){
				if (getPreferenceParameterValue("showObjectCardinalityRestrictionsAsMultiplicity", preferences).equals("true")) {
					createMultiplisity(componentontology, newAssociation, newSubCompartments);
				}
		} else {
					
	    }
		
		// property chains 
        if (getPreferenceParameterProcName("showObjectPropertiesPropertyChains", preferences).equals("")){
			if (getPreferenceParameterValue("showObjectPropertiesPropertyChains", preferences).equals("true")) {
				createObjectPropertiesPropertyChains(op, componentontology, newSubCompartments, false, null, prefixesArray, prefixesMap);
        	}
    	} else {
    		createObjectPropertiesPropertyChains(op, componentontology, newSubCompartments, true, preferences, prefixesArray, prefixesMap);	
		}
		
		//ExtraItems
		String[] opExtraItems = {"Functional", "InverseFunctional", "Symmetric", "Asymmetric", "Reflexive", "Irreflexive", "Transitive"};
		String[] opExtraParameters = {"showObjectPropertiesIsFunctional", "showObjectPropertiesIsInverseFunctional", "showObjectPropertiesIsSymmetric", "showObjectPropertiesIsAsymmetric", "showObjectPropertiesIsReflexive", "showObjectPropertiesIsIrreflexive", "showObjectPropertiesIsTransitive"};
		Boolean[] opExtraItemPresent = {
				componentontology.getFunctionalObjectPropertyAxioms(op).isEmpty(),
				componentontology.getInverseFunctionalObjectPropertyAxioms(op).isEmpty(),
				componentontology.getSymmetricObjectPropertyAxioms(op).isEmpty(),
				componentontology.getAsymmetricObjectPropertyAxioms(op).isEmpty(),
				componentontology.getReflexiveObjectPropertyAxioms(op).isEmpty(),
				componentontology.getIrreflexiveObjectPropertyAxioms(op).isEmpty(),
				componentontology.getTransitiveObjectPropertyAxioms(op).isEmpty(),
				};
		
		for (int i=0; i<opExtraItems.length; i++)
        {

            if (getPreferenceParameterProcName(opExtraParameters[i], preferences).equals("")){
    			if (getPreferenceParameterValue(opExtraParameters[i], preferences).equals("true")) {
    				if (!opExtraItemPresent[i]){
    					createObjectPropertyCompartments(newSubCompartments, opExtraItems[i], opExtraParameters[i], false, null);
    				}
    		    }
    		} else {
    			createObjectPropertyCompartments(newSubCompartments, opExtraItems[i], opExtraParameters[i], true, preferences);
    		}
        }
		
		newAssociation.setCompartments(compartments);
	}
	
	public static void createObjectPropertyCompartments(ArrayList<Compartment> compartments, String type, String parameter, Boolean calcProc, JsonObject preferences){
		if (calcProc == false) {
			Compartment newCompartment = createCompartment(type, "true");
			compartments.add(newCompartment);
    	} else {
    		if (calculateParameterProcedure(parameter, preferences).equals("true")){
    			Compartment newCompartment = createCompartment(type, "true");
    			compartments.add(newCompartment);
        	}
    	}
	}
	
	public static Compartment createNameStructure(String name, String namespace){
		//Name
    	Compartment newCompartment = createCompartment("Name", "");

    	//Name Namespace
    	ArrayList<Compartment> subCompartments = new ArrayList<Compartment>();
    	subCompartments.add(createCompartment("Name", name));
    	subCompartments.add(createCompartment("Namespace", namespace));
    	newCompartment.setSubCompartments(subCompartments);
    	return newCompartment;
	}
	
	public static void setAssociationSource(OWLOntology componentontology, ArrayList<Box> boxes, Association newAssociation, OWLObjectProperty op, JsonObject preferences){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		String domainName = "";
		String domainNamespace = "";
		for(OWLObjectPropertyDomainAxiom opda: componentontology.getObjectPropertyDomainAxioms(op)){
			if (domainName == "") domainName = m.render(opda.getDomain()).replace("\n", "\\n");
			else domainName = domainName + " and " + m.render(opda.getDomain()).replace("\n", "\\n");
			if(opda.getDomain().getSignature().size() == 1 && !opda.getDomain().getClassExpressionType().toString().equals("ObjectUnionOf")){

				domainNamespace = opda.getDomain().asOWLClass().getIRI().getNamespace();
			}
		}
		if (domainName == "") domainName = "Thing";
		
		if(avf == true){
			for(OWLClass clazz: componentontology.getClassesInSignature()){
				for(OWLSubClassOfAxiom sc: componentontology.getSubClassAxiomsForSubClass(clazz)){
					if(sc.getSuperClass().getClassExpressionType().toString().equals("ObjectAllValuesFrom")){
						OWLObjectAllValuesFrom oavf = (OWLObjectAllValuesFrom) sc.getSuperClass();
						if(oavf.getProperty().equals(op)){
							for(OWLAnnotationAssertionAxiom aa:componentontology.getAnnotationAssertionAxioms(op.getIRI())){
								if(aa.getProperty().getIRI().getShortForm().toString().equals("schema")) domainName = m.render(sc.getSubClass());
							}
						}
					}
				}
			}
		}
		
		/*for(OWLAnnotationAssertionAxiom aa : componentontology.getAnnotationAssertionAxioms(op.getIRI())){
			if(aa.getProperty().getIRI().getShortForm().toString().equals("schema")){
				domainName = "";
			}
		}*/
		
		for (Box co: boxes) {			
			if(co.getType().equals("Class")){
				if(((Class) co).getName().equals(domainName) && (((Class) co).getNamespace() == null || domainNamespace.equals("") || ((Class) co).getNamespace().equals(domainNamespace))) {
					newAssociation.setSource(co);
        			break;
        		}
			}
    	}
	}
	
	public static Compartment setAssociationTarget(OWLOntology componentontology, ArrayList<Box> boxes, Association newAssociation, OWLObjectProperty op, JsonObject preferences){
		Compartment allValuesFrom = null;
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		String rangeName = "";
		String rangeNamespace = "";
		for(OWLObjectPropertyRangeAxiom opr: componentontology.getObjectPropertyRangeAxioms(op)){
			if (rangeName == "") rangeName = m.render(opr.getRange()).replace("\n", "\\n");
			else rangeName = rangeName + " and " + m.render(opr.getRange()).replace("\n", "\\n");
			if(opr.getRange().getSignature().size() == 1 && !opr.getRange().getClassExpressionType().toString().equals("ObjectUnionOf") && !opr.getRange().getClassExpressionType().toString().equals("ObjectComplementOf")){

				rangeNamespace = opr.getRange().asOWLClass().getIRI().getNamespace();
			}
		}
		if (rangeName == "") rangeName = "Thing";
		if(avf == true && componentontology.getObjectPropertyDomainAxioms(op).isEmpty()){
			for(OWLClass clazz: componentontology.getClassesInSignature()){
				for(OWLSubClassOfAxiom sc: componentontology.getSubClassAxiomsForSubClass(clazz)){
					if(sc.getSuperClass().getClassExpressionType().toString().equals("ObjectAllValuesFrom")){
						OWLObjectAllValuesFrom oavf = (OWLObjectAllValuesFrom) sc.getSuperClass();
						if(oavf.getProperty().equals(op)){
							for(OWLAnnotationAssertionAxiom aa:componentontology.getAnnotationAssertionAxioms(op.getIRI())){
								if(aa.getProperty().getIRI().getShortForm().toString().equals("schema")) {
									rangeName = m.render(oavf.getFiller());
									allValuesFrom = createCompartment("allValuesFrom", "true");
								}
							}
						}
					}
				}
			}
		}
		
		/*for(OWLAnnotationAssertionAxiom aa : componentontology.getAnnotationAssertionAxioms(op.getIRI())){
			if(aa.getProperty().getIRI().getShortForm().toString().equals("schema")){
				rangeName = "";
			}
		}*/

		for (Box co: boxes) {			
			if(co.getType().equals("Class")){
				if(((Class) co).getName().equals(rangeName) && (((Class) co).getNamespace() == null || rangeNamespace.equals("") || ((Class) co).getNamespace().equals(rangeNamespace))) {
					newAssociation.setTarget(co);
        		}
			}
    	}
		return allValuesFrom;
	}
	
	//public static void createMultiLineCompartments(ArrayList<Compartment> classes, Set<OWLClass> classesInSignature, OWLClass co,
	public static void createMultiLineCompartments(ArrayList<Compartment> classes, Set<OWLClassExpression> classesInSignature, OWLClass co,
			String level1, String level2, String level3, String level4){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		Compartment newClasses = createCompartment(level1, "");
   		classes.add(newClasses);
   	    Compartment ASFictitiousClass = createCompartment(level2, "");
   	    ASFictitiousClass.setIsMultiline(true);
   	    newClasses.setSubCompartment(ASFictitiousClass);
   		
   		ArrayList<Compartment> newClasses2 = new ArrayList<Compartment>();
   		ASFictitiousClass.setSubCompartments(newClasses2);
   		//Compartment newClass = createCompartment(level3, "");
   		//newClasses2.add(newClass);
   		
   		for(OWLClassExpression eqCl: classesInSignature){
   			if(!eqCl.equals(co)){
   				Compartment newClass = createCompartment(level3, "");
   		   		newClasses2.add(newClass);
   				Compartment newExpression = new Compartment(level4, m.render(eqCl).replace("\n", "\\n"));
   				newClass.setSubCompartment(newExpression);
   			}
   		}
	}
	
	public static void createMultiLineCompartments(ArrayList<Compartment> classes, String classesInSignature,
			String level1, String level2, String level3, String level4){
		Compartment newClasses = createCompartment(level1, "");
   		classes.add(newClasses);
   	    Compartment ASFictitiousClass = createCompartment(level2, "");
   	    ASFictitiousClass.setIsMultiline(true);
   	    newClasses.setSubCompartment(ASFictitiousClass);
   		
   		ArrayList<Compartment> newClasses2 = new ArrayList<Compartment>();
   		ASFictitiousClass.setSubCompartments(newClasses2);
   		Compartment newClass = createCompartment(level3, "");
   		newClasses2.add(newClass);

   		Compartment newExpression = new Compartment(level4, classesInSignature);
   		newClass.setSubCompartment(newExpression);
	}
	
	public static void createASFictitiousForMultiLineCompartments(ArrayList<Compartment> subCompartments, ArrayList<Compartment> compartments, String aSFictitiousName){
		if (!subCompartments.isEmpty()){
       	    Compartment ASFictitiousClasses = createCompartment(aSFictitiousName, "");
       	    ASFictitiousClasses.setIsMultiline(true);
         	ASFictitiousClasses.setSubCompartments(subCompartments);
       	    compartments.add(ASFictitiousClasses);
       	}
	}
	
	public static void createSuperClassesAsText(Class box, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){
    	OWLClass co = box.getOwlClass();
		Set<OWLSubClassOfAxiom> superClassAxioms = componentontology.getSubClassAxiomsForSubClass(co);
        	
    	ArrayList<Compartment> superClasses = new ArrayList<Compartment>();
    	if (calcProc == false) {
	    	for (OWLSubClassOfAxiom superClassAxiom : superClassAxioms) {
	    		createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
	       	}
    	} else {
    		for (OWLSubClassOfAxiom superClassAxiom : superClassAxioms) {
    			if (calculateParameterProcedure("showSubclassesType", preferences).equals("As text")){
    				createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
        		}
	       	}
    	}
    	createASFictitiousForMultiLineCompartments(superClasses, compartments, "ASFictitiousSuperClasses"); 
	}
	
	public static void createSuperClassAsText(OWLSubClassOfAxiom superClassAxiom, ArrayList<Compartment> superClasses,  JsonObject preferences, OWLOntology componentontology){
		String expression = "";
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		String superClassExpression = m.render(superClassAxiom.getSuperClass());

		if (superClassExpression.contains(" min ") || superClassExpression.contains(" max ") || superClassExpression.contains(" exactly ") ){
			
			if ((superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("DataMaxCardinality") || 
					superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("DataMinCardinality") || 
					superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("DataExactCardinality")) 
					&& !getPreferenceParameterValue("showPropertyRestrictionsHideNotGraphical", preferences).equals("true")){
				expression = m.render(superClassAxiom.getSuperClass()).replace("\n", "\\n");
				Compartment newSuperClass = new Compartment("SuperClasses", "");
				Compartment newExpression = new Compartment("Expression", expression);
				newSuperClass.setSubCompartment(newExpression);
				superClasses.add(newSuperClass);
			} else if ((superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectMaxCardinality") || 
					superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectMinCardinality") || 
					superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectExactCardinality")) 
					&& !getPreferenceParameterValue("showPropertyRestrictionsGraphically", preferences).equals("true")) {
				expression = m.render(superClassAxiom.getSuperClass()).replace("\n", "\\n");
				Compartment newSuperClass = new Compartment("SuperClasses", "");
				Compartment newExpression = new Compartment("Expression", expression);
				newSuperClass.setSubCompartment(newExpression);
				superClasses.add(newSuperClass);
			}
		} else if ((superClassExpression.contains(" some ") || superClassExpression.contains(" only ")) && superClassAxiom.getSuperClass().getClassesInSignature().size() < 2){
			
			if (getPreferenceParameterProcName("showPropertyRestrictions", preferences).equals("") && getPreferenceParameterProcName("showPropertyRestrictionsGraphically", preferences).equals("")){
				Boolean createSuperClass = true;
				if(superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("ObjectAllValuesFrom")){
					OWLObjectAllValuesFrom davf = (OWLObjectAllValuesFrom) superClassAxiom.getSuperClass();
					for(OWLAnnotationAssertionAxiom aa: componentontology.getAnnotationAssertionAxioms(davf.getProperty().asOWLObjectProperty().getIRI())){
						if(avf == true && aa.getProperty().getIRI().getShortForm().toString().equals("schema") && aa.getSubject().toString().equals(davf.getProperty().asOWLObjectProperty().getIRI().toString())){
							createSuperClass = false;
						}
					}
				}
				
				if(createSuperClass == true){
					
					if (getPreferenceParameterValue("showPropertyRestrictions", preferences).equals("true") && !getPreferenceParameterValue("showPropertyRestrictionsGraphically", preferences).equals("true")
							&& !getPreferenceParameterValue("showPropertyRestrictionsHideNotGraphical", preferences).equals("true")) {
						if (superClassAxiom.getSuperClass().isAnonymous() == false) expression = superClassAxiom.getSuperClass().asOWLClass().getIRI().getShortForm();
						else {
							expression = m.render(superClassAxiom.getSuperClass()).replace("\n", "\\n");
						}
						Compartment newSuperClass = new Compartment("SuperClasses", "");
						Compartment newExpression = new Compartment("Expression", expression);
						newSuperClass.setSubCompartment(newExpression);
						superClasses.add(newSuperClass);
		        	}
					else{
						
						if ((superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("DataAllValuesFrom") || 
								superClassAxiom.getSuperClass().getClassExpressionType().toString().equals("DataSomeValuesFrom")) 
								&& !getPreferenceParameterValue("showPropertyRestrictionsHideNotGraphical", preferences).equals("true")){
							expression = m.render(superClassAxiom.getSuperClass()).replace("\n", "\\n");
							Compartment newSuperClass = new Compartment("SuperClasses", "");
							Compartment newExpression = new Compartment("Expression", expression);
							newSuperClass.setSubCompartment(newExpression);
							superClasses.add(newSuperClass);
						}
					}
				}
	    	} else {
	    		//TODO
			} 
		} else {
			if (superClassAxiom.getSuperClass().isAnonymous() == false) expression = superClassAxiom.getSuperClass().asOWLClass().getIRI().getShortForm();
			else {
				expression = m.render(superClassAxiom.getSuperClass()).replace("\n", "\\n");
			}
			Compartment newSuperClass = new Compartment("SuperClasses", "");
			Compartment newExpression = new Compartment("Expression", expression);
			newSuperClass.setSubCompartment(newExpression);
			superClasses.add(newSuperClass);
		}
	}
	
	public static void createEquivalentClassesAsText(Class box, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){
		OWLClass co = box.getOwlClass();
		Set<OWLEquivalentClassesAxiom> equivalentClassesAxioms = componentontology.getEquivalentClassesAxioms(co);
		ArrayList<Compartment> equivalentClasses = new ArrayList<Compartment>();
		if (calcProc == false) {
			for (OWLEquivalentClassesAxiom equivalentClassesAxiom : equivalentClassesAxioms) {
				createMultiLineCompartments(equivalentClasses, equivalentClassesAxiom.getClassExpressionsMinus(co), co, "EquivalentClasses", "ASFictitiousEquivalentClass", "EquivalentClass", "Expression");
	       	}
		} else {
			for (OWLEquivalentClassesAxiom equivalentClassesAxiom : equivalentClassesAxioms) {
				if (calculateParameterProcedure("showEquivalentClassesType", preferences).equals("As text")) createMultiLineCompartments(equivalentClasses, equivalentClassesAxiom.getClassExpressionsMinus(co), co, "EquivalentClasses", "ASFictitiousEquivalentClass", "EquivalentClass", "Expression");
		    }
		}
		createASFictitiousForMultiLineCompartments(equivalentClasses, compartments, "ASFictitiousEquivalentClasses"); 
	}
	
	public static void createDisjointClassesAsText(Class box, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){
		OWLClass co = box.getOwlClass();
		Set<OWLDisjointClassesAxiom> disjointClassesAxioms = componentontology.getDisjointClassesAxioms(co);
		ArrayList<Compartment> disjointClasses = new ArrayList<Compartment>();
		if (calcProc == false) {
			for (OWLDisjointClassesAxiom disjointClassesAxiom : disjointClassesAxioms) {
				createMultiLineCompartments(disjointClasses, disjointClassesAxiom.getClassExpressionsMinus(co), co, "DisjointClasses", "ASFictitiousDisjointClass", "DisjointClass", "Expression");
	       	}
		} else {
			for (OWLDisjointClassesAxiom disjointClassesAxiom : disjointClassesAxioms) {
				if (calculateParameterProcedure("showDisjointClassesType", preferences).equals("As text")) createMultiLineCompartments(disjointClasses, disjointClassesAxiom.getClassExpressionsMinus(co), co, "DisjointClasses", "ASFictitiousDisjointClass", "DisjointClass", "Expression");
	       	}
		}
		createASFictitiousForMultiLineCompartments(disjointClasses, compartments, "ASFictitiousDisjointClasses"); 
	}
	
	public static void createIndividualAnnotationsAsText(Individual box, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences, 
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap){
		OWLNamedIndividual individual = (OWLNamedIndividual) box.getIndividual();
		if(individual!=null){
			Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms = componentontology.getAnnotationAssertionAxioms(individual.getIRI());
			createAnnotationsAsTextFromAxiom(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Object", userFieldsParameter, prefixesArray, prefixesMap, false, null);
			createAnnotationsAsTextFromAxiomForUserField(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Object", userFieldsParameter, false);
		}
	}
	
	public static void createClassAnnotationsAsText(Class box, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences, 
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap){
		OWLClass co = box.getOwlClass();
		if(co!=null){
			Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms = componentontology.getAnnotationAssertionAxioms(co.getIRI());
			createAnnotationsAsTextFromAxiom(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Class", userFieldsParameter, prefixesArray, prefixesMap, false, null);
			createAnnotationsAsTextFromAxiomForUserField(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Class", userFieldsParameter, false);
		}
	}
	
	public static void createAssociationAnnotationsAsText(OWLObjectProperty op, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences,
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap, Boolean isAllValuesFrom, String source){
		Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms = componentontology.getAnnotationAssertionAxioms(op.getIRI());
		createAnnotationsAsTextFromAxiom(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Association", userFieldsParameter, prefixesArray, prefixesMap, isAllValuesFrom, source);
		createAnnotationsAsTextFromAxiomForUserField(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Association", userFieldsParameter, isAllValuesFrom);
	}
	
	public static void createAttributeAnnotationsAsText(OWLDataProperty dp, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, 
			JsonObject preferences, ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap, Boolean isAllValuesFrom, String source){
		Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms = componentontology.getAnnotationAssertionAxioms(dp.getIRI());
		createAnnotationsAsTextFromAxiom(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Attribute", userFieldsParameter, prefixesArray, prefixesMap, isAllValuesFrom, source);
		createAnnotationsAsTextFromAxiomForUserField(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Attribute", userFieldsParameter, isAllValuesFrom);
	}
	
	public static void createIndividualClassAssertionsAsText(Individual box, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){
		OWLIndividual individual = box.getIndividual();
		ArrayList<Compartment> titleCompartments = null;
		for(Compartment compartment : compartments){
			if (compartment.getType().equals("Title")){
				titleCompartments = compartment.getSubCompartments();
				break;
			}
		}
		
		if (calcProc == false) {
			for (OWLClassAssertionAxiom caa: componentontology.getClassAssertionAxioms(individual)){
				createIndividualClassAssertionAsTextCompartments(titleCompartments, caa);
			}
    	} else {
    		
    		for (OWLClassAssertionAxiom caa: componentontology.getClassAssertionAxioms(individual)){
    			if (calculateParameterProcedure("showSubclassesType", preferences).equals("As text")){
    				createIndividualClassAssertionAsTextCompartments(titleCompartments, caa);
    			}
    		}
    	}
	}
	
	
	public static void createDifferentIndividualsAsText(Individual box, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences, 
			String[] prefixesArray,Map<String, String> prefixesMap){
		OWLIndividual individual = box.getIndividual();
        
		ArrayList<Compartment> differentIndividuals = new ArrayList<Compartment>();
		
		if (calcProc == false) {
			for(OWLDifferentIndividualsAxiom di: componentontology.getDifferentIndividualAxioms(individual)) {
				createDifferentIndividualAsText(di, individual, differentIndividuals, componentontology, prefixesArray, prefixesMap);
	    	}
		} else {
			for(OWLDifferentIndividualsAxiom di: componentontology.getDifferentIndividualAxioms(individual))  {
				if (calculateParameterProcedure("showDifferentIndividualsType", preferences).equals("As text")) createDifferentIndividualAsText(di, individual, differentIndividuals,  componentontology, prefixesArray, prefixesMap);
	    	}
		}
		createASFictitiousForMultiLineCompartments(differentIndividuals, compartments, "ASFictitiousDifferentIndividuals");
	}
	
	public static void createDifferentIndividualAsText(OWLDifferentIndividualsAxiom di, OWLIndividual individual, ArrayList<Compartment> differentIndividuals,  
			OWLOntology componentontology, String[] prefixesArray, Map<String, String> prefixesMap){
		for(OWLNamedIndividual ind : di.getIndividualsInSignature()){
    		if(!ind.equals(individual)){
    			createSameOrDifferentIndividualCompartments(ind, individual, differentIndividuals,  "DifferentIndividuals",  componentontology, prefixesArray, prefixesMap);
    		}
    	}
	}
	
	public static void createOntologyAnnotationsInSeedSymbol(){
		//nav atvalstits OWLGrEd-a
	}
	
	public static void createDifferentIndividualsGraphically(Individual box, ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology, Boolean calcProc,
			JsonObject preferences, String[] prefixesArray, Map<String, String> prefixesMap){
		OWLIndividual individual = box.getIndividual();
		Set<OWLDifferentIndividualsAxiom> differentIndividualAxioms = componentontology.getDifferentIndividualAxioms(individual);
		if (calcProc == false) {
			for (OWLDifferentIndividualsAxiom dia: differentIndividualAxioms) {
				if (getPreferenceParameterValue("showDifferentIndividualsGraphicsGroupAsBoxes", preferences).equals("true") && dia.getIndividuals().size() > 2)  {}
				else createSameAsOrDifferentIndivideGraphically("DifferentIndivid", "different", individual, dia.getIndividuals(), boxes, lines, box, dia.getAnnotations(), prefixesArray, preferences, prefixesMap);
	       	}
		} else {
			for (OWLDifferentIndividualsAxiom dia: differentIndividualAxioms) {
				if (calculateParameterProcedure("showDifferentIndividualsType", preferences).equals("Graphically")) createSameAsOrDifferentIndivideGraphically("DifferentIndivid", "different", individual, dia.getIndividuals(), boxes, lines, box, dia.getAnnotations(), prefixesArray, preferences,  prefixesMap);
	       	}
		}
	}
	
	public static void createSameIndividualsAsText(Individual box, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences, String[] prefixesArray, Map<String, String> prefixesMap){
		OWLIndividual individual = box.getIndividual();
        
		ArrayList<Compartment> sameIndividuals = new ArrayList<Compartment>();
		
		if (calcProc == false) {
			for(OWLSameIndividualAxiom si: componentontology.getSameIndividualAxioms(individual)) {
				createSameIndividualAsText(si, individual, sameIndividuals, componentontology, prefixesArray, prefixesMap);
	    	}
		} else {
			for(OWLSameIndividualAxiom si: componentontology.getSameIndividualAxioms(individual))  {
				if (calculateParameterProcedure("showSameIndividualsType", preferences).equals("As text")) createSameIndividualAsText(si, individual, sameIndividuals, componentontology, prefixesArray, prefixesMap);
	    	}
		}
		createASFictitiousForMultiLineCompartments(sameIndividuals, compartments, "ASFictitiousSameIndividuals");
	}
	
	public static void createSameIndividualAsText(OWLSameIndividualAxiom si, OWLIndividual individual, ArrayList<Compartment> sameIndividuals,  OWLOntology componentontology, String[] prefixesArray, Map<String, String> prefixesMap){
		for(OWLNamedIndividual ind : si.getIndividualsInSignature()){
			createSameOrDifferentIndividualCompartments(ind, individual, sameIndividuals,  "SameIndividuals", componentontology, prefixesArray, prefixesMap);
    	}
	}
	
	public static void createSameIndividualsGraphically(Individual box, ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology, Boolean calcProc, JsonObject preferences, 
			String[] prefixesArray, Map<String, String> prefixesMap){
		OWLIndividual individual = box.getIndividual();
		Set<OWLSameIndividualAxiom> sameIndividualAxioms = componentontology.getSameIndividualAxioms(individual);
		if (calcProc == false) {
			for (OWLSameIndividualAxiom sia: sameIndividualAxioms) {
				if (getPreferenceParameterValue("showSameIndividualsGraphicsGroupAsBoxes", preferences).equals("true") && sia.getIndividuals().size() > 2)  {}
				else createSameAsOrDifferentIndivideGraphically("SameAsIndivid", "sameAs", individual, sia.getIndividuals(), boxes, lines, box, sia.getAnnotations(), prefixesArray, preferences, prefixesMap);
	       	}
		} else {
			for (OWLSameIndividualAxiom sia: sameIndividualAxioms) {
				if (calculateParameterProcedure("showSameIndividualsType", preferences).equals("Graphically")) createSameAsOrDifferentIndivideGraphically("SameAsIndivid", "sameAs", individual, sia.getIndividuals(), boxes, lines, box, sia.getAnnotations(), prefixesArray, preferences, prefixesMap);
	       	}
		}
	}
	
	public static void createSameOrDifferentIndividualCompartments(OWLNamedIndividual ind, OWLIndividual individual, ArrayList<Compartment> compIndividuals, String type,  OWLOntology componentontology,
			String[] prefixesArray, Map<String, String> prefixesMap){
		if(!ind.equals(individual)){
			Compartment compIndividual = createCompartment(type, "");
			ArrayList<Compartment> compIndividualCompartments = new ArrayList<Compartment>();
			compIndividual.setSubCompartments(compIndividualCompartments);
			compIndividualCompartments.add(createCompartment("Individual", ind.getIRI().getShortForm()));
			
			String namespace = "";
			if ((!componentontology.getOntologyID().isAnonymous() 
					&& !ind.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
					&& !ind.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))
					||(componentontology.getOntologyID().isAnonymous()
							&& !ind.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = ind.getIRI().getNamespace();
			namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
			
			compIndividualCompartments.add(createCompartment("Namespace", namespace));
			compIndividuals.add(compIndividual);
		}
	}
	
	public static void createIndividualClassAssertionAsTextCompartments(ArrayList<Compartment> titleCompartments, OWLClassAssertionAxiom caa){
		Compartment kols = createCompartment("Kols", ":");
		titleCompartments.add(kols);
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		Compartment className = createCompartment("ClassName", m.render(caa.getClassExpression()));
		//Compartment className = createCompartment("ClassName", caa.getClassExpression().asOWLClass().getIRI().getShortForm());
		titleCompartments.add(className);
	}
	
	public static void createAnnotationsAsTextFromAxiomForUserField(Boolean calcProc, JsonObject preferences, Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms, 
			ArrayList<Compartment> compartments, String annotationType, ArrayList<UserFieldsParameter> userFieldsParameter,  Boolean isAllValuesFrom){
		
		String userFieldType = "";
		if (annotationType.equals("Class")) userFieldType = "Class";
		else if (annotationType.equals("Object")) userFieldType = "Indiv";
		else if (annotationType.equals("Association")) userFieldType = "Role";
		else if (annotationType.equals("Attribute")) userFieldType = "Attr";
		for(UserFieldsParameter userFieldParameter : userFieldsParameter) {
			if (userFieldParameter.getType().equals("For"+userFieldType+"_ShowAnnotation_InField")){
				
				ArrayList<Compartment> userFieldCompartments = new ArrayList<Compartment>();
				String[] path = userFieldParameter.getPath().split("/");
				
				for(OWLAnnotationAssertionAxiom classAAAxiom : classAnnotationAssertionAxioms){
					Boolean contextInAnnotation = false;
					for(OWLAnnotation annot: classAAAxiom.getAnnotations()){
						if(annot.getProperty().getIRI().getShortForm().equals("Context") && avf == true) contextInAnnotation = true;
					}
					if(isAllValuesFrom != true || (isAllValuesFrom == true && contextInAnnotation == true)){
						if (classAAAxiom.getProperty().getIRI().getShortForm().equals(userFieldParameter.getName())){
							if(!classAAAxiom.getValue().asLiteral().toString().equals("Optional.absent()")){
								OWLLiteral annotation = (OWLLiteral) classAAAxiom.getValue();
								String value = annotation.getLiteral();//.replace("\n", "\\\n");
								if (value.endsWith("\n")) value = value.substring(0, value.length()-2);
								if (userFieldParameter.getRequireValue() != null ){
									if (userFieldParameter.getRequireValue().equals(value) && userFieldParameter.getCreateValue() != null) value = userFieldParameter.getCreateValue();
									else value = null;
								}
								if (value != null) {
									if (path.length == 1){
										Compartment firstLevelField = createCompartment(userFieldParameter.getName(), value);
										compartments.add(firstLevelField);
									} else {
										String compartName = userFieldParameter.getName();
										Compartment field = createCompartment(compartName.substring(0, 1).toUpperCase() + compartName.substring(1), value);
										userFieldCompartments.add(field);
									}
								}
							}
						}
					}
				}

				if (path.length > 1) {
					if (!userFieldCompartments.isEmpty()){
						Boolean isMultiple = false;
						Compartment firstLevelField = null;
						for (int i = path.length-2; i>=0;  i--){
							if (path[i].startsWith("ASFictitious")){
								isMultiple = true;
								firstLevelField = createCompartment(path[i], "");
								firstLevelField.setIsMultiline(true);
								firstLevelField.setSubCompartments(userFieldCompartments);
							} else if (isMultiple == true) {
								Compartment f = firstLevelField;
								firstLevelField = createCompartment(path[i], "");
								firstLevelField.setSubCompartment(f);
							} else {
								ArrayList<Compartment> userFieldCompartmentsTemp = new ArrayList<Compartment>();
								for (Compartment field : userFieldCompartments){
									Compartment f = createCompartment(path[i], "");
									userFieldCompartmentsTemp.add(f);
									f.setSubCompartment(field);
								}
								userFieldCompartments = userFieldCompartmentsTemp;
								userFieldCompartmentsTemp = null;
							}
						}
						compartments.add(firstLevelField); 
					}
				}
			}
		}
	}
	
	public static Boolean createContainerFromAnnotationAxiom(Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms, OWLOntology componentontology, 
			ArrayList<Box> boxes, ArrayList<Box> needToBeAddedToBoxes, Box box, ArrayList<Ontology> ontologies, Iterator<Box> iterbox){
		Boolean removeFromDiagramm = false;
		for(OWLAnnotationAssertionAxiom aa: classAnnotationAssertionAxioms){
			if(aa.getProperty().getIRI().getShortForm().equals("Container") && cont == true){
				Box container = getContainer(aa.getValue().toString().substring(1, aa.getValue().toString().length()-1), boxes, needToBeAddedToBoxes);
		        box.setContainer(container);
		        container.setElemCount(container.getElemCount() + 1);
			}
			/*if(aa.getProperty().getIRI().getShortForm().equals("Fragment")){
				removeFromDiagramm = true;
				getOntology(aa.getValue().toString().substring(1, aa.getValue().toString().length()-1), box, boxes, needToBeAddedToBoxes, ontologies);
			}*/
		}
		return removeFromDiagramm;
	}
	
	public static Box getContainer(String containerName, ArrayList<Box> boxes, ArrayList<Box> needToBeAddedToBoxes){
		for(Box b : boxes){
			if(b.getType().equals("Container")){
				 ArrayList<Compartment> contComp = b.getCompartments();
				 for(Compartment c: contComp){
					if(c.getType().equals("Name") && c.getValue().equals(containerName)){
						return b;
					}
				 }
			}
		}
		
		for(Box b : needToBeAddedToBoxes){
			if(b.getType().equals("Container")){
				 ArrayList<Compartment> contComp = b.getCompartments();
				 for(Compartment c: contComp){
					if(c.getType().equals("Name") && c.getValue().equals(containerName)){
						return b;
					}
				 }
			}
		}
		Box container = new Box("Container");
		needToBeAddedToBoxes.add(container);
        ArrayList<Compartment> contComp = new ArrayList<Compartment>();
        container.setCompartments(contComp);
        contComp.add(createCompartment("Name", containerName));
		
		return container;
	}
	
	public static void getOntology(String fragmentName, Box box, ArrayList<Box> boxes, ArrayList<Box> needToBeAddedToBoxes, ArrayList<Ontology> ontologies){
	for(Ontology o : ontologies){
			if(o.getName().equals(fragmentName)){
				o.getBoxes().add(box);
				return;
			}
		}
			
		Box fragment = new Box("OntologyFragment");
		needToBeAddedToBoxes.add(fragment);
        ArrayList<Compartment> contComp = new ArrayList<Compartment>();
        fragment.setCompartments(contComp);
        contComp.add(createCompartment("Name", fragmentName));
       
         Ontology ontology = new Ontology(fragmentName, fragmentName, "1", "1");
         ontologies.add(ontology);
         ArrayList<Box> fbox = new ArrayList<Box>();
         fbox.add(box);
        // boxes.remove(box);
         ontology.setBoxes(fbox);
         ontology.setLines(new ArrayList<Line>());
         ontology.setImports(new ArrayList<String>());
         fragment.setChild(ontology);

 		 ontology.setIsOntologyFragment(true);

	}
	
	public static void createAnnotationsAsTextFromAxiom(Boolean calcProc, JsonObject preferences, Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms, ArrayList<Compartment> compartments, 
			String annotationType, ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap, Boolean isAllValuesFrom, String subject){
		ArrayList<Compartment> classAnnotations = new ArrayList<Compartment>();
		Boolean foundedComment = false;
		String userFieldType = "";
		if (annotationType.equals("Class")) userFieldType = "Class";
		else if (annotationType.equals("Object")) userFieldType = "Indiv";
		else if (annotationType.equals("Association")) userFieldType = "Role";
		else if (annotationType.equals("Attribute")) userFieldType = "Attr";
		if (calcProc == false) {
			for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : classAnnotationAssertionAxioms) {
				Boolean contextInAnnotation = false;
				
				for(OWLAnnotation annot: classAnnotationAssertionAxiom.getAnnotations()){
					if(annot.getProperty().getIRI().getShortForm().equals("Context") && avf == true && annot.getValue().toString().endsWith(subject)) contextInAnnotation = true;

				}
				if(isAllValuesFrom != true || (isAllValuesFrom == true && contextInAnnotation == true )){
					if((!classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().toString().equals("schema") || (classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().toString().equals("schema") && avf == false))
							&& !classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().toString().equals("Container") 
							&& !classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().toString().equals("Fragment")){
						Boolean exists = false;
						if (userFieldsParameter != null){
						for(UserFieldsParameter userFieldParameter : userFieldsParameter) {
							if (classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals(userFieldParameter.getName()) && userFieldParameter.getType().equals("For"+userFieldType+"_ShowAnnotation_InField")){
								exists = true;
								break;
							}
						}
						}
						if (getPreferenceParameterValue("showClassAnnotationsEnableSpecComments", preferences).equals("true") && foundedComment == false && classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("comment") && annotationType.equals("Class")){
							Boolean annotationsInLang = false;
							List<String> items = new ArrayList<String>();
							if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
					      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
					      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
					      	    	if(items.contains(classAnnotationAssertionAxiom.getValue().asLiteral().get().getLang().toString())) annotationsInLang = true;
					      	    } else annotationsInLang = true;
					      	} 
							
							if(annotationsInLang == true){
								foundedComment = true;
								createComment(classAnnotationAssertionAxiom, compartments);
							}
						} else if (exists == false) createAnnotationCompartmentsFromOWLAnnotationAssertionAxioms(classAnnotations, classAnnotationAssertionAxiom, prefixesArray, prefixesMap);
					}
				}
			}
		} else {
			for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : classAnnotationAssertionAxioms) {
				if (calculateParameterProcedure("showClassAnnotationsType", preferences).equals("As text")) {
					if (getPreferenceParameterValue("showClassAnnotationsEnableSpecComments", preferences).equals("true") && foundedComment == false && classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("comment") && annotationType.equals("Class")){
						Boolean annotationsInLang = false;
						List<String> items = new ArrayList<String>();
						if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
				      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
				      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
				      	    	if(items.contains(classAnnotationAssertionAxiom.getValue().asLiteral().get().getLang().toString())) annotationsInLang = true;
				      	    } else annotationsInLang = true;
				      	} 
						
						if(annotationsInLang == true){
							foundedComment = true;
							createComment(classAnnotationAssertionAxiom, compartments);
						}
					} else createAnnotationCompartmentsFromOWLAnnotationAssertionAxioms(classAnnotations, classAnnotationAssertionAxiom, prefixesArray, prefixesMap);
				}
	    	}
		}
		createASFictitiousForMultiLineCompartments(classAnnotations, compartments, "ASFictitiousAnnotation"); 
	}
	
	public static void createComment(OWLAnnotationAssertionAxiom annotationAssertionAxiom, ArrayList<Compartment> compartments){
		if(!annotationAssertionAxiom.getValue().asLiteral().toString().equals("Optional.absent()")){
			OWLLiteral annotation = (OWLLiteral) annotationAssertionAxiom.getValue();
			String value = annotation.getLiteral();
			compartments.add(createCompartment("Comment", value.replaceAll("\r", "\n")));
		} else {
			unexported.add(annotationAssertionAxiom.toString());
		}
	}
	
	public static void createAnnotationCompartmentsFromOWLAnnotationAssertionAxioms(ArrayList<Compartment> annotations, OWLAnnotationAssertionAxiom annotationAssertionAxiom, String[] prefixesArray, Map<String, String> prefixesMap){
		String property = annotationAssertionAxiom.getProperty().getIRI().getShortForm();
		if(annotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("isDefinedBy") || annotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("seeAlso")){
			String value = annotationAssertionAxiom.getValue().toString();
			String lang ="";
			String namespace = annotationAssertionAxiom.getProperty().getIRI().getNamespace();
			if(namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
			namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
			createAnnotation(annotations, property, value, lang, namespace);
		}
		else if(annotationAssertionAxiom.getProperty().isBuiltIn() == false || annotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("description")){
			
			String aaValue = annotationAssertionAxiom.toString();
			String value = "";
			String lang="";
			if(aaValue.contains("\""))	{
				value =	aaValue.substring(aaValue.indexOf('"')+1, aaValue.lastIndexOf('"'));
				String tempValue = annotationAssertionAxiom.getValue().toString();
				if (tempValue.contains("\"@")) {
					lang = tempValue.substring(tempValue.indexOf("\"@")+2, tempValue.length());
				}
			}
			else value = annotationAssertionAxiom.getValue().toString();
			
			
			if (value.startsWith("\"")){ 
				if (value.contains("\"@")) {
					lang = value.substring(value.indexOf("\"@")+2, value.length());
				}
				value = value.substring(1, value.lastIndexOf('"'));
			}
			value = value.replace("\\\"", "\"");
			value = value.replace("\n", "\\n");

			String namespace = annotationAssertionAxiom.getProperty().getIRI().getNamespace();
			namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
			createAnnotation(annotations, property, value, lang, namespace);
		}else{
			if(!annotationAssertionAxiom.getValue().asLiteral().toString().equals("Optional.absent()")){
				OWLLiteral annotation = (OWLLiteral) annotationAssertionAxiom.getValue();
				String value = annotation.getLiteral();
				String lang = annotation.getLang();
				String namespace = annotationAssertionAxiom.getProperty().getIRI().getNamespace();
				if(namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
				namespace = namespaceValue(prefixesArray, namespace,  prefixesMap);
				createAnnotation(annotations, property, value, lang, namespace);
			} else{
				unexported.add(annotationAssertionAxiom.toString());
			}
		}
	}
	
	public static void createAnnotationCompartmentsFromAnnotations(ArrayList<Compartment> annotations, OWLAnnotation annotationAxiom, String[] prefixesArray, Map<String, String> prefixesMap){
		if(!annotationAxiom.getValue().asLiteral().toString().equals("Optional.absent()")){
			OWLLiteral annotation = (OWLLiteral) annotationAxiom.getValue();
			String property = annotationAxiom.getProperty().getIRI().getShortForm();
			String value = annotation.getLiteral();
			String lang = annotation.getLang();
			String namespace = annotationAxiom.getProperty().getIRI().getNamespace();
			if(!namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
			namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
			createAnnotation(annotations, property, value, lang, namespace);
		} else{
			unexported.add(annotationAxiom.toString());
		}
	}
	
	public static void createAnnotation(ArrayList<Compartment> annotations, String property, String value, String lang, String namespace){
		Boolean annotationsInLang = false;
		List<String> items = new ArrayList<String>();
		if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
      	    	if(items.contains(lang)) annotationsInLang = true;
      	    } else annotationsInLang = true;
      	} 
		if(annotationsInLang == true){
			Compartment newAnnotation = createCompartment("Annotation", "");
			annotations.add(newAnnotation);
			
			ArrayList<Compartment> annatationCompartments = new ArrayList<Compartment>();
			newAnnotation.setSubCompartments(annatationCompartments);
			createAnnotationCompartments(property, value, lang, annatationCompartments, namespace, null);
		}
	}
	
	public static void createIndividualClassAssertionsGraphically(Individual box, ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology, Boolean calcProc, JsonObject preferences){
		OWLIndividual individual = box.getIndividual();
		if (calcProc == false) {
			for (OWLClassAssertionAxiom caa: componentontology.getClassAssertionAxioms(individual)){
				createIndividualClassAssertionGraphically(caa, boxes, lines, box);
			}
    	} else {
    		for (OWLClassAssertionAxiom caa: componentontology.getClassAssertionAxioms(individual)){
    			if (calculateParameterProcedure("showClassAssertionsType", preferences).equals("Graphically")) createIndividualClassAssertionGraphically(caa, boxes, lines, box);
    		}
    	}
	}
	
	public static void createIndividualClassAssertionGraphically(OWLClassAssertionAxiom caa, ArrayList<Box> boxes, ArrayList<Line> lines, Individual box){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
		String className = m.render(caa.getClassExpression());
		String classNamespace = "";
		if(caa.getClassExpression().getSignature().size() == 1){
			classNamespace = caa.getClassExpression().asOWLClass().getIRI().getNamespace();
		}
		for(Box b : boxes){
			if (b.getType().equals("Class")){
				Class cl = (Class) b;
				if (cl.getName().equals(className) && (classNamespace.equals("") || cl.getNamespace() == null || cl.getNamespace().equals(classNamespace))) createDependency(cl, box, lines);
			}
		}
	}
	
	public static void createDependency(Class cl, Individual individual, ArrayList<Line> lines){
		Line newDependency = new Line(individual, cl, "Dependency");
		newDependency.setCompartment(createCompartment("Label", "instanceOf"));
		lines.add(newDependency);
	}
	
	public static void createSuperClassGeneralizations(Class box, ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology, Boolean calcProc, JsonObject preferences){
		OWLClass co = box.getOwlClass();
		Set<OWLSubClassOfAxiom> superClassAxioms = componentontology.getSubClassAxiomsForSubClass(co);
		Set<OWLSubClassOfAxiom> subClassAxioms = componentontology.getSubClassAxiomsForSuperClass(co);

		if (calcProc == false) {
			for (OWLSubClassOfAxiom superClassAxiom : superClassAxioms) {
				createSuperClassGeneralization(superClassAxiom, box, boxes, lines, preferences, componentontology);
	       	}
			for (OWLSubClassOfAxiom subClassAxiom : subClassAxioms) {
				createSubClassGeneralization(subClassAxiom, box, boxes, lines, componentontology);
	       	}
    	} else {
    		for (OWLSubClassOfAxiom superClassAxiom : superClassAxioms) {
    			if (calculateParameterProcedure("showSubclassesType", preferences).equals("Graphically")){
    				createSuperClassGeneralization(superClassAxiom, box, boxes, lines, preferences, componentontology);
        		}
	       	}
    		for (OWLSubClassOfAxiom subClassAxiom : subClassAxioms) {
    			if (calculateParameterProcedure("showSubclassesType", preferences).equals("Graphically")){
    				createSubClassGeneralization(subClassAxiom, box, boxes, lines, componentontology);
        		}
	       	}
    	}
	}
	
	public static ArrayList<Compartment> findASFictitiousSuperClassesCompartment(Box box){
		ArrayList<Compartment> compartments = box.getCompartments();
		ArrayList<Compartment> superClasses = null;
		if (compartments == null){
				compartments = new ArrayList<Compartment>();
				box.setCompartments(compartments);
		}
		for(Compartment c : compartments){
				if(c.getType().equals("ASFictitiousSuperClasses")){
					superClasses = c.getSubCompartments();
					break;
				}
		}
		if (superClasses == null) {
			superClasses = new ArrayList<Compartment>();
			Compartment ASFictitiousClasses = createCompartment("ASFictitiousSuperClasses", "");
			ASFictitiousClasses.setIsMultiline(true);
			ASFictitiousClasses.setSubCompartments(superClasses);
			compartments.add(ASFictitiousClasses);
		}
		return superClasses;
	}
	
	public static void createSuperClassGeneralization(OWLSubClassOfAxiom superClassAxiom,Class box, ArrayList<Box> boxes, ArrayList<Line> lines, 
			JsonObject preferences, OWLOntology componentontology){
		String sType = superClassAxiom.getSuperClass().getClassExpressionType().toString();
		Boolean classGeneralizationCreated = false;
		if (superClassAxiom.getSuperClass().isAnonymous() == false) {
			Box targetClass = null;
   			targetClass = getTargetBox(boxes, superClassAxiom.getSuperClass().asOWLClass().getIRI().getShortForm(), superClassAxiom.getSuperClass().asOWLClass().getIRI().getNamespace());
   			Line generalization = new Line(box, targetClass, "Generalization");
			lines.add(generalization);
		} else if(sType.equals("ObjectUnionOf") && getPreferenceParameterValue("showSubclassesToUnionOfNamed", preferences).equals("true") 
				&& (getPreferenceParameterValue("showSubclassesCreateTarget", preferences).equals("Yes") || getPreferenceParameterValue("showSubclassesCreateTarget", preferences).equals("Create if multiple use"))){
			ManchesterOWLSyntaxOWLObjectRendererImpl m = new ManchesterOWLSyntaxOWLObjectRendererImpl();
				for(Box b: boxes){
					if(b.getType().equals("Class")){
						Class clazz = (Class) b;
						if (clazz.getName().equals(m.render(superClassAxiom.getSuperClass()).replace("\n", "\\n"))){
							//check if generalization not exists
							Boolean generalizationExists = false;
							for(Line line : lines){
								if (line.getType().equals("Generalization") && line.getSource().equals(box) &&  line.getTarget() != null && line.getTarget().equals(b)){
									generalizationExists = true;
								}
							}
							if(generalizationExists == false){
								Line generalization = new Line(box, b, "Generalization");
								lines.add(generalization);
								classGeneralizationCreated = true;
							}
						}
					}
				}
				if (classGeneralizationCreated == false){
					ArrayList<Compartment> superClasses = findASFictitiousSuperClassesCompartment(box);
					
					if(!getPreferenceParameterValue("showPropertyRestrictionsHideNotGraphical", preferences).equals("true")) createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
				}
		}else if(sType.equals("ObjectIntersectionOf") && getPreferenceParameterValue("showSubclassesFromAndNamed", preferences).equals("true") 
				&& getPreferenceParameterValue("showSubclassesCreateTarget", preferences).equals("Yes") || getPreferenceParameterValue("showSubclassesCreateTarget", preferences).equals("Create if multiple use")){
			ManchesterOWLSyntaxOWLObjectRendererImpl m = new ManchesterOWLSyntaxOWLObjectRendererImpl();
			for(Box b: boxes){
				if(b.getType().equals("Class")){
					Class clazz = (Class) b;
					if (clazz.getName().equals(m.render(superClassAxiom.getSuperClass()).replace("\n", "\\n"))){
						//check if generalization not exists
						Boolean generalizationExists = false;
						for(Line line : lines){
							if (line.getType().equals("Generalization") && line.getSource().equals(box) &&  line.getTarget() != null && line.getTarget().equals(b)){
								generalizationExists = true;
							}
						}
						if(generalizationExists == false){
							Line generalization = new Line(box, b, "Generalization");
							lines.add(generalization);
							classGeneralizationCreated = true;
						}
					}
				}
			}
			if (classGeneralizationCreated == false){
				ArrayList<Compartment> superClasses = findASFictitiousSuperClassesCompartment(box);
				if(!getPreferenceParameterValue("showPropertyRestrictionsHideNotGraphical", preferences).equals("true")) createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
			}
		}else if(!getPreferenceParameterValue("showPropertyRestrictionsGraphically", preferences).equals("true") && !getPreferenceParameterValue("showPropertyRestrictionsHideNotGraphical", preferences).equals("true")
				&& !getPreferenceParameterValue("showSubclassesHideNotGraphical", preferences).equals("true") && (sType.equals("ObjectAllValuesFrom") || sType.equals("ObjectSomeValuesFrom"))){
			ArrayList<Compartment> superClasses = findASFictitiousSuperClassesCompartment(box);
			createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
		}else if(!sType.equals("DataMaxCardinality") && !sType.equals("DataMinCardinality") && !sType.equals("DataExactCardinality") &&
				!sType.equals("ObjectMaxCardinality") && !sType.equals("ObjectMinCardinality") && !sType.equals("ObjectExactCardinality")) {
			ArrayList<Compartment> compartments = box.getCompartments();
			ArrayList<Compartment> superClasses = null;
			if (compartments == null){
					compartments = new ArrayList<Compartment>();
					box.setCompartments(compartments);
			}
			for(Compartment c : compartments){
					if(c.getType().equals("ASFictitiousSuperClasses")){
						superClasses = c.getSubCompartments();
						break;
					}
			}
			if (superClasses == null) {
				superClasses = new ArrayList<Compartment>();
				Compartment ASFictitiousClasses = createCompartment("ASFictitiousSuperClasses", "");
				ASFictitiousClasses.setIsMultiline(true);
				ASFictitiousClasses.setSubCompartments(superClasses);
				compartments.add(ASFictitiousClasses);
			}
			ManchesterOWLSyntaxOWLObjectRendererImpl m = new ManchesterOWLSyntaxOWLObjectRendererImpl();
			Boolean classExists = false;
			for(Box b : boxes){
				if(b.getType().equals("Class")){
					Class c = (Class) b;
					if (c.getName().equals(m.render(superClassAxiom.getSuperClass()))) classExists = true;
				}
			}
			if(classExists!=true && !getPreferenceParameterValue("showSubclassesHideNotGraphical", preferences).equals("true")) createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
			//if(classExists!=true && superClassAxiom.getSuperClass().getSignature().size() > 2 && !getPreferenceParameterValue("showSubclassesHideNotGraphical", preferences).equals("true")) createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
		} else if ((sType.equals("DataMaxCardinality") || sType.equals("DataMinCardinality") || sType.equals("DataExactCardinality"))){
			Set<OWLDataProperty> dataProperties = superClassAxiom.getSuperClass().getDataPropertiesInSignature();
			if (dataProperties.size() == 1){
				String dataPropety = "";
				for (OWLDataProperty dp : dataProperties ){dataPropety = dp.getIRI().getShortForm();}
				Boolean attributeExists = false;
				for(Compartment c : box.getCompartments()){
					if(c.getType().equals("ASFictitiousAttributes")){
						for(Compartment attr : c.getSubCompartments()){
							for(Compartment attrComp : attr.getSubCompartments()){	
								if (attrComp.getType().equals("Name")){
									for(Compartment attrCompName : attrComp.getSubCompartments()){
										if (attrCompName.getType().equals("Name") && attrCompName.getValue().equals(dataPropety)) {
											attributeExists = true;
											break;
										}
									}
								}
								
							}
						}
						break;
					}
				}
				if (attributeExists == false){
					ArrayList<Compartment> compartments = box.getCompartments();
					ArrayList<Compartment> superClasses = null;
					if (compartments == null){
							compartments = new ArrayList<Compartment>();
							box.setCompartments(compartments);
					}
					for(Compartment c : compartments){
							if(c.getType().equals("ASFictitiousSuperClasses")){
								superClasses = c.getSubCompartments();
								break;
							}
					}
					if (superClasses == null) {
						superClasses = new ArrayList<Compartment>();
						Compartment ASFictitiousClasses = createCompartment("ASFictitiousSuperClasses", "");
						ASFictitiousClasses.setIsMultiline(true);
						ASFictitiousClasses.setSubCompartments(superClasses);
						compartments.add(ASFictitiousClasses);
					}
					if(!getPreferenceParameterValue("showPropertyRestrictionsHideNotGraphical", preferences).equals("true")) createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
				}
			}
			
		} else if ((sType.equals("ObjectMaxCardinality") || sType.equals("ObjectMinCardinality") || sType.equals("ObjectExactCardinality"))){
			ArrayList<Compartment> compartments = box.getCompartments();
			ArrayList<Compartment> superClasses = null;
			if (compartments == null){
					compartments = new ArrayList<Compartment>();
					box.setCompartments(compartments);
			}
			for(Compartment c : compartments){
					if(c.getType().equals("ASFictitiousSuperClasses")){
						superClasses = c.getSubCompartments();
						break;
					}
			}
			if (superClasses == null) {
				superClasses = new ArrayList<Compartment>();
				Compartment ASFictitiousClasses = createCompartment("ASFictitiousSuperClasses", "");
				ASFictitiousClasses.setIsMultiline(true);
				ASFictitiousClasses.setSubCompartments(superClasses);
				compartments.add(ASFictitiousClasses);
			}
			ManchesterOWLSyntaxOWLObjectRendererImpl m = new ManchesterOWLSyntaxOWLObjectRendererImpl();
			
			Boolean classExists = false;
			for(Box b : boxes){
				if(b.getType().equals("Class")){
					Class c = (Class) b;
					if (c.getName().equals(m.render(superClassAxiom.getSuperClass()))) classExists = true;
				}
			}
			if(classExists!=true  && !getPreferenceParameterValue("showSubclassesHideNotGraphical", preferences).equals("true")) {
				createSuperClassAsText(superClassAxiom, superClasses, preferences, componentontology);
			};
		}
	}
	
	public static void createSubClassGeneralization(OWLSubClassOfAxiom subClassAxiom, Class box, ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology){
		ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
   		Box targetClass = null;
   		String namespace = "";
   		if(subClassAxiom.getSubClass().getSignature().size() == 1){
   			namespace = subClassAxiom.getSubClass().asOWLClass().getIRI().getNamespace();
   		}
		targetClass = getTargetBox(boxes, m.render(subClassAxiom.getSubClass()).replace("\n", "\\n"), namespace);
		if(targetClass != null){
			Class tclass = (Class) targetClass;
		OWLClass owlClass = tclass.getOwlClass();
		if(!componentontology.getSubClassAxiomsForSubClass(owlClass).contains(subClassAxiom)){
			Line generalization = new Line(targetClass, box, "Generalization");
   			lines.add(generalization);
		}}
	}
	
	//public static void createEquivalentOrDisjoinClassesGraphically(String type, String label, OWLClass co, Set<OWLClass> classesInSignature, ArrayList<Box> boxes, ArrayList<Line> lines, Box box, Set<OWLAnnotation> annotations){
	public static void createEquivalentOrDisjoinClassesGraphically(String type, String label, OWLClass co, Set<OWLClassExpression> classesInSignature, ArrayList<Box> boxes, 
			ArrayList<Line> lines, Box box, Set<OWLAnnotation> annotations, String[] prefixesArray, OWLOntology componentontology, JsonObject preferences, Map<String, String> prefixesMap){
			Box targetClass = null;
			ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
			String parameterType;
			if(type.equals("Disjoint")) parameterType = "showDisjointClassesHideNotGraphical";
			else parameterType = "showEquivalentClassesHideNotGraphical";
			for(OWLClassExpression typeCl: classesInSignature){
			   	if(!typeCl.equals(co)){
			   		String namespace = "";
			   		if(typeCl.getSignature().size() == 1 && typeCl.getClassExpressionType().toString().equals("Class")){
			   			namespace = typeCl.asOWLClass().getIRI().getNamespace();
			   		}
			   		targetClass = getTargetBox(boxes, m.render(typeCl), namespace);
			   		Boolean lineCreated = createDottedLine(lines, type, box, targetClass, label, annotations, prefixesArray, prefixesMap);
			   		
			   		if (lineCreated == false && !getPreferenceParameterValue(parameterType, preferences).equals("true")) {
			   			if(type.equals("Disjoint")) {
			   				if(!getPreferenceParameterValue("showDisjointClassesHideNotGraphical", preferences).equals("true")) createDisjointClassesAsText((Class)box, componentontology, box.getCompartments(), false, null);
			   			}
			   			else if(!getPreferenceParameterValue("showEquivalentClassesHideNotGraphical", preferences).equals("true")){ createEquivalentClassesAsText((Class)box, componentontology, box.getCompartments(), false, null);}
			   		}
	   			}
	   		}	
	}
	
	public static void createSameAsOrDifferentIndivideGraphically(String type, String label, OWLIndividual individual, 
			Set<OWLIndividual> individualsInSignature, ArrayList<Box> boxes, ArrayList<Line> lines, Box box, Set<OWLAnnotation> annotations, 
			String[] prefixesArray, JsonObject preferences, Map<String, String> prefixesMap){
		Box targetBox = null;
		for(OWLIndividual typeIn: individualsInSignature){
   			Boolean lineCreted = false;
			if(!typeIn.equals(individual)){
   				targetBox = getTargetIndividualBox(boxes, typeIn);
   				lineCreted = createDottedLine(lines, type, box, targetBox, label, annotations, prefixesArray, prefixesMap);
			}
			if(lineCreted==false){
				ManchesterOWLSyntaxOWLObjectRendererImpl m = new ManchesterOWLSyntaxOWLObjectRendererImpl();
				if(type.equals("different") && getPreferenceParameterValue("showDifferentIndividualsHideNotGraphical", preferences).equals("true") && !typeIn.equals(individual)){
					ArrayList<Compartment> compartments = box.getCompartments();
					ArrayList<Compartment> superClasses = null;
					if (compartments == null){
							compartments = new ArrayList<Compartment>();
							box.setCompartments(compartments);
					}
					for(Compartment c : compartments){
							if(c.getType().equals("ASFictitiousDifferentIndividuals")){
								superClasses = c.getSubCompartments();
								break;
							}
					}
					if (superClasses == null) {
						superClasses = new ArrayList<Compartment>();
						Compartment ASFictitiousClasses = createCompartment("ASFictitiousDifferentIndividuals", "");
						ASFictitiousClasses.setIsMultiline(true);
						ASFictitiousClasses.setSubCompartments(superClasses);
						compartments.add(ASFictitiousClasses);
					}
					
					Compartment compIndividual = createCompartment(type, "");
					ArrayList<Compartment> compIndividualCompartments = new ArrayList<Compartment>();
					compIndividual.setSubCompartments(compIndividualCompartments);
					compIndividualCompartments.add(createCompartment("Individual", m.render(typeIn)));
					
					String namespace = "";
					namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
					
					compIndividualCompartments.add(createCompartment("Namespace", namespace));
					superClasses.add(compIndividual);
				} else if (type.equals("sameAs") && getPreferenceParameterValue("showSameIndividualsHideNotGraphical", preferences).equals("true") && !typeIn.equals(individual)){
					ArrayList<Compartment> compartments = box.getCompartments();
					ArrayList<Compartment> superClasses = null;
					if (compartments == null){
							compartments = new ArrayList<Compartment>();
							box.setCompartments(compartments);
					}
					for(Compartment c : compartments){
							if(c.getType().equals("ASFictitiousSameIndividuals")){
								superClasses = c.getSubCompartments();
								break;
							}
					}
					if (superClasses == null) {
						superClasses = new ArrayList<Compartment>();
						Compartment ASFictitiousClasses = createCompartment("ASFictitiousSameIndividuals", "");
						ASFictitiousClasses.setIsMultiline(true);
						ASFictitiousClasses.setSubCompartments(superClasses);
						compartments.add(ASFictitiousClasses);
					}
					
					Compartment compIndividual = createCompartment(type, "");
					ArrayList<Compartment> compIndividualCompartments = new ArrayList<Compartment>();
					compIndividual.setSubCompartments(compIndividualCompartments);
					compIndividualCompartments.add(createCompartment("Individual", m.render(typeIn)));
					
					String namespace = "";
					namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
					
					compIndividualCompartments.add(createCompartment("Namespace", namespace));
					superClasses.add(compIndividual);
				}
			}
		}
	}
	
	public static Boolean createDottedLine(ArrayList<Line> lines, String type, Box box, Box targetBox, String label, Set<OWLAnnotation> annotations, String[] prefixesArray, Map<String, String> prefixesMap){
		if (targetBox!= null && box!=null){
			//if not existing already
			for(Line line: lines){
				if (line.getType().equals(type) && line.getTarget().equals(box) && line.getSource().equals(targetBox)) return true;
			}
	
			Line eqClases = new Line(box, targetBox, type);
			lines.add(eqClases);
			ArrayList<Compartment> equivalentClassCompartemts = new ArrayList<Compartment>();
			eqClases.setCompartments(equivalentClassCompartemts);
			equivalentClassCompartemts.add(createCompartment("Label", label));
			
			//Annotation
			for (OWLAnnotation annotationAxiom : annotations) {
				createAnnotationCompartmentsFromAnnotations(equivalentClassCompartemts, annotationAxiom, prefixesArray, prefixesMap);
	    	} 
			return true;
		} 
		return false;
	}
	public static void createEquivalentClassesGraphically(Class box, ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology, Boolean calcProc, JsonObject preferences, String[] prefixesArray, Map<String, String> prefixesMap){
		OWLClass co = box.getOwlClass();
		Set<OWLEquivalentClassesAxiom> equivalentClassesAxioms = componentontology.getEquivalentClassesAxioms(co);
		if (calcProc == false) {
			for (OWLEquivalentClassesAxiom equivalentClassesAxiom : equivalentClassesAxioms) {	
				/*if (getPreferenceParameterValue("showEquivalentClassesGraphicsGroupAsBoxes", preferences).equals("true") && equivalentClassesAxiom.getClassesInSignature().size() > 2)  {
					createEquivalentClassesAsText(box, componentontology, box.getCompartments(), false, null);
				}
				else */
					createEquivalentOrDisjoinClassesGraphically("EquivalentClass", "equivalent", co, equivalentClassesAxiom.getClassExpressions(), boxes, lines, box, equivalentClassesAxiom.getAnnotations(), prefixesArray, componentontology, preferences, prefixesMap);
	       	}
		} else {
			for (OWLEquivalentClassesAxiom equivalentClassesAxiom : equivalentClassesAxioms) {	
				if (calculateParameterProcedure("showEquivalentClassesType", preferences).equals("Graphically") && (!getPreferenceParameterValue("showEquivalentClassesGraphicsGroupAsBoxes", preferences).equals("true") || equivalentClassesAxiom.getClassesInSignature().size() < 3)) createEquivalentOrDisjoinClassesGraphically("EquivalentClass", "equivalent", co, equivalentClassesAxiom.getClassExpressions(), boxes, lines, box, equivalentClassesAxiom.getAnnotations(), prefixesArray, componentontology, preferences, prefixesMap);
	       	}
		}
	}
	
	public static void createDisjointClassesGraphically(Class box, ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology, Boolean calcProc, JsonObject preferences, String[] prefixesArray, Map<String, String> prefixesMap){
		OWLClass co = box.getOwlClass();
		Set<OWLDisjointClassesAxiom> disjointClassesAxioms = componentontology.getDisjointClassesAxioms(co);
		if (calcProc == false) {
			for (OWLDisjointClassesAxiom disjointClassesAxiom : disjointClassesAxioms) {
				/*if (getPreferenceParameterValue("showDisjointClassesGraphicsGroupAsBoxes", preferences).equals("true") && disjointClassesAxiom.getClassesInSignature().size() > 2)  {
					createDisjointClassesAsText(box, componentontology, box.getCompartments(), false, null);
				}
				else */
					createEquivalentOrDisjoinClassesGraphically( "Disjoint", "disjoint", co, disjointClassesAxiom.getClassExpressions(), boxes, lines, box, disjointClassesAxiom.getAnnotations(), prefixesArray, componentontology, preferences, prefixesMap);
	       	}
		} else {
			for (OWLDisjointClassesAxiom disjointClassesAxiom : disjointClassesAxioms) {
				if (calculateParameterProcedure("showDisjointClassesType", preferences).equals("Graphically") && (!calculateParameterProcedure("showDisjointClassesGraphicsGroupAsBoxes", preferences).equals("true") || disjointClassesAxiom.getClassesInSignature().size() < 3)) createEquivalentOrDisjoinClassesGraphically( "Disjoint", "disjoint", co, disjointClassesAxiom.getClassExpressions(), boxes, lines, box, disjointClassesAxiom.getAnnotations(), prefixesArray, componentontology, preferences, prefixesMap);
	       	}
		}
	}
	
	public static void createClassAnnotationsGraphically(Class box, OWLOntology componentontology, ArrayList<Box> boxes, ArrayList<Line> lines, Boolean calcProc, JsonObject preferences,
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap){
		OWLClass co = box.getOwlClass();
		if (co != null){
			Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms = componentontology.getAnnotationAssertionAxioms(co.getIRI());
			Boolean foundedComment = false;
			if (calcProc == false) {
				for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : classAnnotationAssertionAxioms) {
					Boolean exists = false;
					for(UserFieldsParameter userFieldParameter : userFieldsParameter) {
						if (classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals(userFieldParameter.getName()) && userFieldParameter.getType().equals("ForClass_ShowAnnotation_InField")){
							exists = true;
							break;
						}
					}
					if (getPreferenceParameterValue("showClassAnnotationsEnableSpecComments", preferences).equals("true") && foundedComment == false && classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("comment")){
						Boolean annotationsInLang = false;
						List<String> items = new ArrayList<String>();
						if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
				      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
				      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
				      	    	if(items.contains(classAnnotationAssertionAxiom.getValue().asLiteral().get().getLang().toString())) annotationsInLang = true;
				      	    } else annotationsInLang = true;
				      	} 
						
						if(annotationsInLang == true){
							foundedComment = true;
							createComment(classAnnotationAssertionAxiom, box.getCompartments());
						}
					} else if (exists == true){
						
					}
					else createClassAnnotation(classAnnotationAssertionAxiom, box, boxes, lines, null, prefixesArray, prefixesMap, preferences);
		    	}
			} else {			
				for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : classAnnotationAssertionAxioms) {
					if (calculateParameterProcedure("showClassAnnotationsType", preferences).equals("Graphically")) {
						
						if (getPreferenceParameterValue("showClassAnnotationsEnableSpecComments", preferences).equals("true") && foundedComment == false && classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("comment")){
							Boolean annotationsInLang = false;
							List<String> items = new ArrayList<String>();
							if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
					      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
					      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
					      	    	if(items.contains(classAnnotationAssertionAxiom.getValue().asLiteral().get().getLang().toString())) annotationsInLang = true;
					      	    } else annotationsInLang = true;
					      	} 
							
							if(annotationsInLang == true){
								foundedComment = true;
								createComment(classAnnotationAssertionAxiom, box.getCompartments());
							}
						} else createClassAnnotation(classAnnotationAssertionAxiom, box, boxes, lines, null, prefixesArray, prefixesMap, preferences);
					}
		    	}
			}
			createAnnotationsAsTextFromAxiomForUserField(calcProc, preferences, classAnnotationAssertionAxioms, box.getCompartments(), "Class", userFieldsParameter, false);
		}
	}
	
	public static void createAssociationAnnotationsGraphically(OWLObjectProperty op, Association newAssociation, OWLOntology componentontology, 
			ArrayList<Line> lines, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, ArrayList<UserFieldsParameter> userFieldsParameter, 
			ArrayList<Compartment> compartment, String[] prefixesArray, Map<String, String> prefixesMap, Boolean isAllValuesFrom, String source){
		Set<OWLAnnotationAssertionAxiom> opAnnotationAssertionAxioms = componentontology.getAnnotationAssertionAxioms(op.getIRI());
		if (calcProc == false) {
			for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : opAnnotationAssertionAxioms) {
				
				Boolean exists = false;
				for(UserFieldsParameter userFieldParameter : userFieldsParameter) {
					if (classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals(userFieldParameter.getName()) && userFieldParameter.getType().equals("ForRole_ShowAnnotation_InField")){
						exists = true;
						break;
					}
				}
				if (exists == false) createAssociationAnnotationGraphically(classAnnotationAssertionAxiom, newAssociation, boxes, lines, prefixesArray, prefixesMap, isAllValuesFrom);
	    	}
		} else {
			for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : opAnnotationAssertionAxioms) {
				if (calculateParameterProcedure("showObjectPropertyAnnotationsType", preferences).equals("Graphically")) createAssociationAnnotationGraphically(classAnnotationAssertionAxiom, newAssociation, boxes, lines, prefixesArray, prefixesMap, isAllValuesFrom);
	    	}
		}
		createAnnotationsAsTextFromAxiomForUserField(calcProc, preferences, opAnnotationAssertionAxioms, compartment, "Association", userFieldsParameter, isAllValuesFrom);
	}
	
	public static void createAttributeAnnotationsGraphically(OWLDataProperty dp, OWLOntology componentontology, ArrayList<Compartment> compartments, 
			Class clazz, ArrayList<Line> lines, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, 
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap, Boolean isAllValuesFrom, String subject){
		Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms = componentontology.getAnnotationAssertionAxioms(dp.getIRI());
		if (calcProc == false) {
			for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : classAnnotationAssertionAxioms) {
				if(!classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().toString().equals("schema") || (classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().toString().equals("schema") && avf == false)){
					Boolean exists = false;
					for(UserFieldsParameter userFieldParameter : userFieldsParameter) {
						if (classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals(userFieldParameter.getName()) && userFieldParameter.getType().equals("ForAttr_ShowAnnotation_InField")){
							exists = true;
							break;
						}
					}
					
					if(exists == false) {
						Boolean contextInAnnotation = false;
						for(OWLAnnotation annot: classAnnotationAssertionAxiom.getAnnotations()){
							if(annot.getProperty().getIRI().getShortForm().equals("Context") && avf == true && annot.getValue().toString().endsWith(subject)) contextInAnnotation = true;
						}
						if(isAllValuesFrom != true || (isAllValuesFrom == true && contextInAnnotation == true)){createClassAnnotation(classAnnotationAssertionAxiom, clazz, boxes, lines, dp.getIRI().getShortForm(), prefixesArray, prefixesMap, preferences);}
					}
				}
	    	}
			
			createAnnotationsAsTextFromAxiomForUserField(calcProc, preferences, classAnnotationAssertionAxioms, compartments, "Attribute", userFieldsParameter, isAllValuesFrom);
			
		} else {
			for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : classAnnotationAssertionAxioms) {
				if (calculateParameterProcedure("showDataPropertiesAnnotationType", preferences).equals("Graphically")) createClassAnnotation(classAnnotationAssertionAxiom, clazz, boxes, lines, dp.getIRI().getShortForm(), prefixesArray, prefixesMap, preferences);
	    	}
		}
	}
	
	public static void createIndividualAnnotationsGraphically(Individual box, OWLOntology componentontology, ArrayList<Box> boxes, ArrayList<Line> lines, Boolean calcProc, JsonObject preferences, 
			ArrayList<UserFieldsParameter> userFieldsParameter, String[] prefixesArray, Map<String, String> prefixesMap)
	{
		OWLIndividual individual = box.getIndividual();
		if (individual != null){
			Set<OWLAnnotationAssertionAxiom> classAnnotationAssertionAxioms = componentontology.getAnnotationAssertionAxioms(((OWLNamedIndividual)individual).getIRI());
			if (calcProc == false) {
				for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : classAnnotationAssertionAxioms) {
					Boolean exists = false;
					for(UserFieldsParameter userFieldParameter : userFieldsParameter) {
						if (classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals(userFieldParameter.getName()) && userFieldParameter.getType().equals("ForIndiv_ShowAnnotation_InField")){
							exists = true;
							break;
						}
					}
					
					if(exists == false) createClassAnnotation(classAnnotationAssertionAxiom, box, boxes, lines, null, prefixesArray, prefixesMap, preferences);
		    	}
			} else {
				for (OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom : classAnnotationAssertionAxioms) {
					if (calculateParameterProcedure("showIndividualAnnotationType", preferences).equals("Graphically")) createClassAnnotation(classAnnotationAssertionAxiom, box, boxes, lines, null, prefixesArray, prefixesMap, preferences);
		    	}
			}
		}
	}	
	
	public static void createOntologyAnnotationsInDiagram(OWLOntology componentontology, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, String[] prefixesArray, Map<String, String> prefixesMap){
		if (calcProc == false) {
			for (OWLAnnotation ontologyAnnotation : componentontology.getAnnotations()) {
				
				Box box = createOntologyAnnotation(ontologyAnnotation, boxes, prefixesArray, prefixesMap);
				
				for(OWLAnnotation aa: ontologyAnnotation.getAnnotations()){
					if(aa.getProperty().getIRI().getShortForm().equals("Container")){
						Box container = getContainer(aa.getValue().toString().substring(1, aa.getValue().toString().length()-1), boxes, boxes);
				        box.setContainer(container);
				        container.setElemCount(container.getElemCount() + 1);
					}
					/*if(aa.getProperty().getIRI().getShortForm().equals("Fragment")){
						removeFromDiagramm = true;
						getOntology(aa.getValue().toString().substring(1, aa.getValue().toString().length()-1), box, boxes, needToBeAddedToBoxes, ontologies);
					}*/
				}
				
				if (box.getContainer() == null && getPreferenceParameterValue("useContainersForSingleNodes", preferences).equals("true") 
						&& getPreferenceParameterValue("useContainersForSingleNodesOntoAnnotations", preferences).equals("true")){
					if(!getPreferenceParameterValue("useContainersForSingleNodesOntoAnnotationsSeparate", preferences).equals("true")){
						Box container = getContainer("Container_for_single_nodes", boxes, boxes);
				        box.setContainer(container);
				        container.setElemCount(container.getElemCount() + 1);
			        } else {
			        	Box container = getContainer("Container_for_ontology_annotations", boxes, boxes);
				        box.setContainer(container);
				        container.setElemCount(container.getElemCount() + 1);
			        }
				}
	    	}
		} else {
			for (OWLAnnotation ontologyAnnotation : componentontology.getAnnotations()) {
				if (getPreferenceParameterValue("showOntoAnnotationsInSeed", preferences).equals("Show in diagram")) createOntologyAnnotation(ontologyAnnotation, boxes, prefixesArray, prefixesMap);
			}
		}
	}
	
	public static void createOntologyAnnotationProperties(OWLOntology componentontology, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, 
			String[] prefixesArray, Map<String, String> prefixesMap, ArrayList<Ontology> ontologies){
		if (calcProc == false) {
			for (OWLAnnotationProperty ap :  componentontology.getAnnotationPropertiesInSignature()){
				Box newAnnotationProperty = createOntologyAnnotationProperty(componentontology, ap, boxes, prefixesArray, prefixesMap);
				if(newAnnotationProperty != null){
					Boolean removeFromBoxes = createContainerFromAnnotationAxiom(componentontology.getAnnotationAssertionAxioms(ap.getIRI()),  componentontology, boxes, boxes, newAnnotationProperty, ontologies, null);
					if(removeFromBoxes == true) boxes.remove(newAnnotationProperty);
					
					if (newAnnotationProperty.getContainer() == null && getPreferenceParameterValue("useContainersForSingleNodes", preferences).equals("true") 
							&& getPreferenceParameterValue("useContainersForSingleNodesAnnotPropDefs", preferences).equals("true")){
						if(!getPreferenceParameterValue("useContainersForSingleNodesAnnotPropDefsSeparate", preferences).equals("true")){
							Box container = getContainer("Container_for_single_nodes", boxes, boxes);
							newAnnotationProperty.setContainer(container);
							container.setElemCount(container.getElemCount() + 1);
				        } else {
				        	Box container = getContainer("Container_for_annot_prop", boxes, boxes);
				        	newAnnotationProperty.setContainer(container);
				        	container.setElemCount(container.getElemCount() + 1);
				        }
					}
				}
	        }
		} else {
			for (OWLAnnotationProperty ap : componentontology.getAnnotationPropertiesInSignature()) {
				if (calculateParameterProcedure("showAnnotationPropertyDefs", preferences).equals("true")) createOntologyAnnotationProperty(componentontology, ap, boxes, prefixesArray, prefixesMap);
			}
		}
	}
	
	public static void createOntologyDataTypes(OWLOntology componentontology, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, 
			String[] prefixesArray, Map<String, String> prefixesMap, ArrayList<Ontology> ontologies){
		if (calcProc == false) {
			for (OWLDatatype ap :  componentontology.getDatatypesInSignature()){
				Box dataType = createOntologyDataType(componentontology, ap, boxes, prefixesArray, prefixesMap, ontologies, preferences);
				Boolean removeFromBoxes = createContainerFromAnnotationAxiom(componentontology.getAnnotationAssertionAxioms(ap.getIRI()),  componentontology, boxes, boxes, dataType, ontologies, null);
				if(removeFromBoxes == true) boxes.remove(dataType);
	        }
		} else {
			for (OWLDatatype ap :  componentontology.getDatatypesInSignature()) {
				if (calculateParameterProcedure("showDataTypes", preferences).equals("true")) createOntologyDataType(componentontology, ap, boxes, prefixesArray, prefixesMap, ontologies, preferences);
			}
		}
	}
	
	public static void createSubClassesAsForks(ArrayList<Line> lines, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences){
		if (calcProc == false) {
			ArrayList<Box> needToBeAddedToboxes = new ArrayList<Box>();
			for (Box box : boxes){
				if(box.getType().equals("Class")){
					Class clazz = (Class) box;
					int apereanceCount = 0;
					for(Line line : lines){
						if(line.getType().equals("Generalization")){
							if (line.getTarget() == clazz) apereanceCount++;
						}
					}
					if(apereanceCount > 1) needToBeAddedToboxes.add(createHorizontalFork(clazz, lines, boxes));
				}
			}
			boxes.addAll(needToBeAddedToboxes);
		} else {
			//TODO
		}
	}
	
	//so pirms disjoint kastisu veidosanas
	public static void createDisjointClassesMarkAtForks(ArrayList<Box> boxes, ArrayList<Line> lines, OWLOntology componentontology,  Boolean calcProc, JsonObject preferences){
		for (Box box : boxes){
			if (box.getType().equals("HorizontalFork")){
				ArrayList<Class> classes = new ArrayList<Class>();
				for (Line line : lines){
					if (line.getType().equals("AssocToFork") && line.getTarget().equals(box)){
						classes.add((Class) line.getSource());
					}
				}
				Boolean disjoint = true;
				
				for(Class clazz : classes){
					if(clazz != null){
						for(Class disclazz : classes){
							boolean isDisjiontToclazz = false;
							for(OWLDisjointClassesAxiom disj : componentontology.getDisjointClassesAxioms(clazz.getOwlClass())){
								if (disj.contains(disclazz.getOwlClass())){
									isDisjiontToclazz = true;
								}
							}
							if(isDisjiontToclazz == false) disjoint = false;
						}
					}
				}
				
				if (disjoint!= null && disjoint) {
					ArrayList<Compartment> compartments = box.getCompartments();
					compartments.add(createCompartment("Disjoint", "true"));
					//delete all disjoint link between classes
					deleteDisjointOrEquivalentLinks(lines, "Disjoint", classes, null);
					
				}
			}
		}
	}
	
	public static void createDisjointOrEquivalentClassesGraphicsAsBoxes2(ArrayList<Line> lines, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, String lineType, OWLOntology componentontology){
		if (calcProc == false) {
			ArrayList<Box> needToBeAddedToboxes = new ArrayList<Box>();
			if (lineType.equals("EquivalentClass")){
			 for (OWLAxiom ax :   componentontology.getAxioms()) {
		        	if (ax.getAxiomType().toString().equals("EquivalentClasses") && ax.getClassesInSignature().size() > 2 ) {
		        		needToBeAddedToboxes.add(createDisjointOrEquivalentBox2(lines, boxes, lineType, ax.getClassesInSignature()));
		        	}
			 }
			} else {
				 for (OWLAxiom ax :   componentontology.getAxioms()) {
			        	if (ax.getAxiomType().toString().equals("DisjointClasses") && ax.getClassesInSignature().size() > 2 ) {
			        		needToBeAddedToboxes.add(createDisjointOrEquivalentBox2(lines, boxes, lineType, ax.getClassesInSignature()));
			        	}
				 }
			}
			boxes.addAll(needToBeAddedToboxes);
		} else {
			//TODO
		}
	}
	
	public static ArrayList<Class> findDisjointOrEquivelentClassesToGivenOne(ArrayList<Line> lines, Class clazz, String linkType){
		ArrayList<Class> disjointClassList = new ArrayList<Class>();
		//find all disjoint classes to given
		disjointClassList.add(clazz);
		for(Line line: lines){
			if(line.getType().equals(linkType) ){
				if(line.getSource().equals(clazz)) disjointClassList.add((Class) line.getTarget());
				if(line.getTarget().equals(clazz)) disjointClassList.add((Class) line.getSource());
			}
		}
		return disjointClassList;
	}
	
	public static void createDisjointOrEquivalentClassesGraphicsAsBoxes(ArrayList<Line> lines, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, String lineType, OWLOntology componentontology){
		if (calcProc == false) {
			ArrayList<Box> needToBeAddedToboxes = new ArrayList<Box>();
			for(Box box: boxes){
				if (box.getType().equals("Class")){
					Class clazz = (Class) box;
					ArrayList<Class> disjointClassList = findDisjointOrEquivelentClassesToGivenOne(lines, clazz, lineType);

					//for all disjoint classes
					if(disjointClassList.size() > 2){
						Boolean needBox = true;
						for(Class c : disjointClassList){
							ArrayList<Class> disjointClassListCopy = findDisjointOrEquivelentClassesToGivenOne(lines, clazz, lineType);
							ArrayList<Class> disjointCList = findDisjointOrEquivelentClassesToGivenOne(lines, c, lineType);
							disjointClassListCopy.removeAll(disjointCList);
							if (!disjointClassListCopy.isEmpty()){
								needBox = false;
							}
						}
						if (needBox == true){
							//create box element + connectors
							Box b = createDisjointOrEquivalentBox(lines, boxes, lineType, disjointClassList);
							needToBeAddedToboxes.add(b);
							//delete links
							deleteDisjointOrEquivalentLinks(lines, lineType, disjointClassList, b.getCompartments());
						}
					}
				}
			}
			boxes.addAll(needToBeAddedToboxes);
		} else {
			//TODO
		}
	}
	
	public static void createSubclassesAutoForksForDisjoint(ArrayList<Line> lines, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, OWLOntology componentontology){
		ManchesterOWLSyntaxOWLObjectRendererImpl m = new ManchesterOWLSyntaxOWLObjectRendererImpl();
		ArrayList<Box> needToAddToBoxes = new ArrayList<Box>();
		for (Iterator<Box> iterbox = boxes.listIterator(); iterbox.hasNext(); ){
			Box box = iterbox.next();
			//for (Box box : boxes){
			//cauri katrai DisjointClasses kastei
			if (box.getType().equals("DisjointClasses")){
				//atrast visas klases, kas saistas ar doto disjoint kasti
				ArrayList<Class> classes = new ArrayList<Class>();
				for (Line line : lines){
					if (line.getType().equals("Connector") && line.getTarget().equals(box)){
						classes.add((Class) line.getSource());	
					}
				}
				//parbaudit vai virsklase ir viena un ta pati
				for(OWLSubClassOfAxiom subClassAxiom : componentontology.getSubClassAxiomsForSubClass(classes.get(0).getOwlClass())){
					Boolean sameSuperClass = true;
					for(Class cl : classes){
						for(OWLSubClassOfAxiom subCA : componentontology.getSubClassAxiomsForSubClass(cl.getOwlClass())){
							if(!subCA.getSuperClass().equals(subClassAxiom.getSuperClass())) sameSuperClass = false;
						}
					}
					if(sameSuperClass) {
						//atrast virsklasi
						for (Box b : boxes){
							if(b.getType().equals("Class")){
								Class cl = (Class) b;
								
								if(cl.getName().equals(m.render(subClassAxiom.getSuperClass()))){
									Box horizontalFork = new Box();
									horizontalFork.setType("HorizontalFork");
									
									for(Line l: lines){
										if(l.getType().equals("GeneralizationToFork") && l.getTarget().equals(cl)){
											for(Box bb: boxes){
												if(bb.getType().equals("HorizontalFork") && bb.equals(l.getSource())){
													for(Class c : classes){
														for(Line ll : lines){
															if(ll.getType().equals("AssocToFork") && ll.getTarget().equals(bb) && ll.getSource().equals(c)){
																ll.setTarget(horizontalFork);
															}
														}
													}
												}
											}
										}
									}
									
									ArrayList<Compartment> compartments = new ArrayList<Compartment>();
									Compartment forkStyle = createCompartment("ForkStyle", "");
									compartments.add(forkStyle);
									Compartment disjointMakr = createCompartment("Disjoint", "true");
									compartments.add(disjointMakr);
									horizontalFork.setCompartments(compartments);
									
									Line generalizationToFork = new Line(horizontalFork, cl, "GeneralizationToFork");
									lines.add(generalizationToFork);
									
									needToAddToBoxes.add(horizontalFork);
									
									for (Iterator<Line> iter = lines.listIterator(); iter.hasNext(); ) {
									    Line line = iter.next();
									    if(line.getType().equals("Connector") && line.getTarget().equals(box)){
											iter.remove();
										}
									}
								}
							}
						}
						iterbox.remove();
					}
				}
				
			}
		}
		boxes.addAll(needToAddToBoxes);
	}
	
	public static void createSameAsOrDifferentIndividualsGraphicsAsBoxes(ArrayList<Line> lines, ArrayList<Box> boxes, Boolean calcProc, JsonObject preferences, String lineType, 
			OWLOntology componentontology, String[] prefixesArray, Map<String, String> prefixesMap){
		if (calcProc == false) {
			ArrayList<Box> needToBeAddedToboxes = new ArrayList<Box>();
			if (lineType.equals("SameAsIndivid")){
			 for (OWLAxiom ax :   componentontology.getAxioms()) {
		        	if (ax.getAxiomType().toString().equals("SameIndividual") && ax.getIndividualsInSignature().size() > 2 ) {
		        		
		        		Box b = createSameAsOrDifferentBox(lines, boxes, lineType, ax.getIndividualsInSignature());
		        		needToBeAddedToboxes.add(b);
		        		
		        		for (OWLAnnotation annotationAxiom : ax.getAnnotations()) {
		    				createAnnotationCompartmentsFromAnnotations(b.getCompartments(), annotationAxiom, prefixesArray, prefixesMap);
		    	    	} 
		        	}
			 }
			} else {
				 for (OWLAxiom ax :   componentontology.getAxioms()) {
			        	if (ax.getAxiomType().toString().equals("DifferentIndividuals") && ax.getIndividualsInSignature().size() > 2 ) {

			        		Box b = createSameAsOrDifferentBox(lines, boxes, lineType, ax.getIndividualsInSignature());
			        		needToBeAddedToboxes.add(b);
			        		
			        		for (OWLAnnotation annotationAxiom : ax.getAnnotations()) {
			    				createAnnotationCompartmentsFromAnnotations(b.getCompartments(), annotationAxiom, prefixesArray, prefixesMap);
			    	    	} 
			        	}
				 }
			}
			boxes.addAll(needToBeAddedToboxes);
		} else {
			//TODO
		}
	}
	
	public static Box createSameAsOrDifferentBox(ArrayList<Line> lines, ArrayList<Box> boxes, String lineType, Set<OWLNamedIndividual> indiv){
		String boxType = null;
		String label = null;
		if(lineType.equals("DifferentIndivid")) {
			boxType = "DifferentIndivids";
			label = "different";
		} else if(lineType.equals("SameAsIndivid")) {
			boxType = "SameAsIndivids";
			label = "sameAs";
		}
		Box classBox = new Box();
		classBox.setType(boxType);
		
		ArrayList<Compartment> compartments = new ArrayList<Compartment>();
		Compartment labelComp = createCompartment("Label", label);
		compartments.add(labelComp);
		classBox.setCompartments(compartments);
		
		ArrayList<Line> needTobeAddedTolines = new ArrayList<Line>();
		
		Boolean notInContainer = null;
		Box container = null;
		
		for(Box box : boxes){
			if (box.getType().equals("Object")){
				Individual in = (Individual) box;
				if (indiv.contains(in.getIndividual())) {
					needTobeAddedTolines.add( new Line(in, classBox, "Connector"));
					//check if classes are in container and container is the same for all classes
					if(in.getContainer() != null) {
						if(container == null){
							container = in.getContainer();
						} else {
							if(!container.equals(in.getContainer())){
								notInContainer = true;
							}
						}
					}
				}
			}
		}
		if(notInContainer == null) classBox.setContainer(container);
		lines.addAll(needTobeAddedTolines);
		return classBox;
	}
	
	public static void deleteDisjointOrEquivalentLinks(ArrayList<Line> lines, String lineType, ArrayList<Class> classes, ArrayList<Compartment> compartments){
		Compartment annotation = null;
		for (Iterator<Line> iter = lines.listIterator(); iter.hasNext(); ) {
		    Line line = iter.next();
		    if(line.getType().equals(lineType)){
				if (classes.contains(line.getTarget()) && classes.contains(line.getSource())) {
					for(Compartment comp : line.getCompartments()){
						if(comp.getType().equals("Annotation")){
							annotation = comp;
						}
					}
					iter.remove();
				}
			}
		}
		if(annotation != null && compartments != null) compartments.add(annotation);
	}
	
	public static Box createDisjointOrEquivalentBox(ArrayList<Line> lines, ArrayList<Box> boxes, String lineType, ArrayList<Class> classes){
		String boxType = null;
		String label = null;
		if(lineType.equals("Disjoint")) {
			boxType = "DisjointClasses";
			label = "disjoint";
		} else if(lineType.equals("EquivalentClass")) {
			boxType = "EquivalentClasses";
			label = "equivalent";
		}
		Box classBox = new Box();
		classBox.setType(boxType);
		
		ArrayList<Compartment> compartments = new ArrayList<Compartment>();
		Compartment labelComp = createCompartment("Label", label);
		compartments.add(labelComp);
		classBox.setCompartments(compartments);
		
		ArrayList<Line> needTobeAddedTolines = new ArrayList<Line>();

		Boolean notInContainer = null;
		Box container = null;
		
		for(Box clazz : classes){
			needTobeAddedTolines.add(new Line(clazz, classBox, "Connector"));
			//check if classes are in container and container is the same for all classes
			if(clazz.getContainer() != null) {
				if(container == null){
					container = clazz.getContainer();
				} else {
					if(!container.equals(clazz.getContainer())){
						notInContainer = true;
					}
				}
			}
		}

		if(notInContainer == null) classBox.setContainer(container);
		
		lines.addAll(needTobeAddedTolines);
		return classBox;
	}
	
	public static Box createDisjointOrEquivalentBox2(ArrayList<Line> lines, ArrayList<Box> boxes, String lineType, Set<OWLClass> classes){
		String boxType = null;
		String label = null;
		if(lineType.equals("Disjoint")) {
			boxType = "DisjointClasses";
			label = "disjoint";
		} else if(lineType.equals("EquivalentClass")) {
			boxType = "EquivalentClasses";
			label = "equivalent";
		}
		Box classBox = new Box();
		classBox.setType(boxType);
		
		ArrayList<Compartment> compartments = new ArrayList<Compartment>();
		Compartment labelComp = createCompartment("Label", label);
		compartments.add(labelComp);
		classBox.setCompartments(compartments);
		
		ArrayList<Line> needTobeAddedTolines = new ArrayList<Line>();

		for(Box box : boxes){
			if (box.getType().equals("Class")){
				Class cl = (Class) box;
				if (classes.contains(cl.getOwlClass())) {
					needTobeAddedTolines.add( new Line(cl, classBox, "Connector"));
				}
			}
		}
		
		
		lines.addAll(needTobeAddedTolines);
		return classBox;
	}
	
	public static Box createHorizontalFork(Class clazz, ArrayList<Line> lines, ArrayList<Box> boxes){
		Box horizontalFork = new Box();
		horizontalFork.setType("HorizontalFork");
		
		ArrayList<Compartment> compartments = new ArrayList<Compartment>();
		Compartment forkStyle = createCompartment("ForkStyle", "");
		compartments.add(forkStyle);
		horizontalFork.setCompartments(compartments);
		
		Line generalizationToFork = new Line(horizontalFork, clazz, "GeneralizationToFork");
		lines.add(generalizationToFork);
		
		Box container = clazz.getContainer();
		Boolean notInContainer = null;
		
		ArrayList<Line> needTobeAddedTolines = new ArrayList<Line>();
		
		for (Iterator<Line> iter = lines.listIterator(); iter.hasNext(); ) {
		    Line line = iter.next();
		    if(line.getType().equals("Generalization")){
				if (line.getTarget() == clazz) {
					Line assocToFork = new Line(line.getSource(), horizontalFork, "AssocToFork");
					needTobeAddedTolines.add(assocToFork);
					
					if(clazz.getContainer() != null) {
						if(container == null){
							notInContainer = true;
						} else {
							if(!container.equals(line.getTarget().getContainer())){
								notInContainer = true;
							}
						}
					}
					
					iter.remove();
				}
			}
		}
		if(notInContainer == null) horizontalFork.setContainer(container);
		for(Line line : lines){
			if(line.getType().equals("Generalization")){
				if (line.getTarget() == clazz) {
					Line assocToFork = new Line(line.getSource(), horizontalFork, "AssocToFork");
					needTobeAddedTolines.add(assocToFork);
					line = null;
				}
			}
		}
		lines.addAll(needTobeAddedTolines);
		return horizontalFork;
	}
	
	public static Box createOntologyDataType(OWLOntology componentontology, OWLDatatype ap, ArrayList<Box> boxes, String[] prefixesArray, 
			Map<String, String> prefixesMap, ArrayList<Ontology> ontologies, JsonObject preferences){
		if (!ap.isBuiltIn()){
			Box newAnnotation = new Box("DataType");
			boxes.add(newAnnotation);
	
			ArrayList<Compartment> compartments = new ArrayList<Compartment>();
			newAnnotation.setCompartments(compartments);
			
			String namespace = "";
			if ((!componentontology.getOntologyID().isAnonymous() 
					&& !ap.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
					&& !ap.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) || (
							componentontology.getOntologyID().isAnonymous() 
							&& !ap.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")
							)) namespace = ap.getIRI().getNamespace();
			//if (!ap.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") && !ap.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = ap.getIRI().getNamespace();
			
			namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
			Compartment newCompartment = createNameStructure(ap.getIRI().getShortForm().toString(), namespace);
			compartments.add(newCompartment);
			Compartment newLabel = createCompartment("Label", "<<DataType>>");
			compartments.add(newLabel);
			ManchesterOWLSyntaxOWLObjectRendererImpl  m =  new ManchesterOWLSyntaxOWLObjectRendererImpl();
			for (OWLDatatypeDefinitionAxiom dtd : componentontology.getDatatypeDefinitions(ap)){
				Compartment dataTypeDefinition = createCompartment("DataTypeDefinition", m.render(dtd.getDataRange()));
				compartments.add(dataTypeDefinition);
			}
			
			Boolean foundedComment = false;
			ArrayList<Compartment> classAnnotations = new ArrayList<Compartment>();
			for (OWLAnnotationAssertionAxiom dataTypeAnnotationAssertionAxiom : componentontology.getAnnotationAssertionAxioms(ap.getIRI())){
				if (getPreferenceParameterValue("showClassAnnotationsEnableSpecComments", preferences).equals("true") && foundedComment == false 
						&& dataTypeAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("comment")){
					Boolean annotationsInLang = false;
					List<String> items = new ArrayList<String>();
					if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
			      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
			      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
			      	    	if(items.contains(dataTypeAnnotationAssertionAxiom.getValue().asLiteral().get().getLang().toString())) annotationsInLang = true;
			      	    } else annotationsInLang = true;
			      	} 
					
					if(annotationsInLang == true){
						foundedComment = true;
						createComment(dataTypeAnnotationAssertionAxiom, compartments);
					}
				} else createAnnotationCompartmentsFromOWLAnnotationAssertionAxioms(classAnnotations, dataTypeAnnotationAssertionAxiom, prefixesArray, prefixesMap);
			}
			createASFictitiousForMultiLineCompartments(classAnnotations, compartments, "ASFictitiousAnnotation"); 
			return newAnnotation;
		}
		return null;
	}
	
	public static Box createOntologyAnnotationProperty(OWLOntology componentontology, OWLAnnotationProperty ap, ArrayList<Box> boxes, String[] prefixesArray, Map<String, String> prefixesMap){
		if (!ap.isBuiltIn()){
			if((!ap.getIRI().getShortForm().toString().equals("schema") || (ap.getIRI().getShortForm().toString().equals("schema") && avf == false))
					&& !ap.getIRI().getShortForm().toString().equals("Container") 
					&& !ap.getIRI().getShortForm().toString().equals("Fragment") 
					&& (!ap.getIRI().getShortForm().toString().equals("Context") ||(ap.getIRI().getShortForm().toString().equals("Context") && avf == false))){
				Box newAnnotationProperty = new Box("AnnotationProperty");
				boxes.add(newAnnotationProperty);
				ArrayList<Compartment> compartments = new ArrayList<Compartment>();
				newAnnotationProperty.setCompartments(compartments);
				//System.out.println(componentontology.getAnnotationAssertionAxioms(ap.getIRI()));
				String namespace = "";
				if (!componentontology.getOntologyID().isAnonymous() && !ap.getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") && !ap.getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = ap.getIRI().getNamespace();
				namespace = namespaceValueAnnotationProperty(prefixesArray, namespace, prefixesMap);
				
				Compartment newCompartment = createNameStructure(ap.getIRI().getShortForm().toString(), namespace);
				compartments.add(newCompartment);
				
				for (OWLAnnotationPropertyRangeAxiom range : componentontology.getAnnotationPropertyRangeAxioms(ap)){
	        		Compartment apRange = createCompartment("Range", "");
	        		compartments.add(apRange);
	        		
	        		//Name Namespace
	            	ArrayList<Compartment> subCompartments = new ArrayList<Compartment>();
	
	    			String namespaceR = "";
	    			if (!componentontology.getOntologyID().isAnonymous() && !range.getRange().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#")) namespaceR = range.getRange().getNamespace();
	    			
	            	
	            	subCompartments.add(createCompartment("Name", range.getRange().getShortForm()));
	            	subCompartments.add(createCompartment("Namespace", namespaceR));
	            	apRange.setSubCompartments(subCompartments);
	        	}
				
				for (OWLAnnotationPropertyDomainAxiom domain : componentontology.getAnnotationPropertyDomainAxioms(ap)){
	        		Compartment apDomain = createCompartment("Domain", "");
	        		compartments.add(apDomain);
	        		
	        		String namespaceD = "";
	    			if (!componentontology.getOntologyID().isAnonymous() && !domain.getDomain().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#")) namespaceD = domain.getDomain().getNamespace();
	    			
	        		
	        		//Name Namespace
	            	ArrayList<Compartment> subCompartments = new ArrayList<Compartment>();
	            	subCompartments.add(createCompartment("Name", domain.getDomain().getShortForm()));
	            	subCompartments.add(createCompartment("Namespace", namespaceD));
	            	apDomain.setSubCompartments(subCompartments);
	        	}
				
				
				Boolean foundedComment = false;
				ArrayList<Compartment> classAnnotations = new ArrayList<Compartment>();
				for (OWLAnnotationAssertionAxiom dataTypeAnnotationAssertionAxiom : componentontology.getAnnotationAssertionAxioms(ap.getIRI())){
					if (getPreferenceParameterValue("showClassAnnotationsEnableSpecComments", preferences).equals("true") && foundedComment == false 
							&& dataTypeAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("comment")){
						Boolean annotationsInLang = false;
						List<String> items = new ArrayList<String>();
						if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
				      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
				      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
				      	    	if(items.contains(dataTypeAnnotationAssertionAxiom.getValue().asLiteral().get().getLang().toString())) annotationsInLang = true;
				      	    } else annotationsInLang = true;
				      	} 
						
						if(annotationsInLang == true){
							foundedComment = true;
							createComment(dataTypeAnnotationAssertionAxiom, compartments);
						}
					} else createAnnotationCompartmentsFromOWLAnnotationAssertionAxioms(classAnnotations, dataTypeAnnotationAssertionAxiom, prefixesArray, prefixesMap);
				}
				createASFictitiousForMultiLineCompartments(classAnnotations, compartments, "ASFictitiousAnnotation"); 
				
				return newAnnotationProperty;
			}
    	}
		return null;
	}
	
	public static Box createOntologyAnnotation(OWLAnnotation classAnnotationAssertionAxiom, ArrayList<Box> boxes, String[] prefixesArray, Map<String, String> prefixesMap){
		String property = classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm();
		String namespace = "";
		String value = "";
		String lang = "";
		if(classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("isDefinedBy") 
				|| classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("seeAlso")
				|| classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("backwardCompatibleWith")
				|| classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("versionInfo")
				|| classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("priorVersion")
				|| classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("incompatibleWith")){
			value = classAnnotationAssertionAxiom.getValue().toString();
			lang ="";
			namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
			if(!namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
			namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		}else if(classAnnotationAssertionAxiom.getProperty().isBuiltIn() == false){
			value = classAnnotationAssertionAxiom.getValue().toString();
			lang="";
			if (value.startsWith("\"")){ 
				value = value.substring(1);
				if (value.contains("\"@")) {
					lang = value.substring(value.indexOf("\"@")+2, value.length());
					value = value.substring(0, value.indexOf("\"@"));
				}
				if (value.endsWith("\"")) value = value.substring(0, value.length()-1);
			}
			value = value.replace("\\\"", "\"");
			namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
			namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
		}else{
			if(!classAnnotationAssertionAxiom.getValue().asLiteral().toString().equals("Optional.absent()")){
				OWLLiteral annotation = (OWLLiteral) classAnnotationAssertionAxiom.getValue();
				value = annotation.getLiteral();
				lang = annotation.getLang();
				namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
				if(!namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
				namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
			} else {
				unexported.add(classAnnotationAssertionAxiom.toString());
				/*value = classAnnotationAssertionAxiom.getValue().toString();
				lang = "";
				namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
				if(!namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
				namespace = namespaceValue(prefixesArray, namespace, prefixesMap);*/
			}
		}
		Boolean annotationsInLang = false;
		List<String> items = new ArrayList<String>();
		if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
      	    	if(items.contains(lang)) annotationsInLang = true;
      	    } else annotationsInLang = true;
      	} 
		if(!value.equals("") &&  annotationsInLang == true){
			Box newAnnotation = new Box("Annotation");
			boxes.add(newAnnotation);
	
			ArrayList<Compartment> annatationCompartments = new ArrayList<Compartment>();
			newAnnotation.setCompartments(annatationCompartments);
	
			createAnnotationCompartments(property, value, lang, annatationCompartments, namespace, null);
			return newAnnotation;
		} else {
			unexported.add(classAnnotationAssertionAxiom.toString());
		}
		return null;
	}
	
	public static void createAssociationAnnotationGraphically(OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom, Association newAssociation, 
			ArrayList<Box> boxes, ArrayList<Line> lines, String[] prefixesArray, Map<String, String> prefixesMap, Boolean isAllValuesFrom){
		if((!classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("schema") || classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("schema") && avf == false)
				&& !classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("Container") 
				&& !classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("Fragment")){
			Boolean contextInAnnotation = false;
			for(OWLAnnotation annot: classAnnotationAssertionAxiom.getAnnotations()){
				if(annot.getProperty().getIRI().getShortForm().equals("Context") && avf == true) contextInAnnotation = true;
			}
			if(isAllValuesFrom != true || (isAllValuesFrom == true && contextInAnnotation == true)){
				String namespace = "";
				String value = "";
				String lang = "";
				String property = classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm();
				if(classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("isDefinedBy") || classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("seeAlso")){
					value = classAnnotationAssertionAxiom.getValue().toString();
					lang ="";
					namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
					if(!namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
					namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
				}else{
					if(!classAnnotationAssertionAxiom.getValue().asLiteral().toString().equals("Optional.absent()")){
						OWLLiteral annotation = (OWLLiteral) classAnnotationAssertionAxiom.getValue();
						value = annotation.getLiteral();
						lang = annotation.getLang();
						namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
						if(!namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
						namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
					}
				}
				if (!value.equals("")){
					Box newAnnotation = new Box("Annotation");
					boxes.add(newAnnotation);
			
					ArrayList<Compartment> annatationCompartments = new ArrayList<Compartment>();
					newAnnotation.setCompartments(annatationCompartments);
			
					createAnnotationCompartments(property, value, lang, annatationCompartments, namespace, "");
					//System.out.println("tttttttt " + newAnnotation + " " + newAssociation);
					//Connector
					Line newConnector = new Line(newAnnotation, newAssociation, "Connector");
					lines.add(newConnector);
				}else {
					unexported.add(classAnnotationAssertionAxiom.toString());
				}
			}
		}
	}
	
	public static void createClassAnnotation(OWLAnnotationAssertionAxiom classAnnotationAssertionAxiom, Box box, ArrayList<Box> boxes, ArrayList<Line> lines, String attributeAnnotaion, String[] prefixesArray, 
			Map<String, String> prefixesMap, JsonObject preferences){
		if((!classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("schema") ||(classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("schema") && avf == false))
				&& !classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("Container") 
				&& !classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("Fragment")){
			String namespace = "";
			String value = "";
			String lang = "";
			
			String property = classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm();
			if(classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("isDefinedBy") || classAnnotationAssertionAxiom.getProperty().getIRI().getShortForm().equals("seeAlso")){
				value = classAnnotationAssertionAxiom.getValue().toString();
				lang ="";
				namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
				if(!namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
				
			}else if(classAnnotationAssertionAxiom.getProperty().isBuiltIn() == false){
				value = classAnnotationAssertionAxiom.getValue().toString();
				lang="";
				if (value.startsWith("\"")){ 
					value = value.substring(1);
					if (value.contains("\"@")) {
						lang = value.substring(value.indexOf("\"@")+2, value.length());
						value = value.substring(0, value.indexOf("\"@"));
					}
					if (value.endsWith("\"")) value = value.substring(0, value.length()-1);
				}
				value = value.replace("\\\"", "\"");
				
				namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
			}
			else{
				if(!classAnnotationAssertionAxiom.getValue().asLiteral().toString().equals("Optional.absent()")){
					OWLLiteral annotation = (OWLLiteral) classAnnotationAssertionAxiom.getValue();
					value = annotation.getLiteral();
					lang = annotation.getLang();
					namespace = classAnnotationAssertionAxiom.getProperty().getIRI().getNamespace();
					if(!namespace.equals("http://www.w3.org/2000/01/rdf-schema#")) namespace = "";
				}
			}
			//ArrayList<String>
			Boolean annotationsInLang = false;
			List<String> items = new ArrayList<String>();
			//System.out.println(preferences);
			if (getPreferenceParameterProcName("showAnnotationsInLanguages", preferences).equals("")) {
	      	    if (!getPreferenceParameterValue("showAnnotationsInLanguages", preferences).equals("")){
	      	    	items = Arrays.asList(getPreferenceParameterValue("showAnnotationsInLanguages", preferences).split("\\s*,\\s*"));
	      	    	if(items.contains(lang)) annotationsInLang = true;
	      	    } else annotationsInLang = true;
	      	} 
			
			if(!value.equals("") && annotationsInLang == true){
				namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
				Box newAnnotation = new Box("Annotation");
				boxes.add(newAnnotation);
		
				ArrayList<Compartment> annatationCompartments = new ArrayList<Compartment>();
				newAnnotation.setCompartments(annatationCompartments);
		
				createAnnotationCompartments(property, value, lang, annatationCompartments, namespace, attributeAnnotaion);
				newAnnotation.setContainer(box.getContainer());
		
				//Connector
				Line newConnector = new Line(newAnnotation, box, "Connector");
				lines.add(newConnector);
			} else {
				unexported.add(classAnnotationAssertionAxiom.toString());
			}
		}
	}
	
	public static void createAnnotationCompartments(String property, String value, String lang, ArrayList<Compartment> annatationCompartments, String namespace, String attributeAnnotaion){
		
		value=value.replaceAll("\r", "\n");
		//AnnotationType
		annatationCompartments.add(createCompartment("AnnotationType", property));

		if(attributeAnnotaion!=null) annatationCompartments.add(createCompartment("Property", attributeAnnotaion));
		
		//Namespace
		annatationCompartments.add(createCompartment("Namespace", namespace));
		
		//ValueLanguage
		Compartment valueLanguage = createCompartment("ValueLanguage", "");
		annatationCompartments.add(valueLanguage);
		
		ArrayList<Compartment> valueLanguageCompartments = new ArrayList<Compartment>();
		valueLanguage.setSubCompartments(valueLanguageCompartments);
		
		//Value
		valueLanguageCompartments.add(createCompartment("Value", value.replace("\n", "\\n")));
		//Language
		valueLanguageCompartments.add(createCompartment("Language", lang));
	}
	
	public static void createDataPropertyAssertions(OWLNamedIndividual individual, ArrayList<Compartment> individualCompartments, JsonObject preferences, OWLOntology componentontology, boolean calcProc) {
		ArrayList<Compartment> dataPropertyAssertions = new ArrayList<Compartment>();	
		if (calcProc == false) {
			for(OWLDataPropertyAssertionAxiom dpaa : componentontology.getDataPropertyAssertionAxioms(individual)){
				createDataPropertyAssertion(dataPropertyAssertions, dpaa);
			}
    	} else {
    		for(OWLDataPropertyAssertionAxiom dpaa : componentontology.getDataPropertyAssertionAxioms(individual)){
    			if (calculateParameterProcedure("showIndividualsDataPropertyAssertions", preferences).equals("true")){
    				createDataPropertyAssertion(dataPropertyAssertions, dpaa);
    			}
    		}
    	}
    	createASFictitiousForMultiLineCompartments(dataPropertyAssertions, individualCompartments, "ASFictitiousDataPropertyAssertion");
	}
	
	public static void createNegativeDataPropertyAssertions(OWLNamedIndividual individual, ArrayList<Compartment> individualCompartments, JsonObject preferences, OWLOntology componentontology, boolean calcProc) {
		ArrayList<Compartment> dataPropertyAssertions = new ArrayList<Compartment>();	
		if (calcProc == false) {
			for(OWLNegativeDataPropertyAssertionAxiom dpaa : componentontology.getNegativeDataPropertyAssertionAxioms(individual)){
				createNegativeDataPropertyAssertion(dataPropertyAssertions, dpaa);
			}
    	} else {
    		for(OWLNegativeDataPropertyAssertionAxiom dpaa : componentontology.getNegativeDataPropertyAssertionAxioms(individual)){
    			if (calculateParameterProcedure("showIndividualsNegativeDataPropertyAssertions", preferences).equals("true")){
    				createNegativeDataPropertyAssertion(dataPropertyAssertions, dpaa);
    			}
    		}
    	}
    	createASFictitiousForMultiLineCompartments(dataPropertyAssertions, individualCompartments, "ASFictitiousNegativeDataPropertyAssertion");
	}
	
	public static void createDataPropertyAssertion(ArrayList<Compartment> dataPropertyAssertions, OWLDataPropertyAssertionAxiom dpaa){
		createPropertyAssertioncompartments(dataPropertyAssertions, dpaa.getProperty().asOWLDataProperty().getIRI().getShortForm(), dpaa.getObject().getLiteral(), dpaa.getObject().getDatatype().getIRI().getShortForm(), "DataPropertyAssertion");
	}
	
	public static void createNegativeDataPropertyAssertion(ArrayList<Compartment> dataPropertyAssertions, OWLNegativeDataPropertyAssertionAxiom dpaa){
		createPropertyAssertioncompartments(dataPropertyAssertions, dpaa.getProperty().asOWLDataProperty().getIRI().getShortForm(), dpaa.getObject().getLiteral(), dpaa.getObject().getDatatype().getIRI().getShortForm(), "NegativeDataPropertyAssertion");
	}
	
	public static void createPropertyAssertioncompartments(ArrayList<Compartment> dataPropertyAssertions, String property, String value, String type, String propertyType){
		Compartment dataPropertyAssertion = createCompartment(propertyType, "");
		dataPropertyAssertions.add(dataPropertyAssertion);
		ArrayList<Compartment> dataPropertyAssertionCompartments = new ArrayList<Compartment>();
		dataPropertyAssertion.setSubCompartments(dataPropertyAssertionCompartments);
		dataPropertyAssertionCompartments.add(createCompartment("Property", property));
		dataPropertyAssertionCompartments.add(createCompartment("Value", value));
		if (type != null){
		dataPropertyAssertionCompartments.add(createCompartment("Type", type));
		}
	}
	
	public static void createDisjointObjectProperties(Boolean calcProc, OWLOntology componentontology, OWLObjectProperty op, JsonObject preferences, ArrayList<Compartment> compartments){
		ArrayList<Compartment> superClasses = new ArrayList<Compartment>();

		if (calcProc == false) {
			for (OWLDisjointObjectPropertiesAxiom disjointObjectPropertiesAxiom : componentontology.getDisjointObjectPropertiesAxioms(op)){
				 for(OWLObjectProperty dop : disjointObjectPropertiesAxiom.getObjectPropertiesInSignature()){
		   			 if (!dop.getIRI().getShortForm().equals(op.getIRI().getShortForm())) {
		   				createMultiLineCompartments(superClasses,  dop.getIRI().getShortForm(), "DisjointProperties", "ASFictitiousDisjointProperty", "DisjointProperty", "Expression");
		   				
		   				if (!superClasses.isEmpty()){
		   					Compartment newDisjProperty = new Compartment("DisjointProperties", "");
			   				compartments.add(newDisjProperty);
		   					
		   					Compartment ASFictitiousClasses = createCompartment("ASFictitiousDisjointProperties", "");
		   		       	    ASFictitiousClasses.setIsMultiline(true);
		   		         	ASFictitiousClasses.setSubCompartments(superClasses);
		   		       	    compartments.add(ASFictitiousClasses);
		   		       	    
		   		       	    newDisjProperty.setSubCompartment(ASFictitiousClasses);
		   		       	}
		   				
		   			 }
		   		 }
			}
		} else {
			for (OWLDisjointObjectPropertiesAxiom disjointObjectPropertiesAxiom : componentontology.getDisjointObjectPropertiesAxioms(op)){	
				if (calculateParameterProcedure("showObjectPropertiesDisjointProperties", preferences).equals("true")) {
					for(OWLObjectProperty dop : disjointObjectPropertiesAxiom.getObjectPropertiesInSignature()){
			   			 if (!dop.getIRI().getShortForm().equals(op.getIRI().getShortForm())) {
			   				createMultiLineCompartments(superClasses,  dop.getIRI().getShortForm(), "DisjointProperties", "ASFictitiousDisjointProperty", "DisjointProperty", "Expression");
			   				
			   				if (!superClasses.isEmpty()){
			   					Compartment newDisjProperty = new Compartment("DisjointProperties", "");
				   				compartments.add(newDisjProperty);
			   					
			   					Compartment ASFictitiousClasses = createCompartment("ASFictitiousDisjointProperties", "");
			   		       	    ASFictitiousClasses.setIsMultiline(true);
			   		         	ASFictitiousClasses.setSubCompartments(superClasses);
			   		       	    compartments.add(ASFictitiousClasses);
			   		       	    
			   		       	    newDisjProperty.setSubCompartment(ASFictitiousClasses);
			   		       	}
			   				
			   			 }
			   		 }
				}
	       	}
		}
	}	
	
	
	public static void createEquivalentObjectProperties(Boolean calcProc, OWLOntology componentontology, OWLObjectProperty op, JsonObject preferences, ArrayList<Compartment> compartments){
		ArrayList<Compartment> superClasses = new ArrayList<Compartment>();

		if (calcProc == false) {
			for (OWLEquivalentObjectPropertiesAxiom equivalentObjectPropertiesAxiom : componentontology.getEquivalentObjectPropertiesAxioms(op)){
				 for(OWLObjectProperty dop : equivalentObjectPropertiesAxiom.getObjectPropertiesInSignature()){
		   			 if (!dop.getIRI().getShortForm().equals(op.getIRI().getShortForm())) {
		   				createMultiLineCompartments(superClasses,  dop.getIRI().getShortForm(), "EquivalentProperties", "ASFictitiousEquivalentProperty", "EquivalentProperty", "Expression");
		   				if (!superClasses.isEmpty()){
		   					Compartment newDisjProperty = new Compartment("EquivalentProperties", "");
			   				compartments.add(newDisjProperty);
		   					
		   					Compartment ASFictitiousClasses = createCompartment("ASFictitiousEquivalentProperties", "");
		   		       	    ASFictitiousClasses.setIsMultiline(true);
		   		         	ASFictitiousClasses.setSubCompartments(superClasses);
		   		       	    compartments.add(ASFictitiousClasses);
		   		       	    
		   		       	    newDisjProperty.setSubCompartment(ASFictitiousClasses);
		   		       	}
		   			 }
		   		 }
			}
		} else {
			for (OWLEquivalentObjectPropertiesAxiom equivalentObjectPropertiesAxiom : componentontology.getEquivalentObjectPropertiesAxioms(op)){	
				if (calculateParameterProcedure("showObjectPropertiesEquivalentProperties", preferences).equals("true")) {
					 for(OWLObjectProperty dop : equivalentObjectPropertiesAxiom.getObjectPropertiesInSignature()){
			   			 if (!dop.getIRI().getShortForm().equals(op.getIRI().getShortForm())) {
			   				createMultiLineCompartments(superClasses,  dop.getIRI().getShortForm(), "EquivalentProperties", "ASFictitiousEquivalentProperty", "EquivalentProperty", "Expression");
			   				if (!superClasses.isEmpty()){
			   					Compartment newDisjProperty = new Compartment("EquivalentProperties", "");
				   				compartments.add(newDisjProperty);
			   					
			   					Compartment ASFictitiousClasses = createCompartment("ASFictitiousEquivalentProperties", "");
			   		       	    ASFictitiousClasses.setIsMultiline(true);
			   		         	ASFictitiousClasses.setSubCompartments(superClasses);
			   		       	    compartments.add(ASFictitiousClasses);
			   		       	    
			   		       	    newDisjProperty.setSubCompartment(ASFictitiousClasses);
			   		       	}
			   			 }
			   		 }
				}
	       	}
		}
	}
	
	public static void createSubProperties(Boolean calcProc, OWLOntology componentontology, OWLObjectProperty op, JsonObject preferences, ArrayList<Compartment> compartments){
		
    	ArrayList<Compartment> superClasses = new ArrayList<Compartment>();
    	
		if (calcProc == false) {
			for (OWLSubObjectPropertyOfAxiom subObjectPropertyOfAxiom : componentontology.getObjectSubPropertyAxiomsForSubProperty(op)){
	    		Compartment newSuperClass = new Compartment("SuperProperties", "");
	   			Compartment newExpression = new Compartment("Expression", subObjectPropertyOfAxiom.getSuperProperty().asOWLObjectProperty().getIRI().getShortForm());
	   			newSuperClass.setSubCompartment(newExpression);
	    		superClasses.add(newSuperClass);
	    	}
		} else {
			for (OWLSubObjectPropertyOfAxiom subObjectPropertyOfAxiom : componentontology.getObjectSubPropertyAxiomsForSubProperty(op)){	
				if (calculateParameterProcedure("showObjectPropertiesSuperProperties", preferences).equals("true")) {
					Compartment newSuperClass = new Compartment("SuperProperties", "");
		   			Compartment newExpression = new Compartment("Expression", subObjectPropertyOfAxiom.getSuperProperty().asOWLObjectProperty().getIRI().getShortForm());
		   			newSuperClass.setSubCompartment(newExpression);
		    		superClasses.add(newSuperClass);
				}
	       	}
		}
		
		if (!superClasses.isEmpty()){
       	    Compartment SP = createCompartment("SuperProperties", "");
       	    compartments.add(SP);
       	    
			Compartment ASFictitiousClasses = createCompartment("ASFictitiousSuperProperties", "");
       	    ASFictitiousClasses.setIsMultiline(true);
         	ASFictitiousClasses.setSubCompartments(superClasses);
       	    SP.setSubCompartment(ASFictitiousClasses);
       	}
	}
	
	public static void createDataPropertySuperProperty(OWLDataProperty dp, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){

		ArrayList<Compartment> preperty = new ArrayList<Compartment>();
    	
		if (calcProc == false) {
			for (OWLSubDataPropertyOfAxiom dpsp : componentontology.getDataSubPropertyAxiomsForSubProperty(dp)){
				createDataPropertyProperty(preperty, dpsp.getSuperProperty().asOWLDataProperty().getIRI().getShortForm(), "SuperProperties");
			}
		} else {
			for (OWLSubDataPropertyOfAxiom dpsp : componentontology.getDataSubPropertyAxiomsForSubProperty(dp)){	
				if (calculateParameterProcedure("showDataPropertiesSuperProperties", preferences).equals("true")) {
					createDataPropertyProperty(preperty, dpsp.getSuperProperty().asOWLDataProperty().getIRI().getShortForm(), "SuperProperties");
				}
	       	}
		}
		createDataPropertyPropertyTopLevel(preperty, compartments, "SuperProperties", "ASFictitiousSuperProperties");	
	}

	public static void createDataPropertyEquivalentObjectProperty(OWLObjectProperty dp, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){

		ArrayList<Compartment> preperty = new ArrayList<Compartment>();
    	
		if (calcProc == false) {
			for (OWLEquivalentObjectPropertiesAxiom dpsp : componentontology.getEquivalentObjectPropertiesAxioms(dp)){
				for(OWLObjectProperty dop : dpsp.getObjectPropertiesInSignature()){
		   			 if (!dop.getIRI().getShortForm().equals(dp.getIRI().getShortForm())) {
		   				 createDataPropertyProperty(preperty, dop.getIRI().getShortForm(), "EquivalentProperties");
		   			 }
				}
				
			}
		} else {
			for (OWLEquivalentObjectPropertiesAxiom dpsp : componentontology.getEquivalentObjectPropertiesAxioms(dp)){	
				if (calculateParameterProcedure("showObjectPropertiesEquivalentProperties", preferences).equals("true")) {
					for(OWLObjectProperty dop : dpsp.getObjectPropertiesInSignature()){
			   			 if (!dop.getIRI().getShortForm().equals(dp.getIRI().getShortForm())) {
			   				 createDataPropertyProperty(preperty, dop.getIRI().getShortForm(), "EquivalentProperties");
			   			 }
					}
				}
	       	}
		}
		createDataPropertyPropertyTopLevel(preperty, compartments, "EquivalentProperties", "ASFictitiousEquivalentProperties");	
	}
	
	public static void createDataPropertyEquivalentProperty(OWLDataProperty dp, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){

		ArrayList<Compartment> preperty = new ArrayList<Compartment>();
    	
		if (calcProc == false) {
			for (OWLEquivalentDataPropertiesAxiom dpsp : componentontology.getEquivalentDataPropertiesAxioms(dp)){
				for(OWLDataProperty dop : dpsp.getDataPropertiesInSignature()){
		   			 if (!dop.getIRI().getShortForm().equals(dp.getIRI().getShortForm())) {
		   				 createDataPropertyProperty(preperty, dop.getIRI().getShortForm(), "EquivalentProperties");
		   			 }
				}
				
			}
		} else {
			for (OWLSubDataPropertyOfAxiom dpsp : componentontology.getDataSubPropertyAxiomsForSubProperty(dp)){	
				if (calculateParameterProcedure("showDataPropertiesEquivalentProperties", preferences).equals("true")) {
					for(OWLDataProperty dop : dpsp.getDataPropertiesInSignature()){
			   			 if (!dop.getIRI().getShortForm().equals(dp.getIRI().getShortForm())) {
			   				 createDataPropertyProperty(preperty, dop.getIRI().getShortForm(), "EquivalentProperties");
			   			 }
					}
				}
	       	}
		}
		createDataPropertyPropertyTopLevel(preperty, compartments, "EquivalentProperties", "ASFictitiousEquivalentProperties");	
	}
	
	public static void createDataPropertyDisjointObjectProperty(OWLObjectProperty dp, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){

		ArrayList<Compartment> preperty = new ArrayList<Compartment>();
    	
		if (calcProc == false) {
			for (OWLDisjointObjectPropertiesAxiom dpsp : componentontology.getDisjointObjectPropertiesAxioms(dp)){
				for(OWLObjectProperty dop : dpsp.getObjectPropertiesInSignature()){
		   			 if (!dop.getIRI().getShortForm().equals(dp.getIRI().getShortForm())) {
		   				 createDataPropertyProperty(preperty, dop.getIRI().getShortForm(), "DisjointProperties");
		   			 }
				}
				
			}
		} else {
			for (OWLDisjointObjectPropertiesAxiom dpsp : componentontology.getDisjointObjectPropertiesAxioms(dp)){	
				if (calculateParameterProcedure("showObjectPropertiesDisjointProperties", preferences).equals("true")) {
					for(OWLObjectProperty dop : dpsp.getObjectPropertiesInSignature()){
			   			 if (!dop.getIRI().getShortForm().equals(dp.getIRI().getShortForm())) {
			   				 createDataPropertyProperty(preperty, dop.getIRI().getShortForm(), "DisjointProperties");
			   			 }
					}
				}
	       	}
		}
		createDataPropertyPropertyTopLevel(preperty, compartments, "DisjointProperties", "ASFictitiousDisjointProperties");	
	}
	
	public static void createDataPropertyDisjointProperty(OWLDataProperty dp, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences){

		ArrayList<Compartment> preperty = new ArrayList<Compartment>();
    	
		if (calcProc == false) {
			for (OWLDisjointDataPropertiesAxiom dpsp : componentontology.getDisjointDataPropertiesAxioms(dp)){
				for(OWLDataProperty dop : dpsp.getDataPropertiesInSignature()){
		   			 if (!dop.getIRI().getShortForm().equals(dp.getIRI().getShortForm())) {
		   				 createDataPropertyProperty(preperty, dop.getIRI().getShortForm(), "DisjointProperties");
		   			 }
				}
				
			}
		} else {
			for (OWLDisjointDataPropertiesAxiom dpsp : componentontology.getDisjointDataPropertiesAxioms(dp)){	
				if (calculateParameterProcedure("showDataPropertiesDisjointProperties", preferences).equals("true")) {
					for(OWLDataProperty dop : dpsp.getDataPropertiesInSignature()){
			   			 if (!dop.getIRI().getShortForm().equals(dp.getIRI().getShortForm())) {
			   				 createDataPropertyProperty(preperty, dop.getIRI().getShortForm(), "DisjointProperties");
			   			 }
					}
				}
	       	}
		}
		createDataPropertyPropertyTopLevel(preperty, compartments, "DisjointProperties", "ASFictitiousDisjointProperties");	
	}
	
	public static void createObjectPropertiesPropertyChains(OWLObjectProperty op, OWLOntology componentontology, ArrayList<Compartment> compartments, Boolean calcProc, JsonObject preferences, String[] prefixesArray, Map<String, String> prefixesMap){

		ArrayList<Compartment> property = new ArrayList<Compartment>();
		
		if (calcProc == false) {
			 for (OWLAxiom a : componentontology.getAxioms()){
		        if (a.getAxiomType().toString().equals("SubPropertyChainOf")) {
		        	OWLSubPropertyChainOfAxiom aa = (OWLSubPropertyChainOfAxiom) a;
		        	if (aa.getSuperProperty().equals(op)) createPropertyChain(property, aa, componentontology, op, prefixesArray, prefixesMap);
		        	
		        	if (!property.isEmpty()){
		        		Compartment pcs = createCompartment("PropertyChains", "");
		        		compartments.add(pcs);
		        		
		        		Compartment asfpcs = createCompartment("ASFictitiousPropertyChains", "");
		        		asfpcs.setIsMultiline(true);
		        		pcs.setSubCompartment(asfpcs);
		        		
		        		asfpcs.setSubCompartments(property);
		        	}
		        }
		     }	

		} else {
			//TODO
		}
	}
	
	public static void createPropertyChain(ArrayList<Compartment> property, OWLSubPropertyChainOfAxiom aa, OWLOntology componentontology, OWLObjectProperty op, String[] prefixesArray, Map<String, String> prefixesMap){
		Compartment pcs = createCompartment("PropertyChains", ""); // PC-s
		property.add(pcs);
		
		Compartment asfpcs = createCompartment("ASFictitiousPropertyChain", ""); // ASFictitiousPropertyChain
		pcs.setSubCompartment(asfpcs);
		asfpcs.setIsMultiline(true);
		
		ArrayList<Compartment> pcsArray = new ArrayList<Compartment>();
		asfpcs.setSubCompartments(pcsArray);
		
		for (OWLObjectPropertyExpression pcexpr : aa.getPropertyChain()){
			Compartment pc = createCompartment("PropertyChain", "");
			pcsArray.add(pc);
			
			ArrayList<Compartment> pcArray = new ArrayList<Compartment>();
			pc.setSubCompartments(pcArray);
			
			Compartment pr = createCompartment("Property", pcexpr.getNamedProperty().getIRI().getShortForm());
			pcArray.add(pr);
			
			
			if (pcexpr.getSimplified().toString().startsWith("InverseOf(")) {
				Compartment inv = createCompartment("Inverse", "true");
				pcArray.add(inv);
			}
			
			 String namespace = "";
     		 if ((!componentontology.getOntologyID().isAnonymous() 
     				 && !op.getNamedProperty().getIRI().getNamespace().equals(componentontology.getOntologyID().getOntologyIRI().get().toString() + "#") 
     				 && op.asOWLObjectProperty().getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#")) 
     				 ||(componentontology.getOntologyID().isAnonymous()
     						&& op.asOWLObjectProperty().getIRI().getNamespace().equals("http://www.w3.org/2000/01/rdf-schema#"))) namespace = op.getIRI().getNamespace();
     		 namespace = namespaceValue(prefixesArray, namespace, prefixesMap);
     		 Compartment Namespace = createCompartment("Namespace", namespace);
     		 pcArray.add(Namespace);
		}
	}
	
	public static void createDataPropertyProperty(ArrayList<Compartment> preperty, String expression, String propertyType){
		Compartment newProperty = new Compartment(propertyType, "");
		Compartment newExpression = new Compartment("Expression", expression);
		newProperty.setSubCompartment(newExpression);
		preperty.add(newProperty);
	}
	
	public static void createDataPropertyPropertyTopLevel(ArrayList<Compartment> preperty, ArrayList<Compartment> compartments, String propertyType, String propertyTypeASF){
		if (!preperty.isEmpty()){
       	    Compartment SP = createCompartment(propertyType, "");
       	    compartments.add(SP);
       	    
			Compartment ASFictitiousClasses = createCompartment(propertyTypeASF, "");
       	    ASFictitiousClasses.setIsMultiline(true);
         	ASFictitiousClasses.setSubCompartments(preperty);
       	    SP.setSubCompartment(ASFictitiousClasses);
       	}
	}
	
	public static Box getTargetBox(ArrayList<Box> boxes, String targetClassName, String targetClassNamespace){
		Box targetClass = null;
		
		for (Box target: boxes) {			
			if(target.getType().equals("Class")){
				if(((Class) target).getName().equals(targetClassName) && (targetClassNamespace.equals("") || ((Class) target).getNamespace() == null || ((Class) target).getNamespace().equals(targetClassNamespace))) {
					targetClass = target;
        			break;
        		}
			}
    	}
		
		return targetClass;
	}
	
	public static Box getTargetIndividualBox(ArrayList<Box> boxes, OWLIndividual owlNamedIndividual){
		Box targetClass = null;
		
		for (Box target: boxes) {			
			if(target.getType().equals("Object")){
				if(((Individual) target).getIndividual().equals(owlNamedIndividual)) {
					targetClass = target;
        			break;
        		}
			}
    	}
		
		return targetClass;
	}
	
	public static void moveInverseAssociotionContent(Association association, Association associationInv){
		ArrayList<Compartment> associationCompartments = association.getCompartments();
		ArrayList<Compartment> associationCompartmentsInv = associationInv.getCompartments();
		for(Compartment compartment: associationCompartmentsInv){
			if (compartment.getType().equals("Role")){
				Compartment invRole = createCompartment("InvRole", "");
				invRole.setSubCompartments(compartment.getSubCompartments());
				associationCompartments.add(invRole);
			}
		}
	}
	
	public static void mergeInverseAssociation(Line line, ArrayList<Line> lines, OWLOntology componentontology){
		Association association = (Association) line;
		if (!association.getIsInverse()){
			OWLObjectProperty op = association.getOwlObjectProperty();
			Set<OWLInverseObjectPropertiesAxiom> inverseObjectProperties = componentontology.getInverseObjectPropertyAxioms(op);
	        for(OWLInverseObjectPropertiesAxiom inverseObjectProperty : inverseObjectProperties){
				for(OWLObjectProperty objectProperty: inverseObjectProperty.getObjectPropertiesInSignature()){
					if (!op.equals(objectProperty)){
						//find inverse association
						for (Line lineInv :lines) {
							if(lineInv.getType().equals("Association")){
								Association associationInv = (Association) lineInv;
								if(associationInv.getOwlObjectProperty().equals(objectProperty) && 
										line.getTarget() != null && line.getSource() != null &&
										associationInv.getSource() != null && associationInv.getTarget() != null &&
										line.getTarget().equals(associationInv.getSource()) && 
										line.getSource().equals(associationInv.getTarget())){
									moveInverseAssociotionContent(association, associationInv);
									associationInv.setIsInverse(true);
									break;
								}
							}
						}
					}
				}
	        }
		}
	}
	
	public static void removeInverseAssociations(ArrayList<Line> lines){
		for (Iterator<Line> iterator = lines.iterator(); iterator.hasNext();){
			Line line = iterator.next();
			if(line.getType().equals("Association")){
				Association association = (Association) line;
				if (association.getIsInverse()) {
					// Remove the current element from the iterator and the list.
					iterator.remove();
				}
			}
		}
	}
	
	public static Compartment createCompartment(String type, String value){
		Compartment newCompartment = new Compartment(type, value);
		return newCompartment;
	}
	
	public static String getPreferenceParameterValue(String parameter, JsonObject preferences){
		//System.out.println(parameter);
		return preferences.getAsJsonObject(parameter).getAsJsonPrimitive("pValue").toString().replace("\"", "");
	}
	
	public static String getPreferenceParameterProcName(String parameter, JsonObject preferences){
		//System.out.println(parameter);
		return preferences.getAsJsonObject(parameter).getAsJsonPrimitive("procName").toString().replace("\"", "");
	}
	
	public static String calculateParameterProcedure(String parameter, JsonObject preferences){
		return "true";
	}
	
	public static String namespaceValue(String[] prefixesArray, String namespace, Map<String, String> prefixesMap){
		if(namespace == null ||  namespace.equals("#") || namespace.equals("")) {return "";}
		if(prefixesMap.containsValue(namespace)) {
			for (Map.Entry<String, String> entry : prefixesMap.entrySet())
			{
			    if(entry.getValue().equals(namespace)){
			    	String tempNS = entry.getKey().substring(0, entry.getKey().length()-1);
			    	if(tempNS.isEmpty()) {return "";}
			    	return entry.getKey().substring(0, entry.getKey().length()-1);
			    }
			}
		}
		for (String prefix :prefixesArray){
			String longForm = prefix.substring(prefix.indexOf(":=")+3, prefix.length()-2);
			if (longForm.equals(namespace)){ return "";}
		}
		return namespace;
	}
	
	public static String namespaceValueAnnotationProperty(String[] prefixesArray, String namespace, Map<String, String> prefixesMap){
		if(namespace.equals("#") || namespace.equals("")) return "";
		if(prefixesMap.containsValue(namespace)) {
			for (Map.Entry<String, String> entry : prefixesMap.entrySet())
			{
				if(entry.getValue().equals(namespace)) return entry.getKey().substring(0, entry.getKey().length()-1);
			}
		}
		for (String prefix :prefixesArray){
			String shortForm = prefix.substring(7, prefix.indexOf(":="));
			String longForm = prefix.substring(prefix.indexOf(":=")+3, prefix.length()-2);
			if (longForm.equals(namespace)) return shortForm;
		}
		return namespace;
	}
	
	public static void superClassesForModule(OWLOntology componentontology, Set<OWLEntity> entities, Set<OWLAxiom> set, OWLClass cl, JsonObject preferences, String restrictionType){
		for(OWLSubClassOfAxiom superClass : componentontology.getSubClassAxiomsForSubClass(cl)){
			//tiesas
			 if (getPreferenceParameterProcName("DirectAssertedSuperclassesOfModuleClasses", preferences).equals("")) {
    	        if (getPreferenceParameterValue("DirectAssertedSuperclassesOfModuleClasses", preferences).equals("true")) {
    	        	if(superClass.getSuperClass().getClassExpressionType().toString().equals("Class")){
						set.add(superClass);
						entities.add((OWLClass)superClass.getSuperClass());
						if (getPreferenceParameterProcName("TransitiveSuperclasses", preferences).equals("")) {
			    	        if (getPreferenceParameterValue("TransitiveSuperclasses", preferences).equals("true")){
			    	        	String restrinctionTypeTemp = "";
			    	        	if(restrictionType.equals("moduleClass")) restrinctionTypeTemp = "superClass";
			    	        	else restrinctionTypeTemp = "";
			    	        	superClassesForModule(componentontology, entities, set, (OWLClass)superClass.getSuperClass(), preferences, restrinctionTypeTemp);
			    	        }
						} else {
							//TODO
						}
						//virsklases ObjectPropertijas
						objectPropertiesForModule(componentontology, entities, set, (OWLClass)superClass.getSuperClass(), "PropertyRangeAssertionsForModuleClassesForSuperclasses", "RangeClassesForObjectPropertiesAtSuperclasses", preferences);
					} 
    	        } 
    	     } else {
    	        	//TODO
    	     }
			
			 if (getPreferenceParameterProcName("AnonymousSuperclassesOfModuleClasses", preferences).equals("")) {
        	     if (getPreferenceParameterValue("AnonymousSuperclassesOfModuleClasses", preferences).equals("true")) {
        	    	 //A or B
        	    	 if(superClass.getSuperClass().getClassExpressionType().toString().equals("ObjectUnionOf")){
        	    		 set.add(superClass);
					}
        	     }
        	 } else {
        	        	//TODO
        	 }
			 //restrictions
			 if (restrictionType.equals("moduleClass") && getPreferenceParameterProcName("RestrictionTargetClassesForRestrictionsAtModuleClasses", preferences).equals("")) {
	    	        if (getPreferenceParameterValue("RestrictionTargetClassesForRestrictionsAtModuleClasses", preferences).equals("true")) {
						 if(superClass.getSuperClass().getClassExpressionType().toString().contains("AllValuesFrom") || superClass.getSuperClass().getClassExpressionType().toString().contains("SomeValuesFrom")){
			 	        	set.add(superClass);
							entities.addAll(superClass.getObjectPropertiesInSignature());
							if (getPreferenceParameterProcName("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("")) {
  				          	     if (getPreferenceParameterValue("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("true")) {
  				          	    	entities.addAll(superClass.getClassesInSignature());
  							}}
			 	        }
	    	        }
			 } else if (restrictionType.equals("superClass") && getPreferenceParameterProcName("RestrictionTargetClassesForRestrictionsAtSuperclasses", preferences).equals("")) {
	    	        if (getPreferenceParameterValue("RestrictionTargetClassesForRestrictionsAtSuperclasses", preferences).equals("true")) {
						 if(superClass.getSuperClass().getClassExpressionType().toString().contains("AllValuesFrom") || superClass.getSuperClass().getClassExpressionType().toString().contains("SomeValuesFrom")){
			 	        	set.add(superClass);
							entities.addAll(superClass.getObjectPropertiesInSignature());
							if (getPreferenceParameterProcName("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("")) {
 				          	     if (getPreferenceParameterValue("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("true")) {
 				          	    	entities.addAll(superClass.getClassesInSignature());
 							}}
			 	        }
	    	        }
			 }
		}
		
		if (getPreferenceParameterProcName("AnonymousSuperclassesOfModuleClasses", preferences).equals("")) {
	   	     if (getPreferenceParameterValue("AnonymousSuperclassesOfModuleClasses", preferences).equals("true")) {
	   	    	 //A or B
	   	    	for(OWLAxiom axiom : componentontology.getReferencingAxioms(cl)){
	   	    		if(axiom.getAxiomType().toString().equals("DataPropertyDomain")){
	   	    			OWLDataPropertyDomainAxiom domain = (OWLDataPropertyDomainAxiom) axiom;
	   	    			if(domain.getDomain().getClassExpressionType().toString().equals("ObjectUnionOf")){
	   	    				set.add(axiom);
	   	    				entities.add(domain.getProperty().asOWLDataProperty());
	   	    			}
	   	    		}
	   	    		
	   	    	}
	   	     }
	   	 } else {
	   	        	//TODO
	   	 }
		
		String restrictionSourseType = "";
		if(restrictionType.equals("moduleClass")) restrictionSourseType ="RestrictionSourcetClassesForRestrictionsAtModuleClasses";
		else if (restrictionType.equals("superClass")) restrictionSourseType ="RestrictionSourcetClassesForRestrictionsAtSuperclasses";

		if (!restrictionType.equals("") && getPreferenceParameterProcName(restrictionSourseType, preferences).equals("")) {
 	        if (getPreferenceParameterValue(restrictionSourseType, preferences).equals("true")) {
				for(OWLAxiom ax : componentontology.getReferencingAxioms(cl)){
					if(ax.getAxiomType().toString().equals("SubClassOf")){
						OWLSubClassOfAxiom subClass = (OWLSubClassOfAxiom) ax;
						if(subClass.getSuperClass().getClassesInSignature().contains(cl) && (subClass.getSuperClass().getClassExpressionType().toString().contains("AllValuesFrom") || subClass.getSuperClass().getClassExpressionType().toString().contains("SomeValuesFrom"))){
							set.add(ax);
							if (getPreferenceParameterProcName("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("")) {
				          	     if (getPreferenceParameterValue("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("true")) {
				          	    	entities.addAll(subClass.getSubClass().getClassesInSignature());
							}}
							//restriction cardinality
							for(OWLObjectProperty pr : subClass.getSuperClass().getObjectPropertiesInSignature()){	
								for(OWLAxiom a : componentontology.getReferencingAxioms(pr)){
									if(a.getAxiomType().toString().equals("SubClassOf") && a.toString().contains("Cardinality")) set.add(a);
								}
							}
						}
					}
				}
 	        }
		}
	}
	
	public static void subClassesForModule(OWLOntology componentontology, Set<OWLEntity> entities, Set<OWLAxiom> set, OWLClass cl, JsonObject preferences, String restrictionType){
		for(OWLSubClassOfAxiom subClass : componentontology.getSubClassAxiomsForSuperClass(cl)){
			if (getPreferenceParameterProcName("DirectAssertedSubclassesOfModuleClasses", preferences).equals("")) {
    	        if (getPreferenceParameterValue("DirectAssertedSubclassesOfModuleClasses", preferences).equals("true")) {
    	        	//tiesas
					if(subClass.getSubClass().getClassExpressionType().toString().equals("Class")){
						set.add(subClass);
						entities.add((OWLClass)subClass.getSubClass());
						if (getPreferenceParameterProcName("TransitiveSubclasses", preferences).equals("")) {
			    	        if (getPreferenceParameterValue("TransitiveSubclasses", preferences).equals("true")){
			    	        	String restrictionTypeTemp = "";
			    	        	if(restrictionType.equals("moduleClass")) restrictionTypeTemp = "subClass";
			    	        	subClassesForModule(componentontology, entities, set, (OWLClass)subClass.getSubClass(), preferences, restrictionTypeTemp);
			    	        }
			    	    } else{
			    	    	//TODO
			    	    }
						//Apaksklases ObjectPropertijas
						objectPropertiesForModule(componentontology, entities, set, (OWLClass)subClass.getSubClass(), "PropertyRangeAssertionsForModuleClassesForSubclasses", "RangeClassesForObjectPropertiesAtSubclasses", preferences);
					}
    	        }
    	     } else {
    	        	//TODO
    	     }
			
			 if (getPreferenceParameterProcName("AnonymousSubclassesOfModuleClasses", preferences).equals("")) {
        	     if (getPreferenceParameterValue("AnonymousSubclassesOfModuleClasses", preferences).equals("true")) {
        	    	//A and ...
					if(subClass.getSubClass().getClassExpressionType().toString().equals("ObjectIntersectionOf")){
						set.add(subClass);
						//????
					}
        	     }
        	 } else {
        	    //TODO
        	 }	
 
		}
		for(OWLSubClassOfAxiom superClass : componentontology.getSubClassAxiomsForSubClass(cl)){
			if (restrictionType.equals("subClass") && getPreferenceParameterProcName("RestrictionTargetClassesForRestrictionsAtSubclasses", preferences).equals("")) {
		        if (getPreferenceParameterValue("RestrictionTargetClassesForRestrictionsAtSubclasses", preferences).equals("true")) {
					 if(superClass.getSuperClass().getClassExpressionType().toString().contains("AllValuesFrom") || superClass.getSuperClass().getClassExpressionType().toString().contains("SomeValuesFrom")){
		 	        	set.add(superClass);
						entities.addAll(superClass.getObjectPropertiesInSignature());
						if (getPreferenceParameterProcName("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("")) {
			          	     if (getPreferenceParameterValue("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("true")) {
			          	    	entities.addAll(superClass.getClassesInSignature());
						}}
		 	        }
		        }
			}
		}
		
		String restrictionSourseType = "";
		if (restrictionType.equals("subClass")) restrictionSourseType ="RestrictionSourcetClassesForRestrictionsAtSubclasses";

		if (!restrictionSourseType.equals("") && getPreferenceParameterProcName(restrictionSourseType, preferences).equals("")) {
 	        if (getPreferenceParameterValue(restrictionSourseType, preferences).equals("true")) {
				for(OWLAxiom ax : componentontology.getReferencingAxioms(cl)){
					if(ax.getAxiomType().toString().equals("SubClassOf")){
						OWLSubClassOfAxiom subClass = (OWLSubClassOfAxiom) ax;
						if(subClass.getSuperClass().getClassesInSignature().contains(cl) && (subClass.getSuperClass().getClassExpressionType().toString().contains("AllValuesFrom") || subClass.getSuperClass().getClassExpressionType().toString().contains("SomeValuesFrom"))){
							set.add(ax);
							if (getPreferenceParameterProcName("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("")) {
				          	     if (getPreferenceParameterValue("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("true")) {
				          	    	entities.addAll(subClass.getSuperClass().getClassesInSignature());
							}}
							//restriction cardinality
							for(OWLObjectProperty pr : subClass.getSuperClass().getObjectPropertiesInSignature()){	
								for(OWLAxiom a : componentontology.getReferencingAxioms(pr)){
									if(a.getAxiomType().toString().equals("SubClassOf") && a.toString().contains("Cardinality")) set.add(a);
								}
							}
						}
					}
				}
 	        }
		}
	}
	
	public static void objectPropertiesForModule(OWLOntology componentontology, Set<OWLEntity> entities, Set<OWLAxiom> set, OWLClass cl, 
			String domainParameter, String rangeParameter, JsonObject preferences){
		
        for(OWLObjectProperty op : componentontology.getObjectPropertiesInSignature()){
        	
        	if (getPreferenceParameterProcName(domainParameter, preferences).equals("")) {
          	     if (getPreferenceParameterValue(domainParameter, preferences).equals("true")) {
          	    	for (OWLObjectPropertyDomainAxiom opda: componentontology.getObjectPropertyDomainAxioms(op)){
                		if(opda.getDomain().getClassExpressionType().toString().equals("Class") && opda.getDomain().equals(cl)) {
        					entities.add(op);
        					set.add(opda);
        					//range
        					for (OWLObjectPropertyRangeAxiom opra: componentontology.getObjectPropertyRangeAxioms(op)){
        						if(opra.getRange().getClassExpressionType().toString().equals("Class")) {
        							if (getPreferenceParameterProcName("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("")) {
        				          	     if (getPreferenceParameterValue("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("true")) {
        				          	    	 entities.add((OWLClass) opra.getRange());
        							}}
        							set.add(opra);
        						}
        					}
        				}
                	}
          	     }
          	 }
        	
        	if (getPreferenceParameterProcName(rangeParameter, preferences).equals("")) {
          	     if (getPreferenceParameterValue(rangeParameter, preferences).equals("true")) {
          	    	for (OWLObjectPropertyRangeAxiom opra: componentontology.getObjectPropertyRangeAxioms(op)){
                		if(opra.getRange().getClassExpressionType().toString().equals("Class") && opra.getRange().equals(cl)) {
        					entities.add(op);
        					set.add(opra);
        					//domain
        					for (OWLObjectPropertyDomainAxiom opda: componentontology.getObjectPropertyDomainAxioms(op)){
        						if(opda.getDomain().getClassExpressionType().toString().equals("Class")) {
        							if (getPreferenceParameterProcName("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("")) {
	       				          	     if (getPreferenceParameterValue("ShowOtherPropertiesInPropertyDomainRangeRestriction", preferences).equals("true")) {
	       				          	    entities.add((OWLClass) opda.getDomain());
	       							}}
        							set.add(opda);
        						}
        					}
        				}
                	}
          	     }
          	 }
        }
	}
}
