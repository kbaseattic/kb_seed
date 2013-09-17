use strict;

use Getopt::Long;
use SeedEnv;

#
# This is a SAS Component
#


=head1 svr_all_models

List the existing metabolic models (and the genomes for which
they were built).

There is no input.  The output is 2-column table containing
genome and model IDs.

------
Example:

    svr_all_models > genome_model.table

would produce a 2-column table of genome IDs and model IDs.
------

=back

=head2 Output Format

The standard output is a file where each line contains genome ID and a model
ID (tab-separated).

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();

my $modelH = $sapObject->all_models;

foreach my $model (sort { $modelH->{$a} <=> $modelH->{$b} } keys(%$modelH))
{
    if ($model =~ /^Seed/)
    {
	print join("\t",($modelH->{$model},$model)),"\n";
    }
}

