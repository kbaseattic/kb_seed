package Bio::KBase::CDMI::TaxonomyUtils;
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

=head1 CDMI Taxonomy Load Utilities

These are subroutines used to reload taxonomy-related data. Included are
methods for handling the NCBI taxonomy information and the genome sets from
SEED.

=head3 VerifyHidden

    my $stats = Bio::KBase::CDMI::TaxonomyUtils::VerifyHidden($cdmi, $directoryName, $fix);

Verify the hidden-group bits in the specified directory against the database.
Errors will be output to the standard output.

=over 4

=item cdmi

L<Bio::KBase::CDMI::CDMI> object used to access the target database.

=item directoryName

Name of the directory containing the NCBI taxonomy dump files.

=item fix

If TRUE, then incorrect hidden bits will be corrected in place.

=item RETURN

Returns a L<Stats> object describing the events during the operation.

=back

=cut

sub VerifyHidden {
    # Get the parameters.
    my ($cdmi, $directoryName, $fix) = @_;
    # Declare the return variable.
    my $retVal = Stats->new();
    # Open the nodes.dmp file.
    open(my $ih, "<$directoryName/nodes.dmp") || die "Could not open nodes file: $!\n";
    while (! eof $ih) {
        # Get the data for this group.
        my ($taxID, undef, $type, undef, undef,
            undef,  undef, undef, undef, undef, $hidden) = GetTaxData($ih, $retVal);
        # Check for the group in the database.
        my ($name, $hidden_db) = $cdmi->GetEntityValues(TaxonomicGrouping => $taxID,
                [qw(scientific-name hidden)]);
        if (! $name) {
            # It wasn't found. This is ok.
            $retVal->Add(taxNew => 1);
        } else {
            # It was found. Normalize the two booleans.
            $hidden = ($hidden ? 1 : 0);
            $hidden_db = ($hidden_db ? 1 : 0);
            # Now compare them.
            if ($hidden == $hidden_db) {
                # Here they match.
                $retVal->Add(taxMatch => 1);
            } else {
                print "Mismatch in group $taxID: $name ($type). $hidden in file, $hidden_db in CDMI.\n";
                $retVal->Add(taxMismatch => 1);
                # Are we fixing?
                if ($fix) {
                    # Yes. Update the database.
                    $cdmi->UpdateEntity(TaxonomicGrouping => $taxID, hidden => $hidden);
                    $retVal->Add(taxUpdate => 1);
                }
            }
        }
    }
    # Return the statistics.
    return $retVal;
}

=head3 ClearTaxonomies

    my $stats = Bio::KBase::CDMI::TaxonomyUtils::ClearTaxonomies($cdmi);

Delete the taxonomy information from the database. This involves removing entire tables,
since the information is global. As a result, the statistics are fairly uninformative.

=over 4

=item cdmi

L<Bio::KBase::CDMI::CDMI> object used to access the target database.

=item RETURN

Returns a L<Stats> object describing the events during the operation.

=back

=cut

sub ClearTaxonomies {
    # Get the parameters.
    my ($cdmi) = @_;
    # Create the return object.
    my $retVal = Stats->new('tables');
    # Create a list of the tables to clear.
    my @tables = qw(TaxonomicGrouping IsGroupFor TaxonomicGroupingAlias);
    # Loop through the list, truncating the tables.
    for my $table (@tables) {
        $cdmi->TruncateTable($table);
        $retVal->Add(tables => 1);
    }
    # Return the statistics.
    return $retVal;
}

=head3 ReadTaxonomies

    Bio::KBase::CDMI::TaxonomyUtils::ReadTaxonomies($cdmi, $directoryName);

Read the NCBI taxonomy groupings from the specified directory.

=over 4

=item cdmi

L<Bio::KBase::CDMI::CDMI> object for accessing the database.

=item directoryName

Name of the directory containing the NCBI taxonomy dump files.

=back

=cut

