use strict;
use Data::Dumper;
use SeedEnv;
use Getopt::Long;

#
# This is a SAS Component
#

=head1 svr_get_rep_genomes

Get a set of representative genomes using heuristics and the NCBI taxonomy


------

Example:

    svr_get_rep_genomes -n 80 -f taxonomies -t Proteobacteria -c 1 -m 2000000

would produce a 5-column table.  The first column would contain
KBase IDs for the selected genomes, the second column would have the SEED ID,
the third column is the size of the genome, the fourth column is the number of
contigs, and the fifth is the NCBI taxonomy.  

    -n says "get 80 genomes"
    -f taxonomies indicates a file that should contain the NCBI taxonomies (built
          by running this program with the name of a file that does not exist, 
          causing the program to build it)
    -t Proteobacteria says "get the 80 genomes from the taxonomic grouping Proteobacteria"
    -c 1 says "give me only genomes with a single contig"
    -m 2000000 says "get only genomes that are at least 2M in size

------

=head2 Command-Line Options

=over 4

=item -k File [name of file containing already selected genomes]

=item -n N [the number of genomes being requested - default is 100]

You may or may not get exactly that number

=item -f tax-file [a file in which taxonomies have been cached]

If the file does not exist, running the program builds it (and it may take a few minutes).

=item -t [taxonomic group - default is 'Bacteria']

Scan the tax-file if you are not sure of the NCBI names of taxonomic groups

=item -c Max-Contigs

=item -m Min-DNA-size

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the following fields:

      the KBase ID of a selected genome
      the SEED ID of a selected genome
      the size of the genome (in bp)
      the number of contigs in the genome
      a representation of the NCBI taxonomy with consecutive groups separated by ": "

=cut


my $usage = "usage:  svr_get_rep_genomes -n N -f taxonomies-file [-t Taxo] [-k GenomeFile ] [-c MaxContigs] [-m MinSize]  > genome.IDs\n";

my($tax,$gfile,$taxF);
my $n = 100;
my $tax = "Bacteria";
my $min_sz = 1000000;
my $max_contigs = 30;

my $rc  = GetOptions('n=i' => \$n, 
		     'm=i' => \$min_sz, 
		     'c=i' => \$max_contigs, 
		     'k=s'  => \$gfile,
		     'f=s'  => \$taxF,
		     't=s' => \$tax);
if ((! $rc) || (! $taxF) || (! $n)) { print STDERR $usage; exit }

my %keep;
if (-s $gfile)
{
    %keep = map { ($_ =~ /\b(kb\|g\.\d+)\b/) ? ($1 => 1) : () } `cat $gfile`;
}

if (! -s $taxF)
{

    my %seed_genomes = map { ($_ =~ /^(\S+)/) ? ($1 => 1) : () }
			     `all_entities_Genome | get_relationship_WasSubmittedBy -rel to_link | grep SEED`;
    my @taxL =  grep { $_ !~ /plasmid|phage|virus/i }
                grep { $_ !~ / sp\.?\t/i }
                grep { $_ =~ /Archaea|Bacteria/ }
                `query_entity_Genome -is 'complete,1' -f source_id,dna_size,contigs | genomes_to_taxonomies -c 1 2> stderr`;
    open(TAXF,">$taxF") || die "could not open $taxF";
    foreach $_ (grep { (($_ =~ /^(\S+)/) && $seed_genomes{$1}) } @taxL) 
    { 
	print TAXF $_;
    }
    close(TAXF);
}

my %gdataH = map { ($_ =~ /^(kb\|g\.\d+)\t(\S.*\S)/) ? ($1,[split(/\t/,$2)]) : () } `cat $taxF`;

my @close;
my @all;

foreach my $g (sort { $a <=> $b } keys(%gdataH))
{
    my($source_id,$dna_sz,$contigs,$phylo) = @{$gdataH{$g}};
    next if (($dna_sz < $min_sz) || ($contigs > $max_contigs));
    my @phyloL = split(/: /,$phylo);
    my $i;
    for ($i=0; ($i < @phyloL) && ($phyloL[$i] ne $tax); $i++) {}
    if ($i < @phyloL)
    {
	if ($i > 0)
	{
	    splice(@phyloL,0,$i+1);
	}
	push(@all,[$g,[@phyloL]]);
    }
}

my $tree = &build_tree(\@all);
my $got = 0;
my $tries = 0;
while (($got < $n) && ($tries < 5))
{
    $got += &pick($tree,\%keep,$n+1-$got);
    $tries++;
}
print STDERR "picked $got\n";
foreach my $g (keys(%keep))
{
    print join("\t",($g,@{$gdataH{$g}})),"\n";
}

sub pick {
    my($tree,$picked,$n) = @_;

#    print "picking $n from ",&Dumper($tree);
    my $tot = 0;
    my @nodes = keys(%$tree);
    while (my $node = shift @nodes)
    {
	my $left = @nodes + 1;
	my $seek = int(($n/$left) + 0.5);
	if ($seek > 0)
	{
#	    print "node=$node seek=$seek left=$left\n";
	    if ($tree->{$node} eq 'leaf')
	    {
		if (! $picked->{$node})
		{
#		    print "picked $node\n";
		    $picked->{$node} = 1;
		    $n--;
		    $tot++;
		}
	    }
	    else
	    {
		my $got = &pick($tree->{$node},$picked,$seek);
		$n -= $got;
		$tot += $got;
	    }
	}
    }
    return $tot;
}
    

sub build_tree {
    my($all) = @_;

    my $tree = {};
    foreach my $tuple (@$all)
    {
	&add_to_tree($tree,$tuple);
    }
    return $tree;
}

sub add_to_tree {
    my($tree,$tuple) = @_;

    my($g,$phylo) = @$tuple;
    foreach my $label (@$phylo)
    {
	if (! $tree->{$label})
	{
	    $tree->{$label} = {};
	}
	$tree = $tree->{$label};
    }
    $tree->{$g} = 'leaf';
}
