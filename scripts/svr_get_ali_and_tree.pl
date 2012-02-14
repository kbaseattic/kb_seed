########################################################################
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 svr_get_ali_and_tree 

Get alignments and trees corresponding based on a
set of gene IDs.

------

Example:

    svr_get_ali_and_tree -d Output < PEGs

andirectory of output (Output will be created, if it does not already
exist).  There will be one subdirectory for every input PEG.  That directory
will contain a set of files that will include the alignment, the tree, and the
HTML files to display each.

------

    The input should be a file; each line in the file should contain a single PEG ID.

=head2 Command-Line Options

=over 4

=item -d OutputDirectory

=item -a anno Use the annotator's Seed

=item -ppseed Use the PubSEED

=item -nocollapse   [ do not collapse the tree -- show all sequences ]

=head2 Output Format

=cut

use SeedEnv;
use Getopt::Long;

my $usage = "usage: svr_get_ali_and_tree -d OutputDirectory [-anno] [-ppseed] < PEGs";

my $nocollapse = '';
my $dir;
my $anno;
my $ppseed = 1;
my $rc  = GetOptions('d=s' => \$dir,
		     'anno' => \$anno,
		     'nocollapse' => \$nocollapse,
		     'ppseed' => \$ppseed);

if ((! $rc) || (! $dir)) { print STDERR $usage; exit }
if ($nocollapse) { $nocollapse = "-p none" }

my @ids = map { ($_ =~ /(\S+)/) ? [split(/,/,$1)] : () } <STDIN>;
&SeedUtils::verify_dir($dir);

foreach my $tuple (@ids) {
    my $peg1 = substr($tuple->[0],4);
    my $subdir = "$dir/$peg1";
    &SeedUtils::verify_dir($subdir);
    open(TMP,"| svr_fasta -protein -fasta > $subdir/query") || die "could not open query";
    foreach my $peg (@$tuple)
    {
	print TMP "$peg\n";
    }
    close(TMP);
    run("svr_psiblast_search -inc -fast -l -a 8 -u 50 -nq 200 -r $subdir/report < $subdir/query > $subdir/hits");
    run("svr_align_seqs -l -mafft < $subdir/hits > $subdir/trim");
    run("grep included $subdir/report | cut -f1 | svr_fasta -protein -fasta > $subdir/full.seqs");
    run("svr_align_seqs -l -mafft -z < $subdir/full.seqs > $subdir/full.ali");
    run("svr_trim_ali -l -c -cd -html $subdir/full.trim.html < $subdir/full.ali > $subdir/full.trim");
    run("grep '>' $subdir/trim | sed 's/>//' | sed 's/[()]//g' | sed 's/\s/\t/' > $subdir/trim.coords");
    run("svr_tree -l < $subdir/trim > $subdir/tree");
    if ($ppseed)
    {
	run("svr_tree_to_html $nocollapse -ppseed -nc 20 -c role -d $subdir/trim.coords < $subdir/tree > $subdir/tree.html");
    }
    elsif ($anno)
    {
	run("svr_tree_to_html $nocollapse -anno -nc 20 -c role -d $subdir/trim.coords < $subdir/tree > $subdir/tree.html");
    }
    else
    {
	run("svr_tree_to_html $nocollapse -nc 20 -c role -d $subdir/trim.coords < $subdir/tree > $subdir/tree.html");
    }
}

sub run {
    my ($cmd) = @_;
    system($cmd) == 0 or die("FAILED: $cmd");
}
