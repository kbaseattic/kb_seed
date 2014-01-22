/* The CDMI_API defines the component of the Kbase API that supports interaction with
   instances of the CDM (Central Data Model).  A basic familiarity with these routines
   will allow the user to extract data from the CS (Central Store).  We anticipate
   supporting numerous sparse CDMIs in the PS (Persistent Store).

   =head2 Basic Themes

   There are several broad categories of routines supported in the CDMI-API.

   The simplest is set of "get entity" routines -- each returning data
   extracted from instances of a single entity type.  These routines all take
   as input a list of ids referencing instances of a single type of entity.
   They construct as output a mapping which takes as input an id and
   associates as output a set of fields from that instance of the entity.  Each
   routine allows the user to specify which fields are desired.

For example, assume you have an input file "Staphylococci," which is a list of genome IDs for each species of Staphylococcus in the database. The get_entity_Genome command is used to retrieve detailed information about each genome in the file. By using different modifiers, you can specify what kind of information you want to display. In this example, the modifier "contigs" was used. Thus, the number next to the genome ID in the output file indicates the number of contigs each Staphylococcus genome has. For a list of available modifiers relating to each identity, please refer to the ER model.

           > / cat Staphylococci | cut -f 1 | get_entity_Genome - f contigs
           kb|g.134	2
           kb|g.636	1
           kb|g.2506	15
           kb|g.9303	1
           kb|g.3801	87
           kb|g.2025	46
           kb|g.2516	13
           kb|g.2603	33
           kb|g.19928	2
           kb|g.1852	131
           kb|g.8476	1
           kb|g.2742	46

   To use these routines effectively, a user will need to gradually
   become familiar with the entities supported in the CDM.  We suggest
   perusing the entity-relationship model that underlies the CDM to
   get a good introduction.

   The next simplest set of routines provide the "get relationship" routines.  These
   take as input a list of ids for a specific entity type, and the give access
   to the relationship nodes associated with each entity.  Thus, get_relationship_WasSubmittedBy takes the input genome ID and outputs the ID with an added column showing the source of that particular genome. It is essential to be able to navigate the ER model to successfully implement these commands, since not all relationship types are applicable to each entity.

           > / echo 'kb|g.0' | get_relationship_WasSubmittedBy -to id
           kb|g.0	SEED

   Of the remaining CDMI-API routines, most are used to extract data by
   "crossing one or more relationships".  Thus,

	   my $references = $kbO->fids_to_literature($fids)

   takes as input a list of feature ids referenced by the variable $fids.  It
   creates a hash ($references) which maps each input key to a list of literature
   references.  The construction of the literature references for a given ID involves
   crossing relationships from the entity 'Feature' to 'ProteinSequence' to 'Publication'.
   We have attempted to package this specific search in a convenient form.  We anticipate
   that the number of queries of this last class will grow (especially as new entities are
   added to the model).

   =head2 Batching queries

   A majority of the CS-API routines take a list of ids as input.  Each id may be thought
   of as input to a query that produces an output result.  We support processing an input list,
   since the performance (which is usually governed by network interactions) is much better
   if you process a batch of items, rather than invoking the API repeatedly for each of the
   ids.  Normally, the output would be a mapping (a hash for Perl versions) from the
   input ids to the output results.  Thus, a routine like

		fids_to_literature

   will take a list of feature ids as input.  The returned value will be a mapping from
   feature ids (fids) to publication references.

   It is a little inconvenient to batch your requests by supplying a list of fids,
   but the performance will be much better in most cases.  Please note that you are
   controlling the granularity of each request, and in most cases the size of the input
   list is not critical.  However, you should note that while batching up hundreds or thousands
   of input ids at a time should work just fine, millions may well cause things to break (e.g.,
   you may exhaust local memory in your machine as the output results are returned).  As
   machines get larger, the appropriate size of the input lists may become largely irrelevant.
   For now, we recommend that you experiment a bit and use common sense.

*/
module CDMI_API : CDMI_API {
    typedef string annotator;
    typedef int annotation_time;
    typedef string comment;

        /* A fid is a "feature id".  A feature represents an ordered list of regions from
	   the contigs of a genome.  Features all have types.  This allows you to speak
	   of not only protein-encoding genes (PEGs) and RNAs, but also binding sites,
	   large regions, etc.  The location of a fid is defined as a list of
	   "location of a contiguous DNA string" pieces (see the description of the
	   type "location")
       */
    typedef string fid;

	/* A protein_family is thought of as a set of isofunctional, homologous protein sequences.
	   This is not exactly what other groups have meant by "protein families".  There is no
	   hierarchy of super-family, family, sub-family.  We plan on loading different collections
           of protein families, but in many cases there will need to be a transformation into the
	   concept used by Kbase.
        */
    typedef string protein_family;

	/* The concept of "role" or "functional role" is basically an atomic functional unit.
	   The "function of a protein" is made up of one or more roles.  That is, a bifunctional protein
	   with an assigned function of

              5-Enolpyruvylshikimate-3-phosphate synthase (EC 2.5.1.19) / Cytidylate kinase (EC 2.7.4.14)

           would implement two distinct roles (the "function1 / function2" notation is intended to assert
           that the initial part of the protein implements function1, and the terminal part of the protein
	   implements function2).  It is worth noting that a protein often implements multiple roles due
	   to broad specificity.  In this case, we suggest describing the protein function as

		function1 @ function2

	   That is the ' / ' separator is used to represent multiple roles implemented by distinct
	   domains of the protein, while ' @ ' is used to represent multiple roles implemented by
	   distinct domains.
	*/
    typedef string role;

