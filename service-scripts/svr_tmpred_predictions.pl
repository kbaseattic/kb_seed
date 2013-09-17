########################################################################
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_tmpred_predictions

Estimate transmembrane domains

------

Example:

    svr_all_features 3702.1 peg | svr_tmpred_predictions

would produce a 5-column table.  The first column would contain
PEG IDs for genes occurring in genome 3702.1, and the remainder are
use to capture the core domains and scores produced by TMpred.  There
would be a separate line for each predicted TM domain.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG for which functions are being requested.
If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -min MinSc  [defaults to 0]

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with five extra columns added:

    the beginning of the core domain
    the end of the core domain
    the score
    the predicted center
    the direction (outside-to-inside or inside-to-outside)

=cut

use SeedEnv;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;
use ScriptThing;
use LWP;
use URI;

my $usage = "usage: svr_tmpred_predictions [-c column] [-min = MinSc] ";

my $i = "-";
my $column;
my $cutoff = 0;
my $rc  = GetOptions('c=i' => \$column,
		     'min=i' => \$cutoff,
		     'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @ids = map { $_->[0] } @tuples;
    my $pegH = $sapObject->ids_to_sequences( -ids => \@ids,
					     -protein => 1,
					     -fasta   => 0);
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
	my $seq = $pegH->{$id};
	my $browser = LWP::UserAgent->new;
	my $url = "http://www.ch.embnet.org/cgi-bin/TMPRED_form_parser";
	my $response = $browser->post($url,
				      [
				       'outmode' => "html",
				       'min' => "17",
				       'max' => "33",
				       'comm' => "FIGSEQ",
				       'format' => "plain_text",
				       'seq' => $seq
				       ]
				      );
	my @good_hits;
	my $x = $response->content;
	if ($x =~ /Inside to outside[^\n]+\n[ \t]+from[ \t]+to[ \t]+score[ \t]+center\s+(.*?)\n\n/sg)
	{
	    push(@good_hits,map { (($_ =~ /^\s*\d+\s*\(\s*(\d+)\)\s+\d+\s+\(\s*(\d+)\)\s+(\d+)\s+(\d+)/) && ($3 >= $cutoff)) ? [$1,$2,$3,$4,'inside-to-outside'] : () }
		            split(/\n/,$1));
	}

	if ($x =~ /Outside to inside[^\n]+\n[ \t]+from[ \t]+to[ \t]+score[ \t]+center\s+(.*?)\n\n/sg)

	{
	    push(@good_hits, map { (($_ =~ /^\s*\d+\s*\(\s*(\d+)\)\s+\d+\s+\(\s*(\d+)\)\s+(\d+)\s+(\d+)/) && ($3 >= 400)) ? [$1,$2,$3,$4,'outside-to-inside'] : () }
		             split(/\n/,$1));
	}
        @good_hits = sort { ($a->[0] <=> $b->[0]) } @good_hits;
	foreach my $tm (@good_hits)
	{
	    print join("\t",($line,@$tm)),"\n";
	}
    }
}

sub overlaps {
    my($b1,$e1,$b2,$e2) = @_;

    return ((($b1 <= $b2) && ($b2 <= $e1)) ||
	    (($b2 <= $b1) && ($b1 <= $e2)));
}
