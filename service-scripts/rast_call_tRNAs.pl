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

rast_call_RNAs

=head1 SYNOPSIS

rast_call_RNAs [--input genome_file] [--output genome_file] [--url service-url] [< genome-file] [> genome-file]   

=head1 DESCRIPTION

Find instances of tRNAs in a genome-type object.

Example:

    rast_call_tRNAs < input_genome > output_genome_with_tRNAs_called

=head1 COMMAND-LINE OPTIONS

Usage: rast_call_tRNAs  < input_genome_object  > output_genome_object
Usage: rast_call_tRNAs  --input input_genome_object --output output_genome_object

    --input      --- Read input genome-typed object from file instead of STDIN

    --output     --- Read output genome-typed object from file outstead of STDOUT

    --tmpdir     --- Use named temporary-file directory instead of the default temporary directory

    --id_prefix  --- Use the specified feature prefix instead of the default of 'rast|0'

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


use strict;
use warnings;
use Data::Dumper;

use gjoseqlib;
use Bio::KBase::GenomeAnnotation::Client;
use Bio::KBase::IDServer::Client;
use JSON::XS;

use IDclient;
use Find_RNAs;
use GenomeTypeObject;

my $help;
my $input_file;
my $output_file;
my $temp_dir;
my $id_prefix = 'rast|0';
my $id_server;

use Getopt::Long;
my $rc = GetOptions('help'        => \$help,
		    'input=s'     => \$input_file,
		    'output=s'    => \$output_file,
		    'tmpdir=s'    => \$temp_dir,
		    'id-prefix=s' => \$id_prefix,
		    'id-server=s' => \$id_server,
		    );

if (!$rc || $help || @ARGV != 0) {
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

my $in_fh;
if ($input_file) {
    open($in_fh, "<", $input_file) or die "Cannot open $input_file: $!";
} else { $in_fh = \*STDIN; }

my $out_fh;
if ($output_file) {
    open($out_fh, ">", $output_file) or die "Cannot open $output_file: $!";
} else { $out_fh = \*STDOUT; }

my $json = JSON::XS->new;

my $genomeTO = GenomeTypeObject->create_from_file($in_fh);

my $id_client;
if ($id_server)
{
    $id_client = Bio::KBase::IDServer::Client->new($id_server);
}
else
{	
    $id_client = IDclient->new($genomeTO);
}



#...Extract genome-object fields...
my ($genus, $species) = (($genomeTO->{scientific_name} =~ m/^(\S+)\s+(\S+)/o)
			 ? ($1, $2)
			 : qw(Unknown sp.)
			 );

my $domain = (($genomeTO->{domain} =~ m/^([ABEV])/io)
	      ? uc($1)
	      : (warn(qq(Unrecognized domain: \"$genomeTO->{domain}\")) && q(U))
	      );

my $contigs = [ map { [ $_->{id}, undef, $_->{dna} ] }  @ { $genomeTO->{contigs} } ];

my $params = { -orgID   => $genomeTO->{id},
	       -rnas    => q(tRNA),
	       -genus   => $genus,
	       -species => $species,
	       -domain  => $domain,
	       -contigs => $contigs,
	   };
if ($temp_dir) { $params->{-tmpdir} = $temp_dir; }
	
	   
#...Run the `search_for_rnas` wrapper...
my($result, $event) = Find_RNAs::find_rnas($params);
my $event_id = &GenomeTypeObject::add_analysis_event($genomeTO, $event);

foreach my $entry (@$result) {
    my (undef, $contig, $beg, $end, $func) = @$entry;
    
    my $length = 1 + abs($end - $beg);
    my $strand = ($beg < $end) ? q(+) : q(-);
    
    &GenomeTypeObject::add_feature($genomeTO, { -id_client  => $id_client,
						-id_prefix  => $id_prefix,
						-type       => 'rna',
						-location   => [[ $contig, $beg, $strand, $length ]],
						-function   => $func,
						-annotator  => 'search_for_rnas',
						-annotation => 'Add feature called by search_for_rnas',
						-analysis_event_id => $event_id,
					    }
				   );
}

$genomeTO->destroy_to_file($out_fh);
close($out_fh);

__DATA__
