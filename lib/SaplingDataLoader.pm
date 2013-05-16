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

package SaplingDataLoader;

    use strict;
    use Tracer;
    use Stats;
    use SeedUtils;
    use SAPserver;
    use Sapling;
    use AliasAnalysis;

=head1 Sapling Data Loader

This is the base class for packages that load the Sapling database from
SEED data files.

=head2 Loader Object Methods

=head3 new

    my $loaderObject = SaplingDataLoader->new($sap, @stats);

Create a loader object that can be used to facilitate loading Sapling data from a
directory.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item stats

List of names for statistics to be initialized in the statistics object.

=back

The object created contains the following fields.

=over 4

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
    my ($class, $sap, @stats) = @_;
    # Create the object.
    my $retVal = {
        sap => $sap,
        stats => Stats->new(@stats),
        supportRecords => {}
    };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Internal Utility Methods

=head3 DeleteRelatedRecords

    DeleteRelatedRecords($sap, $genome, $stats, $relName, $entityName);

Delete all the records in the named entity and relationship relating to the
specified genome and roll up the statistics in the specified statistics object.

=over 4

=item sap

L<Sapling> object for accessing the database.

=item genome

ID of the relevant genome.

=item stats

L<Stats> object for tracking the delete activity.

=item relName

Name of a relationship from the B<Genome> table.

=item entityName

Name of the entity on the other side of the relationship.

=back

=cut

sub DeleteRelatedRecords {
    # Get the parameters.
    my ($sap, $genome, $stats, $relName, $entityName) = @_;
    # Get all the relationship records.
    my (@targets) = $sap->GetFlat($relName, "$relName(from-link) = ?", [$genome],
                                  "to-link");
    Trace(scalar(@targets) . " entries found for delete of $entityName via $relName.") if T(3) && @targets;
    # Loop through the relationship records, deleting them and the target entity
    # records.
    for my $target (@targets) {
        # Delete the relationship instance.
        $sap->DeleteRow($relName, $genome, $target);
        $stats->Add("delete-$relName" => 1);
        # Delete the entity instance.
        my $subStats = $sap->Delete($entityName, $target);
        # Roll up the statistics.
        $stats->Accumulate($subStats);
    }
}

=head3 ExtractFields

    my %fieldHash = SaplingGenomeLoader::ExtractFields($tableName, $dataHash);

Extract from the incoming hash the field names and values from the specified table.

=over 4

=item tableName

Name of the table whose field names and values are desired.

=item dataHash

Reference to a hash mapping fully-qualified ERDB field names to values.

=item RETURN

Returns a hash containing only the fields from the specified table and their values.

=back

=cut

sub ExtractFields {
    # Get the parameters.
    my ($tableName, $dataHash) = @_;
    # Declare the return variable.
    my %retVal;
    # Extract the desired fields.
    for my $field (keys %$dataHash) {
        # Is this a field for the specified table?
        if ($field =~ /^$tableName\(([^)]+)/) {
            # Yes, put it in the output hash.
            $retVal{$1} = $dataHash->{$field};
        }
    }
    # Return the computed hash.
    return %retVal;
}

=head3 InsureEntity

    my $createdFlag = $loaderObject->InsureEntity($entityType => $id, %fields);

Insure that the specified record exists in the database. If no record is found of the
specified type with the specified ID, one will be created with the indicated fields.

=over 4

=item $entityType

Type of entity to check.

=item id

ID of the entity instance in question.

=item fields

Hash mapping field names to values for all the fields in the desired entity record except
for the ID.

=item RETURN

Returns TRUE if a new object was created, FALSE if it already existed.

=back

=cut

