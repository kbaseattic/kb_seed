use strict;

use Getopt::Long;
use ScriptThing;
use SAPserver;

#
# This is a SAS Component
#


=head1 svr_fids_for_md5

Output the FIG IDs and functional assignments of all features that produce a
specific protein. This script takes as input a single protein sequence on the
command-line or a FASTA file. It outputs a tab-delimited file connecting each
specified protein to its features.

------
Example:

    svr_find_protein MENIIARRYAKAIASRADINDFYQNLCILNFAFVLPKFKNIIESNEIKKERKMEFLDSFFDIKNSSFQNFLRLLIENSRLECIPQIVKELERQKAFKENIFVGIVYSKEKLSQENLKDLEVKLNKKFDANIKLNNKISQDDSVKIELEELGYELSFSMKALQNKLNEYILKII

or

    svr_find_protein < prots.fasta > fids.tbl
------

=back

=head2 Command-Line Options

=over 4

=item -n

If specified and the protein is provided as a parameter (instead of a FASTA
file provided as input), then the name to be given to the protein in the
output file.

=back

=head2 Output Format

The standard output is a tab-delimited file with four columns: (1) the
protein ID, (2) the FIG ID of a gene that produces the protein, (3) the
name of the genome containing the gene, and (4) the functional assignment of the
gene. There will frequently be multiple features for a single protein.

=cut

use SeedUtils;
use SAPserver;
use Getopt::Long;
use ScriptThing;
use gjoseqlib;
use Digest::MD5;

my $usage = "usage: svr_find_protein [-n name] proteinSequence";

my $name;
my $rc  = GetOptions('n=s' => \$name);
if (! $rc) { print STDERR $usage; exit }
my $sapObject = SAPserver->new();

my $protein = $ARGV[0];

# This list will contain FASTA protein sequence triplets.
my @seqs;
# Are we using a protein from the command line or a FASTA file on the standard
# input?
if ($protein) {
    # Here we have a protein from the command line. Insure we have a name for it.
    if (! $name) {
        $name = "protein1";
    }
    push @seqs, [$name, undef, $protein];
} else {
    # Here we have input via a FASTA file. First, we do a little hack so that we have
    # an option to run in this mode in the debugging environment (where we can't use
    # direct STDIN support).
    ScriptThing::AdjustStdin();
    # Now read the FASTA tripled from the standard input.
    @seqs = gjoseqlib::read_fasta(\*STDIN);
}
# Now we run through the triples in batches of 100, getting the feature IDs.
for (my $i = 0; $i < @seqs; $i += 100) {
    # Get the range of triples in this group.
    my $i2 = $i + 99;
    $i2 = $#seqs if ($i2 > $#seqs);
    # Compute the associated features.
    my $protHash = $sapObject->proteins_to_fids(-prots => [map { $_->[2] } @seqs[$i .. $i2] ]);
    # Now loop through the sequences in this group, writing out the features for each.
    for (my $j = $i; $j <= $i2; $j++) {
        # Get the current triple.
        my ($id, undef, $sequence) = @{$seqs[$j]};
        # Get this sequence's features.
        my $fids = $protHash->{$sequence};
        # Insure we found some.
        if (! $fids || ! @$fids) {
            print STDERR "No genes found for $id.\n";
        } else {
            # Compute the feature assignments.
            my $fidHash = $sapObject->ids_to_data(-ids => $fids,
                                                  -data => ['genome-name', 'function']);
            # Output the features.
            for my $fid (@$fids) {
                print join("\t", $id, $fid, @{$fidHash->{$fid}[0]}) . "\n";
            }
        }
    }
}
# All done.
