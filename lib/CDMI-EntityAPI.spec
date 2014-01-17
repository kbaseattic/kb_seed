module CDMI_API : CDMI_EntityAPI {
    typedef string diamond;
    typedef string countVector;
    typedef string rectangle;

    /*
    Wrapper for the GetAll function documented L<here|http://pubseed.theseed.org/sapling/server.cgi?pod=ERDB#GetAll>.
    Note that the object_names and fields arguments must be strings; array references are not allowed.
    */
    funcdef get_all(string object_names,
		    string filter_clause,
		    list<string> parameters,
		    string fields,
		    int count) returns(list<list<string>> result_set);




    typedef structure {
        string id;
	int n_rows;
	int n_cols;
	string status;
	int is_concatenation;
	string sequence_type;
	string timestamp;
	string method;
	string parameters;
	string protocol;
	string source_id;
    } fields_Alignment;

    /*
An alignment arranges a group of sequences so that they
match. Each alignment is associated with a phylogenetic tree that
describes how the sequences developed and their evolutionary
distance.

It has the following fields:

=over 4

=item n_rows

number of rows in the alignment

=item n_cols

number of columns in the alignment

=item status

status of the alignment, currently either [i]active[/i], [i]superseded[/i], or [i]bad[/i]

=item is_concatenation

TRUE if the rows of the alignment map to multiple sequences, FALSE if they map to single sequences

=item sequence_type

type of sequence being aligned, currently either [i]Protein[/i], [i]DNA[/i], [i]RNA[/i], or [i]Mixed[/i]

=item timestamp

date and time the alignment was loaded

=item method

name of the primary software package or script used to construct the alignment

=item parameters

non-default parameters used as input to the software package or script indicated in the method attribute

=item protocol

description of the steps taken to construct the alignment, or a reference to an external pipeline

=item source_id

ID of this alignment in the source database


=back
    */

    funcdef get_entity_Alignment(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Alignment>);
    funcdef query_entity_Alignment(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Alignment>);
    funcdef all_entities_Alignment(int start, int count, list<string> fields)
	returns(mapping<string, fields_Alignment>);
	

    typedef structure {
        string id;
    } fields_AlignmentAttribute;

    /*
This entity represents an attribute type that can
be assigned to an alignment. The attribute
values are stored in the relationships to the target. The
key is the attribute name.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_AlignmentAttribute(list<string> ids, list<string> fields)
	returns(mapping<string, fields_AlignmentAttribute>);
    funcdef query_entity_AlignmentAttribute(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_AlignmentAttribute>);
    funcdef all_entities_AlignmentAttribute(int start, int count, list<string> fields)
	returns(mapping<string, fields_AlignmentAttribute>);
	

    typedef structure {
        string id;
	int row_number;
	string row_id;
	string row_description;
	int n_components;
	int beg_pos_aln;
	int end_pos_aln;
	string md5_of_ungapped_sequence;
	string sequence;
    } fields_AlignmentRow;

    /*
This entity represents a single row of an alignment.
In general, this corresponds to a sequence, but in a
concatenated alignment multiple sequences may be represented
here.

It has the following fields:

=over 4

=item row_number

1-based ordinal number of this row in the alignment

=item row_id

identifier for this row in the FASTA file for the alignment

=item row_description

description of this row in the FASTA file for the alignment

=item n_components

number of components that make up this alignment row; for a single-sequence alignment this is always "1"

=item beg_pos_aln

the 1-based column index in the alignment where this sequence row begins

=item end_pos_aln

the 1-based column index in the alignment where this sequence row ends

=item md5_of_ungapped_sequence

the MD5 of this row's sequence after gaps have been removed; for DNA and RNA sequences, the [b]U[/b] codes are also normalized to [b]T[/b] before the MD5 is computed

=item sequence

sequence for this alignment row (with indels)


=back
    */

    funcdef get_entity_AlignmentRow(list<string> ids, list<string> fields)
	returns(mapping<string, fields_AlignmentRow>);
    funcdef query_entity_AlignmentRow(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_AlignmentRow>);
    funcdef all_entities_AlignmentRow(int start, int count, list<string> fields)
	returns(mapping<string, fields_AlignmentRow>);
	

    typedef structure {
        string id;
	string source_id;
	int position;
	float minor_AF;
	string minor_allele;
	float major_AF;
	string major_allele;
	int obs_unit_count;
    } fields_AlleleFrequency;

    /*
An allele frequency represents a summary of the major and minor allele frequencies for a position on a chromosome.

It has the following fields:

=over 4

=item source_id

identifier for this allele in the original (source) database

=item position

Specific position on the contig where the allele occurs

=item minor_AF

Minor allele frequency.  Floating point number from 0.0 to 0.5.

=item minor_allele

Text letter representation of the minor allele. Valid values are A, C, G, and T.

=item major_AF

Major allele frequency.  Floating point number less than or equal to 1.0.

=item major_allele

Text letter representation of the major allele. Valid values are A, C, G, and T.

=item obs_unit_count

Number of observational units used to compute the allele frequencies. Indicates the quality of the analysis.


=back
    */

    funcdef get_entity_AlleleFrequency(list<string> ids, list<string> fields)
	returns(mapping<string, fields_AlleleFrequency>);
    funcdef query_entity_AlleleFrequency(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_AlleleFrequency>);
    funcdef all_entities_AlleleFrequency(int start, int count, list<string> fields)
	returns(mapping<string, fields_AlleleFrequency>);
	

    typedef structure {
        string id;
	string annotator;
	string comment;
	string annotation_time;
    } fields_Annotation;

    /*
An annotation is a comment attached to a feature.
Annotations are used to track the history of a feature's
functional assignments and any related issues. The key is
the feature ID followed by a colon and a complemented ten-digit
sequence number.

It has the following fields:

=over 4

=item annotator

name of the annotator who made the comment

=item comment

text of the annotation

=item annotation_time

date and time at which the annotation was made


=back
    */

    funcdef get_entity_Annotation(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Annotation>);
    funcdef query_entity_Annotation(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Annotation>);
    funcdef all_entities_Annotation(int start, int count, list<string> fields)
	returns(mapping<string, fields_Annotation>);
	

    typedef structure {
        string id;
	string source_id;
	string assay_type;
	string assay_type_id;
    } fields_Assay;

    /*
An assay is an experimental design for determining alleles at specific chromosome positions.

It has the following fields:

=over 4

=item source_id

identifier for this assay in the original (source) database

=item assay_type

Text description of the type of assay (e.g., SNP, length, sequence, categorical, array, short read, SSR marker, AFLP marker)

=item assay_type_id

source ID associated with the assay type (informational)


=back
    */

    funcdef get_entity_Assay(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Assay>);
    funcdef query_entity_Assay(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Assay>);
    funcdef all_entities_Assay(int start, int count, list<string> fields)
	returns(mapping<string, fields_Assay>);
	

    typedef structure {
        string id;
	string name;
	string description;
	int directional;
	float confidence;
	string url;
    } fields_Association;

    /*
An Association represents a protein complex or a pairwise
(binary) physical association between proteins.


It has the following fields:

=over 4

=item name

This is the name of the association. 

=item description

This is a description of this association.  If the protein complex has a name, this should be it. 

=item directional

True for directional binary associations (e.g., those detected by a pulldown experiment), false for non-directional binary associations and complexes. Bidirectional associations (e.g., associations detected by reciprocal pulldown experiments) should be encoded as 2 separate binary associations. 

=item confidence

Optional numeric estimate of confidence in the association. Recommended to use a 0-100 scale. 

=item url

Optional URL for more info about this complex.


=back
    */

    funcdef get_entity_Association(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Association>);
    funcdef query_entity_Association(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Association>);
    funcdef all_entities_Association(int start, int count, list<string> fields)
	returns(mapping<string, fields_Association>);
	

    typedef structure {
        string id;
	string description;
	string data_source;
	string url;
	string association_type;
    } fields_AssociationDataset;

    /*
An Association Dataset is a collection of PPI
data imported from a single database or publication.


It has the following fields:

=over 4

=item description

This is a description of the dataset.

=item data_source

Optional external source for this dataset; e.g., another database.

=item url

Optional URL for more info about this dataset.

=item association_type

The type of this association.


=back
    */

    funcdef get_entity_AssociationDataset(list<string> ids, list<string> fields)
	returns(mapping<string, fields_AssociationDataset>);
    funcdef query_entity_AssociationDataset(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_AssociationDataset>);
    funcdef all_entities_AssociationDataset(int start, int count, list<string> fields)
	returns(mapping<string, fields_AssociationDataset>);
	

    typedef structure {
        string id;
	string description;
    } fields_AssociationDetectionType;

    /*
This documents methods by which associations are detected
or annotated.


It has the following fields:

=over 4

=item description

This is a brief description of this detection method. 


=back
    */

    funcdef get_entity_AssociationDetectionType(list<string> ids, list<string> fields)
	returns(mapping<string, fields_AssociationDetectionType>);
    funcdef query_entity_AssociationDetectionType(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_AssociationDetectionType>);
    funcdef all_entities_AssociationDetectionType(int start, int count, list<string> fields)
	returns(mapping<string, fields_AssociationDetectionType>);
	

    typedef structure {
        string id;
    } fields_AtomicRegulon;

    /*
An atomic regulon is an indivisible group of coregulated
features on a single genome. Atomic regulons are constructed so
that a given feature can only belong to one. Because of this, the
expression levels for atomic regulons represent in some sense the
state of a cell.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_AtomicRegulon(list<string> ids, list<string> fields)
	returns(mapping<string, fields_AtomicRegulon>);
    funcdef query_entity_AtomicRegulon(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_AtomicRegulon>);
    funcdef all_entities_AtomicRegulon(int start, int count, list<string> fields)
	returns(mapping<string, fields_AtomicRegulon>);
	

    typedef structure {
        string id;
	string description;
    } fields_Attribute;

    /*
An attribute describes a category of condition or characteristic for
an experiment. The goals of the experiment can be inferred from its values
for all the attributes of interest.

It has the following fields:

=over 4

=item description

Descriptive text indicating the nature and use of this attribute.


=back
    */

    funcdef get_entity_Attribute(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Attribute>);
    funcdef query_entity_Attribute(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Attribute>);
    funcdef all_entities_Attribute(int start, int count, list<string> fields)
	returns(mapping<string, fields_Attribute>);
	

    typedef structure {
        string id;
	string mod_date;
	list<string> name;
	float dna;
	float protein;
	float cell_wall;
	float lipid;
	float cofactor;
	float energy;
    } fields_Biomass;

    /*
A biomass is a collection of compounds in a specific
ratio and in specific compartments that are necessary for a
cell to function properly. The prediction of biomasses is key
to the functioning of the model. Each biomass belongs to
a specific model.

It has the following fields:

=over 4

=item mod_date

last modification date of the biomass data

=item name

descriptive name for this biomass

=item dna

portion of a gram of this biomass (expressed as a fraction of 1.0) that is DNA

=item protein

portion of a gram of this biomass (expressed as a fraction of 1.0) that is protein

=item cell_wall

portion of a gram of this biomass (expressed as a fraction of 1.0) that is cell wall

=item lipid

portion of a gram of this biomass (expressed as a fraction of 1.0) that is lipid but is not part of the cell wall

=item cofactor

portion of a gram of this biomass (expressed as a fraction of 1.0) that function as cofactors

=item energy

number of ATP molecules hydrolized per gram of this biomass


=back
    */

    funcdef get_entity_Biomass(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Biomass>);
    funcdef query_entity_Biomass(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Biomass>);
    funcdef all_entities_Biomass(int start, int count, list<string> fields)
	returns(mapping<string, fields_Biomass>);
	

    typedef structure {
        string id;
	string frequencies;
	int genetic_code;
	string type;
	string subtype;
    } fields_CodonUsage;

    /*
This entity contains information about the codon usage
frequency in a particular genome with respect to a particular
type of analysis (e.g. high-expression genes, modal, mean,
etc.).

It has the following fields:

=over 4

=item frequencies

A packed-string representation of the codon usage frequencies. These are not global frequencies, but rather frequenicy of use relative to other codons that produce the same amino acid.

=item genetic_code

Genetic code used for these codons.

=item type

Type of frequency analysis: average, modal, high-expression, or non-native.

=item subtype

Specific nature of the codon usage with respect to the given type, generally indicative of how the frequencies were computed.


=back
    */

    funcdef get_entity_CodonUsage(list<string> ids, list<string> fields)
	returns(mapping<string, fields_CodonUsage>);
    funcdef query_entity_CodonUsage(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_CodonUsage>);
    funcdef all_entities_CodonUsage(int start, int count, list<string> fields)
	returns(mapping<string, fields_CodonUsage>);
	

    typedef structure {
        string id;
	list<string> name;
	string source_id;
	string mod_date;
    } fields_Complex;

    /*
A complex is a set of chemical reactions that act in concert to
effect a role.

It has the following fields:

=over 4

=item name

name of this complex. Not all complexes have names.

=item source_id

ID of this complex in the source from which it was added.

=item mod_date

date and time of the last change to this complex's definition


=back
    */

    funcdef get_entity_Complex(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Complex>);
    funcdef query_entity_Complex(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Complex>);
    funcdef all_entities_Complex(int start, int count, list<string> fields)
	returns(mapping<string, fields_Complex>);
	

    typedef structure {
        string id;
	string label;
	string abbr;
	string source_id;
	int ubiquitous;
	string mod_date;
	float mass;
	string formula;
	float charge;
	float deltaG;
	float deltaG_error;
    } fields_Compound;

    /*
A compound is a chemical that participates in a reaction. Both
ligands and reaction components are treated as compounds.

It has the following fields:

=over 4

=item label

primary name of the compound, for use in displaying reactions

=item abbr

shortened abbreviation for the compound name

=item source_id

common modeling ID of this compound

=item ubiquitous

TRUE if this compound is found in most reactions, else FALSE

=item mod_date

date and time of the last modification to the compound definition

=item mass

pH-neutral atomic mass of the compound

=item formula

a pH-neutral formula for the compound

=item charge

computed charge of the compound in a pH-neutral solution

=item deltaG

the pH 7 reference Gibbs free-energy of formation for this compound as calculated by the group contribution method (units are kcal/mol)

=item deltaG_error

the uncertainty in the [b]deltaG[/b] value (units are kcal/mol)


=back
    */

    funcdef get_entity_Compound(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Compound>);
    funcdef query_entity_Compound(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Compound>);
    funcdef all_entities_Compound(int start, int count, list<string> fields)
	returns(mapping<string, fields_Compound>);
	

    typedef structure {
        string id;
	float charge;
	string formula;
    } fields_CompoundInstance;

    /*
A Compound Instance represents the occurrence of a particular
compound in a location in a model.

It has the following fields:

=over 4

=item charge

computed charge based on the location instance pH and similar constraints

=item formula

computed chemical formula for this compound based on the location instance pH and similar constraints


=back
    */

    funcdef get_entity_CompoundInstance(list<string> ids, list<string> fields)
	returns(mapping<string, fields_CompoundInstance>);
    funcdef query_entity_CompoundInstance(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_CompoundInstance>);
    funcdef all_entities_CompoundInstance(int start, int count, list<string> fields)
	returns(mapping<string, fields_CompoundInstance>);
	

    typedef structure {
        string id;
	string accession;
	string short_name;
	string description;
    } fields_ConservedDomainModel;

    /*
A ConservedDomainModel represents a conserved domain model
as found in the NCBI CDD archive.
The id of a ConservedDomainModel is the PSSM-Id. 

It has the following fields:

=over 4

=item accession

CD accession (starting with 'cd', 'pfam', 'smart', 'COG', 'PRK' or "CHL')

=item short_name

CD short name

=item description

CD description


=back
    */

    funcdef get_entity_ConservedDomainModel(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ConservedDomainModel>);
    funcdef query_entity_ConservedDomainModel(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ConservedDomainModel>);
    funcdef all_entities_ConservedDomainModel(int start, int count, list<string> fields)
	returns(mapping<string, fields_ConservedDomainModel>);
	

    typedef structure {
        string id;
	string source_id;
    } fields_Contig;

    /*
A contig is thought of as composing a part of the DNA
associated with a specific genome.  It is represented as an ID
(including the genome ID) and a ContigSequence. We do not think
of strings of DNA from, say, a metgenomic sample as "contigs",
since there is no associated genome (these would be considered
ContigSequences). This use of the term "ContigSequence", rather
than just "DNA sequence", may turn out to be a bad idea.  For now,
you should just realize that a Contig has an associated
genome, but a ContigSequence does not.

It has the following fields:

=over 4

=item source_id

ID of this contig from the core (source) database


=back
    */

    funcdef get_entity_Contig(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Contig>);
    funcdef query_entity_Contig(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Contig>);
    funcdef all_entities_Contig(int start, int count, list<string> fields)
	returns(mapping<string, fields_Contig>);
	

    typedef structure {
        string id;
	string sequence;
    } fields_ContigChunk;

    /*
ContigChunks are strings of DNA thought of as being a
string in a 4-character alphabet with an associated ID.  We
allow a broader alphabet that includes U (for RNA) and
the standard ambiguity characters.

It has the following fields:

=over 4

=item sequence

base pairs that make up this sequence


=back
    */

    funcdef get_entity_ContigChunk(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ContigChunk>);
    funcdef query_entity_ContigChunk(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ContigChunk>);
    funcdef all_entities_ContigChunk(int start, int count, list<string> fields)
	returns(mapping<string, fields_ContigChunk>);
	

    typedef structure {
        string id;
	int length;
    } fields_ContigSequence;

    /*
ContigSequences are strings of DNA.  Contigs have an
associated genome, but ContigSequences do not.  We can think
of random samples of DNA as a set of ContigSequences. There
are no length constraints imposed on ContigSequences -- they
can be either very short or very long.  The basic unit of data
that is moved to/from the database is the ContigChunk, from
which ContigSequences are formed. The key of a ContigSequence
is the sequence's MD5 identifier.

It has the following fields:

=over 4

=item length

number of base pairs in the contig


=back
    */

    funcdef get_entity_ContigSequence(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ContigSequence>);
    funcdef query_entity_ContigSequence(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ContigSequence>);
    funcdef all_entities_ContigSequence(int start, int count, list<string> fields)
	returns(mapping<string, fields_ContigSequence>);
	

    typedef structure {
        string id;
	string source_id;
	list<int> binding_location;
    } fields_CoregulatedSet;

    /*
We need to represent sets of genes that are coregulated via
some regulatory mechanism.  In particular, we wish to represent
genes that are coregulated using transcription binding sites and
corresponding transcription regulatory proteins. We represent a
coregulated set (which may, or may not, be considered a regulon)
using CoregulatedSet.

It has the following fields:

=over 4

=item source_id

original ID of this coregulated set in the source (core) database

=item binding_location

binding location for this set's transcription factor; there may be none of these or there may be more than one


=back
    */

    funcdef get_entity_CoregulatedSet(list<string> ids, list<string> fields)
	returns(mapping<string, fields_CoregulatedSet>);
    funcdef query_entity_CoregulatedSet(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_CoregulatedSet>);
    funcdef all_entities_CoregulatedSet(int start, int count, list<string> fields)
	returns(mapping<string, fields_CoregulatedSet>);
	

    typedef structure {
        string id;
	string name;
	list<string> content;
    } fields_Diagram;

    /*
A functional diagram describes a network of chemical
reactions, often comprising a single subsystem.

It has the following fields:

=over 4

=item name

descriptive name of this diagram

=item content

content of the diagram, in PNG format


=back
    */

    funcdef get_entity_Diagram(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Diagram>);
    funcdef query_entity_Diagram(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Diagram>);
    funcdef all_entities_Diagram(int start, int count, list<string> fields)
	returns(mapping<string, fields_Diagram>);
	

    typedef structure {
        string id;
	int obsolete;
	string replacedby;
    } fields_EcNumber;

    /*
EC numbers are assigned by the Enzyme Commission, and consist
of four numbers separated by periods, each indicating a successively
smaller cateogry of enzymes.

It has the following fields:

=over 4

=item obsolete

This boolean indicates when an EC number is obsolete.

=item replacedby

When an obsolete EC number is replaced with another EC number, this string will hold the name of the replacement EC number.


=back
    */

    funcdef get_entity_EcNumber(list<string> ids, list<string> fields)
	returns(mapping<string, fields_EcNumber>);
    funcdef query_entity_EcNumber(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_EcNumber>);
    funcdef all_entities_EcNumber(int start, int count, list<string> fields)
	returns(mapping<string, fields_EcNumber>);
	

    typedef structure {
        string id;
	string name;
	string effector_class;
    } fields_Effector;

    /*


It has the following fields:

=over 4

=item name

Name of this effector.

=item effector_class

The class of this effector.


=back
    */

    funcdef get_entity_Effector(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Effector>);
    funcdef query_entity_Effector(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Effector>);
    funcdef all_entities_Effector(int start, int count, list<string> fields)
	returns(mapping<string, fields_Effector>);
	

    typedef structure {
        string id;
	float temperature;
	string description;
	float oxygenConcentration;
	float pH;
	string source_id;
    } fields_Environment;

    /*
An Environment is a set of conditions for microbial growth,
including temperature, aerobicity, media, and supplementary
conditions.

It has the following fields:

=over 4

=item temperature

The temperature in Kelvin.

=item description

A description of the environment.

=item oxygenConcentration

The oxygen concentration in the environment in Molar (mol/L). A value of -1 indicates that there is oxygen in the environment but the concentration is not known, (e.g. an open air shake flask experiment).

=item pH

The pH of the media used in the environment.

=item source_id

The ID of the environment used by the data source.


=back
    */

    funcdef get_entity_Environment(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Environment>);
    funcdef query_entity_Environment(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Environment>);
    funcdef all_entities_Environment(int start, int count, list<string> fields)
	returns(mapping<string, fields_Environment>);
	

    typedef structure {
        string id;
	string source;
    } fields_Experiment;

    /*
An experiment is a combination of conditions for which gene expression
information is desired. The result of the experiment is a set of expression
levels for features under the given conditions.

It has the following fields:

=over 4

=item source

Publication or lab relevant to this experiment.


=back
    */

    funcdef get_entity_Experiment(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Experiment>);
    funcdef query_entity_Experiment(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Experiment>);
    funcdef all_entities_Experiment(int start, int count, list<string> fields)
	returns(mapping<string, fields_Experiment>);
	

    typedef structure {
        string id;
	string title;
	string description;
	string source_id;
	string startDate;
	string comments;
    } fields_ExperimentMeta;

    /*
An Experiment consists of (potentially) multiple
strains, environments, and measurements on
those strains and environments.

It has the following fields:

=over 4

=item title

Title of the experiment.

=item description

Description of the experiment including the experimental plan, general results, and conclusions, if possible.

=item source_id

The ID of the experiment used by the data source.

=item startDate

The date this experiment was started.

=item comments

Any data describing the experiment that is not covered by the description field.


=back
    */

    funcdef get_entity_ExperimentMeta(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ExperimentMeta>);
    funcdef query_entity_ExperimentMeta(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ExperimentMeta>);
    funcdef all_entities_ExperimentMeta(int start, int count, list<string> fields)
	returns(mapping<string, fields_ExperimentMeta>);
	

    typedef structure {
        string id;
	string source_id;
    } fields_ExperimentalUnit;

    /*
An ExperimentalUnit is a subset of an experiment consisting of
a Strain, an Environment, and one or more Measurements on that
strain in the specified environment. ExperimentalUnits belong to a
single experiment.

It has the following fields:

=over 4

=item source_id

The ID of the experimental unit used by the data source.


=back
    */

    funcdef get_entity_ExperimentalUnit(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ExperimentalUnit>);
    funcdef query_entity_ExperimentalUnit(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ExperimentalUnit>);
    funcdef all_entities_ExperimentalUnit(int start, int count, list<string> fields)
	returns(mapping<string, fields_ExperimentalUnit>);
	

    typedef structure {
        string id;
	string source_id;
	string name;
	string comments;
	string groupType;
    } fields_ExperimentalUnitGroup;

    /*
An ExperimentalUnitGroup allows for grouping related experimental units
and their measurements - for instance measurements that were in the same plate.


It has the following fields:

=over 4

=item source_id

The ID of the experimental unit group used by the data source.

=item name

The name of this group, if any.

=item comments

Any comments about this group.

=item groupType

The type of this grouping, for example '24 well plate', '96 well plate', '384 well plate', 'microarray'.


=back
    */

    funcdef get_entity_ExperimentalUnitGroup(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ExperimentalUnitGroup>);
    funcdef query_entity_ExperimentalUnitGroup(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ExperimentalUnitGroup>);
    funcdef all_entities_ExperimentalUnitGroup(int start, int count, list<string> fields)
	returns(mapping<string, fields_ExperimentalUnitGroup>);
	

    typedef structure {
        string id;
	string type;
	string release;
	list<string> family_function;
	list<string> alignment;
    } fields_Family;

    /*
The Kbase will support the maintenance of protein families
(as sets of Features with associated translations).  We are
initially only supporting the notion of a family as composed of
a set of isofunctional homologs.  That is, the families we
initially support should be thought of as containing
protein-encoding genes whose associated sequences all implement
the same function (we do understand that the notion of "function"
is somewhat ambiguous, so let us sweep this under the rug by
calling a functional role a "primitive concept").
We currently support families in which the members are
protein sequences as well. Identical protein sequences
as products of translating distinct genes may or may not
have identical functions.  This may be justified, since
in a very, very, very few cases identical proteins do, in
fact, have distinct functions.

It has the following fields:

=over 4

=item type

type of protein family (e.g. FIGfam, equivalog)

=item release

release number / subtype of protein family

=item family_function

optional free-form description of the family. For function-based families, this would be the functional role for the family members.

=item alignment

FASTA-formatted alignment of the family's protein sequences


=back
    */

    funcdef get_entity_Family(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Family>);
    funcdef query_entity_Family(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Family>);
    funcdef all_entities_Family(int start, int count, list<string> fields)
	returns(mapping<string, fields_Family>);
	

    typedef structure {
        string id;
	string feature_type;
	string source_id;
	int sequence_length;
	string function;
	list<string> alias;
    } fields_Feature;

    /*
A feature (sometimes also called a gene) is a part of a
genome that is of special interest. Features may be spread across
multiple DNA sequences (contigs) of a genome, but never across more
than one genome. Each feature in the database has a unique
ID that functions as its ID in this table. Normally a Feature is
just a single contigous region on a contig. Features have types,
and an appropriate choice of available types allows the support
of protein-encoding genes, exons, RNA genes, binding sites,
pathogenicity islands, or whatever.

It has the following fields:

=over 4

=item feature_type

Code indicating the type of this feature. Among the codes currently supported are "peg" for a protein encoding gene, "bs" for a binding site, "opr" for an operon, and so forth.

=item source_id

ID for this feature in its original source (core) database

=item sequence_length

Number of base pairs in this feature.

=item function

Functional assignment for this feature. This will often indicate the feature's functional role or roles, and may also have comments.

=item alias

alternative identifier for the feature. These are highly unstructured, and frequently non-unique.


=back
    */

    funcdef get_entity_Feature(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Feature>);
    funcdef query_entity_Feature(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Feature>);
    funcdef all_entities_Feature(int start, int count, list<string> fields)
	returns(mapping<string, fields_Feature>);
	

    typedef structure {
        string id;
	int pegs;
	int rnas;
	string scientific_name;
	int complete;
	int prokaryotic;
	int dna_size;
	int contigs;
	string domain;
	int genetic_code;
	float gc_content;
	list<string> phenotype;
	string md5;
	string source_id;
    } fields_Genome;

    /*
The Kbase houses a large and growing set of genomes.  We
often have multiple genomes that have identical DNA.  These usually
have distinct gene calls and annotations, but not always.  We
consider the Kbase to be a framework for managing hundreds of
thousands of genomes and offering the tools needed to
support compartive analysis on large sets of genomes,
some of which are virtually identical.

It has the following fields:

=over 4

=item pegs

Number of protein encoding genes for this genome.

=item rnas

Number of RNA features found for this organism.

=item scientific_name

Full genus/species/strain name of the genome sequence.

=item complete

TRUE if the genome sequence is complete, else FALSE

=item prokaryotic

TRUE if this is a prokaryotic genome sequence, else FALSE

=item dna_size

Number of base pairs in the genome sequence.

=item contigs

Number of contigs for this genome sequence.

=item domain

Domain for this organism (Archaea, Bacteria, Eukaryota, Virus, Plasmid, or Environmental Sample).

=item genetic_code

Genetic code number used for protein translation on most of this genome sequence's contigs.

=item gc_content

Percent GC content present in the genome sequence's DNA.

=item phenotype

zero or more strings describing phenotypic information about this genome sequence

=item md5

MD5 identifier describing the genome's DNA sequence

=item source_id

identifier assigned to this genome by the original source


=back
    */

    funcdef get_entity_Genome(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Genome>);
    funcdef query_entity_Genome(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Genome>);
    funcdef all_entities_Genome(int start, int count, list<string> fields)
	returns(mapping<string, fields_Genome>);
	

    typedef structure {
        string id;
	string source_name;
	string city;
	string state;
	string country;
	string origcty;
	int elevation;
	int latitude;
	int longitude;
	string lo_accession;
    } fields_Locality;

    /*
A locality is a geographic location.

It has the following fields:

=over 4

=item source_name

Name or description of the location used as a collection site.

=item city

City of the collecting site.

=item state

State or province of the collecting site.

=item country

Country of the collecting site.

=item origcty

3-letter ISO 3166-1 extended country code for the country of origin.

=item elevation

Elevation of the collecting site, expressed in meters above sea level.  Negative values are allowed.

=item latitude

Latitude of the collecting site, recorded as a decimal number.  North latitudes are positive values and south latitudes are negative numbers.

=item longitude

Longitude of the collecting site, recorded as a decimal number.  West longitudes are positive values and east longitudes are negative numbers.

=item lo_accession

gazeteer ontology term ID


=back
    */

    funcdef get_entity_Locality(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Locality>);
    funcdef query_entity_Locality(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Locality>);
    funcdef all_entities_Locality(int start, int count, list<string> fields)
	returns(mapping<string, fields_Locality>);
	

    typedef structure {
        string id;
    } fields_LocalizedCompound;

    /*
This entity represents a compound occurring in a
specific location. A reaction always involves localized
compounds. If a reaction occurs entirely in a single
location, it will frequently only be represented by the
cytoplasmic versions of the compounds; however, a transport
always uses specifically located compounds.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_LocalizedCompound(list<string> ids, list<string> fields)
	returns(mapping<string, fields_LocalizedCompound>);
    funcdef query_entity_LocalizedCompound(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_LocalizedCompound>);
    funcdef all_entities_LocalizedCompound(int start, int count, list<string> fields)
	returns(mapping<string, fields_LocalizedCompound>);
	

    typedef structure {
        string id;
	string mod_date;
	string name;
	string source_id;
	int abbr;
    } fields_Location;

    /*
A location is a region of the cell where reaction compounds
originate from or are transported to (e.g. cell wall, extracellular,
cytoplasm).

It has the following fields:

=over 4

=item mod_date

date and time of the last modification to the compartment's definition

=item name

common name for the location

=item source_id

ID from the source of this location

=item abbr

an abbreviation (usually a single letter) for the location.


=back
    */

    funcdef get_entity_Location(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Location>);
    funcdef query_entity_Location(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Location>);
    funcdef all_entities_Location(int start, int count, list<string> fields)
	returns(mapping<string, fields_Location>);
	

    typedef structure {
        string id;
	int index;
	list<string> label;
	float pH;
	float potential;
    } fields_LocationInstance;

    /*
The Location Instance represents a region of a cell
(e.g. cell wall, cytoplasm) as it appears in a specific
model.

It has the following fields:

=over 4

=item index

number used to distinguish between different instances of the same type of location in a single model. Within a model, any two instances of the same location must have difference compartment index values.

=item label

description used to differentiate between instances of the same location in a single model

=item pH

pH of the cell region, which is used to determine compound charge and pH gradient across cell membranes

=item potential

electrochemical potential of the cell region, which is used to determine the electrochemical gradient across cell membranes


=back
    */

    funcdef get_entity_LocationInstance(list<string> ids, list<string> fields)
	returns(mapping<string, fields_LocationInstance>);
    funcdef query_entity_LocationInstance(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_LocationInstance>);
    funcdef all_entities_LocationInstance(int start, int count, list<string> fields)
	returns(mapping<string, fields_LocationInstance>);
	

    typedef structure {
        string id;
	string source_id;
	float value;
	float mean;
	float median;
	float stddev;
	int N;
	float p_value;
	float Z_score;
    } fields_Measurement;

    /*
A Measurement is a value generated by performing a protocol to
evaluate a value on an ExperimentalUnit - e.g. a strain in an
environment.

It has the following fields:

=over 4

=item source_id

The ID of the measurement used by the data source.

=item value

The value of the measurement.

=item mean

The mean of multiple replicates if they are included in the measurement.

=item median

The median of multiple replicates if they are included in the measurement.

=item stddev

The standard deviation of multiple replicates if they are included in the measurement.

=item N

The number of replicates if they are included in the measurement.

=item p_value

The p-value of multiple replicates if they are included in the measurement. The exact meaning of the p-value is specified in the MeasurementDescription object for this measurement.

=item Z_score

The Z-score of multiple replicates if they are included in the measurement. The exact meaning of the Z-score is specified in the MeasurementDescription object for this measurement.


=back
    */

    funcdef get_entity_Measurement(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Measurement>);
    funcdef query_entity_Measurement(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Measurement>);
    funcdef all_entities_Measurement(int start, int count, list<string> fields)
	returns(mapping<string, fields_Measurement>);
	

    typedef structure {
        string id;
	string name;
	string description;
	string unitOfMeasure;
	string category;
	string source_id;
    } fields_MeasurementDescription;

    /*
A MeasurementDescription provides information about a
measurement value.

It has the following fields:

=over 4

=item name

The name of the measurement.

=item description

The description of the measurement, how it is measured, and what the measurement statistics mean.

=item unitOfMeasure

The units of the measurement.

=item category

The category the measurement fits into, for example phenotype, experimental input, environment.

=item source_id

The ID of the measurement description used by the data source.


=back
    */

    funcdef get_entity_MeasurementDescription(list<string> ids, list<string> fields)
	returns(mapping<string, fields_MeasurementDescription>);
    funcdef query_entity_MeasurementDescription(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_MeasurementDescription>);
    funcdef all_entities_MeasurementDescription(int start, int count, list<string> fields)
	returns(mapping<string, fields_MeasurementDescription>);
	

    typedef structure {
        string id;
	string mod_date;
	string name;
	string is_minimal;
	string source_id;
	string type;
    } fields_Media;

    /*
A media describes the chemical content of the solution in which cells
are grown in an experiment or for the purposes of a model. The key is the
common media name. The nature of the media is described by its relationship
to its constituent compounds.

It has the following fields:

=over 4

=item mod_date

date and time of the last modification to the media's definition

=item name

descriptive name of the media

=item is_minimal

TRUE if this is a minimal media, else FALSE

=item source_id

The ID of the media used by the data source.

=item type

The general category of the media.


=back
    */

    funcdef get_entity_Media(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Media>);
    funcdef query_entity_Media(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Media>);
    funcdef all_entities_Media(int start, int count, list<string> fields)
	returns(mapping<string, fields_Media>);
	

    typedef structure {
        string id;
	string mod_date;
	string name;
	int version;
	string type;
	string status;
	int reaction_count;
	int compound_count;
	int annotation_count;
    } fields_Model;

    /*
A model specifies a relationship between sets of features and
reactions in a cell. It is used to simulate cell growth and gene
knockouts to validate annotations.

It has the following fields:

=over 4

=item mod_date

date and time of the last change to the model data

=item name

descriptive name of the model

=item version

revision number of the model

=item type

string indicating where the model came from (e.g. single genome, multiple genome, or community model)

=item status

indicator of whether the model is stable, under construction, or under reconstruction

=item reaction_count

number of reactions in the model

=item compound_count

number of compounds in the model

=item annotation_count

number of features associated with one or more reactions in the model


=back
    */

    funcdef get_entity_Model(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Model>);
    funcdef query_entity_Model(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Model>);
    funcdef all_entities_Model(int start, int count, list<string> fields)
	returns(mapping<string, fields_Model>);
	

    typedef structure {
        string id;
    } fields_OTU;

    /*
An OTU (Organism Taxonomic Unit) is a named group of related
genomes.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_OTU(list<string> ids, list<string> fields)
	returns(mapping<string, fields_OTU>);
    funcdef query_entity_OTU(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_OTU>);
    funcdef all_entities_OTU(int start, int count, list<string> fields)
	returns(mapping<string, fields_OTU>);
	

    typedef structure {
        string id;
	string source_name;
	list<string> source_name2;
	string plant_id;
    } fields_ObservationalUnit;

    /*
An ObservationalUnit is an individual plant that 1) is part of an experiment or study, 2) has measured traits, and 3) is assayed for the purpose of determining alleles.  

It has the following fields:

=over 4

=item source_name

Name/ID by which the observational unit may be known by the originator and is used in queries.

=item source_name2

Secondary name/ID by which the observational unit may be known and is queried.

=item plant_id

ID of the plant that was tested to produce this observational unit. Observational units with the same plant ID are different assays of a single physical organism.


=back
    */

    funcdef get_entity_ObservationalUnit(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ObservationalUnit>);
    funcdef query_entity_ObservationalUnit(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ObservationalUnit>);
    funcdef all_entities_ObservationalUnit(int start, int count, list<string> fields)
	returns(mapping<string, fields_ObservationalUnit>);
	

    typedef structure {
        string id;
	string id;
	string name;
	string definition;
	string ontologySource;
    } fields_Ontology;

    /*
-- Environmental Ontology. (ENVO Terms) http://environmentontology.org/  
-- Plant Ontology (PO Terms). http://www.plantontology.org/   
-- Plant Environmental Ontology (EO Terms). http://www.gramene.org/plant_ontology/index.html#eo
-- ENVO : http://envo.googlecode.com/svn/trunk/src/envo/envo-basic.obo
-- PO : http://palea.cgrb.oregonstate.edu/viewsvn/Poc/tags/live/plant_ontology.obo?view=co
-- EO : http://obo.cvs.sourceforge.net/viewvc/obo/obo/ontology/phenotype/environment/environment_ontology.obo


It has the following fields:

=over 4

=item id

Ontologgy ID.

=item name

Type of the ontology.

=item definition

Definition of the ontology

=item ontologySource

Enumerated value (ENVO, EO, PO).


=back
    */

    funcdef get_entity_Ontology(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Ontology>);
    funcdef query_entity_Ontology(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Ontology>);
    funcdef all_entities_Ontology(int start, int count, list<string> fields)
	returns(mapping<string, fields_Ontology>);
	

    typedef structure {
        string id;
    } fields_Operon;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_entity_Operon(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Operon>);
    funcdef query_entity_Operon(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Operon>);
    funcdef all_entities_Operon(int start, int count, list<string> fields)
	returns(mapping<string, fields_Operon>);
	

    typedef structure {
        string id;
	int score;
    } fields_PairSet;

    /*
A PairSet is a precompute set of pairs or genes.  Each
pair occurs close to one another of the chromosome.  We believe
that all of the first members of the pairs correspond to one another
(are quite similar), as do all of the second members of the pairs.
These pairs (from prokaryotic genomes) offer one of the most
powerful clues relating to uncharacterized genes/peroteins.

It has the following fields:

=over 4

=item score

Score for this evidence set. The score indicates the number of significantly different genomes represented by the pairings.


=back
    */

    funcdef get_entity_PairSet(list<string> ids, list<string> fields)
	returns(mapping<string, fields_PairSet>);
    funcdef query_entity_PairSet(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_PairSet>);
    funcdef all_entities_PairSet(int start, int count, list<string> fields)
	returns(mapping<string, fields_PairSet>);
	

    typedef structure {
        string id;
    } fields_Pairing;

    /*
A pairing indicates that two features are found
close together in a genome. Not all possible pairings are stored in
the database; only those that are considered for some reason to be
significant for annotation purposes.The key of the pairing is the
concatenation of the feature IDs in alphabetical order with an
intervening colon.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_Pairing(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Pairing>);
    funcdef query_entity_Pairing(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Pairing>);
    funcdef all_entities_Pairing(int start, int count, list<string> fields)
	returns(mapping<string, fields_Pairing>);
	

    typedef structure {
        string id;
    } fields_Parameter;

    /*
A parameter is the name of some quantity that has a value.


It has the following fields:

=over 4


=back
    */

    funcdef get_entity_Parameter(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Parameter>);
    funcdef query_entity_Parameter(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Parameter>);
    funcdef all_entities_Parameter(int start, int count, list<string> fields)
	returns(mapping<string, fields_Parameter>);
	

    typedef structure {
        string id;
	string firstName;
	string lastName;
	string contactEmail;
	string institution;
	string source_id;
    } fields_Person;

    /*
A person represents a human affiliated in some way with Kbase.

It has the following fields:

=over 4

=item firstName

The given name of the person.

=item lastName

The surname of the person.

=item contactEmail

Email address of the person.

=item institution

The institution where the person works.

=item source_id

The ID of the person used by the data source.


=back
    */

    funcdef get_entity_Person(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Person>);
    funcdef query_entity_Person(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Person>);
    funcdef all_entities_Person(int start, int count, list<string> fields)
	returns(mapping<string, fields_Person>);
	

    typedef structure {
        string id;
	string title;
	string externalSourceId;
	string technology;
	string type;
	string source_id;
    } fields_Platform;

    /*
Platform that the expression sample/experiment was run on.

It has the following fields:

=over 4

=item title

free text title of the comparison

=item externalSourceId

The externalSourceId gives users potentially an easy way to find the data of interest (ex:GPL514). This will keep them from having to do problematic likes on the source-id field.

=item technology

Ideally enumerated values, but may have to make this free text (spotted DNA/cDNA, spotted oligonucleotide, in situ oligonucleotide, antibody, tissue, SARST, RT-PCR, or MPSS).

=item type

Enumerated Microarray, RNA-Seq, qPCR

=item source_id

The ID used as the data source.


=back
    */

    funcdef get_entity_Platform(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Platform>);
    funcdef query_entity_Platform(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Platform>);
    funcdef all_entities_Platform(int start, int count, list<string> fields)
	returns(mapping<string, fields_Platform>);
	

    typedef structure {
        string id;
    } fields_ProbeSet;

    /*
A probe set is a device containing multiple probe sequences for use
in gene expression experiments.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_ProbeSet(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ProbeSet>);
    funcdef query_entity_ProbeSet(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ProbeSet>);
    funcdef all_entities_ProbeSet(int start, int count, list<string> fields)
	returns(mapping<string, fields_ProbeSet>);
	

    typedef structure {
        string id;
	string sequence;
    } fields_ProteinSequence;

    /*
We use the concept of ProteinSequence as an amino acid
string with an associated MD5 value.  It is easy to access the
set of Features that relate to a ProteinSequence.  While function
is still associated with Features (and may be for some time),
publications are associated with ProteinSequences (and the inferred
impact on Features is through the relationship connecting
ProteinSequences to Features).

It has the following fields:

=over 4

=item sequence

The sequence contains the letters corresponding to the protein's amino acids.


=back
    */

    funcdef get_entity_ProteinSequence(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ProteinSequence>);
    funcdef query_entity_ProteinSequence(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ProteinSequence>);
    funcdef all_entities_ProteinSequence(int start, int count, list<string> fields)
	returns(mapping<string, fields_ProteinSequence>);
	

    typedef structure {
        string id;
	string name;
	string description;
	string source_id;
    } fields_Protocol;

    /*
A Protocol is a step by step set of instructions for
performing a part of an experiment.

It has the following fields:

=over 4

=item name

The name of the protocol.

=item description

The step by step instructions for performing the experiment, including measurement details, materials, and equipment. A researcher should be able to reproduce the experimental results with this information.

=item source_id

The ID of the protocol used by the data source.


=back
    */

    funcdef get_entity_Protocol(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Protocol>);
    funcdef query_entity_Protocol(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Protocol>);
    funcdef all_entities_Protocol(int start, int count, list<string> fields)
	returns(mapping<string, fields_Protocol>);
	

    typedef structure {
        string id;
	string title;
	string link;
	string pubdate;
    } fields_Publication;

    /*
Experimenters attach publications to experiments and
protocols. Annotators attach publications to ProteinSequences.
The attached publications give an ID (usually a
DOI or Pubmed ID),  a URL to the paper (when we have it), and a title
(when we have it). Pubmed IDs are given unmodified. DOI IDs
are prefixed with [b]doi:[/b], e.g. [i]doi:1002385[/i].

It has the following fields:

=over 4

=item title

title of the article, or (unknown) if the title is not known

=item link

URL of the article, DOI preferred

=item pubdate

publication date of the article


=back
    */

    funcdef get_entity_Publication(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Publication>);
    funcdef query_entity_Publication(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Publication>);
    funcdef all_entities_Publication(int start, int count, list<string> fields)
	returns(mapping<string, fields_Publication>);
	

    typedef structure {
        string id;
	string mod_date;
	string name;
	string source_id;
	string abbr;
	string direction;
	float deltaG;
	float deltaG_error;
	string thermodynamic_reversibility;
	float default_protons;
	string status;
    } fields_Reaction;

    /*
A reaction is a chemical process that converts one set of
compounds (substrate) to another set (products).

It has the following fields:

=over 4

=item mod_date

date and time of the last modification to this reaction's definition

=item name

descriptive name of this reaction

=item source_id

ID of this reaction in the resource from which it was added

=item abbr

abbreviated name of this reaction

=item direction

direction of this reaction (> for forward-only, < for backward-only, = for bidirectional)

=item deltaG

Gibbs free-energy change for the reaction calculated using the group contribution method (units are kcal/mol)

=item deltaG_error

uncertainty in the [b]deltaG[/b] value (units are kcal/mol)

=item thermodynamic_reversibility

computed reversibility of this reaction in a pH-neutral environment

=item default_protons

number of protons absorbed by this reaction in a pH-neutral environment

=item status

string indicating additional information about this reaction, generally indicating whether the reaction is balanced and/or lumped


=back
    */

    funcdef get_entity_Reaction(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Reaction>);
    funcdef query_entity_Reaction(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Reaction>);
    funcdef all_entities_Reaction(int start, int count, list<string> fields)
	returns(mapping<string, fields_Reaction>);
	

    typedef structure {
        string id;
	string direction;
	float protons;
    } fields_ReactionInstance;

    /*
A reaction instance describes the specific implementation of
a reaction in a model.

It has the following fields:

=over 4

=item direction

reaction directionality (> for forward, < for backward, = for bidirectional) with respect to this model

=item protons

number of protons produced by this reaction when proceeding in the forward direction. If this is a transport reaction, these protons end up in the reaction instance's main location. If the number is negative, then the protons are consumed by the reaction rather than being produced.


=back
    */

    funcdef get_entity_ReactionInstance(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ReactionInstance>);
    funcdef query_entity_ReactionInstance(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ReactionInstance>);
    funcdef all_entities_ReactionInstance(int start, int count, list<string> fields)
	returns(mapping<string, fields_ReactionInstance>);
	

    typedef structure {
        string id;
	string name;
	string rfam_id;
	string tf_family;
	string type;
	string taxonomy;
    } fields_Regulator;

    /*


It has the following fields:

=over 4

=item name

A human-readable name for this Regulator. 

=item rfam_id

If this regulator is an RNA regulator, the rfam-id field will contain the RFAM identifier corresponding to it. 

=item tf_family

If this regulator is a transcription factor, then the tf-family field will contain the name of the transcription factor family. 

=item type

Type of the regulator; currently either RNA or TF. 

=item taxonomy

Type of the regulator; currently either RNA or TF. 


=back
    */

    funcdef get_entity_Regulator(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Regulator>);
    funcdef query_entity_Regulator(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Regulator>);
    funcdef all_entities_Regulator(int start, int count, list<string> fields)
	returns(mapping<string, fields_Regulator>);
	

    typedef structure {
        string id;
	string description;
    } fields_Regulog;

    /*


It has the following fields:

=over 4

=item description




=back
    */

    funcdef get_entity_Regulog(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Regulog>);
    funcdef query_entity_Regulog(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Regulog>);
    funcdef all_entities_Regulog(int start, int count, list<string> fields)
	returns(mapping<string, fields_Regulog>);
	

    typedef structure {
        string id;
	string name;
	string description;
    } fields_RegulogCollection;

    /*
A RegulogCollection describes a set of regulogs that are being
curated on well-defined set of genomes.


It has the following fields:

=over 4

=item name

The name of this regulog collection. 

=item description

A brief description of this regulog collection. 


=back
    */

    funcdef get_entity_RegulogCollection(list<string> ids, list<string> fields)
	returns(mapping<string, fields_RegulogCollection>);
    funcdef query_entity_RegulogCollection(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_RegulogCollection>);
    funcdef all_entities_RegulogCollection(int start, int count, list<string> fields)
	returns(mapping<string, fields_RegulogCollection>);
	

    typedef structure {
        string id;
	string description;
	string creation_date;
    } fields_Regulome;

    /*


It has the following fields:

=over 4

=item description

A short description for this regulome. 

=item creation_date

Creation date for this regulome.


=back
    */

    funcdef get_entity_Regulome(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Regulome>);
    funcdef query_entity_Regulome(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Regulome>);
    funcdef all_entities_Regulome(int start, int count, list<string> fields)
	returns(mapping<string, fields_Regulome>);
	

    typedef structure {
        string id;
	string description;
    } fields_Regulon;

    /*


It has the following fields:

=over 4

=item description

A short description for this regulon. 


=back
    */

    funcdef get_entity_Regulon(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Regulon>);
    funcdef query_entity_Regulon(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Regulon>);
    funcdef all_entities_Regulon(int start, int count, list<string> fields)
	returns(mapping<string, fields_Regulon>);
	

    typedef structure {
        string id;
    } fields_ReplicateGroup;

    /*
Keeps track of Replicate Groups of Expression Samples.  Has only an ID.  Relationship is the important part.


It has the following fields:

=over 4


=back
    */

    funcdef get_entity_ReplicateGroup(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ReplicateGroup>);
    funcdef query_entity_ReplicateGroup(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_ReplicateGroup>);
    funcdef all_entities_ReplicateGroup(int start, int count, list<string> fields)
	returns(mapping<string, fields_ReplicateGroup>);
	

    typedef structure {
        string id;
	int hypothetical;
    } fields_Role;

    /*
A role describes a biological function that may be fulfilled
by a feature. One of the main goals of the database is to assign
features to roles. Most roles are effected by the construction of
proteins. Some, however, deal with functional regulation and message
transmission.

It has the following fields:

=over 4

=item hypothetical

TRUE if a role is hypothetical, else FALSE


=back
    */

    funcdef get_entity_Role(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Role>);
    funcdef query_entity_Role(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Role>);
    funcdef all_entities_Role(int start, int count, list<string> fields)
	returns(mapping<string, fields_Role>);
	

    typedef structure {
        string id;
    } fields_SSCell;

    /*
An SSCell (SpreadSheet Cell) represents a role as it occurs
in a subsystem spreadsheet row. The key is a colon-delimited triple
containing an MD5 hash of the subsystem ID followed by a genome ID
(with optional region string) and a role abbreviation.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_SSCell(list<string> ids, list<string> fields)
	returns(mapping<string, fields_SSCell>);
    funcdef query_entity_SSCell(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_SSCell>);
    funcdef all_entities_SSCell(int start, int count, list<string> fields)
	returns(mapping<string, fields_SSCell>);
	

    typedef structure {
        string id;
	int curated;
	string region;
    } fields_SSRow;

    /*
An SSRow (that is, a row in a subsystem spreadsheet)
represents a collection of functional roles present in the
Features of a single Genome.  The roles are part of a designated
subsystem, and the features associated with each role are included
in the row. That is, a row amounts to an instance of a subsystem as
it exists in a specific, designated genome.

It has the following fields:

=over 4

=item curated

This flag is TRUE if the assignment of the molecular machine has been curated, and FALSE if it was made by an automated program.

=item region

Region in the genome for which the row is relevant. Normally, this is an empty string, indicating that the machine covers the whole genome. If a subsystem has multiple rows for a genome, this contains a location string describing the region occupied by this particular row.


=back
    */

    funcdef get_entity_SSRow(list<string> ids, list<string> fields)
	returns(mapping<string, fields_SSRow>);
    funcdef query_entity_SSRow(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_SSRow>);
    funcdef all_entities_SSRow(int start, int count, list<string> fields)
	returns(mapping<string, fields_SSRow>);
	

    typedef structure {
        string id;
	string title;
	string dataSource;
	string externalSourceId;
	string description;
	string molecule;
	string type;
	string kbaseSubmissionDate;
	string externalSourceDate;
	string custom;
	float originalLog2Median;
	string source_id;
	int dataQualityLevel;
    } fields_Sample;

    /*
A sample is an experiment.  
In intensity experiment situations the sample will map 1 to 1 to the GSM.  
In this case there will be corresponding log2level data stored in the Measurement table.


It has the following fields:

=over 4

=item title

free text title of the sample

=item dataSource

The Data Source will be a way to identify where the data came from.  Examples might be : GEO, SEED Expression Pipeline, Enigma, M3D

=item externalSourceId

The externalSourceId gives users potentially an easy way to find the data of interest (ex:GSM9514). This will keep them from having to do problematic likes on the source-id field.

=item description

Free-text descibing the experiment.

=item molecule

Enumerated field (total RNA, polyA RNA, cytoplasmic RNA, nuclear RNA, genomic DNA).

=item type

Enumerated Microarray, RNA-Seq, qPCR

=item kbaseSubmissionDate

date of submission to Kbase

=item externalSourceDate

date that may exist in the external source metadata (could be to GEO, M3D etc...)

=item custom

A flag to keep track if this series was generated by custom operations (averaging or comparison)

=item originalLog2Median

The Original Median of the sample in log2space.  If null means the original median was not able to be determined.

=item source_id

The ID of the environment used by the data source.

=item dataQualityLevel

The quality of the data.  Lower the number the better.  Details need to be worked out.


=back
    */

    funcdef get_entity_Sample(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Sample>);
    funcdef query_entity_Sample(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Sample>);
    funcdef all_entities_Sample(int start, int count, list<string> fields)
	returns(mapping<string, fields_Sample>);
	

    typedef structure {
        string id;
	string annotationDate;
	string source_id;
    } fields_SampleAnnotation;

    /*
Keeps track of ontology annotation date (and person if not automated).


It has the following fields:

=over 4

=item annotationDate

date of annotation

=item source_id

The ID of the environment used by the data source.


=back
    */

    funcdef get_entity_SampleAnnotation(list<string> ids, list<string> fields)
	returns(mapping<string, fields_SampleAnnotation>);
    funcdef query_entity_SampleAnnotation(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_SampleAnnotation>);
    funcdef all_entities_SampleAnnotation(int start, int count, list<string> fields)
	returns(mapping<string, fields_SampleAnnotation>);
	

    typedef structure {
        string id;
	string common_name;
    } fields_Scenario;

    /*
A scenario is a partial instance of a subsystem with a
defined set of reactions. Each scenario converts input compounds to
output compounds using reactions. The scenario may use all of the
reactions controlled by a subsystem or only some, and may also
incorporate additional reactions. Because scenario names are not
unique, the actual scenario ID is a number.

It has the following fields:

=over 4

=item common_name

Common name of the scenario. The name, rather than the ID number, is usually displayed everywhere.


=back
    */

    funcdef get_entity_Scenario(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Scenario>);
    funcdef query_entity_Scenario(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Scenario>);
    funcdef all_entities_Scenario(int start, int count, list<string> fields)
	returns(mapping<string, fields_Scenario>);
	

    typedef structure {
        string id;
	string title;
	string summary;
	string design;
	string externalSourceId;
	string kbaseSubmissionDate;
	string externalSourceDate;
	string source_id;
    } fields_Series;

    /*
A series refers to a group of samples for expression data.

It has the following fields:

=over 4

=item title

free text title of the series

=item summary

free text summary of the series

=item design

free text design of the series

=item externalSourceId

The externalSourceId gives users potentially an easy way to find the data of interest (ex:GSE2365). This will keep them from having to do problematic likes on the source-id field.

=item kbaseSubmissionDate

date of submission (to Kbase)

=item externalSourceDate

date that may exist in the external source metadata (could be to GEO, M3D etc...)

=item source_id

The ID of the environment used by the data source.


=back
    */

    funcdef get_entity_Series(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Series>);
    funcdef query_entity_Series(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Series>);
    funcdef all_entities_Series(int start, int count, list<string> fields)
	returns(mapping<string, fields_Series>);
	

    typedef structure {
        string id;
	string name;
	string url;
	string description;
    } fields_Source;

    /*
A source is a user or organization that is permitted to
assign its own identifiers or to submit bioinformatic objects
to the database.

It has the following fields:

=over 4

=item name

The user-readable name for this source.

=item url

The URL to a site with information about this source.

=item description

A short textual description of this source.


=back
    */

    funcdef get_entity_Source(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Source>);
    funcdef query_entity_Source(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Source>);
    funcdef all_entities_Source(int start, int count, list<string> fields)
	returns(mapping<string, fields_Source>);
	

    typedef structure {
        string id;
	string name;
	string description;
	string source_id;
	string aggregateData;
	string wildtype;
	string referenceStrain;
    } fields_Strain;

    /*
This entity represents an organism derived from a genome or
another organism with one or more modifications to the organism's
genome.

It has the following fields:

=over 4

=item name

The common or laboratory name of the strain, e.g. DH5a or JMP1004.

=item description

A description of the strain, e.g. knockout/modification methods, resulting phenotypes, etc.

=item source_id

The ID of the strain used by the data source.

=item aggregateData

Denotes whether this entity represents a physical strain (False) or aggregate data calculated from one or more strains (True).

=item wildtype

Denotes this strain is presumably identical to the parent genome.

=item referenceStrain

Denotes whether this strain is a reference strain; e.g. it is identical to the genome it's related to (True) or not (False). In contrast to wildtype, a referenceStrain is abstract and does not physically exist and is used for data that refers to a genome but not a particular strain. There should only exist one reference strain per genome and all reference strains are wildtype. 


=back
    */

    funcdef get_entity_Strain(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Strain>);
    funcdef query_entity_Strain(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Strain>);
    funcdef all_entities_Strain(int start, int count, list<string> fields)
	returns(mapping<string, fields_Strain>);
	

    typedef structure {
        string id;
	string source_name;
	string design;
	string originator;
    } fields_StudyExperiment;

    /*
An Experiment is a collection of observational units with one originator that are part of a specific study.  An experiment may be conducted at more than one location and in more than one season or year.

It has the following fields:

=over 4

=item source_name

Name/ID by which the experiment is known at the source.  

=item design

Design of the experiment including the numbers and types of observational units, traits, replicates, sampling plan, and analysis that are planned.

=item originator

Name of the individual or program that are the originators of the experiment.


=back
    */

    funcdef get_entity_StudyExperiment(list<string> ids, list<string> fields)
	returns(mapping<string, fields_StudyExperiment>);
    funcdef query_entity_StudyExperiment(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_StudyExperiment>);
    funcdef all_entities_StudyExperiment(int start, int count, list<string> fields)
	returns(mapping<string, fields_StudyExperiment>);
	

    typedef structure {
        string id;
	int version;
	string curator;
	string notes;
	string description;
	int usable;
	int private;
	int cluster_based;
	int experimental;
    } fields_Subsystem;

    /*
A subsystem is a set of functional roles that have been annotated simultaneously (e.g.,
the roles present in a specific pathway), with an associated subsystem spreadsheet
which encodes the fids in each genome that implement the functional roles in the
subsystem.

It has the following fields:

=over 4

=item version

version number for the subsystem. This value is incremented each time the subsystem is backed up.

=item curator

name of the person currently in charge of the subsystem

=item notes

descriptive notes about the subsystem

=item description

description of the subsystem's function in the cell

=item usable

TRUE if this is a usable subsystem, else FALSE. An unusable subsystem is one that is experimental or is of such low quality that it can negatively affect analysis.

=item private

TRUE if this is a private subsystem, else FALSE. A private subsystem has valid data, but is not considered ready for general distribution.

=item cluster_based

TRUE if this is a clustering-based subsystem, else FALSE. A clustering-based subsystem is one in which there is functional-coupling evidence that genes belong together, but we do not yet know what they do.

=item experimental

TRUE if this is an experimental subsystem, else FALSE. An experimental subsystem is designed for investigation and is not yet ready to be used in comparative analysis and annotation.


=back
    */

    funcdef get_entity_Subsystem(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Subsystem>);
    funcdef query_entity_Subsystem(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Subsystem>);
    funcdef all_entities_Subsystem(int start, int count, list<string> fields)
	returns(mapping<string, fields_Subsystem>);
	

    typedef structure {
        string id;
    } fields_SubsystemClass;

    /*
Subsystem classes impose a hierarchical organization on the
subsystems.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_SubsystemClass(list<string> ids, list<string> fields)
	returns(mapping<string, fields_SubsystemClass>);
    funcdef query_entity_SubsystemClass(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_SubsystemClass>);
    funcdef all_entities_SubsystemClass(int start, int count, list<string> fields)
	returns(mapping<string, fields_SubsystemClass>);
	

    typedef structure {
        string id;
	int domain;
	int hidden;
	string scientific_name;
	list<string> alias;
    } fields_TaxonomicGrouping;

    /*
We associate with most genomes a "taxonomy" based on
the NCBI taxonomy. This includes, for each genome, a list of
ever larger taxonomic groups. The groups are stored as
instances of this entity, and chained together by the
IsGroupFor relationship.

It has the following fields:

=over 4

=item domain

TRUE if this is a domain grouping, else FALSE.

=item hidden

TRUE if this is a hidden grouping, else FALSE. Hidden groupings are not typically shown in a lineage list.

=item scientific_name

Primary scientific name for this grouping. This is the name used when displaying a taxonomy.

=item alias

Alternate name for this grouping. A grouping may have many alternate names. The scientific name should also be in this list.


=back
    */

    funcdef get_entity_TaxonomicGrouping(list<string> ids, list<string> fields)
	returns(mapping<string, fields_TaxonomicGrouping>);
    funcdef query_entity_TaxonomicGrouping(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_TaxonomicGrouping>);
    funcdef all_entities_TaxonomicGrouping(int start, int count, list<string> fields)
	returns(mapping<string, fields_TaxonomicGrouping>);
	

    typedef structure {
        string id;
	string source_id;
	string name;
	string comments;
	string timeUnits;
    } fields_TimeSeries;

    /*
A TimeSeries provides a means to specify a series of experimental data
over time by ordering multiple ExperimentalUnits.


It has the following fields:

=over 4

=item source_id

The ID of the time series used by the data source.

=item name

The name of this time series, if any.

=item comments

Any comments regarding this time series.

=item timeUnits

The units of time for this time series, e.g. 'seconds', 'hours', or more abstractly, 'number of times culture grown to saturation.'


=back
    */

    funcdef get_entity_TimeSeries(list<string> ids, list<string> fields)
	returns(mapping<string, fields_TimeSeries>);
    funcdef query_entity_TimeSeries(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_TimeSeries>);
    funcdef all_entities_TimeSeries(int start, int count, list<string> fields)
	returns(mapping<string, fields_TimeSeries>);
	

    typedef structure {
        string id;
	string trait_name;
	string unit_of_measure;
	string TO_ID;
	string protocol;
    } fields_Trait;

    /*
A Trait is a phenotypic quality that can be measured or observed for an observational unit.  Examples include height, sugar content, color, or cold tolerance.

It has the following fields:

=over 4

=item trait_name

Text name or description of the trait

=item unit_of_measure

The units of measure used when determining this trait.  If multiple units of measure are applicable, each has its own row in the database.  

=item TO_ID

Trait Ontology term ID (http://www.gramene.org/plant-ontology/)

=item protocol

A thorough description of how the trait was collected, and if a rating, the minimum and maximum values


=back
    */

    funcdef get_entity_Trait(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Trait>);
    funcdef query_entity_Trait(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Trait>);
    funcdef all_entities_Trait(int start, int count, list<string> fields)
	returns(mapping<string, fields_Trait>);
	

    typedef structure {
        string id;
	string status;
	string data_type;
	string timestamp;
	string method;
	string parameters;
	string protocol;
	string source_id;
	string newick;
    } fields_Tree;

    /*
A tree describes how the sequences in an alignment relate
to each other. Most trees are phylogenetic, but some may be based on
taxonomy or gene content.

It has the following fields:

=over 4

=item status

status of the tree, currently either [i]active[/i], [i]superseded[/i], or [i]bad[/i]

=item data_type

type of data the tree was built from, usually [i]sequence_alignment[/i]

=item timestamp

date and time the tree was loaded

=item method

name of the primary software package or script used to construct the tree

=item parameters

non-default parameters used as input to the software package or script indicated in the method attribute

=item protocol

description of the steps taken to construct the tree, or a reference to an external pipeline

=item source_id

ID of this tree in the source database

=item newick

NEWICK format string containing the structure of the tree


=back
    */

    funcdef get_entity_Tree(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Tree>);
    funcdef query_entity_Tree(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Tree>);
    funcdef all_entities_Tree(int start, int count, list<string> fields)
	returns(mapping<string, fields_Tree>);
	

    typedef structure {
        string id;
    } fields_TreeAttribute;

    /*
This entity represents an attribute type that can
be assigned to a tree. The attribute
values are stored in the relationships to the target. The
key is the attribute name.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_TreeAttribute(list<string> ids, list<string> fields)
	returns(mapping<string, fields_TreeAttribute>);
    funcdef query_entity_TreeAttribute(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_TreeAttribute>);
    funcdef all_entities_TreeAttribute(int start, int count, list<string> fields)
	returns(mapping<string, fields_TreeAttribute>);
	

    typedef structure {
        string id;
    } fields_TreeNodeAttribute;

    /*
This entity represents an attribute type that can
be assigned to a node. The attribute
values are stored in the relationships to the target. The
key is the attribute name.

It has the following fields:

=over 4


=back
    */

    funcdef get_entity_TreeNodeAttribute(list<string> ids, list<string> fields)
	returns(mapping<string, fields_TreeNodeAttribute>);
    funcdef query_entity_TreeNodeAttribute(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_TreeNodeAttribute>);
    funcdef all_entities_TreeNodeAttribute(int start, int count, list<string> fields)
	returns(mapping<string, fields_TreeNodeAttribute>);
	

    typedef structure {
        string id;
	list<string> role_rule;
	string code;
	string type;
	string comment;
    } fields_Variant;

    /*
Each subsystem may include the designation of distinct
variants.  Thus, there may be three closely-related, but
distinguishable forms of histidine degradation.  Each form
would be called a "variant", with an associated code, and all
genomes implementing a specific variant can easily be accessed. The ID
is an MD5 of the subsystem name followed by the variant code.

It has the following fields:

=over 4

=item role_rule

a space-delimited list of role IDs, in alphabetical order, that represents a possible list of non-auxiliary roles applicable to this variant. The roles are identified by their abbreviations. A variant may have multiple role rules.

=item code

the variant code all by itself

=item type

variant type indicating the quality of the subsystem support. A type of "vacant" means that the subsystem does not appear to be implemented by the variant. A type of "incomplete" means that the subsystem appears to be missing many reactions. In all other cases, the type is "normal".

=item comment

commentary text about the variant


=back
    */

    funcdef get_entity_Variant(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Variant>);
    funcdef query_entity_Variant(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_Variant>);
    funcdef all_entities_Variant(int start, int count, list<string> fields)
	returns(mapping<string, fields_Variant>);
	


    typedef structure {
        string from_link;
	string to_link;
	int level;
    } fields_AffectsLevelOf;

    /*
This relationship indicates the expression level of an atomic regulon
for a given experiment.

It has the following fields:

=over 4

=item level

Indication of whether the feature is expressed (1), not expressed (-1), or unknown (0).


=back
    */

    funcdef get_relationship_AffectsLevelOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Experiment,
			   fields_AffectsLevelOf,
			   fields_AtomicRegulon>>);
		     
	
    funcdef get_relationship_IsAffectedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AtomicRegulon,
			   fields_AffectsLevelOf,
			   fields_Experiment>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Aligned;

    /*
This relationship connects an alignment to the database
from which it was generated.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Aligned(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_Aligned,
			   fields_Alignment>>);
		     
	
    funcdef get_relationship_WasAlignedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Alignment,
			   fields_Aligned,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string function;
	string external_id;
	string organism;
	int gi_number;
	string release_date;
    } fields_AssertsFunctionFor;

    /*
Sources (users) can make assertions about protein sequence function.
The assertion is associated with an external identifier.

It has the following fields:

=over 4

=item function

text of the assertion made about the identifier. It may be an empty string, indicating the function is unknown.

=item external_id

external identifier used in making the assertion

=item organism

organism name associated with this assertion. If the assertion is not associated with a specific organism, this will be an empty string.

=item gi_number

NCBI GI number associated with the asserted identifier

=item release_date

date and time the assertion was downloaded


=back
    */

    funcdef get_relationship_AssertsFunctionFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_AssertsFunctionFor,
			   fields_ProteinSequence>>);
		     
	
    funcdef get_relationship_HasAssertedFunctionFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProteinSequence,
			   fields_AssertsFunctionFor,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int stoichiometry;
	float strength;
	int rank;
    } fields_AssociationFeature;

    /*
The AssociationFeature relationship links associations to
the features that encode their component proteins.

It has the following fields:

=over 4

=item stoichiometry

Stoichiometry, if applicable (e.g., for a curated complex.

=item strength

Optional numeric measure of strength of the association (e.g., kD or relative estimate of binding affinity)

=item rank

Numbered starting at 1 within an Association, if directional.  Meaning is method-dependent; e.g., for associations derived from pulldown data, rank 1 should be assigned to the bait.


=back
    */

    funcdef get_relationship_AssociationFeature(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Association,
			   fields_AssociationFeature,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_FeatureInteractsIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_AssociationFeature,
			   fields_Association>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_CompoundMeasuredBy;

    /*
Denotes the compound that a measurement quantifies.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_CompoundMeasuredBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_CompoundMeasuredBy,
			   fields_Measurement>>);
		     
	
    funcdef get_relationship_MeasuresCompound(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Measurement,
			   fields_CompoundMeasuredBy,
			   fields_Compound>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Concerns;

    /*
This relationship connects a publication to the protein
sequences it describes.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Concerns(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Publication,
			   fields_Concerns,
			   fields_ProteinSequence>>);
		     
	
    funcdef get_relationship_IsATopicOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProteinSequence,
			   fields_Concerns,
			   fields_Publication>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float molar_ratio;
    } fields_ConsistsOfCompounds;

    /*
This relationship defines the subcompounds that make up a
compound. For example, CoCl2-6H2O is made up of 1 Co2+, 2 Cl-, and
6 H2O.

It has the following fields:

=over 4

=item molar_ratio

Number of molecules of the subcompound that make up the compound. A -1 in this field signifies that although the subcompound is present in the compound, the molar ratio is unknown.


=back
    */

    funcdef get_relationship_ConsistsOfCompounds(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_ConsistsOfCompounds,
			   fields_Compound>>);
		     
	
    funcdef get_relationship_ComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_ConsistsOfCompounds,
			   fields_Compound>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Contains;

    /*
This relationship connects a subsystem spreadsheet cell to the features
that occur in it. A feature may occur in many machine roles and a
machine role may contain many features. The subsystem annotation
process is essentially the maintenance of this relationship.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Contains(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SSCell,
			   fields_Contains,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_IsContainedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_Contains,
			   fields_SSCell>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int index_in_concatenation;
	int beg_pos_in_parent;
	int end_pos_in_parent;
	int parent_seq_len;
	int beg_pos_aln;
	int end_pos_aln;
	string kb_feature_id;
    } fields_ContainsAlignedDNA;

    /*
This relationship connects a nucleotide alignment row to the
contig sequences from which its components are formed.

It has the following fields:

=over 4

=item index_in_concatenation

1-based ordinal position in the alignment row of this nucleotide sequence

=item beg_pos_in_parent

1-based position in the contig sequence of the first nucleotide that appears in the alignment

=item end_pos_in_parent

1-based position in the contig sequence of the last nucleotide that appears in the alignment

=item parent_seq_len

length of original sequence

=item beg_pos_aln

the 1-based column index in the alignment where this nucleotide sequence begins

=item end_pos_aln

the 1-based column index in the alignment where this nucleotide sequence ends

=item kb_feature_id

ID of the feature relevant to this sequence, or an empty string if the sequence is not specific to a genome


=back
    */

    funcdef get_relationship_ContainsAlignedDNA(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AlignmentRow,
			   fields_ContainsAlignedDNA,
			   fields_ContigSequence>>);
		     
	
    funcdef get_relationship_IsAlignedDNAComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ContigSequence,
			   fields_ContainsAlignedDNA,
			   fields_AlignmentRow>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int index_in_concatenation;
	int beg_pos_in_parent;
	int end_pos_in_parent;
	int parent_seq_len;
	int beg_pos_aln;
	int end_pos_aln;
	string kb_feature_id;
    } fields_ContainsAlignedProtein;

    /*
This relationship connects a protein alignment row to the
protein sequences from which its components are formed.

It has the following fields:

=over 4

=item index_in_concatenation

1-based ordinal position in the alignment row of this protein sequence

=item beg_pos_in_parent

1-based position in the protein sequence of the first amino acid that appears in the alignment

=item end_pos_in_parent

1-based position in the protein sequence of the last amino acid that appears in the alignment

=item parent_seq_len

length of original sequence

=item beg_pos_aln

the 1-based column index in the alignment where this protein sequence begins

=item end_pos_aln

the 1-based column index in the alignment where this protein sequence ends

=item kb_feature_id

ID of the feature relevant to this protein, or an empty string if the protein is not specific to a genome


=back
    */

    funcdef get_relationship_ContainsAlignedProtein(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AlignmentRow,
			   fields_ContainsAlignedProtein,
			   fields_ProteinSequence>>);
		     
	
    funcdef get_relationship_IsAlignedProteinComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProteinSequence,
			   fields_ContainsAlignedProtein,
			   fields_AlignmentRow>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string location;
	string groupMeta;
    } fields_ContainsExperimentalUnit;

    /*
Experimental units may be collected into groups, such as assay
plates. This relationship describes which experimenal units belong to
which groups.

It has the following fields:

=over 4

=item location

The location, if any, of the experimental unit in the group. Often a plate locator, e.g. 'G11' for 96 well plates.

=item groupMeta

Denotes that the associated ExperimentalUnit's data measures the group as a whole - for example, summary statistics.


=back
    */

    funcdef get_relationship_ContainsExperimentalUnit(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentalUnitGroup,
			   fields_ContainsExperimentalUnit,
			   fields_ExperimentalUnit>>);
		     
	
    funcdef get_relationship_GroupedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentalUnit,
			   fields_ContainsExperimentalUnit,
			   fields_ExperimentalUnitGroup>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Controls;

    /*
This relationship connects a coregulated set to the
features that are used as its transcription factors.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Controls(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_Controls,
			   fields_CoregulatedSet>>);
		     
	
    funcdef get_relationship_IsControlledUsing(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_CoregulatedSet,
			   fields_Controls,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_DefaultControlSample;

    /*
The Default control for samples to compare against.  (Log2 measurments of Test Sample)/(Log2 measurements of Default Control).
Really minus instead of divide since the values are already in Log2 Space.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_DefaultControlSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_DefaultControlSample,
			   fields_Sample>>);
		     
	
    funcdef get_relationship_SamplesDefaultControl(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_DefaultControlSample,
			   fields_Sample>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Describes;

    /*
This relationship connects a subsystem to the individual
variants used to implement it. Each variant contains a slightly
different subset of the roles in the parent subsystem.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Describes(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Subsystem,
			   fields_Describes,
			   fields_Variant>>);
		     
	
    funcdef get_relationship_IsDescribedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Variant,
			   fields_Describes,
			   fields_Subsystem>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string value;
    } fields_DescribesAlignment;

    /*
This relationship connects an alignment to its free-form
attributes.

It has the following fields:

=over 4

=item value

value of this attribute


=back
    */

    funcdef get_relationship_DescribesAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AlignmentAttribute,
			   fields_DescribesAlignment,
			   fields_Alignment>>);
		     
	
    funcdef get_relationship_HasAlignmentAttribute(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Alignment,
			   fields_DescribesAlignment,
			   fields_AlignmentAttribute>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_DescribesMeasurement;

    /*
The DescribesMeasurement relationship specifies a description
for a particular measurement.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_DescribesMeasurement(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_MeasurementDescription,
			   fields_DescribesMeasurement,
			   fields_Measurement>>);
		     
	
    funcdef get_relationship_IsDefinedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Measurement,
			   fields_DescribesMeasurement,
			   fields_MeasurementDescription>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string value;
    } fields_DescribesTree;

    /*
This relationship connects a tree to its free-form
attributes.

It has the following fields:

=over 4

=item value

value of this attribute


=back
    */

    funcdef get_relationship_DescribesTree(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_TreeAttribute,
			   fields_DescribesTree,
			   fields_Tree>>);
		     
	
    funcdef get_relationship_HasTreeAttribute(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Tree,
			   fields_DescribesTree,
			   fields_TreeAttribute>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string value;
	string node_id;
    } fields_DescribesTreeNode;

    /*
This relationship connects an tree to the free-form
attributes of its nodes.

It has the following fields:

=over 4

=item value

value of this attribute

=item node_id

ID of the node described by the attribute


=back
    */

    funcdef get_relationship_DescribesTreeNode(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_TreeNodeAttribute,
			   fields_DescribesTreeNode,
			   fields_Tree>>);
		     
	
    funcdef get_relationship_HasNodeAttribute(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Tree,
			   fields_DescribesTreeNode,
			   fields_TreeNodeAttribute>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_DetectedWithMethod;

    /*
The DetectedWithMethod relationship describes which
protein-protein associations were detected or annotated by
particular methods

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_DetectedWithMethod(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AssociationDetectionType,
			   fields_DetectedWithMethod,
			   fields_Association>>);
		     
	
    funcdef get_relationship_DetectedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Association,
			   fields_DetectedWithMethod,
			   fields_AssociationDetectionType>>);
	

    typedef structure {
        string from_link;
	string to_link;
	rectangle location;
    } fields_Displays;

    /*
This relationship connects a diagram to its reactions. A
diagram shows multiple reactions, and a reaction can be on many
diagrams.

It has the following fields:

=over 4

=item location

Location of the reaction's node on the diagram.


=back
    */

    funcdef get_relationship_Displays(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Diagram,
			   fields_Displays,
			   fields_Reaction>>);
		     
	
    funcdef get_relationship_IsDisplayedOn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Reaction,
			   fields_Displays,
			   fields_Diagram>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Encompasses;

    /*
This relationship connects a feature to a related
feature; for example, it would connect a gene to its
constituent splice variants, and the splice variants to their
exons.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Encompasses(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_Encompasses,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_IsEncompassedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_Encompasses,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_EvaluatedIn;

    /*
The EvaluatedIn relationship specifies the experimental
units performed on a particular strain.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_EvaluatedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Strain,
			   fields_EvaluatedIn,
			   fields_ExperimentalUnit>>);
		     
	
    funcdef get_relationship_IncludesStrain(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentalUnit,
			   fields_EvaluatedIn,
			   fields_Strain>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_FeatureIsTranscriptionFactorFor;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_FeatureIsTranscriptionFactorFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_FeatureIsTranscriptionFactorFor,
			   fields_Regulon>>);
		     
	
    funcdef get_relationship_HasTranscriptionFactorFeature(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulon,
			   fields_FeatureIsTranscriptionFactorFor,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_FeatureMeasuredBy;

    /*
Denotes the feature that a measurement quantifies.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_FeatureMeasuredBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_FeatureMeasuredBy,
			   fields_Measurement>>);
		     
	
    funcdef get_relationship_MeasuresFeature(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Measurement,
			   fields_FeatureMeasuredBy,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Formulated;

    /*
This relationship connects a coregulated set to the
source organization that originally computed it.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Formulated(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_Formulated,
			   fields_CoregulatedSet>>);
		     
	
    funcdef get_relationship_WasFormulatedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_CoregulatedSet,
			   fields_Formulated,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	string to_link;
	countVector level_vector;
    } fields_GeneratedLevelsFor;

    /*
This relationship connects an atomic regulon to a probe set from which experimental
data was produced for its features. It contains a vector of the expression levels.

It has the following fields:

=over 4

=item level_vector

Vector of expression levels (-1, 0, 1) for the experiments, in sequence order.


=back
    */

    funcdef get_relationship_GeneratedLevelsFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProbeSet,
			   fields_GeneratedLevelsFor,
			   fields_AtomicRegulon>>);
		     
	
    funcdef get_relationship_WasGeneratedFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AtomicRegulon,
			   fields_GeneratedLevelsFor,
			   fields_ProbeSet>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_GenomeParentOf;

    /*
The GenomeParentOf relationship specifies the direct child
strains of a specific genome.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_GenomeParentOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_GenomeParentOf,
			   fields_Strain>>);
		     
	
    funcdef get_relationship_DerivedFromGenome(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Strain,
			   fields_GenomeParentOf,
			   fields_Genome>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string alias;
    } fields_HasAliasAssertedFrom;

    /*
A Source may assert aliases for features.

It has the following fields:

=over 4

=item alias

text of the alias for the feature.


=back
    */

    funcdef get_relationship_HasAliasAssertedFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_HasAliasAssertedFrom,
			   fields_Source>>);
		     
	
    funcdef get_relationship_AssertsAliasFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_HasAliasAssertedFrom,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string alias;
    } fields_HasCompoundAliasFrom;

    /*
This relationship connects a source (database or organization)
with the compounds for which it has assigned names (aliases).
The alias itself is stored as intersection data.

It has the following fields:

=over 4

=item alias

alias for the compound assigned by the source


=back
    */

    funcdef get_relationship_HasCompoundAliasFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_HasCompoundAliasFrom,
			   fields_Compound>>);
		     
	
    funcdef get_relationship_UsesAliasForCompound(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_HasCompoundAliasFrom,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasEffector;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasEffector(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulon,
			   fields_HasEffector,
			   fields_Effector>>);
		     
	
    funcdef get_relationship_IsEffectorFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Effector,
			   fields_HasEffector,
			   fields_Regulon>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasExperimentalUnit;

    /*
The HasExperimentalUnit relationship describes which
ExperimentalUnits are part of a Experiment.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasExperimentalUnit(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentMeta,
			   fields_HasExperimentalUnit,
			   fields_ExperimentalUnit>>);
		     
	
    funcdef get_relationship_IsExperimentalUnitOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentalUnit,
			   fields_HasExperimentalUnit,
			   fields_ExperimentMeta>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasExpressionSample;

    /*
This relationship indicating the expression samples for an experimental unit.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasExpressionSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentalUnit,
			   fields_HasExpressionSample,
			   fields_Sample>>);
		     
	
    funcdef get_relationship_SampleBelongsToExperimentalUnit(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_HasExpressionSample,
			   fields_ExperimentalUnit>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasGenomes;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasGenomes(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_RegulogCollection,
			   fields_HasGenomes,
			   fields_Genome>>);
		     
	
    funcdef get_relationship_IsInRegulogCollection(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_HasGenomes,
			   fields_RegulogCollection>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float rma_value;
	int level;
    } fields_HasIndicatedSignalFrom;

    /*
This relationship connects an experiment to a feature. The feature
expression levels inferred from the experimental results are stored here.

It has the following fields:

=over 4

=item rma_value

Normalized expression value for this feature under the experiment's conditions.

=item level

Indication of whether the feature is expressed (1), not expressed (-1), or unknown (0).


=back
    */

    funcdef get_relationship_HasIndicatedSignalFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_HasIndicatedSignalFrom,
			   fields_Experiment>>);
		     
	
    funcdef get_relationship_IndicatesSignalFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Experiment,
			   fields_HasIndicatedSignalFrom,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasKnockoutIn;

    /*
The HasKnockoutIn relationship specifies the gene knockouts in
a particular strain.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasKnockoutIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Strain,
			   fields_HasKnockoutIn,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_KnockedOutIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_HasKnockoutIn,
			   fields_Strain>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasMeasurement;

    /*
The HasMeasurement relationship specifies a measurement(s)
performed on a particular experimental unit.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasMeasurement(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentalUnit,
			   fields_HasMeasurement,
			   fields_Measurement>>);
		     
	
    funcdef get_relationship_IsMeasureOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Measurement,
			   fields_HasMeasurement,
			   fields_ExperimentalUnit>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasMember;

    /*
This relationship connects each feature family to its
constituent features. A family always has many features, and a
single feature can be found in many families.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasMember(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Family,
			   fields_HasMember,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_IsMemberOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_HasMember,
			   fields_Family>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string value;
    } fields_HasParameter;

    /*
This relationship denotes which parameters each environment has,
as well as the value of the parameter.

It has the following fields:

=over 4

=item value

The value of the parameter.


=back
    */

    funcdef get_relationship_HasParameter(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Environment,
			   fields_HasParameter,
			   fields_Parameter>>);
		     
	
    funcdef get_relationship_OfEnvironment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Parameter,
			   fields_HasParameter,
			   fields_Environment>>);
	

    typedef structure {
        int from_link;
	string to_link;
	int type;
    } fields_HasParticipant;

    /*
A scenario consists of many participant reactions that
convert the input compounds to output compounds. A single reaction
may participate in many scenarios.

It has the following fields:

=over 4

=item type

Indicates the type of participaton. If 0, the reaction is in the main pathway of the scenario. If 1, the reaction is necessary to make the model work but is not in the subsystem. If 2, the reaction is part of the subsystem but should not be included in the modelling process.


=back
    */

    funcdef get_relationship_HasParticipant(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Scenario,
			   fields_HasParticipant,
			   fields_Reaction>>);
		     
	
    funcdef get_relationship_ParticipatesIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Reaction,
			   fields_HasParticipant,
			   fields_Scenario>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float concentration;
	float minimum_flux;
	float maximum_flux;
    } fields_HasPresenceOf;

    /*
This relationship connects a media to the compounds that
occur in it. The intersection data describes how much of each
compound can be found.

It has the following fields:

=over 4

=item concentration

The concentration of the compound in the media. A null value indicates that although the compound is present in the media, its concentration is not specified. This is typically the case for model medias which do not have physical analogs.

=item minimum_flux

minimum flux level for the compound in the medium.

=item maximum_flux

maximum flux level for the compound in the medium.


=back
    */

    funcdef get_relationship_HasPresenceOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Media,
			   fields_HasPresenceOf,
			   fields_Compound>>);
		     
	
    funcdef get_relationship_IsPresentIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_HasPresenceOf,
			   fields_Media>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string source_id;
    } fields_HasProteinMember;

    /*
This relationship connects each feature family to its
constituent protein sequences. A family always has many protein sequences,
and a single sequence can be found in many families.

It has the following fields:

=over 4

=item source_id

Native identifier used for the protein in the definition of the family. This will be its ID in the alignment, if one exists.


=back
    */

    funcdef get_relationship_HasProteinMember(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Family,
			   fields_HasProteinMember,
			   fields_ProteinSequence>>);
		     
	
    funcdef get_relationship_IsProteinMemberOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProteinSequence,
			   fields_HasProteinMember,
			   fields_Family>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string alias;
    } fields_HasReactionAliasFrom;

    /*
This relationship connects a source (database or organization)
with the reactions for which it has assigned names (aliases).
The alias itself is stored as intersection data.

It has the following fields:

=over 4

=item alias

alias for the reaction assigned by the source


=back
    */

    funcdef get_relationship_HasReactionAliasFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_HasReactionAliasFrom,
			   fields_Reaction>>);
		     
	
    funcdef get_relationship_UsesAliasForReaction(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Reaction,
			   fields_HasReactionAliasFrom,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasRegulogs;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasRegulogs(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_RegulogCollection,
			   fields_HasRegulogs,
			   fields_Regulog>>);
		     
	
    funcdef get_relationship_IsInCollection(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulog,
			   fields_HasRegulogs,
			   fields_RegulogCollection>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasRepresentativeOf;

    /*
This relationship connects a genome to the FIGfam protein families
for which it has representative proteins. This information can be computed
from other relationships, but it is provided explicitly to allow fast access
to a genome's FIGfam profile.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasRepresentativeOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_HasRepresentativeOf,
			   fields_Family>>);
		     
	
    funcdef get_relationship_IsRepresentedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Family,
			   fields_HasRepresentativeOf,
			   fields_Genome>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasRequirementOf;

    /*
This relationship connects a model to the instances of
reactions that represent how the reactions occur in the model.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasRequirementOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Model,
			   fields_HasRequirementOf,
			   fields_ReactionInstance>>);
		     
	
    funcdef get_relationship_IsARequirementOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ReactionInstance,
			   fields_HasRequirementOf,
			   fields_Model>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int sequence;
    } fields_HasResultsIn;

    /*
This relationship connects a probe set to the experiments that were
applied to it.

It has the following fields:

=over 4

=item sequence

Sequence number of this experiment in the various result vectors.


=back
    */

    funcdef get_relationship_HasResultsIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProbeSet,
			   fields_HasResultsIn,
			   fields_Experiment>>);
		     
	
    funcdef get_relationship_HasResultsFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Experiment,
			   fields_HasResultsIn,
			   fields_ProbeSet>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasSection;

    /*
This relationship connects a contig's sequence to its DNA
sequences.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasSection(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ContigSequence,
			   fields_HasSection,
			   fields_ContigChunk>>);
		     
	
    funcdef get_relationship_IsSectionOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ContigChunk,
			   fields_HasSection,
			   fields_ContigSequence>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasStep;

    /*
This relationship connects a complex to the reactions it
catalyzes.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasStep(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Complex,
			   fields_HasStep,
			   fields_Reaction>>);
		     
	
    funcdef get_relationship_IsStepOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Reaction,
			   fields_HasStep,
			   fields_Complex>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float value;
	string statistic_type;
	string measure_id;
    } fields_HasTrait;

    /*
This relationship contains the measurement values of a trait on a specific observational Unit

It has the following fields:

=over 4

=item value

value of the trait measurement

=item statistic_type

text description of the statistic type (e.g. mean, median)

=item measure_id

internal ID given to this measurement


=back
    */

    funcdef get_relationship_HasTrait(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ObservationalUnit,
			   fields_HasTrait,
			   fields_Trait>>);
		     
	
    funcdef get_relationship_Measures(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Trait,
			   fields_HasTrait,
			   fields_ObservationalUnit>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasUnits;

    /*
This relationship associates observational units with the
geographic location where the unit is planted.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasUnits(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Locality,
			   fields_HasUnits,
			   fields_ObservationalUnit>>);
		     
	
    funcdef get_relationship_IsLocated(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ObservationalUnit,
			   fields_HasUnits,
			   fields_Locality>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_HasUsage;

    /*
This relationship connects a specific compound in a model to the localized
compound to which it corresponds.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_HasUsage(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_LocalizedCompound,
			   fields_HasUsage,
			   fields_CompoundInstance>>);
		     
	
    funcdef get_relationship_IsUsageOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_CompoundInstance,
			   fields_HasUsage,
			   fields_LocalizedCompound>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string value;
    } fields_HasValueFor;

    /*
This relationship connects an experiment to its attributes. The attribute
values are stored here.

It has the following fields:

=over 4

=item value

Value of this attribute in the given experiment. This is always encoded as a string, but may in fact be a number.


=back
    */

    funcdef get_relationship_HasValueFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Experiment,
			   fields_HasValueFor,
			   fields_Attribute>>);
		     
	
    funcdef get_relationship_HasValueIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Attribute,
			   fields_HasValueFor,
			   fields_Experiment>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int position;
	int len;
	string data;
	string data2;
	float quality;
    } fields_HasVariationIn;

    /*
This relationship defines an observational unit's DNA variation
from a contig in the reference genome.

It has the following fields:

=over 4

=item position

Position of this variation in the reference contig.

=item len

Length of the variation in the reference contig. A length of zero indicates an insertion.

=item data

Replacement DNA for the variation on the primary chromosome. An empty string indicates a deletion. The primary chromosome is chosen arbitrarily among the two chromosomes of a plant's chromosome pair (one coming from the mother and one from the father).

=item data2

Replacement DNA for the variation on the secondary chromosome. This will frequently be the same as the primary chromosome string.

=item quality

Quality score assigned to this variation.


=back
    */

    funcdef get_relationship_HasVariationIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Contig,
			   fields_HasVariationIn,
			   fields_ObservationalUnit>>);
		     
	
    funcdef get_relationship_IsVariedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ObservationalUnit,
			   fields_HasVariationIn,
			   fields_Contig>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string source_name;
	int rank;
	float pvalue;
	int position;
    } fields_Impacts;

    /*
This relationship contains the best scoring statistical correlations between measured traits and the responsible alleles.

It has the following fields:

=over 4

=item source_name

Name of the study which analyzed the data and determined that a variation has impact on a trait

=item rank

Rank of the position among all positions correlated with this trait.

=item pvalue

P-value of the correlation between the variation and the trait

=item position

Position in the reference contig where the trait has an impact.


=back
    */

    funcdef get_relationship_Impacts(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Trait,
			   fields_Impacts,
			   fields_Contig>>);
		     
	
    funcdef get_relationship_IsImpactedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Contig,
			   fields_Impacts,
			   fields_Trait>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_ImplementsReaction;

    /*
This relationship connects features to reaction instances
that exist because the feature is included in a model.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_ImplementsReaction(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_ImplementsReaction,
			   fields_ReactionInstance>>);
		     
	
    funcdef get_relationship_ImplementedBasedOn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ReactionInstance,
			   fields_ImplementsReaction,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int sequence;
	string abbreviation;
	int auxiliary;
    } fields_Includes;

    /*
A subsystem is defined by its roles. The subsystem's variants
contain slightly different sets of roles, but all of the roles in a
variant must be connected to the parent subsystem by this
relationship. A subsystem always has at least one role, and a role
always belongs to at least one subsystem.

It has the following fields:

=over 4

=item sequence

Sequence number of the role within the subsystem. When the roles are formed into a variant, they will generally appear in sequence order.

=item abbreviation

Abbreviation for this role in this subsystem. The abbreviations are used in columnar displays, and they also appear on diagrams.

=item auxiliary

TRUE if this is an auxiliary role, or FALSE if this role is a functioning part of the subsystem.


=back
    */

    funcdef get_relationship_Includes(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Subsystem,
			   fields_Includes,
			   fields_Role>>);
		     
	
    funcdef get_relationship_IsIncludedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Role,
			   fields_Includes,
			   fields_Subsystem>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float concentration;
	string units;
    } fields_IncludesAdditionalCompounds;

    /*
This relationship connects a environment to the compounds that
occur in it. The intersection data describes how much of each
compound can be found.

It has the following fields:

=over 4

=item concentration

The concentration of the compound in the environment. A null value indicates that although the compound is present in the environment, its concentration is not specified. This is typically the case for model environments which do not have physical analogs.

=item units

vol%, g/L, or molar (mol/L).


=back
    */

    funcdef get_relationship_IncludesAdditionalCompounds(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Environment,
			   fields_IncludesAdditionalCompounds,
			   fields_Compound>>);
		     
	
    funcdef get_relationship_IncludedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_IncludesAdditionalCompounds,
			   fields_Environment>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IncludesAlignmentRow;

    /*
This relationship connects an alignment to its component
rows.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IncludesAlignmentRow(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Alignment,
			   fields_IncludesAlignmentRow,
			   fields_AlignmentRow>>);
		     
	
    funcdef get_relationship_IsAlignmentRowIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AlignmentRow,
			   fields_IncludesAlignmentRow,
			   fields_Alignment>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IncludesPart;

    /*
This relationship associates observational units with the
experiments that generated the data on them.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IncludesPart(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_StudyExperiment,
			   fields_IncludesPart,
			   fields_ObservationalUnit>>);
		     
	
    funcdef get_relationship_IsPartOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ObservationalUnit,
			   fields_IncludesPart,
			   fields_StudyExperiment>>);
	

    typedef structure {
        string from_link;
	string to_link;
	countVector level_vector;
    } fields_IndicatedLevelsFor;

    /*
This relationship connects a feature to a probe set from which experimental
data was produced for the feature. It contains a vector of the expression levels.

It has the following fields:

=over 4

=item level_vector

Vector of expression levels (-1, 0, 1) for the experiments, in sequence order.


=back
    */

    funcdef get_relationship_IndicatedLevelsFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProbeSet,
			   fields_IndicatedLevelsFor,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_HasLevelsFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IndicatedLevelsFor,
			   fields_ProbeSet>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float coefficient;
	int cofactor;
    } fields_Involves;

    /*
This relationship connects a reaction to the
specific localized compounds that participate in it.

It has the following fields:

=over 4

=item coefficient

Number of molecules of the compound that participate in a single instance of the reaction. For example, if a reaction produces two water molecules, the stoichiometry of water for the reaction would be two. When a reaction is written on paper in chemical notation, the stoichiometry is the number next to the chemical formula of the compound. The value is negative for substrates and positive for products.

=item cofactor

TRUE if the compound is a cofactor; FALSE if it is a major component of the reaction.


=back
    */

    funcdef get_relationship_Involves(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Reaction,
			   fields_Involves,
			   fields_LocalizedCompound>>);
		     
	
    funcdef get_relationship_IsInvolvedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_LocalizedCompound,
			   fields_Involves,
			   fields_Reaction>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsAnnotatedBy;

    /*
This relationship connects a feature to its annotations. A
feature may have multiple annotations, but an annotation belongs to
only one feature.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsAnnotatedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsAnnotatedBy,
			   fields_Annotation>>);
		     
	
    funcdef get_relationship_Annotates(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Annotation,
			   fields_IsAnnotatedBy,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsAssayOf;

    /*
This relationship associates each assay with the relevant
experiments.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsAssayOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Assay,
			   fields_IsAssayOf,
			   fields_StudyExperiment>>);
		     
	
    funcdef get_relationship_IsAssayedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_StudyExperiment,
			   fields_IsAssayOf,
			   fields_Assay>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsClassFor;

    /*
This relationship connects each subsystem class with the
subsystems that belong to it. A class can contain many subsystems,
but a subsystem is only in one class. Some subsystems are not in any
class, but this is usually a temporary condition.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsClassFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SubsystemClass,
			   fields_IsClassFor,
			   fields_Subsystem>>);
		     
	
    funcdef get_relationship_IsInClass(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Subsystem,
			   fields_IsClassFor,
			   fields_SubsystemClass>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int representative;
    } fields_IsCollectionOf;

    /*
A genome belongs to only one genome set. For each set, this relationship marks the genome to be used as its representative.

It has the following fields:

=over 4

=item representative

TRUE for the representative genome of the set, else FALSE.


=back
    */

    funcdef get_relationship_IsCollectionOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_OTU,
			   fields_IsCollectionOf,
			   fields_Genome>>);
		     
	
    funcdef get_relationship_IsCollectedInto(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_IsCollectionOf,
			   fields_OTU>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsComposedOf;

    /*
This relationship connects a genome to its
constituent contigs. Unlike contig sequences, a
contig belongs to only one genome.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsComposedOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_IsComposedOf,
			   fields_Contig>>);
		     
	
    funcdef get_relationship_IsComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Contig,
			   fields_IsComposedOf,
			   fields_Genome>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float coefficient;
    } fields_IsComprisedOf;

    /*
This relationship connects a biomass composition reaction to the
compounds specified as contained in the biomass.

It has the following fields:

=over 4

=item coefficient

number of millimoles of the compound instance that exists in one gram cell dry weight of biomass


=back
    */

    funcdef get_relationship_IsComprisedOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Biomass,
			   fields_IsComprisedOf,
			   fields_CompoundInstance>>);
		     
	
    funcdef get_relationship_Comprises(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_CompoundInstance,
			   fields_IsComprisedOf,
			   fields_Biomass>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsConfiguredBy;

    /*
This relationship connects a genome to the atomic regulons that
describe its state.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsConfiguredBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_IsConfiguredBy,
			   fields_AtomicRegulon>>);
		     
	
    funcdef get_relationship_ReflectsStateOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AtomicRegulon,
			   fields_IsConfiguredBy,
			   fields_Genome>>);
	

    typedef structure {
        int from_link;
	string to_link;
	float percent_identity;
	int alignment_length;
	int mismatches;
	int gap_openings;
	int protein_start;
	int protein_end;
	int domain_start;
	int domain_end;
	float e_value;
	float bit_score;
    } fields_IsConservedDomainModelFor;

    /*
This relationship connects a protein sequence with the conserved domains
that have been computed to be associated with it.


It has the following fields:

=over 4

=item percent_identity



=item alignment_length



=item mismatches



=item gap_openings



=item protein_start



=item protein_end



=item domain_start



=item domain_end



=item e_value



=item bit_score




=back
    */

    funcdef get_relationship_IsConservedDomainModelFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ConservedDomainModel,
			   fields_IsConservedDomainModelFor,
			   fields_ProteinSequence>>);
		     
	
    funcdef get_relationship_HasConservedDomainModel(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProteinSequence,
			   fields_IsConservedDomainModelFor,
			   fields_ConservedDomainModel>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsConsistentWith;

    /*
This relationship connects a functional role to the EC numbers consistent
with the chemistry described in the role.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsConsistentWith(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_EcNumber,
			   fields_IsConsistentWith,
			   fields_Role>>);
		     
	
    funcdef get_relationship_IsConsistentTo(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Role,
			   fields_IsConsistentWith,
			   fields_EcNumber>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsContextOf;

    /*
The IsContextOf relationship describes the enviroment a
subexperiment defined by an ExperimentalUnit was performed in.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsContextOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Environment,
			   fields_IsContextOf,
			   fields_ExperimentalUnit>>);
		     
	
    funcdef get_relationship_HasEnvironment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentalUnit,
			   fields_IsContextOf,
			   fields_Environment>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float coefficient;
    } fields_IsCoregulatedWith;

    /*
This relationship connects a feature with another feature in the
same genome with which it appears to be coregulated as a result of
expression data analysis.

It has the following fields:

=over 4

=item coefficient

Pearson correlation coefficient for this coregulation.


=back
    */

    funcdef get_relationship_IsCoregulatedWith(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsCoregulatedWith,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_HasCoregulationWith(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsCoregulatedWith,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int co_occurrence_evidence;
	int co_expression_evidence;
    } fields_IsCoupledTo;

    /*
This relationship connects two FIGfams that we believe to be related
either because their members occur in proximity on chromosomes or because
the members are expressed together. Such a relationship is evidence the
functions of the FIGfams are themselves related. This relationship is
commutative; only the instance in which the first FIGfam has a lower ID
than the second is stored.

It has the following fields:

=over 4

=item co_occurrence_evidence

number of times members of the two FIGfams occur close to each other on chromosomes

=item co_expression_evidence

number of times members of the two FIGfams are co-expressed in expression data experiments


=back
    */

    funcdef get_relationship_IsCoupledTo(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Family,
			   fields_IsCoupledTo,
			   fields_Family>>);
		     
	
    funcdef get_relationship_IsCoupledWith(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Family,
			   fields_IsCoupledTo,
			   fields_Family>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsDatasetFor;

    /*
The IsDatasetFor relationship describes which genomes
are covered by particular association datasets.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsDatasetFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AssociationDataset,
			   fields_IsDatasetFor,
			   fields_Genome>>);
		     
	
    funcdef get_relationship_HasAssociationDataset(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_IsDatasetFor,
			   fields_AssociationDataset>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int inverted;
    } fields_IsDeterminedBy;

    /*
A functional coupling evidence set exists because it has
pairings in it, and this relationship connects the evidence set to
its constituent pairings. A pairing cam belong to multiple evidence
sets.

It has the following fields:

=over 4

=item inverted

A pairing is an unordered pair of protein sequences, but its similarity to other pairings in a pair set is ordered. Let (A,B) be a pairing and (X,Y) be another pairing in the same set. If this flag is FALSE, then (A =~ X) and (B =~ Y). If this flag is TRUE, then (A =~ Y) and (B =~ X).


=back
    */

    funcdef get_relationship_IsDeterminedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_PairSet,
			   fields_IsDeterminedBy,
			   fields_Pairing>>);
		     
	
    funcdef get_relationship_Determines(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Pairing,
			   fields_IsDeterminedBy,
			   fields_PairSet>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsDividedInto;

    /*
This relationship connects a model to its instances of
subcellular locations that participate in the model.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsDividedInto(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Model,
			   fields_IsDividedInto,
			   fields_LocationInstance>>);
		     
	
    funcdef get_relationship_IsDivisionOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_LocationInstance,
			   fields_IsDividedInto,
			   fields_Model>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsExecutedAs;

    /*
This relationship links a reaction to the way it is used in a model.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsExecutedAs(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Reaction,
			   fields_IsExecutedAs,
			   fields_ReactionInstance>>);
		     
	
    funcdef get_relationship_IsExecutionOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ReactionInstance,
			   fields_IsExecutedAs,
			   fields_Reaction>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsExemplarOf;

    /*
This relationship links a role to a feature that provides a typical
example of how the role is implemented.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsExemplarOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsExemplarOf,
			   fields_Role>>);
		     
	
    funcdef get_relationship_HasAsExemplar(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Role,
			   fields_IsExemplarOf,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsFamilyFor;

    /*
This relationship connects an isofunctional family to the roles that
make up its assigned function.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsFamilyFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Family,
			   fields_IsFamilyFor,
			   fields_Role>>);
		     
	
    funcdef get_relationship_DeterminesFunctionOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Role,
			   fields_IsFamilyFor,
			   fields_Family>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsFormedOf;

    /*
This relationship connects each feature to the atomic regulon to
which it belongs.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsFormedOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AtomicRegulon,
			   fields_IsFormedOf,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_IsFormedInto(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsFormedOf,
			   fields_AtomicRegulon>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsFunctionalIn;

    /*
This relationship connects a role with the features in which
it plays a functional part.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsFunctionalIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Role,
			   fields_IsFunctionalIn,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_HasFunctional(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsFunctionalIn,
			   fields_Role>>);
	

    typedef structure {
        int from_link;
	int to_link;
    } fields_IsGroupFor;

    /*
The recursive IsGroupFor relationship organizes
taxonomic groupings into a hierarchy based on the standard organism
taxonomy.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsGroupFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_TaxonomicGrouping,
			   fields_IsGroupFor,
			   fields_TaxonomicGrouping>>);
		     
	
    funcdef get_relationship_IsInGroup(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_TaxonomicGrouping,
			   fields_IsGroupFor,
			   fields_TaxonomicGrouping>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsGroupingOf;

    /*
The IsGroupingOf relationship describes which
associations are part of a particular association
dataset.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsGroupingOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AssociationDataset,
			   fields_IsGroupingOf,
			   fields_Association>>);
		     
	
    funcdef get_relationship_InAssociationDataset(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Association,
			   fields_IsGroupingOf,
			   fields_AssociationDataset>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsImplementedBy;

    /*
This relationship connects a variant to the physical machines
that implement it in the genomes. A variant is implemented by many
machines, but a machine belongs to only one variant.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsImplementedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Variant,
			   fields_IsImplementedBy,
			   fields_SSRow>>);
		     
	
    funcdef get_relationship_Implements(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SSRow,
			   fields_IsImplementedBy,
			   fields_Variant>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int rank;
    } fields_IsInOperon;

    /*


It has the following fields:

=over 4

=item rank

The rank (order) of this feature in the operon.


=back
    */

    funcdef get_relationship_IsInOperon(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsInOperon,
			   fields_Operon>>);
		     
	
    funcdef get_relationship_OperonContains(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Operon,
			   fields_IsInOperon,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsInPair;

    /*
A pairing contains exactly two protein sequences. A protein
sequence can belong to multiple pairings. When going from a protein
sequence to its pairings, they are presented in alphabetical order
by sequence key.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsInPair(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsInPair,
			   fields_Pairing>>);
		     
	
    funcdef get_relationship_IsPairOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Pairing,
			   fields_IsInPair,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsInstantiatedBy;

    /*
This relationship connects a subcellular location to the instances
of that location that occur in models.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsInstantiatedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Location,
			   fields_IsInstantiatedBy,
			   fields_LocationInstance>>);
		     
	
    funcdef get_relationship_IsInstanceOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_LocationInstance,
			   fields_IsInstantiatedBy,
			   fields_Location>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int ordinal;
	int begin;
	int len;
	string dir;
    } fields_IsLocatedIn;

    /*
A feature is a set of DNA sequence fragments, the location of
which are specified by the fields of this relationship. Most features
are a single contiguous fragment, so they are located in only one
DNA sequence; however, for search optimization reasons, fragments
have a maximum length, so even a single contiguous feature may
participate in this relationship multiple times. Thus, it is better
to use the CDMI API methods to get feature positions and sequences
as those methods rejoin the fragements for contiguous features. A few
features belong to multiple DNA sequences. In that case, however, all
the DNA sequences belong to the same genome. A DNA sequence itself
will frequently have thousands of features connected to it.

It has the following fields:

=over 4

=item ordinal

Sequence number of this segment, starting from 1 and proceeding sequentially forward from there.

=item begin

Index (1-based) of the first residue in the contig that belongs to the segment.

=item len

Length of this segment.

=item dir

Direction (strand) of the segment: "+" if it is forward and "-" if it is backward.


=back
    */

    funcdef get_relationship_IsLocatedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsLocatedIn,
			   fields_Contig>>);
		     
	
    funcdef get_relationship_IsLocusFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Contig,
			   fields_IsLocatedIn,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsMeasurementMethodOf;

    /*
The IsMeasurementMethodOf relationship describes which protocol
was used to take a measurement.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsMeasurementMethodOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Protocol,
			   fields_IsMeasurementMethodOf,
			   fields_Measurement>>);
		     
	
    funcdef get_relationship_WasMeasuredBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Measurement,
			   fields_IsMeasurementMethodOf,
			   fields_Protocol>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsModeledBy;

    /*
A genome can be modeled by many different models, but a model belongs
to only one genome.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsModeledBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_IsModeledBy,
			   fields_Model>>);
		     
	
    funcdef get_relationship_Models(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Model,
			   fields_IsModeledBy,
			   fields_Genome>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string modification_type;
	string modification_value;
    } fields_IsModifiedToBuildAlignment;

    /*
Relates an alignment to other alignments built from it.

It has the following fields:

=over 4

=item modification_type

description of how the alignment was modified

=item modification_value

description of any parameters used to derive the modification


=back
    */

    funcdef get_relationship_IsModifiedToBuildAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Alignment,
			   fields_IsModifiedToBuildAlignment,
			   fields_Alignment>>);
		     
	
    funcdef get_relationship_IsModificationOfAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Alignment,
			   fields_IsModifiedToBuildAlignment,
			   fields_Alignment>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string modification_type;
	string modification_value;
    } fields_IsModifiedToBuildTree;

    /*
Relates a tree to other trees built from it.

It has the following fields:

=over 4

=item modification_type

description of how the tree was modified (rerooted, annotated, etc.)

=item modification_value

description of any parameters used to derive the modification


=back
    */

    funcdef get_relationship_IsModifiedToBuildTree(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Tree,
			   fields_IsModifiedToBuildTree,
			   fields_Tree>>);
		     
	
    funcdef get_relationship_IsModificationOfTree(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Tree,
			   fields_IsModifiedToBuildTree,
			   fields_Tree>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsOwnerOf;

    /*
This relationship connects a genome to the features it
contains. Though technically redundant (the information is
available from the feature's contigs), it simplifies the
extremely common process of finding all features for a
genome.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsOwnerOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_IsOwnerOf,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_IsOwnedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsOwnerOf,
			   fields_Genome>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsParticipatingAt;

    /*
This relationship connects a localized compound to the
location in which it occurs during one or more reactions.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsParticipatingAt(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Location,
			   fields_IsParticipatingAt,
			   fields_LocalizedCompound>>);
		     
	
    funcdef get_relationship_ParticipatesAt(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_LocalizedCompound,
			   fields_IsParticipatingAt,
			   fields_Location>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsProteinFor;

    /*
This relationship connects a peg feature to the protein
sequence it produces (if any). Only peg features participate in this
relationship. A single protein sequence will frequently be produced
by many features.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsProteinFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProteinSequence,
			   fields_IsProteinFor,
			   fields_Feature>>);
		     
	
    funcdef get_relationship_Produces(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsProteinFor,
			   fields_ProteinSequence>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float coefficient;
    } fields_IsReagentIn;

    /*
This relationship connects a compound instance to the reaction instance
in which it is transformed.

It has the following fields:

=over 4

=item coefficient

Number of molecules of the compound that participate in a single instance of the reaction. For example, if a reaction produces two water molecules, the stoichiometry of water for the reaction would be two. When a reaction is written on paper in chemical notation, the stoichiometry is the number next to the chemical formula of the compound. The value is negative for substrates and positive for products.


=back
    */

    funcdef get_relationship_IsReagentIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_CompoundInstance,
			   fields_IsReagentIn,
			   fields_ReactionInstance>>);
		     
	
    funcdef get_relationship_Targets(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ReactionInstance,
			   fields_IsReagentIn,
			   fields_CompoundInstance>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsRealLocationOf;

    /*
This relationship connects a specific instance of a compound in a model
to the specific instance of the model subcellular location where the compound exists.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRealLocationOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_LocationInstance,
			   fields_IsRealLocationOf,
			   fields_CompoundInstance>>);
		     
	
    funcdef get_relationship_HasRealLocationIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_CompoundInstance,
			   fields_IsRealLocationOf,
			   fields_LocationInstance>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsReferencedBy;

    /*
This relationship associates each observational unit with the reference
genome that it will be compared to.  All variations will be differences
between the observational unit and the reference.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsReferencedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_IsReferencedBy,
			   fields_ObservationalUnit>>);
		     
	
    funcdef get_relationship_UsesReference(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ObservationalUnit,
			   fields_IsReferencedBy,
			   fields_Genome>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsRegulatedIn;

    /*
This relationship connects a feature to the set of coregulated features.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRegulatedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsRegulatedIn,
			   fields_CoregulatedSet>>);
		     
	
    funcdef get_relationship_IsRegulatedSetOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_CoregulatedSet,
			   fields_IsRegulatedIn,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsRegulatorFor;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRegulatorFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulator,
			   fields_IsRegulatorFor,
			   fields_Regulog>>);
		     
	
    funcdef get_relationship_HasRegulator(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulog,
			   fields_IsRegulatorFor,
			   fields_Regulator>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsRegulatorForRegulon;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRegulatorForRegulon(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulator,
			   fields_IsRegulatorForRegulon,
			   fields_Regulon>>);
		     
	
    funcdef get_relationship_ReglonHasRegulator(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulon,
			   fields_IsRegulatorForRegulon,
			   fields_Regulator>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsRegulatorySiteFor;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRegulatorySiteFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Feature,
			   fields_IsRegulatorySiteFor,
			   fields_Operon>>);
		     
	
    funcdef get_relationship_HasRegulatorySite(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Operon,
			   fields_IsRegulatorySiteFor,
			   fields_Feature>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsRelevantFor;

    /*
This relationship connects a diagram to the subsystems that are depicted on
it. Only diagrams which are useful in curating or annotation the subsystem are
specified in this relationship.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRelevantFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Diagram,
			   fields_IsRelevantFor,
			   fields_Subsystem>>);
		     
	
    funcdef get_relationship_IsRelevantTo(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Subsystem,
			   fields_IsRelevantFor,
			   fields_Diagram>>);
	

    typedef structure {
        int from_link;
	string to_link;
    } fields_IsRepresentedBy;

    /*
This relationship associates observational units with a genus,
species, strain, and/or variety that was the source material.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRepresentedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_TaxonomicGrouping,
			   fields_IsRepresentedBy,
			   fields_ObservationalUnit>>);
		     
	
    funcdef get_relationship_DefinedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ObservationalUnit,
			   fields_IsRepresentedBy,
			   fields_TaxonomicGrouping>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsRoleOf;

    /*
This relationship connects a role to the machine roles that
represent its appearance in a molecular machine. A machine role has
exactly one associated role, but a role may be represented by many
machine roles.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRoleOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Role,
			   fields_IsRoleOf,
			   fields_SSCell>>);
		     
	
    funcdef get_relationship_HasRole(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SSCell,
			   fields_IsRoleOf,
			   fields_Role>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsRowOf;

    /*
This relationship connects a subsystem spreadsheet row to its
constituent spreadsheet cells.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsRowOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SSRow,
			   fields_IsRowOf,
			   fields_SSCell>>);
		     
	
    funcdef get_relationship_IsRoleFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SSCell,
			   fields_IsRowOf,
			   fields_SSRow>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsSequenceOf;

    /*
This relationship connects a Contig as it occurs in a
genome to the Contig Sequence that represents the physical
DNA base pairs. A contig sequence may represent many contigs,
but each contig has only one sequence.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsSequenceOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ContigSequence,
			   fields_IsSequenceOf,
			   fields_Contig>>);
		     
	
    funcdef get_relationship_HasAsSequence(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Contig,
			   fields_IsSequenceOf,
			   fields_ContigSequence>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsSourceForAssociationDataset;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsSourceForAssociationDataset(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_IsSourceForAssociationDataset,
			   fields_AssociationDataset>>);
		     
	
    funcdef get_relationship_AssociationDatasetSourcedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AssociationDataset,
			   fields_IsSourceForAssociationDataset,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	int to_link;
    } fields_IsSubInstanceOf;

    /*
This relationship connects a scenario to its subsystem it
validates. A scenario belongs to exactly one subsystem, but a
subsystem may have multiple scenarios.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsSubInstanceOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Subsystem,
			   fields_IsSubInstanceOf,
			   fields_Scenario>>);
		     
	
    funcdef get_relationship_Validates(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Scenario,
			   fields_IsSubInstanceOf,
			   fields_Subsystem>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int position;
    } fields_IsSummarizedBy;

    /*
This relationship describes the statistical frequencies of the
most common alleles in various positions on the reference contig.

It has the following fields:

=over 4

=item position

Position in the reference contig where the trait has an impact.


=back
    */

    funcdef get_relationship_IsSummarizedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Contig,
			   fields_IsSummarizedBy,
			   fields_AlleleFrequency>>);
		     
	
    funcdef get_relationship_Summarizes(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_AlleleFrequency,
			   fields_IsSummarizedBy,
			   fields_Contig>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsSuperclassOf;

    /*
This is a recursive relationship that imposes a hierarchy on
the subsystem classes.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsSuperclassOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SubsystemClass,
			   fields_IsSuperclassOf,
			   fields_SubsystemClass>>);
		     
	
    funcdef get_relationship_IsSubclassOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SubsystemClass,
			   fields_IsSuperclassOf,
			   fields_SubsystemClass>>);
	

    typedef structure {
        int from_link;
	string to_link;
    } fields_IsTaxonomyOf;

    /*
A genome is assigned to a particular point in the taxonomy tree, but not
necessarily to a leaf node. In some cases, the exact species and strain is
not available when inserting the genome, so it is placed at the lowest node
that probably contains the actual genome.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsTaxonomyOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_TaxonomicGrouping,
			   fields_IsTaxonomyOf,
			   fields_Genome>>);
		     
	
    funcdef get_relationship_IsInTaxa(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_IsTaxonomyOf,
			   fields_TaxonomicGrouping>>);
	

    typedef structure {
        string from_link;
	int to_link;
	int group_number;
    } fields_IsTerminusFor;

    /*
A terminus for a scenario is a compound that acts as its
input or output. A compound can be the terminus for many scenarios,
and a scenario will have many termini. The relationship attributes
indicate whether the compound is an input to the scenario or an
output. In some cases, there may be multiple alternative output
groups. This is also indicated by the attributes.

It has the following fields:

=over 4

=item group_number

If zero, then the compound is an input. If one, the compound is an output. If two, the compound is an auxiliary output.


=back
    */

    funcdef get_relationship_IsTerminusFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_IsTerminusFor,
			   fields_Scenario>>);
		     
	
    funcdef get_relationship_HasAsTerminus(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Scenario,
			   fields_IsTerminusFor,
			   fields_Compound>>);
	

    typedef structure {
        string from_link;
	string to_link;
	int optional;
	string type;
	int triggering;
    } fields_IsTriggeredBy;

    /*
This connects a complex to the roles that work together to form the complex.

It has the following fields:

=over 4

=item optional

TRUE if the role is not necessarily required to trigger the complex, else FALSE

=item type

a string code that is used to determine whether a complex should be added to a model

=item triggering

TRUE if the presence of the role requires including the complex in the model, else FALSE


=back
    */

    funcdef get_relationship_IsTriggeredBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Complex,
			   fields_IsTriggeredBy,
			   fields_Role>>);
		     
	
    funcdef get_relationship_Triggers(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Role,
			   fields_IsTriggeredBy,
			   fields_Complex>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_IsUsedToBuildTree;

    /*
This relationship connects each tree to the alignment from
which it is built. There is at most one.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_IsUsedToBuildTree(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Alignment,
			   fields_IsUsedToBuildTree,
			   fields_Tree>>);
		     
	
    funcdef get_relationship_IsBuiltFromAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Tree,
			   fields_IsUsedToBuildTree,
			   fields_Alignment>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Manages;

    /*
This relationship connects a model to its associated biomass
composition reactions.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Manages(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Model,
			   fields_Manages,
			   fields_Biomass>>);
		     
	
    funcdef get_relationship_IsManagedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Biomass,
			   fields_Manages,
			   fields_Model>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_OntologyForSample;

    /*
This relationship the ontology PO#, EO# or ENVO# associatioed with the sample.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_OntologyForSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Ontology,
			   fields_OntologyForSample,
			   fields_SampleAnnotation>>);
		     
	
    funcdef get_relationship_SampleHasOntology(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SampleAnnotation,
			   fields_OntologyForSample,
			   fields_Ontology>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_OperatesIn;

    /*
This relationship connects an experiment to the media in which the
experiment took place.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_OperatesIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Experiment,
			   fields_OperatesIn,
			   fields_Media>>);
		     
	
    funcdef get_relationship_IsUtilizedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Media,
			   fields_OperatesIn,
			   fields_Experiment>>);
	

    typedef structure {
        string from_link;
	string to_link;
	float time;
	string timeMeta;
    } fields_OrdersExperimentalUnit;

    /*
Experimental units may be ordered into time series. This
relationship describes which experimenal units belong to
which time series.

It has the following fields:

=over 4

=item time

The time at which the associated ExperimentUnit's data was taken.

=item timeMeta

Denotes that the associated ExperimentalUnit's data measures the time series as a whole - for example, lag and doubling times for bacterial growth curves.


=back
    */

    funcdef get_relationship_OrdersExperimentalUnit(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_TimeSeries,
			   fields_OrdersExperimentalUnit,
			   fields_ExperimentalUnit>>);
		     
	
    funcdef get_relationship_IsTimepointOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentalUnit,
			   fields_OrdersExperimentalUnit,
			   fields_TimeSeries>>);
	

    typedef structure {
        int from_link;
	string to_link;
    } fields_Overlaps;

    /*
A Scenario overlaps a diagram when the diagram displays a
portion of the reactions that make up the scenario. A scenario may
overlap many diagrams, and a diagram may be include portions of many
scenarios.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Overlaps(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Scenario,
			   fields_Overlaps,
			   fields_Diagram>>);
		     
	
    funcdef get_relationship_IncludesPartOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Diagram,
			   fields_Overlaps,
			   fields_Scenario>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_ParticipatesAs;

    /*
This relationship connects a generic compound to a specific compound
where subceullar location has been specified.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_ParticipatesAs(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_ParticipatesAs,
			   fields_LocalizedCompound>>);
		     
	
    funcdef get_relationship_IsParticipationOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_LocalizedCompound,
			   fields_ParticipatesAs,
			   fields_Compound>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string role;
    } fields_PerformedExperiment;

    /*
Denotes that a Person was associated with a
Experiment in some role.

It has the following fields:

=over 4

=item role

Describes the role the person played in the experiment. Examples are Primary Investigator, Designer, Experimentalist, etc.


=back
    */

    funcdef get_relationship_PerformedExperiment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Person,
			   fields_PerformedExperiment,
			   fields_ExperimentMeta>>);
		     
	
    funcdef get_relationship_PerformedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentMeta,
			   fields_PerformedExperiment,
			   fields_Person>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_PersonAnnotatedSample;

    /*
Only stores a person if a person annotates the data by hand.  
Automated Sample Annotations will not be annotated by a person.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_PersonAnnotatedSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Person,
			   fields_PersonAnnotatedSample,
			   fields_SampleAnnotation>>);
		     
	
    funcdef get_relationship_SampleAnnotatedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SampleAnnotation,
			   fields_PersonAnnotatedSample,
			   fields_Person>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_PlatformWithSamples;

    /*
This relationship indicates the expression samples that were run on a particular platform.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_PlatformWithSamples(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Platform,
			   fields_PlatformWithSamples,
			   fields_Sample>>);
		     
	
    funcdef get_relationship_SampleRunOnPlatform(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_PlatformWithSamples,
			   fields_Platform>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_ProducedResultsFor;

    /*
This relationship connects a probe set to a genome for which it was
used to produce experimental results. In general, a probe set is used for
only one genome and vice versa, but this is not a requirement.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_ProducedResultsFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ProbeSet,
			   fields_ProducedResultsFor,
			   fields_Genome>>);
		     
	
    funcdef get_relationship_HadResultsProducedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_ProducedResultsFor,
			   fields_ProbeSet>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_ProtocolForSample;

    /*
This relationship indicates the protocol used in the expression sample.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_ProtocolForSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Protocol,
			   fields_ProtocolForSample,
			   fields_Sample>>);
		     
	
    funcdef get_relationship_SampleUsesProtocol(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_ProtocolForSample,
			   fields_Protocol>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Provided;

    /*
This relationship connects a source (core) database
to the subsystems it submitted to the knowledge base.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Provided(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_Provided,
			   fields_Subsystem>>);
		     
	
    funcdef get_relationship_WasProvidedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Subsystem,
			   fields_Provided,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_PublishedAssociation;

    /*
The PublishedAssociation relationship links associations
to the manuscript they are published in.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_PublishedAssociation(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Publication,
			   fields_PublishedAssociation,
			   fields_Association>>);
		     
	
    funcdef get_relationship_AssociationPublishedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Association,
			   fields_PublishedAssociation,
			   fields_Publication>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_PublishedExperiment;

    /*
The PublishedExperiment relationship describes where a
particular experiment was published.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_PublishedExperiment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Publication,
			   fields_PublishedExperiment,
			   fields_ExperimentMeta>>);
		     
	
    funcdef get_relationship_ExperimentPublishedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ExperimentMeta,
			   fields_PublishedExperiment,
			   fields_Publication>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_PublishedProtocol;

    /*
The ProtocolPublishedIn relationship describes where a
particular protocol was published.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_PublishedProtocol(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Publication,
			   fields_PublishedProtocol,
			   fields_Protocol>>);
		     
	
    funcdef get_relationship_ProtocolPublishedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Protocol,
			   fields_PublishedProtocol,
			   fields_Publication>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_RegulogHasRegulon;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_RegulogHasRegulon(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulog,
			   fields_RegulogHasRegulon,
			   fields_Regulon>>);
		     
	
    funcdef get_relationship_RegulonIsInRegolog(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulon,
			   fields_RegulogHasRegulon,
			   fields_Regulog>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_RegulomeHasGenome;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_RegulomeHasGenome(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulome,
			   fields_RegulomeHasGenome,
			   fields_Genome>>);
		     
	
    funcdef get_relationship_GenomeIsInRegulome(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_RegulomeHasGenome,
			   fields_Regulome>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_RegulomeHasRegulon;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_RegulomeHasRegulon(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulome,
			   fields_RegulomeHasRegulon,
			   fields_Regulon>>);
		     
	
    funcdef get_relationship_RegulonIsInRegolome(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulon,
			   fields_RegulomeHasRegulon,
			   fields_Regulome>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_RegulomeSource;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_RegulomeSource(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulome,
			   fields_RegulomeSource,
			   fields_Source>>);
		     
	
    funcdef get_relationship_CreatedRegulome(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_RegulomeSource,
			   fields_Regulome>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_RegulonHasOperon;

    /*


It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_RegulonHasOperon(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Regulon,
			   fields_RegulonHasOperon,
			   fields_Operon>>);
		     
	
    funcdef get_relationship_OperonIsInRegulon(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Operon,
			   fields_RegulonHasOperon,
			   fields_Regulon>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_SampleAveragedFrom;

    /*
Custom averaging of samples (typically replicates).

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_SampleAveragedFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_SampleAveragedFrom,
			   fields_Sample>>);
		     
	
    funcdef get_relationship_SampleComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_SampleAveragedFrom,
			   fields_Sample>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_SampleContactPerson;

    /*
The people that performed the expression experiment(sample).

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_SampleContactPerson(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_SampleContactPerson,
			   fields_Person>>);
		     
	
    funcdef get_relationship_PersonPerformedSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Person,
			   fields_SampleContactPerson,
			   fields_Sample>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_SampleHasAnnotations;

    /*
This relationship indicates the sample annotations that belong to the sample.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_SampleHasAnnotations(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_SampleHasAnnotations,
			   fields_SampleAnnotation>>);
		     
	
    funcdef get_relationship_AnnotationsForSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SampleAnnotation,
			   fields_SampleHasAnnotations,
			   fields_Sample>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_SampleInSeries;

    /*
This relationship indicates what samples are in a series.  Note a sample can be in more than one series.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_SampleInSeries(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_SampleInSeries,
			   fields_Series>>);
		     
	
    funcdef get_relationship_SeriesWithSamples(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Series,
			   fields_SampleInSeries,
			   fields_Sample>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_SampleMeasurements;

    /*
The Measurements for expression microarray data should be in Log2 space and 
the measurements for a given sample should have the median set to zero.  RNA-Seq data will likely be in FPKM.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_SampleMeasurements(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_SampleMeasurements,
			   fields_Measurement>>);
		     
	
    funcdef get_relationship_MeasurementInSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Measurement,
			   fields_SampleMeasurements,
			   fields_Sample>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_SamplesInReplicateGroup;

    /*
The samples that are identified as being part of one replicate group.  All samples in replicate group are replicates of one another.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_SamplesInReplicateGroup(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_SamplesInReplicateGroup,
			   fields_ReplicateGroup>>);
		     
	
    funcdef get_relationship_ReplicateGroupsForSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_ReplicateGroup,
			   fields_SamplesInReplicateGroup,
			   fields_Sample>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_SeriesPublishedIn;

    /*
This relationship indicates where the series was published.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_SeriesPublishedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Series,
			   fields_SeriesPublishedIn,
			   fields_Publication>>);
		     
	
    funcdef get_relationship_PublicationsForSeries(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Publication,
			   fields_SeriesPublishedIn,
			   fields_Series>>);
	

    typedef structure {
        string from_link;
	string to_link;
	rectangle location;
    } fields_Shows;

    /*
This relationship indicates that a compound appears on a
particular diagram. The same compound can appear on many diagrams,
and a diagram always contains many compounds.

It has the following fields:

=over 4

=item location

Location of the compound's node on the diagram.


=back
    */

    funcdef get_relationship_Shows(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Diagram,
			   fields_Shows,
			   fields_Compound>>);
		     
	
    funcdef get_relationship_IsShownOn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Compound,
			   fields_Shows,
			   fields_Diagram>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_StrainParentOf;

    /*
The recursive StrainParentOf relationship organizes derived
organisms into a tree based on parent/child relationships.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_StrainParentOf(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Strain,
			   fields_StrainParentOf,
			   fields_Strain>>);
		     
	
    funcdef get_relationship_DerivedFromStrain(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Strain,
			   fields_StrainParentOf,
			   fields_Strain>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_StrainWithPlatforms;

    /*
This relationship indicates the platforms for a strain.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_StrainWithPlatforms(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Strain,
			   fields_StrainWithPlatforms,
			   fields_Platform>>);
		     
	
    funcdef get_relationship_PlatformForStrain(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Platform,
			   fields_StrainWithPlatforms,
			   fields_Strain>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_StrainWithSample;

    /*
This indicates which expression samples a strain has.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_StrainWithSample(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Strain,
			   fields_StrainWithSample,
			   fields_Sample>>);
		     
	
    funcdef get_relationship_SampleForStrain(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Sample,
			   fields_StrainWithSample,
			   fields_Strain>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Submitted;

    /*
This relationship connects a genome to the
core database from which it was loaded.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Submitted(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_Submitted,
			   fields_Genome>>);
		     
	
    funcdef get_relationship_WasSubmittedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_Submitted,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string successor_type;
    } fields_SupersedesAlignment;

    /*
This relationship connects an alignment to the alignments
it replaces.

It has the following fields:

=over 4

=item successor_type

Indicates whether sequences were removed or added to create the new alignment.


=back
    */

    funcdef get_relationship_SupersedesAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Alignment,
			   fields_SupersedesAlignment,
			   fields_Alignment>>);
		     
	
    funcdef get_relationship_IsSupersededByAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Alignment,
			   fields_SupersedesAlignment,
			   fields_Alignment>>);
	

    typedef structure {
        string from_link;
	string to_link;
	string successor_type;
    } fields_SupersedesTree;

    /*
This relationship connects a tree to the trees
it replaces.

It has the following fields:

=over 4

=item successor_type

Indicates whether sequences were removed or added to create the new tree.


=back
    */

    funcdef get_relationship_SupersedesTree(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Tree,
			   fields_SupersedesTree,
			   fields_Tree>>);
		     
	
    funcdef get_relationship_IsSupersededByTree(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Tree,
			   fields_SupersedesTree,
			   fields_Tree>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Treed;

    /*
This relationship connects a tree to the source database from
which it was generated.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Treed(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Source,
			   fields_Treed,
			   fields_Tree>>);
		     
	
    funcdef get_relationship_IsTreeFrom(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Tree,
			   fields_Treed,
			   fields_Source>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_UsedIn;

    /*
The UsedIn relationship defines which media is used by an
Environment.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_UsedIn(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Media,
			   fields_UsedIn,
			   fields_Environment>>);
		     
	
    funcdef get_relationship_HasMedia(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Environment,
			   fields_UsedIn,
			   fields_Media>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_Uses;

    /*
This relationship connects a genome to the machines that form
its metabolic pathways. A genome can use many machines, but a
machine is used by exactly one genome.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_Uses(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_Uses,
			   fields_SSRow>>);
		     
	
    funcdef get_relationship_IsUsedBy(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_SSRow,
			   fields_Uses,
			   fields_Genome>>);
	

    typedef structure {
        string from_link;
	string to_link;
    } fields_UsesCodons;

    /*
This relationship connects a genome to the various codon usage
records for it.

It has the following fields:

=over 4


=back
    */

    funcdef get_relationship_UsesCodons(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_Genome,
			   fields_UsesCodons,
			   fields_CodonUsage>>);
		     
	
    funcdef get_relationship_AreCodonsFor(list<string> ids, list<string> from_fields, list<string> rel_fields, list<string> to_fields)
        returns(list<tuple<fields_CodonUsage,
			   fields_UsesCodons,
			   fields_Genome>>);
	



};