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

=head1 Statistical Survey for CDMI

    CDMISurvey [options]

=head2 Introduction

This script displays statistical infomation about the entities in a
CDMI. The entities are displayed with the number of records in each,
in an order specified by the command-line options.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item order

Indicates the sort order-- C<alpha> for alphabetical order (the default)
or C<pop> to display from most populous to least populous.

=item rels

In addition to the entity counts, each entity's relationship counts
are displayed.

=item all

Normally, relationships and entities with no rows are omitted. If
this option is specified, they are included.

=back

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;

    # valid orderings
    use constant ORDERS => { 'alpha' => 1, 'pop' => 1 };

    $| = 1; # Prevent buffering on STDOUT.
    # This holds the load order.
    my $order = 'alpha';
    # This will be set to TRUE if relationships should be displayed.
    my $rels;
    # This will be set to TRUE if zero-row entities and relationships
    # should be dislayed.
    my $all;
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("order=s" => \$order,
        "rels" => \$rels, "all" => \$all);
    if (! $cdmi) {
        print "usage: CDMISurvey [options]\n";
    } else {
        print "Connected.\n";
        # Verify the order parameter.
        if (! ORDERS->{$order}) {
            die "Invalid order specification \"$order\".\n";
        }
        # This will hold the length of the longest name.
        my $length = 0;
        # This hash will map the entity names to the counts found.
        my %counts;
        # This is used to print status messages.
        my $queries = 0;
        # If "rels" is specified, this hash will map each entity name
        # to a subhash that maps its relationships to their counts.
        my %relCounts;
        # Get a list of the entity names.
        my @entities = $cdmi->GetEntityTypes();
        # Loop through the entities.
        for my $entity (@entities) {
            # Get this entity's count.
            my $count = $cdmi->GetCount($entity, "", []);
            CountQuery(\$queries);
            # Only proceed if we are handling all entities or this
            # entity is populated.
            if ($all || $count) {
                $counts{$entity} = $count;
                MergeLength(\$length, $entity);
                # If we are counting relationships, process them
                # here. Note that we store relationship names with
                # padding in front for display purposes.
                if ($rels) {
                    my @relationships = $cdmi->GetConnectingRelationships($entity);
                    CountQuery(\$queries);
                    my $subHash = {};
                    for my $relationship (@relationships) {
                        $count = $cdmi->GetCount("$relationship $entity", "", []);
                        if ($all || $count) {
                            my $relationshipName = "     $relationship";
                            MergeLength(\$length, $relationshipName);
                            $subHash->{$relationshipName} = $count;
                        }
                    }
                    $relCounts{$entity} = $subHash;
                }
            }
        }
        # Now we display the results. First, we need to sort the
        # entity names. We also want to eliminate the entities that
        # were not recorded.
        @entities = keys %counts;
        my @sorted;
        if ($order eq 'pop') {
            @sorted = sort { $counts{$b} <=> $counts{$a} } @entities;
        } else {
            @sorted = sort @entities;
        }
        for my $entity (@sorted) {
            DisplayLine($entity, $counts{$entity}, $length);
            if ($rels) {
                my $subHash = $relCounts{$entity};
                for my $rel (sort keys %$subHash) {
                    DisplayLine($rel, $subHash->{$rel}, $length);
                }
            }
        }
    }


# Merge the length of the specified string into the specified length
# variable. We use this to figure out the length of the longest name
# we need to display.
sub MergeLength {
    my ($lengthVar, $string) = @_;
    my $length = length($string);
    if ($length > $$lengthVar) {
        $$lengthVar = $length;
    }
}

# Left-pad the specified string to the specified length.
sub Pad {
    my ($string, $len) = @_;
    my $stringLen = length($string);
    my $retVal;
    if ($stringLen < $len) {
        $retVal = (' ' x ($len - $stringLen)) . $string;
    } else {
        $retVal = ' ' . $string;
    }
    return $retVal;
}

# Display an output line.
sub DisplayLine {
    my ($name, $count, $length) = @_;
    print $name . (' ' x ($length - length($name))) . Pad($count, 15) . "\n";
}

# Display a message every 20 queries.
sub CountQuery {
    my ($pqueries) = @_;
    $$pqueries++;
    if ($$pqueries % 20 == 0) {
        print "$$pqueries queries used.\n";
    }
}