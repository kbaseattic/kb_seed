#!/usr/bin/perl -w

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#

    use strict;
    use Stats;
    use SeedUtils;
    use CDMI;
    use CDMILoader;

=head1 CDMI Coupling Loader

    CDMILoadCoupling [options] dumpDirectory outDirectory

This script loads the coupling data from a Sapling database dump. The dump files
are read in and the feature IDs converted from FIG IDs to KBase IDs. Only
features for genomes found in the KBase CDMI will be included in the
output. The output files are then loaded into the KBase CDMI. The following
tables are affected.

=over 4

=item Pairing

a pair of physically close features

=item IsInPair

relationship from features to pairings

=item PairSet

a precomputed set of pairs of genes

=item IsDeterminedBy

relationship from pairings to pairsets

=back

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<CDMI/new_for_script> plus
the following.

=over 4

=item loadOnly

Load the tables from pre-existing load files rather than by creating
them from Sapling dump files.

=back

There are two positional parameters: the name of the directory containing
the dump files from the Sapling and the name of the directory to contain
the load files produced by this script. The files all have the same name as
the corresponding relation with a suffix of C<.dtx>.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my $loadOnly;
my $cdmi = CDMI->new_for_script(loadOnly => \$loadOnly);
if (! $cdmi) {
    print "usage: CDMILoadCoupling [options] dumpDirectory outDirectory\n";
} else {
    # Create the loader object.
    my $loader = CDMILoader->new($cdmi);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Get the directories.
    my ($dumpDirectory, $outDirectory) = @ARGV;
    # Insure they're valid.
    if (! $dumpDirectory) {
        die "Missing input directory.\n";
    } elsif (! -d $dumpDirectory) {
        die "Invalid input directory $dumpDirectory.\n";
    } elsif (! $outDirectory) {
        die "Missing output directory.\n";
    } elsif (! -d $outDirectory) {
        die "Invalid output directory $outDirectory.\n";
    } else {
        # Do we need to create the load files?
        if (! $loadOnly) {
            # Yes. Get the list of SEED genomes in the CDMI. This will be our input filter.
            my %genomes = map { $_ => 1 } $cdmi->GetFlat('Submitted Genome', 'Submitted(from-link) = ?',
                    ['SEED'], 'Genome(source-id)');
            # Start with the pairings. We build the IsPairOf output file at the same
            # time.
            my ($ih, $oh, $ph);
            open($ih, "<$dumpDirectory/Pairing.dtx") || die "Could not open Pairing.dtx: $!\n";
            open($oh, ">$outDirectory/Pairing.dtx") || die "Could not open Pairing output: $!\n";
            open($ph, ">$outDirectory/IsInPair.dtx") || die "Could not open IsPairOf output: $!\n";
            print "Reading Pairing file.\n";
            # Loop through the pairings in the file.
            while (! eof $ih) {
                my ($pairing) = $loader->GetLine($ih);
                $stats->Add(pairingIn => 1);
                # Compute the new pairing key.
                my ($newKey, $inverted) = compute_pair_key($loader, $pairing, \%genomes);
                # If we're keeping it, output it to the new file and create its
                # IsInPair relationships.
                if (defined $newKey) {
                    print $oh "$newKey\n";
                    $stats->Add(pairingOut => 1);
                    my @newFids = split /:/, $newKey;
                    for my $newFid (@newFids) {
                        print $ph join("\t", $newFid, $newKey) . "\n";
                        $stats->Add(isInPairOut => 1);
                    }
                }
            }
            # Close all three files.
            close $ih; undef $ih;
            close $oh; undef $oh;
            close $ph; undef $ph;
            # Read through the IsDeterminedBy file. We will write it out and produce
            # a hash of the pair sets we need to keep (and their new IDs).
            my %pairSets;
            open($ih, "<$dumpDirectory/IsDeterminedBy.dtx") || die "Could not open IsDeterminedBy.dtx: $!\n";
            open($oh, ">$outDirectory/IsDeterminedBy.dtx") || die "Could not open IsDeterminedBy output: $!\n";
            print "Reading IsDeterminedBy file.\n";
            while (! eof $ih) {
                my ($set, $pairing, $inverted) = $loader->GetLine($ih);
                $stats->Add(isDeterminedByIn => 1);
                # Compute the new ID for the pairing.
                my ($newPairing, $newInverted) = compute_pair_key($loader, $pairing, \%genomes);
                if (defined $newPairing) {
                    # Here we are keeping the pair. That means we also want to keep
                    # the pairset. Insure we have the set's key.
                    my $newSet = $pairSets{$set};
                    if (! $newSet) {
                        $newSet = "pset$set";
                        $pairSets{$set} = $newSet;
                        $stats->Add(keptPairSet => 1);
                    }
                    # If the pair key is inverted, flip the relationship's
                    # inversion flag.
                    if ($newInverted) {
                        $inverted = ($inverted ? 0 : 1);
                        $stats->Add(invertFlip => 1);
                    }
                    # Output the relationship.
                    print $oh join("\t", $newSet, $newPairing, $inverted) . "\n";
                    $stats->Add(IsDeterminedByOut => 1);
                }
            }
            # Close the files.
            close $oh; undef $oh;
            close $ih; undef $ih;
            # Now we process the PairSet file.
            open ($ih, "<$dumpDirectory/PairSet.dtx") || die "Could not open PairSet.dtx: $!\n";
            open ($oh, ">$outDirectory/PairSet.dtx") || die "Could not open PairSet output: $!\n";
            print "Reading PairSet file.\n";
            while (! eof $ih) {
                my ($set, $score) = $loader->GetLine($ih);
                $stats->Add(pairSetIn => 1);
                # Are we keeping this set?
                if ($pairSets{$set}) {
                    # Yes. Write it out with its new key.
                    print $oh join("\t", $pairSets{$set}, $score) . "\n";
                    $stats->Add(pairSetOut => 1);
                }
            }
            # Close the files.
            close $oh; undef $oh;
            close $ih; undef $ih;
        }
        # Load the tables.
        for my $table (qw(PairSet Pairing IsInPair IsDeterminedBy)) {
            print "Loading $table.\n";
            $cdmi->CreateTable($table, 1);
            my $newStats = $cdmi->LoadTable("$outDirectory/$table.dtx", $table);
            $stats->Accumulate($newStats);
        }
    }
    print "All done:\n" . $stats->Show();
}

