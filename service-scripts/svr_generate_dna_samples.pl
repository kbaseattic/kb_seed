use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_generate_dna_samples

Create random samples of DNA from known genomes

------

Example:

    echo '83333.1 | svr_generate_dna_samples -n 200 -s 550

would produce a 2-column table.  The first column would contain
the genome ID (83333.1) and the second a 550 bp piece of DNA from the genome.
There would be 200 rows in the table

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the genome for which sequence is  being requested.
If some other column contains the genomes, use

    -c N

where N is the column (from 1) that contains the genome ID in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing genomes is not the last.

=item -s [default: 500]

Size of the requested fragments.

=item -n [number of rows to output for each input genome]

Note that this times the number of input lines gives the number of fragments.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (a fragment of DNA)

=cut

use SeedUtils;
use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_generate_dna_samples [-c column] [-n Fragments] [-s SzOfFragments]";

my $column;
my $n = 1;
my $i = "-";
my $s = 500;
my $rc  = GetOptions('c=i' => \$column, 
		     'n=i' => \$n,
		     's=i' => \$s,
		     'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @ids = map { $_->[0] } @tuples;
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;

        my @frag = &sequence_fragments($sapO,$id,$n,$s);
        foreach my $seq (@frag)
        {
            print "$line\t$seq\n";
        }
    }
}

sub sequence_fragments {
    my($sapO,$g,$n,$s) = @_;

    my $gH = $sapO->genome_contigs(-ids => [$g]);
    my $contig_ids = $gH->{$g};
    my $contigH = $sapO->contig_sequences( -ids => $contig_ids);
    my @seqs = grep { length($_) >= $s } map { $contigH->{$_} } keys(%$contigH);
    my @frag;
    my $N = @seqs;
    for (my $i=0; ($i < $n); $i++)
    {
	my $which = int(rand($N));
	my $sz = length($seqs[$which]);
	my $off = int(rand($sz-$s));
	my $seq = substr($seqs[$which],$off,$s);
	push(@frag,$seq);
    }
    return @frag;
}
