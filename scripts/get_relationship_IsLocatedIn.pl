use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 get_relationship_IsLocatedIn

Example:

    get_relationship_IsLocatedIn -a < ids > table.with.fields.added

would read in a file of ids and add a column for each filed in the relationship.

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the id. If some other column contains the id,
use

    -c N

where N is the column (from 1) that contains the id.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing id is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added for each requested field.  Input lines that cannot
be extended are written to stderr.  

=cut
use ScriptThing;
use CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'ordinal', 'begin', 'len', 'dir' );
my %all_fields = map { $_ => 1 } @all_fields;

my $usage = "usage: get_relationship_IsLocatedIn [-c column] [-a | -f field list] < ids > extended.by.a.column(s)";

my $column;
my $a;
my $f;
my $i = "-";
my @fields;
my $geO = CDMIClient->new_get_entity_for_script('c=i'	   => \$column,
						"a"	   => \$a,
						"fields=s" => \$f,
						'i=s'	   => \$i);		      

#my @h = ('FIG00000004');
#my $h = $geO->get_relationship_IsFamilyFor(\@h, ['type'], [], ['description']);
my @h = ('kb|SEED|fig|1000565.3.peg.1183');
my $h = $geO->get_relationship_IsLocatedIn(\@h, ['sequence_length', 'function'], ['len'], ['source_id']);
print Dumper($h);
