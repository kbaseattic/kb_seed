#
# This is a SAS Component
#


=head1 get_families_final

Generate protein families (of isofunctional homologs) using kmer technology.

------

Example:

    get_families_final -f Families/families -s Seqs.Fasta

This simple program gathers the families from 

    good families (those which were assigned funtions and usually have a unique PEG)
    bad.fixed families (those assigned a function and then subjected to a splitting test)
    missed  (those families of PEGs with no assigned functions and clustered by similarity)

and builds families.all, the final set of families.

=head2 Command-Line Options

=over 4

=item -f FamilyFilesPrefix

The prefix used when writing files recording subfamilies (and the final
families.all)

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
use gjostat;

my $usage = "usage: get_families_final -f families -s Seq\n";
my $families;
my $seqD;
my $rc  = GetOptions('f=s' => \$families,
                     's=s' => \$seqD);

if ((! $rc) || (! $families) || (! $seqD))
{ 
    print STDERR $usage; exit ;
}

open(IN,"cat $families.good $families.bad.fixed $families.missed |")
    || die "could not read families";

my %genomes;
my %needed_pegs;

while (defined($_ = <IN>))
{
    chomp;
    my(undef,undef,$peg) = split(/\t/,$_);
    my $g = &SeedUtils::genome_of($peg);
    $genomes{$g} = 1;
    $needed_pegs{$peg} = 1;
}
close(IN);
my %to_seq;
foreach my $g (keys(%genomes))
{
    my @tuples = grep { $needed_pegs{$_->[0]} } &gjoseqlib::read_fasta("$seqD/$g");
    foreach my $tuple (@tuples)
    {
	my($peg,undef,$seq) = @$tuple;
	$to_seq{$peg} = $seq;
    }
}

open(FAMS,"cat $families.good $families.bad.fixed $families.missed |")
    || die "could not open families";

my @sets;
my $last = <FAMS>;
while ($last && ($last =~ /^(\S[^\t]*)\t(\d+)\t(\S+)/))
{
    my $fam = $1;
    my $subfam = $2;
    my @set;
    while ($last && ($last =~ /^(\S[^\t]*\S)\t(\d+)\t(\S+)/) && ($fam eq $1) && ($subfam == $2))
    {
	push(@set,[$1,$2,$3]);
	$last = <FAMS>;
    }
    push(@sets,\@set);
}
if ($last) { die "POORLY FORMATTED FAMILY: CHECK $last" }
my $famN = 1;
foreach my $set (sort { (@$b <=> @$a) or 
			($a->[0] cmp $b->[0]) or
		        ($a->[1] <=> $b->[1])
		      } @sets)
{
    my @lens;
    foreach my $tuple (@$set)
    {
	my $ln = length($to_seq{$tuple->[2]});
	push(@lens,$ln);
    }
    my($mean,$std_dev) = &mean_stddev(@lens);

    foreach my $tuple (@$set)
    {
	my($fam,$subfam,$peg) = @$tuple;
	my $ln = length($to_seq{$peg});
	if (! $ln) { print STDERR &Dumper($peg,$to_seq{$peg}); die "HERE"; }
	my $z_sc = ($ln - $mean) / ($std_dev + 0.000000001);
	print join("\t",($famN,$fam,$subfam,$peg,$ln,sprintf("%0.3f",$mean),sprintf("%0.3f",$std_dev),sprintf("%0.3f",$z_sc))),"\n";
    }
    $famN++;
}

sub mean_stddev
{
    my $n = @_;
    return $n ? ( shift, undef) : ( undef, undef ) if $n < 2;
    my ( $sum, $sum2 ) = ( 0, 0 );
    foreach ( @_ ) { $sum += $_; $sum2 += $_ * $_ }
    my $x = $sum / $n;
    my $to_check = ( $sum2 - ($n * $x * $x )) / ( $n - 1 );
    ( $x, ($to_check > 0) ? sqrt($to_check) : 0);
}
