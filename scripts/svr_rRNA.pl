#
#	This is a SAS Component.
#

use strict;

=head1 svr_rRNA

Get 16S rRNAs of genomes 

  Usage: svr_rRNA [--c=N] <genome_id_list >rRNA.fasta

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing Genome IDs is not the last.

=back

=head2 Output Format

The standard output is a FASTA file containing the rRNA sequences.

=cut


use Getopt::Long;
use gjoseqlib;

my $usage = "Usage: svr_rRNA [--c=N] <genome_id_list >rRNA.fasta\n\n";
my $column;

my $opted = GetOptions('c=i' => \$column);
$opted or die $usage;

my @lines = map { chomp; [ split /\t/ ] } <STDIN>;
$column ||= @{$lines[0]};

my %gid = map { /(\d+\.\d+)/ ? ($1 => 1) : () } map { $_->[$column-1] } @lines;

my $rRNA_file = "/vol/public-pseed/FIGdisk/FIG/Data/Global/genome_rRNA.fasta";
-s $rRNA_file or die "Could not open $rRNA_file\n\n";

my @seqs = grep { $gid{$_->[0]} } gjoseqlib::read_fasta($rRNA_file);

gjoseqlib::print_alignment_as_fasta(@seqs);

