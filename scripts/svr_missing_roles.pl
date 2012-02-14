use strict;
use SeedEnv;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_missing_roles -r reaction -g genome

It is assumed that -r is used to specify a column in the input file.
The column should contain reaction IDs for which "missing roles" might exist.
The -g argument is used to specify the column containing the genome ID.

------

Example:

    svr_all_models | 
    svr_gap_filled_reactions_and_roles -c 2 | 
    cut -f1,2,3 | sort -u |
    svr_find_clusters_relevant_to_reaction -g 1 -c 3 |
    svr_find_hypos_for_cluster |
    svr_missing_roles -g 1 -r 3

would produce a 6-column table [Genome,
				Model,
				reaction,
				cluster-of-genes-connected-to-role,
				peg-for-hypothetical,
				PossibleRoles]

------

=head2 Command-Line Options

=over 4

=item -r ReactionColmun

Specifies which column in the input table contains the reaction ID. 

=item -g GenomeColumn

Specifies which column in the input contains the genome ID, or
it can give the actual genome ID, if you are processing a single
genome.

=back

=head2 Output Format

The standard output is a tab-delimited file.  Each line will contain
the input fields followed by one or more new columns, each containing a
functional role that appears to be missing (and, hence, a candidate for
a hypothetical).
    
=cut

use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_missing_roles -r ReactionColumn -g GenomeColumn";

my $reactionI;
my $genomeI;
my $rc  = GetOptions('r=i' => \$reactionI,
		     'g=s' => \$genomeI
		    );

if ((! $rc) || (! $genomeI) || (! $reactionI)) { print STDERR $usage; exit }

my @lines            = map { chomp; [split(/\t/,$_)] } <STDIN>;
my @reactions        = map { $_->[$reactionI-1] } @lines;
my %all_reactions    = map { $_ => 1 } @reactions;
my $reactions2rolesH = $sapO->reactions_to_roles( -ids => [keys(%all_reactions)]);

foreach my $line (@lines)
{
    my $reaction = $line->[$reactionI-1];
    my $genome   = ($genomeI =~ /^\d+$/) ? $line->[$genomeI-1] : $genomeI;
    my @roles    = @{$reactions2rolesH->{$reaction}};
    if (@roles > 0)
    {
	my $role_to_pegsH  = $sapO->occ_of_role( -roles => \@roles, -genomes => [$genome] );
	my @missing        = grep { @{$role_to_pegsH->{$_}} < 1 } @roles;
	if (@missing > 0)
	{
	    print join("\t",(@$line,@missing)),"\n";
	}
    }
}


