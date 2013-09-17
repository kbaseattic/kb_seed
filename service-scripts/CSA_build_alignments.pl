use strict;
#
# This is a SAS Component
#
use Data::Dumper;
use gjoseqlib;
use SeedEnv;
use Carp;

my $usage = "usage: CSA_build_alignments RefD SnpsD NewSeedDirs < WorkDir-AnnoD-Pairs";
my @dirs;
my $snpsD;
my $seed_dirs;
my $refD;
(
 ($refD      = shift @ARGV) &&
 ($snpsD     = shift @ARGV) &&
 ($seed_dirs = shift @ARGV)
)
    || die $usage;

((-d $refD) && ($refD =~ /(\d+\.\d+)$/))
    || die "$refD is not a valid SEED directory";
my $ref = $1;

(! -d $snpsD)                   || die "$snpsD already exists; delete it and try again";
mkdir($snpsD,0777)              || die "could not make $snpsD";
mkdir("$snpsD/Alignments",0777) || die "could not make $snpsD/Alignments";
mkdir("$snpsD/HTML",0777)       || die "could not make $snpsD/HTML";
mkdir("$snpsD/snp",0777)        || die "could not make $snpsD/snp";    # a Feature directory

(! -d $seed_dirs) || die "$seed_dirs already exists; delete it and try again";
mkdir($seed_dirs,0777) || die "could not make $seed_dirs";

while (defined($_ = <STDIN>) && ($_ =~ /^(\S+)\s+(\S+)$/))
{
    my $workD = $1;
    my $annoD = $2;
    if ((-d $workD) && ($workD =~ /(\d+\.\d+)-(\d+\.\d+)$/))
    {
	if ($ref eq $1)
	{
	    my $genomeId = $2;
	    if ((-d $annoD) && ($annoD =~ /(\d+\.\d+)/) && ($genomeId eq $1))
	    {
		push(@dirs,[$workD,$annoD,$genomeId]);
	    }
	    else
	    {
		die "$annoD appears to be an invalid annotation directory";
	    }
	}
	else
	{
	    die "conflicting reference genomes: $ref and $1";
	}
    }
    else
    {
	die "invalid work directory: $workD";
    }
}

(@dirs > 0) || die $usage;

my($fids,$intergenic) = &what_should_we_align($dirs[0]->[0]);
my @work_to_align;
foreach my $work_dir (@dirs)
{
    $work_dir->[0] =~ /(\d+\.\d+)$/;
    my $genome = $1;
    my($fids2,$intergenic2) = &get_nonref_strain($work_dir,$fids,$intergenic,$seed_dirs,$refD);
    push(@work_to_align,[$genome,$fids2,$intergenic2]);
}

my $gene_ali = {};
my $ig_ali   = {};

&load_ali($ref,$fids,$intergenic,'ref',$gene_ali,$ig_ali);
foreach $_ (@work_to_align)
{
    my($workG,$fidsG,$intergenicG) = @$_;
    &load_ali($workG,$fidsG,$intergenicG,'',$gene_ali,$ig_ali);
}
my $snps = &write_ali_and_snps($gene_ali,$ig_ali,$snpsD);
(@$snps > 0) || die "no SNPs";