sub InsureEntity {
    # Get the parameters.
    my ($self, $entityType, $id, %fields) = @_;
    # Get the database.
    my $sap = $self->{sap};
    # Get the support record ID hash.
    my $supportHash = $self->{supportRecords};
    # Denote we haven't created a new record.
    my $retVal = 0;
    # Get the sub-hash for this entity type.
    my $entityHash = $supportHash->{$entityType};
    if (! defined $entityHash) {
        $entityHash = {};
        $supportHash->{$entityType} = $entityHash;
    }
    # Check for this instance.
    if (! $entityHash->{$id}) {
        # It's not found. Check the database.
        if (! $sap->Exists($entityType => $id)) {
            # It's not in the database either, so create it.
            $sap->InsertObject($entityType, id => $id, %fields);
            $self->{stats}->Add(insertSupport => 1);
            $retVal = 1;
        }
        # Mark the record in the hash so we know we have it.
        $entityHash->{$id} = 1;
    }
    # Return the insertion indicator.
    return $retVal;
}

=head3 ConnectFunctionRoles

    $self->ConnectFunctionRoles($fid, $function);

Connect the specified feature to the roles indicated by its functional assignment.

=over 4

=item fid

ID of the feature of interest.

=item function

Functional assignment for the feature. Most of the time, this corresponds to a single role,
but that is not always the case.

=back

=cut

sub ConnectFunctionRoles {
    # Get the parameters.
    my ($self, $fid, $function) = @_;
    # Get the statistics object.
    my $stats = $self->{stats};
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Get the roles and the error count from the function.
    my ($roles, $errors) = SeedUtils::roles_for_loading($function);
    # Accumulate the errors in the stats object.
    $stats->Add(roleErrors => $errors);
    # Is this a suspicious function?
    if (! defined $roles) {
        # Yes, so track it.
        $stats->Add(badFunction => 1);
    } else {
        # No, connect the roles.
        for my $role (@$roles) {
            # Insure this role exists.
            my $hypo = hypo($role);
            $self->InsureEntity(Role => $role, hypothetical => $hypo);
            # Connect it to the feature.
            $sap->InsertObject('IsFunctionalIn', from_link => $role, to_link => $fid);
        }
    }
}

=head3 ComputeAnnotationID

    my $annotationID = SaplingDataLoader::ComputeAnnotationID($fid, $keyStamp);

Compute the annotation ID for the specified feature and timestamp. The annotation ID is an
inverted number designed so that higher timestamps sort later in the ordering.

=over 4

=item fid

Relevant feature ID.

=item keyStamp

Timestamp to be used to form the key.

=item RETURN

Returns an ID string formed from the feature ID and the inverted timestamp.

=back

=cut

sub ComputeAnnotationID {
    # Get the parameters.
    my ($fid, $keyStamp) = @_;
    # Compute the annotation ID from the feature ID and keystamp.
    my $retVal = "$fid:" . Tracer::Pad(9999999999 - $keyStamp, 10, 1, "0");
    # Return the result.
    return $retVal;
}

=head3 ComputeKeyStamp

    my $keyStamp = SaplingDataLoader::ComputeKeyStamp($annotationID, $default);

Compute the timestamp value from the specified annotation ID. The timestamp portion is
parsed out and then inverted to get the original time value.

=over 4

=item annotationID

The annotation ID to parse for the timestamp.

=item default

Default value to return if the original annotation ID is undefined or invalid.

=item RETURN

Returns the timestamp value used to compute the original annotation ID.

=back

=cut

sub ComputeKeyStamp {
    # Get the parameters.
    my ($annotationID, $default) = @_;
    # Declare the return variable. We initialize it to the default value.
    my $retVal = $default;
    # Parse out the timestamp portion of the annotation ID.
    if ($annotationID && $annotationID =~ /:(\d+)/) {
        # If we found one, convert it to a timestamp.
        $retVal = 9999999999 - $1;
    }
    # Return the result.
    return $retVal;
}

=head3 CreateIdentifier

    $loaderObject->CreateIdentifier($alias, $conf, $aliasType, $fid);

Link an identifier to a feature. The identifier is presented in prefixed form and is of the
specified type and the specified confidence level.

=over 4

=item alias

Identifier to connect to the feature.

=item conf

Confidence level (C<A> curated, C<B> normal, C<C> protein only).

