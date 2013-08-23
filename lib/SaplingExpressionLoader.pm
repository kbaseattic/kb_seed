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

package SaplingExpressionLoader;

    use strict;
    use Tracer;
    use Stats;
    use SeedUtils;
    use SAPserver;
    use Sapling;
    use base qw(SaplingDataLoader);

=head1 Sapling Expression Loader

This class loads Expression data into a Sapling database from an expression directory.
Unlike L<SaplingGenomeLoader>, this version is designed for updating a populated
database only. Links to features and genomes are put in, but not the features and
genomes themselves.

=head2 Main Methods

=head3 Load

    my $stats = SaplingExpressionLoader::Load($sap, $genome, $directory);

Load a genome's expression data from an expression data directory into the sapling database.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item genome

ID of the relevant genome.

=item directory

Name of the directory containing the expression data.

=back

=cut

sub Load {
    # Get the parameters.
    my ($sap, $genome, $directory) = @_;
    # Create the loader object.
    my $loaderObject = SaplingExpressionLoader->new($sap, $genome, $directory);
    # Load the expression data.
    $loaderObject->LoadExperiments();
    # Return the statistics.
    return $loaderObject->{stats};
}

=head3 ClearExpressionData

    my $stats = SaplingExpressionLoader::ClearExpressionData($sap, $genome);

Delete the specified genome's expression data from the specified sapling
database. This method can also be used to clean up after a failed or aborted load.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item genome

ID of the genome whose expression data is to be deleted.

=item RETURN

Returns a statistics object counting the records deleted.

=back

=cut

sub ClearExpressionData {
    # Get the parameters.
    my ($sap, $genome) = @_;
    # Create the statistics object.
    my $stats = Stats->new();
    # Get a list of this genome's chips.
    my @chips = $sap->GetFlat('HadResultsProducedBy', "HadResultsProducedBy(from-link) = ?",
                              [$genome], 'to-link');
    # Delete the chips and their associated experiment data.
    Trace("Deleting chips.") if T(SaplingDataLoader => 2);
    for my $chip (@chips) {
        my $newStats = $sap->Delete(Chip => $chip);
        $stats->Accumulate($newStats);
    }
    # Now we need to delete all coregulation information for features in this genome.
    Trace("Deleting feature coregulation pairs.") if T(SaplingDataLoader => 2);
    my $fidPattern = "fig|$genome.%";
    my $coregDeletes = $sap->DeleteLike('IsCoregulatedWith', "IsCoregulatedWith(from-link) LIKE ?",
                                        [$fidPattern]);
    $stats->Add(IsCoregulatedWith => $coregDeletes);
    # Loop through the coregulated set links for features in this genome, keeping the coregulated set
    # IDs.
    Trace("Deleting coregulation sets.") if T(SaplingDataLoader => 2);
    my %cosets;
    my $q = $sap->Get('IsRegulatedWith', "IsRegulatedWith(from-link) LIKE ?", [$fidPattern]);
    while (my $coset = $q->Fetch()) {
        $cosets{$coset->PrimaryValue('to-link')} = 1;
    }
    # Now delete the coregulated sets found.
    for my $coset (keys %cosets) {
        my $newStats = $sap->Delete(CoregulatedSet => $coset);
        $stats->Accumulate($newStats);
    }
    # Finally, delete the atomic regulons.
    my $regStats = ClearRegulonData($sap, $genome);
    $stats->Accumulate($regStats);
    # Return the statistics object.
    return $stats;
}

=head3 ClearRegulonData

    my $stats = SaplingExpressionLoader::ClearRegulonData($sap, $genome);

Delete all the atomic regulons for the specified genome. This is provided as a
separate process because sometimes the atomic regulons are updated independently
of the other expression data.

=over 4

=item sap

L<Sapling> object for accessing the database.

=item genome

ID of the genome whose atomic regulons are to be deleted.

=item RETURN

Returns a statistics object describing the records deleted.

=back

=cut

