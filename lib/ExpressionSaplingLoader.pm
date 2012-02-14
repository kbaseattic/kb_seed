#!/usr/bin/perl -w

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
# for Interpretations of Expressions. All Rights Reserved.
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
# Expressions at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#

package ExpressionSaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSaplingLoader';

=head1 Sapling Expression Load Group Class

=head2 Introduction

The Expression Load Group includes all of the tables that contain gene-expression
data.

=head3 new

    my $sl = ExpressionSaplingLoader->new($erdb, $source, $options, @tables);

Construct a new ExpressionSaplingLoader object.

=over 4

=item erdb

L<Sapling> object for the database being loaded.

=item options

Reference to a hash of command-line options.

=item tables

List of tables in this load group.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $options) = @_;
    # Create the table list.
    my @tables = sort qw(Chip HasResultsIn Experiment AffectsLevelOf AtomicRegulon
                         IsFormedOf IsConfiguredBy OperatesIn CoregulatedSet
                         IsRegulatedWith IsCoregulatedWith HasIndicatedSignalFrom
                         Attribute HasValueFor ProducedResultsFor IndicatedLevelsFor
                         GeneratedLevelsFor);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the expression-related files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Process according to the type of section.
    if ($self->global()) {
        # This is the global section. There is no global data yet.
    } else {
        # Get the section ID.
        my $genomeID = $self->section();
        # This is a genome section. Create the data for the genome.
        $self->LoadExperiments($genomeID);
    }
}

=head3 LoadExperiments

    $sl->LoadExperiments($genomeID);

Load the experiments and related data for the specified genome. This data is stored
in the B<UserSpace> for the genome, in a subdirectory called B<ExpressionData>.

If no such subdirectory exists, then no expression data will be loaded for the genome
in question.

=over 4

=item genomeID

ID of the genome whose expression data is to be loaded.

=back

=cut

sub LoadExperiments {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Check for the expression data.
    # my $expSeedBase = $FIG_Config::organisms;
    my $expSeedBase = "/vol/expression/current/";
    my $expDataDirectory = "$expSeedBase/$genomeID";
    if (! -d $expDataDirectory) {
        Trace("No expression data found for $genomeID.") if T(ERDBLoadGroup => 3);
        $self->Add(noExpressionData => 1);
    } elsif (! -f "$expDataDirectory/atomic.regulons") {
        Trace("No atomic regulons file found for $genomeID. Expression data skipped.") if T(ERDBLoadGroup => 3);
        $self->Add(missingAtomicRegulons => 1);
    } elsif (-f "$expDataDirectory/PRIVATE") {
        Trace("$genomeID marked PRIVATE: expression data not loaded.") if T(ERDBLoadGroup => 3);
        $self->Add(privateExpressionData => 1);
    } else {
        Trace("Expression data directory is $expDataDirectory.") if T(ERDBLoadGroup => 3);
        # Load the chip data.
        my $chipID = $self->LoadChip($expDataDirectory, $genomeID);
        # Load the coregulation and regulon data.
        $self->LoadCoregulation($chipID, $genomeID, $expDataDirectory);
    }
}

=head3 LoadChip

    my $chipID = $sl->LoadChip($expDataDirectory, $genomeID);

Find the ID of the chip used for this genome. The chip ID can be found
in the B<chip> file. It is stored into the chip table and returned to
the caller.

=over 4

=item expDataDirectory

Directory containing the expression data for this genome.

=item genomeID

ID of the genome whose expression data is being loaded.

=item RETURN

Returns the ID of the chip for this genome's expression data experiments.

=back

=cut

sub LoadChip {
    # Get the parameters.
    my ($self, $expDataDirectory, $genomeID) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for a chip file.
    my $chipFileName = "$expDataDirectory/chip";
    if (! -f $chipFileName) {
        # No chip file. We make up an ID.
        $retVal = "CNF$genomeID";
        $self->Add(missingChipFile => 1);
        Trace("No chip file found for expression data in $expDataDirectory.") if T(ERDBLoadGroup => 2);
    } else {
        # Chip file found.
        my $ih = Open(undef, "<$expDataDirectory/chip");
        # Read the chip ID.
        ($retVal) = Tracer::GetLine($ih);
        # Close the chip file.
        close $ih;
    }
    # Store the ID in the Chip table.
    $self->PutE(Chip => $retVal);
    $self->Add(chips => 1);
    # Connect it to the genome.
    $self->PutR(ProducedResultsFor => $retVal, $genomeID);
    # Return the chip ID.
    return $retVal;
}


