use strict;
use SeedEnv;
use Data::Dumper;

#
# This is a SAS Component
#

=head1 svr_split_fams < protein.families > without.multiple 2> with.cycles

Detect cases in which BBHs have led to cycles

=head2 Introduction

If you are constructing protein families and using comparisons that are BBHs, you often wish
to avoid cases in which a single family has more than one gene/protein from a single genome.
This little utility splits out the sets with multiple genes from a single genome, writes
the removed entries to STDERR, and you can peruse them manually.

=head2 Output

The output consists of sets without cycles going to STDOUT and sets with cycles going
to STDERR

=cut

my $last = <STDIN>;
while ($last && ($last =~ /^(\S+)/))
{
    my $curr = $1;
    my @set = ();
    while ($last && ($last =~ /^(\S+)\t(\S+)/) && ($1 eq $curr))
    {
	push(@set,[$2,$last]);
	$last = <STDIN>;
    }
    &process(\@set);
}

sub process {
    my($set) = @_;

    my %genomes;
    my($i,$g);
    for ($i=0; ($i < @$set) && ($g = &SeedUtils::genome_of($set->[$i]->[0])) && (! $genomes{$g}); $i++) 
    {
	$genomes{$g} = 1;
    }

    foreach $_ (map { $_->[1] } @$set)
    {
	if ($i == @$set)
	{
	    print $_;
	}
	else
	{
	    print STDERR $_;
	}
    }
}
