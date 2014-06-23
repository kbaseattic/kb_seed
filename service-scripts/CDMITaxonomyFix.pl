### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;
use Bio::KBase::CDMI::TaxonomyUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
	my @genomes = $cdmi->GetAll('Genome', '', [], 'id source-id scientific-name');
	for my $genome (@genomes) {
		my ($id, $sourceID, $name) = @$genome;
		my ($taxID) = $cdmi->GetFlat('IsInTaxa', 'IsInTaxa(from-link) = ?', [$id], 'to-link');
		if (! defined $taxID) {
			if ($sourceID =~ /(\d+)\.\d+/) {
				my $possibleTaxID = $1;
				my ($taxGroup) = $cdmi->GetAll('TaxonomicGrouping', 'TaxonomicGrouping(id) = ?', [$possibleTaxID],
					'scientific-name type');
				if (defined $taxGroup) {
					$cdmi->InsertObject('IsTaxonomyOf', from_link => $possibleTaxID, confidence => 0, to_link => $id);
					my ($taxName, $taxType) = @$taxGroup;
					print "$id ($sourceID) $name :=> $possibleTaxID $taxType $taxName\n";
				}
			}
		}
	}