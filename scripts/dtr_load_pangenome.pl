use strict;
use myRAST;
use GenomeLoader;

@ARGV == 1 or die "Usage: dtr_load_pangenome pangenome-dir\n";

my $pg_dir = shift;

-d $pg_dir or die "Pangenome dir $pg_dir does not exist\n";

my $gsdb = myRAST->instance->genome_set_db;
my $sap = myRAST->instance->sap;

my $set = $gsdb->create_set_from_pangenome($pg_dir);
print "created set " . $set->id . " " . $set->name . "\n";

opendir(D, "$pg_dir/Genomes") or die "Cannot open $pg_dir/Genomes: $!";

my @genomes = sort { $a <=> $b } grep { /^\d+\.\d+$/ && -d "$pg_dir/Genomes/$_" } readdir(D);

my $loader = GenomeLoader->new();

for my $genome (@genomes)
{
    if ($loader->genome_present($genome))
    {
	print "Genome $genome is already loaded\n";
	next;
    }

    my $dir = "$pg_dir/Genomes/$genome";
    print "Loading genome from $dir\n";
    my $ok = $loader->load_genome($dir);
    if ($ok)
    {
	print "Genome loaded\n";
    }
    else
    {
	print "Error loading genome\n";
    }
}
