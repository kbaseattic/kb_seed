########################################################################
use strict;
use Data::Dumper;
use SeedUtils;
use Getopt::Long;

my $usage = "usage: build_just_otu_index -d DataDir\n";
my $dataD;
my $rc  = GetOptions('d=s' => \$dataD);

if ((! $rc) || (! $dataD))
{ 
    print STDERR $usage; exit ;
}
if (! -s "$dataD/genomes")
{
    die "you need to give an genomes in $dataD\n$usage";
}

my %counts;
foreach $_ (`cat $dataD/genomes`)
{
    chomp;
    my($name,$genome) = split(/\t/,$_);
    if ($name =~ /^(\S+)\s(\S+)/)
    {
	my $genus = $1;
	my $species = $2;
	if ($species !~ /^sp\.?$/i)
	{
	    if ($genus !~ /^(other|unclassified)/)
	    {
		$counts{"$genus $species"}++;
	    }
	}
    }
}

open(WTS,">$dataD/otu.occurrences") || "could not open $dataD/otu.occurrences";
my $nxt = 0;
foreach my $gs (sort keys(%counts))
{
    print WTS join("\t",($nxt,$counts{$gs},$gs)),"\n";
    $nxt++;
}
close(WTS);

system "cut -f1,3 $dataD/otu.occurrences > $dataD/otu.index";
