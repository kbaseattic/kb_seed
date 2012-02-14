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

package ERDBTypeText;

    use strict;
    use Tracer;
    use ERDB;
    use base qw(ERDBType);

=head1 ERDB Text Type Definition

=head2 Introduction

This object represents the primitive data type for long strings (0 to 16M
characters). These are stored with tabs, newlines, and backslashes escaped, and
unlike normal strings they are large enough that it is impractical to index the
entire length.

=head3 new

    my $et = ERDBTypeText->new();

Construct a new ERDBTypeText descriptor.

=cut

sub new {
    # Get the parameters.
    my ($class) = @_;
    # Create the ERDBTypeText object.
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
    return 1000;
}

=head3 prettySortValue

    my $value = $et->prettySortValue();

Number indicating where fields of this type should go in relation to other
fields. The value should be somewhere between C<1> and C<5>. A value outside
that range will make terrible things happen.

=cut

sub prettySortValue() {
    return 4;
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
    # Escape the text.
    my $text = Tracer::Escape($value);
    # Verify the length.
    if (length $text > 16777216) {
        $retVal = "Text string too long.";
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

use constant ENHASH => { "\x80" => "\\x80", "\x81" => "\\x81", "\x82" => "\\x82", "\x83" => "\\x83", "\x84" => "\\x84", "\x85" => "\\x85", "\x86" => "\\x86", "\x87" => "\\x87", "\x88" => "\\x88", "\x89" => "\\x89", "\x8A" => "\\x8A", "\x8B" => "\\x8B", "\x8C" => "\\x8C", "\x8D" => "\\x8D", "\x8E" => "\\x8E", "\x8F" => "\\x8F",
                         "\x90" => "\\x90", "\x91" => "\\x91", "\x92" => "\\x92", "\x93" => "\\x93", "\x94" => "\\x94", "\x95" => "\\x95", "\x96" => "\\x96", "\x97" => "\\x97", "\x98" => "\\x98", "\x99" => "\\x99", "\x9A" => "\\x9A", "\x9B" => "\\x9B", "\x9C" => "\\x9C", "\x9D" => "\\x9D", "\x9E" => "\\x9E", "\x9F" => "\\x9F",
                         "\xA0" => "\\xA0", "\xA1" => "\\xA1", "\xA2" => "\\xA2", "\xA3" => "\\xA3", "\xA4" => "\\xA4", "\xA5" => "\\xA5", "\xA6" => "\\xA6", "\xA7" => "\\xA7", "\xA8" => "\\xA8", "\xA9" => "\\xA9", "\xAA" => "\\xAA", "\xAB" => "\\xAB", "\xAC" => "\\xAC", "\xAD" => "\\xAD", "\xAE" => "\\xAE", "\xAF" => "\\xAF",
                         "\xB0" => "\\xB0", "\xB1" => "\\xB1", "\xB2" => "\\xB2", "\xB3" => "\\xB3", "\xB4" => "\\xB4", "\xB5" => "\\xB5", "\xB6" => "\\xB6", "\xB7" => "\\xB7", "\xB8" => "\\xB8", "\xB9" => "\\xB9", "\xBA" => "\\xBA", "\xBB" => "\\xBB", "\xBC" => "\\xBC", "\xBD" => "\\xBD", "\xBE" => "\\xBE", "\xBF" => "\\xBF",
                         "\xC0" => "\\xC0", "\xC1" => "\\xC1", "\xC2" => "\\xC2", "\xC3" => "\\xC3", "\xC4" => "\\xC4", "\xC5" => "\\xC5", "\xC6" => "\\xC6", "\xC7" => "\\xC7", "\xC8" => "\\xC8", "\xC9" => "\\xC9", "\xCA" => "\\xCA", "\xCB" => "\\xCB", "\xCC" => "\\xCC", "\xCD" => "\\xCD", "\xCE" => "\\xCE", "\xCF" => "\\xCF",
                         "\xD0" => "\\xD0", "\xD1" => "\\xD1", "\xD2" => "\\xD2", "\xD3" => "\\xD3", "\xD4" => "\\xD4", "\xD5" => "\\xD5", "\xD6" => "\\xD6", "\xD7" => "\\xD7", "\xD8" => "\\xD8", "\xD9" => "\\xD9", "\xDA" => "\\xDA", "\xDB" => "\\xDB", "\xDC" => "\\xDC", "\xDD" => "\\xDD", "\xDE" => "\\xDE", "\xDF" => "\\xDF",
                         "\xE0" => "\\xE0", "\xE1" => "\\xE1", "\xE2" => "\\xE2", "\xE3" => "\\xE3", "\xE4" => "\\xE4", "\xE5" => "\\xE5", "\xE6" => "\\xE6", "\xE7" => "\\xE7", "\xE8" => "\\xE8", "\xE9" => "\\xE9", "\xEA" => "\\xEA", "\xEB" => "\\xEB", "\xEC" => "\\xEC", "\xED" => "\\xED", "\xEE" => "\\xEE", "\xEF" => "\\xEF",
                         "\xF0" => "\\xF0", "\xF1" => "\\xF1", "\xF2" => "\\xF2", "\xF3" => "\\xF3", "\xF4" => "\\xF4", "\xF5" => "\\xF5", "\xF6" => "\\xF6", "\xF7" => "\\xF7", "\xF8" => "\\xF8", "\xF9" => "\\xF9", "\xFA" => "\\xFA", "\xFB" => "\\xFB", "\xFC" => "\\xFC", "\xFD" => "\\xFD", "\xFE" => "\\xFE", "\xFF" => "\\xFF",
                         "\n"   => "\\n",   "\\"   => "\\\\",  "\t"   => "\\t"  , "\r"   => "" };

sub encode {
    # Get the parameters.
    my ($self, $value, $mode) = @_;
    # Declare the return variable.
    my $retVal = $value;
    # Process the encoding substitutions.
    $retVal =~ s/([\t\n\r\\\x80-\xFF])/ENHASH->{$1}/ge;
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

use constant DEHASH => { "x80" => "\x80", "x81" => "\x81", "x82" => "\x82", "x83" => "\x83", "x84" => "\x84", "x85" => "\x85", "x86" => "\x86", "x87" => "\x87", "x88" => "\x88", "x89" => "\x89", "x8A" => "\x8A", "x8B" => "\x8B", "x8C" => "\x8C", "x8D" => "\x8D", "x8E" => "\x8E", "x8F" => "\x8F",
                         "x90" => "\x90", "x91" => "\x91", "x92" => "\x92", "x93" => "\x93", "x94" => "\x94", "x95" => "\x95", "x96" => "\x96", "x97" => "\x97", "x98" => "\x98", "x99" => "\x99", "x9A" => "\x9A", "x9B" => "\x9B", "x9C" => "\x9C", "x9D" => "\x9D", "x9E" => "\x9E", "x9F" => "\x9F",
                         "xA0" => "\xA0", "xA1" => "\xA1", "xA2" => "\xA2", "xA3" => "\xA3", "xA4" => "\xA4", "xA5" => "\xA5", "xA6" => "\xA6", "xA7" => "\xA7", "xA8" => "\xA8", "xA9" => "\xA9", "xAA" => "\xAA", "xAB" => "\xAB", "xAC" => "\xAC", "xAD" => "\xAD", "xAE" => "\xAE", "xAF" => "\xAF",
                         "xB0" => "\xB0", "xB1" => "\xB1", "xB2" => "\xB2", "xB3" => "\xB3", "xB4" => "\xB4", "xB5" => "\xB5", "xB6" => "\xB6", "xB7" => "\xB7", "xB8" => "\xB8", "xB9" => "\xB9", "xBA" => "\xBA", "xBB" => "\xBB", "xBC" => "\xBC", "xBD" => "\xBD", "xBE" => "\xBE", "xBF" => "\xBF",
                         "xC0" => "\xC0", "xC1" => "\xC1", "xC2" => "\xC2", "xC3" => "\xC3", "xC4" => "\xC4", "xC5" => "\xC5", "xC6" => "\xC6", "xC7" => "\xC7", "xC8" => "\xC8", "xC9" => "\xC9", "xCA" => "\xCA", "xCB" => "\xCB", "xCC" => "\xCC", "xCD" => "\xCD", "xCE" => "\xCE", "xCF" => "\xCF",
                         "xD0" => "\xD0", "xD1" => "\xD1", "xD2" => "\xD2", "xD3" => "\xD3", "xD4" => "\xD4", "xD5" => "\xD5", "xD6" => "\xD6", "xD7" => "\xD7", "xD8" => "\xD8", "xD9" => "\xD9", "xDA" => "\xDA", "xDB" => "\xDB", "xDC" => "\xDC", "xDD" => "\xDD", "xDE" => "\xDE", "xDF" => "\xDF",
                         "xE0" => "\xE0", "xE1" => "\xE1", "xE2" => "\xE2", "xE3" => "\xE3", "xE4" => "\xE4", "xE5" => "\xE5", "xE6" => "\xE6", "xE7" => "\xE7", "xE8" => "\xE8", "xE9" => "\xE9", "xEA" => "\xEA", "xEB" => "\xEB", "xEC" => "\xEC", "xED" => "\xED", "xEE" => "\xEE", "xEF" => "\xEF",
                         "xF0" => "\xF0", "xF1" => "\xF1", "xF2" => "\xF2", "xF3" => "\xF3", "xF4" => "\xF4", "xF5" => "\xF5", "xF6" => "\xF6", "xF7" => "\xF7", "xF8" => "\xF8", "xF9" => "\xF9", "xFA" => "\xFA", "xFB" => "\xFB", "xFC" => "\xFC", "xFD" => "\xFD", "xFE" => "\xFE", "xFF" => "\xFF",
                         "n"   => "\n",   "\\"   => "\\",  "t"   => "\t" };

sub decode {
    # Get the parameters.
    my ($self, $string) = @_;
    # Declare the return variable.
    my $retVal = $string;
    # Perform the decoding substitutions.
    $retVal =~ s/\\(x..|.)/DEHASH->{$1}/ge;
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
    my ($self, $dbh) = @_;
    my $retVal = "TEXT";
    if ($dbh->dbms() eq 'mysql') {
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
    return 250;
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
    return 'Long character string, from 0 to approximately 16 million characters, not generally indexable.';
}

=head3 name

    my $name = $et->name();

Return the name of this type, as it will appear in the XML database definition.

=cut

sub name() {
    return "text";
}

=head3 default

    my $defaultValue = $et->default();

Default value to be used for fields of this type if no default value is
specified in the database definition or in an L<ERDBLoadGroup/Put>
call during a loader operation. The default is undefined, which means
an error will be thrown during the load.

=cut

sub default {
    return '';
}

1;
