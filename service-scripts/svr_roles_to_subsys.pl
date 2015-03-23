########################################################################
use strict;
use SeedEnv;

#
# This is a SAS Component
#


=head1 svr_roles_to_subsys

Extend a set of roles to include the subsystems and category data

=head2 Introduction

Examples:

    svr_roles_to_subsys -all < table.with.roles.as.last.column > extended.table
        extend to all subsystems, including cluster-based (defaults to just usable, non-cluster-based)

    svr_roles_to_subsys -c 2 -aux < table.with.roles.as.last.column > extended.table
        extend from roles in column 2 to usable, non-cluster-based subsys including thoise in which 
        the role is auxiliary

=head2 Command-Line Arguments

The program is invoked using

    svr_role_to_subsys [-all] [-aux] [-c Column] < table.with.role.column > with.3.more.columns

=over 4

=item -all

Use all subsystems, including experimental and cluster-based [default is only usable, non-cluster-based]

=item -aux 

Include subsystemns in which the role is auxiliary [default is to ignore auxiliary roles]

=item -c=Column

Specifies the column in the input table that is believed to contain the role.

=back

=head2 Output

A table with 2 added columnns (subsystem, comma-delimited list of categories).
Lines in the incoming table that do not match are written to STDERR.

=cut

use Getopt::Long;
my $usage = "svr_roles_to_subsys [-all] [-aux] [-c Column] < table.with.roles > extended.table 2> nonconnecting.rows\n";

my $all = 0;
my $aux = 0;
my $column;
my $url = '';

my $rc = GetOptions( "all" => \$all,
                     "aux"   => \$aux,
                     "c=i" => \$column,
                     "url=s" => \$url
                   );

$rc or print STDERR $usage and exit;

# Get the server object.
my $sapServer = SAPserver->new(url => $url);
# We'll use this to cache subsystem classifications.
my %subClasses;
# Compute the auxiliary parameters.
my %auxParms;
if ($aux) {
    $auxParms{-aux} = 1
}
if ($all) {
    $auxParms{-usable} = 0
} else {
    $auxParms{-exclude} = 'cluster-based';
}
# The main loop processes chunks of input, 1000 lines at a time.
while (my @tuples = ScriptThing::GetBatch(\*STDIN, undef, $column)) {
    # Ask the server for the subsystems.
    my $roleHash = $sapServer->subsystems_for_role(-ids => [map { $_->[0] } @tuples],
                                                   %auxParms);
    # Collect the new subsystems we've found this time.
    my @subs;
    for my $role (keys %$roleHash) {
        my $subList = $roleHash->{$role};
        for my $sub (@$subList) {
            if (! exists $subClasses{$sub}) {
                push @subs, $sub;
            }
        }
    }
    # Get the classifications for these subsystems.
    my $subHash = $sapServer->classification_of(-ids => \@subs);
    # Put them in the classification hash.
    for my $sub (@subs) {
	# RAE: originally we joined these with a ', ', but that is often part of the
	# classification, and makes it impossible to know where one begins and one ends
        $subClasses{$sub} = join(" :: ", @{$subHash->{$sub}});
    }
    # Output the results for these roles.
    for my $tuple (@tuples) {
        # Get this line and the relevant role.
        my ($role, $line) = @$tuple;
        # Get this role's subsystems.
	my $subs = $roleHash->{$role};
	if (@$subs == 0)
	{
	    print STDERR "$line\n";
	}
	else
	{
	    for my $sub (@{$roleHash->{$role}}) {
		# Output the line with the subsystem and classification appended.
		print join("\t", $line, $sub, $subClasses{$sub}) . "\n";
	    }
        }
    }
}
