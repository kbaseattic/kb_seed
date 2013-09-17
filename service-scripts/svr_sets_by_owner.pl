use strict;

use Getopt::Long;
use SeedEnv;
use PersistentSets;

#
# This is a SAS Component
#


=head1 svr_sets_by_owner

List all the persistent sets owned by owner

The output is a list of sets names

------
Example: svr_sets_by_owner -owner owner_name  > allsets.tbl

would produce a 2-column table of the owner and set names of the persistent sets owned by owner_name.
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

my $usage    = "usage: svr_sets_by_owner [--owner=owner_name] >output\n";
my $owner = "";
my $url = '';
my $opted    = GetOptions('owner=s', \$owner, 'url=s', \$url);

if (! $opted) {
    print $usage;
} else {
    if (!$owner) {
	while(<>) {
		chomp;
		get_sets($_);
	}
    } else {
	get_sets($owner);
    }	
}

sub get_sets {
    my ($owner) = @_;
    my $sets = PersistentSets::enumerate_sets_by_owner($owner);
    for my $set (@$sets) {
	print "$owner\t$set\n";
    }
}
	
