########################################################################
use strict;
#
# This is a SAS Component
#
##########
#
# This script takes as input a set of "reference genomes" and attempts to suggest
# corrections in gene calls, as well as identifying regions of large repeats.  It is very
# slow, so if you are going to use over 10 genomes, let it run overnight (or over a weekend).
# 
# It first copies the genomes into OutDir/ReferenceGenomes.  At the end, the Features/peg
# directory will be altered to reflect the suggested changes.  See the OutputDir/2/Reports
# directory for a log of the proposed changes.  Then look in 
# 
#     OutputDir/2/AnnoD/*/possible.large.repeats
#     OutputDir/2/AnnoD/*/potentially.lost.features
#     OutputDir/2/AnnoD/*/potenitally.disrupted.features
###########

use Data::Dumper;
use Proc::ParallelLoop;

my $usage = "usage: CSA_ref_vs_ref OutputDir < RefGenomesDesc";

my $outputD;

(
 ($outputD    = shift @ARGV)
)
    || die $usage;
(! -d $outputD) || die "$outputD already exists";
mkdir($outputD,0777) || die "could not make $outputD";
mkdir("$outputD/ReferenceGenomes") || die "could not make $outputD/ReferenceGenomes";
foreach my $genome_dir ( map { chop; $_} <STDIN> )
{
    &run("cp -r $genome_dir $outputD/ReferenceGenomes");
}
opendir(REF,"$outputD/ReferenceGenomes") || die "could not set up ReferenceGenomes";
my @refG = sort { ($a <=> $b) or ($a cmp $b) } grep { $_ =~ /^\d+\.\d+$/ } readdir(REF);
closedir(REF);

for (my $stage = 1; ($stage <= 2); $stage++)
{
    my $stageD = "$outputD/$stage";
    mkdir($stageD,0777) || die "could not make $stageD";
    mkdir("$stageD/AnnoD",0777) || die "could not open $stageD/AnnoD";
    mkdir("$stageD/WorkD",0777) || die "could not open $stageD/WorkD";

    my @todo;
    my($i,$j);
    for ($i=0; ($i < @refG); $i++)
    {
	my $refI        = $refG[$i];
	my $genome_dirI = "$outputD/ReferenceGenomes/$refG[$i]";
	my @ref_genomes;
	for ($j=0; ($j < @refG); $j++)
	{
	    if ($i != $j)
	    {
		my $refJ        = $refG[$j];
		my $genome_dirJ = "$outputD/ReferenceGenomes/$refG[$j]";
		push(@ref_genomes,$genome_dirJ);
	    }
	}
	my $annoD       = "$stageD/AnnoD/$refI";
	my $workD       = "$stageD/WorkD/$refI";
	my $ref_dirs    = join(" ",@ref_genomes);
	push(@todo,"CSA_get_close_strain_annotations $annoD $workD $refI $genome_dirI/contigs $ref_dirs");
    }
    &pareach(\@todo,\&run,{ Max_Workers => 2 });

    mkdir("$stageD/Reports",0777) || die "could not make $stageD/Reports";
    for ($i=0; ($i < @refG); $i++)
    {
	my $refI = $refG[$i];
	my $genome_dirI = "$outputD/ReferenceGenomes/$refG[$i]";
	&run("CSA_predict_features_based_on_refs -install $stageD/AnnoD/$refI/features $stageD/AnnoD/$refI/contigs.index $genome_dirI > $stageD/Reports/$refI");
    }
}

sub run {
    my($cmd) = @_;

#    print STDERR "running: $cmd\n";
    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}
