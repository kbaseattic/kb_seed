use strict;
use Data::Dumper;
use Carp;
use gjonewicklib;

#
# This is a SAS Component
#

=head1 svr_reroot_tree

Reroot a tree at a different node or a point on an internal arc.

=head2 Introduction

Examples:

    svr_reroot_tree -m < tree.nwk > rerooted.tree.wk [to midpoint of tree (an approximation of that)]
    svr_reroot_tree 'Deh.eth.19,Sph.the.DS,Deh.sp.CBD' < tree.nwk > rerooted.tree.nwk [at a node in an unrooted tree]
    svr_reroot_tree 'Deh.eth.19,Deh.sp.CBD' < tree.nwk > rerooted.tree.nwk [at an internal node in a rooted tree]
    svr_reroot_tree 'Deh.eth.19'            < tree.nwk > rerooted.tree.nwk [at a tip]
    svr_reroot_tree -t 'Deh.eth.19'            < tree.nwk > rerooted.tree.nwk [at a node next to a tip]

To reroot to a point on an arc between two nodes, use 

       svr_reroot_tree -f 0.5 NODE1 NODE2 < tree.nwk > rerooted.tree.nwk [NODE1 and NODE2 can be 1, 2,or 3 ids]
e.g.,  
       svr_reroot_tree -f 0.5 Deh.eth.19 'Deh.eth.19,Deh.sp.CBD' < tree.nwk > rerooted.tree.nwk [NODE1 and NODE2 can be 1, 2,or 3 ids]
or     svr_reroot_tree -d 1.5 Deh.eth.19 'Deh.eth.19,Deh.sp.CBD' < tree.nwk > rerooted.tree.nwk [NODE1 and NODE2 can be 1, 2,or 3 ids]


=head2 Command-Line Arguments

The program is invoked using

    svr_reroot_tree [-m] [-t] [-f Fraction] [-d Distance] Node(s)

    The operation may require one or two nodes to be specified; these
    immediately follow the optional arguments.  A node is specified
    as a string containing 1 to 3 IDs comma-separated.

=over 4

=item -m

Root at the midpoint of the tree (an approximation)

=item -t

Root at the parent node of the specified tip (i.e., there should be a single node given,
and it should be a single tip ID).

=item -f=Fraction

Specifies the fraction along the path from NODE1 to NODE2 that you wish to place the root at

=item -d=Distance

Specifies the distance along the path from NODE1 to NODE2 that you wish to place the root at

=back

=head2 Output

A rerooted tree in newick format.

=cut

use Getopt::Long;
my $midpoint = 0;
my $root_at_parent = 0;
my $fraction;
my $distance;
my $usage = "svr_corresponding_genes [-m] [-t] [-f Fraction] [-d Distance] Node(s) < tree > rerooted\n";

my $rc = GetOptions( "m" => \$midpoint,
		     "a"   => \$root_at_parent,
                     "f=f" => \$fraction,
                     "d=f" => \$distance
		   );

$rc or print STDERR $usage and exit;

if (($fraction || $distance) && (@ARGV != 2))
{
    print STDERR "You need to specify two nodes when rerooting to a point on a path\n";
    print STDERR $usage;
    exit;
}

if ((! defined($fraction)) && (! defined($distance)) && (@ARGV == 2))
{
    print STDERR "You need to specify fraction or distance when rerooting to a point on a path\n";
    print STDERR $usage;
    exit;
}

if ($root_at_parent && (@ARGV != 1))
{
    print STDERR "You need to specify a single tip node when rerooting to the parent of a tip\n";
    print STDERR $usage;
    exit;
}

if ($midpoint && (@ARGV != 0))
{
    print STDERR "You have extra arguments (rerooting to the midpoint of a tree requires no nodes\n";
    print STDERR $usage;
    exit;
}

if ((@ARGV == 0) && (! $midpoint))
{
    print STDERR "You are missing arguments (node(s) are required if not rerooting to a midpoint)\n";
    print STDERR $usage;
    exit;
}

my @args = map { [split(/,/,$_)] } @ARGV;

my $tree  = &gjonewicklib::read_newick_tree( );

my $rerooted = &gjonewicklib::reroot_tree($tree, { midpoint => $midpoint,
					           adjacent_to_tip => $root_at_parent,
					           fraction => $fraction,
					           distance => $distance,
					           nodes    => \@args
					         });

&gjonewicklib::writeNewickTree( $rerooted );
