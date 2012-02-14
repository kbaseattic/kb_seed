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
    use CDMI;

=head1 CDMI Database Creator

    CDMICreate [options]

This script creates the tables in a new KBase Central Data Model instance.
Any existing data in the tables will be destroyed. (Tables not normally found in
a CDMI, however, will be unaffected.)

The command-line options are as specified in L<CDMI/new_for_script>. There are
no positional parameters.

=cut

# Connect to the database.
my $cdmi = CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMICreate [options]\n";
} else {
    # Create the tables.
    $cdmi->CreateTables();
    # Tell the user we're done.
    print "Database tables created.\n";
}
