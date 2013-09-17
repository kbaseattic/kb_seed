use strict;

use Getopt::Long;
use SeedEnv;

#
# This is a SAS Component
#


=head1 svr_all_reactions

List the reactions IDs

There is no input.  The output is a file of reaction IDs

------
Example:

    svr_all_reactions > reaction.table

would produce a 1-column table of reaction IDs.
------

=back

=head2 Output Format

The standard output is a file where each line contains a reaction ID.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();

my $reactions = $sapObject->all_reactions();
for my $reaction (@$reactions) {
    print "$reaction\n";
}
