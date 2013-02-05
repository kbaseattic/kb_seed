use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

get_entity_Reaction

=head1 SYNOPSIS

get_entity_Reaction [-c N] [-a] [--fields field-list] < ids > table.with.fields.added

=head1 DESCRIPTION

A reaction is a chemical process that converts one set of
compounds (substrate) to another set (products).

Example:

    get_entity_Reaction -a < ids > table.with.fields.added

would read in a file of ids and add a column for each field in the entity.

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the id. If some other column contains the id,
use

    -c N

where N is the column (from 1) that contains the id.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

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

Usage: get_entity_Reaction [arguments] < ids > table.with.fields.added

    -a		    Return all available fields.
    -c num          Select the identifier from column num.
    -i filename     Use filename rather than stdin for input.
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


our $usage = <<'END';
Usage: get_entity_Reaction [arguments] < ids > table.with.fields.added

    -c num          Select the identifier from column num
    -i filename     Use filename rather than stdin for input
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



use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'mod_date', 'name', 'source_id', 'abbr', 'direction', 'deltaG', 'deltaG_error', 'thermodynamic_reversibility', 'default_protons', 'status' );
my %all_fields = map { $_ => 1 } @all_fields;

my $column;
my $a;
my $f;
my $i = "-";
my @fields;
my $help;
my $show_fields;
my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script('c=i'		 => \$column,
								  "all-fields|a" => \$a,
								  "help|h"	 => \$help,
								  "show-fields"	 => \$show_fields,
								  "fields=s"	 => \$f,
								  'i=s'		 => \$i);
if ($help)
{
    print $usage;
    exit 0;
}

if ($show_fields)
{
    print STDERR "Available fields:\n";
    print STDERR "\t$_\n" foreach @all_fields;
    exit 0;
}

if ($a && $f) 
{
    print STDERR "Only one of the -a and --fields options may be specified\n";
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
	print STDERR "get_entity_Reaction: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
} else {
    print STDERR $usage;
    exit 1;
}

my $ih;
if ($i eq '-')
{
    $ih = \*STDIN;
}
else
{
    open($ih, "<", $i) or die "Cannot open input file $i: $!\n";
}

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $geO->get_entity_Reaction(\@h, \@fields);
    for my $tuple (@tuples) {
        my @values;
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};
	if (! defined($v))
	{
	    #nothing found for this id
	    print STDERR $line,"\n";
     	} else {
	    foreach $_ (@fields) {
		my $val = $v->{$_};
		push (@values, ref($val) eq 'ARRAY' ? join(",", @$val) : $val);
	    }
	    my $tail = join("\t", @values);
	    print "$line\t$tail\n";
        }
    }
}
__DATA__
