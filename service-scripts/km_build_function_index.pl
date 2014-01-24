########################################################################
use strict;
use Data::Dumper;
use SeedUtils;
use Getopt::Long;

my $usage = "usage: km_build_function_index -d DataDir\n";
my $dataD;
my $rc  = GetOptions('d=s' => \$dataD);

if ((! $rc) || (! -d $dataD))
{ 
    print STDERR $usage; exit ;
}

$ENV{'SAS_SERVER'} = 'PUBSEED';
open(ASSIGNMENTS,"cut -f2 $dataD/genomes | svr_all_features peg | svr_function_of |")
    || die "cannot access assignments";

if (! -s "$dataD/function.index")
{
    my %funcs;
    while (defined($_ = <ASSIGNMENTS>))
    {
	if ($_ =~ /^\S+\t(\S.*\S+)/)
	{
	    my $stripped = &SeedUtils::strip_func($1);   #### CHECK THIS
	    $funcs{$stripped}++;
	}
    }
    close(ASSIGNMENTS);
    open(FI,">$dataD/function.index") || die "could not open $dataD/function.index";

    my $nxt = 0;
    foreach my $f (sort keys(%funcs))
    {
	if (($funcs{$f} > 5)  && ((! &SeedUtils::hypo($f)) || ($f =~ /FIG/)))
	{
	    print FI "$nxt\t$f\n";
	    $nxt++;
	}
    }
}
close(FI);
