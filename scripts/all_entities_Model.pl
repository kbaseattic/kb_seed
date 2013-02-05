use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Model

=head1 SYNOPSIS

all_entities_Model [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Model entity.

A model specifies a relationship between sets of features and
reactions in a cell. It is used to simulate cell growth and gene
knockouts to validate annotations.

Example:

    all_entities_Model -a 

would retrieve all entities of type Model and include all fields
in the entities in the output.

=head2 Related entities

The Model entity has the following relationship links:

=over 4
    
=item HasRequirementOf ReactionInstance

=item IsDividedInto LocationInstance

=item Manages Biomass

=item Models Genome


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Model [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item mod_date

date and time of the last change to the model data

=item name

descriptive name of the model

=item version

revision number of the model

=item type

string indicating where the model came from (e.g. single genome, multiple genome, or community model)

=item status

indicator of whether the model is stable, under construction, or under reconstruction

=item reaction_count

number of reactions in the model

=item compound_count

number of compounds in the model

=item annotation_count

number of features associated with one or more reactions in the model


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'mod_date', 'name', 'version', 'type', 'status', 'reaction_count', 'compound_count', 'annotation_count' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Model [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    mod_date
        date and time of the last change to the model data
    name
        descriptive name of the model
    version
        revision number of the model
    type
        string indicating where the model came from (e.g. single genome, multiple genome, or community model)
    status
        indicator of whether the model is stable, under construction, or under reconstruction
    reaction_count
        number of reactions in the model
    compound_count
        number of compounds in the model
    annotation_count
        number of features associated with one or more reactions in the model
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
	print STDERR "all_entities_Model: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Model($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Model($start, $count, \@fields);
}
