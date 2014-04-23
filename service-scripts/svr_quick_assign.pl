#
# This is a SAS Component
#

=head1 svr_quick_assign -d Data.kmers

Use staged-kmers (new, followed by old on hypotheticals)

------

Example:

    svr_quick_assign [-d Data.kmers] < aa.seq.fasta > id-func.table

This simple script just runs new kmer annotation, and for sequences that do not
get asigned a function, an attempt will be made using the older kmers (built on FIGfams).

=cut

use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;
use gjoseqlib;

my $usage = "usage: svr_quick_assign [ -d Data] < aa.seq.fasta > id-func.table\n";
my $dataD ="/homes/overbeek/Ross/MakeCS/Data/Data.kmers";  # get better deafult mechanism someday

my $rc  = GetOptions('d=s' => \$dataD);
if (! $rc)
{ 
    print STDERR $usage; exit ;
}

my @all = &gjoseqlib::read_fasta();;
open(CALLS,"| kmer_search -d $dataD -a 2> /dev/null | cut -f1,2 > tmp.$$.km.calls") || die "could not write to tmp.$$.km.calls";
foreach my $tuple (@all)
{
    my($id,undef,$seq) = @$tuple;
    print CALLS ">$id\n$seq\n";
}
close(CALLS);
my %called = map { ($_ =~ /^(\S+)\t(\S.*\S)/) ? ($1 => 1) : () } `cat tmp.$$.km.calls`;
open(CALLS,"| svr_assign_using_figfams 2> /dev/null | cut -f2,3 | grep -v hypothetical -i >> tmp.$$.km.calls") || die "could not extend tmp.$$.km.calls";
foreach my $tuple (grep { ! $called{$_->[0]} } @all)
{
    my($id,undef,$seq) = @$tuple;
    print CALLS ">$id\n$seq\n";
}
close(CALLS);
open(CALLS,"<tmp.$$.km.calls") || die "could not open tmp.$$.km.calls";
while (defined($_ = <CALLS>))
{
    print $_;
}
close(CALLS);
unlink("tmp.$$.km.calls");
