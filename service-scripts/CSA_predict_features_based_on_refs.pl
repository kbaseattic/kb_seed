use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use SeedEnv;
use gjoseqlib;
use Carp;
use FS_RAST;

my $usage = "usage: CSA_predict_features_based_on_refs [-install] Features ContigIndex CurrentDir > recommended.changes";

my $install = $ARGV[0] eq "-install";
if ($install) { shift @ARGV }

my($featuresF,$indexF,$currentD);
(
 ($featuresF    = shift @ARGV) &&
 ($indexF       = shift @ARGV) &&
 ($currentD     = shift @ARGV)
)
    || die $usage;

(-s $featuresF) || die "$featuresF does not exist";
(-s $indexF)    || die "$indexF does not exist";
(-s "$currentD/Features/peg/tbl") || die "$currentD is not a valid Seed Directory";

my $refH;
if ($install)
{
    $refH = &load_dir($currentD);
}

my $fids = [];
my $fidH = {};
&load_existing($currentD,'peg',$fids,$fidH);
&load_existing($currentD,'rna',$fids,$fidH);
my @predictions = &load_scored_predictions($featuresF,$indexF);

my @kept;
foreach my $tuple (@predictions)
{
    my($id,$contig,$beg,$end,$func,$seq,$errs,$template_peg,undef,undef,$template_translation,$sc) = @$tuple;
    my $existing = 0;
    my $i;
    for ($i=0; ($i < @kept) && (&overlaps($contig,$beg,$end,$kept[$i]->[1],$kept[$i]->[2],$kept[$i]->[3]) < 30); $i++) {}
    if ($i == @kept)
    {
	for ($i=0; ($i < @$fids); $i++)
	{
	    my($id1,$contig1,$beg1,$end1) = @{$fids->[$i]};
	    if ($contig eq $contig1) 
	    {
		if (($beg != $beg1) || ($end != $end1))
		{
		    if (($_ = &overlaps($contig,$beg,$end,$contig1,$beg1,$end1)) >= 150)
		    {
			if ($sc >= 4)
			{
			    if ($end == $end1)
			    {
				print join("\t",('replace',$id1,$contig1,$beg1,$end1,$contig,$beg,$end,$func,$_,$sc)),"\n";
				$fidH->{join(",",(&SeedUtils::type_of($id1),$contig,$beg,$end))} = 1;
				if ($install)
				{
				    &replace($refH,$id1,$contig,$beg,$end,$func,$seq,$errs,$template_peg,$template_translation);
				}
			    }
			    else
			    {
				print join("\t",('delete',$id1,$contig1,$beg1,$end1,$contig,$beg,$end,$func,$_,$sc)),"\n";
				if ($install)
				{
				    &delete_fid($refH,$id1);
				}
			    }
			}
			else
			{
			    $existing = 1;
			}
		    }
		}
	    }
	}
	my $type = &SeedUtils::type_of($id);
	if ((! $fidH->{join(",",($type,$contig,$beg,$end))}) && (! $existing))
	{
	    my $len = abs($end-$beg)+1;
	    if (($len > 150) || (! &SeedUtils::hypo($func)))
	    {
		print join("\t",('add',$type,$contig,$beg,$end,$len,$func,$errs,$sc,$template_translation)),"\n";
		push(@kept,$tuple);
		if ($install)
		{
		    &add($refH,$type,$contig,$beg,$end,$func,$errs,$seq,$template_peg,$template_translation);
		}
	    }
	}
    }
}

if ($install)
{
    &update_dir($refH,$currentD);
}

sub update_dir {
    my($refH,$currentD) = @_;

    &update_tbl($currentD,$refH,'peg');
    &update_tbl($currentD,$refH,'rna');
    &update_fasta($currentD,$refH,'peg');
    &update_fasta($currentD,$refH,'rna');
    &update_func($currentD,$refH);
    &update_annotations($currentD,$refH);
}

sub overlaps {
    my($c1,$b1,$e1,$c2,$b2,$e2) = @_;

    if ($b1 > $e1) { ($b1,$e1) = ($e1,$b1) }
    if ($b2 > $e2) { ($b2,$e2) = ($e2,$b2) }

    if (($b1 <= $b2) && ($e1 >= $b2))
    {
	return (&min($e1,$e2) - $b2) + 1;
    }
    elsif (($b2 <= $b1) && ($e2 >= $b1))
    {
	return (&min($e1,$e2) - $b1) + 1;
    }
    else
    {
	return 0;
    }
}

