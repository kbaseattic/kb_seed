use strict;

use Getopt::Long;
use SeedEnv;
use PersistentSets;

#
# This is a SAS Component
#


=head1 svr_create_set

Create  a persistent set owned by owner


------
Example: svr_create_set -owner owner_name  -set_name setname

------

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item owner

 required name of owner 

=back
=item set_name

 required name of set 

=back

=cut

my $usage    = "usage: svr_create_set --owner=owner_name --set_name=set name \n";
my $owner;
my $set_name;
my $url = '';
my $opted    = GetOptions('set_name=s' => \$set_name, 'owner=s', \$owner, 'url=s', \$url);

if (! $opted) { print STDERR $usage; exit }
if (!$set_name || !$owner) {
        print "Missing Owner Set name\n"; exit
}

PersistentSets::create_set("no type", $set_name, $owner, "no desc");

