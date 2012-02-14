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

package TargetCriterionConservedNeighborhood;

    use strict;
    use Tracer;
    use Sprout;
    use base qw(TargetCriterionQuery);

=head1 Conserved Neighborhood Target Search Criterion Object

=head2 Introduction

This is a search criterion object that only matches features with a conserved
neighborhood. Such features are considered "pinned".

=head3 new

    my $tc = TargetCriterionConservedNeighborhood->new($rhelp, $name, $label, $hint);

Construct a new TargetCriterionConservedNeighborhood object. The following parameters are
expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item name

Identifying name of this criterion.

=item label

Label to display for this criterion in the type dropdown.

=item hint

The hint tooltip to be displayed for this criterion.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $name, $label, $hint) = @_;
    # Construct the underlying object.
    my $retVal = TargetCriterionQuery::new($class, $rhelp,
                                           { label => $label, hint => $hint,
                                             selectionData => RHFeatures::RealBoolean(),
                                             name => $name },
                                           'conserved-neighbors' => 'Feature');
    # Denote we're insane.
    $retVal->{sanity} = 0;
    # Return the object.
    return $retVal;
}

=head2 Virtual Methods

=head3 Validate

    my $okFlag = $tc->Validate($parms);

Return TRUE if the specified parameters are valid for a search criterion of this type
and FALSE otherwise. If an error is detected, the error message can be retrieved using
the L</message> method.

=over 4

=item parms

A Criterion Parameter Object whose fields are to be validated.

=item RETURN

Returns TRUE if the parameters are valid, else FALSE.

=back

=cut

sub Validate {
    # Get the parameters.
    my ($self, $parms) = @_;
    # We're always valid.
    my $retVal = 1;
    # Return the validation code.
    return $retVal;
}

=head3 ComputeQuery

    my ($joins, $filterString, $parms) = $tc->ComputeQuery($criterion);

Compute the SQL filter, join list, and parameter list for this
criterion. If the criterion cannot be processed by SQL, then nothing is
returned, and the criterion must be handled during post-processing.

The join list and the parameter list should both be list references. The
filter string is a true string.

If the filter string only uses the B<Genome> and B<Feature> tables, then the
join list can be left empty. Otherwise, the join list should start with the
particular starting point (B<Genome> or B<Feature>) and list the path through
the other relevant entities and relationships. Each criterion will have its
own separate join path. 

=over 4

=item criterion

Reference to a Criterion Parameter Object.

=item RETURN

Returns a 3-tuple consisting of the join list, the relevant filter string,
and the matching parameters. If the criterion cannot be processed using
SQL, then the return list contains three undefined values. (This is what happens if
you don't override this method.)

=back

=cut

sub ComputeQuery {
    # Get the parameters.
    my ($self, $criterion) = @_;
    # Get the name of the relevant field with the appropriate suffix.
    my $fieldName = $self->RelevantField($criterion->{idx});
    # Is this a YES or a NO?
    my $condition = ($criterion->{selection} ? "> 0" : "= 0");
    # Return the resulting condition.
    return ([], "$fieldName $condition", []);
}

=head3 CheckValue

    my $match = $tc->CheckValue($criterion, $valueData);

Return TRUE if the current feature matches this criterion, else FALSE.

=over 4

=item criterion

Criterion Parameter object describing this criterion's parameters.

=item valueData

Value computed for the current feature by the L</GetValueData> method.

=item RETURN

Returns TRUE if the current feature matches the criterion, else FALSE.

=back

=cut

sub CheckValue {
    # Get the parameters.
    my ($self, $criterion, $valueData) = @_;
    # See if we have conserved neighbors.
    my $retVal = ($valueData->[0] > 0);
    # Return the result.
    return $retVal;
}


1;
