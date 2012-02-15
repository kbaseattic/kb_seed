module CDMI_API : CDMI_EntityAPI {
typedef string diamond;
typedef string countVector;
typedef string rectangle;

typedef structure {
	string id;
	string alignment_method nullable;
	string alignment_parameters nullable;
	string alignment_properties nullable;
	string tree_method nullable;
	string tree_parameters nullable;
	string tree_properties nullable;
} fields_AlignmentTree ;

/*
An alignment arranges a group of protein sequences so that they
match. Each alignment is associated with a phylogenetic tree that
describes how the sequences developed and their evolutionary distance.
The actual tree and alignment FASTA are stored in separate flat files.
The Kbase will maintain a set of alignments and associated
trees.  The majority
of these will be based on protein sequences.  We will not have a comprehensive set
but we will have tens of thousands of such alignments, and we view them as an
imporant resource to support annotation.
The alignments/trees will include the tools and parameters used to construct
them.
Access to the underlying sequences and trees in a form convenient to existing
tools will be supported.

It has the following fields:

=over 4


=item alignment_method

The name of the program used to produce the alignment.


=item alignment_parameters

The parameters given to the program when producing the alignment.


=item alignment_properties

A colon-delimited string of key-value pairs containing additional
properties of the alignment.


=item tree_method

The name of the program used to produce the tree.


=item tree_parameters

The parameters given to the program when producing the tree.


=item tree_properties

A colon-delimited string of key-value pairs containing additional
properties of the tree.



=back


*/
funcdef get_entity_AlignmentTree(list<string> ids, list<string> fields)
	returns(mapping<string, fields_AlignmentTree>);
funcdef all_entities_AlignmentTree(int start, int count, list<string> fields)
	returns(mapping<string, fields_AlignmentTree>);

typedef structure {
	string id;
	string annotator nullable;
	string comment nullable;
	string annotation_time nullable;
} fields_Annotation ;

/*
An annotation is a comment attached to a feature. Annotations
are used to track the history of a feature's functional assignments
and any related issues. The key is the feature ID followed by a
colon and a complemented ten-digit sequence number.

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
funcdef all_entities_Annotation(int start, int count, list<string> fields)
	returns(mapping<string, fields_Annotation>);

typedef structure {
	string id;
} fields_AtomicRegulon ;

/*
An atomic regulon is an indivisible group of coregulated features
on a single genome. Atomic regulons are constructed so that a given feature
can only belong to one. Because of this, the expression levels for
atomic regulons represent in some sense the state of a cell.
An atomicRegulon is a set of protein-encoding genes that
are believed to have identical expression profiles (i.e.,
they will all be expressed or none will be expressed in the
vast majority of conditions).  These are sometimes referred
to as "atomic regulons".  Note that there are more common
notions of "coregulated set of genes" based on the notion
that a single regulatory mechanism impacts an entire set of
genes. Since multiple other mechanisms may impact
overlapping sets, the genes impacted by a regulatory
mechanism need not all share the same expression profile.
We use a distinct notion (CoregulatedSet) to reference sets
of genes impacted by a single regulatory mechanism (i.e.,
by a single transcription regulator).

It has the following fields:

=over 4



=back


*/
funcdef get_entity_AtomicRegulon(list<string> ids, list<string> fields)
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
funcdef all_entities_Attribute(int start, int count, list<string> fields)
	returns(mapping<string, fields_Attribute>);

typedef structure {
	string id;
	string mod_date nullable;
	string name nullable;
} fields_Biomass ;

/*
A biomass is a collection of compounds in a specific
ratio and in specific compartments that are necessary for a
cell to function properly. The prediction of biomasses is key
to the functioning of the model.
It has the following fields:

=over 4


=item mod_date

last modification date of the biomass data


=item name

descriptive name for this biomass



=back


*/
funcdef get_entity_Biomass(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Biomass>);
funcdef all_entities_Biomass(int start, int count, list<string> fields)
	returns(mapping<string, fields_Biomass>);

typedef structure {
	string id;
	float coefficient nullable;
} fields_BiomassCompound ;

/*
A Biomass Compound represents the occurrence of a particular
compound in a biomass.
It has the following fields:

=over 4


=item coefficient

proportion of the biomass in grams per mole that
contains this compound



=back


*/
funcdef get_entity_BiomassCompound(list<string> ids, list<string> fields)
	returns(mapping<string, fields_BiomassCompound>);
funcdef all_entities_BiomassCompound(int start, int count, list<string> fields)
	returns(mapping<string, fields_BiomassCompound>);

typedef structure {
	string id;
	string abbr nullable;
	string mod_date nullable;
	string name nullable;
} fields_Compartment ;

/*
A compartment is a section of a single model that represents
the environment in which a reaction takes place (e.g. cell
wall).
It has the following fields:

=over 4


=item abbr

short abbreviated name for this compartment (usually
a single character)


=item mod_date

date and time of the last modification to the
compartment's definition


=item name

common name for the compartment



=back


*/
funcdef get_entity_Compartment(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Compartment>);
funcdef all_entities_Compartment(int start, int count, list<string> fields)
	returns(mapping<string, fields_Compartment>);

typedef structure {
	string id;
	string name nullable;
	string mod_date nullable;
} fields_Complex ;

/*
A complex is a set of chemical reactions that act in concert to
effect a role.
It has the following fields:

=over 4


=item name

name of this complex. Not all complexes have names.


=item mod_date

date and time of the last change to this complex's definition



=back


*/
funcdef get_entity_Complex(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Complex>);
funcdef all_entities_Complex(int start, int count, list<string> fields)
	returns(mapping<string, fields_Complex>);

typedef structure {
	string id;
	string label nullable;
	string abbr nullable;
	int ubiquitous nullable;
	string mod_date nullable;
	string uncharged_formula nullable;
	string formula nullable;
	float mass nullable;
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


=item ubiquitous

TRUE if this compound is found in most reactions, else FALSE


=item mod_date

date and time of the last modification to the
compound definition


=item uncharged_formula

a electrically neutral formula for the compound


=item formula

a pH-neutral formula for the compound


=item mass

atomic mass of the compound



=back


*/
funcdef get_entity_Compound(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Compound>);
funcdef all_entities_Compound(int start, int count, list<string> fields)
	returns(mapping<string, fields_Compound>);

typedef structure {
	string id;
	string source_id nullable;
} fields_Contig ;

/*
A contig is thought of as composing a part of the DNA associated with a specific
genome.  It is represented as an ID (including the genome ID) and a ContigSequence.
We do not think of strings of DNA from, say, a metgenomic sample as "contigs",
since there is no associated genome (these would be considered ContigSequences).
This use of the term "ContigSequence", rather than just "DNA sequence", may turn out
to be a bad idea.  For now, you should just realize that a Contig has an associated
genome, but a ContigSequence does not.

It has the following fields:

=over 4


=item source_id

ID of this contig from the core (source) database



=back


*/
funcdef get_entity_Contig(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Contig>);
funcdef all_entities_Contig(int start, int count, list<string> fields)
	returns(mapping<string, fields_Contig>);

typedef structure {
	string id;
	string sequence nullable;
} fields_ContigChunk ;

/*
ContigChunks are strings of DNA thought of as being a string in a 4-character alphabet
with an associated ID.  We allow a broader alphabet that includes U (for RNA) and
the standard ambiguity characters.
The notion of ContigChunk was introduced to avoid transferring/manipulating
huge contigs to access small substrings.  A ContigSequence is formed by
concatenating a set of one or more ContigChunks.  Thus, ContigChunks are the
basic units moved from the database to memory.  Their existence should be
hidden from users in most circumstances (users are expected to request
substrings of ContigSequences, and the Kbase software locates the appropriate
ContigChunks).

It has the following fields:

=over 4


=item sequence

base pairs that make up this sequence



=back


*/
funcdef get_entity_ContigChunk(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ContigChunk>);
funcdef all_entities_ContigChunk(int start, int count, list<string> fields)
	returns(mapping<string, fields_ContigChunk>);

typedef structure {
	string id;
	int length nullable;
} fields_ContigSequence ;

/*
ContigSequences are strings of DNA.  Contigs have an associated
genome, but ContigSequences do not..   We can think of random samples of DNA as a set of ContigSequences.
There are no length constraints imposed on ContigSequences -- they can be either
very short or very long.  The basic unit of data that is moved to/from the database
is the ContigChunk, from which ContigSequences are formed. The key
of a ContigSequence is the sequence's MD5 identifier.

It has the following fields:

=over 4


=item length

number of base pairs in the contig



=back


*/
funcdef get_entity_ContigSequence(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ContigSequence>);
funcdef all_entities_ContigSequence(int start, int count, list<string> fields)
	returns(mapping<string, fields_ContigSequence>);

typedef structure {
	string id;
	string reason nullable;
} fields_CoregulatedSet ;

/*
We need to represent sets of genes that are coregulated via some
regulatory mechanism.  In particular, we wish to represent genes
that are coregulated using transcription binding sites and
corresponding transcription regulatory proteins.
We represent a coregulated set (which may, or may not, be considered
an atomic regulon) using CoregulatedSet.

It has the following fields:

=over 4


=item reason

Description of how this coregulated set was derived.



=back


*/
funcdef get_entity_CoregulatedSet(list<string> ids, list<string> fields)
	returns(mapping<string, fields_CoregulatedSet>);
funcdef all_entities_CoregulatedSet(int start, int count, list<string> fields)
	returns(mapping<string, fields_CoregulatedSet>);

typedef structure {
	string id;
	string name nullable;
	string content nullable;
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
funcdef all_entities_EcNumber(int start, int count, list<string> fields)
	returns(mapping<string, fields_EcNumber>);

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
funcdef all_entities_Experiment(int start, int count, list<string> fields)
	returns(mapping<string, fields_Experiment>);

typedef structure {
	string id;
	string type nullable;
	string family_function nullable;
} fields_Family ;

/*
The Kbase will support the maintenance of protein families (as sets of Features
with associated translations).  We are initially only supporting the notion of a family
as composed of a set of isofunctional homologs.  That is, the families we
initially support should be thought of as containing protein-encoding genes whose
associated sequences all implement the same function
(we do understand that the notion of "function" is somewhat ambiguous, so let
us sweep this under the rug by calling a functional role a "primitive concept").
We currently support families in which the members are
translations of features, and we think of Features as
having an associated function. Identical protein sequences
as products of translating distinct genes may or may not
have identical functions, and we allow multiple members of
the same Family to share identical protein sequences.  This
may be justified, since in a very, very, very few cases
identical proteins do, in fact, have distinct functions.
We would prefer to reach the point where our Families are
sets of protein sequence, rather than sets of
protein-encoding Features.

It has the following fields:

=over 4


=item type

type of protein family (e.g. FIGfam, equivalog)


=item family_function

optional free-form description of the family. For function-based
families, this would be the functional role for the family
members.



=back


*/
funcdef get_entity_Family(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Family>);
funcdef all_entities_Family(int start, int count, list<string> fields)
	returns(mapping<string, fields_Family>);

typedef structure {
	string id;
	string feature_type nullable;
	string source_id nullable;
	int sequence_length nullable;
	string function nullable;
} fields_Feature ;

/*
A feature (sometimes also called a gene) is a part of a
genome that is of special interest. Features may be spread across
multiple DNA sequences (contigs) of a genome, but never across more
than one genome. Each feature in the database has a unique
ID that functions as its ID in this table.
Normally a Feature is just a single contigous region on a contig.
Features have types, and an appropriate choice of available types
allows the support of protein-encoding genes, exons, RNA genes,
binding sites, pathogenicity islands, or whatever.

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



=back


*/
funcdef get_entity_Feature(list<string> ids, list<string> fields)
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
	string phenotype nullable;
	string md5 nullable;
	string source_id nullable;
} fields_Genome ;

/*
The Kbase houses a large and growing set of genomes.  We often have multiple
genomes that have identical DNA.  These usually have distinct gene calls and
annotations, but not always.  We consider the Kbase to be a framework for
managing hundreds of thousands of genomes and offering the tools needed to
support compartive analysis on large sets of genomes, some of which are
virtually identical.
Each genome has an MD5 value computed from the DNA that is associated with the genome.
Hence, it is easy to recognize when you have identical genomes, perhaps annotated
by distinct groups.

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
funcdef all_entities_Genome(int start, int count, list<string> fields)
	returns(mapping<string, fields_Genome>);

typedef structure {
	string id;
	string source nullable;
	string natural_form nullable;
} fields_Identifier ;

/*
An identifier is an alternate name for a protein sequence.
The identifier is typically stored in a prefixed form that
indicates the database it came from.
It has the following fields:

=over 4


=item source

Specific type of the identifier, such as its source
database or category. The type can usually be decoded to
convert the identifier to a URL.


=item natural_form

Natural form of the identifier. This is how the identifier looks
without the identifying prefix (if one is present).



=back


*/
funcdef get_entity_Identifier(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Identifier>);
funcdef all_entities_Identifier(int start, int count, list<string> fields)
	returns(mapping<string, fields_Identifier>);

typedef structure {
	string id;
	string mod_date nullable;
	string name nullable;
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


=item type

type of the medium (aerobic or anaerobic)



=back


*/
funcdef get_entity_Media(list<string> ids, list<string> fields)
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

ask Chris


=item status

indicator of whether the model is stable, under
construction, or under reconstruction


=item reaction_count

number of reactions in the model


=item compound_count

number of compounds in the model


=item annotation_count

number of annotations used to build the model



=back


*/
funcdef get_entity_Model(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Model>);
funcdef all_entities_Model(int start, int count, list<string> fields)
	returns(mapping<string, fields_Model>);

typedef structure {
	string id;
	int compartment_index nullable;
	string label nullable;
	float pH nullable;
	float potential nullable;
} fields_ModelCompartment ;

/*
The Model Compartment represents a section of a cell
(e.g. cell wall, cytoplasm) as it appears in a specific
model.
It has the following fields:

=over 4


=item compartment_index

number used to distinguish between different
instances of the same type of compartment in a single
model. Within a model, any two instances of the same
compartment must have difference compartment index
values.


=item label

description used to differentiate between instances
of the same compartment in a single model


=item pH

pH used to determine proton balance in this
compartment


=item potential

ask Chris



=back


*/
funcdef get_entity_ModelCompartment(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ModelCompartment>);
funcdef all_entities_ModelCompartment(int start, int count, list<string> fields)
	returns(mapping<string, fields_ModelCompartment>);

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
funcdef all_entities_OTU(int start, int count, list<string> fields)
	returns(mapping<string, fields_OTU>);

typedef structure {
	string id;
	int score nullable;
} fields_PairSet ;

/*
A PairSet is a precompute set of pairs or genes.  Each pair occurs close to
one another of the chromosome.  We believe that all of the first members
of the pairs correspond to one another (are quite similar), as do all of
the second members of the pairs.  These pairs (from prokaryotic genomes)
offer on of the most powerful clues relating to uncharacterized genes/peroteins.

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
funcdef all_entities_Pairing(int start, int count, list<string> fields)
	returns(mapping<string, fields_Pairing>);

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
funcdef all_entities_ProbeSet(int start, int count, list<string> fields)
	returns(mapping<string, fields_ProbeSet>);

typedef structure {
	string id;
	string sequence nullable;
} fields_ProteinSequence ;

/*
We use the concept of ProteinSequence as an amino acid string with an associated
MD5 value.  It is easy to access the set of Features that relate to a ProteinSequence.
While function is still associated with Features (and may be for some time), publications
are associated with ProteinSequences (and the inferred impact on Features is through
the relationship connecting ProteinSequences to Features).

It has the following fields:

=over 4


=item sequence

The sequence contains the letters corresponding to
the protein's amino acids.



=back


*/
funcdef get_entity_ProteinSequence(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ProteinSequence>);
funcdef all_entities_ProteinSequence(int start, int count, list<string> fields)
	returns(mapping<string, fields_ProteinSequence>);

typedef structure {
	string id;
	string citation nullable;
} fields_Publication ;

/*
Annotators attach publications to ProteinSequences.  The criteria we have used
to gather such connections is a bit nonstandard.  We have sought to attach publications
to ProteinSequences when the publication includes an expert asserting a belief or estimate
of function.  The paper may not be the original characterization.  Further, it may not
even discuss a sequence protein (much of the lietarture is very valuable, but reports
work on proteins in strains that have not yet been sequenced).  On the other hand,
reports of sequencing regions of a chromosome (with no specific assertion of a
clear function) should not be attached.  The attached publications give an ID (usually a
Pubmed ID),  a URL to the paper (when we have it), and a title (when we have it).

It has the following fields:

=over 4


=item citation

Hyperlink of the article. The text is the article title.



=back


*/
funcdef get_entity_Publication(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Publication>);
funcdef all_entities_Publication(int start, int count, list<string> fields)
	returns(mapping<string, fields_Publication>);

typedef structure {
	string id;
	string mod_date nullable;
	string name nullable;
	string abbr nullable;
	string equation nullable;
	string reversibility nullable;
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


=item abbr

abbreviated name of this reaction


=item equation

displayable formula for the reaction


=item reversibility

direction of this reaction (> for forward-only,
< for backward-only, = for bidirectional)



=back


*/
funcdef get_entity_Reaction(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Reaction>);
funcdef all_entities_Reaction(int start, int count, list<string> fields)
	returns(mapping<string, fields_Reaction>);

typedef structure {
	string id;
	string direction nullable;
	float transproton nullable;
} fields_ReactionRule ;

/*
A reaction rule represents the way a reaction takes place
within the context of a model.
It has the following fields:

=over 4


=item direction

reaction directionality (> for forward, < for
backward, = for bidirectional) with respect to this complex


=item transproton

ask Chris



=back


*/
funcdef get_entity_ReactionRule(list<string> ids, list<string> fields)
	returns(mapping<string, fields_ReactionRule>);
funcdef all_entities_ReactionRule(int start, int count, list<string> fields)
	returns(mapping<string, fields_ReactionRule>);

typedef structure {
	string id;
	float stoichiometry nullable;
	int cofactor nullable;
	int compartment_index nullable;
	float transport_coefficient nullable;
} fields_Reagent ;

/*
This entity represents a compound as it is used by
a specific reaction. A reaction involves many compounds, and a
compound can be involved in many reactions. The reagent
describes the use of the compound by a specific reaction.
It has the following fields:

=over 4


=item stoichiometry

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


=item compartment_index

Abstract number that groups this reagent into a
compartment. Each group can then be assigned to real
compartments when doing comparative analysis.


=item transport_coefficient

Number of reagents of this type transported.
A positive value implies transport into the reactions
default compartment; a negative value implies export
to the reagent's specified compartment.



=back


*/
funcdef get_entity_Reagent(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Reagent>);
funcdef all_entities_Reagent(int start, int count, list<string> fields)
	returns(mapping<string, fields_Reagent>);

typedef structure {
	string id;
	string direction nullable;
	float transproton nullable;
	float proton nullable;
} fields_Requirement ;

/*
A requirement describes the way a reaction fits
into a model.
It has the following fields:

=over 4


=item direction

reaction directionality (> for forward, < for
backward, = for bidirectional) with respect to this model


=item transproton

ask Chris


=item proton

ask Chris



=back


*/
funcdef get_entity_Requirement(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Requirement>);
funcdef all_entities_Requirement(int start, int count, list<string> fields)
	returns(mapping<string, fields_Requirement>);

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
funcdef all_entities_SSCell(int start, int count, list<string> fields)
	returns(mapping<string, fields_SSCell>);

typedef structure {
	string id;
	int curated nullable;
	string region nullable;
} fields_SSRow ;

/*
An SSRow (that is, a row in a subsystem spreadsheet) represents a collection of
functional roles present in the Features of a single Genome.  The roles are part
of a designated subsystem, and the fids associated with each role are included in the row,
That is, a row amounts to an instance of a subsystem as it exists in a specific, designated
genome.

It has the following fields:

=over 4


=item curated

This flag is TRUE if the assignment of the molecular
machine has been curated, and FALSE if it was made by an
automated program.


=item region

Region in the genome for which the machine is relevant.
Normally, this is an empty string, indicating that the machine
covers the whole genome. If a subsystem has multiple machines
for a genome, this contains a location string describing the
region occupied by this particular machine.



=back


*/
funcdef get_entity_SSRow(list<string> ids, list<string> fields)
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
funcdef all_entities_Source(int start, int count, list<string> fields)
	returns(mapping<string, fields_Source>);

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
funcdef all_entities_SubsystemClass(int start, int count, list<string> fields)
	returns(mapping<string, fields_SubsystemClass>);

typedef structure {
	string id;
	int domain nullable;
	int hidden nullable;
	string scientific_name nullable;
	string alias nullable;
} fields_TaxonomicGrouping ;

/*
We associate with most genomes a "taxonomy" based on the NCBI taxonomy.
This includes, for each genome, a list of ever larger taxonomic groups.

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
funcdef all_entities_TaxonomicGrouping(int start, int count, list<string> fields)
	returns(mapping<string, fields_TaxonomicGrouping>);

typedef structure {
	string id;
	string role_rule nullable;
	string code nullable;
	string type nullable;
	string comment nullable;
} fields_Variant ;

/*
Each subsystem may include the designation of distinct variants.  Thus,
there may be three closely-related, but distinguishable forms of histidine
degradation.  Each form would be called a "variant", with an associated code,
and all genomes implementing a specific variant can easily be accessed.

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
funcdef all_entities_Variant(int start, int count, list<string> fields)
	returns(mapping<string, fields_Variant>);

typedef structure {
	string id;
	string notes nullable;
} fields_Variation ;

/*
A variation describes a set of aligned regions
in two or more contigs.
It has the following fields:

=over 4


=item notes

optional text description of what the variation
means



=back


*/
funcdef get_entity_Variation(list<string> ids, list<string> fields)
	returns(mapping<string, fields_Variation>);
funcdef all_entities_Variation(int start, int count, list<string> fields)
	returns(mapping<string, fields_Variation>);

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
	int begin nullable;
	int end nullable;
	int len nullable;
	string sequence_id nullable;
	string properties nullable;
} fields_Aligns ;

/*
This relationship connects each alignment to its constituent protein
sequences. Each alignment contains many protein sequences, and a single
sequence can be in many alignments. Parts of a single protein can occur
in multiple places in an alignment. The sequence-id field is used to
keep these unique, and is the string that represents the sequence in the
alignment and tree text.
It has the following fields:

=over 4


=item begin

location within the sequence at which the aligned portion begins


=item end

location within the sequence at which the aligned portion ends


=item len

length of the sequence within the alignment


=item sequence_id

identifier for this sequence in the alignment


=item properties

additional information about this sequence's participation in the
alignment



=back


*/
funcdef get_relationship_Aligns(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_AlignmentTree, fields_Aligns, fields_ProteinSequence>>);
funcdef get_relationship_IsAlignedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_Aligns, fields_AlignmentTree>>);

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
	string function nullable;
	int expert nullable;
} fields_HasAssertionFrom ;

/*
Sources (users) can make assertions about identifiers using the annotation clearinghouse.
When a user makes a new assertion about an identifier, it erases the old one.
It has the following fields:

=over 4


=item function

The function is the text of the assertion made about the identifier.


=item expert

TRUE if this is an expert assertion, else FALSE



=back


*/
funcdef get_relationship_HasAssertionFrom(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Identifier, fields_HasAssertionFrom, fields_Source>>);
funcdef get_relationship_Asserts(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Source, fields_HasAssertionFrom, fields_Identifier>>);

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
	float minimum_flux nullable;
	float maximum_flux nullable;
} fields_HasPresenceOf ;

