import java.util.ArrayList;


public class Compartment {
	String type;
	String value;
	Boolean isMultiline;
	ArrayList<Compartment> subCompartments;
	Compartment subCompartment;
	
	public Compartment(String type, String value) {
		super();
		this.type = type;
		this.value = value;
		this.isMultiline = false;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getValue() {
		return value;
	}

	public void setValue(String value) {
		this.value = value;
	}

	public ArrayList<Compartment> getSubCompartments() {
		return subCompartments;
	}

	public void setSubCompartments(ArrayList<Compartment> subCompartments) {
		this.subCompartments = subCompartments;
	}

	public Compartment getSubCompartment() {
		return subCompartment;
	}

	public void setSubCompartment(Compartment subCompartment) {
		this.subCompartment = subCompartment;
	}

	public Boolean getIsMultiline() {
		return isMultiline;
	}

	public void setIsMultiline(Boolean isMultiline) {
		this.isMultiline = isMultiline;
	}	
}
