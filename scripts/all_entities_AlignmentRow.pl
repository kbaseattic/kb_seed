use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 all_entities_AlignmentRow

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


=head2 Command-Line Options

=over 4

=item -a

Return all fields.

=item -h

Display a list of the fields available for use.

=item -fields field-list

Choose a set of fields to return. Field-list is a comma-separated list of 
strings. The following fields are available:

=over 4

=item row_number

=item row_id

=item row_description

=item n_components

=item beg_pos_aln

=item end_pos_aln

=item md5_of_ungapped_sequence

=item sequence

=back    
   
=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added for each requested field.  Input lines that cannot
be extended are written to stderr.  

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'row_number', 'row_id', 'row_description', 'n_components', 'beg_pos_aln', 'end_pos_aln', 'md5_of_ungapped_sequence', 'sequence' );
my %all_fields = map { $_ => 1 } @all_fields;

my $usage = "usage: all_entities_AlignmentRow [-show-fields] [-a | -f field list] > entity.data";

my $a;
my $f;
my @fields;
my $show_fields;
my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script("a" 		=> \$a,
								  "show-fields" => \$show_fields,
								  "h" 		=> \$show_fields,
								  "fields=s"    => \$f);

if ($show_fields)
{
    print STDERR "Available fields: @all_fields\n";
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
