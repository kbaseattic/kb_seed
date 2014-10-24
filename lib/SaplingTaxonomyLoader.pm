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

package SaplingTaxonomyLoader;

    use strict;
    use Tracer;
    use Stats;
    use SeedUtils;
    use SAPserver;
    use Sapling;
    use base qw(SaplingDataLoader);

=head1 Sapling Taxonomy Loader

This class loads taxonomy information into the Sapling database. This is global information
that involves deleting and recreating entire tables. In particular, the following tables
will be truncated and rebuilt.

The taxonomy process involves relationships with genomes. Only genomes currently in the
database will be connected to the taxonomy groups and genome sets; after new genomes are
added this process needs to be rerun or the genomes need to be connected manually.

=over 4

=item GenomeSet

OTU sets

=item IsCollectionOf

relationship from GenomeSet to Genome

=item TaxonomicGrouping

organism classifications

=item IsGroupFor

relationship that organizes taxonomic groupings into a hierarchy

=item IsTaxonomyOf

relationship that connects a genome to its parent in the taxonomy tree

=back

=head2 Main Methods

=head3 ClearTaxonomies

    my $stats = SaplingTaxonomyLoader::ClearTaxonomies($sap);

Delete the taxonomy information from the database. This involves removing entire tables,
since the information is global. As a result, the statistics are fairly uninformative.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item RETURN

Returns a L<Stats> object describing the events during the operation.

=back

=cut

sub ClearTaxonomies {
    # Get the parameters.
    my ($sap) = @_;
    # Create the return object.
    my $retVal = Stats->new('tables');
    # Create a list of the tables to clear.
    my @tables = qw(GenomeSet IsCollectionOf TaxonomicGrouping IsGroupFor IsTaxonomyOf);
    # Loop through the list, truncating the tables.
    for my $table (@tables) {
        $sap->TruncateTable($table);
        $retVal->Add(tables => 1);
    }
    # Return the statistics.
    return $retVal;
}

=head3 LoadTaxonomies

    my $stats = SaplingTaxonomyLoader::LoadTaxonomies($sap, $dumpDirectory, $setFile);

Load the taxonomic information from the specified files.

=over 4

=item sap

L<Sapling> object used to access the target database.

=item dumpDirectory

Name of the directory containing the taxonomic dump files from the NCBI.

=item setFile (optional)

Name of the file containing the OTU information. If omitted, the OTU information is not loaded.

=item RETURN

Returns a L<Stats> object describing the events during the operation.

=back

=cut

sub LoadTaxonomies {
    # Get the parameters.
    my ($sap, $dumpDirectory, $setFile) = @_;
    # Create the helper object.
    my $loaderObject = SaplingTaxonomyLoader->new($sap);
    # Load the OTUs.
    if ($setFile) {
    	$loaderObject->ReadGenomeSets($setFile);
    }
    # Load the taxonomy data.
    $loaderObject->ReadTaxonomies($dumpDirectory);
    # Return the statistics.
    return $loaderObject->{stats};
}

=head3 Process

    my $stats = SaplingTaxonomyLoader::Process($sap, $dumpDirectory, $setFile);

Load taxonomy data from the specified directory and OTU set file. If the taxonomy data
already exists, it will be deleted first.

=over 4

=item sap

L</Sapling> object for accessing the database.

=item dumpDirectory

name of the directory containing the taxonomy data.

=item setFile

name of the file describing the OTUs

=item RETURN

Returns a statistics object describing the activity during the reload.

=back

=cut

sub Process {
    # Get the parameters.
    my ($sap, $dumpDirectory, $setFile) = @_;
    # Clear the existing taxonomy data.
    my $stats = ClearTaxonomies($sap);
    # Load the new taxonomy data from the specified directory and OTU file.
    my $newStats = LoadTaxonomies($sap, $dumpDirectory, $setFile);
    # Merge the statistics.
    $stats->Accumulate($newStats);
    # Return the result.
    return $stats;
}


=head2 Loader Object Methods

