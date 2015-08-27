#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use SeedUtils;

use File::Slurp;
use Time::HiRes 'gettimeofday';
use File::Temp;
use File::Basename;
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

use Getopt::Long;
my $rc = GetOptions('help'        => \$help,
		    'input=s'     => \$input_file,
		    'output=s'    => \$output_file,
		    'tmpdir=s'    => \$temp_dir,
		    'id-prefix=s' => \$id_prefix,
		    'id-server=s' => \$id_server,
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

$genomeTO = GenomeTypeObject->initialize($genomeTO);
my $seed_dir = $genomeTO->write_temp_seed_dir({ map_CDS_to_peg => 1 });

#
# Find our KBase top. In a hacked SEED environment KB_RUNTIME might not be set so find it based on
# where all_entities_Genome is found.
#

my $runtime = $ENV{KB_RUNTIME};
if (!$runtime)
{
    for my $p (split(/:/, $ENV{PATH}))
    {
	if (-d "$p/../phispy")
	{
	    $runtime = dirname($p);
	    last;
	}
    }
    $ENV{R_LIBS} = "$runtime/lib/R/library" if $runtime;
}
if (!$runtime)
{
    $runtime = "/vol/kbase/runtime";
    $ENV{R_LIBS} = "$runtime/lib/R/library";
}

if (! -d $runtime)
{
    die "Cannot find KB runtime\n";
}
my $phispy = "$runtime/phispy";

my $sci = $genomeTO->{scientific_name};

my $training_set;
my $default_training_set;
open(T, "<", "$phispy/data/trainingGenome_list.txt") or die "Cannot open $phispy/data/trainingGenome_list.txt: $!";
while (<T>)
{
    chomp;
    my($id, $file, $genome, $mult) = split(/\t/);
    if ($genome eq 'Generic Test Set')
    {
	$default_training_set = $id;
    }
    if ($sci =~ /^$genome\b/)
    {
	$training_set = $id;
	last;
    }
}
$training_set = $default_training_set unless defined($training_set);

my $out = File::Temp->newdir(undef, CLEANUP => 1);

$ENV{PATH} = "$runtime/bin:$ENV{PATH}";

my @cmd = ("$runtime/bin/python", "$phispy/phiSpy.py", "-i", "" . $seed_dir, "-o", "" . $out, "-t", $training_set);
my $cmd = "@cmd > $out/phispy.stdout 2> $out/phispy.stderr";
print STDERR "Run $cmd\n";
$rc = system($cmd);
my $err = read_file("$out/phispy.stderr");
if ($rc != 0)
{
    die "Error $rc running @cmd\n$err";
}

$id_prefix = $genomeTO->{id} unless $id_prefix;

my $type = 'prophage';
my $typed_prefix = join(".", $id_prefix, $type);

my $hostname = `hostname`;
chomp $hostname;

my $event = {
    tool_name => "phispy",
    execute_time => scalar gettimeofday,
    parameters => \@cmd,
    hostname => $hostname,
};
my $event_id = &GenomeTypeObject::add_analysis_event($genomeTO, $event);

open(O, "<", "$out/prophage.tbl") or die "Cannot open $out/prophage.tbl: $!\n";

while (<O>)
{
    chomp;
    my($xid, $loc) = split(/\t/);

    my($contig, $beg, $end) = $loc =~ /^(\S+)_(\d+)_(\d+)$/;

    my $len = $end - $beg + 1;
    if ($contig)
    {
	&GenomeTypeObject::add_feature($genomeTO, {
	    -id_client => $id_client,
	    -id_prefix => $id_prefix,
	    -type       => $type,
	    -location   => [[ $contig, $beg, '+', $len ]],
	    -annotator  => 'phispy',
	    -annotation => 'Add feature called by phispy',
	    -analysis_event_id   => $event_id,
	    -function => 'phiSpy-predicted prophage',
	});
    }
}

$genomeTO->destroy_to_file($out_fh);
close($out_fh);
