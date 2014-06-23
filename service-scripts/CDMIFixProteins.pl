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

=head1 Protein Error Check

    CDMIFixProteins [options]

=head2 Introduction

This script searches for bad proteins in the CDMI. A protein with a stop codon at
the end will have the stop removed and the various links moved. This may require
creating a new protein sequence record. Proteins which look like DNA will be
flagged and listed.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item minProtLen

Minimum length for a protein to be considered reasonable. The default is C<10>.

=item shiftPercent

Percent length error considered significant. The default is C<5>.

=back

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;

    $| = 1; # Prevent buffering on STDOUT.
    # These are the command-line options.
    my $minProtLen = 10;
    my $shiftPercent = 4;
    # These will hold genome counts.
    my %counters = (dnaProtein => {}, noStopCodon => {}, 
            veryShortProtein => {}, stopCodon => {},
            slightlyShort => {}, badType => {},
            veryShort => {}, slightlyLong => {},
            veryLong => {});
    # These describe the above errors.
    my %desc = (dnaProtein => "protein appears to be a DNA sequence",
                noStopCodon => "DNA does not have a stop codon",
                veryShortProtein => "protein is unusually small",
                stopCodon => "protein had a stop codon in it",
                slightlyShort => "DNA sequence was a little shorter than protein",
                badType => "feature associated with a protein was not a CDS",
                veryShort => "DNA sequence was much shorter than protein",
                slightlyLong => "DNA sequence was a little longer than protein",
                veryLong => "DNA sequence was much longer than protein"
                );
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("minProtLen=i" => \$minProtLen,
            "shiftPercent=i" => \$shiftPercent);
    if (! $cdmi) {
        print "usage: CDMIFixProteins [options]\n";
    } else {
        # Create the loader object.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        # Get the statistics object.
        my $stats = $loader->stats;
        # Loop through the proteins.
        my $qry = $cdmi->Get('ProteinSequence', "", []);
        while (my $record = $qry->Fetch()) {
            my ($id, $sequence) = $record->Values(['id', 'sequence']);
            my $count = $stats->Add(proteinRead => 1);
            if ($count % 10000 == 0) {
                print "$count proteins read.\n";
            }
            # Get the protein's features. For each feature we want to know the
            # parent genome, the type, and the sequence length.
            my %feats = map { $_->[0] => [$_->[1], $_->[2], $_->[3]] } 
                    $cdmi->GetAll('IsProteinFor Feature IsOwnedBy',
                    'IsProteinFor(from-link) = ?', [$id], 
                    "Feature(id) IsOwnedBy(to-link) Feature(feature-type) Feature(sequence-length)");
            # We'll set this to TRUE if we decide a protein is hopeless.
            my $error;
            # Check for anomalies in this sequence.
            if ($sequence =~ /\*$/) {
                # Here we have a stop codon on the end.
                print "Stop codon found in protein $id.\n";
                $stats->Add(stopEndFound => 1);
                FixStoppedProtein($loader, $id, $sequence);
                # Record the genomes involved.
                for my $fid (keys %feats) {
                    $counters{stopCodon}{$feats{$fid}[0]}++;
                }
                $error = 1;
            }
            if (! $error && $sequence =~ /^[AGTCN]+$/i) {
                # Here the sequence looks like DNA.
                $error = CheckDnaProtein($loader, $id, $sequence, \%feats, $counters{dnaProteinFeature});
            }
            if (! $error && length($sequence) < $minProtLen) {
                # Here the protein sequence is too short.
                $stats->Add(shortProtein => 1);
                # Record the genomes involved.
                for my $fid (keys %feats) {
                    $counters{veryShortProtein}{$feats{$fid}[0]}++;
                }
            }
            # Add more checks here as we discover problems. Only
            # continue checking if $error is FALSE.
            if (! $error) {
                # Here we check for a mismatch in the codon count.
                $error = CheckProteinCodons($loader, $id, $sequence, \%feats, $shiftPercent, 
                        \%counters);
                
            }
        }
        print "Statistics by genome.\n";
        for my $type (sort keys %counters) {
            my $countHash = $counters{$type};
            print "\nFeature counts for error: $desc{$type}.\n";
            for my $genome (sort keys %$countHash) {
                my ($name, $sourceName) = $cdmi->GetEntityValues(Genome => $genome, ['scientific-name', 'source-id']);
                print "$genome  $sourceName  $name    $countHash->{$genome} \n";
            }
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