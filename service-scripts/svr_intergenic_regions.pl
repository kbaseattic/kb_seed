use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_intergenic_regions

List all the intergenic regions in the contigs for a specified genome.

Intergenic regions are defined here as areas of the contig not occupied by
features of specified types, usually PEG and/or RNA.

The genome ID and the types of features to be considered in computing the regions
are specified on the command line. The output will be a flat file containing
L<SAP/Location Strings>, one per line. For example,

    svr_intergenic_regions 360108.3 peg rna

would output strings for the locations in the contigs for genome 360108.3 that
are not used by PEGs or RNAs.

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=back

=head2 Output Format

The standard output is a file where each line just contains a location string.

=cut


use SeedEnv;
use Getopt::Long;

my $usage = "usage: svr_intergenic_regions Genome [Type1 Type2 ...]";

my $url;
my $opted =  GetOptions('url=s' => \$url);
if (! $opted) {
    print "$usage\n";
} else {
    my $genome = shift @ARGV or die $usage;
    my @types = @ARGV;

    my $sapObject = SAPserver->new(url => $url);
    
    my $locList = $sapObject->intergenic_regions(-genome => $genome,
                                                 -type => \@types);
    for my $loc (@$locList) {
        print "$loc\n";
    }
}
