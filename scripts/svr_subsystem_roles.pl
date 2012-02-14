#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use ScriptThing;

#
#	This is a SAS Component.
#

=head1 svr_subsystem_roles

    svr_subsystem_roles "subsystem ID" >sub_data.tbl


Output the roles of a subsystem.

This script takes as input a subsystem name on the command line and produces a
tab-delimited file of all the roles in the subsystem (in order) and their
abbreviations. Each line of the file will contain the subsystem name, abbreviation and
the full role name. The output will be produced on the standard output.

Note that because the subsystem name likely contains spaces, it will need to be
enclosed in quotes on the command-line.

If you want to see the data for a set of subsystems, you can read a file of genome IDs.
The script will then write out the roles for all subsystems in the file. 

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item aux

If specified, auxiliary roles will be included in the output. Normally these are
excluded.

=back

=cut

# Parse the command-line options.
my $url = '';
my $aux;
my $column;
my $opted =  GetOptions('url=s' => \$url, 
			'c=i' => \$column,
			aux => \$aux);
my $subID = $ARGV[0];
if (! $opted)
{
    print "usage: svr_subsystem_roles [--url=http://...] [--aux] \"subsystem name\" >output\n";
} else {
    # Get the server object.
    my $sapServer = SAPserver->new(url => $url);
    my @lines;
    if ($ARGV[0])
    {
	@lines = ([$ARGV[0]]);
    }
    else
    {
	@lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
    }
    (@lines > 0) || exit;
    if (! $column)  { $column = @{$lines[0]} }
    my @ss = map { $_->[$column-1] } @lines;
    my $subHash = $sapServer->subsystem_roles(-ids => \@ss, -aux => $aux, -abbr => 1);
    foreach my $subID (@ss)
    {
	# Loop through them, producing output.
	my $roles = $subHash->{$subID};
	if (! $roles) {
	    print STDERR "Could not find \"$subID\".\n";
	} else {
	    for my $role (@$roles) {
		my ($roleID, $abbr) = @$role;
		print "$subID\t$abbr\t$roleID\n";
	    }
        }
    }
}

