
# This is a SAS component.

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

=head1 High-scoring Segment Pair Object

=head2 Introduction

The HSP object provides access by name to the fields of a BLAST result.
Unlike a standard object, the similarity object is stored as a list
reference, not a hash reference. The HSP fields are pulled from the
appropriate places in the list.

A blast takes a sequence called the I<query> and matches it against a
I<database>. When describing the data in an HSP, we will
refer repeatedly to the query sequence and the database sequence. Often,
the query and database sequences will be given by peg IDs. In some cases,
however, they will be contig IDs. In both cases, the match is represented
by an alignment between portions of the sequences. Gap characters may
be required to get the alignments to match, and the number of gaps is
part of the data in the HSP.

=cut

package Hsp;

use strict;
use BasicLocation;

=head2 new

    my $hsp = Hsp->new(  @data );
    my $hsp = Hsp->new( \@data );

Create an HSP object from an array of fields.

=over 4

=item data

An array of data in fields:

   0   qid        query sequence id
   1   qdef       query sequence comment
   2   qlen       total query sequence length
   3   sid        subject sequence id
   4   sdef       subject sequence comment
   5   slen       total subject sequence length
   6   scr        match score
   7   e_val      match e-value (probability match is a coincidence)
   8   p_n        the p-number
   9   p_val      the Poisson value
  10   n_mat      match length
  11   n_id       identity count
  12   n_pos      positive count
  13   n_gap      gap count
  14   dir        frame direction or shift
  15   q1         start position of match in the query sequence
  16   q2         end position of match in the query sequence
  17   qseq       query alignment sequence
  18   s1         start position of match in the subject sequence
  19   s2         end position of match in the subject sequence
  20   sseq       subject alignment sequence

=item RETURN

Returns an HSP object that allows the values to be accessed by name.

=back

=cut

sub new {
    my $class = shift;
    my $self  = [ $_[0] && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_ ];
    bless $self, $class;
}

=head3 qid

    my $qid = $hsp->qid

Return the query sequence id.

=cut

sub qid {
    my ($self) = @_;
    return $self->[0];
}


=head3 qdef

    my $qdef = $hsp->qdef

Return the query sequence comment.

=cut

sub qdef {
    my ($self) = @_;
    return $self->[1];
}


=head3 qlen

    my $qlen = $hsp->qlen

Return the total query sequence length.

=cut

sub qlen {
    my ($self) = @_;
    return $self->[2];
}


=head3 sid

    my $sid = $hsp->sid

Return the subject sequence id.

=cut

sub sid {
    my ($self) = @_;
    return $self->[3];
}


=head3 sdef

    my $sdef = $hsp->sdef

Return the subject sequence comment.

=cut

sub sdef {
    my ($self) = @_;
    return $self->[4];
}


=head3 slen

    my $slen = $hsp->slen

Return the total subject sequence length.

=cut

sub slen {
    my ($self) = @_;
    return $self->[5];
}


=head3 scr

    my $scr = $hsp->scr

Return the match score.

=cut

sub scr {
    my ($self) = @_;
    return $self->[6];
}


=head3 e_val

    my $e_val = $hsp->e_val

Return the match e-value (probability match is a coincidence).

=cut

sub e_val {
    my ($self) = @_;
    return $self->[7];
}


=head3 p_n

    my $p_n = $hsp->p_n

Return the the p-number.

=cut

sub p_n {
    my ($self) = @_;
    return $self->[8];
}


=head3 p_val

    my $p_val = $hsp->p_val

Return the the Poisson value.

=cut

sub p_val {
    my ($self) = @_;
    return $self->[9];
}


=head3 n_mat

    my $n_mat = $hsp->n_mat

Return the match length.

=cut

sub n_mat {
    my ($self) = @_;
    return $self->[10];
}


=head3 n_id

    my $n_id = $hsp->n_id

Return the identity count.

=cut

sub n_id {
    my ($self) = @_;
    return $self->[11];
}

=head3 pct

    my $pct = $hsp->pct;

Return the percent identity.

=cut

sub pct {
    my ($self) = @_;
    return ($self->[11] * 100 / $self->[10]);
}

=head3 n_pos

    my $n_pos = $hsp->n_pos

Return the positive count.

=cut

sub n_pos {
    my ($self) = @_;
    return $self->[12];
}


=head3 n_gap

    my $n_gap = $hsp->n_gap

Return the gap count.

=cut

sub n_gap {
    my ($self) = @_;
    return $self->[13];
}


=head3 dir

    my $dir = $hsp->dir

Return the frame direction or shift.

=cut

sub dir {
    my ($self) = @_;
    return $self->[14];
}


=head3 q1

    my $q1 = $hsp->q1

Return the start position of match in the query sequence.

=cut

sub q1 {
    my ($self) = @_;
    return $self->[15];
}


=head3 q2

    my $q2 = $hsp->q2

Return the end position of match in the query sequence.

=cut

sub q2 {
    my ($self) = @_;
    return $self->[16];
}


=head3 qseq

    my $qseq = $hsp->qseq

Return the query alignment sequence.

=cut

sub qseq {
    my ($self) = @_;
    return $self->[17];
}


=head3 s1

    my $s1 = $hsp->s1

Return the start position of match in the subject sequence.

=cut

sub s1 {
    my ($self) = @_;
    return $self->[18];
}


=head3 s2

    my $s2 = $hsp->s2

Return the end position of match in the subject sequence.

=cut

sub s2 {
    my ($self) = @_;
    return $self->[19];
}


=head3 sseq

    my $sseq = $hsp->sseq

Return the subject alignment sequence.

=cut

sub sseq {
    my ($self) = @_;
    return $self->[20];
}

=head3 sloc

    my $sloc = $hsp->sloc;

Return the match region of the subject sequence as a L<BasicLocation> object.

=cut

sub sloc {
    my ($self) = @_;
    my $retVal;
    my $contig = $self->sid;
    my $s1 = $self->s1;
    my $s2 = $self->s2;
    if ($s1 == $s2) {
        $retVal = BasicLocation->new($contig, $s1, $self->dir, 1);
    } elsif ($s1 < $s2) {
        $retVal = BasicLocation->new($contig, $s1, '+', $s2 + 1 - $s1);
    } else {
        $retVal = BasicLocation->new($contig, $s1, '-', $s1 + 1 - $s2);
    }
    return $retVal;
}

=head3 qloc

    my $qloc = $hsp->qloc;

Return the match region of the query sequence as a L<BasicLocation> object.

=cut

sub qloc {
    my ($self) = @_;
    my $retVal;
    my $contig = $self->qid;
    my $q1 = $self->q1;
    my $q2 = $self->q2;
    if ($q1 == $q2) {
        $retVal = BasicLocation->new($contig, $q1, $self->dir, 1);
    } elsif ($q1 < $q2) {
        $retVal = BasicLocation->new($contig, $q1, '+', $q2 + 1 - $q1);
    } else {
        $retVal = BasicLocation->new($contig, $q1, '-', $q1 + 1 - $q2);
    }
    return $retVal;
}


1;
