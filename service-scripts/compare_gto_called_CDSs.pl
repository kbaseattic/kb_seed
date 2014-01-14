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

compare-called-CDSs

=head1 SYNOPSIS

usage: compare-called-CDSs  old.gto  new.gto  [summary.yaml] > comparison.tab  2> summary.txt

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
use YAML::Any;
# use Carp;

use Bio::KBase::GenomeAnnotation::Client;
use JSON::XS;

my $help;
my $first_file;
my $second_file;
my $output_file;
my $summary_yaml;

my $trouble;
use Getopt::Long;
my $rc = GetOptions('help'        => \$help,
		    'file1=s'     => \$first_file,
		    'file2=s'     => \$second_file,
		    'output=s'    => \$output_file,
		    'summary=s'   => \$summary_yaml,
		    );

if (@ARGV >= 2) {
    $first_file  ||= shift @ARGV;
    if (!-s $first_file) {
	$trouble = 1;
	warn "ERROR: file1=\'$first_file\' does not exist or is empty\n";
    }
    
    $second_file ||= shift @ARGV;
    if (!-s $second_file) {
	$trouble = 1;
	warn "ERROR: file2=\'$second_file\' does not exist or is empty\n";
    }
}


if (@ARGV == 1) {
    $summary_yaml = shift @ARGV;
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


my ($old_tbl, $old_num_pegs) = &load_gto($first_file);
my ($new_tbl, $new_num_pegs) = &load_gto($second_file);


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


my $identical   = 0;
my $same_stop   = 0;
my $differ      = 0;
my $short       = 0;
my $long        = 0;
my $added       = 0;
my $lost        = 0;


my (%keys, @keys);
foreach my $key ((keys %$old_tbl), (keys %$new_tbl)) {
    $keys{$key} = 1;
}
@keys = sort { &by_key($a,$b) } (keys %keys);

print STDERR (q(Num keys = ), (scalar @keys), qq(\n\n)) if $ENV{VERBOSE};

print STDOUT (q(#), join(qq(\t), qw(Comparison Old_ID New_ID Old_Length New_Length Length_Diff Old_Loc New_Loc Old_Function New_Function Old_Alt_IDs New_Alt_IDs)), qq(\n));

foreach my $key (sort { &by_key($a,$b) } @keys) {
    my $case      = q();
    
    my $old_fid   = q();
    my $old_func  = q();
    my $old_loc   = q();
    my $old_len   = 0;
    my $old_alt   = q();
    if (defined($old_tbl->{$key})) {
	$old_fid   = $old_tbl->{$key}->[FID];
	$old_func  = $old_tbl->{$key}->[FUNC];
	$old_loc   = $old_tbl->{$key}->[LOCUS];
	$old_len   = $old_tbl->{$key}->[LEN];
	$old_alt   = $old_tbl->{$key}->[ALT_IDS];
    }
    
    my $new_fid   = q();
    my $new_func  = q();
    my $new_loc   = q();
    my $new_len   = 0;
    my $new_alt   = q();
    if (defined($new_tbl->{$key})) {
	$new_fid   = $new_tbl->{$key}->[FID];
	$new_func  = $new_tbl->{$key}->[FUNC];
	$new_loc   = $new_tbl->{$key}->[LOCUS];
	$new_len   = $new_tbl->{$key}->[LEN];
	$new_alt   = $new_tbl->{$key}->[ALT_IDS];
    }
    
    if (defined($old_tbl->{$key})) {
	if (not defined($new_tbl->{$key})) {
	    $case = q(lost);
	    
	    ++$lost;
	    ++$differ;
	    die Dumper($old_tbl->{$key}) unless $old_len;
	}
	else {
	    ++$same_stop;
	    if    ($old_len == $new_len) {
		$case = q(ident);
		
		++$identical;
	    }
	    elsif ($old_len >  $new_len) {
		$case = q(short);
		
		++$short;
		++$differ;
	    }
	    elsif ($old_len <  $new_len) {
		$case = q(long);
		
		++$long;
		++$differ;
	    }
	    else {
		die "Could not handle $key";
	    }
	}
    }
    else {
	$case = q(added);
	
	++$added;
	++$differ;
    }
    my $diff = $new_len - $old_len;
    
    print STDOUT (join(qq(\t), ($case, $old_fid, $new_fid, $old_len, $new_len, $diff, $old_loc, $new_loc, $old_func, $new_func, $old_alt, $new_alt)), qq(\n));
}		
		
if (defined($summary_yaml))
{
    if (open(my $fh, ">", $summary_yaml))
    {
	&write_summary_yaml($fh, $old_num_pegs, $new_num_pegs, $identical, $same_stop, $differ, $short, $long, $added, $lost);
    }
    else
    {
	die "Error opening $summary_yaml for writing: $!";
    }
}
else
{
    &write_summary($old_num_pegs, $new_num_pegs, $identical, $same_stop, $differ, $short, $long, $added, $lost);
}

exit(0);



sub load_gto {
    my ($filename) = @_;
    my ($tbl, $num_pegs);
    my ($key, $id, $locus, $func, $contig, $beg, $end, $left, $right, $len, $strand, $type, $alt_ids);
    
    my $fh;
    open($fh, "<", $filename) or die "Cannot open $filename: $!";
    
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
		
		$key = join("\t", ($contig, $strand.$end));
		
		if (not defined($tbl->{$key})) {
		    ++$num_pegs;
		    $tbl->{$key} = [ $id, $locus, $contig, $strand, $beg, $end, $left, $right, $len, $type, $func, $alt_ids, $feature ];
		}
		else {
		    warn ("Skipping same-STOP TBL entry for $filename, $key:\n"
			  , Dumper($feature),
			  , "\n\n");
		}
	    }
	    else {
		warn ("INVALID ENTRY:\n", Dumper($feature), "\n\n");
	    }
	}
    }
    
    return ($tbl, $num_pegs);
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



sub load_tbl
{
    my ($file) = @_;
    my ($tbl, $num_pegs);
    my ($key, $entry, $id, $locus, $func, $rest, $contig, $beg, $end, $len, $strand, $type);
    
    open(TBL, "<$file") || die "Could not read-open \'$file\'";
    while (defined($entry = <TBL>))
    {
	next if ($entry =~ m/^\#/);
	
	chomp $entry;
	my @fields = split /\t/, $entry, -1;
	$id    = shift @fields;
	$func  = pop @fields;
	$locus = pop @fields;
	
	$rest = join(q(,), (grep { $_ } @fields) );
	
	if ((($contig, $beg, $end, $len, $strand) = &from_locus($locus)) 
	   && defined($contig) && $contig
	   && defined($beg)    && $beg
	   && defined($end)    && $end
	   && defined($len)    && $len
           && defined($strand) && $strand
           )
	{
	    $key = "$contig\t$strand$end";
	    
	    $type = q(peg);   #...Until such time as RNAs are handled properly...
# 	    if (($type eq 'peg') || ($type eq 'orf')) {
 		++$num_pegs;
# 	    }
# 	    else {
# 		warn "Unknown feature type: $entry\n";
# 	    }
	    
	    if (not defined($tbl->{$key})) {
		$tbl->{$key} = [ $id, $locus, $contig, $beg, $end, $len, $strand, $type, $entry, ($func || q()), $rest ];
	    }
	    else {
		warn "Skipping same-STOP TBL entry for $file, $key:\n"
		    , "$tbl->{$key}->[ENTRY]\n$entry\n\n";
	    }
	}
	else {
	    warn "INVALID ENTRY:\t$entry\n";
	}
    }
    
    return ($tbl, $num_pegs);
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
    my ($x, $a, $b) = @_;
    
    my (undef, undef, $A_contig, $A_beg, $A_end, $A_len, $A_strand) = $x->[$a];
    my (undef, undef, $B_contig, $B_beg, $B_end, $B_len, $B_strand) = $x->[$b];

    return (  ($A_contig cmp $B_contig) 
	   || (&FIG::min($A_beg, $A_end) <=> &FIG::min($B_beg, $B_end))
	   || ($B_len <=> $A_len)
	   || ($A_strand cmp $B_strand)
	   );
}
sub by_key {
    my ($x, $y) = @_;
    
    my ($X_contig, $X_strand, $X_end) = ($x =~ m/^([^\t]+)\t([+-])(\d+)/o);
    my ($Y_contig, $Y_strand, $Y_end) = ($y =~ m/^([^\t]+)\t([+-])(\d+)/o);
    
    return (  ($X_contig cmp $Y_contig) 
	   || ($X_end    <=> $Y_end)
	   || ($X_strand cmp $Y_strand)
	   );
}


sub write_summary {
    my ($old_pegs, $new_pegs, $identical, $same_stop, $differ, $short, $long, $added, $lost) = @_;
    
    print STDERR "old_num   = $old_pegs PEGs\n";
    print STDERR "new_num   = $new_pegs PEGs\n\n";
    
    print  STDERR '             Num    %_Old    %_New', qq(\n);
    printf STDERR "same_stop = %4u   %5.2f%%   %5.2f%%\n"
	, $same_stop, 100*$same_stop/$old_pegs, 100*$same_stop/$new_pegs;


    printf STDERR "added     = %4u   %5.2f%%   %5.2f%%\n"
	, $added, 100*$added/$old_pegs, 100*$added/$new_pegs;
    
    printf STDERR "lost      = %4u   %5.2f%%   %5.2f%%\n\n"
	, $lost, 100*$lost/$old_pegs, 100*$lost/$new_pegs;
    
    
    print  STDERR '             Num    %_Old    %_New  %_Common', qq(\n);
    printf STDERR "identical = %4u   %5.2f%%   %5.2f%%   %5.2f%%\n"
	, $identical, 100*$identical/$old_pegs, 100*$identical/$new_pegs, 100*$identical/$same_stop;;
    
    printf STDERR "differ    = %4u   %5.2f%%   %5.2f%%   %5.2f%%  %s\n"
	, $differ, 100*$differ/$old_pegs, 100*$differ/$new_pegs, 100*$differ/$same_stop, q((Includes Lost and Added));
    
    printf STDERR "short     = %4u   %5.2f%%   %5.2f%%   %5.2f%%\n"
	, $short, 100*$short/$old_pegs, 100*$short/$new_pegs, 100*$short/$same_stop;
    
    printf STDERR "long      = %4u   %5.2f%%   %5.2f%%   %5.2f%%\n\n"
	, $long, 100*$long/$old_pegs, 100*$long/$new_pegs, 100*$long/$same_stop;
    
    
    return 1;
}


sub write_summary_yaml {
    my ($fh, $old_pegs, $new_pegs, $identical, $same_stop, $differ, $short, $long, $added, $lost) = @_;

    my $dat = {
	old_num => $old_pegs,
	new_num => $new_pegs,
    };

    for my $what (qw(same_stop added lost identical differ short long))
    {
	my $val = eval "\$$what";
	$dat->{$what} = $val;
	$dat->{"${what}_pct_old"} = 100 * $val / $old_pegs;
	$dat->{"${what}_pct_new"} = 100 * $val / $new_pegs;
    }
    for my $what (qw(identical differ short long))
    {
	my $val = eval "\$$what";
	$dat->{"${what}_pct_common"} = 100 * $val / $same_stop;
    }

    print $fh Dump($dat);
    return 1;
}

__DATA__
