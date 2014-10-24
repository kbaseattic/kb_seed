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

package SaplingSubsystemLoader;

    use strict;
    use Tracer;
    use Stats;
    use SeedUtils;
    use SAPserver;
    use Sapling;
    use base qw(SaplingDataLoader);

=head1 Sapling Subsystem Loader

This class loads Subsystem data into a Sapling database from a subsystem directory.
Unlike L<SaplingGenomeLoader>, this version is designed for updating a populated
database only. Links to features and genomes are put in, but not the features and
genomes themselves, which may lead to orphan links.

=head2 Main Methods

=head3 Load

    my $stats = SaplingSubsystemLoader::Load($sap, $subsystem, $directory);

Load a subsystem from a subsystem directory into the sapling database.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item subsystem

ID of the subsystem being loaded.

=item directory

Name of the directory containing the subsystem information.

=back

=cut

sub Load {
    # Get the parameters.
    my ($sap, $subsystem, $directory) = @_;
    # Create the loader object.
    my $loaderObject = SaplingSubsystemLoader->new($sap, $subsystem, $directory);
    # Create the subsystem record.
    $loaderObject->CreateSubsystem();
    # Read the spreadsheet file.
    $loaderObject->ParseSpreadsheet();
    # Return the statistics.
    return $loaderObject->{stats};
}

=head3 ClearSubsystem

    my $stats = SaplingSubsystemLoader::ClearSubsystem($sap, $subsystem);

Delete the specified subsystem and all the related records from the specified sapling
database. This method can also be used to clean up after a failed or aborted load.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item subsystem

ID of the subsystem to delete.

=item RETURN

Returns a statistics object counting the records deleted.

=back

=cut

sub ClearSubsystem {
    # Get the parameters.
    my ($sap, $subsystem) = @_;
    # Create the statistics object.
    my $stats = Stats->new();
    # Delete the subsystem and all its associated records.
    $stats = $sap->Delete(Subsystem => $subsystem);
    # Return the statistics object.
    return $stats;
}

=head3 Process

    my $stats = SaplingSubsystemLoader::Process($sap, $subsystem, $directory);

Load subsystem data from the specified directory. If the subsystem data already
exists in the database, it will be deleted first.

=over 4

=item sap

L</Sapling> object for accessing the database.

=item subsystem

name of the subsystem whose data is being loaded.

=item directory

Name of the directory containing the subsystem data files. If omitted,
the subsystem will be deleted from the database.

=item RETURN

Returns a statistics object describing the activity during the reload.

=back

=cut

sub Process {
    # Get the parameters.
    my ($sap, $subsystem, $directory) = @_;
    # Clear the existing data for the specified subsystem.
    my $stats = ClearSubsystem($sap, $subsystem);
    if ($subsystem) {
        # Load the new subsystem data from the specified directory.
        my $newStats = Load($sap, $subsystem, $directory);
        # Merge the statistics.
        $stats->Accumulate($newStats);
    }
    # Return the result.
    return $stats;
}


=head2 Loader Object Methods

=head3 new

    my $loaderObject = SaplingSubsystemLoader->new($sap, $subsystem, $directory);

Create a loader object that can be used to facilitate loading Sapling data from a
subsystem directory.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item subsystem

ID of the subsystem being loaded.

=item directory

Name of the directory containing the subsystem data.

=back

The object created contains the following fields.

=over 4

=item supportRecords

A hash of hashes, used to track the support records known to exist in the database.

=item sap

L<Sapling> object used to access the database.

=item stats

L<Stats> object for tracking statistical information about the load.

=item subsystem

ID of the subsystem being loaded.

=item directory

Name of the directory containing the subsystem data.

=item roleList

Reference to a list of roles abbreviations, in order.

=item roleHash

Reference to a hash mapping each role abbreviation to the association role ID.

=item variants

Hash mapping variant codes to descriptions.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $sap, $subsystem, $directory) = @_;
    # Create the object.
    my $retVal = SaplingDataLoader::new($class, $sap, qw(roles));
    # Add our specialized data.
    $retVal->{subsystem} = $subsystem;
    $retVal->{directory} = $directory;
    $retVal->{variants} = {};
    # Return the result.
    return $retVal;
}

=head3 CreateSubsystem

    $loaderObject->CreateSubsystem();

Create the root record for this subsystem and connect it to the classifications. This
method also reads in the variant descriptions (if any);

=cut

