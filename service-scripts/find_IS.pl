#! /usr/bin/env perl 

# This is a SAS Component

use strict;
use IS_Data;
use gjoseqlib;
use BlastInterface;
use IS_Subroutines;
use Data::Dumper;
use Getopt::Long;

my %IS_Data = %IS_Data::IS_Data;

my $usage = 'find_IS.pl [opts] <contigs in fasta format  > list of IS elements
           Options:
              -d	dump reference end sequences and die
              -e	print end regions (only reports the ends from the reference-based search)
              -f	print output as fasta (default is RAST-tk add-features formatted table)
              -h	help
              -n	do not report full length elements
              -r    report available insertion sequence types from reference-based search and die
              -s    search for only one IS type from the -r list
              -t    dump reference trasposase sequences and die
              -w    window size for denovo IS element search. Default is 10,000bp 
                    from either end of a transposase gene.
              -x    perform reference-based search only
              -y    perform denovo search only
                    
              This program performs two types of searches to find finds IS elements.
              The reference-based search uses sequences from the SEED and ISfinder and works by first finding matches 
              to a set of curated end regions, and then confirming the presence of an IS element by searching for 
              a transposase or integrase gene between a pair of inverted ends.  The denovo search works by first 
              findng a transposase gene and then searching for inverted repeat regions upstream and downstream from 
              the ends of the transposase gene.
              ';

my ($dump_ends, $fasta, $print_ends, $no_full_length, $help, $report, $single_is, $dump_tpns, $window, $ref_only, $denovo_only);
my $opts = GetOptions('d'   => \$dump_ends,  
					  'e'   => \$print_ends,
                      'f'   => \$fasta,
                      'h'   => \$help,
                      'n'   => \$no_full_length,
                      'r'   => \$report,
                      's=s' => \$single_is,
                      't'   => \$dump_tpns,
                      'w=i' => \$window,
                      'x'   => \$ref_only,
                      'y'   => \$denovo_only);
                      

if ($help){die "$usage\n"}
unless ($window){$window = 10000;}

if ($report)  # dump the IS types and die
{
	foreach (sort keys %IS_Data)
	{
		print "$_\n";
	}
	die;
}


if ($dump_tpns)  #dump the representative transposase sequences and die
{
	if ($single_is)
	{
		my $tpn_seqr    = $IS_Data{$single_is}{tpn_seqs};
		gjoseqlib::print_alignment_as_fasta(@$tpn_seqr);
		die;
	}
	elsif ($single_is == undef)
	{
		foreach my $IS_Element (sort keys %IS_Data)
		{	
			my $tpn_seqr    = $IS_Data{$IS_Element}{tpn_seqs};
			gjoseqlib::print_alignment_as_fasta(@$tpn_seqr);
		}
		die;
	}
}


if ($dump_ends) #dump the representative end sequences and die
{
	if ($single_is)
	{
		my $end_seqr    = $IS_Data{$single_is}{end_seqs};
		gjoseqlib::print_alignment_as_fasta(@$end_seqr);
		die;
	}
	elsif ($single_is == undef)
	{
		foreach my $IS_Element (sort keys %IS_Data)
		{	
			my $end_seqr    = $IS_Data{$IS_Element}{end_seqs};
			gjoseqlib::print_alignment_as_fasta(@$end_seqr);
		}
		die;
	}
}
		
my @contigs = gjoseqlib::read_fasta();

#  Description of data in %IS_Data:
#  $IS_Data{"IS Element Name"} = 
#            qw ( 
#                 end_eval        => $eval          max eval for the blastn of the ends
#                 end_min_cov     => $frac          minimum fraction of coverage for the ends
#                 end_min_id      => $frac          minimum fraction id for the ends
#                 end_feat        => $feature       feature id for the ends e.g., 'Tn3_end'
#                 end_func        => $func          function for the ends e.g., 'Tn3 end sequence'
#                 tpn_eval        => $eval          max eval for the transposase blastx
#                 tpn_min_cov     => $frac          minimum coverage for the transposase blast 
#                 ele_feat        => $feature       feature id for the whole element e.g., 'IS_Tn3'
#                 ele_func        => $func          function of the whole element e.g., 'Tn3 family insertion sequence'
#                 ele_max_len     => $len           longest allowable element (I have been using 1 stdev greater than the longest observed)
#                 ele_min_len     => $len           shortest allowable element (currently half the size of the smallest example) --these are guesses
#                 end_seqs        => @seqs          ends, gjo tuple  
#                 tpn_seqs        => @seqs          transposases, gjo tuple
#               );

unless ( %IS_Data ){die "IS_Data is empty\n"}

if ($single_is)      # reduce %IS_Data to a single IS element if it is specified by -s
{
	my $hashr = $IS_Data{$single_is};
	my %hash = %$hashr;
	%IS_Data = ();
	$IS_Data{$single_is} = \%hash;
}

my @all_ref_elements;

