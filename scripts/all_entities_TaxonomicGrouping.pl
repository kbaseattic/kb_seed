use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_TaxonomicGrouping

=head1 SYNOPSIS

all_entities_TaxonomicGrouping [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the TaxonomicGrouping entity.

We associate with most genomes a "taxonomy" based on
the NCBI taxonomy. This includes, for each genome, a list of
ever larger taxonomic groups. The groups are stored as
instances of this entity, and chained together by the
IsGroupFor relationship.

Example:

    all_entities_TaxonomicGrouping -a 

would retrieve all entities of type TaxonomicGrouping and include all fields
in the entities in the output.

=head2 Related entities

The TaxonomicGrouping entity has the following relationship links:

=over 4
    
=item IsGroupFor TaxonomicGrouping

=item IsInGroup TaxonomicGrouping

=item IsRepresentedBy ObservationalUnit

=item IsTaxonomyOf Genome


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_TaxonomicGrouping [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item domain

TRUE if this is a domain grouping, else FALSE.

=item hidden

TRUE if this is a hidden grouping, else FALSE. Hidden groupings are not typically shown in a lineage list.

=item scientific_name

Primary scientific name for this grouping. This is the name used when displaying a taxonomy.

=item alias

Alternate name for this grouping. A grouping may have many alternate names. The scientific name should also be in this list.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'domain', 'hidden', 'scientific_name', 'alias' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_TaxonomicGrouping [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    domain
        TRUE if this is a domain grouping, else FALSE.
    hidden
        TRUE if this is a hidden grouping, else FALSE. Hidden groupings are not typically shown in a lineage list.
    scientific_name
        Primary scientific name for this grouping. This is the name used when displaying a taxonomy.
    alias
        Alternate name for this grouping. A grouping may have many alternate names. The scientific name should also be in this list.
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
	print STDERR "all_entities_TaxonomicGrouping: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_TaxonomicGrouping($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_TaxonomicGrouping($start, $count, \@fields);
}
