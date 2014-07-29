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
    use SeedUtils;
    use Bio::KBase::CDMI::CDMILoader;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::ExpressionUtils;
    use Bio::KBase::CDMI::GenomeUtils;
    use Bio::KBase::CDMI::FamilyUtils;
    use Bio::KBase::CDMI::TaxonomyUtils;
    use Bio::KBase::CDMI::SubsystemUtils;
    use FIG;
    use File::Path;

=head1 CDMI Incremental Load

    CDMILoadCheck [options] workDirectory

This command checks the PubSEED against the KBase CDMI and updates it with any
major changes. In particular, it compares the genomes, subsystems, expression
data, and FIGfams. It also reloads taxonomic information unconditionally.

The positional parameter is a directory that can be used for generating temporary
data.
 
The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item notaxon

Do not reload taxonomic information.

=item nogenomes

Do not process genome changes.

=item noexpr

Do not process expression data.

=item nofam

Do not process FIGfam data.

=item nosubsys

Do not process subsystem data.

=item blackList

Name of a file containing SEED IDs of genomes not to load. The file should contain
one genome ID per line, tab-delimited.

=item fighost

Alternate database host for the SEED. This is useful for testing.

=item figport

Alternate database access port for the SEED. This is useful for testing.

=item figdisk

Alternate directory for the SEED. This is useful for testing.

=item figdb

Alternate database for the SEED. This is useful for testing.

=back

=cut

# Prevent buffering on the log output.
$| = 1;
# The command-line options are kept in here.
my ($notaxon, $blackList, $fighost, $figport, $figdisk, $nogenome, $noexpr, $nofam,
    $nosubsys, $figdb);
# Connect to the database using the command-line options.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("notaxon" => \$notaxon,
    "nogenome" => \$nogenome, "noexpr" => \$noexpr, "nofam" => \$nofam,
    "nosubsys" => \$nosubsys, "blackList=s" => \$blackList, "fighost=s" => \$fighost,
    "figport=s" => \$figport, "figdisk=s" => \$figdisk, "figdb=s" => \$figdb);
