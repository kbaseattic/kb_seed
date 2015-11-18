
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

#
#  Field definitions:
#
#   0   id1        query sequence id
#   1   id2        subject sequence id
#   2   iden       percentage sequence identity
#   3   ali_ln     alignment length
#   4   mismatches  number of mismatch
#   5   gaps       number of gaps
#   6   b1         query seq match start
#   7   e1         query seq match end
#   8   b2         subject seq match start
#   9   e2         subject seq match end
#  10   psc        match e-value
#  11   bsc        bit score
#  12   ln1        query sequence length
#  13   ln2        subject sequence length
#  14   tool       tool used to produce similarities
#
#  All following fields may vary by tool:
#
#  15   loc1       query seq locations string (b1-e1,b2-e2,b3-e3)
#  16   loc2       subject seq locations string (b1-e1,b2-e2,b3-e3)
#  17   dist       tree distance
#
#  Other access functions:
#
#       as_line    tab delimited text representation (including the new line)
#       as_string  "sim:$id1->$id2:$evalue:$identity"
#       feature2   feature object for subject sequence
#       nbsc       normalized bit score
#

=head1 Similarity Object

=head2 Introduction

The similarity object provides access by name to the fields of a similarity
list. Unlike a standard object, the similarity object is stored as a list
reference, not a hash reference. The similarity fields are pulled from the
appropriate places in the list.

A blast takes a sequence called the I<query> and matches it against a
I<database>. When describing the data in a similarity, we will
refer repeatedly to the query sequence and the database sequence. Often,
the query and database sequences will be given by peg IDs. In some cases,
however, they will be contig IDs. In both cases, the match is represented
by an alignment between portions of the sequences. Gap characters may
be required to get the alignments to match, and the number of gaps is
part of the data in the similarity.

=cut

package Sim;

use strict;

=head2 new

    my $sim = Sim->new(  @data );
    my $sim = Sim->new( \@data );

Create a similarity object from an array of fields.

=over 4

=item data

An array of data in fields:

   0   id1        query sequence id
   1   id2        subject sequence id
   2   iden       percentage sequence identity
   3   ali_ln     alignment length
   4   mismatches  number of mismatch
   5   gaps       number of gaps
   6   b1         query seq match start
   7   e1         query seq match end
   8   b2         subject seq match start
   9   e2         subject seq match end
  10   psc        match e-value
  11   bsc        bit score
  12   ln1        query sequence length
  13   ln2        subject sequence length
  14   tool       tool used to produce similarities

The following fields may vary by tool:

  15   loc1       query seq locations string (b1-e1,b2-e2,b3-e3)
  16   loc2       subject seq locations string (b1-e1,b2-e2,b3-e3)
  17   dist       tree distance


=item RETURN

Returns a similarity object that allows the values to be accessed by name.

=back

=cut

sub new {
    my $class = shift;
    my $self  = [ $_[0] && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_ ];
    bless $self, $class;
}


=head2 new_from_hsp

    my $sim = Sim->new_from_hsp(  @hsp );
    my $sim = Sim->new_from_hsp( \@hsp );
    my $sim = Sim->new_from_hsp( \@hsp, $tool );

Create a similarity object from a gjoparseblast hsp.

=over 4

=item hsp

An array of data on a blast hsp as returned by gjoparseblast::blast_hsp_list()
or gjoparseblast::next_blast_hsp().

=item RETURN

Returns a similarity object that allows the values to be accessed by name.

=back

=cut

