### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;
use Bio::KBase::CDMI::TaxonomyUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $taxDirectory = $ARGV[0];
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Update the DBD.
    $cdmi->InternalizeDBD();
    print "Database definition stored in the CDMI.\n";
	# Clear the taxonomy tables.
	my @tables = qw(TaxonomicGrouping IsGroupFor TaxonomicGroupingAlias IsTaxonomyOf);
	for my $table (@tables) {
		$cdmi->DropRelation($table);
		$cdmi->CreateTable($table, 1, 1500000);
		print "$table recreated.\n";
	}
	# Load the taxonomies.
	Bio::KBase::CDMI::TaxonomyUtils::ReadTaxonomies($loader, $taxDirectory);
	my $stats = $loader->stats;
	# Loop through the genomes, assigning taxonomies.
	my @genomes = $cdmi->GetAll("Genome", '', [], 'id source-id scientific-name');
	for my $genomeData (@genomes) {
		my ($id, $source, $name) = @$genomeData;
		$stats->Add(genomeFound => 1);
		my $taxID;
		if ($source =~ /(\d+)\.\d+/) {
			$taxID = $1;
			$stats->Add(taxIDfound => 1);
		}
		my $conf = Bio::KBase::CDMI::TaxonomyUtils::AssignTaxonomy($cdmi, $id, $name, $taxID);
		if (! defined $conf) {
			$stats->Add(taxonomyNotFound => 1);
			print "No taxonomic group found for $id ($source): $name\n";
		} elsif ($conf == 0) {
			$stats->Add(taxonomyGuessed => 1);
		} elsif ($conf == 2) {
			$stats->Add(taxonomyAlias => 1);
		} elsif ($conf == 3) {
			$stats->Add(taxonomyNumbered => 1);
		} elsif ($conf == 4) {
			$stats->Add(taxonomyNumberedWithAlias => 1);
		} elsif ($conf == 5) {
			$stats->Add(taxonomyExactName => 1);
		}
	}
	print "All done:\n" . $stats->Show();