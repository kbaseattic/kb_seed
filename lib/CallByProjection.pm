package CallByProjection;

# This is a SAS component.

use strict;
use warnings;
use Data::Dumper;
use Carp;
use SAPserver;
use ANNOserver;
use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

sub fill_in_by_walking {
    my ($close_genomes,$contigs,$coding_regions,$calls,$parms) = @_;

    my $new_calls = {};
    $parms->{-csObj} || die "BAD HERE";
    if (! $parms->{-must_pin}) { $parms->{-must_pin} = 0.3 }
    if (! $parms->{-k})        { $parms->{-k} = 0.2 }
    
#    print STDERR &Dumper($calls);
    my @sorted_hits = sort { ($a->[0] cmp $b->[0]) or ($a->[1] <=> $b->[1]) } @$coding_regions;
    my %contigH = map { $_->[0] => $_->[2] } @$contigs;
    my @potential_calls;
    for (my $i=0; ($i < @sorted_hits); $i++)
    {
#	print STDERR &Dumper($sorted_hits[$i],&key_of_hit($sorted_hits[$i])); 
	if (! $calls->{&key_of_hit($sorted_hits[$i])})
	{
	    my $j;
	    for ($j=$i-1; ($j >= 0) && (! $calls->{&key_of_hit($sorted_hits[$j])}); $j--) {}
	    if ($j >= 0)
	    {
		my $k;
		for ($k=$i+1; ($j < @sorted_hits) && (! $calls->{&key_of_hit($sorted_hits[$k])}); $k++) {}
		if (($k < @sorted_hits) && (($k-$j) < 6))
		{
		    my $close_fidsL = $parms->{-close_fids}->{&key_of_hit($sorted_hits[$j])};
		    my $close_fidsR = $parms->{-close_fids}->{&key_of_hit($sorted_hits[$k])};
		    my($contig,$hit_beg,$hit_end,$sc,$newF) = @{$sorted_hits[$i]};
#		    print STDERR &Dumper([$j,$i,$k],$close_fidsL,$close_fidsR); die "HERE";
		    my %pegH2 = map { ($_ =~ /^fig\|(\d+\.\d+)\.peg\.(\d+)$/) ? ($1 => $2) : () } @$close_fidsR;
		    my $c1 = 0;
		    my $close_fids = [];
		    while ($c1 < @$close_fidsL)
		    {
			my $peg1 = $close_fidsL->[$c1];
			if (($peg1 =~ /^fig\|(\d+\.\d+)\.peg\.(\d+)$/) && 
			    ($_ = $pegH2{$1}) && 
			    (abs($_ - $2) == ($k - $j)))
			{
			    my $poss_peg = "fig|$1\.peg\." . abs(int(($_ + $2)/2));
			    push(@$close_fids,$poss_peg);
			}
			$c1++;
		    }
		    if (@$close_fids > 0)
		    {
			$parms->{-close_fids}->{&key_of_hit($sorted_hits[$i])} = $close_fids;
			my($orf_beg,$orf_end,$trans) = &expand_to_orf($contigH{$contig},$hit_beg,$hit_end,$parms);
			push(@potential_calls,[$contig,$orf_beg,$orf_end,$trans,$close_fids,$newF,$hit_beg,$hit_end,0]);
#			print STDERR &Dumper($sorted_hits[$i],$orf_beg,$orf_end,$trans); 
		    }
		}
	    }
	}
    }

    my $existing_transH = &get_existing_trans(\@potential_calls,$close_genomes,$parms);
    foreach my $tuple (@potential_calls)
    {
	my($contig,$orf_beg,$orf_end,undef,$close_fids,$newF,$hit_beg,$hit_end) = @$tuple;
	my $close_fid     = $close_fids->[0];
	my $close_tran    = $existing_transH->{$close_fid};
	my($start,$trans) = &good_call($tuple,$close_tran,\%contigH,$parms);
	if ($start)
	{
	    my $key_loc = join(":",($contig,$hit_beg,$hit_end));
	    $calls->{$key_loc} = $new_calls->{$key_loc} = [$start,$orf_end,$trans,$newF,$close_fid,0];
	}
	else
	{
#	    print STDERR "    could not map $close_fids->[0]: $newF\n";
	}
    }
    return $new_calls;
}

sub key_of_hit {
    my($hit) = @_;

    my($contig,$hit_beg,$hit_end) = @$hit;
    return join(":",($contig,$hit_beg,$hit_end));
}

