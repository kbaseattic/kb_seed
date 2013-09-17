use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_keep_good_connections -h MinHits -r MinRatio < connections > connections.to.keep


------

Example:

    svr_keep_good_connections -h 5 -r 0.8 < connections > connections.kept

=head2 Command-Line Options

=over 4

=item -h Minimum number of BBHs that remain clustered

=item -r Minimum Ratio of Preserved/those-that-have-BBHs
      That is, you have a pair of PEGs, you have the number of cases in which
      they remain close (of those with BBHs for both PEGs) and the number that
      are no longer neighbors.  This parameter requires that the ration of the
      number preserve divided by the sum of the number preserved and those not 
      preserved exceeds a specified value.

=back

=head2 Output Format

The output is a file of clusters.  Each cluster is a tab-separated line.

=cut

use SeedUtils;
use Getopt::Long;

my $usage = "usage: svr_keep_good_connections -h MinHits -r MinRatio";

my $min_hits = 5;
my $min_ratio = 0.2;
my $file;

my $rc  = GetOptions('h=f' => \$min_hits, 
		     'r=f' => \$min_ratio);
if (! $rc) { print STDERR $usage; exit }

open(CLUSTER, "| cluster_objects") || die "could not cluster";

while (defined($_ = <STDIN>))
{
    if (($_ =~ /^(\S+)\t(\S+)\t(\S+)\t(\S+)/) && ($3 >= $min_hits) && (($3+$4 > 0) && (($3/($3+$4)) >= $min_ratio)))
    {
	print CLUSTER "$1\t$2\n";
    }
}
close(CLUSTER);