	/* A substem is composed of two components: a set of roles that are gathered to be annotated
	   simultaneously and a spreadsheet depicting the proteins within each genome that implement
	   the roles.  The set of roles may correspond to a pathway, a complex, an inventory (say, "transporters")
	   or whatever other principle an annotator used to formulate the subsystem.

	   The subsystem spreadsheet is a list of "rows", each representing the subsytem in a specific genome.
	   Each row includes a variant code (indicating what version of the molecular machine exists in the
	   genome) and cells.  Each cell is a 2-tuple:

		[role,protein-encoding genes that implement the role in the genome]

           Annotators construct subsystems, and in the process impose a controlled vocabulary
           for roles and functions.
	*/
    typedef string subsystem;
    typedef string variant;
    typedef tuple<subsystem,variant> variant_of_subsystem;
    typedef list<variant_of_subsystem> variant_subsystem_pairs;
    typedef string type_of_fid;
    typedef list<type_of_fid> types_of_fids;

    typedef int length;
    typedef int begin;

	/* In encodings of locations, we often specify strands.  We specify the strand
	   as '+' or '-'
	*/
    typedef string strand;
    typedef string contig;

	/* A region of DNA is maintained as a tuple of four components:

		the contig
		the beginning position (from 1)
		the strand
		the length

	   We often speak of "a region".  By "location", we mean a sequence
	   of regions from the same genome (perhaps from distinct contigs).
        */
    typedef tuple<contig,begin,strand,length> region_of_dna;

	/* a "location" refers to a sequence of regions
	*/
    typedef list<region_of_dna> location;
    typedef list<location>      locations;

	/* we often need to represent regions or locations as
	   strings.  We would use something like

		contigA_200+100,contigA_402+188

           to represent a location composed of two regions
	*/
    typedef string region_of_dna_string;
    typedef list<region_of_dna_string> region_of_dna_strings;
    typedef string location_string;
    typedef string dna;
    typedef string function;
    typedef string protein;
    typedef string md5;
    typedef string genome;
    typedef string taxonomic_group;

	/* The Kbase stores annotations relating to features.  Each annotation
	   is a 3-tuple:

		the text of the annotation (often a record of assertion of function)

		the annotator attaching the annotation to the feature

		the time (in seconds from the epoch) at which the annotation was attached
	*/
    typedef tuple<comment, annotator, annotation_time> annotation;

	/* The Kbase will include a growing body of literature supporting protein
	   functions, asserted phenotypes, etc.  References are encoded as 3-tuples:

		an id (often a PubMed ID)

		a URL to the paper

		a title of the paper

	   The URL and title are often missing (but, can usually be inferred from the pubmed ID).
	*/
    typedef tuple<string id, string link, string title> pubref;
    typedef tuple<fid, float score> scored_fid;
    typedef list<annotation> annotations;
    typedef list<pubref> pubrefs;
    typedef list<role> roles;
    typedef string optional;
    typedef tuple<role,optional> role_with_flag;
    typedef list<role_with_flag> roles_with_flags;
    typedef list<scored_fid> scored_fids;
    typedef list<protein> proteins;
    typedef list<function> functions;
    typedef list<taxonomic_group> taxonomic_groups;
    typedef list<subsystem> subsystems;
    typedef list<contig> contigs;
    typedef list<md5> md5s;
    typedef list<genome> genomes;
    typedef tuple<fid,fid> pair_of_fids;
    typedef list<pair_of_fids> pairs_of_fids;
    typedef list<protein_family> protein_families;

    typedef float score;
    typedef list<pair_of_fids> evidence;
    typedef list<fid> fids;
    typedef tuple<variant, mapping<role, fids>> row;
    typedef tuple<fid,function> fid_function_pair;
    typedef list<fid_function_pair> fid_function_pairs;

	/* A functionally coupled protein family identifies a family, a score, and a function
           (of the related family)
        */
    typedef tuple<protein_family,score,function> fc_protein_family;

    typedef list<fc_protein_family> fc_protein_families;

	/* This routine takes as input a list of fids.  It retrieves the existing
           annotations for each fid, including the text of the annotation, who
	   made the annotation and when (as seconds from the epoch).
       */
    funcdef fids_to_annotations(fids) returns (mapping<fid,annotations>);

        /* This routine takes as input a list of fids and returns a mapping
           from the fids to their assigned functions. */
    funcdef fids_to_functions(fids) returns (mapping<fid,function>);

	/* We try to associate features and publications, when the publications constitute
	   supporting evidence of the function.  We connect a paper to a feature when
	   we believe that an "expert" has asserted that the function of the feature
	   is basically what we have associated with the feature.  Thus, we might
	   attach a paper reporting the crystal structure of a protein, even though
	   the paper is clearly not the paper responsible for the original characterization.
	   Our position in this matter is somewhat controversial, but we are seeking to
	   characterize some assertions as relatively solid, and this strategy seems to
	   support that goal.  Please note that we certainly wish we could also
	   capture original publications, and when experts can provide those
	   connections, we hope that they will help record the associations.
        */
    funcdef fids_to_literature(fids) returns (mapping<fid,pubrefs>);

