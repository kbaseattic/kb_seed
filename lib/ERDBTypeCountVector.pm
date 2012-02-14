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

package ERDBTypeCountVector;

    use strict;
    use Tracer;
    use ERDB;
    use CGI;
    use base qw(ERDBType);

=head1 ERDB CountVector Descriptor Type Definition

=head2 Introduction

This object represents the data type for a vector of counts. The vector is
represented in the database as a long text string. To the user, it is represented
as a reference to a list of integers. Utility methods are provided for the most
common vector operations.

The vectors are expected to be sparse and biased toward low numbers. A simple
base-64 representation is used for the counts, with a null string representing
zero. The first character of a count is either a space (indicating 0), a plus (indicating 1),
or a minus (indicating -1, the only negative number allowed). If it is a space,
then there may be zero or more additional digits.

=head3 DIGITS

This is a constant containing the base64 digit string.

=cut

use constant DIGITS => '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_.';

=head3 new

    my $et = ERDBTypeCountVector->new();

Construct a new ERDBTypeCountVector descriptor.

=cut

sub new {
    # Get the parameters.
    my ($class) = @_;
    # Create the ERDBTypeCountVector object.
    my $retVal = { };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Virtual Methods

=head3 averageLength

    my $value = $et->averageLength();

Return the average length of a data item of this field type when it is stored in the
database. This value is used to compute the expected size of a database table.

=cut

sub averageLength {
    return 10000;
}

=head3 prettySortValue

    my $value = $et->prettySortValue();

Number indicating where fields of this type should go in relation to other
fields. The value should be somewhere between C<1> and C<5>. A value outside
that range will make terrible things happen.

=cut

sub prettySortValue() {
    return 5;
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
    if (! defined $value || ref $value ne 'ARRAY') {
        $retVal = "Value is not a list reference.";
    } else {
        my $errCount;
        for my $entry (@$value) {
            unless ($entry =~ /^\-?\d+$/) {
                $errCount++;
            }
        }
        if ($errCount) {
            $retVal = "$errCount invalid characters found.";
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
    # Convert the numbers to strings and join them together.
    my $retVal = join("", map { NumToString($_) } @$value);
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
    # We'll put the values found in here.
    my @retVal;
    # Loop through the string.
    while ($string =~ /([+\- ][^+\- ]*)/g) {
        push @retVal, StringToNum($1);
    }
    # Return the result.
    return \@retVal;
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
    my ($self, $dbh) = @_;
    my $retVal = "TEXT";
    if ($dbh->dbms eq 'mysql') {
        $retVal = "MEDIUMTEXT";
    }
    return $retVal;
}

=head3 indexMod

    my $length = $et->indexMod();

Return the index modifier for this field type. The index modifier is the number of
characters to be indexed. If it is undefined, the field cannot be indexed. If it
is an empty string, the entire field is indexed. The default is an empty string.

=cut

sub indexMod {
    return undef;
}

=head3 sortType

    my $letter = $et->sortType();

Return the sorting type for this field type. The sorting type is C<n> for integers,
C<g> for floating-point numbers, and the empty string for character fields.
The default is the empty string.

=cut

sub sortType {
    return "";
}

=head3 documentation

    my $docText = $et->documentation();

Return the documentation text for this field type. This should be in TWiki markup
format, though HTML will also work.

=cut

sub documentation() {
    return 'vector of counts';
}

=head3 name

    my $name = $et->name();

Return the name of this type, as it will appear in the XML database definition.

=cut

sub name() {
    return "countVector";
}

=head3 default

    my $defaultValue = $et->default();

Return the default value to be used for fields of this type if no default value
is specified in the database definition or in an L<ERDBLoadGroup/Put> call
during a loader operation. The default is undefined, which means an error will
be thrown during the load.

=cut

sub default {
    return '';
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
    # Display the number of values.
    my $retVal = "&lt;" . scalar(@$value) . "-vector&gt;";
    # Return the result.
    return $retVal;
}

=head2 Vector Manipulation Utilities

=head2 Internal Utilities

=head3 NumToString

    my $string = ERDBTypeCountVector::NumToString($number);

Convert an unsigned integer into a base-64 character string for encoding into a count
vector.

=over 4

=item number

Number to convert.

=item RETURN

Returns a (possibly null) string consisting of characters from the B<DIGITS> string
that represents the incoming number.

=back

=cut

sub NumToString {
    # Get the parameter.
    my ($number) = @_;
    # Declare the return variable.
    my $retVal;
    # Get a copy of the number.
    my $residual = $number;
    # Check for the specials.
    if ($residual == 0) {
        $retVal = " ";
    } elsif ($residual == -1) {
        $retVal = "-";
    } elsif ($residual == 1) {
        $retVal = "+";
    } else {
        # We'll store our digits in here.
        my @digits;
        # Loop until it's zero.
        while ($residual > 0) {
            # Get the last digit.
            push @digits, substr(DIGITS, $residual & 63, 1);
            # Shift it off.
            $residual >>= 6;
        }
        # Form the digits into a string.
        $retVal = " " . join("", @digits);
    }
    # Return the result.
    return $retVal;
}

=head3 StringToNum

    my $number = ERDBTypeCountVector::StringToNum($string);

Convert a base-64 character string into an unsigned integer for a count vector.

=over 4

=item string

(Possibly null) string to convert.

=item RETURN

Returns the number represented by the incoming string.

=back

=cut

sub StringToNum {
    # Get the parameter.
    my ($string) = @_;
    # We'll store the result in here.
    my $retVal = 0;
    # Check for the specials.
    if ($string eq ' ') {
        $retVal = 0;
    } elsif ($string eq '-') {
        $retVal = -1;
    } elsif ($string eq '+') {
        $retVal = 1;
    } else {
        # Loop through the string. Note that we ignore the space at the
        # front.
        for (my $i = length($string) - 1; $i > 0; $i--) {
            # Get the current digit.
            my $digit = substr($string, $i, 1);
            # Add it to the number result.
            $retVal = ($retVal << 6) + index(DIGITS, $digit);
        }
    }
    # Return the result.
    return $retVal;
}

=head3 VectorLength

    my $length = ERDBTypeCountVector::VectorLength($vector);

Return the length of a vector.

=over 4

=item vector

A count vector, represented as a reference to a list of unsigned integers.

=item RETURN

Returns a real number representing the length of the vector.

=cut

sub VectorLength {
    # Get the parameter.
    my ($vector) = @_;
    # Compute the sum of squares.
    my $retVal = 0;
    for my $value (@$vector) {
        if ($value == 1 || $value == -1) {
            $retVal++
        } elsif ($value != 0) {
            $retVal += $value * $value;
        }
    }
    # Return the square root.
    return sqrt($retVal);
}

=head3 DotProduct

    my $product = ERDBTypeCountVector::DotProduct($vector1, $vector2);

Compute the normalized dot product of the two incoming vectors. The result will be C<1>
if the vectors are parallel and C<0> if they are orthogonal.

=over 4

=item vector1

A count vector, represented as a reference to a list of unsigned integers.

=item vector2

Another count vector, represented as a reference to a list of unsigned integers.

=item RETURN

Returns a value between 0 and 1 that indicates the cosine of the angle between the
two vectors.

=back

=cut

sub DotProduct {
    # Get the parameters.
    my ($vector1, $vector2) = @_;
    # Compute the length of the shortest vector.
    my $len = scalar @$vector1;
    my $len2 = scalar @$vector2;
    if ($len2 < $len) {
        $len = $len2;
    }
    # Compute the sum of products.
    my $retVal = 0;
    for (my $i = 0; $i < $len; $i++) {
        $retVal += $vector1->[$i] * $vector2->[$i];
    }
    # Normalize the result.
    $retVal /= VectorLength($vector1) * VectorLength($vector2);
    # Return it.
    return $retVal;
}

1;
