########################################################################
use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;
use Carp;

my $sapO = SAPserver->new;
my $annO = ANNOserver->new;

#
# This is a SAS Component
#


=head1 svr_inconsistent_sets

Separate out inconsistent sets

------

Example:

    svr_inconsistent_sets < pg.sets 2> inconsistent.pg.sets > consistent.pg.sets
or
    svr_inconsistent_sets -s -f assignments < pg.sets 2> inconsistent.pg.sets > consistent.pg.sets


would write consistent sets to consistent.pg.sets and inconsistent sets to inconsistent.pg.sets.
The second form will 

    1. strip comments before the comparison
    2. write proposed assignments to the file "assignments".

Using the second form, the consistent.pg.sets include sets corrected by the proposed assignments.

------

=head2 Command-Line Options

=over 4

=item -f proposed.assignments

This causes correction of the assignments that can trivially be fixed.  The resulting
proposed set of assignments gets written to the designated file.

=item -s [strip comments]

This causes comments to be stripped from functions before the comparisons.

=item -k [update assignments using kmers - a performance hit]

=back

=head2 Output Format

Consistent sets are written to STDOUT, while inconsistent sets get writeen to STDERR.

=cut


my $usage = "usage: svr_inconsistent_sets [-s] [-f Assignments] > consistent.sets 2> inconsistent.sets";

my $strip = 0;
my $assignments;
my $kmers;
my $rc  = GetOptions('s' => \$strip,
                     'f=s' => \$assignments,
		     'k' => \$kmers
                    );
if (! $rc) { print STDERR $usage; exit }
if ($assignments)
{
    open(ASSIGNMENTS,">",$assignments) || die "could not open $assignments";
}
my $last = <STDIN>;
while ($last && ($last =~ /^(\S+)\t/))
{
    my $curr = $1;
    my @set;
    while ($last && ($last =~ /^(\S+)\t(fig\|\d+\.\d+\.peg\.\d+)\t(.*)$/) && ($1 eq $curr))
    {
	push(@set,[$1,$2,$3]);
	$last = <STDIN>;
    }
    my @pegs = map { $_->[1] } @set;
    my $funcH = $sapO->ids_to_functions( -ids => \@pegs);
    foreach $_ (@set)
    {
	my $func = $funcH->{$_->[1]};
	$_->[2]  = $func ? $func : "hypothetical protein";
    }
    my $i;
    for ($i=1; ($i < @set) && &same($set[$i]->[2],$set[0]->[2],$strip); $i++) {}
    if ($i == @set)
    {
	&write_to(\@set,\*STDOUT);
    }
    else
    {
	if ($assignments)
	{
	    my $set1 = &fix_if_possible(\@set,\*ASSIGNMENTS,$sapO,$annO,$kmers);
	    if ($set1)
	    {
		&write_to($set1,\*STDOUT);
	    }
	    else
	    {
		&write_to(\@set,\*STDERR);
	    }
	}
	else
	{
	    &write_to(\@set,\*STDERR);
	}
    }
}
if ($assignments) { close(ASSIGNMENTS) }

sub write_to {
    my($set,$fh) = @_;
    
    foreach my $x (@$set)
    {
	print $fh join("\t",@$x),"\n";
    }
}

sub same {
    my($x,$y,$strip) = @_;

    if ((! $strip) && ($x ne $y)) { return 0 }
    if ($x eq $y)                 { return 1 }
    $x =~ s/\s*\#.*$//;
    $y =~ s/\s*\#.*$//;
    return ($x eq $y);
}

sub fix_if_possible {
    my($set,$fh_assign,$sapO,$annO,$kmers) = @_;
    my $set1;
    if ($set1 = &fix_by_voting($set,$fh_assign,$sapO,$annO,$kmers)) { return $set1 }

    return undef;
}

