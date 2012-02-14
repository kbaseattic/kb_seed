
#
# myRAST pipeline processing script.
#
# dtr_call_rnas notify-port notify-handle dom-otu-in contig-file-in fasta-file-out tbl-file-out
#

#
# This is a SAS Component
#

use strict;
use ANNOserver;
use NotifyClient;

@ARGV == 6 || die "Usage: $0 notify-port notify-handle dom-otu-in contig-file-in fasta-file-out tbl-file-out\n";

my $nport = shift;
my $nhandle = shift;

my $dom_otu = shift;
my $contigs = shift;
my $fasta = shift;
my $tbl = shift;

my $nc = NotifyClient->new(port => $nport, handle => $nhandle);
$nc->status("Calling RNAs");
$nc->progress(-1, 100);

my $ffServer = ANNOserver->new();

open(OTU, "<", $dom_otu) or die "Cannot open dominant-OTU file $dom_otu: $!";
open(CONTIGS, "<", $contigs) or die "Cannot open contigs file $contigs: $!";

open(FA, ">", $fasta) or die "Cannot write fasta file $fasta: $!";
open(TBL, ">", $tbl) or die "Cannot write tbl file $tbl: $!";

$_ = <OTU>;
chomp;
my($name, $genus, $species, $domain) = split(/\t/);
close(OTU);

print "genus=$genus species=$species domain=$domain\n";
my $ret = $ffServer->find_rnas(-input => \*CONTIGS,
			       -genus => $genus,
			       -species => $species,
			       -domain => $domain);
close(CONTIGS);

my($fa, $tbl) = @$ret;

$nc->status("Writing output files");
$nc->progress(50, 100);

print FA $fa;
close(FA);

$nc->progress(75, 100);

print TBL join("\t", @$_), "\n" for @$tbl;
close(TBL);

$nc->progress(100, 100);
$nc->status("Complete");


