use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Platform

=head1 SYNOPSIS

all_entities_Platform [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Platform entity.

Platform that the expression sample/experiment was run on.

Example:

    all_entities_Platform -a 

would retrieve all entities of type Platform and include all fields
in the entities in the output.

=head2 Related entities

The Platform entity has the following relationship links:

=over 4
    
=item PlatformForStrain Strain

=item PlatformWithSamples Sample


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Platform [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

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

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'title', 'externalSourceId', 'technology', 'type', 'source_id' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Platform [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    title
        free text title of the comparison
    externalSourceId
        The externalSourceId gives users potentially an easy way to find the data of interest (ex:GPL514). This will keep them from having to do problematic likes on the source-id field.
    technology
        Ideally enumerated values, but may have to make this free text (spotted DNA/cDNA, spotted oligonucleotide, in situ oligonucleotide, antibody, tissue, SARST, RT-PCR, or MPSS).
    type
        Enumerated Microarray, RNA-Seq, qPCR
    source_id
        The ID used as the data source.
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
	print STDERR "all_entities_Platform: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Platform($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Platform($start, $count, \@fields);
}
