import java.util.ArrayList;

import org.semanticweb.owlapi.model.OWLObjectProperty;


public class Association extends Line {
	
	String name;
	String namespace;
	OWLObjectProperty owlObjectProperty;
	Boolean isInverse;
	
	public OWLObjectProperty getOwlObjectProperty() {
		return owlObjectProperty;
	}
	public void setOwlObjectProperty(OWLObjectProperty owlObjectProperty) {
		this.owlObjectProperty = owlObjectProperty;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getNamespace() {
		return namespace;
	}
	public void setNamespace(String namespace) {
		this.namespace = namespace;
	}
	public Boolean getIsInverse() {
		return isInverse;
	}
	public void setIsInverse(Boolean isInverse) {
		this.isInverse = isInverse;
	}
	public ArrayList<Compartment> getCompartments() {
		return compartments;
	}
	public void setCompartments(ArrayList<Compartment> compartments) {
		this.compartments = compartments;
	}
	public Association(String type, OWLObjectProperty owlObjectProperty) {
		super();
		this.type = type;
		this.owlObjectProperty = owlObjectProperty;
		this.isInverse = false;
	}
}
