# -*- perl -*-
# This is a SAS component.
########################################################################
# Copyright (c) 2003-2006 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
# 
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License. 
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
########################################################################

use strict;
use warnings;
use SeedUtils;

$0 =~ m/([^\/]+)$/;
my $self  =  $1;
my $usage = "$self  [-norm] [-null] [-nolabel] [-pept] [-locus] < tbl.file > tbl.cumul 2> summary";

if (defined($ARGV[0]) && ($ARGV[0] =~ m/-help/))
{
    print STDERR "\n\t$usage\n\n";
    exit(1);
}

my $norm    = "";
my $null    = "";
my $nolabel = "";
my $pept    = "";
my $exons   = "";
my $locus   = "";
my $file    = "";
my $verbose = "";
while (@ARGV) {
    if    ($ARGV[0] =~ m/-norm/)     { $norm    = shift; }
    elsif ($ARGV[0] =~ m/-null/)     { $null    = shift; }
    elsif ($ARGV[0] =~ m/-nolabel/)  { $nolabel = shift; }
    elsif ($ARGV[0] =~ m/-pept/)     { $pept    = shift; }
    elsif ($ARGV[0] =~ m/-exons/)    { $exons   = shift; }
    elsif ($ARGV[0] =~ m/-locus/)    { $locus   = shift; }
    elsif ($ARGV[0] =~ m/-verbose/)  { $verbose = shift; }
    elsif (-s $ARGV[0])              { $file    = shift; }
    else  { die "Invalid arg $ARGV[0] --- usage: $usage"; }
}
if ($verbose) { $ENV{VERBOSE} = 1; }

my $fh;
if ($file) { 
    open(FILE, "<$file") || die "could not read-open $file";
    $fh = \*FILE; 
}
else {
    $fh = \*STDIN;
}


my $chars = 0;
my $total = 0;
my ($entry, $id_base, $loc, $contig, $left, $right, $strand, %histo, %id_set);
while (defined($entry = <$fh>)) {
    chomp $entry;
    if (($id_base, $loc) = ($entry =~ m/^(\S+)\t(\S+\_\d+[_+-]\d+)/)) {
	#...Do nothing
    }
    elsif (($loc) = ($entry =~ m/^(\S+\_\d+[_+-]\d+)/)) {
	$id_base = undef;
    }
    else {
	warn "Could not parse entry \'$entry\'\n" if $ENV{VERBOSE};
	next;
    }
    
    ($contig, $left, $right, $strand) = &SeedUtils::boundaries_of($loc);
    unless ($id_base) {
	$id_base = "$contig$strand$left\_$right";
    }
    
    my @exons;
    if ($exons) {
	@exons = split(/,/, $loc);
    }
    else {
	@exons = ($loc);
    }
    
    my $num_exon = 0;
    foreach my $exon (@exons) {
	++$total;
	
	my $id;
	if ($exons) {
	    $id = $id_base . q(-) . ++$num_exon;
	}
	else {
	    $id = $id_base;
	}
	
	($contig, $left, $right, $strand) = &SeedUtils::boundaries_of($exon);
	
	my $len = (1 + $right-$left);
	if ($pept) {
	    $len /= 3;
	}
	
	unless (defined($histo{$len})) { 
	    $histo{$len}  = 0;
	    unless ($nolabel || $null)  { $id_set{$len} = []; }
	}
	
	$chars       += $len;
	$histo{$len} += 1;
	
	unless ($nolabel || $null)  {
	    my $x = $id_set{$len};
	    if ($locus) {
		push(@$x, $loc);
	    }
	    else {
		push(@$x, $id);
	    }
	}
    }
}

my $cumul  = 0;
my $expect = 0;
my $min;
my $max;
my $median;
my $mean;
foreach my $len (sort {$a <=> $b} keys %histo)
{
    $expect += $histo{$len} * $len;
    
    $cumul  += $histo{$len};
    
    if (! defined($min))     { $min = $len; }
    
    if ((! defined($median)) && ($cumul > $total/2))  { $median = $len; }
    
    my $plot = $norm ? ($cumul/$total) : $cumul ;
    
    unless ($null)
    {
	print "$len\t$histo{$len}\t$plot";
	print "\t", join(", ", @{$id_set{$len}}) unless ($nolabel || $null);
	print "\n";
    }
    
    $max = $len;
}
$expect  = int(0.5 + 10*$expect/$cumul)/10;

print STDERR "\nThere are $chars chars in $total seqs.";
print STDERR "\nmin length = $min, median length = $median, mean length = $expect, max length = $max\n\n";
