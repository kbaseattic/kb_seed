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

#
# This is a SAS component.
#

package BasicLocation;

    use strict;

=head1 Basic Location Object

=head2 Introduction

A I<basic location> defines a region of a contig. Because of the way genetic features
work, a basic location has a direction associated with it. The traditional method for encoding
a basic location is to specify the contig ID, the starting offset, and the ending offset. If the
start is before the end, we have a forward basic location, and if the start is after the end, we
have a backward basic location.

=over 4

=item C<RED_1_400>

is the first 400 nucleotides of the RED contig, processed forward.

=item C<NC_000913_500_401>

is a 100-nucleotide region in NC_000913 that is processed backward from the 500th nucleotide.

=back

Note that even though they are called "offsets", location indices are 1-based.
Note also that the possibility of an underscore in the contig ID makes the parsing a little
tricky.

The databases use a slightly different format designed to allow for the possibility of
zero-length regions. Instead of a starting and ending position, we specify the start position,
the direction (C<+> or C<->), and the length. The Sprout versions of the two example locations
above are C<RED_1+400> (corresponds to C<RED_1_400>), and C<NC_000913_500-100> (corresponds
to C<NC_000913_500_401>).

Working with the raw location string is difficult because it can have one of two formats
and it is constantly necessary to ask if the location is forward or backward. The basic location
object seeks to resolve these differences by providing a single interface that can be
used regardless of the format or direction.


=head2 Public Methods

=head3 new

    my $loc = BasicLocation->new($locString);

Construct a basic location from a location string. A location string has the form
I<contigID>C<_>I<begin>I<dir>I<len> where I<begin> is the starting position,
I<dir> is C<+> for a forward transcription or C<-> for a backward transcription,
and I<len> is the length. So, for example, C<1999.1_NC123_4000+200> describes a
location beginning at position 4000 of contig C<1999.1_NC123> and ending at
position 4199. Similarly, C<1999.1_NC123_2000-400> describes a location in the
same contig starting at position 2000 and ending at position 1601.

=over 4

=item locString

Location string, as described above.

=back

    my $loc = BasicLocation->new($location, $contigID);

Construct a location by copying another location and plugging in a new contig ID.

=over 4

=item location

Location whose data is to be copied.

=item contigID (optional)

ID of the new contig to be plugged in.

=back

    my $loc = BasicLocation->new($tuple);

Construct a location from a database location tuple. A database location specification
consists of a contig ID, a leftmost location, a direction, and a length.

=over 4

=item tuple

A 4-tuple consisting of (0) a contig ID, (1) the leftmost point of the location,
(2) the direction (C<+> or C<->), and (3) the length.

=back

    my $loc = BasicLocation->new($contigID, $beg, $dir, $len);

Construct a location from specific data elements, in particular the contig ID, the starting
offset, the direction, and the length.

=over 4

=item contigID

ID of the contig on which the location occurs.

=item beg

Starting offset of the location.

=item dir

Direction of the location: C<+> for a forward location and C<-> for a backward location. If
C<_> is specified instead, it will be presumed that the fourth argument is an endpoint and not
a length.

=item len

Length of the location. If the direction is an underscore (C<_>), it will be the endpoint
instead of the length.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, @p) = @_;
    require BBasicLocation;
    require FBasicLocation;
    # Declare the data variables.
    my ($contigID, $beg, $dir, $len, $end);
    # Determine the signature type.
    if (@p >= 4) {
        # Here we have specific incoming data.
        ($contigID, $beg, $dir, $len) = @p;
    } elsif (UNIVERSAL::isa($p[0],__PACKAGE__)) {
        # Here we have a source location and possibly a new contig ID.
        $contigID = (defined $p[1] ? $p[1] : $p[0]->{_contigID});
        ($beg, $dir, $len) = ($p[0]->{_beg}, $p[0]->{_dir}, $p[0]->{_len});
    } elsif (ref $p[0] eq 'ARRAY') {
        # Here we have a database location tuple.
        ($contigID, $beg, $dir, $len) = @{$p[0]};
        # Adjust the beginning if this is on the - strand.
        if ($dir eq '-') {
            $beg = $beg + $len - 1;
        }
    } else {
        # Here we have a source string.
        $p[0] =~ /^(.+)_(\d+)(\+|\-|_)(\d+)$/;
        ($contigID, $beg, $dir, $len) = ($1, $2, $3, $4);
    }
    # Determine the format.
    if ($dir eq '_') {
        # Here we have the old format. The endpoint was parsed as the length.
        $end = $len;
        # Compare the start and end to get the direction and compute the true length.
        if ($beg > $end) {
            ($dir, $len) = ('-', $beg - $end + 1);
        } else {
            ($dir, $len) = ('+', $end - $beg + 1);
        }
    } else {
        # Here we have the new format. We compute the endpoint
        # from the direction.
        $end = (($dir eq '+') ? $beg + $len - 1 : $beg - $len + 1);
    }
    # Create the return structure.
    my $retVal = { _contigID => $contigID, _beg => $beg, _dir => $dir,
                   _end => $end, _len => $len };
    # Bless the location with the appropriate package name.
    if ($dir eq '+') {
        bless $retVal, "FBasicLocation";
    } else {
        bless $retVal, "BBasicLocation";
    }
    # Return the blessed object.
    return $retVal;
}

