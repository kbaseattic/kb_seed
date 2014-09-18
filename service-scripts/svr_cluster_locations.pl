########################################################################
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_cluster_locations < LOCs > CLUSTERs

Cluster locations on the chromosome

------

Example:

    svr_all_features 3702.1 peg | svr_fids_to_locations | svr_cluster_locations -m 3000 -n 3

would produce a 3-column table.  The first column would contain
PEG IDs, the second the PEG locations,  and the third cluster IDs.  
The file would be sorted on the second column.
------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the LOC for which clusters are being requested.
If some other column contains the LOCs, use

    -c N

where N is the column (from 1) that contains the location in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing LOCs is not the last.

=item -m Maximum Gap between LOCs in a cluster [default is 3000]

Clusters are thought of as "runs with gaps less then or equal to 
this value".  A run can include genes in either (or both) orientations.

=item -n Minimum Size of Cluster [default is 2]

Kept clusters will contain at least this many locations.  runs
of size less than this will not show up in the output (use 1
if you want to keep all input lines).

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the Cluster IDs)

=cut

use SeedUtils;
use SAPserver;
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_cluster_locations [-c column] [-m max-gap] [-n min-size]\n";

my $column;
my $max_gap = 3000;
my $min_size = 1;
my $i = "-";
my $url = '';

my $rc  = GetOptions('c=i' => \$column, 
		     'm=i' => \$max_gap,
		     'url=s' => \$url,
		     'n=i' => \$min_size);
if (! $rc) { print STDERR $usage; exit }
my $sapObject = SAPserver->new(url => $url);
open my $ih, "<$i";
my @split_tuples;
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) 
{
    push(@split_tuples, map { my($loc,$line) = @$_;
			      ($loc =~ /^([^:]+):(\S+)_(\d+)([+-])(\d+)$/) ? 
				  [[$1,$2,$3,$4,$5,($4 eq '+') ? ($3 + ($3+$5)) : ($3 + ($3-$5))],$line] : 
				  () } @tuples);
}
@split_tuples = sort { ($a->[0]->[0] cmp $b->[0]->[0]) or
		       ($a->[0]->[1] cmp $b->[0]->[1]) or
		       ($a->[0]->[5] <=> $b->[0]->[5]) } @split_tuples;

my $cluster = 1;
my $last = shift @split_tuples;
while ($last)
{
    my @set = ($last);
    while (($last = shift @split_tuples) && 
	   (($set[-1]->[0]->[0] eq $last->[0]->[0]) &&
	    ($set[-1]->[0]->[1] eq $last->[0]->[1]) &&
	    ((($last->[0]->[5] - $set[-1]->[0]->[5])/2) <= $max_gap)))
    {
	push(@set,$last);
    }
    if (@set >= $min_size)
    {
	foreach $_ (@set)
	{
	    print $_->[1] . "\t$cluster\n";
	}
	$cluster++;
    }
}

		       
