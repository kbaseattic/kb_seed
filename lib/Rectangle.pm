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

package Rectangle;

    use strict;
    use Tracer;


=head1 Rectangular Region Object

=head2 Introduction

This is a simple object that represents rectangular coordinates on a graphical
canvas.

The fields in this object are as follows.

=over 4

=item left

Leftmost coordinate.

=item right

Rightmost coordinate.

=item top

Top coordinate.

=item bottom

Bottom coordinate.

=back

=cut

=head3 new

    my $rect = Rectangle->new($left, $right, $top, %bottom);

Construct a new Rectangle object. The parameters are as follows.

=over 4

=item left

Leftmost coordinate.

=item top

Top coordinate.

=item right

Rightmost coordinate.

=item bottom

Bottom coordinate.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $left, $top, $right, $bottom) = @_;
    # Create the Rectangle object.
    my $retVal = { 
                    left => $left,
                    right => $right,
                    top => $top,
                    bottom => $bottom,
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 left

    my $left = $rect->left($newValue);

Set or return the left coordinate.

=over 4

=item newValue (optional)

If specified, the new value for the left coordinate.

=item RETURN

Returns the current value of the left coordinate. (This is the new
value if a parameter was specified.)

=back

=cut

sub left {
    # Get the parameters.
    my ($self, $newValue) = @_;
    # Set the new value if specified.
    if (defined $newValue) {
        $self->{left} = $newValue;
    }
    # Return the result.
    return $self->{left};
}

=head3 right

    my $right = $rect->right($newValue);

Set or return the right coordinate.

=over 4

=item newValue (optional)

If specified, the new value for the right coordinate.

=item RETURN

Returns the current value of the right coordinate. (This is the new
value if a parameter was specified.)

=back

=cut

sub right {
    # Get the parameters.
    my ($self, $newValue) = @_;
    # Set the new value if specified.
    if (defined $newValue) {
        $self->{right} = $newValue;
    }
    # Return the result.
    return $self->{right};
}

=head3 top

    my $top = $rect->top($newValue);

Set or return the top coordinate.

=over 4

=item newValue (optional)

If specified, the new value for the top coordinate.

=item RETURN

Returns the current value of the top coordinate. (This is the new
value if a parameter was specified.)

=back

=cut

sub top {
    # Get the parameters.
    my ($self, $newValue) = @_;
    # Set the new value if specified.
    if (defined $newValue) {
        $self->{top} = $newValue;
    }
    # Return the result.
    return $self->{top};
}

=head3 bottom

    my $bottom = $rect->bottom($newValue);

Set or return the bottom coordinate.

=over 4

=item newValue (optional)

If specified, the new value for the bottom coordinate.

=item RETURN

Returns the current value of the bottom coordinate. (This is the new
value if a parameter was specified.)

=back

=cut

sub bottom {
    # Get the parameters.
    my ($self, $newValue) = @_;
    # Set the new value if specified.
    if (defined $newValue) {
        $self->{bottom} = $newValue;
    }
    # Return the result.
    return $self->{bottom};
}

=head3 All

    my ($left, $top, $right, $bottom) = $rect->All();

Return all four coordinates.

=cut

sub All {
    # Get the parameters.
    my ($self) = @_;
    # Return the results.
    return ($self->{left}, $self->{top}, $self->{right},
            $self->{bottom});
}

=head3 width

    my $width = $rect->width($newValue);

Set or return the width of the rectangle.

=over 4

=item newValue (optional)

Proposed new width.

=item RETURN

Returns the width of the rectangular region.

=back

=cut

sub width {
    # Get the parameters.
    my ($self, $newValue) = @_;
    # If a new value is specified, update the right edge.
    if (defined $newValue) {
        $self->{right} = $self->{left} + $newValue;
    }
    # Return the value.
    return $self->{right} - $self->{left};
}

=head3 height

    my $height = $rect->height($newValue);

Set or return the height of the rectangle.

=over 4

=item newValue (optional)

Proposed new height.

=item RETURN

Returns the height of the rectangular region.

=back

=cut

sub height {
    # Get the parameters.
    my ($self, $newValue) = @_;
    # If a new value is specified, update the right edge.
    if (defined $newValue) {
        $self->{bottom} = $self->{top} + $newValue;
    }
    # Return the value.
    return $self->{bottom} - $self->{top};
}


1;
