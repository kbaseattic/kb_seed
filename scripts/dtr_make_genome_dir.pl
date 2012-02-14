#!/usr/bin/perl
use strict;
use Data::Dumper;
use SeedEnv;
use NotifyClient;
use gjoseqlib;
use SeedV;

# This is a SAS component

#
# Convert the raw myRast per-stage output files to a SEED genome directory.
#

my $usage = "dtr_make_genome_dir notify-port notify-handle genome-id myrast-data-dir dest-dir";

@ARGV == 5 or die "Usage: $usage\n";

my $nport = shift;
my $nhandle = shift;

my $genome_id = shift;
my $src_dir = shift;
my $dest_dir = shift;

my $nc = NotifyClient->new(port => $nport, handle => $nhandle);
$nc->status("Creating genome directory");
$nc->progress(0, 3);

my $genome_dir = "$dest_dir/$genome_id";
-d $genome_dir || mkdir($genome_dir);

my %next_id = (peg => 1, rna => 1);

#
# Start by walking the proteins to create the features directory. We
# assign pegs as well as part of the genome ID we picked.
#

my %id_map;

my $rna_dir = "$genome_dir/Features/rna";
my $peg_dir = "$genome_dir/Features/peg";

SeedUtils::verify_dir($peg_dir);
SeedUtils::verify_dir($rna_dir);

open(AF, ">", "$genome_dir/assigned_functions") or die "Cannot write $genome_dir/assigned_functions: $!";

my %features;

write_features("$src_dir/peg.fa", "$src_dir/peg.tbl", "peg", $peg_dir, \*AF);
write_features("$src_dir/rna.fa", "$src_dir/rna.tbl", "rna", $rna_dir, \*AF);

$nc->progress(1, 3);

my $seedv = SeedV->new($genome_dir);

my %called;
open(AI, "<", "$src_dir/functions.tbl") or die "Cannot open $src_dir/annotation.out: $!";
while (<AI>)
{
    chomp;
    my($id, $fam, $score, $non_overlap, $overlap, $func) = split(/\t/);
    my $nid = $id_map{$id};
    print AF join("\t", $nid, $func), "\n";
    $called{$nid}++;
    if (defined($score))
    {
	$seedv->add_annotation($nid, 'myRAST', "Original annotation based on kmers. score=$score non_overlap=$non_overlap overlap=$overlap function=$func");
    }
    else
    {
	$seedv->add_annotation($nid, 'myRAST', "Original annotation based on similarity. function=$func");
    }
}

#
# Fill in anything uncalled as hypothetical.
#
for my $peg (keys %{$features{peg}})
{
    next if $called{$peg};
    print AF join("\t", $peg, "hypothetical protein"), "\n";
    $seedv->add_annotation($peg, 'myRAST', "function not determined by myRAST");
}    

close(AF);

system("cp", "$src_dir/contigs", "$genome_dir/contigs");

$nc->progress(2, 3);

SeedUtils::verify_dir("$genome_dir/Subsystems");
open(M, "<", "$src_dir/meta_recon.tbl") or die "Cannot open $src_dir/metabolic_reconstruction.out: $!";
open(B, ">", "$genome_dir/Subsystems/bindings") or die "cannot write $genome_dir/Subsystems/bindings: $!";
open(S, ">", "$genome_dir/Subsystems/subsystems") or die "cannot write $genome_dir/Subsystems/subsystems: $!";

my %ss_seen;
while (<M>)
{
    chomp;
    my @a = split(/\t/);
    my $id = $a[0];
    my $variant = $a[-1];
    my $subsystem = $a[-2];
    my $func = $a[-3];

    my $nid = $id_map{$id};

    print B join("\t", $subsystem, $func, $nid), "\n";

    if (!$ss_seen{$subsystem})
    {
	print S join("\t", $subsystem, $variant), "\n";
	$ss_seen{$subsystem}++;
    }
	
}
close(M);
close(B);
close(S);
$nc->progress(3, 3);
$nc->status("Complete");

sub write_features
{
    my($fasta_in, $tbl_in, $type, $out_dir, $assigned_funcs_fh) = @_;

    open(G, "<", $fasta_in) or die "Cannot open $fasta_in: $!";
    open(FA, ">", "$out_dir/fasta") or die "Cannot write $out_dir/fasta: $!";

    while (my($xid, $def, $seq) = read_next_fasta_seq(\*G))
    {
	my $id = $next_id{$type}++;
	my $fid = "fig|$genome_id.$type.$id";
	$id_map{$xid} = $fid;

	print_alignment_as_fasta(\*FA, [$fid, $def, $seq]);

	$features{$type}->{$fid}++;
    }

    close(G);
    close(FA);

    open(TI, "<", $tbl_in) or die "Cannot open $tbl_in: $!";
    open(TO, ">", "$out_dir/tbl") or die "Cannot open $out_dir/tbl: $!";

    while (<TI>)
    {
	chomp;
	my($id, $contig, $b, $e, $fun) = split(/\t/);
	my $nid = $id_map{$id};
	my $loc = join("_", $contig, $b, $e);
	print TO join("\t", $nid, $loc, $fun), "\n";
	if ($fun)
	{
	    print $assigned_funcs_fh "$nid\t$fun\n";
	}
    }
    close(TI);
    close(TO);
}


