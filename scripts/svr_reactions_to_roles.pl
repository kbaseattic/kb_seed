use strict;

use Getopt::Long;
use SeedUtils;
use ScriptThing;
use SAPserver;

#
# This is a SAS Component
#


=head1 svr_reactions_to_roles

Takes as input a table containing reaction IDs and 
adds a column giving the roles that implement the reactions

------
Example: svr_all_reactions | svr_reactions_to_roles > table.with.reactions.and.roles

would produce a 2-column table of reaction IDs and the roles that implement each reaction.

------

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing reaction IDs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (a role that is part of the set that
implements the reaction ID).  Note that this implies that there will
often be multiple output lines for a single input line.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_reactions_to_roles [-c column]";

my $column;
my $rc  = GetOptions('c=i' => \$column);
if (! $rc) { print STDERR $usage; exit }

while (my @lines = ScriptThing::GetBatch(\*STDIN, 10, $column)) {
    my @reactions = map { $_->[0] } @lines;
    my $reactionsH = $sapObject->reactions_to_roles( -ids => \@reactions );
    for my $line (@lines) {
        my ($rxn, $text) = @$line;
        my $roles = $reactionsH->{$rxn};
        for my $role (@$roles) {
            print "$text\t$role\n";
        }
    }
}

