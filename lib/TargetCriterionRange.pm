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

package TargetCriterionRange;

    use strict;
    use Tracer;
    use Sprout;
    use base qw(TargetCriterionQuery);

=head1 Numeric Value Range Target Search Criterion Object

=head2 Introduction

This is a search criterion object for filtering a numeric value within a specified
range. The range is specified using the min/max control in the target search form.

=head3 new

    my $tc = TargetCriterionRange->new($rhelp, $name, $label, $hint, $field => @path);

Construct a new TargetCriterionRange object. The following parameters are
expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item name

Identifying name of this criterion.

=item label

Label to use for this criterion.

=item hint

Hint string to display when this criterion is selected.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $name, $label, $hint, $sanity, $field, @path) = @_;
    # Package the options.
    my %options = (label => $label, hint => $hint, minMax => 1, name => $name);
    # Construct the underlying object.
    my $retVal = TargetCriterionQuery::new($class, $rhelp, \%options, $field => @path);
    # Override the sanity.
    $retVal->{sane} = $sanity;
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
    # Declare the return variable.
    my $retVal;
    # Get the values to validate.
    my ($min, $max) = $self->GetMinMax($parms);
    # An undefined value for either is an error.
    if (! defined $min) {
        $self->SetMessage("Invalid or missing minimum for $self->{label}.");
    } elsif (! defined $max) {
        $self->SetMessage("Invalid or missing maximum for $self->{label}.");
    } elsif ($min > $max) {
        $self->SetMessage("Minimum cannot be greater than maximum for $self->{label}.");
    } else {
        $retVal = 1;
    }
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
    # Compute the join list.
    my $joins = $self->JoinList();
    # Compute the filter string.
    my $filterString = "$fieldName >= ? AND $fieldName <= ?";
    # Finally, we build the parameter list, which contains the minimum value and
    # the maximum value.
    my $parms = [ $self->GetMinMax($criterion) ];
    # Return the results.
    return ($joins, $filterString, $parms);
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
    # Get the min and max parameters.
    my ($min, $max) = $self->GetMinMax($criterion);
    # We match if any value is in the given range.
    my $retVal = grep { $_ >= $min && $_ <= $max } @$valueData;
    # Return the result.
    return $retVal;
}



1;