sub fix_by_voting {
    my($set,$fh_assign,$sapO,$annO,$kmers) = @_;
	
    my @pegs = map { $_->[1] } @$set;
    my $pegH = $sapO->is_in_subsystem( -ids => \@pegs );
    my %assign;

    if ($kmers)
    {
	my %set_elements = map { $_->[1] => $_ } @$set;
	my $pegseqH          = $sapO->fids_to_proteins( -ids => \@pegs, -sequence => 1 );
	my @pegs_with_seq = map { $pegseqH->{$_} ? [$_,'',$pegseqH->{$_}] : () } keys(%$pegseqH);
	my $resultsH = $annO->assign_function_to_prot( -input => \@pegs_with_seq, -kmer => 8 );
	while (my $hit = $resultsH->get_next)
	{
	    my $peg  = $hit->[0];
	    my $func = $hit->[1];
	    if (($func && ($func ne $set_elements{$peg}->[2])) && &not_in_subsys($pegH,$peg))
	    {
		$set_elements{$peg}->[2] = $func;
		$assign{$peg} = $func;
	    }
	}
	foreach $_ (@$set)
	{
	    if (&not_in_subsys($pegH,$_->[1]))
	    {
		$_->[2] = $set_elements{$_->[1]}->[2];
	    }
	}
    }
    my $i;
    for ($i=0; ($i < @$set) && ($set->[$i]->[2] eq $set->[0]->[2]); $i++) {}
    if ($i == @$set)
    {
	&write_assign(\%assign,$fh_assign);
	return $set;
    }

    my %f_in_ss;
    my %f_not_in_ss;
    my %hypo;
    foreach my $tuple (@$set)
    {
	my($set,$peg,$func) = @$tuple;
	if ($func && ($func !~ /^hypothetical protein$/i))
	{
	    if (($_ = $pegH->{$peg}) && (@$_ > 0))
	    {
		push(@{$f_in_ss{$func}},$peg);
	    }
	    else
	    {
		push(@{$f_not_in_ss{$func}},$peg);
	    }
	}
	else
	{
	    $hypo{$peg} = 1;
	    if ($tuple->[2] ne 'hypothetical protein')
	    {
		$assign{$peg} = $tuple->[2] = 'hypothetical protein';
	    }
	}
    }
    my @in_ss = keys(%f_in_ss);
    my $hyposN = keys(%hypo);
    if (@in_ss > 1) { return undef }
    my $best;
    if (@in_ss == 1)
    {
	$best = $in_ss[0];
    }
    else
    {
	my @not_in_ss = sort { @{$f_not_in_ss{$b}} cmp @{$f_not_in_ss{$a}} } keys(%f_not_in_ss);
	if (@not_in_ss == 0) ## all hypo
	{
	    &write_assign(\%assign,$fh_assign);
	    return $set;
	}
	elsif ((@not_in_ss > 1) && (@{$f_not_in_ss{$not_in_ss[0]}} < ((@{$f_not_in_ss{$not_in_ss[1]}} + (0.5 * $hyposN)) * 2)))
	{
	    return undef;
	}
	$best = $not_in_ss[0];
    }

    if (&fix($best,\%hypo,$set,\%assign))
    {
	&write_assign(\%assign,$fh_assign);
	return $set;
    }
}

sub fix {
    my($best,$hypo,$set,$assign) = @_;

    foreach my $tuple (@$set)
    {
	my($set,$peg,$func) = @$tuple;
	if ((uc $func ne uc $best) && (! &SeedUtils::hypo($func)))
	{
	    return undef;
	}
	if ($func ne $best)
	{
	    $tuple->[2] = $assign->{$peg} = $best;
	}
    }
    return 1;
}

sub not_in_subsys {
    my($pegH,$peg) = $_;

    if ($pegH && $peg && $pegH->{$peg})
    {
	return @{$pegH->{$peg}} == 0;
    }
    return 1;
}

sub write_assign {
    my($assign,$fh) = @_;

    foreach my $peg (keys(%$assign))
    {
	print $fh "$peg\t$assign->{$peg}\n";
    }
}
