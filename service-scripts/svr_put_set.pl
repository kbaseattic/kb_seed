use strict;

use Getopt::Long;
use SeedEnv;
use PersistentSets;

#
# This is a SAS Component
#


=head1 svr_put_set

Add  entries to a persistent set owned by owner

Owner name and set name(s) are required.

Owner must be supplied with the -owner command line argument.

Set name must  be supplied with the -set_name argument

Example: svr_put_set -owner owner_name  -set_name set_name < set_contents.tbl

would read a 1-column table of entries and add them to the contents of the set named set_name owned by owner.
------

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item owner

If supplied, owner name will be used for all subsequent operations

=item set_name

If supplied, all entries will be added to this set

=item -c Column

This is used only if the column containing the input, owner and/or set names is not the last.

=back

=head2 Output Format

=cut

my $usage    = "usage: svr_put_set [--owner=owner_name] [--set_name=set_name]  >output\n";
my $owner = "";
my $set_name = "";
my $column;
my $url = '';
my $opted    = GetOptions('c=i' => \$column, 'owner=s', \$owner, 'set_name=s', \$set_name, 'url=s', \$url);

if (! $opted) { print STDERR $usage; exit }
if (!$set_name || !$owner) {
	print "Missing Owner Set name\n"; exit
}

my @entries = ScriptThing::GetList(\*STDIN, $column);
PersistentSets::put_to_set($set_name, $owner, \@entries);
