use strict;
use SeedEnv;
use ScriptThing;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_find_clusters_relevant_to_reaction

Find clusters potentially relevant to a search for a "missing gene"

------

Example:

    svr_find_clusters_relevant_to_reaction -g 83333.1 < unconnected.reactions

would take as input a file containing reacions that are believed to
be present in the genome 83333.1, but cannot yet be connected to specific genes.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain a role for which relevant clusters are desired.
If some other column contains the roles, use

    -c N

where N is the column (from 1) that contains the reaction in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing reactions is not the last.

=item -g Genome

This normally specifies the genome for which relevant clusters are
sought.  If it is an integer, then each line of input is thought of as
a genome-role pair, and the integer specifies the column in each input
line that will contain the genome.  The -c parameter is the column
that will be used as a role.

=item -d MaxSteps  [default is 1]

This parameter gives the maximum number of steps (i.e., the "radius") the
program can take to create the neighborhood of a  reaction

=item -i inputFile

If specified, the name of the input file; otherwise, the input will be taken from STDIN.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added.  The extra column will contain a list
of two or more comma-separated PEGs.  There may be more than one
output line for a single input (if multiple clusters are detected within the
genome).

=cut

use Getopt::Long;
# use Tracer; ##HACK

my $usage = "usage: svr_find_clusters_relevant_to_reaction -g Genome [-c column]";

my $column;
my $genome;
my $inFileName;
my $dist = 1;
my $url;

my $rc  = GetOptions('c=i' => \$column,
		     'd=i' => \$dist,
		     'g=s' => \$genome,
		     'i=s' => \$inFileName,
		     'u=s' => \$url,
		    );

if ((! $rc) || (! defined($genome))) { print STDERR $usage; exit }
# Allowing the specification of an input file on the command line enables this script to run
# in the real-time debugger on Bruce's laptop.
my $ih;
if ($inFileName) {
    open($ih, "<$inFileName") || die "Could not open $inFileName: $!\n";
} else {
    $ih = \*STDIN;
}
my $sapO = SAPserver->new(url => $url);
# Determine how we're going to find the genome ID.
my $genomeColumn;
if ($genome =~ /^\d+$/) {
    # Here the genome is taken from an input column.
    $genomeColumn = $genome;
}

# The main loop pulls out batches of input 5 lines at a time. The input is formatted into
# 2-tuples of the form (keyColumn, inputLine). Note the use of the $column parameter to get
# the key from the correct column.
#while (my @tuples = ScriptThing::GetBatch($ih, 100, $column)) {
while (my @tuples = ScriptThing::GetBatch($ih, 5, $column)) {
    # Get a list of the reactions in this batch.
    my @reactionList = map { $_->[0] } @tuples;
    # Get a hash that maps each reaction to a sub-hash of its neighbors.
    my $neighH = $sapO->reaction_neighbors( -ids => \@reactionList, -depth => $dist );
    # Now we need a list of all the reactions we've found. This includes the incoming reactions
    # and all their neighbors. To prevent duplicates, we build the list using a hash.
    my %all_reactions = map { $_ => 1 } map { ($_, keys %{$neighH->{$_}}) } @reactionList;
    # Get a hash that maps each reaction to its roles.
    my $reactions2rolesH = $sapO->reactions_to_roles( -ids => [keys(%all_reactions)]);
    # Now loop through the tuples in this batch.
    for my $tuple (@tuples) {
	my ($reaction, $line) = @$tuple;
	# Compute the genome ID.
	my $genome1;
	if ($genomeColumn) {
	    my @cols = split /\t/, $line;
	    $genome1 = $cols[$genomeColumn - 1];
	} else {
	    $genome1 = $genome;
	}
	# Get all the reactions in the neighborhood of the incoming reaction. This always
	# includes the incoming reaction itself, since its in the neighborhood at a distance
	# of 0.
	my @reactions = keys(%{$neighH->{$reaction}});
#	$_ = @reactions; print STDERR "$_ reactions in neighborhood of $reaction\n";
	# Get all the roles for these reactions.
	my %tmp             = map { $_ => 1 } map { @{$reactions2rolesH->{$_}} } @reactions;
	my @roles           = keys(%tmp);
	next if (@roles == 0);
	# $_ = @roles; print STDERR "$_ roles in neighborhood\n";
	# Find all the features in the genome of interest for those roles.
	my $role_to_pegsH   = $sapO->occ_of_role( -roles => \@roles, -genomes => [$genome1]  );
	my %pegsH           = map { $_ => 1 } map {@{$role_to_pegsH->{$_}}}  keys(%$role_to_pegsH);
	my @pegs            = keys(%pegsH);
	#    $_ = @pegs; print STDERR "$_ pegs\n";
	# Now we want to find the features with these roles that are physically close to
	# each other.
        my $locH = $sapO->fid_locations( -ids => \@pegs, -boundaries => 1 );    
	my @pegs_with_locs = sort { ($a->[1] cmp $b->[1]) or ($a->[2] <=> $b->[2]) }
			     map { my $peg = $_; my $loc = $locH->{$peg};
			     ($loc =~ /^\d+\.\d+:(\S+)_(\d+)([-+])(\d+)/) ? [$peg,$1,$2,$3,$4] : () } @pegs;
	my $clusters = &clustered_pegs(\@pegs_with_locs);
	foreach my $cluster (@$clusters)
	{
	    print "$line\t" . join(",",@$cluster) . "\n";
	}
    }
    
}

sub clustered_pegs {
    my($pegs_with_locs) = @_;

    my $clusters = [];
    my $i;
    $i = 0;
    while ($i < (@$pegs_with_locs - 1))
    {
	my $j;
	for ($j=$i+1; ($j < @$pegs_with_locs) && (&gap_sz($pegs_with_locs->[$j-1],$pegs_with_locs->[$j]) <= 3000); $j++) {}
	if ($j > $i+1)
	{
	    push(@$clusters,[map { $_->[0] } @{$pegs_with_locs}[$i..$j-1]]);
	}
	$i = $j;
    }
    return $clusters;
}

sub gap_sz {
    my($x,$y) = @_;

    if ($x->[1] ne $y->[1]) { return 1000000 }
    my $min = ($x->[3] eq "+") ? ($x->[2] + $x->[4]) : $x->[2];
    my $max = ($y->[3] eq "+") ? $y->[2] : ($y->[2] - $y->[4]);
    return abs($max - $min);
}

