package AdaboostClassify;

# This is a SAS Component

use strict;
use gjoseqlib;
use AdaboostClassifierAMRv1;
use Getopt::Long;
use Data::Dumper;
use BlastInterface;
use File::Temp;


sub new
{
    my($class, $opts) = @_;

    my $self = {
	threads => 8,
    };
    if (ref($opts) eq 'HASH')
    {
	for my $k (qw(threads))
	{
	    $self->{$k} = $opts->{$k} if exists $opts->{$k};
	}
    }

    return bless $self, $class;
}

#
# Contigs is either a filename or a filehandle. If it is a filehandle
# the data is written to a temp file.
#

sub classify
{
    my($self, $sci_name, $contigs) = @_;

    my %blast_opts = (minIden       => 1,
		      minCovQ       => 1,
		      lcFilter      => "F",
		      num_threads   => $self->{threads},
		      );

    my $contig_file;
    
    if (ref($contigs) eq 'GLOB')
    {
	$contig_file = File::Temp->new(UNLINK => 1);
	print $contig_file while <$contigs>;
	close($contig_file);
    }
    elsif (ref($contigs))
    {
	die "Cannot handle contigs $contigs\n";
    }
    else
    {
	$contig_file = $contigs;
    }

    #Get the Classifier Hash
    my $adaH = \%AdaboostClassifierAMRv1::AdaboostValues;

    my $all_classifiers = $adaH->{$sci_name};

    my @result;

    foreach my $classifier (sort keys %$all_classifiers)
    {
	my $features = [];
	
	my $adaboost_score;
	my $function = $adaH->{$sci_name}->{$classifier}->{'FUNCTION'};
	my $BoostH = $adaH->{$sci_name}->{$classifier}->{'ADABOOST'};
	
	foreach my $round (sort {$a <=> $b} keys %$BoostH)
	{
	    my $alpha = $adaH->{$sci_name}->{$classifier}->{'ADABOOST'}->{$round}->{ALPHA};
	    my $kmerA = $adaH->{$sci_name}->{$classifier}->{'ADABOOST'}->{$round}->{KMERS};

	    #print STDERR  "##$round\t$alpha\n";
	    my @for_blast;
	    my $count = 0;
	    my @seqA;
	    # blast a set of k-mers from a round of boosting against the contigs
	    my $ksize = length @$kmerA[0];
	    foreach (@$kmerA)
	    {
		$seqA[$count][0] = $count;
		$seqA[$count][1] = $round;
		$seqA[$count][2] = $_;
		$count ++;
	    }
	    my @hsps    = &BlastInterface::blastn( \@seqA, "$contig_file", \%blast_opts );
	    #print STDERR "#$classifier\t$round\n";
	    # print Dumper \@hsps;
	    if (@hsps) {
		$adaboost_score += $alpha;
	    } else {
		$adaboost_score -= $alpha;
	    }
	    # Put the k-mers in the right order so that we can build the contiguous feature
	    # Contig=>$start=>$end;
	    # k-mers that are on the opposite strand are reversed.
	    my %cont_starts;
	    for my $i (0..$#hsps)
	    {
		if ($hsps[$i][8] <= $hsps[$i][9])
		{
		    $cont_starts{$hsps[$i][1]}{$hsps[$i][8]} = $hsps[$i][9];
		}
		elsif ($hsps[$i][9] < $hsps[$i][8])
		{
		    $cont_starts{$hsps[$i][1]}{$hsps[$i][9]} = $hsps[$i][8];
		
		}
	    }
	    
	    foreach my $contig (keys %cont_starts)
	    {
		my $locsR = $cont_starts{$contig};
		my %locs = %$locsR;
		my @starts = sort {$a <=> $b} keys %locs;

		if (@starts == 1)
		{
		    #print "SINGLETON\n";
		    push(@$features, [$contig, $starts[0], $locs{$starts[0]}, $alpha, $round, $classifier, $function]);
		}
		elsif (@starts > 1)
		{
		    #my $nkmers = scalar @starts;
		    #print "NKMERS = $nkmers\n";
		    my $previous = $starts[0];
		    for my $i (1..$#starts)
		    {					
			if ($starts[$i] > $locs{$starts[$i - 1]})
			{
			    #print FEAT "BREAK: $previous\t$starts[$i-1]\n";
			    push(@$features, [$contig, $previous, $locs{$starts[$i-1]}, $alpha, $round, $classifier, $function]);
			    $previous = $starts[$i];
			}
		    }
		    push(@$features, [$contig, $previous, $locs{$starts[-1]}, $alpha, $round, $classifier, $function]);
		}
	    }
	}

	#get the output right:
	# print CLASS "Classifier: $classifier\n";
	# print CLASS "AdaBoost Score: $adaboost_score\n";
	my $antibiotic = $adaH->{$sci_name}->{$classifier}->{'ANTIBIOTICS'};
	$antibiotic =~ s/ /\, /g;
	my $what;
	if ($adaboost_score >= 0)
	{
	    $what = 'resistant';
		# print CLASS "This genome is predicted to be resistant to: $antibiotic\n";
	} else {
	    $what = 'sensitive';
		print CLASS "This genome is predicted to be sensitive to: $antibiotic\n";
	}
	#print CLASS "Classifier Information:\n";
	
	my $comment = $adaH->{$sci_name}->{$classifier}->{'COMMENTS'};
	# if ($comment){print CLASS "Comments: $comment\n";}
	# print CLASS "Classifier accuracy: $adaH->{$sci_name}->{$classifier}->{'ACCURACY'}\n";
	# print CLASS "Area under the ROC curve: $adaH->{$sci_name}->{$classifier}->{'AUC'}\n";
	# print CLASS "F1 Score: $adaH->{$sci_name}->{$classifier}->{'F1'}\n";
	my $source = $adaH->{$sci_name}->{$classifier}->{'SOURCES'};
	# 	if ($source){print CLASS "Data sources: $source\n";}
	# print CLASS "\n";

	push(@result, {
	    classifier => $classifier,
	    adaboost_score => $adaboost_score,
	    antibiotic => $antibiotic,
	    sensitivity => $what,
	    ($comment ? (comment => $comment) : ()),
	    accuracy => $adaH->{$sci_name}->{$classifier}->{'ACCURACY'},
	    area_under_roc_curve => $adaH->{$sci_name}->{$classifier}->{'AUC'},
	    f1_score => $adaH->{$sci_name}->{$classifier}->{'F1'},
	    ($source ? (sources => $source) : ()),
	    features => $features,
	});
    }
    return \@result;

}
		
















##----------------------------------------------------
## ( qid, sid, %id, alilen, mismatch, gaps, qstart, qend, sstart, send, eval, bit, qlen, slen)
##    0    1    2      3       4        5      6      7      8      9    10    11    12   13
##----------------------------------------------------

1;
