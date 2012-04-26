module GenomeAnnotation
{
    typedef string genome_id;
    typedef string feature_id;
    typedef string contig_id;
    typedef string feature_type;

    /* A region of DNA is maintained as a tuple of four components:

		the contig
		the beginning position (from 1)
		the strand
		the length

	   We often speak of "a region".  By "location", we mean a sequence
	   of regions from the same genome (perhaps from distinct contigs).
        */
    typedef tuple<contig_id, int begin, string strand,int length> region_of_dna;

    /*
	a "location" refers to a sequence of regions
    */
    typedef list<region_of_dna> location;
    
    typedef tuple<string comment, string annotator, int annotation_time> annotation;

    typedef structure {
	feature_id id;
	location location;
	feature_type type;
	string function;
	string protein_translation;
	list<string> aliases;
	list<annotation> annotations;
    } feature;

    typedef structure {
	contig_id id;
	string dna;
    } contig;

    typedef structure {
	genome_id id;
	string scientific_name;
	string domain;
	int genetic_code;
	string source;
	string source_id;
	
	list<contig> contigs;
	list<feature> features;
    } genome;

    /*
     * Given a genome object populated with contig data, perform gene calling
     * and functional annotation and return the annotated genome.
     */
    funcdef annotate_genome(genome) returns (genome);

    /*
     * Given a genome object populated with feature data, reannotate
     * the features that have protein translations. Return the updated
     * genome object.
     */
    funcdef annotate_proteins(genome) returns (genome);

};
