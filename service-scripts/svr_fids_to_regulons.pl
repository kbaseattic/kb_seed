#!/usr/bin/perl -w 

use strict;
use SAPserver;
use Getopt::Long;
use ScriptThing;

# This is a SAS Component

=head1 svr_fids_to_regulons

    svr_fids_to_regulons <fids.tbl >regulon_data.tbl

Return all the atomic regulons each feature belongs to.

This script takes a tab-delimited file with FIG feature IDs in the
last column and appends two additional columns-- an atomic regulon ID
and the number of features in the regulon. For each incoming feature ID,
all the atomic regulons it belongs to are returned. In general, however,
there will only be one. The augmented file will be written to the
standard output.

This is a pipe command. The input is from the standard input and the output is
to the standard output.

The following command-line options are supported.

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item c

Number (1-based) of the column in the input file containing the subsystem name. If omitted,
the last column is used.

=back

=cut

my $column;
my $url = "";
my $inputFile = "-";

$0 =~ m/([^\/]+)$/;
my $self = $1;
my $usage = "$self [--c=N --url=http://...] <fids.tbl >fidsRegulons.tbl";

my $rc = GetOptions("url=s" => \$url, "i=s" => \$inputFile, "c=i" => \$column);

if (!$rc) {
    die "\n   usage: $usage\n\n";
}

my $ss = SAPserver->new(url => $url);

open(my $ih, "<$inputFile") || die "Error opening input: $!";
while (my @tuples = ScriptThing::GetBatch($ih, 100, $column)) {
    my @pegs = map { $_->[0] } @tuples;
    my $fidHash = $ss->fids_to_regulons(-ids => \@pegs);
    # Loop through the incoming lines, and pair the results with the inputs.
    for my $tuple (@tuples) {
        # Get the current line and its feature ID.
        my ($fid, $line) = @$tuple;
        # Get the regulon hash for this subsystem.
        my $regHash = $fidHash->{$fid};
        # Only proceed if we found something.
        if ($regHash) {
            for my $reg (sort keys %$regHash) {
                print "$line\t$reg\t$regHash->{$reg}\n";
            }
        }
    }
}

