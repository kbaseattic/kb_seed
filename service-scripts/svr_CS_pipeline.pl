#
# This is a SAS Component
#


=head1 svr_CS_pipeline

Generate data needed to support close-strain analysis.

------

Example:

    mkdir Data.Strep
    svr_CS_pipeline -d Data.Strep -g Streptococus
or
    fill in Data.kmers, rep.genomes and genome.names and use
    svr_CS_pipeline -d Data.Streptococcus
or
    fill in Data.kmers, rep.genomes, genome.names, Seqs, PegLocs, and PegDNA and use
    svr_CS_pipeline -d Data.Streptococcus
or
    fill in Data.kmers, rep.genomes, genome.names, Seqs, PegLocs, PegDNA, families.all  and use
    svr_CS_pipeline -d Data.Streptococcus

=head2 Command-Line Options

=over 4

=item -d Data

This is an extended Data directory (what Bob might call a "close strain workspace").
It includes a Data.kmers directory that is used by kmer_guts to annotate PEGs,
a "rep.genomes" and "genme.names" files that identify the genomes to be included,
s set of derived protein families and a set of derived files used to support
comparative analysis of the genomes.

=item -r Role for representative genomes (defaults to DNA-directed RNA polymerase beta subunit (EC 2.7.7.6)).

=item -i IdentityFraction

This is the fraction used by Gary's representative_sequences when choosing representative genomes

=item -g Genus (required if rep.genomes and genome.names are missing)

=back

=head2 Output Format

Output is added to the extended Data directory.  The key files are

    families.all [the protein families underlying everything]
             FamilyID - an integer
             Function - function assigned to family
             SubFunction - the Function and an integer (SubFunction) together uniquely
                  determine the FamilyID.  Another way to look at it is

                  a) each family is assigned a unique ID and a function
                  b) multiple families can have the same function (consider
                     "hypothetical protein")
                  c) the Function+SubFunction uniquely determine the FamilyID
             PEG
             LengthProt - the length of the translated PEG
             Mean       - the mean length of PEGs in the family
             StdDev     - standard deviation of lengths for family
             Z-sc       - the Z-score associated with the length of this PEG

    labeled.tree [a rooted labeled newick tree]
    readable.tree [an ascii version of labeled.tree]
    placed.events [adjacency shifts placed on the tree]
        Each line describes an event that occurred on an arc.  The format
        used to encode the events is as follows:
             ancestral node
             node   [the event occurred on the arc from the ancestor to the node]
             family:direction [thus, 1206:upstream meand the event occurred as a
                    change of the protein family upstream of family 1206]
             ancestral-adjacency [family:strand of the adjacent family at ancestral node]
             node-adjacency      [family:strand of adjacent family at the child]
    
    where.shifts.occurred [where families were gained/lost on arcs]
        describes where families were gained or lost
             ancestral node
             node (child of ancestor)
             family
             abcestral value
             node value

These are the files that drive the "What Changed?" application.

=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;

my $usage = "usage: svr_CS_pipeline -d DataDir [-g Genus]\n";
my $dataD;
my $genus;
my $role_for_reps = "DNA-directed RNA polymerase beta subunit (EC 2.7.7.6)";
my $iden = 0.99;
my $rc  = GetOptions('d=s' => \$dataD,
		     'r=s' => \$role_for_reps,
		     'i=f' => \$iden,
                     'g=s' => \$genus);

if ((! $rc) || (! -d $dataD))
{ 
    print STDERR $usage; exit ;
}

if ((! $genus) && (! -s "$dataD/genomes") && (! -s "$dataD/rep.genomes"))
{
    if ( ! $genus)
    {
	die "Please give a genus or a genome file and try again\n";
    }
}

if (! -s "$dataD/genomes")
{
    &generate_genomes($dataD,$genus);
}

my %genomes;
my @added;
my @genomes = map { ($_ =~ /(\d+\.\d+)$/) ? $1 : () } `cat $dataD/genomes`;
if (! -s "$dataD/rep.genomes")
{
    if (@genomes > 80)
    {
	if (! -s "$dataD/role.fasta.for.getting.reps")
	{
	    &SeedUtils::run("cut -f2 $dataD/genomes > tmp1.$$; echo '$role_for_reps' | svr_role_to_pegs -g tmp1.$$ | cut -f2 | svr_fasta -protein -fasta > $dataD/role.fasta.for.getting.reps");
	    unlink "tmp1.$$";
	}

	&SeedUtils::run("svr_representative_sequences -s $iden -b -f $dataD/representatives < $dataD/role.fasta.for.getting.reps > $dataD/representatives.fasta");
	%genomes = map { ($_ =~ /(\d+\.\d+)/) ? ($1 => 1) : () } `cut -f1 $dataD/representatives`;
	if  (keys(%genomes) < 30)
	{
	    my @random = &randomize(\@genomes);
	    for (my $i=0; ($i < @random) && ($i < 40); $i++)
	    {
		$genomes{$random[$i]} = 1;
	    }
	    @genomes = keys(%genomes);
	}
    }

    if (-s "$dataD/added.genomes")
    {
	@added = map { ($_ = /(\d+\.\d+)/) ? $1 : () } `cat $dataD/added.genomes`;
    }
    open(REP,">$dataD/rep.genomes") || die "could not open $dataD/rep.genomes";
    my %with_added = map { ($_ => 1) } (@genomes,@added);
    foreach $_ (sort { $a <=> $b } keys(%with_added))
    {
	print REP $_,"\n";
    }
    close(REP);
}
&SeedUtils::run("svr_genome_statistics name < $dataD/rep.genomes > $dataD/genome.names");

