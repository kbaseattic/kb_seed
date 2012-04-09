package Corresponds;
use strict;
use Data::Dumper;
use Carp;
use ProtSims;

#
# This is a SAS component
#

# Column-1
sub id1
{
    return $_[0]->[0];
}

# Column-2
sub iden
{
    return $_[0]->[1];
}

# Column-3
sub npairs
{
    return $_[0]->[2];
}

# Column-4
sub beg1
{
    return $_[0]->[3];
}

# Column-5
sub end1
{
    return $_[0]->[4];
}

# Column-6
sub ln1
{
    return $_[0]->[5];
}

# Column-7
sub beg2
{
    return $_[0]->[6];
}

# Column-8
sub end2
{
    return $_[0]->[7];
}

# Column-9
sub ln2
{
    return $_[0]->[8];
}

# Column-10
sub sc
{
    return $_[0]->[9];
}

# Column-11
sub id2
{
    return $_[0]->[10];
}

use gjoseqlib;

sub correspondence_of_reps {
    my($seqs1,$locs1,$seqs2,$locs2,$sz_context,$max_overlaps) = @_;
    my @reps1 = &non_overlapping_pegs($locs1,$max_overlaps);
    my @reps2 = &non_overlapping_pegs($locs2,$max_overlaps);
    my %ids1 = map { ($_->[0]->[0] => 1) } @reps1;
    my @seqs1   = grep { $ids1{$_->[0]} } @$seqs1;
    my @locs1   = grep { $ids1{$_->[0]} } @$locs1;
    my %ids2 = map { ($_->[0]->[0] => 1) } @reps2;
    my @seqs2   = grep { $ids2{$_->[0]} } @$seqs2;
    my @locs2   = grep { $ids2{$_->[0]} } @$locs2;
    return (&build_corr(\@seqs1,\@locs1,\@seqs2,\@locs2,$sz_context),\@reps1,\@reps2);
}

# This routine takes as input a list of [peg,location] pairs: 
#                                       [fid,loc] where loc is [r1,r2,...] 
#                                  and  ri is [contig,beg,strand,len]
#
# It outputs a list of [fid,loc] pairs that have the property
# that none overlap more than a specified number of bps.
# A representative is chosen for each cluster of overlapping
# genes, and the projections will be to these representatives.
#
sub non_overlapping_pegs {
    my($fid_loc_pairs,$max_overlap) = @_;
    my @keep = ();
    my @sorted  = sort { ($a->[1]->[0] cmp $b->[1]->[0]) or 
			 (($a->[1]->[1] + $a->[1]->[2]) <=> 
			  ($b->[1]->[1] + $b->[1]->[2])) 
                       }
                  map { my($id,$loc) = @$_; [$id,&condense_loc($loc),$loc] } @$fid_loc_pairs;
#
#   We now have tuples of the form [Id,[Contig,Begin,End],Loc]    
#   We saved the full location for each Id, since they will be needed for
#   invoking build_corr/5.
#

    my $group;
    while ($group = &group(\@sorted,$max_overlap))
    {
	my $rep = (@$group == 1) ? $group->[0]  : &representative_of($group);
	push(@keep,[[$rep->[0],$rep->[2]],$group]);  # [keep [id,loc],group-represented]
    }
    return @keep;
}

sub group {
    my($sorted,$max_overlap) = @_;  # this routine grabs the start of the list, altering sorted
    
    if (my $x = shift @$sorted)
    {
	my $group = [$x];
	while ((@$sorted > 0) && (&overlaps_same_strand($group,$sorted->[0]) > $max_overlap))
	{
	    my $y = shift @$sorted;
	    push(@$group,$y);
	}
	return $group;
    }
    return undef;
}

sub overlaps_same_strand {
    my($group,$y) = @_;

    my $i;
    my $ov = 0;
    for ($i=0; ($i < @$group); $i++)
    {
	$ov = &max($ov,&overlaps_same_strand1($group->[$i],$y));
    }
    return $ov;
}

sub overlaps_same_strand1 {
    my($x,$y) = @_;

    if ($x eq 'kb|g.0.peg.1690') { confess 'BAD' }
    my($c1,$beg1,$end1) = @{$x->[1]};
    my($c2,$beg2,$end2) = @{$y->[1]};

    my $ov = 0;
    if ($c1 eq $c2)
    {
	if ((($beg1 < $end1) && ($beg2 < $end2)) ||
	    (($beg1 > $end1) && ($beg2 > $end2)))
	{
	    my ($left1, $right1, $left2, $right2);

	    $left1  = &min($beg1, $end1);
	    $left2  = &min($beg2, $end2);

	    $right1 = &max($beg1, $end1);
	    $right2 = &max($beg2, $end2);

	    if ($left1 > $left2)
	    {
		($left1, $left2)   = ($left2, $left1);
		($right1, $right2) = ($right2, $right1);
	    }

	    if ($right1 >= $left2) { $ov = &min($right1,$right2) - $left2 + 1; }
	}
    }
    return $ov;
}

