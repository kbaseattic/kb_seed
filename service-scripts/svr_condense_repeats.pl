use strict;
use Data::Dumper;
use SeedEnv;

#
# This is a SAS Component
#

# condenses table produced by svr_big_repeats to a 4-column table:
#
#   contig
#   beginning coordinate
#   ending coordinate
#   estimate of identity [minimum of values of merged regions]
#
my $regions = {};

while (defined($_ = <STDIN>))
{
    chop;
    my(undef,$iden,$contig1,$b1,$e1,$contig2,$b2,$e2) = split(/\t/,$_);
    if (($contig1 ne $contig2) || ((! &SeedUtils::between($b1,$b2,$e1)) &&
				   (! &SeedUtils::between($b2,$b1,$e2))))
    {
	&keep($regions,$contig1,$b1,$e1,$iden);
	&keep($regions,$contig2,$b2,$e2,$iden);
    }
}

foreach my $contig (keys(%$regions))
{
    my $x = $regions->{$contig};
    my @raw = sort { $a->[0] <=> $b->[0] } @$x;

    while (my $y = shift @raw)
    {
	my($b1,$e1,$iden1) = @$y;
	while ((@raw > 0) && ($raw[0]->[0] < $e1))
	{
	    my $x2 = shift @raw;
	    my($b2,$e2,$iden2) = @$x2;
	    $e1 = ($e1 < $e2) ? $e2 : $e1;
	    $iden1 = ($iden1 < $iden2) ? $iden1 : $iden2;
	}
	print join("\t",($contig,$b1,$e1,$iden1)),"\n";
    }
}

sub keep {
    my($regions,$contig,$b,$e,$iden) = @_;

    if ($b > $e) { ($b,$e) = ($e,$b) }
    push(@{$regions->{$contig}},[$b,$e,$iden]);
}
