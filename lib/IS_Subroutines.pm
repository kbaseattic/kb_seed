#! /usr/bin/env perl

# This is a SAS Component

package IS_Subroutines;
use strict;
use gjoseqlib;
use IS_Data;
use Tpn_Int_Reps;
use gjoalignandtree;
use Data::Dumper;

#===============================================================================
#  This package does the heavy lifting for the insertion sequence finder 
#
#  Usage:  use IS_Subroutines;
#
#===============================================================================



use strict;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
		add_features_formatted_matches
		denovo_is_search
		filter_hsps
		full_length_IS_from_end_hsps
		subseq
);



#----------------------------------------------------
#  sub add_features_formatted_matches 
#
#  For every hsp returned from BlastInterface,
#  this will return an array of "rast-add-features"
#  formatted locations.  It currently invents an identifier.
#  It assumes a seed-formatted contig id which is:
#     "Genome_ID:contigID", e.g., "83333.1:NC_000913".
#  It also assumes 1hsp per query.
#  @array = add_features_formatted_matches ($feature_type, $fn, @hsps);
#
#----------------------------------------------------
sub add_features_formatted_matches
{
	my $feature  = shift @_;  ## these should probably have been assigned later.
	my $function = shift @_;
	my @matches = @_;
	my %contigs = map{$_->[0], 0}@matches;
	my @array;
	my $count = 0;

	#sort and process the matches by contig and position
	for my $key ( sort {$a cmp $b} keys %contigs) 
	{
		my @cmatch = grep{$_->[0] eq $key}@matches;	
    	my @cmatchsort = sort { $a->[6] <=> $b->[6] } @cmatch;     	
     	
		for my $i (0..$#cmatchsort)
		{
			my $gid = $cmatchsort[0][0];
			$gid =~ s/\:.+//g;
			my $id = "$gid"."."."$feature".".".($count + 1);					
			if ($cmatchsort[$i][8] < $cmatchsort[$i][9])  # matches subject in forward direction
			{
				my $loc =  "$cmatchsort[$i][0]"."_"."$cmatchsort[$i][6]"."_"."$cmatchsort[$i][7]";
				push @array, [$id, $loc, $feature, $function];
			}
			if ($cmatchsort[$i][8] > $cmatchsort[$i][9])  # matches subject in reverse direction
			{
				my $loc = "$cmatchsort[$i][0]"."_"."$cmatchsort[$i][7]"."_"."$cmatchsort[$i][6]";
				push @array, [$id, $loc, $feature, $function];
			}    
	    $count ++;
		}
	}
	return @array;
}


#----------------------------------------------------
#  sub denovo_is_search
#  this subroutine searches for IS elements by finding matches to the 
#  representative transposase genes in Tpn_Int_Reps.pm and then looking for 
#  inverted repeats within n distance in bp from either end.
#  my @coordinates = denovo_is_search($dist, \@contigs);
#----------------------------------------------------
sub denovo_is_search
{
	my $dist = shift @_;
	my $contr = shift @_;
	my @contigs = @$contr;
	
	my %Tpn_Data = %Tpn_Int_Reps::Tpn_Data;

	my $tpn_seqr    = $Tpn_Data{tpns};
	my @rep_tpns    = @$tpn_seqr;  
	
	my %opts = ( 
				 blastplus     => 1,
				 #evalue        => 0.00001,
			     #perc_identity => 0.5,
				 #minPos        => 0.4,
				 #		     minCovS       => 0.5,
			     num_threads   => 12,
		        );                          

	my @blastx = &BlastInterface::blastx( \@contigs, \@rep_tpns, \%opts ); 
	my @tpn_matches = filter_hsps(@blastx);	
	
	my %cont_lens;  # I need to get the length of each contig
	for my $i (0..$#contigs)
	{
		my $size = length $contigs[$i][2];
		$cont_lens{$contigs[$i][0]} = $size;
	}


	# Now I need to pull either end of the transposase end and blast them against themselves.
	my %opts2 = (# blastplus     => 1,
	              evalue => 0.00001);                          

	my @matches;
	for my $i (0..$#tpn_matches)
	{
		my $id = $blastx[$i][0];
		my $id2 = $blastx[$i][1];
		my $cont_end = $cont_lens{$id};
		my $qstart = $blastx[$i][6];
		my $qend   = $blastx[$i][7];
		my $begin_seg_start;
		my $begin_seg_end;
		my $end_seg_start;
		my $end_seg_end;
	
		if ($qstart < $qend)   # first process potential element if the transposase is in the forward direction
		{
			$begin_seg_start = ($qstart - $dist);
			if ($begin_seg_start <= 0)
			{
				$begin_seg_start = 1;
			}
			$begin_seg_end = ($qstart - 1);
	
			$end_seg_start = ($qend + 1);
			$end_seg_end   = ($qend + $dist);
			if ($end_seg_end > $cont_end)
			{
				$end_seg_end = $cont_end;
			}
			
			my @begin_seg = subseq ($id, $begin_seg_start, $begin_seg_end, @contigs);	
			my @end_seg   = subseq ($id, $end_seg_start, $end_seg_end, @contigs);		
	
			my @blastn = &BlastInterface::blastn( \@begin_seg, \@end_seg, \%opts2); 

			#next I check that the HSP subj and query are in opposite directions			
			# ( qid, sid, %id, alilen, mismatch, gaps, qstart, qend, sstart, send, eval, bit, qlen, slen)

			for my $j (0..$#blastn)
			{
				if (($blastn[$j][6] < $blastn[$j][7]) && ($blastn[$j][8] > $blastn[$j][9]) && 
				($blastn[$j][3] >= 20) && ($blastn[$j][3] <= 100) && ($blastn[$j][2] > 85))  
				{
					my $ele_start   = ($begin_seg_end - (($begin_seg_end - $begin_seg_start) - ($blastn[$j][6] - 1)));
					my $ele_end = $qend + $blastn[$j][8];
					my @full_ele = ($id, $ele_start, $ele_end, 'F');
					push @matches, \@full_ele;
					
					#print  STDERR "$id2\n";
				}
			}
		}		
		#-------------------------------------------------#	
			

		elsif ($qstart > $qend)       #next process potential element if the transposase is in the reverse direction
		{
			$begin_seg_start = ($qend - $dist);
			if ($begin_seg_start <= 0)
			{
				$begin_seg_start = 1;
			}
			$begin_seg_end = ($qend - 1);
	
			$end_seg_start = ($qstart + 1);
			$end_seg_end   = ($qstart + $dist);
			if ($end_seg_end > $cont_end)
			{
				$end_seg_end = $cont_end;
			}
			my @begin_seg = subseq ($id, $begin_seg_start, $begin_seg_end, @contigs);	
			my @end_seg   = subseq ($id, $end_seg_start, $end_seg_end, @contigs);		
	
			my @blastn = &BlastInterface::blastn( \@begin_seg, \@end_seg, \%opts2); 
				
			#next I check that the HSP subj and query are in opposite directions			
			# ( qid, sid, %id, alilen, mismatch, gaps, qstart, qend, sstart, send, eval, bit, qlen, slen)
			for my $j (0..$#blastn)
			{
				if (($blastn[$j][6] < $blastn[$j][7]) && ($blastn[$j][8] > $blastn[$j][9]) && 
				($blastn[$j][3] >= 20) && ($blastn[$j][3] <= 100) && ($blastn[$j][2] > 85))  
				{
					my $ele_start   = ($begin_seg_end - (($begin_seg_end - $begin_seg_start) - ($blastn[$j][6] - 1)));
					my $ele_end = $qstart + $blastn[$j][8];
					my @full_ele = ($id, $ele_start, $ele_end, 'R');
					push @matches, \@full_ele;
				}
			}
		}			   
	}			   
	
	# given a single start site, i choose for better or worse to report the longest element.	
	my %cont_id = map{$_->[0], 0}@matches;
	my @final_locs;
	for my $key ( sort {$a cmp $b} keys %cont_id) 
	{
		my @same_cont = grep{$_->[0] eq $key}@matches;	
		my @cont_sorted = sort { $b->[2] <=> $a->[2] } @same_cont;     	
		my $prev_start = 0;
		for my $i (0..$#cont_sorted)
		{
			unless ($cont_sorted[$i][1] == $prev_start)
			{
				my $final_id;
				if ($cont_sorted[$i][3] =~ /^R$/)
				{
					push @final_locs, [$cont_sorted[$i][0], $cont_sorted[$i][2], $cont_sorted[$i][1]];
				}
				else
				{
					push @final_locs, [$cont_sorted[$i][0], $cont_sorted[$i][1], $cont_sorted[$i][2]];
				}
				$prev_start = $cont_sorted[$i][1];
			}
		}
	}
	return @final_locs;
}




#----------------------------------------------------
# Sub filter_hsps
#  @non_overlapping_hsps = filter_hsps(@original_hsps)
#
#
# ( qid, sid, %id, alilen, mismatch, gaps, qstart, qend, sstart, send, eval, bit, qlen, slen)
#    0    1    2      3       4        5      6      7      8      9    10    11    12   13
#----------------------------------------------------
sub filter_hsps
{
	my @hsps = @_;
	my %qids = map{$_->[0], 0}@hsps;
	my @return;
	foreach my $key (keys %qids)
	{
		my @per_qid = grep{$_->[0] eq $key}@hsps;	
	
		my @mids;
		my @sorted = sort { $b->[11] <=> $a->[11] } @per_qid; #sort on bit score
		for my $i (0..$#sorted)
		{
			my $slen = $sorted[$i][13];
			my $qbeg = $sorted[$i][6];
			my $qend = $sorted[$i][7];
			my $mid;
			if ($qbeg < $qend)
			{
				$mid = ((($qend - $qbeg) * 0.5) + $qbeg);
			}
			elsif ($qbeg > $qend)
			{
				$mid = ((($qbeg - $qend) * 0.5) + $qend);
			}
			if (@mids == undef)
			{
				push @mids, $mid;
				#print "##", "mid = $mid\t", join "\t", @{$sorted[$i]}, "\n"; 
				push @return, [@{$sorted[$i]}];
			}
			
			else
			{			
				my @test = @mids;
				push @test, $mid;
				my @stest = sort { $a <=> $b} @test;
				my $good = 1;
				while (@stest)
				{
					my $first = shift @stest;
					my $second = shift @stest;
					if (($second - $first) < $slen)
					{
						$good = 0;
					}
				}
				if ($good)
				{
					push @mids, $mid;
					#print "##", "mid = $mid\t", join "\t", @{$sorted[$i]}, "\n"; 
					push @return, [@{$sorted[$i]}];
				}
			}			
		}
	}
	return @return;
}


#----------------------------------------------------
# full_length_IS_from_end_hsps
# @hsps should be in BlastInterface format.
# full_length_IS_from_end_hsps($min_len, $max_len, $element, $element_fn, \@contigs, \@hsps);
# \@hsps are the blastn hsps for potential end sequences.
# full_length_IS_from_end_hsps($element, \@contigs, \@hsps);
# returns an array that is [contig id, element start, element stop, element, element function]
#----------------------------------------------------	
sub full_length_IS_from_end_hsps
{
	my $element = shift @_;
	my $contr = shift @_;
	my @contigs = @$contr;
	my $matchr = shift @_;
	my @matches = @$matchr;

	my %IS_Data = %IS_Data::IS_Data;
	my $max_len          = $IS_Data{$element}{ele_max_len};
	my $min_len          = $IS_Data{$element}{ele_min_len};
	my $element_fn       = $IS_Data{$element}{ele_func};               
	my $tpn_seqr         = $IS_Data{$element}{tpn_seqs};
	my @tpn_seqs         = @$tpn_seqr; 


	my %contigs = map{$_->[0], 0}@matches;
	my @array;
	
	#sort and process the matches by contig and position
	my @array;

	for my $key ( sort {$a cmp $b} keys %contigs) 
	{
		my %best_len;
		my %best_pair;
		my @cmatch = grep{$_->[0] eq $key}@matches;	
		my @cmatchsort = sort { $a->[6] <=> $b->[6] } @cmatch;     	
	
		for my $i (0..$#cmatchsort)
		{
			if (scalar @cmatchsort > 1)  #make sure there is more than one set of ends to compare
			{
				while (@cmatchsort)
				{
					my @first = @{ shift @cmatchsort };
					for my $i (0..$#cmatchsort)
					{
						my @second = @{$cmatchsort[$i]};
					
						if (($first[9] == $first[3]) && ($second[8] == $second[3])) # check that ends are in opposite directions
						{	
							my $size = ($second[7] - $first[6]);
						
							# filter on provided cutoffs for min and max length
							if (($size >= $min_len) && ($size <= $max_len))
							{
								my @region =  subseq( $key, $first[6], $second[7], @contigs);           
							
								#print "evaluate\t", join "\t", @first, "\n";
								#print "evaluate\t", join "\t", @second, "\n\n";

							
								my %x_opts = (  blastplus   => 1,
												maxHSP      => 1,
												num_threads => 12,
												evalue      => $IS_Data{$element}{tpn_eval},
												minCovS     => $IS_Data{$element}{tpn_min_cov});
							
                                    # now we blast to see if there is representative transposase gene
                                    # Fileds of &BlastInterface:
									# (qid, sid, %id, alilen, mismatch, gaps, qstart, qend, sstart, send, eval, bit, qlen, slen)
                           
                                my @blastx = &BlastInterface::blastx( \@region, \@tpn_seqs, \%x_opts ); 
                                if (@blastx)
								{	
									#print "MATCH\t", join "\t", @first, "\n";
									#print "MATCH\t", join "\t", @second, "\n\n";
                                        
									if  (($best_len{$first[6]} == undef) || ($best_len{$first[6]} > $size))
									{
										$best_len{$first[6]} = $size;		
										my @coord = ($first[0], $first[6], $second[7], $blastx[0][6], $blastx[0][7]);  
										# $first[6] is the start, $first[7] the end, and the blastx options are coordinates of the element
										# i return the element in the direction of the transposase below. 
										$best_pair{$first[6]} = [@coord];																			
									}
								}
							}
						}
					}
				}
			}
		}
		for my $spos (keys %best_pair)
		{
			my @coord = @{$best_pair{$spos}};
			#return in transposase orientation:
			if ($coord[3] > $coord[4])
			{
				push @array, [$coord[0], $coord[2], $coord[1], $element, $element_fn]
			}
			else
			{
				push @array, [$coord[0], $coord[1], $coord[2], $element, $element_fn]
			}
		}
	}
	return @array;
}


#----------------------------------------------------
# sub subseq gets a subsequence from a gary-formatted tuple
# adds the location to the comment as "begin_end".
# my @subseq = subseq ($id, $begin, $end, @sequence);
#----------------------------------------------------
sub subseq
{
	my $cont_id =  shift  @_;
	my $begin = shift @_;
	my $end = shift @_;
	my @seq = @_;

	my @contig = grep{$_->[0] eq $cont_id}@seq;
	my $len = abs($end - $begin);
	my $start = $begin;
	
	my $subseq;
	if ($begin > $end)
	{
		$start = $end;
	}
   
	my $segmentf = substr $contig[0][2],($start - 1),($len + 1);
	my $subseq = $segmentf;
	
	if ($begin > $end)
	{
		my $segmentr = 	&gjoseqlib::complement_DNA_seq( $subseq );
		$subseq = $segmentr; 
	}
		
	my @new = [$cont_id, "$begin"."_"."$end", $subseq];
	
	return @new;
} 
