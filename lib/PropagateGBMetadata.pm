package PropagateGBMetadata;

#
# This is a SAS component.
#

use strict;
use overlap_resolution;
use Data::Dumper;
use Time::HiRes 'gettimeofday';
use Set::IntervalTree;
use List::Util qw(min max);

#
# Given a GTO that has multiple annotations including a GenBank import,
# propagate the feature metadata from the GB features to the features
# that have been otherwise called.
#

sub propagate_gb_metadata
{
    my($gto, $params, $user) = @_;

    $params = {} unless ref($params) eq 'HASH';
    $params->{min_rna_pct_coverage} ||= 90;

    $user ||= "PropagateGBMetadata";

    my %orf;

    my $hostname = `hostname`;
    chomp $hostname;

    my $event = { tool_name => "PropagateGBMetadata",
		      execution_time => scalar gettimeofday,
		      parameters => [],
		      hostname => $hostname };

    my $event_id = $gto->add_analysis_event($event);

    #
    # First propagate to exact matches.
    #    

    my %seen;
    
    for my $f ($gto->features)
    {
	my($contig, $left, $right, $dir, $size) = overlap_resolution::bounds($f);
	
	my $stop = $dir eq '+' ? $right : $left;
	# print join("\t", $f->{id}, $contig, $stop, $left, $right, $dir), "\n";
	my $orf = join(".", $contig, $stop, $dir, $size);
	push(@{$orf{$orf}}, $f);
    }

    propagate_orfs($gto, $params, $user, $event_id, \%orf, \%seen);

    #
    # Then propagate fuzzier matches.
    #

    %orf = ();

    for my $f ($gto->features)
    {
	next if $seen{$f->{id}};
	
	my($contig, $left, $right, $dir, $size) = overlap_resolution::bounds($f);
	
	my $stop = $dir eq '+' ? $right : $left;
	# print join("\t", $f->{id}, $contig, $stop, $left, $right, $dir), "\n";
	my $orf = join(".", $contig, $stop, $dir);
	push(@{$orf{$orf}}, $f);
    }

    propagate_orfs($gto, $params, $user, $event_id, \%orf, \%seen);

    propagate_trnas($gto, $params, $user, $event_id, \%seen);

    return $gto;
}

#
# Propagate tRNA metadata based on coverage - we see differing endpoints
# so the prior orf-based mechanism does not work.
#

