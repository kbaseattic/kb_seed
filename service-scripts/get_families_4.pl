#
# This is a SAS Component
#


=head1 get_families_4

Try to split "bad" families into "good" families.

------

Example:

    get_families_4 -d Data.kmers -m 10  -s Seqs.Fasta < bad > bad.fixed

This uses a Data.kmer directory built to support kmer_guts processing.
We suggest using the one in pubSEED (Global/Data.kmers).  

The -m parameter gives the minimum number of signature kmers that are
need to be in common for two PEGs to be considered part of the same
family.

Seqs.Fasta is a directory that contains protein fasta files.  The file names
must be genome IDs.  Thus, it is assumed that 

    Seqs.Fasta/83333.1

would be the peg translations for E.coli (assuming that you wished E.coli
to be one of the genomes from which families get produced).

------


=head2 Command-Line Options

=over 4

=item -d Data

This is a Data directory usable by kmer_guts.  I suggest using the one in
the Global directory (FIGfisk/FIG/Data/Global/Data.kmers).

=item -m MatchN

Families that may need to be split use an algorithm in which
two PEGs are kept in the same family iff they share at least MatchN kmers
=item -s Seqs.Fasta

The directory from which the translations of PEGs from each genome are 
used.

=back

=head2 Output Format

Sets are written to STDOUT (and often a single input sets will produce multiple
output sets)

=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;
use gjoseqlib;
use File::Temp 'tempfile';


my $usage = "usage: get_families_4 -d Data -s Seqs\n";
my $dataD;
my $seqsD;
my $matchN = 3;
my $rc  = GetOptions('d=s' => \$dataD,
		     'm=i' => \$matchN,
                     's=s' => \$seqsD);
if ((! $rc) || (! $dataD) || (! $seqsD))
{ 
    print STDERR $usage; exit ;
}

my $primes = [3769,6337,12791,24571,51043,101533,206933,400187,
              821999,2000003,4000037,8000009,16000057,32000011,
	      64000031,128000003,248000009,508000037,1073741824,
	      1400303159,2147483648];
open(SZ,"<$dataD/size") || die "could not open $dataD/size";
my $sz = <SZ>;
chomp $sz;
my $i;
# print STDERR "required sz = $sz\n";
for ($i=0; ($i < @$primes) && ($primes->[$i] < (3 * $sz)); $i++) {}
if ($i == @$primes) { die "$sz is too large - adjust the '$primes' above" }
my $hash_size = $primes->[$i];
# print STDERR "hash_size=$hash_size\n";

my ($seqs_fh, $seqs_file) = tempfile();
my ($kout_fh, $kout_file) = tempfile();

my %genomes;
my %needed_pegs;
my @sets;
my %func_of;
while (defined($_ = <STDIN>))
{
    chomp;
    my $set = [split(/\t/,$_)];
    my $func = shift @$set;
    push(@sets,$set);
    foreach my $peg (@$set)
    {
	my $g = &SeedUtils::genome_of($peg);
	$genomes{$g} = 1;
	$needed_pegs{$peg} = 1;
	$func_of{$peg} = $func;
    }
}

foreach my $g (keys(%genomes))
{
    my @tuples = grep { $needed_pegs{$_->[0]} } &read_fasta("$seqsD/$g");
    foreach my $tuple (@tuples)
    {
	my($peg,undef,$seq) = @$tuple;
	print $seqs_fh ">$peg\n$seq\n";
    }
}
close($seqs_fh);
close($kout_fh);
&SeedUtils::run("kmer_guts -d 1 -D $dataD -a -s $hash_size < $seqs_file | condense_kmer_output > $kout_file");
my %seen;
open(TMP,"<$kout_file") || die "could not read $kout_file";
while (defined($_ = <TMP>))
{
    if ($_ =~ /^(\S+)\t(\S*)/)
    {
	next if (! $2);
	foreach my $k (split(/,/,$2))
	{
	    $seen{$k}++;
	}
    }
}
close(TMP);
my %to_kmers;
open(TMP,"<$kout_file") || die "could not read $kout_file";
while (defined($_ = <TMP>) && ($_ =~ /^(\S+)\t(\S*)/))
{
    my($peg,$kmers) = ($1,$2);
    if ($kmers)
    {
	$to_kmers{$peg} = [grep { $seen{$_} > 1 } split(/,/,$kmers)];
    }
}
close(TMP);
foreach my $set (@sets)
{
    my @sorted = sort { &by_size($to_kmers{$b},$to_kmers{$a}) } @$set;
    &process_set(\@sorted,\%to_kmers,$matchN,\%func_of);
}
unlink($kout_file);

sub by_size {
    my($x,$y) = @_;

    my $v1 = ($x ? @$x : 0);
    my $v2 = ($y ? @$y : 0);
    return ($v1 <=> $v2);
}

sub process_set {
    my($sorted_pegs,$to_kmers,$matchN,$func_of) = @_;

    my $bad = 0;
    my @subsets;
    my @next_sorted;
    my $subN = 1;
    while (@$sorted_pegs > 0)
    {
	my $seed = shift @$sorted_pegs;
	my @new_set = ($seed);
	@next_sorted = ();
	my $i;
	for ($i=0; ($i < @$sorted_pegs); $i++)
	{
	    if (&match($sorted_pegs->[$i],$seed,$to_kmers,$matchN))
	    {
		push(@new_set,$sorted_pegs->[$i]);
	    }
	    else
	    {
		push(@next_sorted,$sorted_pegs->[$i]);
	    }
	}
#	print join("\t",@new_set),"\n";
	foreach my $peg ( @new_set)
	{
	    print join("\t",($func_of{$peg},$subN,$peg)),"\n";
	}
	$sorted_pegs = [@next_sorted];
	$subN++;
    }
}

sub match {
    my($peg1,$peg2,$to_kmers,$matchN) = @_;

    my $n = 0;
    my $k1 = $to_kmers->{$peg1}; if (! $k1) { $k1 = [] }
    my $k2 = $to_kmers->{$peg2}; if (! $k2) { $k2 = [] }
    my $i1 = 0;
    my $i2 = 0;
    while (($n < $matchN) && ($i1 < @$k1) && ($i2 < @$k2))
    {
	if ($k1->[$i1] == $k2->[$i2])
	{
	    $n++;
	    $i1++;
	    $i2++;
	}
	elsif ($k1->[$i1] < $k2->[$i2])
	{
	    $i1++;
	}
	else
	{
	    $i2++;
	}
    }
    return ($n == $matchN)
}
