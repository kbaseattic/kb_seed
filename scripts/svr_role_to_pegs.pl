########################################################################
use strict;
use Data::Dumper;
use Carp;
use SeedEnv;
#
# This is a SAS Component
#


=head1 svr_role_to_pegs [-c column] [-g Genomes] < Roles > with.PEGs

Get PEGs that implement a given set of functional roles

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain a role for which functions are being requested.
If some other column contains the roles, use

    -c N

where N is the column (from 1) that contains the role in each case.

If you wish to constrain the set of PEGs to a specific set of genomes,
you can specify a file containing genomes IDs.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -g Genomes

This is a file containing a genome ID in column 1 (use cut -fn to make the file
if necessary).

=back

=head2 Output Format

The output file is a copy of the table from the input, except
that an extra column giving a PEG id is appended (and many lines
in the output may result from a single input line).

=cut

use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_role_to_pegs [-c column] [-g Genomes] < Roles > with.PEGs";

my $column;
my $genomesF;
my $rc  = GetOptions('c=i' => \$column,
		     'g=s' => \$genomesF);
if (! $rc) { print STDERR $usage; exit }

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
if (! $column)  { $column = @{$lines[0]} }
my @roles = map { $_->[$column-1] } @lines;

my @genomes;
if ($genomesF)
{
    open(GENOMES,"<",$genomesF) || die "could not open $genomesF";
    @genomes = map { ($_ =~ /^(\d+\.\d+)/) ? $1 :  () } <GENOMES>;
    close(GENOMES);
}

my $roleH;
if ($genomesF)
{
    $roleH = $sapO->occ_of_role( -roles => \@roles, -genomes => \@genomes );
}
else
{
    $roleH = $sapO->occ_of_role( -roles => \@roles );
}
foreach my $line (@lines)
{
    my $role = $line->[$column-1];
    if (my $pegs = $roleH->{$role})
    {
	foreach my $peg (sort { &SeedUtils::by_fig_id($a,$b) } @$pegs)
	{
	    print join("\t",(@$line,$peg)),"\n";
	}
    }
}