=head3 new

    my $loaderObject = SaplingTaxonomyLoader->new($sap);

Create a loader object that can be used to facilitate loading taxonomy information.

=over 4

=item sap

L<Sapling> object used to access the target database.

=back

The object created contains the following fields.

=over 4

=item supportRecords

A hash of hashes, used to track the support records known to exist in the database.

=item sap

L<Sapling> object used to access the database.

=item stats

L<Stats> object for tracking statistical information about the load.

=item gHash

Reference to a hash containing the IDs of all the genomes in the database.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $sap) = @_;
    # Create the object.
    my $retVal = SaplingDataLoader::new($class, $sap, qw(groups sets));
    # Create the hash of genome IDs.
    my %gHash = map { $_ => 1 } $sap->GetFlat('Genome', "", [], 'id');
    # Store it in the object.
    $retVal->{gHash} = \%gHash;
    # Return the result.
    return $retVal;
}

=head2 Internal Utility Methods

=head3 ReadGenomeSets

    $loaderObject->ReadGenomeSets($fileName);

Read the OTU data from the specified set file and load it into the database.

=over 4

=item fileName

Name of the file containing the OTU data. The file is tab-delimited, and each record consists of
a genome set number followed by a genome ID. The first genome in each set is the representative
genome.

=back

=cut

sub ReadGenomeSets {
    # Get the parameters.
    my ($self, $fileName) = @_;
    # Get the statistics object.
    my $stats = $self->{stats};
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Get the genome hash.
    my $gHash = $self->{gHash};
    # Open the set file.
    my $ih = Open(undef, "<$fileName");
    # This will be the ID of the current genome set.
    my $currentSet = "";
    # This will be the number of genomes stored in the current set.
    my $storedInSet = 0;
    # Loop through the file records, creating the sets and links.
    while (! eof $ih) {
        # Get this record.
        my ($setID, $genome) = Tracer::GetLine($ih);
        # Is this a new set?
        if ($setID ne $currentSet) {
            # Yes. Create the set record.
            $sap->InsertObject('GenomeSet', id => $setID);
            # Denote no genomes in this set have been stored.
            $storedInSet = 0;
            # Record that we have a new set.
            $stats->Add(sets => 1);
            $currentSet = $setID;
        }
        # Is this a genome we're keeping?
        if (! $gHash->{$genome}) {
            $stats->Add(setGenomeSkipped => 1);
        } else {
            # Yes. If this is the first one for this set, make it the representative.
            my $repFlag = ($storedInSet ? 0 : 1);
            # Connect the genome to the set.
            $sap->InsertObject('IsCollectionOf', from_link => $setID, to_link => $genome,
                               representative => $repFlag);
            # Record that we've stored this genome.
            $stats->Add(genomesInSets => 1);
            $storedInSet++;
        }
    }
}


=head3 ReadTaxonomies

    $loaderObject->ReadTaxonomies($directoryName);

Read the NCBI taxonomy groupings from the specified directory.

=over 4

=item directoryName

Name of the directory containing the NCBI taxonomy dump files.

=back

=cut

