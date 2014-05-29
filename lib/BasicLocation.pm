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
    use FBasicLocation;
    use BBasicLocation;

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

The Sprout uses a slightly different format designed to allow for the possibility of
zero-length regions. Instead of a starting and ending position, we specify the start position,
the direction (C<+> or C<->), and the length. The Sprout versions of the two example locations
above are C<RED_1+400> (corresponds to C<RED_1_400>), and C<NC_000913_500-100> (corresponds
to C<NC_000913_500_401>).

Working with the raw location string is difficult because it can have one of two formats
and it is constantly necessary to ask if the location is forward or backward. The basic location
object seeks to resolve these differences by providing a single interface that can be
used regardless of the format or direction.

It is frequently useful to keep additional data about a basic location while it is being passed
around. The basic location object is a PERL hash, and this additional data is kept in the object
by adding hash keys. The internal values used by the object have keys preceded by an
underscore, so any keys not beginning with underscores are considered to be additional
values. The additional values are called I<augments>.

When a basic location is in its string form, the augments can be tacked on using parentheses
enclosing a comma-delimited list of assignments. For example, say we want to describe
the first 400 base pairs in the contig B<RED>, and include the fact that it is the second
segment of feature B<fig|12345.1.peg.2>. We could use the key C<fid> for the feature ID and
C<idx> for the segment index (0-based), in which case the location string would be

    RED_1+400(fid=fig|12345.1.peg.2,idx=1)

When this location string is converted to a location object in the variable C<$loc>, we
would have

    $loc->{fig} eq 'fig|12345.1.peg.2'
    $loc->{idx} == 1

Spaces can be added for readability. The above augmented location string can also be
coded as

    RED_1+400(fid = fig|12345.1.peg.2, idx = 1)

A basic location is frequently part of a full location. Full locations are described by the
B<FullLocation> object. A full location is a list of basic locations associated with a genome
and a FIG-like object. If the parent full location is known, we can access the basic location's
raw DNA. To construct a basic location that is part of a full location, we add the parent full
location and the basic location's index to the constructor. In the constructor below,
C<$parent> points to the parent full location.

    my $secondLocation = BasicLocation->new("RED_450+100", $parent, 1);

=cut

=head2 Public Methods

=head3 new

    my $loc = BasicLocation->new($locString, $parentLocation, $idx);

Construct a basic location from a location string. A location string has the form
I<contigID>C<_>I<begin>I<dir>I<len> where I<begin> is the starting position,
I<dir> is C<+> for a forward transcription or C<-> for a backward transcription,
and I<len> is the length. So, for example, C<1999.1_NC123_4000+200> describes a
location beginning at position 4000 of contig C<1999.1_NC123> and ending at
position 4199. Similarly, C<1999.1_NC123_2000-400> describes a location in the
same contig starting at position 2000 and ending at position 1601.

Augments can be specified as part of the location string using parentheses and
a comma-delimited list of assignments. For example, the following constructor
creates a location augmented by a feature ID called C<fid> and an index value
called C<idx>.

    my $loc = BasicLocation->new("NC_000913_499_400(fid = fig|83333.1.peg.10, idx => 2)");

All fields internal to the location object have names beginning with an
underscore (C<_>), so as long as the value name begins with a letter,
there should be no conflict.

=over 4

=item locString

Location string, as described above.

=item parentLocation (optional)

Full location that this basic location is part of (if any).

=item idx (optional)

Index of this basic location in the parent full location.

=back

    my $loc = BasicLocation->new($location, $contigID);

Construct a location by copying another location and plugging in a new contig ID.

=over 4

=item location

Location whose data is to be copied.

=item contigID (optional)

ID of the new contig to be plugged in.

=back

    my $loc = BasicLocation->new($contigID, $beg, $dir, $len, $augments, $parentLocation, $idx);

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

=item augments (optional)

Reference to a hash containing any augment values for the location.

=item parentLocation (optional)

Full location that this basic location is part of (if any).

=item idx (optional)

Index of this basic location in the parent full location.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, @p) = @_;
    # Declare the data variables.
    my ($contigID, $beg, $dir, $len, $end, $parent, $idx, $augments, $augmentString);
    # Determine the signature type.
    if (@p >= 4) {
        # Here we have specific incoming data.
        ($contigID, $beg, $dir, $len, $augments, $parent, $idx) = @p;
    } elsif (UNIVERSAL::isa($p[0],__PACKAGE__)) {
        # Here we have a source location and possibly a new contig ID.
        $contigID = (defined $p[1] ? $p[1] : $p[0]->{_contigID});
        ($beg, $dir, $len) = ($p[0]->{_beg}, $p[0]->{_dir}, $p[0]->{_len});
        if (exists $p[0]->{_parent}) {
            ($parent, $idx) = ($p[0]->{_parent}, $p[0]->{_idx});
        }
        # Get the augments (if any) from the source location. We want these
        # copied to the new location.
        $augments = { };
        for my $key (keys %{$p[0]}) {
            if (substr($key, 0, 1) ne '_') {
                $augments->{$key} = $p[0]->{$key};
            }
        }
    } else {
        # Here we have a source string and possibly augments. We first parse
        # the source string.
        $p[0] =~ /^(.+)_(\d+)(\+|\-|_)(\d+)($|\(.*\)$)/;
        ($contigID, $beg, $dir, $len, $augmentString) = ($1, $2, $3, $4, $5);
        # Check for augments.
        if ($augmentString) {
            # Here we have an augment string. First, we strip the enclosing
            # parentheses.
            $augmentString = substr $augmentString, 1, length($augmentString) - 2;
            # Now we parse out the assignments and put them in a hash.
            my %augmentHash = map { split /\s*,\s*/, $_ } split /\s*=\s*/, $augmentString;
            $augments = \%augmentHash;
        }
        # Pull in the parent location and index, if applicable.
        ($parent, $idx) = ($p[1], $p[2]);
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
                   _end => $end, _len => $len, _parent => $parent,
                   _idx => $idx };
    # Add the augments.
    if ($augments) {
        for my $key (keys %{$augments}) {
            $retVal->{$key} = $augments->{$key};
        }
    }
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

=head3 AugmentString

    my $string = $loc->AugmentString;

Return a Sprout-format string representation of this location with augment data
included. The augment data will be appended as a comma-delimited list of assignments
enclosed in parentheses, the exact format expected by the single-argument location object
constructor L</new>.

=cut

sub AugmentString {
    # Get this instance.
    my ($self) = @_;
    # Get the pure location string.
    my $retVal = $self->String;
    # Create the augment string. We build it from all the key-value pairs in the hash
    # for which the key does not being with an underscore.
    my @augmentStrings = ();
    for my $key (sort keys %{$self}) {
        if (substr($key,0,1) ne "_") {
            push @augmentStrings, "$key = " . $self->{$key};
        }
    }
    # If any augments were found, we concatenate them to the result string.
    if (@augmentStrings > 0) {
        $retVal .= "(" . join(", ", @augmentStrings) . ")";
    }
    # Return the result.
    return $retVal;
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

=head3 Attach

    my  = $loc->Attach($parent, $idx);

Point this basic location to a parent full location. The basic location will B<not> be
inserted into the full location's data structures.

=over 4

=item parent

Parent full location to which this location should be attached.

=item idx

Index of this location in the full location.

=back

=cut

sub Attach {
    # Get the parameters.
    my ($self, $parent, $idx) = @_;
    # Save the parent location and index in our data structures.
    $self->{_idx} = $idx;
    $self->{_parent} = $parent;
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
