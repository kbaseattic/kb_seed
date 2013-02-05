use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_AlleleFrequency

=head1 SYNOPSIS

all_entities_AlleleFrequency [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the AlleleFrequency entity.

An allele frequency represents a summary of the major and minor allele frequencies for a position on a chromosome.

Example:

    all_entities_AlleleFrequency -a 

would retrieve all entities of type AlleleFrequency and include all fields
in the entities in the output.

=head2 Related entities

The AlleleFrequency entity has the following relationship links:

=over 4
    
=item Summarizes Contig


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_AlleleFrequency [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

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

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'source_id', 'position', 'minor_AF', 'minor_allele', 'major_AF', 'major_allele', 'obs_unit_count' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_AlleleFrequency [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    source_id
        identifier for this allele in the original (source) database
    position
        Specific position on the contig where the allele occurs
    minor_AF
        Minor allele frequency.  Floating point number from 0.0 to 0.5.
    minor_allele
        Text letter representation of the minor allele. Valid values are A, C, G, and T.
    major_AF
        Major allele frequency.  Floating point number less than or equal to 1.0.
    major_allele
        Text letter representation of the major allele. Valid values are A, C, G, and T.
    obs_unit_count
        Number of observational units used to compute the allele frequencies. Indicates the quality of the analysis.
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
	print STDERR "all_entities_AlleleFrequency: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_AlleleFrequency($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_AlleleFrequency($start, $count, \@fields);
}
