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
	if ($fix) {
	    # Compute the maximum location segment length.
    	$segmentLength = $cdmi->TuningParameter('maxLocationLength');
    	print "Computed segment length maximum is $segmentLength.\n";
	}
	my $genome = 'kb|g.166806';
	print "Processing $genome.\n";
	my $geneCode = $cdmi->GetFlat('Genome', 'Genome(id) = ?', [$genome], 'genetic-code');
	my $geneMap = SeedUtils::genetic_code($geneCode);
	my $fid = 'kb|g.166806.CDS.2630';
	my @locs = $cdmi->GetLocations($fid);
	my ($realProt) = $cdmi->GetFlat('Produces ProteinSequence', 'Produces(from-link) = ?', [$fid], 'ProteinSequence(sequence)');
	my $dna = join("", map { $cdmi->ComputeDNA($_) } @locs);
	my $prot = translate($dna, $geneMap, 1);
	$prot =~ s/\*$//;
	my ($head1, $fixNeeded);
	if ($prot ne $realProt) {
		$head1 = "Mismatch on $fid:";
		$fixNeeded = 1;
	} else {
		$head1 = "Protein for $fid:";
	}
	my $head2 = "should be:";
	$head2 = (" " x (length($head1) - length($head2))) . $head2;
	print "$head1 $prot\n";
	print "$head2 $realProt\n";
	if ($fix && $fixNeeded) {
		my @newLocs = sort { $b->Begin <=> $a->Begin } @locs;
		$dna = join("", map { $cdmi->ComputeDNA($_) } @newLocs);
		$prot = translate($dna, $geneMap, 1);
		$head2 =~ s/should be/ fixed as/;
		print "$head2 $prot\n";
		my $count = $cdmi->Disconnect('IsLocatedIn', Feature => $fid);
		print "Fixing locations: $count deleted.\n";
		Bio::KBase::CDMI::GenomeUtils::CreateLocations($loader, undef, $segmentLength, $fid, \@newLocs);
	}
	print "-\n";
	print "All done.\n";
