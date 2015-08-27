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
use Bio::KBase::IDServer::Client;

my $help;
my $input_file;
my $output_file;
my $temp_dir;
my $id_prefix;
my $id_server;
my $id_type = "CDS";

use Getopt::Long;
my $rc = GetOptions('help'        => \$help,
		    'input=s'     => \$input_file,
		    'output=s'    => \$output_file,
		    'tmpdir=s'    => \$temp_dir,
		    'id-prefix=s' => \$id_prefix,
		    'id-server=s' => \$id_server,
		    'id-type=s'   => \$id_type,
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

my $params = { -contigs      => $contigs,
	       -genetic_code => $genetic_code,
	       };
if ($temp_dir) { $params->{-tmpdir} = $temp_dir; }
		   
my($result, $event) = &Prodigal::run_prodigal($params);

my $event_id = &GenomeTypeObject::add_analysis_event($genomeTO, $event);

$id_prefix = $genomeTO->{id} unless $id_prefix;

my $count = @$result;
my $type = 'CDS';
my $typed_prefix = join(".", $id_prefix, $id_type);
my $cur_id_suffix = $id_client->allocate_id_range($typed_prefix, $count);

foreach my $entry (@$result) {
    print STDERR (&SeedUtils::flatten_dumper($entry), "\n") if $ENV{DEBUG};
    my ($contig, $beg, undef, $strand, $length, $translation) = @$entry;

    my $id = join(".", $typed_prefix, $cur_id_suffix);
    $cur_id_suffix++;
    &GenomeTypeObject::add_feature($genomeTO, { -id         => $id,
						-type       => 'CDS',
						-location   => [[ $contig, $beg, $strand, $length ]],
						-annotator  => 'prodigal',
						-annotation => 'Add feature called by PRODIGAL',
						-analysis_event_id   => $event_id,
						    -protein_translation => $translation,
					    }
				   );
}

$genomeTO->destroy_to_file($out_fh);
close($out_fh);