	/* Kbase supports the creation and maintence of protein families.  Each family is intended to contain a set
           of isofunctional homologs.  Currently, the families are collections of translations
	   of features, rather than of just protein sequences (represented by md5s, for example).
	   fids_to_protein_families supports access to the features that have been grouped into a family.
	   Ideally, each feature in a family would have the same assigned function.  This is not
	   always true, but probably should be.
	*/
    funcdef fids_to_protein_families(fids) returns (mapping<fid,protein_families>);

	/* Given a feature, one can get the set of roles it implements using fid_to_roles.
	   Remember, a protein can be multifunctional -- implementing several roles.
	   This can occur due to fusions or to broad specificity of substrate.
	*/
    funcdef fids_to_roles(fids) returns (mapping<fid,roles>);

	/* fids in subsystems normally have somewhat more reliable assigned functions than
	   those not in subsystems.  Hence, it is common to ask "Is this protein-encoding gene
	   included in any subsystems?"   fids_to_subsystems can be used to see which subsystems
	   contain a fid (or, you can submit as input a set of fids and get the subsystems for each).
	*/
    funcdef fids_to_subsystems(fids) returns (mapping<fid,subsystems>);

	/* One of the most powerful clues to function relates to conserved clusters of genes on
           the chromosome (in prokaryotic genomes).  We have attempted to record pairs of genes
	   that tend to occur close to one another on the chromosome.  To meaningfully do this,
	   we need to construct similarity-based mappings between genes in distinct genomes.
	   We have constructed such mappings for many (but not all) genomes maintained in the
	   Kbase CS.  The prokaryotic geneomes in the CS are grouped into OTUs by ribosomal
	   RNA (genomes within a single OTU have SSU rRNA that is greater than 97% identical).
	   If two genes occur close to one another (i.e., corresponding genes occur close
	   to one another), then we assign a score, which is the number of distinct OTUs
	   in which such clustering is detected.  This allows one to normalize for situations
	   in which hundreds of corresponding genes are detected, but they all come from
	   very closely related genomes.

           The significance of the score relates to the number of genomes in the database.
	   We recommend that you take the time to look at a set of scored pairs and determine
	   approximately what percentage appear to be actually related for a few cutoff values.
	*/
    funcdef fids_to_co_occurring_fids(fids) returns (mapping<fid,scored_fids>);

	/* A "location" is a sequence of "regions".  A region is a contiguous set of bases
	   in a contig.  We work with locations in both the string form and as structures.
	   fids_to_locations takes as input a list of fids.  For each fid, a structured location
	   is returned.  The location is a list of regions; a region is given as a pointer to
	   a list containing

			the contig,
			the beginning base in the contig (from 1).
			the strand (+ or -), and
			the length

	   Note that specifying a region using these 4 values allows you to represent a single
	   base-pair region on either strand unambiguously (which giving begin/end pairs does
	   not achieve).
	*/
    funcdef fids_to_locations(fids) returns (mapping<fid,location>);

	/* It is frequently the case that one wishes to look up the genes that
	   occur in a given region of a contig.  Location_to_fids can be used to extract
	   such sets of genes for each region in the input set of regions.  We define a gene
	   as "occuring" in a region if the location of the gene overlaps the designated region.
	*/
    funcdef locations_to_fids(region_of_dna_strings) returns (mapping<region_of_dna_string,fids>);

	/* We now have a number of types and functions relating to ObservationalUnits (ous),
	   alleles and traits.  We think of a reference genome and a set of ous that
	   have measured differences (SNPs) when compared to the reference genome.
           Each allele is associated with a position on a contig of the reference genome.
	   Prior analysis has associated traits with the alleles that impact them.
	   We are interested in supporting operations that locate genes in the region
	   of an allele (i.e., genes of the reference genome that are in a region 
	   containining an allele).  Similarly, we wish to locate the alleles that
	   impact a trait, map the alleles to regions, loacte the possibly impacted genes,
	   relate these to subsystems, etc.
       */
    typedef string allele;
    typedef list<allele> alleles;
    typedef string trait;
    typedef list<trait> traits;
    typedef string ou;
    typedef list<ou> ous;
    typedef tuple<contig,int position> bp_loc;
    funcdef alleles_to_bp_locs(alleles) returns (mapping<allele,bp_loc>);
    funcdef region_to_fids(region_of_dna) returns (fids);
    funcdef region_to_alleles(region_of_dna) returns (list<tuple<allele,int position>>);
    funcdef alleles_to_traits(alleles) returns (mapping<allele,traits>);
    funcdef traits_to_alleles(traits)  returns (mapping<trait,alleles>);	
    typedef string measurement_type;
    typedef float measurement_value;
    funcdef ous_with_trait(genome,trait,measurement_type,float min_value,float max_value) returns (list<tuple<ou,measurement_value>>);

	/* locations_to_dna_sequences takes as input a list of locations (each in the form of
	   a list of regions).  The routine constructs 2-tuples composed of

		[the input location,the dna string]

           The returned DNA string is formed by concatenating the DNA for each of the
	   regions that make up the location.
	*/
    funcdef locations_to_dna_sequences(locations) returns (list<tuple<location,dna>> dna_seqs);

	/* proteins_to_fids takes as input a list of proteins (i.e., a list of md5s) and
	   returns for each a set of protein-encoding fids that have the designated
	   sequence as their translation.  That is, for each sequence, the returned fids will
	   be the entire set (within Kbase) that have the sequence as a translation.
	*/
    funcdef proteins_to_fids(proteins) returns (mapping<protein,fids>);

