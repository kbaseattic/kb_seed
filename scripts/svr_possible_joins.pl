use strict;

#
# This is a SAS Component
#


=head1 svr_possible_joins

Given kmer hits on ends of contigs, just group the hits having the same functions
to support finding cases in which genes might span contigs.

------

Example:

    svr_just_ends < contigs | svr_assign_to_dna_using_figfams | perl svr_possible_joins

would produce something like

ctg7180000000449	10257	10809	Antiadhesin Pls, binding to squamous nasal epithelial cells
ctg7180000000549	11391	11799	Antiadhesin Pls, binding to squamous nasal epithelial cells

ctg7180000000282	2306	1937	Arsenate reductase (EC 1.20.4.1)
ctg7180000000453	449	848	Arsenate reductase (EC 1.20.4.1)

ctg7180000000282	2697	2326	Arsenic efflux pump protein
ctg7180000000452	200959	201954	Arsenic efflux pump protein
ctg7180000000453	3	429	Arsenic efflux pump protein
ctg7180000000455	1000	1	Arsenic efflux pump protein

ctg7180000000282	1000	850	Chromate transport protein ChrA
ctg7180000000282	1834	1699	Chromate transport protein ChrA

.
.
.

Each line contains a region on a contig that seems to encode a protein.  
These lines are grouped into two or more that correspond to proteins with the designated function.
In some cases (the first and last in the example output above), these are definitely
not ends that span contigs.  In other cases (the third above), you have groups that need 
to be resolved.

In any event, before doing directed sequencing to close any of these "gaps",
blast the indicated ends against complete non-redundant databases and piece out
what it means first.

This is just a simple, fast tool that can supply relevant clues in some cases.

------

=cut

my @lines = sort { $a->[3] cmp $b->[3] } map { chomp; [split(/\t/,$_)] } <STDIN>;

while (my $end1 = shift @lines)
{
    if ((@lines > 0) && ($end1->[3] eq $lines[0]->[3]) && 
	($lines[0]->[0] ne $end1->[0]) && 
	($end1->[3] ne "hypothetical protein") && ($end1->[1] >= 5))
    {
	&display($end1);
	while ((@lines > 0) && ($end1->[3] eq $lines[0]->[3]))
	{
	    &display($lines[0]);
	    shift @lines;
	}
	print "\n";
    }
}

sub display {
    my($x) = @_;

    if ($x->[2] =~ /^(\S+)_(\d+)_(\d+)_(\d+)_(\d+)/)
    {
	my($contig,$be,$ee,$bm,$em) = ($1,$2,$3,$4,$5);
	my $func = $x->[3];
	print join("\t",($contig,$be+($bm-1),$be+($em-1),$func)),"\n";
    }
}
