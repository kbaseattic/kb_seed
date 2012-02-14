use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 svr_aliases_to_pegs 

Convert aliases to PEGs

------

Example:

    svr_aliases_to_pegs -protein < aliases > plus_PEGs 2> no.matches

assumes that the files aliases ends with a column containing aliases.
An extra column containing PEGs will be added, and those aliases that
do not match PEGs will be written to STDERR.

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

=item -protein=1 (optional)

If TRUE, then all FIG IDs for equivalent proteins will be returned. The default is FALSE, 
meaning that only FIG IDs for the same gene will be returned.

=item -source

Specifies the source of the incoming IDs. The default is C<prefixed>, which means the
type of the incoming ID will be determined by its prefix (C<gi> for NCBI numbers,
C<uni> for UniProt IDs). Otherwise, use the name of the database from which the IDs
were taken: C<RefSeq>, C<CMR>, C<NCBI>, C<Trembl>, or C<UniProt>.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the matching PEGs).

=cut

use Getopt::Long;
use SeedUtils;
use SAPserver;
my $sapO = SAPserver->new();

my $usage = "usage: svr_aliases_to_pegs [-c column] [-protein=1]\n";

my $column;
my $protein = 0;
my $source = "prefixed";
my $rc  = GetOptions('c=i' => \$column, 'protein=i' => \$protein, 'source=s' => \$source);
if (! $rc) { print STDERR $usage; exit }

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
if (! $column)  { $column = @{$lines[0]} }
my @aliases = map { $_->[$column-1] } @lines;

my $aliasH = $sapO->ids_to_fids( -ids => \@aliases, -protein => $protein, -source => $source );
foreach my $line (@lines)
{
    my $pegs = $aliasH->{$line->[$column-1]};
    if (defined($pegs) && (@$pegs > 0))
    {
	foreach my $peg (@$pegs)
	{
	    print join("\t",@$line,$peg),"\n";
	}
    }
    else
    {
	print STDERR join("\t",@$line),"\n";
    }
}
