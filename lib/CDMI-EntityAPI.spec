module CDMI_API : CDMI_EntityAPI {
typedef string diamond;
typedef string countVector;
typedef string rectangle;

typedef structure {
	string id;
	int n_rows nullable;
	int n_cols nullable;
	string status nullable;
	int is_concatenation nullable;
	string sequence_type nullable;
	string timestamp nullable;
	string method nullable;
	string parameters nullable;
	string protocol nullable;
	string source_id nullable;
} fields_Alignment ;

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

status of the alignment, currently either [i]active[/i],
[i]superseded[/i], or [i]bad[/i]


=item is_concatenation

TRUE if the rows of the alignment map to multiple
sequences, FALSE if they map to single sequences


=item sequence_type

type of sequence being aligned, currently either
[i]Protein[/i], [i]DNA[/i], [i]RNA[/i], or [i]Mixed[/i]


=item timestamp

date and time the alignment was loaded


=item method

name of the primary software package or script used
to construct the alignment


=item parameters

non-default parameters used as input to the software
package or script indicated in the method attribute


=item protocol

description of the steps taken to construct the alignment,
or a reference to an external pipeline


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
} fields_AlignmentAttribute ;

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
	int row_number nullable;
	string row_id nullable;
	string row_description nullable;
	int n_components nullable;
	int beg_pos_aln nullable;
	int end_pos_aln nullable;
	string md5_of_ungapped_sequence nullable;
	string sequence nullable;
} fields_AlignmentRow ;

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

number of components that make up this alignment
row; for a single-sequence alignment this is always "1"


=item beg_pos_aln

the 1-based column index in the alignment where this
sequence row begins


=item end_pos_aln

the 1-based column index in the alignment where this
sequence row ends


=item md5_of_ungapped_sequence

the MD5 of this row's sequence after gaps have been
removed; for DNA and RNA sequences, the [b]U[/b] codes are also
normalized to [b]T[/b] before the MD5 is computed


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
	string source_id nullable;
	int position nullable;
	float minor_AF nullable;
	string minor_allele nullable;
	float major_AF nullable;
	string major_allele nullable;
	int obs_unit_count nullable;
} fields_AlleleFrequency ;

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

Number of observational units used to compute the allele frequencies. Indicates
the quality of the analysis.



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
	string annotator nullable;
	string comment nullable;
	string annotation_time nullable;
} fields_Annotation ;

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
	string source_id nullable;
	string assay_type nullable;
	string assay_type_id nullable;
} fields_Assay ;

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
} fields_AtomicRegulon ;

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
	string description nullable;
} fields_Attribute ;

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
	string mod_date nullable;
	list<string> name nullable;
	float dna nullable;
	float protein nullable;
	float cell_wall nullable;
	float lipid nullable;
	float cofactor nullable;
	float energy nullable;
} fields_Biomass ;

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

portion of a gram of this biomass (expressed as a
fraction of 1.0) that is DNA


=item protein

portion of a gram of this biomass (expressed as a
fraction of 1.0) that is protein


=item cell_wall

portion of a gram of this biomass (expressed as a
fraction of 1.0) that is cell wall


=item lipid

portion of a gram of this biomass (expressed as a
fraction of 1.0) that is lipid but is not part of the cell
wall


=item cofactor

portion of a gram of this biomass (expressed as a
fraction of 1.0) that function as cofactors


=item energy

number of ATP molecules hydrolized per gram of
this biomass



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
	string frequencies nullable;
	int genetic_code nullable;
	string type nullable;
	string subtype nullable;
} fields_CodonUsage ;

/*
This entity contains information about the codon usage
frequency in a particular genome with respect to a particular
type of analysis (e.g. high-expression genes, modal, mean, 
etc.).
It has the following fields:

=over 4


=item frequencies

A packed-string representation of the codon usage
frequencies. These are not global frequencies, but rather
frequenicy of use relative to other codons that produce
the same amino acid.


=item genetic_code

Genetic code used for these codons.


=item type

Type of frequency analysis: average, modal,
high-expression, or non-native.


=item subtype

Specific nature of the codon usage with respect
to the given type, generally indicative of how the
frequencies were computed.



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
	list<string> name nullable;
	string source_id nullable;
	string mod_date nullable;
} fields_Complex ;

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
	string label nullable;
	string abbr nullable;
	string source_id nullable;
	int ubiquitous nullable;
	string mod_date nullable;
	float mass nullable;
	string formula nullable;
	float charge nullable;
	float deltaG nullable;
	float deltaG_error nullable;
} fields_Compound ;

/*
A compound is a chemical that participates in a reaction. Both
ligands and reaction components are treated as compounds.
It has the following fields:

=over 4


=item label

primary name of the compound, for use in displaying
reactions


=item abbr

shortened abbreviation for the compound name


=item source_id

common modeling ID of this compound


=item ubiquitous

TRUE if this compound is found in most reactions, else FALSE


=item mod_date

date and time of the last modification to the
compound definition


=item mass

pH-neutral atomic mass of the compound


=item formula

a pH-neutral formula for the compound


=item charge

computed charge of the compound in a pH-neutral
solution


=item deltaG

the pH 7 reference Gibbs free-energy of formation for this
compound as calculated by the group contribution method (units are
kcal/mol)


=item deltaG_error

the uncertainty in the [b]deltaG[/b] value (units are
kcal/mol)



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
	float charge nullable;
	string formula nullable;
} fields_CompoundInstance ;

/*
A Compound Instance represents the occurrence of a particular
compound in a location in a model.
It has the following fields:

=over 4


=item charge

computed charge based on the location instance pH
and similar constraints


=item formula

computed chemical formula for this compound based
on the location instance pH and similar constraints



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
	string source_id nullable;
} fields_Contig ;

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
	string sequence nullable;
} fields_ContigChunk ;

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
	int length nullable;
} fields_ContigSequence ;

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
	string source_id nullable;
	list<int> binding_location nullable;
} fields_CoregulatedSet ;

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

original ID of this coregulated set in the source (core)
database


=item binding_location

binding location for this set's transcription factor;
there may be none of these or there may be more than one



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
	string name nullable;
	list<string> content nullable;
} fields_Diagram ;

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
	int obsolete nullable;
	string replacedby nullable;
} fields_EcNumber ;

/*
EC numbers are assigned by the Enzyme Commission, and consist
of four numbers separated by periods, each indicating a successively
smaller cateogry of enzymes.
It has the following fields:

=over 4


=item obsolete

This boolean indicates when an EC number is obsolete.


=item replacedby

When an obsolete EC number is replaced with another EC number, this string will
hold the name of the replacement EC number.



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
	float temperature nullable;
	string description nullable;
	int anaerobic nullable;
	float pH nullable;
	string source_id nullable;
} fields_Environment ;

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


=item anaerobic

Whether the environment is anaerobic (True) or aerobic
(False).


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
	string source nullable;
} fields_Experiment ;

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
	string source_id nullable;
} fields_ExperimentalUnit ;

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
	string type nullable;
	string release nullable;
	list<string> family_function nullable;
	list<string> alignment nullable;
} fields_Family ;

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

optional free-form description of the family. For function-based
families, this would be the functional role for the family
members.


=item alignment

FASTA-formatted alignment of the family's protein
sequences



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
	string feature_type nullable;
	string source_id nullable;
	int sequence_length nullable;
	string function nullable;
	list<string> alias nullable;
} fields_Feature ;

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

Code indicating the type of this feature. Among the
codes currently supported are "peg" for a protein encoding
gene, "bs" for a binding site, "opr" for an operon, and so
forth.


=item source_id

ID for this feature in its original source (core)
database


=item sequence_length

Number of base pairs in this feature.


=item function

Functional assignment for this feature. This will
often indicate the feature's functional role or roles, and
may also have comments.


=item alias

alternative identifier for the feature. These are
highly unstructured, and frequently non-unique.



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
	int pegs nullable;
	int rnas nullable;
	string scientific_name nullable;
	int complete nullable;
	int prokaryotic nullable;
	int dna_size nullable;
	int contigs nullable;
	string domain nullable;
	int genetic_code nullable;
	float gc_content nullable;
	list<string> phenotype nullable;
	string md5 nullable;
	string source_id nullable;
} fields_Genome ;

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

Domain for this organism (Archaea, Bacteria, Eukaryota,
Virus, Plasmid, or Environmental Sample).


=item genetic_code

Genetic code number used for protein translation on most
of this genome sequence's contigs.


=item gc_content

Percent GC content present in the genome sequence's
DNA.


=item phenotype

zero or more strings describing phenotypic information
about this genome sequence


=item md5

MD5 identifier describing the genome's DNA sequence


=item source_id

identifier assigned to this genome by the original
source



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
	string source_name nullable;
	string city nullable;
	string state nullable;
	string country nullable;
	string origcty nullable;
	int elevation nullable;
	int latitude nullable;
	int longitude nullable;
	string lo_accession nullable;
} fields_Locality ;

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
} fields_LocalizedCompound ;

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
	string mod_date nullable;
	string name nullable;
	string source_id nullable;
	int hierarchy nullable;
} fields_Location ;

/*
A location is a region of the cell where reaction compounds
originate from or are transported to (e.g. cell wall, extracellular,
cytoplasm).
It has the following fields:

=over 4


=item mod_date

date and time of the last modification to the
compartment's definition


=item name

common name for the location


=item source_id

ID from the source of this location


=item hierarchy

a number indicating where this location occurs
in relation other locations in the cell. Zero indicates
extra-cellular.



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
	int index nullable;
	list<string> label nullable;
	float pH nullable;
	float potential nullable;
} fields_LocationInstance ;

/*
The Location Instance represents a region of a cell
(e.g. cell wall, cytoplasm) as it appears in a specific
model.
It has the following fields:

=over 4


=item index

number used to distinguish between different
instances of the same type of location in a single
model. Within a model, any two instances of the same
location must have difference compartment index
values.


=item label

description used to differentiate between instances
of the same location in a single model


=item pH

pH of the cell region, which is used to determine compound
charge and pH gradient across cell membranes


=item potential

electrochemical potential of the cell region, which is used to
determine the electrochemical gradient across cell membranes



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
	string timeSeries nullable;
	string source_id nullable;
	float value nullable;
	float mean nullable;
	float median nullable;
	float stddev nullable;
	float N nullable;
	float p_value nullable;
	float Z_score nullable;
} fields_Measurement ;

/*
A Measurement is a value generated by performing a protocol to
evaluate a phenotype on an ExperimentalUnit - e.g. a strain in an
environment.
It has the following fields:

=over 4


=item timeSeries

A string containing time series data in the following
format: time1,value1;time2,value2;...timeN,valueN.


=item source_id

The ID of the measurement used by the data source.


=item value

The value of the measurement.


=item mean

The mean of multiple replicates if they are included in the
measurement.


=item median

The median of multiple replicates if they are included in
the measurement.


=item stddev

The standard deviation of multiple replicates if they are
included in the measurement.


=item N

The number of replicates if they are included in the
measurement.


=item p_value

The p-value of multiple replicates if they are included in
the measurement. The exact meaning of the p-value is specified in
the Phenotype object for this measurement.


=item Z_score

The Z-score of multiple replicates if they are included in
the measurement. The exact meaning of the p-value is specified in
the Phenotype object for this measurement.



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
	string mod_date nullable;
	string name nullable;
	int is_minimal nullable;
	string source_id nullable;
	string type nullable;
} fields_Media ;

/*
A media describes the chemical content of the solution in which cells
are grown in an experiment or for the purposes of a model. The key is the
common media name. The nature of the media is described by its relationship
to its constituent compounds.
It has the following fields:

=over 4


=item mod_date

date and time of the last modification to the media's
definition


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
	string mod_date nullable;
	string name nullable;
	int version nullable;
	string type nullable;
	string status nullable;
	int reaction_count nullable;
	int compound_count nullable;
	int annotation_count nullable;
} fields_Model ;

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

string indicating where the model came from
(e.g. single genome, multiple genome, or community model)


=item status

indicator of whether the model is stable, under
construction, or under reconstruction


=item reaction_count

number of reactions in the model


=item compound_count

number of compounds in the model


=item annotation_count

number of features associated with one or more reactions in
the model



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
} fields_OTU ;

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
	string source_name nullable;
	list<string> source_name2 nullable;
	string plant_id nullable;
} fields_ObservationalUnit ;

/*
An ObservationalUnit is an individual plant that 1) is part of an experiment or study, 2) has measured traits, and 3) is assayed for the purpose of determining alleles.  
It has the following fields:

=over 4


=item source_name

Name/ID by which the observational unit may be known by the originator and is used in queries.


=item source_name2

Secondary name/ID by which the observational unit may be known and is queried.


=item plant_id

ID of the plant that was tested to produce this
observational unit. Observational units with the same plant
ID are different assays of a single physical organism.



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
	int score nullable;
} fields_PairSet ;

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

Score for this evidence set. The score indicates the
number of significantly different genomes represented by the
pairings.



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
} fields_Pairing ;

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
	string firstName nullable;
	string lastName nullable;
	string contactEmail nullable;
	string institution nullable;
	string source_id nullable;
} fields_Person ;

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
	string name nullable;
	string description nullable;
	string unitOfMeasure nullable;
	string source_id nullable;
} fields_PhenotypeDescription ;

/*
A Phenotype is a measurable characteristic of an organism.
It has the following fields:

=over 4


=item name

The name of the phenotype.


=item description

The description of the physical phenotype, how it is
measured, and what the measurement statistics mean.


=item unitOfMeasure

The units of the measurement of the phenotype.


=item source_id

The ID of the phenotype description used by the data source.



=back


*/
funcdef get_entity_PhenotypeDescription(list<string> ids, list<string> fields)
	returns(mapping<string, fields_PhenotypeDescription>);
