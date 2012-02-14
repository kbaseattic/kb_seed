use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_genome_of

Get genome of feature

------

Example:

    svr_all_features 3702.1 peg | svr_genome_of

would produce a 2-column table.  The first column would contain
PEG IDs for genes occurring in genome 3702.1, and the second
would contain 3702.1 (a pretty poor example, I grant)

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
file with an extra column added (the genome of the feature)

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_genome_of [-c column]";

my $column;
my $i = "-";
my $rc  = GetOptions('c=i' => \$column, 
		     'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
        my $genome = &SeedUtils::genome_of($id);
	print "$line\t$genome\n";
    }
}
