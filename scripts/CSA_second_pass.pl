########################################################################
use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use Carp;
use gjoseqlib;
use SeedEnv;

my $usage = "usage: CSA_second_pass WorkingDir";
$| = 1;

my($dir);
(
 ($dir           = shift @ARGV) && (-s "$dir/matches")
)
    || die $usage;

my %contigs1 = map { $_->[0] => $_->[2] } &gjoseqlib::read_fasta("$dir/contigs1");
my %contigs2 = map { $_->[0] => $_->[2] } &gjoseqlib::read_fasta("$dir/contigs2");

my @first_pass = map { chop; [split(/\t/,$_)] } `cat $dir/output.first.pass`;

my $x;
while ($x = shift @first_pass)
{
#   print &Dumper(['processing',$x]);
    &print_connection($x);
    my $gap;
    if ((@first_pass > 0) && 
	($gap = &gen_alignments($x,$first_pass[0],\%contigs1,\%contigs2)))
    {
#	print &Dumper(['gap',$gap]); 
	&print_connections($gap);
    }
}

sub print_connections {
    my($x) = @_;

    foreach my $ali (@$x)
    {
	&print_connection($ali);
    }
}

sub print_connection {
    my($x) = @_;
    print join("\t",@$x),"\n";
}

sub gen_alignments {
    my($x,$y,$contigs1,$contigs2) = @_;

#   print STDERR &Dumper(['gen_alignments',$x,$y]);
    my($ln1,$ln2);
    if (($x->[0] eq $y->[0]) && ($x->[3] eq $y->[3]) # if same contigs
	&& ($y->[1] > $x->[2]) && (($ln1 = ($y->[1] - ($x->[2]+1))) <= 10000) && ($ln1 > 0))
    {
	if ((((&strand($x->[4],$x->[5]) eq "+") && 
	      (&strand($y->[4],$y->[5]) eq "+") && 
	      (($ln2 = ($y->[4] - ($x->[5]+1))) > 0)) ||
	     ((&strand($x->[4],$x->[5]) eq "-") && 
	      (&strand($y->[4],$y->[5]) eq "-") && 
	      (($ln2 = ($x->[5] - ($y->[4]+1))) > 0))) && 
	    ($ln2 > 0) && (abs($ln2-$ln1) <= (0.1 * $ln1)))
	{
	    my $seq1 = &dna_seq($x->[0],$x->[2]+1,$y->[1]-1,$contigs1);
	    if (length($seq1) != $ln1) { print &Dumper(['bad seq1',$x,$y,$ln1,$seq1]); die '1' }
	    my $incr = ($x->[4] < $x->[5]) ? 1 : -1;
	    my $seq2 = &dna_seq($x->[3],$x->[5]+$incr,$y->[4]-$incr,$contigs2);
	    if (length($seq2) != $ln2) { print &Dumper(['bad seq2',$ln2,$x,$y,$seq2]); die '2' }
	    if (abs(length($seq1) - length($seq2)) > (0.1 * $ln1)) 
	    { 
		print &Dumper($x,$y,$seq1,$seq2,$x->[3],$x->[5],$incr,$y->[4],$ln1,$ln2);
		die "bad lengths";
	    }
	    my @ali = &get_alignments($seq1,$seq2,
				      $x->[0],$x->[2]+1,$y->[1]-1,,
				      $x->[3],$x->[5]+$incr,$y->[4]-$incr);
	    if (@ali > 0) { return \@ali }
	}
    }
    return undef;
}


sub get_alignments {
    my($seq1,$seq2,$contig1,$beg1,$end1,$contig2,$beg2,$end2) = @_;

    ($seq1 && $seq2) || confess "bad seqs";
    my @ali;
    my $tmp1 = "tmp1.$$.fasta";
    my $tmp2 = "tmp2.$$.fasta";
    open(TMP,">",$tmp1) || die "could not open $tmp1";
    print TMP ">s1\n$seq1\n>s2\n$seq2\n";
    close(TMP);
#   print "running svr_align_seqs -l -z < $tmp1 > $tmp2\n";
    &run("svr_align_seqs -l -z < $tmp1 > $tmp2");
#    print "look in $tmp1 and $tmp2\n";
    my @ali_seqs = &gjoseqlib::read_fasta($tmp2);
    unlink($tmp1,$tmp2);

    my $ln = length($ali_seqs[0]->[2]);
    my $i=0;
    my $posI1 = 0;
    my $posI2 = 0;
    my $c1;
    my $c2;
    while ($i < $ln)
    {
	while (($i < $ln) && 
	       ($c1 = substr($ali_seqs[0]->[2],$i,1)) &&
	       ($c2 = substr($ali_seqs[1]->[2],$i,1)) &&
	       (($c1 eq '-') || ($c2 eq '-')))
	{
	    $i++;
	    if ($c1 ne "-") { $posI1++ }
	    if ($c2 ne "-") { $posI2++ }
	}
	my($j,$iden);
	$iden = 0;
	my $c1;
	my $c2;
	my $posJ1  = $posI1;
	my $posJ2  = $posI2;
	     
	for ($j = $i; (($j < $ln) &&
	                 (($c1 = substr($ali_seqs[0]->[2],$j,1)) ne '-') &&
	                 (($c2 = substr($ali_seqs[1]->[2],$j,1)) ne '-')); $j++) 
	{
	    if (uc $c1 eq uc $c2) { $iden++ }
	    $posJ1++;
	    $posJ2++;
	}

	my $ln_piece = $j - $i;
	if (($ln_piece > 5) && (($iden/$ln_piece) >= 0.5))
	{
	    push(@ali,[$contig1,$beg1+$posI1,$beg1+($posJ1-1),
		       $contig2,
		       ($beg2 < $end2) ? ($beg2+$posI2,$beg2+($posJ2-1)) : ($beg2-$posI2,$beg2-($posJ2-1)),
		       'ali']);
	}
	$i = $j;
	$posI1 = $posJ1;
	$posI2 = $posJ2;
    }
    return @ali;
}

sub run {
    my($cmd) = @_;

    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}

sub strand {
    my($beg,$end) = @_;
    return ($beg < $end) ? '+' : '-';
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
