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

rast_annotate_proteins_similarity

=head1 SYNOPSIS

rast_annotate_proteins_similarity [--input genome_file] [--output genome_file] [--url service-url] [< genome-file] [> genome-file]   

=head1 DESCRIPTION

Annotate proteins in the genome object based on similarity to a set of predefined NR databases.

=head1 COMMAND-LINE OPTIONS

Usage: rast_annotate_proteins_similarity  < input_genome_object  > output_genome_object
Usage: rast_annotate_proteins_similarity --input input_genome_object --output output_genome_object

    --input      --- Read input genome-typed object from file instead of STDIN

    --output     --- Read output genome-typed object from file outstead of STDOUT

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
use DB_File;

use IDclient;
use GenomeTypeObject;
use ProtSims;

my $iden_thresh = 50;
my $evalue_thresh = 1e-5;

my $hypo_only;
my $help;
my $input_file;
my $output_file;
my $remove_temp;

my $id_prefix = 'rast|0';
my $id_server;
my $nr_dir;

use Getopt::Long;
my $rc = GetOptions('help'         => \$help,
		    'input=s' 	   => \$input_file,
		    'output=s'     => \$output_file,
		    'nr-dir=s'     => \$nr_dir,
		    'id_prefix=s'  => \$id_prefix,
		    'id-prefix=s'  => \$id_prefix,
		    'id-server=s'  => \$id_server,
		    'hypothetical_only|H' => \$hypo_only,
		    );


if (not ($help || $nr_dir)) {
    $rc ||= 1;
    die "ERROR: NR directory not specified\n";
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

my $in_fh;
if ($input_file) {
    open($in_fh, "<", $input_file) or die "Cannot open $input_file: $!";
} else { $in_fh = \*STDIN; }

my $out_fh;
if ($output_file) {
    open($out_fh, ">", $output_file) or die "Cannot open $output_file: $!";
} else { $out_fh = \*STDOUT; }

my $genomeTO = GenomeTypeObject->create_from_file($in_fh);
$genomeTO->update_indexes();

my $id_client;
if ($id_server)
{
    $id_client = Bio::KBase::IDServer::Client->new($id_server);
}
else
{	
    $id_client = IDclient->new($genomeTO);
}


#
# Create event for logging in genome object.
#
my $hostname = `hostname`;
chomp $hostname;

#
# Remove this so we don't pollute the log.
#

my $event = {
    tool_name => "annotate_proteins_similarity",
    execute_time => scalar gettimeofday,
    parameters => [ $nr_dir ],
    hostname => $hostname,
};
my $event_id = GenomeTypeObject::add_analysis_event($genomeTO, $event);

#
# Tie the indexes.
#

my %genus_index;

tie %genus_index, 'DB_File', "$nr_dir/genus_index.btree", O_RDONLY, 0644, $DB_BTREE or die "Cannot tie $nr_dir/genus_index.btree: $!";
    
#
# Determine set of NR files to examine.
#

my $genus = $genomeTO->{scientific_name};
$genus =~ s/\s.*$//;

my @list = ($genus);
my %seen = ( $genus => 1 );

if (ref($genomeTO->{close_genomes}))
{
    for my $close (@{$genomeTO->{close_genomes}})
    {
	my $g = $close->{genome_name};
	$g =~ s/\s.*$//;
	if (!$seen{$g})
	{
	    push(@list, $g);
	    $seen{$g}++;
	}
    }
}

    
my %to_annotate;

for my $feature ($genomeTO->features)
{
    next if !$feature->{protein_translation};
    
    if ($hypo_only) {
	my $f = $feature->{function};
	if (defined($f) && $f ne '' && $f !~ /^\s*hypothetical\s+protein\s*$/i) {
	    next;
	}
    }

    my $ent = [$feature->{id}, undef, $feature->{protein_translation}];
    $to_annotate{$feature->{id}} = $ent;
}


while (%to_annotate && @list)
{
    my $genus = shift @list;
    my $file = $genus_index{lc($genus)};
    if (!$file)
    {
	warn "No file for genus $genus\n";
	next;
    }
    my @to_annotate = values %to_annotate;
    my $n = @to_annotate;
    $file = "$nr_dir/$file";
    print STDERR "Annotate $n proteins with $file\n";

    my %function_index;
    tie %function_index, 'DB_File', "$file.btree", O_RDONLY, 0644, $DB_BTREE or die "Cannot tie $file.btree $!";

    my @res = ProtSims::blastP(\@to_annotate, $file, 0);

    #
    # Results are returned in score order for a given search peg (id1)
    # so we take the first one per group.
    #
    my $last = '';
    for my $ent (@res)
    {
	my $id = $ent->id1;
	next if $id eq $last;
	if ($ent->psc <= $evalue_thresh && $ent->iden >= $iden_thresh)
	{
	    $last = $id;

	    my $hit = $ent->id2;
	    my $func = $function_index{$hit};

	    if (defined($func) && $func)
	    {
			
		my ($fstr, undef, $gstr) = $func =~ /^(.*?)(\s+\[(.*)\]\s*)?$/;
		$fstr =~ s/\s*$//;

		if ($fstr =~ /^hypothetical\s*protein/i)
		{
		    warn "Skipping hypothetical annotation $func\n";
		    next;
		}
		delete $to_annotate{$id};

		print STDERR "$id\t$hit\t$fstr\t$gstr\n";
		
		$genomeTO->update_function("annotate_proteins_similarity", $id, $fstr, $event_id);
		my $feature = $genomeTO->find_feature($id);
		if (ref($feature) eq 'HASH')
		{
#		    $feature->{ quality }->{ hit_count } = $score;
		    my $annotation = ["Function $fstr was found in genome $gstr feature $hit", "annotate_proteins_similarity", scalar gettimeofday, $event_id];
		    push(@{$feature->{annotations}}, $annotation);
		}
	    }
	}
    }

    untie %function_index;
}

$genomeTO->prepare_for_return();
my $j = JSON::XS->new->pretty(1);
print $out_fh $j->encode($genomeTO);

__DATA__
