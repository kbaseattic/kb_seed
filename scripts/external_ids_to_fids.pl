use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 external_ids_to_fids


external_ids_to_fids is used to search for the feature ids that a set of given
external_ids maps to.


Example:

    external_ids_to_fids [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input,
and the output is to the standard output. For each input line, there
can be many output lines, one per feature. The feature id is added to
the end of the line.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call external_ids_to_fids. It is documented as follows:

  $return = $obj->external_ids_to_fids($external_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$external_ids is an external_ids
$return is a reference to a hash where the key is an alias and the value is a fid
external_ids is a reference to a list where each element is an external_id
external_id is a string
fid is a string
</pre>

=end html

=begin text

$external_ids is an external_ids
$return is a reference to a hash where the key is an alias and the value is a fid
external_ids is a reference to a list where each element is an external_id
external_id is a string
fid is a string

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


my $usage = "usage: external_ids_to_fids [-c column] [-prefix] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;
my $prefix_flag = 0;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
						       'prefix' => \$prefix_flag,
						       'i=s' => \$input_file);
if (! $kbO) { print STDERR $usage; exit }

my $ih;
if ($input_file)
{
    open $ih, "<", $input_file or die "Cannot open input file $input_file: $!";
}
else
{
    $ih = \*STDIN;
}

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, 10, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $kbO->external_ids_to_fids(\@h, $prefix_flag);
    for my $tuple (@tuples) {
        #
        # Process output here and print.
        #
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};

        if (! defined($v))
        {
            print STDERR $line,"\n";
        }
        elsif (ref($v) eq 'ARRAY')
        {
            foreach $_ (@$v)
            {
                print "$line\t$_\n";
            }
        }
        else
        {
            print "$line\t$v\n";
        }
    }
}
