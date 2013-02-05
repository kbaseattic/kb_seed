use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

get_entity_Alignment

=head1 SYNOPSIS

get_entity_Alignment [-c N] [-a] [--fields field-list] < ids > table.with.fields.added

=head1 DESCRIPTION

An alignment arranges a group of sequences so that they
match. Each alignment is associated with a phylogenetic tree that
describes how the sequences developed and their evolutionary
distance.

Example:

    get_entity_Alignment -a < ids > table.with.fields.added

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

The Alignment entity has the following relationship links:

=over 4
    
=item HasAlignmentAttribute AlignmentAttribute

=item IncludesAlignmentRow AlignmentRow

=item IsModificationOfAlignment Alignment

=item IsModifiedToBuildAlignment Alignment

=item IsSupersededByAlignment Alignment

=item IsUsedToBuildTree Tree

=item SupersedesAlignment Alignment

=item WasAlignedBy Source


=back

=head1 COMMAND-LINE OPTIONS

Usage: get_entity_Alignment [arguments] < ids > table.with.fields.added

    -a		    Return all available fields.
    -c num          Select the identifier from column num.
    -i filename     Use filename rather than stdin for input.
    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item n_rows

number of rows in the alignment

=item n_cols

number of columns in the alignment

=item status

status of the alignment, currently either [i]active[/i], [i]superseded[/i], or [i]bad[/i]

=item is_concatenation

TRUE if the rows of the alignment map to multiple sequences, FALSE if they map to single sequences

=item sequence_type

type of sequence being aligned, currently either [i]Protein[/i], [i]DNA[/i], [i]RNA[/i], or [i]Mixed[/i]

=item timestamp

date and time the alignment was loaded

=item method

name of the primary software package or script used to construct the alignment

=item parameters

non-default parameters used as input to the software package or script indicated in the method attribute

=item protocol

description of the steps taken to construct the alignment, or a reference to an external pipeline

=item source_id

ID of this alignment in the source database


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = <<'END';
Usage: get_entity_Alignment [arguments] < ids > table.with.fields.added

    -c num          Select the identifier from column num
    -i filename     Use filename rather than stdin for input
    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    n_rows
        number of rows in the alignment
    n_cols
        number of columns in the alignment
    status
        status of the alignment, currently either [i]active[/i], [i]superseded[/i], or [i]bad[/i]
    is_concatenation
        TRUE if the rows of the alignment map to multiple sequences, FALSE if they map to single sequences
    sequence_type
        type of sequence being aligned, currently either [i]Protein[/i], [i]DNA[/i], [i]RNA[/i], or [i]Mixed[/i]
    timestamp
        date and time the alignment was loaded
    method
        name of the primary software package or script used to construct the alignment
    parameters
        non-default parameters used as input to the software package or script indicated in the method attribute
    protocol
        description of the steps taken to construct the alignment, or a reference to an external pipeline
    source_id
        ID of this alignment in the source database
END



use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'n_rows', 'n_cols', 'status', 'is_concatenation', 'sequence_type', 'timestamp', 'method', 'parameters', 'protocol', 'source_id' );
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
	print STDERR "get_entity_Alignment: unknown fields @err. Valid fields are: @all_fields\n";
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
    my $h = $geO->get_entity_Alignment(\@h, \@fields);
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
