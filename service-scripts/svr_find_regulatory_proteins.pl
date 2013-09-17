use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_find_regulatory_genes 

Find potential regulatory proteins

------

Example:

    svr_find_regulatory_genes fasta.of.protein.sequences > ids.and.functions

------

=cut

use SeedUtils;

my $in = shift @ARGV;
($in && (-s $in))
    || die "You need to specify an input file of protein sequences in fasta format (as a command line argument)";

my @patterns = map { chomp; $_ } <DATA>;
open(FIND,"svr_assign_using_figfams < $in 2> /dev/null |") || die "could not open $in";
while (defined($_ = <FIND>))
{
    chomp;
    my($hits,$peg,$func) = split(/\t/,$_);
    if ($hits >= 5)
    {
	my $i;
	for ($i=0; ($i < @patterns) && ($func !~ /$patterns[$i]/i); $i++) {}
	if ($i < @patterns)
	{
	    print "$peg\t$func\n";
	}
    }
}

__DATA__
repressor
activator
Transcription factor
regulator
transcriptional reg
transcription reg
regulat.*protein
regulator of
histidine kinase
signal.*transduct
response regulator
two[- ]components.*system
cAMP signaling
Adenylate cyclases, cAMP-binding domains
adenylate cyclase
diguanylate cyclase
GGDEF domain
PAS/PAC sensor
EAL domain
Methyl-accepting
MCP-domain
protein kinase
protein phosphatase
Phytochrome
sigma.*factor
stringent response
ppgpp
guanosine-3\',5\'\-bis
