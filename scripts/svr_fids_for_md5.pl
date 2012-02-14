use strict;

use Getopt::Long;
use ScriptThing;
use SAPserver;

#
# This is a SAS Component
#


=head1 svr_fids_for_md5

Given a set of md5 protein IDs, compute the FIG IDs of features that produce each
protein. This script takes as input a table containing md5 protein IDs and 
adds a column containing the associated FIG feature IDs.

------
Example:

    svr_fids_for_md5 < md5_file > md5_file_with_fids

------

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing md5 protein IDs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the ID of a feature that produces the
specified protein).  Note that this implies that there will
often be multiple output lines for a single input line.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_fids_for_md5 [-c column]";

my $column;
my $rc  = GetOptions('c=i' => \$column);
if (! $rc) { print STDERR $usage; exit }
my $inFile = $ARGV[0] || '-';
open my $ih, "<$inFile";

while (my @lines = ScriptThing::GetBatch($ih, 1000, $column)) {
    my $md5H = $sapObject->proteins_to_fids(-prots => [map { $_->[0] } @lines] );
    for my $line (@lines) {
        my ($md5, $text) = @$line;
        my $fids = $md5H->{$md5};
        for my $fid (@$fids) {
            print "$text\t$fid\n";
        }
    }
}

