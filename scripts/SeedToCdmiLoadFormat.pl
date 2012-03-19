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
use Tracer;
use Bio::KBase::CDMI::CDMI;
use Stats;
use Time::HiRes;
use File::Copy;
use BasicLocation;

=head1 SEED Genome Conversion Script for CDMI Load

    SeedToCdmiLoadFormat [options] <outDirectory> <genome1> <genome2> ...

=head2 Introduction

This script converts SEED genome directories into the genome load
format specified for the Kbase Central Data Model.

=head2 Positional Parameters

=over 4

=item outDirectory

Name of the directory in which to put the output. The output will be
one directory per genome, containing the four files used to load
genomes into a CDMI.

=item genomeN

ID of a SEED genome to load.

=back

=head2 Command-Line Options

=over 4

=item newOnly

If specified, an organism which already has an output directory will be
skipped.

=item orgDirectory

Name of the directory containing the genome directories to load. If omitted,
the organism directory from the FIG_Config file will be used.

=item trace

Specifies the tracing level. The higher the tracing level, the more messages
will appear in the trace log. Use E to specify emergency tracing.

=item user

Name suffix to be used for log files. If omitted, the PID is used.

=item background

Save the standard and error output to files. The files will be created
in the FIG temporary directory and will be named C<err>I<User>C<.log> and
C<out>I<User>C<.log>, respectively, where I<User> is the value of the
B<user> option above.

=item help

Display this command's parameters and options.

=item listFile

If specified, the name of a tab-delimited file containing a list of the
genome IDs for the genomes to load in its first column.

=back

