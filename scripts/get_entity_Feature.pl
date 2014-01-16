use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

get_entity_Feature

=head1 SYNOPSIS

get_entity_Feature [-c N] [-a] [--fields field-list] < ids > table.with.fields.added

=head1 DESCRIPTION

A feature (sometimes also called a gene) is a part of a
genome that is of special interest. Features may be spread across
multiple DNA sequences (contigs) of a genome, but never across more
than one genome. Each feature in the database has a unique
ID that functions as its ID in this table. Normally a Feature is
just a single contigous region on a contig. Features have types,
and an appropriate choice of available types allows the support
of protein-encoding genes, exons, RNA genes, binding sites,
pathogenicity islands, or whatever.

Example:

    get_entity_Feature -a < ids > table.with.fields.added

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

The Feature entity has the following relationship links:

=over 4
    
=item Controls CoregulatedSet

=item Encompasses Feature

=item FeatureInteractsIn Association

=item FeatureIsTranscriptionFactorFor Regulon

=item FeatureMeasuredBy Measurement

=item HasAliasAssertedFrom Source

=item HasCoregulationWith Feature

=item HasFunctional Role

=item HasIndicatedSignalFrom Experiment

=item HasLevelsFrom ProbeSet

=item ImplementsReaction ReactionInstance

=item IsAnnotatedBy Annotation

=item IsContainedIn SSCell

=item IsCoregulatedWith Feature

=item IsEncompassedIn Feature

=item IsExemplarOf Role

=item IsFormedInto AtomicRegulon

=item IsInOperon Operon

=item IsInPair Pairing

=item IsLocatedIn Contig

=item IsMemberOf Family

=item IsOwnedBy Genome

=item IsRegulatedIn CoregulatedSet

=item IsRegulatorySiteFor Operon

=item KnockedOutIn Strain

=item Produces ProteinSequence


=back

=head1 COMMAND-LINE OPTIONS

Usage: get_entity_Feature [arguments] < ids > table.with.fields.added

    -a		    Return all available fields.
    -c num          Select the identifier from column num.
    -i filename     Use filename rather than stdin for input.
    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item feature_type

Code indicating the type of this feature. Among the codes currently supported are "peg" for a protein encoding gene, "bs" for a binding site, "opr" for an operon, and so forth.

=item source_id

ID for this feature in its original source (core) database

=item sequence_length

Number of base pairs in this feature.

=item function

Functional assignment for this feature. This will often indicate the feature's functional role or roles, and may also have comments.

=item alias

alternative identifier for the feature. These are highly unstructured, and frequently non-unique.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = <<'END';
Usage: get_entity_Feature [arguments] < ids > table.with.fields.added

    -c num          Select the identifier from column num
    -i filename     Use filename rather than stdin for input
    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    feature_type
        Code indicating the type of this feature. Among the codes currently supported are "peg" for a protein encoding gene, "bs" for a binding site, "opr" for an operon, and so forth.
    source_id
        ID for this feature in its original source (core) database
    sequence_length
        Number of base pairs in this feature.
    function
        Functional assignment for this feature. This will often indicate the feature's functional role or roles, and may also have comments.
    alias
        alternative identifier for the feature. These are highly unstructured, and frequently non-unique.
END



use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'feature_type', 'source_id', 'sequence_length', 'function', 'alias' );
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
	print STDERR "get_entity_Feature: unknown fields @err. Valid fields are: @all_fields\n";
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
    my $h = $geO->get_entity_Feature(\@h, \@fields);
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
