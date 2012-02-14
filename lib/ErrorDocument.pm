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

package ErrorDocument;

    use strict;
    use overload '""' => "baseMessage";

=head1 Error Document

=head2 Introduction

The error document is a simple class that describes a server error. When it is
exported by the YAML facility, it will be clearly identified as an Error
Document object, so that the recipient of the data knows something has gone
wrong.

This object has been replaced by L<ErrorObject>.

The fields in this object are as follows.

=over 4

=item function

name of the function that failed

=item message

detailed message describing the error

=item baseMessage

message describing the kind of error

=back

=cut

=head3 new

    my $errDoc = ErrorDocument->new($function, $message, $baseMessage);

Construct a new ErrorDocument object. The following parameters are expected.

=over 4

=item function

Name of the function that failed.

=item message

Text of the detailed error message. The detailed error message is long, and frequently
contains information about where the error occurred and the contents of the call stack.

=item baseMessage

Text of the user-friendly error message. The user-friendly message is short, and
designed to be minimally confusing; it is also minimally informative.


=back

=cut

sub new {
    # Get the parameters.
    my ($class, $function, $message, $baseMessage) = @_;
    # Clean the message.
    my $cleaned = $message;
    chomp $cleaned;
    # Create the ErrorDocument object.
    my $retVal = { 
                    function => $function,
                    message => $cleaned,
                    baseMessage => $baseMessage,
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 message

    my $text = $errDoc->message();

Return the error message.

=cut

sub message {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{message};
}

=head3 baseMessage

    my $text = $errDoc->baseMessage();

Return the user-friendly error message.

=cut

sub baseMessage {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{baseMessage};
}

=head3 function

    my $text = $errDoc->function();

Return the error function.

=cut

sub function {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{function};
}


1;