sub ReadTaxonomies {
    # Get the parameters.
    my ($loader, $directoryName) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the CDMI object.
    my $cdmi = $loader->cdmi;
    # Initialize the relation loaders.
    $loader->SetRelations(qw(TaxonomicGrouping TaxonomicGroupingAlias IsGroupFor));
    # The first step is to read in all the names. We will build a hash that maps
    # each name to a taxonomy ID. The first scientific name encountered
    # for an ID will be saved as the primary name. Only certain name classes are used. Note that
    # one scientific name will be assigned to each taxonomy ID, and only one taxonomy ID
    # (the last) to each name.
    my %classes = ('synonym' => 1, 'equivalent name' => 1, 'common name' => 1, 'misspelling' => 1);
    my (%nameTable, %primaryNames);
    my $ih;
    my %nameHash;
    open($ih, "<$directoryName/names.dmp") || die "Could not open names file: $!\n";
    while (! eof $ih) {
        # Get the next name.
        my ($taxID, $name, $unique, $type) = GetTaxData($ih, $stats);
        # Fix environmental samples.
        if ($name eq 'environmental samples' && $unique) {
        	$name = $unique;
        }
        $stats->Add('taxnames-in' => 1);
        # Is this a scientific name?
        if ($type eq 'scientific name') {
            # Yes. Save it if it is the first for this ID.
            if (! exists $primaryNames{$taxID}) {
                $primaryNames{$taxID} = $name;
	            $stats->Add('taxnames-scientific' => 1);
            }
            # Store it in the names table.
            $nameTable{$name} = $taxID;
        } elsif ($classes{$type}) {
            # Here it's not scientific, but it's generally useful, so we keep it.
            $nameTable{$name} = $taxID;
            $stats->Add('taxnames-other' => 1);
        }
    }
    # Now we read in the taxonomy nodes. For each node, we generate a TaxonomicGrouping
    # record, and we connect it to its parent using IsGroupFor. We also keep the node ID
    # for later so we know what's available.
    close $ih;
    undef $ih;
    open($ih, "<$directoryName/nodes.dmp") || die "Could not open nodes file: $!\n";
    while (! eof $ih) {
        # Get the data for this group.
        my ($taxID, $parent, $type, undef, undef,
            undef,  undef,   undef, undef, undef, $hidden) = GetTaxData($ih, $stats);
        # Determine whether or not this is a domain group. A domain group is
        # terminal when doing taxonomy searches. The NCBI indicates a top-level
        # node by making it a child of the root node 1. We also include
        # super-kingdoms (archaea, eukaryota, bacteria), which are below cellular
        # organisms but are still terminal in our book.
        my $domain = ((($type eq 'superkingdom') || ($parent == 1)) ? 1 : 0);
        # Get the node's name.
        my $name = $primaryNames{$taxID};
        # It's an error if there's no name.
        die "No name found for tax ID $taxID." if ! $name;
        # Create the taxonomy group record.
        $loader->InsertObject('TaxonomicGrouping', id => $taxID, domain => $domain, hidden => $hidden,
               scientific_name => $name, type => $type);
        # Connect the group to its parent. Note the special check to avoid creating the loop at the
        # top in the NCBI data, where the root is the parent of itself.
        if ($parent ne $taxID) {
        	$loader->InsertObject('IsGroupFor', from_link => $parent, to_link => $taxID);
        }
    }
    # Create the aliases.
    for my $alias (keys %nameTable) {
    	my $taxID = $nameTable{$alias};
        $loader->InsertObject('TaxonomicGroupingAlias', id => $taxID, alias => $alias);
    }
    # Unspool the relation loaders.
    $loader->LoadRelations();

    # Read in the merge file. The merge file tells us which old IDs are mapped to
    # new IDs. We use this to reconnect genomes whose taxonomy IDs have changed.
    my %merges;
    undef $ih;
    open($ih, "<$directoryName/merged.dmp") || die "Could not open merge file: $!\n";
    while (! eof $ih) {
        # Get this merge record.
        my ($oldID, $newID) = GetTaxData($ih, $stats);
        # Look for genomes connected to the old ID.
        my (@genomes) = $cdmi->GetAll('IsTaxonomyOf',
                'IsTaxonomyOf(from_link) = ?', [$oldID], 'to-link confidence');
        # Did we find any?
        if (@genomes) {
            # Yes. Disconnect them.
            $cdmi->Disconnect('IsTaxonomyOf', 'TaxonomicGrouping', $oldID);
            # Reconnect them to the new ID.
            for my $genomeInfo (@genomes) {
            	my ($genome, $conf) = @$genomeInfo;
                $cdmi->InsertObject('IsTaxonomyOf', from_link => $newID,
                to_link => $genome, confidence => $conf);
                $stats->Add(reconnectGenomes => 1);
            }
        }
    }
}

