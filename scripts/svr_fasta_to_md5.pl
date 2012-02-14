#!/usr/bin/perl -w

#
# This is a SAS Component
#

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#

use strict;
use SeedUtils;
use Getopt::Long;
use Digest::MD5;
use gjoseqlib;

=head1 svr_fasta_to_md5

=head2 Convert Protein FASTA to MD5 Protein IDs

    svr_fasta_to_md5 <protein_list.fasta >protein_ids.tbl

This script takes a FASTA file of protein sequences from the standard input and
writes a tab-delimited file of protein IDs to the standard output. Each output record will
correspond to a single FASTA input record and will contain the incoming ID
in the first column and the MD5 protein ID in the second column.

=head2 Command-Line Options

=over 4

=item --help

Display this command's parameters and options.

=back

=head3 Output Format

The standard output is a tab-delimited file. Each output record
consists of the ID of an incoming sequence following by the MD5
protein ID for the sequence itself.

=cut

# Get the command-line options and parameters.
my $help;
my $i = "-";
my $rc = GetOptions("help" => \$help, "i=s" => \$i);

if ($help)
{
    #pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    my $usage = [ "$0 [options]",
                  "\t-help       \tdisplay command-line options", ""];

    print join "\n", @$usage;
    exit;
}
# Open the input file.
open my $ih, "<$i";
# Read the fasta sequences from the input file.
my @seqs = gjoseqlib::read_fasta($ih);
# Loop through the sequences, converting them to output.
for my $seqTuple (@seqs) {
    my ($id, $comment, $seq) = @$seqTuple;
    print $id . "\t" . Digest::MD5::md5_hex($seq) . "\n";
}

