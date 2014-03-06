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

package ERDBType;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use ERDB;


=head1 ERDB Database Type Definition Base Class

=head2 Introduction

This class describes an ERDB type. All ERDB types are defined as subclasses of
this one. The class itself is purely virtual, and contains no useful methods.

It's important to recognize that an instance of this class represents a type, not
an item of the specific type. The types provide methods for manipulating and
describing values in the data base, but those values are usually scalars or
objects unrelated to the ERDB type classes.

=cut

=head3 new

    my $et = ERDBType->new();

Construct a new ERDBType object. The following options are supported.

=over 4

=back

=cut

sub new {
    # Get the parameters.
    my ($class) = @_;
    # Create the ERDBType object.
    my $retVal = { };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Virtual Methods

=head3 numeric

    my $flag = $et->numeric();

Return TRUE if this is a numeric type and FALSE otherwise. The default is
FALSE.

=cut

sub numeric {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return 0;
}

=head3 nullable

    my $flag = $et->nullable();

Return TRUE if this type allows null-valued fields, else FALSE. The default is
FALSE.

=cut

sub nullable {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return 0;
}

=head3 averageLength

    my $value = $et->averageLength();

Return the average length of a data item of this field type when it is stored in the
database. This value is used to compute the expected size of a database table.

=cut

sub averageLength {
    Confess("Pure virtual method \"averageLength\" called.");
}

=head3 prettySortValue

    my $value = $et->prettySortValue();

Number indicating where fields of this type should go in relation to other
fields. The value should be somewhere between C<1> and C<5>. A value outside
that range will make terrible things happen.

=cut

sub prettySortValue {
    return 2;
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
    Confess("Pure virtual method \"validate\" called.");
}

=head3 encode

    my $string = $et->encode($value, $mode)

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
    Confess("Pure virtual method \"encode\" called.");
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
    Confess("Pure virtual method \"decode\" called.");
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
    Confess("Pure virtual method \"sqlType\" called.");
}

=head3 indexMod

    my $length = $et->indexMod();

Return the index modifier for this field type. The index modifier is the number of
characters to be indexed. If it is undefined, the field cannot be indexed. If it
is an empty string, the entire field is indexed. The default is an empty string.

=cut

sub indexMod {
    return "";
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
    Confess("Pure virtual method \"documentation\" called.");
}

=head3 name

    my $name = $et->name();

Return the name of this type, as it will appear in the XML database definition.

=cut

sub name() {
    Confess("Pure virtual method \"name\" called.");
}

=head3 default

    my $defaultValue = $et->default();

Return the default value to be used for fields of this type if no default
value is specified in the database definition or in an L<ERDBLoadGroup/Put>
call during a loader operation. The default is undefined, which means
an error will be thrown during the load.

=cut

sub default {
    return undef;
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
    my $retVal = CGI::escapeHTML($value);
    return $retVal;
}

=head3 objectType

    my $type = $et->objectType();

Return the PERL type for fields of this type. An undefined value means it's
a scalar; otherwise, it should be the package name (suitable for a C<use> clause).

=cut

sub objectType {
    return undef;
}

1;
