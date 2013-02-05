use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_CodonUsage

=head1 SYNOPSIS

all_entities_CodonUsage [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the CodonUsage entity.

This entity contains information about the codon usage
frequency in a particular genome with respect to a particular
type of analysis (e.g. high-expression genes, modal, mean,
etc.).

Example:

    all_entities_CodonUsage -a 

would retrieve all entities of type CodonUsage and include all fields
in the entities in the output.

=head2 Related entities

The CodonUsage entity has the following relationship links:

=over 4
    
=item AreCodonsFor Genome


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_CodonUsage [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

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

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'frequencies', 'genetic_code', 'type', 'subtype' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_CodonUsage [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    frequencies
        A packed-string representation of the codon usage frequencies. These are not global frequencies, but rather frequenicy of use relative to other codons that produce the same amino acid.
    genetic_code
        Genetic code used for these codons.
    type
        Type of frequency analysis: average, modal, high-expression, or non-native.
    subtype
        Specific nature of the codon usage with respect to the given type, generally indicative of how the frequencies were computed.
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
	print STDERR "all_entities_CodonUsage: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_CodonUsage($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_CodonUsage($start, $count, \@fields);
}
