use strict;

use Getopt::Long;
use SeedUtils;
use SAPserver;

#
# This is a SAS Component
#


=head1 svr_exp_genomes

List the names and IDs of all the genomes with expression data.

There is no input.  The output is a file of genome names and genome IDs.

------
Example: svr_exp_genomes > expression_data_genomes.tbl

would produce a 2-column table.  The first column would contain the
names of all complete genomes, and the second the IDs of those genomes.
------

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=back

=head2 Output Format

The standard output is a file where each line contains a genome name and a genome ID.

=cut

my $usage    = "usage: svr_exp_genomes [--url=http://...] >output\n";
my $complete = 0;
my $url = '';
my $opted    = GetOptions('complete' => \$complete, 'url=s', \$url);

if (! $opted) {
    print $usage;
} else {
    my $sapObject  = SAPserver->new(url => $url);
    my $genomeHash = $sapObject->expressed_genomes( -names => 1 );
    while (my ($id, $name) = each %$genomeHash ) {
        print "$name\t$id\n";
    }
}
