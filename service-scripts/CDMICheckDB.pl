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

=head1 CDMI Database Check

    CDMICheckDB [options] queryfile

This script runs a list of queries used to check a CDMI instance for bad data.

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.

The positional parameter is the name of a file containing SQL queries used to check the
database. The file must be tab-delimited. The last column should contain the queries. The
other columns will be displayed as comments.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMICheckDB [options] queryFile\n";
} else {
    # Create the statistics object.
    my $stats = Stats->new();
    # Get the database handle. We're doing direct SQL queries.
    my $dbh = $cdmi->{_dbh};
    # Get the input file.
    print "Queries will be read from $ARGV[0].\n";
    open my $ih, "<$ARGV[0]" || die "Could not open input file: $!";
    # Loop through the input file.
    while (! eof $ih) {
        my @fields = Bio::KBase::CDMI::CDMILoader::GetLine($ih);
        $stats->Add(linesIn => 1);
        # Get the query text.
        my $query = pop @fields;
        # Print the comments.
        for my $field (@fields) {
            if ($field) {
                print "--> $field\n";
            }
        }
        # Execute the query.
        my $rv = $dbh->SQL($query);
        $stats->Add(queries => 1);
        # Check for results.
        if (! $rv) {
            print "Query failed: $query\n";
            $stats->Add(badQueries => 1);
        } else {
            # Here the query worked and we need to display results.
            my $rows = scalar (@$rv);
            if (! $rows) {
                print "    No results from query.\n";
                $stats->Add(emptyQueries => 1);
            } else {
                $stats->Add(resultRows => $rows);
                for my $row (@$rv) {
                    print "    " . join(", ", @$row) . "\n";
                }
            }
        }
        print "\n";
    }
    # Denote we're done.
    print "\n\nAll done.\n" . $stats->Show();
}