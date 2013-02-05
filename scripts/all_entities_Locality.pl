use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Locality

=head1 SYNOPSIS

all_entities_Locality [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Locality entity.

A locality is a geographic location.

Example:

    all_entities_Locality -a 

would retrieve all entities of type Locality and include all fields
in the entities in the output.

=head2 Related entities

The Locality entity has the following relationship links:

=over 4
    
=item HasUnits ObservationalUnit


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Locality [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item source_name

Name or description of the location used as a collection site.

=item city

City of the collecting site.

=item state

State or province of the collecting site.

=item country

Country of the collecting site.

=item origcty

3-letter ISO 3166-1 extended country code for the country of origin.

=item elevation

Elevation of the collecting site, expressed in meters above sea level.  Negative values are allowed.

=item latitude

Latitude of the collecting site, recorded as a decimal number.  North latitudes are positive values and south latitudes are negative numbers.

=item longitude

Longitude of the collecting site, recorded as a decimal number.  West longitudes are positive values and east longitudes are negative numbers.

=item lo_accession

gazeteer ontology term ID


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'source_name', 'city', 'state', 'country', 'origcty', 'elevation', 'latitude', 'longitude', 'lo_accession' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Locality [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    source_name
        Name or description of the location used as a collection site.
    city
        City of the collecting site.
    state
        State or province of the collecting site.
    country
        Country of the collecting site.
    origcty
        3-letter ISO 3166-1 extended country code for the country of origin.
    elevation
        Elevation of the collecting site, expressed in meters above sea level.  Negative values are allowed.
    latitude
        Latitude of the collecting site, recorded as a decimal number.  North latitudes are positive values and south latitudes are negative numbers.
    longitude
        Longitude of the collecting site, recorded as a decimal number.  West longitudes are positive values and east longitudes are negative numbers.
    lo_accession
        gazeteer ontology term ID
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
	print STDERR "all_entities_Locality: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Locality($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Locality($start, $count, \@fields);
}