=head3 ComputeTaxonomy

	my ($conf, $newTaxID) = Bio::KBase::CDMI::TaxonomyUtils::ComputeTaxonomy($cdmi, $kbID, $name, $taxID);

Compute a taxonomy ID for the specified genome. The genome's name and an optional taxonomy ID are
specified. If the taxonomy ID is specified, it is used automatically. Otherwise, an attempt is made
to match the name to one of the taxonomic aliases.

=over 4

=item cdmi

L<Bio::KBase::CMDI::CDMI> object for accessing the database.

=item kbID

ID of the target genome.

=item name

Name of the target genome.

=item taxID (optional)

Taxonomic ID of the target genome.

=item RETURN

Returns a two-element list containing the confidence level of the assignment made
(or C<undef> if no assignment was made), and the new taxonomy ID.

=back

=cut

sub ComputeTaxonomy {
	# Get the parameters.
	my ($cdmi, $kbID, $name, $taxID) = @_;
	# We will store the confidence here.
	my $conf;
	# This will contain the new taxonomy ID.
	my $assignedTaxID;
	# Start by checking for an exact match in the alias table.
	my ($taxon) = $cdmi->GetAll('TaxonomicGrouping', 'TaxonomicGrouping(alias) = ?', [$name], 
			'id type scientific-name');
	if ($taxon) {
		# Get the information about this match.
		my ($newTaxID, $type, $foundName) = @$taxon;
		# Determine our confidence in the match.
		if ($foundName eq $name) {
			$assignedTaxID = $newTaxID;
			$conf = 5;
		} elsif (defined $taxID && $taxID eq $newTaxID) {
			$assignedTaxID = $newTaxID;
			$conf = 4;
		} else {
			$assignedTaxID = $newTaxID;
			$conf = 2;
		}
	} else {
		if (defined $taxID) {
			# Here the name does not match, but we have a taxonomy ID. Verify that it is real.
			my ($taxon) = $cdmi->GetAll('TaxonomicGrouping', 'TaxonomicGrouping(id) = ?', [$taxID],
				'type scientific-name');
			if ($taxon) {
				# Here it's real. Verify that the assigned taxonomy ID is a leaf.
				my ($child) = $cdmi->GetFlat('IsGroupFor', 'IsGroupFor(from-link) = ?', [$taxID], 'to-link');
				if (! $child) {
					# It is. Go for it.
					$assignedTaxID = $taxID;
					$conf = 3;
				}
			}
		}
		# Check to see if we have an assignment.
		if (! defined $conf) {
			# No. We have to guess.
			my @words = split /\s+/, $name;
			# Try looking for a substring match.
			while (! defined $conf && scalar(@words) >= 2) {
				my $guessName = join(" ", @words);
				my ($newTaxID) = $cdmi->GetFlat('TaxonomicGrouping', 'TaxonomicGrouping(alias) = ?', [$guessName],
					'id');
				if ($newTaxID) {
					# Match found. Keep it.
					$assignedTaxID = $newTaxID;
					$conf = 0;
				} else {
					# No match, so shorten the string.
					pop @words;
				}
			}
		}	
	}
	# Return the confidence and the assignment.
	return ($conf, $assignedTaxID);
}


=head3 GetTaxData

    my @fields = Bio::KBase::CDMI::TaxonomyUtils::GetTaxData($ih, $stats);

Read a taxonomy dump record and return its fields in a list. Taxonomy
dump records end in a tab-bar-newline sequence, and fields are separated
by a tab-bar-tab sequence, a more complex arrangement than is used in
standard tab-delimited files.

=over 4

=item ih

Open input handle for the taxonomy dump file.

=item stats

L<Stats> object for recording statistics about the read process.

=item RETURN

Returns a list of the fields in the record read.

=back

=cut

