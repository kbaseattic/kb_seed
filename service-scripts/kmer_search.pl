# This is a SAS component.

########################################################################
=head1 kmer_search

Get functions and OTUs from protein or DNA sequences

------

Example:

    mkdir Data
    svr_all_genomes > Data/genomes
    
    kmer_search -d Data -a < protein-sequences > output.aa
    kmer_search -d Data    < dna.sequences     > output.dna

NOTE: the first few (usually 3) times you run this, it will be very,
very slow.  The first time, it builds the kmers, which will usually
take hours.  The second time It builds a memory map.  The third time
it moves the memory map into cache.  Thereafter, as long as the map
does not drift out of cache, it should run quickly.  

------

The standard input should be a fasta file (use -a for protein sequences; leave
the -a off for DNA sequences.

=head2 Command-Line Options

=over 4

=item -d Data

The Data directory must exist, and it must contain either a 2-column file
named

        Data/genomes

or a 2-column file

        Data/properties

In the case in which a genome file is given,
the first column is the scientific name of the organism, beginning with
genus and species.  The first two words of this field are used to name OTUs
(distinct values are treated as distinct "operational taxonomic units".
The second column must be a genome ID.

If a properties file is given, the second column still must be a valid
genome ID.  The first column must be a property.

=item -a

Implies that the input is amino acid sequences (in fasta format).

=item -m

Minimum number of hits to make a call.  Defaults to 5.

=item -g

Maximum gap between hits in a "run".  Defaults to 200.

=item -p 

Build kmers from PubSEED data

=item -r

Build kmers from a directory, in which each subdirectory is a RAST genome directory

=back

=head2 Output Format

The output is separated into two parts: first we have estimates of OTU 
for each contig.  You get lines like

ContigOrPeg
      Count1    OTU (or set separated by bars)
      Count2    OTU (or set separated by bars)
      .
      .

This section is seprated from the calls by a line containing

     ---------------------

The lines following the separator contain

     contig-or-peg  first-hit last-hit  count  function [strand if not -a ]

Note that you can get multiple hits in the same region.  If you are using -a,
you will probably wish to vote and pick the most likely.

=cut

########
use strict;
use Data::Dumper;
use SeedUtils;
use Getopt::Long;

my $usage = "usage: kmer_search -d DataDir [-a] [-m MinHits] [-g MaxGap] [-p] [-r RastDirs] [-z]\n";
my $dataD;
my $aa = 0;
my $min_hits = 5;
my $max_gap  = 200;
my $use_pub_seed = 0;
my $rast_dirs;
my $zscores = 0;
my $rc  = GetOptions('d=s' => \$dataD,
		     'g=i' => \$max_gap,
                     'm=i' => \$min_hits, 
		     'p'   => \$use_pub_seed,
		     'r=s' => \$rast_dirs,
                     'a'   => \$aa,
                     'z'   => \$zscores);

if ((! $rc) || (! $dataD))
{ 
    print STDERR $usage; exit ;
}
if ((! -s "$dataD/genomes") && (! -s "$dataD/properties"))
{
    die "you need to give a genomes or properties file in $dataD\n$usage";
}

if (! -s "$dataD/final.kmers")
{
    my $which_seed;
    if ($use_pub_seed)
    {
	$which_seed = '-p';
    }
    elsif ($rast_dirs)
    {
	$which_seed = "-r $rast_dirs";
    }
    else
    {
	$which_seed = '';
    }
    &SeedUtils::run("km_build_Data -d $dataD -k 8 $which_seed");
}

my $primes = [3769,6337,12791,24571,51043,101533,206933,400187,
              821999,2000003,4000037,8000009,16000057,32000011,
	      64000031,128000003,248000009,508000037,1073741824,
	      1400303159,2147483648,1190492993,3559786523,6461346257];
open(SZ,"<$dataD/size") || die "could not open $dataD/size";
my $sz = <SZ>;
chomp $sz;
my $i;
# print STDERR "required sz = $sz\n";
for ($i=0; ($i < @$primes) && ($primes->[$i] < (3 * $sz)); $i++) {}
if ($i == @$primes) { die "$sz is too large - adjust the '$primes' above" }
my $hash_size = $primes->[$i];
# print STDERR "hash_size=$hash_size\n";

my $write_mem = '';
if (! -s "$dataD/kmer.table.mem_map")
{
    $write_mem = "-w ";
}
my $command;
my $z = $zscores ? '-z' : '';
if ((-s "$dataD/genomes") && (! $aa))
{
    $command = "kmer_guts -D $dataD $write_mem -s $hash_size -m $min_hits -g $max_gap | km_process_hits_to_regions -d $dataD $z";
}
elsif ((-s "$dataD/genomes") && $aa)
{
    $command = "kmer_guts -D $dataD -a $write_mem -s $hash_size -m $min_hits -g $max_gap | km_process_hits_to_regions -a -d $dataD $z | km_pick_best_hit_in_peg";
}
elsif ((-s "$dataD/properties") && $aa)
{
    $command = "kmer_guts -s $hash_size -D $dataD -a $write_mem -m $min_hits -g $max_gap | kp_process_hits -d $dataD";
}
elsif ((-s "$dataD/properties") && (! $aa))
{
    $command = "kmer_guts -s $hash_size -D $dataD $write_mem -m $min_hits -g $max_gap | kp_process_dna_hits -d $dataD";
}
# print STDERR $command,"\n";
open(INPUT,'-') || die "could not transer STDIN";
open(RUN,"| $command") || die "could not open $command";
while (defined($_ = <INPUT>))
{
    print RUN $_;
}
close(INPUT);
close(RUN);
