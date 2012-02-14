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
use CDMI;
use CDMILoader;
use IDServerAPIClient;

=head1 CDMI Expression Data Loader

    CDMILoadExpression [options] source expDirectory

Load expression data for a genome into a KBase Central Data Model Instance.
At the current time, we do not support multiple sets of expression data
per genome. A future database update will address this.

The lowest-level name of the directory must be the genome ID. Data is
represented by the following files.

=over 4

=item chip (optional)

Contains the ID of the chip used to run the experiments. If this file
is missing, a chip ID is artificially generated from the genome ID.

=item experiment.names

A two-column tab-delimited file containing the names of the experiments performed
using the chip. The first column is an index number and the second is
the experiment name.

=item rma_normalized.tab (optional)

A tab-delimited file containing the normalized expression levels from the
experiments. The first row contains a list of experiment names, indicating
the order the results will appear in. The remaining rows contain a feature
ID in the first column followed by the expression level for that feature
in each experiment.

=item final_on_off_calls.txt (required if B<rma_normalized.tab> present)

A tab-delimited file containing the on/off calls computed from the
normalized expression results. The first row is ignored (it basically
contains the same information as the first row of B<rma_normalized.tab>
in a different format). The remaining rows contain a feature ID in
the first column followed by on/off indicators-- C<-1> for off, C<1>
for on, and C<0> for indeterminate.

=item pearson.tbl

A tab-delimited file containing pearson coefficients for pairs of
features with significant correlation or anti-correlation. The
first two columns contain feature IDs, and the third column contains
the pearson coefficient for the expression results of the two
features.

=item atomic.regulons

A tab-delimited file containing the atomic regulons for the
genome. The first column is an atomic regulon ID and the second
is a feature ID. The atomic regulon IDs are not unique across
genomes.

=item ar.vectors

A tab-delimited file containing the on/off results for the
atomic regulons with respect to the experiments. The first
column is the atomic regulon ID and the second is a comma-delimited
list of the on-off values.

=back


=head2 Command-Line Options and Parameters

The command-line options are those specified in L<CDMI/new_for_script> plus the
following.

=over 4

=item recursive

If this option is specified, then instead of loading a single expression
data set from the specified directory, data will be loaded from each subdirectory
of the specified directory. This allows multiple data sets from a single
source to be loaded in one pass.

=item newOnly

If this option is specified, a data set will only be loaded if its chip is
not already found in the database.

=item clear

If this option is specified, the expression tables will be recreated
before loading.

=item idserver

URL to use for the ID server. The default uses the standard KBase ID
server.

=back

There are two positional parameters-- the source database name (e.g. C<SEED>,
C<MOL>, ...) and the name of the directory containing the expression data.

=cut

use constant TABLES => [qw(ProbeSet IndicatedLevelsFor ProducedResultsFor
                            HasResultsIn Experiment AffectsLevelOf
                            HasIndicatedSignalFrom AtomicRegulon
                            IsFormedOf IsConfiguredBy GeneratedLevelsFor
                            IsCoregulatedWith)];

# Create the command-line option variables.
my ($recursive, $newOnly, $clear, $id_server_url);

# Connect to the database.
my $cdmi = CDMI->new_for_script("recursive" => \$recursive, "newOnly" => \$newOnly,
        "clear" => \$clear, "idserver=s" => \$id_server_url);
if (! $cdmi) {
    print "usage: CDMILoadExpression [options] source genomeDirectory\n";
    exit;
}

# Get the source and expression directory.
    my ($source, $expDirectory) = @ARGV;
    if (! $source) {
        die "No source database specified.\n";
    } elsif (! $expDirectory) {
        die "No expression directory specified.\n";
    } elsif (! -d $expDirectory) {
        die "Expression directory $expDirectory not found.\n";
    } else {

        # Connect to the KBID server and create the loader utility object.
	my $id_server;
	if ($id_server_url) {
	    $id_server = IDServerAPIClient->new($id_server_url);
	}
        my $loader = CDMILoader->new($cdmi, $id_server);

        # Are we clearing?
        if($clear) {
            # Yes. Recreate the expression tables.
            for my $table (@{TABLES()}) {
                print "Recreating $table.\n";
                $cdmi->CreateTable($table, 1);
            }
        }
        # Are we in recursive mode?
        if (! $recursive) {
            # No. Load the one expression directory.
            LoadExpressionData($loader, $source, $expDirectory);
        } else {
            # Yes. Get the subdirectories.
            opendir(TMP, $expDirectory) || die "Could not open $expDirectory.\n";
            my @subDirs = sort grep { substr($_,0,1) ne '.' } readdir(TMP);
            print scalar(@subDirs) . " entries found in $expDirectory.\n";
            # Loop through the subdirectories.
            for my $subDir (@subDirs) {
                my $fullPath = "$expDirectory/$subDir";
                if (-d $fullPath) {
                    LoadExpressionData($loader, $source, $fullPath);
                }
            }
        }
        # Display the statistics.
        print "All done.\n" . $loader->stats->Show();
    }


