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

package SaplingFunctionLoader;

    use strict;
    use Tracer;
    use Stats;
    use SeedUtils;
    use SAPserver;
    use Sapling;
    use base qw(SaplingDataLoader);

=head1 Sapling Function Loader

This class changes the functional assignments on one or more features and provides
methods for performing other incremental feature changes, such as adding and
deleting features and changing genome names. (Basically, it started out being for
changes to functional assignments, and evolved due to operational concerns into a
general repository for small database changes.)

=head2 Main Methods

=head3 Load

    my $stats = SaplingFunctionLoader::Load($sap, \%newFunctions);

Change the functional assignments for the specified features.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item newFunctions

Reference to a hash that maps feature IDs to 2-tuples, each 2-tuple consisting of (0) the
new functional assignment and (1) the annotator making the assignment. Each feature's
functional assignment will be updated to the new value.

=back

=cut

sub Load {
    # Get the parameters.
    my ($sap, $newFunctions) = @_;
    # Create the loader object.
    my $loaderObject = SaplingFunctionLoader->new($sap);
    # Loop through the incoming features.
    for my $fid (keys %$newFunctions) {
        $loaderObject->UpdateFeature($fid, $newFunctions->{$fid}[0], $newFunctions->{$fid}[1]);
    }
    # Return the statistics.
    return $loaderObject->{stats};
}

=head3 Process

    my $stats = SaplingFunctionLoader::Process($sap, $fileName);

Process the functional assignment updates in a file. The file should be a standard tab-
delimited file with the feature ID in the first column, the name of the annotator making the
assignment in the second, and the new functional assignment in the third.

=over 4

=item sap

L</Sapling> object for accessing the database.

=item fileName

Name of the file containing the functional assignment changes.

=item RETURN

Returns a statistics object describing the activity during the updates.

=back

=cut

sub Process {
    # Get the parameters.
    my ($sap, $fileName) = @_;
    # We'll store our functional assignments in here.
    my %assignments;
    # Get the changes from the file.
    my $ih = Open(undef, "<$fileName");
    while (! eof $ih) {
        my ($fid, $name, $function) = Tracer::GetLine($ih);
        $assignments{$fid} = [$function, $name];
    }
    close $ih;
    # Perform the functional assignment updates.
    my $stats = ChangeFunctions($sap, \%assignments);
    # Return the result.
    return $stats;
}



=head2 Loader Object Methods

=head3 new

    my $loaderObject = SaplingFunctionLoader->new($sap);

Create a loader object that can be used to facilitate updating functional assignments
for features.

=over 4

=item sap

L<Sapling> object used to access the target database.

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
    my ($class, $sap) = @_;
    # Create the object.
    my $retVal = SaplingDataLoader::new($class, $sap, qw(fids));
    # Return the result.
    return $retVal;
}

=head3 UpdateFunction

    $loaderObject->UpdateFunction($fid, $newFunction);

Update the functional assignment of the specified feature without making an
annotation about it.

This is a more primitive version of L</UpdateFeature> that is used when the
annotations are being processed separately.

=over 4

=item fid

ID of the feature whose functional assignment is to be updated.

=item newFunction

New functional assignment to give to the feature.

=back

=cut

sub UpdateFunction {
    # Get the parameters.
    my ($self, $fid, $newFunction, $user) = @_;
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Only proceed if the feature exists.
    if ($sap->Exists(Feature => $fid)) {
        # Disconnect the feature from its current roles.
        $sap->Disconnect('IsFunctionalIn', Feature => $fid);
        # Connect it to its new roles.
        $self->ConnectFunctionRoles($fid, $newFunction);
        # Update the feature with the new functional role.
        $sap->UpdateEntity('Feature', $fid, function => $newFunction);
    }
}

=head3 DeleteFeature

    $loaderObject->DeleteFeature($fid);

Delete a single feature from the database. This will not delete the protein
sequence (if any), only the records directly related to the feature itself.

=over 4

=item fid

ID of the feature to delete.

=back

=cut

sub DeleteFeature {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Get the Sapling database.
    my $sap = $self->{sap};
    # We want to delete any aliases that belong only to this feature. This
    # Requires going out to the identifier table and then back, counting
    # the number of times each identifier is encountered.
    my %aliases;
    my @aliasRows = $sap->GetFlat("IsIdentifiedBy Identifies",
                       'IsIdentifiedBy(from-link) = ?', [$fid],  'Identifies(from-link)');
    for my $aliasRow (@aliasRows) {
        $aliases{$aliasRow}++
    }
    # Now delete all the aliases found that have only a single occurrence.
    for my $alias (keys %aliases) {
        if ($aliases{$alias} == 1) {
            $sap->Delete(Identifier => $alias);
        }
    }
    # Finally, delete the feature itself.
    $sap->Delete(Feature => $fid);
}

=head3 ChangeGenomeName

    $loaderObject->ChangeGenomeName($genomeID, $newName);

Change the scientific name of a genome. This is a simple, uncomplicated update designed to
prevent a need to reload the entire genome in the face of a common environmental change.

=over 4

=item genomeID

ID of the genome getting a new scientific name.

=item newName

New scientific name for the genome.

=back

=cut

sub ChangeGenomeName {
    # Get the parameters.
    my ($self, $genomeID, $newName) = @_;
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Update the genome record.
    $sap->UpdateEntity(Genome => $genomeID, scientific_name => $newName);
}

=head3 UpdateFeature

    $loaderObject->UpdateFeature($fid, $newFunction, $user);

Update the functional assignment of the specified feature.

=over 4

=item fid

ID of the feature whose functional assignment is to be updated.

=item newFunction

New functional assignment to give to the feature.

=item user

Name of the annotator responsible for the new assignment.

=back

=cut

sub UpdateFeature {
    # Get the parameters.
    my ($self, $fid, $newFunction, $user) = @_;
    # Update the functional assignment.
    $self->UpdateFunction($fid, $newFunction);
    # Update the annotation.
    $self->MakeAnnotation($fid, "Set FIG function to\n$newFunction", $user);
    # Record this feature.
    $self->{stats}->Add(fids => 1);
}



1;