use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use gjoseqlib;
use SeedEnv;
use Carp;

my $usage = "usage: CSA_merge_estimates AnnotationsDir GenomeId < working.dirs";

my($annoD,$genome);
(
 ($annoD  = shift @ARGV) &&
 ($genome = shift @ARGV)
)
    || die $usage;

if (-d $annoD)
{
    die "$annoD already exists";
}
else
{
    mkdir($annoD,0777) || die "could not make $annoD";
}


my @dirs = map { $_ =~ /(\S.*\S)/; $1 } <STDIN>;
my @not_ok = grep { ! -s "$_/mapped.features" } @dirs;
if (@not_ok > 0)
{
    foreach $_ (@not_ok)
    {
	print STDERR "$_ is not a valid working directory\n";
    }
    die "bad working directories";
}

&run("cp $dirs[0]/index2 $annoD/contigs.index");
&merge_called(\@dirs,$annoD);
&merge_lost(\@dirs,$annoD);
&merge_disrupted(\@dirs,$annoD);
&merge_repeats(\@dirs,$annoD);

sub merge_lost {
    my($wds,$annoD) = @_;
    
    my $cmd = "cat " . join(" ",map { "$_/lost.features" } @$wds) . " > $annoD/potentially.lost.features";
    &run($cmd);
}

sub merge_disrupted {
    my($wds,$annoD) = @_;
    
    my $cmd = "cat " . join(" ",map { "$_/disrupted.features" } @$wds) . " > $annoD/potentially.disrupted.features";
    &run($cmd);
}

sub merge_repeats {
    my($wds,$annoD) = @_;
    
    my @repeats;
    foreach my $dir (@$wds)
    {
	foreach $_ (`cat $dir/big.repeats2`)
	{
	    chop;
	    my($sz,$iden,$c1,$b1,$e1,$c2,$b2,$e2) = split(/\t/,$_);
	    push(@repeats,[$c1,&SeedUtils::min($b1,$e1),&SeedUtils::max($b1,$e1)]);
	    push(@repeats,[$c2,&SeedUtils::min($b2,$e2),&SeedUtils::max($b2,$e2)]);
	}
    }
    @repeats = sort { ($a->[0] cmp $b->[0]) or ($a->[1] <=> $b->[1]) or ($a->[2] <=> $b->[2]) } 
               @repeats;
    open(REPEATS,">"."$annoD/possible.large.repeats") || die "could not open $annoD/possible.large.repeats";
    while (my $x = shift @repeats)
    {
	my($c,$b,$e) = @$x;
	while ((@repeats > 0) && ($c eq $repeats[0]->[0]) && &SeedUtils::between($b,$repeats[0]->[1],$e))
	{
	    my $y = shift @repeats;
	    my($c2,$b2,$e2) = @$y;
	    $e = &SeedUtils::max($e,$e2);
	}
	print REPEATS join("\t",($c,$b,$e)),"\n";
    }
    close(REPEATS);
}

sub merge_called {
    my($wds,$annoD) = @_;

    my %by_stop;
    foreach my $dir (@$wds)
    {
	my @trans = &gjoseqlib::read_fasta("$dir/translations1");
	my %trans_of = map { ($_->[0] => $_->[2]) } @trans;
	open(MAPPED,"<","$dir/mapped.features") || die "could not open $dir/mapped.features";
	while (defined($_ = <MAPPED>))
	{
	    chop;
	    my($contig,$beg,$end,$fid,$func,$seq) = split(/\t/,$_);
	    my($type) = ($fid =~ /^fig\|\d+\.\d+\.([^\.]+)\.\d+$/);
	    my $translation = $trans_of{$fid} || '';
	    push(@{$by_stop{"$contig,$end"}->{$beg}},[$type,$func,$seq,$fid,$translation]);
	}
	close(MAPPED);
    }
    my $next_peg = 1;
    my $next_rna = 1;
    my @stops = sort keys(%by_stop);
    my @called;
    foreach my $stop (@stops)
    {
	my($c,$e) = ($stop =~ /(\S+),(\d+)/);
	my $set = $by_stop{$stop};
	my @poss_beg = sort { (@{$set->{$b}} <=> @{$set->{$a}} ) or 
			         (abs($e-$b) <=> abs($e-$a)) }
		       keys(%$set);
	my $b1 = $poss_beg[0];
	my $num_occ    = @{$set->{$b1}};
	my $next_best  = (@poss_beg > 1) ? @{$set->{$poss_beg[1]}} : 0;
	push(@called,[$c,$b1,$e,@{$by_stop{$stop}->{$b1}->[0]},$num_occ,$next_best]);
    }

    open(FIDS,">","$annoD/features") || die "could not open $annoD/features";
    foreach my $tuple (sort { $a->[0] cmp $b->[0] or ($a->[1] <=> $b->[1]) } @called)
    {
	my($c,$b,$e,$type,$func,$seq,$rfid,$trans,$num_occ,$better_by) = @$tuple;
	$rfid || confess "rfid is undefined";
	my $n = ($type eq "peg") ? $next_peg++ : $next_rna++;
	my $fid = "fig\|$genome\." . $type . ".$n";
	my $err = ($type eq 'peg' ) ? &check_seq($seq) : '';
	print FIDS join("\t",($fid,$c,$b,$e,$func,$seq,$err,$rfid,$num_occ,$better_by,$trans)),"\n";
    }
}

sub check_seq {
    my($seq) = @_;

    my @errs;
    if ($seq !~ /^[agt]tg/i)        { push(@errs,'bad start codon') }
    if ($seq !~ /(tag|taa|tga)$/i)  { push(@errs,'bad stop codon')  }
    if ((length($seq) % 3) != 0)    { push(@errs,'possible frameshift') }
    my $i;
    for ($i=0; ($i < (length($seq)-3)) && (substr($seq,$i,3) !~ /(tag|taa|tga)/i); $i += 3) {}
    if ($i < length($seq)-3)
    {
	push(@errs,'embedded stop codon');
    }
    return join("; ",@errs);
}
    
sub run {
    my($cmd) = @_;

    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}
