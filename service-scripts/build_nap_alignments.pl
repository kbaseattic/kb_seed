#
# 
#
# This is a SAS Component
#
# This program can be used to construct the set of alignments used to suggest
# pseudo-genes when comparing a reference genome to a set of very closely related
# genomes.  You must generate the comparison between the reference genome and the
# set of closely related genomes using something like
#
#    CSA_create_SNP_data ReferenceGenomeD OtherGenomes OutputDir
#
# where the reference genome is a SEED directory, OtherGenomes is a file
# containing lines that contain full path locations of contig files.
# The paths must end in 
#
#      xxxx.yyy/contigs
#
# This program should take the OutputDir/AnnoD and a constructed genomes directory
# (say, OutputDir/Final/PG/Genomes) 
##
# It builds directories containing files of alignments for possible
# pseudo-genes.
#

use strict;
use FS_RAST;
use Data::Dumper;

my($annoD,$genomesD);
my $usage = "usage: build_nap_alignments AnnoD GenomeD";
(
 ($annoD    = shift @ARGV) &&
 ($genomesD = shift @ARGV) 
)
    || die $usage;

opendir(ANNOD,$annoD) || die "could not open $annoD";
my @genomes = grep { $_ =~ /^\d+\.\d+$/ } readdir(ANNOD);
closedir(ANNOD);

foreach my $g (@genomes)
{
    (-d "$genomesD/$g") || die "missing $genomesD/$g";
    my $aliD = "$genomesD/$g/Features/pseudo/Alignments";
    &SeedUtils::verify_dir($aliD);
    &SeedUtils::verify_dir("$genomesD/$g/Features/pseudo/Alignments");
    my %to_contig = map { ($_ =~ /^(\S+)\t(\S+)/) ? ($1 => $2) : () } `cat $annoD/$g/contigs.index`;
    foreach $_ (`cat $annoD/$g/features`)
    {
	chop;
	my(undef,$contig,$begin,$end,undef,$dna,$err,$peg,undef,undef,$prot) = split(/\t/,$_);
	if ($err =~ /(possible frameshift)|(embedded stop codon)/)
	{
	    my $actual_contig = $to_contig{$contig};
	    my $ali = &FS_RAST::make_ali($dna,$prot,".");
	    if ($peg =~ /(peg\.\d+)$/)
	    {
		my $pegN = $1;
		open(ALI,">$aliD/$pegN") || die "could not open $aliD/$pegN";
		print ALI "$err\n$actual_contig\t$begin\t$end\n\n$ali\n\n";
		close(ALI);
		&record_pseudo_gene($genomesD,$g,$pegN,$actual_contig,$begin,$end,$dna);
	    }
	}
    }
}

sub record_pseudo_gene {
    my($genomesD,$g,$pegN,$actual_contig,$begin,$end,$dna) = @_;

    open(TBL,">>$genomesD/$g/Features/pseudo/tbl")  || die "could not open $genomesD/$g/Features/pseudo/tbl";
    my $pg = $pegN;
    $pg =~ s/^peg//;
    $pg = 'fig|' . $g . '.pseudo' . $pg;
    my $loc = join("_",($actual_contig,$begin,$end));
    print TBL "$pg\t$loc\t\n";
    close(TBL);
    open(FASTA,">>$genomesD/$g/Features/pseudo/fasta")  || die "could not open $genomesD/$g/Features/pseudo/fasta";
    print FASTA ">$pg\n$dna\n";
    close(FASTA);
    open(ASS,">>$genomesD/$g/assigned_functions") || die "could not open $genomesD/$g/assigned_functions";
    print ASS "$pg\tno assigned function\n";
    close(ASS);
}
