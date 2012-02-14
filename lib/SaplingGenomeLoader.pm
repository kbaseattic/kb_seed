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

package SaplingGenomeLoader;

    use strict;
    use Tracer;
    use Stats;
    use SeedUtils;
    use SAPserver;
    use Sapling;
    use AliasAnalysis;
    use base qw(SaplingDataLoader);

=head1 Sapling Genome Loader

This package contains the methods used to load a genome into the Sapling from a genome
directory. This is not very efficient if you are trying to create a full database,
but is useful if you wish to add genomes one at a time. The information loaded will
include the basic genome data, the contigs and the DNA, subsystems, and the features.

=head2 Main Methods

=head3 Load

    my $stats = SaplingGenomeLoader::Load($sap, $genome, $directory);

Load a genome from a genome directory into the sapling database.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item genome

ID of the genome being loaded.

=item directory

Name of the directory containing the genome information.

=item disconnected

True if the application is disconnected from the network - do not
attempt to contact a SAP server for more data.

=item assignHash

Hash of feature IDs to functional assignments. Deleted features are removed, which
means only features listed in this hash can be legally inserted into the database.

=back

=cut

sub Load {
    # Get the parameters.
    my ($sap, $genome, $directory, $disconnected) = @_;
    # Create the loader object.
    my $loaderObject = SaplingGenomeLoader->new($sap, $genome, $directory, $disconnected);
    # Load the contigs.
    Trace("Loading contigs for $genome.") if T(SaplingDataLoader => 2);
    $loaderObject->LoadContigs();
    # Load the features.
    Trace("Loading features for $genome.") if T(SaplingDataLoader => 2);
    $loaderObject->LoadFeatures();
    # Check for annotation history. If we have it, load the history records into the
    # database.
    if (-f "$directory/annotations") {
        Trace("Processing annotations.") if T(SaplingDataLoader => 3);
        $loaderObject->LoadAnnotations("$directory/annotations");
    }
    # Load the subsystem bindings.
    Trace("Loading subsystems for $genome.") if T(SaplingDataLoader => 2);
    $loaderObject->LoadSubsystems();
    # Create the Genome record and taxonomy information.
    Trace("Creating root for $genome.") if T(SaplingDataLoader => 2);
    $loaderObject->CreateGenome();
    # Return the statistics.
    return $loaderObject->{stats};
}

=head3 ClearGenome

    my $stats = SaplingGenomeObject::ClearGenome($sap, $genome);

Delete the specified genome and all the related records from the specified sapling
database. This method can also be used to clean up after a failed or aborted load.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item genome

ID of the genome to delete.

=item RETURN

Returns a statistics object counting the records deleted.

=back

=cut

sub ClearGenome {
    # Get the parameters.
    my ($sap, $genome) = @_;
    # Create the statistics object.
    my $stats = Stats->new();
    # Delete the DNA sequences.
    my @seqs = $sap->GetFlat('DNASequence', 'DNASequence(id) LIKE ?', ["$genome:%"], 'id');
    for my $seq (@seqs) {
        my $delStats = $sap->Delete(DNASequence => $seq);
        $stats->Accumulate($delStats);
    }
    # Delete the contigs.
    SaplingDataLoader::DeleteRelatedRecords($sap, $genome, $stats, 'IsMadeUpOf', 'Contig');
    # Delete the features.
    SaplingDataLoader::DeleteRelatedRecords($sap, $genome, $stats, 'IsOwnerOf', 'Feature');
    # Delete the molecular machines.
    SaplingDataLoader::DeleteRelatedRecords($sap, $genome, $stats, 'Uses', 'MolecularMachine');
    # Delete the genome itself.
    my $subStats = $sap->Delete(Genome => $genome);
    # Accumulate the statistics from the delete.
    $stats->Accumulate($subStats);
    # Return the statistics object.
    return $stats;
}


=head3 Process

    my $stats = SaplingGenomeLoader::Process($sap, $genome, $directory);

Load genome data from the specified directory. If the genome data already
exists in the database, it will be deleted first.

=over 4

=item sap

L</Sapling> object for accessing the database.

=item genome

ID of the genome whose  data is being loaded.

=item directory

Name of the directory containing the genome data files.

=item disconnected

True if the application is disconnected from the network - do not
attempt to contact a SAP server for more data.

=item RETURN

Returns a statistics object describing the activity during the reload.

