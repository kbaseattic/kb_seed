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

=head1 svr_tree

    svr_tree [options] < ali.fa > tree.newick

This script uses fasttree, PhyML or RAxML to build a
maximum-likelihood tree from a FASTA alignment, or evaluates the
likelihood of an input tree against a given alignment.

Example:  svr_tree -e -phyml -i aaa.tree < aaa.ali

would evaluate the likelihood of aaa.tree using PhyML.

=head2 Introduction

usage: svr_tree [options] < ali.fa > tree.newick

       -tool fasttree (D), phyml, raxml

       -b  n_bootstraps  - number of bootstrap samples (D = 0)
       -c  num_classes   - number of substitution categories (D = 4)
       -e                - evaluate the log likelihood of a given tree
       -g  log_file      - log file with time and likelihood information
       -i  tree_file     - input tree file for likelihood evaluation 
       -l                - construct tree locally 
       -m  model         - substitution model
       -n  num_procs     - number of processors to use for bootstraps
       -p  param_str     - parameter string for tree tool
       -r                - use gamma distribution for substitution rates
       -s                - use SPR for tree topology search (more expensive than NNI)
       -t  file_name     - output tree file (can be used in combination with -e)

=head1 Command-Line options

=over 4

=item -b bootstraps

The number of bootstrap samples.

=item -c nclasses

The number of categories of substitution rates. 

=item -e

With the -e option, the likelihood of an input tree (specified by the -i option) 
is evaluated.

=item -g log_file

The log file name.

=item -i tree_file

The name of tree file whose log likelihood is to be evaluated.

=item -l

With the -l option, tree construction or likelihood evaluation is done olocally.

=item -m model

Sequence substitution model:

Nucleotides:

  fasttree: GTR

  PhyML: HKY85 (d), JC69, K80, F81, F84, TN93

  RAxML: GTR

Amino acids:

  fasttree: GTR

  PhyML: LG (d), WAG, JTT, MtREV, Dayhoff, DCMut

  RAxML: WAG (d), JTT, Dayhoff, DCMUT, METREV, RTREV, CPREV, VT, BLOSSUM62, MTNAM, GTR 

=item -n num_procs

Number of processors to use for bootstraps.

=item -p param_str

The raw parameter string for a tree building tool, which may be
superseded by other options if there is an overlap. It can be used to
set options that are not universal to all tree building programs.

For example, in the following command, the conflicting 'model' option
will be resolved to be 'JTT', but the 'search' option will be set to
'BEST' which is only available to PhyML.

svr_tree -tool=phyml -p '-m WAG -s BEST' -m JTT < ali.fa > tree.newick

=item -r 

With the -r option, the discretized gamma distribution is used for
substitution rates. 

=item -s 

With the -s option, both fasttree and PhyML will try to use the SPR
(Subtree Pruning and Regrafting) operation, instead of the default,
less expensive, NNI operation, in the heuristic search for the best
tree topology. RAxML uses SPR by default. In fasttree, the number of
SPR rounds is set to 2 by default, and it can be customized with the
"-p '-spr x'" option.

=item t tree_file

The file name of the output tree to be saved.

=back

=head2 Input

The input set of aligned sequences is read from STDIN.

=head2 Output

If the -e option is set, the output is the log likelihood value of the
input tree; otherwise, it is the tree (in newick format) built from
the input alignment.

=cut

use AlignTree;
use ATserver;
use SeedUtils;

use ffxtree;
use gjoalignment;
use gjoseqlib;

my $usage = <<"End_of_Usage";

usage: svr_tree [options] < ali.fa > tree.newick

       -tool fasttree (D), phyml, raxml

       -b  n_bootstraps  - number of bootstrap samples (D = 0)
       -c  num_classes   - number of substitution categories (D = 4)
       -e                - evaluate the log likelihood of a given tree
       -g  log_file      - log file with time and likelihood information
       -i  tree_file     - input tree file for likelihood evaluation 
       -l                - construct tree locally 
       -m  model         - substution model
       -n  num_procs     - number of processors to use for bootstraps
       -p  param_str     - parameter string for tree tool
       -r                - use gamma distribution for substitution rates
       -s                - use SPR for tree topology search (more expensive than NNI)
       -t  file_name     - output tree file (can be used in combination with -e)

  Substition models supported in tools:

    |          | NT                  | AA                            |
    |----------+---------------------+-------------------------------|
    | fasttree | GTR                 | JTT                           |
    |----------+---------------------+-------------------------------|
    | phyml    | HKY85 (d), JC69,    | LG (d), WAG, JTT, MtREV,      |
    |          | K80, F81, F84, TN93 | Dayhoff, DCMut                |
    |----------+---------------------+-------------------------------|
    | raxml    | GTR                 | WAG (d), JTT, Dayhoff, DCMUT, |
    |          |                     | METREV, RTREV, CPREV, VT,     |
    |          |                     | BLOSSUM62, MTNAM, GTR         |

End_of_Usage

my ($help, $local, $url, $nc, $eval, $logfile, $intree, $model, $params, $gamma, $spr, $treefile, $bootstrap, $noml, $nome, $mllen, $nproc);
my ($tool, $fasttree, $raxml, $phyml);

GetOptions("h|help"         => \$help,
           "l|local"        => \$local,
           "url=s"          => \$url,
           "b=i"            => \$bootstrap,
           "c=i"            => \$nc,
           "e"              => \$eval,
           "g|log=s"        => \$logfile,
           "i|in=s"         => \$intree,
           "m=s"            => \$model,
           "n|np=i"         => \$nproc,
           "p=s"            => \$params,
           "r|gamma"        => \$gamma,
           "s|spr"          => \$spr,
           "t|tree=s"       => \$treefile,
           "tool|program=s" => \$tool,
           "phyml"          => \$phyml,
           "raxml"          => \$raxml,
           "fasttree"       => \$fasttree,
           "noml"           => \$noml,
           "nome"           => \$nome,
           "mllen"          => \$mllen);

$help and die $usage;

if    ($phyml)  { $tool   = "phyml"    }
elsif ($raxml)  { $tool   = "raxml"    }
else            { $tool ||= "fasttree" }

my $opts;

$opts->{tool}         = $tool;
$opts->{bootstrap}    = $bootstrap;
$opts->{nclasses}   ||= $nc || 4;
$opts->{optimize}     = $eval   ? 'eval'  : 'all';
$opts->{rate}         = $gamma  ? 'Gamma' : 'Uniform';
$opts->{search}       = $spr    ? 'SPR'   : 'NNI';
$opts->{model}        = $model     if $model;
$opts->{params}       = $params    if $params;
$opts->{logfile}      = $logfile   if $logfile;
$opts->{treefile}     = $treefile  if $treefile;
$opts->{noml}         = 1          if $noml;
$opts->{nome}         = 1          if $nome;
$opts->{mllen}        = 1          if $mllen;
$opts->{nproc}        = $nproc     if $nproc;  
$opts->{input}        = ffxtree::read_tree($intree) if $intree;
$opts->{ali}          = gjoseqlib::read_fasta();

!$eval || $opts->{input} or die $usage;

$opts->{nproc} = 4 if $nproc > 4 && !$local; # override maximum nproc on bio-big

my $AT;
my ($tree, $stats, $ret);

if ($local) {
    ($tree, $stats) = AlignTree::make_tree($opts);
} else {
    $AT    = ATserver->new(url => $url);
    $ret   = $AT->make_tree($opts);
    $tree  = $ret->{rv};
    $stats = $ret->{stats};
}

if ($eval) {
    print $stats->{logLk} . "\n";
} else {
    gjonewicklib::writeNewickTree($tree);    
}
