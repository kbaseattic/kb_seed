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

=head1 EnsemblPlant Genome Conversion Script for CDMI Load

    PlantToCdmiLoadFormat <outDirectory> <inDirectory> ...

=head2 Introduction

This script converts EnsemblPlant exchange files into the genome load
format specified for the Kbase Central Data Model.

EnsemblPlant exchange files are very different from the
orthodox genome load files. First and foremost, rather than having
fixed names in a separate directory for each genome, all the files
are in a single directory and have a genome ID embedded before the file
extension. The file names themselves are also different, with the
protein file called C<translations> and the extension for tab-separated
files being C<tsv> instead of C<tab>. Finally, the C<name> and
C<attribute> files have been replaced by the C<metadata> file, which
has an extension of C<tbl>.

So, for Arabidopsis thaliana, which has an ID of C<Athaliana.TAIR10>,
the file names are C<contigs.Athaliana.TAIR10.fa>, C<translations.Athaliana.TAIR10.fa>,
C<metadata.Athaliana.TAIR10.tbl>, C<features.Athaliana.TAIR10.tsv>,
and C<functions.Athaliana.TAIR10.tsv>.

The processing for each file is as follows:

=over 4

=item contigs.*.fa

The genome ID must be prefixed to the contig ID for each contig.

=item translations.*.fa

The file name must be converted to C<proteins.fa>.

=item metadata.*.tbl

