#!/usr/bin/env perl
# This is a SAS Component
########################################################################
# Copyright (c) 2003-2013 University of Chicago and Fellowship
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

compare_gto_assigned_roles

=head1 SYNOPSIS

compare_gto_assigned_roles genome_A.gto genome_B.gto > comparison.tab

=head1 DESCRIPTION

Produces tabe-separated table of functional roles present in genome A, genome B, or both genomes.

Example:

    compare_gto_assigned_roles genome_A.gto genome_B.gto > comparison.tab

=head1 COMMAND-LINE OPTIONS

Usage: compare_gto_assigned_roles genome_A.gto genome_B.gto > comparison.tab

    -file1  --- Optional named-argument for genome-type-object file for genome A

    -file2  --- Optional named-argument for genome-type-object file for genome B

    -output --- Named-argument for output-file (output defaults to STDOUT)

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


use strict;
use warnings;

use SeedUtils;
use Data::Dumper;

use Bio::KBase::GenomeAnnotation::Client;
use JSON::XS;

my $help;
my $first_file;
my $second_file;
my $output_file;

my $trouble;
use Getopt::Long;
my $rc = GetOptions('help'        => \$help,
		    'file1=s'     => \$first_file,
		    'file2=s'     => \$second_file,
		    'output=s'    => \$output_file,
		    );

if (@ARGV == 2) {
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


my $features_with_role = &load( $first_file, $second_file);


my $out_fh;
if ($output_file) {
    open($out_fh, ">", $output_file) or die "Cannot open $output_file: $!";
} else { $out_fh = \*STDOUT; }



foreach my $role (sort keys %$features_with_role) {
    my @features = @ { $features_with_role->{$role} };
    my @in_A = $features[0] ? sort map { $_->{id} } @{$features[0]} : ();
    my @in_B = $features[1] ? sort map { $_->{id} } @{$features[1]} : ();
    
    my $type = '';
    if (@in_A > 0) { $type .= 'A'; }
    if (@in_B > 0) { $type .= 'B'; }
    
    print $out_fh (join("\t", ($type, $role, join(',', @in_A), join(',', @in_B))), "\n");
    
}
close($out_fh);

exit(0);


sub load {
    my @files = @_;
    my $json = JSON::XS->new;
    
    my $features_with_role = {};
    for (my $file_num=0; $file_num < @files; ++$file_num)
    {
	my $filename = $files[$file_num];
	
	my $fh;
	open($fh, "<", $filename) or die "Cannot open $filename: $!";
	
	my $gto;
	{
	    local $/;
	    undef $/;
	    my $gto_txt = <$fh>;
	    $gto = $json->decode($gto_txt);
	    foreach my $feature (@ { $gto->{features} }) {
		foreach my $role ( &SeedUtils::roles_of_function( $feature->{function} ) )
		{
		    push @ { $features_with_role->{$role}->[$file_num] }, $feature;
		}
	    }
	}
    }
    
    return $features_with_role;
}

__DATA__