=head3 LoadCoregulation

    $self->LoadCoregulation($chipID, $genomeID, $expDataDirectory);

Load the coregulation data. This is kept in the B<raw_data.tab> file, and
includes the list of experiments and the expression values for each of
the features. In addition, it is used to compute the coregulated sets and
the pearson coefficients.

=over 4

=item chipID

ID of the chip used for this genome's gene expression experiments.

=item genomeID

ID of the genome whose expression data is being loaded.

=item expDataDirectory

Directory containing the gene expression data.

=back

=cut

sub LoadCoregulation {
    # Get the parameters.
    my ($self, $chipID, $genomeID, $expDataDirectory) = @_;
    # Do we have experiments?
    my $fileName = "$expDataDirectory/experiment.names";
    if (! -f $fileName) {
        # No, so skip this genome.
        Trace("No experiment names found for $genomeID.") if T(ERDBLoadGroup => 2);
        $self->Add(missingExperimentNames => 1);
    } else {
        # Yes. Get the vector of experiment IDs.
        my $ih = Open(undef, "<$fileName");
        # This array will hold the experiment names.
        my @experiments;
        # This hash maps experiment IDs to sequence numbers.
        my %expHash;
        # Loop through the experiments.
        while (! eof $ih) {
            my ($id, $name) = Tracer::GetLine($ih);
            $self->Add(experimentRecord => 1);
            # Note that the experiment numbers are 1-based.
            my $seqNo = $id - 1;
            $experiments[$seqNo] = $name;
            $expHash{$name} = $seqNo;
            # Put the experiments in the experiment table.
            $self->PutE(Experiment => $name, source => '');
            $self->PutR(HasResultsIn => $chipID, $name, sequence => $seqNo);
            $self->Add(experiment => 1);
        }
        close $ih;
        # Remember the number of experiments.
        my $expCount = scalar @experiments;
        # Check for a raw data file.
        my $raw_data_file = "$expDataDirectory/rma_normalized.tab";
        if (! -f $raw_data_file) {
            # This means we have a chip and probes, but no experimental results.
            Trace("No raw data file found for $genomeID expression data.") if T(ERDBLoadGroup => 1);
            $self->Add(missingRawData => 1);
        } else {
            # Open the raw data file.
            $ih = Open(undef, "<$raw_data_file");
            Trace("Processing expression data from $raw_data_file.") if T(ERDBLoadGroup => 3);
            # Read the list of experiments.
            my @exps = Tracer::GetLine($ih);
            # Spool them into the experiment table if they're not already there.
            for my $exp (@exps) {
                if (! exists $expHash{$exp}) {
                    $self->PutE(Experiment => $exp, source => '');
                    $self->PutR(HasResultsIn => $chipID, $exp, sequence => -1);
                    $self->Add(extraExperiment => 1);
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
                    $self->AddWarning("No signals found for $fid in experiments for $genomeID.");
                } else {
                    # This will be used to build the levels vector.
                    my @levels;
                    # Generate the signal records.
                    for (my $i = 0; $i <= $#exps; $i++) {
                        if (defined $signals->[$i]) {
                            # Here we have a signal for this experiment.
                            $self->PutR(HasIndicatedSignalFrom => $fid, $exps[$i], rma_value => $signals->[$i], level => $onOffs[$i]);
                            $self->Add(signalX => 1);
                        } else {
                            # No signal, so no indication will be built.
                            $self->Add(signalZ => 1);
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
                            $self->Add(fidLevelGap => 1);
                        }
                    }
                    # Output the relationship.
                    $self->PutR(IndicatedLevelsFor => $chipID, $fid, level_vector => \@levels);
                }
            }
            # Close the raw data file.
            close $ih;
            # Now we loop through the coregulated sets. These are found in files named
            # "coregulated.<something>".
            Trace("Generating coregulated sets for $genomeID.") if T(ERDBLoadGroup => 3);
            my @files = grep { $_ =~ /^coregulated/ } Tracer::OpenDir($expDataDirectory, 0);
            for my $file (@files) {
                $ih = Open(undef, "<$expDataDirectory/$file");
                # Loop through the sets in this file.
                while (! eof $ih) {
                    my ($fidList, $desc) = Tracer::GetLine($ih);
                    if (! defined $desc) {
                        Trace("Invalid record in coregulated set file $file for $genomeID.") if T(0);
                        $self->Add(invalidCoregulation => 1);
                    } else {
                        $self->Track(coregulations => $desc, 100);
                        # Compute the list of features in this set.
                        my @fids = split /,/, $fidList;
                        # Create an ID for it.
                        my $setID = ERDB::DigestKey(join("-", sort @fids));
                        # Create the record for the set.
                        $self->PutE(CoregulatedSet => $setID, reason => $desc);
                        # Connect it to the features.
                        for my $fid (@fids) {
                            $self->PutR(IsRegulatedWith => $fid, $setID);
                        }
                    }
                }
            }
            # Check to see if we can load the correlation coefficients.
            my $pearsonFile = "$expDataDirectory/pearson.tbl";
            if (! -f $pearsonFile) {
                Trace("Could not find pearson coefficients for $genomeID.") if T(1);
                $self->Add(missingPearson => 1);
            } else {
                # Yes we can. Read them from the pearson coefficient file.
                $ih = Open(undef, "<$pearsonFile");
                while (! eof $ih) {
                    my ($fid1, $fid2, $pc) = Tracer::GetLine($ih);
                    # Store both directions of the correlation.
                    $self->PutR(IsCoregulatedWith => $fid1, $fid2, coefficient => $pc);
                    $self->PutR(IsCoregulatedWith => $fid2, $fid1, coefficient => $pc);
                    $self->Track(corrCoefficients => "$fid1:$fid2", 50000);
                }
            }
        }
        # Open the atomic regulon file.
        $ih = Open(undef, "<$expDataDirectory/atomic.regulons");
        # We'll track our regulons in here.
        my %regulons;
        Trace("Generating regulons for $genomeID.") if T(ERDBLoadGroup => 3);
        # Loop through the regulons.
        while (! eof $ih) {
            my ($id, $fid) = Tracer::GetLine($ih);
            $self->Add(regulonRecord => 1);
            $self->Track(regulonFeatures => $fid, 1000);
            # Compute the real regulon ID.
            my $realID = "$genomeID:$id";
            # Is this is a new regulon?
            if (! exists $regulons{$id}) {
                # Yes. Create the regulon record and connect it to the genome.
                $self->PutE(AtomicRegulon => $realID);
                $self->PutR(IsConfiguredBy => $genomeID, $realID);
                # Make sure we know this is handled.
                $regulons{$id} = 1;
            }
            # Connect the regulon to the feature.
            $self->PutR(IsFormedOf => $realID, $fid);
        }
        close $ih;
        Trace("Generating expression levels for $genomeID.") if T(ERDBLoadGroup => 3);
        # Now we can connect the regulons to the experiments.
        $ih = Open(undef, "<$expDataDirectory/ar.vectors");
        # Loop through the experiment vectors.
        while (! eof $ih) {
            my ($id, $levelList) = Tracer::GetLine($ih);
            $self->Add(vectorRecord => 1);
            # Compute the real regulon ID.
            my $realID = "$genomeID:$id";
            # Extract the expression levels.
            my @levels = split /\s*,\s*/, $levelList;
            my $levelCount = scalar @levels;
            if ($levelCount != $expCount) {
                Trace("Vector $id for $genomeID has $levelCount levels for $expCount experiments.") if T(ERDBLoadGroup => 2);
                if ($levelCount < $expCount) {
                    $self->Add(shortExpressionVector => 1);
                } else {
                    $self->Add(longExpressionVector => 1);
                }
            }
            # Loop through them, connecting the regulon to experiments.
            for (my $i = 0; $i <= $#levels; $i++) {
                if ($i >= $expCount) {
                    $self->Add(extraExpressionVectorElement => 1);
                } else {
                    $self->PutR(AffectsLevelOf => $experiments[$i], $realID,
                                level => $levels[$i]);
                }
            }
            # Create the atomic regulon experiment vector.
            $self->PutR(GeneratedLevelsFor => $chipID, $realID, level_vector => \@levels);
        }
    }
}


