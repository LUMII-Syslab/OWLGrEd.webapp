import java.util.ArrayList;


public class Line {
	Box source;
	Box target;
	Line sourceLine;
	Line targetLine;
	String id;
	String type;
	
	Compartment compartment;
	ArrayList<Compartment> compartments;
	
	public Box getSource() {
		return source;
	}
	public Line(Box source, Box target, String type) {
		super();
		this.source = source;
		this.target = target;
		this.type = type;
	}
	public Line(Box source, Line targetLine, String type) {
		super();
		this.source = source;
		this.targetLine = targetLine;
		this.type = type;
	}
	public Line() {
		super();
	}
	public void setSource(Box source) {
		this.source = source;
	}
	public Box getTarget() {
		return target;
	}
	public void setTarget(Box target) {
		this.target = target;
	}
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
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
	public ArrayList<Compartment> getCompartments() {
		return compartments;
	}
	public void setCompartments(ArrayList<Compartment> compartments) {
		this.compartments = compartments;
	}
	public Line getSourceLine() {
		return sourceLine;
	}
	public void setSourceLine(Line sourceLine) {
		this.sourceLine = sourceLine;
	}
	public Line getTargetLine() {
		return targetLine;
	}
	public void setTargetLine(Line targetLine) {
		this.targetLine = targetLine;
	}
}
