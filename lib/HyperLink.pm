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

package HyperLink;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);

=head1 HyperLink Package

=head2 Introduction

This is a dinky object that can be used to encode and decode hyperlinks. The
client can extract the text value, the URL value, or an HTML representation. It
also contains L</Encode> and L</Decode> methods for use by L<ERDB>.

The hyperlink is stored in the database with the text first, to make
indexing more natural. The text is followed by a space, then the URL,
another space, a double color (C<::>), and the length.

The fields in this object are as follows.

=over 4

=item text

The text of the hyperlink.

=item link

The URL of the link.

=back

=head2 Constructors

=head3 new

    my $hl = HyperLink->new($text, $link);

Construct a new HyperLink object.

=over 4

=item text

Text for the link.

=item link (optional)

URL to which we should link.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $text, $link) = @_;
    # Convert an empty or zero link to an undefined one.
    my $url = (! $link ? undef : $link);
    # Create the HyperLink object.
    my $retVal = { 
                    text => $text,
                    link => $url,
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 newFromHtml

    my $hl = HyperLink->new_from_html($htmlLink)

Create a HyperLink object from an HTML link tag.

=over 4

=item htmlLink

Anchor href tag containing the URL and the link text.

=back

=cut

sub newFromHtml {
    # Get the parameters.
    my ($class, $htmlLink) = @_;
    # Declare the return variable.
    my $retVal;
    # Parse the HTML.
    if ($htmlLink =~ /^<a.*?\shref="([^"]+).*>([^<]+)<\/a>$/) {
        # Here it's a real anchor tag. We need to unescape the text,
        # then pass the text and URL to the real constructor.
        my $link = $1;
        my $text = CGI::unescapeHTML($2);
        $retVal = new($class, $text, $link);
    } else {
        # Here it's just text. Unescape the whole thing and pass it
        # without a link.
        $retVal = CGI::unescapeHTML($htmlLink);
    }
    # Return the result.
    return $retVal;
}

=head2 Public Methods

=head3 Decode

    my $hl = HyperLink->Decode($string);

Convert a string from the database to a Hyperlink object.

=over 4

=item string

String read from an L<ERDB> database.

=item RETURN

Returns a Hyperlink object represented by the string.

=back

=cut

sub Decode {
    # Get the parameters.
    my ($class, $string) = @_;
    # Unescape the input string.
    my $realString = Tracer::UnEscape($string);
    # The default is to treat the string as all text, without a URL.
    my $text = $realString;
    my $url;
    # Get the length of the text. This is stored at the end of the string
    # as a number preceded by a double colon.
    if ($realString =~ /::(\d+)$/) {
        # Save the parsed length.
        my $textLen = $1;
        # Split off the text.
        $text = substr($realString, 0, $textLen);
        my $leftOver = substr($realString, $textLen);
        # Now we need to peel out the url.
        if ($leftOver =~ /(\S+)\s::/) {
            $url = $1;
        }
    }
    
    # Form a hyperlink out of the two pieces.
    my $retVal = HyperLink->new($text, $url);
    return $retVal;
}

=head3 Encode

    my $string = $hl->Encode();

Return the database representation for a hyperlink.

=cut

sub Encode {
    # Get the parameters.
    my ($self) = @_;
    # Compute the return value. First, we get the text length.
    my ($text, $url) = ($self->{text}, $self->{link});
    my $textLen = length($text);
    # Assemble the pieces.
    my $string = "$text $url ::$textLen";
    # Escape the assembled string.
    my $retVal = Tracer::Escape($string);
    # Return the result.
    return $retVal;
}

=head3 text

    my $message = $hl->text();

Return the text of a hyperlink.

=cut

sub text {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{text};
}

=head3 link

    my $message = $hl->link();

Return the URL of a hyperlink.

=cut

sub link {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{link};
}

=head3 html

    my $message = $hl->html();

Return the HTML representation of a hyperlink.

=cut

sub html {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my $retVal;
    # Do we have a URL?
    if (defined $self->{link}) {
        # Yes, wrap it around the text.
        $retVal = CGI::a({ href => $self->{link} }, CGI::escapeHTML($self->{text}));
    } else {
        # No, return the text alone.
        $retVal = $self->{text};
    }
    # Return the result.
    return $retVal;
}


1;
