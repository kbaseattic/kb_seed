use strict;

use Getopt::Long;
use SeedEnv;

#
# This is a SAS Component
#


=head1 svr_all_roles_used_in_models

List the roles used in the existing metabolic models.

There is no input.  The output is 1-column table containing
role names.

------
Example:

    svr_all_roles_used_in_models > role.table

would produce a file of role IDs, one per line.
------

=back

=head2 Output Format

The standard output is a file where each line contains a role name.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();

my $roleL = $sapObject->all_roles_used_in_models;

foreach my $role (sort @$roleL) {
    print "$role\n";
}

