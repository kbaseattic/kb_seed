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

=head1 CDMI Relationship Cleaner

    CDMIDupFix [options] relName field1 field2 ...

This script analyzes a relationship in a CDMI and deletes duplicate rows.

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.

The positional parameters are the relationship name and the names of any additional
fields that should be used to determine whether or not a row is a duplicate.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMIDupFix [options] relName field1 field2 ... \n";
} else {
    # Get the relationship name and the list of fields.
    my ($relName, @fields) = @ARGV;
    print "Processing $relName with " . scalar(@fields) . " extra fields.\n";
    # Call the processing method.
    my $stats = $cdmi->CleanRelationship($relName, @fields);
    # Denote we're done.
    print "All done.\n" . $stats->Show();
}