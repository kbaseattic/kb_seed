#!/usr/bin/perl -w

    use strict;
    use Tracer;
	use Bio::KBase::CDMI::CDMI;
	use Bio::KBase::CDMI::CDMILoader;
	use Bio::KBase::CDMI::GenomeUtils;
	use SeedUtils;
	
	my ($fix, $file, $segmentLength);
	my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(fix => \$fix, 'file=s' => \$file);
	my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
	my $stats = $loader->stats;
	if ($fix) {
	    # Compute the maximum location segment length.
    	$segmentLength = $cdmi->TuningParameter('maxLocationLength');
    	print "Computed segment length maximum is $segmentLength.\n";
	}
	my @genomes;
	if ($file) {
		open(my $ih, "<$file") || die "Could not open input file $file.\n";
		while (! eof $ih) {
			my ($genome) = $loader->GetLine($ih);
			push @genomes, $genome;
		}
	} else {
		@genomes = @ARGV;
	}
	for my $genome (@genomes) {
		$stats->Add(genomes => 1);
		print "Processing $genome.\n";
		my @fids = $cdmi->GetFlat('Feature', 'Feature(id) LIKE ?', ["$genome.%"], 'id');
		for my $fid (@fids) {
			$stats->Add(features => 1);
			my @locs = $cdmi->GetLocations($fid);
			if (scalar(@locs) > 1 && $locs[1]->Dir eq '-') {
				$stats->Add(strandFeatures => 1);
				if ($locs[1]->Begin > $locs[0]->Begin) {
					$stats->Add(badFeatures => 1);
					if ($fix) {
						my @newLocs = sort { $b->Begin <=> $a->Begin } @locs;
						my $count = $cdmi->Disconnect('IsLocatedIn', Feature => $fid);
						print "Fixing locations for $fid: $count deleted.\n";
						$stats->Add(fixFeatures => 1);
						$stats->Add(fixLocations => $count);
						Bio::KBase::CDMI::GenomeUtils::CreateLocations($loader, undef, $segmentLength, $fid, \@newLocs);
					}
				}
			}
		}
	}
	print "All done.\n" . $stats->Show();
