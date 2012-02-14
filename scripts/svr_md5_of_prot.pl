use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

use Digest::MD5;

=head1 svr_md5_of_prot

Get md5s of protein-encoding genes

------

Example:

    svr_all_features 3702.1 peg | svr_md5_of_prot

would produce a 2-column table.  The first column would contain
PEG IDs for genes occurring in genome 3702.1, and the second
would contain the md5 values of the encoded genes.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG for which md5s are being requested.
If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the md5 associated with the PEG).

=cut

use SeedEnv;
$ENV{'SAS_DEBUG'} = 1;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_md5_of [-c column]";

my $column;
my $i = "-";
my $rc  = GetOptions('c=i' => \$column, 'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @ids = map { $_->[0] } @tuples;
#   print STDERR &Dumper(\@ids); 
    my $md5H = $sapObject->fids_to_proteins(-ids => \@ids);
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
        my $md5 = $md5H->{$id};
        if (! defined $md5) {
	    if ($id)
	    {
		my $seqsH = $sapObject->ids_to_sequences(-ids => [$id], -protein => 1);
		if ($seqsH->{$id})
		{
		    my $md5 = Digest::MD5::md5_hex( uc $seqsH->{$id} );
		    if (! $md5)
		    {
			print STDERR "$id not found.\n";
		    }
		    else
		    {
			print "$line\t$md5\n";
		    }
		}
		else
		{
		    print STDERR "$id not found.\n";
		}
	    }
        } else {
            print "$line\t$md5\n";
        }

    }
}