=head2 Subroutines

=head3 LoadExpressionData

    LoadExpression($loader, $source, $genomeDirectory);

Load a single genome's expression data from the specified directory.

=over 4

=item loader

L<CDMILoader> object to help manager the load.

=item source

Source database the genome came from.

=item expDirectory

Directory containing the expression data files.

=back

=cut

sub LoadExpressionData {
    # Get the parameters.
    my ($loader, $source, $expDataDirectory) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the database.
    my $cdmi = $loader->cdmi;
    # Get the genome ID.
    my $genomeID = $expDataDirectory;
    if ($expDataDirectory =~ m#.+\/([^/]+)#) {
        $genomeID = $1;
    }
    # Convert it to KBase. If it's not in the database, we won't find it
    # and we'll skip it.
    my ($genome) = $cdmi->GetFlat("Submitted Genome",
            'Submitted(from-link) = ? AND Genome(source-id) = ?',
            [$source, $genomeID], 'Genome(id)');
    if (! defined $genome) {
        print "Genome $genomeID not found.\n";
        $stats->Add(genomeNotFound => 1);
    } else {
        print "Processing $expDataDirectory for $genomeID ($genome).\n";
        # Initialize the relation loaders.
        $loader->SetRelations(@{TABLES()});
        # The chipd ID will go in here.
        my $chipID;
        # Check for a chip ID file.
        my $chipFileName = "$expDataDirectory/chip";
        if (-f $chipFileName) {
            # Chip file found.
            open(my $ih, "<$chipFileName") || die "Could not open chip file: $!\n";
            # Read the chip ID.
            ($chipID) = $loader->GetLine($ih);
            # Close the chip file.
            close $ih;
            # Denote we have a custom chip ID.
            $stats->Add(customChipID => 1);
        } else {
            # Generate a default chip ID.
            $chipID = $loader->GetKBaseID('kb|chip', $source, "Chip:$genomeID");
        }
        # Create the chip record.
        $loader->InsertObject('ProbeSet', id => $chipID);
        # Connect it to the genome.
        $loader->InsertObject('ProducedResultsFor', from_link => $chipID, to_link => $genome);
        # Get KBase IDs for all the features. We only care about features
        # already in the database.
        print "Generating feature map.\n";
        my %fidMap = map { $_->[0] => $_->[1] }
                $cdmi->GetAll("IsOwnerOf Feature", 'IsOwnerOf(from-link) = ?',
                [$genome], 'Feature(source-id) Feature(id)');
        # Do we have experiments?
        my @experiments = ReadExperiments($expDataDirectory);
        if (! @experiments) {
            # No, so skip this genome.
            print "No experiment names found for $genome.\n";
            $stats->Add(missingExperimentNames => 1);
        } else {
            # Yes. This hash maps experiment IDs to sequence numbers.
            my %expHash;
            # Remember the number of experiments.
            my $expCount = scalar @experiments;
            # Loop through the experiments, putting them in the experiment table and the
            # experiment hash.
            for (my $seqNo = 0; $seqNo < $expCount; $seqNo++) {
                my $name = $experiments[$seqNo];
                $expHash{$name} = $seqNo;
                $loader->InsertObject('HasResultsIn', from_link => $chipID, to_link => $name,
                                    sequence => $seqNo);
                $loader->InsertObject('Experiment', id => $name, source => '');
                $stats->Add(experiments => 1);
            }
            # We'll use this to hold our input file handles.
            my $ih;
            # Check for a raw data file.
            my $raw_data_file = "$expDataDirectory/rma_normalized.tab";
            if (! -f $raw_data_file) {
                # This means we have a chip and probes, but no experimental results.
                print "No raw data file found for $genome expression data.\n";
                $stats->Add(missingRawData => 1);
            } else {
                # Open the raw data file.
                open($ih, "<$raw_data_file") || die "Could not open rma_normalized.tab: $!\n";
                print "Processing expression data from $raw_data_file.\n";
                # Read the list of experiments.
                my @exps = $loader->GetLine($ih);
                # Spool them into the experiment table if they're not already there.
                for my $exp (@exps) {
                    if (! exists $expHash{$exp}) {
                        $loader->InsertObject('HasResultsIn', from_link => $chipID,
                                            to_link => $exp, sequence => -1);
                        $loader->InsertObject('Experiment', id => $exp, source => '');
                        $stats->Add(extraExperiment => 1);
                    }
                }
                # We'll put the signal values in here. For each feature, we will
                # have a list of signals in the same order as the list of experiments.
                my $corrH = {};
                while (! eof $ih) {
                    my ($fid, @signals) = $loader->GetLine($ih);
                    # Store the signals in the hash.
                    $corrH->{$fid} = \@signals;
                }
                # Close the raw data file.
                close $ih; undef $ih;
                # Now we need to generate the signal records. This includes the signal values we just
                # read in plus on/off indications from the "final_on_off_calls.txt".
                open($ih, "<$expDataDirectory/final_on_off_calls.txt") || die "Could not open final_on_off_calls.\n";
                # Discard the experiment list. It will be the same as the one we already have.
                $loader->GetLine($ih);
                # Loop through the on/off file.
                while (! eof $ih) {
                    my ($fid, @onOffs) = $loader->GetLine($ih);
                    # Insure this feature exists in the KBase.
                    my $fidKBID = $fidMap{$fid};
                    if (! defined $fidKBID) {
                        $stats->Add(onOffCallsFidNotFound => 1);
                    } else {
                        # Get the signals for this feature.
                        my $signals = $corrH->{$fid};
                        if (! $signals) {
                            print "No signals found for $fid in experiments for $genome.\n";
                            $stats->Add(noSignals => 1);
                        } else {
                            # This will be used to build the levels vector.
                            my @levels;
                            # Generate the signal records.
                            for (my $i = 0; $i <= $#exps; $i++) {
                                if (defined $signals->[$i]) {
                                    # Here we have a signal for this experiment.
                                    $loader->InsertObject('HasIndicatedSignalFrom', to_link => $exps[$i],
                                                        from_link => $fidKBID, rma_value => $signals->[$i],
                                                        level => $onOffs[$i]);
                                    $stats->Add(signalX => 1);
                                } else {
                                    # No signal, so no indication will be built.
                                    $stats->Add(signalZ => 1);
                                }
                                # Next, we put the on/off level in the experiment vector.
                                my $i = $expHash{$exps[$i]};
                                if (defined $i) {
                                    $levels[$i] = $onOffs[$i];
                                }
                            }
                            # We need to connect the feature to the chip, specifying the level vector.
                            # First, we must fill in the gaps.
                            for (my $i = 0; $i <= $expCount; $i++) {
                                if (! defined $levels[$i]) {
                                    $levels[$i] = 0;
                                    $stats->Add(fidLevelGap => 1);
                                }
                            }
                            # Output the relationship.
                            $loader->InsertObject('IndicatedLevelsFor', from_link => $chipID,
                                                to_link => $fidKBID, level_vector => \@levels);
                        }
                    }
                }
                # Close the on/off call file.
                close $ih; undef $ih;
                # Check to see if we can load the correlation coefficients.
                my $pearsonFile = "$expDataDirectory/pearson.tbl";
                if (! -f $pearsonFile) {
                    Trace("Could not find pearson coefficients for $genome.") if T(1);
                    $stats->Add(missingPearson => 1);
                } else {
                    # Yes we can. Read them from the pearson coefficient file.
                    open($ih, "<$pearsonFile") || die "Could not open pearson file: $!\n";
                    while (! eof $ih) {
                        my ($fid1, $fid2, $pc) = Tracer::GetLine($ih);
                        # Only proceed if both feature exists.
                        if (! defined $fidMap{$fid1} || ! defined $fidMap{$fid2}) {
                            $stats->Add(pearsonFidNotFound => 1);
                        } else {
                            # Store both directions of the correlation.
                            $loader->InsertObject('IsCoregulatedWith', from_link => $fidMap{$fid1},
                                                           to_link => $fidMap{$fid2}, coefficient => $pc);
                            $loader->InsertObject('IsCoregulatedWith', from_link => $fidMap{$fid2},
                                                           to_link => $fidMap{$fid1}, coefficient => $pc);
                            $stats->Add(corrCoefficients => 2);
                        }
                    }
                    # Close the pearson file.
                    close $ih; undef $ih;
                }
            }
            # Open the atomic regulon file.
            open($ih, "<$expDataDirectory/atomic.regulons") || die "Could not open atomic regulon file: $!\n";
            # We'll track our regulons in here.
            my %regulons;
            print "Generating regulons for $genome.\n";
            # Loop through the regulons.
            while (! eof $ih) {
                my ($id, $fid) = Tracer::GetLine($ih);
                # Only proceed if the feature exists.
                my $fidKBID = $fidMap{$fid};
                if (! defined $fidKBID) {
                    $stats->Add(atomicRegulonFidNotFound => 1);
                } else {
                    $stats->Add(regulonRecord => 1);
                    # Compute the real regulon ID.
                    my $realID = "$genome.ar.$id";
                    # Is this is a new regulon?
                    if (! exists $regulons{$id}) {
                        # Yes. Create the regulon record and connect it to the genome.
                        $loader->InsertObject('AtomicRegulon', id => $realID);
                        $loader->InsertObject('IsConfiguredBy', from_link => $genome,
                                            to_link => $realID);
                        # Make sure we know this is handled.
                        $regulons{$id} = 1;
                    }
                    # Connect the regulon to the feature.
                    $loader->InsertObject('IsFormedOf', from_link => $realID, to_link => $fidKBID);
                }
            }
            close $ih; undef $ih;
            print "Generating expression levels for $genome.\n";
            # Now we can connect the regulons to the experiments.
            open($ih, "<$expDataDirectory/ar.vectors") || die "Could not open AR vectors file: $!\n";
            # Loop through the experiment vectors.
            while (! eof $ih) {
                my ($id, $levelList) = $loader->GetLine($ih);
                $stats->Add(vectorRecord => 1);
                # Compute the real regulon ID.
                my $realID = "$genome.ar.$id";
                # Extract the expression levels.
                my @levels = split /\s*,\s*/, $levelList;
                my $levelCount = scalar @levels;
                if ($levelCount != $expCount) {
                    print "Vector $id for $genome has $levelCount levels for $expCount experiments.\n";
                    if ($levelCount < $expCount) {
                        $stats->Add(shortExpressionVector => 1);
                    } else {
                        $stats->Add(longExpressionVector => 1);
                    }
                }
                # Loop through them, connecting the regulon to experiments.
                for (my $i = 0; $i <= $#levels; $i++) {
                    if ($i >= $expCount) {
                        $stats->Add(extraExpressionVectorElement => 1);
                    } else {
                        $loader->InsertObject('AffectsLevelOf', from_link => $experiments[$i],
                                            to_link => $realID, level => $levels[$i]);
                    }
                }
                # Create the atomic regulon experiment vector.
                $loader->InsertObject('GeneratedLevelsFor', from_link => $chipID,
                                    to_link => $realID, level_vector => \@levels);
            }
        }
        # Load the relations.
        print "Unspooling relations.\n";
        $loader->LoadRelations();
    }
}

=head3 ReadExperiments

    my @experiments = ReadExperiments($expDataDirectory);

Read in the vector of experiment names for this genome. If the experiment names file does
not exist, an empty list will be returned.

=over 4

=item expDataDirectory

Directory containing the experimental data files.

=back

=cut

sub ReadExperiments {
    # Get the parameters.
    my ($expDataDirectory) = @_;
    # This array will hold the experiment names.
    my @retVal;
    # Compute the experiment-names file name.
    my $fileName = "$expDataDirectory/experiment.names";
    # Only proceed if the file exists.
    if (-f $fileName) {
        # Get the vector of experiment IDs.
        open (my $ih, "<$fileName") || die "Could not open experiment names file: $!\n";
        # Read in the experiments.
        while (! eof $ih) {
            my ($id, $name) = CDMILoader::GetLine($ih);
            # Note that the experiment numbers are 1-based.
            my $seqNo = $id - 1;
            $retVal[$seqNo] = $name;
        }
    }
    # Return the experiment vector.
    return @retVal;
}


