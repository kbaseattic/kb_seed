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

=head1 Redundant Genome Selection Utility

    CDMIFindRedundantGenomes [options] <delFileName>

=head2 Introduction

This script searches for genomes in a CDMI that have the same sequence
data. One genome is selected as preferred. First, a genome connected to
expression data is automatically preferred. If no expression data is
found, an optional list of preferred source IDs is checked. If no source
ID is preferred, then the SEED version of the genome with the numerically
lowest source ID is chosen. The list of genomes to be deleted is produced
in the indicated output file. The standard output contains a description
of what was found.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item prefer

If specified, the name of a file containing source IDs for preferred genomes.
The source IDs should be specified one per line. If a tab character is found
on a line, the tab and everything after it is ignored. In other words, the
input is a tab-delimited file with the source genome IDs in the first column
and any additional columns are ignored.

=item keep

If specified, the name of a file to contain a list of the genomes to be
kept. The file will be tab-delimited, with the KBase genome ID in the
first column, followed by the genome name, the source ID, and the source
database name.

=back

There is a single position parameter: the name of a file to contain a
list of KBase IDs for genomes considered redundant.

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;

    # Readable names for priorities.
    use constant PRIO => { A => 'expressed', B => 'preferred', C => 'source',
                           D => 'other' };

    $| = 1; # Prevent buffering on STDOUT.
    # These will hold the prefered ID file name and the output file names.
    my ($preferFileName, $outFileName, $keepFileName);
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("keep=s" => \$keepFileName,
            "prefer=s" => \$preferFileName);
    if (! $cdmi) {
        print "usage: CDMIFindRedundantGenomes [options] outputFile\n";
    } else {
        # Create the statistics object.
        my $stats = Stats->new();
        # Get the output file name.
        $outFileName = $ARGV[0];
        if (! $outFileName) {
            die "No output file name specified.\n";
        } else {
            # The preferred source IDs will be put in this hash.
            my %prefer;
            if (defined $preferFileName) {
                print "Reading preferred IDs from $preferFileName.\n";
                # Here a preferred-ID file was specified, so we need to read
                # it into the hash.
                my $ih;
                if (! -f $preferFileName) {
                    die "Prefer option file $preferFileName not found.\n";
                } elsif (! open($ih, "<$preferFileName")) {
                    die "Could not open prefer option file: $!\n";
                } else {
                    while (! eof $ih) {
                        my ($genomeID) = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
                        $prefer{$genomeID} = 1;
                        $stats->Add(preferredID => 1);
                    }
                }
            }
            # Create the keep file if the user wants one.
            my $kh;
            if ($keepFileName) {
                open($kh, ">$keepFileName") || die "Could not open output file $keepFileName: $!\n";
            }
            # Get a hash of all the KBase IDs for genomes with expression data.
            my %express = map { $_ => 1 } $cdmi->GetFlat("HadResultsProducedBy",
                                                "", [], "from-link");
            my $expCount = scalar keys %express;
            print "$expCount genomes found with expression data.\n";
            # Open the output file.
            open my $oh, ">$outFileName";
            $stats->Add(expressedID => $expCount);
            # Query the database for genomes using the sequence MD5.
            print "Preparing to read from database query.\n";
            my $query = $cdmi->Get("Genome WasSubmittedBy", "ORDER BY Genome(md5)",
                []);
            # This will contain the MD5 of the current batch of genomes.
            my $currentMd5 = "";
            # For each batch, we have a list of the genomes kept in here.
            # Each genome is stored as a 5-tuple consisting of (0) the
            # priority, (1) the KBase genome ID, (2) its scientific name,
            # (3) its source ID, and (4) its source database. The priority
            # codes are "A" if the genome has expression data, "B" if it is
            # preferred, "C" if it is from the SEED, and "D" otherwise.
            my @currentGenomes;
            # Now loop through the query.
            while (my $genome = $query->Fetch()) {
                # Get the data fields for the current genome.
                my ($kbID, $md5, $name, $sourceID, $source) =
                    $genome->Values([qw(id md5 scientific-name source-id
                        WasSubmittedBy(to-link))]);
                $stats->Add("genomeFrom$source" => 1);
                $stats->Add(totalGenomes => 1);
                # Now we compute the priority.
                my $prio = "D";
                if ($express{$kbID}) {
                    $prio = "A";
                } elsif ($prefer{$sourceID}) {
                    $prio = "B";
                } elsif ($source eq 'SEED') {
                    $prio = "C";
                }
                $stats->Add(PRIO->{$prio} . "Found" => 1);
                # Is this genome from the current batch?
                if ($md5 ne $currentMd5) {
                    # No. Close the old batch.
                    ProcessBatch($stats, $oh, $kh, $currentMd5, \@currentGenomes);
                    @currentGenomes = ();
                    $currentMd5 = $md5;
                }
                # Save the new genome.
                push @currentGenomes, [$prio, $kbID, $name, $sourceID, $source];
            }
            # Process the residual batch.
            ProcessBatch($stats, $oh, $kh, $currentMd5, \@currentGenomes);
            # All done, close the files and print the stats.
            close $oh;
            print "All done:\n" . $stats->Show();
        }
    }

# This method processes a batch of genomes. The genomes to be deleted
# are written to the output file.
sub ProcessBatch {
    my ($stats, $oh, $kh, $md5, $currentGenomes) = @_;
    # Only process the batch if there is more than one genome.
    my $count = scalar @$currentGenomes;
    if ($count) {
        $stats->Add("batchOf$count" => 1);
        if ($count == 1) {
            # Singleton. Output to the keeper file if we have one.
            if ($kh) {
                my ($prio, $kbID, $name, $sourceID, $source) = @{$currentGenomes->[0]};
                print $kh join("\t", $kbID, $name, $sourceID, $source) . "\n";
            }
        } else {
            # A real batch. Sort the genomes by priority.
            my @sorted = sort { $a->[0] cmp $b->[0] } @$currentGenomes;
            # Select the first and delete the rest.
            my $selected = $sorted[0][1];
            print "Genomes for $md5:\n";
            for my $genome (@sorted) {
                my ($prio, $kbID, $name, $sourceID, $source) = @$genome;
                my $marker = "";
                if ($kbID eq $selected) {
                    $marker = " SELECTED";
                    $stats->Add(PRIO->{$prio} . "Selected" => 1);
                    # If we have a keeper file, output this genome to it.
                    if ($kh) {
                        print $kh join("\t", $kbID, $name, $sourceID, $source) . "\n";
                    }
                } else {
                    print $oh "$kbID\n";
                }
                print "$kbID: $name ($sourceID from $source) $prio$marker\n";
            }
        }
    }
}