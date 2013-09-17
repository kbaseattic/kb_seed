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

=head1 svr_find_fused_genes

  svr_find_fused_genes [options] [<seqs.fa] >fusion.tbl

Find genes that are homologous to the query genes and prints a list
of fusions among them.

Examples:

  svr_find_fused_genes -peg 'fig|83333.1.peg.784'  

  svr_find_fused_genes < query.fasta > fusions.table

  svr_find_fused_genes  -o hits.fasta  -r report  -t tree.html  < query.fasta  > fusion.table

=head2 Introduction

usage: svr_find_fused_genes [options] [<seqs.fa] >fusion.tbl

       -a   n_processor     - number of processors to use (D = 4)
       -b   database        - database to search against: SEED (D), PSEED, PPSEED, FASTA file name, FIG genome ID
       -i   min_ident       - minimum fraction identity (D = 0.1)
       -u   max_q_uncov     - maximum unmatched query (D = 100)
       -r   report_file     - output file of psiblast report
       -o   output          - output psiblast search hits in fasta       
       -t   html_tree       - output html tree painted with fusion genes
       -l                   - run search locally if a local database is specified
       -peg fid             - query gene ID

=head2 Command-Line options

=over 4

=item -a n_processor

Number of processors to use (D = 2 locally or 4 remotely)

=item -b database

Database for psiblast to search against. It can be a FASTA file name,
a FIG genome ID, or a string, SEED, PSEED or PPSEED, to indicate one of the
preconfigured database of all protein sequences from complete
genomes. The default is SEED.

=item -i min_ident

Minimum fraction identity used in psi-blast search (D = 0.1).

=item -l 

With the -l option, psiblast search is run locally. The database must
be a local FASTA file.

=item -u max_q_uncov

Maximum unmatched query, c-term or n-term (D = 100).

=item -o output_file

With the -o option, psiblast hits are written to a FASTA file.

=item -r report_file

Output file name for psiblast records produced as a 11-column table containing:

  [ subject_id, bit_score, e_value,
    subject_length, status,
    fraction_ident, fraction_positive,
    query_uncov_n_term, query_uncov_c_term,
    subject_uncov_n_term, subject_uncov_c_term ]

=item -t html_tree

With the -t option, a HTML tree is generated with the functional roles
of sequences colored and the fused genes highlighted.

=back

=head2 Input

The input search profile is a FASTA file read from STDIN or a PEG ID
specified with the -peg option.

=head2 Output

The set of predicted fused genes is written to STDOUT. 

  [ fused_gene_ID, subject_uncov_n_term, subject_uncov_c_term ]

=cut


use AlignTree;
use ATserver;
use SeedAware;
use SeedUtils;

use ffxtree;
use gjoalignment;
use gjoseqlib;

my $usage = <<"End_of_Usage";

usage: svr_find_fused_genes [options] [<seqs.fa] >fusion.tbl

       -a   n_processor     - number of processors to use (D = 4)
       -b   database        - database to search against: SEED (D), PSEED, PPSEED, FASTA file name, FIG genome ID
       -i   min_ident       - minimum fraction identity (D = 0.1)
       -u   max_q_uncov     - maximum unmatched query (D = 100)
       -r   report_file     - output file of psiblast report
       -o   output          - output psiblast search hits in fasta       
       -t   html_tree       - output html tree painted with fusion genes
       -l                   - run search locally if a local database is specified
       -peg fid             - query gene ID

End_of_Usage

my ($help, $local, $db, $nthread, $uncov, $min_ident, $report_file, $html_tree, $output, $query_peg);

GetOptions("h|help"   => \$help,
           "l|local"  => \$local, 
           "a=i"      => \$nthread,
           "b|db=s"   => \$db,
           "i=f"      => \$min_ident,
           "u=i"      => \$uncov,
           "o=s"      => \$output,
           "r=s"      => \$report_file,
           "t=s"      => \$html_tree,
           "peg=s"    => \$query_peg);

$help and die $usage;

my $opts;

$opts->{nthread}     = $nthread || ($local ? 2 : 4);
$opts->{db}          = gjoseqlib::read_fasta($db) if -s $db;
$opts->{db}        ||= $ENV{SAS_SERVER} || 'SEED';
$opts->{max_q_uncov} = $uncov     || 100;
$opts->{min_ident}   = $min_ident || 0.1;

$opts->{incremental}    = 1;
$opts->{fast}           = 1;
$opts->{max_query_nseq} = 200;

if ($query_peg) {
    my $data = SeedAware::run_gathering_output("echo '$query_peg' | svr_fasta -protein -fasta") or die "Abort: no query sequences.\n";
    $opts->{profile} = gjoseqlib::read_fasta(\$data);
} else {
    $opts->{profile} = gjoseqlib::read_fasta();
}

my ($AT, $hits, $report, $ret);

if ($local) {
    ($hits, $report) = AlignTree::psiblast_search($opts);
} else {
    $AT      = ATserver->new();
    $ret     = $AT->psiblast_search($opts);
    $hits    = $ret->{rv};
    $report  = $ret->{report};
}

if ($report_file) {
    my $report_string = join("\n", map { join "\t", @$_ } sort { $b->[1] <=> $a->[1] } values %$report) . "\n";
    AlignTree::print_string($report_file, $report_string);
}

gjoseqlib::print_alignment_as_fasta($output, $hits) if $output;

my @incl   = grep { $report->{$_}->[4] =~ /included/i } keys %$report or die "No sequences found.\n";
my @uncov1 = sort { $a <=> $b } map { $report->{$_}->[9]  } @incl;
my @uncov2 = sort { $a <=> $b } map { $report->{$_}->[10] } @incl;
my $mid1   = $uncov1[int(@uncov1/2)];
my $mid2   = $uncov2[int(@uncov2/2)];

my @fusions;
for (@incl) {
    my ($u1, $u2) = @{$report->{$_}}[9, 10];
    my $fu1 = $u1 if $u1 > max($mid1 + 50, 100);
    my $fu2 = $u2 if $u2 > max($mid2 + 50, 100);
    if ($fu1 || $fu2) {
        print join("\t", $_, $u1, $u2) . "\n";
        my $str = join("\t", $_, 'Fusion:');
        $str .= " beg=$fu1" if $fu1;
        $str .= " end=$fu2" if $fu2;
        push @fusions, $str;
    }
}

if ($html_tree) {
    my $tmpdir = SeedAware::location_of_tmp();
    my $tmpin1 = SeedAware::new_file_name("$tmpdir/psiblast_hits", 'fa');
    my $tmpin2 = SeedAware::new_file_name("$tmpdir/fusion_ends",  'txt');
    my $fusion = join("", map { $_."\n" } @fusions);
    gjoseqlib::print_alignment_as_fasta($tmpin1, $hits);
    AlignTree::print_string($tmpin2, $fusion);
    SeedUtils::run("svr_align_seqs -mafft <$tmpin1 | svr_tree | svr_tree_to_html -c role -nc 20 -anno -p none -f $tmpin2 -d $tmpin2 >$html_tree");
    for ($tmpin1, $tmpin2) { unlink $_ if -e $_ };
}


