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

rast_call_special_proteins

=head1 SYNOPSIS

rast_call_special_proteins (--seleno | --pyrro) [--input genome_file] [--output genome_file] [--url service-url] [< genome-file] [> genome-file]   

=head1 DESCRIPTION

Find instances of unusual but well-preserved classes of protein-encoding genes
that have abnormal translation rules, such as selenoproteins or pyrrolysoproteins.

Example:

    rast_call_special_proteins --seleno < input_genome > output_genome_with_selenoproteins_called

Find and add all instances of the known classes of selenocysteine-containing protein-encoding genes
in the input genome-typed object file, and write the enhanced genome-typed object to output.

Example:

    rast_call_special_proteins --pyrro --input input_genome --output output_genome_with_pyrrolysoproteins_called

Same as above, but looking for pyrrolysoproteins, and using named file arguments instead of redirection.

=head1 COMMAND-LINE OPTIONS

Usage: rast_call_special_proteins (--seleno | --pyrro)  < input_genome_object  > output_genome_object
Usage: rast_call_special_proteins (--seleno | --pyrro)  --input input_genome_object --output output_genome_object

    --seleno     --- Find and add CDSs encoding selenocysteine-containing proteins

    --pyrro      --- Find and add CDSs encoding pyrrolysine-containing proteins

    --input      --- Read input genome-typed object from file instead of STDIN

    --output     --- Read output genome-typed object from file outstead of STDOUT

    --tmpdir     --- Use named temporary-file directory instead of the default temporary directory

    --id_prefix  --- Use the specified feature prefix instead of the defult of 'rast|0'

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


use strict;
use warnings;
use Data::Dumper;
use SeedUtils;
use SeedAware;

use Bio::KBase::GenomeAnnotation::Client;
use Bio::KBase::IDServer::Client;
use JSON::XS;
use Time::HiRes 'gettimeofday';

use IDclient;
use find_special_proteins;
use GenomeTypeObject;

my $help;
my $input_file;
my $output_file;
my $temp_dir;
my $remove_temp;

my $seleno;
my $pyrro;
my $id_prefix = 'rast|0';
my $id_server;

use Getopt::Long;
my $rc = GetOptions('help'         => \$help,
		    'input=s' 	   => \$input_file,
		    'output=s'     => \$output_file,
		    'tmpdir=s'     => \$temp_dir,
		    'seleno'       => \$seleno,
		    'pyrro'        => \$pyrro,
		    'id_prefix=s'  => \$id_prefix,
		    'id-prefix=s'  => \$id_prefix,
		    'id-server=s'  => \$id_server,
		    );


if (not ($help || $seleno || $pyrro)) {
    $rc ||= 1;
    warn "ERROR: No special-protein class selected\n";
}    

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

if (!$temp_dir)
{
    $temp_dir = &SeedAware::temporary_directory();
    $remove_temp = 1;
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

if ($genomeTO->{domain} !~ m/^([ABV])/o) {
    die "Invalid domain: \"$genomeTO->{domain}\"";
}

my $id_client;
if ($id_server)
{
    $id_client = Bio::KBase::IDServer::Client->new($id_server);
}
else
{	
    $id_client = IDclient->new($genomeTO);
}

my $genetic_code = $genomeTO->{genetic_code};
my $contigs      = [ map { [ $_->{id}, undef, $_->{dna} ] }  @ { $genomeTO->{contigs} } ];

my $params = { contigs      => $contigs,
};
if ($temp_dir) { $params->{-tmpdir} = $temp_dir; }

my @results = ();

my $qual;

if ($seleno) {
    push @results, &find_special_proteins::find_selenoproteins( $params );
    $qual = { selenoprotein => 1 };
}

if ($pyrro) {
    $params->{ pyrrolysine } = 1;
    push @results, &find_special_proteins::find_selenoproteins( $params );
    $qual = { pyrrolysylprotein => 1 };
}
print STDERR Dumper(\@results) if $ENV{DEBUG};

#
# Create event for logging in genome object.
#
my $hostname = `hostname`;
chomp $hostname;

#
# Remove this so we don't pollute the log.
#
delete $params->{contigs};
my $event = {
    tool_name => "find_special_proteins",
    execute_time => scalar gettimeofday,
    parameters => [ %$params ], 
    hostname => $hostname,
};
my $event_id = GenomeTypeObject::add_analysis_event($genomeTO, $event);

foreach my $entry (@results) {
    my ($contig, $beg, $end, $strand) = &SeedUtils::parse_location( $entry->{location} );
    my $length = 1 + abs($end - $beg);
    
    my $function    = $entry->{reference_def};
    my $translation = $entry->{sequence};
    
    &GenomeTypeObject::add_feature($genomeTO, { -id_client  => $id_client,
						-id_prefix  => $id_prefix,
						-type       => 'CDS',
						-location   => [[ $contig, $beg, $strand, $length ]],
						-annotator  => 'find_special_proteins',
						-annotation => 'Add feature called by find_special_proteins',
						-function   => $function,
						-protein_translation => $translation,
						-analysis_event_id => $event_id,
						-quality_measure => $qual,
				   }
	);
}

$genomeTO->destroy_to_file($out_fh);
close($out_fh);
if ($remove_temp)
{
    system("rm", "-rf", $temp_dir);
}

__DATA__
