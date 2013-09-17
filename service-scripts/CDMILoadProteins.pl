    use strict;
    use Stats;
    use SeedUtils;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;


=head1 CDMI Proteins Loader

    CDMILoadProteins [options] protein_fasta

This script loads the protein sequences from a protein fasta file.
The identifiers in the file should be MD5 protein identifiers.

The following table is loaded.

=over 4

=item ProteinSequence

Describes the amino acids in a protein.

=back

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.
There is a single positional parameter: the name of a protein FASTA file.
If it is omitted, the standard input is used.

=cut

# Prevent buffering on STDOUT.
$| = 1;

# Connect to the database using the command-line options.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMILoadProteins [options] fasta_file\n";
} else {
    # Get a CDMI loader.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # This will be used to display progress.
    my $count = 0;
    # Verify the input file. If no input file is specified, we use the
    # standard input.
    my $ih;
    my $fastaFile = $ARGV[0];
    if (! $fastaFile) {
        print "FASTA data taken from standard input.\n";
        $ih = \*STDIN;
    } elsif (! -f $fastaFile) {
        die "Could not find input file $fastaFile.\n";
    } else {
        open($ih, "<$fastaFile") || die "Could not open input file: $!\n";
    }
    # Read the first protein identifier.
    my $line = <$ih>;
    if (! $line) {
        die "No data found in file.\n";
    } elsif ($line !~ /^>(\S+)/){
        die "Invalid FASTA header line.\n";
    } else {
        my $protein = $1;
        # Loop through the input.
        while ($protein) {
            # Get the sequence and the next identifier.
            my ($sequence, $nextProtein) = $loader->ReadFastaRecord($ih);
            $stats->Add(sequenceIn => 1);
            # Insure this protein is in the database.
            my $created = $loader->InsureEntity(ProteinSequence => $protein,
                    sequence => $sequence);
            if ($created) {
                $stats->Add(newProtein => 1);
            } else {
                $stats->Add(oldProtein => 1);
            }
            # Set up for the next loop iteration.
            $count++;
            if ($count % 5000 == 0) {
                print "$count proteins processed, " . $stats->Ask("newProtein") . " new.\n";
            }
            $protein = $nextProtein;
        }
    }
    print "All done:\n" . $stats->Show();
}