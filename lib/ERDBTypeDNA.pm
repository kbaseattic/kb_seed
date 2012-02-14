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

package ERDBTypeDNA;

    use strict;
    use Tracer;
    use ERDB;
    use base qw(ERDBType);

=head1 ERDB DNA Type Definition

=head2 Introduction

This object represents the data type for DNA sequences. These are stored in a
compressed format to save space, and there is no hope of ever being able to
index them. For the four basic characters-- C<A>, C<C>, C<G>, and C<T>-- each
letter uses 2 bits, so each triple is converted to a base64 character. One or
two equal signs at the end indicate 2 or 4 unused bits in the last triple.
Characters other than the basic 4 (which must be either a hyphen or another letter)
are placed in the output with a preceding exclamation point. A run of hyphens
is placed as a hyphen followed by a base64 digit.

For a clean DNA stream, this provides a 66% reduction in size without exposing
us to characters that would mess up a database table load. This is significantly
smaller than we get by piping Zlib through base64 conversion, and it's pretty fast.

DNA strings are automatically converted to lower-case when stored.

=head3 Character Maps

The constants MAP and UNMAP are used to translate character triples into base64
encodings. If a character triple is not found in MAP, then it must have one of the
nonstandard characters, such as an ambiguity code or a hyphen.

=cut

use constant MAP => { 
                      aaa => 'A', aac => 'B', aag => 'C', aat => 'D',
                      aca => 'E', acc => 'F', acg => 'G', act => 'H',
                      aga => 'I', agc => 'J', agg => 'K', agt => 'L',
                      ata => 'M', atc => 'N', atg => 'O', att => 'P',
                      caa => 'Q', cac => 'R', cag => 'S', cat => 'T',
                      cca => 'U', ccc => 'V', ccg => 'W', cct => 'X',
                      cga => 'Y', cgc => 'Z', cgg => 'a', cgt => 'b',
                      cta => 'c', ctc => 'd', ctg => 'e', ctt => 'f',
                      gaa => 'g', gac => 'h', gag => 'i', gat => 'j',
                      gca => 'k', gcc => 'l', gcg => 'm', gct => 'n',
                      gga => 'o', ggc => 'p', ggg => 'q', ggt => 'r',
                      gta => 's', gtc => 't', gtg => 'u', gtt => 'v',
                      taa => 'w', tac => 'x', tag => 'y', tat => 'z',
                      tca => '0', tcc => '1', tcg => '2', tct => '3',
                      tga => '4', tgc => '5', tgg => '6', tgt => '7',
                      tta => '8', ttc => '9', ttg => '/', ttt => '+',
                      };
use constant UNMAP => {
                      'A' => 'aaa', 'B' => 'aac', 'C' => 'aag', 'D' => 'aat',
                      'E' => 'aca', 'F' => 'acc', 'G' => 'acg', 'H' => 'act',
                      'I' => 'aga', 'J' => 'agc', 'K' => 'agg', 'L' => 'agt',
                      'M' => 'ata', 'N' => 'atc', 'O' => 'atg', 'P' => 'att',
                      'Q' => 'caa', 'R' => 'cac', 'S' => 'cag', 'T' => 'cat',
                      'U' => 'cca', 'V' => 'ccc', 'W' => 'ccg', 'X' => 'cct',
                      'Y' => 'cga', 'Z' => 'cgc', 'a' => 'cgg', 'b' => 'cgt',
                      'c' => 'cta', 'd' => 'ctc', 'e' => 'ctg', 'f' => 'ctt',
                      'g' => 'gaa', 'h' => 'gac', 'i' => 'gag', 'j' => 'gat',
                      'k' => 'gca', 'l' => 'gcc', 'm' => 'gcg', 'n' => 'gct',
                      'o' => 'gga', 'p' => 'ggc', 'q' => 'ggg', 'r' => 'ggt',
                      's' => 'gta', 't' => 'gtc', 'u' => 'gtg', 'v' => 'gtt',
                      'w' => 'taa', 'x' => 'tac', 'y' => 'tag', 'z' => 'tat',
                      '0' => 'tca', '1' => 'tcc', '2' => 'tcg', '3' => 'tct',
                      '4' => 'tga', '5' => 'tgc', '6' => 'tgg', '7' => 'tgt',
                      '8' => 'tta', '9' => 'ttc', '/' => 'ttg', '+' => 'ttt',
                    };
