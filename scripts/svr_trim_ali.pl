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

=head1 svr_trim_ali

    svr_trim_ali [options] < ali.fa > trim.fa

This script takes a FASTA file of aligned sequences, trims the
alignment by running PSIBLAST against the sequences themselves, and
writes the trimmed alignment to the standard output.

=head2 Introduction

usage: svr_trim_ali [options] < ali.fa > trim.fa

       -a align_tool   - alignment tool to use: Clustal (D), MAFFT, Muscle. 
       -c              - append trimming coordinates to description fields in FASTA
       -d log_dir      - direcotry for log files
       -e log_prefix   - prefix for log file names
       -f fract_cov    - fraction of sequences to be covered in initial trimming (D = 0.75)
       -g              - attempt no more than a single round of psiblast
       -l              - run trimming locally
       -m              - trim to median ends only
       -r              - first collapse seqs into representatives
       -s max_reps_sim - threshold used to collapse seqs into representatives (D = 0.9)
       -cd             - trim to conserved domains
       -html file      - show clipped ends in lower letters in an html alignment 

=head2 Command-Line options

=over 4

=item -a align_tool

Alignment tool to use. The default is Clustal, which seems to deal
with end gaps better. If MAFFT is chosen, automatically selects an
appropriate strategy from L-INS-i, FFT-NS-i and FFT-NS-2, according to
data size.

=item -c 

With the -c option, the coordiates of the trimmed sequences are
appended to the comment field of the output FASTA.

=item -d log_dir

Directory name for trimming log files. Without the -d option, log
files are not saved.

=item -e log_prefix

Prefix for log file names. Random digits are appended to the file
names so that existing files will not be clobbered.

=item -f fract_cov (D = 0.75)

Fraction of sequences to be covered in initial trimming.  Use 0.5 for
trimming to medien ends.

=item -g 

Without the -g option, more than one rounds of psiblast search may be
attempted to incorporate seqs with multiple hsps.

=item -l

Run trimming and psiblast locally. 

=item -m 

Trim to median ends (or a specified coverage fraction in the -f option) only.

=item -r 

Use represetative sequences to reduce data size and over-represented sequences.

=item -s max_reps_sim (D = 0.9)

The similarity threshold used to collapse seqs into representatives. 

=item -t fract_ends (D = 0.1)

The minimum fraction of ends falling in the same window of uncovered
amino acids that are considered significant for determining the
trimming cutoff. A smaller fraction value indicates more aggressive
trimming.

=item -w window_size (D = 10)

The size of the initial sliding window used to count instances of
sequences whose ends have similar number of uncovered amino acids. If
no cutoff value is found, additional rounds of calculation are carried
out with increasing window sizes. The effect of starting window size
on trimming is uncertain. A narrower starting window size usually
indicates less aggressive trimming, but it may have the opposite
effect when fract_ends is very small.

=item -cd

Trim to conserved domains. No psiblast search is attempted.

=item -html file

Generate an HTML file for visualizing trimmed alignment with clipped
ends in lower case.

=back 

=head2 Input

The input set of aligned sequences is read from STDIN.

=head2 Output

The set of trimmed sequences is written to STDOUT.

=cut

use AlignTree;
use ATserver;
use SeedUtils;

use gjoalignment;
use gjoseqlib;

my $usage = <<"End_of_Usage";

usage: svr_trim_ali [options] < ali.fa > trim.fa

       -a  align_tool   - alignment tool to use: Clustal (D), MAFFT, Muscle
       -c               - append trimming coordinates to description fields in FASTA
       -d  log_dir      - directory for log files
       -e  log_prefix   - prefix for log file names
       -f  fract_cov    - fraction of sequences to be covered in initial trimming (D = 0.75)
       -g               - attempt no more than a single round of psiblast
       -l               - run trimming locally
       -m               - trim to median ends only
       -r               - first collapse seqs into representatives
       -s  max_reps_sim - threshold used to collapse seqs into representatives (D = 0.9)
       -t  fract_ends   - minimum fraction of ends to be considered significant for uncov cutoff (D = 0.1)
       -w  win_size     - size of sliding window used in calculating uncov cutoff (D = 10)
       -cd              - trim to conserved domains
       -html file       - show clipped ends in lower letters in an html alignment 