	/* Protein families contain a set of isofunctional homologs.  proteins_to_protein_families
	   can be used to look up is used to get the set of protein_families containing a specified protein.
	   For performance reasons, you can submit a batch of proteins (i.e., a list of proteins),
	   and for each input protein, you get back a set (possibly empty) of protein_families.
	   Specific collections of families (e.g., FIGfams) usually require that a protein be in
	   at most one family.  However, we will be integrating protein families from a number of
	   sources, and so a protein can be in multiple families.
	*/
    funcdef proteins_to_protein_families(proteins) returns (mapping<protein,protein_families>);

	/* The routine proteins_to_literature can be used to extract the list of papers
           we have associated with specific protein sequences.  The user should note that
           in many cases the association of a paper with a protein sequence is not precise.
           That is, the paper may actually describe a closely-related protein (that may
	   not yet even be in a sequenced genome).  Annotators attempt to use best
	   judgement when associating literature and proteins.  Publication references
           include [pubmed ID,URL for the paper, title of the paper].  In some cases,
	   the URL and title are omitted.  In theory, we can extract them from PubMed
           and we will attempt to do so.
	*/
    funcdef proteins_to_literature(proteins) returns (mapping<protein,pubrefs>);

	/* The routine proteins_to_functions allows users to access functions associated with
	   specific protein sequences.  The input proteins are given as a list of MD5 values
	   (these MD5 values each correspond to a specific protein sequence).  For each input
	   MD5 value, a list of [feature-id,function] pairs is constructed and returned.
           Note that there are many cases in which a single protein sequence corresponds
	   to the translation associated with multiple protein-encoding genes, and each may
	   have distinct functions (an undesirable situation, we grant).

	   This function allows you to access all of the functions assigned (by all annotation
	   groups represented in Kbase) to each of a set of sequences.
	*/
    funcdef proteins_to_functions(proteins) returns (mapping<protein,fid_function_pairs>);

	/* The routine proteins_to_roles allows a user to gather the set of functional
	   roles that are associated with specifc protein sequences.  A single protein
	   sequence (designated by an MD5 value) may have numerous associated functions,
           since functions are treated as an attribute of the feature, and multiple
	   features may have precisely the same translation.  In our experience,
	   it is not uncommon, even for the best annotation teams, to assign
	   distinct functions (and, hence, functional roles) to identical
	   protein sequences.

	   For each input MD5 value, this routine gathers the set of features (fids)
	   that share the same sequence, collects the associated functions, expands
	   these into functional roles (for multi-functional proteins), and returns
	   the set of roles that results.

	   Note that, if the user wishes to see the specific features that have the
	   assigned fiunctional roles, they should use proteins_to_functions instead (it
	   returns the fids associated with each assigned function).
	*/
    funcdef proteins_to_roles(proteins) returns (mapping<protein,roles>);

	/* roles_to_proteins can be used to extract the set of proteins (designated by MD5 values)
	   that currently are believed to implement a given role.  Note that the proteins
	   may be multifunctional, meaning that they may be implementing other roles, as well.
	*/
    funcdef roles_to_proteins(roles) returns (mapping<role,proteins>);

	/* roles_to_subsystems can be used to access the set of subsystems that include
	   specific roles. The input is a list of roles (i.e., role descriptions), and a mapping
	   is returned as a hash with key role description and values composed of sets of susbsystem names.
	*/
    funcdef roles_to_subsystems(roles) returns (mapping<role,subsystems>);

	/* roles_to_protein_families can be used to locate the protein families containing
	   features that have assigned functions implying that they implement designated roles.
	   Note that for any input role (given as a role description), you may have a set
           of distinct protein_families returned.
	*/
    funcdef roles_to_protein_families(roles) returns (mapping<role,protein_families>);

	/* The routine fids_to_coexpressed_fids returns (for each input fid) a
	   list of features that appear to be coexpressed.  That is,
	   for an input fid, we determine the set of fids from the same genome that
	   have Pearson Correlation Coefficients (based on normalized expression data)
	   greater than 0.5 or less than -0.5.
	*/
    funcdef fids_to_coexpressed_fids(fids) returns (mapping<fid,scored_fids>);

	/* protein_families_to_fids can be used to access the set of fids represented by each of
	   a set of protein_families.  We define protein_families as sets of fids (rather than sets
	   of MD5s.  This may, or may not, be a mistake.
	*/
    funcdef protein_families_to_fids(protein_families) returns (mapping<protein_family,fids>);

	/* protein_families_to_proteins can be used to access the set of proteins (i.e., the set of MD5 values)
	    represented by each of a set of protein_families.  We define protein_families as sets of fids (rather than sets
	   of MD5s.  This may, or may not, be a mistake.
	*/
    funcdef protein_families_to_proteins(protein_families) returns (mapping<protein_family,proteins>);

	/* protein_families_to_functions can be used to extract the set of functions assigned to the fids
	   that make up the family.  Each input protein_family is mapped to a family function.
	*/
    funcdef protein_families_to_functions(protein_families) returns (mapping<protein_family,function>);

	/* Since we accumulate data relating to the co-occurrence (i.e., chromosomal
	   clustering) of genes in prokaryotic genomes,  we can note which pairs of genes tend to co-occur.
	   From this data, one can compute the protein families that tend to co-occur (i.e., tend to
	   cluster on the chromosome).  This allows one to formulate conjectures for unclustered pairs, based
	   on clustered pairs from the same protein_families.
	*/
    funcdef protein_families_to_co_occurring_families(protein_families) returns (mapping<protein_family,fc_protein_families>);