funcdef query_entity_PhenotypeDescription(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_PhenotypeDescription>);
funcdef all_entities_PhenotypeDescription(int start, int count, list<string> fields)
	returns(mapping<string, fields_PhenotypeDescription>);

typedef structure {
	string id;
	string description nullable;
	string source_id nullable;
	string dateUploaded nullable;
	string metadata nullable;
} fields_PhenotypeExperiment ;

/*
A PhenotypeExperiment, consisting of (potentially) multiple
strains, enviroments, and measurements of phenotypic information on
those strains and environments.
It has the following fields:

=over 4


=item description

Design of the experiment including the numbers and types of
experimental units, phenotypes, replicates, sampling plan, and
analyses that are planned.


=item source_id

The ID of the phenotype experiment used by the data source.


=item dateUploaded

The date this experiment was loaded into the database


=item metadata

Any data describing the experiment that is not covered by
the description field.



=back


*/
funcdef get_entity_PhenotypeExperiment(list<string> ids, list<string> fields)
	returns(mapping<string, fields_PhenotypeExperiment>);
funcdef query_entity_PhenotypeExperiment(list<tuple<string, string, string>> qry, list<string> fields)
	returns(mapping<string, fields_PhenotypeExperiment>);
funcdef all_entities_PhenotypeExperiment(int start, int count, list<string> fields)
	returns(mapping<string, fields_PhenotypeExperiment>);

typedef structure {
	string id;
} fields_ProbeSet ;

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
	string sequence nullable;
} fields_ProteinSequence ;

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

The sequence contains the letters corresponding to
the protein's amino acids.



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
	string name nullable;
	string description nullable;
	string source_id nullable;
} fields_Protocol ;

