########################################################################
use strict;
use Data::Dumper;
use Getopt::Long;
use SeedUtils;
use gjoseqlib;

my $usage = "usage: km_process_hits_to_regions -d DataDir < Hits \n";
my $dataD;
my $aa = 0;
my $z = 0;
my $rc  = GetOptions('d=s' => \$dataD,
   	  	     'z'   => \$z,
                     'a'   => \$aa);

if ((! $rc) || (! $dataD))
{ 
    print STDERR $usage; exit ;
}

if ($z && (! -s "$dataD/function.stats"))
{
    die "you need to run \n\tcompute_stats_for_kmer_hits -d $dataD\nfirst";
}

# a hit looks like [$contig,$beg1,$end1,$strand,$frame,$hitsN,$f]
#
# hits get sorted by [contig,beg1,end1]
#

my $otu_index = &load_otu_index("$dataD/otu.index");

my($hits,$otuH) = &load_hits($otu_index,$aa);
my @merged;

# This first grouping just groups adjacent hits with the same function

&print_otus($otuH);
print "---------------------\n";

my %fparms;
if ($z)
{
    %fparms = map { ($_ =~ /^(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)/) ? ($1 => [$4,$5]) : () } `cat $dataD/function.stats`;
}

&process_merged($dataD,$hits,$aa,$z,\%fparms);

sub print_otus {
    my($otuH) = @_;

    foreach my $c (sort keys(%$otuH))
    {
	print "$c\n";
	my $counts = $otuH->{$c};
	foreach my $tuple (@$counts)
	{
	    my($n,$val) = @$tuple;
	    print "\t$n\t$val\n";
	}
	print "\n";
    }
}

sub frame {
    my($x) = @_;
    return $x->[4];
}

sub id {
    my($x) = @_;
    return $x->[0];
}

sub strand {
    my($x) = @_;
    return $x->[3];
}

sub hits {
    my($x) = @_;
    return $x->[5];
}

sub function {
    my($x) = @_;
    return $x->[6];
}

# tuples contain [contig,beg,end,hits,function,frame]
sub process_merged {
    my($dataD,$merged,$aa,$z,$fparms) = @_;

    my @merged;
    if ($aa) {
	@merged = sort { &SeedUtils::by_fig_id($a->[0],$b->[0]) or ($a->[1] <=> $b->[1]) or ($a->[2] <=> $b->[2]) } @$merged;
    }
    else
    {
	@merged = sort { ($a->[0] cmp $b->[0]) or ($a->[1] <=> $b->[1]) or ($a->[2] <=> $b->[2]) } @$merged;
    }
    my @collapsed;
    my $i=0;
    while ($i < @merged)
    {
	push(@collapsed,$merged[$i++]);
	while (($i < @merged) && 
	       (&id($merged[$i]) eq &strand($collapsed[-1])) &&
	       (&strand($merged[$i]) eq &strand($collapsed[-1]))  &&
	       (&function($merged[$i]) eq &function($collapsed[-1])))
	{
	    $collapsed[-1]->[2] = $merged[$i]->[2];
	    $i++;
	}
    }

    $i = 0;
    undef @merged;
    while ($i < @collapsed)
    {
	push(@merged,$collapsed[$i++]);
	while (($i < (@collapsed-2)) && 
	       (&strand($collapsed[$i+1]) eq &strand($merged[-1]))  &&
	       (&function($collapsed[$i+1]) eq &function($merged[-1])) &&
	       (&hits($collapsed[$i]) < 5) &&
	       ((&hits($merged[-1]) + &hits($collapsed[$i+1])) >= 10))
	{
	    $merged[-1]->[2]  = $collapsed[$i+1]->[2];
	    $merged[-1]->[3] += $collapsed[$i+1]->[3];
	    $i += 2;
	}
    }

    foreach my $tuple (@merged)
    {
	my($contig,$beg,$end,$strand,$frame,$hits,$f,$fI,$weighted_sc) = @$tuple;
	if ($aa)
	{
	    print join("\t",($contig,$beg,$end,$strand,'.',$hits,$f,$weighted_sc,$fI));
	}
	else
	{
	    print join("\t",($contig,$beg,$end,$strand,$frame,$hits,$f,$weighted_sc,$fI));
	}

	if ($z)
	{
	    my $tuple = $fparms->{$fI};
	    if ($tuple)
	    {
		my($mean,$stddev) = @$tuple;
		if ($stddev > 0.0001)
		{
		    my $v = $hits / ((abs($beg-$end)+1)/3);
		    my $zsc = ($v - $mean) / $stddev;
		    print "\t",sprintf("%0.3f",$zsc);
		}
	    }
	}
	print "\n";
    }
}