	/* co-occurence_evidence is used to retrieve the detailed pairs of genes that go into the
	   computation of co-occurence scores.  The scores reflect an estimate of the number of distinct OTUs that
	   contain an instance of a co-occuring pair.  This routine returns as evidence a list of all the pairs that
	   went into the computation.

	   The input to the computation is a list of pairs for which evidence is desired.

	   The returned output is a list of elements. one for each input pair.  Each output element
	   is a 2-tuple: the input pair and the evidence for the pair.  The evidence is a list of pairs of
	   fids that are believed to correspond to the input pair.
	*/
    funcdef co_occurrence_evidence(pairs_of_fids) returns (list<tuple<pair_of_fids,evidence>>);

	/* contigs_to_sequences is used to access the DNA sequence associated with each of a set
	   of input contigs.  It takes as input a set of contig IDs (from which the genome can be determined) and
	   produces a mapping from the input IDs to the returned DNA sequence in each case.
	*/
    funcdef contigs_to_sequences(contigs)returns (mapping<contig,dna>);

	/* In some cases, one wishes to know just the lengths of the contigs, rather than their
	   actual DNA sequence (e.g., suppose that you wished to know if a gene boundary occured within
	   100 bp of the end of the contig).  To avoid requiring a user to access the entire DNA sequence,
	   we offer the ability to retrieve just the contig lengths.  Input to the routine is a list of contig IDs.
	   The routine returns a mapping from contig IDs to lengths
	*/
    funcdef contigs_to_lengths(contigs) returns (mapping<contig,length>);

	/* contigs_to_md5s can be used to acquire MD5 values for each of a list of contigs.
	   The quickest way to determine whether two contigs are identical is to compare their
	   associated MD5 values, eliminating the need to retrieve the sequence of each and compare them.

	   The routine takes as input a list of contig IDs.  The output is a mapping
	   from contig ID to MD5 value.
	*/
    funcdef contigs_to_md5s(contigs) returns (mapping<contig,md5>);

	/* md5s to genomes is used to get the genomes associated with each of a list of input md5 values.

	   The routine takes as input a list of MD5 values.  It constructs a mapping from each input
	   MD5 value to a list of genomes that share the same MD5 value.

	   The MD5 value for a genome is independent of the names of contigs and the case of the DNA sequence
	   data.
	*/
    funcdef md5s_to_genomes(md5s) returns (mapping<md5,genomes>); 

	/* The routine genomes_to_md5s can be used to look up the MD5 value associated with each of
	   a set of genomes.  The MD5 values are computed when the genome is loaded, so this routine
	   just retrieves the precomputed values.

	   Note that the MD5 value of a genome is independent of the contig names and case of the
	   DNA sequences that make up the genome.
	*/
    funcdef genomes_to_md5s(genomes) returns (mapping<genome,md5>);

	/* The routine genomes_to_contigs can be used to retrieve the IDs of the contigs
	   associated with each of a list of input genomes.  The routine constructs a mapping
	   from genome ID to the list of contigs included in the genome.
	*/
    funcdef genomes_to_contigs(genomes) returns (mapping<genome,contigs>);

        /* genomes_to_fids bis used to get the fids included in specific genomes.  It
           is often the case that you want just one or two types of fids -- hence, the
	   types_of_fids argument. */
    funcdef genomes_to_fids(genomes,types_of_fids) returns (mapping<genome,fids>);

	/* The routine genomes_to_taxonomies can be used to retrieve taxonomic information for
	   each of a list of input genomes.  For each genome in the input list of genomes, a list of
	   taxonomic groups is returned.  Kbase will use the groups maintained by NCBI.  For an NCBI
	   taxonomic string like

		cellular organisms;
	        Bacteria;
	        Proteobacteria;
	        Gammaproteobacteria;
	        Enterobacteriales;
	        Enterobacteriaceae;
	        Escherichia;
	        Escherichia coli

	   associated with the strain 'Escherichia coli 1412', this routine would return a list of these
	   taxonomic groups:


		['Bacteria',
		 'Proteobacteria',
		 'Gammaproteobacteria',
		 'Enterobacteriales',
		 'Enterobacteriaceae',
		 'Escherichia',
		 'Escherichia coli',
		 'Escherichia coli 1412'
		]

	   That is, the initial "cellular organisms" has been deleted, and the strain ID has
	   been added as the last "grouping".

	   The output is a mapping from genome IDs to lists of the form shown above.
	*/
    funcdef genomes_to_taxonomies(genomes) returns (mapping<genome,taxonomic_groups>);

	/* A user can invoke genomes_to_subsystems to rerieve the names of the subsystems
	   relevant to each genome.  The input is a list of genomes.  The output is a mapping
	   from genome to a list of 2-tuples, where each 2-tuple give a variant code and a
	   subsystem name.  Variant codes of -1 (or *-1) amount to assertions that the
	   genome contains no active variant.  A variant code of 0 means "work in progress",
	   and presence or absence of the subsystem in the genome should be undetermined.
	*/
    funcdef genomes_to_subsystems(genomes) returns (mapping<genome,variant_subsystem_pairs>);