/*
A Protocol is a step by step set of instructions for
performing a part of an experiment.
It has the following fields:

=over 4


=item name

The name of the protocol.


=item description

The step by step instructions for performing the experiment,
including measurement details, materials, and equipment. A
researcher should be able to reproduce the experimental results
with this information.


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
	string title nullable;
	string link nullable;
	string pubdate nullable;
} fields_Publication ;

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
	string mod_date nullable;
	string name nullable;
	string source_id nullable;
	string abbr nullable;
	string direction nullable;
	float deltaG nullable;
	float deltaG_error nullable;
	string thermodynamic_reversibility nullable;
	float default_protons nullable;
	string status nullable;
} fields_Reaction ;

/*
A reaction is a chemical process that converts one set of
compounds (substrate) to another set (products).
It has the following fields:

=over 4


=item mod_date

date and time of the last modification to this reaction's
definition


=item name

descriptive name of this reaction


=item source_id

ID of this reaction in the resource from which it was added


=item abbr

abbreviated name of this reaction


=item direction

direction of this reaction (> for forward-only,
< for backward-only, = for bidirectional)


=item deltaG

Gibbs free-energy change for the reaction calculated using
the group contribution method (units are kcal/mol)


=item deltaG_error

uncertainty in the [b]deltaG[/b] value (units are kcal/mol)


=item thermodynamic_reversibility

computed reversibility of this reaction in a
pH-neutral environment


=item default_protons

number of protons absorbed by this reaction in a
pH-neutral environment


=item status

string indicating additional information about
this reaction, generally indicating whether the reaction
is balanced and/or lumped



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
	string direction nullable;
	float protons nullable;
} fields_ReactionInstance ;

/*
A reaction instance describes the specific implementation of
a reaction in a model.
It has the following fields:

=over 4


=item direction

reaction directionality (> for forward, < for
backward, = for bidirectional) with respect to this model


=item protons

number of protons produced by this reaction when
proceeding in the forward direction. If this is a transport
reaction, these protons end up in the reaction instance's
main location. If the number is negative, then the protons
are consumed by the reaction rather than being produced.



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
	int hypothetical nullable;
} fields_Role ;

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
} fields_SSCell ;

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
	int curated nullable;
	string region nullable;
} fields_SSRow ;

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

This flag is TRUE if the assignment of the molecular
machine has been curated, and FALSE if it was made by an
automated program.


=item region

Region in the genome for which the row is relevant.
Normally, this is an empty string, indicating that the machine
covers the whole genome. If a subsystem has multiple rows
for a genome, this contains a location string describing the
region occupied by this particular row.



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
	string common_name nullable;
} fields_Scenario ;

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

Common name of the scenario. The name, rather than the ID
number, is usually displayed everywhere.



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
} fields_Source ;

/*
A source is a user or organization that is permitted to
assign its own identifiers or to submit bioinformatic objects
to the database.
It has the following fields:

=over 4



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
	string description nullable;
	string source_id nullable;
	int aggregateData nullable;
} fields_Strain ;

/*
This entity represents an organism derived from a genome or
another organism with one or more modifications to the organism's
genome.
It has the following fields:

=over 4


=item description

A description of the strain, e.g. knockout/modification
methods, resulting phenotypes, etc.


=item source_id

The ID of the strain used by the data source.


=item aggregateData

Denotes whether this entity represents a physical strain
(False) or aggregate data calculated from one or more strains
(True).



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
	string source_name nullable;
	string design nullable;
	string originator nullable;
} fields_StudyExperiment ;

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
	int version nullable;
	string curator nullable;
	string notes nullable;
	string description nullable;
	int usable nullable;
	int private nullable;
	int cluster_based nullable;
	int experimental nullable;
} fields_Subsystem ;

/*
A subsystem is a set of functional roles that have been annotated simultaneously (e.g.,
the roles present in a specific pathway), with an associated subsystem spreadsheet
which encodes the fids in each genome that implement the functional roles in the
subsystem.
It has the following fields:

=over 4


=item version

version number for the subsystem. This value is
incremented each time the subsystem is backed up.


=item curator

name of the person currently in charge of the
subsystem


=item notes

descriptive notes about the subsystem


=item description

description of the subsystem's function in the
cell


=item usable

TRUE if this is a usable subsystem, else FALSE. An
unusable subsystem is one that is experimental or is of
such low quality that it can negatively affect analysis.


=item private

TRUE if this is a private subsystem, else FALSE. A
private subsystem has valid data, but is not considered ready
for general distribution.


=item cluster_based

TRUE if this is a clustering-based subsystem, else
FALSE. A clustering-based subsystem is one in which there is
functional-coupling evidence that genes belong together, but
we do not yet know what they do.


=item experimental

TRUE if this is an experimental subsystem, else FALSE.
An experimental subsystem is designed for investigation and
is not yet ready to be used in comparative analysis and
annotation.



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
} fields_SubsystemClass ;

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
	int domain nullable;
	int hidden nullable;
	string scientific_name nullable;
	list<string> alias nullable;
} fields_TaxonomicGrouping ;

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

TRUE if this is a hidden grouping, else FALSE. Hidden groupings
are not typically shown in a lineage list.


=item scientific_name

Primary scientific name for this grouping. This is the name used
when displaying a taxonomy.


=item alias

Alternate name for this grouping. A grouping
may have many alternate names. The scientific name should also
be in this list.



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
	string trait_name nullable;
	string unit_of_measure nullable;
	string TO_ID nullable;
	string protocol nullable;
} fields_Trait ;

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
	string status nullable;
	string data_type nullable;
	string timestamp nullable;
	string method nullable;
	string parameters nullable;
	string protocol nullable;
	string source_id nullable;
	string newick nullable;
} fields_Tree ;

/*
A tree describes how the sequences in an alignment relate
to each other. Most trees are phylogenetic, but some may be based on
taxonomy or gene content.
It has the following fields:

=over 4


=item status

status of the tree, currently either [i]active[/i],
[i]superseded[/i], or [i]bad[/i]


=item data_type

type of data the tree was built from, usually
[i]sequence_alignment[/i]


=item timestamp

date and time the tree was loaded


=item method

name of the primary software package or script used
to construct the tree


=item parameters

non-default parameters used as input to the software
package or script indicated in the method attribute


=item protocol

description of the steps taken to construct the tree,
or a reference to an external pipeline


=item source_id

ID of this tree in the source database


=item newick

NEWICK format string containing the structure
of the tree



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
} fields_TreeAttribute ;

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
} fields_TreeNodeAttribute ;

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
	list<string> role_rule nullable;
	string code nullable;
	string type nullable;
	string comment nullable;
} fields_Variant ;

/*
Each subsystem may include the designation of distinct
variants.  Thus, there may be three closely-related, but
distinguishable forms of histidine degradation.  Each form
would be called a "variant", with an associated code, and all
genomes implementing a specific variant can easily be accessed.
It has the following fields:

=over 4


=item role_rule

a space-delimited list of role IDs, in alphabetical order,
that represents a possible list of non-auxiliary roles applicable to
this variant. The roles are identified by their abbreviations. A
variant may have multiple role rules.


=item code

the variant code all by itself


=item type

variant type indicating the quality of the subsystem
support. A type of "vacant" means that the subsystem
does not appear to be implemented by the variant. A
type of "incomplete" means that the subsystem appears to be
missing many reactions. In all other cases, the type is
"normal".


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
	string id;
	int level nullable;
} fields_AffectsLevelOf ;

/*
This relationship indicates the expression level of an atomic regulon
for a given experiment.
It has the following fields:

=over 4


=item level

Indication of whether the feature is expressed (1), not expressed (-1),
or unknown (0).



=back


*/
funcdef get_relationship_AffectsLevelOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Experiment, fields_AffectsLevelOf, fields_AtomicRegulon>>);
funcdef get_relationship_IsAffectedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AtomicRegulon, fields_AffectsLevelOf, fields_Experiment>>);

typedef structure {
	string id;
} fields_Aligned ;

/*
This relationship connects an alignment to the database
from which it was generated.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Aligned(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_Aligned, fields_Alignment>>);
funcdef get_relationship_WasAlignedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Alignment, fields_Aligned, fields_Source>>);

typedef structure {
	string id;
	string function nullable;
	string external_id nullable;
	string organism nullable;
	int gi_number nullable;
	string release_date nullable;
} fields_AssertsFunctionFor ;

/*
Sources (users) can make assertions about protein sequence function.
The assertion is associated with an external identifier.
It has the following fields:

=over 4


=item function

text of the assertion made about the identifier.
It may be an empty string, indicating the function is unknown.


=item external_id

external identifier used in making the assertion


=item organism

organism name associated with this assertion. If the
assertion is not associated with a specific organism, this
will be an empty string.


=item gi_number

NCBI GI number associated with the asserted identifier


=item release_date

date and time the assertion was downloaded



=back


*/
funcdef get_relationship_AssertsFunctionFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_AssertsFunctionFor, fields_ProteinSequence>>);
funcdef get_relationship_HasAssertedFunctionFrom(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_AssertsFunctionFor, fields_Source>>);

typedef structure {
	string id;
} fields_BelongsTo ;

/*
The BelongsTo relationship specifies the experimental
units performed on a particular strain.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_BelongsTo(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Strain, fields_BelongsTo, fields_ExperimentalUnit>>);
funcdef get_relationship_IncludesStrain(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ExperimentalUnit, fields_BelongsTo, fields_Strain>>);

typedef structure {
	string id;
} fields_Concerns ;

/*
This relationship connects a publication to the protein
sequences it describes.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Concerns(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Publication, fields_Concerns, fields_ProteinSequence>>);
funcdef get_relationship_IsATopicOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_Concerns, fields_Publication>>);

typedef structure {
	string id;
	float molar_ratio nullable;
} fields_ConsistsOfCompounds ;

/*
This relationship defines the subcompounds that make up a
compound. For example, CoCl2-6H2O is made up of 1 Co2+, 2 Cl-, and
6 H2O.
It has the following fields:

=over 4


=item molar_ratio

Number of molecules of the subcompound that make up
the compound. A -1 in this field signifies that although
the subcompound is present in the compound, the molar
ratio is unknown.



=back


*/
funcdef get_relationship_ConsistsOfCompounds(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_ConsistsOfCompounds, fields_Compound>>);
funcdef get_relationship_ComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_ConsistsOfCompounds, fields_Compound>>);

typedef structure {
	string id;
} fields_Contains ;

/*
This relationship connects a subsystem spreadsheet cell to the features
that occur in it. A feature may occur in many machine roles and a
machine role may contain many features. The subsystem annotation
process is essentially the maintenance of this relationship.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Contains(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SSCell, fields_Contains, fields_Feature>>);
funcdef get_relationship_IsContainedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_Contains, fields_SSCell>>);

typedef structure {
	string id;
	int index_in_concatenation nullable;
	int beg_pos_in_parent nullable;
	int end_pos_in_parent nullable;
	int parent_seq_len nullable;
	int beg_pos_aln nullable;
	int end_pos_aln nullable;
	string kb_feature_id nullable;
} fields_ContainsAlignedDNA ;

/*
This relationship connects a nucleotide alignment row to the
contig sequences from which its components are formed.
It has the following fields:

=over 4


=item index_in_concatenation

1-based ordinal position in the alignment row of this
nucleotide sequence


=item beg_pos_in_parent

1-based position in the contig sequence of the first
nucleotide that appears in the alignment


=item end_pos_in_parent

1-based position in the contig sequence of the last
nucleotide that appears in the alignment


=item parent_seq_len

length of original sequence


=item beg_pos_aln

the 1-based column index in the alignment where this
nucleotide sequence begins


=item end_pos_aln

the 1-based column index in the alignment where this
nucleotide sequence ends


=item kb_feature_id

ID of the feature relevant to this sequence, or an
empty string if the sequence is not specific to a genome



=back


*/
funcdef get_relationship_ContainsAlignedDNA(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AlignmentRow, fields_ContainsAlignedDNA, fields_ContigSequence>>);
funcdef get_relationship_IsAlignedDNAComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ContigSequence, fields_ContainsAlignedDNA, fields_AlignmentRow>>);

