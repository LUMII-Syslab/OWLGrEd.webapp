import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;


public class SerializeToJSON {
	int id = 1;
	JsonObject preferences;
	int mainOntologyId;
	
	public SerializeToJSON(JsonObject preferences) {
		super();
		this.preferences = preferences;
	}

	public JsonObject  serializeToJSON(ArrayList<Ontology> ontology, String mainOntology){

		JsonObject json = new JsonObject();
		json.add("ontologies", createOntologies(ontology, mainOntology));
		json.addProperty("active-ontology", Integer.toString(mainOntologyId));
		
		JsonObject jsonElements = new JsonObject();
		json.add("Elements", jsonElements);
		
		jsonElements.add("Import", createImports(ontology));
		return json;
	}
	
	public JsonObject createImports(ArrayList<Ontology> ontologies){
		JsonObject json = new JsonObject();
		for(Ontology ontology : ontologies){
			for(String ont : ontology.getImports()){
				json.add(Integer.toString(id), createImport(ontology, ontologies, ont));
				id++;
			}
		}
		return json;
	}
	
	public JsonObject createImport(Ontology ontology, ArrayList<Ontology> ontologies, String ontImp){
		JsonObject json = new JsonObject();
		
		String target = "";
		for(Ontology ont : ontologies){
			if(ont.getName().equals(ontImp)){
				target = ont.getId();
				break;
			}
		}
		if(!target.equals("")){
			json.addProperty("source", ontology.getId());
			json.addProperty("target", target);
		}
		
		JsonObject compartments = new JsonObject();
		json.add("compartments", compartments);
		compartments.addProperty("Label", "<<import>>");
		
		return json;
	}
	
	public JsonObject createOntologies(ArrayList<Ontology> ontologies, String mainOntology){
		JsonObject json = new JsonObject();
		//int i = 1;
		for(Ontology ontology : ontologies){
			if(ontology.getIRI().equals(mainOntology)) mainOntologyId = id;
			ontology.setId(Integer.toString(id));
			//json.add(Integer.toString(id), createOntology(ontology));
			id++;
		}
		for(Ontology ontology : ontologies){
		//	if(ontology.getIRI().equals(mainOntology)) mainOntologyId = id;
			//ontology.setId(Integer.toString(id));
			json.add(ontology.getId(), createOntology(ontology));
			//id++;
		}
		return json;
	}
	
	public JsonObject createOntology(Ontology ontology){
		JsonObject json = new JsonObject();
		json.add("ontology", createOntologyJSONObject(ontology));
		//elementi
		json.add("Elements", createElements(ontology));
		if(ontology.getUnexported() != null)json.add("unexported", createUnexported(ontology));
		
		return json;
	}
	
	public JsonArray createUnexported(Ontology ontology){
		JsonArray json = new JsonArray();
		ArrayList<String> al = ontology.getUnexported();
		Set<String> hs = new HashSet<>();
		hs.addAll(al);
		al.clear();
		al.addAll(hs);
		for(String st : al){
			JsonPrimitive element = new JsonPrimitive(st);
			json.add(element);
		}
		return json;
	}
	
	public JsonObject createOntologyJSONObject(Ontology ontology){
		JsonObject json = new JsonObject();
		json.addProperty("name", ontology.getName());
		json.addProperty("uri", ontology.getIRI());
		json.add("prefixes", new JsonObject());
		json.add("stats", createOntologystats(ontology));
		if(ontology.getIsOntologyFragment() != null) json.addProperty("isOntologyFragment", ontology.getIsOntologyFragment());
		//ontologijas parametri
		return json;
	}
	
	public JsonObject createOntologystats(Ontology ontology){
		JsonObject json = new JsonObject();
		json.addProperty("ontology_id", ontology.getIRI());
		json.addProperty("axiom_count", ontology.getAxiomCount());
		json.addProperty("logical_axiom_count", ontology.getLogicalAxiomCount());
		return json;
	}
	
