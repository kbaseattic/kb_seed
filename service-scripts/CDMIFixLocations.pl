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

=head1 Feature Location Error Check

    CDMIFixLocations [options]

=head2 Introduction

This script searches for features that are missing location information. The genomes
with this problem will be identified and then displayed along with the number of
bad features found.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;

    $| = 1; # Prevent buffering on STDOUT.
    # These will hold genome counts.
    my %genomeCounts;
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    if (! $cdmi) {
        print "usage: CDMIFixLocations [options]\n";
    } else {
        # Create the loader object.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        # Get the statistics object.
        my $stats = $loader->stats;
        # Loop through the features.
        my $qry = $cdmi->Get('Feature IsOwnedBy', "", []);
        while (my $record = $qry->Fetch()) {
            my ($fid, $seqLen, $gid) = $record->Values(['id', 'sequence-length',
                    'IsOwnedBy(to-link)']);
            my $count = $stats->Add(featureRead => 1);
            if ($count % 50000 == 0) {
                print "$count features read.\n";
            }
            # Get the feature's location list.
            my @locs = $cdmi->GetLocations($fid);
            # If there are no locations, that's the error.
            if (! @locs) {
                $genomeCounts{$gid}++;
                $stats->Add(missingLocations => 1);
            }
        }
        print "Statistics by genome.\n";
        for my $gid (sort keys %genomeCounts) {
            # Get the specifications of this genome.
            my ($genomeData) = $cdmi->GetAll("Genome WasSubmittedBy", "Genome(id) = ?",
                    [$gid], "scientific-name source-id WasSubmittedBy(to-link)");
            my ($name, $sid, $source) = @$genomeData;
            print join("\t", $gid, $name, $sid, $source, $genomeCounts{$gid}) . "\n";
        }
        print "All done:\n" . $stats->Show();
        
    }
    
# Fix a protein with a stop codon at the end. This requires creating a new copy of the
# protein with the corrected sequence and a new ID. The corrected protein may already
# exist in the database. All of the features connected to the protein must be moved
# as well.
sub FixStoppedProtein {
    # Get the parameters.
    my ($loader, $id, $sequence) = @_;
    # Get the statistics object and the CDMI database object.
    my $stats = $loader->stats;
    my $cdmi = $loader->cdmi;
    # Create the new protein sequence.
    my $fixed = $sequence;
    chop $fixed;
    my $newID = $loader->CheckProtein($fixed);
    # Now we need to reconnect the protein's old records to the new sequence.
    my $subStats = $cdmi->MoveEntity('ProteinSequence', $id, $newID);
    $stats->Accumulate($subStats);
    # Delete the old protein.
    $subStats = $cdmi->Delete('ProteinSequence', $id);
    print "Protein $id renamed to $newID.\n";
}


# Check a protein that looks like DNA to see if it is.
sub CheckDnaProtein {
    # Get the parameters.
    my ($loader, $id, $sequence, $feats, $counters) = @_;
    # Declare the return value. We default to FALSE.
    my $retVal = 0;
    # Get the statistics object and the CDMI database object.
    my $stats = $loader->stats;
    my $cdmi = $loader->cdmi;
    $stats->Add(possibleDnaProteins => 1);
    $stats->Add(DnaProteinFeaturesChecked => scalar keys %$feats);
    # Figure out how many are suspicious.
    my $protLen = length($sequence);
    my @suspicionList;
    for my $fid (keys %$feats) {
        # Check to see if this feature fits the protein.
        my ($genome, $type, $dnaLen) = @{$feats->{$fid}};
        my $transLen = int($dnaLen / 3);
        if ($protLen > $transLen) {
            push @suspicionList, $fid;
            $stats->Add(suspiciousFeature => 1);
            $counters->{$genome}++
        }
    }
    my $suspicionCount = scalar @suspicionList;
    if ($suspicionCount) {
        print "Protein $id has $suspicionCount suspicious features: " . join(", ", @suspicionList) . ".\n";
        $stats->Add(probableDnaProtein => 1);
        $retVal = 1;
    }
    # Return TRUE if this protein is probably bad, else FALSE.
    return $retVal;
}

# Check a protein to see if its length is different from what the coding sequences predict.
sub CheckProteinCodons {
    # Get the parameters.
    my ($loader, $id, $sequence, $feats, $shiftPercent, $counters) = @_;
    # Declare the return value. We default to FALSE.
    my $retVal = 0;
    # Get the statistics object and the CDMI database object.
    my $stats = $loader->stats;
    my $cdmi = $loader->cdmi;
    $stats->Add(checkingProteinCodons => 1);
    # Loop through the features.
    for my $fid (keys %$feats) {
        # Get this feature's information.
        my ($genomeID, $type, $seqLen) = @{$feats->{$fid}};
        # Compute the number of codons and amino acids.
        my $codons = int($seqLen/3);
        my $aaLen = length($sequence);
        if ($type ne 'CDS') {
            # We have a feature of the wrong type.
            $counters->{badType}{$genomeID}++;
        } elsif ($aaLen == $codons) {
            # Here the lengths are the same. Check to see if there is a stop codon on the DNA.
            my @locs = $cdmi->GetLocations($fid);
            my $lastLoc = pop @locs;
            if (! defined $lastLoc) {
                print "No location data found for $fid.\n";
                $stats->Add(MissingLocations => 1);
            } else {
                $lastLoc->Tail(3);
                my $lastCodon = $cdmi->ComputeDNA($lastLoc);
                if ($lastCodon =~ /^t(aa|ag|ga)$/) {
                    # There is a stop codon. So the protein has an extra amino acid.
                    $retVal = 1;
                    $stats->Add(DnaBadStopCodon => 1);
                    $counters->{slightlyShort}{$genomeID}++;
                } else {
                    # No stop codon. Flag the feature but it's not an error.
                    $stats->Add(DnaNoStopCodon => 1);
                    $counters->{noStopCodon}{$genomeID}++
                }
            }
        } elsif ($aaLen < ($codons - 1)) {
            # Here the DNA sequence is too long.
            # Check how much longer.
            if (($codons - 1 - $aaLen) * 100 / $codons < $shiftPercent) {
                $counters->{slightlyLong}{$genomeID}++;
                $stats->Add(slightlyLongFeature => 1);
            } else {
                $counters->{veryLong}{$genomeID}++;
                $stats->Add(veryLongFeature => 1);
            }
            $retVal = 1;
        } elsif ($aaLen > $codons) {
            # Here the DNA sequence is too short.
            # Check how much shorter.
            if (($aaLen - $codons + 1) * 100 / $codons < $shiftPercent) {
                $counters->{slightlyShort}{$genomeID}++;
                $stats->Add(slightlyShortFeature => 1);
            } else {
                $counters->{veryShort}{$genomeID}++;
                $stats->Add(veryShortFeature => 1);
            }
            $retVal = 1;
        }
    }
    # Return the error flag.
    return $retVal;
}