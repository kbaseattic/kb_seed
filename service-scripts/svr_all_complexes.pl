use strict;

use Getopt::Long;
use SeedEnv;

#
# This is a SAS Component
#


=head1 svr_all_complexes

List the reaction complexes in the database.

There is no input.  The output is 1-column table containing
complex IDs.

------
Example:

    svr_all_complexes > complex.table

would produce a file of complex IDs, one per line.
------

=back

=head2 Output Format

The standard output is a file where each line contains a complex ID.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();

my $cpxL = $sapObject->all_complexes;

foreach my $cpx (sort @$cpxL) {
    print "$cpx\n";
}

