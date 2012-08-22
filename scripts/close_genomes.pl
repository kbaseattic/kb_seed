use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 close_genomes

Example:

    close_genomes [arguments] < input > output

This is a strange command.  It has two quite distinct uses:

    1. it can be used to find genomes close to existing genomes (stored in either
       the KBase CS or the PubSEED).  
    2. Alternatively, it can be used to compute close genomes for a new genome
       encoded in a JSON file.

The second use will be performed iff the 

     -g Encoded_JSON_directory

is used.  In that case, the updated genome directory will be written to STDOUT.

If the input is to be one or more genomes from the CS, then
the standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call close_genomes. It is documented as follows:

  $return = $obj->close_genomes($seq_set, $n)

=over 4

=item Parameter and return types

=begin html

<pre>
$seq_set is a seq_set
$n is an int
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome
	1: a float
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
genome is a string

</pre>

=end html

=begin text

$seq_set is a seq_set
$n is an int
$return is a reference to a list where each element is a reference to a list containing 2 items:
	0: a genome
	1: a float
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
genome is a string


=end text

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing the identifier is not the last column.

=item -i InputFile    [ use InputFile, rather than stdin ]

=item -n N            [ N is the number of close genomes desired ]


=back

=head2 Output Format

If close genomes are being computed for genomes in the CS, then
the input is a tab-delimited file, and the output will have two
extra columns: [projected degree of identity,close-genome].
If the -g option is used, then an updated genome structure will
be encoded and written to STDOUT.

=cut

use SeedUtils;

my $usage = "usage: close_genomes [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;
my $n = 5;
my $genomeF;
my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
				                       'i=s' => \$input_file,
				                       'n=i' => \$n,
				                       'g=s' => \$genomeF);
if (! $kbO) { print STDERR $usage; exit }

if (defined($genomeF))
{
    my $in_fh;
    open($in_fh, "<", $genomeF) or die "Cannot open $genomeF: $!";
    my $genomeTO;
    local $/;
    undef $/;
    my $genomeTO_txt = <$in_fh>;
    use JSON::XS;
    my $json = JSON::XS->new;
    $genomeTO = $json->decode($genomeTO_txt);

    my $tmp = $genomeTO->{contigs};
    my @raw_contigs = map { [$_->{id},'',$_->{dna}] }  @$tmp;
    my $contigs = \@raw_contigs;
    my $tuples = $kbO->close_genomes($contigs,$n);
    $genomeTO->{close_genomes} = $tuples;
    $json->pretty(1);
    print $json->encode($genomeTO);
}
Else
{
    use Bio::KBase::CDMI::CDMIClient;
    use Bio::KBase::Utilities::ScriptThing;
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

	foreach my $tuple (@tuples)
	{
	    my ($g, $line) = @$tuple;
	    open(CONTIGS,"echo '$g' | genomes_to_contigs | contigs_to_sequences |");
	    my $contigs = &gjoseqlib::read_fasta(\*CONTIGS);
	    close(CONTIGS);
	    my $parms = {};
	    $parms->{-source} = "KBase";
	    $parms->{-csObj} = Bio::KBase::CDMI::CDMIClient->new_for_script();
	    my ($close,$coding) = &CloseGenomes::close_genomes_and_hits($contigs, $parms);
	    my @tmp = @$close;
	    if (@tmp > $n) { $#tmp = $n-1 }  # return the $n closest
	    foreach my $x (@tmp)
	    {
		my($close_g,$avg_iden) = @$x;
		print "$line\t$avg_iden\t$close_g\n";
            }
        }
    }
}