if (! $cdmi) {
    print "usage: CDMILoadCheck [options] workDirectory \n";
} else {
    # Get the SEED data. We may need to update some of the configuration parameters.
    if ($fighost) {
        $FIG_Config::dbhost = $fighost;
    }
    if ($figport) {
        $FIG_Config::dbport = $figport;
    }
    if ($figdisk) {
        $FIG_Config::fig_disk = $figdisk;
        $FIG_Config::global = "$figdisk/FIG/Data/Global";
        $FIG_Config::organisms = "$figdisk/FIG/Data/Organisms";
        $FIG_Config::data = "$figdisk/FIG/Data";
    }
    if ($figdb) {
    	$FIG_Config::db = $figdb;
    }
    my $fig = FIG->new();
    # Create the CDMI loader.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Denote we're loading from the SEED.
    $loader->SetSource('SEED');
    # Get its statistics object.
    my $stats = $loader->stats;
    # Create the blacklist.
    my %blackListH;
    if ($blackList) {
        print "Reading genome blacklist from $blackList.\n";
        my @lines = Bio::KBase::CDMI::GenomeUtils::GetFile($blackList);
        for my $line (@lines) {
            my ($genomeID) = split /\t/, $line, 2;
            $blackListH{$genomeID} = 1;
            $stats->Add('blacklist-genomes' => 1);
        }
        print scalar(keys %blackListH) . " genome IDs read from blacklist file.\n";
    }
    # Get the working directory.
    my $workDir = $ARGV[0];
    if (! $workDir) {
        die "No working directory specified.\n";
    } elsif (! -d $workDir) {
        die "Invalid working directory $workDir.\n";
    } else {
        # We need to clean the working directory now.
        File::Path::remove_tree($workDir, { keep_root => 1});
    }
    if (! $notaxon) {
        # Here we need to reload the taxonomy data and the genome sets.
        print "Reloading taxonomies.\n";
        # Clear the existing taxonomy data.
        Bio::KBase::CDMI::TaxonomyUtils::ClearTaxonomies($cdmi);
        # Read the new taxonomy data.
        Bio::KBase::CDMI::TaxonomyUtils::ReadTaxonomies($loader, "$FIG_Config::global/Taxonomy");
        # Update the genome sets.
        Bio::KBase::CDMI::TaxonomyUtils::LoadGenomeSets($loader, 'SEED', "$FIG_Config::global/genome.sets");
    }
    # Update the genomes.
    if (! $nogenome) {
        UpdateGenomes($loader, $fig, \%blackListH, $workDir);
    }
    # Check for expression data for the new genomes.
    if (! $noexpr) {
        print "Checking expression data.\n";
        my $expDirectory = '/vol/expression/current';
        UpdateExpressionData($loader, $expDirectory);
    }
    # Check for a FIGfam reload.
    if (! $nofam) {
        # First, we must find the latest figfam-prod release directory.
        my @releases = sort { Bio::KBase::CDMI::GenomeUtils::Cmp($a, $b) } grep { $_ =~ /^Release\d+/ }
                Bio::KBase::CDMI::GenomeUtils::OpenDir("/vol/figfam-prod");
        # Find the first valid FIGfam directory.
        my $figFamRel;
        for (my $i = $#releases; $i >= 0 && ! $figFamRel; $i--) {
            my $release = $releases[$i];
            if (-f "/vol/figfam-prod/$release/coupling.values") {
                $figFamRel = $release;
            }
        }
        if (! $figFamRel) {
            die "No FIGfam directory found.";
        } else {
            # We have a FIGfam release directory.
            my $figFamDir = "/vol/figfam-prod/$figFamRel";
            print "FIGfams are currently in $figFamDir.\n";
            # Get the current release from the database.
            my ($release) = $cdmi->GetFlat('Family', 'Family(type) = ?', ['FIGfam'],
                    'release');
            if (! $release || Bio::KBase::CDMI::GenomeUtils::Cmp($figFamRel, $release) < 0) {
                # Here the database has no FIGfams or it is a lower release, so we
                # must reload.
                print "Loading FIGfam release $figFamRel.\n";
                if ($release) {
                    print "Old FIGfam release is $release.\n";
                }
                Bio::KBase::CDMI::FamilyUtils::LoadFamily($loader, 'FIGfam', 
                        $figFamDir, $figFamRel);
            }
        }
    }
    # Finally, we must update the subsystems.
    if (! $nosubsys) {
        # Get the list of subsystems in the SEED. This requires a direct query
        # to the SEED database to get us the version numbers, and we have to 
        # convert the subsystem IDs.
        print "Reading subsystems from SEED.\n";
        my $fig_dbh = $fig->db_handle;
        my %seedSubs = map { Bio::KBase::CDMI::SubsystemUtils::SubsystemID($_->[0]) => $_ }
            @{$fig_dbh->SQL("SELECT `subsystem`, `version` FROM subsystem_metadata")};
        # Get the subsystems and versions from the CDMI.
        print "Reading subsystems from CDMI.\n";
        my %cdmiSubs = map { $_->[0] => $_->[1] } $cdmi->GetAll('Subsystem', "", [],
                'id version');
        # This will hold the new and updated subsystems.
        my %changeSubs;
        # Loop through the SEED subsystems, looking for ones to reload.
        my @seedSubList = sort keys %seedSubs;
        for my $seedSub (@seedSubList) {
            $stats->Add(seedSubsystemsChecked => 1);
            # Get this subsystem's version and directory name.
            my $seedVersion = $seedSubs{$seedSub}[1];
            my $seedDirectory = "$FIG_Config::data/Subsystems/$seedSubs{$seedSub}[0]";
            # Verify that the subsystem is real.
            if (! -d $seedDirectory) {
                print "Subsystem $seedSub is not found in the data directory.\n";
                delete $seedSubs{$seedSub};
            } elsif (Bio::KBase::CDMI::SubsystemUtils::BadSubsys($seedDirectory)) {
                print "Subsysytem $seedSub is invalid: skipped.\n";
                delete $seedSubs{$seedSub};
            } else {
                # It is. See if the subsystem is new or changed.
                my $cdmiVersion = $cdmiSubs{$seedSub};
                if (! defined $cdmiVersion) {
                    $stats->Add(seedSubsystemsNewFound => 1);
                    $changeSubs{$seedSub} = $seedDirectory;
                } elsif ($seedVersion > $cdmiVersion) {
                    $stats->Add(seedSubsystemsChangedFound => 1);
                    $changeSubs{$seedSub} = $seedDirectory;
                    print "Must update $seedSub from $cdmiVersion to $seedVersion.\n";
                }
            }
        }
        # Loop through the CDMI subsystems, looking for ones that were deleted.
        # We will delete these on the spot.
        print "Scanning for deleted subsystems.\n";
        for my $cdmiSub (sort keys %cdmiSubs) {
            $stats->Add(cdmiSubsystemsChecked => 1);
            # Check for this subsystem in the SEED.
            if (! exists $seedSubs{$cdmiSub}) {
                $stats->Add(cdmiSubsystemDeletesFound => 1);
                Bio::KBase::CDMI::SubsystemUtils::DeleteSubsystem($loader, $cdmiSub);
            }
        }
        # Now process the list of changes. Each of these subsystems will be reloaded,
        # and then we must process all of the genomes to redo the bindings. First,
        # the reloading.
        for my $seedSub (sort keys %changeSubs) {
            Bio::KBase::CDMI::SubsystemUtils::LoadSubsystem($loader, 'SEED', 
                    $changeSubs{$seedSub}, 0);
            $stats->Add(seedSubsystemUpdate => 1);
        }
        # Now we need to go through the binding file for each genome, processing the
        # subsystems that have changed. All of these will have had all their
        # spreadsheet data deleted, so we are doing pure insertion. First, we need a
        # list of the genomes to check.
        my @genomes = $cdmi->GetFlat('Submitted Genome', "Submitted(from-link) = ?",
                ['SEED'], 'Genome(source-id)');
        print scalar(@genomes) . "  genomes found from SEED.\n";
        for my $genome (@genomes) {
            # Compute the genome directory.
            my $genomeDirectory = "$FIG_Config::organisms/$genome";
            print "Processing subsystem bindings in $genomeDirectory.\n";
            # Process its bindings.
            Bio::KBase::CDMI::SubsystemUtils::ProcessBindings($loader, $genome,
                    $genomeDirectory, \%changeSubs);
        }
    }
    # Display the statistics.
    print "All done:\n" . $stats->Show();
}

