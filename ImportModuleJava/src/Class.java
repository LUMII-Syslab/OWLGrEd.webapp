import org.semanticweb.owlapi.model.OWLClass;


public class Class extends Box {
	
	public String name;
	public String namespace;
	public OWLClass owlClass;
	
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

	public OWLClass getOwlClass() {
		return owlClass;
	}

	public void setOwlClass(OWLClass owlClass) {
		this.owlClass = owlClass;
	}

	public Class(String type, String name) {
		super();
		this.type = type;
		this.name = name;
		// TODO Auto-generated constructor stub
	}
	
	
}
