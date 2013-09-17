#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use SeedUtils;

use Bio::KBase::GenomeAnnotation::Client;
use JSON::XS;

use IDclient;
use Prodigal;
use GenomeTypeObject;

my $help;
my $input_file;
my $output_file;
my $temp_dir;

use Getopt::Long;
my $rc = GetOptions('help'      => \$help,
		    'input=s' 	=> \$input_file,
		    'output=s'  => \$output_file,
		    'tmpdir=s'  => \$temp_dir,
		    );

if (!$rc || $help || @ARGV != 0) {
    die "Bad ARGV";
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

my $genomeTO;
{
    local $/;
    undef $/;
    my $genomeTO_txt = <$in_fh>;
    $genomeTO = $json->decode($genomeTO_txt);
}


if ($genomeTO->{domain} !~ m/^([ABV])/o) {
    die "Invalid domain: \"$genomeTO->{domain}\"";
}


my $id_server = IDclient->new($genomeTO);
my $genetic_code = $genomeTO->{genetic_code};
my $contigs      = [ map { [ $_->{id}, undef, $_->{dna} ] }  @ { $genomeTO->{contigs} } ];

my $params = { -contigs      => $contigs,
	       -genetic_code => $genetic_code,
	       };
if ($temp_dir) { $params->{-tmpdir} = $temp_dir; }
		   
my $result = &Prodigal::run_prodigal($params);


foreach my $entry (@$result) {
    print STDERR (&SeedUtils::flatten_dumper($entry), "\n");
    my ($contig, $beg, undef, $strand, $length, $translation) = @$entry;
    
    &GenomeTypeObject::add_feature($genomeTO, { -id_server  => $id_server,
						-id_prefix  => 'rast|0',
						-type       => 'CDS',
						-location   => [[ $contig, $beg, $strand, $length ]],
						-annotator  => 'prodigal',
						-annotation => 'Add feature called by PRODIGAL',
					    }
				   );
}

$json->pretty(1);
print $out_fh $json->encode($genomeTO);
close($out_fh);
