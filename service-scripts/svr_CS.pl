########################################################################
use strict;
use Data::Dumper;
use CloseStrains;
use Getopt::Long;
use SeedEnv;

#
# Make sure the bin dir is in our path.
#
$ENV{PATH} .= ":$FIG_Config::bin";


#===============================================================================
# This code takes a CS directory containing at least a rep.genomes file as input.
# The rep.genome entries represent pubSEED, CS (i.e., Kbase), and RAST genomes.
# The genome list in rep.genomes is used to construct a directory ($csD/GTOs) of
# typed genome objects.  These GTOs are independent of source, freeing the remainer
# of the code from worrying about where the genomes came from.
#
# The lines in the rep.genomes file can be
#
#       a genome id (implying PubSEED)
#       rast|JOB\tUSERNAME\tPASSWORD  (implying a RAST job)
#       kb|g.\d+ implying a CS genome
#       rast2|genomeID\tRAST2DIR (I am uncertain of what this does; I would guess
#            that is specifies a directory and a GTO in the directory


my $DataKmers = "/homes/overbeek/Ross/MakeCS.Kbase/Data/Data.kmers";
my $usage = "usage: svr_CS -d CloseStrainDir [--fill-in-refs] \n";
my $csD;
my $fill_in_refs;
my $rc  = GetOptions('d=s'          => \$csD,
		     'fill-in-refs' => \$fill_in_refs);
if ((! $rc) || (! $csD))
{ 
    print STDERR $usage; exit ;
}
if (! -s "$csD/rep.genomes")
{
    die "the $csD must have a rep.genomes file";
}

CloseStrains::set_status($csD, "initializing");

my $number_genomes = &lines_in_file("$csD/rep.genomes");
if ($number_genomes < 4) { die "you need more than 4 genomes, but you have $number_genomes" }
if (! -d "$csD/GTOs") 
{ 
    &CloseStrains::get_genome_objects($csD);
    &CloseStrains::get_genome_name($csD);
}
else
{
    #
    # If we are filling in, run through the reps file to
    # find genomes (just reference genomes) for which we don't have GTOs.
    #

    if ($fill_in_refs)
    {
	my @refs_to_add;
	open(R, "<", "$csD/rep.genomes") or die "Cannot open $csD/rep.genomes: $!";
	while (<R>)
	{
	    if (/^(\d+\.\d+)$/)
	    {
		my $g = $1;
		if (! -s "$csD/GTOs/$g")
		{
		    push(@refs_to_add, $g);
		}
	    }
	}
	close(R);
	if (@refs_to_add)
	{
	    open(T, ">>", "$csD/genome.types") or die "Cannot append to $csD/genome.types: $!";
	    for my $ref (@refs_to_add)
	    {
		CloseStrains::set_status($csD, "filling in reference $ref");
		CloseStrains::get_pubseed_genome_object("$csD/GTOs", $ref, \*T);
	    }
	    close(T);
	    &CloseStrains::get_genome_name($csD);
	}
    }
    else
    {
	opendir(GTOS,"$csD/GTOs") || die "could not open $csD/GTOs";
	my @tmp = grep { $_ !~ /^\./ } readdir(GTOS);
	closedir(GTOS);
	
	if (@tmp < $number_genomes) 
	{ 
	    &CloseStrains::get_genome_objects($csD);
	    &CloseStrains::get_genome_name($csD);
	}
    }
}
if (! -d "$csD/Seqs") { &CloseStrains::get_translations($csD) }
else
{
    CloseStrains::set_status($csD, "getting sequences");
    opendir(TRANS,"$csD/Seqs") || die "could not open $csD/Seqs";
    my @tmp = grep { $_ !~ /^\./ } readdir(GTOS);
    closedir(TRANS);
    if (@tmp < $number_genomes) { &CloseStrains::get_translations($csD) }
}

if (! -d "$csD/PegLocs") { &CloseStrains::get_locations($csD) }
else
{
    CloseStrains::set_status($csD, "getting locations");
    opendir(TRANS,"$csD/PegLocs") || die "could not open $csD/PegLocs";
    my @tmp = grep { $_ !~ /^\./ } readdir(GTOS);
    closedir(TRANS);
    if (@tmp < $number_genomes) { &CloseStrains::get_locations($csD) }
}

if (! -s "$csD/families.all")
{
    CloseStrains::set_status($csD, "computing families");

    &SeedUtils::run("cut -f1 $csD/genome.names | get_families -d $DataKmers -s $csD/Seqs -f $csD/families > $csD/families.all");
}

if (! -s "$csD/readable.tree")
{
    CloseStrains::set_status($csD, "computing trees");
    &CloseStrains::build_tree($csD);
}

if (! -s "$csD/families.on.tree")
{
    CloseStrains::set_status($csD, "placing families");
    &CloseStrains::place_families_on_tree($csD);
}

if (! -s "$csD/coupled.families")
{
    CloseStrains::set_status($csD, "computing coupling");
    &SeedUtils::run("CS_compute_coupling -d $csD");
}

CloseStrains::set_status($csD, "compute index");
CloseStrains::create_inverted_index($csD);

CloseStrains::set_status($csD, "complete");

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

