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

=head1 svr_cohesion_groups

    svr_cohesion_groups [options] < tree.newick > cohesion_groups.table

This script classifies tips of a newick tree into cohesion groups
based on bootstrap values of tree branches.

=head1 Introduction

A cohesion group is a collection of protein sequences from various
organisms whose amino acid sequences assemble as a compact cluster on
a phylogenetic tree.

See Roy A. Jensen's cohesion group analysis (PubMed ID: 18322033)

=head2 Command-line options

=over 4

=item -c bootstrap_cutoff

Specifies the threshold of branch support value for collapsing subtrees. (D = 0.85)

=item -f max_CG_size_in_fraction

Max fraction of a cohesion group (D = 0.20).

=item -m max_CG_size

Max size of a cohesion group (D = number of tips in tree).

=item -o 

With the -o option, all orphan cohesion groups are labeled as 'Orp'.

=back 

=head2 Input

The input tree is a newick file read from STDIN.

=head2 Output

The output is a two-column table [ tip_id, cohesion_group_id ] written to STDOUT.

=cut

use AlignTree;
use ATserver;
use SeedUtils;

use ffxtree;
use gjoalignment;
use gjoseqlib;

my $usage = <<"End_of_Usage";

usage: svr_cohesion_groups [options] < tree.newick > cohesion_group.table

       -c cutoff    - collapse subtrees whose root branch has support
                      values greater than cutoff (D = 0.85)
       -f fraction  - max fraction of a cohesion group (D = 0.20)
       -m size      - max size of a cohesion group (D = number of tips in tree)
       -o           - label all orphan groups as 'Orp'

End_of_Usage

my ($help, $cutoff, $fract, $maxcg, $orphan, $single);

GetOptions("h|help"         => \$help,
           "c|cutoff=f"     => \$cutoff,
           "f|fract=f"      => \$fract,
           "m|maxcg=i"      => \$maxcg,
           "o|orphan"       => \$orphan,
           "s|single"       => \$single);

$help and die $usage;

$cutoff ||= 0.85;
$fract  ||= 0.50;

my $tree = ffxtree::read_tree();
my $opts = { 'cg_cutoff' => $cutoff, "max_fract" => $fract, 'max_cg_size' => $maxcg, 'show_orphan' => $orphan, 'single_collapse' => $single };
my $cg   = ffxtree::make_cohesion_groups($tree, $opts);

if ($cg) {
    print join("\t", $_, $cg->{$_}). "\n" for keys %$cg;
}

