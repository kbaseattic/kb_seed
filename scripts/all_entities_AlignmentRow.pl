use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_AlignmentRow

=head1 SYNOPSIS

all_entities_AlignmentRow [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the AlignmentRow entity.

This entity represents a single row of an alignment.
In general, this corresponds to a sequence, but in a
concatenated alignment multiple sequences may be represented
here.

Example:

    all_entities_AlignmentRow -a 

would retrieve all entities of type AlignmentRow and include all fields
in the entities in the output.

=head2 Related entities

The AlignmentRow entity has the following relationship links:

=over 4
    
=item ContainsAlignedDNA ContigSequence

=item ContainsAlignedProtein ProteinSequence

=item IsAlignmentRowIn Alignment


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_AlignmentRow [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item row_number

1-based ordinal number of this row in the alignment

=item row_id

identifier for this row in the FASTA file for the alignment

=item row_description

description of this row in the FASTA file for the alignment

=item n_components

number of components that make up this alignment row; for a single-sequence alignment this is always "1"

=item beg_pos_aln

the 1-based column index in the alignment where this sequence row begins

=item end_pos_aln

the 1-based column index in the alignment where this sequence row ends

=item md5_of_ungapped_sequence

the MD5 of this row's sequence after gaps have been removed; for DNA and RNA sequences, the [b]U[/b] codes are also normalized to [b]T[/b] before the MD5 is computed

=item sequence

sequence for this alignment row (with indels)


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'row_number', 'row_id', 'row_description', 'n_components', 'beg_pos_aln', 'end_pos_aln', 'md5_of_ungapped_sequence', 'sequence' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_AlignmentRow [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    row_number
        1-based ordinal number of this row in the alignment
    row_id
        identifier for this row in the FASTA file for the alignment
    row_description
        description of this row in the FASTA file for the alignment
    n_components
        number of components that make up this alignment row; for a single-sequence alignment this is always "1"
    beg_pos_aln
        the 1-based column index in the alignment where this sequence row begins
    end_pos_aln
        the 1-based column index in the alignment where this sequence row ends
    md5_of_ungapped_sequence
        the MD5 of this row's sequence after gaps have been removed; for DNA and RNA sequences, the [b]U[/b] codes are also normalized to [b]T[/b] before the MD5 is computed
    sequence
        sequence for this alignment row (with indels)
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
	print STDERR "all_entities_AlignmentRow: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_AlignmentRow($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_AlignmentRow($start, $count, \@fields);
}