typedef structure {
	string id;
	int index_in_concatenation nullable;
	int beg_pos_in_parent nullable;
	int end_pos_in_parent nullable;
	int parent_seq_len nullable;
	int beg_pos_aln nullable;
	int end_pos_aln nullable;
	string kb_feature_id nullable;
} fields_ContainsAlignedProtein ;

/*
This relationship connects a protein alignment row to the
protein sequences from which its components are formed.
It has the following fields:

=over 4


=item index_in_concatenation

1-based ordinal position in the alignment row of this
protein sequence


=item beg_pos_in_parent

1-based position in the protein sequence of the first
amino acid that appears in the alignment


=item end_pos_in_parent

1-based position in the protein sequence of the last
amino acid that appears in the alignment


=item parent_seq_len

length of original sequence


=item beg_pos_aln

the 1-based column index in the alignment where this
protein sequence begins


=item end_pos_aln

the 1-based column index in the alignment where this
protein sequence ends


=item kb_feature_id

ID of the feature relevant to this protein, or an
empty string if the protein is not specific to a genome



=back


*/
funcdef get_relationship_ContainsAlignedProtein(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AlignmentRow, fields_ContainsAlignedProtein, fields_ProteinSequence>>);
funcdef get_relationship_IsAlignedProteinComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_ContainsAlignedProtein, fields_AlignmentRow>>);

typedef structure {
	string id;
} fields_Controls ;

/*
This relationship connects a coregulated set to the
features that are used as its transcription factors.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Controls(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_Controls, fields_CoregulatedSet>>);
funcdef get_relationship_IsControlledUsing(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CoregulatedSet, fields_Controls, fields_Feature>>);

typedef structure {
	string id;
} fields_DerivedFromStrain ;

/*
The recursive DerivedFromStrain relationship organizes derived
organisms into a tree based on parent/child relationships.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_DerivedFromStrain(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Strain, fields_DerivedFromStrain, fields_Strain>>);
funcdef get_relationship_StrainParentOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Strain, fields_DerivedFromStrain, fields_Strain>>);

typedef structure {
	string id;
} fields_Describes ;

/*
This relationship connects a subsystem to the individual
variants used to implement it. Each variant contains a slightly
different subset of the roles in the parent subsystem.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Describes(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Subsystem, fields_Describes, fields_Variant>>);
funcdef get_relationship_IsDescribedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Variant, fields_Describes, fields_Subsystem>>);

typedef structure {
	string id;
	string value nullable;
} fields_DescribesAlignment ;

/*
This relationship connects an alignment to its free-form
attributes.
It has the following fields:

=over 4


=item value

value of this attribute



=back


*/
funcdef get_relationship_DescribesAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AlignmentAttribute, fields_DescribesAlignment, fields_Alignment>>);
funcdef get_relationship_HasAlignmentAttribute(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Alignment, fields_DescribesAlignment, fields_AlignmentAttribute>>);

typedef structure {
	string id;
	string value nullable;
} fields_DescribesTree ;

/*
This relationship connects a tree to its free-form
attributes.
It has the following fields:

=over 4


=item value

value of this attribute



=back


*/
funcdef get_relationship_DescribesTree(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_TreeAttribute, fields_DescribesTree, fields_Tree>>);
funcdef get_relationship_HasTreeAttribute(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Tree, fields_DescribesTree, fields_TreeAttribute>>);

typedef structure {
	string id;
	string value nullable;
	string node_id nullable;
} fields_DescribesTreeNode ;

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
funcdef get_relationship_DescribesTreeNode(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_TreeNodeAttribute, fields_DescribesTreeNode, fields_Tree>>);
funcdef get_relationship_HasNodeAttribute(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Tree, fields_DescribesTreeNode, fields_TreeNodeAttribute>>);

typedef structure {
	string id;
	rectangle location nullable;
} fields_Displays ;

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
funcdef get_relationship_Displays(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Diagram, fields_Displays, fields_Reaction>>);
funcdef get_relationship_IsDisplayedOn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_Displays, fields_Diagram>>);

typedef structure {
	string id;
} fields_Encompasses ;

/*
This relationship connects a feature to a related
feature; for example, it would connect a gene to its
constituent splice variants, and the splice variants to their
exons.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Encompasses(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_Encompasses, fields_Feature>>);
funcdef get_relationship_IsEncompassedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_Encompasses, fields_Feature>>);

typedef structure {
	string id;
} fields_Formulated ;

/*
This relationship connects a coregulated set to the
source organization that originally computed it.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Formulated(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_Formulated, fields_CoregulatedSet>>);
funcdef get_relationship_WasFormulatedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CoregulatedSet, fields_Formulated, fields_Source>>);

typedef structure {
	string id;
	countVector level_vector nullable;
} fields_GeneratedLevelsFor ;

/*
This relationship connects an atomic regulon to a probe set from which experimental
data was produced for its features. It contains a vector of the expression levels.
It has the following fields:

=over 4


=item level_vector

Vector of expression levels (-1, 0, 1) for the experiments, in
sequence order.



=back


*/
funcdef get_relationship_GeneratedLevelsFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProbeSet, fields_GeneratedLevelsFor, fields_AtomicRegulon>>);
funcdef get_relationship_WasGeneratedFrom(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AtomicRegulon, fields_GeneratedLevelsFor, fields_ProbeSet>>);

typedef structure {
	string id;
} fields_GenomeParentOf ;

/*
The DerivedFromGenome relationship specifies the direct child
strains of a specific genome.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_GenomeParentOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_GenomeParentOf, fields_Strain>>);
funcdef get_relationship_DerivedFromGenome(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Strain, fields_GenomeParentOf, fields_Genome>>);

typedef structure {
	string id;
} fields_HasAssociatedMeasurement ;

/*
The HasAssociatedMeasurement relationship specifies a measurement that
measures a phenotype.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasAssociatedMeasurement(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_PhenotypeDescription, fields_HasAssociatedMeasurement, fields_Measurement>>);
funcdef get_relationship_MeasuresPhenotype(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Measurement, fields_HasAssociatedMeasurement, fields_PhenotypeDescription>>);

typedef structure {
	string id;
	string alias nullable;
} fields_HasCompoundAliasFrom ;

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
funcdef get_relationship_HasCompoundAliasFrom(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_HasCompoundAliasFrom, fields_Compound>>);
funcdef get_relationship_UsesAliasForCompound(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_HasCompoundAliasFrom, fields_Source>>);

typedef structure {
	string id;
} fields_HasExperimentalUnit ;

/*
The HasExperimentalUnit relationship describes which
ExperimentalUnits are part of a PhenotypeExperiment.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasExperimentalUnit(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_PhenotypeExperiment, fields_HasExperimentalUnit, fields_ExperimentalUnit>>);
funcdef get_relationship_IsExperimentalUnitOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ExperimentalUnit, fields_HasExperimentalUnit, fields_PhenotypeExperiment>>);

typedef structure {
	string id;
	float rma_value nullable;
	int level nullable;
} fields_HasIndicatedSignalFrom ;

/*
This relationship connects an experiment to a feature. The feature
expression levels inferred from the experimental results are stored here.
It has the following fields:

=over 4


=item rma_value

Normalized expression value for this feature under the experiment's
conditions.


=item level

Indication of whether the feature is expressed (1), not expressed (-1),
or unknown (0).



=back


*/
funcdef get_relationship_HasIndicatedSignalFrom(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_HasIndicatedSignalFrom, fields_Experiment>>);
funcdef get_relationship_IndicatesSignalFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Experiment, fields_HasIndicatedSignalFrom, fields_Feature>>);

typedef structure {
	string id;
} fields_HasKnockoutIn ;

/*
The HasKnockoutIn relationship specifies the gene knockouts in
a particular strain.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasKnockoutIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Strain, fields_HasKnockoutIn, fields_Feature>>);
funcdef get_relationship_KnockedOutIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_HasKnockoutIn, fields_Strain>>);

typedef structure {
	string id;
} fields_HasMeasurement ;

/*
The HasMeasurement relationship specifies a measurement
performed on a particular experimental unit.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasMeasurement(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ExperimentalUnit, fields_HasMeasurement, fields_Measurement>>);
funcdef get_relationship_IsMeasureOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Measurement, fields_HasMeasurement, fields_ExperimentalUnit>>);

typedef structure {
	string id;
} fields_HasMember ;

/*
This relationship connects each feature family to its
constituent features. A family always has many features, and a
single feature can be found in many families.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasMember(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Family, fields_HasMember, fields_Feature>>);
funcdef get_relationship_IsMemberOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_HasMember, fields_Family>>);

typedef structure {
	string id;
	int type nullable;
} fields_HasParticipant ;

/*
A scenario consists of many participant reactions that
convert the input compounds to output compounds. A single reaction
may participate in many scenarios.
It has the following fields:

=over 4


=item type

Indicates the type of participaton. If 0, the
reaction is in the main pathway of the scenario. If 1, the
reaction is necessary to make the model work but is not in
the subsystem. If 2, the reaction is part of the subsystem
but should not be included in the modelling process.



=back


*/
funcdef get_relationship_HasParticipant(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Scenario, fields_HasParticipant, fields_Reaction>>);
funcdef get_relationship_ParticipatesIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_HasParticipant, fields_Scenario>>);

