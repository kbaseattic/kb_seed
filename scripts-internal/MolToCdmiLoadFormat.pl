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
use File::Copy;
use BasicLocation;
use Bio::KBase::CDMI::CDMILoader;

=head1 MOL Genome Conversion Script for CDMI Load

    MolToCdmiLoadFormat <outDirectory> <inDirectory>

=head2 Introduction

This script converts Microbes Online exchange files into the genome load
format specified for the Kbase Central Data Model.

Microbes Online exchange files are only slightly different from the
orthodox genome load files. First and foremost, rather than having
fixed names in a separate directory for each genome, all the files
have the genome number embedded before the file extension. So, for
Infectious pancreatic necrosis virus (MOL genome 11002), the file
names are C<contigs.11002.fa>, C<functions.11002.tab>,
C<features.11002.tab>, C<proteins.11002.tab>, and C<name.11002.tab>.
In addition, the features file is different. The feature types are
in text form and must be translated to the standard codes and the
location strings consist of a start location, two periods, a stop
location, one period and a strand. In addition, the columns are
(0) contig ID, (1) feature ID, (2) feature type, (3) location string.
Finally, the name file must be converted to a metadata file.
This script will create subdirectories to contain the correctly-named
load files and will perform the format translation for the feature file.

=head2 Command-Line Options

=head2 Positional Parameters

=over 4

=item outDirectory

Name of the directory in which to put the output. The output will be
one directory per genome, containing the four files used to load
genomes into a CDMI.

=item inDirectory

Name of the directory containing the microbes online files.

=back

=cut

    # Turn off buffering for progress messages.
    $| = 1;
    # Create the statistics object.
    my $stats = Stats->new();
    # Get the directories.
    my ($outDirectory, $inDirectory) = @ARGV;
    if (! $outDirectory) {
        die "No output directory specified.";
    } elsif (! -d $outDirectory) {
        die "Invalid output directory $outDirectory.";
    } elsif (! $inDirectory) {
        die "No input directory specified.";
    } elsif (! -d $inDirectory) {
        die "Invalid input directory $inDirectory.";
    }
    # Get a list of all the input files and extract the genome IDs.
    my %genomes;
    opendir(TMP, $inDirectory) || die "Could not open $inDirectory.\n";
    for my $file (grep { $_ =~ /^\w+\.(\d+)\.(?:fa|tab)$/} readdir(TMP)) {
        my ($id) = ($file =~ /(\d+)/);
        $genomes{$id} = 1;
    }
    # Loop through the genomes.
    for my $genome (sort keys %genomes) {
        CreateDirectory($stats, $genome, $inDirectory, "$outDirectory/$genome");
    }
    # Output the statistics.
    print "Processing complete:\n" . $stats->Show();

 # This method actually creates the CDMI directory from the MOL
 # files.
 sub CreateDirectory {
    # Get the parameters.
    my ($stats, $genomeID, $inDirectory, $outDirectory) = @_;
    # Insure the output directory exists.
    if (! -d $outDirectory) {
        mkdir $outDirectory;
    }
    $stats->Add(genomes => 1);
    print "Processing $genomeID from $inDirectory.\n";
    # Copy the basic files.
    print "Copying files for $genomeID.\n";
    copy("$inDirectory/contigs.$genomeID.fa", "$outDirectory/contigs.fa");
    copy("$inDirectory/functions.$genomeID.tab", "$outDirectory/functions.tab");
    copy("$inDirectory/proteins.$genomeID.fa", "$outDirectory/proteins.fa");
    print "Processing features for $genomeID.\n";
    # Now we must process the features.
    open(my $ih, "<$inDirectory/features.$genomeID.tab") || die "Could not open features input file for $genomeID: $!\n";
    open(my $oh, ">$outDirectory/features.tab") || die "Could not open feature output file for $genomeID: $!\n";
    # Loop through the feature file.
    while (! eof $ih) {
        # Get the current feature record.
        my ($contigID, $fid, $type, $location) = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
        $stats->Add(featuresIn => 1);
        # Convert the type.
        my $realType;
        my $lcType = lc $type;
        if ($lcType =~ /protein/) {
            $realType = 'CDS';
        } elsif ($lcType =~ /crispr\s+spacer/) {
            $realType = 'crs';
        } elsif ($lcType =~ /crispr/) {
            $realType = 'crispr';
        } elsif ($lcType =~ /rna/) {
            $realType = 'rna';
        } elsif ($lcType =~ /pseudo/) {
            $realType = 'pseudo';
        } else {
            $stats->Add(unknownType => 1);
            print STDERR "Unknown feature type $realType found in $genomeID.\n";
            $realType = 'unk'
        }
        # Convert the location.
        unless ($location =~ /^(\d+)[.]+(\d+)[.]+(.)/) {
            print STDERR "Invalid location string for feature $fid in $genomeID.\n";
            $stats->Add(badLocation => 1);
        } else {
            # Get the pieces of the location string.
            my ($left, $right, $dir) = ($1, $2, $3);
            # Insure the left and right are correct.
            if ($left > $right) {
                my $temp = $left;
                $left = $right;
                $right = $left;
                $stats->Add(switchedLocation => 1);
            }
            # Compute the length.
            my $len = $right + 1 - $left;
            # Compute the start location.
            my $start = ($dir eq '+' ? $left : $right);
            # Form the location string.
            my $locString = $contigID . "_" . "$start$dir$len";
            # Output the feature.
            print $oh join("\t", $fid, $realType, $locString) . "\n";
            $stats->Add(featuresOut => 1);
        }
    }
    close $oh; undef $oh;
    close $ih; undef $ih;
    # Now we create the metadata file.
    print "Creating metadata file.\n";
    open($ih, "<$inDirectory/name.$genomeID.tab") || die "Could not open name file for $genomeID: $!\n";
    open($oh, ">$outDirectory/metadata.tbl") || die "Could not create metadata file for $genomeID: $!\n";
    my ($id, $name) = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
    print $oh "name\n";
    print $oh "$name\n";
    print $oh "//\n";
    close $oh;
    close $ih;
    print "Genome completed.\n";
 }