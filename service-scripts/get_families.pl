#
# This is a SAS Component
#


=head1 get_families

Generate protein families (of isofunctional homologs) using kmer technology.

------

Example:

    get_families -d Data.kmers -f Families/families -s Seqs.Fasta < genomes

This uses a Data.kmer directory built to support kmer_guts processing.
We suggest using the one in pubSEED (Global/Data.kmers).  The invocation causes a
set of "families" files to be generated in the existing Families directory.  They will all
be prefixed with the word "famies.".  "families.all" will be the final set of protein
families.

Seqs.Fasta is a directory that contains protein fasta files.  The file names
must be pubSEED genome IDs.  Thus, it is assumed that 

    Seqs.Fasta/83333.1

would be the peg translations for E.coli (assuming that you wished E.coli
to be one of the genomes from which families get produced).

The files in Seqs.Fast used in constructing the families is determined
by the contents of STDIN (each input line contains just a genome ID to be included.
Each included genome must have a corresponding fasta file in Seqs.Fasta.

------

The standard input should be a file of genome IDs (an input line must end in
a genome ID (/\d+\.\d+$/)).  These will be the genomes from which families are constructed.

------

Now, let us summarize the steps used to generate the families.  We go through the following steps:

    1. the script get_families_1.pl runs all of the PEG translations from all of
       the genomes (specified in STDIN) through kmer_search, which uses kmers to attempt
       assignment of function.  Successfully called PEGs are written to tmp.calls.  Those
       that were not assigned a function are written to tmp.missed.

    2. The PEGs in tmp.missed are thn processed using svr_representative_sequences, which
       generates sets based on blast for those kmers not handled by kmer_search.  They are
       all assigned the function "hypothetical protein", and the sets are written to
       families.missed.

    3. Then, we go through the PEGs that were called by kmers (and recorded in tmp.calls).
       This is done by get_families_3.
       We form potential sets as all PEGs assigned the same function.  For each "function-based set"
       we count the number of PEGs from each genome.  If 90% of the genomes represented
       in the set have only one PEG in the set, the set is considered "good" and written to
       "families.good".  Otherwise, the set is written to tmp.bad.

    4. Now, get_families-4 is used to  process the families written to tmp.bad.
       Note that kmer assignment of function by "group" disparate
       sequences into a single function.  If the manual assignments of
       function upon which the kmers were derived correctly assigned
       one set of sequences to a function F and incorrectly assigned a
       second set to function F, then sequences that get assigned a
       sequence F by kmers may have gotten the assignment due to signature
       kmers from either of 2 distinct sets.  For that matter, if two
       non-homologous classes of sequences both have proteins with a
       common function (due to non-orthologous replacement), you will
       have distinct kmers that produce a common call, and there may
       legitimately be multiple instances of the function in a single
       genome. 

       Anyway, for each set we wish to split, we compute the kmers
       that are associated with each peg in the set.  Then, we sort
       the pegs in the set based on the number of kmers that hit each
       peg.  Then, we make passes through the sorted set of pegs,
       seeding a new set and adding pegs that share at least MatchN
       common kmers (we set MatchN to 3, usually).  Each pass induces
       a new set written to families.bad.fixed (possibly singletons).

Finally, the sets from families.good, families.bad.fixed, and
families.missed are all gathered and renumbered into families.all.

=head2 Command-Line Options

=over 4

=item -d Data

This is a Data directory usable by kmer_guts.  I suggest using the one in
the Global directory (FIGfisk/FIG/Data/Global/Data.kmers).

=item -m MatchN

During one step, families that may need to be split use an algorithm in which
two PEGs are kept in the same family iff they share at least MatchN kmers (see above)

=item -i IdentityFraction

This is the fraction used by Gary's representative_sequences when forming families
of the sequences left uncalled by kmers (see above)

=item -f FamilyFilesPrefix

The prefix used when writing files recording subfamilies (and the final
families.all)

=item -s Seqs.Fasta

The directory from which the translations of PEGs from each genome are 
used.

=back

=head2 Output Format

Output is writen to a set of files with the prefix specified in the -f parameter.
Assuming 

    -f Families/families

were specified, you would get

    Families/families.good
    Families/families.bad.fixed
    Families/families.missed     - families formed from PEGs that could not be assigned functions using kmers
    Families/families.all

=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;
use gjoseqlib;


my $usage = "usage: get_families -d Data -s Seqs < genomes\n";
my $dataD;
my $seqsD;
my $matchN = 3;
my $iden = 50;
my $families;
my $rc  = GetOptions('d=s' => \$dataD,
		     'm=i' => \$matchN,
		     'i=i' => \$iden,
		     'f=s' => \$families,
                     's=s' => \$seqsD);
if ((! $rc) || (! $dataD) || (! $seqsD) || (! $families))
{ 
    print STDERR $usage; exit ;
}

&SeedUtils::run("get_families_1 -d $dataD -s $seqsD > tmp.calls 2> tmp.missed");
print STDERR "got1\n";
&SeedUtils::run("get_families_2 -i $iden -s $seqsD < tmp.missed > $families.missed");
print STDERR "got2\n";
&SeedUtils::run("get_families_3 -i $iden -s $seqsD < tmp.calls > $families.good 2> tmp.bad");
print STDERR "got3\n";
&SeedUtils::run("get_families_4 -d $dataD -s $seqsD < tmp.bad > $families.bad.fixed");
&SeedUtils::run("get_families_final -f $families -s $seqsD > $families.all");
# unlink("tmp.missed","tmp.calls","tmp.bad");

