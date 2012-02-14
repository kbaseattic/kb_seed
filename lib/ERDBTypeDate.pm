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

package ERDBTypeDate;

    use strict;
    use Tracer;
    use ERDB;
    use Time::Local qw(timelocal_nocheck);
    use POSIX qw(strftime);
    use base qw(ERDBType);
    
    use constant MONTHS => [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

=head1 ERDB Date Type Definition

=head2 Introduction

This object represents the primitive data type for dates. Dates are stored as a
whole number of seconds since the Unix epoch, which was midnight on January 1,
1970 UCT. Dates prior to 1970 are negative numbers, but bad things happen if you
try to go back beyond 1800, because of the calendar conversions in the 18th
century.

As a convenience, if a date is specified as a string of the style
C<mm/dd/yy hh:mm:ss>, it will be converted from the local time to the internal
representation. (The hours must be in military time-- 0 to 24.) There is no
corresponding conversion on the way out.

=head3 new

    my $et = ERDBTypeDate->new();

Construct a new ERDBTypeDate descriptor.

=cut

sub new {
    # Get the parameters.
    my ($class) = @_;
    # Create the ERDBTypeDate object.
    my $retVal = { };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 parseDate

    my ($y, $mo, $d, $h, $mi, $s) = $et->parseDate($string);

Parse the string into the constituent date components: month, day, year,
hour, minute, second. The pieces are not validated in any meaningful way,
but if the date won't parse, an empty list will be returned.

=over 4

=item string

Input string representing a date. It must in in a standard C<mm/dd/yy hh:mm:ss>
format with a 24-hour clock.

=item RETURN

Returns the six components of a time stamp, in order from largest significance
to smallest significance.

=back

=cut

sub parseDate {
    # Get the parameters.
    my ($self, $string) = @_;
    # Declare the return variables.
    my ($y, $mo, $d, $h, $mi, $s);
    # Parse the string. Note that the time and the seconds are optional.
    # The constructs that make them conditional use the clustering operator
    # (?:) so that they don't interfere in the grouping results.
    if ($string =~ m#^\s*(\d+)/(\d+)/(\d+)(?:\s+(\d+):(\d+)(?::(\d+))?)?\s*$#) {
        # Extract the pieces of the time stamp. Note that the hours, minutes,
        # and seconds all default to 0 if they weren't found.
        ($mo, $d, $y, $h, $mi, $s) = ($1, $2, $3, $4 || 0, $5 || 0, $6 || 0);
    }
    # Return the results.
    return ($y, $mo, $d, $h, $mi, $s);
}

=head2 Virtual Methods

=head3 averageLength

    my $value = $et->averageLength();

Return the average length of a data item of this field type when it is stored in the
database. This value is used to compute the expected size of a database table.

=cut

sub averageLength {
    return 8;
}

=head3 prettySortValue

    my $value = $et->prettySortValue();

Number indicating where fields of this type should go in relation to other
fields. The value should be somewhere between C<1> and C<5>. A value outside
that range will make terrible things happen.

=cut

sub prettySortValue() {
    return 1;
}

=head3 validate

    my $okFlag = $et->validate($value);

Return an error message if the specified value is invalid for this field type.

The parameters are as follows.

=over 4

=item value

Value of this type, for validation.

=item RETURN

Returns an empty string if the specified field is valid, and an error message
otherwise.

=back

=cut

sub validate {
    # Get the parameters.
    my ($self, $value) = @_;
    # Assume it's valid until we prove otherwise.
    my $retVal = "";
    if ($value =~ m/^[+-]?\d+$/) {
        # Here the value is a number, so we just need to verify that
        # it will fit. No sane date will ever fail this check.
        if ($value > 9223372036854775807 || $value < -9223372036854775807) {
            $retVal = "Date number is out of range.";
        }
    } else {
        # Here we have to have a date string. Parse it and complain if it
        # won't parse.
        my ($y, $mo, $d, $h, $mi, $s) = $self->parseDate($value);
        if (! defined $y) {
            $retVal = "Date has an invalid format.";
        } else {
            # Validate the individual pieces of the date.
            if ($y > 99 && $y < 1800) {
                $retVal = "Dates cannot be prior to 1800.";
            } elsif ($mo < 1 || $mo > 12) {
                $retVal = "Date has an invalid month."
            } elsif ($d < 1 || $d > MONTHS->[$mo]) {
                $retVal = "Date has an invalid day of month.";
            } elsif ($d == 29 && $mo == 2 &&
                     ($y % 4 != 0 || $y % 100 == 0 && $y % 400 != 0)) {
                $retVal = "Date is for February 29 in a non-leap year.";
            } elsif ($h >= 24) {
                $retVal = "Date has an invalid hour number.";
            } elsif ($mi >= 60) {
                $retVal = "Date has an invalid minute number.";
            } elsif ($s >= 60) {
                $retVal = "Date has an invalid second number.";
            }
        }
    }
    # Return the determination.
    return $retVal;
}

=head3 encode

    my $string = $et->encode($value, $mode);

Encode a value of this field type for storage in the database (or in a database load
file.)

The parameters are as follows.

=over 4

=item value

Value of this type, for encoding.

=item mode

TRUE if the value is being encoding for placement in a load file, FALSE if it
is being encoded for use as an SQL statement parameter. In most cases, the
encoding is the same for both modes.

=back

=cut

sub encode {
    # Get the parameters.
    my ($self, $value, $mode) = @_;
    # Declare the return variable.
    my $retVal = $value;
    # Is it a date string?
    my ($y, $mo, $d, $h, $mi, $s) = $self->parseDate($value);
    if (defined $y) {
        # Yes. Convert it from local time.
        $retVal = timelocal_nocheck($s, $mi, $h, $d-1, $mo-1, $y);
    }
    # Return the result.
    return $retVal;
}

=head3 decode

    my $value = $et->decode($string);

Decode a string from the database into a value of this field type.

The parameters are as follows.

=over 4

=item string

String from the database to be decoded.

=item RETURN

Returns a value of the desired type.

=back

=cut

sub decode {
    # Get the parameters.
    my ($self, $string) = @_;
    # Declare the return variable.
    my $retVal = $string;
    # Return the result.
    return $retVal;
}

=head3 sqlType

    my $typeString = $et->sqlType($dbh);

Return the SQL data type for this field type.

=over 4

=item dbh

Open L<DBKernel> handle for the database in question. This is used when the
datatype may be different depending on the DBMS used.

=item RETURN

Returns the datatype string to be used when creating a field of this type in
an SQL table.

=back

=cut

sub sqlType {
    return "BIGINT";
}

=head3 indexMod

    my $length = $et->indexMod();

Return the index modifier for this field type. The index modifier is the number of
characters to be indexed. If it is undefined, the field cannot be indexed. If it
is an empty string, the entire field is indexed. The default is an empty string.

=cut

sub indexMod {
    return '';
}

=head3 sortType

    my $letter = $et->sortType();

Return the sorting type for this field type. The sorting type is C<n> for integers,
C<g> for floating-point numbers, and the empty string for character fields.
The default is the empty string.

=cut

sub sortType {
    return "n";
}

=head3 documentation

    my $docText = $et->documentation();

Return the documentation text for this field type. This should be in TWiki markup
format, though HTML will also work.

=cut

sub documentation() {
    return 'Date and time stamp, in seconds since 1970.';
}

=head3 name

    my $name = $et->name();

Return the name of this type, as it will appear in the XML database definition.

=cut

sub name() {
    return "date";
}

=head3 default

    my $defaultValue = $et->default();

Default value to be used for fields of this type if no default value is
specified in the database definition or in an L<ERDBLoadGroup/Put>
call during a loader operation. The default is undefined, which means
an error will be thrown during the load.

=cut

sub default {
    return time;
}

=head3 align

    my $alignment = $et->align();

Return the display alignment for fields of this type: either C<left>, C<right>, or
C<center>. The default is C<left>.

=cut

sub align {
    return 'left';
}

=head3 html

    my $html = $et->html($value);

Return the HTML for displaying the content of a field of this type in an output
table. The default is the raw value, html-escaped.

=cut

sub html {
    my ($self, $value) = @_;
    # Break the time into its component parts.
    my @times = localtime($value);
    # Convert them to a string.
    my $retVal = strftime("%m/%d/%Y %H:%M:%S", @times);
    # Return the result.
    return $retVal;
}


1;
