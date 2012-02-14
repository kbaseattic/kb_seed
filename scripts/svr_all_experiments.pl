#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use ScriptThing;
use SeedEnv;

#
#	This is a SAS Component.
#

=head1 svr_all_experiments

    svr_all_experiments -g genome >experiments.tbl

List all the experiments present for a specified genome or for all genomes lists
in a file.

This script takes as input one or more genomes and for each genome lists all the
experiments associated with it. The input should be a tab-delimited file with
genome IDs in the last column. The output file will have an additional column
containing the experiment IDs.

This is a pipe command. The input is from the standard input and the output is
to the standard output. The number of output lines will in general be far greater
than the number of input genomes.

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item c

Index (1-based) of the input column containing the genome ID. If omitted, the
last column of the input will be used.

=item g

ID of a genome. If this option is specified, then the output file will contain
two columns, with the incoming genome ID in the first column of every line and
the second column containing the experiment IDs. The standard input will not
be read.

=back

=cut

# Parse the command-line options.
my $url;
my $genomeID;
my $column;
my $inputFile = "-";
my $opted =  GetOptions('url=s' => \$url, "g=s" => \$genomeID, "c=i" => \$column,
                        "i=s" => \$inputFile);
# Check for errors.
if (! $opted) {
    print "usage: svr_all_experiments [--url=http://...] [-g genomeID] [-c col] <input >output\n";
} else {
    # Get the server object.
    my $sapObject = SAPserver->new(url => $url);
    # Get the input genomes. This will either be in the form of an open file
    # handle or a singleton list. The GetBatch method knows what to do in
    # either case.
    my $ih;
    if ($genomeID) {
        # We have a genome ID, so it's passed in as a list.
        $ih = [$genomeID];
    } else {
        # Here we have an input file.
        open($ih, "<$inputFile") || die "Cannot open genome file: $!";
    }
    # The main loop processes chunks of input, 10 lines at a time.
    while (my @tuples = ScriptThing::GetBatch($ih, 10, $column)) {
        # Get the experiments for this group of genomes.
        my $genomeH = $sapObject->genome_experiments(-ids => [map { $_->[0] } @tuples]);
        # Loop through the tuples, writing out the results.
        for my $tuple (@tuples) {
            # Get the genome ID and the input line.
            my ($genome, $line) = @$tuple;
            # Get the list of experiments for this genome and write them out.
            my $exps = $genomeH->{$genome};
            for my $exp (@$exps) {
                print "$line\t$exp\n";
            }
        }
    }
}
