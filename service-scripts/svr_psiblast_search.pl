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

=head1 svr_psiblast_search

    svr_psiblast_search [options] < ali.trimmed.fa > hits.extracted.fa

This script takes a FASTA file of trimmed protein sequence alignment,
uses PSIBLAST to search against the protein database of complete
genomes, and writes the extracted regions of hits to the standard output.

=head2 Introduction

usage: svr_psiblast_search [options] < ali.trimmed.fa > hits.fa

       -a   n_processor     - number of processors to use (D = 2)
       -b   database        - database to search against: SEED, CORE, PSEED, PUBSEED (D), FASTA file name, FIG genome ID
       -c   min_frac_cov    - minimum fraction coverage of query and subject sequence (D = 0.20)
       -cq  min_q_cov       - minimum fraction coverage of query sequence (D = 0.50)
       -cs  min_s_cov       - minimum fraction coverage of subject sequence (D = 0.20)
       -e   max_e_val       - maximum psiblast e-Value (D = 0.01)
       -i   min_ident       - minimum fraction identity (D = 0.15)
       -l                   - run search locally if a local database is specified
       -n   max_num_seqs    - maximum matching sequences (D = 5000)
       -p   min_positive    - minimum fraction positive scoring (D = 0.20)
       -r   report_file     - output file of psiblast report
       -u   max_q_uncov     - maximum unmatched query (D = 20)
       -uc  max_q_uncov_c   - maximum unmatched query, c-term (D = 20)
       -un  max_q_uncov_n   - maximum unmatched query, n-term (D = 20)

       options for incremental search:

       -inc                 - incrementally expand an initial set of of sequences through multiple psiblast rounds
       -fast                - use fast trimming (trim to conserved domains) (D = 0)
       -nr   min_reps       - only use representative seqs if number of seqs exceeds this threshold (D = 10)
       -nq   max_nquery     - stop incremental search if the number of query sequences exceeds this threshold (D = 500)
       -rep                 - collapse profile seqs into representatives before submitting to psiblast
       -sim  max_reps_sim   - threshold used to collapse seqs into representatives (D = 0.95)
       -stop max_rounds     - stop incremental search after a specified number of psiblast rounds (D = until convergence)

=head2 Command-Line options

=over 4

=item -a n_processor

Number of processors to use (D = 2)

=item -b database

Database for psiblast to search against. It can be a FASTA file name,
a FIG genome ID, or a string, SEED, CORE, PSEED, or PUBSEED, to
indicate one of the preconfigured database of all protein sequences
from complete genomes. The default is PUBSEED.

=item -c min_frac_cov

Minimum fraction coverage of query and subject sequence (D = 0.20)

=item -cq min_q_cov

Minimum fraction coverage of query sequence (D = 0.50)

=item -cs min_s_cov

Minimum fraction coverage of subject sequence (D = 0.20)

=item -e max_e_eval

Maximum psiblast e-Value (D = 0.01).

=item -i min_ident

Minimum fraction identity (D = 0.15).

=item -l 

With the -l option, psiblast search is run locally. The database must
be a local FASTA file.

=item -n max_num_seqs

Maximum matching sequences (D = 5000).

=item -p min_positive

Minimum fraction of positive scoring AAs (D = 0.20).

=item -r report_file

Output file name for psiblast records produced as a 11-column table containing:

  [ subject_id, bit_score, e_value,
    subject_length, status,
    fraction_ident, fraction_positive,
    query_uncov_n_term, query_uncov_c_term,
    subject_uncov_n_term, subject_uncov_c_term ]

=item -u max_q_uncov

Maximum unmatched query (D = 20).

=item -uc max_q_uncov_c

Maximum unmatched query, c-term (D = 20).

=item -un max_q_uncov_n

Maximum unmatched query, n-term (D = 20).

=item -inc

