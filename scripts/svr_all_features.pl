use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_all_features Genome Type

Get a list of Feature IDs for all features of a given type in a given genome
or a list of genomes.

If a genome ID is specified in the command line, there is no input. Otherwise,
this script takes as input a tab-delimited file with genome IDs at the end of
each line.

The output is a file of feature IDs, one ID per line.

------
Example: svr_all_features 3702.1 peg | svr_function_of

would produce a 2-column table.  The first column would contain
PEG IDs for genes occurring in genome 3702.1, and the second
would contain the functions of those genes.
------

=head2 Command-Line Options

=over 4

=item Genome

A genome that is in the SEED. The ID must be a valid SEED genome ID of the
form /^\d+\.\d+$/ (i.e., of the form xxxx.yyy)

=item Type

The type of the features sought (e.g., peg or rna)

=back

=head2 Output Format

The standard output is a file where each line just contains a feature ID.

=cut


use SeedEnv;
my $sapObject = SAPserver->new();

my $usage = "usage: svr_all_features [Genome] Type";

my($genome, $type);

if (@ARGV == 1)
{
    $type = shift;
}
elsif (@ARGV == 2)
{
    $genome = shift;
    $type = shift;

    process_genomes($type, [$genome]);
    exit;
}
else
{
    die $usage;
}

#
# If we get here, we are reading genomes from STDIN. Process in batches
# to make this code friendlier on the servers for large input files.
#

my $batch_size = 10;

my @genomes;

while (<STDIN>)
{
    chomp;
    my @cols = split(/\t/);
    my $genome = $cols[-1];
    push(@genomes, $genome);
    if (@genomes >= $batch_size)
    {
	process_genomes($type, \@genomes);
	@genomes = ();
    }
}
if (@genomes)
{
    process_genomes($type, \@genomes);
}
   
sub process_genomes
{
    my($type, $genomes) = @_;

    # print STDERR "Request @$genomes\n";
    my $fidHash = $sapObject->all_features(-ids => $genomes, -type => $type);

    foreach my $gid (@$genomes)
    {
	foreach my $fid (sort { &SeedUtils::by_fig_id($a, $b) } @{$fidHash->{$gid}} )
	{
	    print "$fid\n";
	}
    }
}

