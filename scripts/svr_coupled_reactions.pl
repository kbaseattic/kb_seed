use strict;

use Getopt::Long;
use ScriptThing;
use SAPserver;

#
# This is a SAS Component
#


=head1 svr_coupled_reactions

Takes as input a table containing reaction IDs and 
adds a column giving the "adjacent" reactions.

------
Example:

    svr_all_reactions | svr_coupled_reactions > table.with.coupled.reactions

would produce a 2-column table, each a pair of reaction IDs.  There would
be redundancy, since each pair of coupled reactions would show up twice.

------

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing reaction IDs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (a reaction that is part of the set that
are considered adjacent).  Note that this implies that there will
often be multiple output lines for a single input line.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_coupled_reactions [-c column]";

my $column;
my $rc  = GetOptions('c=i' => \$column);
if (! $rc) { print STDERR $usage; exit }

while (my @lines = ScriptThing::GetBatch(\*STDIN, 10, $column)) {
    my $coupledH = $sapObject->coupled_reactions( -ids => [map { $_->[0] } @lines] );
    for my $line (@lines) {
        my ($rxn, $text) = @$line;
        my @coupled = sort keys %{$coupledH->{$rxn}};
        for my $coupledRxn (@coupled) {
            print "$text\t$coupledRxn\n";
        }
    }
}

