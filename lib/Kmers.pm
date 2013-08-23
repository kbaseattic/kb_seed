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

use strict;
use DB_File;
use File::Basename;
use FIG;

use Tracer;

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
    $figfams->{fig} = new FIG;


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
	    if (! &FIG::hypo($func))
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
		    if (! &FIG::hypo($func))
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

    $matches = $self->process_dna_seq(&FIG::reverse_comp($seq));
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
    $matches = $self->process_prot_seq($motif_sz, &FIG::reverse_comp($seq));
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
	my $tran = uc &FIG::translate(substr($seq,$off,$ln_tran));

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

1;