open(TBL,">$snpsD/snp/tbl") || die "could not open $snpsD/tbl";
open(FASTA,">$snpsD/snp/fasta") || die "could not open $snpsD/fasta";
open(SNP2ALI,">$snpsD/snp2ali") || die "could not open $snpsD/snp2ali";
my $n = 1;
my $pre = "fig\|$ref\.snp\.";
my $i;
my %snp_exists;
foreach $_ (@$snps)
{
    my($ali,$comment,$seq) = @$_;
#   print STDERR &Dumper($comment);
    if ($comment =~ /(\S+)_(\d+)_(\d+)$/)
    {
	my($contig,$beg,$end) = ($1,$2,$3);
	my $len = abs($end-$beg)+1;
	my $offset = int(($len/2)-5);
	my($snp_beg,$snp_end,$snp_seq);
	if ($beg < $end)
	{
	    $snp_beg = $beg + $offset;
	    $snp_end = $snp_beg+9;
	    $snp_seq = substr($seq,$offset,10);
	}
	else
	{
	    $snp_beg = $beg - $offset;
	    $snp_end = $snp_beg-9;
	    $snp_seq = substr($seq,$offset,10);
	}
	my $snp_loc = join("_",($contig,$snp_beg,$snp_end));
	my $fid = $snp_exists{$snp_loc};
	if (! $fid)
	{
	    $fid = $pre . $n++; 
	    print TBL join("\t",($fid,$snp_loc)), "\t\n";
	    print FASTA ">$fid\n$snp_seq\n";
	    $snp_exists{$snp_loc} = $fid;
	}
	my @fids = ($ali =~ /((?:peg|rna)\.\d+)/g);
	print SNP2ALI join("\t",($fid,$ali,@fids)),"\n";
    }
}
close(TBL);
close(FASTA);
close(SNP2ALI);


sub write_ali_and_snps {
    my($gene_ali,$ig_ali,$snpsD) = @_;

    my $snps = [];
    foreach $_ (sort keys(%$gene_ali))
    {
	&process_fid($_,$gene_ali->{$_},$snps,$snpsD);
    }
    
    foreach $_ (sort keys(%$ig_ali))
    {
	&process_name($_,$ig_ali->{$_},$snps,$snpsD);
    }
    return $snps;
}


sub process_fid {
    my($fid,$tuples,$snps,$snpsD) = @_;

    $fid =~ /((peg|rna)\.\d+)/;
    my $name = $1;

#   print STDERR &Dumper(["tuples for $fid",$tuples]);
    if (@$tuples > 1)   # takes two to align
    {
	my @seqs = map { my($g,$dna,$prot,$loc) = @$_; [$g,"$fid $loc",$dna] } @$tuples;
	&align_set_and_form_snps(\@seqs,$snpsD,"$name.dna",$snps,'dna');
	@seqs    = map { my($g,$dna,$prot,$loc) = @$_; [$g,"$fid $loc",$prot] } @$tuples;;
	&align_set_and_form_snps(\@seqs,$snpsD,"$name.prot",$snps,'prot');
    }
}

sub process_name {
    my($name,$tuples,$snps,$snpsD) = @_;

    if (@$tuples > 1)
    {
#	print STDERR &Dumper(["tuples for $name",$tuples]);
	my @seqs = map { my($g,$dna,undef,$loc) = @$_; ["$g","$name $loc",$dna] } @$tuples;
	&align_set_and_form_snps(\@seqs,$snpsD,"$name.dna",$snps,'dna');
    }
}

sub align_set_and_form_snps {
    my($seqs,$snpsD,$ali,$snps,$dna_or_prot) = @_;

#    carp('align_seqs');
    if (@$seqs < 2) { confess "bad" } 
    if (! $seqs->[0]->[0]) { confess "bad id" }
    foreach $_ (@$seqs) { $_->[2] = uc $_->[2] }  # make sequences uppercase
    my $i;
    for ($i=1; ($i < @$seqs) && ($seqs->[$i]->[2] eq $seqs->[0]->[2]); $i++) {}
    if ($i < @$seqs)   # if we have a SNP
    {
	my $tmp1 = "tmp.1.$$.fasta";
	&gjoseqlib::print_alignment_as_fasta($tmp1,$seqs);
	&run("svr_align_seqs -k -l -tool=muscle < $tmp1 > $snpsD/Alignments/$ali; alignment_to_html < $snpsD/Alignments/$ali > $snpsD/HTML/$ali.html");
	my @alignment = &gjoseqlib::read_fasta("$snpsD/Alignments/$ali");
	unlink $tmp1;
	my(undef,$comment,$seq) = @{$alignment[0]};
	my $tuple = [$ali,$comment,$seq];
	push(@$snps,$tuple);
    }
}