With the -inc option, multiple psiblast search rounds will be carried
out to expand the input set of sequences. This can be particularly
useful when the starting profile contains few sequences.

The input set of sequences can be unaligned. The psiblast hits at the
end of each round are aligned, trimmed, and sorted. The top hits are
then selected to form the set of profile sequences for the next
round. The algorithm tries to expand the set cautiously. Unless the
psiblast hits share high identity (~75%) with the profile, the set
grows by no more than a factor of 2 each round.  If '-stop
max_psiblast_rounds' is not specified, the process runs to convergence
or until the number of profile sequences reaches 500, at which point a
clear pattern should have emerged in the aligned profile sequences.

The command-line options only affect the final round of
psiblast. Customized psiblast options are used in the iterative
rounds.

=item -fast

With the -fast option, fast trimming (trim to conserved domains) is used.

=item -nr min_seqs_for_reps

Only use representative seqs if number of seqs exceeds this threshold (D = 10)

=item -nq max_query_seqs

Stop incremental search if the number of query sequences exceeds this threshold (D = 500)

=item -rep

Collapse profile seqs into representatives before submitting to
psiblast if the number of profile sequences is equal or greater than
min_seqs_for_reps in a psiblast round.

=item -sim max_reps_sim

Specifies the threshold to use for collapsing seqs into representatives (D = 0.95)

=item -stop max_psiblast_rounds

Stop incremental search after a specified number of psiblast rounds (D = unlimited).

=back 

=head2 Input

The input search profile is a FASTA alignment read from STDIN.

=head2 Output

The set of hits is written to STDOUT. Coordinates of the extracted
sequences are appended to the FASTA comment field.

If the -inc option is specified, psiblast history is produced as a
4-column table, and written to STDERR. The rows correspond to search
status at each psiblast round.

  [ profile_length, num_starting_seqs, num_trimmed_reps, num_psiblast_hits ]

=cut

use AlignTree;
use ATserver;
use SeedUtils;

use gjoalignment;
use gjoseqlib;

my $usage = <<"End_of_Usage";

usage: svr_psiblast_search [options] < ali.trimmed.fa > hits.fa

       -a   n_processor     - number of processors to use (D = 2)
       -b   database        - database to search against: SEED, CORE, PSEED, PUBSEED (D), FASTA file name, FIG genome ID
       -c   min_frac_cov    - minimum fraction coverage of query and subject sequence (D = 0.20)
       -cq  min_q_cov       - minimum fraction coverage of query sequence (D = 0.50)
       -cs  min_s_cov       - minimum fraction coverage of subject sequence (D = 0.20)
       -e   max_e_val       - maximum psiblast e-Value (D = 0.01)
       -i   min_ident       - minimum fraction identity (D = 0.15)
       -l                   - run search locally if a local database is specified
       -n   max_num_seqs    - maximum matching sequences (D = 5000)
       -p   min_positive    - minimum fraction positive scoring (D = 0.20)
       -r   report_file     - output file of psiblast report
       -u   max_q_uncov     - maximum unmatched query (D = 20)
       -uc  max_q_uncov_c   - maximum unmatched query, c-term (D = 20)
       -un  max_q_uncov_n   - maximum unmatched query, n-term (D = 20)

       options for incremental search:

       -inc                 - incrementally expand an initial set of of sequences through multiple psiblast rounds
       -fast                - use fast trimming (trim to conserved domains) (D = 0)
       -nr   min_reps       - only use representative seqs if number of seqs exceeds this threshold (D = 10)
       -nq   max_nquery     - stop incremental search if the number of query sequences exceeds this threshold (D = 500)
       -rep                 - collapse profile seqs into representatives before submitting to psiblast
       -sim  max_reps_sim   - threshold used to collapse seqs into representatives (D = 0.95)
       -stop max_rounds     - stop incremental search after a specified number of psiblast rounds (D = until convergence) 

  Psiblast report is a 11-column table containing the following fields:

    [ subject_id, bit_score, e_value,
      subject_length, status,
      fraction_ident, fraction_positive,
      query_uncov_n_term, query_uncov_c_term,
      subject_uncov_n_term, subject_uncov_c_term ]

  Search history is produced for incremental psiblast search as a
  4-column table, with the rows corresponding to search status at each
  psiblast round:

     [ profile_length, num_starting_seqs, num_trimmed_reps, num_psiblast_hits ]

