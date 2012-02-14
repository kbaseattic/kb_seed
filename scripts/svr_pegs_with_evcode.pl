use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_

Get pegs that have a given evcode (along with all of the peg's evcodes).

------

Example:

    svr_pegs_with_evcode EvCode [G1 G2 ...]

would produce a 2-column table.  The first column would contain
PEG IDs for genes that have an evidence code specified as the first
argument.  The second is the specified evcode value,
YOu can optionally restrict output to a set of genomes.

------

=head2 Command-Line Options

=over 4

=item EvCode

This specifies a type of evidence code (dlit, ilit, ...)

=back

=head2 Output Format

The standard output is a tab-delimited file.  The first field in each line is a PEG,
and the second is the complete set of evidence codes for the peg separated by commas.

=cut

use SeedUtils;
use SAPserver;
my $sapO = SAPserver->new();

my $usage = "usage: svr_pegs_with_evcode Evcode G1 G2 G3...";

my $evcode = shift @ARGV;
$evcode || die $usage;
my @genomes = @ARGV;
(@genomes > 0) || die "You need to specify one or more genomes";

my $fidH;
$fidH = $sapO->fids_with_evidence_codes( -codes => [$evcode], -genomes => \@genomes );

foreach my $peg (sort { &SeedUtils::by_fig_id($a,$b) } keys(%$fidH))
{
    my $codes = join(",",grep { index($_,$evcode) >= 0 }@{$fidH->{$peg}});
    if ($codes)
    {
	print join("\t",($peg,$codes)),"\n";
    }
}