=back

=cut

sub Process {
    # Get the parameters.
    my ($sap, $genome, $directory, $disconnected) = @_;
    # Clear the existing data for the specified genome.
    my $stats = ClearGenome($sap, $genome);
    # Load the new expression data from the specified directory.
    my $newStats = Load($sap, $genome, $directory, $disconnected);
    # Merge the statistics.
    $stats->Accumulate($newStats);
    # Return the result.
    return $stats;
}


=head2 Loader Object Methods

=head3 new

    my $loaderObject = SaplingGenomeLoader->new($sap, $genome, $directory, $disconnected);

Create a loader object that can be used to facilitate loading genome data from a
directory.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item genome

ID of the genome being loaded.

=item directory

Name of the directory containing the genome information.

=item disconnected

Set to a true value if the application should be considered to be disconnected
from the network - that is, do not attempt to connect to a Sapling server
to load subsystem data.

=back

The object created contains the following fields.

=over 4

=item directory

Name of the directory containing the genome data.

=item genome

ID of the genome being loaded.

=item supportRecords

A hash of hashes, used to track the support records known to exist in the database.

=item sap

L<Sapling> object used to access the database.

=item stats

L<Stats> object for tracking statistical information about the load.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $sap, $genome, $directory, $disconnected) = @_;
    # Create the object.
    my $retVal = SaplingDataLoader::new($class, $sap, qw(contigs dna pegs rnas));
    # Add our specialized data.
    $retVal->{genome} = $genome;
    $retVal->{directory} = $directory;
    # Leave the assignment hash undefined until we populate it.
    $retVal->{assignHash} = undef;
    $retVal->{disconnected} = defined($disconnected) ? 1 : 0;
    # Return the result.
    return $retVal;
}

=head3 LoadContigs

    $loaderObject->LoadContigs();

Load the contig information into the database. This includes the contigs themselves and
the DNA. The number of contigs will be recorded as the C<contigs> statistic, the
number of base pairs as the C<dna> statistic, and the number of GC instances as the
C<gc_content> statistic.

=cut

sub LoadContigs {
    # Get this object.
    my ($self) = @_;
    # Open the contigs file from the genome directory.
    my $ih = Open(undef, "<$self->{directory}/contigs");
    # Get the length of a DNA segment.
    my $segmentLength = $self->{sap}->TuningParameter('maxSequenceLength');
    # Get the genome ID.
    my $genome = $self->{genome};
    # These variables will contain the current contig ID, the current contig length,
    # the ordinal of the current chunk, the accumulated DNA sequence, and its length.
    my ($contigID, $contigLen, $ordinal, $chunk, $chunkLen) = (undef, 0, 0, '', 0);
    # Loop through the contig file.
    while (! eof $ih) {
        # Get the current record.
        my $line = <$ih>; chomp $line;
        # Is this the start of a new contig?
        if ($line =~ /^>(\S+)/) {
            # Yes. Save the contig ID.
            my $newContigID = $1;
            # Is there a current contig?
            if (defined $contigID) {
                # Yes. Output the current chunk.
                $self->OutputChunk($contigID, $ordinal, $chunk);
                # Output the contig.
                $self->OutputContig($contigID, $contigLen);
            }
            # Compute the new contig ID. We need to insure it has a genome ID in front.
            $self->FixContig(\$newContigID);
            # Initialize the new contig.
            $contigID = $newContigID;
            $contigLen = 0;
            $ordinal = 0;
            $chunk = '';
            $chunkLen = 0;
        } else {
            # Here we have more DNA in the current contig. Are we at the end of
            # the current chunk?
            my $lineLen = length($line);
            my $newChunkLen = $chunkLen + $lineLen;
            if ($newChunkLen < $segmentLength) {
                # No. Add this line to the chunk.
                $chunk .= $line;
                $chunkLen += $lineLen;
            } else {
                # Yes. Create the actual chunk.
                $chunk .= substr($line, 0, $segmentLength - $chunkLen);
                # Write it out.
                $self->OutputChunk($contigID, $ordinal, $chunk);
                # Set up the new chunk.
                $chunk = substr($line, $segmentLength - $chunkLen);
                $ordinal++;
                $chunkLen = length($chunk);
            }
            # Update the contig length.
            $contigLen += $lineLen;
        }
    }
    # Is there a current contig?
    if (defined $contigID) {
        # Yes. Output the residual chunk.
        $self->OutputChunk($contigID, $ordinal, $chunk);
        # Output the contig itself.
        $self->OutputContig($contigID, $contigLen);
    }
}