sub CreateSubsystem {
    # Get the parameters.
    my ($self) = @_;
    # Get the subsystem directory.
    my $directory = $self->{directory};
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Read the classification information.
    my @classes;
    my $classFile = "$directory/CLASSIFICATION";
    if (-f $classFile) {
        my $ih = Open(undef, "<$classFile");
        @classes = grep { $_ } Tracer::GetLine($ih);
    }
    # Loop through the classes from bottom to top, insuring we have them linked up
    # in the database.
    my $lastClass;
    if (@classes) {
        Trace("Processing classifications.") if T(SaplingDataLoader => 3);
        # Insure the lowest-level class is present.
        my $i = $#classes;
        $lastClass = $classes[$i];
        my $createdFlag = $self->InsureEntity(SubsystemClass => $lastClass);
        # Work up through the other classes until we find one already present or hit the top.
        my $thisClass = $lastClass;
        while ($createdFlag && $i > 1) {
            # Connect to the next class up.
            $i--;
            my $nextClass = $classes[$i];
            $sap->InsertObject('IsSuperClassOf', from_link => $nextClass, to_link => $thisClass);
            # Insure the next class is in the database.
            $createdFlag = $self->InsureEntity(SubsystemClass => $nextClass);
        }
    }
    # Get the top class, if any. We use this to do some typing.
    my $topClass = $classes[0] || ' ';
    # Compute the class-related subsystem types.
    my $clusterBased = ($topClass =~ /clustering-based/i ? 1 : 0);
    my $experimental = ($topClass =~ /experimental/i ? 1 : 0);
    my $usable = ! $experimental;
    # Check for the privacy flag.
    my $private = (-f "$directory/EXCHANGABLE" ? 0 : 1);
    # Get the version.
    my $version = "0";
    my $versionFile = "$directory/VERSION";
    if (-f $versionFile) {
        ($version) = Tracer::GetFile($versionFile);
    }
    # Get the curator. This involves finding the start line in the curator log.
    my $curator = "fig";
    my $curatorFile = "$directory/curation.log";
    if (-f $curatorFile) {
        my $ih = Open(undef, "<$curatorFile");
        while ($curator eq "fig" && ! eof $ih) {
            my $line = <$ih>;
            if ($line =~ /^\d+\t(\S+)\s+started/) {
                $curator = $1;
                $curator =~ s/^master://;
            }
        }
    }
    # Finally, we need to get the notes and description from the notes file.
    my ($description, $notes) = ("", "");
    my $notesFile = "$directory/notes";
    if (-f $notesFile) {
        Trace("Processing notes file.") if T(SaplingDataLoader => 3);
        my $ih = Open(undef, "<$notesFile");
        my $notesHash = ParseNotesFile($ih);
        if (exists $notesHash->{description}) {
            $description = $notesHash->{description};
        }
        if (exists $notesHash->{notes}) {
            $notes = $notesHash->{notes};
        }
        # Stash the variant information for later.
        if (exists $notesHash->{variants}) {
            # We need to create a hash of variant data.
            my %varHash;
            # Get the individual lines of the variant line.
            my @varLines = split /\n/, $notesHash->{variants};
            for my $varLine (@varLines) {
                # Split this line around the tab.
                my ($code, $comment) = split /\t/, $varLine;
                # Only proceed if the code is nonempty.
                if (defined $code && $code ne '') {
                    # Trim excess spaces from the code.
                    $code =~ s/\s+//g;
                    # Store the comment.
                    $varHash{$code} = $comment;
                }
            }
            $self->{variants} = \%varHash;
        }
    }
    # Create the subsystem record.
    $sap->InsertObject('Subsystem', id => $self->{subsystem}, cluster_based => $clusterBased,
                       curator => $curator, description => $description, experimental => $experimental,
                       notes => $notes, private => $private, usable => $usable, version => $version);
    # If there is a classification for it, connect it.
    if ($lastClass) {
        $sap->InsertObject('IsClassFor', from_link => $lastClass, to_link => $self->{subsystem});
    }
}


=head3 ParseSpreadsheet

    $loaderObject->ParseSpreadsheet();

Read and parse the spreadsheet file. This creates the roles, the molecular machines, and fills
in the variant table.

=cut

use constant VARIANT_TYPES => { '-1' => 'vacant', '0' => 'incomplete'};

