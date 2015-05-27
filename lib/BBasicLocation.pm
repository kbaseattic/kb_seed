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

#
# This is a SAS component.
#
package BBasicLocation;

    use strict;
    use base qw(BasicLocation);

=head2 Backward Basic BasicLocation Object

A I<backward location object> is a location in a contig that is transcribed from right to left.
It is a subclass of the B<BasicLocation> object, and contains methods that require different
implementation for a forward location than a backward location.

=head2 Override Methods

=head3 Left

    my $leftPoint = $loc->Left;

Return the offset of the leftmost point of the location.

=cut

sub Left {
    return $_[0]->{_end};
}

=head3 Right

    my $rightPoint = $loc->Right;

Return the offset of the rightmost point of the location.

=cut

sub Right {
    return $_[0]->{_beg};
}

=head3 Compare

    my ($distance, $cmp) = $loc->Compare($point);

Determine the relative location of the specified point on the contig. Returns a distance,
which indicates the location relative to the leftmost point of the contig, and a comparison
number, which is negative if the point is to the left of the location, zero if the point is
inside the location, and positive if the point is to the right of the location.

=cut

sub Compare {
    # Get the parameters.
    my ($self, $point) = @_;
    # Compute the distance from the end (leftmost) point.
    my $distance = $point - $self->{_end};
    # Set the comparison value. The distance works unless it is positive and less than
    # the length. In that case, it's inside the location so we want to return 0.
    my $cmp = (defined $self->IfValid($distance) ? 0 : $distance);
    # Return the results.
    return ($distance, $cmp);
}

=head3 Split

    my $newLocation = $loc->Split($offset);

Split this location into two smaller ones at the specified offset from the left endpoint. The
new location split off of it will be returned. If the offset is at either end of the location,
no split will occur and an underfined value will be returned.

=over 4

=item offset

Offset into the location from the left endpoint of the point at which it should be split.

=item RETURN

The new location split off of this one, or an undefined value if no split was necessary.

=back

=cut

sub Split {
    # Get the parameters.
    my ($self, $offset) = @_;
    # Declare the return variable.
    my $retVal;
    # Only proceed if a split is necessary.
    if ($offset > 0 && $offset < $self->{_len}) {
        # Save the current ending point.
        my $oldEndpoint = $self->{_end};
        # Update this location's ending point and length.
        $self->{_end} += $offset;
        $self->{_len} -= $offset;
        # Create the new location.
        $retVal = BasicLocation->new($self->{_contigID}, $oldEndpoint + $offset - 1, '-', $offset);
    }
    # Return the new location object.
    return $retVal;
}

=head3 Peel

    my $peel = $loc->Peel($length);

Peel a specified number of positions off the beginning of the location. Peeling splits
a location at a specified offset from the beginning, while splitting takes it at a
specified offset from the left point. If the specified length is equal to or longer
than the location's length, an undefined value will be returned.

=over 4

=item length

Number of positions to split from the location.

=item RETURN

Returns a new location formed by splitting positions off of the existing location, which is
shortened accordingly. If the specified length is longer than the location's length, an
undefined value is returned and the location is not modified.

=back

=cut

sub Peel {
    # Get the parameters.
    my ($self, $length) = @_;
    # Declare the return variable.
    my $retVal;
    # Only proceed if a split is necessary.
    if ($length < $self->{_len}) {
        # Save the current begin point.
        my $oldBegpoint = $self->{_beg};
        # Update this location's begin point and length. We're peeling from the beginning,
        # which for this type of location means the segment is chopped off the right end.
        $self->{_beg} -= $length;
        $self->{_len} -= $length;
        # Create the new location.
        $retVal = BasicLocation->new($self->{_contigID}, $oldBegpoint, '-', $length);
    }
    # Return the new location object.
    return $retVal;
}

=head3 Reverse

    $loc->Reverse;

Change the polarity of the location. The location will have the same nucleotide range, but
the direction will be changed.

=cut

sub Reverse {
    # Get the parameters.
    my ($self) = @_;
    # Swap the beginning and end, then update the direction.
    ($self->{_beg}, $self->{_end}) = ($self->{_end}, $self->{_beg});
    $self->{_dir} = '+';
    # Re-bless us as a forward location.
    bless $self, "FBasicLocation";
}

=head3 PointIndex

    my $index = $loc->PointIndex($point);

Return the index of the specified point in this location. The value returned is the distance
from the beginning. If the specified point is not in the location, an undefined value is returned.

=over 4

=item point

Offset into the contig of the point in question.

=item RETURN

Returns the distance of the point from the beginning of the location, or an undefined value if the
point is outside the location.

=back

=cut

