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

package ReactionSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use HTML;
    use base 'BaseSproutLoader';

=head1 Sprout Reaction Load Group Class

=head2 Introduction

The Reaction Load Group includes all of the major reaction and compound tables.

=head3 new

    my $sl = ReactionSproutLoader->new($erdb, $source, $options, @tables);

Construct a new ReactionSproutLoader object.

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
    my @tables = sort qw(Reaction ReactionURL Compound CompoundName CompoundCAS IsIdentifiedByCAS HasCompoundName IsAComponentOf Scenario Catalyzes HasScenario IsInputFor IsOutputOf ExcludesReaction IncludesReaction IsOnDiagram IncludesReaction);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the reaction and compound files.

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
        Trace("Generating reaction data.") if T(2);
        # We need some hashes to prevent duplicates.
        my %compoundNames = ();
        my %compoundCASes = ();
        # First we create the compounds.
        my %compounds = map { $_ => 1 } $fig->all_compounds();
        for my $cid (keys %compounds) {
            # Check for names.
            my @names = $fig->names_of_compound($cid);
            # Each name will be given a priority number, starting with 1.
            my $prio = 0;
            for my $name (@names) {
                if (! exists $compoundNames{$name}) {
                    $self->PutE(CompoundName => $name);
                    $compoundNames{$name} = 1;
                }
                $self->PutR(HasCompoundName => $cid, $name, priority => ++$prio);
            }
            # Create the main compound record. Note that the first name
            # becomes the label.
            my $label = (@names > 0 ? $names[0] : $cid);
            $self->PutE(Compound => $cid, label => $label);
            # Check for a CAS ID.
            my $cas = $fig->cas($cid);
            if ($cas) {
                $self->PutR(IsIdentifiedByCAS => $cid, $cas);
                $self->PutE(CompoundCAS => $cas);
            }
        }
        # All the compounds are set up, so we need to loop through the reactions next. First,
        # we initialize the discriminator index. This is a single integer used to insure
        # duplicate elements in a reaction are not accidentally collapsed.
        my $discrim = 0;
        my %reactions = map { $_ => 1 } $fig->all_reactions();
        for my $reactionID (keys %reactions) {
            # Create the reaction record.
            $self->PutE(Reaction => $reactionID, rev => $fig->reversible($reactionID));
            # Compute the reaction's URL.
            my $url = HTML::reaction_link($reactionID);
            # Put it in the ReactionURL table.
            $self->PutE(ReactionURL => $reactionID, url => $url);
            # Now we need all of the reaction's compounds. We get these in two phases,
            # substrates first and then products.
            for my $product (0, 1) {
                # Get the compounds of the current type for the current reaction. FIG will
                # give us 3-tuples: [ID, stoichiometry, main-flag]. At this time we do not
                # have location data in SEED, so it defaults to the empty string.
                my @compounds = $fig->reaction2comp($reactionID, $product);
                for my $compData (@compounds) {
                    # Extract the compound data from the current tuple.
                    my ($cid, $stoich, $main) = @{$compData};
                    # Link the compound to the reaction.
                    $self->PutR(IsAComponentOf => $cid, $reactionID,
                                discriminator => $discrim++, loc => "",
                                main => $main, product => $product,
                                stoichiometry => $stoich);
                }
            }
        }
        # Now we run through the subsystems and roles, generating the scenarios
        # and connecting the reactions. We'll need some hashes to prevent
        # duplicates and a counter for compound group keys.
        my %roles = ();
        my %scenarios = ();
        my @subsystems = sort keys %{$self->GetSubsystems()};
        for my $subName (@subsystems) {
            my $sub = $fig->get_subsystem($subName);
            Trace("Processing $subName reactions.") if T(3);
            # Get the subsystem's reactions.
            my %reactions = $sub->get_hope_reactions();
            # Loop through the roles, connecting them to the reactions.
            for my $role (keys %reactions) {
                # Only process this role if it is new.
                if (! $roles{$role}) {
                    $roles{$role} = 1;
                    my @reactions = @{$reactions{$role}};
                    for my $reaction (@reactions) {
                        $self->PutR(Catalyzes => $role, $reaction);
                    }
                }
            }
            Trace("Processing $subName scenarios.") if T(3);
            # Get the subsystem's scenarios. Note we ignore un-named scenarios.
            # None of them have any data, so we don't need to keep them.
            my @scenarioNames = grep { $_ } $sub->get_hope_scenario_names();
            # Loop through the scenarios, creating scenario data.
            for my $scenarioName (@scenarioNames) {
                $self->Track(Scenarios => $scenarioName, 100);
                # Link this scenario to this subsystem.
                $self->PutR(HasScenario => $subName, $scenarioName);
                # If this scenario is new, we need to create it.
                if (! $scenarios{$scenarioName}) {
                    Trace("Creating scenario $scenarioName.") if T(3);
                    $scenarios{$scenarioName} = 1;
                    # Create the scenario itself.
                    $self->PutE(Scenario => $scenarioName);
                    # Attach the input compounds.
                    for my $input ($sub->get_hope_input_compounds($scenarioName)) {
                        $self->PutR(IsInputFor => $input, $scenarioName);
                    }
                    # Now we need to set up the output compounds. They come in two
                    # groups, which we mark 0 and 1.
                    my $outputGroupID = 0;
                    # Set up the output compounds.
                    for my $outputGroup ($sub->get_hope_output_compounds($scenarioName)) {
                        # Attach the compounds.
                        for my $compound (@$outputGroup) {
                            $self->PutR(IsOutputOf => $compound, $scenarioName,
                                        auxiliary => $outputGroupID);
                        }
                        $outputGroupID = 1;
                    }
                    # Create the reaction lists.
                    my @addReactions = $sub->get_hope_additional_reactions($scenarioName);
                    for my $reaction (@addReactions) {
                        $self->PutR(IncludesReaction => $scenarioName, $reaction);
                    }
                    my @notReactions = $sub->get_hope_ignore_reactions($scenarioName);
                    for my $reaction (@notReactions) {
                        $self->PutR(ExcludesReaction => $scenarioName, $reaction);
                    }
                    # Link the maps.
                    my @maps = $sub->get_hope_map_ids($scenarioName);
                    for my $map (@maps) {
                        $self->PutR(IsOnDiagram => $scenarioName, "map$map");
                    }
                }
            }
            # Clear this subsystem from the cache.
            $fig->clear_subsystem_cache();
        }
    }
}


1;