=head3 ListBounds

    my ($left, $right) = BasicLocation::ListBounds(@contigLocs);

Find the left and right bounds of the locations in the specified list. It
is assumed they are all for the same contig.

=over 4

=item contigLocs

List of B<BasicLocation> objects to be scanned.

=item RETURN

Returns a two-element list. The first element is the position on the contig
of the leftmost point in all the locations and the second element is the
position of the rightmost point.

=back

=cut

sub ListBounds {
    # Get the parameters. The first location is used to prime the loop.
    my ($loc1, @contigLocs) = @_;
    my $left = $loc1->Left;
    my $right = $loc1->Right;
    # Loop through the other locations.
    for my $loc (@contigLocs) {
        # Merge in this location.
        my $newLeft = $loc->Left;
        my $newRight = $loc->Right;
        if ($newLeft < $left) {
            $left = $newLeft;
        }
        if ($newRight > $right) {
            $right = $newRight;
        }
    }
    # Return the results.
    return ($left, $right);
}


=head3 Contig

    my $contigID = $loc->Contig;

Return the location's contig ID.

=cut

sub Contig {
    return $_[0]->{_contigID};
}

=head3 Begin

    my $beg = $loc->Begin;

Return the location's starting offset.

=cut

sub Begin {
    return $_[0]->{_beg};
}

=head3 Dir

    my $dirChar = $loc->Dir;

Return the location's direction: C<+> for a forward location and C<-> for a backward one.

=cut

sub Dir {
    return $_[0]->{_dir};
}

=head3 Length

    my $len = $loc->Length;

Return the location's length (in nucleotides).

=cut

sub Length {
    return $_[0]->{_len};
}

=head3 EndPoint

    my $offset = $loc->EndPoint;

Return the location's ending offset.

=cut

sub EndPoint {
    return $_[0]->{_end};
}

=head3 Parent

    my $parentLocation = $loc->Parent;

Return the full location containing this basic location (if any).

=cut

sub Parent {
    return $_[0]->{_parent};
}

=head3 Index

    my $idx = $loc->Index;

Return the index of this basic location inside the parent location (if any).

=cut

sub Index {
    return $_[0]->{_idx};
}

=head3 String

    my $string = $loc->String;

Return a Sprout-format string representation of this location.

=cut

sub String {
    my ($self) = @_;
    return $self->{_contigID} . "_" . $self->{_beg} . $self->{_dir} . $self->{_len};
}

=head3 SeedString

    my $string = $loc->SeedString;

Return a SEED-format string representation of this location.

=cut

sub SeedString {
    my ($self) = @_;
    return $self->{_contigID} . "_" . $self->{_beg} . "_" . $self->{_end};
}

=head3 IfValid

    my $distance = $loc->IfValid($distance);

Return a distance if it is a valid offset inside this location, and an undefined value otherwise.

=over 4

=item distance

Relevant distance inside this location.

=item RETURN

Returns the incoming distance if it is non-negative and less than the location length, and an
undefined value otherwise.

=back

=cut

sub IfValid {
    # Get the parameters.
    my ($self, $distance) = @_;
    # Return the appropriate result.
    return (($distance >= 0 && $distance < $self->{_len}) ? $distance : undef);
}

