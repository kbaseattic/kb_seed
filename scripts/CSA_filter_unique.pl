use strict;
#
# This is a SAS Component
#
use Data::Dumper;

my $last = <STDIN>;
while (defined($last) && ($last =~ /^(\S+)/))
{
    my $kmer = uc $1;
    my $_ = <STDIN>;
    if ((! $_) || (($_ =~ /^(\S+)/) && (uc $1 ne $kmer)))
    {
	print $last;
	$last = $_;
    }
    else
    {
	print STDERR $last;
	print STDERR $_;
	while (defined($last = <STDIN>) && ($last =~ /^(\S+)/) && (uc $1 eq $kmer))
	{
	    print STDERR $last;
	}
    }
}
