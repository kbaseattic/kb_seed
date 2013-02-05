use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Reaction

=head1 SYNOPSIS

all_entities_Reaction [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Reaction entity.

A reaction is a chemical process that converts one set of
compounds (substrate) to another set (products).

Example:

    all_entities_Reaction -a 

would retrieve all entities of type Reaction and include all fields
in the entities in the output.

=head2 Related entities

The Reaction entity has the following relationship links:

=over 4
    
=item Involves LocalizedCompound

=item IsDisplayedOn Diagram

=item IsExecutedAs ReactionInstance

=item IsStepOf Complex

=item ParticipatesIn Scenario

=item UsesAliasForReaction Source


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Reaction [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item mod_date

date and time of the last modification to this reaction's definition

=item name

descriptive name of this reaction

=item source_id

ID of this reaction in the resource from which it was added

=item abbr

abbreviated name of this reaction

=item direction

direction of this reaction (> for forward-only, < for backward-only, = for bidirectional)

=item deltaG

Gibbs free-energy change for the reaction calculated using the group contribution method (units are kcal/mol)

=item deltaG_error

uncertainty in the [b]deltaG[/b] value (units are kcal/mol)

=item thermodynamic_reversibility

computed reversibility of this reaction in a pH-neutral environment

=item default_protons

number of protons absorbed by this reaction in a pH-neutral environment

=item status

string indicating additional information about this reaction, generally indicating whether the reaction is balanced and/or lumped


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'mod_date', 'name', 'source_id', 'abbr', 'direction', 'deltaG', 'deltaG_error', 'thermodynamic_reversibility', 'default_protons', 'status' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Reaction [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    mod_date
        date and time of the last modification to this reaction's definition
    name
        descriptive name of this reaction
    source_id
        ID of this reaction in the resource from which it was added
    abbr
        abbreviated name of this reaction
    direction
        direction of this reaction (> for forward-only, < for backward-only, = for bidirectional)
    deltaG
        Gibbs free-energy change for the reaction calculated using the group contribution method (units are kcal/mol)
    deltaG_error
        uncertainty in the [b]deltaG[/b] value (units are kcal/mol)
    thermodynamic_reversibility
        computed reversibility of this reaction in a pH-neutral environment
    default_protons
        number of protons absorbed by this reaction in a pH-neutral environment
    status
        string indicating additional information about this reaction, generally indicating whether the reaction is balanced and/or lumped
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
	print STDERR "all_entities_Reaction: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Reaction($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Reaction($start, $count, \@fields);
}
