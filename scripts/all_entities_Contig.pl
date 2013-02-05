use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Contig

=head1 SYNOPSIS

all_entities_Contig [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Contig entity.

A contig is thought of as composing a part of the DNA
associated with a specific genome.  It is represented as an ID
(including the genome ID) and a ContigSequence. We do not think
of strings of DNA from, say, a metgenomic sample as "contigs",
since there is no associated genome (these would be considered
ContigSequences). This use of the term "ContigSequence", rather
than just "DNA sequence", may turn out to be a bad idea.  For now,
you should just realize that a Contig has an associated
genome, but a ContigSequence does not.

Example:

    all_entities_Contig -a 

would retrieve all entities of type Contig and include all fields
in the entities in the output.

=head2 Related entities

The Contig entity has the following relationship links:

=over 4
    
=item HasAsSequence ContigSequence

=item HasVariationIn ObservationalUnit

=item IsComponentOf Genome

=item IsImpactedBy Trait

=item IsLocusFor Feature

=item IsSummarizedBy AlleleFrequency


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Contig [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item source_id

ID of this contig from the core (source) database


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'source_id' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Contig [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    source_id
        ID of this contig from the core (source) database
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
	print STDERR "all_entities_Contig: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Contig($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Contig($start, $count, \@fields);
}
