use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_function_of

Get functions of protein-encoding genes

------

Example:

    svr_all_features 3702.1 peg | svr_function_of

would produce a 2-column table.  The first column would contain
PEG IDs for genes occurring in genome 3702.1, and the second
would contain the functions of those genes.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG for which functions are being requested.
If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -s

Strip comments from the functions.

=item -keep

This is used to keep input lines for which the PEG has no function

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the function associated with the PEG).

=cut

use SeedUtils;
use SAPserver;
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_function_of [-c column] [-keep] [-s]";

my $column;
my $keep = 1;
my $i = "-";
my $s;
my $url = '';
my $rc  = GetOptions('c=i' => \$column, 
		     'keep' => \$keep,
		     's' => \$s, 'url=s' => \$url,
		     'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
my $sapObject = SAPserver->new(url => $url);
open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @ids = map { $_->[0] } @tuples;
    my $functions = $sapObject->ids_to_functions(-ids => \@ids);
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
        my $function = $functions->{$id};
        if (! defined $function) {
#           print STDERR "$id not found.\n";
	    if ($keep) { print "$line\t\n" }
        } else {
            if ($s) {
                $function = ($function =~ /(.+?)\s*[#!]/ ? $1 : $function);
            }
            print "$line\t$function\n";
        }
    }
}