=item aliasType

Type of alias (e.g. C<NCBI>, C<LocusTag>).

=item fid

ID of the relevant feature.

=back

=cut

sub CreateIdentifier {
    # Get the parameters.
    my ($self, $alias, $conf, $aliasType, $fid) = @_;
    # Get the Sapling object.
    my $sap = $self->{sap};
    # Compute the identifier's natural form.
    my $natural = $alias;
    if ($natural =~ /[:|](.+)/ && $aliasType ne 'SEED') {
        $natural = $1;
    }
    # Insure the identifier exists in the database.
    $self->InsureEntity(Identifier => $alias, source => $aliasType, natural_form => $natural);
    # Connect the identifier to the feature.
    $sap->InsertObject('IsIdentifiedBy', to_link => $alias, from_link => $fid, conf => $conf);
}

=head3 ProcessAliases

    $loaderObject->ProcessAliases($fid, \@aliases);

Create all the aliases for the specified feature. Each alias will be analyzed to determine
its type and processed accordingly.

=over 4

=item fid

ID of the feature to which the aliases apply.

=item aliases

Reference to a list of the aliases for the specified feature.

=back

=cut

sub ProcessAliases {
    # Get the parameters.
    my ($self, $fid, $aliases) = @_;
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Get the statistics object.
    my $stats = $self->{stats};
    # Loop through the aliases.
    for my $alias (@$aliases) {
        my $normalized;
        # Determine the type.
        my $aliasType = AliasAnalysis::TypeOf($alias);
        $stats->Add(aliasAll => 1);
        # Is this a recognized type?
        if ($aliasType) {
            $stats->Add(aliasNormal => 1);
            # Yes. Write it normally.
            $self->CreateIdentifier($alias, B => $aliasType, $fid);
        } elsif ($alias =~ /^LocusTag:(.+)/ || $alias =~ /^(?:locus|locus_tag|LocusTag)\|(.+)/) {
            # No, but this is a specially-marked locus tag.
            $normalized = "LocusTag:$1";
            $stats->Add(aliasLocus => 1);
            $self->CreateIdentifier($normalized, B => 'LocusTag', $fid);
        } elsif ($normalized = AliasAnalysis::IsNatural(LocusTag => $alias)) {
            # No, but this is a natural locus tag.
            $stats->Add(aliasLocus => 1);
            $self->CreateIdentifier($normalized, B => 'LocusTag', $fid);
        } elsif ($normalized = AliasAnalysis::IsNatural(GENE => $alias)) {
            # No, but this is a natural gene name.
            $stats->Add(aliasGene => 1);
            $self->CreateIdentifier($normalized, B => 'GENE', $fid);
        } elsif ($alias =~ /^\d+$/) {
            # Here it's a naked number, which means it's a GI number
            # of some sort.
            $stats->Add(aliasGI => 1);
            $self->CreateIdentifier("gi|$alias", B => 'NCBI', $fid);
        } elsif ($alias =~ /^protein_id\|(.+)/) {
            # Here we have a REFSEQ protein ID. Right now we don't have a way to
            # handle that, because we don't know the feature's protein ID here.
            $stats->Add(aliasProtein => 1);
        } elsif ($alias =~ /[:|]/) {
            # Here it's an alias of an unknown type, so we skip it.
            $stats->Add(aliasUnknown => 1);
        } else {
            # Here it's a miscellaneous type.
            $stats->Add(aliasMisc => 1);
            $self->CreateIdentifier($alias, B => 'Miscellaneous', $fid);
        }
    }
    # Add an identifier for the FIG ID itself.
    $self->CreateIdentifier($fid, A => 'SEED', $fid);
}

=head3 AddFeature

    $loaderObject->AddFeature($fid, $function, $locations, $aliases, $protein, $evidence);

Add a new feature to the database. The feature will be connected to the roles implied by
the functional assignment, its location(s) will be stored, and the necessary aliases will be
attached. If it is a PEG, its protein assignment will also be put in place.

=over 4

=item fid

