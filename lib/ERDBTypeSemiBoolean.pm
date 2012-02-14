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

package ERDBTypeSemiBoolean;

    use strict;
    use Tracer;
    use ERDB;
    use CGI qw(-nosticky);
    use base qw(ERDBType);

=head1 ERDB Ternary Value Type Definition

=head2 Introduction

This data type allows a ternary boolean value: Yes, No, or Unknown. The value is
represented as a single character-- C<N>, C<Y>, or C<?>. The type sorts with the
unknown value first, then NO, then YES.

=head2 Public Methods

=head3 new

    my $et = ERDBTypeSemiBoolean->new();

Construct a new ERDBTypeSemiBoolean descriptor.

=cut

sub new {
    # Get the parameters.
    my ($class) = @_;
    # Create the ERDBTypeSemiBoolean object.
    my $retVal = { };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 ComputeFromString

    my $char = ERDBTypeSemiBoolean::ComputeFromString($string);

Compute a ternary value from a string. C<1>, C<y>, C<t>, C<true> and C<yes>
all become C<Y>. C<0>, C<n>, C<f>, and C<false> all become C<N>. Anything
else (including an undefined value) becomes a question mark. The process is
entirely case-insensitive.

=over 4

=item string

String to convert to a ternary value.

=item RETURN

A single-character ternary value computed from a string.

=back

=cut

sub ComputeFromString {
    # Get the parameters.
    my ($string) = @_;
    # Default the return value to "?".
    my $retVal = "?";
    # Insure the string is defined.
    if (defined $string) {
        # Convert it to lower case.
        my $lowerString = lc $string;
        # Look for yes-like stuff.
        if ($lowerString =~ /^(y|yes|t|true|1)$/) {
            $retVal = 'Y';
        } elsif ($lowerString =~ /^(n|no|false|0)$/) {
            $retVal = 'N';
        }
    }
    # Return the result.
    return $retVal;
}


=head2 Virtual Methods

=head3 averageLength

    my $value = $et->averageLength();

Return the average length of a data item of this field type when it is stored in the
database. This value is used to compute the expected size of a database table.

=cut

sub averageLength {
    return 80;
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
    if (not $value =~ /^[YN\?]$/) {
        $retVal = 'Illegal semi-boolean (ternary) value.';
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
    # Return the result.
    return $value;
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
    # Return the result.
    return $string;
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
    return "CHAR(1)";
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
    return "";
}

=head3 documentation

    my $docText = $et->documentation();

Return the documentation text for this field type. This should be in TWiki markup
format, though HTML will also work.

=cut

sub documentation() {
    return 'Ternary boolean value-- Y, N, or ?.';
}

=head3 name

    my $name = $et->name();

Return the name of this type, as it will appear in the XML database definition.

=cut

sub name() {
    return "semi-boolean";
}

=head3 default

    my $defaultValue = $et->default();

Return the default value to be used for fields of this type if no default value
is specified in the database definition or in an L<ERDBLoadGroup/Put> call
during a loader operation. The default is undefined, which means an error will
be thrown during the load.

=cut

sub default {
    return '?';
}

=head3 align

    my $alignment = $et->align();

Return the display alignment for fields of this type: either C<left>, C<right>, or
C<center>. The default is C<left>.

=cut

sub align {
    return 'center';
}

=head3 html

    my $html = $et->html($value);

Return the HTML for displaying the content of a field of this type in an output
table. The default is the raw value, html-escaped.

=cut

sub html {
    my ($self, $value) = @_;
    my $retVal = "";
    if ($value eq 'Y') {
        $retVal = "Yes";
    } elsif ($value eq 'N') {
        $retVal = "No";
    }
    return $retVal;
}

1;