sub load_otu_index {
    my($file) = @_;

    my $otu_index = {};
    foreach $_ (`cat $file`)
    {
	chomp;
	my($n,$v) = split(/\t/,$_);
	my @sub   = split(/,/,$v);
	if (@sub == 1)
	{
	    $otu_index->{$n} = $v;
	}
	else
	{
	    $otu_index->{$n} = join("|",map { $otu_index->{$_} } @sub);
	}
    }
    return $otu_index;
}

sub load_hits {
    my($otu_index,$aa) = @_;

    my $otuH = {};
    my @hits;
    my $contig;
    my $strand = "+";
    my $frame  = 0;
    my $contig_ln;
    while (defined($_ = <STDIN>))
    {
	if ($_ =~ /^TRANSLATION\s+(\S+)\t(\d+)\t(\S)\t(\S+)/)
	{
	    $contig = $1;
	    $contig_ln = $2;
	    $strand = $3;
	    $frame = $4;
	}
	elsif ($_ =~ /^PROTEIN-ID\t(\S+)/)
	{
	    $contig = $1;
	}
	elsif ($_ =~ /^CALL\t(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\S[^\t]*\S)\t(\S+)/)
	{
	    my($beg0,$end0,$hitsN,$fI,$f,$weighted_sc) = ($1,$2,$3,$4,$5,$6);
	    $f =~ s/\s+\#.*$//;
	    my $beg1 = &to_coord($beg0,$frame,$strand,$contig_ln);
	    my $end1 = &to_coord($end0,$frame,$strand,$contig_ln);
	    push(@hits,[$contig,
			&SeedUtils::min($beg1,$end1),
			&SeedUtils::max($beg1,$end1),
			$strand,
			$frame,
			$hitsN,
			$f,
			$fI,
			$weighted_sc]);
	}
	elsif ($_ =~ /^OTU-COUNTS\t(\S+)\[\d+\]\t(\S.*\S)/)
	{
	    my $c = $1;
	    my @poss = map { ($_ =~ /^(\d+)-(\d+)/) ? [$1,$2] : () } split(/\t/,$2);
	    foreach my $tuple (@poss)
	    {
		my($n,$otu) = @$tuple;
		my $trans_otu = $otu_index->{$otu};
		push(@{$otuH->{$c}},[$n,$trans_otu]);
	    }
	}
    }
    my @sorted;
    if ($aa)
    {
	@sorted = sort { &SeedUtils::by_fig_id($a->[0],$b->[0]) or ($a->[1] <=> $b->[1]) or ($a->[2] <=> $b->[2])  } @hits;
    }
    else
    {
	@sorted = sort { ($a->[0] cmp $b->[0]) or ($a->[1] <=> $b->[1]) or ($a->[2] <=> $b->[2]) } @hits;
    }
    return(\@sorted,$otuH);
}

sub to_coord {
    my($x,$frame,$strand,$contig_ln) = @_;

    if ($strand eq "+")
    {
	return ($x * 3) + $frame + 1;
    }
    else
    {
	return ($contig_ln - (($x * 3) - $frame));
    }
}

