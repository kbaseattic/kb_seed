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

=item fixup

If specified, tables in the database not found in the DBD will be deleted, and
tables missing from the database will be created. Tables that have changed and
are empty will be dropped and re-created. Tables that have data in them will
be displayed without being updated. If this option is specified, C<missing>
will be ignored.

=back

There are no positional parameters.

=cut

# Connect to the database.
my ($missing, $fixup);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(missing => \$missing, fixup => \$fixup);
if (! $cdmi) {
    print "usage: CDMICreate [options]\n";
} else {
    # Create the statistics object.
    my $stats = Stats->new();
    # Get the database handle.
    my $dbh = $cdmi->{_dbh};
    # Get the relation names.
    my @relNames = sort $cdmi->GetTableNames();
    # The list of changed tables will be kept in here.
    my %changed;
    # Is this a fixup?
    if ($fixup) {
        # Yes. Denote we only want to create missing tables.
        $missing = 1;
        # Get a list of a tables in the actual database.
        my @tablesFound = $dbh->get_tables();
        print scalar(@tablesFound) . " tables found in database.\n";
        # Create a hash for checking the tables against the schema. The check
        # needs to be case-insensitive.
        my %relHash = map { lc($_) => 1 } @relNames;
        # Loop through the tables in the database, looking for ones to drop.
        for my $table (@tablesFound) {
            $stats->Add(tableChecked => 1);
            if (substr($table, 0, 1) eq "_") {
                # Here we have a system table.
                $stats->Add(systemTable => 1);
            } elsif (! $relHash{lc $table}) {
                # Here the table is not in the DBD.
                print "Dropping $table.\n";
                $dbh->drop_table(tbl => $table);
                $stats->Add(tableDropped => 1);
            } else {
                # Here we need to compare the table's real schema to the DBD.
                print "Analyzing $table.\n";
                # This is the real scheme.
                my @cols = $dbh->table_columns($table);
                # We'll set this to TRUE if there is a difference.
                my $different;
                # Loop through the DBD schema, comparing.
                my $relation = $cdmi->FindRelation($table);
                my $fields = $relation->{Fields};
                my $count = scalar(@cols);
                if (scalar(@$fields) != $count) {
                    print "$table has a different column count.\n";
                    $different = 1;
                } else {
                    # The column count is the same, so we do a 1-for-1 compare.
                    for (my $i = 0; $i < $count && ! $different; $i++) {
                        # Get the fields at this position.
                        my $actual = $cols[$i];
                        my $schema = $fields->[$i];
                        # Compare the names and the nullabilitiy.
                        if (lc $actual->[0] ne lc ERDB::_FixName($schema->{name})) {
                            print "Field mismatch at position $i in $table.\n";
                            $different = 1;
                        } elsif ($actual->[2] ? (! $schema->{null}) : $schema->{null}) {
                            print "Nullability mismatch in $actual->[0] of $table.\n";
                            $different = 1;
                        } else {
                            # Here we have to compare the field types. Because of
                            # a glitch, we only look at the first word.
                            my ($schemaType) = split m/\s+/, $cdmi->_TypeString($schema);
                            if (lc $schemaType ne lc $actual->[1]) {
                                print "Type mismatch in $actual->[0] of $table.\n";
                                $different = 1;
                            }
                        }
                    }
                }
                if ($different) {
                    # Here we have a table mismatch.
                    $stats->Add(tableMismatch => 1);
                    # Check for data in the table.
                    if ($cdmi->IsUsed($table)) {
                        # There's data, so save it for being listed
                        # later.
                        $changed{$table} = 1;
                    } else {
                        # No data, so drop it.
                        print "Dropping $table.\n";
                        $dbh->drop_table(tbl => $table);
                        $stats->Add(tableDropped => 1);
                    }
                }
            }
        }
    }
    # Loop through the relations.
    for my $relationName (@relNames) {
        $stats->Add(relationChecked => 1);
        # Do we want to create this table?
        if (! $missing || ! $dbh->table_exists($relationName)) {
            $cdmi->CreateTable($relationName, 1);
            print "$relationName created.\n";
            $stats->Add(relationCreated => 1);
        } elsif ($changed{$relationName}) {
            print "$relationName needs to be recreated.\n";
            print "Field string: " . $cdmi->ComputeFieldString($relationName) . "\n";
        }
    }
    # Tell the user we're done.
    print "Database processed.\n" . $stats->Show();
}
