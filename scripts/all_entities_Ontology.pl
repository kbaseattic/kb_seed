use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Ontology

=head1 SYNOPSIS

all_entities_Ontology [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Ontology entity.

-- Environmental Ontology. (ENVO Terms) http://environmentontology.org/  
-- Plant Ontology (PO Terms). http://www.plantontology.org/   
-- Plant Environmental Ontology (EO Terms). http://www.gramene.org/plant_ontology/index.html#eo
-- ENVO : http://envo.googlecode.com/svn/trunk/src/envo/envo-basic.obo
-- PO : http://palea.cgrb.oregonstate.edu/viewsvn/Poc/tags/live/plant_ontology.obo?view=co
-- EO : http://obo.cvs.sourceforge.net/viewvc/obo/obo/ontology/phenotype/environment/environment_ontology.obo


Example:

    all_entities_Ontology -a 

would retrieve all entities of type Ontology and include all fields
in the entities in the output.

=head2 Related entities

The Ontology entity has the following relationship links:

=over 4
    
=item OntologyForSample SampleAnnotation


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Ontology [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item id

Ontologgy ID.

=item name

Type of the ontology.

=item definition

Definition of the ontology

=item ontologySource

Enumerated value (ENVO, EO, PO).


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'id', 'name', 'definition', 'ontologySource' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Ontology [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    id
        Ontologgy ID.
    name
        Type of the ontology.
    definition
        Definition of the ontology
    ontologySource
        Enumerated value (ENVO, EO, PO).
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
	print STDERR "all_entities_Ontology: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Ontology($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Ontology($start, $count, \@fields);
}