sub new_from_hsp {
    my $class = shift;
    my ($hsp, $tool);
    if (ref $_[0] eq 'ARRAY' || ref $_[0] eq 'Hsp') {
        ($hsp, $tool) = @_;
    } else {
        ($hsp, $tool) = (\@_, 'blast');
    }
    my ( $qid, undef, $qlen, $sid, undef, $slen, $scr, $e_val, undef, undef,
         $n_mat, $n_id, undef, $n_gap, undef, $q1, $q2, undef, $s1, $s2, undef
       ) = @$hsp;

    my $ident = sprintf( '%.1f', 100 * ($n_id || 0) / ($n_mat || 1) );
    my $n_mis = $n_mat ? ( $n_mat - $n_id - $n_gap ) : 0;
    Sim->new( $qid, $sid, $ident, $n_mat, $n_mis, $n_gap, $q1, $q2, $s1, $s2,
              $e_val, $scr, $qlen, $slen, $tool );
}


=head2 as_string

    my $simString = "$sim";

or

    my $simString = $sim->as_string;

Return the similarity as a descriptive string, consisting of the query peg,
the similar peg, and the match score.

=cut

use overload '""' => \&as_string;

sub as_string {
    my ($obj) = @_;
    return sprintf("sim:%s->%s:%s:%s", $obj->id1, $obj->id2, $obj->psc, $obj->iden);
}

=head2 new_from_line

    my $sim = Sim->new_from_line($line);

Create a similarity object from a blast output line. The line is presumed to have
the complete list of similarity values in it, tab-separated.

=over 4

=item line

Input line, containing the similarity values in it delimited by tabs. A line terminator
may be present at the end.

=item RETURN

Returns a similarity object that allows the values to be accessed by name.

=back

=cut

sub new_from_line {
    my ($class, $line) = @_;
    chomp $line;
    my $self = [split(/\t/, $line)];
    return bless $self, $class;
}

=head2 validate

    my $okFlag = $sim->validate();

Return TRUE if the similarity values are valid, else FALSE.

=cut

sub validate {
    my ($self) = @_;
    return ($self->id1 ne "" and
            $self->id2 ne "" and
            $self->iden =~ /^[.\d]+$/ and
            $self->ali_ln =~ /^\d+$/ and
            $self->mismatches =~ /^\d+$/ and
            $self->gaps =~ /^\d+$/ and
            $self->b1 =~ /^\d+$/ and
            $self->e1 =~ /^\d+$/ and
            $self->b2 =~ /^\d+$/ and
            $self->e2 =~ /^\d+$/ and
            $self->psc =~ /^[-.e\d]+$/ and
            $self->bsc =~ /^[-.\d]+$/ and
            $self->ln1 =~ /^\d+$/ and
            $self->ln2 =~ /^\d+$/);
}

=head2 as_line

    my $line = $sim->as_line;

Return the similarity as an output line. This is exactly the reverse of
L</new_from_line>.

=cut

sub as_line {
    my ($self) = @_;
    return join("\t", @$self) . "\n";
}


=head2 id1

    my $id = $sim->id1;

Return the ID of the query sequence that was blasted against the database.

=cut

sub id1 {
    my ($sim) = @_;
    return $sim->[0];
}

=head2 id2

    my $id = $sim->id2;

Return the ID of the sequence in the database that matched the query sequence.

=cut

sub id2 {
    my ($sim) = @_;
    return $sim->[1];
}

sub feature2 {
    require FIGO;
    my($sim) = @_;
    my $id = $sim->[1];
    if ($id !~ /^fig\|/) { return undef }
    my $figO = new FIGO;
    return FeatureO->new($figO, $id);
}

=head2 iden

    my $percent = $sim->iden;

Return the percentage identity between the query and database sequences.

=cut

sub iden {
    my ($sim) = @_;
    return $sim->[2];
}

=head2 ali_ln

    my $chars = $sim->ali_ln;

Return the length (in characters) of the alignment between the two similar sequences.

=cut

sub ali_ln {
    my ($sim) = @_;
    return $sim->[3];
}

=head2 mismatches

    my $count = $sim->mismatches;

Return the number of alignment positions that do not match.

=cut

sub mismatches {
    my ($sim) = @_;
    return $sim->[4];
}

=head2 gaps

    my $count = $sim->gaps;

Return the number of gaps required to align the sequences.

=cut

sub gaps {
    my ($sim) = @_;
    return $sim->[5];
}