ID of the feature to add.

=item function

Functional assignment for the feature.

=item locations

A string containing a comma-delimited list of the feature's locations in SEED format.

=item aliases

Reference to a list of the feature's aliases. If it has no aliases, this parameter must
be an empty list.

=item protein (optional)

The protein translation for this feature.

=item evidence (optional)

A string containing a comma-delimited list of the feature's evidence codes.

=back

=cut

sub AddFeature {
    # Get the parameters.
    my ($self, $fid, $function, $locations, $aliases, $protein, $evidence) = @_;
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Get the statistics object.
    my $stats = $self->{stats};
    # Parse the feature ID to get the genome and feature type.
    unless ($fid =~ /^fig\|(\d+\.\d+)\.(\w+)\.\d+/) {
        # Here the feature ID is invalid.
        $stats->Add(badFeatureID => 1);
        Trace("Invalid feature ID $fid.") if T(0);
    } else {
        my $genomeID = $1;
        my $featureType = $2;
        # This will record the number of errors found.
        my $errorCount = 0;
        # Verify that we have a protein sequence iff this is a PEG.
        if ($featureType eq 'peg' && ! $protein) {
            Trace("Missing protein sequence for $fid.") if T(0);
            $errorCount++;
            $stats->Add(missingProtein => 1);
        } elsif ($featureType ne 'peg' && $protein) {
            Trace("Protein sequence provided for non-encoding feature $fid.") if T(0);
            $errorCount++;
            $stats->Add(extraProtein => 1);
        }
        # We need to analyze the locations next. The following list will contain the
        # location components, in order.
        my @locs;
        # Get the maximum location  segment length.
        my $maxLength = $sap->TuningParameter('maxLocationLength');
        # This will record the total number of base pairs.
        my $dnaLength = 0;
        # Process the locations.
        for my $loc (split m/\s*,\s*/, $locations) {
            # Parse the location.
            unless ($loc =~ /^(.+)_(\d+)_(\d+)$/) {
                # Here the location is invalid.
                $stats->Add(badLocation => 1);
                $errorCount++;
                Trace("Invalid location $loc for $fid.") if T(0);
            } else {
                # Save the pieces of the location.
                my ($contig, $start, $end) = ($1, $2, $3);
                my ($dir, $len);
                if ($start <= $end) {
                    $dir = '+';
                    $len = $end + 1 - $start;
                } else {
                    $dir = '-';
                    $len = $start + 1 - $end;
                }
                # Record the length.
                $dnaLength += $len;
                # Fix the contig ID. Sometimes it comes in without the genome ID prefixed
                # to it.
                unless ($contig =~ /^\d+\.\d+:/) {
                    $contig = "$genomeID:$contig";
                }
                # The next processing depends on the direction we're going: we need
                # to break up the location into segments so that each segment is no
                # greater than the maximum length.
                if ($dir eq '+') {
                    # Here the location is on the forward strand. We peel off segments
                    # from the left.
                    while ($len > $maxLength) {
                        push @locs, [$contig, $start, $dir, $maxLength];
                        $len -= $maxLength;
                        $start += $maxLength;
                        $stats->Add(dnaSegmented => 1);
                    }
                    # Store the residual segment. There will always be one because
                    # the loop condition insures the length never becomes zero
                    # unless the entire location is zero-length on entry.
                    push @locs, [$contig, $start, $dir, $len];
                } else {
                    # Here the location is on the backward strand. We peel off
                    #segments from the right.
                    while ($len > $maxLength) {
                        push @locs, [$contig, $start - $maxLength + 1, $dir, $maxLength];
                        $len -= $maxLength;
                        $start -= $maxLength;
                        $stats->Add(dnaSegmented => 1);
                    }
                    # Store the residual segment. Again, the loop condition
                    # insures there will always be one.
                    push @locs, [$contig, $start - $len + 1, $dir, $len];
                }
            }
        }
        # Only proceed if no errors were found.
        if (! $errorCount) {
            # Make this feature part of the genome.
            $sap->InsertObject('IsOwnerOf', from_link => $genomeID, to_link => $fid);
            # Create the feature record.
            $sap->InsertObject('Feature', id => $fid, feature_type => $featureType,
                               function => $function, locked => 0, sequence_length => $dnaLength);
            $stats->Add(addFeature => 1);
            # Connect it to its locations.
            my $ordinal = 1;
            for my $loc (@locs) {
                my ($contig, $begin, $dir, $len) = @$loc;
                $sap->InsertObject('IsLocatedIn', from_link => $fid, to_link => $contig,
                                   begin => $begin, dir => $dir, len => $len,
                                   ordinal => $ordinal);
                $ordinal++;
                $stats->Add(addIsLocatedIn => 1);
            }
            # Connect it to its roles.
            $self->ConnectFunctionRoles($fid, $function);
            # If this is a protein, we need to process the protein sequence.
            if ($protein) {
                # Compute the key for the protein sequence.
                my $protID = $sap->ProteinID($protein);
                # Insure the protein exists.
                $self->InsureEntity(ProteinSequence => $protID, sequence => $protein);
                # Connect the feature to it.
                $sap->InsertObject('IsProteinFor', from_link => $protID, to_link => $fid);
                $stats->Add(addIsProteinFor => 1);
            }
            # Add the evidence codes (if any).
            if ($evidence) {
                for my $evCode (split m/\s*,\s*/, $evidence) {
                    $sap->InsertValue($fid, 'Feature(evidence-code)', $evCode);
                    $stats->Add(addEvidenceCode => 1);
                }
            }
            # Finally, connect the aliases.
            $self->ProcessAliases($fid, $aliases);
        }
    }
}

