#!/usr/bin/perl -w 

use strict;
use SAPserver;
use Getopt::Long;
use ScriptThing;

# This is a SAS Component

=head1 svr_fids_to_regulons

    svr_regulons_to_fids <regulons.tbl >regulons_with_fids.tbl

Return all the atomic regulons each feature belongs to.

This script takes a tab-delimited file with atomic regulon IDs in the
last column and appends an additional column for the feature IDs
in the regulon. For each incoming regulon ID,
all the feature IDs that belong to it are returned, each on a
separate line. The augmented file will be written to the
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
my $usage = "$self [--c=N --url=http://...] <regs.tbl >regsFidss.tbl";

my $rc = GetOptions("url=s" => \$url, "i=s" => \$inputFile, "c=i" => \$column);

if (!$rc) {
    die "\n   usage: $usage\n\n";
}

my $ss = SAPserver->new(url => $url);

open(my $ih, "<$inputFile") || die "Error opening input: $!";
while (my @tuples = ScriptThing::GetBatch($ih, 100, $column)) {
    my @regs = map { $_->[0] } @tuples;
    my $regHash = $ss->regulons_to_fids(-ids => \@regs);
    # Loop through the incoming lines, and pair the results with the inputs.
    for my $tuple (@tuples) {
        # Get the current line and its regulon ID.
        my ($reg, $line) = @$tuple;
        # Get the fid list for this regulon.
        my $fids = $regHash->{$reg};
        # Loop through the features found.
        for my $fid (@$fids) {
            print "$line\t$fid\n";
        }
    }
}

