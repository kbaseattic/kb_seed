use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

genome_to_intergenic_regions

=head1 SYNOPSIS

genome_to_intergenic_regions -g GenomeID [-pad=num] > output

=head1 DESCRIPTION

genome_to_intergenic_regions is used to get the intergenic regions in a specified
genome (specified using the -g argument).  The command allows you
to take "padding DNA" from the bounding fids using a -pad argument.

Example:

    genome_to_intergenic_regions -g 'kb|g.0' -pad=10 > output

This is a pipe command in the sense that it produces a tab-separated list of lines.
The columns will correspond to [Fid1,Fid2,padded-intergenic-region].
Overlapping Fids produce no lines in the output.

=head1 COMMAND-LINE OPTIONS

Usage: genome_to_intergenic_regions -g GenomeID [-pad=num] > output

    -g GenomeID

        This is required and specifies a KBase genome

    -pad PadSize [defaults to 0]

        If the intergenic regions are to be padded with characters from the Fids,
        this specifies the size.

=head1 OUTPUT FORMAT

The standard output is a tab-delimited file. It consists of 3 columns:
[Fid1,Fid2,LocationOfIntergenicRegion]

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

our $usage = "usage: genome_to_intergenic_regions > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $genome;
my $pad = 0;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('g=s' => \$genome,
				                       'pad=i' => \$pad);
if (! $kbO) { print STDERR $usage; exit }

if ((! defined($genome)) || ($genome !~ /^kb\|g.\d+$/))
{
    print STDERR "Use -g Genome to specify a valid KBase genome\n"; 
    exit;
}

open(LOCS,"echo 'kb|g.0' | genomes_to_fids peg CDS rna | get_relationship_IsLocatedIn -to id -rel begin,dir,len | cut -f2,3,4,5,6 | sort -k 5 -k 2n |")
    || die "could not access fids from $genome";
my @tab = map { $_->[1] = ($_->[2] eq "+") ? $_->[1] : ($_->[1] + $_->[3] - 1); $_ }
          map { chop; [split(/\t/,$_)] } <LOCS>;
close(LOCS);

my @regions;
my %fids;

my $i;
for ($i=0; ($i < $#tab); $i++)
{
    my($fid1,$b1,$strand1,$len1,$contig1) = @{$tab[$i]};
    my($fid2,$b2,$strand2,$len2,$contig2) = @{$tab[$i+1]};
    if ($contig1 eq $contig2)
    {
	my $right1 = ($strand1 eq "+") ? ($b1 + ($len1-1)) : $b1;
	my $left2  = ($strand2 eq "+") ? $b2 : ($b2 - ($len2-1));
	if ($left2 > ($right1+1))
	{
	    my $b  = $right1 + 1 - $pad;
	    my $ln = ($left2+$pad) - $b;
	    my $loc = "$contig1\_$b\+$ln";
	    push(@regions,[[$contig1,$b,'+',$ln]]);
	    $fids{$loc} = "$fid1-$fid2";
	}
    }
}

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;
my $csO = Bio::KBase::CDMI::CDMIClient->new_for_script();

my $dna_seqs = $csO->locations_to_dna_sequences(\@regions);
foreach my $tuple (@$dna_seqs)
{
    my $req = $tuple->[0]->[0];
    my $dna = $tuple->[1];
    my($contig1,$b,undef,$ln) = @$req;
    my $loc = "$contig1\_$b\+$ln";
    if ($pad > 0)
    {
	my $padL = substr($dna,0,$pad);
	substr($dna,0,$pad) = uc $padL;
	my $padR = substr($dna,-$pad);
	substr($dna,-$pad) = uc $padR;
    }
    my $hdr = $fids{$loc};
    print ">$hdr location=$loc\n$dna\n";
}

__DATA__