my @genomes = map { chomp; $_ } `cat $dataD/rep.genomes`;
mkdir("$dataD/Seqs",0777);
mkdir("$dataD/PegDNA",0777);
mkdir("$dataD/PegLocs",0777);
foreach my $g (@genomes)
{
    if (! -s "$dataD/Seqs/$g")
    {
	&SeedUtils::run("echo $g | svr_all_features peg | svr_fasta -fasta -protein > $dataD/Seqs/$g");
    }
    if (! -s "$dataD/PegDNA/$g")
    {
	&SeedUtils::run("echo $g | svr_all_features peg | upstream plus=10000 > $dataD/PegDNA/$g");
    }
    if (! -s "$dataD/PegLocs/$g")
    {
	&SeedUtils::run("echo $g | svr_all_features peg | svr_location_of > $dataD/PegLocs/$g");
    }
}

if (! -s "$dataD/families.all")
{
    &SeedUtils::run("get_families -d $dataD/Data.kmers -s $dataD/Seqs -f $dataD/families < $dataD/rep.genomes > $dataD/families.all");
}

if (! -s "$dataD/FastaForPhylogeny/Fasta/1")
{
    &SeedUtils::run("CS_build_fasta_for_phylogeny -d $dataD");
}
if (! -s "$dataD/estimated.phylogeny.nwk")
{
    &SeedUtils::run("pg_build_newick_tree -d $dataD");

    my @labels = map { ($_ =~ /(\d+\.\d+)\t(\S.*\S)$/) ? "$1\t$1: $2" : ()  } `cat $dataD/rep.genomes | svr_genome_statistics name`;
    open(LABELS,">tmp$$.labels") || die "could not open tmp$$.labels";
    foreach $_ (@labels)
    {
	print LABELS "$_\n";
    }
    close(LABELS);
    &SeedUtils::run("svr_reroot_tree -m < $dataD/estimated.phylogeny.nwk | label_all_nodes > $dataD/labeled.tree");
    &SeedUtils::run("sketch_tree -a -l tmp$$.labels  < $dataD/labeled.tree > $dataD/readable.tree");
    unlink("tmp$$.labels");
}


if (! -s "$dataD/families.on.tree")
{
    open(ONTREE,">$dataD/tmp.prop.$$")
	|| die "could not open $dataD/tmp.prop.$$";
    my @fams = map { ($_ =~ /^(\d+)\tfig\|(\d+\.\d+)/) ? [$1,$2] : () } `cut -f1,4 $dataD/families.all`;
#   @fams is a list of 2-tuples: [fam,genome]  There may be duplicates

    my %genomes = map { ($_->[1] => 1) } @fams;
    my @genomes = keys(%genomes);
    my $last = shift @fams;
    while ($last)
    {
	my $fam = $last->[0];
	my %has;
	while ($last && ($last->[0] == $fam))
	{
	    $has{$last->[1]} = 1;
	    $last = shift @fams;
	}
	foreach my $g (@genomes)
	{
	    print ONTREE join("\t",($fam,$g,($has{$g} ? 1 : 0))),"\n";
	}
    }
    close(ONTREE);
    &SeedUtils::run("place_properties_on_tree -t $dataD/labeled.tree -p $dataD/tmp.prop.$$ -e $dataD/families.on.tree");
    unlink("$dataD/tmp.prop.$$");
    &SeedUtils::run("where_shifts_occurred  -t $dataD/labeled.tree -e $dataD/families.on.tree > $dataD/where.shifts.occurred");
}

if (! -s "$dataD/coupled.families")
{
    &SeedUtils::run("CS_compute_coupling -d $dataD");
}

if (! -s "$dataD/placed.events")
{
    &SeedUtils::run("cs_adjacency_data -d $dataD");
}

sub generate_genomes {
    my($dataD,$genus) = @_;

    my @poss = map { (($_ =~ /^(\S+).*\t(\d+\.\d+)$/) && ($1 eq $genus)) ? $_ : () } 
               grep { $_ !~ /phage/i }
               `svr_all_genomes -complete -prokaryotic`;
    open(GENOMES,">$dataD/genomes") || die "could not open $dataD/genomes";
    foreach $_ (@poss)
    {
	print  GENOMES $_;
    }
    close(GENOMES);
}

use List::Util qw(shuffle);
sub randomize {
    my($list) = @_;
    my @random = &shuffle(@$list);
    return @random;
}
