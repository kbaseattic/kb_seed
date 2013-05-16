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

package SubsystemSaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use LoaderUtils;
    use SeedUtils;
    use base 'BaseSaplingLoader';

=head1 Sapling Subsystem Load Group Class

=head2 Introduction

The Subsystem Load Group includes all of the major subsystem-related tables.

=head3 new

    my $sl = SubsystemSaplingLoader->new($erdb, $options, @tables);

Construct a new SubsystemSaplingLoader object.

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
    my @tables = sort qw(Subsystem IsClassFor SubsystemClass IsSuperclassOf Includes
                         Describes Variant IsRoleOf IsImplementedBy MachineRole
                         IsMachineOf MolecularMachine Contains Uses VariantRole);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the subsystem-related files.

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
        # Yes, build the subsystem framework.
        $self->GenerateSubsystems($fig, $erdb);
    } else {
        # Get the section ID.
        my $genomeID = $self->section();
        # Generate the subsystem date for this genome.
        $self->GenerateSubsystemData($fig, $erdb, $genomeID);
    }
}

=head3 GenerateSubsystems

    $sl->GenerateSubsystems($fig, $erdb);

Generate the subsystems, variants, and roles for this database. This
method concerns itself primarily with the genome-independent part of the
subsystem framework. This includes the following tables:

    Subsystem
    Describes
    Variant
    Includes
    IsClassFor
    SubsystemClass
    IsSuperclassOf

=over 4

=item fig

Source object from which the subsystem data will be extracted.

=item erdb

Database object for the Sapling database.

=back

=cut

