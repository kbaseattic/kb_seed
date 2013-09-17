use strict;
use Data::Dumper;
use Carp;
use Correspondence;
use CorrTableEntry;

#
# This is a SAS Component
#

=head1 svr_make_pan_genome_prot_families < InputDefiningGenomes > ProteinFamilies

Construct the protein families needed to study Pan Genomes

=head2 Introduction

The study of pan genomes focuses on protein families composed of corresponding proteins.
This program takes an input file that defines where to find the genomes, what proteins each
contains, locations for the proteins, and functions for the proteins.


=head2 Command-Line Arguments

The program is invoked using

    svr_make_pan_genome_prot_families [options] < FileDefiningGenomes > ProteinFamilies

    The genomes can be identified by a genome ID from P-SEED, a SEED/RAST directory,
    or a triple of files (fasta,tbl,assigned_functions).  Each line of the input
    file describes one of these three sources of a genome.

=over 4

=item -d 

Directory used to store the binary correspondences

=item -i

Minimum identity used in forming binary correspondences (defaults to 80)

=item -bbhs=[0|1]

Use -bbhs=1 to force connections to be bidirectional best hits (BBHs).  Defaults to 1,
so use -bbhs=0 to get a looser matching procedure.

=item -n

Minimum number of genes in context that can be paired (defaults to 5)

=item -numMatchingFunctionsInContext=N

Minimum number of the pairs in context that contain matching functions.  (Defaults to min(2,# genes in context)).

=item -maxPsc=pscore

Maximum p-score required in correspondences (defaults to 1.0e-10)

=item -coverage=Frac

Fraction of each gene in a pair that must be within the region of similarity if the
pair are to be considered as "corresponding" (defaults to 0.7)

=item -p=N

Number of computations of correspondences that can be run in parallel.

=back

=head2 Output

The output files defines the resulting protein families.  Each line contains

    [SetNumber,ProteinID,AssignedFunction]

=cut

use Getopt::Long;
my $dirC = "GenomeCorrespondences";
my $bbhs = 1;
my $maxPsc       = 1.0e-10;
my $minIden      = 80;
my $min_context  = 5;
my $min_cov      = 0.7;
my $min_matching = 2;
my $p            = 1;

my $usage = "
    svr_make_pan_genome_prot_families -d Corr 
                                       [-bbhs=0|1 (defaults to 1)]
                                       [-i MinIdentity] 
                                       [-n MinContext] 
                                       [-numMatchingFunctionsInContext N]
                                       [-maxPsc Psc]
                                       [-p NumberProcs]
                                       [-coverage Fraction] < GenomeDefs > Families
\n";

my $rc = GetOptions( "d=s"        => \$dirC,
		     "bbhs=i"     => \$bbhs,
		     "p=i"        => \$p,
		     "i=i"        => \$minIden,
		     "n=i"        => \$min_context,
		     "maxPsc=f"   => \$maxPsc,
                     "coverage=f" => \$min_cov,
		     "numMatchingFunctionsInContext=i" => \$min_matching
		   );

$rc or print STDERR $usage and exit;
if ($min_matching > $min_context) { $min_matching = $min_context }

&SeedUtils::verify_dir($dirC);

my @genomes = map { $_ =~ /(\S+)/; [$1,&genome_id($1)] } <STDIN>;

my($i,$j,@queue);
for ($i=0; ($i < $#genomes); $i++)
{
    for ($j=$i+1; ($j < @genomes); $j++)
    {
	my $file = $genomes[$i]->[1] . '-' . $genomes[$j]->[1];
	my $tmpF = "$dirC/$file.tmp";
	if (! -s "$dirC/$file")
	{
	    push(@queue,[$genomes[$i]->[0],$genomes[$j]->[0],$tmpF,"$dirC/$file"]);
	}
    }
}

use Proc::ParallelLoop;
&pareach(\@queue,\&generate_corr_table,{Max_Workers => $p});

open(BIN,"| cluster_objects | tabs2rel") || die "could not cluster objects";
for ($i=0; ($i < $#genomes); $i++)
{
    for ($j=$i+1; ($j < @genomes); $j++)
    {
	my $file = $genomes[$i]->[1] . '-' . $genomes[$j]->[1];
	open(CORR,"<","$dirC/$file") || die "could not open $dirC/$file";
	foreach my $tuple (map { chomp; [split(/\t/,$_)] } <CORR>)
	{
	    bless $tuple,"CorrTableEntry";
	    if (&Correspondence::entry_meets_criteria( undef,$tuple,
						       -bbhRequired => $bbhs,
						       -minIden => $minIden,
						       -minCoverage1 => $min_cov,
						       -minCoverage2 => $min_cov,
						       -maxPsc       => $maxPsc,
						       -contextSize  => $min_context,
						       -numMatchingFunctionsInContext => $min_matching))
	    {
		print BIN $tuple->id1,"\t",$tuple->id2,"\n";
	    }
	}
    }
}
close(BIN);

sub genome_id {
    my($x) = @_;

    if ($x =~ /^(\d+\.\d+)$/)           { return $1 }
    if ($x =~ /\/(\d+\.\d+)$/)          { return $1 }
    if ($x =~ /.*\b(\d+\.\d+)\b/)       { return $1 }
    die "could not determine the genome id";
}
	
sub generate_corr_table {
    my($wu) = @_;
    my($g1,$g2,$tmpF,$corr) = @$wu;

    if (system("svr_corresponding_genes2 $g1 $g2 > $tmpF") != 0)
    {
	die "$g1 vs $g2 failed [tried to write it to $tmpF]";
    }
    else
    {
	rename($tmpF,$corr);
    }
}
