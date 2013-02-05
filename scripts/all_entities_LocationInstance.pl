use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_LocationInstance

=head1 SYNOPSIS

all_entities_LocationInstance [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the LocationInstance entity.

The Location Instance represents a region of a cell
(e.g. cell wall, cytoplasm) as it appears in a specific
model.

Example:

    all_entities_LocationInstance -a 

would retrieve all entities of type LocationInstance and include all fields
in the entities in the output.

=head2 Related entities

The LocationInstance entity has the following relationship links:

=over 4
    
=item IsDivisionOf Model

=item IsInstanceOf Location

=item IsRealLocationOf CompoundInstance


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_LocationInstance [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item index

number used to distinguish between different instances of the same type of location in a single model. Within a model, any two instances of the same location must have difference compartment index values.

=item label

description used to differentiate between instances of the same location in a single model

=item pH

pH of the cell region, which is used to determine compound charge and pH gradient across cell membranes

=item potential

electrochemical potential of the cell region, which is used to determine the electrochemical gradient across cell membranes


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'index', 'label', 'pH', 'potential' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_LocationInstance [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    index
        number used to distinguish between different instances of the same type of location in a single model. Within a model, any two instances of the same location must have difference compartment index values.
    label
        description used to differentiate between instances of the same location in a single model
    pH
        pH of the cell region, which is used to determine compound charge and pH gradient across cell membranes
    potential
        electrochemical potential of the cell region, which is used to determine the electrochemical gradient across cell membranes
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
	print STDERR "all_entities_LocationInstance: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_LocationInstance($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_LocationInstance($start, $count, \@fields);
}
