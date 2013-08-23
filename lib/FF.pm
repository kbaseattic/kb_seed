# -*- perl -*-
########################################################################
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
########################################################################

package FF;

# This is a SAS component.

use strict;
use Carp;
use Data::Dumper;
no warnings 'redefine';

=head1 Module to access FIGfams

=head3 new

usage:
    my $figfam_obj = FFserver->new();

=cut

#   
# Actually, if you are using FF.pm, you should do FF->new(), not FFserver->new()
# That comment above is for the benefit of the pod doc stuff on how to use FFserver 
# that is generated from this file.

# Here's how you use this module
#    my $figfam_obj = FF->new($fam_id, $fam_dir);
#C<$fam_id> is the ID of the family, of the form C<FIGnnnnnn> where C<n> is a digit;
#it is required.
#
#C<$fam_data> is required
#as the directory that contains (or will contain) FigFam data.
#
#

sub new {
    my($class,$fam_id,$ffs) = @_;

    ($fam_id =~ /^FIG\d+$/) || confess "invalid family id: $fam_id";
    my $fam = {};
    $fam->{id}  = $fam_id;
    $fam->{ffs} = $ffs;

    return bless $fam, $class;
}

=head3 pegs_of

usage:
    print $figfam_obj->pegs_of();

Returns a list of just pegs.

=cut

sub pegs_of {
    my($self) = @_;
    return [$self->list_members];
}

=head3 list_members

usage:
    @ids = $figfam_obj->list_members();

Returns a list of the PEG FIDs in a family.

=cut

sub list_members {
    my ($self)  = @_;

    return @{$self->{ffs}->family_pegs($self->{id})};
}


=head3 family_function

usage:
    $func = $figfam_obj->family_function();

Returns the "consensus function" assigned to a FIGfam object.

=cut

sub family_function {
    my($self,$full) = @_;

    return $self->{ffs}->family_function($self->{id});
}


=head3 family_id

usage:
    $fam_id = $figfam_obj->family_id();

Returns the FIGfam ID of a FIGfam object.

=cut

sub family_id {
    my($self) = @_;

    return $self->{id};
}

1;
