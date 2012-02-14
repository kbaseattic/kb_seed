use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use SeedEnv;

my $usage = "usage: CSA_make_conn DirOfGenomes ComparisonDirectories";
my($inD,$outD);

(
 ($inD  = shift @ARGV) && opendir(IN,$inD) &&
 ($outD = shift @ARGV) 
)
    || die $usage;

my @genomes = sort { ($a <=> $b) or ($a cmp $b) } grep { $_ =~ /^\d+\.\d+$/ } readdir(IN);
closedir(IN);

mkdir($outD,0777) || warn "extending existing directory\n";
foreach my $g1 (@genomes)
{
    foreach my $g2 (@genomes)
    {
	if (($g1 ne $g2) && (! -s "$outD/$g1-$g2/layout.after.first.pass"))
	{
	    &run("perl CSA_get_pins.pl $inD/$g1 $inD/$g2 $outD/$g1-$g2 ../Data/TBLs/$g1/peg/tbl ../Data/TBLs/$g1/rna/tbl ../Data/Functions/$g1");
	}
    }
}

sub run {
    my($cmd) = @_;

    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}

