use strict;
use Data::Dumper;
use Carp;
use Corresponds;
use JSON::XS;

#
# This is a SAS Component
#

=head1 NAME

corresponds

=head1 SYNOPSIS

corresponds [-a cutoff] genome1 genome2 > output

=head1 DESCRIPTION

This command produces a correspondence between genes in genome=1 and genome-2.
It is often the case that you wish to know which gene in genome X "corresponds" to a specific
gene in genome Y.  Frequently the term "ortholog" is used, although not always accurately.
Here we offer a basic tool that produces a reasonable estimate for the set of genes that
form a 1-1 correspondence. 

Example:

    corresponds [-a cutoff] genome1 genome2 > output

=head1 COMMAND-LINE OPTIONS

corresponds [-a cutoff] genome1 genome2 > output

    -a Cutoff
        This requests an abbreviated format in which only two columns are written:
        the projection score and the fid in the target genome.  If this is not
        used 10 column are produced.  The Cutoff specifies a minimum projection score.

    genome1
    genome2

        Input genomes. These are either filenames which are expected to contain genome
        typed-objects (as created by annotate_genome, for instances) or they are
        KBase genome IDs.

=head1 OUTPUT FORMAT

The standard output is a tab-delimited file. It consists of the input
file with extra columns added.  If the abbreviated format is requested,
two columns get added (sc and the fid projected to).  If the abbreviated
format is not requested, ten columns will be added

=over 4

=item 1  - percent-identity: the average percent identity over the
         range of the match

=item 2  - the number of genes in the five adjacent genes to the left and
         the five adjacent genes to the right (i.e., the number of genes in 
         the "chromosomal context") that correspond to genes in genome-2 which
         occur within the chromosomal context of id2

=item 3   - b1, the start of the match in the protein encoded by the gene in genome -1

=item 4   - e1, the end of the match in the protein encoded by the gene in genome-1

=item 5   - ln1, the length of the protein encoded by the gene in genome-1

=item 6   - b2

=item 7   - e2

=item 8   - ln2

=item 9   - a score between 0 and 1 that reflects the reliability of the
          projection

=item 10  - id2, the corresponding gene in genome-2

Input lines that cannot be extended are written to stderr.

=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use SeedUtils;

our $usage = "usage: corresponds [-a cutoff] g1 g2 > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $min_sc = 0;

my $csO = Bio::KBase::CDMI::CDMIClient->new_for_script('a=f'   => \$min_sc);
						       
if (! $csO|| @ARGV != 2) { print STDERR $usage; exit }

my $g1 = shift;
my $g2 = shift;

my $g1_obj;
my $g2_obj;

my($seqs1, $locs1, $seqs2, $locs2);

my $json = JSON::XS->new;

if (open(G, "<", $g1))
{
    local $/;
    undef $/;
    my $input_genome_txt = <G>;
    $g1_obj = $json->decode($input_genome_txt);
    close(G);
    ($seqs1, $locs1) = load_from_object($g1_obj);
}
else
{
    ($seqs1, $locs1) = load_from_cs($g1);
}

if (open(G, "<", $g2))
{
    local $/;
    undef $/;
    my $input_genome_txt = <G>;
    $g2_obj = $json->decode($input_genome_txt);
    ($seqs2, $locs2) = load_from_object($g2_obj);
}
else
{
    ($seqs2, $locs2) = load_from_cs($g2);
}

my $h = $csO->corresponds_from_sequences($seqs1, $locs1, $seqs2, $locs2);

for my $fid (map { $_->[0] } @$seqs1)
{
    next unless exists $h->{$fid};
    my $v = $h->{$fid};
    if (! $min_sc) 
    {
	print join("\t",($fid,
			 $v->{iden},
			 $v->{ncontext},
			 $v->{b1},
			 $v->{e1},
			 $v->{ln1},
			 $v->{b2},
			 $v->{e2},
			 $v->{ln2},
			 $v->{score},
			 $v->{to}
			)),"\n";
    }
    elsif ($v->{score} >= $min_sc)
    {
	print join("\t", $fid, $v->{score}, $v->{to}),"\n";
    }
}

sub load_from_object
{
    my($obj) = @_;

    my $seqs = [];
    my $locs = [];

    for my $f (@{$obj->{features}})
    {
	if (exists($f->{protein_translation}))
	{
	    push(@$seqs, [$f->{id}, $f->{protein_translation}]);
	    push(@$locs, [$f->{id}, $f->{location}]);
	}
    }
    return($seqs, $locs);
}

sub load_from_cs
{
    my($g) = @_;

    my $seqs = [];
    my $locs = [];

    my $fids = $csO->genomes_to_fids([$g], ['peg', 'CDS']);
    $fids = $fids->{$g};

    my $fid_locs = $csO->fids_to_locations($fids);
    my $trans = $csO->fids_to_protein_sequences($fids);

    for my $fid (sort { my $aloc = $fid_locs->{$a}->[0];
			my $bloc = $fid_locs->{$b}->[0];
			$aloc->[0] cmp $bloc->[0] or $aloc->[1] <=> $bloc->[1]
			}
		 keys %$trans)
    {
	push(@$seqs, [$fid, $trans->{$fid}]);
	push(@$locs, [$fid, $fid_locs->{$fid}]);
    }

    return($seqs, $locs);
}

__DATA__
