use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use gjoseqlib;
use SeedAware;
use SeedEnv;

my $repeats;
my $usage = "usage: CSA_collapse_repeats Repeats > collapsed.repeats";
(
 ($repeats = shift @ARGV)
)
    || die $usage;

open(REPEATS,"grep '+' $repeats | sort -T . -k 2 -n -k 4 |")
    || die "could not open $repeats";

my $last = <REPEATS>;
while ($last && ($last =~ /^(\S+)\t(\S+)\t\S\t(\d+)/))
{
    my $contig = $2;
    my $pos    = $3;
    my $beg = $pos;
    my $end = $pos + length($1) - 1;
    while (($last = <REPEATS>) && 
	   ($last =~ /^\S+\t(\S+)\t\S\t(\d+)/) && 
	   ($1 eq $contig) &&
	   ($2 == ($pos+1)))
    {
	$pos++;
	$end++;
    }
    print join("\t",($contig,$beg,$end)),"\n";
}