sub ParseSpreadsheet {
    # Get the parameters.
    my ($self) = @_;
    # Get the variant hash.
    my $varHash = $self->{variants};
    # Get the sapling database.
    my $sap = $self->{sap};
    # Get the statistics object.
    my $stats = $self->{stats};
    # Get the subsystem ID.
    my $subsystem = $self->{subsystem};
    # Compute its MD5 for the machine role IDs.
    my $ssMD5 = ERDB::DigestKey($subsystem);
    # Insure the default variants are present.
    if (! exists $varHash->{'0'}) {
        $varHash->{'0'} = 'Subsystem functionality is incomplete.';
    }
    if (! exists $varHash->{'-1'}) {
        $varHash->{'-1'} = 'Subsystem is not functional.';
    }
    # Open the spreadsheet file.
    Trace("Processing spreadsheet.") if T(SaplingDataLoader => 3);
    my $ih = Open(undef, "<$self->{directory}/spreadsheet");
    my (@roleList, %roleHash);
    # Loop through the roles.
    my $done = 0;
    while (! eof $ih && ! $done) {
        my ($abbr, $role) = Tracer::GetLine($ih);
        # Is this an end marker?
        if ($abbr eq '//') {
            # Yes. Stop the loop.
            $done = 1;
        } elsif ($abbr) {
            # No, store the role.
            push @roleList, $abbr;
            $roleHash{$abbr} = $role;
        }
    }
    # The next section is the subsets. All we care about here are the auxiliary roles.
    my %auxHash;
    $done = 0;
    while (! eof $ih && ! $done) {
        my ($subset, @idxes) = Tracer::GetLine($ih);
        # Is this an end marker?
        if ($subset eq '//') {
            # Yes. Stop the loop.
            $done = 1;
        } elsif ($subset =~ /^aux/) {
            # Here we have an auxiliary subset. Mark its roles in the auxiliary-role hash.
            for my $idx (@idxes) {
                $auxHash{$roleList[$idx - 1]} = 1;
            }
        }
    }
    # We now have enough information to generate the role tables.
    my $col = 0;
    Trace("Generating roles.") if T(SaplingDataLoader => 3);
    for my $abbr (@roleList) {
        # Get the role ID.
        my $roleID = $roleHash{$abbr};
        # Determine if it's hypothetical.
        my $hypo = (hypo($roleID) ? 1 : 0);
        # Insure it's in the database.
        $self->InsureEntity(Role => $roleID, hypothetical => $hypo, role_index => -1);
        # Connect it to the subsystem
        $sap->InsertObject('Includes', from_link => $subsystem, to_link => $roleID,
                           abbreviation => $abbr, auxiliary => ($auxHash{$abbr} ? 1 : 0),
                           sequence => $col++);
        $stats->Add(roles => 1);
    }
    # The final section is the role table itself. Here we get the rest of the variant data, as well.
    # We do this in two passes. First pass accumulates the data in a hash table. The second processes
    # the data. This insures that the last version of any molecular machine is the one we keep.
    my (%varsAdded, %machines);
    $done = 0;
    Trace("Processing role table.") if T(SaplingDataLoader => 3);
    while (! eof $ih && ! $done) {
        my ($genome, $variant, @cells) = Tracer::GetLine($ih);
        # Is this the end marker?
        if ($genome eq '//') {
            # Yes. Stop the loop.
            $done = 1;
        } elsif ($genome) {
            # Compute the true variant code and the curation flag.
            my $curated = ($variant =~ /^\s*\*/ ? 0 : 1);
            my $realVariant = Starless($variant);
            # Check for a region string.
            my ($genomeID, $regionString) = split m/:/, $genome;
            $regionString ||= "";
            # Compute the variant and molecular machine IDs.
            my $variantID = ERDB::DigestKey("$subsystem:$realVariant");
            my $machineID = ERDB::DigestKey("$subsystem:$realVariant:$genomeID:$regionString");
            # Insure we have the variant in the database.
            if (! exists $varsAdded{$variantID}) {
                # Denote the variant is in this subsystem.
                $sap->InsertObject('Describes', from_link => $subsystem, to_link => $variantID);
                # Create the variant record. For now, the role-rule is kept empty. We'll add the
                # rules later as we find them.
                $sap->InsertObject('Variant', id => $variantID, code => $realVariant,
                                   comment => ($varHash->{comment} || ''),
                                   type => (VARIANT_TYPES->{$realVariant} || ''));
                # Denote we've added this variant.
                $varsAdded{$variantID} = {};
                $stats->Add(variants => 1);
            }
            # Store this machine.
            $machines{$machineID} = [$variantID, $genomeID, $curated, $regionString, @cells];
        }
    }
    for my $machineID (keys %machines) {
       	# Get this machine's data.
       	my $machineData = $machines{$machineID};
       	my ($variantID, $genomeID, $curated, $regionString, @cells) = @$machineData;
      	Trace("Processing machine $machineID for genome $genomeID/$regionString.") if T(SaplingDataLoader => 3);
        # Create the molecular machine.
        $sap->InsertObject('IsImplementedBy', from_link => $variantID, to_link => $machineID);
        $sap->InsertObject('MolecularMachine', id => $machineID, curated => $curated,
                           region => $regionString);
        # Now loop through the cells.
        my @rolesFound;
        for (my $i = 0; $i <= $#cells; $i++) {
            my $cell = $cells[$i];
            # Is this cell occupied?
            if ($cell) {
                # Yes. Get this cell's role abbreviation and add it to the list of roles found
                # in this row.
                my $abbr = $roleList[$i];
                push @rolesFound, $abbr;
                # Create the machine role.
                my $machineRoleID = "$machineID:$abbr";
                $sap->InsertObject('IsMachineOf', from_link => $machineID, to_link => $machineRoleID);
                $sap->InsertObject('MachineRole', id => $machineRoleID);
                $sap->InsertObject('IsRoleOf', from_link => $roleHash{$abbr},
                                   to_link => $machineRoleID);
                # Connect the pegs in this cell to it.
                for my $pegN (split m/\s*,\s*/, $cell) {
                    $sap->InsertObject('Contains', from_link => $machineRoleID,
                                       to_link => "fig|$genomeID.peg.$pegN");
                }
            }
        }
        # Compute a role rule from this row's roles and associate it with this variant.
        my $roleRule = join(" ", @rolesFound);
        $varsAdded{$variantID}->{$roleRule} = 1;
    }
    # We've finished the spreadsheet. Now we go back and add the role rules to the variants.
    for my $variantID (keys %varsAdded) {
        my $ruleHash = $varsAdded{$variantID};
        for my $roleRule (sort keys %$ruleHash) {
            $sap->InsertValue($variantID, 'Variant(role-rule)', $roleRule);
        }
    }
}