sub ClearRegulonData {
    # Get the parameters.
    my ($sap, $genome) = @_;
    Trace("Deleting atomic regulons.") if T(SaplingDataLoader => 2);
    # Create the return object.
    my $retVal = Stats->new();
    # Delete the links that connect the regulons to the features. This prevents the regulon
    # deletes from deleting the features themselves.
    my $atomicFeatureLinks = $sap->DeleteLike('IsFormedOf', "IsFormedOf(to-link) LIKE ?",
                                              ["fig|$genome%"]);
    $retVal->Add(IsFormedInto => $atomicFeatureLinks);
    # Now get the list of regulons for this genome.
    my @regulons = $sap->GetFlat('IsConfiguredBy', "IsConfiguredBy(from-link) = ?", [$genome],
                                 'to-link');
    # Loop through the regulons, deleting them.
    for my $regulon (@regulons) {
        my $newStats = $sap->Delete(AtomicRegulon => $regulon);
        $retVal->Accumulate($newStats);
    }
    # Return the statistics.
    return $retVal;
}

=head3 Process

    my $stats = SaplingExpressionLoader::Process($sap, $genome, $directory);

Load expression data from the specified directory. If the expression data already
exists in the database for the specified genome, it will be deleted first. (This
can be very expensive, so we hope it doesn't happen.)

=over 4

=item sap

L</Sapling> object for accessing the database.

=item genome

ID of the genome whose expression data is being loaded.

=item directory

Name of the directory containing the expression data files.

=item RETURN

Returns a statistics object describing the activity during the reload.

=back

=cut

sub Process {
    # Get the parameters.
    my ($sap, $genome, $directory) = @_;
    # Clear the existing expression data for the specified genome.
    my $stats = ClearExpressionData($sap, $genome);
    # Load the new expression data from the specified directory.
    my $newStats = Load($sap, $genome, $directory);
    # Merge the statistics.
    $stats->Accumulate($newStats);
    # Return the result.
    return $stats;
}


=head2 Loader Object Methods

=head3 new

    my $loaderObject = SaplingExpressionLoader->new($sap, $genome, $directory);

Create a loader object that can be used to facilitate loading Sapling data from an
expression data directory.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item genome

ID of the genome whose expression data is being loaded.

=item directory

Name of the directory containing the expression data.

=back

The object created contains the following fields.

=over 4

=item supportRecords

A hash of hashes, used to track the support records known to exist in the database.

=item sap

L<Sapling> object used to access the database.

=item stats

L<Stats> object for tracking statistical information about the load.

=item genome

ID of the genome whose data is being loaded.

=item chip

ID of the relevant chip.

=item directory

Name of the directory containing the subsystem data.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $sap, $genome, $directory) = @_;
    # Create the object.
    my $retVal = SaplingDataLoader::new($class, $sap, qw(experiments));
    # Add our specialized data.
    $retVal->{genome} = $genome;
    $retVal->{chip} = "CNF$genome";
    $retVal->{directory} = $directory;
    # Return the result.
    return $retVal;
}

=head2 Internal Utility Methods

=head3 LoadExperiments

    $loaderObject->LoadExperiments();

Load all the expression data experiments and related information for this genome from the
incoming directory.

=cut

