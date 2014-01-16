use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

get_entity_Genome

=head1 SYNOPSIS

get_entity_Genome [-c N] [-a] [--fields field-list] < ids > table.with.fields.added

=head1 DESCRIPTION

The Kbase houses a large and growing set of genomes.  We
often have multiple genomes that have identical DNA.  These usually
have distinct gene calls and annotations, but not always.  We
consider the Kbase to be a framework for managing hundreds of
thousands of genomes and offering the tools needed to
support compartive analysis on large sets of genomes,
some of which are virtually identical.

Example:

    get_entity_Genome -a < ids > table.with.fields.added

would read in a file of ids and add a column for each field in the entity.

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the id. If some other column contains the id,
use

    -c N

where N is the column (from 1) that contains the id.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Related entities

The Genome entity has the following relationship links:

=over 4
    
=item GenomeIsInRegulome Regulome

=item GenomeParentOf Strain

=item HadResultsProducedBy ProbeSet

=item HasAssociationDataset AssociationDataset

=item HasRepresentativeOf Family

=item IsCollectedInto OTU

=item IsComposedOf Contig

=item IsConfiguredBy AtomicRegulon

=item IsInRegulogCollection RegulogCollection

=item IsInTaxa TaxonomicGrouping

=item IsModeledBy Model

=item IsOwnerOf Feature

=item IsReferencedBy ObservationalUnit

=item Uses SSRow

=item UsesCodons CodonUsage

=item WasSubmittedBy Source


=back

=head1 COMMAND-LINE OPTIONS

Usage: get_entity_Genome [arguments] < ids > table.with.fields.added

    -a		    Return all available fields.
    -c num          Select the identifier from column num.
    -i filename     Use filename rather than stdin for input.
    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

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

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = <<'END';
Usage: get_entity_Genome [arguments] < ids > table.with.fields.added

    -c num          Select the identifier from column num
    -i filename     Use filename rather than stdin for input
    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    pegs
        Number of protein encoding genes for this genome.
    rnas
        Number of RNA features found for this organism.
    scientific_name
        Full genus/species/strain name of the genome sequence.
    complete
        TRUE if the genome sequence is complete, else FALSE
    prokaryotic
        TRUE if this is a prokaryotic genome sequence, else FALSE
    dna_size
        Number of base pairs in the genome sequence.
    contigs
        Number of contigs for this genome sequence.
    domain
        Domain for this organism (Archaea, Bacteria, Eukaryota, Virus, Plasmid, or Environmental Sample).
    genetic_code
        Genetic code number used for protein translation on most of this genome sequence's contigs.
    gc_content
        Percent GC content present in the genome sequence's DNA.
    phenotype
        zero or more strings describing phenotypic information about this genome sequence
    md5
        MD5 identifier describing the genome's DNA sequence
    source_id
        identifier assigned to this genome by the original source
END



use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'pegs', 'rnas', 'scientific_name', 'complete', 'prokaryotic', 'dna_size', 'contigs', 'domain', 'genetic_code', 'gc_content', 'phenotype', 'md5', 'source_id' );
my %all_fields = map { $_ => 1 } @all_fields;

my $column;
my $a;
my $f;
my $i = "-";
my @fields;
my $help;
my $show_fields;
my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script('c=i'		 => \$column,
								  "all-fields|a" => \$a,
								  "help|h"	 => \$help,
								  "show-fields"	 => \$show_fields,
								  "fields=s"	 => \$f,
								  'i=s'		 => \$i);
if ($help)
{
    print $usage;
    exit 0;
}

if ($show_fields)
{
    print STDERR "Available fields:\n";
    print STDERR "\t$_\n" foreach @all_fields;
    exit 0;
}

if ($a && $f) 
{
    print STDERR "Only one of the -a and --fields options may be specified\n";
    exit 1;
} 
if ($a)
{
    @fields = @all_fields;
}
elsif ($f) {
    my @err;
    for my $field (split(",", $f))
    {
	if (!$all_fields{$field})
	{
	    push(@err, $field);
	}
	else
	{
	    push(@fields, $field);
	}
    }
    if (@err)
    {
	print STDERR "get_entity_Genome: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
} else {
    print STDERR $usage;
    exit 1;
}

my $ih;
if ($i eq '-')
{
    $ih = \*STDIN;
}
else
{
    open($ih, "<", $i) or die "Cannot open input file $i: $!\n";
}

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $geO->get_entity_Genome(\@h, \@fields);
    for my $tuple (@tuples) {
        my @values;
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};
	if (! defined($v))
	{
	    #nothing found for this id
	    print STDERR $line,"\n";
     	} else {
	    foreach $_ (@fields) {
		my $val = $v->{$_};
		push (@values, ref($val) eq 'ARRAY' ? join(",", @$val) : $val);
	    }
	    my $tail = join("\t", @values);
	    print "$line\t$tail\n";
        }
    }
}
__DATA__