=head3 UpdateGenomes

    my $newGenomesH = UpdateGenomes($loader, $fig, $blackListH, $workDir);

Update the genomes in the CDMI from the SEED. A genome will be added to the CDMI
if it does not match the DNA sequence of a genome already present and if it is
not in the blacklist.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for connecting to the CDMI being loaded.

=item fig

L<FIG> object for connecting to the SEED.

=item blackListH

Reference to a hash of SEED genome IDs for genomes not to be loaded.

=item workDir

Working directory to contain the temporary files.

=item RETURN

Returns a reference to a hash containing the SEED IDs of the new genomes loaded.

=back

=cut

sub UpdateGenomes {
    # Get the parameters.
    my ($loader, $fig, $blackListH, $workDir) = @_;
    # Get the CDMI object for talking to the database.
    my $cdmi = $loader->cdmi;
    # Get the statistics object.
    my $stats = $loader->stats;
    # We want to create a hash mapping the genome IDs to their MD5 sums.
    print "Finding SEED genomes.\n";
    my $seedGenomes = Bio::KBase::CDMI::GenomeUtils::GetSeedGenomeHash($stats,
        $blackListH);
    # Loop through the SEED genomes. OUr goal is to create a list of genomes
    # to be added. For each SEED genome, if its MD5 is not currently in the
    # KBase, we will flag it as a candidate for loading. If two such genomes
    # have the same MD5, the one with the highest SEED genome ID (indicating
    # a later version) is used. To pull this off, we need a work hash that
    # maps MD5 to genome IDs for the candidates.
    print "Checking for new genomes.\n";
    my %foundMap;
    for my $seedGenome (sort keys %$seedGenomes) {
        my $md5 = $seedGenomes->{$seedGenome};
        # Check for this MD5 in the list of found genomes.
        if ($foundMap{$md5}) {
            # We found it. Because we're going through the genomes in ID
            # order, the new one wins.
            $foundMap{$md5} = $seedGenome;
            $stats->Add(dupGenomeInSeed => 1);
        } else {
            # This is a new MD5. Is it in the KBase already?
            my ($kbID) = $cdmi->GetFlat('Genome', 'Genome(md5) = ?', [$md5], 'id');
            if ($kbID) {
                # Yes, skip it.
                $stats->Add(SeedGenomeFoundInKBase => 1);
            } else {
                # No, schedule it for add.
                $stats->Add(newSeedGenomeFound => 1);
                $foundMap{$md5} = $seedGenome;
            }
        }
    }
    # This hash will serve as the return variable.
    my %retVal;
    # Now we loop through the genomes selected, loading them.
    for my $seedGenome (sort values %foundMap) {
    	# Insure this genome has not already been loaded.
    	print "Checking $seedGenome.\n";
    	my ($kbID) = $cdmi->GetFlat('Submitted Genome', 'Submitted(from-link) = ? AND Genome(source-id) = ?',
    			['SEED', $seedGenome], 'Genome(id)');
    	if ($kbID) {
    		$stats->Add(SeedGenomeAlreadyLoaded => 1);
    	} else {
	        # It hasn't. Compute the input and output directories for this genome.
	        my $inDirectory = "$FIG_Config::organisms/$seedGenome";
	        my $outDirectory = "$workDir/$seedGenome";
	        # Convert the genome to exchange format.
	        Bio::KBase::CDMI::GenomeUtils::ConvertGenome($stats, $seedGenome,
	                $inDirectory, $outDirectory);
	        # Load the genome from the exchange format.
	        Bio::KBase::CDMI::GenomeUtils::LoadGenome($loader, $outDirectory,
	                0, 'SEED', 0, 1);
	        # Store its ID in the return hash.
	        $retVal{$seedGenome} = 1;
    	}
    }
    # Return the result.
    return \%retVal;
}

