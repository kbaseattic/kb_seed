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

    CDMILoadAssertions [options] assertion_file

This script loads the protein function assertions from an assertion file.

The following table is loaded.

=over 4

=item AssertsFunctionFor

specifies an assertion of protein function from a specific source

=back

Only assertions for identifiers found in the database will be loaded.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
the following.

=over 4

=item recursive

If this option is specified, then instead of loading the single specified
file, all files from the specified directory will be loaded.

=item clear

If this option is specified, the main table will be deleted and re-created
prior to loading.

=back

There is a single positional parameter: the name of a tab-delimited file
containing assertions. Each assertion has the following fields.

=over 4

=item 1

source identifier

=item 2

MD5 protein identifier

=item 3

external identifier relevant to the assertion (prefixed)

=item 4

GI number corresponding to the identifier (with a C<gi|> prefix)

=item 5

function asserted for the protein (optional, may be empty string)

=item 6

name of the organism (optional, may be empty string)

=item 7

date the assertion was downloaded, in the form
I<yyyy>C<->I<mm>C<->I<dd> I<hh>C<:>I<mm>C<:>I<ss>.

=back

=cut

# List of tables we are loading.
my @TABLES = qw(AssertsFunctionFor);

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my ($recursive, $clear);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(recursive => \$recursive,
        clear => \$clear);
if (! $cdmi) {
    print "usage: CDMILoadAssertions [options] assertionFile\n";
} else {
    # Get a CDMI loader.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Verify the input parameter.
    my $assertionFile = $ARGV[0];
    if (! $assertionFile) {
        die "No input file specified.\n";
    } else {
        # Are we clearing?
        if ($clear) {
            # Yes. Recreate the tables.
            print "Recreating tables.\n";
            for my $table (@TABLES) {
                $cdmi->CreateTable($table, 1);
            }
        }
        # Set up the load files.
        $loader->SetRelations(@TABLES);
        if ($recursive) {
            # Here we're processing all the files in a directory.
            if (! -d $assertionFile) {
                die "Invalid input directory $assertionFile specified.\n";
            } else {
                opendir(TMP, $assertionFile) || die "Could not open $assertionFile.\n";
                my @files = sort grep { substr($_,0,1) ne '.' } readdir(TMP);
                print scalar(@files) . " entries found in $assertionFile.\n";
                # Loop through the subdirectories.
                for my $file (@files) {
                    my $fullPath = "$assertionFile/$file";
                    if (-f $fullPath) {
                        LoadAssertions($loader, $fullPath);
                    }
                }
            }
        } else {
            # Here we're processing a single file.
            if (! -f $assertionFile) {
                die "Invalid input file $assertionFile specified.\n";
            } else {
                LoadAssertions($loader, $assertionFile);
            }
        }
        # Unspool the load files into the database.
        print "Loading database.\n";
        $loader->LoadRelations(@TABLES);
        print "All done:\n" . $stats->Show();
    }
}

=head2 Subroutines

=head3 LoadAssertions

    LoadAssertions($loader, $fileName);

Load the assertions from the specified assertion file.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for the current load.

=item fileName

Name of the file containing the assertions.

=back

=cut

sub LoadAssertions {
    # Get the parameters.
    my ($loader, $fileName) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the CDMI database object.
    my $cdmi = $loader->cdmi;
    # This will be used to track progress.
    my $count = 0;
    # Open the file for input.
    open(my $ih, "<$fileName") || die "Could not open $fileName: $!\n";
    print "Loading assertions from $fileName.\n";
    $stats->Add(files => 1);
    # Loop through the input file.
    while (! eof $ih) {
        my ($source, $protein, $ext_id, $gi_number, $function, $organism, $date) = $loader->GetLine($ih);
        $stats->Add(linesIn => 1);
        # Convert the GI number to an integer.
        my $giNumber;
        if (! $gi_number) {
            $giNumber = 0;
            $stats->Add(giNumberMissing => 1);
        } elsif ($gi_number =~ /^gi\|(\d+)/) {
            $giNumber = $1;
        } else {
            $giNumber = 0;
            $stats->Add(giNumberBad => 1);
        }
        # Convert the date to the ERDB format.
        my $dateValue = Bio::KBase::CDMI::CDMILoader::ConvertTime($date);
        # Default the possibly-empty fields.
        if (! defined $function) {
            $function = "";
        }
        if (! defined $organism) {
            $organism = "";
        }
        # Insure the protein exists in the database.
        my $protFound = $cdmi->Exists(ProteinSequence => $protein);
        if (! $protFound) {
            $stats->Add(proteinNotFound => 1);
        } else {
            # Write it to the database.
            $loader->InsertObject('AssertsFunctionFor',
                from_link => $source, to_link => $protein,
                function => $function, external_id => $ext_id,
                organism => $organism, gi_number => $giNumber,
                release_date => $dateValue);
            $stats->Add(assertionOut => 1);
        }
        # Display our progress.
        $count++;
        if ($count % 5000 == 0) {
            print "$count assertions processed.\n";
        }
    }
}