sub load_scored_predictions {
    my($features,$index) = @_;

    open(INDEX,"<$indexF") || die "could not open $indexF";
    my %to_real = map { ($_ =~ /^(\S+)\t(\S+)$/) ? ($1 => $2) : () } <INDEX>;
    close(INDEX);

    open(FEATURES,"<$featuresF") || die "could not open $featuresF";
    my @scored = sort { $b->[11] <=> $a->[11] }
                 grep { $_->[11] >= 2 }
	         map { chop; 
		       my @x = split(/\t/,$_); 
		       $x[1] = $to_real{$x[1]};
		       push(@x,&score(&SeedUtils::type_of($x[0]),$x[4],length($x[5]),$x[6],$x[8],$x[9]));
		       \@x;
		     } <FEATURES>;
    close(FEATURES);
    return @scored;
}

sub score {
    my($type,$func,$seqlen,$errs,$mapped,$next_best) = @_;

    my $score = 2 * ($mapped - $next_best);
    if (! &SeedUtils::hypo($func))    { $score += 2 }
    if ($seqlen > 120)                { $score += 2 }
    if ($errs)                        { $score -= 10 }
    return $score;
}

sub load_existing {
    my($seed_dir,$type,$fids,$fidH) = @_;
    open(TBL,"<$seed_dir/Features/$type/tbl")
	|| die "$seed_dir/Features/$type/tbl does not exist";
    foreach $_ (<TBL>)
    {
	if ($_ =~ /^(fig\|\d+\.\d+\.$type\.\d+)\t(\S+)_(\d+)_(\d+)/) 
	{
	    push(@$fids,[$1,$2,$3,$4]);
	    $fidH->{join(",",($type,$2,$3,$4))} = $1;
	}
    }
    close(TBL);
}

sub load_dir {
    my($currentD) = @_;

    my $refH = {};
    $refH->{'deleted'}->{peg} = &deleted_fids($currentD,'peg');
    $refH->{'deleted'}->{rna} = &deleted_fids($currentD,'rna');
    $refH->{annotations} = [];
    &load_tbl($currentD,$refH,'rna');
    &load_tbl($currentD,$refH,'peg');
    $refH->{max}->{rna} = &max_fid($refH->{tbl}->{rna});
    $refH->{max}->{peg} = &max_fid($refH->{tbl}->{peg});
    &load_fasta($currentD,$refH,'rna'); 
    &load_fasta($currentD,$refH,'peg');
    &load_func($currentD,$refH);
    $refH->{code} = 11;
    return $refH;
}

sub max_fid {
    my($tblH) = @_;
    
    my @fids = sort { &SeedUtils::by_fig_id($a,$b) } keys(%$tblH);
    return $fids[-1];
}

sub deleted_fids {
    my($currentD,$type) = @_;

    my $delH = {};
    if (open(DEL,"<$currentD/Features/$type/delete.features"))
    {
	while (defined($_ = <DEL>))
	{
	    if ($_ =~ /^(\S+)/) { $delH->{$1} = 1 }
	}
	close(DEL);
    }
    return $delH;
}

sub load_tbl {
    my($currentD,$refH,$type) = @_;

    my $file = "$currentD/Features/$type/tbl";
    my $delH = $refH->{deleted}->{$type};
    open(TBL,"<$file") || die "cannot open $file";
    my %tbl = map { (($_ =~ /^(\S+)/) && (! $delH->{$1})) ? ($1 => $_) : () } <TBL>;
    close(TBL);
    $refH->{tbl}->{$type} = \%tbl;
}

sub update_tbl {
    my($currentD,$refH,$type) = @_;

    my $tbl = $refH->{tbl}->{$type};
    my $file = "$currentD/Features/$type/tbl";
    if (-s "$file~") { unlink("$file~") }
    rename($file,"$file~");
    open(TBL,">$file") || die "could not open $file";
    foreach my $fid (sort { &SeedUtils::by_fig_id($a,$b) } keys(%$tbl))
    {
	print TBL $tbl->{$fid};
    }
    close(TBL);
    my $delH = $refH->{deleted}->{$type};
    if ($refH)
    {
	my @deleted = sort { &SeedUtils::by_fig_id($a,$b) } keys(%$delH);
	if (@deleted > 0)
	{
	    my $file = "$currentD/Features/$type/deleted.features";
	    open(DEL,">$file") || die "could not open $file";
	    foreach $_ (@deleted)
	    {
		print DEL "$_\n";
	    }
	    close(DEL);
	}
    }
}
    
sub load_fasta {
    my($currentD,$refH,$type) = @_;

    my $delH  = $refH->{deleted}->{$type};
    my $file  = "$currentD/Features/$type/fasta";
    my @seqs  = grep { ! $delH->{$_->[0]} } &gjoseqlib::read_fasta($file);
    my %seqsH = map { $_->[0] => [$_->[1],$_->[2]] } @seqs;
    $refH->{fasta}->{$type} = \%seqsH;
}

