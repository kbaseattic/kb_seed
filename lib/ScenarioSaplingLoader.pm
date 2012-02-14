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

package ScenarioSaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use Rectangle;
    use GD;
    use base 'BaseSaplingLoader';

=head1 Sapling Scenario Load Group Class

=head2 Introduction

The Scenario Load Group includes all of the major scenario-related data tables.

=head3 new

    my $sl = ScenarioSaplingLoader->new($erdb, $options, @tables);

Construct a new ScenarioSaplingLoader object.

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
    my @tables = sort qw(Scenario IsTerminusFor IsSubInstanceOf IsRelevantFor
                         HasParticipant Shows Displays Diagram DiagramContent Overlaps);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the scenario-related data files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the database object.
    my $erdb = $self->db();
    # Get the source object.
    my $fig = $self->source();
    # Is this the global section?
    if ($self->global()) {
        # Yes. Load the scenarios.
        $self->LoadScenarios($fig);
        # Load the diagrams.
        $self->LoadDiagrams($fig);
    }
}

=head3 LoadScenarios

    $sl->LoadScenarios($fig);

Create the load files for the scenario data.

=over 4

=item fig

FIG-like object used to access the scenario data.

=back

=cut

sub LoadScenarios {
    # Get the parameters.
    my ($self, $fig) = @_;
    # Get the Sapling object.
    my $erdb = $self->db();
    # We run through the subsystems and roles, generating the scenarios.
    # We'll need a role hash to prevent duplicates.
    my %roles = ();
    # This counter is used to compute scenario IDs.
    my $scenarios = 0;
    # Now loop through the subsystems.
    my @subsystems = sort keys %{$erdb->SubsystemHash()};
    for my $subName (@subsystems) {
        Trace("Processing $subName.") if T(ERDBLoadGroup => 3);
        my $sub = $fig->get_subsystem($subName);
        # Only proceed if the subsystem exists.
        if (! defined $sub) {
            $self->Add(missingSubsystem => 1);
        } elsif ($sub->{empty_ss}) {
            $self->Add(emptySubsystem => 1);
        } else {
            # Get the subsystem's reactions. This is a bit complicated, since
            # the subsystem object only gives us a role-to-reaction map.
            my %roleMap = $sub->get_hope_reactions();
            my @reactions;
            for my $reactionList (values %roleMap) {
                push @reactions, @$reactionList;
            }
            # Connect the subsystem to its diagrams.
            my @maps = $sub->get_diagrams();
            for my $mapData (@maps) {
                $self->PutR(IsRelevantFor => $mapData->[0], $subName);
            }
            # Get the subsystem's scenarios. Note we ignore un-named scenarios.
            # None of them have any data, so we don't need to keep them.
            my @scenarioNames = grep { $_ } $sub->get_hope_scenario_names();
            # Loop through the scenarios, creating scenario data.
            for my $scenarioName (@scenarioNames) {
                $self->Track(Scenarios => $scenarioName, 100);
                # Get this scenario's ID.
                $scenarios++;
                my $scenarioID = $scenarios;
                # Link this scenario to this subsystem.
                $self->PutR(IsSubInstanceOf => $subName, $scenarioID);
                # Create the scenario itself.
                Trace("Creating scenario $scenarioID: $scenarioName.") if T(3);
                $self->PutE(Scenario => $scenarioID, common_name => $scenarioName);
                # Attach the input compounds.
                for my $input ($sub->get_hope_input_compounds($scenarioName)) {
                    # Resolve the compound ID.
                    my $inputID = $self->CompoundID($input);
                    # Write the relationship record.
                    $self->PutR(IsTerminusFor => $inputID, $scenarioID,
                                group_number => 0);
                    # Now we need to set up the output compounds. They come in two
                    # groups, which we mark 1 and 2.
                    my $outputGroupID = 1;
                    # Set up the output compounds.
                    for my $outputGroup ($sub->get_hope_output_compounds($scenarioName)) {
                        # Attach the compounds.
                        for my $compound (@$outputGroup) {
                            # Resolve the compound ID.
                            my $compoundID = $self->CompoundID($compound);
                            # Write the relationship record.
                            $self->PutR(IsTerminusFor => $compoundID, $scenarioID,
                                        group_number => $outputGroupID);
                        }
                        # # Increment the group number.
                        $outputGroupID++;
                    }
                    # Now we create the reaction lists. First we have the reactions that
                    # are not in the subsystem but are part of the scenario.
                    my @addReactions = $sub->get_hope_additional_reactions($scenarioName);
                    for my $reaction (@addReactions) {
                        # Resolve the reaction ID.
                        my $reactionID = $self->ReactionID($reaction);
                        # Write the relationship record.
                        $self->PutR(HasParticipant => $scenarioID, $reactionID,
                                    type => 1);
                    }
                    # Next is the list of reactions not in the scenario. We get the list
                    # of these, and then we use it to modify the full reaction list. If
                    # the reaction is in the not-list, the type is 2. If it isn't in the
                    # not-list, the type is 0.
                    my %notReactions = map { $_ => 2 } $sub->get_hope_ignore_reactions($scenarioName);
                    for my $reaction (@reactions) {
                        # Resolve the reaction ID.
                        my $reactionID = $self->ReactionID($reaction);
                        # Write the relationship record.
                        $self->PutR(HasParticipant => $scenarioID, $reactionID,
                                    type => ($notReactions{$reaction} || 0));
                    }
                    # Link the maps.
                    my @maps = $sub->get_hope_map_ids($scenarioName);
                    for my $map (@maps) {
                        $self->PutR(Overlaps => $scenarioID, "map$map");
                    }
                }
            }
            # Clear the subsystem cache to save space.
            $fig->clear_subsystem_cache();
        }
    }
}


