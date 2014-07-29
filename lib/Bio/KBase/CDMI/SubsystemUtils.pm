package Bio::KBase::CDMI::SubsystemUtils;

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

    use strict;
    use SeedUtils;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Digest::MD5;
    use ERDB;

=head1 CDMI Subsystem Load Utilities

This module contains methods for loading a subsystem into a KBase Central 
Data Model Instance. The subsystem is represented by a standard SEED 
subsystem directory.


=head3 LoadSubsystem

    LoadSubsystem($loader, $source, $SubsystemDirectory, $missing);

Load a single subsystem from the specified subsystem directory.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manager the load.

=item source

Source database the subsystem came from.

=item subsystemDirectory

Directory containing the subsystem files. The lowest-level component of
the directory name (with any underscores translated to spaces) is the
subsystem name.

=item missing

If TRUE, then the subsystem will be skipped if it is already in the
database. The default is FALSE, in which case the subsystem will be
deleted and reloaded.

=back

=cut

sub LoadSubsystem {
    # Get the parameters.
    my ($loader, $source, $subsystemDirectory, $missing) = @_;
    # Indicate our progress.
    print "Processing $subsystemDirectory.\n";
    # Compute the subsystem name.
    my @pathParts = split /\\|\//, $subsystemDirectory;
    my $foreignID = pop @pathParts;
    my $subsysName = SubsystemID($foreignID);
    print "Subsystem name is $subsysName.\n";
    # Get access to the database.
    my $cdmi = $loader->cdmi;
    # We may decide to skip this subsystem. If we decide to load it,
    # we will set this value to TRUE.
    my $loadThis;
    # Check for an existing copy of the subsystem.
    if (! $cdmi->Exists(Subsystem => $subsysName)) {
        # No existing copy. Do the load.
        $loadThis = 1;
    } else {
        # We have an existing copy. Are we in missing-only mode?
        if ($missing) {
            # Yes. Skip this subsystem.
            print "$subsysName already exists. Skipped.\n";
            $loader->stats->Add(skippedSubsystem => 1);
        } else {
            # No. Delete the existing copy.
            DeleteSubsystem($loader, $subsysName);
            # Go ahead and load it.
            $loadThis = 1;
        }
    }
    # Only proceed if we approve this load.
    if ($loadThis) {
        # Initialize the relation loaders.
        $loader->SetRelations(qw(IsImplementedBy SSRow Uses IsRowOf SSCell
                IsRoleOf Contains));
        # Create the subsystem record and the surrounding roles and variants.
        my $varHash = CreateSubsystem($loader, $source, $subsysName,
                $subsystemDirectory);
        # Unspool the relation loaders.
        $loader->LoadRelations();
    }
}

=head3 DeleteSubsystem

    DeleteSubsystem($loader, $subsysID);

Delete the existing data for the specified subsystem. This method is designed
to work even if the subsystem was only partially loaded. It will not, however,
delete any roles, since these do not belong to the subsystem.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item subsysID

ID of the subsystem to delete.

=back

=cut

sub DeleteSubsystem {
    # Get the parameters.
    my ($loader, $subsysID) = @_;
    # Get the CDMI object.
    my $cdmi = $loader->cdmi;
    # Delete the subsystem
    print "Deleting old copy of $subsysID.\n";
    my $stats = $cdmi->Delete(Subsystem => $subsysID);
    # In case of missing variants, we need to delete the SSRows. Look for
    # SSRows with keys matching the subsystem's MD5.
    my $digest = Digest::MD5::md5_base64($subsysID);
    my @rows = $cdmi->GetFlat('SSRow', "SSRow(id) LIKE ?", ["$digest:%"], 'id');
    for my $row (@rows) {
        print "Deleting SS row $row.\n";
        my $subStats = $cdmi->Delete(SSRow => $row);
        $stats->Accumulate($subStats);
    }
    # Roll up the statisics.
    $loader->stats->Accumulate($stats);
}

=head3 CreateSubsystem

    my $varHash = CreateSubsystem($loader, $source, $name,
                                  $subsystemDirectory);

Create the subsystem and its variants, and connect it to its
classifications.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item source

Source (core) database the subsystem came from.

=item name

Name of the subsystem.

=item subsystemDirectory

Name of the directory containing the subsystem files.

=item RETURN

Returns a reference to a hash mapping each variant code to its database ID.

=back

=cut

