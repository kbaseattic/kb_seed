use strict;
use Data::Dumper;

#
# This is a SAS Component
#


=head1 svr_current_annotation

Get the functional role, annotator and timestamp of the current
annotation for a protein-encoding gene or RNA.

------

Example:

    svr_all_features 3702.1 peg | svr_current_annotation

would produce a 4-column table for genes occurring in genome 3702.1: [ PEG, function, annotator, timestamp ]

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG for which functions are being requested.
If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with 3 extra columns added (the function associated with the PEG,
the annotator who made the assignment, and the timestamp of the
annotation).

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_current_annotation [-c column]";

my $column;
my $i = "-";
my $rc  = GetOptions('c=i' => \$column, 'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @ids = map { $_->[0] } @tuples;
    my ($annotations) = $sapObject->ids_to_annotations(-ids => \@ids);
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
        my ($function, $annotator, $timestamp) = @{$annotations->{$id}->[0]} if @{$annotations->{$id}};
        if ($function =~ /locked assignments to '(.*?)'/) {
            $function = $1;
        } else {
            $function = [split(/\n/, $function)]->[1];
        }
        # $function =~ s/^\s*Set FIG function to\s*//;
        # $function =~ s/^\s*Set function to\s*//;
        if (! defined $function) {
            print STDERR "$id not found.\n";
        } else {
            print join("\t", $line, $function, $annotator, $timestamp)."\n";
        }
    }
}
