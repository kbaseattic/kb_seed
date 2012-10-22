use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 tree_by_id

Example:

    tree_by_id [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call tree_by_id. It is documented as follows:



=over 4

=item Parameter and return types

=begin html

<pre>
$tree_id is a tree_id
$return is a newick_tree
tree_id is a string
newick_tree is a string

</pre>

=end html

=begin text

$tree_id is a tree_id
$return is a newick_tree
tree_id is a string
newick_tree is a string


=end text

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing the identifier is not the last column.

=item -i InputFile    [ use InputFile, rather than stdin ]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with extra columns added.

Input lines that cannot be extended are written to stderr.

=cut

use SeedUtils;

my $usage = "usage: tree_by_id [[<]tree_id] > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script();

my $tree_id  = shift @ARGV; 
$tree_id or $tree_id = <STDIN> and chomp($tree_id);

my $newick = $kbO->tree_by_id($tree_id);

print $newick. "\n";