typedef structure {
	string id;
	float concentration nullable;
	float maximum_flux nullable;
	float minimum_flux nullable;
} fields_HasPresenceOf ;

/*
This relationship connects a media to the compounds that
occur in it. The intersection data describes how much of each
compound can be found.
It has the following fields:

=over 4


=item concentration

concentration of the compound in the media


=item maximum_flux

maximum allowed increase in this compound


=item minimum_flux

maximum allowed decrease in this compound



=back


*/
funcdef get_relationship_HasPresenceOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Media, fields_HasPresenceOf, fields_Compound>>);
funcdef get_relationship_IsPresentIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_HasPresenceOf, fields_Media>>);

typedef structure {
	string id;
	string source_id nullable;
} fields_HasProteinMember ;

/*
This relationship connects each feature family to its
constituent protein sequences. A family always has many protein sequences,
and a single sequence can be found in many families.
It has the following fields:

=over 4


=item source_id

Native identifier used for the protein in the definition
of the family. This will be its ID in the alignment, if one
exists.



=back


*/
funcdef get_relationship_HasProteinMember(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Family, fields_HasProteinMember, fields_ProteinSequence>>);
funcdef get_relationship_IsProteinMemberOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_HasProteinMember, fields_Family>>);

typedef structure {
	string id;
	string alias nullable;
} fields_HasReactionAliasFrom ;

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
funcdef get_relationship_HasReactionAliasFrom(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_HasReactionAliasFrom, fields_Reaction>>);
funcdef get_relationship_UsesAliasForReaction(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_HasReactionAliasFrom, fields_Source>>);

typedef structure {
	string id;
} fields_HasRepresentativeOf ;

/*
This relationship connects a genome to the FIGfam protein families
for which it has representative proteins. This information can be computed
from other relationships, but it is provided explicitly to allow fast access
to a genome's FIGfam profile.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasRepresentativeOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_HasRepresentativeOf, fields_Family>>);
funcdef get_relationship_IsRepresentedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Family, fields_HasRepresentativeOf, fields_Genome>>);

typedef structure {
	string id;
} fields_HasRequirementOf ;

/*
This relationship connects a model to the instances of
reactions that represent how the reactions occur in the model.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasRequirementOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Model, fields_HasRequirementOf, fields_ReactionInstance>>);
funcdef get_relationship_IsARequirementOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ReactionInstance, fields_HasRequirementOf, fields_Model>>);

typedef structure {
	string id;
	int sequence nullable;
} fields_HasResultsIn ;

/*
This relationship connects a probe set to the experiments that were
applied to it.
It has the following fields:

=over 4


=item sequence

Sequence number of this experiment in the various result vectors.



=back


*/
funcdef get_relationship_HasResultsIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProbeSet, fields_HasResultsIn, fields_Experiment>>);
funcdef get_relationship_HasResultsFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Experiment, fields_HasResultsIn, fields_ProbeSet>>);

typedef structure {
	string id;
} fields_HasSection ;

/*
This relationship connects a contig's sequence to its DNA
sequences.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasSection(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ContigSequence, fields_HasSection, fields_ContigChunk>>);
funcdef get_relationship_IsSectionOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ContigChunk, fields_HasSection, fields_ContigSequence>>);

typedef structure {
	string id;
} fields_HasStep ;

/*
This relationship connects a complex to the reactions it
catalyzes.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasStep(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Complex, fields_HasStep, fields_Reaction>>);
funcdef get_relationship_IsStepOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_HasStep, fields_Complex>>);

typedef structure {
	string id;
	float value nullable;
	string statistic_type nullable;
	string measure_id nullable;
} fields_HasTrait ;

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
funcdef get_relationship_HasTrait(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ObservationalUnit, fields_HasTrait, fields_Trait>>);
funcdef get_relationship_Measures(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Trait, fields_HasTrait, fields_ObservationalUnit>>);

typedef structure {
	string id;
} fields_HasUnits ;

/*
This relationship associates observational units with the
geographic location where the unit is planted.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasUnits(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Locality, fields_HasUnits, fields_ObservationalUnit>>);
funcdef get_relationship_IsLocated(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ObservationalUnit, fields_HasUnits, fields_Locality>>);

typedef structure {
	string id;
} fields_HasUsage ;

/*
This relationship connects a specific compound in a model to the localized
compound to which it corresponds.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasUsage(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_LocalizedCompound, fields_HasUsage, fields_CompoundInstance>>);
funcdef get_relationship_IsUsageOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CompoundInstance, fields_HasUsage, fields_LocalizedCompound>>);

typedef structure {
	string id;
	string value nullable;
} fields_HasValueFor ;

/*
This relationship connects an experiment to its attributes. The attribute
values are stored here.
It has the following fields:

=over 4


=item value

Value of this attribute in the given experiment. This is always encoded
as a string, but may in fact be a number.



=back


*/
funcdef get_relationship_HasValueFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Experiment, fields_HasValueFor, fields_Attribute>>);
funcdef get_relationship_HasValueIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Attribute, fields_HasValueFor, fields_Experiment>>);

typedef structure {
	string id;
	int position nullable;
	int len nullable;
	string data nullable;
	string data2 nullable;
	float quality nullable;
} fields_HasVariationIn ;

/*
This relationship defines an observational unit's DNA variation
from a contig in the reference genome.
It has the following fields:

=over 4


=item position

Position of this variation in the reference contig.


=item len

Length of the variation in the reference contig. A length
of zero indicates an insertion.


=item data

Replacement DNA for the variation on the primary chromosome. An
empty string indicates a deletion. The primary chromosome is chosen
arbitrarily among the two chromosomes of a plant's chromosome pair
(one coming from the mother and one from the father).


=item data2

Replacement DNA for the variation on the secondary chromosome.
This will frequently be the same as the primary chromosome string.


=item quality

Quality score assigned to this variation.



=back


*/
funcdef get_relationship_HasVariationIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Contig, fields_HasVariationIn, fields_ObservationalUnit>>);
funcdef get_relationship_IsVariedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ObservationalUnit, fields_HasVariationIn, fields_Contig>>);

typedef structure {
	string id;
	string source_name nullable;
	int rank nullable;
	float pvalue nullable;
	int position nullable;
} fields_Impacts ;

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

Position in the reference contig where the trait
has an impact.



=back


*/
funcdef get_relationship_Impacts(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Trait, fields_Impacts, fields_Contig>>);
funcdef get_relationship_IsImpactedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Contig, fields_Impacts, fields_Trait>>);

typedef structure {
	string id;
	int sequence nullable;
	string abbreviation nullable;
	int auxiliary nullable;
} fields_Includes ;

/*
A subsystem is defined by its roles. The subsystem's variants
contain slightly different sets of roles, but all of the roles in a
variant must be connected to the parent subsystem by this
relationship. A subsystem always has at least one role, and a role
always belongs to at least one subsystem.
It has the following fields:

=over 4


=item sequence

Sequence number of the role within the subsystem.
When the roles are formed into a variant, they will
generally appear in sequence order.


=item abbreviation

Abbreviation for this role in this subsystem. The
abbreviations are used in columnar displays, and they also
appear on diagrams.


=item auxiliary

TRUE if this is an auxiliary role, or FALSE if this role
is a functioning part of the subsystem.



=back


*/
funcdef get_relationship_Includes(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Subsystem, fields_Includes, fields_Role>>);
funcdef get_relationship_IsIncludedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Role, fields_Includes, fields_Subsystem>>);

typedef structure {
	string id;
	float concentration nullable;
	string units nullable;
} fields_IncludesAdditionalCompounds ;

/*
This relationship connects a environment to the compounds that
occur in it. The intersection data describes how much of each
compound can be found.
It has the following fields:

=over 4


=item concentration

concentration of the compound in the environment


=item units

vol%, g/L, or molar (mol/L).



=back


*/
funcdef get_relationship_IncludesAdditionalCompounds(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Environment, fields_IncludesAdditionalCompounds, fields_Compound>>);
funcdef get_relationship_IncludedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_IncludesAdditionalCompounds, fields_Environment>>);

typedef structure {
	string id;
} fields_IncludesAlignmentRow ;

/*
This relationship connects an alignment to its component
rows.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IncludesAlignmentRow(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Alignment, fields_IncludesAlignmentRow, fields_AlignmentRow>>);
funcdef get_relationship_IsAlignmentRowIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AlignmentRow, fields_IncludesAlignmentRow, fields_Alignment>>);

typedef structure {
	string id;
} fields_IncludesPart ;

/*
This relationship associates observational units with the
experiments that generated the data on them.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IncludesPart(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_StudyExperiment, fields_IncludesPart, fields_ObservationalUnit>>);
funcdef get_relationship_IsPartOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ObservationalUnit, fields_IncludesPart, fields_StudyExperiment>>);

typedef structure {
	string id;
	countVector level_vector nullable;
} fields_IndicatedLevelsFor ;

/*
This relationship connects a feature to a probe set from which experimental
data was produced for the feature. It contains a vector of the expression levels.
It has the following fields:

=over 4


=item level_vector

Vector of expression levels (-1, 0, 1) for the experiments, in
sequence order.



=back


*/
funcdef get_relationship_IndicatedLevelsFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProbeSet, fields_IndicatedLevelsFor, fields_Feature>>);
funcdef get_relationship_HasLevelsFrom(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IndicatedLevelsFor, fields_ProbeSet>>);

