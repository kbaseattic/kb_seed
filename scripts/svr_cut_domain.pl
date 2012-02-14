use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_cut_domain

Clip domains out of a set of protein sequences

------

Example:

    svr_cut_domain domain_desc < fasta > fasta.of.domains

would read a 3-column table (domain_desc) in which each line
contains [ID,Begin,End].  The complete protein sequences are
read from STDIN.  A fasta file of the extracted domains is written
to STDOUT.

------

=cut

use SeedUtils;

my $usage = "usage: svr_cut_domain DomainDesc < protein_seqs.fasta > domain_seqs.fasta";
($ARGV[0] && open(DOM,"<",$ARGV[0])) || die $usage;

my %seqs;
$/ = "\n>";
while (defined($_ = <STDIN>))
{
    chomp;
    my($id,$seq);
    if ($_ =~ /^>?(\S+)[^\n]*\n(.*)/s)
    {
	$id  = $1;
	$seq = $2;
	$seq    =~ s/\s//g;
    }
    if ($seqs{$id}) { die "$id occurs multiple times in the input collection" }
    $seqs{$id} = $seq;
}

$/ = "\n";
while (defined($_ = <DOM>))
{
    my $domain;
    if (($_ =~ /^(\S+)\t(\d+)\t(\d+)\s*$/) && $seqs{$1} && ($domain = substr($seqs{$1},$2-1,(($3+1)-$2))))
    {
	print ">$1\n$domain\n";
    }
    else
    {
	die "bad input: $_";
    }
}
