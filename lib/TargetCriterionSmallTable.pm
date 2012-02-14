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

package TargetCriterionSmallTable;

    use strict;
    use Tracer;
    use Sprout;
    use base qw(TargetCriterionCodeMatch);

=head1 Small Table Target Search Criterion Object

=head2 Introduction

This is a search criterion object for filtering via a connection to a small
table of values. This is a subclass of the [[TargetCriterionCodeMatchPm]] class
for the case where the code table must be computed at runtime.

=head3 new

    my $tc = TargetCriterionSmallTable->new($rhelp, $name, $label, $hint, $field => @path);

Construct a new TargetCriterionSmallTable object. The following parameters are
expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item name

Identifying name of this criterion.

=item label

Label to display in the type dropdown.

=item hint

String to use as a tooltip for the hint button.

=item field

Name of the relevant database field.

=item path

List of entities and relationships forming a path from the C<Genome> or C<Feature> table
to the table containing the database field.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $name, $label, $hint, $field, @path) = @_;
    # Rip the small table off the path.
    my $table = pop @path;
    # Compute the possible values. Note that we throw away "unknown".
    my $sprout = $rhelp->DB();
    my %selectionData = map { $_ => $_ } grep { $_ && $_ ne 'unknown' } $sprout->GetFlat($table, "", [], 'id');
    # Construct the underlying object.
    my $retVal = TargetCriterionCodeMatch::new($class, $rhelp, $name, $label, $hint,
                                               \%selectionData, $field, @path);
    # Return the object.
    return $retVal;
}


1;