typedef structure {
	string id;
	float coefficient nullable;
	int cofactor nullable;
} fields_Involves ;

/*
This relationship connects a reaction to the
specific localized compounds that participate in it.
It has the following fields:

=over 4


=item coefficient

Number of molecules of the compound that participate
in a single instance of the reaction. For example, if a
reaction produces two water molecules, the stoichiometry of
water for the reaction would be two. When a reaction is
written on paper in chemical notation, the stoichiometry is
the number next to the chemical formula of the
compound. The value is negative for substrates and positive
for products.


=item cofactor

TRUE if the compound is a cofactor; FALSE if it is a major
component of the reaction.



=back


*/
funcdef get_relationship_Involves(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_Involves, fields_LocalizedCompound>>);
funcdef get_relationship_IsInvolvedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_LocalizedCompound, fields_Involves, fields_Reaction>>);

typedef structure {
	string id;
} fields_IsAnnotatedBy ;

/*
This relationship connects a feature to its annotations. A
feature may have multiple annotations, but an annotation belongs to
only one feature.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsAnnotatedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsAnnotatedBy, fields_Annotation>>);
funcdef get_relationship_Annotates(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Annotation, fields_IsAnnotatedBy, fields_Feature>>);

typedef structure {
	string id;
} fields_IsAssayOf ;

/*
This relationship associates each assay with the relevant
experiments.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsAssayOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Assay, fields_IsAssayOf, fields_StudyExperiment>>);
funcdef get_relationship_IsAssayedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_StudyExperiment, fields_IsAssayOf, fields_Assay>>);

typedef structure {
	string id;
} fields_IsClassFor ;

/*
This relationship connects each subsystem class with the
subsystems that belong to it. A class can contain many subsystems,
but a subsystem is only in one class. Some subsystems are not in any
class, but this is usually a temporary condition.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsClassFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SubsystemClass, fields_IsClassFor, fields_Subsystem>>);
funcdef get_relationship_IsInClass(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Subsystem, fields_IsClassFor, fields_SubsystemClass>>);

typedef structure {
	string id;
	int representative nullable;
} fields_IsCollectionOf ;

/*
A genome belongs to only one genome set. For each set, this relationship marks the genome to be used as its representative.
It has the following fields:

=over 4


=item representative

TRUE for the representative genome of the set, else FALSE.



=back


*/
funcdef get_relationship_IsCollectionOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_OTU, fields_IsCollectionOf, fields_Genome>>);
funcdef get_relationship_IsCollectedInto(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_IsCollectionOf, fields_OTU>>);

typedef structure {
	string id;
} fields_IsComposedOf ;

/*
This relationship connects a genome to its
constituent contigs. Unlike contig sequences, a
contig belongs to only one genome.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsComposedOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_IsComposedOf, fields_Contig>>);
funcdef get_relationship_IsComponentOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Contig, fields_IsComposedOf, fields_Genome>>);

typedef structure {
	string id;
	float coefficient nullable;
} fields_IsComprisedOf ;

/*
This relationship connects a biomass composition reaction to the
compounds specified as contained in the biomass.
It has the following fields:

=over 4


=item coefficient

number of millimoles of the compound instance that exists in one
gram cell dry weight of biomass



=back


*/
funcdef get_relationship_IsComprisedOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Biomass, fields_IsComprisedOf, fields_CompoundInstance>>);
funcdef get_relationship_Comprises(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CompoundInstance, fields_IsComprisedOf, fields_Biomass>>);

typedef structure {
	string id;
} fields_IsConfiguredBy ;

/*
This relationship connects a genome to the atomic regulons that
describe its state.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsConfiguredBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_IsConfiguredBy, fields_AtomicRegulon>>);
funcdef get_relationship_ReflectsStateOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AtomicRegulon, fields_IsConfiguredBy, fields_Genome>>);

typedef structure {
	string id;
} fields_IsConsistentWith ;

/*
This relationship connects a functional role to the EC numbers consistent
with the chemistry described in the role.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsConsistentWith(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_EcNumber, fields_IsConsistentWith, fields_Role>>);
funcdef get_relationship_IsConsistentTo(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Role, fields_IsConsistentWith, fields_EcNumber>>);

typedef structure {
	string id;
	float coefficient nullable;
} fields_IsCoregulatedWith ;

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
funcdef get_relationship_IsCoregulatedWith(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsCoregulatedWith, fields_Feature>>);
funcdef get_relationship_HasCoregulationWith(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsCoregulatedWith, fields_Feature>>);

typedef structure {
	string id;
	int co_occurrence_evidence nullable;
	int co_expression_evidence nullable;
} fields_IsCoupledTo ;

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

number of times members of the two FIGfams occur close to each
other on chromosomes


=item co_expression_evidence

number of times members of the two FIGfams are co-expressed in
expression data experiments



=back


*/
funcdef get_relationship_IsCoupledTo(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Family, fields_IsCoupledTo, fields_Family>>);
funcdef get_relationship_IsCoupledWith(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Family, fields_IsCoupledTo, fields_Family>>);

typedef structure {
	string id;
	int inverted nullable;
} fields_IsDeterminedBy ;

/*
A functional coupling evidence set exists because it has
pairings in it, and this relationship connects the evidence set to
its constituent pairings. A pairing cam belong to multiple evidence
sets.
It has the following fields:

=over 4


=item inverted

A pairing is an unordered pair of protein sequences,
but its similarity to other pairings in a pair set is
ordered. Let (A,B) be a pairing and (X,Y) be another pairing
in the same set. If this flag is FALSE, then (A =~ X) and (B
=~ Y). If this flag is TRUE, then (A =~ Y) and (B =~
X).



=back


*/
funcdef get_relationship_IsDeterminedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_PairSet, fields_IsDeterminedBy, fields_Pairing>>);
funcdef get_relationship_Determines(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Pairing, fields_IsDeterminedBy, fields_PairSet>>);

typedef structure {
	string id;
} fields_IsDividedInto ;

/*
This relationship connects a model to its instances of
subcellular locations that participate in the model.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsDividedInto(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Model, fields_IsDividedInto, fields_LocationInstance>>);
funcdef get_relationship_IsDivisionOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_LocationInstance, fields_IsDividedInto, fields_Model>>);

typedef structure {
	string id;
} fields_IsExecutedAs ;

/*
This relationship links a reaction to the way it is used in a model.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsExecutedAs(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_IsExecutedAs, fields_ReactionInstance>>);
funcdef get_relationship_IsExecutionOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ReactionInstance, fields_IsExecutedAs, fields_Reaction>>);

typedef structure {
	string id;
} fields_IsExemplarOf ;

/*
This relationship links a role to a feature that provides a typical
example of how the role is implemented.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsExemplarOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsExemplarOf, fields_Role>>);
funcdef get_relationship_HasAsExemplar(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Role, fields_IsExemplarOf, fields_Feature>>);

typedef structure {
	string id;
} fields_IsFamilyFor ;

/*
This relationship connects an isofunctional family to the roles that
make up its assigned function.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsFamilyFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Family, fields_IsFamilyFor, fields_Role>>);
funcdef get_relationship_DeterminesFunctionOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Role, fields_IsFamilyFor, fields_Family>>);

typedef structure {
	string id;
} fields_IsFormedOf ;

/*
This relationship connects each feature to the atomic regulon to
which it belongs.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsFormedOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AtomicRegulon, fields_IsFormedOf, fields_Feature>>);
funcdef get_relationship_IsFormedInto(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsFormedOf, fields_AtomicRegulon>>);

typedef structure {
	string id;
} fields_IsFunctionalIn ;

/*
This relationship connects a role with the features in which
it plays a functional part.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsFunctionalIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Role, fields_IsFunctionalIn, fields_Feature>>);
funcdef get_relationship_HasFunctional(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsFunctionalIn, fields_Role>>);

typedef structure {
	string id;
} fields_IsGroupFor ;

/*
The recursive IsGroupFor relationship organizes
taxonomic groupings into a hierarchy based on the standard organism
taxonomy.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsGroupFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_TaxonomicGrouping, fields_IsGroupFor, fields_TaxonomicGrouping>>);
funcdef get_relationship_IsInGroup(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_TaxonomicGrouping, fields_IsGroupFor, fields_TaxonomicGrouping>>);

typedef structure {
	string id;
} fields_IsImplementedBy ;

/*
This relationship connects a variant to the physical machines
that implement it in the genomes. A variant is implemented by many
machines, but a machine belongs to only one variant.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsImplementedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Variant, fields_IsImplementedBy, fields_SSRow>>);
funcdef get_relationship_Implements(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SSRow, fields_IsImplementedBy, fields_Variant>>);

typedef structure {
	string id;
} fields_IsInPair ;

/*
A pairing contains exactly two protein sequences. A protein
sequence can belong to multiple pairings. When going from a protein
sequence to its pairings, they are presented in alphabetical order
by sequence key.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsInPair(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsInPair, fields_Pairing>>);
funcdef get_relationship_IsPairOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Pairing, fields_IsInPair, fields_Feature>>);

typedef structure {
	string id;
} fields_IsInstantiatedBy ;

/*
This relationship connects a subcellular location to the instances
of that location that occur in models.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsInstantiatedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Location, fields_IsInstantiatedBy, fields_LocationInstance>>);
funcdef get_relationship_IsInstanceOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_LocationInstance, fields_IsInstantiatedBy, fields_Location>>);

typedef structure {
	string id;
	int ordinal nullable;
	int begin nullable;
	int len nullable;
	string dir nullable;
} fields_IsLocatedIn ;

/*
A feature is a set of DNA sequence fragments. Most features
are a single contiquous fragment, so they are located in only one
DNA sequence; however, fragments have a maximum length, so even a
single contiguous feature may participate in this relationship
multiple times. A few features belong to multiple DNA sequences. In
that case, however, all the DNA sequences belong to the same genome.
A DNA sequence itself will frequently have thousands of features
connected to it.
It has the following fields:

=over 4


=item ordinal

Sequence number of this segment, starting from 1
and proceeding sequentially forward from there.


=item begin

Index (1-based) of the first residue in the contig
that belongs to the segment.


=item len

Length of this segment.


=item dir

Direction (strand) of the segment: "+" if it is
forward and "-" if it is backward.



=back


*/
funcdef get_relationship_IsLocatedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsLocatedIn, fields_Contig>>);
funcdef get_relationship_IsLocusFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Contig, fields_IsLocatedIn, fields_Feature>>);

