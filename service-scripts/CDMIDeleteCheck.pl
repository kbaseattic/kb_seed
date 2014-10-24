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

=head1 CDMI Duplicate Genome Check

    CDMIDeleteCheck [options] candidateList

This command looks at the genomes in the KBase CDMI and lists duplicates for deletion.
A genome is considered a duplicate if it is an MD5 match for another genomes. Its
deletability is then computed based on the number of ancillary structures attached to
it. This includes models, expression data, and strain data.

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.
The single positional parameter is the name of an output file. The output file will contain
the genome ID, the number of duplicates, the number of connections, the scientific name, and
the source id.

=cut

# Prevent buffering on the log output.
$| = 1;
# Connect to the database using the command-line options.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
my $outFile = $ARGV[0];
if (! $cdmi || ! $outFile) {
    print "usage: CDMIDeleteCheck [options] outFile \n";
} else {
	# Open the output file.
	open my $oh, ">$outFile" || die "Could not open output file: $!";
	my $stats = Stats->new();
	# Get all the genomes.
	my @genomes = $cdmi->GetAll('Genome IsInTaxa TaxonomicGrouping', 'ORDER BY Genome(md5)', [], 'id scientific-name TaxonomicGrouping(scientific-name) source-id TaxonomicGrouping(id) md5');
	# This will track the old MD5.
	my $oldMD5 = "";
	# This will be a list of the genome records for the genomes in the current MD5 group. For each
	# genome, we have the id, the scientific name, the taxonomic name, and the source ID.
	my @dups;
	for my $genomeData (@genomes) {
		# Get this genome's information.
		my ($genomeID, $name, $taxName, $source, $taxSource, $md5) = @$genomeData;
		$stats->Add(genomeIn => 1);
		# Is it a new MD5?
		if ($md5 ne $oldMD5) {
			# Yes. Process the old group.
			if (scalar(@dups) > 1) {
				ProcessGroup($cdmi, $stats, $oh, \@dups);
			}
			# Set up for the new group.
			@dups = ();
			$oldMD5 = $md5;
		}
		# Add this genome to this group.
		push @dups, [$genomeID, $name, $taxName, $source, $taxSource];
	}
	# Process any residual group.
	if (scalar(@dups) > 1) {
		ProcessGroup($cdmi, $stats, $oh, \@dups);
	}
    # Display the statistics.
    print "All done:\n" . $stats->Show();
}

# Process a genome group to identify candidates for deletion.
sub ProcessGroup {
	my ($cdmi, $stats, $oh, $dups) = @_;
	# Compute the number of duplicates.
	my $size = scalar(@$dups);
	$stats->Add("group-$size" => 1);
	# Loop through the genomes, computing the number of connections.
	for my $genomeData (@$dups) {
		# Get the genome ID.
		my ($genomeID, $name, $taxName, $source, $taxSource) = @$genomeData;
		my $connections = 0;
		for my $rel (qw(GenomeParentOf IsConfiguredBy IsModeledBy HasAssociationDataset)) {
			my $targets = $cdmi->GetCount($rel, "$rel(from-link) = ?", [$genomeID]);
			if ($targets) {
				$stats->Add("$rel-found" => 1);
				$stats->Add("$rel-targets" => $targets);
				$connections++;
			}
		}
		# Write this genome's data record.
		print $oh "$genomeID\t$connections\t$size\t$name\t$taxName\t$source\t$taxSource\n";
		$stats->Add(genomeOut => 1);
	}
	# Signal the end of the group.
	print $oh "\n";
}