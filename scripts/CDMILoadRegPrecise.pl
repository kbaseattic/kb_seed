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
    use Bio::KBase::CDMI::CDMILoader;

=head1 CDMI RegPrecise Loader

    CDMILoadRegPrecise [options] inDirectory

This script loads the RegPrecise data into the CDMI. RegPrecise data
uses Microbes Online feature IDs, and relates these features to
regulons, which are stored as CoregulatedSet objects in the CDMI.
The data is stored in two tab-delimited files: in both files the
first column is a regulon ID and the second is a feature ID.

=over 4

=item kbasegene.tsv

This file relates regulons to the features they contain. It builds the
B<IsRegulatedIn> relationship.

=item kbaseregulator.tsv

This file relates regulons to the features used as their transcription
factors. It builds the B<Controls> relationship.

=back

Both files are used to build the B<Formulated> relationship and the
B<CoregulatedSet> entity. Coregulated sets are assigned KBase IDs.
The source in this case is C<RegPrecise>.

=head2 Parameters

There is a single positional parameter-- the name of the directory
containing the input files. In addition to the command-line options in
L<CDMI/new_for_script>, it supports the following.

=over 4

=item clear

Re-create the four tables before beginning the load.

=back

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my $clear;
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear);
if (! $cdmi) {
    print "usage: CDMILoadRegPrecise [options] inDirectory\n";
} else {
    # Create the loader object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Denote that IDs are typed: this is Microbes Online.
    $loader->SetTyped(1);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Get the input directory
    my ($inDirectory) = @ARGV;
    # Insure it's valid.
    if (! $inDirectory) {
        die "Missing input directory.\n";
    } elsif (! -d $inDirectory) {
        die "Invalid input directory $inDirectory.\n";
    } elsif (! -f "$inDirectory/kbasegene.tsv") {
        die "Missing kbasegene.tsv file in $inDirectory.\n";
    } elsif (! -f "$inDirectory/kbaseregulator.tsv") {
        die "Missing kbaseregulator.tsv file in $inDirectory.\n";
    } else {
        # Insure we have a RegPrecise source record.
        $loader->InsureEntity(Source => 'RegPrecise');
        # Get the list of tables we are loading.
        my @tables = qw(Formulated CoregulatedSet Controls IsRegulatedIn);
        # Are we clearing?
        if ($clear) {
            # Yes. Rebuild all the tables.
            for my $table (@tables) {
                print "Recreating table $table.\n";
                $cdmi->CreateTable($table, 1);
            }
        } else {
            # No. Clear out the existing RegPrecise data.
            print "Deleting old RegPrecise data.\n";
            $loader->DeleteRelatedRecords('RegPrecise', 'Formulated',
                    'CoregulatedSet');
        }
        # Initialize the relation loaders.
        $loader->SetRelations(@tables);
        # This will cache the coregulated set IDs. It maps each to its
        # KBase ID.
        my %coregs;
        # Both files are processed more or less the same way. The only
        # difference is the relation being loaded.
        my %relName = ('kbasegene.tsv' => 'IsRegulatedIn',
                'kbaseregulator.tsv' => 'Controls');
        for my $fileName (keys %relName) {
            # Open the input file.
            print "Reading $fileName.\n";
            open(my $ih, "<$inDirectory/$fileName") || die "Could not open $fileName file: $!\n";
            # We need to batch the incoming IDs for the requests to the ID
            # server. The first hash tracks the feature IDs found, and the
            # second maps each regulon to its related features.
            my (%fids, %regulons);
            # This tracks the number of features in this batch.
            my $batch = 0;
            # Loop through the input file.
            while (! eof $ih) {
                my ($regulon, $fid) = $loader->GetLine($ih);
                # Add this feature to the batch.
                $fids{$fid} = 1;
                push @{$regulons{$regulon}}, $fid;
                $stats->Add(lineIn => 1);
                $batch++;
                # Is the batch full?
                if ($batch >= 5000) {
                    ProcessBatch($loader, \%fids, \%regulons, \%coregs, $relName{$fileName});
                    $batch = 0;
                    %fids = ();
                    %regulons = ();
                }
            }
            # If there's anything left over, process it as well.
            if ($batch > 0) {
                ProcessBatch($loader, \%fids, \%regulons, \%coregs, $relName{$fileName});
            }
            # Close the input file.
            close $ih;
        }
        # Unspool the relations.
        print "Unspooling relations.\n";
        $loader->LoadRelations();
        # Display the statistics.
        print "All done.\n" . $stats->Show();
    }
}

=head2 Subroutines

=head3 ProcessBatch

    ProcessBatch($loader, \%fids, \%regulons, \%coregs, $relName);

Process a batch of regulon information. The feature and regulon IDs
must be converted to KBase IDs, and the appropriate relation populated.
In addition, the B<CoregulatedSet> and B<Formulated> records must be
created for coregulated sets we haven't seen yet.

=over 4

=item loader

L<CMDILoader> object for assisting in the load.

=item fids

Reference to a hash containing the feature IDs for this batch in its
keys.

=item regulons

Reference to a hash mapping each regulon ID to its related features.

=item coregs

Reference to a hash mapping each known regulon ID to its corresponding
KBase ID. It also identifies regulons that have already been output to
the B<CoregulatedSet> relation.

=item relName

Name of the relation being built from this data.

=back

=cut

sub ProcessBatch {
    # Get the parameters.
    my ($loader, $fids, $regulons, $coregs, $relName) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the KBase IDs for the features.
    my $fidMapping = $loader->FindKBaseIDs('MOL', 'Feature', [keys %$fids]);
    # Extract all the new regulon IDs.
    my @newRegs;
    for my $regulon (keys %$regulons) {
        if (! $coregs->{$regulon}) {
            push @newRegs, $regulon;
        }
    }
    # Get KBase IDs for the new regulons.
    my $regMapping = $loader->GetKBaseIDs('kb|reg', 'MOL', 'Regulon', \@newRegs);
    # Create the new regulons.
    for my $regulon (@newRegs) {
        # Get this regulon's KBase ID.
        my $regulonID = $regMapping->{$regulon};
        # Save it in the coregulated-set hash.
        $coregs->{$regulon} = $regulonID;
        # Create the regulon record.
        $loader->InsertObject('CoregulatedSet', id => $regulonID, source_id => $regulon);
        $loader->InsertObject('Formulated', from_link => 'RegPrecise', to_link => $regulonID);
        $stats->Add(regulonCreated => 1);
    }
    # Connect the regulons to the features.
    for my $regulon (keys %$regulons) {
        $stats->Add(regulonGroup => 1);
        # Get this regulon's features.
        my $fids = $regulons->{$regulon};
        for my $fid (@$fids) {
            # Get the feature's KBase ID.
            my $kbid = $fidMapping->{$fid};
            # Check to see if the feature is in the KBase.
            if (! $kbid) {
                $stats->Add(featureNotFound => 1);
            } else {
                $loader->InsertObject($relName, from_link => $fidMapping->{$fid},
                        to_link => $coregs->{$regulon});
                $stats->Add("$relName-fid" => 1);
            }
        }
    }
    print "Batch processed for $relName. " . $stats->Ask('lineIn') . " lines read.\n";
}