	public JsonObject createElements(Ontology ontology){
		
		//varbut seit automatiski iet cauri visiem elementiem???????
		
		JsonObject json = new JsonObject();
		
		//Container
		json.add("Container", new JsonObject());
		
		//Class
		json.add("Class", new JsonObject());
		
		//Association
		json.add("Association", new JsonObject());
		
		//Generalization
		json.add("Generalization", new JsonObject());
		
		//EquivalentClass
		json.add("EquivalentClass", new JsonObject());
		
		//EquivalentClass
		json.add("Disjoint", new JsonObject());
		
		//Class Annotations as boxes
		json.add("Annotation", new JsonObject());
		
		//AnnotationProperties
		json.add("AnnotationProperty", new JsonObject());
		
		//Class Annotations boxes connectors
		json.add("Connector", new JsonObject());
		
		//Individual
		json.add("Object", new JsonObject());
		
		//Dependency
		json.add("Dependency", new JsonObject());
		
		//SameAsIndivid
		json.add("SameAsIndivid", new JsonObject());
		
		//DifferentIndivid
		json.add("DifferentIndivid", new JsonObject());
		
		//SameAsIndivids
		json.add("SameAsIndivids", new JsonObject());
				
		//DifferentIndivids
		json.add("DifferentIndivids", new JsonObject());
		
		//DataType
		json.add("DataType", new JsonObject());
		
		//AssocToFork
		json.add("AssocToFork", new JsonObject());
		
		//GeneralizationToFork
		json.add("GeneralizationToFork", new JsonObject());
		
		//HorizontalFork
		json.add("HorizontalFork", new JsonObject());
		
		//Restriction
		json.add("Restriction", new JsonObject());
		
		//DisjointClasses
		json.add("DisjointClasses", new JsonObject());
	
		//EquivalentClasses
		json.add("EquivalentClasses", new JsonObject());
		
		//ComplementOf
		json.add("ComplementOf", new JsonObject());
		
		//Link
		json.add("Link", new JsonObject());
		//showDataTypesLinkToAttributeClasses
		//ConnectorDataType
		json.add("ConnectorDataType", new JsonObject());
		
		//Attribute
		json.add("Attribute", new JsonObject());
		
		//OntologyFragment
		json.add("OntologyFragment", new JsonObject());
		createContainers(json, ontology);
		createBoxElements(json, ontology);
		createLineElements(json, ontology);
		
		//citi elementi
		return json;
	}
	
	public void createContainers(JsonObject json, Ontology ontology){
		ArrayList<Box> boxes = ontology.getBoxes();
		for (Box box: boxes) {
			if(box.getType().equals("Container"))createBox(ontology, box.getType(), json, box);
    	}
	}
	
	public void createBoxElements(JsonObject json, Ontology ontology){
		ArrayList<Box> boxes = ontology.getBoxes();
		for (Box box: boxes) {
			if(!box.getType().equals("Container"))createBox(ontology, box.getType(), json, box);
    	}
	}
	
	public void createLineElements(JsonObject json, Ontology ontology){
		ArrayList<Line> lines = ontology.getLines();
		for (Line line: lines) {
			createLineElement(ontology, line.getType(), json, line);
    	}
	}
	
	public JsonObject createBox(Ontology ontology, String type, JsonObject jsonP, Box box){
		JsonObject json = jsonP.getAsJsonObject(type);
    	json.add(Integer.toString(id), createCompartmentsObject(box));
    	
    	box.setId(String.valueOf(id));
    	id++;
		return json;
	}
	
	public JsonObject createLineElement(Ontology ontology, String type, JsonObject jsonP, Line line){
		JsonObject json = jsonP.getAsJsonObject(type);
		json.add(Integer.toString(id), createCompartmentsObject(line));
		line.setId(String.valueOf(id));
    	id++;
		return json;
	}

	public JsonObject createCompartmentsObject(Box co){
		JsonObject json = new JsonObject();
		json.add("compartments", createCompartmentsObjecttructure(co));
		if(co.getContainer() !=null){
    		json.addProperty("container", co.getContainer().getId());
    	}
		if(co.getChild() !=null){
    		json.addProperty("child", co.getChild().getId());
    	}
		return json;
	}
		
	public JsonObject createCompartmentsObject(Line o){
		JsonObject json = new JsonObject();
		if (o.getCompartment()!=null || o.getCompartments()!=null) json.add("compartments", createCompartmentsObjecttructure(o));
		if (o.getSource() != null) json.addProperty("source", o.getSource().getId());
		if (o.getTarget() != null) {json.addProperty("target", o.getTarget().getId());
		} else if (o.getTargetLine() != null) {
			System.out.println("dddddddddddddddddddddddddd " + o.getTargetLine().getId());
			json.addProperty("target", o.getTargetLine().getId());
		}
		return json;
	}
	
	public JsonObject createCompartmentsObjecttructure(Box box){
		if (box.getCompartment() != null){
			return createCompartment(box);
		} else {
			return createCompartments(box);
		}		
	}
	
	public JsonObject createCompartmentsObjecttructure(Line line){
		if (line.getCompartment() != null){
			return createCompartment(line);
		} else {
			return createCompartments(line);
		}		
	}
	
	public JsonObject createCompartments(Box o){
		JsonObject json = new JsonObject();
		ArrayList<Compartment> compartments = o.getCompartments();
		
		for (Compartment comp: compartments) {
			createSubCompartment(comp, json);
		}
		return json;
	}
	
