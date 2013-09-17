########################################################################
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_with_close_blast_hits -d DB [-m MaxDist ] [-p MaxPsc] < PEGs > +[PegLocation,HitLocation] 2> no.hits

Determine which of the input PEGs have blastX hits to a given DB "close".

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain a PEG, but you can specify what column the
PEG IDs come from.

If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output and standard error.  Genes in which there is a close
blastX hit against a given protein DB are written to STDOUT (with three appended columns:
the Gene location, the hit location, and the other gene that had the best blast score).  
Genes that fail to hit anything are written to STDERR.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -d BlastDB

This is the name of a protein blast DB.  It is assumed that formatdb has already
been run to properly format it.

=item -m MaxDist

This is the distance used to snip out a section of DNA centered on the PEG.
The snipped DNA will be of length ((2 * MaxDist) + length of PEG). Default is 2000.

=item -p MaxPsc

This is the maximum Psc used to determine whether or not there was a significant similarity

=back

=head2 Output Format

PEGs that can be clustered are written to STDOUT.  Three columns are
added at the end of each line in STDOUT -- the location of the PEG,
the location of a significant blast hit, and the other PEG that generated the hit.  
The locations will be in the form GID:Contig_Start[+-]Length.  For example, 

    100226.1:NC_003888_3766170+612

would designate a gene in genome 10226.1 on contig NC_003888 that starts
at position 3766170 (positions are numbered from 1) that is on the
positive strand and has a length of 612.

When a PEG has no hit, the original line (with no added columns)
is written to STDERR.

=cut

use SeedEnv;
use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_with_close_blast_hits -d DB [-m MaxDist ] [-p MaxPsc] [-c column] < PEGs > +[PegLocation,HitLocation] 2> no.hits";

my $column;
my $blastdb;
my $max_psc = 1.0e-5;
my $maxD = 2000;

my $rc  = GetOptions('c=i' => \$column,
		     'd=s' => \$blastdb,
		     'p=f' => \$max_psc,
		     'm=i' => \$maxD);

if (! $rc) { print STDERR $usage; exit }
($blastdb) || die "you need to give the formatted blastdb";

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
if (! $column)  { $column = @{$lines[0]} }
my @pegs = map { $_->[$column-1] } @lines;
my $pegH = $sapO->fid_locations( -ids => \@pegs, -boundaries => 1 );

my $wus = {};
foreach my $line (@lines)
{
    my($peg,$peg_loc);
    if (($peg = $line->[$column-1]) && ($peg_loc = $pegH->{$peg}))
    {
	if ($peg_loc =~ /^(\d+\.\d+):(\S+)_(\d+)([+-])(\d+)$/) 
	{
	    my($genome,$contig,$beg,$strand,$ln) = ($1,$2,$3,$4,$5);
	    my($min,$max) = ($strand eq "+") ? ($3,$3+$5-1) : ($3+1-$5,$3);
	    $min -= $maxD;
	    $max += $maxD;
	    my $ln = $max +1 - $min;
	    $wus->{$peg} = "$genome:$contig" . "_" . "$min" . "+" . "$ln";
	}
    }
}

my $locH = $sapO->locs_to_dna( -locations => $wus, -fasta => 1 );
open(TMP,">","tmp.$$.fasta") || die "could not open tmp.$$.fasta";
foreach my $peg (keys(%$locH))
{
    my $seq = $locH->{$peg};
    print TMP $seq;
}
close(TMP);

my %blast_hits;
open(BLAST,"blastall -d $blastdb -i tmp.$$.fasta -p blastx -e $max_psc -m 8 -FF |")
    || die "could not run blastall -d $blastdb -i tmp.$$.fasta -p blastx -e $max_psc -m 8 -FF";
while (defined($_ = <BLAST>))
{
    chomp;
    my @flds = split(/\s+/,$_);
    my($id1,$id2,$iden,undef,undef,undef,$b1,$e1,$b2,$e2,$psc,$bsc) = @flds;
    if (! $blast_hits{$id1})
    {
	my $wu = $wus->{$id1};
	if ($wu =~ /^(\d+\.\d+):(\S+)_(\d+)\+(\d+)/)
	{
	    my($genome,$contig,$beg,$ln) = ($1,$2,$3,$4);
	    if (($b1 < ($maxD-10)) || ($e1 < ($maxD-10)) || ($b1 > (($ln+10) - $maxD)) || ($e1 > (($ln+10) - $maxD)))
	    {
		my $start = $b1 + ($beg - 1);
		my $end   = $e1 + ($beg - 1);
		my $ln1 = abs($end-$start)+1;
		my $region;
		if ($b1 < $e1)
		{
		    $region = "$genome:$contig\_$start\+$ln1";
		}
		else
		{
		    $region = "$genome:$contig\_$start\-$ln1";
		}
		$blast_hits{$id1} = [$id2,$region];
	    }
	}
    }
}
close(BLAST);
unlink("tmp.$$.fasta");

foreach my $line (@lines)
{
    my $peg = $line->[$column-1];
    my $peg_loc = $pegH->{$peg};
    my $hit_loc = $blast_hits{$peg}->[1];
    my $id2     = $blast_hits{$peg}->[0];
    if ($hit_loc)
    {
	print join("\t",(@$line,$peg_loc,$hit_loc,$id2)),"\n";
    }
    else
    {
	print STDERR join("\t",@$line),"\n";
    }
}
