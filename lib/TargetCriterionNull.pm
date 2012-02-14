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

package TargetCriterionNull;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use base qw(TargetCriterion);


=head1 Target Search Null Criterion Object

=head2 Introduction

This is a special search criterion that is used as a no-op. It is TRUE for
every feature when it's used with the AND operator and FALSE for every feature
when it's used with the OR or NOT operators. No controls are displayed.

=cut

=head3 new

    my $tc = TargetCriterion->new($rhelp, $name, $label, $hint);

Construct a new TargetCriterion object. The following parameters are expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item name

Identifying name of this criterion.

=item label

Label to display in the type dropdown.

=item hint

String to use as a tooltip for the hint button.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $name, $label, $hint) = @_;
    # Create the underlying object.
    my $retVal = TargetCriterion::new($class, $rhelp, name => $name, label => $label,
                                      hint => $hint);
    # Return it.
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
    return 1;
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
    # We match if this is an AND, otherwise we don't match.
    my $retVal = ($criterion->{op} eq 'AND');
    # Return the result.
    return $retVal;
}


1;
