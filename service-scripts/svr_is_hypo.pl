use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_is_hypo [-c N] [-v]

Keep just hypotheticals

------

Example:

    svr_all_features 3702.1 peg | svr_is_hypo

would produce a 1-column table containing the hypotheticals in 3702.1

Normally, a stream of feature IDs (PEGs) is used as input.  If the things you send
through do not look like PEGs, then they are treated as functional roles.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG .  If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -v [keep only non-hypotheticals]

=back

=head2 Output Format

This is a filter producing a subset of the input lines.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_is_hypo [-c column] [-v]";

my $column;
my $v;
my $rc  = GetOptions('c=i' => \$column,
		     'v'   => \$v);
if (! $rc) { print STDERR $usage; exit }

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
(@lines > 0) || exit;
if (! $column)  { $column = @{$lines[0]} }
my @fids = grep { $_ =~ /^fig\|/ } map { $_->[$column-1] } @lines;

my $functions = $sapObject->ids_to_functions(-ids => \@fids);
foreach $_ (@lines)
{
    my $thing = $_->[$column-1];
    my $func;
    if ($thing =~ /^fig\|/)
    {
	$func = $functions->{$thing};
    }
    else
    {
	$func = $thing;
    }
    my $hypo = &SeedUtils::hypo($func);
    if (((! $v) && $hypo) || ($v && (! $hypo)))
    {
	print join("\t",@$_),"\n";
    }
}
