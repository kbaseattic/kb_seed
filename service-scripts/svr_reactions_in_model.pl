use strict;

use Getopt::Long;
use ScriptThing;
use SAPserver;

#
# This is a SAS Component
#


=head1 svr_reactions_in_model

Takes as input a table containing model IDs and 
adds a column giving a reaction in the model. Since each model contains
hundreds of reactions, the output file will be extremely large compared to the
input file.

------
Example: svr_all_models | svr_reactions_in_model > table.with.reactions

would produce a 3-column table: [genomeID, modelID,reactionID]

------

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing reaction IDs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with two extra columns (distance and connected reaction).

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_reactions_in_model [-c column] < models > models.with.reactions";

my $column;
my $rc  = GetOptions('c=i' => \$column,
                    );
if (! $rc) { print STDERR $usage; exit }

while (my @lines = ScriptThing::GetBatch(\*STDIN, 10, $column)) {
    my $reactionsH = $sapObject->models_to_reactions( -ids => [map { $_->[0] } @lines] );
    for my $line (@lines) {
        my ($model, $text) = @$line;
        my $reactions = $reactionsH->{$model};
        for my $reaction (@$reactions) {
            print "$text\t$reaction\n";
        }
    }
}
