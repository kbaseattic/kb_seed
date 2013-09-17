use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use gjoseqlib;
use SeedEnv;

my $usage = "usage: CSA_make_contig_index Index GenomeID < contigs > renamed.contigs\n";

my($indexF,$genomeID);
(
  ($indexF   = shift @ARGV) &&
  ($genomeID = shift @ARGV)
)
    || die $usage;

open(INDEX,">",$indexF) || die "could not open $indexF";

my @contigs = &gjoseqlib::read_fasta;
my $i;
for ($i=0; ($i < @contigs); $i++)
{
    my $id = "$genomeID:" . ($i+1);
    print INDEX join("\t",$id,$contigs[$i]->[0]),"\n";
    print ">$id\n$contigs[$i]->[2]\n";
}
close(INDEX);
 
