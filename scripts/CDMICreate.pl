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

=head1 CDMI Database Creator

    CDMICreate [options]

This script creates the tables in a new KBase Central Data Model instance.
Any existing data in the tables will be destroyed. (Tables not normally found in
a CDMI, however, will be unaffected.)

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
the following.

=over 4

=item missing

If specified, only tables missing from the database will be created.

=back

There are no positional parameters.

=cut

# Connect to the database.
my ($missing);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(missing => \$missing);
if (! $cdmi) {
    print "usage: CDMICreate [options]\n";
} else {
    # Get the relation names.
    my @relNames = $cdmi->GetTableNames();
    # Get the database handle.
    my $dbh = $cdmi->{_dbh};
    # Loop through the relations.
    for my $relationName (@relNames) {
        # Do we want to create this table?
        if (! $missing || ! $dbh->table_exists($relationName)) {
            $cdmi->CreateTable($relationName, 1);
            print "$relationName created.\n";
        }
    }
    # Tell the user we're done.
    print "Database tables created.\n";
}
