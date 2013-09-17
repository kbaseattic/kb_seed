use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use gjoseqlib;
use SeedAware;
use SeedEnv;

my $usage = "usage: CSA_close_strains Contigs1 Contigs2 WorkingDir Peg1 Rnas1 Functions1 Translations1";

my($orig_contigs1,$orig_contigs2,$dir,$peg_tbl1,$rna_tbl1,$functions1,$translations1);
(
 ($orig_contigs1 = shift @ARGV) && (-s $orig_contigs1) &&
 ($orig_contigs2 = shift @ARGV) && (-s $orig_contigs2) &&
 ($dir           = shift @ARGV) &&
 ($peg_tbl1      = shift @ARGV) && (-s $peg_tbl1) &&
 ($rna_tbl1      = shift @ARGV) && (-s $rna_tbl1) &&
 ($functions1    = shift @ARGV) && (-s $functions1) &&
 ($translations1 = shift @ARGV) && (-s $translations1)
)
    || die $usage;

if (-d $dir)
{
    die "$dir already exists";
}
else
{
    mkdir($dir,0777) || die "could not make $dir";
}

&run("cp $peg_tbl1 $dir/peg.tbl1");
&run("cp $rna_tbl1 $dir/rna.tbl1");
&run("cp $functions1 $dir/functions1");
&run("cp $translations1 $dir/translations1");

my $sz = &SeedUtils::max(-s $orig_contigs1,-s $orig_contigs2);
my $N = ((int(&log4($sz))+1) * 3) - 1;
my $index1            = "$dir/index1";
my $contigs1          = "$dir/contigs1";
my $kmers1            = "$dir/kmers1";
my $index2            = "$dir/index2";
my $contigs2          = "$dir/contigs2";
my $kmers2            = "$dir/kmers2";
my $matches           = "$dir/matches";
my $raw_repeats1      = "$dir/raw_repeats1";
my $raw_repeats2      = "$dir/raw_repeats2";
my $repeats1          = "$dir/repeats1";
my $repeats2          = "$dir/repeats2";
my $output_first_pass = "$dir/output.first.pass";
my $output_2nd_pass   = "$dir/output.second.pass";

&run("CSA_make_contig_index $index1 1 < $orig_contigs1 > $contigs1");
&run("formatdb -i $contigs1 -pF");
&run("CSA_make_contig_index $index2 2 < $orig_contigs2 > $contigs2");
&run("formatdb -i $contigs2 -pF");
&run("CSA_make_unique_kmers $N $raw_repeats1 < $contigs1 > $kmers1"); 
&run("CSA_collapse_repeats $raw_repeats1 > $repeats1");
&run("CSA_make_unique_kmers $N $raw_repeats2 < $contigs2 > $kmers2");
&run("CSA_collapse_repeats $raw_repeats2 > $repeats2");

open(KMERS1,"<$kmers1") || die "could not open $kmers1";
open(KMERS2,"<$kmers2") || die "could not open $kmers2";
open(MATCHES,"| sort -T . -k2,3 -k 4n > $matches") || die "could not open $matches";

my $k1 = <KMERS1>;
my $k2 = <KMERS2>;
while ($k1 && $k2)
{
    my($o1,$strand1) = ($k1 =~ /^(\S+)\t\S+\t(\S)/);
    my($o2) = ($k2 =~ /^(\S+)/);
    if (($strand1 ne "+") || ($o1 lt $o2))
    {
	$k1 = <KMERS1>;
    }
    elsif ($o1 gt $o2)
    {
	$k2 = <KMERS2>;
    }
    else
    {
	chop $k1;
	$k2 =~ /^\S+\t(\S+)\t(\S+)\t(\S+)/;
	print MATCHES join("\t",($k1,$1,$2,$3)),"\n";
	$k1 = <KMERS1>;
	$k2 = <KMERS2>;
    }
}
close(KMERS1);
close(KMERS2);
close(MATCHES);

&run("CSA_first_pass $dir > $output_first_pass");
&run("CSA_second_pass $dir > $output_2nd_pass");
&run("CSA_layout $dir $dir/peg.tbl1 $dir/rna.tbl1 $dir/functions1 > $dir/layout.after.second.pass");
&run("CSA_gather_mapped_objects $dir");
&run("CSA_get_repeat_dna $dir");
# print STDERR "data in $dir\n";

sub run {
    my($cmd) = @_;

#    print STDERR "running: $cmd\n";
    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}

sub log4 {
    my $n = shift;
    return log($n)/log(4);
}
