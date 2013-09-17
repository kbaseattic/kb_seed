#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use ScriptThing;

#
#	This is a SAS Component.
#

=head1 svr_dlits

    svr_dlits < table-of-peg-md5 > table-with-3-more-columns

Get the list of publications associated with each specified protein or
gene.

This script takes as input a tab-delimited file with gene or protein IDs at 
the end of each line. For each ID, the associated literature references are
found and the pubmed ID, title, and URL are appened to the input line.

This is a pipe command: the input is taken from the standard input and the output
is to the standard output.

If a single ID is associated with multiple publications, there will be one 
output line for each publication.


=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item c

Column index. If specified, indicates that the input IDs should be taken from the
indicated column instead of the last column. The first column is column 1.

=back

=cut

# Parse the command-line options.
my $url = '';
my $column = '';
my $opted =  GetOptions('url=s' => \$url, 'c=i' => \$column);
if (! $opted) {
    print "usage: svr_dlits [--url=http://...] [--c=N] <input >output\n";
} else {
    # Get the list of output field names from the remaining positional parameters.
    my @outputs = @ARGV;
    # Get the server object.
    my $sapServer = SAPserver->new(url => $url);
    # The main loop processes chunks of input.
    while (my @tuples = ScriptThing::GetBatch(\*STDIN, undef, $column)) {
        # Ask the server for results.
        my $document = $sapServer->dlits_for_ids(-ids => [map { $_->[0] } @tuples],
                                                 -full => 1);
        # Loop through the IDs, producing output.
        for my $tuple (@tuples) {
            my ($id, $line) = @$tuple;
            # Get this ID's data.
            my $data = $document->{$id};
            # Did we get something?
            if (! $data) {
                # No. Write an error notification.
                print STDERR "Nothing found: $id\n";
            } else {
                # Yes. Loop through the tuples, printing output lines.
                for my $tuple (@$data) {
                    print join("\t", $line, @$tuple) . "\n";
                }
            }
        }
    }
}