=head2 Internal Utility Methods

=head3 ParseNotesFile

    my $notesHash = SaplingSubsystemLoader::ParseNotesFile($ih);

Read and parse the notes file from the specified file handle. The sections of the file will be
returned in a hash, keyed by section name.

=over 4

=item ih

Open handle for the notes file.

=item RETURN

Returns a reference to a hash keyed by section name, mapping each name to the text of that section.

=cut

sub ParseNotesFile {
    # Get the parameters.
    my ($ih) = @_;
    # Create the return hash.
    my $retVal = {};
    # Anything before the first separator will be classified as "notes".
    my ($section, @text) = ('notes');
    # Loop through the lines of the file.
    while (! eof $ih) {
        my $line = <$ih>;
        chomp $ih;
        if ($line =~ /^#####/) {
            # Here we have the start of a new section. If there's an old section,
            #put it in the output hash.
            if (@text) {
                $retVal->{$section} = join("\n", @text);
            }
            # Is there another section?
            if (! eof $ih) {
                # Yes. Save the new section name and clear the text array.
                my $sectionLine = <$ih>;
                $sectionLine =~ /^(\S+)/;
                $section = lc $1;
                undef @text;
            }
        } else {
            # Here we have an ordinary text line.
            push @text, $line;
        }
    }
    # Write out the last section (if any).
    if (@text) {
        $retVal->{$section} = join("\n", @text);
    }
    # Return the result hash.
    return $retVal;
}

=head3 Starless

    my $adjusted = SaplingSubsystemLoader::Starless($codeString);

Remove any spaces and leading or trailing asterisks from the incoming string and
return the result.

=over 4

=item codeString

Input string that needs to have the asterisks trimmed.

=item RETURN

Returns the incoming string with spaces and leading and trailing asterisks
removed.

=back

=cut

sub Starless {
    # Get the parameters.
    my ($codeString) = @_;
    # Declare the return variable.
    my $retVal = $codeString;
    # Remove the spaces.
    $retVal =~ s/\s+//g;
    # Trim the asterisks.
    $retVal =~ s/^\*+//;
    $retVal =~ s/\*+$//;
    # Return the result.
    return $retVal;
}


1;