/*
This relationship connects a media to the compounds that
occur in it. The intersection data describes how much of each
compound can be found.
It has the following fields:

=over 4


=item concentration

concentration of the compound in the media


=item minimum_flux

minimum flux of the compound for this media


=item maximum_flux

maximum flux of the compound for this media



=back


*/
funcdef get_relationship_HasPresenceOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Media, fields_HasPresenceOf, fields_Compound>>);
funcdef get_relationship_IsPresentIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_HasPresenceOf, fields_Media>>);

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
This relationship connects a complex to the reaction
rules for the reactions that work together to make the complex
happen.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasStep(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Complex, fields_HasStep, fields_ReactionRule>>);
funcdef get_relationship_IsStepOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ReactionRule, fields_HasStep, fields_Complex>>);

typedef structure {
	string id;
} fields_HasUsage ;

/*
This relationship connects a biomass compound specification
to the compounds for which it is relevant.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_HasUsage(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_HasUsage, fields_BiomassCompound>>);
funcdef get_relationship_IsUsageOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_BiomassCompound, fields_HasUsage, fields_Compound>>);

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
} fields_Involves ;

/*
This relationship connects a reaction to the
reagents representing the compounds that participate in it.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_Involves(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_Involves, fields_Reagent>>);
funcdef get_relationship_IsInvolvedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reagent, fields_Involves, fields_Reaction>>);

typedef structure {
	string id;
} fields_IsARequirementIn ;

/*
This relationship connects a model to its requirements.
A requirement represents the use of a reaction in a single model.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsARequirementIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Model, fields_IsARequirementIn, fields_Requirement>>);
funcdef get_relationship_IsARequirementOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Requirement, fields_IsARequirementIn, fields_Model>>);

typedef structure {
	string id;
	int start nullable;
	int len nullable;
	string dir nullable;
} fields_IsAlignedIn ;

/*
This relationship connects each variation to the
contig regions that it aligns.
It has the following fields:

=over 4


=item start

start location of region


=item len

length of region


=item dir

direction of region (+ or -)



=back


*/
funcdef get_relationship_IsAlignedIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Contig, fields_IsAlignedIn, fields_Variation>>);
funcdef get_relationship_IsAlignmentFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Variation, fields_IsAlignedIn, fields_Contig>>);

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
} fields_IsBindingSiteFor ;

