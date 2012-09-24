use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 align_sequences

Example:

    align_sequences [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call align_sequences. It is documented as follows:



=over 4

=item Parameter and return types

=begin html

<pre>
$seq_set is a seq_set
$align_seq_parms is an align_seq_parms
$return is a seq_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
align_seq_parms is a reference to a hash where the following keys are defined:
	muscle_parms has a value which is a muscle_parms_t
	mafft_parms has a value which is a mafft_parms_t
	tool has a value which is a string
	align_ends_with_clustal has a value which is an int
muscle_parms_t is a reference to a hash where the following keys are defined:
	anchors has a value which is an int
	brenner has a value which is an int
	cluster has a value which is an int
	dimer has a value which is an int
	diags has a value which is an int
	diags1 has a value which is an int
	diags2 has a value which is an int
	le has a value which is an int
	noanchors has a value which is an int
	sp has a value which is an int
	spn has a value which is an int
	stable has a value which is an int
	sv has a value which is an int
	anchorspacing has a value which is a string
	center has a value which is a string
	cluster1 has a value which is a string
	cluster2 has a value which is a string
	diagbreak has a value which is a string
	diaglength has a value which is a string
	diagmargin has a value which is a string
	distance1 has a value which is a string
	distance2 has a value which is a string
	gapopen has a value which is a string
	log has a value which is a string
	loga has a value which is a string
	matrix has a value which is a string
	maxhours has a value which is a string
	maxiters has a value which is a string
	maxmb has a value which is a string
	maxtrees has a value which is a string
	minbestcolscore has a value which is a string
	minsmoothscore has a value which is a string
	objscore has a value which is a string
	refinewindow has a value which is a string
	root1 has a value which is a string
	root2 has a value which is a string
	scorefile has a value which is a string
	seqtype has a value which is a string
	smoothscorecell has a value which is a string
	smoothwindow has a value which is a string
	spscore has a value which is a string
	SUEFF has a value which is a string
	usetree has a value which is a string
	weight1 has a value which is a string
	weight2 has a value which is a string
mafft_parms_t is a reference to a hash where the following keys are defined:
	sixmerpair has a value which is an int
	amino has a value which is an int
	anysymbol has a value which is an int
	auto has a value which is an int
	clustalout has a value which is an int
	dpparttree has a value which is an int
	fastapair has a value which is an int
	fastaparttree has a value which is an int
	fft has a value which is an int
	fmodel has a value which is an int
	genafpair has a value which is an int
	globalpair has a value which is an int
	inputorder has a value which is an int
	localpair has a value which is an int
	memsave has a value which is an int
	nofft has a value which is an int
	noscore has a value which is an int
	parttree has a value which is an int
	reorder has a value which is an int
	treeout has a value which is an int
	alg has a value which is a string
	aamatrix has a value which is a string
	bl has a value which is a string
	ep has a value which is a string
	groupsize has a value which is a string
	jtt has a value which is a string
	lap has a value which is a string
	lep has a value which is a string
	lepx has a value which is a string
	LOP has a value which is a string
	LEXP has a value which is a string
	maxiterate has a value which is a string
	op has a value which is a string
	partsize has a value which is a string
	retree has a value which is a string
	thread has a value which is a string
	tm has a value which is a string
	weighti has a value which is a string

</pre>

=end html

=begin text

$seq_set is a seq_set
$align_seq_parms is an align_seq_parms
$return is a seq_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
align_seq_parms is a reference to a hash where the following keys are defined:
	muscle_parms has a value which is a muscle_parms_t
	mafft_parms has a value which is a mafft_parms_t
	tool has a value which is a string
	align_ends_with_clustal has a value which is an int
muscle_parms_t is a reference to a hash where the following keys are defined:
	anchors has a value which is an int
	brenner has a value which is an int
	cluster has a value which is an int
	dimer has a value which is an int
	diags has a value which is an int
	diags1 has a value which is an int
	diags2 has a value which is an int
	le has a value which is an int
	noanchors has a value which is an int
	sp has a value which is an int
	spn has a value which is an int
	stable has a value which is an int
	sv has a value which is an int
	anchorspacing has a value which is a string
	center has a value which is a string
	cluster1 has a value which is a string
	cluster2 has a value which is a string
	diagbreak has a value which is a string
	diaglength has a value which is a string
	diagmargin has a value which is a string
	distance1 has a value which is a string
	distance2 has a value which is a string
	gapopen has a value which is a string
	log has a value which is a string
	loga has a value which is a string
	matrix has a value which is a string
	maxhours has a value which is a string
	maxiters has a value which is a string
	maxmb has a value which is a string
	maxtrees has a value which is a string
	minbestcolscore has a value which is a string
	minsmoothscore has a value which is a string
	objscore has a value which is a string
	refinewindow has a value which is a string
	root1 has a value which is a string
	root2 has a value which is a string
	scorefile has a value which is a string
	seqtype has a value which is a string
	smoothscorecell has a value which is a string
	smoothwindow has a value which is a string
	spscore has a value which is a string
	SUEFF has a value which is a string
	usetree has a value which is a string
	weight1 has a value which is a string
	weight2 has a value which is a string
mafft_parms_t is a reference to a hash where the following keys are defined:
	sixmerpair has a value which is an int
	amino has a value which is an int
	anysymbol has a value which is an int
	auto has a value which is an int
	clustalout has a value which is an int
	dpparttree has a value which is an int
	fastapair has a value which is an int
	fastaparttree has a value which is an int
	fft has a value which is an int
	fmodel has a value which is an int
	genafpair has a value which is an int
	globalpair has a value which is an int
	inputorder has a value which is an int
	localpair has a value which is an int
	memsave has a value which is an int
	nofft has a value which is an int
	noscore has a value which is an int
	parttree has a value which is an int
	reorder has a value which is an int
	treeout has a value which is an int
	alg has a value which is a string
	aamatrix has a value which is a string
	bl has a value which is a string
	ep has a value which is a string
	groupsize has a value which is a string
	jtt has a value which is a string
	lap has a value which is a string
	lep has a value which is a string
	lepx has a value which is a string
	LOP has a value which is a string
	LEXP has a value which is a string
	maxiterate has a value which is a string
	op has a value which is a string
	partsize has a value which is a string
	retree has a value which is a string
	thread has a value which is a string
	tm has a value which is a string
	weighti has a value which is a string


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

my $usage = "usage: align_sequences [arguments] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $tool;
my $zero;
my ($clustal, $mafft, $muscle);

Getopt::Long::Configure("pass_through");

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script("tool=s"  => \$tool,
                                                       "mafft"   => \$mafft,
                                                       "clustal" => \$clustal,
                                                       "muscle"  => \$muscle,
                                                       "z|zero"  => \$zero);

my @prog_args = @ARGV;

if (! $kbO) { print STDERR $usage; exit }

my $seqs = gjoseqlib::read_fasta();
my $opts = process_prog_args(\@prog_args);

if    ($clustal) { $tool   = "clustal" }
elsif ($muscle)  { $tool   = "muscle" }
else             { $tool ||= "mafft" }


$opts->{tool}         = $tool;
$opts->{clustal_ends} = 1 if $zero;


my $align = $kbO->align_sequences($seqs, $opts);
gjoseqlib::print_alignment_as_fasta($align);


my %mafft_val = map { $_ => 1 }
                qw( alg algorithm

                    aamatrix
                    bl
                    ep
                    groupsize
                    jtt
                    lap
                    lep
                    lepx
                    LOP
                    LEXP
                    maxiterate
                    op
                    partsize
                    retree
                    thread
                    tm
                    weighti
                 );

my %mafft_flag = map { $_ => 1 }
                 qw( 6merpair
                     amino
                     anysymbol
                     auto
                     clustalout
                     dpparttree
                     fastapair
                     fastaparttree
                     fft
                     fmodel
                     genafpair
                     globalpair
                     inputorder
                     localpair
                     memsave
                     nofft
                     noscore
                     nuc
                     parttree
                     quiet
                     reorder
                     treeout
                  );

my %muscle_val  = map { $_ => 1 }
                  qw( anchorspacing
                      center
                      cluster1
                      cluster2
                      diagbreak
                      diaglength
                      diagmargin
                      distance1
                      distance2
                      gapopen
                      log
                      loga
                      matrix
                      maxhours
                      maxiters
                      maxmb
                      maxtrees
                      minbestcolscore
                      minsmoothscore
                      objscore
                      refinewindow
                      root1
                      root2
                      scorefile
                      seqtype
                      smoothscorecell
                      smoothwindow
                      spscore
                      SUEFF
                      usetree
                      weight1
                      weight2
                   );

my %muscle_flag = map { $_ => 1 }
                  qw( anchors
                      brenner
                      cluster
                      dimer
                      diags
                      diags1
                      diags2
                      le
                      noanchors
                      quiet
                      sp
                      spn
                      stable
                      sv
                      verbose
                   );


my $prog_vals;
my $prog_flags;

sub process_prog_args {
    my @args = @{$_[0]};
    my %opts;
    while ((shift @args) =~ /^-(\S+)/) {
        my $arg = $1;
        if (defined($prog_vals) && defined($prog_flags)) {
            if ($prog_vals->{$arg}) {
                $opts{$arg} = shift @args;
            } elsif ($prog_flags->{$arg}) {
                $opts{$arg} = 1;
            } else {
                die "Bad flag: '$arg'\n" . $usage;
            }
        } else {
            if (@args > 0 && $args[0] !~ /^-/) {
                $opts{$arg} = shift @args;
            } else {
                $opts{$arg} = 1;
            }
        }
    }
    return \%opts;
}
