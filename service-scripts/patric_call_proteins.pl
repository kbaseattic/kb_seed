use strict;
use Kmers;
use SAPserver;
use Data::Dumper;
use Getopt::Long;

#
# This is a SAS component.
#

my $sims_cutoff = 1e-10;
my $iden;
my $iden2;
my $md5_to_fam_file;
my $ff_dir;
my $out;

my $rc = GetOptions("ff=s" => \$ff_dir,
		    "md5-to-fam=s" => \$md5_to_fam_file,
		    "sims-cutoff=s" => \$sims_cutoff,
		    "iden=s" => \$iden,
		    "iden2=s" => \$iden2,
		    "out=s" => \$out,
		   );

if (!$rc || @ARGV != 1)
{
    die "Usage: patric_call_proteins [-ff figfam-directory] proteins.fasta\n";
}

my $out_fh;
if ($out)
{
    open($out_fh, ">", $out) or die "Cannot write output file $out: $!";
}
else
{
    $out_fh = \*STDOUT;
}
    
my $fasta = shift;
-f $fasta or die "$fasta does not exist\n";

#
# Force to anno seed.
#
$ENV{SAS_SERVER} = 'SEED';
my $sapO = SAPserver->new();
my $annO = AnnoUsingFFDir->new($ff_dir);

my %md5_to_fam;
if ($md5_to_fam_file)
{
    open(F, "<", $md5_to_fam_file) or die "Cannot open $md5_to_fam_file: $!";
    while (<F>)
    {
	chomp;
	my($md5, $fam) = split(/\t/);
	push(@{$md5_to_fam{$md5}}, $fam);
    }
    close(F);
}

my($kfunc, $kfam, $kscore, $pegs, $nomatch) = Kmers::patric_figfam_call($ff_dir, undef, $fasta, $annO, \%md5_to_fam, $sims_cutoff, $iden, $iden2);

for my $peg (@$pegs)
{
    print $out_fh join("\t", $peg, $kfam->{$peg}, $kfunc->{$peg}, @{$kscore->{$peg}}[0..2]), "\n";
}
for my $peg (@$nomatch)
{
    print $out_fh "$peg\n";
}

close($out_fh) if $out;

package AnnoUsingFFDir;

use strict;
use Kmers;
use Data::Dumper;

sub new
{
    my($class, $ff_dir) = @_;

    -d $ff_dir or die "Invalid ff dir $ff_dir";

    my $kmer = 8;
    my $friDB = "$ff_dir/FRI.db";
    my $setIDB = "$ff_dir/setI.db";
    my $table = "$ff_dir/Merged/$kmer/table.binary";

    my $kmers = Kmers->new(-frIdb => $friDB, -setIdb => $setIDB, -table => $table);
    my $self = {
	kmers => $kmers,
    };
    return bless $self, $class;
}

sub assign_function_to_prot
{
    my($self, %args) = @_;

    my $in = delete $args{-input};

    my $handle =  Getter->new($self->{kmers}, $in, \%args);
    return $handle;
}

package Getter;

use gjoseqlib;
use strict;

sub new
{
    my($class, $kmers, $inp, $args) = @_;

    my $self = {
	kmers => $kmers,
	input => $inp,
	args => $args,
    };
    return bless $self, $class;
}

sub get_next
{
    my($self) = @_;


    while (my($id, $com, $seq) = read_next_fasta_seq($self->{input}))
    {
	my @res = $self->{kmers}->assign_functions_to_prot_set(-seqs => [[$id, $com, $seq]], %{$self->{args}});
	if (@res)
	{
	    return $res[0];
	}
    }

    return undef;
}

