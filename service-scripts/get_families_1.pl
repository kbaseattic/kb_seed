#
# This is a SAS Component
#

=head1 get_families_1

Run the sequence through kmer annotations

------

Example:

    get_families_1 -d Data.kmers -s Seqs.Fasta < genomes > called 2> missed

This uses a Data.kmer directory built to support kmer_guts processing.
We suggest using the one in pubSEED (Global/Data.kmers).  A set of genomes is read
from STDIN (each line endsin a genome ID, and the genome IDs must
match a filename in Seqs.Fasta.  Each file in Seqs.Fasta is a fasta file of the peg 
translations for a given genome (the ID of the genome must be the filename in
Seqs.Fasta).  The invocation causes all of the sequences for all of the genomes to
be submiited to kmer annotations.  Successfully annotated PEGs produce a line

    PEG function

written to STDOUT.  PEGs that fail to get annotated lead to lines written
to STDERR containing just the PEG id.
------
=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;

my $usage = "usage: get_families_1 -d Data -s Seqs < genomes\n";
my $dataD;
my $seqsD;
my $rc  = GetOptions('d=s' => \$dataD,
                     's=s' => \$seqsD);
if ((! $rc) || (! $dataD) || (! $seqsD))
{ 
    print STDERR $usage; exit ;
}

while (defined(my $seqsF = <STDIN>))
{
    if ($seqsF =~ /(\S+)$/)
    {
	$seqsF = $1;
	my %all = map { ($_ =~ /^>(\S+)/) ? ($1 => 1) : () } `grep ">" '$seqsD/$seqsF'`;
#	open(CALLS,"kmer_search -d $dataD -a < '$seqsD/$seqsF' |");
	open(CALLS,"svr_quick_assign  < '$seqsD/$seqsF' |");
	while (defined($_ = <CALLS>))
	{
	    print $_;
	    if ($_ =~ /^(\S+)/)
	    {
		delete $all{$1};
	    }
	}
	close(CALLS);

	foreach $_ (keys(%all))
	{
	    print STDERR "$_\n";
	}
    }
}

