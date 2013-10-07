use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Media

=head1 SYNOPSIS

all_entities_Media [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Media entity.

A media describes the chemical content of the solution in which cells
are grown in an experiment or for the purposes of a model. The key is the
common media name. The nature of the media is described by its relationship
to its constituent compounds.

Example:

    all_entities_Media -a 

would retrieve all entities of type Media and include all fields
in the entities in the output.

=head2 Related entities

The Media entity has the following relationship links:

=over 4
    
=item HasPresenceOf Compound

=item IsUtilizedIn Experiment

=item UsedIn Environment


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Media [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item mod_date

date and time of the last modification to the media's definition

=item name

descriptive name of the media

=item is_minimal

TRUE if this is a minimal media, else FALSE

=item source_id

The ID of the media used by the data source.

=item type

The general category of the media.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'mod_date', 'name', 'is_minimal', 'source_id', 'type' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Media [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    mod_date
        date and time of the last modification to the media's definition
    name
        descriptive name of the media
    is_minimal
        TRUE if this is a minimal media, else FALSE
    source_id
        The ID of the media used by the data source.
    type
        The general category of the media.
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
	print STDERR "all_entities_Media: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Media($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Media($start, $count, \@fields);
}