unless ($denovo_only)
{
	foreach my $IS_Element (sort keys %IS_Data)
	{
		# Fileds returned from &BlastInterface:
		# ( qid, sid, %id, alilen, mismatch, gaps, qstart, qend, sstart, send, eval, bit, qlen, slen)
	
		my $end_seqr     = $IS_Data{$IS_Element}{end_seqs};
		my @end_seqs     = @$end_seqr; 
		my $end          = $IS_Data{$IS_Element}{end_feat};
		my $end_fn       = $IS_Data{$IS_Element}{end_func};        
		my $element      = $IS_Data{$IS_Element}{ele_feat};


		my %opts = ( #blastplus     => 1,
					 #evalue        => $IS_Data{$IS_Element}{end_eval},
					 #minIden       => $IS_Data{$IS_Element}{end_min_id},
					 #minCovS       => $IS_Data{$IS_Element}{end_min_cov},
					 num_threads   => 12,
					);                          

		my @end_hsps    = &BlastInterface::blastn( \@contigs, \@end_seqs, \%opts );
		my @end_matches = &IS_Subroutines::filter_hsps(@end_hsps);	
		my @ends        = &IS_Subroutines::add_features_formatted_matches($end, $end_fn, @end_matches);

		if ($print_ends)   #print end regions if -e is specified
		{
			for my $i (0..$#ends)
			{
				if ($fasta)
				{
					my @entry = @{$ends[$i]};
					my @coord = split ("\_", $entry[1]);
					my $end = pop @coord;
					my $begin = pop @coord;
					my $contig = join ("\_", @coord);
					my @end_fasta = &IS_Subroutines::subseq ($contig, $begin, $end, @contigs);
					&gjoseqlib::print_alignment_as_fasta(@end_fasta);
				}
				else
				{
					print join "\t", @{$ends[$i]}, "\n";
				}
			}
		}
	
		if ($no_full_length) {die "No full-length elements reported.\n";}; # if -l die with out reporting elements

		my @elements =  &IS_Subroutines::full_length_IS_from_end_hsps($IS_Element, \@contigs, \@end_matches);
		push @all_ref_elements, @elements;
	}	 
}


#@all_ref_elements = (id, start, stop, element, element_function)
# do the denovo search:
my @denovo_elements;

unless ($ref_only)
{
	@denovo_elements = &IS_Subroutines::denovo_is_search($window, \@contigs);
	#@denovo_elemnts = ( id, begin, end)
}


#Resolve reference-based and denovo IS elements

my %cont_ids = map{$_->[0], 0}(@contigs);

my $count = 0;
foreach my $key (sort(keys %cont_ids)) 
{
	my @ref_based    = grep{$_->[0] eq $key}@all_ref_elements;	
	my @denovo_based = grep{$_->[0] eq $key}@denovo_elements;	

	my %by_starts;  # i will make a hash of start => @coordinates for denovo;
					# any identified element that matches a start position will replace
					# the one that was found denovo
	for my $i (0..$#ref_based)
	{
		$by_starts{$ref_based[$i][1]} = @ref_based[$i];
	}

	for my $i (0..$#denovo_based)
	{
		my $good = 1;
		my $dstart = $denovo_based[$i][1];
		for my $j (0..$#ref_based)
		{
			my $rstart = $ref_based[$j][1];
			my $dif = abs($dstart - $rstart);
			if ($dif < 50)  #  get rid of denovo calls that overlap ref-based calls.
			{
				$good = 0;
			}
		}
		if ($good)
		{	
			$by_starts{$dstart} = @denovo_based[$i];
		}
	}

	for my $start ( sort {$a<=>$b} keys %by_starts) 
	{
		my $arrayr = $by_starts{$start};
		my @array    = @$arrayr; 		
		my $gid = $array[0];
		$gid =~ s/\:.+//g;
		my $id = "fig\|"."$gid"."."."IS".".".($count + 1);					

		my $loc = "$array[0]"."_"."$array[1]"."_"."$array[2]";

		if ((scalar @array) < 4)
		{
			if  ($fasta == undef)
			{
				print "$id\t$loc\tIS_Unknown\tPutative insertion sequence\n";
			}
			else
			{
				my @subseq = &IS_Subroutines::subseq($array[0], $array[1], $array[2], @contigs);				
				my @final_seq = [$id, "Putative insertion sequence \[$loc\]", $subseq[0][2]];
				&gjoseqlib::print_alignment_as_fasta(@final_seq);
			}
		}
		else
		{
			if($fasta == undef)
			{
				print "$id\t$loc\t$array[3]\t$array[4]\n";
			}
			else
			{
				my @subseq = &IS_Subroutines::subseq ($array[0], $array[1], $array[2], @contigs);
				my @final_seq = [$id, "$array[4] \[$loc\]", $subseq[0][2]];
				&gjoseqlib::print_alignment_as_fasta(@final_seq);
			}
		}
	$count ++;
	}
}	
