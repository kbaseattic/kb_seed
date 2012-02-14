use strict;
use SeedUtils;
use SAPserver;
use ScriptThing;

#
# This is a SAS Component
#


=head1 svr_role_to_complex

Extend a set of roles to include the triggered complexes

=head2 Introduction

Examples:

    svr_role_to_complex < table.with.roles.as.last.column > extended.table

=head2 Command-Line Arguments

=over 4

=item -c=Column

Specifies the column in the input table that is believed to contain the role.

=back

=head2 Output

A table with 1 added columnn containing complex IDs. Since some roles trigger
multiple complexes, there may be more output lines than input lines. Those roles
that do not trigger any reactions will be missing from the output.

=cut

use Getopt::Long;
my $usage = "svr_role_to_complex [-c Column] < table.with.roles > extended.table\n";

my $column;
my $url = '';
my $i = '-';

my $rc = GetOptions( 
                     "c=i" => \$column,
                     "url=s" => \$url,
                     "i=s" => \$i
                   );

$rc or print STDERR $usage and exit;

# Get the server object.
my $sapServer = SAPserver->new(url => $url);
# Open the input file.
open(my $ih, "<$i") or die "Could not open input: $!"; 
# The main loop processes chunks of input, 1000 lines at a time.
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    # Ask the server for the reactions.
    my $roleHash = $sapServer->roles_to_complexes(-ids => [map { $_->[0] } @tuples]);
    # Output the results for these roles.
    for my $tuple (@tuples) {
        # Get this line and the relevant role.
        my ($role, $line) = @$tuple;
        # Get this role's complexes.
        for my $cpx (@{$roleHash->{$role}}) {
            # Output the line with the complex ID appended.
            print "$line\t$cpx->[0]\n";
        }
    }
}
