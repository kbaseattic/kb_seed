# -*- perl -*-
#
# Copyright (c) 2003-2011 University of Chicago and Fellowship
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

package AnnotationGroup;

=head1 Annotation Group

An I<annotation group> is a list of related annotations. Each annotation in
the group relates to a single feature and in general they are all within the
same small timespan.

This object allows the client to create an annotation group by placing annotation 
tuples into it and then perform useful operations on the group.

The fields of this object are as follows:

=over 4

=item fid

ID of the feature to which the annotation group applies, or C<undef> if the
group is empty.

=item assignment

Text of any assignment made by an annotation in the group, or C<undef> if no
assignment is present.

=item list

List of the annotations in the group.

=item time0

Earliest timestamp in the group, or C<0> if the group is empty.

=back

=cut

	use strict;

=head2 Special Methods

=head3 new

	my $group = AnnotationGroup->new();

Create a new, empty annotation group.

=cut

sub new {
	# Get the parameters.
	my ($class) = @_;
	# Create the object.
	my $retVal = {
		fid => undef,
		assignment => undef,
		time0 => 0,
		list => []
	};
	# Bless and return it.
	bless $retVal, $class;
	return $retVal;
}

=head2 Public Methods

=head3 Read

	my ($fid, $time, $user, $data) = AnnotationGroup::Read($ih);

Read an annotation from an annotation file. The annotation consists of four parts.
Each of the first three components is on a line by itself. The data component is
terminated by a line containing only a pair of forward slashes (C<//>).

=over 4

=item ih

Open handle for the input annotation file.

=item RETURN

Returns a four-element list consisting of the feature ID, the time stamp (in seconds),
the user name, and the data string.

=back

=cut

sub Read {
	# Handle an object-oriented call.
	shift if UNIVERSAL::isa($_[0],__PACKAGE__); 
	# Get the parameters.
	my ($ih) = @_;
	# Declare the return variable.
	my @retVal;
	# Read the first three items.
	for (my $i = 0; $i < 3; $i++) {
		my $item = <$ih>;
		chomp $item;
		push @retVal, $item;
	}
	# Assemble the lines of the data item.
	my @lines;
	my $line = <$ih>;
	while (defined $line && $line ne "//\n") {
		push @lines, $line;
		$line = <$ih>;
	}
	push @retVal, join("", @lines);
	# Return the pieces of the annotation.
	return @retVal;
}

=head3 Add

	$group->Add($fid, $time, $user, $data);

Add the specified annotation to this annotation group. If this is the first
annotation in the group, the feature ID will be memorized. If it is a function
assignment, the function text will be memorized.

=over 4

=item fid

ID of the feature being annotated.

=item time

Time stamp for the annotation.

=item user

Name of the user who made the annotation.

=item data

Data string of the annotation.

=back

=cut

sub Add {
	# Get the parameters.
	my ($self, $fid, $time, $user, $data) = @_;
	# Find out if we need to memorize the feature ID.
	if (! defined $self->{fid}) {
		$self->{fid} = $fid;
	}
	# Is this an assignment?
	if ($data =~ /^Set\s+(master|FIG)\s+function\s+to\n(.+)/) {
		# Yes. Memorize the assignment text.
		$self->{assignment} = $2;
	}
	# Merge in the time. We want to keep the earliest.
	my $oldTime = $self->{time0};
	if (! $oldTime || $oldTime > $time) {
		$self->{time0} = $time;
	}
	# Store the annotation in the annotation list.
	push @{$self->{list}}, [$fid, $time, $user, $data];
}

=head3 fid

	my $fid = $group->fid;

Return the feature ID relevant to this annotation group.

=cut

sub fid {
	return $_[0]->{fid};
}

=head3 assignment

	my $assignment = $group->assignment;

Return the assignment (if any) for this annotation group.

=cut

sub assignment {
	return $_[0]->{assignment};
}

=head3 time0

	my $time0 = $group->time0;

Return the earliest time for any annotation in the group.

=cut

sub time0 {
	return $_[0]->{time0};
}

=head3 count

	my $count = $group->count;

Return the number of annotations in this group.

=cut

sub count {
	return scalar @{$_[0]->{list}};
}

=head3 annotation

	my ($fid, $time, $user, $data) = $group->annotation($idx);

Return the annotation in the specified position of the annotation group.

=over 4

=item idx

Index (0-based) of the desired annotation to retrieve from the annotation group's
annotation list.

=item RETURN

Returns a four-element list consisting of the feature ID, the time stamp (in seconds),
the user name, and the data string. If the index is out of bounds, will return an
empty list.

=back

=cut

sub annotation {
	# Get the parameters.
	my ($self, $idx) = @_;
	# Declare the return variable.
	my @retVal;
	# Get the annotation list.
	my $list = $self->{list};
	# Is the index in range?
	if ($idx >= 0 && $idx < @$list) {
		# Extract the annotation requested.
		@retVal = @{$list->[$idx]};
	}
	# Return the annotation found.
	return @retVal;
}

1;