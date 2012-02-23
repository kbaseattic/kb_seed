use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 get_entity_Subsystem

Example:

    get_entity_Subsystem -a < ids > table.with.fields.added

would read in a file of ids and add a column for each filed in the entity.

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

my @all_fields = ( 'version', 'curator', 'notes', 'description', 'usable', 'private', 'cluster_based', 'experimental' );
my %all_fields = map { $_ => 1 } @all_fields;

my $usage = "usage: get_entity_Subsystem [-c column] [-a | -f field list] < ids > extended.by.a.column(s)";

my $column;
my $a;
my $f;
my $i = "-";
my @fields;
my $geO = CDMIClient->new_get_entity_for_script('c=i'	   => \$column,
						"a"	   => \$a,
						"fields=s" => \$f,
						'i=s'	   => \$i);		      
if ($a && $f) { print STDERR $usage; exit 1 }
if ($a)
{
    @fields = @all_fields;
}
elsif ($f) {
    my @err;
    for my $field (split(",", $f))
    {
	if (!$all_fields{$field})
	{
	    push(@err, $field);
	}
	else
	{
	    push(@fields, $field);
	}
    }
    if (@err)
    {
	print STDERR "get_entity_Subsystem: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
} else {
    print STDERR $usage;
    exit 1;
}

open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $geO->get_entity_Subsystem(\@h, \@fields);
    for my $tuple (@tuples) {
        my @values;
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};
	if (! defined($v))
	{
	    #nothing found for this id
	    print STDERR $line,"\n";
     	} else {
	    foreach $_ (@fields) {
		push (@values, $v->{$_});
	    }
	    my $tail = join("\t", @values);
	    print "$line\t$tail\n";
        }
    }
}
