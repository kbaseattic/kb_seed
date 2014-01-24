use strict;
use Data::Dumper;

use Getopt::Long;
my $no_scores = 0;

my $usage = "usage: km_pick_best_hit_in_peg [-n]\n";

my $rc  = GetOptions('n'   => \$no_scores);
if (! $rc)
{ 
    print STDERR $usage; exit ;
}

use SeedUtils;
while (defined($_ = <STDIN>) && ($_ ne "---------------------\n")) { }
my $last = <STDIN>;
while ($last && ($last =~ /^(\S+)/))
{
    my $peg = $1;
    my %funcsW;
    my %funcs;
    my $z_sc = -100;
    while (($last =~ /^(\S+)\t\S+\t\S+\t\S+\t\S+\t(\d+)\t(\S[^\t]*\S)\t(\S+)\t\S+(\t(\S+))?/) && ($peg eq $1))
    {
	$funcsW{$3} += $4;
	$funcs{$3} += $2;
	$z_sc       = ($6 > $z_sc) ? $6 : $z_sc;
	$last = <STDIN>;
    }
    my @funcs = sort { $funcsW{$b} <=> $funcsW{$a} } keys(%funcs);
    if (! $no_scores)
    {
	print "$peg\t$funcs[0]\t$funcs{$funcs[0]}\t$funcsW{$funcs[0]}\t$z_sc\n";
    }
    else
    {
	print "$peg\t$funcs[0]\n";
    }
}
