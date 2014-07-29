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

=head1 Feature Location Error Check

    CDMIFixLocations [options]

=head2 Introduction

This script searches for features that are missing location information. The genomes
with this problem will be identified and then displayed along with the number of
bad features found.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;

    $| = 1; # Prevent buffering on STDOUT.
    # These will hold genome counts.
    my %genomeCounts;
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    if (! $cdmi) {
        print "usage: CDMIFixLocations [options]\n";
    } else {
        # Create the loader object.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        # Get the statistics object.
        my $stats = $loader->stats;
        # Loop through the features.
        my $qry = $cdmi->Get('Feature IsOwnedBy', "", []);
        while (my $record = $qry->Fetch()) {
            my ($fid, $seqLen, $gid) = $record->Values(['id', 'sequence-length',
                    'IsOwnedBy(to-link)']);
            my $count = $stats->Add(featureRead => 1);
            if ($count % 50000 == 0) {
                print "$count features read.\n";
            }
            # Get the feature's location list.
            my @locs = $cdmi->GetLocations($fid);
            # If there are no locations, that's the error.
            if (! @locs) {
                $genomeCounts{$gid}++;
                $stats->Add(missingLocations => 1);
            }
        }
        print "Statistics by genome.\n";
        for my $gid (sort keys %genomeCounts) {
            # Get the specifications of this genome.
            my ($genomeData) = $cdmi->GetAll("Genome WasSubmittedBy", "Genome(id) = ?",
                    [$gid], "scientific-name source-id WasSubmittedBy(to-link)");
            my ($name, $sid, $source) = @$genomeData;
            print join("\t", $gid, $name, $sid, $source, $genomeCounts{$gid}) . "\n";
        }
        print "All done:\n" . $stats->Show();
        
    }
    
