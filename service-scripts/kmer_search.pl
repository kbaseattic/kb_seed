
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

ALSO NOTE: The genomes file MUST have the genome ID (number) as the SECOND column.
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
The output depends on whether you have dna or aa.  For

 kmer_search -d Data -a < input.fasta > 4-column.table [id,function,hits,weighted-sc]

----------------
If DNA and genomes are used, the following might apply (I need to recheck things)

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
use Getopt::Long::Descriptive;

my $usage = "usage: kmer_search -d DataDir [-a] [-m MinHits] [-g MaxGap] [-p] [-r RastDirs] [-z] [-s server-host:server-port]\n";

my($opt, $usage) = describe_options("%c %o < input",
				    ["data-dir|d=s" => "kmer data directory"],
				    ["url|u=s" => "kmer server URL"],
				    ["max-gap|g=i" => "maximium gap size", { default => 200 }],
				    ["min-hits|m=i" => "minimum hit count", { default => 5 }],
				    ["pubseed|p" => "use PubSEED"],
				    ["rast-dirs|r=s" => "RAST directories to use for input"],
				    ["a" => "input is amino acid sequences"],
				    ["z" => "compute Z-scores"],
				    ["help|h" => "Show this help message"],
				    [],
				    ["The --data-dir and --server parameters are mutually exclusive; exactly one must be provided"]);

print($usage->text), exit if $opt->help;
print($usage->text), exit 1 if (@ARGV != 0);

my $server_url;
my $dataD;
my $aa = $opt->a;
my $min_hits = $opt->min_hits;
my $max_gap  = $opt->max_gap;
my $use_pub_seed = $opt->pubseed;
my $rast_dirs = $opt->rast_dirs;
my $zscores = $opt->z;
my $search_type;		# "genome" or "properties"

my $kmer_guts;
my @kmer_guts_params = ("-m", $min_hits, "-g", $max_gap);

$dataD = $opt->data_dir;

if (!$dataD)
{
    die "The data directory parameter must be provided\n";
}
    
if (! -d $dataD)
{
    die "Data dir $dataD does not exist\n";
}

if (-s "$dataD/genomes")
{
    $search_type = 'genomes';
}
elsif (-s "$dataD/properties")
{
    $search_type = 'properties';
}
else
{
    die "you need to give a genomes or properties file in $dataD\n$usage";
}

if ($opt->url)
{
    $server_url = $opt->url;

    if ($search_type ne 'genomes')
    {
	die "Server-based search only works for data directory containing genomes (not properties)";
    }

    push(@kmer_guts_params, "--url", $server_url);
    $kmer_guts = "kmer_guts_net";
}
else
{
    push(@kmer_guts_params, "-D", $dataD);
    $kmer_guts = "kmer_guts";
}

if ($dataD && ! -s "$dataD/final.kmers")
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

#
# We only need to set a hash size if we are writing the map.
#
# The size file is written by km_build_Data.
#

if ($dataD && ! -s "$dataD/kmer.table.mem_map")
{

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

    push(@kmer_guts_params, "-w", "-s", $hash_size);
}

push(@kmer_guts_params, "-a") if $aa;

my $command;
my $z = $zscores ? '-z' : '';
if ($search_type eq 'genomes')
{
    if ($aa)
    {
	$command = "$kmer_guts @kmer_guts_params | km_process_hits_to_regions -a -d $dataD $z | km_pick_best_hit_in_peg";
    }
    else
    {
	$command = "$kmer_guts @kmer_guts_params | km_process_hits_to_regions -d $dataD $z";
    }
}
elsif ($search_type eq 'properties')
{
    if ($aa)
    {
	$command = "$kmer_guts @kmer_guts_params | kp_process_hits -d $dataD";
    }
    else
    {
	$command = "$kmer_guts @kmer_guts_params | kp_process_dna_hits -d $dataD";
    }
}
else
{
    die "Invalid search type 'search_type'\n";
}

# print STDERR $command,"\n";
#open(INPUT,'-') || die "could not transer STDIN";
# open(RUN,"| $command") || die "could not open $command";
# while (defined($_ = <INPUT>))
# {
#     print RUN $_;
# }
# close(INPUT);
# close(RUN);

my $rc = system($command);
if ($rc != 0)
{
    print STDERR "Command failed with rc=$rc: $command\n";
    exit $rc;
}
