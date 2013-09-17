use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_functionally_coupled

Get functionally_coupled neighbors (neighbors that tend to co-occur).

------

Example:

    svr_all_features 3702.1 peg | svr_functionall_coupled

would produce a 3-column table.  The first column would contain
PEG IDs for genes occurring in genome 3702.1, the second would give the
functional coupling score, and the third would give the PEG that
is functionally coupled.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG for which functions are being requested.
If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -max MaxReturned [default 1000000]

This is used to restrict the number of results displayed for a single incoming line (not a restriction
on the number of tatal lines)

=item -n MinSc  [default 15]						    

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of lines from
the input file that are for PEGs that are functionally coupled.
The lines will have two appended columns: the functional coupling
score (number of distinct OTUs in which the pair co-occur), and the
functionally coupled PEG.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_functionally_coupled [-c column] [-max MaxReturned] [-n MinScore]";

my $column;
my $maxR  = 100000;
my $minsc = 15;
my $rc  = GetOptions('c=i'    => \$column,
		     'n=i'    => \$minsc,
		     'max=i'  => \$maxR);
if (! $rc) { print STDERR $usage; exit }

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
if (! $column)  { $column = @{$lines[0]} }
my @fids = map { $_->[$column-1] } @lines;

my $coupledH = $sapObject->conserved_in_neighborhood(-ids => \@fids);
foreach $_ (@lines)
{
    my $peg = $_->[$column-1];
    if (my $x = $coupledH->{$peg})
    {
	my @to_print = sort { $b->[0] <=> $a->[0] } grep { $_->[0] >= $minsc } @$x;
	if (@to_print > $maxR) { $#to_print = $maxR-1 }
	foreach my $tuple (@to_print)
	{
	    print join("\t",(@$_,$tuple->[0],$tuple->[1])),"\n";
	}
    }
}