/*
This relationship connects a coregulated set to the
binding site to which its feature attaches.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsBindingSiteFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsBindingSiteFor, fields_CoregulatedSet>>);
funcdef get_relationship_IsBoundBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CoregulatedSet, fields_IsBindingSiteFor, fields_Feature>>);

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
} fields_IsComprisedOf ;

/*
This relationship connects a biomass to the compound
specifications that define it.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsComprisedOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Biomass, fields_IsComprisedOf, fields_BiomassCompound>>);
funcdef get_relationship_Comprises(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_BiomassCompound, fields_IsComprisedOf, fields_Biomass>>);

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
	int effector nullable;
} fields_IsControlledUsing ;

/*
This relationship connects a coregulated set to the
protein that is used as its transcription factor.
It has the following fields:

=over 4


=item effector

TRUE if this transcription factor is an effector
(up-regulates), FALSE if it is a suppressor (down-regulates)



=back


*/
funcdef get_relationship_IsControlledUsing(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_CoregulatedSet, fields_IsControlledUsing, fields_Feature>>);
funcdef get_relationship_Controls(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Feature, fields_IsControlledUsing, fields_CoregulatedSet>>);

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
} fields_IsDefaultFor ;

/*
This relationship connects a reaction to the compartment
in which it runs by default.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsDefaultFor(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compartment, fields_IsDefaultFor, fields_Reaction>>);
funcdef get_relationship_RunsByDefaultIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_IsDefaultFor, fields_Compartment>>);

typedef structure {
	string id;
} fields_IsDefaultLocationOf ;

/*
This relationship connects a reagent to the compartment
which is its default location during the reaction.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsDefaultLocationOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compartment, fields_IsDefaultLocationOf, fields_Reagent>>);
funcdef get_relationship_HasDefaultLocation(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reagent, fields_IsDefaultLocationOf, fields_Compartment>>);

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
This relationship connects a model to the cell compartments
that participate in the model.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsDividedInto(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Model, fields_IsDividedInto, fields_ModelCompartment>>);
funcdef get_relationship_IsDivisionOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ModelCompartment, fields_IsDividedInto, fields_Model>>);

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
This relationship connects a compartment to the instances
of that compartment that occur in models.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsInstantiatedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compartment, fields_IsInstantiatedBy, fields_ModelCompartment>>);
funcdef get_relationship_IsInstanceOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ModelCompartment, fields_IsInstantiatedBy, fields_Compartment>>);

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
} fields_IsNamedBy ;

/*
The normal case is that an identifier names a single
protein sequence, while a protein sequence can have many identifiers,
but some identifiers name multiple sequences.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsNamedBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_IsNamedBy, fields_Identifier>>);
funcdef get_relationship_Names(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Identifier, fields_IsNamedBy, fields_ProteinSequence>>);

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
	string type nullable;
} fields_IsProposedLocationOf ;

/*
This relationship connects a reaction as it is used in
a complex to the compartments in which it usually takes place.
Most reactions take place in a single compartment. Transporters
take place in two compartments.
It has the following fields:

=over 4


=item type

role of the compartment in the reaction: 'primary'
if it is the sole or starting compartment, 'secondary' if
it is the ending compartment in a multi-compartmental
reaction



=back


*/
funcdef get_relationship_IsProposedLocationOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compartment, fields_IsProposedLocationOf, fields_ReactionRule>>);
funcdef get_relationship_HasProposedLocationIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ReactionRule, fields_IsProposedLocationOf, fields_Compartment>>);

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
	string type nullable;
} fields_IsRealLocationOf ;

