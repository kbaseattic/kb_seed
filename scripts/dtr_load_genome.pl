
use strict;
use myRAST;
use File::Basename;

use SaplingGenomeLoader;

use Getopt::Long;

my $force;
my $rc = GetOptions("f" => \$force);
$rc or die "Usage: $0 [-f] genome-dirs\n";

my $sapling = myRAST->instance->sapling;
my $sap = myRAST->instance->sap;

my $genomes = $sap->all_genomes();

for my $dir (@ARGV)
{
    my $genome = basename($dir);
    # next unless $dir =~ m,/(\d+\.\d+)$, && -d $dir;
#    my $genome = $1;
    if ($genome !~ /^\d+\.\d+$/)
    {
	warn "Invalid genome dir $dir\n";
	next;
    }
    if ($genomes->{$genome} && !$force)
    {
	print "Already have $genome $genomes->{$genome}\n";
	next;
    }

    print "Loading genome $genome from $dir\n";

    #
    # push empty subsystems in if missing.
    #
    if (! -d "$dir/Subsystems")
    {
	mkdir("$dir/Subsystems");
	print "Create $dir/Subsystems\n";
    }

    for my $f (qw(subsystems bindings))
    {
	my $p = "$dir/Subsystems/$f";
	if (! -f $p)
	{
	    print "Create empty $p\n";
	    open(P, ">", $p);
	    close(P);
	}
    }

    my $name;
    if (open(G, "<", "$dir/GENOME"))
    {
	$name = <G>;
	chomp $name;
	close(G);
    }
    else
    {
	$name = "genome $genome";
	open(G, ">", "$dir/GENOME");
	print G "$name\n";
	close(G);
    }

    if (! -f "$dir/TAXONOMY")
    {
	open(G, ">", "$dir/TAXONOMY");
	print G "$name\n";
	close(G);
    }
    
    $sapling->BeginTran();
    my $stats = SaplingGenomeLoader::Process($sapling, $genome, $dir, 1);
    $sapling->CommitTran();
    if (open(X, ">", "$dir/SAPLING_LOAD_STATS"))
    {
	print X "Genome load stats:\n " . $stats->Show();
	close(X);
    }
    else
    {
	warn "Cannot open $dir/SAPLING_LOAD_STATS: $!";
    }
}
