use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use Carp;
use SeedEnv;

my $usage = "usage: CSA_layout WorkingDir PegTbl1 RnaTbl1 Functions1";

my($dir,$peg_tbl1,$rna_tbl1,$functions1);
(
 ($dir           = shift @ARGV) && (-s "$dir/output.second.pass") &&
 ($peg_tbl1       = shift @ARGV) && (-s $peg_tbl1) &&
 ($rna_tbl1       = shift @ARGV) && (-s $rna_tbl1) &&
 ($functions1     = shift @ARGV) && (-s $functions1)
)
    || die $usage;

my %func_of   = map { ($_ =~ /^(fig\S+)\t(\S.*\S)/) ? ($1 => $2) : () } `cat $functions1`;
my %to_abbrev = map { $_ =~ /^(\S+)\t(\S+)/; ($2 => $1) } `cat $dir/index1`;
my $n = 0;
my @pins      = map { chop; [split(/\t/,$_)] } `cat $dir/output.second.pass`;
my @repeats   = map { chop; [split(/\t/,$_)] } `cat $dir/repeats2`;

my @points;
@pins = sort { ($a->[0] cmp $b->[0]) || ($a->[1] <=> $b->[1]) } @pins;
my $n = 1;
foreach my $_ (@pins)
{
    push(@points,[$_->[3],$_->[4],'start',$_->[6] . ":" . $n]);
    push(@points,[$_->[3],$_->[5],'start',$_->[6] . ":" . $n++]);
}

$n = 1;
foreach my $_ (@repeats)
{
    push(@points,[$_->[0],$_->[1],'start','repeat' . ":" . $n]);
    push(@points,[$_->[0],$_->[2],'end','repeat' . ":" . $n++]);
}

my $mapped = 0;
my $not_mapped = 0;
foreach $_ (`cat $peg_tbl1`,`cat $rna_tbl1`)
{
    if ($_ =~ /^(fig\|\S+)\t(\S+)/)
    {
	my $peg = $1;
	my($contig,$left,$right,$strand) = &SeedUtils::boundaries_of($2);
	my($beg,$end) = ($strand eq "+") ? ($left,$right) : ($right,$left);
	my $f = $func_of{$peg} ? $func_of{$peg} : '';
	my($ptB,$ptE);

	if ($ptB = &locate($to_abbrev{$contig},$beg,\@pins))
	{
	    push(@points,[@$ptB,'start',$peg,$f]);
	    $mapped++;
	}
	else
	{
	    $not_mapped++;
	}

	if (my $ptE = &locate($to_abbrev{$contig},$end,\@pins))
	{
	    push(@points,[@$ptE,'end',$peg,$f]);
	    $mapped++;
	}
	else
	{
	    $not_mapped++;
	}
    }
}
@points = sort { ($a->[0] cmp $b->[0]) or ($a->[1] <=> $b->[1]) } @points;
print "mapped gene boundaries   = $mapped\n";
print "unmapped gene boundaries = $not_mapped\n";
foreach my $pt (@points)
{
    print join("\t",@$pt),"\n";
}

sub locate {
    my($contig,$x,$pins) = @_;

    foreach $_ (@$pins)
    {
	my($c1,$b1,$e1,$c2,$b2,$e2) = @$_;
	if (($contig eq $c1) && ($x >= $b1) && ($x <= $e1))
	{
	    my $incr = $x - $b1;
	    return [$c2,($b2 < $e2) ? ($b2 + $incr) : ($b2 - $incr)];
	}
    }
    return undef;
}