	/* The routine subsystems_to_genomes is used to determine which genomes are in
	   specified subsystems.  The input is the list of subsystem names of interest.
	   The output is a map from the subsystem names to lists of 2-tuples, where each 2-tuple is
	   a [variant-code,genome ID] pair.
	*/
    funcdef subsystems_to_genomes(subsystems) returns (mapping<subsystem,list<tuple<variant, genome>>>);

	/* The routine subsystems_to_fids allows the user to map subsystem names into the fids that
	   occur in genomes in the subsystems.  Specifically, the input is a list of subsystem names.
	   What is returned is a mapping from subsystem names to a "genome-mapping".  The genome-mapping
	   takes genome IDs to 2-tuples that capture the variant code of the genome and the fids from
	   the genome that are included in the subsystem.
	*/
    funcdef subsystems_to_fids(subsystems,genomes) returns (mapping<subsystem,mapping<genome,list<tuple<variant,fids>>>>);

    typedef int aux;
	/* The routine subsystem_to_roles is used to determine the role descriptions that
	   occur in a subsystem.  The input is a list of subsystem names.  A map is returned connecting
	   subsystem names to lists of roles.  'aux' is a boolean variable.  If it is 0, auxiliary roles
           are not returned.  If it is 1, they are returned.
	 */
    funcdef subsystems_to_roles(subsystems,aux) returns (mapping<subsystem,roles>);

	/* The subsystem_to_spreadsheet routine allows a user to extract the subsystem spreadsheets for
	   a specified set of subsystem names.  In the returned output, each subsystem is mapped
	   to a hash that takes as input a genome ID and maps it to the "row" for the genome in the subsystem.
	   The "row" is itself a 2-tuple composed of the variant code, and a mapping from role descriptions to
	   lists of fids.  We suggest writing a simple test script to get, say, the subsystem named
	   'Histidine Degradation', extracting the spreadsheet, and then using something like Dumper to make
	   sure that it all makes sense.
	*/
    funcdef subsystems_to_spreadsheets(subsystems,genomes) returns (mapping<subsystem,mapping<genome,row>>);

	/* The all_roles_used_in_models allows a user to access the set of roles that are included in current models.  This is
           important.  There are far fewer roles used in models than overall.  Hence, the returned set represents
           the minimal set we need to clean up in order to properly support modeling.
	*/
    funcdef all_roles_used_in_models() returns (roles);

    typedef list<string> fields;
    typedef string complex;
    typedef tuple<complex,optional> complex_with_flag;
    typedef list<complex_with_flag> complexes_with_flags;
    typedef list<complex> complexes;
    typedef string name;
    typedef string reaction;
    typedef list<reaction> reactions;

	/*  Reactions do not connect directly to roles.  Rather, the conceptual model is that one or more roles
            together form a complex.  A complex implements one or more reactions.  The actual data relating
            to a complex is spread over two entities: Complex and ReactionComplex. It is convenient to be
	    able to offer access to the complex name, the reactions it implements, and the roles that make it up
	    in a single invocation. 
	*/
    typedef structure {
		name complex_name;
		roles_with_flags complex_roles;
	        reactions complex_reactions;
	} complex_data;
    funcdef complexes_to_complex_data(complexes) returns (mapping<complex,complex_data>);
   
    typedef structure {
	        int complete;
	        int contigs;
		int dna_size;
		float gc_content;
		int genetic_code;
		int pegs;
		int rnas;
		string scientific_name;
		string taxonomy;
		string genome_md5;
        } genome_data;
    funcdef genomes_to_genome_data(genomes) returns (mapping<genome,genome_data>);

    typedef string regulon;
    typedef list<regulon> regulons;
    typedef structure {
	        regulon regulon_id;
	 	fids regulon_set;
		fids tfs;
	} regulon_data;
    typedef list<regulon_data> regulons_data;
    funcdef fids_to_regulon_data(fids) returns (mapping<fid,regulons_data>);
    funcdef regulons_to_fids(regulons) returns (mapping<regulon,fids>);

    typedef structure {
		fid feature_id;
		string genome_name;
	        string feature_function;
	        int feature_length;
	        pubrefs feature_publications;
	        location feature_location;
	} feature_data;
    funcdef fids_to_feature_data(fids) returns (mapping<fid,feature_data>);

    typedef string expert;
    typedef string source;
    typedef string id;
    typedef tuple<id,function,source> function_assertion;
    typedef list<function_assertion> function_assertions;

	/*  Different groups have made assertions of function for numerous protein sequences.
	    The equiv_sequence_assertions allows the user to gather function assertions from
	    all of the sources.  Each assertion includes a field indicating whether the person making
	    the assertion viewed themself as an "expert".  The routine gathers assertions for all
	    proteins having identical protein sequence.
	*/
    funcdef equiv_sequence_assertions(proteins) returns (mapping<protein,function_assertions>);
    typedef string atomic_regulon;
    typedef int atomic_regulon_size;
    typedef tuple<atomic_regulon,atomic_regulon_size> atomic_regulon_size_pair;
    typedef list<atomic_regulon_size_pair> atomic_regulon_size_pairs;
    typedef list<atomic_regulon> atomic_regulons;

	/*  The fids_to_atomic_regulons allows one to map fids into regulons that contain the fids.
	    Normally a fid will be in at most one regulon, but we support multiple regulons.
	*/
    funcdef fids_to_atomic_regulons(fids) returns (mapping<fid,atomic_regulon_size_pairs>);

