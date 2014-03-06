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

=head1 CDMI Table Deletion

    CDMIClean [options] obj1 obj2 ...

This script deletes the tables specified by the entities and relationships in the
parameter list.

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus the following.

=over 4

=item test

Display the tables to be truncated, but don't update the database.

=back

The positional parameters are the entity and relationship names. All tables for these
objects will be truncated and removed from the database.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Declare the command-line option variables.
my ($test);
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(test => \$test);
if (! $cdmi) {
    print "usage: CDMIClean [options] obj1 obj2 ... \n";
} else {
    # Create the statistics object.
    my $stats = Stats->new();
    # Loop through the list of objects.
    for my $obj (@ARGV) {
        print "Processing $obj.\n";
        # Get the entity structure.
        my $struct = $cdmi->FindEntity($obj);
        # If no entity structure was found, it's a relationship, so it has only one table.
        my @tables;
        if (! $struct) {
            @tables = ($obj);
            $stats->Add(Relationships => 1);
        } else {
            # Get the list of tables forming this entity.
            @tables = keys %{$struct->{Relations}};
            $stats->Add(Entities => 1);
        }
        # Loop through the tables, truncating them.
        for my $table (@tables) {
            print "  Clearing $table.\n";
            if ($test) {
                print "      Test mode: no update.\n";
            } else {
                $cdmi->TruncateTable($table);
            }
            $stats->Add(Tables => 1);
        }
    }
    # Denote we're done.
    print "All done.\n" . $stats->Show();
}