=head2 b1

    my $beginOffset = $sim->b1;

Return the position in the query sequence at which the alignment begins.

=cut

sub b1 {
    my ($sim) = @_;
    return $sim->[6];
}

=head2 e1

    my $endOffset = $sim->e1;

Return the position in the query sequence at which the alignment ends.

=cut

sub e1 {
    my ($sim) = @_;
    return $sim->[7];
}

=head2 b2

    my $beginOffset = $sim->b2;

Position in the database sequence at which the alignment begins.

=cut

sub b2 {
    my ($sim) = @_;
    return $sim->[8];
}

=head2 e2

    my $endOffset = $sim->e2;

Return the position in the database sequence at which the alignment ends.

=cut

sub e2 {
    my ($sim) = @_;
    return $sim->[9];
}

=head2 psc

    my $score = $sim->psc;

Return the similarity score as a floating-point number. The score is the computed
probability that the similarity is a result of random chance. A score of 0 indicates a
perfect match. A higher score indicates a less-perfect match. Values of C<1e-10> or
less are considered good matches.

=cut

sub psc {
    my ($sim) = @_;
    return ($sim->[10] =~ /^e-/) ? "1.0" . $sim->[10] : $sim->[10];
}

=head2 bsc

    my $score = $sim->bsc;

Return the bit score for this similarity. The bit score is an estimate of the
search space required to find the similarity by chance. A higher bit score
indicates a better match.

=cut

sub bsc {
    my ($sim) = @_;
    return $sim->[11];
}

=head2 bsc

    my $score = $sim->bit_score;

Return the bit score for this similarity. The bit score is an estimate of the
search space required to find the similarity by chance. A higher bit score
indicates a better match.

=cut

sub bit_score {
    my ($sim) = @_;
    return $sim->bsc;
}

=head2 nbsc

    my $score = $sim->nbsc;

Return the normalized bit score for this similarity. This is the bit score
divided by the length of the matching sequence regions.  It is a better
summary of the overall sequence similarity than is the percentage identity.
Typically identical sequences have a value close to 2, and it goes down to
0 as the similarity decreases (values less than 0 are possible, but are never
significant and hence are never reported in a local similarity search).

=cut

sub nbsc {
    my($sim) = @_;

    my $min_ln = &min( abs( $sim->e1 - $sim->b1 ), abs( $sim->e2 - $sim->b2 ) ) + 1;

    return $min_ln > 1 ? sprintf("%4.2f",$sim->bit_score / $min_ln) : undef;
}

sub min {
    my($x,$y) = @_;
    return ($x < $y) ? $x : $y;
}

=head2 ln1

    my $length = $sim->ln1;

Return the number of characters in the query sequence.

=cut

sub ln1 {
    my ($sim) = @_;
    return $sim->[12];
}

=head2 ln2

    my $length = $sim->ln2;

Return the length of the database sequence.

=cut

sub ln2 {
    my ($sim) = @_;
    return $sim->[13];
}

=head2 tool

    my $name = $sim->tool;

Return the name of the tool used to find this similarity.

=cut

sub tool {
    my ($sim) = @_;
    return $sim->[14];
}

sub def2 {
    my ($sim) = @_;
    return $sim->[15];
}

sub ali {
    my ($sim) = @_;
    return $sim->[16];
}

=head2 usage

    my $pod_as_text = Module::usage;
    my $pod_as_text = Module->usage;
    my $pod_as_text = Package->usage;
    my $pod_as_text = $object->usage;

Returns the module's pod documentation as text.

=cut

sub usage {
    seek(DATA,0,0)                          or return '';
    eval { require Pod::Text }              or return '';
    my $podout;
    open(PODOUT, '>', \$podout)             or return '';
    my $pod = Pod::Text->new( width => 79 ) or return '';;
    $pod->parse_from_filehandle( \*DATA, \*PODOUT );
    close( PODOUT );
    $podout || '';
}

1;