sub PointIndex {
    # Get the parameters.
    my ($self, $point) = @_;
    # Compute the distance from the beginning. Because we are in a backward location, this
    # means subtracting the point's offset from the beginning's offset.
    my $retVal = $self->IfValid($self->{_beg} - $point);
    # Return the result.
    return $retVal;
}

=head3 PointOffset

    my $offset = $loc->PointOffset($index);

Return the offset into the contig of the point at the specified position in the location. A position
of 0 will return the beginning point, a position of 1 returns the point next to that, and a position
1 less than the length will return the ending point.

=over 4

=item index

Index into the location of the relevant point.

=item RETURN

Returns an offset into the contig of the specified point in the location.

=back

=cut

sub PointOffset {
    # Get the parameters.
    my ($self, $index) = @_;
    # Return the offset. This is a backward location, so we subtract it from the begin point.
    return $self->{_beg} - $index;
}

=head3 SetBegin

    $loc->SetBegin($newBegin);

Change the begin point of this location without changing the endpoint.

=over 4

=item newBegin

Proposed new beginning point.

=back

=cut

sub SetBegin {
    # Get the parameters.
    my ($self, $newBegin) = @_;
    # Update the begin point.
    $self->{_beg} = $newBegin;
    # Adjust the length.
    $self->{_len} = $self->{_beg} - $self->{_end} + 1;
}

=head3 SetEnd

    $loc->SetEnd($newEnd);

Change the endpoint of this location without changing the begin point.

=over 4

=item newEnd

Proposed new ending point.

=back

=cut

sub SetEnd {
    # Get the parameters.
    my ($self, $newEnd) = @_;
    # Update the end point.
    $self->{_end} = $newEnd;
    # Adjust the length.
    $self->{_len} = $self->{_beg} - $self->{_end} + 1;
}

=head3 Widen

    my  = $loc->Widen($distance, $max);

Add the specified distance to each end of the location, taking care not to
extend past either end of the contig. The contig length must be provided
to insure we don't fall off the far end; otherwise, only the leftward
expansion is limited.

=over 4

=item distance

Number of positions to add to both ends of the location.

=item max (optional)

Maximum possible value for the right end of the location.

=back

=cut

sub Widen {
    # Get the parameters.
    my ($self, $distance, $max) = @_;
    # Subtract the distance from the end point.
    my $newEnd = BasicLocation::max(1, $self->EndPoint - $distance);
    $self->SetEnd($newEnd);
    # Add the distance to the begin point, keeping track of the maximum.
    my $newBegin = $self->Begin + $distance;
    if ($max && $newBegin > $max) {
        $newBegin = $max;
    }
    $self->SetBegin($newBegin);
}

=head3 Upstream

    my $newLoc = $loc->Upstream($distance, $max);

Return a new location upstream of the given location, taking care not to
extend past either end of the contig.

=over 4

=item distance

Number of positions to add to the front (upstream) of the location.

=item max (optional)

Maximum possible value for the right end of the location.

=item RETURN

Returns a new location object whose last position is next to the first
position of this location.

=back

=cut

sub Upstream {
    # Get the parameters.
    my ($self, $distance, $max) = @_;
    # Add the distance to the begin point, keeping the position safe.
    my $newBegin = $self->Begin + $distance;
    if ($max && $newBegin > $max) {
        $newBegin = $max;
    }
    # Compute the new length. It may be zero.
    my $len = $newBegin - $self->Begin;
    # Return the result.
    return BasicLocation->new($self->Contig, $newBegin, "-", $len);
}

=head3 Truncate

    $loc->Truncate($len);

Truncate the location to a new length. If the length is larger than the location length, then
the location is not changed.

=over 4

=item len

Proposed new length for the location.

=back

=cut

sub Truncate {
    # Get the parameters.
    my ($self, $len) = @_;
    # Only proceed if the new length would be shorter.
    if ($len < $self->Length) {
        $self->SetEnd($self->Begin - $len + 1);
    }
}

=head3 Adjacent

    my $okFlag = $loc->Adjacent($other);

Return TRUE if the other location is adjacent to this one, else FALSE. The other
location must have the same direction and start immediately after this location's
endpoint.

=over 4

=item other

BasicLocation object for the other location.

=item RETURN

Returns TRUE if the other location is an extension of this one, else FALSE.

=back

=cut

sub Adjacent {
    # Get the parameters.
    my ($self, $other) = @_;
    # Default to non-adjacent.
    my $retVal = 0;
    # Only proceed if the contigs and directions are the seme.
    if ($self->Dir eq $other->Dir && $self->Contig eq $other->Contig) {
        # Check the begin and end points.
        $retVal = ($self->EndPoint - 1 == $other->Begin);
    }
    # Return the determination indicator.
    return $retVal;
}

