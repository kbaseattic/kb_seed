use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 co_occurrence_evidence

Example:

    co_occurrence_evidence [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call co_occurrence_evidence. It is documented as follows:

  $return = $obj->co_occurrence_evidence($pairs_of_fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$pairs_of_fids is a pairs_of_fids
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: a pair_of_fids
	1: an evidence
pairs_of_fids is a reference to a list where each element is a pair_of_fids
pair_of_fids is a reference to a list containing 2 items:
	0: a fid
	1: a fid
fid is a string
evidence is a reference to a list where each element is a pair_of_fids

</pre>

=end html

=begin text

$pairs_of_fids is a pairs_of_fids
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: a pair_of_fids
	1: an evidence
pairs_of_fids is a reference to a list where each element is a pair_of_fids
pair_of_fids is a reference to a list containing 2 items:
	0: a fid
	1: a fid
fid is a string
evidence is a reference to a list where each element is a pair_of_fids


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

my $usage = "usage: co_occurrence_evidence [-c column] < input > output";

use CDMIClient;
use ScriptThing;

my $column;

my $input_file;

my $kbO = CDMIClient->new_for_script('c=i' => \$column,
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

while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @h;
    my %lines;
    foreach my $tuple (@tuples) {
	my ($id, $line) = @$tuple;
        my ($a, $b) =  split(":", $id);
	push (@h, [$a, $b]);
	#make a hash so I can look up the line;	
	$lines{$id} = $line;
    }
    my $h = $kbO->co_occurrence_evidence(\@h);

    foreach my $p (@$h) {
	my $a = join(":", @{$p->[0]});
        my @b;
	foreach my $pair (@{$p->[1]}) {
		push (@b, join(":", @$pair));
	}

	print $lines{$a}, "\t";;
	print join(",",@b), "\n";
    }
}
