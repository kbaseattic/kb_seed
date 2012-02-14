########################################################################
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_cluster_pegs [-m MaxDist ] < PEGs > +[ClusterID,Location] 2> singletons

Cluster PEGs that are close on the contig

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain a PEG, but you can specify what column the
PEG IDs come from.

If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output and standard error.  Clusters containing
multiple genes go to STDOUT, while singletons go to STDERR.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=back

=head2 Output Format

PEGs that can be clustered are written to STDOUT.  Two columns are
added at the end of each line in STDOUT -- a ClusterID (an integer
uniquely clustering a set of PEGs) and a Location.  The location will
be in the form GID:Contig_Start[+-]Length.  For example, 

    100226.1:NC_003888_3766170+612

would designate a gene in genome 10226.1 on contig NC_003888 that starts
at position 3766170 (positions are numbered from 1) that is on the
positive strand and has a length of 612.

When a PEG does not cluster, the original line (with no added columns)
is written to STDERR.


=cut

use SeedEnv;
use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;
my $maxD = 2000;

my $usage = "usage: svr_cluster_pegs [-m MaxDist ] < PEGs > +[ClusterID,Location] 2> singletons";

my $column;
my $rc  = GetOptions('c=i' => \$column,
		     'm=i' => \$maxD);

if (! $rc) { print STDERR $usage; exit }

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
if (! $column)  { $column = @{$lines[0]} }

my @pegs = map { $_->[$column-1] } @lines;
my $pegH = $sapO->fid_locations( -ids => \@pegs, -boundaries => 1 );

my @sorted = sort { ($a->[1]->[0] <=> $b->[1]->[0]) or 
		    ($a->[1]->[1] cmp $b->[1]->[1]) or
		    ($a->[1]->[2] <=> $b->[1]->[2]) or
		    ($a->[1]->[3] <=> $b->[1]->[3])
		  }
             map  {  my $loc = $pegH->{$_};
		     if ($loc =~ /^(\d+\.\d+):(\S+)_(\d+)([+-])(\d+)$/) 
		     {
			 [$_,[$1,$2,($4 eq "+") ? ($3,$3+$5) : ($3-$5,$3)]];
		     }
		     else 
		     {
			 ();
		     }
		 } keys(%$pegH);

my %clustH;
my $nxt = 1;
while (@sorted > 0)
{
    my $in = &in_clust(\@sorted,$maxD);
    my @cluster = splice(@sorted,0,$in);
    foreach my $tuple (@cluster)
    {
	if ($in > 1)
	{
	    $clustH{$tuple->[0]} = [$nxt,$pegH->{$tuple->[0]}];
	}
    }
    if ($in > 1) { $nxt++ }
}

my @clusters;
foreach my $line (@lines)
{
    my $peg = $line->[$column-1];
    if (my $pair = $clustH{$peg})
    {
	push(@clusters,[@$line,@$pair]);
    }
    else
    {
	print STDERR join("\t",@$line),"\n";
    }
}

foreach $_ (sort { $a->[-2] <=> $b->[-2] } @clusters)
{
    print join("\t",@$_),"\n";
}


sub in_clust {
    my($sorted,$maxD) = @_;

    my $i;
    for ($i=1; ($i < @$sorted) && &close($sorted->[$i-1],$sorted->[$i],$maxD); $i++) {}
    return $i;
}

sub close {
    my($x,$y,$maxD) = @_;
    
    return (($x->[1]->[0] eq $y->[1]->[0]) &&
	    ($x->[1]->[1] eq $y->[1]->[1]) &&
	    (($x->[1]->[3] + $maxD) >= $y->[1]->[2]));
}
