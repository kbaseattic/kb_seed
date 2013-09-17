use strict;
use Data::Dumper;
use Carp;
use SeedEnv;

#
# This is a SAS Component
#


=head1 svr_atomic_reg_coexp

Get functions of protein-encoding genes

------

Example:

    svr_atomic_reg_coexp -g 83333.1 -ar 514

would produce a table showing the pegs that tended to be coexpressed
with those in atomic regulon 514 of E,coli (genome 83333.1).
Each row lists a peg (which has correlation, but is not in the atomic regulon)

The first column contains the "coexpresssed peg", the second the average
Peasrson correlation coefficient against the pegs in the atomic regulon,
and the subsequent collumns show scores against each peg in the atomic regulon. 

------

=head2 Command-Line Options

=over 4

=item -g Genome (must have expression data)

=item -ar Atomic Regulon ID
=cut

use SeedUtils;
use SAPserver;
my $sapO= SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_atomic_reg_coexp -g genome -ar AtomicRegulonID";

my $genome;
my $ar;
my $rc  = GetOptions('g=s' => \$genome, 
		     'ar=s' => \$ar,);

if ((! $rc) || (! $genome) || (! $ar)) { print STDERR $usage; exit }

my $arH     = $sapO->atomic_regulons( -id => $genome );
if ($arH)
{
    my $fids    = $arH->{"$genome:$ar"};
    if ($fids)
    {
	my $coexpH  = $sapO->coregulated_fids( -ids => $fids );
	if ($coexpH)
	{
	    my @pegs_in_ar = sort { &SeedUtils::by_fig_id($a,$b) } keys(%$coexpH);
	    print "\t\t". join("\t",map { $_ =~ /^\S+\.(\d+)$/; $1 } @pegs_in_ar),"\n";
	    my %hits;
	    foreach my $peg (@pegs_in_ar)
	    {
		my $h = $coexpH->{$peg};
		foreach my $peg2 (keys(%$h))
		{
		    if ((! $coexpH->{$peg2}) && ($h->{$peg2} >= 0.5))
		    {
			$hits{$peg2}->{$peg} = $h->{$peg2};
		    }
		}
	    }
	    my %to_col;
	    for (my $i=0; ($i < @pegs_in_ar); $i++)
	    {
		$to_col{$pegs_in_ar[$i]} = $i+2;
	    }

	    my @rows;
	    foreach my $peg2 (keys(%hits))
	    {
		my $h = $hits{$peg2};
		my @in = keys(%$h);
		my $row = [$peg2,0.0];
		for (my $i=2; ($i < (@pegs_in_ar+2)); $i++)
		{
		    $row->[$i] = ' ';
		}
		my $sc = 0;
		foreach my $peg (@in)
		{
		    $sc += $h->{$peg};
		    $row->[$to_col{$peg}] = sprintf("%0.3f",$h->{$peg});
		}
		$row->[1] = sprintf("%0.3f",$sc/@pegs_in_ar);
		if ($row->[1] >= 0.5)
		{
		    push(@rows,$row);
		}
	    }
	    foreach my $row (sort { $b->[1] <=> $a->[1] } @rows)
	    {
		print join("\t",@$row),"\n";
	    }
	}
    }
}

		
		
	    
