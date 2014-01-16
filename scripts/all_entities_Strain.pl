use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Strain

=head1 SYNOPSIS

all_entities_Strain [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Strain entity.

This entity represents an organism derived from a genome or
another organism with one or more modifications to the organism's
genome.

Example:

    all_entities_Strain -a 

would retrieve all entities of type Strain and include all fields
in the entities in the output.

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

Usage: all_entities_Strain [arguments] > entity.data

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

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'name', 'description', 'source_id', 'aggregateData', 'wildtype', 'referenceStrain' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Strain [arguments] > entity.data

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
	print STDERR "all_entities_Strain: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Strain($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Strain($start, $count, \@fields);
}