sub load_ali {
    my($genome,$fids,$igs,$ref,$gene_ali,$ig_ali) = @_;

    foreach $_ (@$fids)
    {
	my($fid,$contig,$beg,$end,$dna,$trans,$loc) = @$_;
	push(@{$gene_ali->{$fid}},[$genome,$dna,$trans,$loc]);
    }
    
    foreach $_ (@$igs)
    {
	my($name,$contig,$beg,$end,$dna,undef,$loc) = @$_;
	if ($ref || $ig_ali->{$name})
	{
	    push(@{$ig_ali->{$name}},[$genome,$dna,undef,$loc]);
	}
	elsif (($name =~ /^(\d+\.\d+)-(\d+\.\d+)/) &&
	       $ig_ali->{"$2-$1"})
	{
	    my $nameR = "$2-$1";
	    my $dnaR = &Seedutils::rev_comp($dna);
	    $loc =~ /^(\S+)_(\d+)_(\d+)$/;
	    my $locR = join("$_",($1,$3,$2));
	    push(@{$ig_ali->{$nameR}},[$genome,$dnaR,undef,$locR]);
	}
    }
}
    
sub get_nonref_strain {
    my($work_dir,$ref_fids,$ref_intergenic,$seed_dirs,$refD) = @_;
    my($working_dir,$anno_dir,$genome_id) = @$work_dir;

    my %to_real  =  map { $_ =~ /^(\S+)\t(\S+)/; ($1 => $2) } `cat $working_dir/index2`;
    my @contig2_seqs = &gjoseqlib::read_fasta("$working_dir/contigs2");
    my %contigs2 =  map { $_->[0] => $_->[2] } @contig2_seqs;
    @contig2_seqs = map { $_->[0] = $to_real{$_->[0]}; $_ } @contig2_seqs;  ## convert to real contigs
    my @features =  grep { ! $_->[6] } 
                    map  { chop; [split(/\t/,$_)] } 
                    `cat $anno_dir/features`;
    my @fids     =  map { my $trans = ($_->[7] =~ /peg/) ? &SeedUtils::translate($_->[5],undef,1) : '';
			  $trans =~ s/\*$//;
			  [$_->[7],
			   $_->[1],
			   $_->[2],
			   $_->[3],
			   $_->[5],
			   $trans,
			   join("_",($to_real{$_->[1]},$_->[2],$_->[3])),
			   $_->[4]
			  ]
                    }
                    @features;
    &build_seed_dir($seed_dirs,$genome_id,\@fids,$refD,\@contig2_seqs);
    my($fids,$intergenic) = &extract_tuples(\@fids,\%contigs2,undef);
    return ($fids,$intergenic);
}

sub build_seed_dir {
    my($seed_dirs,$genome_id,$features,$refD,$contig2_seqs) = @_;

    my $dir = "$seed_dirs/$genome_id";
    mkdir($dir,0777) || die "could not make $dir";
    if (-s "$refD/RAXONOMY") { &run("cp $refD/TAXONOMY $dir") }
    mkdir("$dir/Features",0777) || die "could not make $dir/Features";
    mkdir("$dir/Features/peg",0777) || die "could not make $dir/Features/peg";
    mkdir("$dir/Features/rna",0777) || die "could not make $dir/Features/rna";
    open(PEGTBL,">$dir/Features/peg/tbl") || die "could not open $dir/Features/peg/tbl";
    open(RNATBL,">$dir/Features/rna/tbl") || die "could not open $dir/Features/rna/tbl";
    open(PEGFASTA,">$dir/Features/peg/fasta") || die "could not open $dir/Features/peg/fasta";
    open(RNAFASTA,">$dir/Features/rna/fasta") || die "could not open $dir/Features/rna/fasta";
    open(FUNC,">$dir/assigned_functions") || die "could not open $dir/assigned_functions";
    &gjoseqlib::print_alignment_as_fasta("$dir/contigs",$contig2_seqs);
    foreach my $tuple (@$features)
    {
	my($refid,undef,undef,undef,$dna,$prot,$loc,$func) = @$tuple;
	($refid =~ /^fig\|\d+\.\d+\.([^\.]+)\.(\d+)$/) || die $refid;
	my $fid = "fig|$genome_id.$1.$2";
	if ($1 eq 'rna')
	{
	    print RNATBL "$fid\t$loc\t\n";
	    print RNAFASTA ">$fid\n$dna\n";
	}
	else
	{
	    print PEGTBL "$fid\t$loc\t\n";
	    print PEGFASTA ">$fid\n$prot\n";
	}
	print FUNC "$fid\t$func\n";
    }
    close(PEGTBL);
    close(RNATBL);
    close(PEGFASTA);
    close(RNAFASTA);
    close(FUNC);
}

