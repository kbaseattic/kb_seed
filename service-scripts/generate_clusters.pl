use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_generate_clusters RefGenome FileOfComparisonGenomes > clusters

Produce a file of "basic clusters" for a reference genome


------

Example:

    svr_generate_clusters -r 83333.1 -f EntericGenomes > ecoli.clusters

would produce a 2-column tyable [setNumber,Peg].

=head2 Command-Line Options

=over 4

=item -r Refernce genome Id

=item -f File

a file containing genomeIds to support comparison

=back

=head2 Output Format

The standard output is a 2-column tab-delimited file.
The first column is the set id, and the second is a Peg included in the set.

=cut

use SeedUtils;
use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;
use GenerateClusters;

my $usage = "usage: svr_generate_clusters -r RefId -f GenomesToCompare";

my $ref;
my $file;

my $rc  = GetOptions('r=s' => \$ref, 
		     'f=s' => \$file);
if (! $rc) { print STDERR $usage; exit }

if (! $ref)  { die "you need to give a reference genome id in the -r argument" }
if (! $file) { die "you need to give a file of genomes -f  argument" }

my @genomes = map { ($_ =~ /^(\S+)/) ? $1 : () } `cat $file`;

my $conn = &GenerateClusters::generate_clusters($ref,\@genomes);
foreach $_ (@$conn)
{
    print join("\t",@$_),"\n";
}
