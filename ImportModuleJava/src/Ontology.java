import java.util.ArrayList;

public class Ontology {
	public String name;
	public String IRI;
	public ArrayList<Box> boxes;
	public ArrayList<Line> lines;
	public String axiomCount;
	public String logicalAxiomCount;
	public ArrayList<String> imports;
	public String id;
	public Boolean isOntologyFragment;
	public ArrayList<String> unexported;
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getIRI() {
		return IRI;
	}
	public void setIRI(String iRI) {
		IRI = iRI;
	}
	public ArrayList<Box> getBoxes() {
		return boxes;
	}
	public void setBoxes(ArrayList<Box> boxes) {
		this.boxes = boxes;
	}
	public ArrayList<Line> getLines() {
		return lines;
	}
	public void setLines(ArrayList<Line> lines) {
		this.lines = lines;
	}
	public String getAxiomCount() {
		return axiomCount;
	}
	public void setAxiomCount(String axiomCount) {
		this.axiomCount = axiomCount;
	}
	public String getLogicalAxiomCount() {
		return logicalAxiomCount;
	}
	public void setLogicalAxiomCount(String logicalAxiomCount) {
		this.logicalAxiomCount = logicalAxiomCount;
	}
	public ArrayList<String> getImports() {
		return imports;
	}
	public void setImports(ArrayList<String> imports) {
		this.imports = imports;
	}
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public Boolean getIsOntologyFragment() {
		return isOntologyFragment;
	}
	public void setIsOntologyFragment(Boolean isOntologyFragment) {
		this.isOntologyFragment = isOntologyFragment;
	}
	public ArrayList<String> getUnexported() {
		return unexported;
	}
	public void setUnexported(ArrayList<String> unexported) {
		this.unexported = unexported;
	}
	public Ontology(String name, String iri, String axiomCount, String logicalAxiomCount) {
		super();
		this.name = name;
		this.IRI = iri;
		this.axiomCount = axiomCount;
		this.logicalAxiomCount = logicalAxiomCount;
	}
}
