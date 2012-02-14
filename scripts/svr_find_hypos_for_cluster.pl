use strict;
use SeedEnv;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_find_hypos_for_cluster

Get candidates for a specific role by finding genes with no real
assignment of function yet that are connected to a cluster.  We will
consider a hypothetical "connected to a cluster" iff

    1. it has a strong functional coupling score to a member of the cluster or
    2. it occurs between the bounding members of the cluster

------

Example:

    svr_gap_filled_reactions_and_roles -g 273035.4 | svr_find_clusters_relevant_to_role -g 273035.4 -r 2 -n 100 | svr_find_hypos_for_cluster

would produce a 5-column table [Genome,reaction,role,cluster-of-genes-connected-to-role,peg-for-hypothetical]

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain a cluster represented as a comma-separated list of genes.
If some other column contains the clusters, use

    -c N

where N is the column (from 1) that contains the role in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.


=head2 Command-Line Options

=over 4

=item -c N

Specifies which column in the input table contains the clusters.  Defaults
to the last column in the input file.

=back

=head2 Output Format

The standard output is a tab-delimited file.  Each line will contain
the input fields followed by a score and a PEG with a hypothetical function that
is connected to the cluster.  The score is either the functional-coupling score or
0 (for a hypo that is embedded, but not functionally coupled).
    
=cut

use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_find_hypos_for_cluster [-c N]";

my $column;
my $rc  = GetOptions('c=i' => \$column);

if (! $rc) { print STDERR $usage; exit }

my @lines          = map { chomp; [split(/\t/,$_)] } <STDIN>;
my @clusters       = map { $_->[$column-1] } @lines;
my @pegs           = map { split(/,/,$_) } @clusters;
my %pegs_in_clust  = map { ($_ => 1) } @pegs;
@pegs              = keys(%pegs_in_clust);
my $fcH            = $sapO->conserved_in_neighborhood( -ids => \@pegs );
my $locH           = $sapO->fid_locations( -ids => \@pegs);
my %cluster_to_loc = map { ($_ => &loc_of_region_containing($_,$locH)) } @clusters;
my %locs           = map { ($cluster_to_loc{$_} => 1) } keys(%cluster_to_loc);
my @regions        = keys(%locs);
my $loc2G          = $sapO->genes_in_region( -locations => \@regions );
my %other_genes    = map { (! $pegs_in_clust{$_}) ? ($_ => 1) : () } map { @{$loc2G->{$_}} } keys(%$loc2G);
my @otherG         = keys(%other_genes);
my $funcH          = $sapO->ids_to_functions( -ids => \@otherG);
my @hypo           = grep { &SeedUtils::hypo($funcH->{$_}) } keys(%$funcH);
my %hypoH          = map { $_ => 1 } @hypo;
foreach my $line (@lines)
{
    if (my $cluster1 = $line->[$column-1])
    {
	my %best_sc;
	foreach my $peg (split(/,/,$cluster1))
	{
	    my $conn  = $fcH->{$peg};
	    if ($conn)
	    {
		foreach my $tuple (@$conn)
		{
		    my($sc,$peg2,$func2) = @$tuple;
		    if ((! $pegs_in_clust{$peg2}) && (&SeedUtils::hypo($func2)))
		    {
			if ((! ($_ = $best_sc{$peg2})) || ($_ < $sc))
			{
			    $best_sc{$peg2} = $sc;
			}
		    }
		}
	    }
	}
	my $loc1         = $cluster_to_loc{$cluster1};
	my %other_genes1 = map { (! $pegs_in_clust{$_}) ? ($_ => 1) : () } @{$loc2G->{$loc1}};
	my @poss         = grep { $hypoH{$_} } keys(%other_genes1);
	foreach my $peg (@poss)
	{
	    if (! defined($best_sc{$peg})) { $best_sc{$peg} = 0 }
	}
	foreach my $peg (sort { $best_sc{$b} <=> $best_sc{$a} } keys(%best_sc))
	{
	    print join("\t",(@$line,$best_sc{$peg},$peg)),"\n";
	}
    }
}

sub loc_of_region_containing {
    my($cluster,$locH) = @_;

    my @pegs = split(/,/,$cluster);
    my @pegs_with_locs = sort { ($a->[1] cmp $b->[1]) or ($a->[2] <=> $b->[2]) }
                         map { my $peg = $_; my $loc = $locH->{$peg}->[0]; 
 	                       ($loc =~ /^(\d+\.\d+):(\S+)_(\d+)([-+])(\d+)/) ? [$peg,$2,$3,$4,$5] : () } @pegs;

    my($peg1,$contig1,$start1,$strand1,$length1) = @{$pegs_with_locs[0]};
    my($peg2,$contig2,$start2,$strand2,$length2) = @{$pegs_with_locs[1]};

    if ($contig1 ne $contig2) { die "contig1=$contig1 contig2=$contig2" }
    my $min = &SeedUtils::min( $start1, ($strand1 eq "+") ? ($start1+($length1-1)) : ($start1-($length1-1)),
			       $start2, ($strand2 eq "+") ? ($start2+($length2-1)) : ($start2-($length2-1)));
    my $max = &SeedUtils::max( $start1, ($strand1 eq "+") ? ($start1+($length1-1)) : ($start1-($length1-1)),
			       $start2, ($strand2 eq "+") ? ($start2+($length2-1)) : ($start2-($length2-1)));
    my $genome = &SeedUtils::genome_of($peg1);
    my $loc =  "$genome:$contig1" . "_" . $min . "_" . $max;
    return $loc;
}
