#!/usr/bin/env perl
# -*- perl -*-
#       This is a SAS Component.
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

=head1 NAME

genome_to_tbl

=head1 SYNOPSIS

usage: gto_to_tbl  genome.gto > genome.tab

=head1 DESCRIPTION

detailed_description_of_purpose_of_script

Example:

    example_of_use

example_description

=head1 COMMAND-LINE OPTIONS

Usage: short_usage_msg

    -opt1

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


use strict;
use warnings;

use SeedUtils;
use Data::Dumper;
# use YAML::Any;
# use Carp;

use Bio::KBase::GenomeAnnotation::Client;
use JSON::XS;

my $help;
my $input_file;
my $output_file;

my $trouble;
use Getopt::Long;
my $rc = GetOptions('help'       => \$help,
		    'input=s'    => \$input_file,
		    'output=s'   => \$output_file,
		    );

if (@ARGV == 1) {
    $input_file  ||= shift @ARGV;
    if (!-s $input_file) {
	$trouble = 1;
	warn "ERROR: input_file=\'$input_file\' does not exist or is empty\n";
    }
}


if (!$rc || $help || $trouble || @ARGV != 0) {
    seek(DATA, 0, 0);
    while (<DATA>) {
	last if /^=head1 COMMAND-LINE /;
    }
    while (<DATA>) {
	last if (/^=/);
	print $_;
    }
    exit($help ? 0 : 1);
}


my $out_fh;
if ($output_file) {
    open($out_fh, ">", $output_file) or die "Cannot open $output_file: $!";
} else { $out_fh = \*STDOUT; }


my $tbl = &load_gto($input_file);


use constant FID     =>  0;
use constant LOCUS   =>  1;
use constant CONTIG  =>  2;
use constant STRAND  =>  3;
use constant START   =>  4;
use constant STOP    =>  5;
use constant LEFT    =>  6;
use constant RIGHT   =>  7;
use constant LEN     =>  8;
use constant TYPE    =>  9;
use constant FUNC    => 10;
use constant ALT_IDS => 11;
use constant ENTRY   => 12;

foreach my $entry (@$tbl) {
    print $out_fh (join("\t", ($entry->[FID], $entry->[LOCUS], $entry->[FUNC])), "\n");
}
exit(0);


sub load_gto {
    my ($filename) = @_;
    my ($key, $id, $locus, $func, $contig, $beg, $end, $left, $right, $len, $strand, $type, $alt_ids);
    
    my $fh;
    open($fh, "<", $filename) or die "Cannot open $filename: $!";
    
    my $tbl = [];
    
    my $json = JSON::XS->new;
    my $gto;
    {
	local $/;
	undef $/;
	my $gto_txt = <$fh>;
	$gto = $json->decode($gto_txt);
	foreach my $feature (@ { $gto->{features} })
	{
	    ($id,   $contig, $strand,
	     $left, $right,
	     $beg,  $end,
	     $len,  $locus) = &feature_bounds($feature);
	    
	    $type = $feature->{type};
	    next unless ($type =~ m/^peg|CDS$/i);
	    
	    $func = $feature->{function} || q();
	    
	    $alt_ids = join(',', (defined($feature->{aliases}) ? @ { $feature->{aliases} } : q()));
	    
	    if (defined($contig)    && $contig
		&& defined($beg)    && $beg
		&& defined($end)    && $end
		&& defined($len)    && $len
		&& defined($strand) && $strand
		)
	    {
		push @$tbl, [ $id, $locus, $contig, $strand, $beg, $end, $left, $right, $len, $type, $func, $alt_ids, $feature ];
	    }
	    else {
		warn ("INVALID ENTRY:\n", Dumper($feature), "\n\n");
	    }
	}
    }
#   warn Dumper($tbl);
    
    @$tbl = sort { &by_locus($a,$b) } @$tbl;
    
    return $tbl;
}

sub feature_bounds {
    my ($feature) = @_;
    
    my $location = $feature->{location};
    
    my ($feature_contig,
	$feature_strand,
	$feature_left,
	$feature_right,
	) = &parse_exon($location->[0]);
    
    foreach my $exon (@$location) {
	my ($contig, $strand, $left, $right) = &parse_exon($exon);
	
	if ($feature_contig) {
	    if ($contig ne $feature_contig) {
		warn ("Malformed feature --- \'$contig\' ne \'$feature_contig\':\n", Dumper($feature));
		return ();
	    }
	}
	
	if ($feature_strand) {
	    if ($strand ne $feature_strand) {
		warn ("Malformed feature --- \'$strand\' ne \'$feature_strand\':\n", Dumper($feature));
		return ();
	    }
	}
	
	$feature_left  = &SeedUtils::min($left,  $feature_left);
	$feature_right = &SeedUtils::max($right, $feature_right);
    }
    
    my ($feature_beg, $feature_end) = ($feature_strand eq q(+))
	? ($feature_left,  $feature_right)
	: ($feature_right, $feature_left);
    
    my $feature_length = $feature_right - $feature_left + 1;
    
    my $feature_locus  = join(',', map { join('', ($_->[0], q(_), $_->[1], $_->[2], $_->[3])) } @$location);
    
    return ($feature->{id}, $feature_contig, $feature_strand,
	    $feature_left, $feature_right,
	    $feature_beg,  $feature_end,
	    $feature_length, $feature_locus);
}

sub parse_exon {
    my ($exon) = @_;
    my ($contig, $beg, $strand, $len) = @$exon;
    my $end = ($strand eq '+') ? $beg + ($len-1) : $beg - ($len-1);
    
    return ($contig, $strand, &SeedUtils::min($beg,$end), &SeedUtils::max($beg,$end));
}


sub from_locus {
    my ($locus) = @_;
    
    if ($locus) {
	my ($contig, $left, $right, $dir) = SeedUtils::boundaries_of($locus);
	my ($beg, $end) = ($dir eq q(+)) ? ($left, $right) : ($right, $left);
	
	if ($contig && $left && $right && $dir) {
	    return ($contig, $beg, $end, (1 + abs($right - $left)), $dir);
	}
	else {
	    die "Invalid locus $locus";
	}
    }
    else {
	die "Missing locus";
    }
    
    return ();
}

sub by_locus {
    my ($x, $y) = @_;
    
    return (  ($x->[CONTIG] cmp $y->[CONTIG]) 
	   || ($x->[LEFT]   <=> $y->[LEFT])
	   || ($y->[RIGHT]  <=> $x->[RIGHT])
	   || ($x->[STRAND] cmp $y->[STRAND])
	   );
}

__DATA__
