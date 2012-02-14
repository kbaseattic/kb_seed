########################################################################
use strict;
use Data::Dumper;
use Carp;


=head1 svr_scanP

Scan proteins for a designated pattern

------

Example:

    svr_all_features 83333.1 peg | svr_scanP 'CxxC' 

would produce a 3-column table.  The first column would contain
the string in a PEG that matched the pattern, the second the location in the PEG
encoded by a gene, and the third the PEG id.

Here is a more interesting pattern:

	CxxH 2...5 GC

It would match things like CAAGRIC, CIGHAAAAAG, etc.  The x...y notation means "a string of
x to y characters in length".  The character 'x' is will match any amino acid.  The match
is case-insensitive.

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

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with three extra columns added (the matched string, the location,
and the matched PEG).  Note that when the pattern is made up of
multiple components, you get embedded blanks within the field giving
the matched string.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_scanP Pattern [-c column]";

my $column;
my $rc  = GetOptions('c=i' => \$column);
if (! $rc) { print STDERR $usage; exit }
(@ARGV > 0) || die "you need to specifiy a pattern";

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
(@lines > 0) || exit;
if (! $column)  { $column = @{$lines[0]} }
my @fids = map { $_->[$column-1] } @lines;
my $matches = &scan_for_matches($sapObject,$ARGV[0],\@fids);
foreach $_ (@lines)
{
    my $hits = $matches->{$_->[$column-1]};
    foreach my $hit (@$hits)
    {
	print join("\t",@$_,@$hit),"\n";
    }
}

sub scan_for_matches {
    my($sapObject,$pat,$pegs) = @_;

    my $hitsH;

    my $hitsF    = "tmp.scanP.hits.$$";
    my $patternF = "tmp.scanP.pattern.$$";
    open(TMP,">",$patternF) || die "could not open $patternF";
    print TMP $pat,"\n";
    close(TMP);
    open(HITS,"| svr_fasta -protein -fasta | scan_for_matches -p $patternF > $hitsF") || die "could not run scan_for_matches";
    foreach my $peg (@$pegs)
    {
	print HITS "$peg\n";
    }
    close(HITS);
    open(HITS,"<",$hitsF) || die "could not open $hitsF";
    while (defined($_ = <HITS>) && ($_ =~ /^>(.*)\:\[(\d+),(\d+)\]/))
    {
	my $peg = $1;
	my $loc = $2;
	my $str = <HITS>; chomp $str;
	push(@{$hitsH->{$peg}},[$loc,$str]);
    }
    unlink($hitsF,$patternF);
    return $hitsH;
}