=head2 Subroutines

=head3 compute_pair_key

    my ($newKey, $inverted) = compute_pair_key($loader, $oldKey, \%genomes);

Parse a pairing key and compute the equivalent KBase key. If one or
both of the pair elements aren't in genomes from the incoming hash,
an undefined result will be returned, indicating that the pairing key
does not belong in the database. If the result pairing key is inverted
from the original, that is indicated in the return.

=over 4

=item loader

L<CDMILoader> object for this load.

=item oldKey

Key of the pairing in the Sapling. This is formed from the two FIG
feature IDs concatenated with an intervening colon.

=item genomes

Reference to a hash whose keys are the FIG IDs of the genomes in the
KBase CDMI and whose values evaluate to TRUE.

=item RETURN

Returns a two-element list containing the appropriate KBase ID for the
pairing followed by FALSE if the KBase ID is in the same order as the
Sapling ID and TRUE if it is inverted. The first element will be
C<undef> if either feature in the pairing does not belong in the CDMI.

=back

=cut

sub compute_pair_key {
    # Get the parameters.
    my ($loader, $oldKey, $genomes) = @_;
    # Declare the return variables.
    my ($newKey, $inverted) = (undef, 0);
    # Split the old key into the two features.
    my ($fid1, $fid2) = split /:/, $oldKey;
    # Get the relevant genomes.
    my $genome1 = genome_of($fid1);
    my $genome2 = genome_of($fid2);
    # Only proceed if they're both in the CDMI.
    if ($genomes->{$genome1} && $genomes->{$genome2}) {
        # Get the KBase IDs of the features in the order they should
        # appear in the output key.
        my $fidHash = $loader->FindKBaseIDs('SEED', [$fid1, $fid2]);
        my @newFids = sort values %$fidHash;
        # Record whether or not they are flipped.
        $inverted = ($newFids[0] ne $fidHash->{$fid1});
        # Form the new key.
        $newKey = join(":", @newFids);
    }
    # Return the result.
    return ($newKey, $inverted);
}

