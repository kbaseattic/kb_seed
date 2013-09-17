use strict;
use SeedUtils;
use SAPserver;
use ScriptThing;

#
# This is a SAS Component
#


=head1 svr_complex_to_reaction

Extend a set of complexes to include the associated reactions

=head2 Introduction

Examples:

    svr_complex_to_reaction < table.with.complexes.as.last.column > extended.table

=head2 Command-Line Arguments

=over 4

=item -c=Column

Specifies the column in the input table that is believed to contain the complex
ID.

=back

=head2 Output

A table with 1 added columnn containing reactions IDs. Since most complexes
contain multiple reactions, there will be more output lines than input lines.

=cut

use Getopt::Long;
my $usage = "svr_complex_to_reaction [-c Column] < table.with.complexes > extended.table\n";

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
    my $cpxHash = $sapServer->complex_data(-ids => [map { $_->[0] } @tuples],
                                           -data => ['reactions']);
    # Output the results for these complexes.
    for my $tuple (@tuples) {
        # Get this line and the relevant role.
        my ($cpx, $line) = @$tuple;
        # Get this role's reactions.
        my $data = $cpxHash->{$cpx};
        if ($data) {
            # Here some reactions were found.
            for my $reaction (@{$data->[0]}) {
                # Output the line with the reaction appended.
                print "$line\t$reaction\n";
            }
        }
    }
}