sub what_should_we_align {
    my($working_dir) = @_;
    my @fids;
    
    my %to_abbrev1  = map { $_ =~ /^(\S+)\t(\S+)/; ($2 => $1) } `cat $working_dir/index1`;
    my %contigs1    = map { $_->[0] => $_->[2] } &gjoseqlib::read_fasta("$working_dir/contigs1");
    my %transH      = map { $_->[0] => $_->[2] } &gjoseqlib::read_fasta("$working_dir/translations1");

    foreach $_ (`cat $working_dir/peg.tbl1 $working_dir/rna.tbl1`)
    {
	if ($_ =~ /^(fig\|\S+)\t(\S+)/)
	{
	    my $fid = $1;
	    my $loc = $2;
	    my($contig,$left,$right,$strand) = &SeedUtils::boundaries_of($loc);
	    my($beg,$end) = ($strand eq "+") ? ($left,$right) : ($right,$left);
	    my $dna = &dna_seq($to_abbrev1{$contig},$beg,$end,\%contigs1);
	    my $trans = ($fid =~ /peg/) ? $transH{$fid} : '';
	    push(@fids,[$fid,$contig,$beg,$end,$dna,$trans,$loc]);
	}
    }
    my($fids,$intergenic) = &extract_tuples(\@fids,\%contigs1,\%to_abbrev1);
    return ($fids,$intergenic);
}

sub extract_tuples {
    my($fids,$contigs,$to_abbrev) = @_;

    my @intergenic;
    my @fids = sort { ($a->[1] cmp $b->[1]) or 
			  (&SeedUtils::min($a->[2],$a->[3]) <=> &SeedUtils::min($b->[2],$b->[3])) 
		    } @$fids;
    my $i;
    for ($i=0; ($i < $#fids); $i++)
    {
	my($fid1,$contig1,$beg1,$end1,$dna1,$trans1,$loc1) = @{$fids[$i]};
	my($fid2,$contig2,$beg2,$end2,$dna2,$trans2,$loc2) = @{$fids[$i+1]};
	if (($contig1 eq $contig2) &&
	    (&SeedUtils::max($beg1,$end1) < &SeedUtils::min($beg2,$end2)))
	{
	    $fid1 =~ /((peg|rna)\.\d+)/;
	    my $name = $1;
	    $fid2 =~ /((peg|rna)\.\d+)/;
	    $name .= "-$1";
	    my $left  = &SeedUtils::max($beg1,$end1) + 1;
	    my $right = &SeedUtils::min($beg2,$end2) - 1;
	    my $abbrev_contig = $to_abbrev ? $to_abbrev->{$contig1} : $contig1;
	    my $dna = &dna_seq($abbrev_contig,$left,$right,$contigs);
	    push(@intergenic,[$name,$contig1,$left,$right,$dna,'',join("_",($contig1,$left,$right))]);
	}
    }
    return (\@fids,\@intergenic);
}

sub dna_seq {
    my($contig,$beg,$end,$contigs) = @_;
    if ($beg < $end)
    {
	return substr($contigs->{$contig},$beg-1,$end-($beg-1));
    }
    else
    {
	return &SeedUtils::rev_comp(substr($contigs->{$contig},$end-1,$beg-($end-1)));
    }
}

sub run {
    my($cmd) = @_;

#    print STDERR "running: $cmd\n";
    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}
