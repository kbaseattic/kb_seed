use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Feature

=head1 SYNOPSIS

all_entities_Feature [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Feature entity.

A feature (sometimes also called a gene) is a part of a
genome that is of special interest. Features may be spread across
multiple DNA sequences (contigs) of a genome, but never across more
than one genome. Each feature in the database has a unique
ID that functions as its ID in this table. Normally a Feature is
just a single contigous region on a contig. Features have types,
and an appropriate choice of available types allows the support
of protein-encoding genes, exons, RNA genes, binding sites,
pathogenicity islands, or whatever.

Example:

    all_entities_Feature -a 

would retrieve all entities of type Feature and include all fields
in the entities in the output.

=head2 Related entities

The Feature entity has the following relationship links:

=over 4
    
=item Controls CoregulatedSet

=item Encompasses Feature

=item FeatureInteractsIn Association

=item FeatureIsTranscriptionFactorFor Regulon

=item FeatureMeasuredBy Measurement

=item HasAliasAssertedFrom Source

=item HasCoregulationWith Feature

=item HasFunctional Role

=item HasIndicatedSignalFrom Experiment

=item HasLevelsFrom ProbeSet

=item ImplementsReaction ReactionInstance

=item IsAnnotatedBy Annotation

=item IsContainedIn SSCell

=item IsCoregulatedWith Feature

=item IsEncompassedIn Feature

=item IsExemplarOf Role

=item IsFormedInto AtomicRegulon

=item IsInOperon Operon

=item IsInPair Pairing

=item IsLocatedIn Contig

=item IsMemberOf Family

=item IsOwnedBy Genome

=item IsRegulatedIn CoregulatedSet

=item IsRegulatorySiteFor Operon

=item KnockedOutIn Strain

=item Produces ProteinSequence


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Feature [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

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

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'feature_type', 'source_id', 'sequence_length', 'function', 'alias' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Feature [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    feature_type
        Code indicating the type of this feature. Among the codes currently supported are "peg" for a protein encoding gene, "bs" for a binding site, "opr" for an operon, and so forth.
    source_id
        ID for this feature in its original source (core) database
    sequence_length
        Number of base pairs in this feature.
    function
        Functional assignment for this feature. This will often indicate the feature's functional role or roles, and may also have comments.
    alias
        alternative identifier for the feature. These are highly unstructured, and frequently non-unique.
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
	print STDERR "all_entities_Feature: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Feature($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Feature($start, $count, \@fields);
}