=head3 compute_pc

    my $hash = ExpressionSaplingLoader::compute_pc(\@gene_ids, \%gxp_hash);

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

=head3 LoadRegulons

    $sl->LoadRegulons($genomeID, $expDataDirectory);

Load the data for the atomic regulons. The main data is kept in the
B<atomic.regulons> file, which links each atomic regulon to its list of
features. We also need expression levels for each atomic regulon in each
experiment. These are kept in the B<ar.vectors> file. The
B<experiment.names> file describes the order in which the experiments are
recorded in the expression level vectors.

=over 4

=item genomeID

ID of the genome whose regulon data is being generated.

=item expDataDirectory

Name of the directory containing the expression data for this genome.

=back

=cut

sub LoadRegulons {
    # Get the parameters.
    my ($self, $genomeID, $expDataDirectory) = @_;
}


=head2 Legacy Methods

These deal with probe data and are no longer used.

=head3 LoadProbes

    $sl->LoadProbes($chipID, $genomeID, $expDataDirectory);

This method loads all the probes from the expression experiments and
links them to the matching contig locations and features. A probe is
identified in the database by its parent chip ID and its xy coordinates.
In the source data files, it is identified only by the xy coordinates.
The probe will be connected to each place in the contig where its DNA
string occurs. The B<probes> file contains the DNA strings; the
B<peg.probe.table> file indicates the features to which the probes are
correlated.

