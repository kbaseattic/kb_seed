# This is a SAS component.

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

package TreeFC;

use Carp;
use Data::Dumper;
use strict;

use gjonewicklib;
use SeedEnv;


sub merge_gene_pairs {
    my($args) = @_;

#        fids        => list of tuples of the form [fid,md5,gid,contig,len,beg,end,midpt,index,num_in_cntig]
#        tree_tips1  => list of [tipId,fid,LenP,trimB,trimE]
#        tree_tips2  => list of [tipId,fid,lenP,trimB,trimE]
#        howClose    => minimum diff in peg indexes

    $args->{howClose} || ($args->{howClose} = 5);

    my %locs = map { my($fid,undef,undef,$contig,undef,undef,undef,undef,$index,undef) = @$_;
		     ($fid => [$contig,$index]) 
                   } @{$args->{fids}};

    my $tipL1 = $args->{tree_tips1};
    my $tipL2 = $args->{tree_tips2};
    my %tip1H;
    foreach $_ (@$tipL1)
    {
	my($tipId,$fid) = @$_;
	my $g           = SeedUtils::genome_of($fid);
	$tip1H{$g}      = [$tipId,$fid];
    }

    my @pairs;
    foreach my $tuple2 (@$tipL2)
    {
	my($tipId2,$fid2) = @$tuple2;
	my $g      = SeedUtils::genome_of($fid2);
	my $tuple1 = $tip1H{$g};
	if ($tuple1)
	{
	    my($tipId1,$fid1) = @$tuple1;
	    if ($fid1)
	    {
		my $loc1 = $locs{$fid1};
		my $loc2 = $locs{$fid2};

		if ($loc1 && $loc2)
		{
		    my($contig2,$index2) = @$loc2;
		    my($contig1,$index1) = @$loc1;
		    if (($contig1 eq $contig2) &&
			(abs($index1 - $index2) <= $args->{howClose}) &&
			($index1 != $index2))
		    {
			push(@pairs,[$tipId1,$tipId2]);
		    }
		}
	    }
	}
    }
    return \@pairs;
}

sub score_coupling {
    my ($args) = @_;
    $args->{close} ||= 0.3;

#        tipPairs    => list of tuples of the form [tipId1,tipId2]
#        tree1       => a gjo tree
#        tree2       => a gjo tree
#       
    my $score    = 0;
    my $tipPairs = $args->{tipPairs};
    my @tips1    = map { $_->[0] } @$tipPairs;
    my @tips2    = map { $_->[1] } @$tipPairs;
    my $tree1    = $args->{tree1};
    my $tree2    = $args->{tree2};
    if ((@tips1 > 2) && (@tips2 > 2) && $tree1 && $tree2)
    {
	my $tree_coupled1 = gjonewicklib::newick_subtree($tree1,\@tips1);
	my $tree_coupled2 = gjonewicklib::newick_subtree($tree2,\@tips2);
	my $rep1          = gjonewicklib::representative_tips($tree_coupled1,$args);
	my $rep2          = gjonewicklib::representative_tips($tree_coupled2,$args);
	my $sz1           = @$rep1;
	my $sz2           = @$rep2;
	$score = ($sz1 < $sz2) ? $sz1 : $sz2;
    }
    return $score;
}

1;
