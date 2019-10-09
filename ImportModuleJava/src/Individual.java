import org.semanticweb.owlapi.model.OWLIndividual;


public class Individual extends Box {
	public OWLIndividual owlIndividual;

	public Individual(OWLIndividual owlIndividual, String type) {
		super();
		this.owlIndividual = owlIndividual;
		this.type = type;
	}

	public OWLIndividual getIndividual() {
		return owlIndividual;
	}

	public void setIndividual(OWLIndividual owlIndividual) {
		this.owlIndividual = owlIndividual;
	}
	
	
}
