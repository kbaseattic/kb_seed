#
# This is a SAS Component
#

=head1 get_families_3

Take "called" families and split off "good" from "bad" based on fraction of genomes with a single PEG

------

Example:

    get_families_3 -c 0.9 < called > good 2> bad

This program takes as input the families produced as "calls" by get_families_1.
For each family, a check is made to see if more than a single PEG is included from each genome
represented in the set.  If more than the cutoff fraction are singletions, the set is "good"
and is written to STDOUT.  Otherwise it is "bad" and written to STDERR.  Note that a "good"
set must exceed the threshhold, which means that a cutoff of 1 send all sets to "bad"
(and, hence, an attempt will be made to cluster on common kmers.

------


=head2 Command-Line Options

=over 4

=item -c cutoff used to differntiate between "good" and "bad" "called families"

if a fraction more than "cutoff" genomes in a family have just one PEG,
the family is "good"; else it is "bad", and an attempt will be made to split it.


=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;

my $cutoff = 0.9;
my $rc  = GetOptions('c=f' => \$cutoff);

my %in;
while (defined($_ = <STDIN>))
{
    chomp;
    my($peg,$func) = split(/\t/,$_);
    my $g = &SeedUtils::genome_of($peg);
    push(@{$in{$func}->{$g}},$peg);
}

foreach my $func (keys(%in))
{
    my $gH = $in{$func};
    my $good = 0;
    my $bad = 0;
    my @set;
    my @bad;
    my @all_pegs;
    foreach my $g (keys(%$gH))
    {
	my $pegs = $gH->{$g}; 
	my $n = @$pegs;
	if ($n == 1)
	{
	    $good++;
	}
	else
	{
	    $bad++;
	}
	push(@all_pegs,@$pegs);
    }
    if ($good > ($cutoff * ($good + $bad)))  # if cutoff is 1.0, this forces kmer splitting
    {
	foreach my $peg (@all_pegs)
	{
	    print join("\t",($func,1,$peg)),"\n";
	}
#	print join("\t",@all_pegs);
#	foreach my $g (keys(%$gH))
#	{
#	    my $pegs = $gH->{$g}; 
#	    my $n = @$pegs;
#	    if ($n > 1)
#	    {
#		print ":",join(",",@$pegs);
#	    }
#	}
#	print "\n";
    }
    else
    {
	print STDERR join("\t",$func,@all_pegs),"\n";
    }
}
