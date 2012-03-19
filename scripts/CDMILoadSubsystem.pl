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

    use strict;
    use SeedUtils;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Digest::MD5;
    use IDServerAPIClient;

=head1 CDMI Subsystem Loader

    CDMILoadSubsystem [options] source subsystemDirectory

Load a subsystem into a KBase Central Data Model Instance. The subsystem
is represented by a standard SEED subsystem directory.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<CDMI/new_for_script> plus the
following.

=over 4

=item recursive

If this option is specified, then instead of loading a single subsystem from
the specified directory, a subsystem will be loaded from each subdirectory
of the specified directory. This allows multiple subsystems from a single
source to be loaded in one pass.

=item clear

Recreate the subsystem tables before loading.

=item idserver

URL to use for the ID server. The default uses the standard KBase ID
server.

=back

There are two positional parameters-- the source database name (e.g. C<SEED>,
C<MOL>, ...) and the name of the directory containing the subsystem data.

=cut

# Create the command-line option variables.
my ($recursive, $clear, $id_server_url);

$id_server_url = "http://bio-data-1.mcs.anl.gov:8080/services/idserver";

# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("recursive" => \$recursive, "clear" => \$clear, "idserver=s" => \$id_server_url);
if (! $cdmi) {
    print "usage: CDMILoadSubsystem [options] source subsystemDirectory\n";
} else {
    # Get the source and subsystem directory.
    my ($source, $subsystemDirectory) = @ARGV;
    if (! $source) {
        die "No source database specified.\n";
    } elsif (! $subsystemDirectory) {
        die "No subsystem directory specified.\n";
    } elsif (! -d $subsystemDirectory) {
        die "Subsystem directory $subsystemDirectory not found.\n";
    } else {
        # Connect to the KBID server and create the loader utility object.
        my $id_server = IDServerAPIClient->new($id_server_url);
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi, $id_server);
        # Are we clearing?
        if($clear) {
            # Yes. Recreate the subsystem tables.
            my @tables = qw(Subsystem IsClassFor SubsystemClass IsSuperclassOf Provided
                            Includes Describes Variant IsRoleOf IsImplementedBy
                            SSCell IsRowOf SSRow Contains Uses);
            for my $table (@tables) {
                print "Recreating $table.\n";
                $cdmi->CreateTable($table, 1);
            }
        }
        # Are we in recursive mode?
        if (! $recursive) {
            # No. Load the one subsystem.
            LoadSubsystem($loader, $source, $subsystemDirectory);
        } else {
            # Yes. Get the subdirectories.
            opendir(TMP, $subsystemDirectory) || die "Could not open $subsystemDirectory.\n";
            my @subDirs = sort grep { substr($_,0,1) ne '.' } readdir(TMP);
            print scalar(@subDirs) . " entries found in $subsystemDirectory.\n";
            # Loop through the subdirectories.
            for my $subDir (sort @subDirs) {
                my $fullPath = "$subsystemDirectory/$subDir";
                if (-d $fullPath) {
                    LoadSubsystem($loader, $source, $fullPath);
                }
            }
        }
        # Display the statistics.
        print "All done.\n" . $loader->stats->Show();
    }
}

=head2 Subroutines

=head3 LoadSubsystem

    LoadSubsystem($loader, $source, $SubsystemDirectory);

Load a single subsystem from the specified subsystem directory.

=over 4

=item loader

L<CDMILoader> object to help manager the load.

=item source

Source database the subsystem came from.

=item subsystemDirectory

Directory containing the subsystem files. The lowest-level component of
the directory name (with any underscores translated to spaces) is the
subsystem name.

=back

=cut

sub LoadSubsystem {
    # Get the parameters.
    my ($loader, $source, $subsystemDirectory) = @_;
    # Indicate our progress.
    print "Processing $subsystemDirectory.\n";
    # Compute the subsystem name.
    my @pathParts = split /\\|\//, $subsystemDirectory;
    my $foreignID = pop @pathParts;
    my $subsysName = $foreignID;
    $subsysName =~ tr/_/ /;
    # Delete any existing copy.
    DeleteSubsystem($loader, $subsysName);
    # Initialize the relation loaders.
    $loader->SetRelations(qw(IsImplementedBy SSRow Uses IsRowOf SSCell
            IsRoleOf Contains));
    # Create the subsystem record and the surrounding roles and variants.
    my $varHash = CreateSubsystem($loader, $source, $subsysName,
            $subsystemDirectory);
    # Process the spreadsheet to connect the subsystems to the features.
    ParseSpreadsheet($loader, $source, $subsysName, $varHash,
            "$subsystemDirectory/spreadsheet");
    # Unspool the relation loaders.
    $loader->LoadRelations();
}

=head3 DeleteSubsystem

    DeleteSubsystem($loader, $subsysID);

Delete the existing data for the specified subsystem. This method is designed
to work even if the subsystem was only partially loaded. It will not, however,
delete any roles, since these do not belong to the subsystem.

=over 4

=item loader

L<CDMILoader> object to help manage the load.

=item subsysID

ID of the subsystem to delete.

