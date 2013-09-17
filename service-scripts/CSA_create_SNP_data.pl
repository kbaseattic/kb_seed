use strict;
#
# This is a SAS Component
#
use Data::Dumper;

my $usage = "CSA_create_SNP_data ReferenceDir OtherGenomesFile OutputDir";

my($refD,$otherG,$outputD);

(
 ($refD    = shift @ARGV) &&
 ($otherG  = shift @ARGV) &&
 ($outputD = shift @ARGV)
)
    || die $usage;

((-d $refD) && ($refD =~ /(\d+\.\d+)$/))
    || die "$refD is not a valid SEED directory";
my $ref = $1;

(! -d $outputD) || die "$outputD already exists; remove it before rerunning";
mkdir($outputD,0777) || die "could not make $outputD";
mkdir("$outputD/Work",0777) || die "could not make $outputD/Work";
mkdir("$outputD/Anno",0777) || die "could not make $outputD/Anno";

open(OTHERS,"<",$otherG) || die "could not open $otherG";
my @other_genomes = map { ($_ =~ /((\S.*)?\d+\.\d+[\.\/]contigs)\s*$/) ? $1 : () } <OTHERS>;
close(OTHERS);

(@other_genomes > 0) || die "there were no valid contig files in $otherG";

open(FINISH,"| CSA_build_alignments $refD $outputD/Final $outputD/SeedGenomes $outputD/PseudoGeneAlignments")
    || die "could not start CSA_build_alignments";

foreach my $contigs (@other_genomes)
{
    if ($contigs =~ /(\d+\.\d+)[\.\/]contigs$/)
    {
	my $other_id = $1;
	&run("CSA_get_close_strain_annotations $outputD/Anno/$other_id $outputD/Work/$other_id $other_id $contigs $refD");
	print FINISH "$outputD/Work/$other_id/$ref-$other_id\t$outputD/Anno/$other_id\n";
    }
    else
    {
	die "$contigs must contain a valid genome ID (that should be registered)";
    }
}
close(FINISH);

opendir(ANNO,"$outputD/Anno") || die "could not open AnnoD";
my @anno_sub  = grep { $_ !~ /^\./ } readdir(ANNO);
closedir(ANNO);

mkdir("$outputD/Final/PG",0777) || die "could not make PG directory";
open(SETS,"| cluster_objects | tabs2rel > $outputD/Final/PG/pg.sets")
    || die "could not open sets";

foreach my $file (map { "$outputD/Anno/$_/features" } @anno_sub)
{
    open(FEATURES,"<",$file) || die "could not open $file";
    while (defined($_ = <FEATURES>))
    {
	if ($_ =~ /^((fig\|)\d+\.\d+(\S+))/)
	{
	    print SETS join("\t",($1,$2 . $ref . $3)),"\n";
	}
    }
}
close(SETS);
mkdir("$outputD/Final/PG/Genomes",0777) || die "could not make Genomes";
&run("cp -r $refD $outputD/SeedGenomes/* $outputD/Final/PG/Genomes");
opendir(GENOMES,"$outputD/Final/PG/Genomes") 
    || die "could not open $outputD/Final/PG/Genomes";
my @genome_ids = grep { $_ =~ /^\d+\.\d+$/ } readdir(GENOMES);
closedir(GENOMES);
open(PGG,">","$outputD/Final/PG/pg.genomes") 
    || die "could not open $outputD/Final/PG/pg.genomes";
foreach $_ (sort { ($a <=> $b) or ($a cmp $b) } @genome_ids)
{
    my $is_ref = ($_ eq $ref);
    print PGG "$is_ref\t$_\n";
}
close(PGG);

&run("cp -r $outputD/Final/snp $outputD/Final/PG/Genomes/$ref/Features");
&run("cp -r $outputD/Final/Alignments $outputD/Final/PG/Genomes/$ref/Features/snp");
&run("cp -r $outputD/Final/snp2ali $outputD/Final/PG/Genomes/$ref/Features/snp");
&run("build_nap_alignments $outputD/Anno $outputD/Final/PG/Genomes");

sub run {
    my($cmd) = @_;

#    print STDERR "running: $cmd\n";
    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}
