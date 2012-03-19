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
    use AliasAnalysis;

=head1 CDMI Identifier Loader

    CDMILoadIdentifiers [options] protein_file

This script loads the protein identifiers from the SEED file.
This is a long process because of the large amount of data involved.

The following tables are loaded.

=over 4

=item Identifier

protein identifier definition

=item IsNamedBy

relationship from identifiers to protein sequences

=back

Only identifiers for proteins found in the database will be loaded.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<CDMI/new_for_script>.
There is a single positional parameter: the name of a tab-delimited file
containing protein IDs in the first column and identifiers in the second
column. The protein IDs are in an extended format containing additional
information: the actual ID is the part between the last vertical bar and
the first comma.

=cut

# List of tables we are loading.
my @TABLES = qw(Identifier IsNamedBy);

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMILoadIdentifiers [options] proteinFile\n";
} else {
    # Get a CDMI loader.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Verify the input file.
    my $protFile = $ARGV[0];
    if (! $protFile) {
        die "No input file specified.\n";
    } elsif (! -f $protFile) {
        die "Could not find input file $protFile.\n";
    } else {
        print "Accessing input file.\n";
        open(my $ih, "<$protFile") || die "Could not open input file: $!\n";
        # Recreate the two tables.
        print "Recreating tables.\n";
        for my $table (@TABLES) {
            $cdmi->CreateTable($table, 1);
        }
        # Set up the load files.
        $loader->SetRelations(@TABLES);
        # This is a performance trick. We will track the previous protein ID
        # so that we don't need to re-check the database for its existence.
        # This works because the input file is sorted by protein ID.
        my $prevProteinID = "";
        my $prevProteinFound = 0;
        # This will be used to periodically issue status messages.
        my $count = 0;
        # Loop through the input file.
        while (! eof $ih) {
            my ($protein, $identifier) = $loader->GetLine($ih);
            $stats->Add(lineIn => 1);
            # Parse the MD5 out of the protein ID.
            unless ($protein =~ /.*\|([^,]+),/) {
                print STDERR "Invalid protein specification \"$protein\".\n";
                $stats->Add(badProteinID => 1);
            } else {
                my $proteinID = $1;
                # Insure this protein exists in the CDMI database.
                my $found;
                if ($proteinID eq $prevProteinID) {
                    $stats->Add(proteinInSequence => 1);
                    $found = $prevProteinFound;
                } else {
                    $stats->Add(proteinChecked => 1);
                    if ($cdmi->Exists(ProteinSequence => $proteinID)) {
                        $stats->Add(proteinFoundInDatabase => 1);
                        $found = 1;
                    } else {
                        $stats->Add(proteinNotFoundInDatabase => 1);
                        $found = 0;
                    }
                    # Set up for the next time through the loop.
                    $prevProteinID = $proteinID;
                    $prevProteinFound = $found;
                }
                if (! $found) {
                    $stats->Add(lineSkipped => 1);
                } else {
                    # Here the protein is in the database, so we want
                    # to process this identifier. We have to make a
                    # special check for FIG IDs.
                    my ($type, $natural);
                    if ($identifier =~ /^fig\|/) {
                        $type = 'SEED';
                        $natural = $identifier;
                        $stats->Add(figIdentifier => 1);
                    } else {
                        $type = AliasAnalysis::TypeOf($identifier);
                        if (! defined $type) {
                            $stats->Add(unsupportedIdentifierType => 1);
                        } else {
                            $natural = AliasAnalysis::Type($type => $identifier);
                            if (! defined $natural) {
                                print "Invalid type for $identifier.\n";
                            }
                        }
                    }
                    # If we have a valid type, add the identifier and
                    # connect it to the protein.
                    if (defined $type) {
                        $loader->InsertObject('Identifier',
                            id => $identifier, source => $type,
                            natural_form => $natural);
                        $loader->InsertObject('IsNamedBy', from_link => $proteinID,
                            to_link => $identifier);
                        $stats->Add("identifier$type" => 1);
                    }
                }
            }
            # Insure our progress is visible.
            $count++;
            if ($count % 10000 == 0) {
                print "$count identifiers processed.\n";
            }
        }
        # Unspool the load files into the database.
        print "Loading database.\n";
        $loader->LoadRelations(@TABLES);
        print "All done:\n" . $stats->Show();
    }
}

