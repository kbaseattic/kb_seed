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
    use CDMILoader;
    use CDMI;

=head1 CDMI Taxonomy Loader

    CDMILoadTaxonomies [options] taxonDirectory

This script loads NCBI taxonomy information into a Kbase Central Data Model
Instance. This is global information that involves deleting and recreating
entire tables. In particular, the following tables will be truncated and
rebuilt.

=over 4

=item TaxonomicGrouping

organism classifications

=item IsGroupFor

relationship that organizes taxonomic groupings into a hierarchy

=back

In addition, genomes connected to taxonomy IDs that have been remapped
will be moved to from the old IDs to the new ones.

The command-line options are those specified in L<CDMI/new_for_script>.
There is a single positional parameter that specifies the directory
containing the NCBI taxonomy files.

=cut

# Connect to the database using the command-line options.
my $cdmi = CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMILoadTaxonomies [options] taxonomyDirectory\n";
} else {
    # Get the directory of taxonomy files.
    my $taxDirectory = $ARGV[0];
    if (! $taxDirectory) {
        die "No taxonomy directory specified.\n";
    } elsif (! -d $taxDirectory) {
        die "Invalid taxonomy directory $taxDirectory.\n";
    } else {
        # Clear the existing taxonomy data.
        my $stats = ClearTaxonomies($cdmi);
        # Read the new taxonomy data.
        my $stats2 = ReadTaxonomies($cdmi, $taxDirectory);
        # Merge in the statistics.
        $stats->Accumulate($stats2);
        # Display the full statistics.
        print "All done:\n" . $stats->Show();
    }
}


=head2 Subroutines

=head3 ClearTaxonomies

    my $stats = ClearTaxonomies($cdmi);

Delete the taxonomy information from the database. This involves removing entire tables,
since the information is global. As a result, the statistics are fairly uninformative.

=over 4

=item cdmi

L<CDMI> object used to access the target database.

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
    my @tables = qw(TaxonomicGrouping IsGroupFor);
    # Loop through the list, truncating the tables.
    for my $table (@tables) {
        $cdmi->TruncateTable($table);
        $retVal->Add(tables => 1);
    }
    # Return the statistics.
    return $retVal;
}

=head3 ReadTaxonomies

    my $stats = ReadTaxonomies($cdmi, $directoryName);

Read the NCBI taxonomy groupings from the specified directory.

=over 4

=item cdmi

L<CDMI> object for accessing the database.

=item directoryName

Name of the directory containing the NCBI taxonomy dump files.

=item RETURN

Returns a L<Stats> object with statistics regarding the load.

=back

=cut

sub ReadTaxonomies {
    # Get the parameters.
    my ($cdmi, $directoryName) = @_;
    # Create the CDMI loader.
    my $loader = CDMILoader->new($cdmi);
    # Get the statistics object.
    my $retVal = $loader->stats;
    # Initialize the relation loaders.
    $loader->SetRelations(qw(TaxonomicGrouping TaxonomicGroupingAlias IsGroupFor));
    # The first step is to read in all the names. We will build a hash that maps
    # each taxonomy ID to a list of its names. The first scientific name encountered
    # will be saved as the primary name. Only scientific names, synonoyms, and
    # equivalent names will be kept.
    my (%nameLists, %primaryNames);
    my $ih;
    open($ih, "<$directoryName/names.dmp") || die "Could not open names file: $!\n";
    while (! eof $ih) {
        # Get the next name.
        my ($taxID, $name, undef, $type) = GetTaxData($ih, $retVal);
        $retVal->Add('taxnames-in' => 1);
        # Is this a scientific name?
        if ($type =~ /scientific/i) {
            # Yes. Save it if it is the first for this ID.
            if (! exists $primaryNames{$taxID}) {
                $primaryNames{$taxID} = $name;
            }
            # Add it to the name list.
            push @{$nameLists{$taxID}}, $name;
            $retVal->Add('taxnames-scientific' => 1);
        } elsif ($type =~ /synonym|equivalent/i) {
            # Here it's not scientific, but it's generally useful, so we keep it.
            push @{$nameLists{$taxID}}, $name;
            $retVal->Add('taxnames-other' => 1);
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
            undef,  undef,   undef, undef, undef, $hidden) = GetTaxData($ih, $retVal);
        # Determine whether or not this is a domain group. A domain group is
        # terminal when doing taxonomy searches. The NCBI indicates a top-level
        # node by making it a child of the root node 1. We also include
        # super-kingdoms (archaea, eukaryota, bacteria), which are below cellular
        # organisms but are still terminal in our book.
        my $domain = ($type eq 'superkingdom') || ($parent == 1);
        # Get the node's name.
        my $name = $primaryNames{$taxID};
        # It's an error if there's no name.
        die "No name found for tax ID $taxID." if ! $name;
        # Create the taxonomy group record.
        $loader->InsertObject('TaxonomicGrouping', id => $taxID, domain => $domain, hidden => $hidden,
               scientific_name => $name);
        # Create the aliases.
        for my $alias (@{$nameLists{$taxID}}) {
            $loader->InsertObject('TaxonomicGroupingAlias', id => $taxID, alias => $alias);
        }
        # Connect the group to its parent.
        $loader->InsertObject('IsGroupFor', from_link => $parent, to_link => $taxID);
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
        my ($oldID, $newID) = GetTaxData($ih, $retVal);
        # Look for genomes connected to the old ID.
        my (@genomes) = $cdmi->GetFlat('IsTaxonomyOf',
                'IsTaxonomyOf(from-link) = ?', [$oldID]);
        # Did we find any?
        if (@genomes) {
            # Yes. Disconnect them.
            $cdmi->Disconnect('IsTaxonomyOf', 'TaxonomyGroup', $oldID);
            # Reconnect them to the new ID.
            for my $genome (@genomes) {
                $cdmi->InsertObject('IsTaxonomyOf', from_link => $newID,
                to_link => $genome);
                $retVal->Add(reconnectGenomes => 1);
            }
        }
    }
    # Return the statistics.
    return $retVal;
}


=head3 GetTaxData

    my @fields = GetTaxData($ih, $stats);

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


1;
