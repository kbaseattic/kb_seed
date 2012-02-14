use strict;

use Getopt::Long;
use SeedEnv;
use PersistentSets;

#
# This is a SAS Component
#


=head1 svr_get_set

List all the entries in a persistent set owned by owner

The output is a list of set entries

Owner name and set name(s) are required.

Owner can be supplied with the -owner command line argument.

Set name can be supplied with the -set_name argument only if the -owner argument is supplied.

If -owner is supplied but not -set_name, set names are read from stdin, starting at column c.

If neither set_name nor -owner is supplied, owner:set_name are read (starting at column -c) from stdin.


Example: svr_get_set -owner owner_name  -set_name set_name > set_contents.tbl

would produce a 1-column table of the contents of the set named set_name owned by owner.
------

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item owner

If supplied, owner name will be used for all subsequent operations

=item set_name

If supplied, the contents of this set will be returned

=item -c Column

This is used only if the column containing the input owner and/or set names is not the last.

=back

=head2 Output Format

The standard output is a file where each line contains an owner name and a  set name

=cut

my $usage    = "usage: svr_get_sets [--owner=owner_name] [--set_name=set_name]  >output\n";
my $owner = "";
my $set_name = "";
my $column;
my $url = '';
my $opted    = GetOptions('c=i' => \$column, 'owner=s', \$owner, 'set_name=s', \$set_name, 'url=s', \$url);

if (! $opted) { print STDERR $usage; exit }
if ($set_name) {
	if (!$owner) {print "Missing Owner"; exit}
	else {
		print_set($owner, $set_name);
	}
} else {


	 my @sets = ScriptThing::GetList(\*STDIN, $column);


	for my $set (@sets) { 

		if ($owner) {
			$set_name = $set;
		} else {
			($owner, $set_name) = split(":", $set)
		}	
		print_set($owner, $set_name);	
	}
}

		
sub print_set {
	my ($owner, $set_name) = @_;
	my $entries = PersistentSets::get_set($set_name, $owner);
        for my $entry (@$entries) {
                print $entry, "\n";
        }
}
