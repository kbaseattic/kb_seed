use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_location_of

Get physical locations of genes.

------

Example:

    svr_all_features 3702.1 peg | svr_location_of

would produce a 2-column table.  The first column would contain
PEG IDs for genes occurring in genome 3702.1, and the second
would contain the locations of those genes.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the ID of the feature for which locations are being requested.
If some other column contains the feature IDs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -bounds

Normally, the location is returned as a comma-delimited list of location strings (each
containing a contig ID, a start location, a strand indicator, and a length). Normally
this would be a single location string, but some genes have multiple contiguous segments,
and each segment is a separate string. If this option is specified, then only a single
location-- one that covers all segments of the gene-- is output.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the location associated with the feature).

=cut

use SeedUtils;
use SAPserver;
use ScriptThing;
use Getopt::Long;

my $usage = "usage: svr_location_of [-c column] [-bounds]";

my $column;
my $bounds = 0;
my $url = '';
my $rc  = GetOptions('c=i' => \$column, "bounds" => \$bounds, "url=s" => \$url);
my $sapObject = SAPserver->new(url => $url);
if (! $rc) { print STDERR $usage; exit }
while (my @tuples = ScriptThing::GetBatch(\*STDIN, undef, $column)) {
    # Get the locations for this batch of features.
    my $fidHash = $sapObject->fid_locations(-ids => [map { $_->[0] } @tuples], -boundaries => $bounds);
    # Loop through them, generating output.
    for my $tuple (@tuples) {
        # Get the feature ID and input line for this tuple.
        my ($fid, $line) = @$tuple;
        # Find the locations for this feature.
        my $locs = $fidHash->{$fid};
        if (! defined $locs) {
            # Here no location was found.
            print STDERR "$fid not found.\n";
        } elsif (ref $locs ne 'ARRAY') {
            # Here we have a singleton location.
            print "$line\t$locs\n";
        } else {
            # Here we have a list of location segments.
            my $locString = join(", ", @$locs);
            print "$line\t$locString\n";
        }
    }
}
