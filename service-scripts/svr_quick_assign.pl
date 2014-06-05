########################################################################
#
# This is a SAS Component
#

=head1 svr_quick_assign -d Data.kmers

Use staged-kmers (new, followed by old on hypotheticals)

------

Example:

    svr_quick_assign [-dc Data.kmers] [-dp Data.kmers] < aa.seq.fasta > id-func.table

This simple script just runs new kmer annotation, and for sequences that do not
get asigned a function, an attempt will be made using the older kmers (built on FIGfams).

=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;
use gjoseqlib;
use File::Temp 'tempfile';

my $usage = "usage: svr_quick_assign < aa.seq.fasta > id-func.table\n";
my $dataD ="/homes/overbeek/Ross/MakeCS/Data";  # contains Data.kmers for coreSEED, Data.kmers.pub for pubSEED
my $dataDC = "$dataD/Data.kmers";
my $dataDP = "$dataD/Data.kmers.pub";

my($calls_fh, $calls_file) = tempfile();
close($calls_fh);

my @all = &gjoseqlib::read_fasta();;
open(CALLS,"| kmer_search -d $dataDC -a 2> /dev/null | cut -f1,2 > $calls_file") || die "could not write to $calls_file";
foreach my $tuple (@all)
{
    my($id,undef,$seq) = @$tuple;
    print CALLS ">$id\n$seq\n";
}
close(CALLS);
my %called = map { ($_ =~ /^(\S+)\t(\S.*\S)/) ? ($1 => $2) : () } `cat $calls_file`;
open(CALLS,"| kmer_search -d $dataDP -a 2> /dev/null | cut -f1,2 >> $calls_file") || die "could not write to $calls_file";
foreach my $tuple (grep { (! $called{$_->[0]}) || ($called{$_->[0]} eq "hypothetical protein") } @all)
{
    my($id,undef,$seq) = @$tuple;
    print CALLS ">$id\n$seq\n";
}
close(CALLS);
%called = map { ($_ =~ /^(\S+)\t(\S.*\S)/) ? ($1 => $2) : () } `cat $calls_file`;
unlink($calls_file);

foreach my $tuple (@all)
{
    my $id = $tuple->[0];
    if ($_ = $called{$id})
    {
	print $id,"\t",$_,"\n";
    }
}
