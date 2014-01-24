########################################################################
use strict;
use Data::Dumper;
use SeedUtils;
use Getopt::Long;

my $usage = "usage: km_build_kmers_part1 -d DataDir -k 8\n";
my $dataD;
my $k;
my $rc  = GetOptions('d=s' => \$dataD,
		     'k=i' => \$k);

if ((! $rc) || (! -d $dataD) || (! $k))
{ 
    print STDERR $usage; exit ;
}
print STDERR "Building kmers of size $k\n";

&build_reduced_kmers($dataD);

sub build_reduced_kmers {
    my($dataD) = @_;

    my %to_oI;
    my %otu_wts;
    foreach $_ (`cat $dataD/otu.occurrences`)
    {
	if ($_ =~ /^(\S+)\t(\S+)\t(\S.*\S)/)
	{
	    $to_oI{$3} = $1;
	    $otu_wts{$1} = $2;
	}
    }

    my %g_to_oI;

    foreach $_ (`cat $dataD/genomes`)
    {
	if ($_ =~ /^(\S[^\t]*\S)\t(\S+)/)
	{
	    my $g = $2;
	    my $gs = $1;
	    if (($gs =~ /^(\S+ \S+)/) && defined($to_oI{$1}))
	    {
		$g_to_oI{$g} = $to_oI{$1};
	    }
	}
    }
    my %to_fI;
    foreach $_ (`cat $dataD/function.index`)
    {
	if ($_ =~ /^(\S+)\t(\S.*\S)/)
	{
	    $to_fI{$2} = $1;
	}
    }
#
#   we take assignments from both the pubSEED and the ASEED.  ASEED functions
#   override PSEED functions
#
    my %peg_to_fI;
    &load_peg_to_fI($dataD,\%to_fI,'PUBSEED',\%peg_to_fI);
#     &load_peg_to_fI($dataD,\%to_fI,'SEED',\%peg_to_fI);

#    open(RAW,"| sort -T /scratch -S 1G  > $dataD/sorted.kmers") || die "could not open $dataD/sorted.kmers";
    open(RAW,"| sort -T . -S 1G  > $dataD/sorted.kmers") || die "could not open $dataD/sorted.kmers";
    foreach my $g (map { chomp; $_ } `cut -f2 $dataD/genomes`)
    {
	next if ((! $g_to_oI{$g}) || (! $otu_wts{$g_to_oI{$g}}));
	foreach $_ (`echo '$g' | svr_all_features peg | svr_translations_of`)
	{
	    if ($_ =~ /^(fig\|\d+\.\d+\.peg\.\d+)\t(\S.*\S)$/)
	    {
		chomp;
		my $seq = $2;
		my $id = $1;
		($id =~ /^fig\|(\d+\.\d+)/) || die "bad peg $_";
		my $g = $1;
		my $oI = $g_to_oI{$g};
		my $fI = $peg_to_fI{$id};
		for (my $i=0; ($i < (length($seq) - $k)); $i++)
		{
		    my $kmer = uc substr($seq,$i,$k);
		    if ($kmer !~ /[^ACDEFGHIKLMNPQRSTVWY]/)
		    {
			print RAW join("\t",($kmer,$fI,$oI,length($seq)-$i),$otu_wts{$oI}),"\n";
		    }
		}
	    }
	}
    }
    close(RAW);

    open(RAW,"<$dataD/sorted.kmers") || die "could not open sorted.kmers";
    open(REDUCED,">$dataD/reduced.kmers") || die "could not open reduced kmers";
    my $last = <RAW>;
    while ($last && ($last =~ /^(\S+)/))
    {
	my $curr = $1;
	my @set;
	while ($last && ($last =~ /^(\S+)\t(\S*)\t(\S*)\t(\S*)\t(\S+)$/) && ($1 eq $curr))
	{
	    push(@set,[$2,$3,$4,$5]);
	    $last = <RAW>;
	}
	&process_set($curr,\@set,\*REDUCED);
    }
    close(REDUCED);
}

sub load_peg_to_fI {
    my($dataD,$to_fI,$which_seed,$peg_to_fI) = @_;
    my $existing = $ENV{'SAS_SERVER'};
    $ENV{'SAS_SERVER'} = $which_seed;

    my @genomes = `cut -f2 $dataD/genomes`;
    foreach my $genome (@genomes)
    {
	foreach $_ (`echo '$genome' | svr_all_features peg | svr_function_of`)
	{
	    if ($_ =~ /^(\S+)\t(\S.*\S)/)
	    {
		my $peg = $1;
		my $func = &SeedUtils::strip_func($2);
		if ($to_fI->{$func})
		{
		    $peg_to_fI->{$peg} = $to_fI->{$func};
		}
	    }
	}
    }
    $ENV{'SAS_SERVER'} = $existing;
}


sub process_set {
    my($kmer,$set,$fh) = @_;

    my %funcs;
    my $tot = 0;
    foreach my $tuple (@$set)
    {
	my($fI,$oI,$off,$otu_count) = @$tuple;
	my $incr = (1/$otu_count);
	$tot += $incr;
	$funcs{$fI} += $incr;
    }
    my @tmp = sort { $funcs{$b} <=> $funcs{$a} } keys(%funcs);
    if (defined($tmp[0]) && ($funcs{$tmp[0]} > (0.5 * $tot)))
    {
	my $best_fI = $tmp[0];
	my $func_wt = sprintf("%0.3f",$funcs{$tmp[0]} / $tot);
	my %otus;
	my $otu = '';
	foreach my $tuple (@$set)
	{
	    my($fI,$oI,$off,$otu_count) = @$tuple;
	    if (($fI == $best_fI) && $oI)
	    {
		$otus{$oI} += (1/$otu_count);
	    }
	}
	@tmp = sort { $otus{$b} <=> $otus{$a} } keys(%otus);
	if (defined($tmp[0]) && ($_ = &pickable_otu(\@tmp,\%otus,$tot)))
	{
	    $otu = $_;
	}
	my $otu_wt = ($otu && $otus{$otu}) ? sprintf("%0.4f",$otus{$otu}/$tot) : 0;

	my @offsets = sort { $a <=> $b } map { $_->[2] } @$set;
	my $median_off = $offsets[int(scalar @offsets / 2)];
	print $fh join("\t",($kmer,$median_off,$best_fI,$func_wt,$otu_wt,$otu)),"\n";
    }
}

sub pickable_otu {
    my($poss_otus,$weighted_counts,$weighted_in_set) = @_;

    my @called;
    if (@$poss_otus == 1) { return $poss_otus->[0] }
    my $best;
    while (($best = shift @$poss_otus) && ($weighted_counts->{$best} >= (0.4 * $weighted_in_set)))
    {
	push(@called,$best);
    }
    if (@called > 0)
    {
	my $composite_wt = 0;
	foreach my $otu (@called)
	{
	    $composite_wt += $weighted_counts->{$otu};
	}
	my $new_otu = join(",",sort { $a <=> $b } @called);
	$weighted_counts->{$new_otu} = $composite_wt;
	return $new_otu;
    }
    return '';
}