End_of_Usage

my ($help, $local, $tool, $coord, $dir, $prefix, $fc, $fe,
    $single, $median, $reps, $sim, $win, $cd, $html, $short);

GetOptions("h|help"   => \$help,
           "l|local"  => \$local,
           "a|tool=s" => \$tool,
           "c"        => \$coord,
           "d=s"      => \$dir,
           "e=s"      => \$prefix,
           "f|fc=f"   => \$fc,
           "g"        => \$single,
           "m"        => \$median,
           "r|rep"    => \$reps,
           "s|sim=f"  => \$sim,
           "t|fe=f"   => \$fe,
           "w=i"      => \$win,
           "cd"       => \$cd,
           "html=s"   => \$html,
           "short"    => \$short);

$help and die $usage;

my $opts;

$opts->{keep_def}       = 1                 if !$coord && !$html;
$opts->{single_round}   = 1                 if $single;
$opts->{skip_psiblast}  = 1                 if $median || $cd;
$opts->{to_domain}      = 1                 if $cd;
$opts->{use_reps}       = 1                 if $reps;
$opts->{fract_cov}      = $fc               if $fc;
$opts->{fract_ends}     = $fe               if $fe;
$opts->{log_dir}        = $dir              if $dir;
$opts->{log_prefix}     = $prefix           if $prefix;
$opts->{max_reps_sim}   = $sim              if $sim;
$opts->{win_size}       = $win              if $win;
$opts->{align_opts}     = { tool => $tool } if $tool;

$opts->{align_opts}->{auto} = 1 if $tool =~ /mafft/i;

$opts->{ali} = gjoseqlib::read_fasta();

my $AT;
my $trim;

if ($local) {
    $trim = AlignTree::trim_alignment($opts);
} else {
    $AT   = ATserver->new();
    $trim = $AT->trim_ali($opts)->{rv};
}

gjoseqlib::print_alignment_as_fasta($trim);

if ($html) {
    my @ali2  = map { [@$_[0,1], uc($_->[2])] } @{$opts->{ali}};
    my %desc  = map { $_->[0] => $_->[1] } @ali2;
    my %coord = map { $_->[0] => substr($_->[1], length($desc{$_->[0]})) } @$trim;

    my ($beg, $end) = (0, length($ali2[0]->[2]));
    for (@ali2) {
        $_->[1] = $desc{$_->[0]}. $coord{$_->[0]};
        my $i = 0;
        my $j = length($_->[2]) - 1;
        if ($coord{$_->[0]} =~ /.* \((\d+)-(\d+)\/(\d+)\)/) {
            my ($b, $e, $l) = ($1, $2, $3);
            my $nongap = 0;
            while ($nongap < $b-1) {
                $nongap++ if substr($_->[2], $i++, 1) =~ /[A-Z]/i;
            }
            $nongap = 0;
            while ($nongap < $l-$e) {
                $nongap++ if substr($_->[2], $j--, 1) =~ /[A-Z]/i;
            }
            substr($_->[2], 0, $i) = lc substr($_->[2], 0, $i) if $i > 0;
            substr($_->[2], $j+1)  = lc substr($_->[2], $j+1)  if $j+1 < length($_->[2]);
            $beg = $i if $i > $beg;
            $end = $j if $j < $end;
        }
    }
    my $show = 20;
    if ($short && $end-$beg > 2*$show) {
        for (@ali2) {
            $_->[2] = join(' ', substr($_->[2],0, $beg),
                           substr($_->[2],$beg, $show),
                           '---OMITTED---',
                           substr($_->[2], $end-$show+1, $show),
                           substr($_->[2], $end+1));
        }
    }
    open(HTML, ">$html") or die "Could not write to $html";
    my ($seqs2, $legend ) = gjoalign2html::color_alignment_by_consensus( { align => \@ali2 } );
    print HTML gjoalign2html::alignment_2_html_page($seqs2, { legend => $legend, title => "Alignment showing trimmed regions" });
    close(HTML);
}
