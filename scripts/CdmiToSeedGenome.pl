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
use BasicLocation;
use Bio::KBase::CDMI::CDMILoader;
use Stats;

=head1 CDMI Genome to SEED Genome Directory Converter

    CdmiToSeedGenome [options] source inDirectory outGenomeID outDirectory

Convert a CDMI genome directory in the exchange format to a SEED
genome directory. A description of the exchange format can be found
at L<CDMILoadGenome.pl>.

=head2 Command-Line Options and Parameters

There are four positional parameters-- the source database name (e.g. C<EnsemblPlant>,
C<MOL>, ...), the name of the directory containing the CDMI genome data,
the SEED ID to assign to the genome, and the name of the output directory.

=cut

# Turn off buffering for progress messages.
$| = 1;
if ($ENV{LC_ALL} ne 'C') {
    die "You must set LC_ALL=C in your environment to run this program.\n";
}
# Get the parameters.
my ($source, $inDirectory, $genomeID, $outDirectory) = @ARGV;
if (! $source) {
    print "usage: CdmiToSeedGenome source inDirectory genomeID outDirectory\n";
    exit;
}
# Create the statistics object.
my $stats = Stats->new();
if (! $source) {
    die "No source database specified.\n";
} elsif (! $inDirectory) {
    die "No input directory specified.\n";
} elsif (! -d $inDirectory) {
    die "Input directory $inDirectory not found.\n";
} elsif (! $genomeID) {
    die "No output genome ID specified.\n";
} elsif ($genomeID !~ /^\d+\.\d+$/) {
    die "Invalid genome ID specified.\n";
} elsif (! $outDirectory) {
    die "No output directory specified.\n";
} elsif (! -d $outDirectory) {
    die "Output directory $outDirectory not found.\n";
} else {
    # These will be the main IO handles.
    my ($ih, $oh);
    # Create the statistics object.
    print "Genome from $source in $inDirectory will be translated into $outDirectory with ID $genomeID.\n";
    # Copy the contig file.
    open($ih, "<$inDirectory/contigs.fa") || die "Could not open input contigs.fa: $!\n";
    open($oh, ">$outDirectory/contigs") || die "Could not open output contigs: $!\n";
    while (! eof $ih) {
        my $line = <$ih>;
        $stats->Add(contigLineIn => 1);
        if ($line =~ /^>(\S+)/) {
            print "Copying contig $1.\n";
            $stats->Add(contigsRead => 1);
        }
        print $oh $line;
        $stats->Add(contigLineOut => 1);
    }
    # Close the files.
    close $ih; undef $ih;
    close $oh; undef $oh;
    # Read the metadata.
    print "Processing metadata.\n";
    my $metaHash = Bio::KBase::CDMI::CDMILoader::ParseMetadata("$inDirectory/metadata.tbl");
    my $keyCount = (scalar keys %$metaHash);
    print "$keyCount metadata keys found.\n";
    # Check for the complete flag. Note the default is 1.
    my $complete = 1;
    if (defined $metaHash->{complete}) {
        $complete = $metaHash->{complete};
    }
    if ($complete) {
        open($oh, ">$outDirectory/COMPLETE") || die "Could not open COMPLETE marker file: $!\n";
        print $oh "1\n";
        $stats->Add(markerFile => 1);
        close $oh; undef $oh;
    }
    # Check for the genetic code.
    if (defined $metaHash->{genetic_code}) {
        open($oh, ">$outDirectory/GENETIC_CODE") || die "Could not open GENETIC_CODE marker file: $!\n";
        print $oh "$metaHash->{genetic_code}\n";
        $stats->Add(markerFile => 1);
        close $oh; undef $oh;
    }
    # The name is required.
    open($oh, ">$outDirectory/GENOME") || die "Could not open GENOME marker file: $!\n";
    print $oh "$metaHash->{name}\n";
    $stats->Add(markerFile => 1);
    close $oh; undef $oh;
    # Now we need to process the features. First we read the main features
    # file and sort it ino feature clusters using the parenting relation.
    # Unfortunately, there's no way to sort the file in order to group the
    # features together by the parenting relation, so we have to read in
    # the whole thing. First, we open the file.
    print "Processing features.\n";
    open($ih, "<$inDirectory/features.tab") || die "Could not open features file: $!\n";
    # This hash will map each feature to its group ID. The parent relationship
    # is used to roll features into groups.
    my %groups;
    # The next available group ID is kept in here.
    my $groupID = 1;
    # This hash will contain a sub-hash for each feature type that maps the source
    # id to a list containing the location string followed by the aliases. A type of
    # CDS is converted to "peg".
    my %features;
    # This hash lists every group containing a peg.
    my %pegged;
    # Loop through the feature file.
    while (! eof $ih) {
        # Get the next feature record.
        my ($sourceID, $type, $loc, $parentID, undef, @aliases) = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
        # Denote we have not yet figured out this feature's group.
        my $group;
        # Insure the parent is valid, and if it is, get its group.
        if ($parentID) {
            $group = $groups{$parentID};
            if (! defined $group) {
                print "Parent $parentID not found for feature $sourceID.\n";
                $stats->Add(invalidParent => 1);
            }
        }
        # Assign a group to this feature.
        if (! $group) {
            $group = $groupID++;
            $stats->Add(groups => 1);
        }
        $groups{$sourceID} = $group;
        # Convert the type.
        if ($type eq 'CDS') {
            $type = 'peg';
            $pegged{$group} = 1;
        }
        # Store this feature in the feature hash.
        $features{$type}{$sourceID} = [$loc, @aliases];
        $stats->Add(featuresIn => 1);
    }
    ## TODO organize the groups. We need to assign a FIG ID to each group. If the
    ## group contains a peg, all other features are eliminated, but we accept a
    ## function from any one and merge the aliases.
    ## TODO create assigned_functions
    ## TODO for each type: create fasta and tbl

}