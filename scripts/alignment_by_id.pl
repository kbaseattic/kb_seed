use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 alignment_by_id

Example:

    alignment_by_id [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call alignment_by_id. It is documented as follows:



=over 4

=item Parameter and return types

=begin html

<pre>
$arg_1 is a string
$return is an alignment
alignment is a seq_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string

</pre>

=end html

=begin text

$arg_1 is a string
$return is an alignment
alignment is a seq_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string


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
use gjoseqlib;

my $usage = "usage: alignment_by_id [[<]aln_id] > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script();

my $aln_id  = shift @ARGV; 
$aln_id or $aln_id = <STDIN> and chomp($aln_id);

my $aln = $kbO->alignment_by_id($aln_id);

gjoseqlib::print_alignment_as_fasta($aln);