sub LoadExperiments {
    # Get the parameters.
    my ($self) = @_;
    # Get the directory name.
    my $expDataDirectory = $self->{directory};
    # Get the sapling database object.
    my $sap = $self->{sap};
    # Get the statistics object.
    my $stats = $self->{stats};
    # Get the genome ID.
    my $genome = $self->{genome};
    # Check for a chip ID.
    my $chipFileName = "$expDataDirectory/chip";
    if (-f $chipFileName) {
        # Chip file found.
        my $ih = Open(undef, "<$chipFileName");
        # Read the chip ID.
        ($self->{chip}) = Tracer::GetLine($ih);
        # Close the chip file.
        close $ih;
        # Denote we have a custom chip ID.
        $stats->Add(customChipID => 1);
    }
    # Create the chip record.
    $sap->InsertObject('Chip', id => $self->{chip});
    # Connect it to the genome.
    $sap->InsertObject('ProducedResultsFor', from_link => $self->{chip}, to_link => $genome);
    # Do we have experiments?
    my @experiments = $self->ReadExperiments();
    if (! @experiments) {
        # No, so skip this genome.
        Trace("No experiment names found for $genome.") if T(SaplingDataLoader => 1);
        $stats->Add(missingExperimentNames => 1);
    } else {
        # Yes. This hash maps experiment IDs to sequence numbers.
        my %expHash;
        # Remember the number of experiments.
        my $expCount = scalar @experiments;
        # Loop through the experiments, putting them in the experiment table and the
        # experiment hash.
        for (my $seqNo = 0; $seqNo < $expCount; $seqNo++) {
            my $name = $experiments[$seqNo];
            $expHash{$name} = $seqNo;
            $sap->InsertObject('HasResultsIn', from_link => $self->{chip}, 
                                to_link => "$self->{chip}:$name",
                                sequence => $seqNo);
            $sap->InsertObject('Experiment', id => "$self->{chip}:$name", source => '');
            $stats->Add(experiments => 1);
        }
        # We'll use this to hold our input file handles.
        my $ih;
        # Check for a raw data file.
        my $raw_data_file = "$expDataDirectory/rma_normalized.tab";
        if (! -f $raw_data_file) {
            # This means we have a chip and probes, but no experimental results.
            Trace("No raw data file found for $genome expression data.") if T(SaplingDataLoader => 1);
            $stats->Add(missingRawData => 1);
        } else {
            # Open the raw data file.
            $ih = Open(undef, "<$raw_data_file");
            Trace("Processing expression data from $raw_data_file.") if T(SaplingDataLoader => 3);
            # Read the list of experiments.
            my @exps = Tracer::GetLine($ih);
            # Spool them into the experiment table if they're not already there.
            for my $exp (@exps) {
                if (! exists $expHash{$exp}) {
                    $sap->InsertObject('HasResultsIn', from_link => $self->{chip},
                                        to_link => "$self->{chip}:$exp", sequence => -1);
                    $sap->InsertObject('Experiment', id => "$self->{chip}:$exp", source => '');
                    $stats->Add(extraExperiment => 1);
                }
            }
            # We'll put the signal values in here. For each feature, we will
            # have a list of signals in the same order as the list of experiments.
            my $corrH = {};
            while (! eof $ih) {
                my ($fid, @signals) = Tracer::GetLine($ih);
                # Store the signals in the hash.
                $corrH->{$fid} = \@signals;
            }
            # Close the raw data file.
            close $ih;
            # Now we need to generate the signal records. This includes the signal values we just
            # read in plus on/off indications from the "final_on_off_calls.txt".
            $ih = Open(undef, "<$expDataDirectory/final_on_off_calls.txt");
            # Discard the experiment list. It will be the same as the one we already have.
            Tracer::GetLine($ih);
            # Loop through the on/off file.
            while (! eof $ih) {
                my ($fid, @onOffs) = Tracer::GetLine($ih);
                # Get the signals for this feature.
                my $signals = $corrH->{$fid};
                if (! $signals) {
                    Trace("No signals found for $fid in experiments for $genome.") if T(SaplingDataLoader => 1);
                    $stats->Add(noSignals => 1);
                } else {
                    # This will be used to build the levels vector.
                    my @levels;
                    # Generate the signal records.
                    for (my $i = 0; $i <= $#exps; $i++) {
                        if (defined $signals->[$i]) {
                            # Here we have a signal for this experiment.
                            $sap->InsertObject('HasIndicatedSignalFrom', 
                                                to_link => "$self->{chip}:$exps[$i]",
                                                from_link => $fid, rma_value => $signals->[$i],
                                                level => $onOffs[$i]);
                            $stats->Add(signalX => 1);
                        } else {
                            # No signal, so no indication will be built.
                            $stats->Add(signalZ => 1);
                        }
                        # Next, we put the on/off level in the experiment vector.
                        my $i = $expHash{$exps[$i]};
                        if (defined $i) {
                            $levels[$i] = $onOffs[$i];
                        }
                    }
                    # We need to connect the feature to the chip, specifying the level vector.
                    # First, we must fill in the gaps.
                    for (my $i = 0; $i <= $expCount; $i++) {
                        if (! defined $levels[$i]) {
                            $levels[$i] = 0;
                            $stats->Add(fidLevelGap => 1);
                        }
                    }
                    # Output the relationship.
                    $sap->InsertObject('IndicatedLevelsFor', from_link => $self->{chip},
                                        to_link => $fid, level_vector => \@levels);
                }
            }
            # Close the raw data file.
            close $ih;
            # Check to see if we can load the correlation coefficients.
            my $pearsonFile = "$expDataDirectory/pearson.tbl";
            if (! -f $pearsonFile) {
                Trace("Could not find pearson coefficients for $genome.") if T(1);
                $stats->Add(missingPearson => 1);
            } else {
                # Yes we can. Read them from the pearson coefficient file.
                $ih = Open(undef, "<$pearsonFile");
                while (! eof $ih) {
                    my ($fid1, $fid2, $pc) = Tracer::GetLine($ih);
                    # Store both directions of the correlation.
                    $sap->InsertObject('IsCoregulatedWith', from_link => $fid1,
                    				   to_link => $fid2, coefficient => $pc);
                    $sap->InsertObject('IsCoregulatedWith', from_link => $fid2, 
                    				   to_link => $fid1, coefficient => $pc);
                    $stats->Add(corrCoefficients => 2);
                }
            }
            # Now we loop through the coregulated sets. These are found in files named
            # "coregulated.<something>". The coregulation data needs to be stored in
            # the database.
            Trace("Generating coregulated sets for $genome.") if T(SaplingDataLoader => 3);
            my @files = grep { $_ =~ /^coregulated/ } Tracer::OpenDir($expDataDirectory, 0);
            for my $file (@files) {
                $ih = Open(undef, "<$expDataDirectory/$file");
                # Loop through the sets in this file.
                while (! eof $ih) {
                    my ($fidList, $desc) = Tracer::GetLine($ih);
                    $stats->Add(coregulations => 1);
                    # Compute the list of features in this set.
                    my @fids = split m/,/, $fidList;
                    # Create an ID for it.
                    my $setID = ERDB::DigestKey(join("-", sort @fids));
                    # Create the record for the set, if it's new.
                    my $newSet = $self->InsureEntity(CoregulatedSet => $setID, reason => $desc);
                    if ($newSet) {
                        # It is new, so connect it to the features.
                        for my $fid (@fids) {
                            $sap->InsertObject('IsRegulatedWith', from_link => $fid,
                                                to_link => $setID);
                        }
                    }
                }
            }
        }
        # Open the atomic regulon file.
        $ih = Open(undef, "<$expDataDirectory/atomic.regulons");
        # We'll track our regulons in here.
        my %regulons;
        Trace("Generating regulons for $genome.") if T(SaplingDataLoader => 3);
        # Loop through the regulons.
        while (! eof $ih) {
            my ($id, $fid) = Tracer::GetLine($ih);
            $stats->Add(regulonRecord => 1);
            # Compute the real regulon ID.
            my $realID = "$genome:$id";
            # Is this is a new regulon?
            if (! exists $regulons{$id}) {
                # Yes. Create the regulon record and connect it to the genome.
                $sap->InsertObject('AtomicRegulon', id => $realID);
                $sap->InsertObject('IsConfiguredBy', from_link => $genome,
                                    to_link => $realID);
                # Make sure we know this is handled.
                $regulons{$id} = 1;
            }
            # Connect the regulon to the feature.
            $sap->InsertObject('IsFormedOf', from_link => $realID, to_link => $fid);
        }
        close $ih;
        Trace("Generating expression levels for $genome.") if T(SaplingDataLoader => 3);
        # Now we can connect the regulons to the experiments.
        $ih = Open(undef, "<$expDataDirectory/ar.vectors");
        # Loop through the experiment vectors.
        while (! eof $ih) {
            my ($id, $levelList) = Tracer::GetLine($ih);
            $stats->Add(vectorRecord => 1);
            # Compute the real regulon ID.
            my $realID = "$genome:$id";
            # Extract the expression levels.
            my @levels = split m/\s*,\s*/, $levelList;
            my $levelCount = scalar @levels;
            if ($levelCount != $expCount) {
                Trace("Vector $id for $genome has $levelCount levels for $expCount experiments.") if T(SaplingDataLoader => 2);
                if ($levelCount < $expCount) {
                    $stats->Add(shortExpressionVector => 1);
                } else {
                    $stats->Add(longExpressionVector => 1);
                }
            }
            # Loop through them, connecting the regulon to experiments.
            for (my $i = 0; $i <= $#levels; $i++) {
                if ($i >= $expCount) {
                    $stats->Add(extraExpressionVectorElement => 1);
                } else {
                    $sap->InsertObject('AffectsLevelOf', 
                                        from_link => "$self->{chip}:$experiments[$i]",
                                        to_link => $realID, level => $levels[$i]);
                }
            }
            # Create the atomic regulon experiment vector.
            $sap->InsertObject('GeneratedLevelsFor', from_link => $self->{chip},
                                to_link => $realID, level_vector => \@levels);
        }
    }
}

