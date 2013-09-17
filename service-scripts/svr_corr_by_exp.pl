
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_corr_by_exp [-m MinPCC]

Get genes that have similar expression profiles.

------

Example:

    svr_all_features 83333.1 peg | svr_corr_by_exp

would produce a 3-column table.  The first column would contain
PEG IDs for genes occurring in genome 83333.1, the second would give the
Pearson correlation coefficient, and the third would give the PEG that
seems to have a similar expression profile..

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

=item -m Minimum value for the Pearson correlation coefficient

=item -max MaxReturned [default 1000000]

This is used to restrict the number of results displayed for a single incoming line (not a restriction
on the number of tatal lines)

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of lines from
the input file that are for PEGs that have Pearson correlation
coefficients that indicate potential correlation.  The lines will have
two appended columns: the Pearson correlation coefficient and the
functionally PEG that appears to have a correlated profile.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_corr_by_exp [-c column] [-m minPCC] [-max MaxReturned]";

my $column;
my $maxR  = 100000;
my $min_pcc = 0;
my $rc  = GetOptions('c=i' => \$column,
		     'max=i'  => \$maxR,
		     'm=f' => \$min_pcc);

if (! $rc) { print STDERR $usage; exit }

while (my @tuples = ScriptThing::GetBatch(\*STDIN, 5, $column)) {
    my $corrH = $sapObject->coregulated_fids(-ids => [map { $_->[0] } @tuples]);
    foreach my $tuple (@tuples) {
	my $printed = 0;
	my ($peg, $line) = @$tuple;
	if (my $x = $corrH->{$peg}) {
	    my @pegs2 = keys(%$x);
	    foreach my $peg2 (@pegs2) {
		my $pcc = sprintf("%0.3f",$x->{$peg2});
		if ($pcc >= $min_pcc)
		{
		    if ($printed < $maxR)
		    {
		        print join("\t",($line,$pcc,$peg2)),"\n";
			$printed++;
		    }
		}
	    }
	}
    }
}