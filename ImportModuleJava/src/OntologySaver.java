import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.OWLOntologyCreationException;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.semanticweb.owlapi.model.OWLDocumentFormat;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyStorageException;
import org.semanticweb.owlapi.model.UnloadableImportException;
import org.semanticweb.owlapi.io.OWLOntologyCreationIOException;
import org.semanticweb.owlapi.formats.FunctionalSyntaxDocumentFormat;
import org.semanticweb.owlapi.formats.ManchesterSyntaxDocumentFormat;
import org.semanticweb.owlapi.formats.OWLXMLDocumentFormat;
import org.semanticweb.owlapi.formats.RDFXMLDocumentFormat;
import org.semanticweb.owlapi.io.UnparsableOntologyException;

import java.io.File;
import java.io.PrintWriter;


//@SuppressWarnings("deprecation")
public class OntologySaver 
{
	public static String saveOntologyToFile (String s)
	{
		//Begin processing input - the input string contains file path, file type and ontology text, delimited by newlines
		int delim1 = s.indexOf('\n'); 
		String pathToFile = s.substring(0, delim1); 
		int delim2 = s.indexOf('\n', delim1 + 1);
		String fileType = s.substring(delim1 + 1, delim2);
		String ontologyText = s.substring(delim2 + 1);
		//At this point, we have three separate strings, each containing one part of the input string
		
		//Create file, write the ontology to it in functional syntax, as received from OWLGrEd.
		PrintWriter ontologyFile = null;
		try
		{
			ontologyFile = new PrintWriter(pathToFile, "UTF8");
			ontologyFile.println(ontologyText);
		}
		catch (Exception e)
		{
			return "Ontology save failed: error when creating or opening file " + pathToFile + " (Java FileNotFoundException)";
		}
		ontologyFile.close();
		
		//the ontology manager is the object that will actually be converting the ontology.
		OWLOntologyManager manager = OWLManager.createOWLOntologyManager();
		File file = new File(pathToFile);
		OWLOntology ontology = null;
		try
		{
			ontology = manager.loadOntologyFromOntologyDocument(file);
		}
		catch (UnparsableOntologyException e)
		{
			return "Ontology save failed: error when parsing functional syntax (Java UnparsableOntologyException).";
		}
		catch (UnloadableImportException e)
		{
			return "Ontology save failed: problem with importing other ontologies (Java UnloadableImportException).";
		}
		catch (OWLOntologyCreationIOException e)
		{
			return "Ontology save failed: Java IOException when reading ontology (Java OWLOntologyCreationIOException.";
		}
		catch (OWLOntologyCreationException e)
		{
			return "Ontology save failed: unknown reason (Java OWLOntologyCreationException).";
		}
		
		//determine the ontology format that must be used
		OWLDocumentFormat ontologyFormat = null;
		//OWLDocumentFormat a = manager.getOntologyFormat(ontology);
		if (fileType.compareTo("RDF/XML") == 0)
		{
			//ontologyFormat = new RDFXMLOntologyFormat();
			ontologyFormat = new RDFXMLDocumentFormat();
		}
		else
		{
			if (fileType.compareTo("OWL/XML") == 0)
			{
				ontologyFormat = new OWLXMLDocumentFormat();
			}
			else
			{
				if (fileType.compareTo("Functional") == 0)
				{
					//ontologyFormat = new OWLFunctionalSyntaxOntologyFormat();
					ontologyFormat = new FunctionalSyntaxDocumentFormat();
				}
				else
				{
					ontologyFormat = new ManchesterSyntaxDocumentFormat();
				}
			}
		}
		
		//convert ontology to selected type
		manager.setOntologyFormat(ontology, ontologyFormat);
		
		//save ontology to file
		try
		{
			manager.saveOntology(ontology);
		}
		catch (OWLOntologyStorageException e)
		{
			e.printStackTrace();
			return "Ontology save failed: error with accessing file (Java OWLOntologyStorageException)" + e.getStackTrace();
		}
		return "Ontology succesfully saved in " + fileType + " notation file at " + pathToFile;
	}
}