	/*  The atomic_regulons_to_fids routine allows the user to access the set of fids that make up a regulon.
	    Regulons may arise from several sources; hence, fids can be in multiple regulons.
	*/
    funcdef atomic_regulons_to_fids(atomic_regulons) returns(mapping<atomic_regulon,fids>);
    typedef string protein_sequence;
    typedef string dna_sequence;

	/* fids_to_protein_sequences allows the user to look up the amino acid sequences
	   corresponding to each of a set of fids.  You can also get the sequence from proteins (i.e., md5 values).
	   This routine saves you having to look up the md5 sequence and then accessing
	   the protein string in a separate call.
	*/
    funcdef fids_to_protein_sequences(fids) returns (mapping<fid,protein_sequence>);

    funcdef fids_to_proteins(fids) returns (mapping<fid,md5>);

	/* fids_to_dna_sequences allows the user to look up the DNA sequences
	   corresponding to each of a set of fids. 
	*/
    funcdef fids_to_dna_sequences(fids) returns (mapping<fid,dna_sequence>);

	/*  A "function" is a set of "roles" (often called "functional roles");

		F1 / F2  (where F1 and F2 are roles)  is a function that implements
			  two functional roles in different domains of the protein.
	        F1 @ F2 implements multiple roles through broad specificity
	        F1; F2  is thought to implement F1 or f2 (uncertainty)

	    You often wish to find the fids in one or more genomes that
	    implement specific functional roles.  To do this, you can use
            roles_to_fids.
	*/
    funcdef roles_to_fids(roles,genomes) returns (mapping<role,fid>);  

	/*  Reactions are thought of as being either spontaneous or implemented by
	    one or more Complexes.  Complexes connect to Roles.  Hence, the connection of fids
	    or roles to reactions goes through Complexes.
	*/
    funcdef reactions_to_complexes(reactions) returns (mapping<reaction,complexes_with_flags>);


    typedef string alias;
    typedef list<alias> aliases;
    funcdef aliases_to_fids(aliases) returns (mapping<alias, fid>);
    funcdef aliases_to_fids_by_source(aliases, string source) returns (mapping<alias, fid>);
    
    funcdef source_ids_to_fids(aliases) returns (mapping<string, list<fid>>);
    
    typedef string external_id;
    typedef list<external_id> external_ids;
    funcdef external_ids_to_fids(external_ids, int prefix_match) returns (mapping<external_id, fid>);

    typedef string name_parameter;

	/* Reaction_strings are text strings that represent (albeit crudely)
	   the details of Reactions.
	*/
    funcdef reaction_strings(reactions,name_parameter) returns (mapping<reaction,string>);

	/*  roles_to_complexes allows a user to connect Roles to Complexes,
	    from there, the connection exists to Reactions (although in the
	    actual ER-model model, the connection from Complex to Reaction goes through
	    ReactionComplex).  Since Roles also connect to fids, the connection between
	    fids and Reactions is induced.

            The "name_parameter" can be 0, 1 or 'only'. If 1, then the compound name will 
	    be included with the ID in the output. If only, the compound name will be included 
	    instead of the ID. If 0, only the ID will be included. The default is 0.
	*/
    funcdef roles_to_complexes(roles) returns (mapping<role,complexes>);
    funcdef complexes_to_roles(complexes) returns (mapping<complexes,roles>);
    typedef tuple<subsystem,variant,role> ss_var_role_tuple;
    typedef list<ss_var_role_tuple> ss_var_role_tuples;
    funcdef fids_to_subsystem_data(fids) returns (mapping<fid,ss_var_role_tuples>);
    funcdef representative(genomes) returns (mapping<genome,genome>);

    typedef string genome_name;
    funcdef otu_members(genomes) returns (mapping<genome,mapping<genome,genome_name>>);	
    funcdef otus_to_representatives(list<int> otus) returns (mapping<int, genome>);
    funcdef fids_to_genomes(fids) returns (mapping<fid,genome>);

    typedef string entity_name;    
    typedef int weight;
    typedef string field_name;
    typedef tuple<weight, mapping<field_name, string>> search_hit;

	/* text_search performs a search against a full-text index maintained 
	   for the CDMI. The parameter "input" is the text string to be searched for.
	   The parameter "entities" defines the entities to be searched. If the list
	   is empty, all indexed entities will be searched. The "start" and "count"
	   parameters limit the results to "count" hits starting at "start". 
	 */
    funcdef text_search(string input, int start, int count, list<string> entities) returns (mapping<entity_name, list<search_hit>>);

	/* A correspondence is generated as a mapping of fids to fids.  The mapping
	   attempts to map a fid to another that performs the same function.  The
	   correspondence describes the regions that are similar, the strength of
	   the similarity, the number of genes in the chromosomal context that appear
	   to "correspond" and a score from 0 to 1 that loosely corresponds to 
	   confidence in the correspondence.
	*/
	    typedef structure {
	        fid to;
	        float iden;
		int ncontext;   
	        int b1;
                int e1;
	        int ln1;
	        int b2;
                int e2;
	        int ln2;
	        int score;
	} correspondence;

     funcdef corresponds(fids,genome) returns (mapping<fid,correspondence>);
     
     funcdef corresponds_from_sequences(list<tuple<fid, protein_sequence>> g1_sequences, 
					list<tuple<fid, location>> g1_locations,
					list<tuple<fid, protein_sequence>> g2_sequences, 
					list<tuple<fid, location>> g2_locations) 
     	returns (mapping<fid,correspondence>);

