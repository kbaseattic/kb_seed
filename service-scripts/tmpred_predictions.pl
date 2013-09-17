########################################################################
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 tmpred_predictions

Estimate transmembrane domains

------

Example:

    tmpred_predictions < fasta-file

would produce a 5-column table.  The first column would contain
the IDs from the fasta input file, and the remainder are
use to capture the core domains and scores produced by TMpred.  There
would be a separate line for each predicted TM domain.
------

The standard input should be a FASTA formatted file of protein sequences.

=head2 Command-Line Options

=over 4

=item -min MinSc  [defaults to 0]

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
TD with five extra columns added:

    the beginning of the core domain
    the end of the core domain
    the score
    the predicted center
    the direction (outside-to-inside or inside-to-outside)

=cut

use SeedEnv;
use Getopt::Long;
use ScriptThing;
use LWP;
use URI;

my $usage = "usage: svr_tmpred_predictions [-min = MinSc] ";

my $cutoff = 0;
my $rc  = GetOptions('min=i' => \$cutoff);
if (! $rc) { print STDERR $usage; exit }

$/ = "\n>";
while (defined($_ = <STDIN>))
{
    chomp;
    $/ = "\n";
    if ($_ =~ /^>?(\S+)[^\n]*\n(.*)/s)
    {
	my $id = $1; 
	my $seq = $2;
	$seq =~ s/\s//gs;
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
	    print join("\t",($id,@$tm)),"\n";
	}
    }
    $/ = "\n>";
}
