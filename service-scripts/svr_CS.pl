use strict;
use Data::Dumper;
use CloseStrains;
use Getopt::Long;
use SeedEnv;

my $DataKmers = "/homes/overbeek/Ross/MakeCS.Kbase/Data/Data.kmers";
my $usage = "usage: svr_CS -d CloseStrainDir\n";
my $csD;
my $rc  = GetOptions('d=s' => \$csD);
if ((! $rc) || (! $csD))
{ 
    print STDERR $usage; exit ;
}
if (! -s "$csD/rep.genomes")
{
    die "the $csD must have a rep.genomes file";
}

my $number_genomes = &lines_in_file("$csD/rep.genomes");
if ($number_genomes < 4) { die "you need more than 4 genomes, but you have $number_genomes" }
if (! -d "$csD/GTOs") 
{ 
    &CloseStrains::get_genome_objects($csD);
    &CloseStrains::get_genome_name($csD);
}
else
{
    opendir(GTOS,"$csD/GTOs") || die "could not open $csD/GTOs";
    my @tmp = grep { $_ !~ /^\./ } readdir(GTOS);
    closedir(GTOS);
    if (@tmp < $number_genomes) 
    { 
	&CloseStrains::get_genome_objects($csD);
	&CloseStrains::get_genome_info($csD);
    }
}
if (! -d "$csD/Seqs") { &CloseStrains::get_translations($csD) }
else
{
    opendir(TRANS,"$csD/Seqs") || die "could not open $csD/Seqs";
    my @tmp = grep { $_ !~ /^\./ } readdir(GTOS);
    closedir(TRANS);
    if (@tmp < $number_genomes) { &CloseStrains::get_translations($csD) }
}

if (! -d "$csD/PegLocs") { &CloseStrains::get_locations($csD) }
else
{
    opendir(TRANS,"$csD/PegLocs") || die "could not open $csD/PegLocs";
    my @tmp = grep { $_ !~ /^\./ } readdir(GTOS);
    closedir(TRANS);
    if (@tmp < $number_genomes) { &CloseStrains::get_locations($csD) }
}

if (! -s "$csD/families.all")
{
    &SeedUtils::run("cut -f1 $csD/genome.names | get_families -d $DataKmers -s $csD/Seqs -f $csD/families > $csD/families.all");
}

if (! -s "$csD/readable.tree")
{
    &CloseStrains::build_tree($csD);
}

if (! -s "$csD/families.on.tree")
{
    &CloseStrains::place_families_on_tree($csD);
}

if (! -s "$csD/coupled.families")
{
    &SeedUtils::run("CS_compute_coupling -d $csD");
}

sub lines_in_file {
    my($file) = @_;

    my $lines = 0;
    open(FILE,"<$file") || return undef;
    while (defined($_ = <FILE>))
    {
	if ($_) 
	{
	    $lines++;
	}
    }
    return $lines;
}

