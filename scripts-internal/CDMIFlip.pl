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

=head1 Relationship Flipper Script for CDMI

    CDMIFlip [options] <relName>

=head2 Introduction

This script reverses an improperly-loaded relationship in the CDMI.
Essentially, the from-link and to-link fields will be reversed. The
relationship is dumped to a temporary file and reloaded.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item dir

Directory to use for the temporary file. If omitted, the load directory
of the database is used.

=item dumped

Name of a file containing data dumped by a previous run. Use this to
recover from an error during the reload phase (in which case the old
data exists in a file, but was not properly put back into the database).
If omitted, the program runs normally.

=back

There is a single positional parameter: the name of the relationship.

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;

    $| = 1; # Prevent buffering on STDOUT.
    # This will hold the load directory name and the temporary file name.
    my ($dirName, $fileName);
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("dir=s" => \$dirName,
        "dumped=s" => \$fileName);
    if (! $cdmi) {
        print "usage: CDMIFlip [options] relName\n";
    } else {
        # Create the loader object.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        # Create the statistics object.
        my $stats = Stats->new();
        # Get the relationship name.
        my $relName = $ARGV[0];
        if (! $relName) {
            die "No relationship name specified.\n";
        } else {
            # Get its descriptor.
            print "Analyzing $relName.\n";
            my $relData = $cdmi->FindRelationship($relName);
            if (! $relData) {
                die "Relationship $relName not found in database.\n";
            } else {
                # Set up the loader to load it.
                $loader->SetRelations($relName);
                # Get the list of the fields in the relationship.
                my @fields = map { $_->{name} } @{$relData->{Relations}{$relName}{Fields}};
                # Get a list of the array indices for the fields.
                my @indices;
                for (my $i = 0; $i < @fields; $i++) {
                    push @indices, $i;
                }
                # Do we have a dump file?
                if ($fileName) {
                    # Yes. We'll use it instead of creating a new one.
                    print "Using data from $fileName.\n";
                } else {
                    # No. Get the load directory name and create a temporary
                    # file name.
                    if (! defined $dirName) {
                        $dirName = $cdmi->LoadDirectory();
                    }
                    $fileName = "$dirName/$relName$$.dtx";
                    # Now we dump the relationship links.
                    print "Dumping old relationship.\n";
                    open(my $oh, ">$fileName") || die "Could not create output file $fileName.\n";
                    my $q = $cdmi->Get($relName, "", []);
                    while (my $record = $q->Fetch()) {
                        my @data = $record->Values(\@fields);
                        $stats->Add(linesIn => 1);
                        print $oh join("\t", @data) . "\n";
                    }
                    close $oh;
                }
                # Open the dump file for input.
                print "Preparing for reload.\n";
                open(my $ih, "<$fileName") || die "Could not open temp file $fileName.\n";
                # The from- and to-links are the first two fields. Switch them around.
                # This way they'll flip when we write the records back to the database.
                ($fields[0], $fields[1]) = ($fields[1], $fields[0]);
                # Clear the table.
                $cdmi->TruncateTable($relName);
                # Reload it with the links inverted.
                print "Reloading relationship.\n";
                while (! eof $ih) {
                    my @data = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
                    $loader->InsertObject($relName, map { $fields[$_] => $data[$_] } @indices);
                    $stats->Add(newLine => 1);
                }
                # Delete the temporary file.
                print "Cleaning up.\n";
                close $ih;
                unlink $fileName;
                # Unspool the relationship.
                print "Unspooling.\n";
                $loader->LoadRelations();
                # All done, print the stats.
                print "All done:\n" . $stats->Show();
            }
        }
    }