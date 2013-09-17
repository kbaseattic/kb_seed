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
use Data::Dumper;
use Carp;
use Getopt::Long;

=head1 svr_motif

    svr_motif [options] < ali.fa > motifs

This script identifies the conserved regions from a set of aligned sequences.

=head2 Introduction

usage: svr_motif [options] < ali.fa > motifs.tbl

       -c  coord_file   - file containing coordinates for motifs to be extracted: [beg end]
       -f  max_f_diff   - maximum fraction exceptions to consensus
       -w1 win_min      - minimum window size (D = 4)
       -w2 win_max      - maximum window size (D = 10)
       -th threshold    - threshold for average site convervation score (D = 0.6)

=head1 Command-Line options

=over 4

=item -c coord_file

The file that contains lines of coordinates for motifs to be extracted: [beg end]

=item -f  max_f_diff

Maximum fraction exceptions to consensus.

=item -w1 win_min

Minimum window size (D = 4)

=item -w2 win_max

Maximum window size (D = 10)

=item -th threshold

Threshold for average site convervation score (D = 0.6)

=back

=head2 Input

The input set of aligned sequences is read from STDIN.

=head2 Output

The output is tab-delmited 7-column table:

  [ motif_beg motif_end avg_conserve_score consensus_seq extended_beg extended_end extended_consensus ]

=cut

use AlignTree;
use SeedUtils;
use SeedAware;

use gjoalign2html;
use gjoseqlib;

my $usage = <<"End_of_Usage";

usage: svr_motif [options] < ali.fa > motifs.tbl

       -c  coord_file   - file containing coordinates for motifs to be extracted: [beg end]
       -f  max_f_diff   - maximum fraction exceptions to consensus
       -w1 win_min      - minimum window size (D = 4)
       -w2 win_max      - maximum window size (D = 10)
       -th threshold    - threshold for average site convervation score (D = 0.6)

End_of_Usage

my ($help, $coord_file, $max_f_diff, $win_min, $win_max, $thresh);

GetOptions("h|help"    => \$help,
           "c|coord=s" => \$coord_file,
           "f|fdiff=f" => \$max_f_diff,
           "w1|wmin=i" => \$win_min,
           "w2|wmax=i" => \$win_max,
           "t|th=f"    => \$thresh);

$help and die $usage;

$win_min ||= 4;
$win_max ||= 10;
$thresh  ||= 0.6;

my $ali = gjoseqlib::read_fasta();
my $len = length($ali->[0]->[2]);

my @coords;
my @sum;

my $conserv = AlignTree::residue_conserv_scores($ali);
for (my $i = 1; $i <= $len; $i++) {                 # 1-based coordinates
    $sum[$i] = $sum[$i-1] + $conserv->[$i-1];
}

if ($coord_file) {
    @coords = map { [ split /\D+/ ] } SeedUtils::file_read($coord_file);
} else {
    @coords = AlignTree::conserved_regions_in_ali($ali, { conserv => $conserv,
                                                          win_min => $win_min,
                                                          win_max => $win_max,
                                                          thresh  => $thresh });
}

for my $coord (@coords) {
    my ($b, $e) = @$coord;

    my $scr = sprintf "%.3f", ($sum[$e] - $sum[$b-1]) / ($e - $b + 1);
    my $s   = consensus_residues_in_region($ali, $b, $e, { max_f_diff => $max_f_diff });
    my $bb  = $b;
    my $ee  = $e;

    $bb-- while $bb > 1    && ($sum[$e]   - $sum[$bb-2]) / ($e - $bb + 2) >= $thresh;
    $ee++ while $ee < $len && ($sum[$ee+1] - $sum[$b-1]) / ($ee - $b + 2) >= $thresh;

    $bb++ while $bb < $b && $conserv->[$bb-1] < $thresh;
    $ee-- while $ee > $e && $conserv->[$ee-1] < $thresh;

    my $ss  = consensus_residues_in_region($ali, $bb, $ee, { max_f_diff => $max_f_diff });
    
    print join("\t", $b, $e, $scr, $s, $bb, $ee, $ss) . "\n";
}

sub consensus_residues_in_region {
    my ($ali, $b, $e) = @_;

    my $max_f_diff = 0.3;
    my $pad_char   = ' ';
    my $chars      = qr/^[-*A-Za-z]$/;
    my $reg1       = qr/^([^A-Za-z.*]+)/;
    my $reg2       = qr/([^A-Za-z.*]+)$/;
    
    my $s;
    my @seq = map { $s = uc $_->[2];
                    $s =~ s/$reg1/$pad_char x length($1)/e;
                    $s =~ s/$reg2/$pad_char x length($1)/e;
                    $s
                  }  @$ali;

    my $conserve_hash = gjoalign2html::conservative_change_hash();
    my ($motif, $chr, $n_signif, $min_consen, $consensus_hash, $c1, $c2);
    for my $i ($b-1 .. $e-1) {
        my %cnt;
        for ( @seq ) { $chr = substr($_,$i,1); $cnt{$chr}++ if $chr =~ /$chars/ }
        $n_signif = sum( map { $cnt{$_} } keys %cnt );
        $min_consen = $n_signif - int( $max_f_diff * $n_signif );
        ( $c1, $c2 ) = gjoalign2html::consensus_residues( \%cnt, $min_consen, $conserve_hash );
        $motif .= $c1 ? $c1 : 'x';
    }
    return $motif;
}

sub sum {
    my $cnt = 0;
    while ( defined( $_[0] ) ) { $cnt += shift }
    $cnt
}
