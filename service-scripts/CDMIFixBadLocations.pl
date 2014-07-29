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

=head1 Feature Bad Location Repair Utility

    CDMIFixBadLocations [options] inFile

=head2 Introduction

This script searches for features with inconsistent location information in the specified
SEED genomes. The bad location information will be reconstituted from the SEED source.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
the following.

=over 4

=item figdisk

Path to the FIG disk containing the source genome files. This is mostly useful for testing. The
default is the directory specified in L<FIG_Config>.

=back

There is a single positional parameter-- the name of the input file, which must be a tab-delimited
file with genome IDs in the first column. If no input file is specified, the standard input is used.

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Bio::KBase::CDMI::GenomeUtils;
    use Stats;

    $| = 1; # Prevent buffering on STDOUT.
    # This will be the FIG disk location.
    my $figdisk = $FIG_Config::fig_disk;
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script( 'figdisk=s' => \$figdisk);
    if (! $cdmi) {
        print "usage: CDMIFixBadLocations [options] inFile\n";
    } else {
        # Create the loader object.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        # Get the statistics object.
        my $stats = $loader->stats;
	    # Compute the maximum location segment length.
    	my $segmentLength = $cdmi->TuningParameter('maxLocationLength');
    	print "Computed segment length maximum is $segmentLength.\n";
        # Open the input file.
        my $inFile = $ARGV[0] || '-';
        open(my $ih, "<$inFile") || die "Could not open $inFile: $!";
        # Loop through the genomes.
        while (! eof $ih) {
        	my ($gid) = $loader->GetLine($ih);
        	# Compute this genome's source directory.
        	my ($sourceID) = $cdmi->GetFlat('Genome', 'Genome(id) = ?', [$gid], 'source-id');
        	my $sourceDir = "$figdisk/FIG/Data/Organisms/$sourceID";
        	if (! -d $sourceDir) {
        		print "Skipping $gid ($sourceID): not a valid SEED genome.\n";
        		$stats->Add(genomeSkipped => 1);
        	} else {
        		print "Processing $gid ($sourceID).\n";
        		$stats->Add(genomeProcessed => 1);
	        	# Get all of this genome's contigs. The hash maps source IDs (that we get from
	        	# the SEED source files) to KBase contig IDs.
	        	my %contigMap = map { $_->[1] => $_->[0] } $cdmi->GetAll('IsComposedOf Contig',
	        			'IsComposedOf(from-link) = ?', [$gid], 'Contig(id) Contig(source-id)');
	        	# Compute the size of each feature's DNA location in the database.
	        	my (%fidLengths, $fidThing);
	        	my $q = $cdmi->Get('IsLocatedIn', 'IsLocatedIn(from_link) LIKE ?', ["$gid.%"]);
	        	while ($fidThing = $q->Fetch()) {
	        		my ($fid, $len) = $fidThing->Values(['from-link', 'len']);
	        		$fidLengths{$fid} += $len;
	        		$stats->Add(locationChecked => 1);
	        	}
	        	# Get all the data from the feature source files. Note that %fidLengths is keyed
	        	# on kBase IDs, but this will be keyed on SEED IDs.
	        	my %fidLocs;
			    # We must loop through the feature types. Each is in a separate directory.
			    opendir(my $dh, "$sourceDir/Features") || die "Could not open Feature directory in $sourceDir.";
    			my @types = grep { $_ =~ /^[a-zA-Z]+$/ } readdir $dh;
    			closedir $dh;
	        	for my $type (@types) {
	        		# Open the tbl file for these features.
			        open(my $fh, "<$sourceDir/Features/$type/tbl") || die "Error opening $type tbl file: $!";
			        # Loop through the features in the file.
			        while (! eof $fh) {
			            my ($fid, $locstr) = Tracer::GetLine($fh);
		                # Parse the locations. We must prefix the genome ID to each contig ID.
        		        my @locs = map { BasicLocation->new($_) } split m/\s*,\s*/, $locstr;
        		        for my $loc (@locs) {
        		        	$loc->FixContig($sourceID);
        		        }
        		        $fidLocs{$fid} = \@locs;
			        }
	        	}
	        	# Compare the location-based lengths to the actual feature lengths.
	        	$q = $cdmi->Get('Feature', 'Feature(id) LIKE ?', ["$gid.%"]);
	        	while ($fidThing = $q->Fetch()) {
	        		my ($fid, $fidSourceID, $len) = $fidThing->Values(['id', 'source-id', 'sequence-length']);
	        		$stats->Add(featureChecked => 1);
	        		if ($len != $fidLengths{$fid}) {
	        			print "Correcting feature $fid ($fidLengths{$fid} => $len).\n";
	        			$stats->Add(featureCorrected => 1);
	        			# Delete the old location data.
	        			my $count = $cdmi->Disconnect('IsLocatedIn', Feature => $fid);
	        			$stats->Add(locationDeleted => $count);
	        			# Get the replacement data.
	        			my $locs = $fidLocs{$fidSourceID};
	        			# Put it in the database.
	        			Bio::KBase::CDMI::GenomeUtils::CreateLocations($loader, \%contigMap,
	        					$segmentLength, $fid, $locs)
	        		}
	        	}
        	}
        }
        # All done. Print the statistics.
        print "All done:\n" . $stats->Show();
    }
    
