use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_SSRow

=head1 SYNOPSIS

all_entities_SSRow [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the SSRow entity.

An SSRow (that is, a row in a subsystem spreadsheet)
represents a collection of functional roles present in the
Features of a single Genome.  The roles are part of a designated
subsystem, and the features associated with each role are included
in the row. That is, a row amounts to an instance of a subsystem as
it exists in a specific, designated genome.

Example:

    all_entities_SSRow -a 

would retrieve all entities of type SSRow and include all fields
in the entities in the output.

=head2 Related entities

The SSRow entity has the following relationship links:

=over 4
    
=item Implements Variant

=item IsRowOf SSCell

=item IsUsedBy Genome


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_SSRow [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item curated

This flag is TRUE if the assignment of the molecular machine has been curated, and FALSE if it was made by an automated program.

=item region

Region in the genome for which the row is relevant. Normally, this is an empty string, indicating that the machine covers the whole genome. If a subsystem has multiple rows for a genome, this contains a location string describing the region occupied by this particular row.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'curated', 'region' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_SSRow [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    curated
        This flag is TRUE if the assignment of the molecular machine has been curated, and FALSE if it was made by an automated program.
    region
        Region in the genome for which the row is relevant. Normally, this is an empty string, indicating that the machine covers the whole genome. If a subsystem has multiple rows for a genome, this contains a location string describing the region occupied by this particular row.
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
	print STDERR "all_entities_SSRow: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_SSRow($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_SSRow($start, $count, \@fields);
}