/*
This relationship connects a model's instance of a reaction
to the compartments in which it takes place. Most instances
take place in a single compartment. Transporters use two compartments.
It has the following fields:

=over 4


=item type

role of the compartment in the reaction: 'primary'
if it is the sole or starting compartment, 'secondary' if
it is the ending compartment in a multi-compartmental
reaction



=back


*/
funcdef get_relationship_IsRealLocationOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ModelCompartment, fields_IsRealLocationOf, fields_Requirement>>);
funcdef get_relationship_HasRealLocationIn(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Requirement, fields_IsRealLocationOf, fields_ModelCompartment>>);

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
} fields_IsRequiredBy ;

/*
This relationship links a reaction to the way it is used in a model.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsRequiredBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_IsRequiredBy, fields_Requirement>>);
funcdef get_relationship_Requires(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Requirement, fields_IsRequiredBy, fields_Reaction>>);

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
} fields_IsTargetOf ;

/*
This relationship connects a compound in a biomass to the
compartment in which it is supposed to appear.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsTargetOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ModelCompartment, fields_IsTargetOf, fields_BiomassCompound>>);
funcdef get_relationship_Targets(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_BiomassCompound, fields_IsTargetOf, fields_ModelCompartment>>);

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
} fields_IsTriggeredBy ;

/*
A complex can be triggered by many roles. A role can
trigger many complexes.
It has the following fields:

=over 4


=item optional

TRUE if the role is not necessarily required to trigger the
complex, else FALSE


=item type

ask Chris



=back


*/
funcdef get_relationship_IsTriggeredBy(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Complex, fields_IsTriggeredBy, fields_Role>>);
funcdef get_relationship_Triggers(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Role, fields_IsTriggeredBy, fields_Complex>>);

