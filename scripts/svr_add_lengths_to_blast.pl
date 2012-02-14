use strict;
use Data::Dumper;
use Carp;
use gjoseqlib;

#
# This is a SAS Component
#


=head1 svr_add_lengths_to_blast

Add query and contig lengths to m8 blast output

------

Example:

    svr_add_lengths_to_blast -i queryF -d db < blast.m8 > with.2.extra.columns

=head2 Command-Line Options

=over 4

=item -i queryF

This gives the name of the file containing the query sequences  in FAST format

=item -d db

This gives the name of the file containing the db contigs in FAST format

=back

=head2 Output Format

The output is the m8 blast output with two columns added.  The first
is the length of the query sequence, and the second is the length
of the db contig.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_add_lengths_to_blast -i queryF -d dbF";

my $queryF;
my $dbF;
my $rc  = GetOptions('i=s' => \$queryF, 'd=s' => \$dbF);
if ((! $rc) || (! $queryF) || (! $dbF)) { print STDERR $usage; exit }

my @query_seqs = &gjoseqlib::read_fasta($queryF);
my %queryH = map { ($_->[0] => length($_->[2])) } @query_seqs;

my @db_seqs = &gjoseqlib::read_fasta($dbF);
my %dbH = map { ($_->[0] => length($_->[2])) } @db_seqs;

while (defined($_ = <STDIN>))
{
    chop;
    my @flds = split(/\s+/,$_);
    print join("\t",@flds),"\t",$queryH{$flds[0]},"\t",$dbH{$flds[1]},"\n";
}