sub CreateSubsystem {
    # Get the parameters.
    my ($loader, $source, $name, $subsystemDirectory) = @_;
    # Get the CDMI object.
    my $cdmi = $loader->cdmi;
    # This will contain the variants on output.
    my %retVal;
    # This will contain a hash that can be used to create the variant
    # records.
    my %varHash;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get a digest of the subsystem name to use in forming sub-object keys.
    my $digest = Digest::MD5::md5_base64($name);
    # Get the classifications from the classification file.
    # Read the classification information.
    my @classes;
    my $classFile = "$subsystemDirectory/CLASSIFICATION";
    if (-f $classFile) {
        open(my $ih, "<$classFile") || die "Could not open classification file: $!\n";
        @classes = grep { $_ } $loader->GetLine($ih);
    }
    # Loop through the classes from bottom to top, insuring we have them linked up
    # in the database.
    my $lastClass;
    if (@classes) {
        print "Processing classifications.\n";
        # Insure the lowest-level class is present.
        my $i = $#classes;
        $lastClass = $classes[$i];
        my $createdFlag = $loader->InsureEntity(SubsystemClass => $lastClass);
        # Work up through the other classes until we find one already present or hit the top.
        my $thisClass = $lastClass;
        while ($createdFlag && $i > 1) {
            # Connect to the next class up.
            $i--;
            my $nextClass = $classes[$i];
            $cdmi->InsertObject('IsSuperclassOf', from_link => $nextClass, to_link => $thisClass);
            # Insure the next class is in the database.
            $createdFlag = $loader->InsureEntity(SubsystemClass => $nextClass);
        }
    }
    # Get the top class, if any. We use this to do some typing.
    my $topClass = $classes[0] || ' ';
    print "Analyzing subsystem type.\n";
    # Compute the class-related subsystem types.
    my $clusterBased = ($topClass =~ /clustering-based/i ? 1 : 0);
    my $experimental = ($topClass =~ /experimental/i ? 1 : 0);
    my $usable = ! $experimental;
    # Check for the privacy flag.
    my $private = (-f "$subsystemDirectory/EXCHANGABLE" ? 0 : 1);
    # Get the version.
    my $version = $loader->ReadAttribute("$subsystemDirectory/VERSION") || 0;
    # Get the curator. This involves finding the start line in the curator log.
    my $curator = "fig";
    my $curatorFile = "$subsystemDirectory/curation.log";
    if (-f $curatorFile) {
        open(my $ih, "<$curatorFile") || die "Could not open curator file: $!\n";
        while ($curator eq "fig" && ! eof $ih) {
            my $line = <$ih>;
            if ($line =~ /^\d+\t(\S+)\s+started/) {
                $curator = $1;
                $curator =~ s/^master://;
            }
        }
    }
    # Now we need to get the notes and description from the notes file.
    my ($description, $notes) = ("", "");
    my $notesFile = "$subsystemDirectory/notes";
    if (-f $notesFile) {
        print "Processing notes file.\n";
        open (my $ih, "<$notesFile") || die "Could not open notes file: $!\n";
        my $notesHash = ParseNotesFile($ih);
        if (exists $notesHash->{description}) {
            $description = $notesHash->{description};
            $stats->Add(ssDescriptions => 1);
        }
        if (exists $notesHash->{notes}) {
            $notes = $notesHash->{notes};
            $stats->Add(ssNotes => 1);
        }
        # Stash the variant information for later.
        if (exists $notesHash->{variants}) {
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
                    $stats->Add(ssVarLines => 1);
                }
            }
        }
    }
    # Insure we have the two special variants.
    if (! exists $varHash{"0"}) {
        $varHash{"0"} = 'Subsystem functionality is incomplete.';
    }
    if (! exists $varHash{"-1"}) {
        $varHash{"-1"} = 'Subsystem is not functional.';
    }
    # We need to find the roles next and identify the auxiliary roles. This
    # information is in the spreadsheet.
    open(my $ih, "<$subsystemDirectory/spreadsheet") || die "Could not open spreadsheet file: $!\n";
    print "Processing spreadsheet.\n";
    # The first section is the roles. We need a list of the roles and a hash mapping role
    # names to abbreviations.
    my (@roleList, %roleHash);
    # Loop through the roles. We may hit end-of-file or a section marker (//).
    my $done = 0;
    while (! eof $ih && ! $done) {
        # Each line contains an abbreviation followed by a role name.
        my ($abbr, $role) = $loader->GetLine($ih);
        # Is this an end marker?
        if ($abbr eq '//') {
            # Yes. Stop the loop.
            $done = 1;
        } elsif ($abbr) {
            # No, but we have an abbreviation. Store the role.
            push @roleList, $abbr;
            $roleHash{$abbr} = $role;
            $stats->Add(ssRoles => 1);
        }
    }
    # The next section is the subsets. All we care about are the auxiliary roles.
    my %auxHash;
    $done = 0;
    while (! eof $ih && ! $done) {
        # Each line contains a subset name followed by a list of role indices.
        my ($subset, @idxes) = $loader->GetLine($ih);
        # Is this an end marker?
        if ($subset eq '//') {
            # Yes. Stop the loop.
            $done = 1;
        } elsif ($subset =~ /^aux/) {
            # Here we have the auxiliary subset. Mark its roles in the aux hash.
            # Note the indices in the file are 1-based.
            for my $idx (@idxes) {
                $auxHash{$roleList[$idx - 1]} = 1;
                $stats->Add(ssAuxRoles => 1);
            }
        }
    }
    # Finally, we have the spreadsheet itself. The bindings will be taken from the
    # bindings files rather than the spreadsheet; however, we use the spreadsheet
    # to compute the role rules.
    my %varRules;
    $done = 0;
    print "Processing role table.\n";
    while (! eof $ih && ! $done) {
        my ($genome, $variant, @cells) = $loader->GetLine($ih);
        # Is this the end marker?
        if ($genome eq '//') {
            # Yes. Stop the loop.
            $done = 1;
        } elsif ($genome) {
            $stats->Add(ssGenomeLines => 1);
            # Here we have the spreadsheet data for a genome. Compute the variant ID.
            my $realVariant = Starless($variant);
            # Insure we have the variant in the variant hash.
            if (! exists $varHash{$realVariant}) {
                $varHash{$realVariant} = "";
            }
            # Create a role rule hash for it.
            if (! exists $varRules{$realVariant}) {
                $varRules{$realVariant} = {};
            }
            # Loop through the cells, collecting the roles used.
            my @rolesFound;
            for (my $i = 0; $i <= $#cells; $i++) {
                # Is this celll occupied?
                if ($cells[$i]) {
                    # Yes. If it is non-auxiliary, add its role to the role rule.
                    my $abbr = $roleList[$i];
                    if (! $auxHash{$abbr}) {
                        push @rolesFound, $abbr;
                    }
                }
            }
            # Form the role rule and associate it with the variant.
            my $roleRule = join(" ", sort @rolesFound);
            $varRules{$realVariant}{$roleRule} = 1;
        }
    }
    # Create the subsystem record.
    print "Creating subsystem.\n";
    $cdmi->InsertObject('Subsystem', id => $name, cluster_based => $clusterBased,
                       curator => $curator, description => $description, experimental => $experimental,
                       notes => $notes, private => $private,
                       usable => $usable, version => $version);
    $stats->Add(subsystems => 1);
    # Connect it to the source.
    $cdmi->InsertObject('Provided', from_link => $source, to_link => $name);
    $loader->InsureEntity(Source => $source);
    # If there is a classification for it, connect it.
    if ($lastClass) {
        $cdmi->InsertObject('IsClassFor', from_link => $lastClass, to_link => $name);
    }
    # Now we create the subsystem's variants.
    print "Creating variants.\n";
    for my $variant (keys %varHash) {
        # Find the variant's KBase ID.
        my $varKey = "$digest:$variant";
        # Save it in the return hash.
        $retVal{$variant} = $varKey;
        # Connect the variant to the subsystem.
        $cdmi->InsertObject('Describes', from_link => $name,
                to_link => $varKey);
        # Determine the variant type.
        my $type = "normal";
        if ($variant eq "0") {
            $type = "incomplete";
        } elsif ($variant eq "-1") {
            $type = "vacant";
        }
        # Create the variant record.
        $cdmi->InsertObject('Variant', id => $varKey, code => $variant,
                comment => $varHash{$variant}, type => $type);
        $stats->Add(variants => 1);
        # Add the variant's role rules (if any).
        my $ruleHash = $varRules{$variant};
        for my $roleRule (keys %$ruleHash) {
            $cdmi->InsertValue($varKey, 'Variant(role-rule)', $roleRule);
            $stats->Add(ssRoleRules => 1);
        }
    }
    # Finally, connect the roles themselves.
    my $col = 0;
    print "Connecting roles.\n";
    for my $abbr (@roleList) {
        # Get the role ID.
        my $role = $roleHash{$abbr};
        # Determine if it's hypothetical and/or auxiliary.
        my $hypo = (hypo($role) ? 1 : 0);
        my $aux = ($auxHash{$abbr} ? 1 : 0);
        # Insure it's in the database.
        $loader->InsureEntity(Role => $role, hypothetical => $hypo);
        # Connect it to the subsystem.
        $cdmi->InsertObject('Includes', from_link => $name, to_link => $role,
                abbreviation => $abbr, auxiliary => $aux, sequence => $col++);
        $stats->Add(ssRoles => 1);
    }
    # Return the variant map.
    return \%retVal;
}

