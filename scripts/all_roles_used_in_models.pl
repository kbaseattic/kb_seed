use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 all_roles_used_in_models

Example:

    all_roles_used_in_models [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call all_roles_used_in_models. It is documented as follows:

  $return = $obj->all_roles_used_in_models()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a roles
roles is a reference to a list where each element is a role
role is a string

</pre>

=end html

=begin text

$return is a roles
roles is a reference to a list where each element is a role
role is a string


=end text

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing the subsystem is not the last column.

=item -i InputFile    [ use InputFile, rather than stdin ]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with extra columns added.

Input lines that cannot be extended are written to stderr.

=cut

use SeedUtils;

my $usage = "usage: all_roles_used_in_models [-c column] < input > output";

use CDMIClient;
use ScriptThing;


my $kbO = CDMIClient->new_for_script();
if (! $kbO) { print STDERR $usage; exit }

my $h = $kbO->all_roles_used_in_models();
foreach my $role (@$h) {
print $role, "\n";
}