=head3 LoadDiagrams

    $sl->LoadDiagrams($fig);

Create the load files for the diagram data.

=over 4

=item fig

FIG-like object used to access the data.

=back

=cut

sub LoadDiagrams {
    # Get the parameters.
    my ($self, $fig) = @_;
    # Loop through the maps.
    my @maps = $fig->all_maps();
    for my $map (sort @maps) {
        $self->Track(Diagrams => $map, 20);
        # Get the map's descriptive name.
        my $name = $fig->map_name($map);
        # Compute its title. The properties of the map are read from files
        # having this title and different extensions.
        my $mapTitle = "$FIG_Config::kegg/pathway/map/$map";
        # Now we need the map itself. If it's a PNG, we use it unaltered.
        my $pngFileName;
        if (-f "$mapTitle.png") {
            $pngFileName = "$mapTitle.png";
            # Read the PNG file in as a GD::Image.
            my $diagram = GD::Image->new($pngFileName);
            # Write the diagram record.
            $self->PutE(Diagram => $map, name => $name);
            $self->PutE(DiagramContent => $map, content => $diagram);
            # Now we connect it to the compounds.
            $self->Connect($map, $mapTitle . "_cpd.coord", 'Shows', 'CompoundID');
            # Finally, the reactions.
            $self->Connect($map, $mapTitle . "_rn.coord", 'Displays', 'ReactionID');
        } else {
            $self->Add(mapNotPNG => 1);
        }
    }
}

=head3 Connect

    $sl->Connect($mapID, $fileName, $relName, $method);

Create the relationship records connecting the specified map to the
objects in the specified file. The file is tab-delimited, with the first
column being IDs of reactions or compounds, and the second through fifth
columns containing the rectangle coordinates of the compound or reaction
in the diagram.

=over 4

=item mapID

ID of the relevant map.

=item fileName

Name of the file containing the coordinate data.

=item relName

Name of the relationship to be filled from the data.

=item method

Name of the method to be used to convert IDs.

=item

=back

=cut

sub Connect {
    # Get the parameters.
    my ($self, $mapID, $fileName, $relName, $method) = @_;
    # Check the file.
    if (! -s $fileName) {
        Trace("File \"$fileName\" not found for map $mapID.") if T(ERDBLoadGroup => 1);
        $self->Add('file-missing' => 1);
    } else {
        # Open the file.
        my $ih = Open(undef, "<$fileName");
        # Loop through the records.
        while (! eof $ih) {
            # Get the ID and the coordinates.
            my ($id, @coords) = Tracer::GetLine($ih);
            # Resolve the ID.
            my $realID = eval("\$self->$method(\$id)");
            # Connect the ID to the diagram.
            $self->PutR($relName => $mapID, $realID, location => Rectangle->new(@coords));
        }
    }
}


=head3 GetFigModel

    my $figModel = $self->GetFigModel();

Return a FIGMODEL object that can be used to map KEGG IDs to our IDs for reactions
and compounds. If we don't have a FIGMODEL object yet, one will be created and
cached in this object.

=cut

sub GetFigModel {
    # Get the parameters.
    my ($self) = @_;
    # Look for a cached object.
    my $retVal = $self->{figModel};
    if (! defined $retVal) {
        # It doesn't exist, so create one.
        require FIGMODEL;
        $retVal = FIGMODEL->new();
        $self->{figModel} = $retVal;
    }
    # Return the cached object.
    return $retVal;
}

=head3 CompoundID

    my $id = $self->CompoundID($compound);

Return the ModelSEED ID for a given compound.

=over 4

=item compound

Regular compound ID to convert.

=item RETURN

Returns the internal ID for the incoming compound, or the incoming value if it is
an unknown compound.

=back

=cut

sub CompoundID {
    # Get the parameters.
    my ($self, $compound) = @_;
    # Declare the return variable.
    my $retVal = $compound;
    # Get the model object.
    #my $figModel = $self->GetFigModel();
    # Get the object for the given compound ID.
    #my $obj = $figModel->database()->get_object("cpdals", {alias => $compound});
    # If we found the compound, get its real ID.
    #if (defined($obj)) {
    #    $retVal = $obj->COMPOUND();
    #}
    # Return the result.
    return $retVal;
}

=head3 ReactionID

    my $id = $self->ReactionID($reaction);

Return the ModelSEED ID for a given reaction.

=over 4

=item reaction

Regular reaction ID to convert.

=item RETURN

Returns the internal ID for the incoming reaction, or the incoming value if it is
an unknown reaction.

=back

=cut

sub ReactionID {
    # Get the parameters.
    my ($self, $reaction) = @_;
    # Declare the return variable.
    my $retVal = $reaction;
    # Get the model object.
    #my $figModel = $self->GetFigModel();
    # Get the reaction ID.
    #$retVal = $figModel->id_of_reaction($reaction);
    # Return the result.
    return $retVal;
}

1;