typedef structure {
	string id;
} fields_IsUsedAs ;

/*
This relationship connects a reaction to its usage in
specific complexes.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_IsUsedAs(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reaction, fields_IsUsedAs, fields_ReactionRule>>);
funcdef get_relationship_IsUseOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ReactionRule, fields_IsUsedAs, fields_Reaction>>);

typedef structure {
	string id;
} fields_Manages ;

/*
This relationship connects a model to the biomasses
that are monitored to determine whether or not the model
is effective.
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
This relationship connects a compound to the reagents
that represent its participation in reactions.
It has the following fields:

=over 4



=back


*/
funcdef get_relationship_ParticipatesAs(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Compound, fields_ParticipatesAs, fields_Reagent>>);
funcdef get_relationship_IsParticipationOf(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_Reagent, fields_ParticipatesAs, fields_Compound>>);

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
	int gene_context nullable;
	float percent_identity nullable;
	float score nullable;
} fields_ProjectsOnto ;

/*
This relationship connects two protein sequences for which a clear
bidirectional best hit exists in known genomes. The attributes of the
relationship describe how good the relationship is between the proteins.
The relationship is bidirectional and symmetric, but is only stored in
one direction (lower ID to higher ID).
It has the following fields:

=over 4


=item gene_context

number of homologous genes in the immediate context of the
two proteins, up to a maximum of 10


=item percent_identity

percent match between the two protein sequences


=item score

score describing the strength of the projection, from 0 to 1,
where 1 is the best



=back


*/
funcdef get_relationship_ProjectsOnto(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_ProjectsOnto, fields_ProteinSequence>>);
funcdef get_relationship_IsProjectedOnto(list<string> ids, list<string> from_fields, list<string> rel_fields,  list<string> to_fields)
	returns(list<tuple<fields_ProteinSequence, fields_ProjectsOnto, fields_ProteinSequence>>);

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

};
