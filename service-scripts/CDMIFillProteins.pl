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

=head1 Missing Protein Replacement

    CDMIFillProteins [options] plantDir seedDir

=head2 Introduction

This script searches for missing proteins in the CDMI. The protein is reconstructed from the source
information if possible, and the DNA otherwise.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>. The positional
parameters are the name of a directory containing genome exchange files and the name of a SEED organism
directory.

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;
    use SeedUtils;
    use Digest::MD5;

    $| = 1; # Prevent buffering on STDOUT.
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    if (! $cdmi) {
        print "usage: CDMIFillProteins [options] plantDir seedDir\n";
    } else {
        # Create the loader object.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        # Get the SQL handle.
        my $dbh = $cdmi->{_dbh};
        # Get the statistics object.
        my $stats = $loader->stats;
        # Get the directories.
        my ($plantDir, $seedDir) = @ARGV;
        if (! $plantDir) {
        	die "Missing genome and SEED directories.";
        } elsif (! $seedDir) {
        	die "Missing SEED directory.";
        } elsif (! -d $plantDir) {
        	die "Invalid genome directory $plantDir.";
        } elsif (! -d $seedDir) {
        	die "Invalid SEED directory $seedDir."; 
        }
        # Loop through the genomes.
        my @genomes = $cdmi->GetAll('Genome', "", [], 'id source-id scientific-name');
        for my $gData (@genomes) {
        	my ($gid, $gSource, $gName) = @$gData;
        	$stats->Add(genomes => 1);
        	print "Checking $gid ($gSource) $gName.\n";
        	# Look for missing proteins.
        	my $feats = $dbh->SQL('SELECT IsProteinFor.to_link, Feature.source_id, IsProteinFor.from_link FROM Feature, IsProteinFor LEFT JOIN ProteinSequence ON IsProteinFor.from_link = ProteinSequence.id WHERE Feature.id LIKE ? AND Feature.feature_type = ? AND Feature.id = IsProteinFor.to_link AND ProteinSequence.id IS NULL',
        			0, "$gid.%", "CDS");
        	my %badFeats = map { $_->[1] => [$_->[0], $_->[2]] } @$feats;
        	if (! @$feats) {
        		$stats->Add(goodGenome => 1);
        	} else {
        		# We have missing proteins.
        		my $badFeatCount = scalar(@$feats);
        		print "$badFeatCount bad features found.\n";
        		$stats->Add(badFeatures => $badFeatCount);
        		# Look for proteins in the exchange files.
        		my $ok = FindExchangeProteins($loader, \%badFeats, $plantDir, $gSource);
        		if (! $ok) {
        			# None found, look in the SEED directory.
        			my $ok = FindSeedProteins($loader, \%badFeats, $seedDir, $gSource);
        			if (! $ok) {
	        			# Still nothing. Compute the proteins.
	        			ComputeProteins($loader, \%badFeats, $gid);
        			}
        		}
        	}
        }
		print "All done:\n" . $stats->Show();    
   	}
   	
# Read the proteins from a CDMI Genome Exchange directory.
sub FindExchangeProteins {
	my ($loader, $badFeats, $plantDir, $gSource) = @_;
	my $retVal = FindFastaProteins($loader, $badFeats, "$plantDir/$gSource/proteins.fa", 'exchangeGenome');
	return $retVal;
}

# Read the proteins from a SEED organism directory.
sub FindSeedProteins {
	my ($loader, $badFeats, $seedDir, $gSource) = @_;
	my $retVal = FindFastaProteins($loader, $badFeats, "$seedDir/$gSource/Features/peg/fasta", 'seedGenome');
	return $retVal;
}

# Read the proteins from a FASTA file.
sub FindFastaProteins {
	my ($loader, $badFeats, $fileName, $genomeType) = @_;
	my $retVal = 0;
	# Check for the FASTA file.
	if (-f $fileName) {
		# We found it.
		my $stats = $loader->stats;
		# Denote we're processing this FASTA file.
		$retVal = 1;
		$stats->Add($genomeType => 1);
		print "Refreshing proteins from $fileName.\n";
		# We'll accumulate the protein ID and sequence in here.
		my ($fid, @seq) = ("");
		# Open the FASTA file.
		open(my $ih, "<$fileName") || die "Could not open $fileName: $!";
		# Loop through the records.
		while (! eof $ih) {
			my $line = <$ih>;
			$stats->Add(fastaLineIn => 1);
			if ($line =~ /^>(\S+)/) {
				# Here we have a new protein starting.
				my $newFid = $1;
				ProcessFastaProtein($loader, $fid, join("", @seq), $badFeats->{$fid});
				# Set up for the next protein.
				$fid = $newFid;
				@seq = ();
			} else {
				# Here we are accumulating the sequence of the old protein.
				chomp $line;
				push @seq, $line;
			}
		}
		# If there is a residual protein, process it.
		ProcessFastaProtein($loader, $fid, join("", @seq), $badFeats->{$fid});
	}
	# Return the success indicator.
	return $retVal;
}

# Compute proteins from DNA sequences.
sub ComputeProteins {
	my ($loader, $badFeats, $genome) = @_;
	print "Refreshing proteins from DNA sequences for $genome.\n";
	my $stats = $loader->stats;
	my $cdmi = $loader->cdmi;
	# Get the genome's translation map.
	my $geneCode = $cdmi->GetFlat('Genome', 'Genome(id) = ?', [$genome], 'genetic-code');
	my $geneMap = SeedUtils::genetic_code($geneCode);
	# Loop through the problem features.
	for my $fid (keys %$badFeats) {
		# Get the ID data for this feature.
		my ($kbfid, $actualProtID) = @{$badFeats->{$fid}};
		$stats->Add(computeFeature => 1);
		# Get the DNA for this feature.
		my @locs = $cdmi->GetLocations($kbfid);
		my $dna = join("", map { $cdmi->ComputeDNA($_) } @locs);
		# Compute the protein.
		my $prot = translate($dna, $geneMap, 1);
		$prot =~ s/\*$//;
		# Compute the protein ID.
		my $protID = Digest::MD5::md5_hex($prot);
		if ($protID ne $actualProtID) {
			print "DNA translation did not work for $kbfid.\n";
			$stats->Add(badDNA => 1);
		} else {
			# The protein ID is correct, so add the protein.
			$loader->CheckProtein($prot);
			$stats->Add(proteinGenerated => 1);
		}
	}
}

# Store a protein in the database.
sub ProcessFastaProtein {
	my ($loader, $fid, $protSequence, $fData) = @_;
	# Get the loader sub-objects.
	my $cdmi = $loader->cdmi;
	my $stats = $loader->stats;
	# Check to see if we have a protein that needs replacement.
	if (! $protSequence) {
		# No protein was specified.
		$stats->Add(nullProteinSkipped => 1);
	} elsif (! defined $fData) {
		# Protein's feature was not listed as missing a protein.
		$stats->Add(goodProteinSkipped => 1);
	} else {
		# Strip off the stop codon.
		$protSequence =~ s/\*$//;
		# Get the ID data for this feature.
		my ($kbfid, $actualProtID) = @$fData;
		$stats->Add(fastaProtein => 1);
		# Compute the ID of the supplied protein sequence.
		my $protID = Digest::MD5::md5_hex($protSequence);
		# Verify that it matches.
		if ($protID ne $actualProtID) {
			print "FASTA translation did not match for $kbfid.\n";
			$stats->Add(badFASTA => 1);
		} else {
			# The protein ID is correct, so add the protein.
			$loader->CheckProtein($protSequence);
			$stats->Add(proteinStored => 1);
		}
	}
}

