use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Tree

=head1 SYNOPSIS

all_entities_Tree [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Tree entity.

A tree describes how the sequences in an alignment relate
to each other. Most trees are phylogenetic, but some may be based on
taxonomy or gene content.

Example:

    all_entities_Tree -a 

would retrieve all entities of type Tree and include all fields
in the entities in the output.

=head2 Related entities

The Tree entity has the following relationship links:

=over 4
    
=item HasNodeAttribute TreeNodeAttribute

=item HasTreeAttribute TreeAttribute

=item IsBuiltFromAlignment Alignment

=item IsModificationOfTree Tree

=item IsModifiedToBuildTree Tree

=item IsSupersededByTree Tree

=item IsTreeFrom Source

=item SupersedesTree Tree


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Tree [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item status

status of the tree, currently either [i]active[/i], [i]superseded[/i], or [i]bad[/i]

=item data_type

type of data the tree was built from, usually [i]sequence_alignment[/i]

=item timestamp

date and time the tree was loaded

=item method

name of the primary software package or script used to construct the tree

=item parameters

non-default parameters used as input to the software package or script indicated in the method attribute

=item protocol

description of the steps taken to construct the tree, or a reference to an external pipeline

=item source_id

ID of this tree in the source database

=item newick

NEWICK format string containing the structure of the tree


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'status', 'data_type', 'timestamp', 'method', 'parameters', 'protocol', 'source_id', 'newick' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Tree [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    status
        status of the tree, currently either [i]active[/i], [i]superseded[/i], or [i]bad[/i]
    data_type
        type of data the tree was built from, usually [i]sequence_alignment[/i]
    timestamp
        date and time the tree was loaded
    method
        name of the primary software package or script used to construct the tree
    parameters
        non-default parameters used as input to the software package or script indicated in the method attribute
    protocol
        description of the steps taken to construct the tree, or a reference to an external pipeline
    source_id
        ID of this tree in the source database
    newick
        NEWICK format string containing the structure of the tree
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
	print STDERR "all_entities_Tree: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Tree($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Tree($start, $count, \@fields);
}
