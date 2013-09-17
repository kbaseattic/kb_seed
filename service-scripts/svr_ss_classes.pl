#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use ScriptThing;
use SeedEnv;

#
#	This is a SAS Component.
#

=head1 svr_ss_classes

    svr_ss_classes -s genome >classes.tbl

List the classifications for a specified subsystem or for all subsystems in a file.

This script takes as input one or more subsystem names and for each on appends
the classification hierarchy for that subsystem. In the current database, the
hierarchy can be anything from an empty list (0) to two entries.

The input should be a tab-delimited file with subsystem IDs in the last column. The
output file will have additional columns containing the classifications, in order
from the largest to the most detailed.

This is a pipe command. The input is from the standard input and the output is
to the standard output.

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item c

Index (1-based) of the input column containing the subsystem ID. If omitted, the
last column of the input will be used.

=item s

ID of a subsystem. If this option is specified, then the output file will contain
only one line (for the one specified subsystem). The standard input will not
be read.

=back

=cut

# Parse the command-line options.
my $url;
my $subsysID;
my $column;
my $inputFile = "-";
my $opted =  GetOptions('url=s' => \$url, "s=s" => \$subsysID, "c=i" => \$column,
                        "i=s" => \$inputFile);
# Check for errors.
if (! $opted) {
    print "usage: svr_ss_classes [--url=http://...] [-s subsysID] [-c col] <input >output\n";
} else {
    # Get the server object.
    my $sapObject = SAPserver->new(url => $url);
    # Get the input subsystems. This will either be in the form of an open file
    # handle or a singleton list. The GetBatch method knows what to do in
    # either case.
    my $ih;
    if ($subsysID) {
        # We have a genome ID, so it's passed in as a list.
        $ih = [$subsysID];
    } else {
        # Here we have an input file.
        open($ih, "<$inputFile") || die "Cannot open input file: $!";
    }
    # The main loop processes chunks of input, 10 lines at a time.
    while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
        # Get the experiments for this group of genomes.
        my $ssH = $sapObject->classification_of(-ids => [map { $_->[0] } @tuples]);
        # Loop through the tuples, writing out the results.
        for my $tuple (@tuples) {
            # Get the genome ID and the input line.
            my ($ss, $line) = @$tuple;
            # Get the list of experiments for this genome and write them out.
            my $classes = $ssH->{$ss};
            print "$line\t" . join("\t", @$classes) . "\n";
        }
    }
}
