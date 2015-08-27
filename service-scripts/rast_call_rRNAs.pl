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

rast_call_rRNAs

=head1 SYNOPSIS

rast_call_rRNAs [--5S] [--SSU] [--LSU] [--input genome_file] [--output genome_file] [--url service-url] [< genome-file] [> genome-file]

=head1 DESCRIPTION

Find instances of ribosomal RNAs in the input genome.

Example:

    rast_call_rRNAs < input_genome > output_genome

Find and add all instances of rRNAs to the input genone typed object.

Example:

    rast_call_rRNAs --SSU --input input_genome --output output_genome

Find and add all instances of (just) SSU rRNAs to the input genone typed object,
getting the genome from a named file and writing the results to named file.

=head1 COMMAND-LINE OPTIONS

Usage: rast_call_rRNAs [options]  < input_genome_object     > output_genome_object
Usage: rast_call_rRNAs [options]  --input input_genome_file --output output_genome_file

    --5S                --- Find and add 5S rRNA genes (default is all rRNA classes)

    --LSU               --- Find and add LSU (large subunit) rRNA genes (default is all rRNA classes)

    --SSU               --- Find and add SSU (small subunit) rRNA genes (default is all rRNA classes)

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
use find_homologs;
use GenomeTypeObject;

my $help;
my $input_file;
my $output_file;
my $temp_dir;
my $remove_temp;

my $FiveS;
my $LSU;
my $SSU;
my $module;
my $id_prefix = 'rast|0';
my $id_server;

use Getopt::Long;
my $rc = GetOptions(
                     '5S'           => \$FiveS,
                     'help'         => \$help,
		     'id-prefix=s' => \$id_prefix,
		     'id-server=s' => \$id_server,
                     'input=s'      => \$input_file,
                     'LSU'          => \$LSU,
                     'module=s'     => \$module,
                     'output=s'     => \$output_file,
                     'SSU'          => \$SSU,
                     'tmpdir=s'     => \$temp_dir,
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

if (!$temp_dir)
{
    $temp_dir = &SeedAware::temporary_directory();
    $remove_temp = 1;
}

#  Default is all rRNA classes
$FiveS = $LSU = $SSU = 1 if ! ( $FiveS || $LSU || $SSU || $module );
my @modules = ();
push @modules, 'RNA_reps_5S_rRNA'  if $FiveS;
push @modules, 'RNA_reps_LSU_rRNA' if $LSU;
push @modules, 'RNA_reps_SSU_rRNA' if $SSU;
push @modules, $module             if $module;

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

my @results = ();
foreach my $module ( @modules )
{
    $module =~ s/\.pm$//;
    eval { require "$module.pm" };
    if ( $@ )
    {
        die "Failed in require '$module'.\n$@\n";
    }
    @RNA_reps::RNA_reps
        or die "No \@RNA_reps shared in '$module'.";

    my $params = { contigs => $contigs };
    $params->{ tmpdir} = $temp_dir  if $temp_dir;

    my $tag;
    {
        no warnings qw(once);

        $params->{ coverage }   =  $RNA_reps::min_coverage     ||  0.70;
        $params->{ descript }   =  $RNA_reps::assignment       || 'unnamed RNA';
        $params->{ extrapol }   =  $RNA_reps::max_extrapolate  || 20;
        $params->{ ftrtype }    =  $RNA_reps::feature_type     ||  undef;
        $params->{ identity }   =  $RNA_reps::min_identity     ||  0.50;
        $params->{ loc_format } =                                 'CBDL';
        $params->{ maxsplit }   =                                 20;
        $params->{ refseq }     = \@RNA_reps::RNA_reps;
        $params->{ seedexp }    =  $RNA_reps::max_expect       ||  1e-10;

        $tag                    =  $RNA_reps::tag              || $module;
    }

    my $event = {
	tool_name => $module,
	execute_time => scalar gettimeofday,
	parameters => [ map { $_, $params->{$_} } qw(coverage descript extrapol ftrtype identity loc_format maxsplit seedexp tag)],
	hostname => $hostname,
    };
    my $event_id = &GenomeTypeObject::add_analysis_event($genomeTO, $event);

    my @instances = find_homologs::find_nucleotide_homologs( $contigs, $params );
    foreach my $instance ( @instances )
    {
	$instance->{module} = $module;
	$instance->{type} ||= 'rna';
	$instance->{event_id} = $event_id;
    };
    push @results, @instances;
}

print STDERR Dumper(\@results) if $ENV{DEBUG};

foreach my $entry ( @results )
{
    &GenomeTypeObject::add_feature($genomeTO, {
	-annotation => "Add feature called by find_nucleotide_homologs based on data in $entry->{module}",
	-annotator  => 'find_nucleotide_homologs',
	-function   => $entry->{ definition },
	-id_client  => $id_client,
	-id_prefix  => $id_prefix,
	-location   => $entry->{ location },
	-type       => $entry->{ type },
	-analysis_event_id => $entry->{event_id},
    });
}

$genomeTO->destroy_to_file($out_fh);
close($out_fh);
if ($remove_temp)
{
    system("rm", "-rf", $temp_dir);
}

__DATA__
