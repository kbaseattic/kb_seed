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
use Bio::KBase::CDMI::GenomeUtils;
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
        	Trace("Processing $genomeID.") if T(2);
        	eval {
	        	Bio::KBase::CDMI::GenomeUtils::ConvertGenome($stats, $genomeID, $genomeHash->{$genomeID},
	                "$outDirectory/$genomeID");
        	};
        	if ($@) {
        		Trace("Error processing $genomeID: $@") if T(1);
        		$stats->Add(badGenomes => 1);
        	}
        }
    }
    # Output the statistics.
    Trace("Processing complete:\n" . $stats->Show()) if T(1);

