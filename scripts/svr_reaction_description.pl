use strict;
use SAPserver;
use SeedUtils;
use ScriptThing;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_reaction_description [-r ReactionID] [-c Column]

This simple utility gives the reaction associated with reaction IDs. 

------

Examples:

    svr_reaction_description -r rxn02270

would produce a single line containing a text expansion of the reaction, while

    svr_reaction_description -c 2 < tab.delimited.table > with.added.description

would take as input a table in which the second column contains reaction IDs, and an extra
column is added to the output.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain a reaction ID.

If some other column contains the reaction IDs, use

    -c N

where N is the column (from 1) that contains the reaction IDs.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.


=head2 Command-Line Options

=over 4

=item -c N

Specifies which column in the input table that contains the reaction IDs.  Defaults
to the last column in the input file.

=item -r reactionID

If specified, then the specified reaction ID will be used instead of reading the IDs
from the input stream.

=item -o

If specified, then the roles that trigger the reaction will be added to the output in
additional columns after the reaction string.

=item -n

If specified, then the compound names will be used in the reaction strings in addition to the
compound IDs.

=item -f

If specified, then the compound names will be used instead of the compound IDs in the reaction
strings. This option overrides C<-n>.

=back

=head2 Output Format

The standard output is a tab-delimited file.  Each line will contain
the input fields followed by a description of the reaction. If -o is specified,
then there will be an additional column for each role that triggers the reaction.
    
=cut

use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_reaction_description [-r ReactionID] [-c Column] [-o] [-n] [-f] < input.table";

my $column;
my $reactionID;
my $roles = 0;
my $names = 0;
my $formula = 0;
my $rc  = GetOptions('c=i' => \$column,
		     'r=s' => \$reactionID,
		     'o' => \$roles,
		     'n' => \$names,
                     'f' => \$formula
		    );

if (! $rc) { print STDERR $usage; exit }

# Compute the source of the reactions. This is either the ID specified on the command line, or the
# standard input file.
my $ih;
if ($reactionID) {
    $ih = [$reactionID];
} else {
    $ih = \*STDIN;
}
# Adjust the names option if the user wants formula mode.
if ($formula) {
    $names = 'only';
}

# Loop through the input.
while (my @lines = ScriptThing::GetBatch($ih, 1000, $column)) {
    # Ask for the reaction data relating to the input lines in this batch.
    my $rxHash = $sapO->reaction_strings(-ids => [ map { $_->[0] } @lines ],
                                         -roles => $roles, -names => $names);
    # Loop through the input, producing the output.
    for my $line (@lines) {
        my ($id, $text) = @$line;
        my $data = $rxHash->{$id} || [];
        if (ref $data ne 'ARRAY') {
            $data = [$data];
        }
        print join("\t", $text, @$data) . "\n";
    }
}
