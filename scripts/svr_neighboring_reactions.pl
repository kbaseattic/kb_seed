use strict;

use Getopt::Long;
use ScriptThing;
use SAPserver;

#
# This is a SAS Component
#


=head1 svr_neighboring_reactions

Takes as input a table containing reaction IDs and 
adds 2 columns giving the distance and the connected reaction.

------
Example: svr_all_reactions | svr_neighboring_reactions -d 2 > table.with.neighboring.reactions

would produce a 3-column table: [reactionID1,Distance,ReactionID2]

         svr_neighboring_reactions -r rxn09225

would produce a 3-column table in which each line represents a reaction
connected (immediately connected, since -d defaults to 1) to rxn09225.

------

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing reaction IDs is not the last.

=item -d MaxDist [default=1]

Gives the maximum distance.  The computation becomes extremely expensive as this value
goes up.

=item -r Reaction

Gives a single reaction, rather than taking reactions from an input file.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with two extra columns (distance and connected reaction).

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_neighboring_reactions [-c column] [-d MaxDistance] [-r reaction]";

my $column;
my $max_dist = 1;
my $reaction;
my $rc  = GetOptions('c=i' => \$column,
		     'r=s' => \$reaction,
                     'd=i' => \$max_dist
                    );
if (! $rc) { print STDERR $usage; exit }

if (! $reaction)
{
    while (my @lines = ScriptThing::GetBatch(\*STDIN, 10, $column)) {
	my $reactionsH = $sapObject->reaction_neighbors( -ids => [map { $_->[0] } @lines],
							 -depth => $max_dist );
	for my $line (@lines) {
	    my ($rxn, $text) = @$line;
	    my $neighborH = $reactionsH->{$rxn};
	    for my $neighbor (sort keys %$neighborH) {
		print "$text\t$neighbor\t$neighborH->{$neighbor}\n";
	    }
	}
    }
}
else
{
    my $reactionsH = $sapObject->reaction_neighbors( -ids => [$reaction], -depth => $max_dist );
    my $neighborH = $reactionsH->{$reaction};
    for my $neighbor (sort keys %$neighborH) {
	print "$reaction\t$neighbor\t$neighborH->{$neighbor}\n";
    }
}
