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

=head1 Function Update Utility

    CDMICheckFunctions [options] genome1 genome2 ...

=head2 Introduction

This script reads the SEED data store and looks for changes to the functional assignments in
the CDMI. Only genomes already in the CDMI will be processed. For each such genome specified
on the command line, the functional assignments will be read from the functional assignment
file and then compared against the CDMI assignments. Differences will be listted (or optionally,
repaired).

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
the following.

=over 4

=item orgDir

The SEED organism directory to search for source genomes.

=item repair

If specified, the functions will be updated. Otherwise, the changes will simply be listed.

=item all

If specified, all of the SEED genomes in the CDMI will be checked; otherwise, only
the genomes listed in the command-line will be checked.

=item verbose

If specified, the functional assignment changes will be listed. Otherwise, the statistics
will be shown, but not the detailed changes.

=back

The positional parameters are the kBase IDs of the genomes to check.

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;
    use SeedUtils;

    $| = 1; # Prevent buffering on STDOUT.
    # The command-line options will be stored in here.
    my $orgDir = $FIG_Config::organisms;
	my ($repair, $all, $verbose);    
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(repair => \$repair, all => \$all, "orgDir=s" => \$orgDir,
    		verbose => \$verbose);
    if (! $cdmi) {
        print "usage: CDMICheckFunctions [options] genome1 genome2 ...\n";
    } else {
        # Create the loader object.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        # Get the statistics object.
        my $stats = $loader->stats;
        # These will be used to build the query filter clause and parameter list. We want to get information
        # about each genome we're checking.
        my ($filter, @parms);
        if ($all) {
        	print "Processing all SEED genomes in $orgDir.\n";
        	$filter = 'Submitted(from-link) = ?';
        	push @parms, 'SEED';
        } else {
        	print scalar(@ARGV) . " genomes in command-line parameter list: " . join(", ", @ARGV) . "\n";
        	$filter = 'Genome(id) IN (' . join(', ', map { '?' } @ARGV) . ')';
        	push @parms, @ARGV;
        }
        # Create a hash that maps each genome to its source ID and name.
        my %genomes = map { $_->[0] => [$_->[1], $_->[2]] } $cdmi->GetAll('Submitted Genome', $filter, \@parms,
        		'Genome(id) Genome(source-id) Genome(scientific-name)');
       	print scalar(keys %genomes) . " genomes found to process.\n";
       	# Loop through the genomes.
       	for my $genomeID (sort keys %genomes) {
       		# Get this genome's source ID and name.
       		my ($source, $name) = @{$genomes{$genomeID}};
       		my $genomeDescription = "$genomeID ($source) $name";
       		$stats->Add(genomeIn => 1);
       		# Check for a SEED directory.
       		my $genomeDir = "$orgDir/$source";
       		if (! -d "$genomeDir") {
       			print "No source directory found for $genomeDescription.\n";
       			$stats->Add(genomeNoDirectory => 1);
       		} elsif (! -f "$genomeDir/assigned_functions") {
       			print "No assigned functions file found for $genomeDescription.\n";
       			$stats->Add(genomeNoFunctions => 1);
       		} else {
       			print "Processing $genomeDescription.\n";
       			$stats->Add(genomeProcessed => 1);
       			# Create a hash of the current assignments and a source => kBase ID mapping.
       			print "Reading current assignments.\n";
       			my (%kbFuns, %idMap, %kbidMap);
       			my @featureData = $cdmi->GetAll('Feature', 'Feature(id) LIKE ?', ["$genomeID.%"], 
       					'id function source-id');
       			for my $featureDatum (@featureData) {
       				my ($fid, $function, $source) = @$featureDatum;
       				$kbFuns{$fid} = $function;
       				$idMap{$source} = $fid;
       				$kbidMap{$fid} = $source;
       				$stats->Add(kbFeatureIn => 1);
       			}
       			# We no longer need the query results.
       			undef @featureData;
       			# Create a hash of the assigned functions file.
       			print "Reading functions file.\n";
       			my %seedFuns;
       			open(my $fh, "<$genomeDir/assigned_functions") || 
       					die "Could not open assigned functions file for $genomeDescription: $!";
       			while (! eof $fh) {
       				my ($fid, $function) = $loader->GetLine($fh);
       				$stats->Add(seedLineIn => 1);
       				if (! $function) {
       					$stats->Add(seedFeatureNoFunction => 1);
       				} else {
	       				my $kbFid = $idMap{$fid};
	       				if (! $kbFid) {
	       					$stats->Add(seedFeatureSkipped => 1);
	       				} else {
	       					$seedFuns{$kbFid} = $function;
	       					$stats->Add(seedFeatureStored => 1);
	       				}
       				}
       			}
       			# Loop through the SEED functions, comparing.
       			my ($funs, $updates, $blanks) = (0, 0, 0);
       			for my $fid (keys %seedFuns) {
       				$funs++;
       				if ($seedFuns{$fid} ne $kbFuns{$fid}) {
       					# Here we need an update.
       					my $idThing = "$fid ($kbidMap{$fid})";
       					my $spacer = " " x length($idThing);
       					if ($verbose) {
       						print "Update required for $idThing: $seedFuns{$fid}\n";
       					}
       					if (! $kbFuns{$fid}) {
       						$stats->Add(oldFunctionBlank => 1);
       						$blanks++;
       					} elsif ($verbose) {
       						print "Old function is $spacer    : $kbFuns{$fid}\n";
       					}
       					$updates++;
       					if ($repair) {
       						$loader->UpdateFunction($fid, $seedFuns{$fid});
       						$stats->Add(updatePerformed => 1);
       					} else {
       						$stats->Add(updateRequired => 1);
       					}
       				}
       			}
       			print "$funs functions examined, $blanks blanks fixed, $updates changes.\n";
       		}
       	}
        print "All done:\n" . $stats->Show();
    }
    