sub call_solid_genes {
    my ($close_genomes,$contigs,$coding_regions,$parms) = @_;
    if (! $parms->{-must_pin}) { $parms->{-must_pin} = 0.3 }
    if (! $parms->{-k})        { $parms->{-k} = 0.3 }

    print STDERR ("In call_solid_genes:\n", Dumper($parms)) if $ENV{VERBOSE};
    my @sorted_close = map { $_->[0] } @$close_genomes;
    my %contigH = map { $_->[0] => $_->[2] } @$contigs;
    $parms->{-contigH} = \%contigH;

    my $called = [];
    my $rel_roles = $parms->{ -roles}; 
    my %roles;
    if ($rel_roles)
    {
	%roles = map { $_ => 1 } @$rel_roles;
    }

    my $num_close = $parms->{ -num_close } || 10;
    my @close_to_use = map { $_->[0] } @$close_genomes;
    if (@close_to_use > $num_close) { $#close_to_use = $num_close-1 }

    my $close_funcH;
    my $genH;
    if ($parms->{-source} eq "SEED")
    {
	my $sapObj = $parms->{-sapObj};
	$genH = $sapObj->all_features( -type => ['peg'], -ids => \@close_to_use );
    }
    else
    {
	my $csObj = $parms->{-csObj};
	$genH = $csObj->genomes_to_fids(\@close_to_use,['peg','CDS']);
    }

    foreach my $g (@sorted_close)
    {
	my $fids = $genH->{$g};
	$parms->{-close}->{$g}->{fids} = $fids;
	my $fidH;
	my $fid_locH;
	if ($parms->{-source} eq 'SEED')
	{
	    my $sapObj = $parms->{-sapObj};
	    $fidH = $sapObj->ids_to_functions( -ids => $fids );
	    $fid_locH = $sapObj->fid_locations( -ids => $fids );
	}
	else
	{
	    my $csObj = $parms->{-csObj};
	    $fidH = $csObj->fids_to_functions($fids);
	    $fid_locH = $csObj->fids_to_locations($fids);
	}
	$parms->{-close}->{g}->{funcs} = $fidH;
	$parms->{-close}->{g}->{locs} = $fid_locH;
	foreach my $fid (keys(%$fidH))
	{
	    my $func = $fidH->{$fid};
	    if ((! $rel_roles) || &ok_func(\%roles,$func))
	    {
		push(@{$close_funcH->{$func}},$fid);
	    }
	}
    }

#   print STDERR scalar @$coding_regions," detected via kmers\n";
    my $new_funcH = {};
    foreach $_ (@$coding_regions)
    {
	my($contig,$beg,$end,$kmer_hits,$func) = @$_;
	if ((! $rel_roles) || &ok_func(\%roles,$func))
	{
	    push(@{$new_funcH->{$func}},[$contig,$beg,$end,$kmer_hits]);
	}
    }
    return &make_calls($close_genomes,$close_funcH,$new_funcH,$parms);
}

sub make_calls {
    my($close_genomes,$close_funcH,$new_funcH,$parms) = @_;
#     print STDERR &Dumper($close_genomes,$close_funcH,$new_funcH); 

    $parms->{-genetic_code} = &genetic_code_of($close_genomes->[0]->[0],$parms);
    my $contigH = $parms->{-contigH};
    my $calls = {};
    my @potential_calls;
    foreach my $newF (keys(%$new_funcH))
    {
	my $hits       = $new_funcH->{$newF};
	my $close_fids = $close_funcH->{$newF};
	if ((@$hits == 1) && $close_fids)
	{
	    my($contig,$hit_beg,$hit_end,$num_kmers) = @{$hits->[0]};
	    my($orf_beg,$orf_end,$trans) = &expand_to_orf($contigH->{$contig},$hit_beg,$hit_end,$parms);
	    if ($trans)
	    {
		$parms->{-close_fids}->{&key_of_hit($hits->[0])} = $close_fids;
		push(@potential_calls,[$contig,$orf_beg,$orf_end,$trans,$close_fids,$newF,$hit_beg,$hit_end,$num_kmers]);
	    }
	    else
	    {
#		print STDERR "no translation\n";
	    }
	}
    }
#    print STDERR scalar @potential_calls," potential calls (unique hits against relevant functions in close genomes)\n";
    my $existing_transH = &get_existing_trans(\@potential_calls,$close_genomes,$parms);
    foreach my $tuple (@potential_calls)
    {
	my($contig,$orf_beg,$orf_end,undef,$close_fids,$newF,$hit_beg,$hit_end,$num_kmers) = @$tuple;
	my $close_fid     = $close_fids->[0];
	my $close_tran    = $existing_transH->{$close_fid};
	my($start,$trans) = &good_call($tuple,$close_tran,$contigH,$parms);
	if ($start)
	{
	    $calls->{join(":",($contig,$hit_beg,$hit_end))} = [$start,$orf_end,$trans,$newF,$close_fid,$num_kmers];
	}
	else
	{
#	    print STDERR "    could not map $close_fids->[0]: $newF\n";
	}
    }
#   print STDERR scalar keys(%$calls)," successfully called genes\n";
    return $calls;
}

# The following routine is the key to iteratively filling things in.  It
# takes a tuple composed of [contigID,orf_beg,orf_end,translation] 
# and tries to resolve the start and the corresponding (shortened) translation.  The
# [orf_begin,orf_end] coordinates include stop codons at each end.  The "translation" covers
# the entire region (stop at least end, so it begins and ends with '*').  
# $close_tran give the translation from a corresponding gene (we believe) in a "close genome".
# The template translation may, or may not, be appropriate.  The filter requires that we
# can pin the $close_tran to a region in the translation that unambiguously maps 30% of
# the amino acids (the pin establishes a correspondence between short kmers).

sub good_call {
    my($tuple,$close_tran,$contigH,$parms) = @_;

    my($projected_start,$projected_trans);

    my($contig,$orf_beg,$orf_end,$trans_orf) = @$tuple;
    my $pinned = &pin($trans_orf,$close_tran,$parms->{-k});
    if (@$pinned >= ($parms->{-must_pin} * length($close_tran)))
    {
	($projected_start,$projected_trans) = &extract_start($pinned,$contigH->{$contig},$orf_beg,$orf_end,$trans_orf);
	if (($projected_start) && (@$pinned >= ($parms->{-must_pin} * length($projected_trans))))
	{
	    return ($projected_start,$projected_trans);
	}
    }
    else
    {
#	print STDERR "too few pins contig=$contig orf_beg=$orf_beg orf_end=$orf_end ",scalar @$pinned,":",length($close_tran),"\n";
    }
    return undef;
}

sub pin {
    my($s1,$s2,$k) = @_;
    my %h1;
    my %h2;
    my $i;
    $s1 = lc $s1;
    $s2 = lc $s2;
    for ($i=0; ($i <= (length($s1) - $k)); $i++)
    {
	push(@{$h1{substr($s1,$i,$k)}},length($s1) - $i);
    }
    for ($i=0; ($i <= (length($s2) - $k)); $i++)
    {
	push(@{$h2{substr($s2,$i,$k)}},length($s2) - $i);
    }

    my @matches;
    for my $kmer (keys(%h1))
    {
	my $hits1 = $h1{$kmer};
	my $hits2 = $h2{$kmer};
	if ($hits2)
	{
	    foreach $_ (@$hits1)
	    {
		push(@matches,[$_,$hits2]);
	    }
	}
    }
    @matches = sort { $a->[0] <=> $b->[0] } @matches;
    return &create_pins(\@matches);
}

sub create_pins {
    my($matches) = @_;

    my @pins;
    my $i = 0;
    while ($i < @$matches)
    {
	my($c1,$c2L) = @{$matches->[$i]};
	if (@pins == 0)
	{
	    push(@pins,[$c1,$c2L->[0]]);
	}
	else
	{
	    my $j;
	    for ($j=0; ($j < @$c2L) && ($c2L->[$j] <= $pins[-1]->[1]); $j++) {}
	    if ($j < @$c2L)
	    {
		my $c2 = $c2L->[$j];
		if (($c1 > $pins[-1]->[0]) && ($c2 > $pins[-1]->[1]))
		{
		    push(@pins,[$c1,$c2]);
		}
		else
		{
		    pop @pins;
		}
	    }
	    else
	    {
		pop @pins;
	    }
	}
	$i++;
    }
    return \@pins;
}

sub extract_start {
    my($pinned,$contig_seq,$orf_beg,$orf_end,$trans) = @_;

#    print STDERR "$contig_seq\n";
#    print STDERR "orf_beg=$orf_beg orf_end=$orf_end\n";
#    print STDERR &gjoseqlib::DNA_subseq($contig_seq,$orf_beg,$orf_end),"\n"; die "HERE";
    my $last_pinned = $pinned->[-1]->[1];   # offset back from stop codon
    my $got = 0;
    while (($last_pinned < length($trans)) && (! $got))
    {
	my $codon;
	if ($orf_beg < $orf_end)
	{
	    $orf_beg = $orf_end + 1 - ($last_pinned * 3);
	    $codon   = &gjoseqlib::DNA_subseq($contig_seq,$orf_beg,$orf_beg+2);
	}
	else
	{
	    $orf_beg = $orf_end - 1 + ($last_pinned * 3);
	    $codon   = &gjoseqlib::DNA_subseq($contig_seq,$orf_beg,$orf_beg-2);
	}
	my $off = $last_pinned * 3;
#	print STDERR "last_pinned=$last_pinned, off=$off orf_beg=$orf_beg orf_end=$orf_end codon=$codon\n";
	if ($codon =~ /^[agt]tg/i)
	{
	    $got = 1;
	}
	else
	{
	    $last_pinned++;
	}
    }
    my $projected_trans = substr($trans,length($trans)-$last_pinned); chop $projected_trans;
    return ($orf_beg,$projected_trans);
}

# For now, we get just the first in each set.  If we wish to use more
# (say, to vote for the start position), make sure that you get them.
#
sub get_existing_trans {
    my($potential_calls,$close_genomes,$parms) = @_;

    my $new_and_old = {};
    my @fids = map { $_->[4]->[0] } @$potential_calls;
    return &get_fid_seqs(\@fids,$parms);
}

sub get_fid_seqs {
    my($fids,$parms) = @_;

    if ($parms->{-source} eq 'SEED')
    {
	my $sapObj = $parms->{-sapObj};
	my $fidH = $sapObj->ids_to_sequences(-ids => $fids, -fasta => 0, -protein => 1 );
	return $fidH;
    }
    else
    {
	my $csObj = $parms->{-csObj};
	$csObj || confess 'bad';
	my $fidH  = $csObj->fids_to_protein_sequences($fids);
	return $fidH;
    }
}


sub genetic_code_of {
    my($genome,$parms) = @_;

    if ($parms->{-source} eq 'SEED')
    {
	my $sapObj = $parms->{-sapObj};
	my $genH   = $sapObj->genome_data( -ids => [$genome], -data => ['genetic-code']);
	return $genH->{$genome}->[0];
    }
    else
    {
	my $csObj = $parms->{-csObj};
	my $genH = $csObj->genomes_to_genome_data([$genome]);
	return $genH->{$genome}->{genetic_code};
    }
}

sub expand_to_orf {
    my($contig_seq,$beg,$end,$parms) = @_;
    my($orf_beg,$orf_end,$trans,$genetic_code);

    my $code       = $parms->{-genetic_code};
    my $strand     = ($beg < $end) ? '+' : '-';
    my $ln         = length($contig_seq);
    my $stop_codons  = ($code == 4) ? ['TAA','TAG'] : ['TAA','TAG','TGA'];

    my $is_partial;
    ($orf_end,$is_partial) = &find_special_proteins::find_orf_end(\$contig_seq,$beg,$end,{ is_term => $stop_codons});
    if ($orf_end && (! $is_partial))
    {
	$orf_beg = &find_prev_stop(\$contig_seq,$beg,$strand,$stop_codons);
#	print STDERR "find_prev_stop returned $orf_beg\n";
	if ($orf_beg && (! $is_partial))
	{
	    my $nt_seq = gjoseqlib::DNA_subseq(\$contig_seq,$orf_beg,$orf_end);
	    my $gc = &NCBI_genetic_code::genetic_code($code);;
	    $trans = &gjoseqlib::translate_seq_with_user_code($nt_seq,$gc);
#	    print STDERR "expand_to_orf: trans=$trans orf_beg=$orf_beg orf_end=$orf_end\n$nt_seq\n";
	    return ($orf_beg,$orf_end,$trans);
	}
    }
    return undef;
}

sub find_prev_stop {
    my($contigR,$beg,$strand,$stop_codons) = @_;
    my $contig_len = length( $$contigR );
    my %stops = map { ($_ => 1, lc $_ => 1) } @$stop_codons;
    
    my $n1 = $beg;
    my $n2 = ($strand eq "+") ? ($n1 + 2) : ($n1 - 2);

    while ((($strand eq "+") && ($n1 > 3)) || (($strand eq "-") && ($n1 < ($contig_len - 2))))
    {
        my $codon = uc gjoseqlib::DNA_subseq( $contigR, $n1, $n2 );
#	warn  "codon=$codon n1=$n1 n2=$n2";

	if ($stops{$codon})
	{
	    return $n1;
	}
	if ($strand eq "+")
	{
	    $n1 -= 3; $n2 -= 3;
	}
	else
	{
	    $n1 += 3; $n2 += 3;
	}
    }
    return undef;
}

sub ok_func {
    my($roles,$func) = @_;

    if (defined($func))
    {
	foreach $_ (&SeedUtils::roles_of_function($func))
	{
	    if ($roles->{$_}) { return 1 }
	}
    }
    return 0;
}

1;

