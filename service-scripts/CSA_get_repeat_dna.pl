use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use Carp;
use gjoseqlib;
use SeedEnv;

my $usage = "usage: CSA_get_repeat_dna WorkingDir";
$| = 1;

my($dir);
(
 ($dir           = shift @ARGV) 
)
    || die $usage;

my %contigs1 = map { $_->[0] => $_->[2] } &gjoseqlib::read_fasta("$dir/contigs1");
my %contigs2 = map { $_->[0] => $_->[2] } &gjoseqlib::read_fasta("$dir/contigs2");

system "svr_big_repeats -i 90 -f $dir/contigs1 > $dir/big.repeats1";
system "svr_big_repeats -i 90 -f $dir/contigs2 > $dir/big.repeats2";

&get_dna_for_repeats("$dir/big.repeats1","$dir/big.repeats1.fasta",\%contigs1);
&get_dna_for_repeats("$dir/big.repeats2","$dir/big.repeats2.fasta",\%contigs2);

system "formatdb -p F -i $dir/contigs2";
my @blast_against_ref = grep { ($_ =~ /\s+(\S+)\s+\S+$/) && ($1 < 1.0e-100) }
                        `blastall -FF -m 8 -p blastn -d $dir/contigs2 -i $dir/big.repeats1.fasta`;
open(REP,">$dir/blast.rep1.contigs2") || die "could not open $dir/blast.rep1.contigs2";
foreach $_ (@blast_against_ref)
{
    print REP $_;
}
close(REP);

sub get_dna_for_repeats {
    my($repeats,$seqF,$contigs) = @_;

    open(DNA,">$seqF") || die "could not open $seqF";
    foreach $_ (`cat $repeats`)
    {
	chop;
	my(undef,undef,$contig1,$beg1,$end1,$contig2,$beg2,$end2) = split(/\t/,$_);
	my $seq = &dna_seq($contig1,$beg1,$end1,$contigs);
	$seq || die "$contig1 $beg1 $end1";
	print DNA ">$contig1\_$beg1\_$end1\n$seq\n";

	my $seq = &dna_seq($contig2,$beg2,$end2,$contigs);
	$seq || die "$contig2 $beg2 $end2";
	print DNA ">$contig2\_$beg2\_$end2\n$seq\n";
    }
    close(DNA);
    system "formatdb -p F -i $seqF";
}

sub dna_seq {
    my($contig,$beg,$end,$contigs) = @_;
    if ($beg < $end)
    {
	return substr($contigs->{$contig},$beg-1,$end-($beg-1));
    }
    else
    {
	return &SeedUtils::rev_comp(substr($contigs->{$contig},$end-1,$beg-($end-1)));
    }
}