This file contains multi-line records with a double slash (C<//>) as a
record separator. In each record, the first line is a field name and the
remaining lines are field values. The C<species> field will be extracted
and used to create the C<name.tab> file.

=item features.*.tsv

This is a tab-delimited file with five columns-- (0) the feature ID, (1) the
feature type, (2) the parent feature ID, (3) the gene name, and (4) a
comma-delimited list of location strings. If the parent feature ID is a period, then the feature
has no parent. Gene names are known to be non-unique and will not be prefixed;
however, it's worth noting they are ultimately applied to protein sequences.
If the gene name is the same as the feature ID it will be ignored. Finally,
the contig IDs in the location string may need to have C<Chr> prefixed to it
in order to match the contig IDs in the B<contigs.*.fa> file.

=item functions.*.tsv

This is a tab-delimited file with two columns-- (0) the feature ID, and (2) the
functional assignment.

=back

=head2 Positional Parameters

=over 4

=item outDirectory

Name of the directory in which to put the output. The output will be
one directory per genome, containing the four files used to load
genomes into a CDMI.

=item inDirectory

Name of the directory containing the plant genome files.

=back

=cut

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
    for my $file (grep { $_ =~ /^\w+\.(.+)\.(?:fa|tbl|tsv)$/} readdir(TMP)) {
        my ($id) = ($file =~ /\.(.+)\./);
        $genomes{$id} = 1;
    }
    # Loop through the genomes.
    for my $genome (sort keys %genomes) {
        CreateDirectory($stats, $genome, $inDirectory, "$outDirectory/$genome");
    }
    # Output the statistics.
    print "Processing complete:\n" . $stats->Show();

 # This method actually creates the CDMI directory from the Plant
 # files.
 sub CreateDirectory {
    # Get the parameters.
    my ($stats, $genomeID, $inDirectory, $outDirectory) = @_;
    # Insure the output directory exists.
    if (! -d $outDirectory) {
        mkdir $outDirectory;
    }
    print "Processing $genomeID from $inDirectory.\n";
    # First, construct the contigs file.
    my ($oh, $ih);
    print "Translating contig file.\n";
    open($ih, "<$inDirectory/contigs.$genomeID.fa") || die "Could not open $genomeID contigs file: $!\n";
    open($oh, ">$outDirectory/contigs.fa") || die "Could not create $genomeID contigs output file: $!\n";
    while (! eof $ih) {
        my $line = <$ih>;
        $stats->Add(contigLineIn => 1);
        if (substr($line,0,1) eq '>') {
            $line = ">" . substr($line,1);
            $stats->Add(contigLineFixed => 1);
        }
        print $oh $line;
        $stats->Add(contigLineOut => 1);
    }
    # Close the files and free the file handles.
    close $oh; undef $oh;
    close $ih; undef $ih;
    # Now we must process the functions file.
    print "Translating functions file.\n";
    open($ih, "<$inDirectory/functions.$genomeID.tsv") || die "Could not open $genomeID functions file: $!\n";
    open($oh, ">$outDirectory/functions.tab") || die "Could not create $genomeID functions output file: $!\n";
    while (! eof $ih) {
        my $line = <$ih>;
        print $oh "$line";
        $stats->Add(functionLineProcessed => 1);
    }
    # Close the files and free the file handles.
    close $oh; undef $oh;
    close $ih; undef $ih;
    # Next comes the features file. This requires the most changes.
    # We have to fix the contig IDs in the locations and move the parent
    # and gene IDs to the end columns. We also need to keep track of the CDS
    # for each mRNA, because the mRNA's protein really belongs to the CDS.
    # A hash will map mRNA IDs to CDS IDs.
    my %mRnaHash;
    print "Translating features file.\n";
    open($ih, "<$inDirectory/features.$genomeID.tsv") || die "Could not open $genomeID features file: $!\n";
    open($oh, ">$outDirectory/features.tab") || die "Could not create $genomeID features output file: $!\n";
    while (! eof $ih) {
        my ($fid, $type, $parent, $name, $location) = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
        $stats->Add(featureLineIn => 1);
        # Delete the parent ID if it's a period. Otherwise, fix it.
        if ($parent eq '.') {
            $parent = "";
            $stats->Add(parentAbsent => 1);
        } else {
            $stats->Add(parentFound => 1);
        }
        # If this is a CDS, add it to the mRNA map.
        if ($type eq 'CDS' && $parent) {
            $mRnaHash{$parent} = $fid;
            $stats->Add(mRnaParentFound => 1);
        }
        # Split up the location.
        my @locs = split /\s*,\s*/, $location;
        # This remembers the previous contig ID for the location.
        my $prevContig = "";
        # The translated location strings will go in here.
        my @oLocs;
        for my $loc (@locs) {
            # Separate out the contig ID.
            if ($loc =~ /^(.+)(_\d+[+\-]\d+)$/) {
                my $contig = $1;
                my $suffix = $2;
                # Sometimes a second contig ID will be missing the "Chr"
                # prefix from the first one. We must fix this.
                if ("Chr$contig" eq $prevContig) {
                    $contig = $prevContig;
                    $stats->Add(locationContigFix => 1);
                } else {
                    $prevContig = $contig;
                }
                push @oLocs, "$contig$suffix";
                $stats->Add(locationFixed => 1);
            } else {
                print "Invalid location for feature $fid: $loc.\n";
                $stats->Add(badLocation => 1);
            }
        }
        # Is this location on the minus strand?
        if ($oLocs[0] =~ /\d+\-\d+/) {
            # Yes. The pieces were given to us in reverse order, so we
            # have to reverse the list.
            @oLocs = reverse @oLocs;
        }
        # Re-assemble the location.
        $location = join(",", @oLocs);
        # Output the fixed line.
        print $oh "$fid\t$type\t$location\t$parent\t$name\n";
        $stats->Add(featureLineOut => 1);
    }
    # Close the files and free the file handles.
    close $oh; undef $oh;
    close $ih; undef $ih;
    # Now we need to copy the Protein FASTA file. In addition, the name is
    # changing.
    print "Translating protein file.\n";
    open($ih, "<$inDirectory/translations.$genomeID.fa") || die "Could not open $genomeID translations file: $!\n";
    open($oh, ">$outDirectory/proteins.fa") || die "Could not create $genomeID proteins output file: $!\n";
    while (! eof $ih) {
        my $line = <$ih>;
        $stats->Add(protLineIn => 1);
        if ($line =~ /^>(\S+)(.*)/) {
            # Here we have a header line. Save the residual part of the line.
            my $fid = $1;
            my $suffix = $2;
            # Check to see if this is an mRNA. If it is, we map it to the
            # CDS.
            if ($mRnaHash{$fid}) {
                $fid = $mRnaHash{$fid};
                $stats->Add(mRnaProteinMapped => 1);
            }
            $line = ">$fid$suffix\n";
            $stats->Add(protLineFixed => 1);
        }
        print $oh $line;
        $stats->Add(protLineOut => 1);
    }
    # Close the files and free the file handles.
    close $oh; undef $oh;
    close $ih; undef $ih;
    # Finally, we have to copy the metadata file.
    print "Processing metadata file.\n";
    open($oh, ">$outDirectory/metadata.tbl") || die "Could not create $genomeID metadata output file: $!\n";
    open($ih, "<$inDirectory/metadata.$genomeID.tbl") || die "Could not open $genomeID metadata input file: $!\n";
    while (! eof $ih) {
        my $line = <$ih>;
        $stats->Add(metadataIn => 1);
        print $oh $line;
        $stats->Add(metadataOut => 1);
    }
    # Close the files and free the file handles.
    close $oh; undef $oh;
    close $ih; undef $ih;
 }
