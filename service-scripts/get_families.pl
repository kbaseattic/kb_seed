#
# This is a SAS Component
#


=head1 get_families

Generate protein families (of isofunctional homologs) using kmer technology.

------

Example:

    get_families -d Data.kmers -f Families/families -s Seqs.Fasta < genomes > families

This uses a Data.kmer directory built to support kmer_guts processing.
We suggest using the one in pubSEED (Global/Data.kmers).  The invocation causes a
set of "families" files to be generated in the existing Families directory.  They will all
be prefixed with the word "families.".  The final set of protein
families is written to STDOUT.

Seqs.Fasta is a directory that contains protein fasta files.  The file names
must be genome IDs.  Thus, it is assumed that 

    Seqs.Fasta/83333.1

would be the peg translations for E.coli (assuming that you wished E.coli
to be one of the genomes from which families get produced).

The files in Seqs.Fasta used in constructing the families is determined
by the contents of STDIN (each input line contains just a genome ID to be included).
Each included genome must have a corresponding fasta file in Seqs.Fasta.

------

The standard input should be a file of genome IDs (an input line must end in
a genome ID (/\d+\.\d+$/)).  These will be the genomes from which families are constructed.

------

Now, let us summarize the steps used to generate the families.  We go through the following steps:

    1. the script get_families_1.pl runs all of the PEG translations from all of
       the genomes (specified in STDIN) through kmer_search, which uses kmers to attempt
       assignment of function.  Successfully called PEGs are written to tmp.$$.calls.  Those
       that were not assigned a function are written to tmp.$$.missed.

    2. The PEGs in tmp.$$.missed are thn processed using svr_representative_sequences, which
       generates sets based on blast for those kmers not handled by kmer_search.  They are
       all assigned the function "hypothetical protein", and the sets are written to
       families.missed.

    3. Then, we go through the PEGs that were called by kmers (and recorded in tmp.$$.calls).
       This is done by get_families_3.
       We form potential sets as all PEGs assigned the same function.  For each "function-based set"
       we count the number of PEGs from each genome.  If 90% (i.e., the cutoff parameter 
       defines this value, which defaults to 0.9) of the genomes represented
       in the set have only one PEG in the set, the set is considered "good" and written to
       "families.good".  Otherwise, the set is written to tmp.$$.bad.

    4. Now, get_families-4 is used to  process the families written to tmp.$$.bad.
       Note that kmer assignment of function may "group" disparate
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
families.missed are all gathered and renumbered and written to STDOUT..

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

The prefix used when writing files recording subfamilies.

=item -c cutoff used to differntiate between "good" and "bad" "called families"

if a fraction more than "cutoff" genomes in a family have just one PEG,
the family is "good"; else it is "bad", and an attempt will be made to split it.

=item -s Seqs.Fasta

The directory from which the translations of PEGs from each genome are 
used.

=back

=head2 Output Format

Output is written to STDOUT and constitutes the derived protein families (which
include singletons).  An 8-column, tab-separated table is written:

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

=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;
use gjoseqlib;
use File::Temp 'tempdir';


my $usage = "usage: get_families -d Data -s Seqs < genomes\n";
my $dataD;
my $seqsD;
my $matchN = 3;
my $iden = 0.5;
my $families;
my $cutoff = 0.9;  # fraction of members with uniq genomes to be "good"
my $rc  = GetOptions('d=s' => \$dataD,
		     'm=i' => \$matchN,
		     'i=f' => \$iden,
		     'f=s' => \$families,
		     'c=f' => \$cutoff,
                     's=s' => \$seqsD);
if ((! $rc) || (! $dataD) || (! $seqsD) || (! $families))
{ 
    print STDERR $usage; exit ;
}

my $tmpdir = tempdir();

&SeedUtils::run("get_families_1 -d $dataD -s $seqsD > $tmpdir/calls 2> $tmpdir/missed");
&SeedUtils::run("get_families_2 -i $iden -s $seqsD < $tmpdir/missed > $families.missed");
&SeedUtils::run("get_families_3 -c $cutoff < $tmpdir/calls > $families.good 2> $tmpdir/bad");
&SeedUtils::run("get_families_4 -d $dataD -s $seqsD -m $matchN < $tmpdir/bad > $families.bad.fixed");
&SeedUtils::run("get_families_final -f $families -s $seqsD");

unlink("$tmpdir/tmp.$$.missed","$tmpdir/tmp.$$.calls","$tmpdir/tmp.$$.bad");
system("rm", "-r", $tmpdir);