=head3 BadSubsys

    my $badFlag = BadSubsys($subsystemDirectory);

Return TRUE if the specified subsystem is invalid. It is invalid if it is experimental
or has a null or hypothetical role.

=over 4

=item dirName

Name of the directory containing the subsystem files.

=item RETURN

Returns TRUE if the subsystem is invalid, else FALSE.

=back

=cut

sub BadSubsys {
    # Get the parameters.
    my ($subsystemDirectory) = @_;
    # This will be set to TRUE if we are bad.
    my $retVal = 0;
    # Check the classification to see if we are experimental.
    my $classFile = "$subsystemDirectory/CLASSIFICATION";
    if (-f $classFile) {
        open(my $ih, "<$classFile") || die "Could not open classification file: $!\n";
        my ($class) = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
        if ($class && $class =~ /experimental/i) {
            $retVal = 1;
        }
    }
    # If we are ok so far, look for a bad role.
    if (! $retVal) {
        my $sheetFile = "$subsystemDirectory/spreadsheet";
        if (! -f $sheetFile) {
            # A missing spreadsheet is very bad.
            $retVal = 1;
        } else {
            open(my $ih, "<$sheetFile") || die "Could not open spreadsheet file: $!\n";
            my $done = 0;
            # Loop until we read all the roles or find a bad one.
            while (! eof $ih && ! $done && ! $retVal) {
                # Read the next role.
                my ($line, $role) = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
                # See what we have.
                if ($line eq "//") {
                    # This is the end marker.
                    $done = 1;
                } elsif (! $role || $role !~ /\S/) {
                    # Here we have a blank role.
                    $retVal = 1;
                } elsif ($role =~ /\bhypothetical\s+protein\b/i) {
                    # Here we have a hypothetical role.
                    $retVal = 1;
                }
            }
        }
    }
    # Return the determination indicator.
    return $retVal;
} 