	public JsonObject createCompartments(Line o){
		JsonObject json = new JsonObject();
		ArrayList<Compartment> compartments = o.getCompartments();
		
		for (Compartment comp: compartments) {	
			createSubCompartment(comp, json);
		}
		return json;
	}
	
	public JsonObject createCompartment(Box co){
		JsonObject json = new JsonObject();
		Compartment compartment = co.getCompartment();
		if (compartment.getSubCompartment() == null && compartment.getSubCompartments() == null 
				&& compartment.getValue() != null && compartment.getValue() != "" && compartment.getValue() != "\"\"") {
			if(compartment.getType().equals("Namespace") && compartment.getValue().endsWith("#")) json.addProperty(compartment.getType(), compartment.getValue().substring(0, compartment.getValue().length()-1).replace("\n", "\\n"));
			else json.addProperty(compartment.getType(), compartment.getValue().replace("\n", "\\n"));
		}
		else json.add(compartment.getType(), createSubCompartments(compartment));
		return json;
	}
	
	public JsonObject createCompartment(Line co){
		JsonObject json = new JsonObject();
		Compartment compartment = co.getCompartment();
		if (compartment.getSubCompartment() == null && compartment.getSubCompartments() == null 
				&& compartment.getValue() != null && compartment.getValue() != "" && compartment.getValue() != "\"\"") {
			if(compartment.getType().equals("Namespace") && compartment.getValue().endsWith("#")) json.addProperty(compartment.getType(), compartment.getValue().substring(0, compartment.getValue().length()-1).replace("\n", "\\n"));
			else json.addProperty(compartment.getType(), compartment.getValue().replace("\n", "\\n"));
		}
		else json.add(compartment.getType(), createSubCompartments(compartment));
		return json;
	}
	
	public JsonArray createSubCompartmentsArray(Compartment comp) {
		JsonArray ja = new JsonArray();
		ArrayList<Compartment> compartments = comp.getSubCompartments();
		for (Compartment scomp: compartments){
			JsonObject json = new JsonObject();
			if (scomp.getSubCompartments()!=null || scomp.getSubCompartment()!=null){
				json.add(scomp.getType(), createSubCompartments(scomp));
			} else {
				if (scomp.getValue() != null && scomp.getValue() != "" && scomp.getValue() != "\"\"") {
					if(scomp.getType().equals("Namespace") && scomp.getValue().endsWith("#")) json.addProperty(scomp.getType(), scomp.getValue().substring(0, scomp.getValue().length()-1).replace("\n", "\\n"));
					else json.addProperty(scomp.getType(), scomp.getValue().replace("\n", "\\n"));
				}
			}
			ja.add(json);
		}
		return ja;
	}
	
	public JsonObject createSubCompartments(Compartment comp){
		JsonObject json = new JsonObject();
		ArrayList<Compartment> compartments = comp.getSubCompartments();
		if (compartments != null){
			for (Compartment scomp: compartments) {
				createSubCompartment(scomp, json);
	    	}
		} else {
			Compartment scomp = comp.getSubCompartment();
			if(scomp!=null) createSubCompartment(scomp, json);
			else {
				if (comp.getValue() != null && comp.getValue() != "" && comp.getValue() != "\"\"") {
					if(comp.getType().equals("Namespace") && comp.getValue().endsWith("#")) json.addProperty(comp.getType(), comp.getValue().substring(0, comp.getValue().length()-1).replace("\n", "\\n"));
					else json.addProperty(comp.getType(), comp.getValue().replace("\n", "\\n"));
				}
			}
		}
		return json;
	}
	
	public void createSubCompartment(Compartment scomp, JsonObject json){
		if (scomp.getSubCompartments() == null && scomp.getSubCompartment() == null) {
			if (scomp.getValue() != null && scomp.getValue() != "" && scomp.getValue() != "\"\"") {
				if(scomp.getType().equals("Namespace") && scomp.getValue().endsWith("#")) json.addProperty(scomp.getType(), scomp.getValue().substring(0, scomp.getValue().length()-1).replace("\n", "\\n"));
				else json.addProperty(scomp.getType(), scomp.getValue().replace("\n", "\\n"));
				}
		} else if (scomp.getSubCompartment() != null) {
			json.add(scomp.getType(), createSubCompartments(scomp));
		}else if (scomp.getIsMultiline() == false) {
			json.add(scomp.getType(), createSubCompartments(scomp));
		} else {
			json.add(scomp.getType(), createSubCompartmentsArray(scomp));
		}
	}
	
	public String getPreferenceParameterValue(String parameter){
		return preferences.getAsJsonObject(parameter).getAsJsonPrimitive("pValue").toString().replace("\"", "");
	}
}
