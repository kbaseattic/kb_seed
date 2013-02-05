use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

get_entity_Tree

=head1 SYNOPSIS

get_entity_Tree [-c N] [-a] [--fields field-list] < ids > table.with.fields.added

=head1 DESCRIPTION

A tree describes how the sequences in an alignment relate
to each other. Most trees are phylogenetic, but some may be based on
taxonomy or gene content.

Example:

    get_entity_Tree -a < ids > table.with.fields.added

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

Usage: get_entity_Tree [arguments] < ids > table.with.fields.added

    -a		    Return all available fields.
    -c num          Select the identifier from column num.
    -i filename     Use filename rather than stdin for input.
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


our $usage = <<'END';
Usage: get_entity_Tree [arguments] < ids > table.with.fields.added

    -c num          Select the identifier from column num
    -i filename     Use filename rather than stdin for input
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



use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'status', 'data_type', 'timestamp', 'method', 'parameters', 'protocol', 'source_id', 'newick' );
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
	print STDERR "get_entity_Tree: unknown fields @err. Valid fields are: @all_fields\n";
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
    my $h = $geO->get_entity_Tree(\@h, \@fields);
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
