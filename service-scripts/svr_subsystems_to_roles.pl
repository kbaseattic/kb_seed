use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_subsystems_to_roles < subsystems > subsystems.role

This take a table in.  One of the columns contains subsystem names.  For
each subsystem, a set of lines is output.  The set will be

    [subsystem,abbreviation,role]

------
Example: svr_all_subsystems | svr_subsystems_to_roles > 3-column.table

would produce a 3-column table.  The first column would contain
subsystem names, the 2nd role abbrviations, and the third a role 
contained in the subsystem.
------

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing subsystems is not the last.

=back


=head2 Output Format

The standard output is a file where each line just contains a subsystem
name, a role abbreviation, and the full role.

=cut


use SeedEnv;
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_subsystems_to_roles [-c column]";

my $column = 1;
my $rc  = GetOptions('c=i' => \$column);
if (! $rc) { print STDERR $usage; exit }

while (defined($_ = <STDIN>))
{
    chomp;
    my @cols = split(/\t/,$_);
    my $subsys = $cols[$column-1];
    my @tuples  = map { ($_ =~ /^([^\t]*)\t([^\t]*)\t(\S.*\S)/) ? [$2,$3] : () } `svr_subsystem_roles "$subsys"`;
    foreach my $tuple (@tuples)
    {
	print join("\t",($subsys,@$tuple)),"\n";
    }
}

