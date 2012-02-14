########################################################################
use strict;
use Data::Dumper;
use Carp;


=head1 svr_scanN

Scan genomes for a designated pattern

This tool is based on scan_for_matches, which can be run without this wrapper.
Scan_for_matches has numerous options that have not been worked into
this simplified version.

------

Example:

    svr_scanN -g 83333.1 'p1=10...15 4...6 ~p1'

would scan the E.coli genome for instances of hirpin loops (in this
case, a stem of 10 to 15 characters, and a loop of 4 to 6 characters).
The output sould be a 3-column table.  The first column would contain
the string in a contig that matched the pattern, the second the
location (genome:contig_begin_end), and the third the PEG id.

------

Normally, the genome is given on the command line, and the contigs
of that genome are scanned.  If the -g option is not used, genome 
IDs are taken from standard input.

The standard input should be a tab-separated table (i.e., each line is
a tab-separated set of fields).  Normally, the last field in each line
would contain the genome IDs.  If some other column contains the
genome IDs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing genome IDs is not the last.

    =item -s [search just the single strand; default is to search both strands]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with three extra columns added (the matched string, the location,
and the matched genome).  Note that when the pattern is made up of
multiple components, you get embedded blanks within the field giving
the matched string.

=cut

use SeedUtils;
use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_scanN [-c column] [-s] [-g genome] Pattern ";

my $column;
my $single_strand;
my $genome;
my $rc  = GetOptions('c=i' => \$column,
		     'g=s' => \$genome,
		     's'   => \$single_strand);
if (! $rc) { print STDERR $usage; exit }
(@ARGV > 0) || die "you need to specifiy a pattern";

my @lines;
if ($genome)
{
    @lines = ([$genome]);
}
else
{
    @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
}
(@lines > 0) || exit;

if (! $column)  { $column = @{$lines[0]} }
my @genomes = map { $_->[$column-1] } @lines;
my $matches = &scan_for_matches($sapO,$ARGV[0],\@genomes,$single_strand);
foreach $_ (@lines)
{
    my $hits = $matches->{$_->[$column-1]};
    foreach my $hit (@$hits)
    {
	print join("\t",@$_,@$hit),"\n";
    }
}

sub scan_for_matches {
    my($sapO,$pat,$all_genomes,$single_strand) = @_;

    my $hitsF    = "tmp.scanP.hits.$$";
    my $patternF = "tmp.scanP.pattern.$$";
    open(TMP,">",$patternF) || die "could not open $patternF";
    print TMP $pat,"\n";
    close(TMP);
    my $complement = $single_strand ? '' : '-c';

    open(HITS,"| scan_for_matches $complement $patternF > $hitsF") || die "could not run scan_for_matches";

    my @genomes = @$all_genomes;
    my $hitsH;

    while (@genomes > 0)
    {
	$_ = (@genomes >= 100) ? 100 : @genomes;
	my @next_set = splice(@genomes,0,$_);
	my $genomeH = $sapO->genome_contigs( -ids => \@next_set );
	my @contigs = map { @{$genomeH->{$_}} } keys(%$genomeH);
	my $seqH    = $sapO->contig_sequences( -ids => \@contigs );
	foreach my $genome (@next_set)
	{
	    my $contigs = $genomeH->{$genome};
	    foreach my $contig (@$contigs)
	    {
		my $seq = $seqH->{$contig};
		if ($seq)
		{
		    print HITS ">$contig\n$seq\n";
		}
	    }
	}
    }
    close(HITS);
    open(HITS,"<",$hitsF) || die "could not open $hitsF";
    while (defined($_ = <HITS>) && ($_ =~ /^>(\d+\.\d+):(\S+)\:\[(\d+),(\d+)\]/))
    {
	my $genome = $1;
	my $contig = $2;
	my $beg    = $3;
	my $end    = $4;
	my $str    = <HITS>; chomp $str;
	push(@{$hitsH->{$genome}},[join("\t",($contig,$beg,$end)),$str]);
    }
    unlink($hitsF,$patternF);
    return $hitsH;
}