=head3 Cmp

    my $compare = BasicLocation::Cmp($a, $b);

Compare two locations.

The ordering principle for locations is that they are sorted first by contig ID, then by
leftmost position, in reverse order by length, and then by direction. The effect is that
within a contig, the locations are ordered first and foremost in the way they would
appear when displayed in a picture of the contig and second in such a way that embedded
locations come after the locations in which they are embedded. In the case of two
locations that represent the exact same base pairs, the forward (C<+>) location is
arbitrarily placed first.

=over 4

=item a

First location to compare.

=item b

Second location to compare.

=item RETURN

Returns a negative number if the B<a> location sorts first, a positive number if the
B<b> location sorts first, and zero if the two locations are the same.

=back

=cut

sub Cmp {
    # Get the parameters.
    my ($a, $b) = @_;
    # Compare the locations.
    my $retVal = ($a->Contig cmp $b->Contig);
    if ($retVal == 0) {
        $retVal = ($a->Left <=> $b->Left);
        if ($retVal == 0) {
            $retVal = ($b->Length <=> $a->Length);
            if ($retVal == 0) {
                $retVal = ($a->Begin <=> $b->Begin);
            }
        }
    }
    # Return the result.
    return $retVal;
}

=head3 Matches

    my $flag = BasicLocation::Matches($locA, $locB);

Return TRUE if the two locations contain the same data, else FALSE. Augment data is included
in the comparison.

=over 4

=item locA, locB

Locations to compare.

=item RETURN

Returns TRUE if the two locations contain the same data, else FALSE.

=back

=cut

sub Matches {
    # Get the parameters.
    my ($locA, $locB) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Verify that the major data items are the same.
    if ($locA->Contig eq $locB->Contig && $locA->Begin eq $locB->Begin &&
        $locA->Dir eq $locB->Dir && $locA->Length == $locB->Length) {
        # Here the locations are the same, so we need to check augment data.
        # First, we loop through all the augment keys in the A location.
        my @aKeys = grep { /^[^_]/ } keys %{$locA};
        # Assume we have a match until we find a mis-match.
        $retVal = 1;
        for (my $i = 0; $i <= $#aKeys && $retVal; $i++) {
            my $aKey = $aKeys[$i];
            $retVal = ((exists $locB->{$aKey}) && ($locA->{$aKey} eq $locB->{$aKey}));
        }
        # If we're still matching, verify that B doesn't have any
        # keys not in A.
        my @bKeys = keys %{$locB};
        for (my $i = 0; $i <= $#bKeys && $retVal; $i++) {
            $retVal = exists $locA->{$bKeys[$i]};
        }
    }
    # Return the result.
    return $retVal;
}

=head3 FixContig

    $loc->FixContig($genomeID);

Insure the genome ID is included in the Contig string. Some portions of the system
store the contig ID in the form I<genome>C<:>I<contig>, while some use only the contig ID.
If this location's contig ID includes a genome ID, nothing will happen, but if it does
not, the caller-specified genome ID will be prefixed to the contig string.

=over 4

=item genomeID

ID of the genome for this location's contig.

=back

=cut

sub FixContig {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Check the contig string for the presence of a genome ID.
    my $contigID = $self->{_contigID};
    if ($contigID !~ /:/) {
        # There's no colon, so we have to prefix the genome ID.
        $self->{_contigID} = "$genomeID:$contigID";
    }
}

=head3 Parse

    my ($contig, $beg, $end) = BasicLocation::Parse($locString);

Parse a location string and return the contig ID, start position, and end position.

=over 4

=item locString

Location string to parse. It may be either Sprout-style or SEED-style.

=item RETURN

Returns the contig ID, start position, and end position as a three-element list.

=back

=cut

sub Parse {
    # Get the parameters.
    my ($locString) = @_;
    # Create a location object from the string.
    my $loc = BasicLocation->new($locString);
    # Return the desired data.
    return ($loc->Contig, $loc->Begin, $loc->EndPoint);
}

=head3 OverlapLoc

    my $len = $loc->OverlapLoc($loc2);

Determine how many positions in this location overlap the specified other location.

=over 4

=item loc2

L<BasicLocation> object to check for overlap.

=item RETURN