sub update_fasta {
    my($currentD,$refH,$type) = @_;

    my $file  = "$currentD/Features/$type/fasta";
    if (-s "$file~") { unlink("$file~") }
    rename($file,"$file~");
    my $seqH = $refH->{fasta}->{$type};
    my @seqs = map { [$_,@{$seqH->{$_}}] } 
               sort { &SeedUtils::by_fig_id($a,$b) } 
               keys(%$seqH);
    &gjoseqlib::print_alignment_as_fasta($file,\@seqs);
}

sub load_func {
    my($currentD,$refH) = @_;

    my $assignments = {};
    &load_file($assignments,"$currentD/proposed_non_ff_functions");
    &load_file($assignments,"$currentD/proposed_functions");
    &load_file($assignments,"$currentD/assigned_functions");
    $refH->{assignments} = $assignments;
}

sub load_file {
    my($assignments,$file) = @_;

    if (open(FILE,"<",$file))
    {
	while (defined($_ = <FILE>))
	{
	    chop;
	    my($fid,$func) = split(/\t/,$_);
	    $assignments->{$fid} = $func;
	}
	close(FILE);
    }
}

sub update_func {
    my($currentD,$refH) = @_;

    my $file = "$currentD/assigned_functions";
    if (-s "$file~") { unlink("$file~") }
    rename($file,"$file~");
    open(ASSIGN,">$file") || die "could not open $file";
    my $assignments = $refH->{assignments};
    foreach my $fid (sort { &SeedUtils::by_fig_id($a,$b) } keys(%$assignments))
    {
	print ASSIGN join("\t",($fid,$assignments->{$fid})),"\n";
    }
    close(ASSIGN);
}

sub update_annotations {
    my($currentD,$refH) = @_;

    my $annotations = $refH->{annotations};
    open(ANN,">>$currentD/annotations")
	|| confess "could not open $currentD/annotations";

    my $time_made = time;
    foreach my $annotation (@$annotations) {
	my ($fid,$text) = @$annotation;
	print ANN "$fid\n$time_made\nchanges to sequence\n$text\n//\n";
    }
    close(ANN);
}

sub replace {
    my($refH,$fid,$contig,$beg,$end,$func,$seq,$errs,$template_peg,$template_translation) = @_;

    &delete_fid($refH,$fid);
    my $type = &SeedUtils::type_of($fid);
    &add($refH,$type,$contig,$beg,$end,$func,$errs,$seq,$template_peg,$template_translation,$fid);
}

sub delete_fid {
    my($refH,$fid) = @_;

    my $type = &SeedUtils::type_of($fid);
    $refH->{deleted}->{$type}->{$fid} = 1;
    delete $refH->{tbl}->{$type}->{$fid};
    delete $refH->{fasta}->{$type}->{$fid};
}

sub add {
    my($refH,$type,$contig,$beg,$end,$func,$errs,$seq,$template_peg,$template_translation,$fid) = @_;

    if (! $fid)
    {
	my $last_fid = $refH->{max}->{$type};
	($last_fid =~ /^(fig\|\d+\.\d+\.[^\.]+\.)(\d+)/) || die "bad fid: $last_fid";
	$fid = $1 . ($2 + 1);
	$refH->{max}->{$type} = $fid;
    }
    if ($refH->{deleted}->{$type}->{$fid}) { delete $refH->{deleted}->{$type}->{$fid} }
    my $tbl_line = join("\t",($fid,join("_",($contig,$beg,$end)),'')) . "\n";
    $refH->{tbl}->{$type}->{$fid} = $tbl_line;
    $func || ($func = '');
    $refH->{assignments}->{$fid} = $func;
    
    my $prot_seq;
    if ($type eq 'peg')
    {
	if (! $errs)
	{
	    ### we need to construct the correct genetic code here, if it is not 11 ###
	    if ($refH->{code} == 11)
	    {
		$prot_seq = &SeedUtils::translate($seq,undef,1);
		$prot_seq =~ s/\*$//;
	    }
	    else
	    {
		die "we do not support genetic code $refH->{code} yet";
	    }
	}
	else
	{
	    my $params = {};
	    $params->{family}  = [[ $template_peg, "", $template_translation ]];
	    $params->{code}    = $refH->{code};
	    my ($new_loc, $new_translation, undef, $annotation) = &FS_RAST::best_match_in_family($params, [$contig,$beg,$end,$seq]);
	    if ($new_loc) 
	    {
		$prot_seq = $new_translation;
		push(@{$refH->{annotations}},[$fid,$annotation]);
	    }
	}
    }
    $refH->{fasta}->{$type}->{$fid} = ['',($type eq 'peg') ? $prot_seq : $seq];
}
