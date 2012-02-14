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

package DrugSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSproutLoader';

=head1 Sprout Drug Load Group Class

=head2 Introduction

The Drug Load Group includes all of the major drug target tables.

=head3 new

    my $sl = DrugSproutLoader->new($erdb, $source, $options, @tables);

Construct a new DrugSproutLoader object.

=over 4

=item erdb

[[SproutPm]] object for the database being loaded.

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
    my @tables = sort qw(PDB Ligand IsProteinForFeature DocksWith);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the drug target files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG object.
    my $fig = $self->source();
    # Is this the global section?
    if ($self->global()) {
        # Create the ligand table. This information can be found in the zinc_name attribute.
        Trace("Loading ligands.") if T(2);
        # The ligand list is huge, so we have to get it in pieces. We also have to check for duplicates.
        my $last_zinc_id = "";
        my $zinc_id = "";
        my $done = 0;
        while (! $done) {
            # Get the next 10000 ligands. We insist that the object ID is greater than
            # the last ID we processed.
            Trace("Loading batch starting with ZINC:$zinc_id.") if T(3);
            my @attributeData = $fig->query_attributes('$object > ? AND $key = ? ORDER BY $object LIMIT 10000',
                                                       ["ZINC:$zinc_id", "zinc_name"]);
            Trace(scalar(@attributeData) . " attribute rows returned.") if T(3);
            if (! @attributeData) {
                # Here there are no attributes left, so we quit the loop.
                $done = 1;
            } else {
                # Process the attribute data we've received.
                for my $zinc_data (@attributeData) {
                    # The ZINC ID is found in the first return column, prefixed with the word ZINC.
                    if ($zinc_data->[0] =~ /^ZINC:(\d+)$/) {
                        $zinc_id = $1;
                        $self->Track(zincIDs => $zinc_id, 10000);
                        # Check for a duplicate. These are very, very common.
                        if ($zinc_id eq $last_zinc_id) {
                            $self->Add('duplicate-zinc' => 1);
                        } else {
                            # Here it's safe to output the ligand. The ligand name is the attribute value
                            # (third column in the row).
                            $self->PutE(Ligand => $zinc_id, name => $zinc_data->[2]);
                            # Insure we don't try to add this ID again.
                            $last_zinc_id = $zinc_id;
                        }
                    } else {
                        $self->AddWarning('zinc-bad-id' => "Invalid zinc ID \"$zinc_data->[0]\" in attribute table.") if T(0);
                    }
                }
            }
        }
    } else {
        # Here we're working with a genome. We need to find all the PDBs that connect
        # to this genome's features.
        Trace("Connecting features.") if T(2);
        my $genome = $self->section();
        Trace("Generating PDB connections for $genome.") if T(3);
        # We'll keep track of the PDBs we find in here.
        my %pdbHash;
        # Get all of the PDBs that BLAST against this genome's features.
        my @attributeData = $fig->get_attributes("fig|$genome%", 'PDB');
        for my $pdbData (@attributeData) {
            # The PDB ID is coded as a subkey.
            if ($pdbData->[1] !~ /PDB::(.+)/i) {
                $self->AddWarning('pdb-key-error' => "Invalid PDB ID \"$pdbData->[1]\" in attribute table.");
            } else {
                my $pdbID = lc $1;
                # Insure the PDB is in the hash.
                if (! exists $pdbHash{$pdbID}) {
                    $pdbHash{$pdbID} = 0;
                }
                # The score and locations are coded in the attribute value.
                if ($pdbData->[2] !~ /^([^;]+)(.*)$/) {
                    $self->AddWarning('pdb-data-error' => "Invalid PDB data for $pdbID and feature $pdbData->[0].");
                } else {
                    my ($score, $locData) = ($1,$2);
                    # The location data may not be present, so we have to start with some
                    # defaults and then check.
                    my ($start, $end) = (1, 0);
                    if ($locData) {
                        $locData =~ /(\d+)-(\d+)/;
                        $start = $1;
                        $end = $2;
                    }
                    # If we still don't have the end location, compute it from
                    # the feature length.
                    if (! $end) {
                        # Most features have one location, but we do a list iteration
                        # just in case.
                        my @locations = $fig->feature_location($pdbData->[0]);
                        $end = 0;
                        for my $loc (@locations) {
                            my $locObject = BasicLocation->new($loc);
                            $end += $locObject->Length;
                        }
                    }
                    # Decode the score.
                    my $realScore = FIGRules::DecodeScore($score);
                    # Connect the PDB to the feature.
                    $self->PutR(IsProteinForFeature => $pdbID, $pdbData->[0],
                                'start-location' => $start, score => $realScore,
                                'end-location' => $end);
                }
            }
        }
        # Output the PDBs found.
        Trace("Unspooling PDBs") if T(2);
        for my $pdbID (sort keys %pdbHash) {
            $self->Track(PDBs => $pdbID, 100);
            # We need to find every ligand that docks with this PDB. Unfortunately, the
            # uploaded PDB data has upper-case IDs, while we use lower-case so that we
            # map to the IDs on the PDB web site. We fix this by asking for both.
            my @dockData = $fig->query_attributes('($object = ? OR $object = ?) AND $key = ? AND $value < ?',
                                                  ["PDB:" . uc $pdbID, "PDB:$pdbID",
                                                   'docking_results', $FIG_Config::dockLimit]);
            Trace(scalar(@dockData) . " rows of docking data found.") if T(3);
            # Count the docking data actually used.
            my $docksUsed = 0;
            # Loop through the docking data.
            for my $dockData (@dockData) {
                # Get the docking data components. We ignore the object ID, since we already
                # know what it is.
                my (undef, $docking_key, @valueData) = @{$dockData};
                # Extract the ZINC ID from the docking key. Note that the "ZINC" string
                # does not always get put in correctly, so it's optional in the pattern.
                my (undef, $zinc_id) = $docking_key =~ /^docking_results::(ZINC)?(\d+)$/i;
                if (! $zinc_id) {
                    $self->AddWarning('dockdata-errors' => "Invalid docking result key $docking_key for $pdbID.") if T(0);
                } else {
                    # Get the pieces of the value and parse the energy.
                    # Note that we don't care about the rank, since
                    # we can sort on the energy level itself in our database.
                    my ($energy, $tool, $type) = @valueData;
                    my ($rank, $total, $vanderwaals, $electrostatic) = split /\s*;\s*/, $energy;
                    # Ignore predicted results.
                    if ($type ne "Predicted") {
                        # Write the result to the output.
                        $self->PutR(DocksWith => $pdbID, $zinc_id,
                                    'electrostatic-energy' => $electrostatic,
                                    reason => $type, tool => $tool,
                                    'total-energy' => $total,
                                    'vanderwaals-energy' => $vanderwaals);
                        # Count it.
                        $docksUsed++;
                    }
                }
            }
            # Output the PDB record.
            $self->PutE(PDB => $pdbID, 'docking-count' => $docksUsed);
        }
    }
}


1;
