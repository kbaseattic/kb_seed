#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use ScriptThing;

#
#	This is a SAS Component.
#

=head1 svr_expressed_genes_in_range

    svr_expressed_genes_in_range --min=minLevel --max=maxLevel <genome_ids.tbl >genome_data.tbl

Compute the genes in the specified genomes that are expressed a particular fraction of the
time, where the fraction is a number between 0 and 1. The fraction is specified as a
range from a minimum to a maximum value. If the minimum is 1, then only genes expressed
all the time are returned. If the maximum is 0, then only genes that are never expressed
are returned.

The expression level is computed by taking all the experiment results called I<on> and
dividing them by the total number of results called either I<on> or I<off>. In other
words, results that are called as indeterminate are ignored in the computation.

This script takes as input a tab-delimited file with genome IDs at the end of each
line. For each genome ID, multiple output lines will be generated-- one per qualified gene--
and each generated line will have a level fraction and a FIG gene ID appended to it.

This is a pipe command: the input is taken from the standard input and the output
is to the standard output.

The following command-line options are supported.

=over 4

=item url

The URL to use for the server. This is primarily a debugging option, and is used to
specify an alternate server script.

=item c

The index (1-based) of the column containing the genome ID. If this option is omitted,
the last column is used.

=item min

The minimum acceptable expression level. The default is 0, meaning all genes with an expression level
less than or equal to the maximum will be returned.

=item max

The maximum acceptable expression level. The default is 1, meaning all genes with an expression level
greater than or equal to the minimum level will be returned.

=cut

# Parse the command-line options.
my $url = '';
my $column = '';
my $max = 1;
my $min = 0;
my $opted =  GetOptions('url=s' => \$url, 'c=i' => \$column, 'min=f' => \$min, 'max=f' => \$max);
if (! $opted) {
    print "usage: svr_expressed_genes_in_range [--url=http://...] [--c=N] [--min=0.00] [--max=1.00] <input >output\n";
} else {
    # Get the server object.
    my $sapServer = SAPserver->new(url => $url);
    # The main loop processes chunks of input.
    while (my @tuples = ScriptThing::GetBatch(\*STDIN, 10, $column)) {
        # Ask the server for results.
        my $document = $sapServer->fids_expressed_in_range(-ids => [map { $_->[0] } @tuples],
                                               -minLevel => $min, -maxLevel => $max);
        # Loop through the IDs, producing output.
        for my $tuple (@tuples) {
            my ($id, $line) = @$tuple;
            # Get this genome's data.
            my $genomeData = $document->{$id};
            # Did we get something?
            if (! $genomeData) {
                # No. Write an error notification.
                print STDERR "Not found: $id\n";
            } else {
                # Yes. Loop through the features found for this genome, producing output lines.
                for my $fid (sort keys %$genomeData) {
                    print join("\t", $line, $genomeData->{$fid}, $fid) . "\n";
                }
            }
        }
    }
}