typedef structure {
	string id;
} fields_IsMeasurementMethodOf ;

/*
The IsMeasurementMethodOf relationship describes which protocol
was used to make a measurement.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsMeasurementMethodOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Protocol, fields_IsMeasurementMethodOf, fields_Measurement>>);
funcdef get_relationship_WasMeasuredBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Measurement, fields_IsMeasurementMethodOf, fields_Protocol>>);

typedef structure {
	string id;
} fields_IsModeledBy ;

/*
A genome can be modeled by many different models, but a model belongs
to only one genome.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsModeledBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_IsModeledBy, fields_Model>>);
funcdef get_relationship_Models(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Model, fields_IsModeledBy, fields_Genome>>);

typedef structure {
	string id;
	string modification_type nullable;
	string modification_value nullable;
} fields_IsModifiedToBuildAlignment ;

/*
Relates an alignment to other alignments built from it.
It has the following fields:

=over 4


=item modification_type

description of how the alignment was modified


=item modification_value

description of any parameters used to derive the
modification



=back


*/
funcdef get_relationship_IsModifiedToBuildAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Alignment, fields_IsModifiedToBuildAlignment, fields_Alignment>>);
funcdef get_relationship_IsModificationOfAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Alignment, fields_IsModifiedToBuildAlignment, fields_Alignment>>);

typedef structure {
	string id;
	string modification_type nullable;
	string modification_value nullable;
} fields_IsModifiedToBuildTree ;

/*
Relates a tree to other trees built from it.
It has the following fields:

=over 4


=item modification_type

description of how the tree was modified (rerooted,
annotated, etc.)


=item modification_value

description of any parameters used to derive the
modification



=back


*/
funcdef get_relationship_IsModifiedToBuildTree(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Tree, fields_IsModifiedToBuildTree, fields_Tree>>);
funcdef get_relationship_IsModificationOfTree(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Tree, fields_IsModifiedToBuildTree, fields_Tree>>);

typedef structure {
	string id;
} fields_IsOwnerOf ;

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
funcdef get_relationship_IsOwnerOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_IsOwnerOf, fields_Feature>>);
funcdef get_relationship_IsOwnedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsOwnerOf, fields_Genome>>);

typedef structure {
	string id;
} fields_IsParticipatingAt ;

/*
This relationship connects a localized compound to the
location in which it occurs during one or more reactions.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsParticipatingAt(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Location, fields_IsParticipatingAt, fields_LocalizedCompound>>);
funcdef get_relationship_ParticipatesAt(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_LocalizedCompound, fields_IsParticipatingAt, fields_Location>>);

typedef structure {
	string id;
} fields_IsProteinFor ;

/*
This relationship connects a peg feature to the protein
sequence it produces (if any). Only peg features participate in this
relationship. A single protein sequence will frequently be produced
by many features.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsProteinFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_IsProteinFor, fields_Feature>>);
funcdef get_relationship_Produces(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsProteinFor, fields_ProteinSequence>>);

typedef structure {
	string id;
	float coefficient nullable;
} fields_IsReagentIn ;

/*
This relationship connects a compound instance to the reaction instance
in which it is transformed.
It has the following fields:

=over 4


=item coefficient

Number of molecules of the compound that participate
in a single instance of the reaction. For example, if a
reaction produces two water molecules, the stoichiometry of
water for the reaction would be two. When a reaction is
written on paper in chemical notation, the stoichiometry is
the number next to the chemical formula of the
compound. The value is negative for substrates and positive
for products.



=back


*/
funcdef get_relationship_IsReagentIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CompoundInstance, fields_IsReagentIn, fields_ReactionInstance>>);
funcdef get_relationship_Targets(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ReactionInstance, fields_IsReagentIn, fields_CompoundInstance>>);

typedef structure {
	string id;
} fields_IsRealLocationOf ;

/*
This relationship connects a specific instance of a compound in a model
to the specific instance of the model subcellular location where the compound exists.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsRealLocationOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_LocationInstance, fields_IsRealLocationOf, fields_CompoundInstance>>);
funcdef get_relationship_HasRealLocationIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CompoundInstance, fields_IsRealLocationOf, fields_LocationInstance>>);

typedef structure {
	string id;
} fields_IsReferencedBy ;

/*
This relationship associates each observational unit with the reference
genome that it will be compared to.  All variations will be differences
between the observational unit and the reference.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsReferencedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_IsReferencedBy, fields_ObservationalUnit>>);
funcdef get_relationship_UsesReference(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ObservationalUnit, fields_IsReferencedBy, fields_Genome>>);

typedef structure {
	string id;
} fields_IsRegulatedIn ;

/*
This relationship connects a feature to the set of coregulated features.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsRegulatedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsRegulatedIn, fields_CoregulatedSet>>);
funcdef get_relationship_IsRegulatedSetOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CoregulatedSet, fields_IsRegulatedIn, fields_Feature>>);

typedef structure {
	string id;
} fields_IsRelevantFor ;

/*
This relationship connects a diagram to the subsystems that are depicted on
it. Only diagrams which are useful in curating or annotation the subsystem are
specified in this relationship.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsRelevantFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Diagram, fields_IsRelevantFor, fields_Subsystem>>);
funcdef get_relationship_IsRelevantTo(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Subsystem, fields_IsRelevantFor, fields_Diagram>>);

typedef structure {
	string id;
} fields_IsRepresentedBy ;

/*
This relationship associates observational units with a genus,
species, strain, and/or variety that was the source material.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsRepresentedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_TaxonomicGrouping, fields_IsRepresentedBy, fields_ObservationalUnit>>);
funcdef get_relationship_DefinedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ObservationalUnit, fields_IsRepresentedBy, fields_TaxonomicGrouping>>);

typedef structure {
	string id;
} fields_IsRoleOf ;

/*
This relationship connects a role to the machine roles that
represent its appearance in a molecular machine. A machine role has
exactly one associated role, but a role may be represented by many
machine roles.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsRoleOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Role, fields_IsRoleOf, fields_SSCell>>);
funcdef get_relationship_HasRole(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SSCell, fields_IsRoleOf, fields_Role>>);

typedef structure {
	string id;
} fields_IsRowOf ;

/*
This relationship connects a subsystem spreadsheet row to its
constituent spreadsheet cells.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsRowOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SSRow, fields_IsRowOf, fields_SSCell>>);
funcdef get_relationship_IsRoleFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SSCell, fields_IsRowOf, fields_SSRow>>);

typedef structure {
	string id;
} fields_IsSequenceOf ;

/*
This relationship connects a Contig as it occurs in a
genome to the Contig Sequence that represents the physical
DNA base pairs. A contig sequence may represent many contigs,
but each contig has only one sequence.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsSequenceOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ContigSequence, fields_IsSequenceOf, fields_Contig>>);
funcdef get_relationship_HasAsSequence(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Contig, fields_IsSequenceOf, fields_ContigSequence>>);

typedef structure {
	string id;
} fields_IsSubInstanceOf ;

/*
This relationship connects a scenario to its subsystem it
validates. A scenario belongs to exactly one subsystem, but a
subsystem may have multiple scenarios.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsSubInstanceOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Subsystem, fields_IsSubInstanceOf, fields_Scenario>>);
funcdef get_relationship_Validates(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Scenario, fields_IsSubInstanceOf, fields_Subsystem>>);

typedef structure {
	string id;
	int position nullable;
} fields_IsSummarizedBy ;

/*
This relationship describes the statistical frequencies of the
most common alleles in various positions on the reference contig.
It has the following fields:

=over 4


=item position

Position in the reference contig where the trait
has an impact.



=back


*/
funcdef get_relationship_IsSummarizedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Contig, fields_IsSummarizedBy, fields_AlleleFrequency>>);
funcdef get_relationship_Summarizes(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AlleleFrequency, fields_IsSummarizedBy, fields_Contig>>);

