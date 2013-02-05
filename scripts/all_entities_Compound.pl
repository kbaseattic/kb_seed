use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Compound

=head1 SYNOPSIS

all_entities_Compound [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Compound entity.

A compound is a chemical that participates in a reaction. Both
ligands and reaction components are treated as compounds.

Example:

    all_entities_Compound -a 

would retrieve all entities of type Compound and include all fields
in the entities in the output.

=head2 Related entities

The Compound entity has the following relationship links:

=over 4
    
=item ComponentOf Compound

=item CompoundMeasuredBy Measurement

=item ConsistsOfCompounds Compound

=item IncludedIn Environment

=item IsPresentIn Media

=item IsShownOn Diagram

=item IsTerminusFor Scenario

=item ParticipatesAs LocalizedCompound

=item UsesAliasForCompound Source


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Compound [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item label

primary name of the compound, for use in displaying reactions

=item abbr

shortened abbreviation for the compound name

=item source_id

common modeling ID of this compound

=item ubiquitous

TRUE if this compound is found in most reactions, else FALSE

=item mod_date

date and time of the last modification to the compound definition

=item mass

pH-neutral atomic mass of the compound

=item formula

a pH-neutral formula for the compound

=item charge

computed charge of the compound in a pH-neutral solution

=item deltaG

the pH 7 reference Gibbs free-energy of formation for this compound as calculated by the group contribution method (units are kcal/mol)

=item deltaG_error

the uncertainty in the [b]deltaG[/b] value (units are kcal/mol)


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'label', 'abbr', 'source_id', 'ubiquitous', 'mod_date', 'mass', 'formula', 'charge', 'deltaG', 'deltaG_error' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Compound [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    label
        primary name of the compound, for use in displaying reactions
    abbr
        shortened abbreviation for the compound name
    source_id
        common modeling ID of this compound
    ubiquitous
        TRUE if this compound is found in most reactions, else FALSE
    mod_date
        date and time of the last modification to the compound definition
    mass
        pH-neutral atomic mass of the compound
    formula
        a pH-neutral formula for the compound
    charge
        computed charge of the compound in a pH-neutral solution
    deltaG
        the pH 7 reference Gibbs free-energy of formation for this compound as calculated by the group contribution method (units are kcal/mol)
    deltaG_error
        the uncertainty in the [b]deltaG[/b] value (units are kcal/mol)
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
	print STDERR "all_entities_Compound: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Compound($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Compound($start, $count, \@fields);
}
