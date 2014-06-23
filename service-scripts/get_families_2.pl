#
# This is a SAS Component
#

=head1 get_families_2 -i 0.5 -s Seqs.Fasta < missed > missed.families

This step takes the set of PEGs for which no assignments were made and clusters
them using

    svr_representative_sequences

Note that the -i parameter takes a fraction between 0 and 1.



=head2 Command-Line Options

=over 4

=item -i IdentityFraction

This is the fraction used by Gary's representative_sequences when forming families
of the sequences left uncalled by kmers (see above).  We default the value to 0.5.

=item -s Seqs.Fasta

The directory from which the translations of PEGs for each genome are 
used.

=back

=head2 Output Format

The output is a 3-column, tab-separated table:

    function (always "hypothetical protein")
    a set # (just an integer acting as an id of the set)
    a PEG

=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use gjoseqlib;
use SeedEnv;
use File::Temp 'tempfile';

my $usage = "usage: get_families_2 -s Seqs < non_hits > non_hit_families\n";
my $seqsD;
my $iden = 0.5;
my $rc  = GetOptions('s=s' => \$seqsD,
                     'i=f' => \$iden);
if ((! $rc) || (! $seqsD))
{ 
    print STDERR $usage; exit ;
}

my %genomes;
my %needed_pegs;

my $peg;
while (defined($peg = <STDIN>))
{
    chomp $peg;
    my $g = &SeedUtils::genome_of($peg);
    $genomes{$g} = 1;
    $needed_pegs{$peg} = 1;
}

my($reps_fh, $reps_file) = tempfile();

foreach my $g (keys(%genomes))
{
    my @tuples = grep { $needed_pegs{$_->[0]} } &read_fasta("$seqsD/$g");
    foreach my $tuple (@tuples)
    {
	my($peg,undef,$seq) = @$tuple;
	print $reps_fh ">$peg\n$seq\n";
    }
}
close($reps_fh);

my($fams_fh, $fams_file) = tempfile();
close($fams_fh);

&SeedUtils::run("svr_representative_sequences -s $iden -b -f $fams_file > /dev/null < $reps_file");
my $n = 1;
foreach my $fam (`cat $fams_file`)
{
    chomp $fam;
    foreach $_ (split(/\t/,$fam))
    {
	print join("\t",("hypothetical protein",$n,$_)),"\n";
    }
    $n++;
}

unlink($fams_file, $reps_file);
