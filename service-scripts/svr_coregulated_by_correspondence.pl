use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_coregulated_by_correspondence [-m MinPCC] [-f] [-n MaxConn] [G1 G2 G3 ...]

Get genes that have evidence of coexpression indirectly (i.e.,
it seems to exist between corresponding genes in one or more
other genomes with expression data).

------

Example:

    svr_all_features 83333.1 peg | svr_coregulated_by_correspondence -m 0.8 83333.1

would produce a 3-column table.  The first column would contain
PEG IDs for genes occurring in genome 83333.1, the second would give "relevant evidence
from genes in 83333.1, and the third would give the PEG that
seems to have a similar expression profile.  Note that this would probably be an enormous
file for reasons we will explain below.  Unless you use the -n option (say, -n 30), you should
probably run only a small set of genes as input.

The notion of "relevant evidence" is composed of a number of entries
separated by semi-colons (one entry per genome with corresponding genes
correlated by expression data).  Each such entry is a triple of 

     "Gene1,PCC,Gene2"

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

=item -m MinPCC

Minimum value for the Pearson correlation coefficient

=item -b 

Show only the best indirect correlation

=item -f 

Requests a full display.  This produces 1 line per item of supporting evidence.
It is the "expanded" format with functions of PEGs displayed.  Do not use it
for more than a relatively small set of PEGs (or you may get flooded in output).

=item -n MaxConnections   [default is 50]

Often two genes have a common expression pattern just because they are both "on"
in all experiments or both are "off" all the time.  When you use indirect evidence 
from other organisms, this can balloon the output.  This parameter says "Consider
only genes that have correlation coefficients above 0.9 for MaxConnections genes or
less.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of lines from
the input file that are for PEGs that have Pearson correlation
coefficients that indicate potential correlation.  The lines will have
two appended columns: the relevant evidence and the
functionally PEG that appears to have a correlated profile.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_coregulated_by_correspondence [-m MinPCC] [-f] [-n MaxConn] [G1 G2 G3 ...]";

my $column;
my $min_pcc = 0;
my $full = 0;
my $max_conn = 50;
my $only_best;
my $rc  = GetOptions('c=i' => \$column,
		     'f'   => \$full,
		     'b'   => \$only_best,
		     'n=i' => \$max_conn,
		     'm=f' => \$min_pcc);

if (! $rc) { print STDERR $usage; exit }
my @genomes = grep { $_ =~ /^\d+\.\d+$/ } @ARGV;

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
if (! $column)  { $column = @{$lines[0]} }
my @fids = grep { $_ =~ /^fig\|\d+\.\d+/ } map { $_->[$column-1] } @lines;

my $corrH = $sapObject->coregulated_correspondence(-ids => \@fids,
                                                   -m   => $min_pcc,
                                                   (@genomes > 0) ? ('-genomes' => \@genomes) : ());

my %to;
foreach my $line (@lines)
{
    my $peg = $line->[$column-1];
    if (my $x = $corrH->{$peg})
    {
	my %counts;
	my %need_func;
	my $funcH;
	foreach my $tuple (@$x)
	{
	    my($peg2,$peg3,$peg4,$pcc) = @$tuple;
	    $counts{$peg3}++;

	    $pcc = sprintf("%0.3f",$pcc);
	    if ($pcc >= $min_pcc)
	    {
		if ($full)
		{
		    $need_func{$peg2} = 1;
		    $need_func{$peg3} = 1;
		    $need_func{$peg4} = 1;
		}
		push(@{$to{$peg2}},[$peg3,$pcc,$peg4]);
	    }
	}

	if ($full)
	{
	    my $ids = [keys(%need_func)];
	    $funcH = $sapObject->ids_to_functions( -ids => $ids );
	}

	foreach my $peg2 (keys(%to))
	{
	    next if ($peg eq $peg2);
	    my @ok = grep { $max_conn >= $counts{$_->[0]} } @{$to{$peg2}};

	    if (@ok > 0)
	    {
		foreach my $tuple (@ok)
		{
		    my($peg3,$pcc,$peg4) = @$tuple;
		    if ($only_best)
		    {
			my @tmp = sort { $b->[2] <=> $a->[2] } 
			          map { [split(/,/,$_)] }
				  split(/;/,$pcc);
			$pcc    = join(",",@{$tmp[0]});
		    }
								     
		    if ($full)
		    {
			my $func2            = &function($funcH,$peg2);
			my $func3            = &function($funcH,$peg3);
			my $func4            = &function($funcH,$peg4);
			print join("\t",(@$line,$func3,$peg3,$pcc,$func4,$peg4,$func2,$peg2)),"\n";
		    }
		    else
		    {
			print join("\t",(@$line,$peg3,$pcc,$peg4,$peg2)),"\n";
		    }
		}
	    }
	}
    }
}

sub function {
    my($funcH,$peg) = @_;
    my $x = $funcH->{$peg};
    return $x ? $x : '';
}
