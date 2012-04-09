use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 close_genomes

Example:

    close_genomes [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call close_genomes. It is documented as follows:

  $return = $obj->close_genomes($genomes, $how, $n)


=over 4

=item Parameter and return types

=begin html

<pre>
$genomes is a genomes
$how is a how
$n is an int
$return is a reference to a hash where the key is a genome and the value is a genomes
genomes is a reference to a list where each element is a genome
genome is a string
how is an int

</pre>

=end html

=begin text

$genomes is a genomes
$how is a how
$n is an int
$return is a reference to a hash where the key is a genome and the value is a genomes
genomes is a reference to a list where each element is a genome
genome is a string
how is an int


=end text

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing the identifier is not the last column.

=item -i InputFile    [ use InputFile, rather than stdin ]

=item -n N            [ N is the number of close genomes desired ]

=item -how Algorithm  [ optional:  0 -> default,
                                   1 -> just match scientific names of genomes
			           2 -> use SSU rRNA (not yet implemented)
                                   3 -> use "universal proteins" (not yet implemented)
                      ]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (a close genome)

Input lines that cannot be extended are written to stderr.

=cut

use SeedUtils;

my $usage = "usage: close_genomes [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;
my $n = 5;
my $how = 0;
my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
				                       'i=s' => \$input_file,
				                       'n=i' => \$n,
				                       'how=i' => \$how);
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

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $kbO->close_genomes(\@h,$how,$n);
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
    }
}