use constant DIGITS64 => 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/+';

=head3 new

    my $et = ERDBTypeDNA->new();

Construct a new ERDBTypeDNA descriptor.

=cut

sub new {
    # Get the parameters.
    my ($class) = @_;
    # Create the ERDBTypeDNA object.
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
    return 100000;
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
    # Look for an invalid character.
    if ($value =~ /([^A-Za-z\-])/) {
        $retVal = "Invalid character \"$1\" found in DNA sequence. Only letters and hyphens are allowed.";
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
    my $retVal = "";
    # Position at the beginning of the string.
    my $pos = 0;
    my $len = length($value);
    # Loop through the string.
    while ($pos < $len) {
        # Get the current triple. Note that we fold it to lower case. DNA is lower
        # case, proteins are upper case.
        my $triple = lc substr($value, $pos, 3);
        # Look for it in the hash.
        my $mapChar = MAP->{$triple};
        # If it's there, we just keep going.
        if (defined $mapChar) {
            $retVal .= $mapChar;
            $pos += 3;
        } else {
            # Find out how many good characters we have.
            $triple =~ /^(.*?)([^acgt]|$)/;
            my ($good, $bad) = ($1, $2);
            # If there were any good characters, spit them out.
            my $goodCount = length($good);
            if ($goodCount) {
                my $extra = 3 - $goodCount;
                $retVal .= MAP->{$good . ('a' x $extra)} . ('=' x $extra);
                $pos += $goodCount;
            }
            # Check for a hyphen run.
            if (substr($retVal, $pos, 64) =~ /^([-]+)/) {
                # Convert the run into a hyphen character followed by a base 64 digit.
                # Since we can't have a run of 0 characters, a digit of 0 means 1 hyphen,
                # a digit of 1 means 2, and so forth.
                my $len = length($1);
                $retVal .= '-' . substr(DIGITS64, $len-1, 1);
                $pos += $len;
            } elsif ($bad) {
                # Here we have a single bad character. Emit an exclamation point
                # followed by the character itself.
                $retVal .= '!' . $bad;
                $pos++;
            }
        }
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
    Trace("Decoding DNA string of length " . length($string) . ":  " . substr($string, 0, 6) . "...") if T(3);
    # Declare the return variable.
    my $retVal = "";
    # Loop through the string.
    my $pos = 0;
    my $len = length($string);
    while ($pos < $len) {
        # Try to unmap the current character.
        my $triple = UNMAP->{substr($string, $pos, 1)};
        if (defined $triple) {
            $retVal .= $triple;
            $pos++;
        } else {
            # Here we have something unusual. Get the current character.
            my $char = substr($string, $pos, 1);
            # It can be a hyphen, an equal sign, or an exclamation point.
            if ($char eq '-') {
                # It's a hyphen. The next character is a run length.
                my $runLength = 1 + index(DIGITS64, substr($string, $pos+1, 1));
                $retVal .= '-' x $runLength;
                $pos += 2;
            } elsif ($char eq '=') {
                # It's an equal sign. Chop the last character off the end of the
                # return string.
                chop $retVal;
                $pos++;
            } elsif ($char eq '!') {
                # It's an exclamation point, so we have an unusual character.
                $retVal .= substr($string, $pos+1, 1);
                $pos += 2;
            }
        }
    }
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
    if ($dbh->dbms eq 'mysql') {
        $retVal = "LONGTEXT";
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
    return 'Long DNA sequence, compressed';
}

=head3 name

    my $name = $et->name();

Return the name of this type, as it will appear in the XML database definition.

=cut

sub name() {
    return "dna";
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

=head3 html

    my $html = $et->html($value);

Return the HTML for displaying the content of a field of this type in an output
table. The default is the raw value, html-escaped.

=cut

sub html {
    my ($self, $value) = @_;
    # Declare the return value.
    my $retVal;
    # We'll put ellipses in here if the string's too long.
    my $suffix = "";
    # We want to peel off 60-character lines, up to a maximum of 100.
    my $len = length $value;
    if ($len > 6000) {
        my $residual = $len - 6000;
        $len = 6000;
        $suffix = " + $residual characters.";
    }
    # Peel off all the lines.
    for (my $pos = 0; $pos < $len; $pos += 60) {
        $retVal = CGI::escapeHTML(substr($value, $pos, 60)) . "<br />";
    }
    # Return the result.
    return $retVal;
}

1;
