use strict;
use Data::Dumper;
use Carp;
use gjoseqlib;

#
# This is a SAS Component
#

=head1 svr_just_ends

Clip off the ends of a set of contigs

=head2 Introduction

Example:

    svr_just_ends -ln 500 < contigs > just.ends


=head2 Command-Line Arguments

The program is invoked using

    svr_just_ends [-ln=N] < contigs > clipped.ends

where B<contigs> is a fasta file (usually containing DNA)

=over 4

=item -ln=N

Take N characters from each end (1000 is the default)

=back

=head2 Output

A fasta file of ends of contigs.  The IDs will be of the form

    Contig_1_N  (e.g., contig1_1_1000) or
    Contig_x_y  where y is the length of the contig (e.g., contig2_232_1231)

=cut

use Getopt::Long;
my $ln = 1000;
my $usage = "svr_just_ends [-ln=N]< contigs > clipped.ends\n";

my $rc = GetOptions( "ln=i" => \$ln );
$rc or print STDERR $usage and exit;

my @contigs = &gjoseqlib::read_fasta;
foreach my $tuple (@contigs)
{
    my($id,undef,$seq) = @$tuple;
    my $contig_ln = length($seq);
    if ($contig_ln >= 2000)
    {
	my $id1   = join("_",($id,1,1000));
	my $seq1  = substr($seq,0,1000);
	my $id2   = join("_",($id,$contig_ln - ($ln-1),$contig_ln));
	my $seq2  = substr($seq,$contig_ln - $ln, $ln);
	print ">$id1\n$seq1\n";
	print ">$id2\n$seq2\n";
    }
    else
    {
	my $id1 = join("_",($id,1,$contig_ln));
	print ">$id1\n$seq\n";
    }
}
