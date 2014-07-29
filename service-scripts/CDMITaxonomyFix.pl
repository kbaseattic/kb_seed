=head1 CDMI Taxonomy Repair

    CDMITaxonomyFix [options] taxonDirectory

This script loads NCBI taxonomy information into a Kbase Central Data Model
Instance and/or repairs the taxonomy links to the genomes.

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item compare

All genomes will be examined, and ones where the taxonomic grouping name does not match
the scientific name will be displayed.

=item fix

If C<missing> is specified, only taxonomic groupings that are missing or have changed will be updated.
If C<all> is specified, then all taxonomic groupings will be redone. If C<none> is
specified, none will be redone. The default is C<missing>.

=back

There is a single positional parameter that specifies the directory
containing the NCBI taxonomy files. If it is omitted, the taxonomy files
are not reloaded.

=cut


use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;
use Bio::KBase::CDMI::TaxonomyUtils;
use Bio::KBase::CDMI::GenomeUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $fix = 'missing';
    my $compare;
    # Connect to the database.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("fix=s" => \$fix, compare => \$compare);
    # Get the taxonomy directory.
    my $taxDirectory = $ARGV[0];
    if ($taxDirectory && ! -d $taxDirectory) {
    	die "Invalid taxonomy directory $taxDirectory.";
    }
    # Create a loader object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # If there is a taxonomy directory specified, we must reload the taxonomy
    # tables.
    if ($taxDirectory) {
		# Clear the taxonomy tables.
		my @tables = qw(TaxonomicGrouping IsGroupFor TaxonomicGroupingAlias);
		for my $table (@tables) {
			$cdmi->TruncateTable($table);
			print "$table recreated.\n";
		}
		# Load the taxonomies.
		Bio::KBase::CDMI::TaxonomyUtils::ReadTaxonomies($loader, $taxDirectory);
    }
    # Get the statistics object.
	my $stats = $loader->stats;
	# Loop through the genomes, comparing and assigning taxonomies if necessary. We need to do a left
	# join, so we do SQL.
	my $dbh = $cdmi->{_dbh};
	my $genomes = $dbh->SQL('SELECT Genome.id, Genome.source_id, Genome.scientific_name, IsTaxonomyOf.from_link, Genome.prokaryotic, Genome.domain, IsTaxonomyOf.confidence FROM Genome LEFT JOIN IsTaxonomyOf ON Genome.id = IsTaxonomyOf.to_link',
			0);
	for my $genomeData (@$genomes) {
		my ($id, $source, $name, $oldTaxID, $oldProkFlag, $oldDomain, $oldConf) = @$genomeData;
		$stats->Add(genomeFound => 1);
		# Do a compare, if desired.
		if ($compare) {
			if (! $oldTaxID) {
				$stats->Add('compare-taxMissing' => 1);
				print "$id ($name) is missing a taxonomic group.\n";
			} else {
				my ($oldTaxName) = $cdmi->GetFlat('TaxonomicGrouping', 'TaxonomicGrouping(id) = ?', [$oldTaxID], 'scientific-name');
				my $cleanName = Clean($name);
				my $cleanOldTax = Clean($oldTaxName);
				if (index($cleanName, $cleanOldTax) < 0) {
					$stats->Add('compare-taxSuspicious' => 1);
					print "$id ($source: $name) has suspicious taxonomic group $oldTaxID ($oldTaxName). Confidence = $oldConf.\n";
				} else {
					$stats->Add('compare-taxOK' => 1);
				}
			}
		}
		# Figure out if we need to fix this genome.
		my $fixNeeded = ($fix eq 'all');
		if (! $fixNeeded && $fix ne 'none') {
			if (! $oldTaxID) {
				$fixNeeded = 1;
				$stats->Add(taxIdMissing => 1);
			} elsif (! $oldDomain) {
				$fixNeeded = 1;
				$stats->Add(domainMissing => 1);
			} else {
				$stats->Add(taxonomyFound => 1);
			}
		}
		if ($fixNeeded) {
			my $taxID;
			if ($source =~ /(\d+)\.\d+/) {
				$taxID = $1;
				$stats->Add(taxIDfound => 1);
			}
			my ($conf, $newTaxID) = Bio::KBase::CDMI::TaxonomyUtils::ComputeTaxonomy($cdmi, $id, $name, $taxID);
			if (! defined $conf) {
				# No assignment was made.
				print "No taxonomic group found for $id ($source): $name\n";
				if (! $oldTaxID) {
					$stats->Add(taxonomyNotFound => 1);
				} else {
					$stats->Add(taxonomyNotStrictlyCorrect => 1);
					# Update the domain stuff, if needed.
					if (! $oldDomain) {
						my ($domain, $prokFlag) = Bio::KBase::CDMI::GenomeUtils::ComputeDomain($cdmi, $oldTaxID);
						$cdmi->UpdateEntity(Genome => $id, domain => $domain, prokaryotic => $prokFlag);
						$stats->Add(domainFixed => 1);
					}
				}
			} else {
				if ($oldTaxID && $newTaxID eq $oldTaxID) {
					# The taxonomy was unchanged.
					$stats->Add(taxonomyNotChanged => 1);
					# Update the confidence, if necessary.
					if ($oldConf != $conf) {
						$cdmi->UpdateField('IsTaxonomyOf(confidence)' => $oldConf, $conf, 
								'IsTaxonomyOf(to-link) = ?', [$id]);
						$stats->Add(confidenceChanged => 1);
					}
				} else {
					# New taxonomy. Connect the taxonomy.
					if ($oldTaxID) {
						$cdmi->DeleteRow('IsTaxonomyOf', $oldTaxID, $id);
					}
					$cdmi->InsertObject('IsTaxonomyOf', from_link => $newTaxID, to_link => $id, confidence => $conf);
				}
				# Record the confidence in the statistics.
				if ($conf == 0) {
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
				# Update the domain stuff, if needed.
				my ($domain, $prokFlag) = Bio::KBase::CDMI::GenomeUtils::ComputeDomain($cdmi, $newTaxID);
				if (! $oldDomain || $domain ne $oldDomain) {
					$cdmi->UpdateEntity(Genome => $id, domain => $domain, prokaryotic => $prokFlag);
					$stats->Add(domainFixed => 1);
				}
			}
		}
	}
	print "All done:\n" . $stats->Show();
	
	
	
	# Clean up a string for easier matching.
	sub Clean {
		my ($string) = @_;
		my $retVal = lc $string;
		$retVal =~ s/-//g;
		$retVal =~ s/\W+/ /g;
		return $retVal;
	}
	