	/* A close_genomes is used to get a set of relatively close genomes (for
	   each input genome, a set of close genomes is calculated, but the
           result should be viewed as quite approximate.  It is quite slow,
	   using similarities for a universal protein as the basis for the 
	   assessments.  It produces estimates of degree of similarity for
	   the universal proteins it samples.

           Up to n genomes will be returned for each input genome.
	*/

     typedef string sequence;
     typedef tuple<id,comment,sequence> seq_triple;
     typedef list<seq_triple> seq_set;
     typedef list<id> id_set;
     typedef seq_set alignment;

     funcdef close_genomes(seq_set,int n) returns (list<tuple<genome,float ident>>);

     typedef structure {
	     seq_set  existing_reps;
	     string   order;     /* keywords: long-to-short */
	     int      alg;
	     string   type_sim;  /* identity_fraction, positive_fraction, score_per_position */
             float    cutoff;    /* fractions or bits */
	} rep_seq_parms;

	/* we return two arguments.  The first is the list of representative triples,
	   and the second is the list of sets (the first entry always being the
	   representative sequence)
	*/
     funcdef representative_sequences(seq_set,rep_seq_parms) returns (id_set,list<id_set>);

     typedef structure {
	     int anchors;
	     int brenner;
             int cluster;
             int dimer;
             int diags;
             int diags1;
             int diags2;
             int le;
             int noanchors;
             int sp;
             int spn;
             int stable;
             int sv;
      
             string anchorspacing;
             string center;
             string cluster1;
             string cluster2;
             string diagbreak;
             string diaglength;
             string diagmargin;
             string distance1;
             string distance2;
             string gapopen;
             string log;
             string loga;
             string matrix;
             string maxhours;
             string maxiters;
             string maxmb;
             string maxtrees;
             string minbestcolscore;
             string minsmoothscore;
             string objscore;
             string refinewindow;
             string root1;
             string root2;
             string scorefile;
             string seqtype;
             string smoothscorecell;
             string smoothwindow;
             string spscore;
             string SUEFF;
             string usetree;
             string weight1;
             string weight2;
     } muscle_parms_t;

     typedef structure {
        int sixmerpair;
        int amino;
        int anysymbol;
        int auto;
        int clustalout;
        int dpparttree;
        int fastapair;
        int fastaparttree;
        int fft;
        int fmodel;
        int genafpair;
        int globalpair;
        int inputorder;
        int localpair;
        int memsave;
        int nofft;
        int noscore;
        int parttree;
        int reorder;
        int treeout;

	string alg;   /* linsi | einsi | ginsi | nwnsi | nwns | fftnsi | fftns (D) */

        string aamatrix;
        string bl;
        string ep;
        string groupsize;
        string jtt;
        string lap;
        string lep;
        string lepx;
        string LOP;
        string LEXP;
        string maxiterate;
        string op;
        string partsize;
        string retree;
        string thread;
        string tm;
        string weighti;
	     
     } mafft_parms_t;

     typedef structure {
	muscle_parms_t muscle_parms;
	mafft_parms_t  mafft_parms;
        string         tool;
	int            align_ends_with_clustal;	
     } align_seq_parms;
             
     funcdef align_sequences(seq_set, align_seq_parms) returns (alignment);

     typedef string newick_tree;

     typedef structure {
	 string bootstrap;
	 string model;
	 string nclasses;
	 string nproc;
	 string rate;
	 string search;
	 string tool;
         string tool_params;
     } build_tree_parms;

     funcdef build_tree(alignment, build_tree_parms) returns (newick_tree);

     typedef string aln_id;
     typedef string tree_id;

     funcdef alignment_by_id(aln_id) returns (alignment);
     funcdef tree_by_id(tree_id) returns (newick_tree);
     
     typedef string entity_name;
     typedef list<entity_name> entity_names;
     typedef string relationship_name;
     typedef list<relationship_name> relationship_names;
     typedef string field_name;
     typedef int boolean;
     
     /* Returns a list of all entities in the database. */
     funcdef all_entities() returns (entity_names);
     
     /* Returns a list of all relationships in the database. */
     funcdef all_relationships() returns (relationship_names);
     
     /* Information about a field in the database. Includes the name of the 
        field, any associated formatted notes, and the type. */
     typedef structure {
     	string name;
     	string notes;
     	string type;
     } field_info;
     
     /* Information about an entity in the database, including the entity name
        and its relationships and fields. */
     typedef structure {
	string name;
	list<tuple<string rel_name, string entity_name>> relationships;
	mapping<field_name, field_info> fields;
     } entity_info;

     /* Information about a relationship in the database, including the 
        entities it relates, its name and converse name, and its fields.
        The real_table boolean designates that the relationship is a real
        table in the database rather than the converse relationship to that
        table. */
     typedef structure {
	string name;
	string from_entity;
	string to_entity;
	boolean real_table;
	string converse;
	mapping<field_name, field_info> fields;
     } relationship_info;

     /* Returns information about a set of entities in the database. Invalid
        entity names are ignored. */
     funcdef get_entity(entity_names) returns (mapping<string, entity_info>);
     
     /* Returns information about a set of relationships in the database. 
        Invalid relationship names are ignored. */
     funcdef get_relationship(relationship_names) returns (mapping<string, relationship_info>);
};
