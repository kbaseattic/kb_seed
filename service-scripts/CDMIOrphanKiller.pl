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
    use Stats;
    use SeedUtils;
    use Bio::KBase::CDMI::CDMI;

=head1 CDMI Database Cleaner

    CDMIOrphanKiller [options]

This script looks for orphan relationships, that is, relationships records
that are missing a target, and deletes them from the database.

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script>. The
sole positional parameter is the name of the relationship. The orphan check
will be in the to-link direction.

=cut

$| = 1;
# Get the statistics object.
my $stats = Stats->new();
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMIOrphanKiller [options] relName\n";
} else {
    # Get the relationship name.
    my $relName = $ARGV[0];
    if (! $relName) {
        die "No relationship name specified.\n";
    } else {
        # Find the target entity.
        my $entity = $cdmi->ComputeTargetEntity($relName);
        if (! $entity) {
            die "Invalid relationship name $relName.\n";
        } else {
            # Get the relationship's real name.
            my $realName = $cdmi->_Resolve($relName);
            # This will track the most recent target ID.
            my $oldTargetID = "";
            # This will be used for tracking messages.
            my $count = 0;
            # We'll store the bad target IDs in here.
            my %badIDs;
            print "Processing $relName.\n";
            # Loop through all of the relationship instances.
            my $q = $cdmi->Get($relName, "ORDER BY $relName(to-link)", []);
            while (my $record = $q->Fetch()) {
                $stats->Add(instanceFound => 1);
                # Get this ID.
                my $targetID = $record->PrimaryValue('to-link');
                # Only check this ID if it's new.
                if ($targetID ne $oldTargetID) {
                    $stats->Add(uniqueTarget => 1);
                    my ($found) = $cdmi->GetFlat($entity, "$entity(id) = ?", [$targetID],
                            'id');
                    if (! $found) {
                        print "Orphan ID $targetID found.\n";
                        $badIDs{$targetID} = 1;
                        $stats->Add(orphanFound => 1);
                    }
                    # Set up for the next time through.
                    $oldTargetID = $targetID;
                }
                # Show our progress.
                $count++;
                if ($count % 50000 == 0) {
                    print "$count instances processed.\n";
                }
            }
            # Run through the bad IDs found, deleting the relationship
            # instances.
            print "Processing orphans.\n";
            for my $orphan (keys %badIDs) {
                my $counter = $cdmi->Disconnect($realName, $entity, $orphan);
                $stats->Add(deleted => $counter);
            }
        }
    }
    # Display the statistics.
    print "All done:\n" . $stats->Show();
}