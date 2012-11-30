#updated 11/29/2012 - landml

use strict;
use Data::Dumper;
use Test::More tests => 36;
use Carp;
#use CDMI_APIClient;
#use CDMI_EntityAPIClient;
use Bio::KBase::CDMI::Client;
use lib "t/server-tests";
use CDMITestConfig qw(getHost getPort);


#my $cdmie = CDMI_EntityAPIClient->new("http://140.221.92.46:5000");
#my $cdmi = CDMI_APIClient->new("http://140.221.92.46:5000");
# MAKE A CONNECTION (DETERMINE THE URL TO USE BASED ON THE CONFIG MODULE)
my $host=getHost(); my $port=getPort();
print "-> attempting to connect to:'".$host.":".$port."'\n";
my $cdmi  = Bio::KBase::CDMI::Client->new($host.":".$port);
my $cdmie= Bio::KBase::CDMI::Client->new($host.":".$port);

# fids_to_* tests (kkeller)
# general plan: test a good fid and a bad fid

my $exampleFid= {
	fid	=>	'kb|g.3093.peg.1000',
	fids_to_protein_sequences	=>	{
		'kb|g.3093.peg.1000'	=>	'MAKKSSIAKQKRREKIVNRNWEKRQELKKKVSDINLSEEERLEASIQLNKMRRDTSPVRLRNRCQITGRCRGYLSKFKVSRLVFREMASIGMIPGVTKSSW',
		},
	fids_to_dna_sequences	=>	{
		'kb|g.3093.peg.1000'	=>	'atggctaaaaaatcatcgattgcaaaacagaagcgtcgcgaaaaaatcgtcaatcgcaactgggaaaaacgtcaagagctgaagaaaaaagtcagcgacattaatttgagcgaagaagagcgtctggaagctagcatccagctgaataaaatgaggcgcgacacgtctccggttcgtctgcgcaaccgctgccaaatcacaggccgctgcagaggctacttgagcaaattcaaagtttctaggcttgtattccgagagatggcttccataggaatgattcctggagtcacaaaatctagctggtaa',
		},
	fids_to_proteins	=>	{
		'kb|g.3093.peg.1000'	=>	'91a4aa54c23c2385e6d13b18d58dd71e',
		},
	fids_to_genomes		=>	'kb|g.3093',
	fids_to_feature_data	=>	{
		'kb|g.3093.peg.1000' => {
			'feature_id' => 'kb|g.3093.peg.1000',
			'feature_length' => '306',
			'feature_publications' => [],
			'genome_name' => 'Waddlia chondrophila WSU 86-1044',
			'feature_function' => 'SSU ribosomal protein S14p (S29e) ## Zinc-independent',
			}
		},
	# getting empty hash
	fids_to_protein_families	=>	{},
	fids_to_functions	=>	{
		'kb|g.3093.peg.1000' => 'SSU ribosomal protein S14p (S29e) ## Zinc-independent'
		},
	fids_to_locations	=>	{
			'kb|g.3093.peg.1000' => [
				[ 'kb|g.3093.c.0', 873357, '-', '306' ],
			],
		},
	fids_to_roles	=>	{
			'kb|g.3093.peg.1000' => [
				'SSU ribosomal protein S14p (S29e)',
			],
		},
	fids_to_subsystems	=>	{
			'kb|g.3093.peg.1000' => [
				'271-Bsub', 'COG0523', 'Ribosome SSU bacterial'
			],
		},
	fids_to_co_occurring_fids	=>	{
			'kb|g.3093.peg.1000' => [
				[ 'kb|g.3093.peg.1667', '8' ], [ 'kb|g.3093.peg.1103', '8' ], [ 'kb|g.3093.peg.1022', '8' ], [ 'kb|g.3093.peg.1324', '8' ],
			],
		},
};


my $exampleBadFid={
	fid	=>	'blah',
	fids_to_feature_data	=>	{
		'blah' => {
			'feature_id' => 'blah',
			'feature_length' => undef,
			'feature_publications' => [],
			'genome_name' => undef,
			'feature_function' => '',
			}
		},
	fids_to_protein_sequences	=>	{ },
	fids_to_proteins	=>	{ },
	fids_to_dna_sequences	=>	{ 'blah' => '' },
	fids_to_protein_families	=>	{},
	fids_to_functions	=>	{
		'blah' => undef,
		},
	fids_to_locations	=>	{
		'blah'	=>	[],
		},
	fids_to_roles	=>	{},
	fids_to_subsystems	=>	{},
	fids_to_co_occurring_fids	=>	{},
};


my @allFidMethods=qw(
fids_to_annotations
fids_to_co_occuring_fids
fids_to_coexpressed_fids
fids_to_dna_sequences
fids_to_feature_data
fids_to_functions
fids_to_genomes
fids_to_literature
fids_to_locations
fids_to_protein_families
fids_to_protein_sequences
fids_to_proteins
fids_to_regulons
fids_to_roles
fids_to_subsystem_data
fids_to_subsystems
);

#my @fidMethods=@fidEmptyHashMethods;
#my @fidMethods=@fidGoodFidsNoDataMethods;

# these methods seem to work correctly in tests
my @fidMethods=qw(
fids_to_dna_sequences
fids_to_feature_data
fids_to_protein_sequences
fids_to_proteins
fids_to_functions
fids_to_locations
fids_to_roles
fids_to_subsystems
fids_to_co_occurring_fids
);

# these methods don't return data for the example fid
# some might be legitimately empty, others (fids_to_genomes) probably shouldn't be
# literature might be a hard one, need to find a fid with papers
my @fidGoodFidsNoData=qw(
fids_to_genomes
fids_to_annotations
fids_to_protein_families
fids_to_literature
fids_to_regulons
fids_to_subsystem_data
fids_to_coexpressed_fids
);

foreach my $method (@fidMethods)
{
	my $goodResult;
	eval { $goodResult=$cdmi->$method([$exampleFid->{fid}]); };
	is($@,'',"method $method call for known fid succeeded");
	is_deeply($goodResult,$exampleFid->{$method} ,"method $method for known fid matched known hash");
#	warn Dumper($goodResult);
#	warn Dumper($exampleFid->{$method});
	my $badResult;
	eval { $badResult=$cdmi->$method([$exampleBadFid->{fid}]); };
	is($@,'',"method $method call for bad fid succeeded");
	# another way of testing for an empty hashref
	#is_deeply($badResult,{},"$method for bad fid");
	# should be no keys in this result set
	is_deeply($badResult,$exampleBadFid->{$method},"method $method for bad fid returned expected hash");
#	warn Dumper($badResult);
}