=head3 ParseNotesFile

    my $notesHash = ParseNotesFile($ih);

Read and parse the notes file from the specified file handle. The sections
of the file will be returned in a hash, keyed by section name.

=over 4

=item ih

Open handle for the notes file.

=item RETURN

Returns a reference to a hash keyed by section name, mapping each name to
the text of that section.

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
            # Here we have the start of a new section. If there's an old
            # section, put it in the output hash.
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

=head3 SubsystemID

    my $subsysID = SubsystemID($foreignID);

Convert a subsystem directory name to a subsystem ID. This involves converting
underscores to spaces and dealing with weirdness at the end.

=cut

sub SubsystemID {
    my ($foreignID) = @_;
    my $retVal = $foreignID;
    # Fix up the underscores at the end.
    if ($retVal =~ /(.+?)(_+)$/) {
        my $suffix = (length $2) + 1;
        $retVal = "$1 $suffix";
    }
    $retVal =~ tr/_/ /;
    return $retVal;
}

=head3 ProcessBindings

    ProcessBindings($loader, $genome, $directory, $subsysH);

Load the subsystem binding data for a genome into the database. This requires 
looking through the bindings and using them to connect to the subsystems that 
are listed in a specified hash.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for loading the CDMI.

=item genome

Source ID of the genome whose bindings are to be processed.

=item directory

Directory containing the genome data and binding files.

=item subsysH

Reference to a hash containing the IDs of the subsystems being updated.

=back

=cut

