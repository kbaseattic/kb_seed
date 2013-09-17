use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_which_genus_species

Try to identify genus and species of DNA fragments

------

Example:

    echo '83333.1 | svr_which_genus_species -n 200 -s 550 | svr_which_genus_species

would produce a 3-column table.  The first column would contain
the genome ID (83333.1), the second a 550 bp piece of DNA from the genome, and
the third would be the predicted species.  Fragments that could not be
predicted are written to STDERR.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the sequence for which the species is desired.
If some other column contains the fragments, use

    -c N

where N is the column (from 1) that contains the sequence in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing sequences is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (a prediction).  Input that does
not result in a prediction is written to STDERR.

=cut

my $dataD = "/home/overbeek/Ross/KBaseServers/KmerEvaluation/Data";

use SeedUtils;
use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_which_genus_species [-c column] [-n Fragments] [-s SzOfFragments]";

my $column;
my $i = "-";
my $rc  = GetOptions('c=i' => \$column, 
		     'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
open my $ih, "<$i";
my $otuH = &Kmers2013::load_otu_index($dataD);
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @ids = map { $_->[0] } @tuples;
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
        if (my $gs = &predict($id,$otuH))
        {
            print "$line\t$gs\n";
        }
        else
        {
            print STDERR $line,"\n";
        }
    }
}

use Kmers2013;
sub predict {
    my($seq,$otuH) = @_;

    my $attempt = &Kmers2013::check_contig_set([['fragment','',$seq]],$otuH);
    my($called,$unplaced) = @$attempt;
    if (@$called == 0) { return undef }
    return $called->[0]->[3];
}