sub GenerateSubsystems {
    # Get the parameters.
    my ($self, $fig, $erdb) = @_;
    # Get the subsystem hash for this Sapling instance. Its key list will be
    # the list of subsystems to put in the database.
    my $subHash = $erdb->SubsystemHash();
    # We'll track the various subsystem classes in here.
    my %subClassHash = ();
    # Loop through the subsystems.
    for my $subsystem (keys %$subHash) {
        Trace("Processing subsystem $subsystem.") if T(ERDBLoadGroup => 3);
        # Get the FIG subsystem object.
        my $ssData = $fig->get_subsystem($subsystem);
        # Only proceed if we found it.
        if (! defined $ssData) {
            $self->Add(missingSubsystem => 1);
            Trace("Subsystem $subsystem not found.") if T(ERDBLoadGroup => 1);
        } elsif ($ssData->{empty_ss}) {
            $self->Add(emptySubsystem => 1);
            Trace("Subsystem $subsystem is empty.") if T(ERDBLoadGroup => 1);
        } else {
            # These will be set to 1 if the subsystem has the indicated property.
            my $experimental = 0;
            my $clustered = 0;
            # Get the subsystem's classes.
            my $classes = $ssData->get_classification();
            # Only proceed if classes exist.
            if (scalar @$classes) {
                # Check for one of the special roots. If we find it, we shift it off
                # the list.
                if ($classes->[0] =~ /Clustering/) {
                    $clustered = 1;
                    shift @$classes;
                } elsif ($classes->[0] =~ /Experimental/) {
                    $experimental = 1;
                    shift @$classes;
                }
                # Loop through the remaining classes from the bottom up.
                my $class = pop @$classes;
                if ($class) {
                    # Create the class record.
                    $self->CreateClass($class);
                    # Connect it to the subsystem.
                    $self->PutR(IsClassFor => $class, $subsystem);
                    # Is this a new class?
                    if (! $subClassHash{$class}) {
                        # Yes. We need to put it in its hierarchy.
                        while (my $newClass = pop @$classes) {
                            # Create the new class's record.
                            $self->CreateClass($newClass);
                            # Put it above the previous class.
                            $self->PutR(IsSuperclassOf => $newClass, $class);
                            # Insure we know we're done with this class.
                            $subClassHash{$class} = 1;
                            # Prepare for the next class.
                            $class = $newClass;
                        }
                    }
                }
            }
            # Get the subsystem properties.
            my $curator = $ssData->get_curator();
            my $description = $ssData->get_description();
            my $notes = $ssData->get_notes();
            my $version = $ssData->get_version();
            my $usable = ($fig->is_experimental_subsystem($subsystem) ? 0 : 1);
            my $private = ($fig->is_exchangable_subsystem($subsystem) ? 0 : 1);
            # Fix the curator.
            if (! defined $curator) {
                $curator = "unknown";
            } else {
                $curator =~ s/^master://;
            }
            # Ensure we have a description.
            if (! defined $description) {
                $description = '';
            }
            # Emit the subsystem record.
            $self->PutE(Subsystem => $subsystem, curator => $curator,
                        description => $description, notes => $notes,
                        version => $version, usable => $usable,
                        private => $private, cluster_based => $clustered,
                        experimental => $experimental);
            # Get this subsystem's roles.
            my @roles = $ssData->get_roles();
            # This will track the column number for the role.
            my $col = 0;
            # Loop through the roles.
            for my $role (@roles) {
                # Check to see if this role is main or auxiliary.
                my $auxFlag = ($fig->is_aux_role_in_subsystem($subsystem, $role) ? 1 : 0);
                # Connect it to the subsystem.
                $self->PutR(Includes => $subsystem, $role,
                            abbreviation => $ssData->get_abbr_for_role($role),
                            sequence => $col++, auxiliary => $auxFlag);
            }
            # Next come the variants. Variant data is sparse in the SEED. We
            # start by getting all the known variant codes.
            my %variants = map { BaseSaplingLoader::Starless($_) => '' } $ssData->get_variant_codes();
            # -1 and 0 are always present.
            $variants{'0'} = 'Subsystem functionality is incomplete.';
            $variants{'-1'} = 'Subsystem is not functional.';
            # Now get notes from any variants that have them. Note that we need
            # to clean up the variant code with a call to Starless.
            my $variantHash = $ssData->get_variants();
            for my $variant (keys %$variantHash) {
                my $realVariantID = BaseSaplingLoader::Starless($variant);
                $variants{$realVariantID} = $variantHash->{$variant};
            }
            # Next we need to compute the role rules. For each genome in the subsystem,
            # we compute its variant code and a list of its roles. These are put
            # into the following two-dimensional hash. Each inner hash maps a role
            # rule list to 1. The keys of the inner hash become the role rules.
            my %roleRuleHash = map { $_ => {} } keys %variants;
            # Loop through the list of genomes.
            my @genomes = $ssData->get_genomes();
            for (my $i = 0; $i < scalar(@genomes); $i++) {
                # Get this genome's variant code.
                my $variantCode = BaseSaplingLoader::Starless($ssData->get_variant_code($i));
                # Get its roles.
                my @roles = $ssData->get_roles_for_genome($genomes[$i]);
                # Convert them to a role rule.
                my $rule = join(" ", sort map { $ssData->get_abbr_for_role($_) } @roles);
                # Put the role in the hash.
                $roleRuleHash{$variantCode}{$rule} = 1;
            }
            # Create the variants.
            for my $variant (keys %variants) {
                # The variant key is the subsystem ID plus the variant code.
                my $variantID = ERDB::DigestKey("$subsystem:$variant");
                # Compute its type.
                my $variant_type = ($variant =~ /^0/ ? 'incomplete' :
                                    $variant =~ /^-/ ? 'vacant' : 'normal');
                # The comment is easily computed from the variant data, so
                # we now have enough data to output the variant record.
                $self->PutE(Variant => $variantID, type => $variant_type,
                            code => $variant, comment => $variants{$variant});
                # Now output the role rules.
                for my $rule (keys %{$roleRuleHash{$variant}}) {
                    $self->PutE(VariantRole => $variantID, role_rule => $rule);
                }
                # Link the subsystem to the variant.
                $self->PutR(Describes => $subsystem, $variantID);
            }
            # Clear the subsystem cache to keep memory under control.
            $fig->clear_subsystem_cache();
        }
    }
}

=head3 GenerateSubsystemData

    $sl->GenerateSubsystemData($fig, $erdb, $genomeID);

Generate the molecular machines and subsystem spreadsheet cells for this
database. This method concerns itself primarily with the genome-dependent
part of the subsystem framework. This includes the following tables.

    IsImplementedBy
    MolecularMachine
    IsMachineOf
    MachineRole
    Uses
    Contains
    IsRoleOf

=over 4

=item fig

Source object from which the subsystem data will be extracted.

=item erdb

Database object for the Sapling database.

=item genomeID

ID of the relevant genome.

=back

=cut