sub ProcessBindings {
    # Get the parameters.
    my ($loader, $genome, $directory, $subsysH) = @_;
    # Get the CDMI object.
    my $cdmi = $loader->cdmi;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Compute the subsystem and binding file names.
    my $subFileName = "$directory/Subsystems/subsystems";
    my $bindFileName = "$directory/Subsystems/bindings";
    # Only proceed if both exist.
    if (! -f $subFileName || ! -f $bindFileName) {
        print "Missing subsystem data for $genome.\n";
        $stats->Add(genomeNoSubsystems => 1);
    } else {
        # Compute the KBase ID for this genome.
        $loader->SetSource('SEED');
        my $kbGenome = $loader->LookupGenome($genome);
        # Get a hash of the molecular machines already connected to this genome.
        # We use this to insure we don't get duplicate-machine errors.
        my %machinesOld = map { $_ => 1 } $cdmi->GetFlat('Uses', 'Uses(from-link) = ?',
                [$kbGenome], 'to-link');
        # This hash maps subsystem IDs to molecular machine IDs.
        my %machines;
        # This hash maps subsystem/role pairs to machine role IDs.
        my %machineRoles;
        # This hash will contain the list of subsystems found in the database.
        my %subsystems;
        # We loop through the subsystems, looking for the ones already in the
        # database. The list is given in the subsystems file of the Subsystems
        # directory.
        open(my $ih, "<$subFileName") || die "Error opening subsystem bindings file $subFileName: $!";
        # Loop through the subsystems in the file, insuring we have them in the database.
        while (! eof $ih) {
            # Get this subsystem.
            my $line = <$ih>;
            chomp $line;
            my ($subsystem, $variant) = split /\t/, $line;
            # Normalize the subsystem name.
            $subsystem = SubsystemID($subsystem);
            # Insure the subsystem is one we're interested in.
            if ($subsysH->{$subsystem}) {
                # We need to compute the machine role IDs and create the molecular 
                # machine. First, we need to remember the subsystem.
                $subsystems{$subsystem} = 1;
                # Compute this subsystem's MD5.
                my $subsystemMD5 = Digest::MD5::md5_base64($subsystem);
                my $rolePrefix = "$subsystemMD5:$genome";
                # Loop through the roles.
                my @roleList = $cdmi->GetAll('Includes', 'Includes(from-link) = ?',
                        [$subsystem], "to-link abbreviation");
                for my $roleTuple (@roleList) {
                    my ($roleID, $abbr) = @$roleTuple;
                    my $machineRoleID = $rolePrefix . '::' . $abbr;
                    $machineRoles{$subsystem}{$roleID} = $machineRoleID;
                }
                # Next we need the variant code and key.
                my $variantCode = Starless($variant);
                my $variantKey = "$subsystemMD5:$variantCode";
                # Insure that the variant exists.
                my $created = $loader->InsureEntity(Variant => $variantKey, code => $variantCode,
                    comment => "", type => "normal");
                if ($created) {
                    $stats->Add(newVariantFromBinding => 1);
                    $cdmi->InsertObject('Describes', from_link => $subsystem, to_link => $variantKey);
                }
                # Now we create the molecular machine connecting this genome to the
                # subsystem variant.
                my $machineID = "$subsystemMD5:$variantCode:$genome";
                $cdmi->InsertObject('IsImplementedBy', from_link => $variantKey, to_link => $machineID);
                $cdmi->InsertObject('SSRow', id => $machineID, curated => 0, region => '');
                $cdmi->InsertObject('Uses', from_link => $kbGenome, to_link => $machineID);
                # Remember the machine ID.
                $machines{$subsystem} = $machineID;
            }
        }
        # Now we go through the bindings file. This file connects the subsystem
        # roles to the molecular machines.
        close $ih; undef $ih;
        open($ih, "<$bindFileName") || die "Could not open subsystems binding file $bindFileName: $!";
        # We cache feature IDs in here.
        my %fidMap = map { $_->[0] => $_->[1] } $cdmi->GetAll('IsOwnerOf Feature', 
                'IsOwnerOf(from-link) = ?', [$kbGenome], 'Feature(source-id) Feature(id)');
        # Loop through the bindings.
        while (! eof $ih) {
            # Get the binding data.
            my ($subsystem, $role, $fid) = Tracer::GetLine($ih);
            # Normalize the subsystem name.
            $subsystem = SubsystemID($subsystem);
            # Insure the subsystem is in the database.
            if ($subsystems{$subsystem}) {
                # Compute the machine role.
                my $machineRoleID = $machineRoles{$subsystem}{$role};
                # Insure it exists.
                if (! $machineRoleID) {
                	$stats->Add(machineRoleMismatch => 1);
                } else {
	                my $created = $loader->InsureEntity(SSCell => $machineRoleID);
	                if ($created) {
	                    # We created the machine role, so connect it to the machine.
	                    my $machineID = $machines{$subsystem};
	                    $cdmi->InsertObject('IsRowOf', from_link => $machineID, to_link => $machineRoleID);
	                    # Connect it to the role, too.
	                    $cdmi->InsertObject('IsRoleOf', from_link => $role, to_link => $machineRoleID);
	                }
	                # Connect the feature.
	                $cdmi->InsertObject('Contains', from_link => $machineRoleID, to_link => $fidMap{$fid});
                }
            }
        }
    }
}

1;