=head3 ReadExperiments

    my @experiments = $self->ReadExperiments();

Read in the vector of experiment names for this genome. If the experiment names file does
not exist, an empty list will be returned.

=cut

sub ReadExperiments {
    # Get the parameters.
    my ($self) = @_;
    # This array will hold the experiment names.
    my @retVal;
    # Compute the experiment-names file name.
    my $fileName = "$self->{directory}/experiment.names";
    # Only proceed if the file exists.
    if (-f $fileName) {
        # Get the vector of experiment IDs.
        my $ih = Open(undef, "<$fileName");
        # Read in the experiments.
        while (! eof $ih) {
            my ($id, $name) = Tracer::GetLine($ih);
            # Note that the experiment numbers are 1-based.
            my $seqNo = $id - 1;
            $retVal[$seqNo] = $name;
        }
    }
    # Return the experiment vector.
    return @retVal;
}


=head3 compute_pc

    my $hash = SaplingExpressionLoader::compute_pc(\@gene_ids, \%gxp_hash);

Compute the Pearson coefficients for each pair of features in the list of incoming
gene IDs. The coefficients will indicate the correlation between the features' gene
expression lists from the incoming hash.

=over 4

=item gene_ids

List of feature IDs for which correlation coefficients are desired.

=item gxp_hash

A hash mapping each feature ID to a list of normalized expression values.

=item RETURN

Returns a reference to a hash of hashes keyed by feature ID. Each feature ID
is mapped to a sub-hash that maps the other feature IDs to the appropriate
Pearson coefficients.

=back

=cut

sub compute_pc {
    my ($gene_ids, $gxp_hash) = @_;
    my %values = map { $_ => {} } @$gene_ids;
    require Statistics::Descriptive;
    for (my $i = 0; $i < @$gene_ids-1; $i++) {
        my $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@{$gxp_hash->{$gene_ids->[$i]}});

        for (my $j = $i+1; $j < @$gene_ids; $j++)
        {
            my ($q, $m, $r, $err) = $stat->least_squares_fit(@{$gxp_hash->{$gene_ids->[$j]}});
            $values{$gene_ids->[$i]}->{$gene_ids->[$j]} = $r;
            $values{$gene_ids->[$j]}->{$gene_ids->[$i]} = $r;
        }
    }
    return \%values;
}

1;