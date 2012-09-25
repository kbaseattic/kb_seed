use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 build_tree

Example:

    build_tree [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call build_tree. It is documented as follows:



=over 4

=item Parameter and return types

=begin html

<pre>
$seq_set is a seq_set
$build_tree_parms is a build_tree_parms
$return is a newick_tree
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
build_tree_parms is a reference to a hash where the following keys are defined:
	bootstrap has a value which is a string
	model has a value which is a string
	nclasses has a value which is a string
	nproc has a value which is a string
	rate has a value which is a string
	search has a value which is a string
	tool has a value which is a string
	tool_params has a value which is a string
newick_tree is a string

</pre>

=end html

=begin text

$seq_set is a seq_set
$build_tree_parms is a build_tree_parms
$return is a newick_tree
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
build_tree_parms is a reference to a hash where the following keys are defined:
	bootstrap has a value which is a string
	model has a value which is a string
	nclasses has a value which is a string
	nproc has a value which is a string
	rate has a value which is a string
	search has a value which is a string
	tool has a value which is a string
	tool_params has a value which is a string
newick_tree is a string


=end text

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing the identifier is not the last column.

=item -i InputFile    [ use InputFile, rather than stdin ]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with extra columns added.

Input lines that cannot be extended are written to stderr.

=cut

use SeedUtils;
use gjoseqlib;

my $usage = "usage: build_tree [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my ($help, $local, $url, $nc, $eval, $logfile, $intree, $model, $params, $gamma, $spr, $treefile, $bootstrap, $noml, $nome, $mllen, $nproc);
my ($tool, $fasttree, $raxml, $phyml);

Getopt::Long::Configure("pass_through");

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script("tool=s"   => \$tool,
                                                       "b=i"      => \$bootstrap,
                                                       "c=i"      => \$nc,
                                                       "m=s"      => \$model,
                                                       "np=i"     => \$nproc,
                                                       "r|gamma"  => \$gamma,
                                                       "s|spr"    => \$spr,
                                                       "phyml"    => \$phyml,
                                                       "raxml"    => \$raxml,
                                                       "fasttree" => \$fasttree);
                                                       
if (! $kbO) { print STDERR $usage; exit }

$params = join(' ', @ARGV);    # remaining args

if    ($phyml)  { $tool   = "phyml"    }
elsif ($raxml)  { $tool   = "raxml"    }
else            { $tool ||= "fasttree" }

my $opts;

$opts->{tool}         = $tool;
$opts->{bootstrap}    = $bootstrap;
$opts->{nclasses}   ||= $nc || 4;
$opts->{optimize}     = $eval   ? 'eval'  : 'all';
$opts->{rate}         = $gamma  ? 'Gamma' : 'Uniform';
$opts->{search}       = $spr    ? 'SPR'   : 'NNI';
$opts->{model}        = $model     if $model;
$opts->{params}       = $params    if $params;
$opts->{logfile}      = $logfile   if $logfile;
$opts->{treefile}     = $treefile  if $treefile;
$opts->{noml}         = 1          if $noml;
$opts->{nome}         = 1          if $nome;
$opts->{mllen}        = 1          if $mllen;
$opts->{nproc}        = $nproc     if $nproc;  

my $aln = gjoseqlib::read_fasta();
my $tree_str = $kbO->build_tree($aln, $opts);

print $tree_str;

