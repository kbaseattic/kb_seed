=head1 CDMI Taxonomy Repair

    CDMITaxonomyGenomes [options] taxonomyName outputFileName

This script writes a list of the genomes found in the taxonomy group with the given name
or ID number. The output is in the form of a tab-delimited file with the genome IDs in the
first column.

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.
There are two positional parameters: the name or ID number of a taxonomic grouping, and
the name of the output file.

=cut


use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;
use Bio::KBase::CDMI::TaxonomyUtils;
use Bio::KBase::CDMI::GenomeUtils;

    $| = 1; # Prevent buffering on STDOUT.
    # Connect to the database.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    # Get the parameters.
	my ($taxName, $outFileName) = @ARGV;
    # Check the output mode. If there is no output file, we write to the standard output and suppress all
    # tracing.
    my ($tracing, $oh);
    if ($outFileName) {
    	# Output file, so we trace.
    	$tracing = 1;
    	open $oh, ">$outFileName" || die "Could not open $outFileName: $!";
    } else {
    	# No output file, open standard output.
    	open $oh, ">-";
    }
    # Determine the nature of the input.
	if (! $taxName) {
		die "usage: CDMITaxonomyGenomes [options] taxonomyName outputFileName";
	}
	my ($groupID, $name, $flag);
	if ($taxName =~ /^\d+$/) {
		# Here we have a taxonomy ID.
		my ($taxInfo) = $cdmi->GetFlat('TaxonomicGrouping', 'TaxonomicGrouping(id) = ?', [$taxName], 'scientific-name domain');
		if ($taxInfo) {
			$groupID = $taxName;
			($name, $flag) = @$taxInfo;
			Trace("Root taxonomic grouping is $groupID ($name).\n");
		} else {
			die "No taxonomic grouping found with ID $taxName.";
		}
	} else {
		# Here we have a group name or alias.
		my ($taxInfo) = $cdmi->GetAll('TaxonomicGrouping', 'TaxonomicGrouping(alias) = ?', [$taxName], 'id scientific-name domain');
		if ($taxInfo) {
			($groupID, $name, $flag) = @$taxInfo;
			Trace("Root taxonomic grouping is $groupID ($name).\n");
		} else {
			die "No taxonomic grouping found with name $taxName.";
		}
	}
	# Determine the domain.
	my $domain;
	my ($newGroup, $newName, $newFlag) = ($groupID, $name, $flag);
	while (! $newFlag) {
		my ($parentData) = $cdmi->GetAll('IsInGroup TaxonomicGrouping', 'IsInGroup(from-link) = ?', [$newGroup],
				'TaxonomicGrouping(id) TaxonomicGrouping(scientific-name) TaxonomicGrouping(domain)');
		if (! $parentData) {
			die "Could not find domain for $groupID. Error going up from $newGroup.";
		} else {
			($newGroup, $newName, $newFlag) = @$parentData;
		}
	}
	$domain = $newName;
	Trace("Looking for genomes of domain $domain.\n");
	# Now we loop through the genomes, looking for the group in the taxonomy tree.
	my @genomes = $cdmi->GetAll('Genome', 'Genome(domain) = ?', [$newName], 'id scientific-name source-id');
	Trace(scalar(@genomes) . " genomes found in domain.\n");
	for my $genome (@genomes) {
		my ($id, $name, $sourceID) = @$genome;
		# Get the taxonomy.
		my @taxonomy = $cdmi->Taxonomy($id, 'numbers');
		# Look for our group ID.
		my @group = grep { $_ == $groupID } @taxonomy;
		if (@group) {
			print $oh join("\t", $id, $name, $sourceID) . "\n";
		}
	}
	Trace("All done.\n");
	
# Print the output if tracing is on.
sub Trace {
	my ($message) = @_;
	if ($tracing) {
		print $message;
	}
}