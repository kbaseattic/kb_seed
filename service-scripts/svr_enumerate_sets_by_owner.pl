use strict;

use Getopt::Long;
use SeedEnv;
use PersistentSets;

#
# This is a SAS Component
#


=head1 svr_enumerate_sets_by_owner

List all the persistent sets owned by owner

The output is a list of sets names

------
Example: svr_enumerate_sets_by_owner -owner owner_name  > allsets.tbl

would produce a 1-column table of the owner:set_name of the persistent sets owned by owner_name.
------

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item owner

If supplied, sets for the owner name will be supplied, if not supplied, owner name(s) are read from stdin

=back

=head2 Output Format

The standard output is a file where each line contains an owner name and a  set name

=cut

my $usage    = "usage: svr_enumerate_sets_by_owner [--owner=owner_name] >output\n";
my $owner = "";
my $url = '';
my $column;
my $opted    = GetOptions('c=i' => \$column, 'owner=s', \$owner, 'url=s', \$url);



if (! $opted) {
    print $usage;
} else {
    if (!$owner) {
	 my @owners = ScriptThing::GetList(\*STDIN, $column);
	for $owner (@owners) {
		get_sets($owner);
	}
    } else {
	get_sets($owner);
    }	
}

sub get_sets {
    my ($owner) = @_;
    my $sets = PersistentSets::enumerate_sets_by_owner($owner);
    for my $set (@$sets) {
	print "$owner:$set\n";
    }
}
	