=head3 OutputChunk

    $loaderObject->OutputChunk($contigID, $ordinal, $chunk);

Output a chunk of DNA for the specified contig.

=over 4

=item contigID

ID of the contig being output.

=item ordinal

Ordinal number of this chunk.

=item chunk

DNA sequence comprising this chunk.

=back

=cut

sub OutputChunk {
    # Get the parameters.
    my ($self, $contigID, $ordinal, $chunk) = @_;
    # Get the sapling object.
    my $sap = $self->{sap};
    # Compute the chunk ID.
    my $chunkID = "$contigID:" . Tracer::Pad($ordinal, 7, 1, '0');
    # Connect this sequence to the contig.
    $sap->InsertObject('HasSection', from_link => $contigID, to_link => $chunkID);
    # Create the DNA sequence.
    $sap->InsertObject('DNASequence', id => $chunkID, sequence => $chunk);
    # Record the chunk.
    $self->{stats}->Add(chunks => 1);
    # Update the GC count.
    $self->{stats}->Add(gc_content => ($chunk =~ tr/GCgc//));
}

=head3 OutputContig

    $loaderObject->OutputContig($contigID, $contigLen);

Write out the current contig.

=over 4

=item contigID

ID of the contig being written out.

=item contigLen

Length of the contig in base pairs.

=back

=cut

sub OutputContig {
    # Get the parameters.
    my ($self, $contigID, $contigLen) = @_;
    # Get the sapling object.
    my $sap = $self->{sap};
    # Connect the contig to the genome.
    $sap->InsertObject('IsMadeUpOf', from_link => $self->{genome}, to_link => $contigID);
    # Output the contig record.
    $sap->InsertObject('Contig', id => $contigID, length => $contigLen);
    # Record the contig.
    $self->{stats}->Add(contigs => 1);
    $self->{stats}->Add(dna => $contigLen);
}

=head3 LoadFeatures

    $loaderObject->LoadFeatures();

Load the feature data into the database. This includes all of the features,
their protein sequences, and their subsystem information. The number of
features of each type will be stored in the statistics object, identified by
the feature type.

=cut

sub LoadFeatures {
    # Get the parameters.
    my ($self) = @_;
    # Read in the functional assignments.
    Trace("Reading functional assignments.") if T(SaplingDataLoader => 3);
    my $assignHash = $self->ReadAssignments();
    $self->{assignHash} = $assignHash;
    # Get the directory of feature types.
    my $featureDir = "$self->{directory}/Features";
    my @types = Tracer::OpenDir("$self->{directory}/Features", 1);
    # Check for protein sequences. If we have some, load them into a hash.
    my $protHash = {};
    if (-f "$featureDir/peg/fasta") {
        Trace("Processing protein sequences.") if T(SaplingDataLoader => 3);
        $protHash = $self->LoadProteinData("$featureDir/peg/fasta");
    }
    # Create the feature records for the types found.
    for my $type (@types) {
        # Insure this is a genuine feature directory.
        if (-f "$featureDir/$type/tbl") {
            # Yes. Read in the evidence codes (if any).
            my $evHash = {};
            my $tranFile = "$featureDir/$type/Attributes/transaction_log";
            if (-f $tranFile) {
                $evHash = $self->LoadEvidenceCodes($tranFile);
            }
            # Now load the feature data.
            $self->LoadFeatureData($featureDir, $type, $protHash, $evHash);
        }
    }
}

=head3 LoadEvidenceCodes

    my $evHash = $loaderObject->LoadEvidenceCodes($attributeFile);

Load the evidence codes from the specified attribute transaction log file into a
hash. The log file is in tab-delimited format. The first column contains the
transaction code (either C<ADD> or C<DELETE>), the second column a feature ID,
the third an attribute name (we'll ignore everything but C<evidence_code>), and
the fourth the attribute value.

=over 4

=item attributeFile

Name of the attribute transaction log file.

=item RETURN

Returns a reference to a hash mapping each feature ID to a comma-delimited list
of its evidence codes.

=back

=cut

sub LoadEvidenceCodes {
    # Get the parameters.
    my ($self, $attributeFile) = @_;
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Get the statistics object.
    my $stats = $self->{stats};
    # Get the assignment hash: we use this to filter the feature IDs.
    my $assignHash = $self->{assignHash};
    # Open the attribute log file for input.
    my $ih = Open(undef, "<$attributeFile");
    # This two-dimensional hash will hold the evidence codes for each feature.
    my %retVal;
    # Loop through the attribute log file.
    while (! eof $ih) {
        # Get the current attribute record.
        my ($command, $fid, $key, $value) = Tracer::GetLine($ih);
        $stats->Add(attributeLine => 1);
        # Insure we have all the pieces we need.
        if (! $command || ! $fid || $key ne 'evidence_code') {
            $stats->Add(attributeLineSkipped => 1);
        } elsif (! $assignHash->{$fid}) {
            # Here the attribute is for a deleted feature.
            $stats->Add(attributeFidSkipped => 1);
        } else {
            # Get the sub-hash for this feature.
            if (! exists $retVal{$fid}) {
                $retVal{$fid} = {};
            }
            my $featureSubHash = $retVal{$fid};
            # Process according to the command.
            if ($command eq 'ADD') {
                # Here we are adding a new evidence code.
                $featureSubHash->{$value} = 1;
                $stats->Add(attributeAdd => 1);
            } elsif ($command eq 'DELETE') {
                # Here we are deleting an evidence code.
                delete $featureSubHash->{$value};
                $stats->Add(attributeDelete => 1);
            } else {
                # here we have an unrecognized command.
                $stats->Add(attributeCommandSkip => 1);
            }
        }
    }
    # Loop through the hash, converting each sub-hash to a comma-delimited list of
    # evidence codes.
    for my $fid (keys %retVal) {
        $retVal{$fid} = join(",", sort keys %{$retVal{$fid}});
    }
    # Return the evidence hash.
    return \%retVal;
}


=head3 LoadFeatureData

    $loaderObject->LoadFeatureData($featureDir, $type, $protHash, $evHash);

Load the basic data for each feature into the database. The number of features of
the type found will be recorded in the statistics object.

=over 4

=item featureDir

Name of the main directory containing all the feature type subdirectories.

=item type

Type of feature to load.

=item protHash

Reference to a hash mapping each feature ID for a protein-encoding gene to
its protein sequence.

=item evHash

Reference to a hash mapping each feature ID to a comma-delimited list of
its evidence codes (if any).

=back

=cut

sub LoadFeatureData {
    # Get the parameters.
    my ($self, $featureDir, $type, $protHash, $evHash) = @_;
    # Get the sapling database.
    my $sap = $self->{sap};
    # Get the statistics object.
    my $stats = $self->{stats};
    # Get the assignment hash. This tells us our functional assignments. This method is
    # also where we remove the deleted features from it.
    my $assignHash = $self->{assignHash};
    # This hash will track the features we've created. If a feature is found a second
    # time, it overwrites the original.
    my %fidHash;
    # Finally, we need the timestamp hash. The initial feature population
    # Insure we have a tbl file for this feature type.
    my $fileName = "$featureDir/$type/tbl";
    my %deleted_features;
    if (-f $fileName) {
        # We have one, so we can read through it. First, however, we need to get the list
        # of deleted features and remove them from the assignment hash. This insures
        # that they are not used by subsequent methods.
        my $deleteFile = "$featureDir/$type/deleted.features";
        if (-f $deleteFile) {
            my $dh = Open(undef, "<$deleteFile");
            while (! eof $dh) {
                my ($deletedFid) = Tracer::GetLine($dh);
                if (exists $assignHash->{$deletedFid}) {
                    delete $assignHash->{$deletedFid};
                    $stats->Add(deletedFid => 1);
		    $deleted_features{$deletedFid} = 1;
                }
            }
        }
        # Open the main file for input.
        Trace("Reading features from $fileName.") if T(SaplingDataLoader => 3);
        my $ih = Open(undef, "<$fileName");
        while (! eof $ih) {
            # Read this feature's information.
            my ($fid, $locations, @aliases) = Tracer::GetLine($ih);
            # Only proceed if the feature is NOT deleted.
            if (!$deleted_features{$fid}) {
                # If the feature already exists, delete it. (This should be extremely rare.)
                if ($fidHash{$fid}) {
                    $sap->Delete(Feature => $fid);
                    $stats->Add(duplicateFid => 1);
                }
                # If this is RNA, the alias list is always empty. Sometimes, the functional
                # assignment is found there.
                if ($type eq 'rna') {
                    if (! $assignHash->{$fid}) {
                        $assignHash->{$fid} = $aliases[0];
                    }
                    @aliases = ();
                }
                # Add the feature to the database.
		my $function = $assignHash->{$fid} // "";
                $self->AddFeature($fid, $function, $locations, \@aliases,
                                  $protHash->{$fid}, $evHash->{$fid});
                # Denote we've added this feature, so that if a duplicate occurs we're ready.
                $fidHash{$fid} = 1;
            }
        }
    }
}


=head3 LoadProteinData

    my $protHash = $self->LoadProteinData($fileName);

Load the protein sequences from the named FASTA file. The sequences will be stored
in a hash by FIG feature ID.

=over 4

=item fileName

Name of the FASTA file containing the protein sequences for this genome.

=item RETURN

Returns a hash mapping feature IDs to protein sequences.

=back

=cut

sub LoadProteinData {
    # Get the parameters.
    my ($self, $fileName) = @_;
    # Open the FASTA file for input.
    my $ih = Open(undef, "<$fileName");
    # Create the return hash.
    my $retVal = {};
    # We'll track the current protein in here.
    my $fid;
    my $sequence = "";
    # Loop through the input file.
    while (! eof $ih) {
        # Get the current record.
        my $line = <$ih>; chomp $line;
        # Is this a label record.
        if ($line =~ /^>(\S+)/) {
            # Yes. Save the new feature ID.
            my $newFid = $1;
            # Do we have an existing protein?
            if (defined $fid) {
                # Yes. Store it in the hash.
                $retVal->{$fid} = $sequence;
            }
            # Initialize for the next protein.
            $fid = $newFid;
            $sequence = "";
        } else {
            # Here we have more letters for the current protein.
            $sequence .= $line;
        }
    }
    # Do we have a residual protein.
    if (defined $fid) {
        # Yes. Store it in the hash.
        $retVal->{$fid} = $sequence;
    }
    # Return the hash.
    return $retVal;
}


=head3 LoadAnnotations

    $loaderObject->LoadAnnotations($fileName);

Read in the annotation history information and use it to create annotation records.

=over 4

=item fileName

Name of the annotation history file. This file is formatted with four fields per
record. Each field is on a separate line, with a double slash (C<//>) used as the
line terminator. The fields, in order, are (0) the feature ID, (1) the timestamp
(formatted as an integer), (2) the user name, and (3) the annotation text.

=back

=cut

sub LoadAnnotations {
    # Get the parameters.
    my ($self, $fileName) = @_;
    # Get the assignment Hash. We use this to filter out deleted features.
    my $assignHash = $self->{assignHash};
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Get the statistics object.
    my $stats = $self->{stats};
    # Open the input file.
    my $ih = Tracer::Open(undef, "<$fileName");
    # Loop through the input.
    while (! eof $ih) {
        # Read in the peg, timestamp, and user ID.
        my ($fid, $timestamp, $user, $text) = ReadAnnotation($ih);
        # Only proceed if the feature is not deleted.
        if ($assignHash->{$fid}) {
            # Add the annotation to this feature.
            $self->MakeAnnotation($fid, $text, $user, $timestamp);
        }
    }
}


=head3 WriteProtein

    $loaderObject->WriteProtein($fid, $sequence);

Write out the specified protein sequence and associate it with the specified feature.
This requires checking to see if the protein sequence is already in the database.

=over 4

=item fid

ID of the feature with the specified protein sequence.

=item sequence

Protein sequence for the indicated feature.

=back

=cut

sub WriteProtein {
    # Get the parameters.
    my ($self, $fid, $sequence) = @_;
    # Compute the key of the protein sequence.
    my $protID = $self->{sap}->ProteinID($sequence);
    # Insure the protein exists.
    $self->InsureEntity(ProteinSequence => $protID, sequence => $sequence);
    # Connect the feature to it.
    $self->{sap}->InsertObject('IsProteinFor', from_link => $protID, to_link => $fid);
}

=head3 LoadSubsystems

    $loaderObject->LoadSubsystems();

Load the subsystem data into the database. This includes all of the subsystems,
their categories, roles, and the bindings that connect them to this genome's features.

=cut

sub LoadSubsystems {
    # Get the parameters.
    my ($self) = @_;

    #
    # If we are running in disconnected mode, do not actually load subsystems.
    # They rely too much on information from the external sapling.
    #
    if ($self->{disconnected})
    {
	return;
    }

    # Get the sapling object.
    my $sap = $self->{sap};
    # Get the statistics object.
    my $stats = $self->{stats};
    # Get the genome ID.
    my $genome = $self->{genome};
    # Connect to the Sapling server so we can get the subsystem variant and role information.
    my $sapO = SAPserver->new();
    # This hash maps subsystem IDs to molecular machine IDs.
    my %machines;
    # This hash maps subsystem/role pairs to machine role IDs.
    my %machineRoles;
    # The first step is to create the subsystems themselves and connect them to the
    # genome. A list is given in the subsystems file of the Subsystems directory.
    my $ih = Open(undef, "<$self->{directory}/Subsystems/subsystems");
    # Create the field hash for the subsystem query.
    my @fields = qw(Subsystem(id) Subsystem(cluster-based) Subsystem(curator) Subsystem(description)
                    Subsystem(experimental) Subsystem(notes) Subsystem(private) Subsystem(usable)
                    Subsystem(version)
                    Includes(from-link) Includes(to-link) Includes(abbreviation) Includes(auxiliary)
                    Includes(sequence)
                    Role(id) Role(hypothetical) Role(role-index));
    my %fields = map { $_ => $_ } @fields;
    # Loop through the subsystems in the file, insuring we have them in the database.
    while (! eof $ih) {
        # Get this subsystem.
        my ($subsystem, $variant) = Tracer::GetLine($ih);
        Trace("Processing subsystem $subsystem variant $variant.") if T(SaplingDataLoader => 3);
        # Normalize the subsystem name.
        $subsystem = $sap->SubsystemID($subsystem);
        # Compute this subsystem's MD5.
        my $subsystemMD5 = ERDB::DigestKey($subsystem);
        # Insure the subsystem is in the database.
        if (! $sap->Exists(Subsystem => $subsystem)) {
            # The subsystem isn't present, so we need to read it. We get the subsystem,
            # its roles, and its classification information. The variant will be added
            # later if we need it.
            my $roleList = $sapO->get(-objects => "Subsystem Includes Role",
                                      -filter => {"Subsystem(id)" => ["=", $subsystem] },
                                      -fields => \%fields);
            # Only proceed if we found some roles.
            if (@$roleList > 0) {
                # Get the subsystem information from the first role and create the subsystem.
                my $roleH = $roleList->[0];
                my %subFields = SaplingDataLoader::ExtractFields(Subsystem => $roleH);
                $sap->InsertObject('Subsystem', %subFields);
                $stats->Add(subsystems => 1);
                # Now loop through the roles. The Includes records are always inserted, but the
                # roles are only inserted if they don't already exist.
                for $roleH (@$roleList) {
                    # Create the Includes record.
                    my %incFields = SaplingDataLoader::ExtractFields(Includes => $roleH);
                    $sap->InsertObject('Includes', %incFields);
                    # Insure we have the role in place.
                    my %roleFields = SaplingDataLoader::ExtractFields(Role => $roleH);
                    my $roleID = $roleFields{id};
                    delete $roleFields{id};
                    $self->InsureEntity('Role', $roleID, %roleFields);
                    # Compute the machine-role ID.
                    my $machineRoleID = join(":", $subsystemMD5, $genome, $incFields{abbreviation});
                    $machineRoles{$subsystem}{$roleID} = $machineRoleID;
                    $stats->Add(subsystemRoles => 1);
                }
            }
        } else {
            # We already have the subsystem in the database, but we still need to compute the
            # machine role IDs. We need information from the sapling server for this.
            my $subHash = $sapO->subsystem_roles(-ids => $subsystem, -aux => 1, -abbr => 1);
            # Loop through the roles.
            my $roleList = $subHash->{$subsystem};
            for my $roleTuple (@$roleList) {
                my ($roleID, $abbr) = @$roleTuple;
                my $machineRoleID = join(":", $subsystemMD5, $genome, $abbr);
                $machineRoles{$subsystem}{$roleID} = $machineRoleID;
            }
        }
        # Now we need to connect the variant to the subsystem. First, we compute the real
        # variant code by removing the asterisks.
        my $variantCode = $variant;
        $variantCode =~ s/^\*+//;
        $variantCode =~ s/\*+$//;
        # Compute the variant key.
        my $variantKey = ERDB::DigestKey("$subsystem:$variantCode");
        # Insure we have it in the database.
        if (! $sap->Exists(Variant => $variantKey)) {
            # Get the variant from the sapling server.
            my $variantH = $sapO->get(-objects => "Variant",
                                      -filter => {"Variant(id)" => ["=", $variantKey]},
                                      -fields => {"Variant(code)" => "code",
                                                  "Variant(comment)" => "comment",
                                                  "Variant(type)" => "type",
                                                  "Variant(role-rule)" => "role-rule"},
                                      -firstOnly => 1);
            $self->InsureEntity('Variant', $variantKey, %$variantH);
            # Connect it to the subsystem.
            $sap->InsertObject('Describes', from_link => $subsystem, to_link => $variantKey);
            $stats->Add(subsystemVariants => 1);
        }
        # Now we create the molecular machine connecting this genome to the subsystem
        # variant.
        my $machineID = ERDB::DigestKey("$subsystem:$variantCode:$genome");
        $sap->InsertObject('Uses', from_link => $genome, to_link => $machineID);
        $sap->InsertObject('MolecularMachine', id => $machineID, curated => 0, region => '');
        $sap->InsertObject('IsImplementedBy', from_link => $variantKey, to_link => $machineID);
        # Remember the machine ID.
        $machines{$subsystem} = $machineID;
    }
    # Now we go through the bindings file. This file connects the subsystem roles to
    # the molecular machines.
    $ih = Open(undef, "<$self->{directory}/Subsystems/bindings");
    # Loop through the bindings.
    while (! eof $ih) {
        # Get the binding data.
        my ($subsystem, $role, $fid) = Tracer::GetLine($ih);
        # Normalize the subsystem name.
        $subsystem = $sap->SubsystemID($subsystem);
        # Compute the machine role.
        my $machineRoleID = $machineRoles{$subsystem}{$role};
        # Insure it exists.
        my $created = $self->InsureEntity(MachineRole => $machineRoleID);
        if ($created) {
            # We created the machine role, so connect it to the machine.
            my $machineID = $machines{$subsystem};
            $sap->InsertObject('IsMachineOf', from_link => $machineID, to_link => $machineRoleID);
            # Connect it to the role, too.
            $sap->InsertObject('IsRoleOf', from_link => $role, to_link => $machineRoleID);
        }
        # Connect the feature.
        $sap->InsertObject('Contains', from_link => $machineRoleID, to_link => $fid);
    }
}

=head3 CreateGenome

    $loaderObject->CreateGenome();

Create the genome record.

=cut

# This hash maps cache statistics to genome record fields.
use constant GENOME_FIELDS => {genome_name => 'scientific-name',
                               genome_domain => 'domain'};
# This hash maps domains to the prokaryotic flag.
use constant PROK_FLAG => {Bacteria => 1, Archaea => 1};

sub CreateGenome {
    # Get the parameters.
    my ($self) = @_;
    # Get the genome directory.
    my $dir = $self->{directory};
    # Get the sapling database.
    my $sap = $self->{sap};
    # We'll put the genome attributes in here.
    my %fields;
    # Check for a basic statistics file.
    my $statsFile = "$dir/cache.basic_statistics";
    if (-f $statsFile) {
        # We have the statistics file, so read the major attributes from it.
        my $ih = Open(undef, "<$statsFile");
        while (! eof $ih) {
            my ($key, $value) = Tracer::GetLine($ih);
            my $fieldKey = GENOME_FIELDS->{$key};
            if ($fieldKey) {
                $fields{$fieldKey} = $value;
            }
        }
        # Translate the domain.
        $fields{domain} = ucfirst $fields{domain};
        # Denote the genome is complete.
        $fields{complete} = 1;
    } else {
        # Check to see if this genome is complete.
        $fields{complete} = (-f "$dir/COMPLETE" ? 1 : 0);
        # Get the genome name.
        my $ih = Open(undef, "<$dir/GENOME");
        my $line = <$ih>; chomp $line;
        $fields{'scientific-name'} = $line;
        # Get the taxonomy and extract the domain from it.
        $ih = Open(undef, "<$dir/TAXONOMY");
        ($fields{domain}) = split /;/, <$ih>, 2;
    }
    # Get the counts from the statistics object.
    my $stats = $self->{stats};
    $fields{contigs} = $stats->Ask('contigs');
    $fields{'dna-size'} = $stats->Ask('dna');
    $fields{pegs} = $stats->Ask('peg');
    $fields{rnas} = $stats->Ask('rna');
    $fields{gc_content} = $stats->Ask('gc_content') * 100 / $stats->Ask('dna');
    # Get the genetic code. The default is 11.
    $fields{'genetic-code'} = 11;
    my $geneticCodeFile = "$dir/GENETIC_CODE";
    if (-f $geneticCodeFile) {
        # There's a genetic code file, so we need to read it for the code.
        my $ih = Open(undef, "<$geneticCodeFile");
        ($fields{'genetic-code'}) = Tracer::GetLine($ih);
    }
    # Use the domain to determine whether or not the genome is prokaryotic.
    $fields{prokaryotic} = PROK_FLAG->{$fields{domain}} || 0;
    # Finally, add the genome ID.
    $fields{id} = $self->{genome};
    # Create the genome record.
    $sap->InsertObject('Genome', %fields);
}

=head3 ReadAssignments

    my $assignHash = $loaderObject->ReadAssignments();

Return a hash mapping each feature ID to its functional assignment. This method
essentially reads the B<assigned_functions> file into memory.

=cut

sub ReadAssignments {
    # Get the parameters.
    my ($self) = @_;
    # Create the return hash.
    my $retVal = {};
    # Loop through the assigned-functions file, storing results in the hash. Later
    # results will override earlier ones.
    my $ih = Open(undef, "<$self->{directory}/assigned_functions");
    while (! eof $ih) {
        my ($fid, $function) = Tracer::GetLine($ih);
        $retVal->{$fid} = $function;
    }
    # Return the hash built.
    return $retVal;
}


=head3 FixContig

    $loaderObject->FixContig(\$contigID);

Insure that the specified contig ID contains the genome ID.

=cut

sub FixContig {
    my ($self, $contigID) = @_;
    # Compute the new contig ID. We need to insure it has a genome ID in front.
    unless ($$contigID =~ /^\d+\.\d+\:/) {
        $$contigID = "$self->{genome}:$$contigID";
    }
}

=head3 ConnectLocation

    $loaderObject->ConnectLocation($fid, $contig, $segment, $left, $dir, $len);

Connect the specified feature to the specified contig location.

=over 4

=item fid

ID of the relevant feature.

=item contig

ID of the contig containing this segment of the feature (normalized).

=item segment

Ordinal number of this segment.

=item left

Location of the segment's leftmost base pair.

=item dir

Direction (strand) of the segment (C<+> or C<->).

=item len

Length of the segment (which must be no greater than the configured maximum).

=back

=cut

sub ConnectLocation {
    # Get the parameters.
    my ($self, $fid, $contig, $segment, $left, $dir, $len) = @_;
    # Get the sapling database.
    my $sap = $self->{sap};
    # Create the relationship.
    $sap->InsertObject('IsLocatedIn', from_link => $fid, to_link => $contig,
                       begin => $left, dir => $dir, len => $len,
                       ordinal => $segment);
    # Record it in the statistics.
    $self->{stats}->Add(segment => 1);
}

=head2 Internal Utility Methods

=head3 ReadAnnotation

    my ($fid, $timestamp, $user, $text) = SaplingGenomeLoader::ReadAnnotation($ih);

Read the next record from an annotation file. The next record must exist (that is, an
end-of-file check should have been performed before calling this method).

=over 4

=item ih

Open file handle for the annotation file.

=item RETURN

Returns a list containing the four fields of the record read-- (0) the feature ID, (1) the
timestamp, (2) the user ID, and (3) the annotation text.

=back

=cut

sub ReadAnnotation {
    # Get the parameter.
    my ($ih) = @_;
    # Read the three fixed fields.
    my $fid = <$ih>; chomp $fid;
    my $timestamp = <$ih>; chomp $timestamp;
    my $user = <$ih>; chomp $user;
    # Loop through the lines of the text field.
    my $text = "";
    my $line = <$ih>;
    while (defined($line) && $line ne "//\n") {
        $text .= $line;
        $line = <$ih>;
    }
    # Remove the trailing new-line from the text.
    chomp $text;
    # Return the fields.
    return ($fid, $timestamp, $user, $text);
}

1;
