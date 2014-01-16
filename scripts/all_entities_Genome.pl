use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Genome

=head1 SYNOPSIS

all_entities_Genome [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Genome entity.

The Kbase houses a large and growing set of genomes.  We
often have multiple genomes that have identical DNA.  These usually
have distinct gene calls and annotations, but not always.  We
consider the Kbase to be a framework for managing hundreds of
thousands of genomes and offering the tools needed to
support compartive analysis on large sets of genomes,
some of which are virtually identical.

Example:

    all_entities_Genome -a 

would retrieve all entities of type Genome and include all fields
in the entities in the output.

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

Usage: all_entities_Genome [arguments] > entity.data

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

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'pegs', 'rnas', 'scientific_name', 'complete', 'prokaryotic', 'dna_size', 'contigs', 'domain', 'genetic_code', 'gc_content', 'phenotype', 'md5', 'source_id' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Genome [arguments] > entity.data

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


my $a;
my $f;
my @fields;
my $show_fields;
my $help;
my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script("a" 		=> \$a,
								  "show-fields" => \$show_fields,
								  "h" 		=> \$help,
								  "fields=s"    => \$f);

if ($help)
{
    print $usage;
    exit 0;
}

if ($show_fields)
{
    print "Available fields:\n";
    print "\t$_\n" foreach @all_fields;
    exit 0;
}

if (@ARGV != 0 || ($a && $f))
{
    print STDERR $usage, "\n";
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
	print STDERR "all_entities_Genome: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Genome($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Genome($start, $count, \@fields);
}