=over 4

=item chipID

ID of the chip used to generate expression data for this genome.

=item genomeID

ID of the genome whose expression data is being generated.

=item expDataDirectory

Directory containing the genome's expression data.

=back

=cut

sub LoadProbes {
    # Get the parameters.
    my ($self, $chipID, $genomeID, $expDataDirectory) = @_;
    # Get the FIG object.
    my $fig = $self->source();
    # Check to see if we have a probe file.
    my $fileName = "$expDataDirectory/probes";
    if (! -f $fileName) {
        # We don't, so make a note of it.
        Trace("No probe data found for $genomeID.") if T(ERDBLoadGroup => 2);
        $self->Add(missingProbes => 1);
    } else {
        # We do, so we need the contigs.
        Trace("Reading contig information for $genomeID to match against probes for $chipID.") if T(ERDBLoadGroup => 3);
        # Get the contigs for this genome. For each contig, we need its forward-strand
        # DNA.
        my $contigDNA = {};
        for my $contig ($fig->contigs_of($genomeID)) {
            my $len = $fig->contig_ln($genomeID, $contig);
            $contigDNA->{$contig} = $fig->dna_seq($genomeID, "${contig}_1_$len");
        }
        # Now we loop through the probes.
        my $ih = Open(undef, "<$expDataDirectory/probes");
        while (! eof $ih) {
            # Get this probe.
            my ($probe, $seq) = Tracer::GetLine($ih);
            # Compute the ID and the xy-coordinates.
            my ($x, $y) = split /_/, $probe;
            my $probeID = "$chipID:$probe";
            $self->Track(probes => $probeID, 500);
            # Create the probe and link it to the chip.
            $self->PutE(Probe => $probeID, sequence => $seq);
            $self->PutR(ConsistsOf => $chipID, $probeID, x_location => $x, y_location => $y);
            # Look for the probe on the contigs.
            for my $contig (keys %$contigDNA) {
                my $dna = $contigDNA->{$contig};
                $self->FindProbeInContig($probeID, $seq, $contig, $dna, '+');
                $self->FindProbeInContig($probeID, FIG::reverse_comp($seq), $contig,
                                         $dna, '-');
            }
        }
        # Close the probe file.
        close $ih;
    }
    # Now we need to read through the probe-to-peg table to connect the probes to
    # features.
    my $ih = Open(undef, "<$expDataDirectory/peg.probe.table");
    while (! eof $ih) {
        my ($fid, $probe) = Tracer::GetLine($ih);
        $self->Track(connections => "$fid:$probe", 1000);
        $self->PutR(OverlapsWith => "$chipID:$probe", $fid);
    }
}


=head3 FindProbeInContig

    $sl->FindProbeInContig($probeID, $seq, $contig, $contigDNA, $strand);

Generate the links between a probe and a contig on the indicated strand.
The contig will be searched for occurrences of the probe DNA, and the
hits will be used to generate I<AlignsWith> records.

=over 4

=item probeID

ID of the probe in question.

=item seq

DNA sequence of the probe.

=item contig

ID of the contig to search.

=item contigDNA

DNA sequence of the contig to search.

=item strand

Strand relevant to this search. If the strand is C<->, then the incoming
probe sequence should be the reverse complement.

=back

=cut

sub FindProbeInContig {
    # Get the parameters.
    my ($self, $probeID, $seq, $contig, $contigDNA, $strand) = @_;
    # Get the sequence length.
    my $len = length($seq);
    # This will track the current position in the contig.
    my $off = 0;
    # This will contain the location found.
    my $found;
    while (($found = index($contigDNA, $seq, $off)) >= 0) {
        $self->PutR(AlignsWith => $probeID, $contig, begin => $found,
                    len => $len, dir => $strand);
        $off = $found + 1;
        $self->Add(probeMatch => 1);
    }
}


1;