Returns the number of overlapping positions, or 0 if there is no overlap (which is automatically the case if the
locations are on different contigs.

=back

=cut

sub OverlapLoc {
    # Get the parameters.
    my ($self, $loc2) = @_;
    # Declare the return variable,
    my $retVal = 0;
    # Check for a contig match.
    if ($self->Contig eq $loc2->Contig) {
        # The contigs match, so check for overlap.
        $retVal = $self->Overlap($loc2->Left, $loc2->Right);
    }
    # Return the result.
    return $retVal;
}


=head3 Overlap

    my $len = $loc->Overlap($b,$e);

Determine how many positions in this location overlap the specified region. The region is defined
by its leftmost and rightmost positions.

=over 4

=item b

Leftmost position in the region to check.

=item e

Rightmost position in the region to check.

=item RETURN

Returns the number of overlapping positions, or 0 if there is no overlap.

=back

=cut

sub Overlap {
    # Get the parameters.
    my ($self, $b, $e) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the type of overlap.
    if ($b < $self->Left) {
        # Here the other region extends to our left.
        if ($e >= $self->Left) {
            # The other region's right is past our left, so we have overlap. The overlap length
            # is determined by whether or not we are wholly inside the region.
            if ($e < $self->Right) {
                $retVal = $e - $self->Left + 1;
            } else {
                $retVal = $self->Length;
            }
        } else {
            # The other region ends before we start, so no overlap.
            $retVal = 0;
        }
    } elsif ($b > $self->Right) {
        # The other region starts after we end, so no overlap.
        $retVal = 0;
    } else {
        # The other region starts inside us.
        $retVal = $self->Right - $b + 1;
    }
    # Return the result.
    return $retVal;
}

=head3 Merge

    $loc->Merge($loc2);

Merge another location into this one. The result will include all bases in both
locations and will have the same direction as this location. It is assumed both
locations share the same contig.

=over 4

=item loc2

Location to merge into this one.

=back

=cut

sub Merge {
    # Get the parameters.
    my ($self, $loc2) = @_;
    # Get a copy of the other location.
    my $other = BasicLocation->new($loc2);
    # Fix the direction so it matches.
    if ($self->Dir ne $other->Dir) {
        $other->Reverse;
    }
    # Combine the other location with this one.
    $self->Combine($other);
}

=head2 Virtual Methods

=head3 Left

    my $leftPoint = $loc->Left;

Return the offset of the leftmost point of the location.

=head3 Right

    my $rightPoint = $loc->Right;

Return the offset of the rightmost point of the location.

=head3 Compare

    my ($distance, $cmp) = $loc->Compare($point);

Determine the relative location of the specified point on the contig. Returns a distance,
which indicates the location relative to the leftmost point of the contig, and a comparison
number, which is negative if the point is to the left of the location, zero if the point is
inside the location, and positive if the point is to the right of the location.

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

=head3 Reverse

    $loc->Reverse;

Change the polarity of the location. The location will have the same nucleotide range, but
the direction will be changed.

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

=head3 SetBegin

    $loc->SetBegin($newBegin);

Change the begin point of this location without changing the endpoint.

=over 4

=item newBegin

Proposed new beginning point.

=back

=head3 SetEnd

    $loc->SetEnd($newEnd);

Change the endpoint of this location without changing the begin point.

=over 4

=item newEnd

Proposed new ending point.

=back

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

=head3 Truncate

    $loc->Truncate($len);

Truncate the location to a new length. If the length is larger than the location length, then
the location is not changed.

=over 4

=item len

Proposed new length for the location.

=back

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

=head3 Combine

    $loc->Combine($other);

Combine another location with this one. The result will contain all bases in both
original locations. Both locations must have the same contig ID and direction.

=over 4

=item other

Other location to combine with this one.

=back

=head3 NumDirection

    my $multiplier = $loc->NumDirection();

Return C<1> if this is a forward location, C<-1> if it is a backward location.

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

=head3 Tail

    $loc->Tail($len)

Reduce the length of the location to the specified amount at the end
of the location's span.

=over 4

=item len

Length of the tail area to keep.

=back

=cut


## max and min
##
## Rather than take them from FIG or Tracer, these methods are stored here to make the
## package self-contained.

sub max {
    my ($a, $b) = @_;
    return ($a > $b ? $a : $b);
}

sub min {
    my ($a, $b) = @_;
    return ($a < $b ? $a : $b);
}


1;
