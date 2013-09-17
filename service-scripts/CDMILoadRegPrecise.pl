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
The data is stored in a series of tab-delimited files-- three for
each RegPrecise genome. Each file contains two fields, the first of
which is aways a RegPrecise regulon ID. The second field in each file
is given below.

=over 4

=item regulons.###.tab

Contains the ID of each gene in the regulon.

=item binding_sites.###.tab

Contains the offset locations of the binding sites for the transcription
factors. There will generally be more than one such location.

=item transcription_factors.###.tab

Contains the ID of the regulon's transcription
factor.

=back

Both files are used to build the B<Formulated> relationship and the
B<CoregulatedSet> entity. Coregulated sets are assigned KBase IDs.
The source in this case is C<RegPrecise>.

=head2 Parameters

There is a single positional parameter-- the name of the directory
containing the input files. In addition to the command-line options in
L<Bio::KBase::CDMI::CDMI/new_for_script>, it supports the following.

=over 4

=item clear

Re-create the four tables before beginning the load.

=item source

Source database for the IDs. If omitted, the IDs are assumed to be Kbase IDs.

=back

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my ($clear, $source);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear,
        "source=s" => \$source);
if (! $cdmi) {
    print "usage: CDMILoadRegPrecise [options] inDirectory\n";
} else {
    # Create the loader object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Denote that IDs are from the specified source (if any).
    if ($source) {
        $loader->SetSource($source);
    }
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Get the input directory
    my ($inDirectory) = @ARGV;
    # Insure it's valid.
    if (! $inDirectory) {
        die "Missing input directory.\n";
    } elsif (! -d $inDirectory) {
        die "Invalid input directory $inDirectory.\n";
    } else {
        # Insure we have a RegPrecise source record.
        $loader->InsureEntity(Source => 'RegPrecise');
        # Get the list of tables we are loading.
        my @tables = qw(Formulated CoregulatedSet CoregulatedSetBinding Controls IsRegulatedIn);
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
        # Get the regulon files.
        opendir(TMP, $inDirectory) || die "Could not open $inDirectory.\n";
        my @regFiles = sort grep { $_ =~ /^regulons\..+\.tab$/ } readdir(TMP);
        print scalar(@regFiles) . " regulon files found in $inDirectory.\n";
        # Loop through the files, processing each group of three.
        for my $regFile (@regFiles) {
            # Extract the genome ID.
            my ($genome) = ($regFile =~ /regulons\.(.+)\.tab/);
            $stats->Add(genomes => 1);
            # Read in the three files. The first hash tracks the actual
            # data for each regulon. The second will track all of the
            # feature IDs read in.
            my (%regData, %features);
            for my $fileType (qw(regulons binding_sites transcription_factors)) {
                # Compute the file name.
                my $fileName = "$inDirectory/$fileType.$genome.tab";
                # Insure it exists.
                if (! -f $fileName) {
                    print "No $fileType found for genome $genome.\n";
                    $stats->Add(missingFile => 1);
                } else {
                    # Open the file and loop through it.
                    open(my $ih, "<$fileName") || die "Could not open $fileName: $!\n";
                    $stats->Add("$fileType-file" => 1);
                    print "Processing $fileType for genome $genome.\n";
                    while (! eof $ih) {
                        my ($regulon, $data) = $loader->GetLine($ih);
                        push @{$regData{$regulon}{$fileType}}, $data;
                        $stats->Add(lineIn => 1);
                        # If this is not the binding-sites file, save
                        # the data value in the list of feature IDs.
                        if ($fileType ne 'binding_sites') {
                            $features{$data} = 1;
                        }
                    }
                }
            }
            # Now we get the KBase feature IDs, if necessary.
            my $idMap;
            if ($source) {
                print "Interrogating ID server for $genome.\n";
                $idMap = $loader->FindKBaseIDs('Feature', [keys %features]);
            } else {
                print "KBase IDs used for $genome.\n";
                my %idMap = map { $_ => $_ } keys %features;
                $idMap = \%idMap;
            }
            # And now the KBase regulon IDs. Unlike the feature IDs, these don't
            # need to already exist in the database.
            my @regulons = keys %regData;
            my $regMap = $loader->GetKBaseIDs('kb|reg', 'Regulon', \@regulons);
            print "Producing output for $genome.\n";
            # Loop through the regulons.
            for my $regulon (keys %regData) {
                # Get the regulon's KBase ID.
                my $kbID = $regMap->{$regulon};
                # Create the regulon object itself.
                $loader->InsertObject('Formulated', from_link => 'RegPrecise',
                    to_link => $kbID);
                $loader->InsertObject('CoregulatedSet', id => $kbID, source_id =>
                    $regulon);
                $stats->Add(regulons => 1);
                # Add the binding offsets.
                my $bindings = $regData{$regulon}{binding_sites};
                if ($bindings) {
                    $stats->Add(boundRegulons => 1);
                    for my $binding (@$bindings) {
                        $loader->InsertObject('CoregulatedSetBinding', id => $kbID,
                            binding_location => $binding);
                        $stats->Add(bindingValues => 1);
                    }
                }
                # Attach the features. Note we have to deal with the possibility
                # that a particular feature does not exist.
                my $features = $regData{$regulon}{regulons};
                if ($features) {
                    for my $feature (@$features) {
                        my $kbFid = $idMap->{$feature};
                        if (! $kbFid) {
                            print STDERR "Could not find member feature $feature for $genome.\n";
                            $stats->Add(memberFeatureNotFound => 1);
                        } else {
                            $loader->InsertObject('IsRegulatedIn', from_link => $kbFid,
                                to_link => $kbID);
                            $stats->Add(featureInRegulon => 1);
                        }
                    }
                }
                # Finally, attach the transcription factors.
                my $factors = $regData{$regulon}{transcription_factors};
                if ($factors) {
                    $stats->Add(factorsFound => 1);
                    for my $factor (@$factors) {
                        my $kbFid = $idMap->{$factor};
                        if (! $kbFid) {
                            print STDERR "Could not find factor feature $factor for $genome.\n";
                            $stats->Add(factorFeatureNotFound => 1);
                        } else {
                            $loader->InsertObject('Controls', from_link => $kbFid,
                                to_link => $kbID);
                            $stats->Add(factorForRegulon => 1);
                        }
                    }
                }
            }
            print "$genome processed.\n";
        }
        # Unspool the relations.
        $loader->LoadRelations();
        # Display the load statistics.
        print "All done:\n" . $stats->Show();
    }
}