End_of_Usage


my ($help, $local, $url, $db, $report_f, $max_e_val, $min_ident, $min_pos, $cov, $cq, $cs,
    $nres, $nthread, $uncov, $uc, $un, $inc, $min_reps, $reps, $sim, $stop, $max_nq, $fast);

GetOptions("h|help"   => \$help,
           "l|local"  => \$local, 
           "url=s"    => \$url,
           "a=i"      => \$nthread,
           "b|db=s"   => \$db,
           "c|cov=f"  => \$cov,
           "cq=f"     => \$cq,
           "cs=f"     => \$cs,
           "e=f"      => \$max_e_val,
           "i=f"      => \$min_ident,
           "n=i"      => \$nres,
           "p=f"      => \$min_pos,
           "r=s"      => \$report_f,
           "u=i"      => \$uncov,
           "uc=i"     => \$uc,
           "un=i"     => \$un,
           "inc"      => \$inc,
           "nr=i"     => \$min_reps,
           "nq=i"     => \$max_nq,
           "fast"     => \$fast,
           "rep"      => \$reps,
           "s|sim=f"  => \$sim,
           "stop=i"   => \$stop);

$help and die $usage;

my $opts;

$opts->{max_e_val}         = $max_e_val if $max_e_val;
$opts->{max_query_nseq}    = $max_nq    if $max_nq;
$opts->{max_q_uncov}       = $uncov     if $uncov;
$opts->{max_q_uncov_c}     = $uc        if $uc;
$opts->{max_q_uncov_n}     = $un        if $un;
$opts->{min_frac_cov}      = $cov       if $cov;
$opts->{min_q_cov}         = $cq        if $cq;
$opts->{min_s_cov}         = $cs        if $cs;
$opts->{min_ident}         = $min_ident if $min_ident;
$opts->{min_positive}      = $min_pos   if $min_pos;
$opts->{nresult}           = $nres      if $nres;
$opts->{nthread}           = $nthread   if $nthread;
$opts->{report}            = 1          if $report_f; 
$opts->{incremental}       = 1          if $inc;
$opts->{use_reps}          = 1          if $reps;
$opts->{fast}              = 1          if $fast;
$opts->{min_seqs_for_reps} = $min_reps  if $min_reps;
$opts->{max_reps_sim}      = $sim       if $sim;
$opts->{stop_round}        = $stop      if $stop;
$opts->{db}                = $db        if $db;


$opts->{db}      = $db if -s $db && $local;
$opts->{db}    ||= gjoseqlib::read_fasta($db) if -s $db;
$opts->{profile} = gjoseqlib::read_fasta();

$opts->{db} ||= $ENV{SAS_SERVER} || 'PUBSEED';

my $AT;
my ($ret, $hits, $report, $history);

if ($local) {
    ($hits, $report) = AlignTree::psiblast_search($opts);
} else {
    $AT      = ATserver->new(url => $url);
    $ret     = $AT->psiblast_search($opts);
    $hits    = $ret->{rv};
    $report  = $ret->{report};
    $history = $ret->{history};
}

if ($opts->{report}) {
    my $report_string = join("\n", map { join "\t", @$_ } sort { $b->[1] <=> $a->[1] } values %$report) . "\n";
    AlignTree::print_string($report_f, $report_string);
}

if ($history && @$history) {
    print STDERR join("\t", @$_, "\n") for @$history;
}

gjoseqlib::print_alignment_as_fasta($hits);    

