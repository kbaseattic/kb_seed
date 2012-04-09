use strict;
use Data::Dumper;
use Carp;
use Corresponds;

#
# This is a SAS Component
#

=head1 corresponds

Example:

    corresponds [arguments] < input > output

The input file should be a table with one column containing fids to
be projected to a designated genome.

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call corresponds. It is documented as follows:

  $return = $obj->corresponds($fids, $genome)


=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a fids
$genome is a genome
$return is a reference to a hash where the key is a fid and the value is a correspondence
fids is a reference to a list where each element is a fid
fid is a string
genome is a string
correspondence is a reference to a hash where the following keys are defined:
	to has a value which is a fid
	ncontext has a value which is an int
	b1 has a value which is an int
	e1 has a value which is an int
	ln1 has a value which is an int
	b2 has a value which is an int
	e2 has a value which is an int
	ln2 has a value which is an int
	score has a value which is an int

</pre>

=end html

=begin text

$fids is a fids
$genome is a genome
$return is a reference to a hash where the key is a fid and the value is a correspondence
fids is a reference to a list where each element is a fid
fid is a string
genome is a string
correspondence is a reference to a hash where the following keys are defined:
	to has a value which is a fid
	ncontext has a value which is an int
	b1 has a value which is an int
	e1 has a value which is an int
	ln1 has a value which is an int
	b2 has a value which is an int
	e2 has a value which is an int
	ln2 has a value which is an int
	score has a value which is an int


=end text

=back

=head2 Command-Line Options

=over 4

=item -g Genome

This is used to designate a genome in the CS.  The command will try to
project fids from the input to fids in this designated genome.

=item -tsg Genome

This is used to designate a genome in the default TS.  The command will try to
project fids from the input to fids in this designated genome.  This argument
and the <b>-g</b> argument ar mutually exclusive.  If they both are specified
then the genome in the CS will be used.

= item -a Cutoff

This requests an abbreviated format in which only two columns are added:
the projection score and the fid in the target genome.  If this is not
used 10 column are added.  The Cutoff specifies a minimum projection score.

=item -c Column

This is used only if the column containing the identifier is not the last column.

=item -i InputFile    [ use InputFile, rather than stdin ]


=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with extra columns added.  If the abbreviated format is requested,
two columns get added (sc and the fid projected to).  If the abbreviated
format is not requested, ten columns will be added 

[percent-identity,matching-context,b1,e1,ln1,b2,e2,ln2,sc,to-fid]

Input lines that cannot be extended are written to stderr.

=cut

use SeedUtils;

my $usage = "usage: corresponds [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;
my $input_file;
my $min_sc = 0;
my $cs_genome;
my $ts_genome;

my $csO = Bio::KBase::CDMI::CDMIClient->new_for_script(
				      'c=i' => \$column,
				      'i=s'   => \$input_file,
				      'a=f'   => \$min_sc,
                                      'g=s'   => \$cs_genome,
				      'tsg=s' => \$ts_genome);
						       
if (! $csO) { print STDERR $usage; exit }
if ((! $cs_genome) && (! $ts_genome)) { print STDERR "You need to specify a target genome" }
if ($ts_genome) { die "-tsg not supported yet" }
my $genome = $cs_genome ? $cs_genome : $ts_genome;

my $ih;
if ($input_file)
{
    open $ih, "<", $input_file or die "Cannot open input file $input_file: $!";
}
else
{
    $ih = \*STDIN;
}
while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, 100000, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $csO->corresponds(\@h,$genome);
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
        elsif (ref($v) eq 'HASH')
        {
	    if (! $min_sc) 
	    {
		print join("\t",($line,$v->{iden},
				       $v->{ncontext},
				       $v->{b1},
				       $v->{e1},
				       $v->{ln1},
				       $v->{b2},
				       $v->{e2},
				       $v->{ln2},
				       $v->{score},
				       $v->{to}
			  )),"\n";
	    }
	    elsif ($v->{score} >= $min_sc)
	    {
		print join("\t",($line,$v->{score},$v->{to})),"\n";
	    }
        }
    }
}
