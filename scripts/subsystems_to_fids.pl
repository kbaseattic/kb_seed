use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 subsystems_to_fids

Example:

    subsystems_to_fids [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call subsystems_to_fids. It is documented as follows:

  $return = $obj->subsystems_to_fids($subsystems, $genomes)

=over 4

=item Parameter and return types

=begin html

<pre>
$subsystems is a subsystems
$genomes is a genomes
$return is a reference to a hash where the key is a subsystem and the value is a reference to a hash where the key is a genome and the value is a reference to a list containing 2 items:
	0: a variant
	1: a fids
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
genomes is a reference to a list where each element is a genome
genome is a string
variant is a string
fids is a reference to a list where each element is a fid
fid is a string

</pre>

=end html

=begin text

$subsystems is a subsystems
$genomes is a genomes
$return is a reference to a hash where the key is a subsystem and the value is a reference to a hash where the key is a genome and the value is a reference to a list containing 2 items:
	0: a variant
	1: a fids
subsystems is a reference to a list where each element is a subsystem
subsystem is a string
genomes is a reference to a list where each element is a genome
genome is a string
variant is a string
fids is a reference to a list where each element is a fid
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

use SeedUtils;

my $usage = "usage: subsystems_to_fids [-c column] < input > output";

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
    my @h = map { $_->[0] } @tuples;
    my $h = $kbO->subsystems_to_fids(\@h);
    for my $tuple (@tuples) {
        #
        # Process output here and print.
        #
        my ($id, $line) = @$tuple;
       my $genomeH = $h->{$id};
        if (! defined($genomeH))
        {
            print STDERR $line,"\n";
        }
        else
        {
            my @genomes = sort keys(%$genomeH);
            foreach my $g (@genomes)
            {
               my $rows = $genomeH->{$g};
               for my $row (@$rows) {
                    my($variant,$fids) = @$row;
                    foreach my $fid (@$fids)
                    {
                        print join("\t",($line,$g,$variant,$fid)),"\n";
                    }
               }
            }
        }
    }
}