=back

=cut

sub DeleteSubsystem {
    ##TODO
}

=head3 CreateSubsystem

    my $varHash = CreateSubsystem($loader, $source, $name,
                                  $subsystemDirectory);

Create the subsystem and its variants, and connect it to its
classifications.

=over 4

=item loader

L<CDMILoader> object to help manage the load.

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
    # This will contain the variants on output.
    my %retVal;
    # This will contain a hash that can be used to create the variant
    # records.
    my %varHash;
    # Get the statistics object.
    my $stats = $loader->stats;
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
            $cdmi->InsertObject('IsSuperClassOf', from_link => $nextClass, to_link => $thisClass);
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
    # Finally, we need to get the notes and description from the notes file.
    my ($description, $notes) = ("", "");
    my $notesFile = "$subsystemDirectory/notes";
    if (-f $notesFile) {
        print "Processing notes file.\n";
        open (my $ih, "<$notesFile") || die "Could not open notes file: $!\n";
        my $notesHash = ParseNotesFile($ih);
        if (exists $notesHash->{description}) {
            $description = $notesHash->{description};
        }
        if (exists $notesHash->{notes}) {
            $notes = $notesHash->{notes};
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
                }
            }
            # Insure we have the two special variants.
            if (! exists $varHash{"0"}) {
                $varHash{"0"} = 'Subsystem functionality is incomplete.';
            }
            if (! exists $varHash{"-1"}) {
                $varHash{"-1"} = 'Subsystem is not functional.';
            }
        }
    }
    # Get a digest of the subsystem name to use in forming sub-object keys.
    my $digest = Digest::MD5::md5_base64($name);
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
    # Now we create the subsystem's variants. We need to compute IDs
    # for them.
    print "Creating variants.\n";
    my @varKeys = map { "$digest:$_" } keys %varHash;
    for my $variant (keys %varHash) {
        # Find the variant's KBase ID.
        my $varKey = "$name:$variant";
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
        # Create the variant record. The role rules get added later.
        $cdmi->InsertObject('Variant', id => $varKey, code => $variant,
                comment => $varHash{$variant}, type => $type);
        $stats->Add(variants => 1);
    }
    # Return the variant map.
    return \%retVal;
}


=head3 ParseSpreadsheet

    ParseSpreadsheet($loader, $source, $subsysID, \%varHash,
                     $spreadsheetFileName);

Create the subsystem's data structures from the subsystem spreadsheet
file. This includes creating the roles and connecting them to the
genomes (in rows) and the features (in cells). Only spreadsheet rows
for genomes currently in the database will be processed.

=over 4

=item loader

L<CDMILoader> object to help manage the load.

=item source

Source (core) database the subsystem came from.

=item subsysID

ID of the subsystem.

=item varHash

Reference to a hash mapping variant codes to the variant IDs.

=item spreadsheetFileName

Name of the file containing the subsystem spreadsheet.

=back

=cut