sub GenerateSubsystemData {
    # Get the parameters.
    my ($self, $fig, $erdb, $genomeID) = @_;
    # Get the subsystem hash for this Sapling instance. Its key list will be
    # the list of subsystems being put in the database.
    my $subHash = $erdb->SubsystemHash();    
    # Get the list of subsystems for this genome. The "1" indicates we want
    # all of them, including the ones for 0 and -1 variants. Note we have
    # to normalize the subsystem names.
    my @subName = map { $erdb->SubsystemID($_) } $fig->subsystems_for_genome($genomeID, 1);
    # Get the functional assignments for the features in this genome. We'll need
    # this later when we're connecting them to subsystem cells.
    my %fidHash = map { $_->[0] => $_->[1] } @{$fig->get_genome_assignment_data($genomeID)};
    # Loop through the named subsystems. Each one corresponds to a molecular
    # machine.
    for my $subName (grep { exists $subHash->{$_} } @subName) {
        $self->Track(MolecularMachines => $subName, 100);
        # Compute the MD5 hash of the subsystem ID.
        my $ssMD5 = ERDB::DigestKey($subName);
        # Get the subsystem object.
        my $ssData = $fig->get_subsystem($subName);
        if (! defined $ssData) {
            Trace("Subsystem $subName has been deleted.") if T(ERDBLoadGroup => 2);
            $self->Add(missingSubsystem => 1);
        } else {
            # Now we find the molecular machines for this subsystem/genome pair.
            my @rows = $ssData->get_genomes();
            for (my $gidx = 0; $gidx <= $#rows; $gidx++) {
                my ($rowGenome, $regionString) = split m/:/, $rows[$gidx], 2;
                if ($rowGenome eq $genomeID) {
                    # Here we're positioned on a row for our genome. If it is
                    # a region-restricted molecular machine, then the region
                    # string will be defined. If it's global, we use an empty
                    # string for the region.
                    $regionString ||= "";
                    # Create the molecular machine. To do that, we need the variant code
                    # for this genome.
                    my $raw_variant_code = $ssData->get_variant_code($gidx);
                    # Check for a leading asterisk. This means the variant assignment is not
                    # curated.
                    my $curated = ($raw_variant_code =~ /^\s*\*/ ? 0 : 1);
                    # Clear any waste from the variant code.
                    my $variant_code = BaseSaplingLoader::Starless($raw_variant_code);
                    # Create the variant and machine IDs.
                    my $variantID = ERDB::DigestKey("$subName:$variant_code");
                    my $machineID = ERDB::DigestKey("$subName:$variant_code:$genomeID:$regionString");
                    # Create the molecular machine and connect it to the genome and
                    # subsystem.
                    $self->PutE(MolecularMachine => $machineID,
                                curated => $curated, region => $regionString);
                    $self->PutR(IsImplementedBy => $variantID, $machineID);
                    $self->PutR(Uses => $genomeID, $machineID);
                    # Now we loop through the subsystem's roles, creating the MachineRoles.
                    # Molecular machines function as spreadsheet rows; machine roles are
                    # spreadsheet cells.
                    my @roles = $ssData->get_roles();
                    for my $role (@roles) {
                        # Get this role's abbreviation.
                        my $ridx = $ssData->get_role_index($role);
                        my $abbr = $ssData->get_role_abbr($ridx);
                        # Create the machine-role ID.
                        my $machineRoleID = "$ssMD5:$genomeID:$regionString:$abbr";
                        # Create the machine-role and connect it to the role and the
                        # machine.
                        $self->PutE(MachineRole => $machineRoleID);
                        $self->PutR(IsMachineOf => $machineID, $machineRoleID);
                        $self->PutR(IsRoleOf => $role, $machineRoleID);
                        # Now get a list of the features in this cell.
                        my @pegs = $ssData->get_pegs_from_cell($genomeID, $ridx);
                        # Connect them to the cell. We need to check the roles,
                        # however.
                        for my $peg (@pegs) {
                            # Get this PEG's functional assignment.
                            my $function = $fidHash{$peg};
                            # Extract its roles.
                            my ($roles, $errors) = SeedUtils::roles_for_loading($function);
                            # If one of the roles matches this subsystem role, we
                            # will connect the peg to the cell. Otherwise, we
                            # count it as disconnected.
                            if (defined $roles && grep { $_ eq $role } @$roles) {
                                $self->PutR(Contains => $machineRoleID, $peg);
                            } else {
                                $self->Add(disconnectedPeg => 1);
                            }
                        }
                    }
                }
            }
        }
        # Clear the subsystem cache to save space.
        $fig->clear_subsystem_cache();
    }
}

=head3 CreateClass

    $sl->CreateClass($className);

Create a SubsystemClass record with the specified class name.

=over 4

=item className

Name of the subsystem classification to create.

=back

=cut

sub CreateClass {
    # Get the parameters.
    my ($self, $className) = @_;
    # Create the subsystem class record.
    $self->PutE(SubsystemClass => $className);
}


1;