sub ReadTaxonomies {
    # Get the parameters.
    my ($self, $directoryName) = @_;
    # Get the statistics object.
    my $stats = $self->{stats};
    # Get the Sapling database.
    my $sap = $self->{sap};
    # Get the hash of genomes in the database.
    my $gHash = $self->{gHash};
    # The first step is to read in all the names. We will build a hash that maps
    # each taxonomy ID to a list of its names. The first scientific name encountered
    # will be saved as the primary name. Only scientific names, synonoyms, and
    # equivalent names will be kept.
    my (%nameLists, %primaryNames);
    my $ih = Open(undef, "<$directoryName/names.dmp");
    while (! eof $ih) {
        # Get the next name.
        my ($taxID, $name, undef, $type) = $self->GetTaxData($ih);
        $stats->Add('taxnames-in' => 1);
        # Is this a scientific name?
        if ($type =~ /scientific/i) {
            # Yes. Save it if it is the first for this ID.
            if (! exists $primaryNames{$taxID}) {
                $primaryNames{$taxID} = $name;
            }
            # Add it to the name list.
            push @{$nameLists{$taxID}}, $name;
            $stats->Add('taxnames-scientific' => 1);
        } elsif ($type =~ /synonym|equivalent/i) {
            # Here it's not scientific, but it's generally useful, so we keep it.
            push @{$nameLists{$taxID}}, $name;
            $stats->Add('taxnames-other' => 1);
        }
    }
    # Now we read in the taxonomy nodes. For each node, we generate a TaxonomicGrouping
    # record, and we connect it to its parent using IsGroupFor. We also keep the node ID
    # for later so we know what's available.
    close $ih;
    $ih = Open(undef, "<$directoryName/nodes.dmp");
    while (! eof $ih) {
        # Get the data for this group.
        my ($taxID, $parent, $type, undef, undef,
            undef,  undef,   undef, undef, undef, $hidden) = $self->GetTaxData($ih);
        # Determine whether or not this is a domain group. A domain group is
        # terminal when doing taxonomy searches. The NCBI indicates a top-level
        # node by making it a child of the root node 1. We also include
        # super-kingdoms (archaea, eukaryota, bacteria), which are below cellular
        # organisms but are still terminal in our book.
        my $domain = ($type eq 'superkingdom') || ($parent == 1);
        # Get the node's name.
        my $name = $primaryNames{$taxID};
        # It's an error if there's no name.
        Confess("No name found for tax ID $taxID.") if ! $name;
        # Create the taxonomy group record.
        $sap->InsertObject('TaxonomicGrouping', id => $taxID, domain => $domain, hidden => $hidden,
                    scientific_name => $name);
        # Create the aliases.
        for my $alias (@{$nameLists{$taxID}}) {
            $sap->InsertValue($taxID, 'TaxonomicGrouping(alias)', $alias);
        }
        # Connect the group to its parent.
        $sap->InsertObject('IsGroupFor', from_link => $parent, to_link => $taxID);
    }
    # Read in the merge file. The merge file tells us which old IDs are mapped to
    # new IDs. We need this to connect genomes with old IDs to the correct group.
    my %merges;
    $ih = Open(undef, "<$directoryName/merged.dmp");
    while (! eof $ih) {
        # Get this merge record.
        my ($oldID, $newID) = $self->GetTaxData($ih);
        # Store it in the hash.
        $merges{$oldID} = $newID;
    }
    # Now we need to connect each genome to its taxonomic grouping.
    # Loop through the genomes.
    for my $genomeID (keys %$gHash) {
        # Get this genome's taxonomic group.
        my ($taxID) = split /\./, $genomeID, 2;
        # Check to see if we have this tax ID. If we don't, we check for a merge.
        if (! $primaryNames{$taxID}) {
            if ($merges{$taxID}) {
                $taxID = $merges{$taxID};
                $stats->Add('merged-names' => 1);
                Trace("$genomeID has alternate taxonomy ID $taxID.") if T(SaplingDataLoader => 2);
            } else {
                $taxID = undef;
                $stats->Add('missing-groups' => 1);
                Trace("$genomeID has no taxonomy group.") if T(SaplingDataLoader => 1);
            }
        }
        # Connect the genome and the group if the group is real.
        if (defined $taxID) {
            $sap->InsertObject('IsTaxonomyOf', from_link => $taxID, to_link => $genomeID);
        }
    }
}


=head3 GetTaxData

    my @fields = $loaderObject->GetTaxData($ih);

Read a taxonomy dump record and return its fields in a list. Taxonomy
dump records end in a tab-bar-newline sequence, and fields are separated
by a tab-bar-tab sequence, a more complex arrangement than is used in
standard tab-delimited files.

=over 4

=item ih

Open input handle for the taxonomy dump file.

=item RETURN

Returns a list of the fields in the record read.

=back

=cut

sub GetTaxData {
    # Get the parameters.
    my ($self, $ih) = @_;
    # Get the statistics object.
    my $stats = $self->{stats};
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


1;