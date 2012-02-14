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
    use CDMILoader;
    use CDMI;

=head1 CDMI Genome Set Loader

    CDMILoadGenomeSets [options] taxonDirectory

This script loads the OTU sets from the specified genome set file. This is
global information that requires deleting and recreating the following
tables.

=over 4

=item OTU

set of related genomes

=item IsCollectionOf

relationship that connects OTUs to genomes

=back

The command-line options are those specified in L<CDMI/new_for_script>
plus the following.

=over 4

=item source

Source (core) database for the genome IDs in the input file. The
default is C<SEED>.

=back

There is a single positional parameter that specifies the genome set
input file. This is a tab-delimited file with three columns: genome
set number, genome ID, and genome name. The first genome ID for a set
is presumed to be the representative genome.

=cut

# The source database name will be stored in here.
my $source = 'SEED';
# Connect to the database using the command-line options.
my $cdmi = CDMI->new_for_script('source=s' => \$source);
if (! $cdmi) {
    print "usage: CDMILoadGenomeSets [options] genomeSetFile\n";
} else {
    # Create the loader utility object.
    my $loader = CDMILoader->new($cdmi);
    # Get the statistics object inside it.
    my $stats = $loader->stats;
    # Get the genome set file name.
    my $setFile = $ARGV[0];
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
                'Submitted(from-link) = ? AND Genome(source-id) = ?',
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
        # Display the full statistics.
        print "All done:\n" . $stats->Show();
    }
}