=head3 Combine

    $loc->Combine($other);

Combine another location with this one. The result will contain all bases in both
original locations. Both locations must have the same contig ID and direction.

=over 4

=item other

Other location to combine with this one.

=back

=cut

sub Combine {
    # Get the parameters.
    my ($self, $other) = @_;
    # If the other location ends past our end, move the endpoint.
    if ($other->EndPoint < $self->EndPoint) {
        $self->SetEnd($other->EndPoint);
    }
    # If the other location starts before our begin, move the begin point.
    if ($other->Begin > $self->Begin) {
        $self->SetBegin($other->Begin);
    }
}

=head3 NumDirection

    my $multiplier = $loc->NumDirection();

Return C<1> if this is a forward location, C<-1> if it is a backward location.

=cut

sub NumDirection {
    return -1;
}

=head3 Lengthen

    my  = $loc->Lengthen($distance, $max);

Add the specified distance to the end of the location, taking care not to
extend past either end of the contig. The contig length must be provided
to insure we don't fall off the far end; otherwise, only the leftward
expansion is limited.

=over 4

=item distance

Number of positions to add to the end of the location.

=item max (optional)

Maximum possible value for the right end of the location.

=back

=cut

sub Lengthen {
    # Get the parameters.
    my ($self, $distance, $max) = @_;
    # Subtract the distance from the end point, keeping track of the minimum.
    my $newEnd = $self->EndPoint - $distance;
    if ($newEnd <= 0) {
        $newEnd = 1;
    }
    $self->SetEnd($newEnd);
}

=head3 ExtendUpstream

    $loc->ExtendUpstream($distance, $max);

Extend the location upstream by the specified distance, taking care not
to go past either end of the contig.

=over 4

=item distance

Number of base pairs to extend upstream.

=item max

Length of the contig, used to insure we don't extend too far.

=back

=cut

sub ExtendUpstream {
    # Get the parameters.
    my ($self, $distance, $max) = @_;
    # Compute the new begin point.
    my $newBegin = BasicLocation::min($self->Begin + $distance, $max);
    # Update the location.
    $self->SetBegin($newBegin);
}


=head3 OverlapRegion

    my ($start, $len) = $loc->OverlapRegion($loc2);

Return the starting offset and length of the overlap region between this
location and a specified other location. Both regions must have the same
direction.

=over 4

=item loc2

Other location to check.

=item RETURN

Returns a two-element list consisting of the 0-based offset of the first
position within this location that the other location overlaps, and the number
of overlapping positions. If there is no overlap, the start offset comes back
undefined and the overlap length is 0.

=back

=cut

sub OverlapRegion {
    # Get the parameters.
    my ($self, $loc2) = @_;
    # Default to no overlap.
    my ($start, $len) = (undef, 0);
    # Check for types of overlap.
    if ($loc2->Begin > $self->Begin) {
        if ($loc2->EndPoint <= $self->Begin) {
            # Here the overlap starts at the beginning and goes to the end of
            # our region or the end of the other region, whichever comes first.
            $start = 0;
            $len = BasicLocation::min($self->Begin - $loc2->EndPoint + 1, $self->Length);
        }
    } elsif ($loc2->Begin >= $self->EndPoint) {
        # Here the overlap starts at the beginning of the other region and goes
        # to the end of our region or the end of the other region, whichever
        # comes first.
        $start = $self->Begin - $loc2->Begin;
        $len = BasicLocation::min($loc2->Begin - $self->EndPoint + 1, $loc2->Length);
    }
    # Return the results.
    return ($start, $len);
}

=head3 Gap

    my $flag = $loc->Gap($loc2);

Return the distance between the end of this location and the beginning of
the specified other location. This can be used as the gap distance when
doing an operon check.

=over 4

=item loc2

Specified other location. It is assumed both locations share the same
contig.

=item RETURN

Returns the number of bases downstream from the end of this location to the
beginning of the next one. If the next location begins upstream of this
location's end point, the returned value will be negative.

=back

=cut

sub Gap {
    # Get the parameters.
    my ($self, $loc2) = @_;
    # Declare the return variable.
    my $retVal = $self->EndPoint - $loc2->Begin;
    # Return the result.
    return $retVal;
}

=head3 Tail

    $loc->Tail($len)

Reduce the length of the location to the specified amount at the end
of the location's span.

=over 4

=item len

Length of the tail area to keep.

=back

=cut

sub Tail {
    # Get the parameters.
    my ($self, $len) = @_;
    # Move the begin point closer to the end.
    $self->{_beg} = $self->{_end} + $len - 1;
    $self->{_len} = $len;
}

1;
