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
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;

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

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
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
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(loadOnly => \$loadOnly);
if (! $cdmi) {
    print "usage: CDMILoadCoupling [options] dumpDirectory outDirectory\n";
} else {
    # Create the loader object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetSource('SEED');
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
            my %genomes = map { $_ => 1 } $cdmi->GetFlat('Submitted Genome', 'Submitted(from_link) = ?',
                    ['SEED'], 'Genome(source_id)');
            # Start with the pairings. We build the IsPairOf output file at the same
            # time.
            my ($ih, $oh, $ph);
            open($ih, "<$dumpDirectory/Pairing.dtx") || die "Could not open Pairing.dtx: $!\n";
            open($oh, ">$outDirectory/Pairing.dtx") || die "Could not open Pairing output: $!\n";
            open($ph, ">$outDirectory/IsInPair.dtx") || die "Could not open IsPairOf output: $!\n";
            print "Reading Pairing file.\n";
            # For performance reasons, we'll process the pairs in batches.
            # This list contains the pairs.
            my $pairs = [];
            # This hash tracks feature IDs.
            my $fidMap = {};
            # Loop through the pairings in the file.
            while (! eof $ih) {
                my ($pairing) = $loader->GetLine($ih);
                $stats->Add(pairingIn => 1);
                # Parse this pairing.
                my ($fid1, $fid2) = parse_pair_key($pairing, \%genomes);
                # Only proceed if the pairing is for genomes we have.
                if (defined $fid1) {
                    # Store the features in the hash.
                    $fidMap->{$fid1} = 1;
                    $fidMap->{$fid2} = 1;
                    # Add the pairing to the current batch.
                    push @$pairs, [$fid1, $fid2];
                    # If the batch is full, process it.
                    if (scalar @$pairs >= 5000) {
                        ProcessPairingBatch($loader, $oh, $ph, $fidMap, $pairs);
                        # Set up for the next batch.
                        $fidMap = {};
                        $pairs = [];
                    }
                }
            }
            # If there's a residual batch, process it.
            if (@$pairs) {
                ProcessPairingBatch($loader, $oh, $ph, $fidMap, $pairs);
                # Release the space used by the batching variables. We'll
                # use them again.
                $fidMap = {};
                $pairs = [];
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
                # Parse this pairing.
                my ($fid1, $fid2) = parse_pair_key($pairing, \%genomes);
                # Only proceed if the pairing is for genomes we have.
                if (defined $fid1) {
                    # Here we are keeping the pair. That means we also want to keep
                    # the pairset. Insure we have the set's key.
                    my $newSet = $pairSets{$set};
                    if (! $newSet) {
                        $newSet = "pset$set";
                        $pairSets{$set} = $newSet;
                        $stats->Add(keptPairSet => 1);
                    }
                    # Store the features in the hash.
                    $fidMap->{$fid1} = 1;
                    $fidMap->{$fid2} = 1;
                    # Add the pairing to the current batch.
                    push @$pairs, [$newSet, $fid1, $fid2, $inverted];
                    # If the batch is full, process it.
                    if (scalar @$pairs >= 5000) {
                        ProcessPairsetBatch($loader, $oh, $fidMap, $pairs);
                        # Set up for the next batch.
                        $fidMap = {};
                        $pairs = [];
                    }
                }
            }
            # If there's a residual batch, process it.
            if (@$pairs) {
                ProcessPairsetBatch($loader, $oh, $fidMap, $pairs);
                # Release the space used by the batching variables.
                $fidMap = {};
                $pairs = [];
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

=head3 parse_pair_key

    my ($fid1, $fid2) = parse_pair_key($pairing, \%genomes);

Split a pair key into its component feature IDs and figure out if both
relevant genomes are in the database.

=over 4

=item pairing

Incoming pairing key, consisting of two feature IDs separated by a semicolon.

=item genomes

Reference to a hash of the genome IDs for SEED genomes in the CDMI database.

=item RETURN

Returns a list consisting of the two feature IDs, in order, or returns
two undefined values if one or the other of the features is not for a
genome in the database.

=cut

sub parse_pair_key {
    # Get the parameters.
    my ($pairing, $genomes) = @_;
    # The return values go in here.
    my @retVal;
    # Split the pairing into its two pieces.
    my ($fid1, $fid2) = split /:/, $pairing;
    # Get the relevant genomes.
    my $genome1 = genome_of($fid1);
    my $genome2 = genome_of($fid2);
    # Are they both in the CDMI?
    if ($genomes->{$genome1} && $genomes->{$genome2}) {
        # Yes. Return them.
        push @retVal, $fid1, $fid2;
    } else {
        # No. Return undefined values.
        push @retVal, undef, undef;
    }
    # Return the result.
    return @retVal;
}

=head3 ProcessPairingBatch

    ProcessPairingBatch($loader, $oh, $ph, \%fidMap, \@pairs);

Insert a list of pairings into the database. This method must find the
KBase IDs for the specified features and construct a new pairing ID
from them, then connect them to the features.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for accessing the ID server.

=item oh

Output file for the Pairing table.

=item ph

Output file for the IsInPair table.

=item fidMap

Reference to a hash whose keys are the features in the incoming pairs.

=item pairs

Reference to a list of 2-tuples, each containing the two features in a
single pair.

=back

=cut

sub ProcessPairingBatch {
    # Get the parameters.
    my ($loader, $oh, $ph, $fidMap, $pairs) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the feature IDs from the ID server.
    my $idMapping = $loader->FindKBaseIDs('Feature', [keys %$fidMap]);
    # Loop through the pairs.
    for my $pair (@$pairs) {
        my ($fid1, $fid2) = @$pair;
        # Find the KBase IDs for this pair.
        my $kbid1 = $idMapping->{$fid1};
        my $kbid2 = $idMapping->{$fid2};
        # Insure we found both.
        if (! $kbid1 || ! $kbid2) {
            $stats->Add(kbidNotFound => 1);
        } else {
            # Compute the new pairing key.
            my $newKey = join(":", sort ($kbid1, $kbid2));
            # Output the three records we need.
            print $oh "$newKey\n";
            $stats->Add(pairingOut => 1);
            print $ph "$kbid1\t$newKey\n";
            print $ph "$kbid2\t$newKey\n";
            $stats->Add(isInPairOut => 2);
        }
    }
    print "Pairing batch processed. " . $stats->Ask('pairingIn') . " pairings read.\n";
}

=head3 ProcessPairsetBatch

    ProcessPairsetBatch($loader, $oh, $fidMap, $pairs);

Output a batch of IsDeterminedBy records. We need to get the KBase IDs
for all of the features of interest, and use those to form new pairing
keys. This may change the inversion state of the pairing.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for accessing the ID server.

=item oh

Output file for the Pairing table.

=item ph

Output file for the IsInPair table.

=item fidMap

Reference to a hash whose keys are the features in the incoming pairs.

=item pairs

Reference to a list of 4-tuples, each consisting of (0) a pairset ID,
(1) the first feature in a pairing, (2) the second feature in a pairing,
and (3) an inversion flag. The features must be assembled into a new
pairing ID, which will be related to the pairset.

=back

=cut

sub ProcessPairsetBatch {
    # Get the parameters.
    my ($loader, $oh, $fidMap, $pairs) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the feature IDs from the ID server.
    my $idMapping = $loader->FindKBaseIDs('Feature', [keys %$fidMap]);
    # Loop through the pairs.
    for my $pair (@$pairs) {
        my ($pairset, $fid1, $fid2, $inverted) = @$pair;
        # Find the KBase IDs for this pair.
        my $kbid1 = $idMapping->{$fid1};
        my $kbid2 = $idMapping->{$fid2};
        # Insure we found both.
        if (! $kbid1 || ! $kbid2) {
            $stats->Add(kbidNotFound => 1);
        } else {
            # Compute the new pairing key.
            my @newOrder = sort ($kbid1, $kbid2);
            my $newKey = join(":", @newOrder);
            # If it's flipped, reverse the inversion flag.
            if ($newOrder[0] ne $kbid1) {
                $inverted = ($inverted ? 0 : 1);
                $stats->Add(invertFlip => 1);
            }
            # Output the relationship.
            print $oh join("\t", $pairset, $newKey, $inverted) . "\n";
            $stats->Add(IsDeterminedByOut => 1);
        }
    }
    print "Pairset batch processed. " . $stats->Ask('isDeterminedByIn') . " relationship instances read.\n";
}
