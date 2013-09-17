use strict;
use SeedUtils;
use SAPserver;
use ScriptThing;

#
# This is a SAS Component
#


=head1 svr_roles_to_reactions

Extend a set of roles to include the associated reactions

=head2 Introduction

Examples:

    svr_roles_to_reactions < table.with.roles.as.last.column > extended.table

=head2 Command-Line Arguments

=over 4

=item -c=Column

Specifies the column in the input table that is believed to contain the role.

=back

=head2 Output

A table with 1 added columnn containing reactions IDs. Since some roles trigger
multiple reactions, there may be more output lines than input lines. Those roles
that do not trigger any reactions will be missing from the output.

=cut

use Getopt::Long;
my $usage = "svr_roles_to_reactions [-c Column] < table.with.roles > extended.table\n";

my $column;
my $url = '';

my $rc = GetOptions( 
                     "c=i" => \$column,
                     "url=s" => \$url
                   );

$rc or print STDERR $usage and exit;

# Get the server object.
my $sapServer = SAPserver->new(url => $url);
# The main loop processes chunks of input, 1000 lines at a time.
while (my @tuples = ScriptThing::GetBatch(\*STDIN, undef, $column)) {
    # Ask the server for the reactions.
    my $roleHash = $sapServer->role_reactions(-ids => [map { $_->[0] } @tuples]);
    # Output the results for these roles.
    for my $tuple (@tuples) {
        # Get this line and the relevant role.
        my ($role, $line) = @$tuple;
        # Get this role's reactions.
        for my $reaction (@{$roleHash->{$role}}) {
            # Output the line with the subsystem and classification appended.
            print "$line\t$reaction\n";
        }
    }
}
