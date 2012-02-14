
#
# myRAST pipeline processing script.
#
# dtr_compute_correspondences genome-dir closest-genomes
#

#
# This is a SAS Component
#

use SeedHTML;
use strict;
use SeedEnv;
use ProtSims;
use gjoseqlib;
use Data::Dumper;

@ARGV == 2 || die "Usage: $0 genome-dir close-genomes\n";

my $gdir = shift;
my $close = shift;

$| = 1;

my $sapO = SAPserver->new;

(-d $gdir && $gdir =~ /(\d+\.\d+)$/) || die "Invalid Genome Directory: $gdir";
my $gdir_id = $1;

open(CLOSE, "<", $close) || die "could not open $close: $!";

my @work;
while (<CLOSE>)
{
    chomp;
    if (/^(\d+\.\d+)/)
    {
	push(@work, $1);
    }
}
close(CLOSE);

for my $genome (@work)
{
    print "Compute correspondence for $genome\n";
    my $outfile = "$gdir/CorrToReferenceGenomes/$genome";
    my $ok = 0;
    if (open(OUT, "<", $outfile))
    {
	my $n = 0;
	$ok = 1;
	while (<OUT>)
	{
	    chomp;
	    my @x = split(/\t/, $_);
	    if (@x != 18)
	    {
		$ok = 0;
		print "not ok, @x = " . scalar(@x) . "\n";
		last;
	    }
	    $n++;
	}
	close(OUT);
	if ($n < 10)
	{
	    $ok = 0;
	    print "Not ok, too few entries\n";
	}
    }
    if ($ok)
    {
	print "Correspondence OK for $genome\n";
	next;
    }

    my $tmp = "$outfile.tmp";
    my $cmd = "svr_corresponding_genes -d $gdir $gdir_id $genome > $tmp";
    my $rc = system($cmd);
    if ($rc != 0)
    {
	die "compute failed for $genome with rc=$rc: $cmd\n";
    }
    rename($tmp, $outfile);
}
