use strict;
use SeedEnv;
use Data::Dumper;
use Carp;
use Getopt::Long;

#
# This is a SAS Component
#


=head1 svr_neighborhood_of_role -r 2 < file.with.roles > with.added.role

Find roles in metabolic-function neighborhood

------

Example:

    svr_neighborhood_of_roles < roles.in.file > with.steps.and.role.column.added

would take as input a file in which the last column was functional roles.
Two columns would be added

    steps       is the number of steps traversed to reach the neighbor
    neighbor    is the neighboring role


------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain a role for which relevant clusters are desired.
If some other column contains the roles, use

    -c N

where N is the column (from 1) that contains the role in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing roles is not the last.

=item -r MaxSteps  [default is 2]

This parameter gives the maximum number of steps (i.e., the "radius") the
program can take to create the neighborhood of a  role

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with two extra columns added.  The extra columns will contain the
number of steps to the neighbor, along with the neighbor.

=cut

my $sapO = SAPserver->new();

my $usage = "usage: svr_neighborhood_of_role [-r Maxsteps] [-c column]";

my $column;
my $radius = 1;
my $input = '-';

my $rc  = GetOptions('c=i' => \$column,
		     'r=i' => \$radius,
		     'i=s' => \$input
		    );

if (! $rc) { print STDERR $usage; exit }
open my $ih, "<$input";
my @lines = map { chomp; [split(/\t/,$_)] } <$ih>;
if (! $column)  { $column = @{$lines[0]} }

my @roles   = map { $_->[$column-1] } @lines;
my $neighH  = &neighbors_of(\@roles,$sapO,$radius);

foreach my $line (@lines)
{
    my $role  = $line->[$column-1];
    my $neigh = $neighH->{$role};
    foreach my $role2 (keys(%$neigh))
    {
	print join("\t",@$line,$neigh->{$role2},$role2),"\n";
    }
}
sub neighbors_of {
    my($roles,$sapO,$radius) = @_;
    
    my %roleH  = map { $_ => { $_  => 1 }} @$roles;
    my $i;
    for ($i=0; ($i < $radius); $i++)
    {
	&expand(\%roleH,$sapO,$i+1);
    }
    return \%roleH;
}

sub expand {
    my($roleH,$sapO,$steps) = @_;

    my $roles_to_expand = {};
    foreach my $role (keys(%$roleH))
    {
	foreach my $role1 (keys(%{$roleH->{$role}})) 
	{
	    $roles_to_expand->{$role1} = $steps;
	}
    }
    my $connH = &get_immediate_neighbors($sapO,$roles_to_expand);
    foreach my $role (keys(%$roleH))
    {
	my @start = keys(%{$roleH->{$role}});
	foreach my $role1 (@start)
	{
	    foreach my $role2 (keys(%{$connH->{$role1}}))
	    {
		if (! $roleH->{$role}->{$role2})
		{
		    $roleH->{$role}->{$role2} = $steps;
		}
	    }
	}
    }
}

sub get_immediate_neighbors {
    my($sapO,$roles_to_expand) = @_;

    my $tmp_roles = [keys(%$roles_to_expand)];
    my $connH = {};
    my $tmpH = $sapO->role_neighbors(-ids => $tmp_roles);
    foreach my $role (keys(%$tmpH)) {
	my $connected = $tmpH->{$role};
	for my $role2 (@$connected) {
	    $connH->{$role}->{$role2} = 1;
	}
    }
    return $connH;
}

