# -*- perl -*-
########################################################################
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
########################################################################

# This is a SAS component.

package Kmers;
no warnings 'redefine';

use SeedUtils;
use strict;
use DB_File;
use File::Basename;
use Digest::MD5;

our $have_fig;
eval {
    require FIG;
    $have_fig = 1;
};

eval {
    require gjoseqlib;
    import gjoseqlib;
};

use ProtSims;

use Data::Dumper;
use Carp;
use FFs;

our $KmersC_available;
eval {
    require KmersC;
    $KmersC_available++;
};


sub new {
    my $class = shift;

    my $figfams = {};

    $KmersC_available or die "KmersC module not available in this perl build";
    
    #
    # Support experiments with kmer builds by allowing
    # arguments to specify fri.db and setI.db as well as
    # a single kmer data file.
    #

    my $dir;
    my $FRIDB;
    my $setIDB;

    if ($_[0] =~ /^-/)
    {
	my %args = @_;

	$FRIDB = $args{-frIdb};
	$setIDB = $args{-setIdb};
	my $table = $args{-table};

	if (!defined($FRIDB) || !defined($setIDB) || !defined($table))
	{
	    warn "Kmer experimental interface must define -frIDb, -setIdb, and -table\n";
	    return undef;
	}

	#
	# Using this interface, we expect that the
	# actual kmer sdirectory is the one containing FRIDB.
	#

	my $ffdir = dirname($FRIDB);
	$figfams->{ffs} = FFs->new($ffdir);

	$figfams->{dir} = $ffdir;

	if (ref($table) eq 'HASH')
	{
	    #
	    # Open a KmersC for each Kmer size.
	    #
	    
	    for my $k (sort { $a <=> $b } keys %$table)
	    {
		my $binary = $table->{$k};
		my $kc = new KmersC;
		$kc->open_data($binary) or die "cannot load Kmer binary database $binary";
		
		$figfams->{KmerC}->{$k} = $kc;
	    }

	    $figfams->{default_kmer_size} = 8;
	    
	}
	else
	{
	    my $kmerc = new KmersC;
	    $kmerc->open_data($table);
	    my $sz = $kmerc->get_motif_len();
	    warn "Experimental Kmers $table of size $sz\n";
	    $figfams->{KmerC}->{$sz} = $kmerc;
	    $figfams->{default_kmer_size} = $sz;
	}
    }
    else
    {
	$dir = shift;
	-d $dir or return undef;

	$FRIDB = "$dir/FRI.db";
	$setIDB = "$dir/setI.db";
	
	#
	# Open a KmersC for each Kmer size.
	#

	if (-d "$dir/binary")
	{
	    for my $binary (<$dir/binary/table.binary.*>)
	    {
		if ($binary =~ /(\d+)$/)
		{
		    my $k = $1;
		    my $kc = new KmersC;
		    $kc->open_data($binary) or die "cannot load Kmer binary database $binary";
		    
		    $figfams->{KmerC}->{$k} = $kc;
		}
	    }
	}
	elsif (-d "$dir/Merged")
	{
	    for my $binary (<$dir/Merged/*/table.binary>)
	    {
		if ($binary =~ m,/(\d+)/table\.binary,)
		{
		    my $k = $1;
		    my $kc = new KmersC;
		    $kc->open_data($binary) or die "Cannot load Kmer binary database $binary";
		    $figfams->{KmerC}->{$k} = $kc;
		}
	    }
	}
	else
	{
	    die "No binary kmers found in $dir\n";
	}
	$figfams->{default_kmer_size} = 8;

	$figfams->{ffs} = FFs->new($dir);
	$figfams->{dir} = $dir;
    }
    
    my %fr_hash;
    my $fr_hash_tie   = tie %fr_hash,   'DB_File', $FRIDB,  O_RDONLY, 0666, $DB_HASH;
    $fr_hash_tie    || die "tie failed for function index $FRIDB";

    my %set_hash;
    my $set_hash_tie  = tie %set_hash,   'DB_File', $setIDB,  O_RDONLY, 0666, $DB_HASH;
    $set_hash_tie   || warn "tie failed for function index $setIDB";

    $figfams->{friH}  = \%fr_hash;
    $figfams->{setiH} = \%set_hash;
    $figfams->{fig} = new FIG if $have_fig;


    bless $figfams,$class;
    return $figfams;
}

sub get_available_kmer_sizes
{
    my($self) = @_;
    return sort { $a <=> $b }  keys %{$self->{KmerC}};
}

sub dir
{
    my($self) = @_;
    return $self->{dir};
}

sub DESTROY {
    my ($self) = @_;
    delete $self->{fig};
}

=head3 match_seq

Uses the find_all_hits to get a tuple of data about the kmer match. The tuples
are

	offset in query,
	kmer,
	index in functional role table (FRI.db / function.index)
	index in OTU table (setI.db /setI)
	figfam number
	average offset of this kmer in the source protein, measured from the end of the protein

The last is used for the "order constraint" where we require sequential kmer hits be sequential in the original protein.

=cut



sub match_seq {
    my($self, $motif_sz, $seq) = @_;

    if ($self->{KmerC}->{$motif_sz})
    {
	my $matches = [];
	if ($seq)
	{
	    $self->{KmerC}->{$motif_sz}->find_all_hits(uc $seq, $matches);
	}
	return $matches;
    }
    else
    {
	die "No KmerC found for size $motif_sz";
    }
}

=head3 assign_functions_to_prot_set

    my $result = $kmers->assign_functions_to_prot_set($args)

=over 4

=item args

Reference to a hash of parameters.

=item RETURN

Returns a list of tuples. If -all => 1 was specified, there will be a tuple for
each input sequence, otherwise there will be a tuple only for each input sequence
that had a successful match.

Each tuple is of the form

    [ sequence-id, assigned-function, OTU, score, non-overlapping hit-count, overlapping hit-count, detailed-hits]

where detailed-hits is optional, depending on the value of the -detailed parameter.

=back

=head4 Parameter Hash Fields

=over 4

=item -seqs list

Reference to a list of triples [sequence-id, comment, sequence-data].

=item -kmer N

Specify the kmer size to use for analysis.

=item -all 0|1

If set, return an entry for each input sequence. If the scoring threshold was not
met, the assigned function will be undefined, but the scores and hit counts 
will still be returned..

=item -scoreThreshold N

Require a Kmer score of at least N for a Kmer match to succeed.

=item -hitThreshold N

Require at least N (possibly overlapping) Kmer hits for a Kmer match to succeed.

=item -seqHitThreshold N

Require at least N sequential (non-overlapping) Kmer hits for a Kmer match to succeed.

=item -normalizeScores 0|1

Normalize the scores to the size of the protein.

=item -detailed 0|1

If true, return a detailed accounting of the kmers hit for each protein.

=back


=cut

sub assign_functions_to_prot_set {

    #
    # This is ugly but needed for the transition to the new form of the code.
    # If we were not invoked with the new args hash, reinvoke the previous
    # version of the code which is named assign_functions_to_prot_set_compat.
    # Otherwise fall through and use the new form.
    #
    my($self, @args) = @_;

    my $args;
    if (@args == 1 && ref($args[0]) eq 'HASH')
    {
	$args = $args[0];
    }
    elsif (@args > 0 && $args[0] !~ /^-/)
    {
	return &assign_functions_to_prot_set_compat;
    }
    else
    {
	$args = { @args };
    }

    my $seq_set = $args->{-seqs};
    if (!defined($seq_set))
    {
	warn "assign_functions_to_prot_set: No sequences provided via the -seqs argument";
	return ();
    }

    my $motif_sz = $args->{-kmer};
    if (!ref($self->{KmerC}->{$motif_sz}))
    {
	die "No KmerC defined for kmer size $motif_sz";
    }

    #
    # Define the good-hit function.
    #

    my $min_hits = $args->{-hitThreshold};
    my $min_seqhits = $args->{-seqHitThreshold};
    my $min_score = $args->{-scoreThreshold};
    my $db_fuzz_threshold = $args->{-fuzzThreshold} || 20;

    # print "min_seqhits=$min_seqhits\n";
    
    my $good_hit = sub {
	my($score, $seqhits, $hits) = @_;

	# print "goodhit $score $hits $seqhits == $min_hits $min_seqhits $min_score\n";

	return 0 if defined($min_hits) && $hits < $min_hits;
	return 0 if defined($min_seqhits) && $seqhits < $min_seqhits;
	return 0 if defined($min_score) && $score < $min_score;
	return 1;
    };

    my $fr_hash   = $self->{friH};
    my $set_hash  = $self->{setiH};
    my $fig = $self->{fig};

    my @out;

    #
    # Run the query.
    #

    for my $seqent (@$seq_set)
    {
	my($id, $com, $seq) = @$seqent;
	my $seq_len = length($seq);
	my $matches = $self->match_seq($motif_sz, $seq);
#	print Dumper($id, $matches);
	
	my(%hitsF,%hitsS, %hitsFam);

	#
	# Compute the non-overlapping hits.
	# Do this by walking the list of hits in order of offset, and for each,
	# compute the distance to the start of the last hit. If that distance
	# is K or greater, increment the non-overlapping hit count.
	#
	my $last_hit_start;
	my $last_frI = -1;
	my %non_overlapping_F;

	#
	# Filter matches based on relative location data.
	#

	if ($args->{-orderConstraint})
	{
	    &filter_group_on_ordering($matches, $db_fuzz_threshold);
	}

	
	my @sorted_matches = sort { $a->[2] <=> $b->[2] or $a->[0] <=> $b->[0] } @$matches;
	my @details;

	foreach my $match (@sorted_matches) 
	{
	    my($offset, $oligo, $frI, $setI, $fam, $db_offset) = @$match;

	    if ($args->{-detailed})
	    {
		push(@details, [$offset, $oligo, $fr_hash->{$frI}, $set_hash->{$setI}, $fam, $db_offset]);
	    }

	    #
	    # $offset - offset in target of this hit
	    # $oligo - actual oligo that hit
	    # $frI - functional role index for this kmer hit
	    # $setI - OTU  set index for this kmer hit
	    # $fam - figfam id (if present in the kmer data set)
	    # $db_offset - average offset of the signature in the protein(s) it was derived fro
	    #

	    #
	    # The sort above groups the hits by functional role and orders by
	    # offset within the target.
	    #
	  
	    if ($frI != $last_frI)
	    {
		#
		# We're searching in a new role now.
		#
		
		undef $last_hit_start;
		$last_frI = $frI;
	    }
	    # print "@$match lhs=$last_hit_start\n";

	    #
	    # If this is the first hit, or if we are a kmer width away at least from the
	    # last non-overlapping hit, count another non-overlapping hit.
	    #
	    
	    if (!defined($last_hit_start) || ($offset - $last_hit_start) >= $motif_sz)
	    {
		$non_overlapping_F{$frI}++;
		$last_hit_start = $offset;
	    }

	    #
	    # We count all functional role and OTU hits.
	    #
	    $hitsF{$frI}++; 
	    if ($setI)
	    { 
		$hitsS{$setI}++ ;
	    }
	    if (defined($fam) && $fam >= 0)
	    {
		$hitsFam{$fam}++;
	    }
	}

#	print Dumper(\%non_overlapping_F, \%hitsF, \%hitsFam);

	#
	# Find the functional roles that had the best overlapping and non-overlapping hit counts.
	#
	my $nonoverlapFRI = &best_hit(\%non_overlapping_F, $min_hits);
	my ($FRI, $bh2) = &best_2hits(\%hitsF, $min_seqhits);

	#
	# Compute score and normalize if required. Score is based on the number of overlapping hits.
	#

	# print STDERR "HitsF\n";
	# print STDERR "$_\t$hitsF{$_}\n" for sort { $hitsF{$b} <=> $hitsF{$a} } keys %hitsF;
	# print STDERR "HitsFam\n";
	# print STDERR "$_\t$hitsFam{$_}\n" for sort { $hitsFam{$b} <=> $hitsFam{$a} } keys %hitsFam
	    ;


	my $nonoverlap_hits = $non_overlapping_F{$nonoverlapFRI};
	my $overlap_hits  = $hitsF{$FRI};
	my $overlap_hits2 = $hitsF{$bh2};

	my $score = 0 + ($overlap_hits - $overlap_hits2);
	if ($args->{-normalizeScores})
	{
	    $score = $score / ($seq_len - $motif_sz + 1);
	}

	my $setI  = &best_hit(\%hitsS,$min_hits);
	my $bestFam = &best_hit(\%hitsFam, $min_hits);

	my $fun;
	my $set;
	my $family;
	my $family_score = 0;
	my $family_sims;

	my $all_fam_info = "";
	if ($args->{-allFamilyInfo})
	{
	    $all_fam_info = join(",", map { sprintf("FIG%08d:%d",$_, $hitsFam{$_}) } sort { $hitsFam{$b} <=> $hitsFam{$a} } keys %hitsFam );
	}
	
	# print "$score $nonoverlap_hits $overlap_hits\n";
	if ($FRI >= 0 && ($nonoverlapFRI == $FRI) && &$good_hit($score, $nonoverlap_hits, $overlap_hits))
	{
	    $fun = $fr_hash->{$nonoverlapFRI};
	    $set = $set_hash->{$setI};

	    if (!defined($fun))
	    {
		warn "No function found for $nonoverlapFRI\n";
	    }

	    if (defined($bestFam) && $bestFam >= 0)
	    {
		my $f = sprintf("FIG%08d", $bestFam);

		#
		# Ensure the function of that family matches the function
		# we're calling. If it does not, do not call the figfam.
		#
		if ($self->{ffs}->family_function($f) eq $fun)
		{
		    $family = $f;
		    $family_score = $hitsFam{$bestFam};
		}
		else
		{
		    # warn "$id: called family $bestFam $f but function " . $self->{ffs}->family_function($f) . " ne $fun\n";
		}
	    }
	    elsif (defined($args->{-determineFamily}) && $args->{-determineFamily} && ref($self->{ffs}))
	    {
		my($fam, $sims) = $self->{ffs}->place_seq_and_function_in_family($seq, $fun);
		$family = $fam;
		$family_sims = $sims if $args->{-returnFamilySims};
	    }
	    push(@out, [$id, $fun, $set, $score, $nonoverlap_hits, $overlap_hits,
			($args->{-detailed} ? \@details : undef),
			$family, $family_sims, $family_score, $all_fam_info]);
	}
	elsif ($args->{-all})
	{
	    push(@out, [$id, $fun, $set, $score, $nonoverlap_hits, $overlap_hits,
			($args->{-detailed} ? \@details : undef),
			$family, $family_sims, $family_score, $all_fam_info]);
	}
    }
    return @out;
}

sub assign_functions_using_similarity
{
    my($self, $args) = _handle_args(@_);

    my $seqs = $args->{-seqs};
    if (!defined($seqs))
    {
	warn "assign_functions_using_similarity: No sequences provided via the -seqs argument";
	return ();
    }

    my $db = $args->{-simDb};
    if (!defined($db))
    {
	die "assign_functions_using_similarity: No similarity database provided by the -simDb argument";
    }

    if (@$seqs ==  0)
    {
	return ();
    }

    my @blastout = ProtSims::blastP($seqs, $db, 5);

    my $cur;
    my @set;
    my @out;
    for my $ent (@blastout)
    {
	if ($cur && $ent->id1 ne $cur)
	{
	    my $val = $self->process_blast_set(@set);
	    push(@out, $val);
	    @set = ();
	}
	$cur = $ent->id1;
	push(@set, $ent);
    }
    if (@set)
    {
	my $val = $self->process_blast_set(@set);
	push(@out, $val);
    }
    return @out;
}

sub process_blast_set
{
    my($self, @blastout) = @_;

    my $id = $blastout[0]->id1;
    my $fig = $self->{fig};

    if (@blastout > 5) { $#blastout = 4 }
	    
    my %hit_pegs = map { $_->id2 => 1 } @blastout;
    my @pegs = keys(%hit_pegs);
    if (@pegs == 0)
    {
	return [$id,'hypothetical protein', undef, 0, 0, 0, undef];
    }
    else
    {
	my %funcs;
	foreach my $peg (@pegs)
	{
	    my $func = $fig->function_of($peg,1);
	    if (! &SeedUtils::hypo($func))
	    {
		$funcs{$func}++;
	    }
	}
	my @pos = sort { $funcs{$b} <=> $funcs{$a} } keys(%funcs);
	my $proposed = (@pos > 0) ? $pos[0] : "hypothetical protein";
	return [$id, $proposed, undef, 0, 0, 0, undef];
    }
}

sub assign_functions_to_prot_set_compat {
    my($self,$seq_set,$blast,$min_hits,$extra_blastdb) = @_;
    $min_hits = 3 unless defined($min_hits);
    
    my %match_set = map { my($id, $com, $seq) = @$_;  $id => [$self->match_seq($self->{default_kmer_size},$seq), $seq] } @$seq_set;
    
    my $fr_hash   = $self->{friH};
    my $set_hash  = $self->{setiH};
    
    my $fig = $self->{fig};
    
    my @missing;
    while (my($id, $ent) = each %match_set)
    {
	my($matches, $seq) = @$ent;
	
	my(%hitsF,%hitsS);
	foreach my $match (@$matches)
	{
	    my($offset, $oligo, $frI, $setI) = @$match;
	    $hitsF{$frI}++;
	    if ($setI)
	    {
		$hitsS{$setI}++ ;
	    }
	}
	
	my $FRI = &best_hit(\%hitsF,$min_hits);
	my $setI  = &best_hit(\%hitsS,$min_hits);
	push(@$ent, $FRI, $setI, \%hitsF);
	
	if (!$fr_hash->{$FRI})
	{
	    push(@missing, [$id, undef, $seq]);
	}
    }
    
    #
    # @missing now has the list of sequences that had no Kmer hits. If we have a
    # blast db, blast 'em.
    
    my @all_blastout;
    if (@missing && -s $extra_blastdb)
    {
	#print Dumper(\@missing);
	@all_blastout = ProtSims::blastP(\@missing, $extra_blastdb, 5);
	#print Dumper(\@all_blastout);
    }
    
    #
    # We now have Kmers output and blast output. Go through the original data and
    # create the output.
    #
    
    my @out;
    
    for my $ent (@$seq_set)
    {
	my $id = $ent->[0];
	my ($matches, $seq, $FRI, $setI, $hitsF)  = @{$match_set{$id}};
	
	my $blast_results = [];
	if ($fr_hash->{$FRI})
	{
	    if ($blast && ($fr_hash->{$FRI} || $set_hash->{$setI}))
	    {
		$blast_results = &blast_data($self,$id,$seq,$fr_hash->{$FRI},$blast,'blastp');
	    }
	    
	    push(@out, [$id, $fr_hash->{$FRI},$set_hash->{$setI}, $blast_results,$hitsF->{$FRI}]);
	}
	else
	{
	    my @blastout = grep { $_->id1 eq $id } @all_blastout;
	    
	    if (@blastout > 5) { $#blastout = 4 }
	    
	    my %hit_pegs = map { $_->id2 => 1 } @blastout;
	    my @pegs = keys(%hit_pegs);
	    if (@pegs == 0)
	    {
		push(@out, [$id,'hypothetical protein','',[],0]);
	    }
	    else
	    {
		my %funcs;
		foreach my $peg (@pegs)
		{
		    my $func = $fig->function_of($peg,1);
		    if (! &SeedUtils::hypo($func))
		    {
			$funcs{$func}++;
		    }
		}
		my @pos = sort { $funcs{$b} <=> $funcs{$a} } keys(%funcs);
		my $proposed = (@pos > 0) ? $pos[0] : "hypothetical protein";
		push(@out, [$id, $proposed,'',[],0]);
	    }
	}
    }
    return @out;
}





sub best_hit {
    my($hits,$min_hits) = @_;
    my @poss = sort { $hits->{$b} <=> $hits->{$a} } keys(%$hits);

    my $val;
    if ((@poss > 0) && ($hits->{$poss[0]} >= $min_hits))
    {
	$val = $poss[0];
    }
    return $val;
}

sub best_2hits {
    my($hits,$min_hits) = @_;
    my @poss = sort { $hits->{$b} <=> $hits->{$a} } keys(%$hits);

    my $val;
    if ((@poss > 0) && ($hits->{$poss[0]} >= $min_hits))
    {
	return @poss[0,1];
    }
    else
    {
	return undef;
    }
}

sub best_hit_in_group
{
    my($group) = @_;

    my %hash;
    for my $tuple (@$group)
    {
    	my($off,$oligo,$frI,$setI) = @$tuple;
	if ($setI > 0)
	{
	    $hash{$setI}++;
	}
    }
    my @sorted = sort { $hash{$b} <=> $hash{$a} } keys %hash;
    my $max = $sorted[0];
    return $max;
}


sub assign_functions_to_DNA_features {
    my($self,$motif_sz,$seq,$min_hits,$max_gap,$blast,$details) = @_;

    $min_hits = 3 unless defined($min_hits);
    $max_gap  = 200 unless defined($max_gap);

    my $fr_hash   = $self->{friH};
    my $set_hash  = $self->{setiH};

    my %hits;
    my @ans;
    my $matches = $self->process_dna_seq($seq);

    push(@ans,&process_hits($self,$motif_sz, $matches,1,length($seq),$motif_sz, $min_hits, $max_gap,$blast,$seq,$details));
    undef %hits;

    $matches = $self->process_dna_seq(&SeedUtils::reverse_comp($seq));
    push(@ans,&process_hits($self,$motif_sz, $matches,length($seq),1,$motif_sz, $min_hits, $max_gap,$blast,$seq,$details));
    return \@ans;
}

sub process_dna_seq {
    my($self, $seq,$hits) = @_;

    my $matches = $self->match_seq($seq);
    return $matches;
}


sub process_hits {
    my($self,$motif_sz, $matches,$beg,$end,$sz_of_match, $min_hits, $max_gap,$blast,$seq,$details) = @_;

    my $fr_hash   = $self->{friH};
    my $set_hash  = $self->{setiH};

    my $hits;
    my %sets;
    foreach my $tuple (@$matches)
    {
	my($off,$oligo,$frI,$setI) = @$tuple;
	push(@{$hits->{$frI}},$tuple);
    }

    my @got = ();
    my @poss = sort { (@{$hits->{$b}} <=> @{$hits->{$a}}) } keys(%$hits);
    if (@poss != 0)
    {
	foreach my $frI (@poss)
	{
	    my $hit_list = $hits->{$frI};
	    my @grouped = &group_hits($hit_list, $max_gap);
	    foreach my $group_ent (@grouped)
	    {
		my($group, $group_hits) = @$group_ent;
		my $N = @$group;
		if ($N >= $min_hits)   # consider only runs containing 3 or more hits
		{
		    my $b1 = $group->[0];
		    my $e1 = $group->[-1] + ($sz_of_match-1);

		    my $loc;
		    if ($beg < $end)
		    {
			$loc = [$beg+$b1,$beg+$e1];
		    }
		    else
		    {
			$loc = [$beg-$b1,$beg-$e1];
		    }
		    my $func = $fr_hash->{$frI};

		    my $set = &best_hit_in_group($group_hits);
		    $set = $set_hash->{$set};

		    my $blast_output = [];
		    if ($blast)
		    {
			$blast_output = &blast_data($self,join("_",@$loc),$seq,$func,$blast,
						    ($motif_sz == $sz_of_match) ? 'blastn' : 'blastx');
		    }
		    
		    my $tuple = [$N,@$loc,$func,$set,$frI,$blast_output];

		    if ($details)
		    {
			my $f = sprintf("FIG%08d", $hit_list->[0]->[4]);
			my $sz = $self->{ffs}->av_prot_length($f, 50);
			# my $genus = $self->{ffs}->genus_for_family($f, 50);
			# my $genus="";
			my $lca = $self->{ffs}->last_common_ancestor($f);
			push(@$tuple, $group_hits, $f, $sz, $lca);
		    }
		    
		    push(@got,$tuple);
		}
	    }
	}
    }
    return @got;
}

sub group_hits {
    my($hits, $max_gap) = @_;

    my @sorted = sort { $a->[0] <=> $b->[0] } @$hits;
    my @groups = ();
    my $position;
    while (defined(my $hit = shift @sorted))
    {
	my($position,$oligo,$frI,$setI) = @$hit;

	my $group = [$position];
	my $ghits = [$hit];
	while ((@sorted > 0) && (($sorted[0]->[0] - $position) < $max_gap))
	{
	    $hit = shift @sorted;
	    ($position,$oligo,$frI,$setI) = @$hit;
	    push(@$group,$position);
	    push(@$ghits, $hit);
	}

	filter_group_on_ordering($ghits, 10);
	$group = [map { $_->[0] } @$ghits];

	push(@groups,[$group, $ghits]);
    }
    return @groups;
}

sub filter_group_on_ordering
{
    my($matches, $db_fuzz_threshold) = @_;
    my $i = 0;
    my @start = @$matches;
    while ($i < $#$matches)
    {
	if (abs(($matches->[$i+1]->[0] - ($matches->[$i]->[0])) - ($matches->[$i+1]->[5] - $matches->[$i]->[5])) > $db_fuzz_threshold)
	{
	    splice(@$matches,$i,2);
	}
	else
	{
	    $i++;
	}
    }
}

sub assign_functions_to_PEGs_in_DNA {
    my($self,$motif_sz,$seq,$min_hits,$max_gap,$blast,$details) = @_;

    $blast = 0 unless defined($blast);
    $min_hits = 3 unless defined($min_hits);
    $max_gap  = 200 unless defined($max_gap);

    my $fr_hash   = $self->{friH};
    my $set_hash  = $self->{setiH};

    my %hits;
    my @ans;
    my $matches = $self->process_prot_seq($motif_sz, $seq);
    push(@ans,&process_hits($self,$motif_sz, $matches,1,length($seq),3 * $motif_sz, $min_hits, $max_gap,$blast,$seq,$details));
    undef %hits;
    $matches = $self->process_prot_seq($motif_sz, &SeedUtils::reverse_comp($seq));
    push(@ans,&process_hits($self,$motif_sz, $matches,length($seq),1,3 * $motif_sz, $min_hits, $max_gap,$blast,$seq,$details));
    return \@ans;
}    

sub process_prot_seq {
    my($self, $motif_sz, $seq) = @_;

    my $ans = [];
    my $ln = length($seq);
    my($i,$off);
    for ($off=0; ($off < 3); $off++)
    {
	my $ln_tran = int(($ln - $off)/3) * 3;
	next if $off > $ln;
	my $tran = uc &SeedUtils::translate(substr($seq,$off,$ln_tran));

	next if $tran eq '';
	
	my $matches = $self->match_seq($motif_sz, $tran);
	
	push(@$ans, map { $_->[0] = ((3 * $_->[0]) + $off); $_ } @$matches);
    }
    return $ans;
}

use Sim;

sub blast_data {
    my($self,$id,$seq,$func,$blast,$tool) = @_;

    if ($tool eq "blastp")   
    { 
	return &blast_data1($self,$id,$seq,$func,$blast,$tool);
    }

    if ($id =~ /^(\d+)_(\d+)$/)
    {
	my($b,$e) = ($1 < $2) ? ($1,$2) : ($2,$1);
	my $b_adj = (($b - 5000) > 0) ? $b-5000 : 1;
	my $e_adj = (($b + 5000) <= length($seq)) ? $b+5000 : length($seq);
	my $seq1 = substr($seq,$b_adj-1, ($e_adj - $b_adj)+1);
	my $blast_out = &blast_data1($self,$id,$seq1,$func,$blast,$tool);
	foreach $_ (@$blast_out)
	{
	    $_->[2] += $b_adj - 1;
	    $_->[3] += $b_adj - 1;
	    $_->[8] = length($seq);
	}
	return $blast_out;
    }
    else
    {
	return &blast_data1($self,$id,$seq,$func,$blast,$tool);
    }
}

sub blast_data1 {
    my($self,$id,$seq,$func,$blast,$tool) = @_;


    if (! $tool) { $tool = 'blastx' }
    my $fig = $self->{fig};

    my @blastout = ();
    if ($tool ne 'blastn')
    {
	my $ffs = $self->{ffs};
	my @fams = $ffs->families_implementing_role($func);
	foreach my $fam (@fams)
	{
	    my $subD = substr($fam,-3);
	    my $pegs_in_fam = "$FIG_Config::FigfamsData/FIGFAMS/$subD/$fam/PEGs.fasta";
	    push(@blastout,map { [$_->id2,$_->iden,$_->b1,$_->e1,$_->b2,$_->e2,$_->psc,$_->bsc,$_->ln1,$_->ln2,$fam] } 
		 $fig->blast($id,$seq,$pegs_in_fam,0.1,"-FF -p $tool -b $blast"));
	}
    }
    else
    {
	push(@blastout,map { [$_->id2,$_->iden,$_->b1,$_->e1,$_->b2,$_->e2,$_->psc,$_->bsc,$_->ln1,$_->ln2,$self->{what}] } 
	     $fig->blast($id,$seq,$self->{blastdb},0.1,"-FF -p $tool -b $blast"));
    }
    @blastout = sort { $b->[7] <=> $a->[7] }  @blastout;
    if (@blastout > $blast) { $#blastout = $blast-1 }
    return \@blastout;
}

#
# Turn an argument list into a $self ref and an argument hash.
# Code lifted from ClientThing.
#
sub _handle_args
{
    my $self = shift;
    my $args = $_[0];
    if (defined $args)
    {
        if (scalar @_ gt 1)
	{
            # Here we have multiple arguments. We check the first one for a
            # leading hyphen.
            if ($args =~ /^-/) {
                # This means we have hash-form parameters.
                my %args = @_;
                $args = \%args;
            } else {
                # This means we have list-form parameters.
                my @args = @_;
                $args = \@args;
            }
        } else {
            # Here we have a single argument. If it's a scalar, we convert it
            # to a singleton list.
            if (! ref $args) {
                $args = [$args];
            }
        }
    }
    return($self, $args);
}

sub patric_figfam_call
{
    my($ff_dir, $fig, $fasta, $annO, $md5_to_fam, $sims_cutoff, $iden, $iden2) = @_;

    my $ffs = FFs->new($ff_dir, $fig);

    my $fh;
    open($fh,"<",$fasta) || die "failed to open $fasta";

    my $handle = $annO->assign_function_to_prot(-input => $fh,
						-kmer => 8,
						-seqHitThreshold => 2,
						-detailed => 0,
						-hitThreshold => 3,
						-all => 1);

    my %kmer_funcs;
    my %kmer_fams;
    my %kmer_score;
    my @pegs;
    my @nomatch;
    my %missing;
    while (my $result = $handle->get_next)
    {
	my($peg, $funcK, $otu, $score, $nonoverlap_hits, $overlap_hits, $details, $fam) = @$result;

	if (!$funcK)
	{
	    $missing{$peg}++;
	    next;
	}

	$kmer_funcs{$peg} = $funcK;
	$kmer_fams{$peg} = $fam;
	$kmer_score{$peg} = [$score, $nonoverlap_hits, $overlap_hits, $details];
	push(@pegs, $peg);
    }

    seek($fh, 0, 0);

    while (my($peg, $com, $seq) = read_next_fasta_seq($fh))
    {
	next unless $missing{$peg};

	my $md5 = Digest::MD5::md5_hex( uc $seq );
	my $len = length($seq);

	my $fams = $md5_to_fam->{$md5};
	if ($fams)
	{
	    for my $fam (@$fams)
	    {
		# print STDERR join("\t", $peg, $len, $fam, 'EXACT', $ffs->family_function($fam)), "\n";
		$kmer_funcs{$peg} = $ffs->family_function($fam);
		$kmer_fams{$peg} = $fam;
		$kmer_score{$peg} = [1000, 1000, 1000, []];
	    }
	    push(@pegs, $peg);
	    next;
	}

	my $md5id = "gnl|md5|$md5";
	my @sims = $fig->sims($md5id, 1000, $sims_cutoff, 'raw');
	
	# print STDERR Dumper($peg, $md5, $len, \@sims);

	if ($iden)
	{
	    @sims = grep { $_->iden > $iden } @sims;
	}

	my %simfams;
	for my $s (@sims)
	{
	    my($sim_md5) = $s->id2 =~ /gnl\|md5\|(.*)/;
	    
	    next unless $sim_md5;

	    if ($iden2)
	    {
		my $mlen = $s->ln1 > $s->ln2 ? $s->ln1 : $s->ln2;
		my $parm = $s->iden * $s->ali_ln / $mlen;
		next if $parm < $iden2;
	    }
	    #my @fams = grep { $_ ne '' } $ffs->families_containing_peg($s->id2);
	    $fams = $md5_to_fam->{$sim_md5};
	    if (ref($fams) && @$fams)
	    {
		push(@{$simfams{$_}}, $s->id2) foreach @$fams;
		# if ($simout)
		# {
		#     print SIMOUT join("\t", $peg, $s->id2, $sim_md5, join(":", @$fams), @$s), "\n";
		# }
	    }
	}
	
	if (%simfams)
	{
	    my %famlens = map { $_ => scalar(@{$simfams{$_}}) } keys %simfams;
	    my @sfams = sort { $famlens{$b} <=> $famlens{$a} } keys %famlens;
	    # die Dumper(\%simfams, \%famlens, \@sfams);
	    if (@sfams == 1 || $famlens{$sfams[0]} > $famlens{$sfams[1]})
	    {
		$kmer_funcs{$peg} = $ffs->family_function($sfams[0]);
		$kmer_fams{$peg} = $sfams[0];
		$kmer_score{$peg} = [999, 999, 999, []];
		push(@pegs, $peg);
	    }
	    else
	    {
		print STDERR "NOASSIGN " . Dumper(\%simfams, \%famlens, \@sfams);
	    }
	    for my $fam (@sfams)
	    {
		my @ids = @{$simfams{$fam}};
		print STDERR join("\t", $peg, $len, $fam, scalar @ids, $ffs->family_function($fam)), "\n";
	    }
	}
	else
	{
	    push(@nomatch, $peg);
	}
    }

    
    close($fh);
    return(\%kmer_funcs, \%kmer_fams, \%kmer_score, \@pegs, \@nomatch);
}

#
# Copy of the logic from find_approx_neigh; included here so that
# we can build a standalone version of this in the kbase kmer_annotation_figfam
# service for use by the genome annotation service.
#
# Here, $proteins is a list of triples ($id, $func, $seq)
#
sub compute_approximate_neighbors
{
    my($self, $proteins) = @_;

    my $core_orgs = $self->{core_orgs};
    if (!$core_orgs)
    {
	$core_orgs = &core_seed_genomes();
	$self->{core_orgs} = $core_orgs;
    }

    my $max_num = 30;
    
    my %id2seqH = map { ($_->[2] && (length($_->[2]) > 30)) ? ($_->[0] => $_->[2]) : () } @$proteins;
    my @poss_pegs = $self->prioritize_pegs_used_to_find_neighbors($proteins);
    my %counts;
    my $best  = 0;
    my $tuple;
    while (($best < 500) && ($tuple = shift @poss_pegs)) {
	my($role,$peg) = @$tuple;
	if ($id2seqH{$peg} && (length($id2seqH{$peg}) > 30)) {
	    $self->compute_hits_and_set_best($tuple, \%id2seqH, \%counts, \$best);
	}
    }
    
    my @reference = sort { $counts{$b} <=> $counts{$a} } keys(%counts);
    if (@reference > $max_num) { $#reference = $max_num-1 }

    my @out;
    
    foreach my $g2 (@reference) {
	if (defined($core_orgs->{$g2})) {
	    push(@out, [$g2, $counts{$g2}, $core_orgs->{$g2}]);
	}
    }
    return \@out;
}

sub prioritize_pegs_used_to_find_neighbors {
    my($self, $proteins) = @_;
    
    my %func_of;
    my %by_func;

    for my $tuple (@$proteins)
    {
	my $f = &SeedUtils::strip_func_comment($tuple->[1]);
	$func_of{$tuple->[0]} = $f;
	push(@{$by_func{$f}}, $tuple->[0]);
    }
    
    my @synthetases        = map {[$_,$by_func{$_}->[0]] } grep { @{$by_func{$_}} == 1 } grep { $_ =~ /tRNA synthetase/o   } keys(%by_func);
    my @ribosomal_proteins = map {[$_,$by_func{$_}->[0]] } grep { @{$by_func{$_}} == 1 } grep { $_ =~ /ribosomal protein/o } keys(%by_func);
    my @ok_pegs            = map {[$_,$by_func{$_}->[0]] } grep { @{$by_func{$_}} == 1 }                                     keys(%by_func);
    
    if ($ENV{VERBOSE} || $ENV{DEBUG}) {
	print STDERR (q(Found ),
		      (scalar @synthetases), q( unique synthetases, ),
		      (scalar @ribosomal_proteins), q( unique ribosomal proteins, ),
		      (scalar @ok_pegs), q( PEGs with unique function),
		      qq(\n)
		     );
    }
    
    my @prioritized = ();
    my %seen;
    foreach my $tuple (@synthetases,@ribosomal_proteins,@ok_pegs) {
	if (! $seen{$tuple->[0]}) {
	    $seen{$tuple->[0]} = 1;
	    push(@prioritized,$tuple);
	}
    }
    return @prioritized;
}

sub compute_hits_and_set_best {
    my ($self, $tuple, $id2seqH, $counts, $bestP) = @_;

    my ($role, $peg) = @$tuple;
    my $figfam_pegs  = $self->figfam_pegs_for_role($role);

    my @sims         = &ProtSims::blastP([[$peg, '', $id2seqH->{$peg}]], $figfam_pegs, 10);

    for (my $i=0; (($i < @sims) && ($i < 50)); ++$i) {
	my $g2 = &SeedUtils::genome_of($sims[$i]->id2);
	$counts->{$g2} += 50 - $i;
	if ($counts->{$g2} > $$bestP) { $$bestP = $counts->{$g2} }
    }
}

sub figfam_pegs_for_role {
    my ($self, $role) = @_;
    
    my %figfams;

    my @fams = $self->{ffs}->families_implementing_role($role);
    my @pegs;
    for my $ff (@fams)
    {
	my $fids = $self->{ffs}->family_pegs($ff);
	#push(@pegs, @$fids);
	push(@pegs, grep { $self->{core_orgs}->{SeedUtils::genome_of($_)} } @$fids);
    }

    return [map { my $seq = $self->{ffs}->{translation}->{$_}; $seq ? [$_,'',$seq] : () } @pegs];
}

sub core_seed_genomes
{
    return {
          '635013.3' => 'Thermincola sp. JR',
          '279010.5' => 'Bacillus licheniformis ATCC 14580',
          '377629.3' => 'Teredinibacter turnerae T7901',
          '717960.3' => 'Eubacterium cylindroides T2-87',
          '484019.3' => 'Thermosipho africanus TCF52B',
          '218491.3' => 'Erwinia carotovora subsp. atroseptica SCRI1043',
          '498211.3' => 'Cellvibrio japonicus Ueda107',
          '358681.3' => 'Brevibacillus brevis NBRC 100599',
          '373903.4' => 'Halothermothrix orenii H 168',
          '1235794.3' => 'Enterorhabdus caecimuris B7',
          '1045004.4' => 'Oenococcus kitaharae DSM 17330',
          '313603.4' => 'Flavobacteriales bacterium HTCC2170',
          '412965.6' => 'Vesicomyosocius okutanii HA',
          '483218.5' => 'Bacteroides pectinophilus ATCC 43243',
          '518766.5' => 'Rhodothermus marinus DSM 4252',
          '272623.1' => 'Lactococcus lactis subsp. lactis Il1403',
          '373994.3' => 'Rivularia sp. PCC 7116',
          '233412.1' => 'Haemophilus ducreyi 35000HP',
          '395965.4' => 'Methylocella silvestris BL2',
          '211586.9' => 'Shewanella oneidensis MR-1',
          '219305.4' => 'Micromonospora sp. ATCC 39149',
          '316056.14' => 'Rhodopseudomonas palustris BisB18',
          '638303.3' => 'Thermocrinis albus DSM 14484',
          '485914.4' => 'Halomicrobium mukohataei DSM 12286',
          '455632.3' => 'Streptomyces griseus subsp. griseus NBRC 13350',
          '351348.5' => 'Marinobacter hydrocarbonoclasticus aquaeolei VT8',
          '887898.3' => 'Lautropia mirabilis ATCC 51599',
          '272626.1' => 'Listeria innocua Clip11262',
          '1005058.3' => 'Gallibacterium anatis UMN179',
          '257309.1' => 'Corynebacterium diphtheriae NCTC 13129',
          '573413.5' => 'Spirochaeta smaragdinae DSM 11293',
          '349521.5' => 'Hahella chejuensis KCTC 2396',
          '340102.3' => 'Pyrobaculum arsenaticum DSM 13514',
          '865937.3' => 'Gillisia limnaea DSM 15749',
          '391619.3' => 'Phaeobacter gallaeciensis BS107',
          '929562.3' => 'Emticicia oligotrophica DSM 17448',
          '869212.3' => 'Turneriella parva DSM 21527',
          '749219.3' => 'Moraxella catarrhalis RH4',
          '334390.3' => 'Lactobacillus fermentum IFO 3956',
          '262724.1' => 'Thermus thermophilus HB27',
          '471870.8' => 'Bacteroides intestinalis DSM 17393',
          '290402.34' => 'Clostridium beijerincki beijerinckii NCIMB 8052',
          '264730.3' => 'Pseudomonas syringae pv. phaseolicola 1448A',
          '247639.3' => 'marine gamma proteobacterium HTCC2080',
          '313598.3' => 'Tenacibaculum sp. MED152',
          '273119.1' => 'Ureaplasma parvum serovar 3 ATCC 700970',
          '401473.3' => 'Bifidobacterium dentium Bd1',
          '384616.5' => 'Pyrobaculum islandicum DSM 4184',
          '1148.1' => 'Synechocystis sp. PCC 6803',
          '266940.5' => 'Kineococcus radiotolerans SRS30216',
          '482234.3' => 'Streptococcus canis FSL Z3-227',
          '1234679.3' => 'Carnobacterium maltaromaticum LMA28',
          '511062.4' => 'Oceanimonas sp. GK1',
          '273116.1' => 'Thermoplasma volcanium GSS1',
          '584708.3' => 'Aminomonas paucivorans DSM 12260',
          '481448.4' => 'Methylacidiphilum infernorum V4',
          '349161.4' => 'Desulfotomaculum reducens MI-1',
          '926556.3' => 'Echinicola vietnamensis DSM 17526',
          '208964.1' => 'Pseudomonas aeruginosa PAO1',
          '395494.4' => 'Gallionella capsiferriformans ES-2',
          '1112215.3' => 'Salinibacterium sp. PAMC 21357',
          '743722.3' => 'Sphingobacterium sp. 21',
          '485918.6' => 'Chitinophaga pinensis DSM 2588',
          '292459.1' => 'Symbiobacterium thermophilum IAM 14863',
          '856793.5' => 'Micavibrio aeruginosavorus ARL-13',
          '443254.3' => 'Marinitoga piezophila KA3',
          '449447.3' => 'Microcystis aeruginosa NIES-843',
          '314345.3' => 'Mariprofundus ferrooxydans PV-1',
          '526225.7' => 'Geodermatophilus obscurus DSM 43160',
          '350058.5' => 'Mycobacterium vanbaaleni vanbaalenii PYR-1',
          '651822.3' => 'Synergistetes bacterium SGP1',
          '267608.1' => 'Ralstonia solanacearum GMI1000',
          '945713.3' => 'Ignavibacterium album JCM 16511',
          '883114.3' => 'Helcococcus kunzii ATCC 51366',
          '246195.3' => 'Dichelobacter nodosus VCS1703A',
          '1120924.3' => 'Acinetobacter baylyi DSM 14961 = CIP 107474',
          '557598.3' => 'Laribacter hongkongensis HLHK9',
          '319225.3' => 'Pelodictyon luteolum DSM 273',
          '186497.1' => 'Pyrococcus furiosus DSM 3638',
          '882378.3' => 'Burkholderia rhizoxinica HKI 454',
          '572547.3' => 'Aminobacterium colombiense DSM 12261',
          '367928.5' => 'Bifidobacterium adolescentis ATCC 15703',
          '454166.6' => 'Salmonella enterica subsp. enterica serovar Agona str. SL483',
          '76114.4' => 'Azoarcus sp. EbN1',
          '889201.3' => 'Streptococcus cristatus ATCC 51100',
          '290434.1' => 'Borrelia garinii PBi',
          '515619.6' => 'Eubacterium rectale ATCC 33656',
          '309799.3' => 'Dictyoglomus thermophilum H-6-12',
          '469378.5' => 'Cryptobacterium curtum DSM 15641',
          '324602.4' => 'Chloroflexus aurantiacus J-10-fl',
          '283165.1' => 'Bartonella quintana str. Toulouse',
          '760011.3' => 'Spirochaeta coccoides DSM 17374',
          '338966.5' => 'Pelobacter propionicus DSM 2379',
          '99287.1' => 'Salmonella typhimurium LT2',
          '66692.3' => 'Bacillus clausii KSM-K16',
          '439235.3' => 'Desulfatibacillum alkenivorans AK-01',
          '546414.3' => 'Deinococcus deserti VCD115',
          '351627.4' => 'Caldicellulosiruptor saccharolyticus DSM 8903',
          '209261.1' => 'Salmonella enterica subsp. enterica serovar Typhi Ty2',
          '439843.6' => 'Salmonella enterica subsp. enterica serovar Schwarzengrund str. CVM19633',
          '314225.8' => 'Erythrobacter litoralis HTCC2594',
          '158879.1' => 'Staphylococcus aureus subsp. aureus N315',
          '757424.7' => 'Herbaspirillum seropedicae SmR1',
          '234826.3' => 'Anaplasma marginale str. St. Maries',
          '36870.1' => 'Wigglesworthia glossinidia endosymbiont of Glossina brevipalpis',
          '283166.1' => 'Bartonella henselae str. Houston-1',
          '178306.1' => 'Pyrobaculum aerophilum str. IM2',
          '349307.9' => 'Methanosaeta thermophila PT',
          '991905.3' => 'Polymorphum gilvum SL003B-26A1',
          '550540.3' => 'Ferrimonas balearica DSM 9799',
          '266779.9' => 'Chelativorans sp. BNC1',
          '523794.5' => 'Leptotrichia buccalis C-1013-b',
          '633131.3' => 'Thalassiobium sp. R2A62',
          '317025.3' => 'Thiomicrospira crunogena XCL-2',
          '485915.5' => 'Desulfohalobium retbaense DSM 5692',
          '195099.3' => 'Campylobacter jejuni RM1221',
          '387092.5' => 'Nitratiruptor sp. SB155-2',
          '1238674.3' => 'Weissella ceti NC36',
          '339671.5' => 'Actinobacillus succinogenes 130Z',
          '386415.6' => 'Clostridium novyi NT',
          '865938.3' => 'Weeksella virosa DSM 16922',
          '706433.3' => 'Solobacterium moorei F0204',
          '85643.4' => 'Thauera sp. MZ1T',
          '458817.3' => 'Shewanella halifaxensis HAW-EB4',
          '391296.7' => 'Streptococcus suis 98HAH33',
          '312309.3' => 'Vibrio fischeri ES114',
          '272621.3' => 'Lactobacillus acidophilus NCFM',
          '349741.3' => 'Akkermansia muciniphila ATCC BAA-835',
          '903503.4' => 'Moranella endobia PCIT',
          '861360.3' => 'Arthrobacter arilaitensis Re117',
          '246201.1' => 'Streptococcus mitis NCTC 12261',
          '281689.4' => 'Desulfuromonas acetoxidans DSM 684',
          '205922.3' => 'Pseudomonas fluorescens PfO-1',
          '411461.4' => 'Dorea formicigenerans ATCC 27755',
          '378753.3' => 'Kocuria rhizophila DC2201',
          '273068.3' => 'Thermoanaerobacter tengcongensis MB4',
          '85963.1' => 'Helicobacter pylori J99',
          '760142.3' => 'Hippea maritima DSM 10411',
          '641149.3' => 'Neisseria sp. oral taxon 014 str. F0314',
          '696281.4' => 'Desulfotomaculum ruminis DSM 2154',
          '679192.3' => 'Bulleidia extructa W1219',
          '537970.9' => 'Helicobacter canadensis MIT 98-5491 (Prj:30719)',
          '262723.3' => 'Mycoplasma synoviae 53',
          '570508.5' => 'Helicobacter pylori P12',
          '434923.3' => 'Coxiella burnetii CbuG_Q212',
          '743718.4' => 'Isoptericola variabilis 225',
          '525328.4' => 'Lactobacillus iners DSM 13335',
          '316275.9' => 'Aliivibrio salmonicida LFI1238',
          '279238.18' => 'Novosphingobium aromaticivorans DSM 12444',
          '272943.3' => 'Rhodobacter sphaeroides 2.4.1',
          '158878.1' => 'Staphylococcus aureus subsp. aureus Mu50',
          '360106.5' => 'Campylobacter fetus subsp. fetus 82-40',
          '243160.4' => 'Burkholderia mallei ATCC 23344',
          '123214.3' => 'Persephonella marina EX-H1',
          '590409.4' => 'Dickeya dadantii Ech586',
          '323097.3' => 'Nitrobacter hamburgensis X14',
          '1122228.3' => 'Metascardovia criceti DSM 17774',
          '338187.4' => 'Vibrio harveyi ATCC BAA-1116',
          '696127.4' => 'Midichloria mitochondrii IricVA',
          '300267.13' => 'Shigella dysenteriae Sd197',
          '272561.1' => 'Chlamydia trachomatis D/UW-3/CX',
          '478749.5' => 'Bryantella formatexigens DSM 14469',
          '867902.3' => 'Ornithobacterium rhinotracheale DSM 15997',
          '471871.7' => 'Clostridium sporogenes ATCC 15579',
          '490899.4' => 'Desulfurococcus kamchatkensis 1221n',
          '533240.4' => 'Cylindrospermopsis raciborskii CS-505',
          '171101.1' => 'Streptococcus pneumoniae R6',
          '43989.3' => 'Cyanothece sp. ATCC 51142',
          '257313.1' => 'Bordetella pertussis Tohama I',
          '203907.1' => 'Blochmannia floridanus',
          '95666.5' => 'Ureaplasma urealyticum serovar 12',
          '596154.3' => 'Alicycliphilus denitrificans K601',
          '312284.4' => 'marine actinobacterium PHSC20C1',
          '70601.1' => 'Pyrococcus horikoshii OT3',
          '100226.1' => 'Streptomyces coelicolor A3(2)',
          '688269.3' => 'Thermotoga thermarum DSM 5069',
          '314267.3' => 'Sulfitobacter sp. NAS-14.1',
          '742821.3' => 'Sutterella wadsworthensis 3_1_45B',
          '458233.11' => 'Macrococcus caseolyticus JCSC5402',
          '318161.14' => 'Shewanella denitrificans OS217',
          '313594.4' => 'Polaribacter irgensii 23-P',
          '1131462.4' => 'Dehalobacter sp. CF',
          '880070.3' => 'Cyclobacterium marinum DSM 745',
          '395495.3' => 'Leptothrix cholodni SP-6',
          '709032.3' => 'Sulfuricurvum kujiense DSM 16994',
          '357244.3' => 'Orientia tsutsugamushi Boryong',
          '416269.5' => 'Actinobacillus pleuropneumoniae L20',
          '1121862.3' => 'Endozoicomonas elysicola DSM 22380',
          '399795.3' => 'Comamonas testosteroni KF-1',
          '390236.5' => 'Borrelia afzelii PKo',
          '243090.15' => 'Rhodopirellula baltica SH 1',
          '210007.1' => 'Streptococcus mutans UA159',
          '667014.3' => 'Thermodesulfatator indicus DSM 15286',
          '756272.5' => 'Planctomyces brasiliensis DSM 5305',
          '321955.3' => 'Brevibacterium linens BL2',
          '438753.3' => 'Azorhizobium caulinodans ORS 571',
          '404380.3' => 'Geobacter bemidjiensis Bem',
          '351607.5' => 'Acidothermus cellulolyticus 11B',
          '639282.3' => 'Deferribacter desulfuricans SSM1',
          '296591.12' => 'Polaromonas sp. JS666',
          '267747.1' => 'Propionibacterium acnes KPA171202',
          '397948.3' => 'Caldivirga maquilingensis IC-167',
          '251221.1' => 'Gloeobacter violaceus PCC 7421',
          '297245.3' => 'Legionella pneumophila str. Lens',
          '431947.6' => 'Porphyromonas gingivalis ATCC 33277',
          '470146.3' => 'Coprococcus comes ATCC 27758',
          '515622.3' => 'Butyrivibrio proteoclasticus B316',
          '83333.1' => 'Escherichia coli K12',
          '252305.5' => 'Oceanicola batsensis HTCC2597',
          '224325.1' => 'Archaeoglobus fulgidus DSM 4304',
          '568817.3' => 'Serratia symbiotica str. \'Cinara cedri\'',
          '413999.4' => 'Clostridium botulinum A str. ATCC 3502',
          '574087.3' => 'Acetohalobium arabaticum DSM 5501',
          '452638.3' => 'Polynucleobacter necessarius subsp. necessarius STIR1',
          '633149.4' => 'Brevundimonas subvibrioides ATCC 15264',
          '1121428.3' => 'Desulfotomaculum hydrothermale Lam5 = DSM 18033',
          '444177.5' => 'Lysinibacillus sphaericus C3-41',
          '258594.1' => 'Rhodopseudomonas palustris CGA009',
          '290315.4' => 'Chlorobium limicola DSM 245',
          '435590.6' => 'Bacteroides vulgatus ATCC 8482',
          '103690.1' => 'Nostoc sp. PCC 7120',
          '411901.7' => 'Bacteroides caccae ATCC 43185',
          '1146883.3' => 'Blastococcus saxobsidens DD2',
          '756067.3' => 'Microcoleus vaginatus FGP-2',
          '335541.4' => 'Syntrophomonas wolfei subsp. wolfei str. Goettingen',
          '182217.3' => 'Helicobacter cetorum MIT 00-7128',
          '526218.6' => 'Sebaldella termitidis ATCC 33386',
          '1007105.3' => 'Pusillimonas sp. T7-7',
          '479436.6' => 'Veillonella parvula DSM 2008',
          '343509.6' => 'Sodalis glossinidius str. \'morsitans\'',
          '96561.3' => 'Desulfococcus oleovorans Hxd3',
          '218491.5' => 'Pectobacterium atrosepticum SCRI1043',
          '931626.3' => 'Acetobacterium woodii DSM 1030',
          '521098.5' => 'Alicyclobacillus acidocaldarius subsp. acidocaldarius DSM 446',
          '37692.4' => 'Phytoplasma mali',
          '314230.4' => 'Blastopirellula marina DSM 3645',
          '573065.6' => 'Asticcacaulis excentricus CB 48',
          '203122.12' => 'Saccharophagus degradans 2-40',
          '302409.3' => 'Ehrlichia ruminantium str. Gardel',
          '629741.3' => 'Kingella oralis ATCC 51147',
          '1085623.3' => 'Glaciecola nitratireducens FR1064',
          '339860.6' => 'Methanosphaera stadtmanae DSM 3091',
          '595494.3' => 'Tolumonas auensis DSM 9187',
          '563194.3' => 'Pediococcus acidilactici 7_4',
          '293653.3' => 'Streptococcus pyogenes MGAS5005',
          '382464.3' => 'Verrucomicrobiae bacterium DG1235',
          '288000.5' => 'Bradyrhizobium sp. BTAi1',
          '240292.3' => 'Anabaena variabilis ATCC 29413',
          '349101.4' => 'Rhodobacter sphaeroides ATCC 17029',
          '314232.4' => 'Loktanella vestfoldensis SKA53',
          '203120.4' => 'Leuconostoc mesenteroides subsp. mesenteroides ATCC 8293',
          '290339.8' => 'Cronobacter sakazakii ATCC BAA-894',
          '195103.9' => 'Clostridium perfringens ATCC 13124',
          '648996.5' => 'Thermovibrio ammonificans HB-1',
          '882.5' => 'Desulfovibrio vulgaris str. Hildenborough',
          '641118.3' => 'Ochrobactrum intermedium LMG 3301',
          '675812.3' => 'Grimontia hollisae CIP 101886',
          '749927.5' => 'Amycolatopsis mediterranei U32',
          '488538.3' => 'alpha proteobacterium IMCC1322',
          '525146.3' => 'Desulfovibrio desulfuricans subsp. desulfuricans str. ATCC 27774',
          '212042.5' => 'Anaplasma phagocytophilum HZ',
          '1132443.3' => 'Methylosarcina fibrata AML-C10',
          '862517.3' => 'Peptoniphilus duerdenii ATCC BAA-1640',
          '177439.1' => 'Desulfotalea psychrophila LSv54',
          '749222.3' => 'Nitratifractor salsuginis DSM 16511',
          '399549.6' => 'Metallosphaera sedula DSM 5348',
          '264732.9' => 'Moorella thermoacetica ATCC 39073',
          '240015.3' => 'Acidobacterium capsulatum ATCC 51196',
          '1002809.3' => 'Solibacillus silvestris StLB046',
          '226900.1' => 'Bacillus cereus ATCC 14579',
          '156586.3' => 'Flavobacteria sp. BBFL7',
          '1171377.3' => 'Bibersteinia trehalosi USDA-ARS-USMARC-192',
          '696747.3' => 'Arthrospira platensis NIES-39',
          '498217.4' => 'Edwardsiella tarda EIB202',
          '394503.6' => 'Clostridium cellulolyticum H10',
          '237727.3' => 'Erythrobacter sp. NAP1',
          '1255043.3' => 'Thioalkalivibrio nitratireducens DSM 14787',
          '693216.3' => 'Cronobacter turicensis z3032',
          '314285.4' => 'Congregibacter litoralis KT71',
          '169963.1' => 'Listeria monocytogenes EGD-e',
          '546274.4' => 'Eikenella corrodens ATCC 23834',
          '326442.4' => 'Pseudoalteromonas haloplanktis TAC125',
          '246200.3' => 'Silicibacter pomeroyi DSS-3',
          '511051.3' => 'Caldisericum exile AZM16c01',
          '393115.8' => 'Francisella tularensis subsp. tularensis FSC198',
          '134676.3' => 'Actinoplanes sp. SE50/110',
          '983917.3' => 'Rubrivivax gelatinosus IL144',
          '309807.19' => 'Salinibacter ruber DSM 13855',
          '471852.6' => 'Thermomonospora curvata DSM 43183',
          '467705.8' => 'Streptococcus gordonii str. Challis substr. CH1',
          '517417.4' => 'Chlorobaculum parvum NCIB 8327',
          '290633.1' => 'Gluconobacter oxydans 621H',
          '870187.4' => 'Thiothrix nivea DSM 5205',
          '517418.3' => 'Chloroherpeton thalassium ATCC 35110',
          '207949.3' => 'Bermanella marisrubri',
          '309798.3' => 'Coprothermobacter proteolyticus DSM 5265',
          '318586.4' => 'Paracoccus denitrificans PD1222',
          '298386.1' => 'Photobacterium profundum SS9',
          '273063.1' => 'Sulfolobus tokodaii str. 7',
          '675635.11' => 'Pseudonocardia dioxanivorans CB1190',
          '221109.1' => 'Oceanobacillus iheyensis HTE831',
          '391037.3' => 'Salinispora arenicola CNS-205',
          '644966.3' => 'Thermaerobacter marianensis DSM 12885',
          '262768.1' => 'Onion yellows phytoplasma OY-M',
          '663278.4' => 'Ethanoligenens harbinense YUAN-3',
          '561229.3' => 'Dickeya zeae Ech1591',
          '272624.3' => 'Legionella pneumophila subsp. pneumophila str. Philadelphia 1',
          '694427.4' => 'Paludibacter propionicigenes WB4',
          '590998.5' => 'Cellulomonas fimi ATCC 484',
          '1248916.3' => 'Sandarakinorhabdus sp. AAP62',
          '228405.5' => 'Hyphomonas neptunium ATCC 15444',
          '380703.5' => 'Aeromonas hydrophila subsp. hydrophila ATCC 7966',
          '259536.4' => 'Psychrobacter sp. 273-4',
          '316279.3' => 'Synechococcus sp. CC9902',
          '314260.5' => 'Parvularcula bermudensis HTCC2503',
          '1234409.3' => 'Catellicoccus marimammalium M35/04/3',
          '445970.5' => 'Alistipes putredinis DSM 17216',
          '63737.4' => 'Nostoc punctiforme PCC 73102',
          '1230341.3' => 'Salimicrobium sp. MJ3',
          '448385.11' => 'Sorangium cellulosum So ce 56',
          '675817.3' => 'Photobacterium damselae subsp. damselae CIP 102761',
          '380749.4' => 'Hydrogenobaculum sp. Y04AAS1',
          '381764.6' => 'Fervidobacterium nodosum Rt17-B1',
          '266835.1' => 'Mesorhizobium loti MAFF303099',
          '1199245.3' => 'secondary endosymbiont of Ctenarytaina eucalypti Thao2000',
          '269800.4' => 'Thermobifida fusca YX',
          '444157.3' => 'Thermoproteus neutrophilus V24Sta',
          '212717.8' => 'Clostridium tetani E88',
          '1026882.3' => 'Methylophaga aminisulfidivorans MP',
          '655811.4' => 'Anaerococcus vaginalis ATCC 51170',
          '580327.4' => 'Thermoanaerobacterium thermosaccharolyticum DSM 571',
          '526227.6' => 'Meiothermus silvanus DSM 9946',
          '314292.23' => 'Photobacterium angustum S14',
          '754252.3' => 'Propionibacterium freudenreichii subsp. shermanii CIRM-BIA1',
          '351605.4' => 'Geobacter uraniireducens Rf4',
          '634176.4' => 'Aggregatibacter aphrophilus NJ8700',
          '272564.4' => 'Desulfitobacterium hafniense DCB-2',
          '717231.3' => 'Flexistipes sinusarabici DSM 4947',
          '716540.3' => 'Erwinia amylovora ATCC 49946',
          '190304.1' => 'Fusobacterium nucleatum subsp. nucleatum ATCC 25586',
          '218496.1' => 'Tropheryma whipplei TW08/27',
          '314231.3' => 'Fulvimarina pelagi HTCC2506',
          '306264.1' => 'Campylobacter upsaliensis RM3195',
          '402880.8' => 'Methanococcus maripaludis C5',
          '323259.5' => 'Methanospirillum hungatei JF-1',
          '592010.4' => 'Abiotrophia defectiva ATCC 49176',
          '419610.8' => 'Methylobacterium extorquens PA1',
          '873533.3' => 'Prevotella oralis ATCC 33269',
          '717773.3' => 'Thioalkalimicrobium cyclicum ALM1',
          '693978.3' => 'Riemerella anatipestifer DSM 15868',
          '979556.3' => 'Microbacterium testaceum StLB037',
          '867900.3' => 'Cellulophaga lytica DSM 7489',
          '765912.4' => 'Thioflavicoccus mobilis 8321',
          '1117647.4' => 'Simiduia agarivorans SA1 = DSM 21679',
          '983544.3' => 'Lacinutrix sp. 5H-3-7-4',
          '456827.3' => 'Cloacamonas acidaminovorans',
          '400668.6' => 'Marinomonas sp. MWYL1',
          '221988.1' => 'Mannheimia succiniciproducens MBEL55E',
          '226186.1' => 'Bacteroides thetaiotaomicron VPI-5482',
          '595499.4' => 'Sulcia muelleri SMDSEM',
          '1278308.3' => 'Zimmermannella faecalis ATCC 13722',
          '525898.7' => 'Sulfurospirillum deleyianum DSM 6946',
          '272620.3' => 'Klebsiella pneumoniae MGH 78578',
          '575589.3' => 'Acinetobacter radioresistens SH164',
          '187303.17' => 'Methylocystis sp. SC2',
          '655438.3' => 'Cycloclasticus pugetii PS-1',
          '198094.1' => 'Bacillus anthracis str. Ames',
          '477974.3' => 'Desulforudis audaxviator MP104C',
          '1185876.3' => 'Fibrisoma limi',
          '530564.3' => 'Pirellula staleyi DSM 6068',
          '299768.3' => 'Streptococcus thermophilus CNRZ1066',
          '399742.4' => 'Enterobacter sp. 638',
          '562970.4' => 'Bacillus tusciae DSM 2912',
          '716544.4' => 'Waddlia chondrophila WSU 86-1044',
          '525897.5' => 'Desulfomicrobium baculatum DSM 4028',
          '504472.7' => 'Spirosoma linguale DSM 74',
          '883111.3' => 'Facklamia hominis CCUG 36813',
          '387344.13' => 'Lactobacillus brevis ATCC 367',
          '269798.12' => 'Cytophaga hutchinsonii ATCC 33406',
          '243273.1' => 'Mycoplasma genitalium G-37',
          '264731.4' => 'Prevotella ruminicola 23',
          '272635.1' => 'Mycoplasma pulmonis UAB CTIP',
          '334380.3' => 'Orientia tsutsugamushi str. Ikeda',
          '709991.3' => 'Odoribacter splanchnicus DSM 20712',
          '402881.6' => 'Parvibaculum lavamentivorans DS-1',
          '349163.4' => 'Acidiphilium cryptum JF-5',
          '316067.3' => 'Geobacter sp. FRC-32',
          '868864.3' => 'Desulfurobacterium thermolithotrophum DSM 11699',
          '717606.6' => 'Paenibacillus curdlanolyticus YK9',
          '426355.14' => 'Methylobacterium radiotolerans JCM 2831',
          '59748.8' => 'Phytoplasma australiense',
          '263820.1' => 'Picrophilus torridus DSM 9790',
          '83332.1' => 'Mycobacterium tuberculosis H37Rv',
          '1279017.3' => 'Microbulbifer variabilis ATCC 700307',
          '441768.4' => 'Acholeplasma laidlawii PG-8A',
          '1303518.3' => 'Chthonomonas calidirosea T49',
          '393595.12' => 'Alcanivorax borkumensis SK2',
          '1073972.4' => 'Arthromitus sp. SFB-mouse-NYU',
          '743721.3' => 'Pseudoxanthomonas suwonensis 11-1',
          '398578.3' => 'Delftia acidovorans SPH-1',
          '155920.1' => 'Xylella fastidiosa Ann-1',
          '521095.6' => 'Atopobium parvulum DSM 20469',
          '1162668.3' => 'Leptospirillum ferrooxidans C2-3',
          '583345.3' => 'Methylotenera mobilis JLW8',
          '137722.3' => 'Azospirillum sp. B510',
          '357809.4' => 'Clostridium phytofermentans ISDg',
          '272631.1' => 'Mycobacterium leprae TN',
          '471857.5' => 'Saccharomonospora viridis DSM 43017',
          '585506.3' => 'Weissella paramesenteroides ATCC 33313',
          '537021.9' => 'Liberibacter asiaticus str. psy62',
          '391009.4' => 'Thermosipho melanesiensis BI429',
          '243277.1' => 'Vibrio cholerae O1 biovar eltor str. N16961',
          '498761.3' => 'Heliobacterium modesticaldum Ice1',
          '632518.3' => 'Caldicellulosiruptor owensensis OL',
          '160491.17' => 'Streptococcus pyogenes str. Manfredo',
          '453591.8' => 'Ignicoccus hospitalis KIN4/I',
          '1122132.3' => 'Kaistia granuli DSM 23481',
          '323848.3' => 'Nitrosospira multiformis ATCC 25196',
          '360107.5' => 'Campylobacter hominis ATCC BAA-381',
          '717959.3' => 'Alistipes shahii WAL 8301',
          '484022.4' => 'Francisella philomiragia subsp. philomiragia ATCC 25017',
          '262543.4' => 'Exiguobacterium sibiricum 255-15',
          '59374.5' => 'Fibrobacter succinogenes subsp. succinogenes S85',
          '880591.3' => 'Ketogulonicigenium vulgare Y25',
          '410359.7' => 'Pyrobaculum calidifontis JCM 11548',
          '263358.5' => 'Verrucosispora maris AB-18-032',
          '926569.3' => 'Anaerolinea thermophila UNI-1',
          '265311.3' => 'Mesoplasma florum L1',
          '883161.3' => 'Propionimicrobium lymphophilum ACS-093-V-SCH5',
          '378806.8' => 'Stigmatella aurantiaca DW4/3-1',
          '645991.3' => 'Syntrophobotulus glycolicus DSM 8271',
          '224308.1' => 'Bacillus subtilis subsp. subtilis str. 168',
          '243265.1' => 'Photorhabdus luminescens subsp. laumondii TTO1',
          '269483.3' => 'Burkholderia cepacia R18194',
          '272558.1' => 'Bacillus halodurans C-125',
          '357544.13' => 'Helicobacter pylori HPAG1',
          '330214.5' => 'Nitrospira defluvii',
          '342108.5' => 'Magnetospirillum magneticum AMB-1',
          '671143.5' => 'Methylomirabilis oxyfera',
          '99598.3' => 'Calothrix sp. PCC 7507',
          '264201.15' => 'Protochlamydia amoebophila UWE25',
          '235909.3' => 'Geobacillus kaustophilus HTA426',
          '439375.7' => 'Ochrobactrum anthropi ATCC 49188',
          '387093.4' => 'Sulfurovum sp. NBC37-1',
          '324057.4' => 'Paenibacillus sp. JDR-2',
          '243164.3' => 'Dehalococcoides ethenogenes 195',
          '1279038.3' => 'Novispirillum itersonii subsp. itersonii ATCC 12639',
          '289376.4' => 'Thermodesulfovibrio yellowstonii DSM 11347',
          '439292.5' => 'Bacillus selenitireducens MLS10',
          '224914.1' => 'Brucella melitensis 16M',
          '929713.3' => 'Niabella soli DSM 19437',
          '335283.5' => 'Nitrosomonas eutropha C91',
          '243275.1' => 'Treponema denticola ATCC 35405',
          '685727.3' => 'Rhodococcus equi 103S',
          '197221.1' => 'Thermosynechococcus elongatus BP-1',
          '338969.3' => 'Rhodoferax ferrireducens DSM 15236',
          '257311.1' => 'Bordetella parapertussis 12822',
          '243231.1' => 'Geobacter sulfurreducens PCA',
          '575540.3' => 'Isosphaera pallida ATCC 43644',
          '1209989.3' => 'Tepidanaerobacter acetatoxydans Re1',
          '471854.4' => 'Dyadobacter fermentans DSM 18053',
          '374847.3' => 'Korarchaeum cryptofilum OPF8',
          '883098.3' => 'Bergeyella zoohelcum CCUG 30536',
          '160492.1' => 'Xylella fastidiosa 9a5c',
          '62928.7' => 'Azoarcus sp. BH72',
          '391600.3' => 'Brevundimonas sp. BAL3',
          '336407.4' => 'Rickettsia bellii RML369-C',
          '535289.3' => 'Diaphorobacter sp. TPSY',
          '297246.3' => 'Legionella pneumophila str. Paris',
          '314262.3' => 'Roseobacter sp. MED193',
          '190650.1' => 'Caulobacter crescentus CB15',
          '667015.3' => 'Bacteroides salanitronis DSM 18170',
          '340099.4' => 'Thermoanaerobacter pseudethanolicus ATCC 33223',
          '630626.3' => 'Escherichia blattae DSM 4481',
          '519442.4' => 'Halorhabdus utahensis DSM 12940',
          '293826.4' => 'Alkaliphilus metalliredigens QYMF',
          '572265.5' => 'Hamiltonella defensa 5AT (Acyrthosiphon pisum)',
          '1206109.5' => 'Portiera aleyrodidarum BT-B',
          '375286.6' => 'Janthinobacterium sp. Marseille',
          '335284.3' => 'Psychrobacter cryohalolentis K5',
          '300852.3' => 'Thermus thermophilus HB8',
          '273075.1' => 'Thermoplasma acidophilum DSM 1728',
          '1006551.4' => 'Klebsiella oxytoca KCTC 1686',
          '349968.3' => 'Yersinia bercovieri ATCC 43970',
          '163164.1' => 'Wolbachia sp. endosymbiont of Drosophila melanogaster',
          '272568.11' => 'Gluconacetobacter diazotrophicus PAl 5',
          '519441.6' => 'Streptobacillus moniliformis DSM 12112',
          '521096.4' => 'Tsukamurella paurometabola DSM 20162',
          '326297.7' => 'Shewanella amazonensis SB2B',
          '262698.3' => 'Brucella abortus biovar 1 str. 9-941',
          '546269.3' => 'Filifactor alocis ATCC 35896',
          '419665.8' => 'Methanococcus aeolicus Nankai-3',
          '194439.1' => 'Chlorobium tepidum TLS',
          '167555.5' => 'Prochlorococcus marinus str. NATL1A',
          '416591.4' => 'Thermotoga lettingae TMO',
          '880073.4' => 'Caldithrix abyssi DSM 13497',
          '33169.1' => 'Eremothecium gossypii',
          '665571.4' => 'Spirochaeta thermophila DSM 6192',
          '411490.6' => 'Anaerostipes caccae DSM 14662',
          '741091.3' => 'Rahnella sp. Y9602',
          '226185.1' => 'Enterococcus faecalis V583',
          '391735.5' => 'Verminephrobacter eiseniae EF01-2',
          '267671.1' => 'Leptospira interrogans serovar Copenhageni str. Fiocruz L1-130',
          '545694.3' => 'Treponema primitia ZAS-2',
          '87626.5' => 'Pseudoalteromonas tunicata D2',
          '273121.1' => 'Wolinella succinogenes DSM 1740',
          '391008.3' => 'Stenotrophomonas maltophilia R551-3',
          '908337.3' => 'Eremococcus coleocola ACS-139-V-Col8',
          '393305.7' => 'Yersinia enterocolitica subsp. enterocolitica 8081',
          '406818.4' => 'Xenorhabdus bovienii SS-2004',
          '485916.5' => 'Desulfotomaculum acetoxidans DSM 771',
          '768704.3' => 'Desulfosporosinus meridiei DSM 13257',
          '521674.6' => 'Planctomyces limnophilus DSM 3776',
          '243365.1' => 'Chromobacterium violaceum ATCC 12472',
          '465515.4' => 'Micrococcus luteus NCTC 2665',
          '452659.3' => 'Rickettsia rickettsii str. Iowa',
          '1007096.3' => 'Oscillibacter ruminantium GH1',
          '694569.3' => 'Aggregatibacter actinomycetemcomitans D7S-1',
          '205914.5' => 'Haemophilus  somnus 129PT',
          '645512.3' => 'Jonquetella anthropi E3_33 E1',
          '761193.3' => 'Runella slithyformis DSM 19594',
          '6035.1' => 'Encephalitozoon cuniculi',
          '287752.3' => 'Aurantimonas manganoxydans SI85-9A1',
          '229193.1' => 'Yersinia pestis biovar Medievalis str. 91001',
          '888741.3' => 'Kingella denitrificans ATCC 33394',
          '243276.1' => 'Treponema pallidum subsp. pallidum str. Nichols',
          '257363.1' => 'Rickettsia typhi str. Wilmington',
          '314275.6' => 'Alteromonas macleodii \'Deep ecotype\'',
          '227882.1' => 'Streptomyces avermitilis MA-4680',
          '983954.3' => 'Methyloversatilis sp. RZ18-153',
          '283942.3' => 'Idiomarina loihiensis L2TR',
          '216432.7' => 'Croceibacter atlanticus HTCC2559',
          '1028307.3' => 'Enterobacter aerogenes KCTC 2190',
          '679197.3' => 'Segniliparus rugosus ATCC BAA-974',
          '348780.3' => 'Natronomonas pharaonis DSM 2160',
          '314254.5' => 'Oceanicaulis alexandrii HTCC2633',
          '420246.5' => 'Geobacillus thermodenitrificans NG80-2',
          '556267.4' => 'Helicobacter winghamensis ATCC BAA-430',
          '651182.5' => 'Desulfobacula toluolica Tol2',
          '1171373.8' => 'Propionibacterium acidipropionici ATCC 4875',
          '1203605.3' => 'Propionibacterium sp. oral taxon 192 str. F0372',
          '590168.4' => 'Thermotoga naphthophila RKU-10',
          '436308.3' => 'Nitrosopumilus maritimus SCM1',
          '573370.3' => 'Desulfovibrio magneticus RS-1',
          '365046.3' => 'Ramlibacter tataouinensis TTB310',
          '368408.5' => 'Thermofilum pendens Hrk 5',
          '1235755.3' => 'Salinicoccus carnicancri Crm',
          '685035.3' => 'Citromicrobium bathyomarinum JL354',
          '395019.3' => 'Burkholderia multivorans ATCC 17616',
          '511145.6' => 'Escherichia coli str. K-12 substr. MG1655',
          '575609.3' => 'Peptoniphilus sp. oral taxon 386 str. F0131',
          '138119.3' => 'Desulfitobacterium sp. Y51',
          '591001.3' => 'Acidaminococcus fermentans DSM 20731',
          '188937.1' => 'Methanosarcina acetivorans C2A',
          '1179773.3' => 'Saccharothrix espanaensis DSM 44229',
          '742159.3' => 'Achromobacter piechaudii ATCC 43553',
          '1208365.4' => 'SAR86 cluster bacterium SAR86E',
          '106370.11' => 'Frankia sp. Ccl3',
          '864564.3' => 'Parascardovia denticolens DSM 10105',
          '388919.8' => 'Streptococcus sanguinis SK36',
          '264462.1' => 'Bdellovibrio bacteriovorus HD100',
          '45361.3' => 'Mycoplasma conjunctivae',
          '335992.3' => 'Pelagibacter ubique HTCC1062',
          '598659.3' => 'Nautilia profundicola AmH',
          '330779.3' => 'Sulfolobus acidocaldarius DSM 639',
          '266834.1' => 'Sinorhizobium meliloti 1021',
          '314607.3' => 'beta proteobacterium KB13',
          '391616.3' => 'Octadecabacter antarcticus 238',
          '443906.9' => 'Clavibacter michiganensis subsp. michiganensis NCPPB 382',
          '565654.4' => 'Enterococcus casseliflavus EC10',
          '478801.5' => 'Kytococcus sedentarius DSM 20547',
          '477641.3' => 'Modestobacter marinus BC501',
          '446471.6' => 'Xylanimonas cellulosilytica DSM 15894',
          '546271.3' => 'Selenomonas sputigena ATCC 35185',
          '398720.4' => 'Leeuwenhoekiella blandensis MED217',
          '415426.7' => 'Hyperthermus butylicus DSM 5456',
          '552396.3' => 'Erysipelotrichaceae bacterium 5_2_54FAA',
          '97393.1' => 'Ferroplasma acidarmanus',
          '522306.3' => 'Accumulibacter phosphatis clade IIA str. UW-1',
          '446466.7' => 'Cellulomonas flavigena DSM 20109',
          '204669.6' => 'Acidobacteria bacterium Ellin345',
          '313596.4' => 'Robiginitalea biformata HTCC2501',
          '391165.8' => 'Granulibacter bethesdensis CGDNIH1',
          '526222.3' => 'Desulfovibrio salexigens DSM 2638',
          '1169145.3' => 'Cryocola sp. 340MFSha3.1',
          '891968.3' => 'Anaerobaculum mobile DSM 13181',
          '552811.9' => 'Dehalogenimonas lykanthroporepellens BL-DC-9',
          '760192.3' => 'Haliscomenobacter hydrossis DSM 1100',
          '1173026.3' => 'Gloeocapsa sp. PCC 7428',
          '657313.3' => 'Ruminococcus torques L2-14',
          '907.4' => 'Megasphaera elsdenii',
          '653733.4' => 'Desulfurispirillum indicum S5',
          '1195246.3' => 'Alishewanella agri BL06',
          '383372.4' => 'Roseiflexus castenholzi DSM 13941',
          '388413.5' => 'Algoriphagus sp. PR1',
          '706434.3' => 'Megasphaera micronuciformis F0359',
          '479434.6' => 'Sphaerobacter thermophilus DSM 20745',
          '655815.4' => 'Zunongwangia profunda SM-A87',
          '525280.3' => 'Erysipelothrix rhusiopathiae ATCC 19414',
          '1123502.3' => 'Wohlfahrtiimonas chitiniclastica DSM 18708',
          '911045.3' => 'Pseudovibrio sp. FO-BEG1',
          '134287.3' => 'secondary endosymbiont of Heteropsylla cubana Thao2000',
          '638301.3' => 'Granulicatella adiacens ATCC 49175',
          '871585.3' => 'Acinetobacter calcoaceticus PHEA-2',
          '334413.6' => 'Finegoldia magna ATCC 29328',
          '335543.6' => 'Syntrophobacter fumaroxidans MPOB',
          '649638.3' => 'Truepera radiovictrix DSM 17093',
          '501479.3' => 'Citreicella sp. SE45',
          '457570.7' => 'Natranaerobius thermophilus JW/NM-WN-LF',
          '292415.3' => 'Thiobacillus denitrificans ATCC 25259',
          '857087.3' => 'Methylomonas methanica MC09',
          '521460.8' => 'Anaerocellum thermophilum DSM 6725',
          '657308.3' => 'Gordonibacter pamelaeae 7-10-1-b',
          '177437.4' => 'Desulfobacterium autotrophicum HRM2',
          '592031.3' => 'Eubacterium saphenum ATCC 49989',
          '272942.6' => 'Rhodobacter capsulatus SB1003',
          '593907.5' => 'Cellvibrio gilvus ATCC 13127 ([Cellvibrio] gilvus ATCC 13127)',
          '314723.3' => 'Borrelia hermsii DAH',
          '929563.3' => 'Leptonema illini DSM 21528',
          '223926.6' => 'Vibrio parahaemolyticus RIMD 2210633',
          '410358.8' => 'Methanocorpusculum labreanum Z',
          '523850.3' => 'Thermococcus onnurineus NA1',
          '755732.3' => 'Fluviicola taffensis DSM 16823',
          '608534.3' => 'Oribacterium sp. oral taxon 078 str. F0262',
          '1193729.4' => 'Endolissoclinum patella L2',
          '556268.6' => 'Oxalobacter formigenes HOxBLS',
          '314266.4' => 'Sphingomonas sp. SKA58',
          '218497.4' => 'Chlamydophila abortus S26/3',
          '637380.6' => 'Bacillus cereus biovar anthracis str. CI',
          '85962.1' => 'Helicobacter pylori 26695',
          '243274.1' => 'Thermotoga maritima MSB8',
          '1051632.5' => 'Sulfobacillus acidophilus TPY',
          '566551.4' => 'Cedecea davisae DSM 4568',
          '985867.6' => 'Odyssella thessalonicensis L13',
          '97084.1' => 'Bacteriovorax marinus SJ',
          '272634.1' => 'Mycoplasma pneumoniae M129',
          '347257.4' => 'Mycoplasma agalactiae PG2',
          '511680.4' => 'Butyrivibrio crossotus DSM 2876',
          '235279.1' => 'Helicobacter hepaticus ATCC 51449',
          '247156.1' => 'Nocardia farcinica IFM 10152',
          '271065.3' => 'Methylomicrobium alcaliphilum',
          '329726.14' => 'Acaryochloris marina MBIC11017',
          '570509.6' => 'Spiroplasma melliferum KC3',
          '321967.8' => 'Lactobacillus casei ATCC 334',
          '390333.6' => 'Lactobacillus delbrueckii subsp. bulgaricus ATCC 11842',
          '216596.11' => 'Rhizobium leguminosarum bv. viciae 3841',
          '452637.4' => 'Opitutus terrae PB90-1',
          '1140.3' => 'Synechococcus elongatus PCC 7942',
          '405948.6' => 'Saccharopolyspora erythraea NRRL 2338',
          '515620.4' => 'Eubacterium eligens ATCC 27750',
          '442563.3' => 'Bifidobacterium animalis subsp. lactis AD011',
          '768066.3' => 'Halomonas elongata DSM 2581',
          '580332.5' => 'Sideroxydans lithotrophicus ES-1',
          '1122137.3' => 'Kordiimonas gwangyangensis DSM 19435',
          '264203.3' => 'Zymomonas mobilis subsp. mobilis ZM4',
          '246194.3' => 'Carboxydothermus hydrogenoformans Z-2901',
          '445987.3' => 'Borrelia valaisiana VS116',
          '338963.3' => 'Pelobacter carbinolicus DSM 2380',
          '290512.6' => 'Prosthecochloris aestuarii DSM 271',
          '357808.3' => 'Roseiflexus sp. RS-1',
          '643867.3' => 'Marivirga tractuosa DSM 4126',
          '405955.9' => 'Escherichia coli APEC O1',
          '411154.5' => 'Gramella forsetii KT0803',
          '485917.6' => 'Pedobacter heparinus DSM 2366',
          '269796.9' => 'Rhodospirillum rubrum ATCC 11170',
          '1122135.3' => 'Kiloniella laminariae DSM 19542',
          '266264.4' => 'Cupriavidus metallidurans CH34',
          '267377.1' => 'Methanococcus maripaludis S2',
          '1048339.3' => 'Sporichthya polymorpha DSM 43042',
          '156889.7' => 'Magnetococcus sp. MC-1',
          '1218108.3' => 'Empedobacter brevis NBRC 14943 = ATCC 43319',
          '1163389.3' => 'Francisella noatunensis subsp. orientalis str. Toba 04',
          '176279.3' => 'Staphylococcus epidermidis RP62A',
          '592026.3' => 'Catonella morbi ATCC 51271',
          '160490.1' => 'Streptococcus pyogenes M1 GAS',
          '342610.6' => 'Pseudoalteromonas atlantica T6c',
          '582744.3' => 'Methylovorus sp. SIP3-4',
          '450851.6' => 'Phenylobacterium zucineum HLK1',
          '1157951.4' => 'Providencia stuartii MRSN 2154',
          '582899.7' => 'Hyphomicrobium denitrificans ATCC 51888',
          '392499.4' => 'Sphingomonas wittichii RW1',
          '553190.4' => 'Gardnerella vaginalis 409-05',
          '640081.3' => 'Dechlorosoma suillum PS',
          '232721.5' => 'Acidovorax sp. JS42',
          '444158.3' => 'Methanococcus maripaludis C6',
          '429009.3' => 'Ammonifex degensii KC4',
          '292805.3' => 'Wolbachia endosymbiont strain TRS of Brugia malayi',
          '180281.4' => 'Cyanobium sp. PCC 7001',
          '309801.4' => 'Thermomicrobium roseum DSM 5159',
          '648757.4' => 'Rhodomicrobium vannielii ATCC 17100',
          '375451.6' => 'Roseobacter denitrificans OCh 114',
          '572480.3' => 'Arcobacter nitrofigilis DSM 7299',
          '479432.6' => 'Streptosporangium roseum DSM 43021',
          '553217.3' => 'Enhydrobacter aerosaccus SK60',
          '634503.3' => 'Edwardsiella ictaluri 93-146',
          '572477.4' => 'Allochromatium vinosum DSM 180',
          '298653.4' => 'Frankia sp. EAN1pec',
          '509169.3' => 'Xanthomonas campestris pv. campestris str. B100',
          '176299.3' => 'Agrobacterium tumefaciens str. C58',
          '324925.4' => 'Pelodictyon phaeoclathratiforme BU-1',
          '533247.5' => 'Raphidiopsis brookii D9',
          '355278.4' => 'Leptospira biflexa serovar Patoc strain \'Patoc 1 (Ames)\'',
          '1120961.3' => 'Ahrensia kielensis DSM 5890',
          '187420.1' => 'Methanothermobacter thermautotrophicus str. Delta H',
          '445973.7' => 'Clostridium bartlettii DSM 16795',
          '420247.6' => 'Methanobrevibacter smithii ATCC 35061',
          '323261.3' => 'Nitrosococcus oceani ATCC 19707',
          '314265.3' => 'Roseovarius sp. HTCC2601',
          '159087.4' => 'Dechloromonas aromatica RCB',
          '396588.3' => 'Thioalkalivibrio sp. HL-EbGR7',
          '399726.4' => 'Thermoanaerobacter sp. X514',
          '196627.4' => 'Corynebacterium glutamicum ATCC 13032',
          '295358.3' => 'Mycoplasma hyopneumoniae 232',
          '326424.13' => 'Frankia alni ACN14a',
          '649639.5' => 'Bacillus cellulosilyticus DSM 2522',
          '272562.1' => 'Clostridium acetobutylicum ATCC 824',
          '1078846.3' => 'Methylovulum miyakonense HT12',
          '795359.3' => 'Thermodesulfobacterium sp. OPB45',
          '281309.3' => 'Bacillus thuringiensis serovar konkukian str. 97-27',
          '190485.1' => 'Xanthomonas campestris pv. campestris ATCC 33913',
          '1156986.4' => 'Diplorickettsia massiliensis 20B',
          '272844.1' => 'Pyrococcus abyssi GE5',
          '167879.3' => 'Colwellia psychrerythraea 34H',
          '379066.3' => 'Gemmatimonas aurantiaca T-27',
          '160488.1' => 'Pseudomonas putida KT2440',
          '351160.3' => 'Uncultured methanogenic archaeon RC-I',
          '259564.8' => 'Methanococcoides burtonii DSM 6242',
          '499177.3' => 'Clostridium sticklandii DSM 519',
          '203275.8' => 'Tannerella forsythia ATCC 43037',
          '360095.7' => 'Bartonella bacilliformis KC583',
          '399741.3' => 'Serratia proteamaculans 568',
          '543728.3' => 'Variovorax paradoxus S110',
          '388399.4' => 'Sagittula stellata E-37',
          '272633.1' => 'Mycoplasma penetrans HF-2',
          '234267.9' => 'Solibacter usitatus Ellin6076',
          '657314.3' => 'Ruminococcus obeum A2-162',
          '1260251.3' => 'Spiribacter salinus M19-40',
          '266117.6' => 'Rubrobacter xylanophilus DSM 9941',
          '349124.5' => 'Halorhodospira halophila SL1',
          '521003.7' => 'Collinsella intestinalis DSM 13280',
          '272557.1' => 'Aeropyrum pernix K1',
          '224911.1' => 'Bradyrhizobium japonicum USDA 110',
          '362242.7' => 'Mycobacterium ulcerans Agy99',
          '479435.6' => 'Kribbella flavida DSM 17836',
          '666685.3' => 'Rhodanobacter sp. 2APBS1',
          '479437.5' => 'Eggerthella lenta DSM 2243',
          '370438.3' => 'Pelotomaculum thermopropionicum SI',
          '592022.4' => 'Bacillus megaterium DSM319',
          '245012.3' => 'butyrate-producing bacterium SM4/1',
          '639283.3' => 'Starkeya novella DSM 506',
          '290397.13' => 'Anaeromyxobacter dehalogenans 2CP-C',
          '396513.4' => 'Staphylococcus carnosus subsp. carnosus TM300',
          '563192.3' => 'Bilophila wadsworthia 3_1_6',
          '13035.3' => 'Dactylococcopsis salina PCC 8305',
          '326426.4' => 'Bifidobacterium breve UCC2003',
          '1123236.3' => 'Salinimonas chungwhensis DSM 16280',
          '1147128.3' => 'Bifidobacterium asteroides PRL2011',
          '196162.6' => 'Nocardioides sp. JS614',
          '675814.3' => 'Vibrio coralliilyticus ATCC BAA-450',
          '445932.3' => 'Elusimicrobium minutum Pei191',
          '397945.5' => 'Acidovorax avenae subsp. citrulli AAC00-1',
          '400667.4' => 'Acinetobacter baumannii ATCC 17978',
          '657321.5' => 'Ruminococcus bromii L2-63',
          '572544.3' => 'Ilyobacter polytropus DSM 2926',
          '243233.4' => 'Methylococcus capsulatus str. Bath',
          '392500.3' => 'Shewanella woodyi ATCC 51908',
          '608538.3' => 'Hydrogenobacter thermophilus TK-6',
          '572479.3' => 'Halanaerobium praevalens DSM 2228',
          '452662.3' => 'Sphingobium japonicum UT26S',
          '204536.4' => 'Sulfurihydrogenibium azorense Az-Fu1',
          '871968.4' => 'Desulfitobacterium metallireducens DSM 15288',
          '521045.3' => 'Kosmotoga olearia TBF 19.5.1',
          '880072.3' => 'Desulfobacca acetoxidans DSM 11109',
          '644282.4' => 'Desulfarculus baarsii DSM 2075',
          '1005048.3' => 'Collimonas fungivorans Ter331',
          '267748.1' => 'Mycoplasma mobile 163K',
          '552526.7' => 'Streptococcus equi subsp. zooepidemicus MGCS10565',
          '762948.4' => 'Rothia dentocariosa ATCC 17931',
          '575594.3' => 'Lactobacillus coleohominis 101-4-CHN',
          '767100.3' => 'Parvimonas sp. oral taxon 110 str. F0139',
          '357804.5' => 'Psychromonas ingrahami ingrahamii 37',
          '862965.3' => 'Haemophilus parainfluenzae T3T1',
          '101510.15' => 'Rhodococcus jostii RHA1',
          '880071.3' => 'Flexibacter litoralis DSM 6794',
          '592028.3' => 'Dialister invisus DSM 15470',
          '243230.1' => 'Deinococcus radiodurans R1',
          '866536.3' => 'Belliella baltica DSM 15883',
          '290398.4' => 'Chromohalobacter salexigens DSM 3043',
          '471855.5' => 'Slackia heliotrinireducens DSM 20476',
          '205921.3' => 'Streptococcus agalactiae A909',
          '363253.4' => 'Lawsonia intracellularis PHE/MN1-00',
          '638300.3' => 'Cardiobacterium hominis ATCC 15826',
          '525904.6' => 'Thermobaculum terrenum ATCC BAA-798',
          '246197.19' => 'Myxococcus xanthus DK 1622',
          '643562.6' => 'Desulfovibrio aespoeensis Aspo-2',
          '523791.5' => 'Kangiella koreensis DSM 16069',
          '446469.4' => 'Sanguibacter keddiei keddieii DSM 10542',
          '1172188.3' => 'Terracoccus sp. 273MFTsu3.1',
          '192952.1' => 'Methanosarcina mazei Go1',
          '1166018.3' => 'Fibrella aestuarina',
          '369723.3' => 'Salinispora tropica CNB-440',
          '395493.3' => 'Beggiatoa alba B18LD',
          '290318.4' => 'Prosthecochloris vibrioformis DSM 265',
          '71421.1' => 'Haemophilus influenzae Rd KW20',
          '246200.7' => 'Ruegeria pomeroyi DSS-3',
          '869210.3' => 'Marinithermus hydrothermalis DSM 14884',
          '649349.3' => 'Leadbetterella byssophila DSM 17132',
          '563178.3' => 'Buchnera aphidicola str. 5A (Acyrthosiphon pisum)',
          '626523.3' => 'Shuttleworthia satelles DSM 14600',
          '600809.5' => 'Blattabacterium sp. (Periplaneta americana) str. BPLAN',
          '279808.3' => 'Staphylococcus haemolyticus JCSC1435',
          '203267.1' => 'Tropheryma whipplei str. Twist',
          '431943.4' => 'Clostridium kluyveri DSM 555',
          '380394.3' => 'Acidithiobacillus ferrooxidans ATCC 53993',
          '525909.11' => 'Acidimicrobium ferrooxidans DSM 10331',
          '59196.3' => 'Rickettsiella grylli',
          '598467.3' => 'Brenneria sp. EniD312',
          '504728.4' => 'Meiothermus ruber DSM 1279',
          '282458.1' => 'Staphylococcus aureus subsp. aureus MRSA252',
          '65093.3' => 'Halothece sp. PCC 7418',
          '666684.3' => 'Afipia sp. 1NLS2',
          '469381.4' => 'Dethiosulfovibrio peptidovorans DSM 11002',
          '265072.7' => 'Methylobacillus flagellatus KT',
          '500635.8' => 'Mitsuokella multacida DSM 20544',
          '452652.3' => 'Kitasatospora setae KM-6054',
          '224326.1' => 'Borrelia burgdorferi B31',
          '340177.8' => 'Chlorobium chlorochromatii CaD3',
          '452471.3' => 'Amoebophilus asiaticus 5a2',
          '710696.3' => 'Intrasporangium calvum DSM 43043',
          '504832.4' => 'Oligotropha carboxidovorans OM5',
          '164546.7' => 'Cupriavidus taiwanensis',
          '469618.3' => 'Fusobacterium varium ATCC 27725',
          '446470.6' => 'Stackebrandtia nassauensis DSM 44728',
          '545696.5' => 'Holdemania filiformis DSM 12042',
          '382638.8' => 'Helicobacter acinonychis str. Sheeba',
          '592029.3' => 'Nonlabens dokdonensis DSW-6',
          '573234.4' => 'Hodgkinia cicadicola Dsem',
          '372461.16' => 'Buchnera aphidicola str. Cc (Cinara cedri)',
          '883.3' => 'Desulfovibrio vulgaris str. \'Miyazaki F\'',
          '1121876.3' => 'Fangia hongkongensis DSM 21703',
          '565045.3' => 'gamma proteobacterium NOR51-B',
          '115711.7' => 'Chlamydophila pneumoniae AR39',
          '354242.8' => 'Campylobacter jejuni subsp. jejuni 81-176',
          '367737.4' => 'Arcobacter butzleri RM4018',
          '1316932.3' => 'Mannheimia haemolytica M42548',
          '264198.3' => 'Ralstonia eutropha JMP134',
          '521097.5' => 'Capnocytophaga ochracea DSM 7271',
          '436114.3' => 'Sulfurihydrogenibium sp. YO3AOP1',
          '272559.3' => 'Bacteroides fragilis ATCC 25285',
          '313595.4' => 'Psychroflexus torquis ATCC 700755',
          '398767.5' => 'Geobacter lovleyi SZ',
          '207559.3' => 'Desulfovibrio desulfuricans G20',
          '563041.5' => 'Helicobacter pylori G27',
          '203123.5' => 'Oenococcus oeni PSU-1',
          '406327.7' => 'Methanococcus vannieli vannielii SB',
          '411466.7' => 'Actinomyces odontolyticus ATCC 17982',
          '290338.6' => 'Citrobacter koseri ATCC BAA-895',
          '52598.8' => 'Sulfitobacter sp. EE-36',
          '487797.3' => 'Flavobacteria bacterium MS024-3C',
          '446468.6' => 'Nocardiopsis dassonvillei subsp. dassonvillei DSM 43111',
          '869209.3' => 'Treponema succinifaciens DSM 2489',
          '411483.3' => 'Faecalibacterium prausnitzii A2-165',
          '83334.1' => 'Escherichia coli O157:H7',
          '706191.3' => 'Pantoea ananatis LMG 20103',
          '445972.6' => 'Anaerotruncus colihominis DSM 17241',
          '680198.5' => 'Streptomyces scabiei 87.22',
          '288705.3' => 'Renibacterium salmoninarum ATCC 33209',
          '311403.8' => 'Agrobacterium radiobacter K84',
          '577650.3' => 'Desulfobulbus propionicus DSM 2032',
          '491915.4' => 'Anoxybacillus flavithermus WK1',
          '471853.5' => 'Beutenbergia cavernae DSM 12333',
          '940190.3' => 'Melissococcus plutonius ATCC 35311',
          '269797.3' => 'Methanosarcina barkeri str. fusaro',
          '257310.1' => 'Bordetella bronchiseptica RB50',
          '670487.3' => 'Oceanithermus profundus DSM 14977',
          '203124.6' => 'Trichodesmium erythraeum IMS101',
          '374463.4' => 'Baumannia cicadellinicola str. Hc (Homalodisca coagulata)',
          '1203568.3' => 'Dermabacter sp. HFH0086',
          '743720.3' => 'Pseudomonas fulva 12-X',
          '632292.3' => 'Caldicellulosiruptor hydrothermalis 108',
          '1191523.3' => 'Melioribacter roseus P3M',
          '203119.11' => 'Clostridium thermocellum ATCC 27405',
          '471856.5' => 'Jonesia denitrificans DSM 20603',
          '228410.1' => 'Nitrosomonas europaea ATCC 19718',
          '1069534.5' => 'Lactobacillus ruminis ATCC 27782',
          '190486.1' => 'Xanthomonas axonopodis pv. citri str. 306',
          '222891.5' => 'Neorickettsia sennetsu str. Miyayama',
          '325240.9' => 'Shewanella baltica OS155',
          '1121451.3' => 'Desulfovibrio hydrothermalis AM13 = DSM 14728',
          '882102.3' => 'Vibrio anguillarum 775',
          '591365.3' => 'Streptococcus intermedius JTH08',
          '196164.1' => 'Corynebacterium efficiens YS-314',
          '583355.3' => 'Coraliomargarita akajimensis DSM 45221',
          '273123.1' => 'Yersinia pseudotuberculosis IP 32953',
          '376686.6' => 'Flavobacterium johnsonia johnsoniae UW101',
          '471821.5' => 'uncultured Termite group 1 bacterium phylotype Rs-D17',
          '198215.1' => 'Shigella flexneri 2a str. 2457T',
          '765420.3' => 'Oscillochloris trichoides DG6',
          '69014.3' => 'Thermococcus kodakarensis KOD1',
          '122587.1' => 'Neisseria meningitidis Z2491',
          '428406.5' => 'Ralstonia pickettii 12D',
          '696748.4' => 'Actinobacillus suis H91-0380',
          '1298593.3' => 'Thalassolituus oleivorans MIL-1',
          '983545.3' => 'Glaciecola sp. 4H-3-7+YE-5',
          '718255.3' => 'Roseburia intestinalis XB6B4',
          '562982.3' => 'Gemella moribillum M424',
          '469596.3' => 'Coprobacillus sp. 29_1',
          '446462.8' => 'Actinosynnema mirum DSM 43827',
          '269799.3' => 'Geobacter metallireducens GS-15',
          '64091.1' => 'Halobacterium sp. NRC-1',
          '314283.5' => 'Reinekea blandensis MED297',
          '525364.3' => 'Lactobacillus salivarius ATCC 11741',
          '744980.3' => 'Roseibium sp. TrichSKD4',
          '244592.3' => 'Labrenzia alexandrii DFL-11',
          '589865.4' => 'Desulfurivibrio alkaliphilus AHT2',
          '243090.1' => 'Pirellula sp. 1',
          '391904.3' => 'Bifidobacterium longum subsp. infantis ATCC 15697',
          '452863.6' => 'Arthrobacter chlorophenolicus A6',
          '317655.9' => 'Sphingopyxis alaskensis RB2256',
          '746697.3' => 'Aequorivita sublithincola DSM 14238',
          '312153.3' => 'Polynucleobacter sp. QLW-P1DMWA-1',
          '937774.3' => 'Taylorella equigenitalis MCE9',
          '526224.6' => 'Brachyspira murdochii DSM 12563',
          '228908.1' => 'Nanoarchaeum equitans Kin4-M',
          '717961.3' => 'Eubacterium siraeum V10Sc8a',
          '688270.3' => 'Cellulophaga algicola DSM 14237',
          '190192.1' => 'Methanopyrus kandleri AV19',
          '411684.3' => 'Hoeflea phototrophica DFL-43',
          '243232.1' => 'Methanocaldococcus jannaschii DSM 2661',
          '391587.3' => 'Kordia algicida OT-1',
          '515618.4' => 'Riesia pediculicola USDA',
          '269484.4' => 'Ehrlichia canis str. Jake',
          '243161.4' => 'Chlamydia muridarum Nigg',
          '316274.3' => 'Herpetosiphon aurantiacus ATCC 23779',
          '445971.6' => 'Anaerofustis stercorihominis DSM 17244',
          '551115.6' => 'Trichormus azollae 0708',
          '521011.3' => 'Methanosphaerula palustris E1-9c',
          '331104.5' => 'Blattabacterium sp. (Blattella germanica) str. Bge',
          '1184607.3' => 'Austwickia chelonae NBRC 105200',
          '1088868.3' => 'Commensalibacter intestini A911',
          '350688.3' => 'Alkaliphilus oremlandi oremlandii OhILAs',
          '580331.4' => 'Thermoanaerobacter italicus Ab9',
          '1049789.4' => 'Leptospira broomii str. 5399',
          '398580.3' => 'Dinoroseobacter shibae DFL 12',
          '702113.7' => 'Novosphingobium sp. PP1Y',
          '1215343.11' => 'Liberibacter crescens BT-1',
          '272843.1' => 'Pasteurella multocida subsp. multocida str. Pm70',
          '63186.3' => 'Zobellia galactanivorans',
          '857290.3' => 'Scardovia wiggsiae F0424',
          '240016.6' => 'Verrucomicrobium spinosum DSM 4136',
          '1173022.3' => 'Crinalium epipsammum PCC 9333',
          '866775.3' => 'Aerococcus urinae ACS-120-V-Col10a',
          '261594.1' => 'Bacillus anthracis str. \'Ames Ancestor\'',
          '217.1' => 'Helicobacter mustelae 43772',
          '224324.1' => 'Aquifex aeolicus VF5',
          '204773.3' => 'Herminiimonas arsenicoxydans',
          '319795.16' => 'Deinococcus geothermalis DSM 11300',
          '426368.9' => 'Methanococcus maripaludis C7',
          '1069080.3' => 'Succinispira mobilis DSM 6222',
          '485913.3' => 'Ktedonobacter racemifer DSM 44963',
          '399550.6' => 'Staphylothermus marinus F1',
          '610130.3' => 'Clostridium saccharolyticum WM1',
          '645463.3' => 'Clostridium difficile R20291',
          '313589.5' => 'Janibacter sp. HTCC2649',
          '313590.6' => 'Dokdonia donghaensis MED134',
          '483216.6' => 'Bacteroides eggerthii DSM 20697',
          '326298.3' => 'Thiomicrospira denitrificans ATCC 33889',
          '403833.5' => 'Petrotoga mobilis SJ95',
          '512562.4' => 'Helicobacter pylori Shi470',
          '279714.3' => 'Lutiella nitroferrum 2002',
          '368407.6' => 'Methanoculleus marisnigri JR1',
          '1538.8' => 'Clostridium ljungdahlii',
          '557723.7' => 'Haemophilus parasuis SH0165',
          '314264.3' => 'Roseovarius sp. 217',
          '525903.6' => 'Thermanaerovibrio acidaminovorans DSM 6589',
          '273057.1' => 'Sulfolobus solfataricus P2',
          '316407.3' => 'Escherichia coli W3110',
          '525919.4' => 'Anaerococcus prevoti prevotii DSM 20548',
          '479431.6' => 'Nakamurella multipartita DSM 44233',
          '903814.3' => 'Eubacterium limosum KIST612',
          '402612.4' => 'Flavobacterium psychrophilum JIP02/86',
          '768710.3' => 'Desulfosporosinus youngiae DSM 17734',
          '187272.6' => 'Alkalilimnicola ehrlichii MLHE-1'
        };
}

1;
