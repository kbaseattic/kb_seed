use strict;
#
# This is a SAS Component
#
use Proc::ParallelLoop;
use Data::Dumper;

my $usage = "usage: CSA_get_close_strain_annotations AnnDir WorkingDirsD GenomeID Contigs RefDir1 RefDir2 ... ";

my($annoD,$work_dirs,$genomeID,$contigs,@refD);

(
 ($annoD       = shift @ARGV) &&
 ($work_dirs   = shift @ARGV) &&
 ($genomeID    = shift @ARGV) &&
 ($contigs     = shift @ARGV) &&
 (@refD        = @ARGV)
)
    || die $usage;

if (-d $annoD) { die "$annoD already exists; delete it if you want to generate a new copy" }
if (-d $work_dirs) { die "$work_dirs already exists; delete it if you want to generate a new copy" }
mkdir($work_dirs,0777) || die "could not make $work_dirs";
(-s $contigs) || die "you need to give contigs in fasta format";

(@refD > 0) || die "you need to give one or more reference genomes";
my @tmp = grep { ! -d $_ } @refD;
if (@tmp > 0)
{
    print STDERR join(",",@tmp), " do not exist; exiting";
    exit;
}

my @args = map { [$work_dirs,$genomeID,$contigs,$_] } @refD;
&pareach(\@args,\&do_one,{ Max_Workers => 4 });

open(TMP,">tmp.$$") || die "aborted";
foreach $_ (@refD)
{
    if ($_ =~ /(\d+\.\d+)$/)
    {
	(-s "$work_dirs/$1-$genomeID/mapped.features")
	    || die "$work_dirs/$1-$genomeID/mapped.features is missing";
	print TMP "$work_dirs/$1-$genomeID\n";
    }
}
close(TMP);
&run("CSA_merge_estimates $annoD $genomeID < tmp.$$");
unlink("tmp.$$");
# print STDERR "MADE IT\n";

sub do_one {
    my($args) = @_;
    my($work_dirs,$genomeID,$contigs,$refD) = @$args;
    my $tmpF = "tmp.functions.$$";
    if (-s "$refD/assigned_functions") { system "cat $refD/assigned_functions > $tmpF" }
    else
    {
	if ((-s "$refD/proposed_functions") && (-s "$refD/proposed_non_ff_functions"))
	{
	    system "cat $refD proposed_functions $refD/proposed_non_ff_functions > $tmpF";
	}
	else
	{
	    die "missing annotations for $refD";
	}
    }
    ($refD =~ /(\d+\.\d+)$/) || die "invalid reference directory";
    &run("CSA_close_strains $refD/contigs $contigs $work_dirs/$1-$genomeID $refD/Features/peg/tbl $refD/Features/rna/tbl $tmpF $refD/Features/peg/fasta");
    unlink($tmpF);
}

sub run {
    my($cmd) = @_;

    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}
