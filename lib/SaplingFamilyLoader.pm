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

package SaplingFamilyLoader;

    use strict;
    use Tracer;
    use Stats;
    use SeedUtils;
    use SAPserver;
    use Sapling;
    use base qw(SaplingDataLoader);

=head1 Sapling Family Loader

This class reloads FIGfam data into a Sapling database from a specified
directory. This loader is designed for updating a populated database only. Links 
to features and genomes are put in, but not the features and genomes themselves.
The Family tables will be dropped and then repopulated from the flat files.

=head2 Main Methods

=head3 Process

    my $stats = SaplingFamilyLoader::Process($sap, $directory);

Reload FIGfam data from the specified directory. The existing data will be
deleted.

=over 4

=item sap

L</Sapling> object for accessing the database.

=item directory

Name of the directory containing the FIGfam data files.

=item RETURN

Returns a statistics object describing the activity during the reload.

=back

=cut

sub Process {
    # Get the parameters.
    my ($sap, $directory) = @_;
    # Create the loader object.
    my $loader = SaplingFamilyLoader->new($sap, $directory);
    # Erase the current family tables.
    my @tables = qw(Family HasMember IsCoupledTo IsFamilyFor 
                    HasRepresentativeOf);
    for my $table (@tables) {
        Trace("Clearing $table.") if T(2);
        $sap->TruncateTable($table);
    }
    # Load the new family data.
    my $stats = $loader->Load();
    # Return the result.
    return $stats;
}


=head2 Loader Object Methods

=head3 new

    my $loaderObject = SaplingExpressionLoader->new($sap, $directory);

Create a loader object that can be used to facilitate loading Sapling data from an
FIGfam release directory.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item directory

Name of the directory containing the FIGfam release.

=back

The object created contains the following fields.

=over 4

=item supportRecords

A hash of hashes, used to track the support records known to exist in the database.

=item sap

L<Sapling> object used to access the database.

=item stats

L<Stats> object for tracking statistical information about the load.

=item directory

Name of the directory containing the subsystem data.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $sap, $directory) = @_;
    # Create the object.
    my $retVal = SaplingDataLoader::new($class, $sap, qw(FIGfams));
    # Add our specialized data.
    $retVal->{directory} = $directory;
    # Return the result.
    return $retVal;
}

=head2 Internal Utility Methods

=head3 Load

    my $stats = $loader->Load();

Load the FIGfam data from the previously selected directory into the database.
The family tables shold exist, but must be empty. The statistics from the load
will be returned. 

=cut

sub Load {
    # Get the parameters.
    my ($self) = @_;
    # Get the Sapling database object and the statistics object.
    my $sap = $self->{sap};
    my $stats = $self->{stats};
    # Get the name of the FIGfam release directory.
    my $figFamDir = $self->{directory};
    Trace("FIGfams will be loaded from $figFamDir.") if T(SaplingDataLoader => 2);
    # We will keep the FIGfam IDs in here. We need them to filter the coupling
    # file.
    my %figFams;
    # Read the family functions.
    Trace("Processing family functions.") if T(SaplingDataLoader => 2);
    my $ih = Open(undef, "<$figFamDir/family.functions");
    while (! eof $ih) {
        my ($fam, $function) = Tracer::GetLine($ih);
        $stats->Add(familyFunctionRecord => 1);
        if (! defined $function) {
            $function = "";
            $stats->Add(missingFamilyFunction => 1);
        }
        # Output the family record.
        $sap->InsertObject('Family', id => $fam, family_function => $function);
        $stats->Add('insert-Family' => 1);
        # Remember that this is a valid family.
        $figFams{$fam} = 1;
        # Connect the family to its roles.
        my ($roles, $errors) = SeedUtils::roles_for_loading($function);
        if (! defined $roles) {
            # Here the family function was suspicious.
            $stats->Add(suspiciousFamilyFunction => 1);
        } else {
            # Here we have a good function.
            for my $role (@$roles) {
                $stats->Add(figfamRole => 1);
                $sap->InsertObject('IsFamilyFor', from_link => $fam,
                        to_link => $role);
                $stats->Add('insert-IsFamilyFor' => 1);
            }
            $stats->Add(badFigfamRoles => $errors);
        }
    }
    close $ih;
    # Now we need to process the memberships. This hash will map each family
    # to a hash of the associated genomes.
    my %famGenomes;
    # We also need a list of the genomes in the database, so that we only
    # process features in those genomes.
    my %genomeHash = map { $_ => 1 } $sap->GetFlat('Genome', "", [], 'id');
    # Read the memberships.
    Trace("Processing family memberships.") if T(SaplingDataLoader => 2);
    $ih = Open(undef, "<$figFamDir/families.2c");
    while (! eof $ih) {
        my ($fam, $featureID) = Tracer::GetLine($ih);
        $stats->Add(familyFeatureRecord => 1);
        # Extract the genome ID.
        if ($featureID =~ /^fig\|(\d+\.\d+)/) {
            # Insure it's one of ours.
            my $genomeID = $1;
            if (! $genomeHash{$genomeID}) {
                $stats->Add(familyFeatureNotInDb => 1);
            } else {
                # It is. Connect the family to the feature.
                $sap->InsertObject('HasMember', from_link => $fam,
                        to_link => $featureID);
                $stats->Add('insert-HasMember' => 1);
                # Connect the family to the genome.
                $famGenomes{$fam}{$1} = 1;
            }
        }
    }
    close $ih;
    # Connect the FIGfams to the genomes found.
    Trace("Connecting families to genomes.") if T(SaplingDataLoader => 2);
    for my $fam (keys %famGenomes) {
        my $genomeH = $famGenomes{$fam};
        for my $genome (keys %$genomeH) {
            $sap->InsertObject('HasRepresentativeOf', from_link => $genome,
                    to_link => $fam);
            $stats->Add('insert-HasRepresentativeOf' => 1);
        }
    }
    # Now read the coupling data.
    Trace("Processing coupling data.") if T(SaplingDataLoader => 2);
    $ih = Open(undef, "<$figFamDir/coupling.values");
    while (! eof $ih) {
        my ($from, $to, $expScore, $contigScore) = Tracer::GetLine($ih);
        $stats->Add(familyCouplingRecord => 1);
        # Verify that both FIGfams are ours and are distinct.
        if (! $figFams{$from} || ! $figFams{$to}) {
            $stats->Add(couplingFigFamNotFound => 1);
        } elsif ($from eq $to) {
            $stats->Add(couplingFigFamReflexive => 1);
        } else {
            # Everything's okay, so we can connect the two figfams together.
            # Insure the ordering is correct.
            if ($from > $to) {
                ($from, $to) = ($to, $from);
            }
            # Forge the connection.
            $sap->InsertObject('IsCoupledTo', from_link => $from, 
                        to_link => $to, co_occurrence_evidence => $contigScore,
                        co_expression_evidence => $expScore);
            $stats->Add('insert-IsCoupledTo' => 1);
        }
    }
    close $ih;
    # Return the statistics.
    return $stats;
}

1;