sub ParseSpreadsheet {
    # Get the parameters.
    my ($loader, $source, $subsysID, $varHash, $spreadsheetFileName) = @_;
    # Get the database object.
    my $cdmi = $loader->cdmi;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get a digest of the subsystem name to use in forming sub-object keys.
    my $digest = Digest::MD5::md5_base64($subsysID);
    # Do we have a spreadsheet?
    if (-f $spreadsheetFileName) {
        # Yes. Open the spreadsheet file.
        print "Processing spreadsheet.\n";
        open(my $ih, "<$spreadsheetFileName") || die "Could not open spreadsheet file: $!\n";
        my (@abbrList, @roleList, %roleHash);
        # Loop through the roles.
        my $done = 0;
        while (! eof $ih && ! $done) {
            my ($abbr, $role) = $loader->GetLine($ih);
            # Is this an end marker?
            if ($abbr eq '//') {
                # Yes. Stop the loop.
                $done = 1;
            } elsif ($abbr) {
                # No, store the role.
                push @abbrList, $abbr;
                push @roleList, $role;
                $roleHash{$abbr} = $role;
            }
        }
        # The next section is the subsets. All we care about here are the auxiliary roles.
        my %auxHash;
        $done = 0;
        while (! eof $ih && ! $done) {
            my ($subset, @idxes) = $loader->GetLine($ih);
            # Is this an end marker?
            if ($subset eq '//') {
                # Yes. Stop the loop.
                $done = 1;
            } elsif ($subset =~ /^aux/) {
                # Here we have an auxiliary subset. Mark its roles in the auxiliary-role hash.
                for my $idx (@idxes) {
                    $auxHash{$abbrList[$idx - 1]} = 1;
                }
            }
        }
        # This will map role names to IDs.
        my %roleMap;
        # We now have enough information to generate the role tables.
        print "Generating roles.\n";
        my $col = 0;
        for my $abbr (@abbrList) {
            # Get the role ID and text.
            my $role = $roleHash{$abbr};
            # Insure the role is in the database.
            my $roleID = $loader->CheckRole($role);
            # Save its ID in the role map.
            $roleMap{$role} = $roleID;
            # Connect it to the subsystem
            $cdmi->InsertObject('Includes', from_link => $subsysID, to_link => $roleID,
                               abbreviation => $abbr, auxiliary => ($auxHash{$abbr} ? 1 : 0),
                               sequence => $col++);
            $stats->Add(roles => 1);
        }
        # The final section is the role table itself. Here we get the variant role
        # rules, as well.
        my %varRoleRules;
        # This variable prevents an error caused by invalid duplicate rows
        # in spreadsheets.
        my %rowIDs;
        # Now we can loop through the role table.
        $done = 0;
        print "Processing role table.\n";
        while (! eof $ih && ! $done) {
            my ($genome, $variant, @cells) = $loader->GetLine($ih);
            # Is this the end marker?
            if ($genome eq '//') {
                # Yes. Stop the loop.
                $done = 1;
            } elsif ($genome) {
                # Check for a region string.
                my ($genomeID, $regionString) = split /:/, $genome;
                # Insure this genome exists in the database.
                my ($genomeKBID) = $cdmi->GetFlat("Submitted Genome",
                    'Submitted(from_link) = ? AND Genome(source_id) = ?',
                    [$source, $genome], 'Submitted(to_link)');
                if (! $genomeKBID) {
                    $stats->Add(genomeNotFound => 1);
                } else {
                    print "Producing row for $genome.\n";
                    # Compute the true variant code and the curation flag.
                    my $curated = ($variant =~ /^\s*\*/ ? 0 : 1);
                    my $realVariant = Starless($variant);
                    $regionString ||= "";
                    # Compute the variant and row IDs.
                    my $variantID = $varHash->{$realVariant};
                    if (! $variantID) {
                        # Here the variant was not found in the notes. We
                        # must create it.
                        $variantID = "$digest:$realVariant";
                        $varHash->{$realVariant} = $variantID;
                        $cdmi->InsertObject('Variant', id => $variantID, code => $realVariant,
                                comment => "", type => "normal");
                        $stats->Add(variantNotInNotes => 1);

                    }
                    my $rowID = "$digest:$realVariant:$genomeID:$regionString";
                    # Insure the row is not a duplicate. Duplicates crash the load.
                    if ($rowIDs{$rowID}) {
                        $stats->AddMessage("Invalid duplicate row for $genome in $subsysID.");
                        $stats->Add(duplicateSSrow => 1);
                    } else {
                        # Create the row.
                        $rowIDs{$rowID} = 1;
                        $loader->InsertObject('IsImplementedBy', from_link => $variantID, to_link => $rowID);
                        $loader->InsertObject('SSRow', id => $rowID, curated => $curated,
                                           region => $regionString);
                        $loader->InsertObject('Uses', from_link => $genomeKBID, to_link => $rowID);
                        $stats->Add(subsysRow => 1);
                        # Now loop through the cells.
                        my @rolesFound;
                        for (my $i = 0; $i <= $#cells; $i++) {
                            my $cell = $cells[$i];
                            # Is this cell occupied?
                            if ($cell) {
                                # Yes. Get this cell's role abbreviation and add it to the list of roles found
                                # in this row.
                                my $abbr = $abbrList[$i];
                                push @rolesFound, $abbr;
                                # Create the cell.
                                my $cellID = "$rowID:$abbr";
                                $loader->InsertObject('IsRowOf', from_link => $rowID, to_link => $cellID);
                                $loader->InsertObject('SSCell', id => $cellID);
                                $loader->InsertObject('IsRoleOf', from_link => $roleMap{$roleHash{$abbr}},
                                                   to_link => $cellID);
                                $stats->Add(subsysCell => 1);
                                # Get the pegs in this cell.
                                my @pegs;
                                for my $pegNum (split /\s*,\s*/, $cell) {
                                    if ($pegNum =~ /[a-z]+/) {
                                        push @pegs, "fig|$genomeID.$pegNum";
                                    } else {
                                        push @pegs, "fig|$genomeID.peg.$pegNum";
                                    }
                                }
                                my $pegMap = $loader->FindKBaseIDs($source, 'Feature', \@pegs);
                                for my $peg (@pegs) {
                                    my $kbPeg = $pegMap->{$peg};
                                    if (! $kbPeg) {
                                        $stats->Add(pegNotFound => 1);
                                    } else {
                                        $loader->InsertObject('Contains', from_link => $cellID,
                                                           to_link => $pegMap->{$peg});
                                        $stats->Add(subsysPeg => 1);
                                    }
                                }
                            }
                        }
                        # Compute a role rule from this row's roles and associate it with this variant.
                        my $roleRule = join(" ", @rolesFound);
                        $varRoleRules{$variantID}->{$roleRule} = 1;
                    }
                }
            }
        }
        # We've finished the spreadsheet. Now we go back and add the role rules to the variants.
        for my $variantID (keys %varRoleRules) {
            my $ruleHash = $varRoleRules{$variantID};
            for my $roleRule (sort keys %$ruleHash) {
                $cdmi->InsertValue($variantID, 'Variant(role_rule)', $roleRule);
            }
        }
    }
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