=head3 MakeAnnotation

    $loaderObject->MakeAnnotation($fid, $message, $user, $timeStamp);

Make an annotation against the specified feature. This method simply adds an
annotation; if the annotation relates to a functional assignment it will not
update the assignment as well.

=over 4

=item fid

ID of the feature to be annotated.

=item message

Text of the annotation.

=item user

Name of the user who made the annotation.

=item timeStamp (optional)

Time at which the annotation was made. If omitted, the current time will be used.

=back

=cut

sub MakeAnnotation {
    # Get the parameters.
    my ($self, $fid, $message, $user, $timeStamp) = @_;
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Get the current time if no timestamp was provided.
    if (! $timeStamp) {
        $timeStamp = time();
    }
    # Convert a master assignment to a FIG assignment.
    $message =~ s/Set master function/Set FIG function/;
    # Compute the annotation ID for this timestamp.
    my $newID = ComputeAnnotationID($fid, $timeStamp);
    # Is it already in the database?
    if ($sap->Exists("Annotation", $newID)) {
        # Yes, so we need to compute a better one. Get the timestamp for the last annotation update
        # to this feature. One has to exist, because we found a duplicate.
        my ($id) = $sap->GetFlat("Annotation", "Annotation(id) LIKE ? ORDER BY Annotation(id) LIMIT 1",
                                 ["$fid:%"], 'id');
        # Get a new timestamp by incrementing its time value.
        my $oldStamp = ComputeKeyStamp($id, 0) + 1;
        # Create the annotation ID.
        $newID = ComputeAnnotationID($fid, $oldStamp);
    }
    # Create the annotation.
    $sap->InsertObject("IsAnnotatedBy", from_link => $fid, to_link => $newID);
    $sap->InsertObject("Annotation", id => $newID, annotation_time => $timeStamp,
                       annotator => $user, comment => $message);
}

=head2 The Process Method

Each loader must provide a C<Process> method for processing input from the
master file of load instructions. The master file contains a load type in the
first column that indicates the relevant load class (e.g. C<Function> for
L<SaplingFunctionLoader>). The remaining columns are the parameters passed to
the load method in sequence. The load method first clears existing data (if
necessary), then loads the new data.

    my $stats = SaplingDataLoader::Process($sap, @parms);

=cut


1;