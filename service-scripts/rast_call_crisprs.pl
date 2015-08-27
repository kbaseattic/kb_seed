#!/usr/bin/env perl
#
# This is a SAS Component
#
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

rast_call_crisprs

=head1 SYNOPSIS

rast_call_crisprs [--input genome_file] [--output genome_file] [--url service-url] [< genome-file] [> genome-file]

=head1 DESCRIPTION

Find instances of CRISPRs in the input genome.

Example:

    rast_call_crisprs < input_genome > output_genome

Find and add all instances of rRNAs to the input genone typed object.

Example:

    rast_call_crisprs --input input_genome --output output_genome

Find and add all instances of crisprs to the input genone typed object,
getting the genome from a named file and writing the results to named file.

=head1 COMMAND-LINE OPTIONS

Usage: rast_call_crisprs [options]  < input_genome_object     > output_genome_object
Usage: rast_call_crisprs [options]  --input input_genome_file --output output_genome_file

    --id_prefix prefix  --- Use the specified feature prefix instead of the defult of 'rast|0'
    --input filename    --- Read input genome-typed object from file instead of STDIN
    --module modulename --- Use RNA reference sequences defined in the named perl module
    --output filename   --- Read output genome-typed object from file outstead of STDOUT
    --tmpdir directory  --- Use named temporary-file directory instead of the default

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
use GenomeTypeObject;
use crispr;

my $help;
my $input_file;
my $output_file;

my $id_prefix = 'rast|0';
my $id_server;

use Getopt::Long;
my $rc = GetOptions(
                     'help'         => \$help,
		     'id-prefix=s' => \$id_prefix,
		     'id-server=s' => \$id_server,
                     'input=s'      => \$input_file,
                     'output=s'     => \$output_file,
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
close($in_fh) if $input_file;

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

my $contigs   = [ map { [ $_->{id}, '', $_->{dna} ] }  @{ $genomeTO->{contigs} } ];

my $hostname = `hostname`;
chomp $hostname;

my $params = {  };
my $event = {
    tool_name => 'rast_call_crisprs',
    execute_time => scalar gettimeofday,
    parameters => [ map { $_, $params->{$_} } sort keys %$params],
    hostname => $hostname,
};
my $event_id = &GenomeTypeObject::add_analysis_event($genomeTO, $event);

my $type_array  = "crispr_array";
my $type_repeat = "crispr_repeat";
my $type_spacer = "crispr_spacer";
my $tool = "crispr::find_crisprs";

my @instances = crispr::find_crisprs($contigs, $params);
for my $inst (@instances)
{
    my($loc, $consensus, $repeats, $spacers) = @$inst;

    &GenomeTypeObject::add_feature($genomeTO, {
	-annotation => "Add feature called by crispr::find_crisprs",
	-function => "CRISPR region with repeat $consensus",
	-annotator  => $tool,
	-id_client  => $id_client,
	-id_prefix  => $id_prefix,
	-location   => $loc,
	-type       => $type_array,
	-analysis_event_id => $event_id,
    });

    for my $repeat (@$repeats)
    {
	my($loc, $repeat_seq) = @$repeat;
	&GenomeTypeObject::add_feature($genomeTO, {
	    -annotation => "Add feature called by crispr::find_crisprs",
	    -function => "CRISPR repeat with sequence $repeat_seq",
	    -annotator  => $tool,
	    -id_client  => $id_client,
	    -id_prefix  => $id_prefix,
	    -location   => $loc,
	    -type       => $type_repeat,
	    -analysis_event_id => $event_id,
	});
    }
    for my $spacer (@$spacers)
    {
	my($loc, $spacer_seq) = @$spacer;
	&GenomeTypeObject::add_feature($genomeTO, {
	    -annotation => "Add feature called by crispr::find_crisprs",
	    -function => "CRISPR spacer",
	    -annotator  => $tool,
	    -id_client  => $id_client,
	    -id_prefix  => $id_prefix,
	    -location   => $loc,
	    -type       => $type_spacer,
	    -analysis_event_id => $event_id,
	});
    }
}

$genomeTO->destroy_to_file($out_fh);
close($out_fh);

__DATA__
