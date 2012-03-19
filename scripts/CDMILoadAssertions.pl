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

=head1 CDMI Assertions Loader

    CDMILoadAssertions [options] master_directory

This script loads the protein function assertions from the SEED assertion
directory.

The following table is loaded.

=over 4

=item HasAssertionFrom

specifies an assertion of protein function from a specific source

=back

Only assertions for identifiers found in the database will be loaded.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<CDMI/new_for_script>.
There is a single positional parameter: the name of a directory containing
sub-directories with assertions in them. The subdirectory name is the source
organization for the assertion. In each directory is a tab-delimited file
named B<assigned_functions> containing the actual assertions themselves.
The first field in each record is a protein identifier and the second is
an assertion functional assignment. Only identifiers found in the CDMI
will be processed.

=cut

# List of tables we are loading.
my @TABLES = qw(HasAssertionFrom);

# List of assertion sources we are processing.
my @SOURCES = qw(Trembl Uniprot IMG CMR ERIC KEGG NCBI);

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMILoadAssertions [options] masterDirectory\n";
} else {
    # Get a CDMI loader.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Verify the input directory.
    my $masterDirectory = $ARGV[0];
    if (! $masterDirectory) {
        die "No input directory specified.\n";
    } elsif (! -d $masterDirectory) {
        die "Could not find input directory $masterDirectory.\n";
    } else {
        # Recreate the tables.
        print "Recreating tables.\n";
        for my $table (@TABLES) {
            $cdmi->CreateTable($table, 1);
        }
        # Set up the load files.
        $loader->SetRelations(@TABLES);
        # Loop through the assertion sources.
        for my $source (@SOURCES) {
            # Try to find the assertion file for this source.
            my $assertFile = "$masterDirectory/$source/assigned_functions";
            if (! -f $assertFile) {
                print "No assertions file found for $source.\n";
                $stats->Add(sourceNotFound => 1);
            } else {
                # Open this assertions file.
                print "Processing assertions for $source.\n";
                open(my $ih, "<$assertFile") || die "Could not open assertions for $source: $!\n";
                $stats->Add(sources => 1);
                # Verify that the source exists in the database.
                my $createFlag = $loader->InsureEntity(Source => $source);
                if ($createFlag) {
                    $stats->Add(newSource => 1);
                }
                # This will be used to periodically issue status messages.
                my $count = 0;
                # Loop through the assertions for this source.
                while (! eof $ih) {
                    my ($identifier, $function) = $loader->GetLine($ih);
                    $stats->Add("$source-in" => 1);
                    # Only proceed if there's really a function.
                    if (! $function) {
                        $stats->Add("$source-noFunction" => 1);
                    } else {
                        # Check for this identifier in the database.
                        if (! $cdmi->Exists(Identifier => $identifier)) {
                            $stats->Add(idNotFound => 1);
                        } else {
                            $stats->Add("$source-found" => 1);
                            # Add the assertion.
                            $loader->InsertObject('HasAssertionFrom', from_link => $identifier,
                                to_link => $source, function => $function, expert => 0);
                        }
                    }
                    # Show our progress.
                    $count++;
                    if ($count % 10000 == 0) {
                        print "$count assertions processed for $source.\n";
                    }
                }
            }
        }
        # Unspool the load files into the database.
        print "Loading database.\n";
        $loader->LoadRelations(@TABLES);
        print "All done:\n" . $stats->Show();
    }
}