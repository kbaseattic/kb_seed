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
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;

=head1 CDMI Genome Verification Script

    CDMIVerifyGenomes [options] source genome1 genome2 ... genomeN

This script runs through the identified genomes for the specified source and 
verifies that their source IDs match what is in the ID server. The genomes, 
contigs, and features are all verified. 

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
the following.

=over 4

=item all

If specified, all genomes for the specified source will be examined.

=item verbose

If specified, the ID mappings for each genome will be displayed in the 
standard output.

=back

The positional parameters are the source database name (e.g. C<MOL>, C<SEED>)
followed by a list of source genome IDs. If the C<all> option is specified,
the list of genome IDs is ignored.

=cut

# Connect to the database.
my ($all, $verbose);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(all => \$all, 
        verbose => \$verbose);
if (! $cdmi) {
    print "usage: CDMIVerifyGenomes [options] source genome1 genome2 ... genomeN\n";
} else {
    # Get the positional parameters.
    my ($source, @genomes) = @ARGV;
    if (! $source) {
        die "No source database specified.\n";
    } else {
        # Initialize a loader helper.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        $loader->SetSource($source);
        # If we're in "all" mode, get a list of the desired genomes.
        if ($all) {
            # Issue a warning if the user specified genomes on the command
            # line in "all" mode.
            if (@genomes) {
                print "WARNING: genome IDs on command line ignored.\n";
            }
            print "Looking up genomes for $source.\n";
            @genomes = $cdmi->GetFlat('Submitted Genome', 'Submitted(from-link) = ?',
                    [$source], 'Genome(source-id)');
            print scalar(@genomes) . " genome IDs found.\n";
        }
        # Loop through the genomes, processing them one at a time.
        for my $genome (@genomes) {
            VerifyGenome($loader, $genome, $verbose);
        }
        print "All done:\n" . $loader->stats->Show();
    }
}

=head2 Subroutines

=head3 VerifyGenome

    VerifyGenome($loader, $genome);

Verify the IDs for the specified genome.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object keyed to the current database source
and connected to the desired CDMI.

=item genome

Source ID of the genome to verify.

=item verbose

TRUE if a map of IDs is to be output, else FALSE.

=back

=cut

sub VerifyGenome {
    # Get the parameters.
    my ($loader, $genome, $verbose) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the CDMI database object.
    my $cdmi = $loader->cdmi;
    # Key the load helper to this genome.
    $loader->SetGenome($genome);
    # Find the KBase ID for this genome using the ID server.
    my $idHash = $loader->FindKBaseIDs(Genome => [$genome]);
    my $genomeKBID = $idHash->{$genome};
    if (! $genomeKBID) {
        print "KBase ID for $genome not found by ID server.\n";
        $stats->Add(genomeNotFoundInServer => 1);
    } else {
        # Verify that the genome is in the CDMI.
        my ($genomeData) = $cdmi->GetAll('Genome', 'Genome(id) = ?',
                [$genomeKBID], 'source-id scientific-name');
        if (! $genomeData) {
            print "Genome $genome ($genomeKBID) not found in database.\n";
            $stats->Add(genomeNotFoundInDatabase => 1);
        } else {
            # Get the source ID and scientific name to verify this genome.
            my ($genomeDBID, $genomeName) = @$genomeData;
            if ($genomeDBID ne $genome) {
                print "Genome $genome ($genomeKBID) has non-matching ID $genomeDBID in database.\n";
                $stats->Add(genomeMismatchID => 1);
            } else {
                print "Found genome $genome ($genomeKBID): $genomeName\n";
                # We found the genome. Now we can analyze its contig and feature IDs.
                my $contigMap = VerifyChildren($loader, $genomeKBID, 'IsComposedOf', 'Contig');
                if ($verbose) {
                    PrintMap($genome, 'Contig', $contigMap);
                }
                my $featureMap = VerifyChildren($loader, $genomeKBID, 'IsOwnerOf', 'Feature');
                if ($verbose) {
                    PrintMap($genome, 'Feature', $featureMap);
                }
            }
        }
    }
}

=head3 VerifyChildren

    my $idMap = VerifyChildren($loader, $genomeKBID, $relName, $entityName);

Verify the IDs for the specified children of the specified genome. The
children are identified by the name of the entity containing the child
records and the name of the relationship connecting them.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object keyed to the current database source
and connected to the desired CDMI.

=item genomeKBID

KBase ID of the genome whose children are to be verified.

=item relName

Name of the relationship connecting the B<Genome> table to the child entity
table.

=item entityName

Name of the entity containing the child records.

=item RETURN

Returns a refernce to a hash mapping the source IDs of the children to 
their KBase IDs.

=back

=cut

sub VerifyChildren {
    # Get the parameters.
    my ($loader, $genomeKBID, $relName, $entityName) = @_;
    # Get the statistics object and the database connection.
    my $stats = $loader->stats;
    my $cdmi = $loader->cdmi;
    # Find all the children and create a map of their source IDs to
    # KBase IDs.
    my %retVal = map { $_->[0] => $_->[1] }
            $cdmi->GetAll("$relName $entityName", "$relName(from-link) = ?",
                    [$genomeKBID], "$entityName(source-id) $entityName(id)");
    my @sourceIDs = keys %retVal;
    my $idsFound = scalar @sourceIDs;
    print "$idsFound $entityName children found in database for $genomeKBID.\n";
    $stats->Add("$entityName-inDB" => $idsFound);
    # Get the ID server results for these objects.
    my $idMapping = $loader->FindKBaseIDs($entityName, \@sourceIDs);
    # Compare the results and note the differences.
    for my $sourceID (@sourceIDs) {
        my $dbID = $retVal{$sourceID};
        my $svrID = $idMapping->{$sourceID};
        if (! defined $svrID) {
            print "$entityName ID $dbID for $sourceID not found in server.\n";
            $stats->Add("$entityName-notInServer" => 1);
        } elsif ($svrID ne $dbID) {
            print "$entityName ID for $sourceID is $dbID in database but $svrID in server.\n";
            $stats->Add("$entityName-wrongInServer" => 1);
        } else {
            $stats->Add("$entityName-ok" => 1);
        }
    }
    # Return the ID mapping.
    return \%retVal;
}

=head3 PrintMap

    PrintMap($genome, $type, \%idMap);

Print the ID correspondence in the specified ID mapping. The ID mapping
is from source IDs to KBase IDs, and is for children of the specified type
belonging to the specified genome.

=over 4

=item genome

Source ID of the genome whose ID mapping is to be displayed.

=item type

Child type whose ID mapping is to be displayed.

=item idMap

Reference to a hash that maps the source IDs of the relevant type to
their KBase IDs.

=back

=cut

sub PrintMap {
    # Get the parameters.
    my ($genome, $type, $idMap) = @_;
    # Display a heading.
    print "$type ID mapping for $genome.\n\n";
    # Loop through the source IDs.
    for my $sourceID (sort keys %$idMap) {
        print "$sourceID\t$idMap->{$sourceID}\n";
    }
    # Output a spacer.
    print "\n";
}