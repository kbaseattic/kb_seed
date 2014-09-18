########################################################################
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_fids_to_locations < FIDs > with.locs

Clusters from protein-encoding genes

------

Example:

    svr_all_features 3702.1 fid | svr_fids_to_locations
    svr_all_features 3702.1 fid | svr_fids_to_locations -b

would produce a 3-column table.  The first column would contain
FID IDs and the second the FID locations. 
The file would be sorted on the locations.
The second version would coallapse multi-region locations into
lust the boundaries.
------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the FID for which clusters are being requested.
If some other column contains the FIDs, use

    -c N

where N is the column (from 1) that contains the FID in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing FIDs is not the last.

=item -b [return just boundaries]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the locations of fids)

=cut

use SeedUtils;
use SAPserver;
use Getopt::Long;
use ScriptThing;

my $usage = "usage: fids_to_locations [-c column] [-b]\n";

my $column;
my $boundaries = 0;
my $i = "-";
my $url = '';

my $rc  = GetOptions('c=i' => \$column, 
		     'b'   => \$boundaries,
		     'url=s' => \$url,
		     'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
my $sapObject = SAPserver->new(url => $url);
open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) 
{
    my @ids = map { $_->[0] } @tuples;
    my $b = $boundaries ? "1" : "0";
    my $locations = $sapObject->fid_locations(-ids => \@ids, -boundaries => $boundaries);
    for my $tuple (@tuples) 
    {
        my ($id, $line) = @$tuple;
        my $location = $locations->{$id};
        if (! defined $location) {
#           print STDERR "$id not found.\n";
        } 
	else 
	{
	    if (! $b)
	    {
		$location = join(",",@$location);
	    }
	    print "$line\t$location\n";
        }
    }
}
