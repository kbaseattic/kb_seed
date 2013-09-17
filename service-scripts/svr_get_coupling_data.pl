########################################################################

use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_get_coupling_data [-g genome] -d CouplingDirectory

Get functional coupling data for genes in a genome

------

Example:

    svr_get_coupling_data -d 83333.1.Coupling -g 83333.1

Would build a directory containing the following files:

    functionally.coupled                   - a 3-column table giving basic fc scores
    functionally.coupled.hypos             - a 4-column table [hypo-PEG,fc-score,nonHypo-PEG,nonHypo-function]
    functionally.coupled.hypos.by.peg      - functionally.coupled.hypos sorted by PEG

    expression.coupled                     - a 3-column table giving basic fc scores (Pearson Correlation coefficients)
    expression.coupled.hypos               - a 4-column table [hypo-PEG,fc-score,nonHypo-PEG,nonHypo-function]
    expression.coupled.hypos.by.peg        - expression.coupled.hypos sorted by PEG

------

The genome is normally taken from the command line.  If it is not,
it is read from STDIN and a separate output directory is constructed for
each genome ID.

Normally, the last field in each
line would contain the genome ID.
If some other column contains the genome IDs, use

    -c N

where N is the column (from 1).

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -g GenomeID

This is normally used to get the genome ID, and in this case output for a single genome is constructed.
If it is not used, genome IDs are read from STDIN.

=item -c Column

This is used only if there is no -g parameter and the  column containing genome IDs is not the last.

=item -d CouplingDirectory

If -g Genome is used, this directory gets built and will contain the data files for the genome.
If not, then this directory gets built. Subdirectories (named the genome ID) will get the
output files for each genome named in the input. 

=back

=head2 Output Format

If -g Genome is used, the output directory will contain the files for the single genome.
If not, the output directory will have a subdirectory for each genome specified in STDIN (named
by the genome ID).

=cut

use SeedUtils;
use Getopt::Long;

my $usage = "usage: svr_get_coupling_data [-c column] [-g Genome] -d OuputDirectory";

my $column;
my $g;
my $outputD;

my $rc  = GetOptions('c=i' => \$column,
		     'g=s'  => \$g,
		     'd=s' => \$outputD);

if ((! $rc) || (! $outputD)) { print STDERR $usage; exit }
mkdir($outputD,0777) || die "could not make $outputD";

my @lines;
if ($g)
{
    @lines = ([$g]);
}
else
{
    @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
}
if (! $column)  { $column = @{$lines[0]} }

open(EXP,"svr_exp_genomes |") || die "cannot get which genomes have expression data";
my %has_expression = map { $_ =~ /(\d+\.\d+)$/; ($1 => 1) } <EXP>;
close(EXP);

foreach $_ (@lines)
{
    my $genome = $_->[$column-1];
    my $subD;
    if ($g)
    {
	$subD = $outputD;
    }
    else
    {
	$subD = "$outputD/$genome";
	mkdir($subD,0777) || die "could not make $subD";
    }
    &SeedUtils::run("echo $genome | svr_all_features peg | svr_functionally_coupled -n 20 > $subD/functionally.coupled");
    &SeedUtils::run("sort +1nr -2 +0 -1 $subD/functionally.coupled | svr_is_hypo -c 1 | svr_is_hypo -v | svr_function_of > $subD/functionally.coupled.hypos");
    &SeedUtils::run("sort +0 -1 +1nr -2 $subD/functionally.coupled.hypos > $subD/functionally.coupled.hypos.by.peg");
    if ($has_expression{$genome})
    {
	&SeedUtils::run("echo $genome | svr_all_features peg | svr_corr_by_exp -max 10 > $subD/exp.coupled");
	&SeedUtils::run("sort +1nr -2 +0 -1 $subD/exp.coupled | svr_is_hypo -c 1 | svr_is_hypo -v | svr_function_of > $subD/exp.coupled.hypos");
	&SeedUtils::run("sort +0 -1 +1nr -2 $subD/exp.coupled.hypos > $subD/exp.coupled.hypos.by.peg");
    }
}