=head3 UpdateExpressionData

    UpdateExpressionData($loader, $expDirectory);

Check all the expression directories and load the ones for KBase genomes
that do not yet have expression data.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for loading the database.

=item expDirectory

Directory containing the expression data. Each genome's data is in a subdirectory
with the same name as a genome ID.

=cut

sub UpdateExpressionData {
    # Get the parameters.
    my ($loader, $expDirectory) = @_;
    # Get the CDMI object and the statistics object.
    my $cdmi = $loader->cdmi;
    my $stats = $loader->stats;
    # Get all the expression directories.
    my @exps = grep { $_ =~ /^\d+\.\d+$/ } Bio::KBase::CDMI::GenomeUtils::OpenDir($expDirectory);
    # Loop through the genomes listed, checking for a KBase presence.
    for my $genomeID (@exps) {
        $stats->Add(expDirectoryChecked => 1);
        my ($kbID) = $cdmi->GetFlat('Genome WasSubmittedBy',
                "Genome(source-id) = ? AND WasSubmittedBy(to-link) = ?",
                [$genomeID, 'SEED'], 'id');
        if (! $kbID) {
            $stats->Add(expGenomeNotInKBase => 1);
        } else {
            $stats->Add(expGenomeInKBase => 1);
            # Check to see if this genome has expression data.
            my ($chipID) = $cdmi->GetFlat('ProducedResultsFor', "ProducedResultsFor(to-link) = ?",
                [$kbID], 'from-link');
            if ($chipID) {
                $stats->Add(expGenomeAlreadyLoaded => 1);
            } else {
                # Here we need to load the expression data.
                print "Expression data for $kbID will be loaded from $expDirectory/$genomeID.\n";
                Bio::KBase::CDMI::ExpressionUtils::LoadExpressionData($loader, "$expDirectory/$genomeID");
                $stats->Add(expGenomeLoaded => 1);
            }
        }
    }
}

1;