sub propagate_trnas
{
    my($gto, $params, $user, $event_id, $seen) = @_;

    #
    # We set up interval trees to store the GB-annotated
    # features.
    #

    my %trees;

    my %trees;
    for my $ctg ($gto->contigs())
    {
	my $tree = Set::IntervalTree->new();
	$trees{$ctg->{id}} = $tree;
    }

    for my $f ($gto->features)
    {
	my($ctg, $min, $max, $dir, $len) = GenomeTypeObject::bounds($f);

	next unless $f->{type} =~ /rna/i;
	next unless exists $f->{genbank_feature};

	# 
	# From Set::IntervalTree doc:
	# All intervals are half-open, i.e. [1,3), [2,6), etc.
	# Thus we bump the right endpoint.
	#
	$max++;

	my $tree = $trees{$ctg};
	$tree->insert($f->{id}, $min, $max);
    }

    #
    # Now walk the rna features looking for overlaps with 
    for my $f ($gto->features)
    {
	my $fid = $f->{id};

	next unless $f->{type} =~ /rna/i;
	next if $seen->{$fid};
	next if exists $f->{genbank_feature};

	my($ctg, $min, $max, $dir, $len) = GenomeTypeObject::bounds($f);
	my $tree = $trees{$ctg};
	my $overlap = $tree->fetch($min, $max+1);
	my @overlap = grep { $_ ne $fid } @$overlap;
	#
	# @overlap contains the genbank feature we are mapping from.
	#
	if (@overlap)
	{
	    my @poss;
	    for my $fid2 (@overlap)
	    {
		my $f2 = $gto->find_feature($fid2);
		my($ctg2, $min2, $max2, $dir2, $len2) = GenomeTypeObject::bounds($f2);

		my $olen;
		my $t = "not";
		if ($min > $min2 && $max < $max2)
		{
		    # enclosed
		    $olen = $len;
		    $t = "1 in 2";
		}
		elsif ($min2 > $min && $max2 < $max)
		{
		    # enclosed
		    $olen = $len2;
		    $t = "2 in 1";
		}
		elsif ($min <= $max2 && $min2 <= $max)
		{
		    $olen = min($max - $min2, $max2 - $min);
		    $t = "overlap";
		}

		my $longest = max($max - $min, $max2 - $min2);
		my $opct = (100 * $olen / $longest);
		push(@poss, [$f, $f2, $fid, $fid2, $olen, $longest, $opct, $t, $min2, $max2]);
	    }

	    @poss = sort { $b->[6] <=> $a->[6] } grep { $_->[6] >= $params->{min_rna_pct_coverage} } @poss;

	    if (@poss)
	    {
		my $n = @poss;
		
		for my $ent (@poss)
		{
		    my($f, $f2, $fid, $fid2, $olen, $longest, $opct, $t, $min2, $max2) = @$ent;
		    print STDERR "Overlap: $olen $opct $longest $t\n\t$min\t$max\t$fid\t$f->{function}\n\t$min2\t$max2\t$fid2\t$f2->{function}\n";
		}
		
		propagate_feature_data($gto, $user, $event_id, $poss[0]->[1], $f);
		$seen->{$f->{id}}++;
	    }
	    else
	    {
		print STDERR "No candidates with sufficient overlap for $fid $f->{function}\n";
	    }
	}
	else
	{
	    print STDERR "No candidates for $fid $f->{function}\n";
	}
    }
    
}

sub propagate_orfs
{
    my($gto, $params, $user, $event_id, $orfH, $seen) = @_;

    while (my($orf, $features) = each %$orfH)
    {
	next if @$features < 2;
	my @fids = map { $_->{id} } @$features;
	my %types = map { tmap($_->{type}) => 1 } @$features;
	if (keys %types > 1)
	{
	    my @types = keys %types;
	    warn "Skipping propagation for @fids due to multiple types @types\n";
	    next;
	}
	my @gb = grep { exists $_->{genbank_feature} } @$features;
	next if @gb == 0;
	if (@gb > 1)
	{
	    warn "Skipping propagation for @fids due to multiple entries with genbank data " . join(" ", map { $_->{id} } @gb) . "\n";
	    next;
	}
	my $gb = $gb[0];

	my @notgb = grep { $_->{id} ne $gb->{id} } @$features;

	for my $f (@notgb)
	{
	    $seen->{$f->{id}}++;
	    propagate_feature_data($gto, $user, $event_id, $gb, $f);
	}
    }

}

sub propagate_feature_data
{
    my($gto, $user, $event_id, $gb, $f) = @_;
    
    my $prop;
    my %aliases = map { $_ => 1 } @{$f->{aliases}};
    for my $a (@{$gb->{aliases}})
    {
	if (!$aliases{$a})
	{
	    push(@{$f->{aliases}}, $a);
	    $prop++;
	    # print "Propagated $a to $f->{id}\n";
	}
    }
    my %pairs = map { join($;, @$_) => 1 } @{$f->{alias_pairs}};
    for my $ap (@{$gb->{alias_pairs}})
    {
	if (!$pairs{join($;, @$ap)})
	{
	    $prop++;
	    push(@{$f->{alias_pairs}}, $ap);
	    # print "Propagated @$ap to $f->{id}\n";
	}
    }
    if ($prop)
    {
	$gto->add_annotation($f, "$prop aliases propagated from $gb->{id}",
			     $user,
			     $event_id);
    }
}

sub tmap
{
    my($t) = @_;
    return $t eq 'CDS' ? 'peg' : $t;
}

1;
