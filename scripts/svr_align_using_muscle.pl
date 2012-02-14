# This is a SAS component
#
use gjoseqlib;
use gjoalignment;
use strict;

my $usage = "usage: svr_align_using_muscle [Seqs Alignment]";

my($seqs,$ali);
if (@ARGV > 1)
{
    my $seqs = &gjoseqlib::read_fasta($ARGV[0]);
    my $ali  = &gjoalignment::align_with_muscle($seqs);
    &gjoseqlib::print_alignment_as_fasta($ali,0,$ARGV[1]);
}
else
{
    my $seqs = &gjoseqlib::read_fasta();
    my $ali  = &gjoalignment::align_with_muscle($seqs);
    &gjoseqlib::print_alignment_as_fasta($ali);
}
