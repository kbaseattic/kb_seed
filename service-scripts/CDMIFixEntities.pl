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

=head1 CDMI Entity Integrity Check

    CDMIFixEntities [options] rel1 rel2 ...

This script analyzes entities and relationships in a CDMI and deletes
entity instances that are not connected to an owning relationship.

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.

The positional parameters are the relationship names. Each relationship must be
one-to-many. The entity on the "to" side of the relationship will be
examined, and if there is no relationship record for a particular entity
instance, that instance will be deleted.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMIFixEntities [options] rel1 rel2 ...\n";
} else {
    # Create the statistics object.
    my $stats = Stats->new();
    # Loop through the list of relationships.
    for my $rel (@ARGV) {
        print "Processing $rel.\n";
        my $subStats = $cdmi->FixEntity($rel);
        print "Statistics for $rel:\n" . $subStats->Show();
        $stats->Accumulate($subStats);
    }
    # Denote we're done.
    print "All done.\n" . $stats->Show();
}