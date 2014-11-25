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
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Bio::KBase::CDMI::GenomeUtils;
use Getopt::Long;
use MD5Computer;
use BasicLocation;
use Digest::MD5;

=head1 CDMI RAST Genome Loader

    CDMILoadGenome [options] jobFile tempDirectory

Load one or more RAST genomes into a KBase Central Data Model Instance. An input file
containing RAST job numbers is read in, and the genomes are converted to exchange files
in a temp directory, after which they are loaded into the CDMI.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus the
following.

=over 4

=item slow

Use individual INSERT commands to load the database instead of spooling into
sequential load files.

=item rastDir

The directory containing the RAST jobs. The default is C</vol/rast-prod/jobs>.

=back

There are two positional parameters-- the RAST job file name, and the name of a directory
in which to build the exchange file sets.  The RAST job file should be tab-delimited, with
the first column containing RAST job numbers. 

=cut

# Create the command-line option variables.
my $slow;
my $rastDir = "/vol/rast-prod/jobs";
# Turn off buffering for progress messages.
$| = 1;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(slow => \$slow, "rastDir=s" => \$rastDir);
if (! $cdmi) {
    print "usage: CDMILoadFromRast [options] jobfile tempDirectory\n";
    exit;
}
# Get the job file and temp directory.
my ($jobFile, $tempDirectory) = @ARGV;
if (! $jobFile) {
    die "No RAST job file specified.";
} elsif (! -f $jobFile) {
	die "RAST job file $jobFile not found.";
} elsif (! $tempDirectory) {
    die "No working directory specified";
} elsif (! -d $tempDirectory) {
    die "Working directory $tempDirectory not found.";
} else {
	# Create the loader utility object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetSource('SEED');
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Open the job file.
    open(my $ih, "<$jobFile") || die "Could not open $jobFile: $!";
    # Loop through the RAST jobs in the file.
    while (! eof $ih) {
    	# Get the job number from the file.
    	my ($jobNum) = $loader->GetLine($ih);
    	$stats->Add(jobLineIn => 1);
    	# Insure it's valid.
    	if (! $jobNum || $jobNum =~ /\D/) {
    		# Here we have a comment line.
    		$stats->Add(jobLineSkipped => 1);
    	} elsif (! -d "$rastDir/$jobNum") {
    		# Here the job does not exist.
    		$stats->Add(jobLineBag => 1);
    		print "Rast job $jobNum not found.\n";
    	} else {
	    	# Compute the job's genome ID.
	    	my $genomeID = $loader->ReadAttribute("$rastDir/$jobNum/GENOME_ID");
	    	if (! $genomeID) {
	    		print "Could not read genome ID for job $jobNum.\n";
	    		$stats->Add(badGenomeID => 1);
	    	} elsif (-f "$rastDir/$jobNum/ERROR") {
	    		print "Genome $genomeID from job $jobNum has errors: skipped.\n";
	    		$stats->Add(badGenomeJob => 1);
	    	} else {
		        # Compute the input and output directories for this genome.
		        my $inDirectory = "$rastDir/$jobNum/rp/$genomeID";
		        my $outDirectory = "$tempDirectory/$genomeID";
	    		# Check the MD5.
                my $md5Object = MD5Computer->new_from_fasta("$inDirectory/contigs");
                my $md5 = $md5Object->genomeMD5();
	    		my ($dup) = $cdmi->GetFlat('Genome', 'Genome(md5) = ?', [$md5], 'id');
	    		if ($dup) {
	    			print "Genome $genomeID from job $jobNum is a duplicate of $dup.\n";
	    			$stats->Add(dupGenome => 1);
	    		} else {
			        # Convert the genome to exchange format.
			        Bio::KBase::CDMI::GenomeUtils::ConvertGenome($stats, $genomeID,
			                $inDirectory, $outDirectory);
			        # Load the genome from the exchange format.
			        Bio::KBase::CDMI::GenomeUtils::LoadGenome($loader, $outDirectory,
			                0, 'SEED', $slow);
	    		}
	    	}
    	}
    }
    # Display the statistics.
    print "All done.\n" . $loader->stats->Show();
}


