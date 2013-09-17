use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_in_fasta

This little script just takes a fasta file of PEGs as input and
outputs a 3-column table [PEG,function,sequence].

Thus, 

    svr_in_fasta < fasta.file | cut -f1,2  

would be normally used to see the functions of the sequences
in a fgasta file.

=cut

use gjoseqlib;

my @seqs = &gjoseqlib::read_fasta();
use SAPserver;
my $sapO = SAPserver->new;
my @pegs = map { $_->[0] } @seqs;
my $seqH = $sapO->ids_to_functions( -ids => \@pegs );
foreach $_ (@seqs)
{
    my $func = $seqH->{$_->[0]};
    if (! $func) { $func = "hypothetical protein" }
    print join("\t",($_->[0],$func,$_->[2])),"\n";
}
