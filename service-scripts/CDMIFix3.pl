### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $stats = Stats->new();
    print "Reading genomes.\n";
    my %genomes = map { $_ => 1 } $cdmi->GetFlat('Genome', '', [], 'id');
    print "Finding bad links.\n";
    my %badGenomes;
    my $q = $cdmi->Get('IsLocatedIn', '', []);
    while (my $row = $q->Fetch()) {
    	my ($from, $to) = $row->Values(['from-link', 'to-link']);
    	$stats->Add(links => 1);
    	$to =~ /^(kb\|g\.\d+)/;
    	my $gto = $1;
    	if (! $genomes{$gto}) {
    		$badGenomes{$gto}++;
    		$stats->Add(badGenomeLink => 1);
    	}
    }
    print "Deleting bad genomes.\n";
    for my $badgenome (keys %badGenomes) {
    	my $count = $cdmi->DeleteLike('IsLocatedIn', 'IsLocatedIn(to-link) LIKE ?', ["$badgenome.%"]);
    	print "$count records deleted for $badgenome.\n";
    	$stats->Add(genomeDeletes => 1);
    	$stats->Add(linkDeletes => $count);
    }
	print "All done.\n" . $stats->Show();