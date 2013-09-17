use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use gjoseqlib;
use SeedAware;
use SeedEnv;

my $N;
my $rpts;
my $usage = "usage: CSA_make_unique_kmers N RepeatKmers < Contigs > Kmers";
(
 ($N = shift @ARGV) &&
 ($rpts = shift @ARGV)
)
    || die $usage;

my @contigs = &gjoseqlib::read_fasta;
my $sz = 0;
foreach $_ (@contigs) { $sz += length($_->[2]) }
my $tmp_dir = '.';
my $tmp1    = "$tmp_dir/tmp1_$$.fasta";
open(TMP,"| sort -T . | CSA_filter_unique > $tmp1 2> $rpts") || die "could not set up pipeline";
foreach $_ (@contigs)
{
    my($id,undef,$seq) = @$_;
    my $seqR = &SeedUtils::rev_comp($seq);
    my $ln = length($seq);
    my $i;
    for ($i=0; ($i < (length($seq) - $N)); $i++)
    {
	&print_kmer(uc substr($seq,$i,$N),$id,'+',$i+1,\*TMP);
	&print_kmer(uc substr($seqR,$i,$N),$id,'-',$ln-$i,\*TMP);
    }
}
close(TMP);
open(KMERS,"<$tmp1") || die "could not open the kmers";
while (defined($_ = <KMERS>))  { print $_ }
close(KMERS);
unlink($tmp1);

sub print_kmer {
    my($seq,$id,$strand,$pos,$fh) = @_;

    my $i;
    my $ln = length($seq);

    for ($i=2; ($i < $ln); $i += 3)
    {
	substr($seq,$i,1) = 'N';
    }
    print $fh join("\t",($seq,$id,$strand,$pos)),"\n";
}
