import java.util.ArrayList;

public class Box {
	String type;
	String id;
	Compartment compartment;
	ArrayList<Compartment> compartments;
	Box container;
	Ontology child;
	int elemCount = 0;
	
	public Box(String type) {
		super();
		this.type = type;
	}
	public Box() {
		super();
	}
	
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	public Compartment getCompartment() {
		return compartment;
	}
	public void setCompartment(Compartment compartment) {
		this.compartment = compartment;
	}
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public ArrayList<Compartment> getCompartments() {
		return compartments;
	}
	public void setCompartments(ArrayList<Compartment> compartments) {
		this.compartments = compartments;
	}
	public Box getContainer() {
		return container;
	}
	public void setContainer(Box container) {
		this.container = container;
	}
	public Ontology getChild() {
		return child;
	}
	public void setChild(Ontology child) {
		this.child = child;
	}
	public int getElemCount() {
		return elemCount;
	}
	public void setElemCount(int elemCount) {
		this.elemCount = elemCount;
	}
}