=cut

    # Get the command-line options and parameters.
    my ($options, @parameters) = StandardSetup([qw() ],
                                               {
                                                  trace => ["2", "tracing level"],
                                                  listFile => ["", "if specified, a file containing the IDs of genomes to load"],
                                                  orgDirectory => [$FIG_Config::organisms, "directory containing the genome directories"],
                                                  newOnly => ["", "if specified, directories already in the output area will not be replaced"]
                                               },
                                               "<outDirectory> <genome1> <genome2> ...",
                                               @ARGV);
    # Create the statistics object.
    my $stats = Stats->new();
    # Get the output directory.
    my $outDirectory = shift @parameters;
    if (! $outDirectory) {
        die "No output directory specified.";
    } elsif (! -d $outDirectory) {
        die "Invalid output directory $outDirectory.";
    }
    # This hash will map genome IDs to directories.
    my $genomeHash;
    # Check for a list file.
    my $listFile = $options->{listFile};
    if (-f $listFile) {
        # We have one, so get the genomes from it.
        my $ih = Open(undef, "<$listFile");
        while (! eof $ih) {
            my ($genomeID) = Tracer::GetLine($ih);
            $genomeHash->{$genomeID} = "$options->{orgDirectory}/$genomeID";
            $stats->Add(genomeInListFile => 1);
        }
        close $ih;
        Trace(scalar(keys %$genomeHash) . " genomes read from $listFile.") if T(2);
    } else {
        # No list file, so process the parameters.
        for my $genomeID (@parameters) {
            # Map this genome to the genome directory.
            $genomeHash->{$genomeID} = "$options->{orgDirectory}/$genomeID";
            $stats->Add(genomeById => 1);
        }
    }
    # Loop through the genomes found, converting them from SEED directories
    # to CDMI load directories.
    for my $genomeID (sort keys %$genomeHash) {
        my $genomeDir = "$outDirectory/$genomeID";
        if ($options->{newOnly} && -d $genomeDir && -f "$genomeDir/contigs.fa") {
            Trace("Genome $genomeID skipped: already created.") if T(2);
            $stats->Add(genomeSkipped => 1);
        } else {
            CreateDirectory($genomeID, $genomeHash->{$genomeID},
                "$outDirectory/$genomeID");
        }
    }
    # Output the statistics.
    Trace("Processing complete:\n" . $stats->Show()) if T(1);

 # This method actually creates the CDMI directory from the SEED
 # directory.
 sub CreateDirectory {
    # Get the parameters.
    my ($genomeID, $inDirectory, $outDirectory) = @_;
    # These will be used for file handles.
    my ($ih, $oh);
    # Insure the output directory exists.
    if (! -d $outDirectory) {
        mkdir $outDirectory;
    }
    Trace("Processing $genomeID from $inDirectory.") if T(2);
    # Now we must copy the contig FASTA file. The contig IDs have
    # to have the genome ID put in front.
    Trace("Copying contigs for $genomeID.") if T(3);
    $ih = Open(undef, "<$inDirectory/contigs");
    $oh = Open(undef, ">$outDirectory/contigs.fa");
    while (! eof $ih) {
        my $line = <$ih>;
        if ($line =~ /^>(.+)/) {
            print $oh ">$genomeID:$1\n";
        } else {
            print $oh $line;
        }
    }
    close $ih;
    close $oh;
    # This will hold a map of the deleted features.
    my %deleted;
    # Open the feature output file.
    $oh = Open(undef, ">$outDirectory/features.tab");
    # Loop through the feature types. Each is in a separate directory.
    my @types = grep { $_ =~ /^[a-zA-Z]+$/ } OpenDir("$inDirectory/Features");
    for my $fidType (@types) {
        Trace("Processing $fidType features.") if T(3);
        $stats->Add(featureType => 1);
        # Check for deleted features.
        my $deletedFidFile = "$inDirectory/Features/$fidType/deleted.features";
        if (-f $deletedFidFile) {
            $ih = Open(undef, "<$deletedFidFile");
            while (! eof $ih) {
                my $line = <$ih>;
                chomp $line;
                $deleted{$line} = 1;
                $stats->Add(deletedFid => 1);
            }
            close $ih;
        }
        # Now open the tbl file for these features.
        $ih = Open(undef, "<$inDirectory/Features/$fidType/tbl");
        # Loop through the features in the file.
        while (! eof $ih) {
            my ($fid, $locs) = Tracer::GetLine($ih);
            # Insure the feature is not deleted.
            if ($deleted{$fid}) {
                $stats->Add(deletedInTbl => 1);
            } else {
                # Parse the locations.
                my @locs = split /\s*,\s*/, $locs;
                my $convertedLocs = join(",", map { "$genomeID:" . BasicLocation->new($_)->String() } @locs);
                # Output the feature information.
                print $oh join("\t", $fid, $fidType, $convertedLocs) . "\n";
                $stats->Add(outputFromTbl => 1);
            }
        }
    }
    close $oh;
    close $ih;
    # Check for a protein FASTA file.
    if (-f "$inDirectory/Features/peg/fasta") {
        # We have one. We must copy it to the protein output file,
        # keeping on the lookout for deleted features.
        $ih = Open(undef, "<$inDirectory/Features/peg/fasta");
        $oh = Open(undef, ">$outDirectory/proteins.fa");
        Trace("Copying protein FASTA file.") if T(3);
        # We'll set this to TRUE if we're handling a deleted feature.
        my $deleting = 0;
        # Loop through the input.
        while (! eof $ih) {
            my $line = <$ih>;
            $stats->Add(proteinFastaLineIn => 1);
            if ($line =~ /^>(\S+)/) {
                # Here we have a header line. Check the feature ID.
                if ($deleted{$1}) {
                    # It's deleted. Suppress this section.
                    $deleting = 1;
                    $stats->Add(deletedProtein => 1);
                } else {
                    $deleting = 0;
                    $stats->Add(keepingProtein => 1);
                }
            }
            # Output this line if we're not deleting.
            if (! $deleting) {
                print $oh $line;
                $stats->Add(proteinFastaLineOut => 1);
            } else {
                $stats->Add(proteinFastaLineSkipped => 1);
            }
        }
        close $oh;
        close $ih;
    }
    # Now we need to output the assignments.
    Trace("Copying assignments.") if T(3);
    $ih = Open(undef, "<$inDirectory/assigned_functions");
    $oh = Open(undef, ">$outDirectory/functions.tab");
    while (! eof $ih) {
        # Get this assignment.
        my ($fid, $assignment) = Tracer::GetLine($ih);
        $stats->Add(assignmentLineIn => 1);
        # Is it deleted?
        if ($deleted{$fid}) {
            # Yes. Skip it.
            $stats->Add(assignmentLineSkipped => 1);
        } else {
            # No. Write it out.
            print $oh "$fid\t$assignment\n";
            $stats->Add(assignmentLineOut => 1);
        }
    }
    close $ih;
    close $oh;
    # Write out the genome name.
    my ($genomeName) = Tracer::GetFile("$inDirectory/GENOME");
    $oh = Open(undef, ">$outDirectory/name.tab");
    print $oh "$genomeID\t$genomeName\n";
    close $oh;
    # Finally, we must create the attributes file.
    $oh = Open(undef, ">$outDirectory/attributes.tab");
    Trace("Writing genome attributes.") if T(3);
    if (-f "$inDirectory/COMPLETE") {
        print $oh "COMPLETE\t1\n";
    } else {
        print $oh "COMPLETE\t0\n";
    }
    $stats->Add(attributeLine => 1);
    my ($taxonomy) = Tracer::GetFile("$inDirectory/TAXONOMY");
    print $oh "TAXONOMY\t$taxonomy\n";
    $stats->Add(attributeLine => 1);
    for my $attribute (qw(PROJECT VERSION TAXONOMY_ID GENETIC_CODE)) {
        my $fileName = "$inDirectory/$attribute";
        if (-f $fileName) {
            my ($value) = Tracer::GetFile($fileName);
            print $oh "$attribute\t$value\n";
            $stats->Add(attributeLine => 1);
        } else {
            $stats->Add(attributeNotFound => 1);
        }
    }
    close $oh;
    Trace("Genome completed.") if T(3);
 }