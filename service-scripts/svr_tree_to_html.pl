#
# This is a SAS Component
#

#
# Copyright (c) 2003-2011 University of Chicago and Fellowship
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

=head1 svr_tree_to_html

    svr_tree_to_html [options] < tree.newick > tree.html

This script converts a newick tree into an HTML page. It has a rich
set of options.

=head1 Introduction

usage: svr_tree_to_html [options] < tree.newick > tree.html

       -a   alias_file    - relabel tips using aliases        # table: [id alias]
       -b                 - show bootstrap/branch support values
       -bar               - show scale bar
       -c   tax|role|file - color tips by taxonomy, roles,
                            or groups specified in a file     # table: [id group]
       -d   desc_file     - add description to each tip       # table: [id description]
       -f   focus_list    - highlight a list of tips          # table: [id]
       -k   keep_list     - keep only the taxa listed         # table: [id]
       -l   link_file     - add URL to each tip               # table: [id URL]
       -lt  link_w_text   - add additional linked text        # table: [id text URL]
       -m   popup_file    - add simple mouseover to each tip  # table: [id popup]
       -nc  n_colors      - number of colors to use (D = 10)
       -p   g|s|file      - collapse trees by genus, species,
                            or groups specified in a file     # table: [id group]
       -s   show_list     - preferred tips to show when collapsing subtrees
                            (D = Woese' list of 69 common organisms)
       -t   title         - title for html page               
       -units label       - units label for scale bar; implies -bar
       -va  fa1[,fa2,..]  - vector annotation files    
       -x   min_dx        - minimum horizontal space between consecutive nodes (D = 1)
       -y   dy            - vertical separation of consecutive tips (D = 1)

       -anno              - use the annotator's SEED for URLs
       -gray n            - gray out name from the n-th word  # default: 2
       -pseed             - use PSEED
       -ppseed            - use PUBSEED
       -raw               - do not color or collapse tree,
                            may be superseded by -c and -p

=head2 Command-line options

=over 4

=item -a alias_file

The sequence IDs in the FASTA file may not be what a user wants to see
in the visualized tree. The alias file is a two-column table
containing ID to alias mapping [ id alias ], and the tree tips will be
relabeled with the aliases. 

The alias file can also be used to supply a mapping from original
sequence ID to FIG peg ID. With FIG ids, taxonomoy and function
information can be automatically retrieved from the SEED server and
painted to the tree tips.

=item -b 

With the -b option, bootstrap values (or branch support values) are
shown in percent for internal nodes of the tree. min_dx and dy are set
to 2 unless they are explicitly specified.

=item -bar

Include a scale bar on the drawing.

=item -c tax | role | group_file

The value for the -c option can be a string ('tax' or 'role') or the
name of a two-column table [ id, group ] that classifies the sequences
into multiple groups. Correspondingly, the tips of the tree will be
colord according to their major taxonomy group, functional role, or
the customized group.

If tips are colored based on taxonomy groups, a taxonomy legend is
shown. Otherwise, a table of color group (functional role by default)
frequencies is shown.

The default behavior is to color tree tips by taxonomy groups.

=item -d description_file

A two-column table [ id, description ]. The description string will
appear in parentheses after the sequence ID for each tip of the tree.

=item -f focus_list

A file with space-delimited IDs for sequences to be highlighted.

=item -k keep_list

Keep only the taxa listed (one per line) in the file keep.

=item -l link_file

A two-column table [ id, url ] for inserting URL for tree tips.

=item -lt linked_text_file

A three-column table [ id, text, url ] for inserting linked text for tree tips.

=item -m mouseover_file

A two-column table [ id, mouseover_description ]. The mouseover
description string will appear in the popup box for the specified tip.

=item -nc n_colors

The number of colors to use for tree tips (D = 10). Max: 20.

=item -p  g | s | group_file

This option provides a rule for collapsing subtrees whose tips all
belong to the same group. The value for the -p option can be a string
('g' for genus, or, 's' for species), or the name of a two-column
table [ id, group ] that classifies the sequenes into multiple groups.

The default behavior is to collapse subtrees whose nodes all belong to
the same genus.

=item -s show_list (D = Woese' list of 69 common organisms)

Show a list of preferred tips when collapsing subtrees.

=item -t html_title

This title of the HTML page.

=item -units scale_bar_units

Include a scale bar with the specified units (inplies -bar).

=item -x n

Specifies the minimum length of a distance between two nodes. (D = 1)

=item -y n

Specifies vertical separation of consecutive tips. (D = 1)

=item -anno

With the -anno option, the tree tips will be linked to the annotator's
SEED instead of the SEED viewer.

=item -gray n

Gray out the tip names after the n-th word. (D = 2)

=item -pseed

With the -pseed option, the taxonomy and function information is
retrieved from the PSEED server. Setting the environment variable
SAS_SERVER to 'PSEED' has the same effect.

=item -ppseed

With the -ppseed option, the taxonomy and function information is
retrieved from the PUBSEED server. Setting the environment variable
SAS_SERVER to 'PUBSEED' has the same effect.

=item -raw

Do not color or collapse the tree. This option maybe superseded if -c
or -p is present.

=back 

=head2 Input

The input tree is a newick file read from STDIN.

=head2 Output

The output is a HTML page written to STDOUT. 

=cut

use AlignTree;
use ATserver;
use SeedUtils;

use ffxtree;
use gjoalignment;
use gjonewicklib;
use gjoseqlib;

my $usage = <<"End_of_Usage";

usage: svr_tree_to_html [options] < tree.newick > tree.html

       -a   alias_file    - relabel tips using aliases        # file: [id alias]
       -b                 - show bootstrap/branch support values
       -bar               - show scale bar
       -c   tax|role|file - color tips by taxonomy, roles,
                            or groups specified in a file     # file: [id group]
       -d   desc_file     - add description to each tip       # file: [id description]
       -f   focus_list    - highlight a list of tips          # file: [id]
       -k   keep_list     - keep only the taxa listed         # table: [id]
       -l   link_file     - add URL to each tip               # file: [id URL]
       -lt  link_w_text   - add additional linked text        # file: [id text URL]
       -m   popup_file    - add simple mouseover to each tip  # file: [id popup]
       -nc  n_colors      - number of colors to use (D = 10)
       -p   g|s|file      - collapse trees by genus, species,
                            or groups specified in a file     # file: [id group]
       -s   show_list     - preferred tips to show when collapsing subtrees
                            (D = Woese' list of 69 common organisms)
       -t   title         - title for html page               
       -units label       - units label for scale bar; implies -bar
       -va  fa1[,fa2,..]  - vector annotation files    
       -x   min_dx        - minimum horizontal space between consecutive nodes (D = 1)
       -y   dy            - vertical separation of consecutive tips (D = 1)
       -anno              - use the annotator's SEED for URLs
       -gray n            - gray out name from the n-th word  # default: 2
       -pseed             - use PSEED
       -ppseed            - use PUBSEED
       -raw               - do not color or collapse the tree,
                            may be superseded by -c and -p

End_of_Usage

my ($help, $url, $alias_file, $focus_file, $branch, $collapse_by, $show_file,
    $desc_file, $keep_file, $link_file, $text_link, $popup_file, $id_file, $title,
    $min_dx, $dy, $ncolor, $color_by, $anno, $gray, $pseed, $ppseed, $raw, $va_files,
    $scale_bar, $scale_lbl);

GetOptions("h|help"         => \$help,
           "a|alias=s"      => \$alias_file,
           "bar"            => \$scale_bar,    # include a scale bar
           "b|branch"       => \$branch,
           "c|color=s"      => \$color_by,
           "d|desc=s"       => \$desc_file,
           "f|focus=s"      => \$focus_file,
           "i|id=s"         => \$id_file,
           "k|keep=s"       => \$keep_file,
           "l|link=s"       => \$link_file,
           "lt=s"           => \$text_link,
           "m|popup=s"      => \$popup_file,
           "nc=i"           => \$ncolor,
           "p|collapse=s"   => \$collapse_by,
           "s|show=s"       => \$show_file,
           "t|title=s"      => \$title,
           "units=s"        => \$scale_lbl,    # units label for scale bar
           "va=s"           => \$va_files,
           "x|dx=i"         => \$min_dx,
           "y|dy=i"         => \$dy,
           "anno"           => \$anno,
           "g|gray=s"       => \$gray,
           "pseed"          => \$pseed,
           "ppseed"         => \$ppseed,
           "raw"            => \$raw);

$help and die $usage;

my @va;
if ($va_files) {
    for my $vaF (split(/,/, $va_files)) {
        my $anno = ffxtree::read_vector_annotation($vaF);
        push @va, $anno if $anno;
    }
}

my $opts = {};

$opts->{show_branch}   = $branch;
$opts->{color_by}      = $color_by;
$opts->{collapse_by}   = $collapse_by;
$opts->{focus_set}     = ffxtree::read_set($focus_file)    if $focus_file    && -s $focus_file;
$opts->{alias}         = ffxtree::read_hash($alias_file)   if $alias_file    && -s $alias_file;
$opts->{color_by}      = ffxtree::read_hash($color_by)     if $color_by      && -s $color_by;
$opts->{collapse_by}   = ffxtree::read_hash($collapse_by)  if $collapse_by   && -s $collapse_by;
$opts->{collapse_show} = ffxtree::read_set($show_file)     if $show_file     && -s $show_file;
$opts->{keep}          = ffxtree::read_set($keep_file)     if $keep_file     && -s $keep_file;
$opts->{desc}          = ffxtree::read_hash($desc_file)    if $desc_file     && -s $desc_file;
$opts->{popup}         = ffxtree::read_hash($popup_file)   if $popup_file    && -s $popup_file;
$opts->{link}          = ffxtree::read_hash($link_file)    if $link_file     && -s $link_file;
$opts->{text_link}     = ffxtree::read_hash($text_link)    if $text_link     && -s $text_link;
$opts->{tree}          = ffxtree::read_tree();
$opts->{ncolor}        = $ncolor || 10;
$opts->{gray}          = $gray   || 2;
$opts->{min_dx}        = $min_dx || $branch ? 2 : 1;
$opts->{dy}            = $dy     || $branch ? 2 : 1;
$opts->{title}         = $title;
$opts->{anno}          = $anno;
$opts->{raw}           = $raw;
$opts->{scale_bar}     = $scale_bar if $scale_bar;
$opts->{scale_lbl}     = $scale_lbl if defined $scale_lbl;
$opts->{anno_vectors}  = \@va       if @va;

$opts->{color_by}      ||= $raw ? 'none' : 'taxonomy';
$opts->{collapse_by}   ||= $raw ? 'none' : 'genus';
$opts->{collapse_show} ||= $raw ? 'none' : 'woese';

$opts->{color_by}      = 0 if $opts->{color_by}    =~ /^none$/i;
$opts->{collapse_by}   = 0 if $opts->{collapse_by} =~ /^none$/i;
$opts->{collapse_show} = 0 if $show_file           =~ /^none$/i;

my $envParm = $ENV{SAS_SERVER};

$ENV{SAS_SERVER} = 'PSEED'   if $pseed;
$ENV{SAS_SERVER} = 'PUBSEED' if $ppseed;

my $html = ffxtree::tree_to_html($opts);

$ENV{SAS_SERVER} = $envParm if $pseed || $ppseed;

print $html;
