use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 svr_link_to_compare_regions

Get link to compare regions organized to show co-occuring genes

------

Example:

    echo 'fig|83333.1.peg.4' | svr_link_to_compare_regions > 2-col.txt

would produce a 2-column table (in this case containing a single row).  
The first column would contain a PEG id (in this case fig|83333.1.peg.4)
and the second a URL to illustrate conserved contiguity.

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

=item -b Base of URL (to the appropriate SEED) [default=http://pubseed.theseed.org which is the PubSEED]

This allows the user to specify which SEED he wishes the links to point at

=item -m Minimum Functional Coupling Score [default=10]

This parameter lets the user give a minimum FC score (which is the number of
distinct OTUs in which co-occurrence has been detected).

=item -g GenomesFile [an optional file designating a restricted list of genomes for the links]

This allows the user to restrict the compare region to a limited set of genomes.

=item -show N [default is 10]
k
This gives the number of genomes to actually show.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the URL to produce the desired compare region).

=cut

use SeedUtils;
use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_link_to_compare_regions [-c column] [-m MinFC] [-b BaseURL] [-g GenomesFile] [-show N]";

my $column;
my $minFC = 10;
my $show  = 10;
my $base = "http://pubseed.theseed.org";
my $genomeF;

my $rc  = GetOptions('c=i' => \$column,
		     'm=i' => \$minFC,
		     'b=s' => \$base,
		     'g=s' => \$genomeF,
		     'show=s' => \$show
		     );
if (! $rc) { print STDERR $usage; exit }
my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
(@lines > 0) || exit;
if (! $column)  { $column = @{$lines[0]} }
my @fids = map { $_->[$column-1] } @lines;
my $fcH  = $sapO->conserved_in_neighborhood( -ids => \@fids);

my %genomeH;
if ($genomeF && (-s $genomeF) && open(G,"<",$genomeF))
{
    %genomeH = map { ($_ =~ /(\d+\.\d+)/) ? ($1 => 1) : () } <G>;
    close(G);
}

my @pairs;
my %urlH;
foreach my $peg (keys(%$fcH))
{
    my $hits       = $fcH->{$peg};
    my @fc         = map  { $_->[1] } 
                     sort { $b->[0] <=> $a->[0] }
                     grep { $_->[0] >= $minFC } @{$hits};
    if (@fc)
    {
	push(@pairs,[$peg,[@fc]]);
    }
}
my @flattened = map { my($p,$xL) = @$_; map { join(":",($p,$_)) } @$xL } @pairs;
my $pairH     = $sapO->co_occurrence_evidence( -pairs => \@flattened);
foreach my $pair (@pairs)
{
    my($peg1,$pegs2) = @$pair;
    my %anchored;
    my $i;
    for ($i=0; ($i < @$pegs2); $i++)
    {
	my $peg2 = $pegs2->[$i];
	my $ev = $pairH->{"$peg1:$peg2"};
	if ($ev)
	{
	    foreach my $pair2 (@$ev)
	    {
		if ((! $anchored{$pair2->[0]}) && 
		    ((! $genomeF) || $genomeH{&SeedUtils::genome_of($pair2->[0])}))
		{
		    $anchored{$pair2->[0]} = $i;
		}
	    }
	}
    }
    my @pin = ($peg1,sort { $anchored{$b} <=> $anchored{$b} } keys(%anchored));
    if (@pin > $show) { $#pin = $show-1 }
    my $url = "$base/seedviewer.cgi?page=Regions&" . join("&",map { "feature=$_" } @pin);
    $urlH{$peg1} = $url;
}
    
foreach $_ (@lines)
{
    my $peg = $_->[$column-1];
    my $url = $urlH{$peg};
    if (! $url) { $url = '' }
    print join("\t",(@$_,$url)),"\n";
}
