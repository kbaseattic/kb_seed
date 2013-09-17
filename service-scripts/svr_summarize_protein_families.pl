#
# This is a SAS Component
#

=head1 svr_summarize_protein_families Report-on-Sets Report-on-Genomes Report-on-Intersections

Write out three simple reports relating to a proposed set of protein families.

=head2 Introduction

If you are constructing a set of protein families for a set of genomes (say, a set of
genomes that are the input of an attempt to form a "pangenome"), it is useful to get 
some summaries on how well the genes were separated into families.  This little program writes
three reports:  Report-on-Sets summarizes the number of sets of different sizes, Report-on-Genome
is a report that allows you to see the distribution of set sizes containing genes from each genome,
and Report-on-Intersections shows the number of sets in common between all pairs of genomes.


=head2 Output

The outpt files have the following formats:

    Set-Report is a two-column table containing ['Set','Size-of-Set']

    Report-on-Genomes is a 3-column table: ['Genome','Size of Set','Number Sets']

    Report-on-Intersections' is a 3-column table: ['Genome1','Genome2','Number of Common Sets']

These are meant to be used as input to a spreadsheet or some other tool for
trying to analyze how well the correspondences could be formed.

=cut

use strict;
use SeedEnv;

my $usage = "usage: svr_sumarize_families Set-Report Genome-Report Intersection-Report";

my($setF,$genomeRep,$incommonF);
(
 ($setF      = shift @ARGV) &&
 ($genomeRep = shift @ARGV) &&
 ($incommonF = shift @ARGV)
)
    || die $usage;

my %by_sz;
my %by_genome;
my %in_common;

my $last = <STDIN>;
while ($last && ($last =~ /^(\S+)/))
{
    my $curr = $1;
    my @set = ();
    while ($last && ($last =~ /^(\S+)\t(\S+)/) && ($1 eq $curr))
    {
	push(@set,$2);
	$last = <STDIN>;
    }
    &process(\@set,\%by_sz,\%by_genome,\%in_common);
}
&show_sets(\%by_sz,$setF);
&show_genomes(\%by_genome,$genomeRep);
&show_in_common(\%in_common,$incommonF);

sub process {
    my($set,$by_sz,$by_genome,$in_common) = @_;

    my $sz = @$set;
    $by_sz->{$sz}++;
    my($i,$j);
    for ($i=0; ($i < @$set); $i++)
    {
	my $peg1 = $set->[$i];
	my $g1 = &SeedUtils::genome_of($peg1);
 	$by_genome->{$g1}->{$sz}++;
	for ($j=$i+1; ($j < @$set); $j++)
	{
	    my $peg2 = $set->[$j];
	    my $g2   = &SeedUtils::genome_of($peg2);
	    $in_common->{$g1}->{$g2}++;
	    $in_common->{$g2}->{$g1}++;
	}
    }
}

sub show_sets {
    my($by_sz,$setF) = @_;

    open(SET,">",$setF) || die "could not open $setF";
    print SET join("\t",('Size of Set','Number of Sets')),"\n";
    foreach my $sz (sort { $b <=> $a } keys(%$by_sz))
    {
	print SET join("\t",($sz,$by_sz->{$sz})),"\n";
    }
    close(SET);
}
 
sub show_genomes {
    my($by_genome,$genomeR) = @_;
    
    open(GEN,">",$genomeR) || die "could not open $genomeR";
    print GEN join("\t",('Genome','Size of Set','Number Sets')),"\n";
    my @genomes = keys(%$by_genome);
    foreach my $g1 (sort { $a <=> $b } keys(%$by_genome))
    {
	my $gH = $by_genome->{$g1};
	foreach my $sz (sort { $gH->{$b} <=> $gH->{$a} } keys(%$gH))
	{
	    print GEN join("\t",($g1,$sz,$by_genome->{$g1}->{$sz})),"\n";
	}
    }
    close(GEN);
}

sub show_in_common {
    my($incommon,$incommonF) = @_;
    
    open(COMM,">",$incommonF) || die "could not open $incommonF";
    print COMM join("\t",('Genome1','Genome2','Number of Common Sets')),"\n";
    my @genomes = keys(%$incommon);
    foreach my $g1 (sort { $a <=> $b } @genomes)
    {
	my $g1H = $incommon->{$g1};
	foreach my $g2 (sort { $g1H->{$b} <=> $g1H->{$a} } keys(%$g1H))
	{
	    print COMM join("\t",($g1,$g2,$g1H->{$g2})),"\n";
	}
    }
    close(COMM);
}