typedef structure {
	string id;
} fields_IsSuperclassOf ;

/*
This is a recursive relationship that imposes a hierarchy on
the subsystem classes.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsSuperclassOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SubsystemClass, fields_IsSuperclassOf, fields_SubsystemClass>>);
funcdef get_relationship_IsSubclassOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SubsystemClass, fields_IsSuperclassOf, fields_SubsystemClass>>);

typedef structure {
	string id;
} fields_IsTaxonomyOf ;

/*
A genome is assigned to a particular point in the taxonomy tree, but not
necessarily to a leaf node. In some cases, the exact species and strain is
not available when inserting the genome, so it is placed at the lowest node
that probably contains the actual genome.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsTaxonomyOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_TaxonomicGrouping, fields_IsTaxonomyOf, fields_Genome>>);
funcdef get_relationship_IsInTaxa(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_IsTaxonomyOf, fields_TaxonomicGrouping>>);

typedef structure {
	string id;
	int group_number nullable;
} fields_IsTerminusFor ;

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

If zero, then the compound is an input. If one, the compound is
an output. If two, the compound is an auxiliary output.



=back


*/
funcdef get_relationship_IsTerminusFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_IsTerminusFor, fields_Scenario>>);
funcdef get_relationship_HasAsTerminus(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Scenario, fields_IsTerminusFor, fields_Compound>>);

typedef structure {
	string id;
	int optional nullable;
	string type nullable;
	int triggering nullable;
} fields_IsTriggeredBy ;

/*
This connects a complex to the roles that work together to form the complex.
It has the following fields:

=over 4


=item optional

TRUE if the role is not necessarily required to trigger the
complex, else FALSE


=item type

a string code that is used to determine whether a complex
should be added to a model


=item triggering

TRUE if the presence of the role requires including the
complex in the model, else FALSE



=back


*/
funcdef get_relationship_IsTriggeredBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Complex, fields_IsTriggeredBy, fields_Role>>);
funcdef get_relationship_Triggers(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Role, fields_IsTriggeredBy, fields_Complex>>);

typedef structure {
	string id;
} fields_IsUsedToBuildTree ;

/*
This relationship connects each tree to the alignment from
which it is built. There is at most one.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsUsedToBuildTree(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Alignment, fields_IsUsedToBuildTree, fields_Tree>>);
funcdef get_relationship_IsBuiltFromAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Tree, fields_IsUsedToBuildTree, fields_Alignment>>);

typedef structure {
	string id;
} fields_Manages ;

/*
This relationship connects a model to its associated biomass
composition reactions.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Manages(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Model, fields_Manages, fields_Biomass>>);
funcdef get_relationship_IsManagedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Biomass, fields_Manages, fields_Model>>);

typedef structure {
	string id;
} fields_OperatesIn ;

/*
This relationship connects an experiment to the media in which the
experiment took place.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_OperatesIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Experiment, fields_OperatesIn, fields_Media>>);
funcdef get_relationship_IsUtilizedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Media, fields_OperatesIn, fields_Experiment>>);

typedef structure {
	string id;
} fields_Overlaps ;

/*
A Scenario overlaps a diagram when the diagram displays a
portion of the reactions that make up the scenario. A scenario may
overlap many diagrams, and a diagram may be include portions of many
scenarios.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Overlaps(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Scenario, fields_Overlaps, fields_Diagram>>);
funcdef get_relationship_IncludesPartOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Diagram, fields_Overlaps, fields_Scenario>>);

typedef structure {
	string id;
} fields_ParticipatesAs ;

/*
This relationship connects a generic compound to a specific compound
where subceullar location has been specified.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_ParticipatesAs(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_ParticipatesAs, fields_LocalizedCompound>>);
funcdef get_relationship_IsParticipationOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_LocalizedCompound, fields_ParticipatesAs, fields_Compound>>);

typedef structure {
	string id;
	string role nullable;
} fields_PerformedExperiment ;

/*
Denotes that a Person was associated with a
PhenotypeExperiment in some role.
It has the following fields:

=over 4


=item role

Describes the role the person played in the experiment.
Examples are Primary Investigator, Designer, Experimentalist, etc.



=back


*/
funcdef get_relationship_PerformedExperiment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Person, fields_PerformedExperiment, fields_PhenotypeExperiment>>);
funcdef get_relationship_PerformedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_PhenotypeExperiment, fields_PerformedExperiment, fields_Person>>);

typedef structure {
	string id;
} fields_ProducedResultsFor ;

/*
This relationship connects a probe set to a genome for which it was
used to produce experimental results. In general, a probe set is used for
only one genome and vice versa, but this is not a requirement.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_ProducedResultsFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProbeSet, fields_ProducedResultsFor, fields_Genome>>);
funcdef get_relationship_HadResultsProducedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_ProducedResultsFor, fields_ProbeSet>>);

typedef structure {
	string id;
} fields_Provided ;

/*
This relationship connects a source (core) database
to the subsystems it submitted to the knowledge base.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Provided(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_Provided, fields_Subsystem>>);
funcdef get_relationship_WasProvidedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Subsystem, fields_Provided, fields_Source>>);

typedef structure {
	string id;
} fields_PublishedExperiment ;

/*
The ExperimentPublishedIn relationship describes where a
particular experiment was published.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_PublishedExperiment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Publication, fields_PublishedExperiment, fields_PhenotypeExperiment>>);
funcdef get_relationship_ExperimentPublishedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_PhenotypeExperiment, fields_PublishedExperiment, fields_Publication>>);

typedef structure {
	string id;
} fields_PublishedProtocol ;

/*
The ProtocolPublishedIn relationship describes where a
particular protocol was published.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_PublishedProtocol(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Publication, fields_PublishedProtocol, fields_Protocol>>);
funcdef get_relationship_ProtocolPublishedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Protocol, fields_PublishedProtocol, fields_Publication>>);

typedef structure {
	string id;
	rectangle location nullable;
} fields_Shows ;

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
funcdef get_relationship_Shows(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Diagram, fields_Shows, fields_Compound>>);
funcdef get_relationship_IsShownOn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_Shows, fields_Diagram>>);

typedef structure {
	string id;
} fields_Submitted ;

/*
This relationship connects a genome to the
core database from which it was loaded.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Submitted(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_Submitted, fields_Genome>>);
funcdef get_relationship_WasSubmittedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_Submitted, fields_Source>>);

typedef structure {
	string id;
	string successor_type nullable;
} fields_SupersedesAlignment ;

/*
This relationship connects an alignment to the alignments
it replaces.
It has the following fields:

=over 4


=item successor_type

Indicates whether sequences were removed or added
to create the new alignment.



=back


*/
funcdef get_relationship_SupersedesAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Alignment, fields_SupersedesAlignment, fields_Alignment>>);
funcdef get_relationship_IsSupersededByAlignment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Alignment, fields_SupersedesAlignment, fields_Alignment>>);

typedef structure {
	string id;
	string successor_type nullable;
} fields_SupersedesTree ;

/*
This relationship connects a tree to the trees
it replaces.
It has the following fields:

=over 4


=item successor_type

Indicates whether sequences were removed or added
to create the new tree.



=back


*/
funcdef get_relationship_SupersedesTree(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Tree, fields_SupersedesTree, fields_Tree>>);
funcdef get_relationship_IsSupersededByTree(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Tree, fields_SupersedesTree, fields_Tree>>);

typedef structure {
	string id;
} fields_Treed ;

/*
This relationship connects a tree to the source database from
which it was generated.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Treed(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_Treed, fields_Tree>>);
funcdef get_relationship_IsTreeFrom(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Tree, fields_Treed, fields_Source>>);

typedef structure {
	string id;
} fields_UsedBy ;

/*
The UsesMedia relationship defines which media is used by an
Environment.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_UsedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Media, fields_UsedBy, fields_Environment>>);
funcdef get_relationship_UsesMedia(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Environment, fields_UsedBy, fields_Media>>);

typedef structure {
	string id;
} fields_UsedInExperimentalUnit ;

/*
The HasEnvironment relationship describes the enviroment a
subexperiment defined by Experimental unit was performed in.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_UsedInExperimentalUnit(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Environment, fields_UsedInExperimentalUnit, fields_ExperimentalUnit>>);
funcdef get_relationship_HasEnvironment(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ExperimentalUnit, fields_UsedInExperimentalUnit, fields_Environment>>);

typedef structure {
	string id;
} fields_Uses ;

/*
This relationship connects a genome to the machines that form
its metabolic pathways. A genome can use many machines, but a
machine is used by exactly one genome.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Uses(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_Uses, fields_SSRow>>);
funcdef get_relationship_IsUsedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_SSRow, fields_Uses, fields_Genome>>);

typedef structure {
	string id;
} fields_UsesCodons ;

/*
This relationship connects a genome to the various codon usage
records for it.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_UsesCodons(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Genome, fields_UsesCodons, fields_CodonUsage>>);
funcdef get_relationship_AreCodonsFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CodonUsage, fields_UsesCodons, fields_Genome>>);

};