sub min {
    my($x,$y) = @_;

    return ($x < $y) ? $x : $y;
}

sub max {
    my($x,$y) = @_;

    return ($x > $y) ? $x : $y;
}

sub representative_of {
    my($group) = @_;

    my $rep = 0;
    my $sofar = 0;
    my $i;
    for ($i=0; ($i < @$group); $i++)
    {
	my $j;
	my $sum = 0;
	for ($j=0; ($j < @$group); $j++)
	{
	    if ($j != $i)
	    {
		$sum += &overlaps_same_strand1($group->[$i],$group->[$j]);
	    }
	}
	if ($sum > $sofar) { $rep = $i; $sofar = $sum }
    }
    return $group->[$rep];
}

# seqs are in [Id,Comment,sequence] tuples (gjo-tuples)
#
# locs are lists of pairs: [fid,loc] where loc is [r1,r2,...] 
#                                     and  ri is [contig,beg,strand,len]
#
sub build_corr {
    my($seqs1,$locs1,$seqs2,$locs2,$sz_context) = @_;
    my @corr;
    my @sims = &ProtSims::blastP($seqs1,$seqs2,1);
    my($sims1,$sims2) = &condense_sims(\@sims);
    my $bbhs = &set_bbhs($sims1,$sims2);;
    
    if (! $sz_context) { $sz_context = 5 }
    my $context  = &set_context($locs1,$locs2,$bbhs,$sz_context);
    foreach my $fid1 (keys(%$sims1))
    {
	if ($bbhs->{$fid1})
	{
	    my($fid2,$iden,undef,undef,$b1,$e1,$b2,$e2,$ln1,$ln2) = @{$sims1->{$fid1}};
	    my $n = $context->{$fid1};
	    my $sc = sprintf("%0.3f",((4 * log($n+1.5)/log(11.5)) + (($iden/100) ** 1.5))/5);
	    push(@corr,[$fid1,$iden,$n,$b1,$e1,$ln1,$b2,$e2,$ln2,$sc,$fid2]);
#	    print join("\t",($fid1,
#			     $iden,
#			     $n,
#			     $b1,
#			     $e1,
#			     $ln1,
#			     $b2,
#			     $e2,
#			     $ln2,
#			     $sc,
#			     $fid2)),"\n";
	}
    }
    return \@corr;
}

sub set_bbhs {
    my($sims1,$sims2) = @_;

    my $bbhs = {};
    foreach my $peg1 (keys(%$sims1))
    {
	my $peg2 = $sims1->{$peg1}->[0];
	my $peg3 = $sims2->{$peg2}->[0]; 
	my $bbh  =  $peg3  && ($peg3 eq $peg1);
	if ($bbh)
	{
	    $bbhs->{$peg1} = $peg2;
	}
    }
    return $bbhs;
}

sub set_context {
    my($locs1,$locs2,$bbhs,$sz_context) = @_;
    my $neigh1   = &neighbors($locs1,$sz_context);
    my $neigh2   = &neighbors($locs2,$sz_context);
    my $context  = {};
    foreach my $peg1 (map { $_->[0] } @$locs1)
    {
	my $peg2 = $bbhs->{$peg1};
	my $count = 0;
	my $n1H;
	if ( $peg2 && ($n1H = $neigh1->{$peg1}))
	{
	    my @n1 = keys(%$n1H);
	    foreach my $peg3 (@n1)
	    {
		my $peg4;
		if (($peg4 = $bbhs->{$peg3}) && 
		    $neigh2->{$peg2}->{$peg4})
		{
		    $count++;
		}
	    }
	}
	$context->{$peg1} = $count;
    }
    return $context;
}
	    
sub condense_sims {
    my($sims) = @_;
    my $sims1 = {};
    my $sims2 = {};
    
    my $last = shift @$sims;
    while ($last)
    {
	my $peg1 = $last->id1;
	my @sims_for_peg = ();
	while ($last && ($last->id1 eq $peg1))
	{
	    push(@sims_for_peg,$last);
	    $last = shift @$sims;
	}
	@sims_for_peg = sort { ($a->id2 cmp $b->id2) or ($b->iden <=> $a->iden) } @sims_for_peg;
	foreach $_ (@sims_for_peg)
	{
	    my($id1,$id2,$iden,undef,undef,undef,$b1,$e1,$b2,$e2,$psc,$bit_sc,$ln1,$ln2) = @$_;
	    &update_best($sims1,$id1,$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$ln1,$ln2);
	    &update_best($sims2,$id2,$id1,$iden,$psc,$bit_sc,$b2,$e2,$b1,$e1,$ln2,$ln1);
	}
    }
    &set_best($sims1);
    &set_best($sims2);
	
    return ($sims1,$sims2);
}

