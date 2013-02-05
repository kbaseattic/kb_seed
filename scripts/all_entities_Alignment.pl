use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Alignment

=head1 SYNOPSIS

all_entities_Alignment [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Alignment entity.

An alignment arranges a group of sequences so that they
match. Each alignment is associated with a phylogenetic tree that
describes how the sequences developed and their evolutionary
distance.

Example:

    all_entities_Alignment -a 

would retrieve all entities of type Alignment and include all fields
in the entities in the output.

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

Usage: all_entities_Alignment [arguments] > entity.data

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

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'n_rows', 'n_cols', 'status', 'is_concatenation', 'sequence_type', 'timestamp', 'method', 'parameters', 'protocol', 'source_id' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Alignment [arguments] > entity.data

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
	print STDERR "all_entities_Alignment: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Alignment($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Alignment($start, $count, \@fields);
}
