use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_project_model

Project atomic regulons from model to new genome.

------

Example:

    svr_project_model -a AtomicRegulons -e Effectors -g TargetGenome -m ModelDir

would produce a directory called "MOdelDir" that contained

    atomic.regulons  [ a file defining the projeted atomic.regulons ]
    effectors        [ a file of predicted effectors ]
    errors           [ a log of problems encountered in the projection ]
------

=head2 Command-Line Options

=over 4

=item -a AtomicRegulons

This is used to specify a set of atomic regulons that are to be projected.
The first two columns of the table must contain 

    [atomic.reg.id,PEG-id]

=item -e Effectors

This is used to suggest effectors of expression.  The first column must 
contain an atomic regulon number.  The second to last column must
contain a code indicting the type of regulation (-,+,+-, or u).
The last column contains the effector.  Each line may be thought of
as stating that the effector activates or represses expression of the
atomic regulon.

=item -g TargetGenome

This specifies the genome to which the projection is made

=item -m ModelDir

The program creates a directory (ModelDir) that will contain

    atomic.regulons - a projection of the atomic regulons expressed
                      as a 2 column table [Id,Gene-in-atomic-regulon]

    effectors       - a projection of the effetors expressed as 3 columns
                        [atomic-regulon,impact-of-effector,effector]

=back

=head2 Output

The output is the ModelDir containing two files, one specifying the atomic
regulons, and one the effectors.  We allow singleton atomic regulons.  They
should be thought of as a means of reflecting the impact of an effector on
a single gene (although some singletons have no associated effectors).

=cut

use SeedUtils;
use SAPserver;
my $sapO = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_project_model -a atomic.regulons.to.project -e effectors -m ModelDir";

my $atomic_regs_in;;
my $effectors_in;
my $model_dir;
my $g2;
my $rc  = GetOptions('a=s' => \$atomic_regs_in, 
		     'e=s' => \$effectors_in,
		     'g=s' => \$g2,
		     'm=s' => \$model_dir);
if (! $rc) { print STDERR $usage; exit }

if (! $g2) { print STDERR "Invalid target genome\n"; exit }

if ((! -s $atomic_regs_in) || (! open(ARIN,"<$atomic_regs_in")))
{
    print STDERR "the atomic regulons are not expressed properly\n$usage";
    exit;
}

($model_dir && (-d $model_dir) || mkdir($model_dir,0777))
    || die "Invalid Model Directory: $model_dir";

my @ar_in = map { ($_ =~ /^(\d+)\t(\S+)/) ? [$1,$2] : () } <ARIN>;
close(ARIN);

(@ar_in > 0) || die "invalid input atomic regulons";
my $g1 = &SeedUtils::genome_of($ar_in[0]->[1]);

my @tmp = $sapO->gene_correspondence_map( -genome1 => $g1,
					   -genome2 => $g2,
					   -fullOutput => 1);
@tmp     = grep { $_->[8] eq "<=>" } @{$tmp[0]};
my %pegH = map { ($_->[0] => $_->[1]) } @tmp;
my @new_ar;
foreach my $tuple (@ar_in)
{
    my($ar,$from) = @$tuple;
    if (my $to_fid = $pegH{$from})
    {
	push(@new_ar,[$ar,$to_fid,$from]);
    }
}

my @fids = map { $_->[1] } @new_ar;

my $funcH_to = $sapO->ids_to_functions( -ids => \@fids);
my $funcH_from = $sapO->ids_to_functions( -ids => [map { $_->[1] } @ar_in]);

@new_ar = grep { $funcH_to->{$_->[1]} eq $funcH_from->{$_->[2]} } @new_ar;

my @effectors = map { chop; [split(/\t/,$_)] } `cat $effectors_in`;

my %projected = map { $_->[0] => 1 } @new_ar;

open(OUT,">$model_dir/atomic.regulons") || die "cannot open $model_dir/atomic.regulons";
foreach $_ (@new_ar)
{
    my $func = $funcH_to->{$_->[1]};
    if (! $func) { $func = "" }
    print OUT join("\t",@$_,$func),"\n";
}
close(OUT);

open(OUT,">$model_dir/effectors") || die "could not open $model_dir/effectors";
foreach $_ (@effectors)
{
#    if ($projected{$_->[0]})   the old effector files had atomic regulon ids, rather than genes
    if (my $fid = $pegH{$_->[0]})    # if we mapped the fid
    {
	$_->[0] = $fid;
	print OUT join("\t",@$_),"\n";
    }
}
close(OUT);