sub update_best {
    my($sims1,$id1,$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2) = @_;

    my $x = $sims1->{$id1};
    if (! $x)
    {
	$sims1->{$id1} = [[$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2]];
    }
    elsif ($x && (($x->[0]->[0] ne $id2) && &better($psc,$x->[0]->[2],$bit_sc,$x->[0]->[3])))
    {
	splice(@$x,0,0,[$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2]);
	$#{$x} = 1;
    }
    elsif ($x && ($x->[0]->[0] eq $id2))
    {
	($b1,$e1,$b2,$e2) = &merge($b1,$e1,$b2,$e2,$x->[0]->[4],$x->[0]->[5],$x->[0]->[6],$x->[0]->[7],$bit_sc,$x->[0]->[3]);
	$x->[0]->[4] = $b1;
	$x->[0]->[5] = $e1;
	$x->[0]->[6] = $b2;
	$x->[0]->[7] = $e2;
    }
    elsif ((@$x == 1) && (($x->[0]->[0] ne $id2) &&  (! &better($psc,$x->[0]->[2],$bit_sc,$x->[0]->[3]))))
    {
	$x->[1] = [$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2];
    }
    elsif ((@$x == 2) && (($x->[1]->[0] ne $id2) && ($psc < $x->[1]->[2])))
    {
	$x->[1] = [$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2];
    }
}

sub ok_len {
    my($sim) = @_;

    my($b1,$e1,$b2,$e2,$ln1,$ln2) = @{$sim}[4..9];
    return ((($e1-$b1) >= (0.8 * $ln1)) && (($e2-$b2) >= (0.8 * $ln2)));
}

sub better {
    my($psc1,$psc2,$bsc1,$bsc2) = @_;

    return (($psc1 < $psc2) || (($psc1 == $psc2) && ($bsc1 > $bsc2)));
}

sub merge {
    my($b1a,$e1a,$b2a,$e2a,$b1b,$e1b,$b2b,$e2b,$bsc1,$bsc2) = @_;

    if (($b1a < $b1b) && (abs($b1b - $e1a) < 10) &&
	($b2a < $b2b) && (abs($b2b - $e2a) < 10))
    {
	return ($b1a,$e1b,$b2a,$e2b);
    }
    elsif (($b1b < $b1a) && (abs($b1a - $e1b) < 10) &&
	   ($b2b < $b2a) && (abs($b2a - $e2b) < 10))
    {
	return ($b1b,$e1a,$b2b,$e2a);
    }
    elsif ($bsc1 >= $bsc2)
    {
	return ($b1a,$e1a,$b2a,$e2a);
    }
    else
    {
	return ($b1b,$e1b,$b2b,$e2b);
    }
}

sub set_best {
    my($sims) = @_;

    foreach my $id (keys(%$sims))
    {
	my $bestL = $sims->{$id};
	my $best = $bestL->[0];
	next if ($best->[2] > 1.0e-20);
	next if (! &ok_len($best));
	# next if diff in identity is < 5 -> not clear
	next if ((@$bestL > 1) && &ok_len($bestL->[1]) && (abs($best->[1] - $bestL->[1]->[1]) < 5));
	$sims->{$id} = $best;
    }
}

sub neighbors {
    my($locs,$sz_context) = @_;
    my $neigh = {};
    my @locs  = sort { ($a->[1]->[0] cmp $b->[1]->[0]) or 
		       (($a->[1]->[1] + $a->[1]->[2]) <=> 
			($b->[1]->[1] + $b->[1]->[2])) 
                     }
                map { my($id,$loc) = @$_; [$id,&condense_loc($loc)] } @$locs;
    my $i;
    for ($i=0; ($i < @locs); $i++)
    {
	my $j;
	for ($j = $i-$sz_context; ($j < @locs) && ($j <= ($i+$sz_context)); $j++)
	{
	    if (($j != $i) && ($j >=0))
	    {
		$neigh->{$locs[$i]->[0]}->{$locs[$j]->[0]} = 1;
		$neigh->{$locs[$j]->[0]}->{$locs[$i]->[0]} = 1;
	    }
	}
    }
    return $neigh;
}

sub condense_loc {
    my($loc) = @_;

    my @pieces = @$loc;
    if (($pieces[0]->[0] ne $pieces[-1]->[0]) ||
	($pieces[0]->[2] ne $pieces[-1]->[2]))
    { 
	print &Dumper($loc); die "invalid location";
    }
    my $b = $pieces[0]->[1];
    my $e = ($pieces[0]->[2] eq '+') ? ($pieces[-1]->[1] + ($pieces[-1]->[3] -1)) 
	                             : ($pieces[-1]->[1] - ($pieces[-1]->[3] -1));
    return [$pieces[0]->[0],$b,$e];
}

1;