sub GetTaxData {
    # Get the parameters.
    my ($ih, $stats) = @_;
    # Temporarily change the end-of-record character.
    local $/ = "\t|\n";
    # Read the next record.
    my $line = <$ih>;
    $stats->Add(taxDumpRecords => 1);
    # Chop off the end, if any.
    if ($line =~ /(.+)\t\|\n$/) {
        $line = $1;
    }
    # Split the line into fields.
    my @retVal = split /\t\|\t/, $line;
    $stats->Add(taxDumpFields => scalar(@retVal));
    # Return the result.
    return @retVal;
}

=head3 LoadGenomeSets

    Bio::KBase::CDMI::TaxonomyUtils::LoadGenomeSets($loader, $setFile);

Load the genome sets into the KBase from the specified genome set file.
The genome sets link OTUs to KBase genomes.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for loading the KBase. Statistics
from the load will be rolled up into the internal statistics object.

=item source

Source database from which the genome IDs were taken.

=item setFile

Name of the file containing the OTU information. The file is tab-delimited,
and each record contains an OTU set number, a genome ID, and a genome
name.

=back

=cut

sub LoadGenomeSets {
    # Get the parameters.
    my ($loader, $source, $setFile) = @_;
    # Get the statistics object inside the loader.
    my $stats = $loader->stats;
    # Get the CDMI object inside the loader.
    my $cdmi = $loader->cdmi;
    # Verify the genome set file.
    if (! $setFile) {
        die "No genome set file specified.\n";
    } elsif (! -f $setFile) {
        die "Invalid genome set file $setFile.\n";
    } else {
        # Clear the existing OTU data.
        my @tables = qw(OTU IsCollectionOf);
        for my $table (@tables) {
            print "Recreating $table.\n";
            $cdmi->CreateTable($table, 1);
        }
        # Open the genome set file.
        open(my $ih, "<$setFile") || die "Could not open genome set file: $!\n";
        # This will map each genome found to its set. We collect all the
        # information into a hash first and then unspool it at the end.
        my %genomes;
        # This will contain the representative genome ID for each set.
        my %sets;
        print "Reading set file.\n";
        # Loop through the input file.
        while (! eof $ih) {
            # Get the next set line.
            my ($setID, $genomeID, $name) = $loader->GetLine($ih);
            $stats->Add(setLineIn => 1);
            # Try to find the genome in the database.
            my ($genomeData) = $cdmi->GetAll("Submitted Genome",
                'Submitted(from_link) = ? AND Genome(source_id) = ?',
                [$source, $genomeID], 'Genome(id) Genome(md5)');
            # Only proceed if we found it.
            if (defined $genomeData) {
                $stats->Add(genomeFound => 1);
                my ($kbGenomeID, $genomeMD5) = @$genomeData;
                # Check to see if we need to add this as the set's
                # representative genome.
                if (! exists $sets{$setID}) {
                    # It's the first one found, so we do.
                    $sets{$setID} = $kbGenomeID;
                }
                # Now get all the genomes that are sequence-identical
                # to this one and put them in the OTU.
                my @matchingGenomes = $cdmi->GetFlat("Genome",
                        'Genome(md5) = ?', [$genomeMD5], 'id');
                for my $matchingGenome (@matchingGenomes) {
                    $genomes{$matchingGenome} = $setID;
                    $stats->Add(genomeInSet => 1);
                }
            }
        }
        # Initialize the relation loaders.
        $loader->SetRelations(@tables);
        # Create the OTU records.
        print "Creating OTUs.\n";
        for my $setID (sort keys %sets) {
            $loader->InsertObject('OTU', id => $setID);
            $stats->Add('OTU-out' => 1)
        }
        # Relate each OTU to its genomes.
        print "Connecting genomes.\n";
        for my $genomeID (sort keys %genomes) {
            # Get the set ID for this genome.
            my $setID = $genomes{$genomeID};
            # Determine whether or not this is the representative.
            my $rep = ($genomeID eq $sets{$setID} ? 1 : 0);
            # Forge the relationship.
            $loader->InsertObject('IsCollectionOf', from_link => $setID,
                    representative => $rep, to_link => $genomeID);
            $stats->Add('IsCollectionOf-out' => 1);
        }
        # Unspool the loaders.
        print "Loading relations.\n";
        $loader->LoadRelations();
    }
}

1;

