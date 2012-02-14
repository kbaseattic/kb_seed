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

package SubsystemSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSproutLoader';

=head1 Sprout Subsystem Load Group Class

=head2 Introduction

The  Load Group includes all of the major subsystem-based tables.

=head3 new

    my $sl = SproutLoader->new($erdb, $source, $options, @tables);

Construct a new SproutLoader object.

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
    my @tables = sort qw(Diagram RoleOccursIn Subsystem Role RoleEC IsIdentifiedByEC Catalyzes SSCell ContainsFeature IsGenomeOf IsRoleOf OccursInSubsystem ParticipatesIn HasSSCell RoleSubset GenomeSubset ConsistsOfRoles ConsistsOfGenomes HasRoleSubset HasGenomeSubset SubsystemClass SubsystemHopeNotes);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the subsystem-based files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG object.
    my $fig = $self->source();
    # Get the subsystem list.
    my $subHash = $self->GetSubsystems();
    # Check the section type.
    if ($self->global()) {
        # In global mode, we generate the subsystem/role data.
        Trace("Generating subsystem data.") if T(2);
        # Get the list of Sprout genomes. We need this for pruning the genome subsets.
        # The genomes are the section IDs that look like genome numbers.
        my %genomeHash = map { $_ => 1 } grep { $_ =~ /\d+\.\d+/ } BaseSproutLoader::GetSectionList($sprout, $fig);
        # This hash will contain the roles for each EC. When we're done, this
        # information will be used to generate the Catalyzes table.
        my %ecToRoles = ();
        # Loop through the subsystems. Our first task will be to create the
        # roles. We do this by looping through the subsystems and creating a
        # role hash. The hash tracks each role ID so that we don't create
        # duplicates. As we move along, we'll connect the roles and subsystems
        # and memorize up the reactions.
        my ($genomeID, $roleID);
        my %roleData = ();
        for my $subsysID (sort keys %$subHash) {
            # Get the subsystem object.
            my $sub = $fig->get_subsystem($subsysID);
            # Only proceed if the subsystem has a spreadsheet.
            if (defined($sub) && ! $sub->{empty_ss}) {
                Trace("Creating subsystem $subsysID.") if T(3);
                $self->Add("subsystemIn");
                # Get the subsystem description. If it's undefined we change it to a
                # null string.
                my $description = $sub->get_description() || "";
                # Create the subsystem record.
                $self->PutE(Subsystem => $subsysID, curator => $sub->get_curator(),
                            version => $sub->get_version(), description => $description,
                            notes => $sub->get_notes);
                # Add the hope notes.
                my $hopeNotes = $sub->get_hope_curation_notes();
                if ($hopeNotes) {
                    $self->PutE(SubsystemHopeNotes => $subsysID, 'hope-curation-notes' => $hopeNotes);
                }
                # Now for the classification string. This comes back as a list
                # reference and we convert it to a splitter-delimited string.
                my $classList = $fig->subsystem_classification($subsysID);
                my $classString = join($FIG_Config::splitter, grep { $_ } @$classList);
                $self->PutE(SubsystemClass => $subsysID, classification => $classString);
                # Connect the subsystem to its roles. Each role is a column in the subsystem spreadsheet.
                for (my $col = 0; defined($roleID = $sub->get_role($col)); $col++) {
                    # Get the role's abbreviation.
                    my $abbr = $sub->get_role_abbr($col);
                    # Get its relevance.
                    my $aux = ($fig->is_aux_role_in_subsystem($subsysID, $roleID) ? 1 : 0);
                    # Get its reaction note.
                    my $hope_note = $sub->get_hope_reaction_notes($roleID) || "";
                    # Connect to this role.
                    $self->Add(roleIn => 1);
                    $self->PutR(OccursInSubsystem => $roleID, $subsysID, abbr => $abbr, auxiliary => $aux,
                                'column-number' => $col, 'hope-reaction-note' => $hope_note);
                    # If it's a new role, add it to the role table.
                    if (! exists $roleData{$roleID}) {
                        # Add the role.
                        $self->Put('Role', id => $roleID);
                        $roleData{$roleID} = 1;
                        # Check for an EC number.
                        if ($roleID =~ /\(EC (\d+\.\d+\.\d+\.\d+)\s*\)\s*$/) {
                            my $ec = $1;
                            $self->PutR(IsIdentifiedByEC => $roleID, $ec);
                            # Check to see if this is our first encounter with this EC.
                            if (exists $ecToRoles{$ec}) {
                                # No, so just add this role to the EC list.
                                push @{$ecToRoles{$ec}}, $roleID;
                            } else {
                                # Output this EC.
                                $self->PutE(RoleEC => $ec);
                                # Create its role list.
                                $ecToRoles{$ec} = [$roleID];
                            }
                        }
                    }
                }
                # Connect this subsystem's roles to its reactions.
                my %reactions = $sub->get_hope_reactions();
                for my $role (keys %reactions) {
                    my @reactions = @{$reactions{$role}};
                    for my $reaction (@reactions) {
                        $self->PutR(Catalyzes => $role, $reaction);
                    }
                }
            }
            # Now we need to generate the subsets. The subset names must be concatenated to
            # the subsystem name to make them unique keys. There are two types of subsets:
            # genome subsets and role subsets. We do the role subsets first.
            my @subsetNames = $sub->get_subset_names();
            for my $subsetID (@subsetNames) {
                # Create the subset record.
                my $actualID = "$subsysID:$subsetID";
                $self->PutE(RoleSubset => $actualID);
                # Connect the subset to the subsystem.
                $self->PutR(HasRoleSubset => $subsysID, $actualID);
                # Connect the subset to its roles.
                my @roles = $sub->get_subsetC_roles($subsetID);
                for my $roleID (@roles) {
                    $self->PutR(ConsistsOfRoles => $actualID, $roleID);
                }
            }
            # Next the genome subsets.
            @subsetNames = $sub->get_subset_namesR();
            for my $subsetID (@subsetNames) {
                # Create the subset record.
                my $actualID = "$subsysID:$subsetID";
                $self->PutE(GenomeSubset => $actualID);
                # Connect the subset to the subsystem.
                $self->PutR(HasGenomeSubset => $subsysID, $actualID);
                # Connect the subset to its genomes.
                my @genomes = $sub->get_subsetR($subsetID);
                for my $genomeID (@genomes) {
                    # Only include genomes that are ours.
                    if ($genomeHash{$genomeID}) {
                        $self->PutR(ConsistsOfGenomes => $actualID, $genomeID);
                    }
                }
            }
            # Clear the subsystem cache to make room for more data.
            $fig->clear_subsystem_cache();
        }
        # Now we loop through the diagrams. We need to create the diagram records
        # and link each diagram to its roles. Note that only roles which occur
        # in subsystems (and therefore appear in the %ecToRoles hash) are
        # included.
        for my $map ($fig->all_maps()) {
            Trace("Loading diagram $map.") if T(3);
            # Get the diagram's descriptive name.
            my $name = $fig->map_name($map);
            $self->PutE(Diagram => $map, name => $name);
            # Now we need to link all the map's roles to it.
            # A hash is used to prevent duplicates.
            my %roleHash = ();
            for my $ec ($fig->map_to_ecs($map)) {
                if (exists $ecToRoles{$ec}) {
                    for my $role (@{$ecToRoles{$ec}}) {
                        if (! $roleHash{$role}) {
                            $self->PutR(RoleOccursIn => $role, $map);
                            $roleHash{$role} = 1;
                        }
                    }
                }
            }
        }
    } else {
        # Here we have a genome section.
        my $genomeID = $self->section();
        Trace("Connecting $genomeID to subsystems.") if T(3);
        # Get the subsystem data for this genome.
        my %subLists = $fig->get_all_subsystem_pegs($genomeID);
        # Loop through the subsystems.
        for my $subsysID (sort keys %subLists) {
            # Only proceed if this subsystem is one of ours.
            if (exists $subHash->{$subsysID}) {
                Trace("Processing subsystem $subsysID.") if T(3);
                # Get the subsystem's roles. We create a hash that maps role ID to its
                # column index.
                my $col = 0;
                my $subObject = $fig->get_subsystem($subsysID);
                my %roles = map { $_ => $col++ } $subObject->get_roles();
                # Create a list for the PEGs we find. This list will be used
                # to generate cluster numbers.
                my %pegsFound = ();
                my $aPegFound = 0;
                # Create hashes that maps spreadsheet IDs to pegs in cells.
                # We will use this to generate the ContainsFeature data
                # after we have the cluster numbers.
                my %cellPegs = ();
                # We'll stash the variant code in here.
                my $variant;
                # Loop through the subsystem's pegs.
                for my $pegTuple (@{$subLists{$subsysID}}) {
                    my ($roleID, $pegID, $variantCode) = @$pegTuple;
                    # Save the variant ID. (It should be the same for each peg.)
                    $variant = $variantCode;
                    # Only proceed if this feature exists.
                    if ($fig->is_deleted_fid($pegID)) {
                        $self->Add('deleted-pegs' => 1);
                    } else {
                        # Get the column number.
                        my $col = $roles{$roleID};
                        # Compute the spreadsheet cell ID.
                        my $cellID = ERDB::DigestKey("$subsysID:$genomeID:$col");
                        # Remember this feature. Note we put -1 in the pegs-found
                        # hash. This is to help us when we generate cluster numbers.
                        $pegsFound{$pegID} = -1;
                        $aPegFound = 1;
                        # Record this cells.
                        push @{$cellPegs{$cellID}}, $pegID;
                    }
                }
                # Generate all the subsystem's spreadsheet cells for this genome.
                for my $roleID (keys %roles) {
                    # Compute the cell ID.
                    my $columnNumber = $roles{$roleID};
                    my $cellID = ERDB::DigestKey("$subsysID:$genomeID:$columnNumber");
                    # Connect it to the subsystem.
                    $self->PutE(SSCell => $cellID, column_number => $columnNumber);
                    $self->PutR(HasSSCell => $subsysID, $cellID);
                    $self->PutR(IsRoleOf => $roleID, $cellID);
                    $self->PutR(IsGenomeOf => $genomeID, $cellID);
                }
                # If we found some cells for this genome, we need to compute clusters and
                # denote it participates in the subsystem.
                if ($aPegFound) {
                    # Connect the genome to the subsystem.
                    $self->PutR(ParticipatesIn => $genomeID, $subsysID,
                                'variant-code' => $variant);
                    # Partition the PEGs found into clusters.
                    my @clusters = $fig->compute_clusters([keys %pegsFound], $subObject);
                    for (my $i = 0; $i <= $#clusters; $i++) {
                        my $subList = $clusters[$i];
                        for my $peg (@{$subList}) {
                            $pegsFound{$peg} = $i;
                        }
                    }
                    # Create the ContainsFeature data.
                    for my $cellID (keys %cellPegs) {
                        my $cellList = $cellPegs{$cellID};
                        for my $cellPeg (@$cellList) {
                            $self->PutR(ContainsFeature => $cellID, $cellPeg,
                                        'cluster-number' => $pegsFound{$cellPeg});
                        }
                    }
                }
                # Clear the cache to make room for more subsystems.
                $fig->clear_subsystem_cache();
            }
        }
    }
}

1;