use strict;
use Data::Dumper;
use Carp;
use gjoseqlib;

#
# This is a SAS Component
#


use SeedEnv;
my $sapO = SAPserver->new();

=head1 svr_blast

Run blast locally

------
Example: svr_blast -p pegs 83333.1    [ blast PEGs identified in file against genome 83333.1 ]
         svr_blast -d pegs 83333.1    [ use blastn, not blastp ]
         svr_blast -s pegs 83333.1    [ blast PEGs in fasta file  against genome 83333.1 ]
         svr_blast -p pegs            [ blast PEGs identified in file against themselves ]
         svr_blast  83333.1           [ sequences of PEGs from the last column of STDIN input against genome]
         svr_blast                    [ sequences of PEGs from the last column of STDIN input against themselves ]
         svr_blast -c 1               [ sequences of PEGs from the first column of STDIN input against themselves ]
         svr_blast -c 1 -parms='-m8'  [ sequences of PEGs from the first column of STDIN input against themselves - -m8 format ]
      
    The output is exactly the unfiltered blast output

------

This svr command may be thought of as implementing two types of requests:

    1.  "Blast a set of PEGs against the genes (or protein products) in a set of genomes"
    2.  "Blast a set of PEGs against itself".

When we say "set of pegs"  or "pegs in genome" we mean either the DNA or the protein sequences
corresponding to the pegs.  Which is determined by the -d flag or its absence (think of 
protein by default, -d for DNA is that is what you want).

A set of PEGs can be read from a file.  If the file contains just IDs, use "-p IDfile".
If the file contains actual sequence in FASTA format use "-s fasta.file".

If you are blasting PEGs against genomes, the genomes are given as one or more
arguments of the form xxx.yyy (where xxx.yyy is the genome ID; for example, E.coli is 83333.1).

You can read the PEG ids from standard input, much like most of the
other SVR scripts (this is done only if -s File and -p File were
omitted).  IDs are from the last column in the STDIN file, or from
another column specified using the -c argument.  The standard input
should be a tab-separated table (i.e., each line is a tab-separated
set of fields).  Normally, the last field in each line would contain
the PEG for which aliases are being requested.  If some other column
contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

NOTE: the PEG sequences are formed as the union of the sequences derived
from

    1. the IDs from STDIN (only if -p and -s are omitted)
    2. the ids from the -p file
    3. the sequences from the -s file

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

The parameters of the BLAST run are the defaults, unless you use
    
    -parms='parameters passed to blast'

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=back

=head2 Output Format

The output is just the BLAST output.

=cut

my $usage = "usage: svr_blast [-c column] [-s fasta.file] [-p IDfile] [-d] [G1 G2...]";

my $column;
my $pFile;
my $sFile;
my $d = 0;
my $parms = "";

while ($ARGV[0] && ($ARGV[0] =~ /^-/))
{
    $_ = shift @ARGV;
    if    ($_ =~ s/^-c=*//)     { $column       = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-d//)       { $d            = 1                   }
    elsif ($_ =~ s/^-s=*//)     { $sFile        = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-parms=*//) { $parms        = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-p=*//)     { $pFile        = ($_ || shift @ARGV) }
    else                        { die "Bad Flag: $_" }
}
my @genomes = @ARGV;

my @fid_ids = ();
if ((! $sFile) && (! $pFile))
{
    ScriptThing::AdjustStdin();
      my @lines = map      { chomp; [split(/\t/,$_)] } <STDIN>;
      if (! $column)       { $column = @{$lines[0]} }
      @fid_ids = map { $_->[$column-1] } @lines;
}

my @fids_seq = ();
my @fids_id  = ();

if ($sFile)
{
    @fids_seq = &gjoseqlib::read_fasta($sFile);
}

my %seen = map { ($_->[0] => 1 ) } @fids_seq;   ### [ID,Comment,Sequence]

if ($pFile)
{
    open(PF,"<",$pFile) || die "could not open $pFile";
    while (defined($_ = <PF>))
    {
	if ($_ =~ /^(fig\|\d+\.\d+\.peg\.\d+)/)
	{
	    push(@fid_ids,$1);
	}
    }
    close(PF);
}

my %ids_to_get = map { $_ => 1 } grep { ! $seen{$_} } @fid_ids;
my @extra_ids = keys(%ids_to_get);
push(@fids_seq,&tuples(\@extra_ids,$d));

my @genome_pegs = ();
if (@genomes > 0)
{
    my $genomeH = $sapO->all_features( -ids => \@genomes, -type => ['peg'] );
    foreach my $genome (keys(%$genomeH))
    {
	my $pegs = $genomeH->{$genome};
	push(@genome_pegs,&tuples($pegs,$d));
    }
}

my $qF  = "query.$$.fasta";
my $dbF = "db.$$.fasta";

&gjoseqlib::print_alignment_as_fasta($qF,\@fids_seq);
if (@genomes > 0)
{
    &gjoseqlib::print_alignment_as_fasta($dbF,\@genome_pegs);
}
else
{
    &gjoseqlib::print_alignment_as_fasta($dbF,\@fids_seq);
}

my $pflag = $d ? 'F' : 'T';
system "formatdb -i $dbF -p $pflag";
my $cmd = $d ? 'blastn' : 'blastp';
open(BLAST,"blastall $parms -p $cmd -i $qF -d $dbF |")
    || die "could not make blast run, sorry";
while (defined($_ = <BLAST>))
{
    print $_;
}
close(BLAST);
unlink($dbF,$qF);

sub tuples {
    my($ids,$dna) = @_;

    my $idsH = $sapO->ids_to_sequences( -ids => $ids,
					-protein => ($dna ? 0 : 1),
					-fasta => 0 );

    return map { [$_,'',$idsH->{$_}] } keys(%$idsH);
}
