use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use Carp;
use gjoseqlib;
use SeedEnv;

my $usage = "usage: CSA_first_pass WorkingDir";


my($dir);
(
 ($dir           = shift @ARGV)
)
    || die $usage;

(-s "$dir/matches") || die "$dir/matches is empty";


open(MATCHES,"<$dir/matches") || die "could not open $dir/matches";
my @matches = map { chop; 
		    my($kmer,$contig1,$strand1,$off1,$contig2,$strand2,$off2) = split(/\t/,$_);
		    my $loc1 = [$contig1,
				$off1,
				($strand1 eq "+") ? ($off1 + (length($kmer)-1)) : ($off1 - (length($kmer)-1))];
		    my $loc2 = [$contig2,
				$off2,
				($strand2 eq "+") ? ($off2 + (length($kmer)-1)) : ($off2 - (length($kmer)-1))];
		    [$loc1,$loc2,'pin']
		  } <MATCHES>;
close(MATCHES);

while (my $pin = shift @matches)
{
#   print STDERR &Dumper(['processing pin',$pin]);
    my $merged;
    while ((@matches > 0) && ($merged = &can_merge($pin,$matches[0])))
    {
#	print STDERR &Dumper(['merged',$matches[0],$pin,$merged]);
	$pin = $merged;
	shift @matches;
    }
#   print STDERR &Dumper($pin);
    print_connection($pin);
}

sub can_merge {
    my($pin1,$pin2) = @_;

#   print STDERR &Dumper(['can_merge',$pin1,$pin2]);
    my($locA1,$locA2,$typeA) = @$pin1;
    my($contigA1,$bA1,$eA1)  = @$locA1;
    my($contigA2,$bA2,$eA2)  = @$locA2;

    my($locB1,$locB2,$typeB) = @$pin2;
    my($contigB1,$bB1,$eB1)  = @$locB1;
    my($contigB2,$bB2,$eB2)  = @$locB2;

    my $merged;
    if ($merged = &can_extend_block($pin1,$pin2))
    {
	return $merged;
    }
    else
    {
	return undef;
    }
}

sub can_extend_block {
    my($pin1,$pin2) = @_;

    my($locA1,$locA2,$typeA) = @$pin1;
    my($contigA1,$bA1,$eA1)  = @$locA1;
    my($contigA2,$bA2,$eA2)  = @$locA2;

    my($locB1,$locB2,$typeB) = @$pin2;
    my($contigB1,$bB1,$eB1)  = @$locB1;
    my($contigB2,$bB2,$eB2)  = @$locB2;

    if (($typeA =~/pin|block/) && 
	($typeB =~/pin|block/) && 
	($contigA1 eq $contigB1) &&
	($contigA2 eq $contigB2) &&
	(&strand($locA1) eq &strand($locB1)) &&
	(&strand($locA2) eq &strand($locB2)))
    {
	my $ext;
	if    ((&SeedUtils::between($bA1,$bB1,$eA1) && (! &SeedUtils::between($bA1,$eB1,$eA1))) &&
	       (&SeedUtils::between($bA2,$bB2,$eA2) && (! &SeedUtils::between($bA2,$eB2,$eA2))) &&
	       (($ext = &SeedUtils::min(abs($eB1-$bA1),abs($eB1-$eA1))) == (&SeedUtils::min(abs($eB2-$bA2),abs($eB2-$eA2)))))
	{
	    return [[$contigA1,$bA1,$eB1],[$contigA2,$bA2,$eB2],(($typeA eq "pin") &&
								 ($typeB eq "pin") &&
								 ($ext == 1)) ? 'pin' : 'block'];
	}
	elsif ((! &SeedUtils::between($bA1,$bB1,$eA1) && (! &SeedUtils::between($bA1,$eB1,$eA1))) &&
	       (($ext = ($eB1 - $eA1)) == abs($eB2 - $eA2)) && ($ext < 200))
	{
	    return [[$contigA1,$bA1,$eB1],[$contigA2,$bA2,$eB2],'block'];
	}
    }
    return undef;
}
    

sub strand {
    my($loc) = @_;

    return ($loc->[1] <= $loc->[2]) ? '+' : '-';
}


sub print_connection {
    my($x) = @_;

    my($loc1,$loc2,$type) = @$x;
    print join("\t",(@$loc1,@$loc2,$type)),"\n";
}

