use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

get_entity_Strain

=head1 SYNOPSIS

get_entity_Strain [-c N] [-a] [--fields field-list] < ids > table.with.fields.added

=head1 DESCRIPTION

This entity represents an organism derived from a genome or
another organism with one or more modifications to the organism's
genome.

Example:

    get_entity_Strain -a < ids > table.with.fields.added

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

The Strain entity has the following relationship links:

=over 4
    
=item DerivedFromGenome Genome

=item DerivedFromStrain Strain

=item EvaluatedIn ExperimentalUnit

=item HasKnockoutIn Feature

=item StrainParentOf Strain

=item StrainWithPlatforms Platform

=item StrainWithSample Sample


=back

=head1 COMMAND-LINE OPTIONS

Usage: get_entity_Strain [arguments] < ids > table.with.fields.added

    -a		    Return all available fields.
    -c num          Select the identifier from column num.
    -i filename     Use filename rather than stdin for input.
    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item name

The common or laboratory name of the strain, e.g. DH5a or JMP1004.

=item description

A description of the strain, e.g. knockout/modification methods, resulting phenotypes, etc.

=item source_id

The ID of the strain used by the data source.

=item aggregateData

Denotes whether this entity represents a physical strain (False) or aggregate data calculated from one or more strains (True).

=item wildtype

Denotes this strain is presumably identical to the parent genome.

=item referenceStrain

Denotes whether this strain is a reference strain; e.g. it is identical to the genome it's related to (True) or not (False). In contrast to wildtype, a referenceStrain is abstract and does not physically exist and is used for data that refers to a genome but not a particular strain. There should only exist one reference strain per genome and all reference strains are wildtype. 


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = <<'END';
Usage: get_entity_Strain [arguments] < ids > table.with.fields.added

    -c num          Select the identifier from column num
    -i filename     Use filename rather than stdin for input
    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    name
        The common or laboratory name of the strain, e.g. DH5a or JMP1004.
    description
        A description of the strain, e.g. knockout/modification methods, resulting phenotypes, etc.
    source_id
        The ID of the strain used by the data source.
    aggregateData
        Denotes whether this entity represents a physical strain (False) or aggregate data calculated from one or more strains (True).
    wildtype
        Denotes this strain is presumably identical to the parent genome.
    referenceStrain
        Denotes whether this strain is a reference strain; e.g. it is identical to the genome it's related to (True) or not (False). In contrast to wildtype, a referenceStrain is abstract and does not physically exist and is used for data that refers to a genome but not a particular strain. There should only exist one reference strain per genome and all reference strains are wildtype. 
END



use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'name', 'description', 'source_id', 'aggregateData', 'wildtype', 'referenceStrain' );
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
	print STDERR "get_entity_Strain: unknown fields @err. Valid fields are: @all_fields\n";
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
    my $h = $geO->get_entity_Strain(\@h, \@fields);
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
