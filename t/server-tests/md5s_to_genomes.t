#!/usr/bin/env perl

#update 11/29/2012 - landml

use strict;
use warnings;

use Test::More;

#use CDMI_APIClient;
#use CDMI_EntityAPIClient;
use Bio::KBase::CDMI::Client;
use lib "t/server-tests";
use CDMITestConfig qw(getHost getPort);

############
#
# CONFIGURE THESE
#
#my $url         = 'http://140.221.92.46:5000';
my $test_method = 'md5s_to_genomes';

#my $cdmi = CDMI_APIClient->new($url);
#my $cdmie = CDMI_EntityAPIClient->new($url);

# MAKE A CONNECTION (DETERMINE THE URL TO USE BASED ON THE CONFIG MODULE)
my $host=getHost(); my $port=getPort();
print "-> attempting to connect to:'".$host.":".$port."'\n";
my $cdmi  = Bio::KBase::CDMI::Client->new($host.":".$port);
my $cdmie= Bio::KBase::CDMI::Client->new($host.":".$port);

#
# CONFIGURE THIS TO LOAD YOUR DATA
#
my $all_available_data = $cdmie->all_entities_Genome(0,100,['id']);

my @random_subset = ();
my @all_available_keys = keys %$all_available_data;
my $num_sample = int rand(@all_available_keys);

for (0..$num_sample) {
    push @random_subset, $all_available_data->{ $all_available_keys[int rand @all_available_keys] }->{'id'};
}

#
# SAMPLE DATA IS OPTIONAL
#

my $sample_data = [
	{'expected' => ['kb|g.3093'], 'id' => '94518bb814a8a79e60637ee6f92ce3bd'},
	{'expected' => ['kb|g.5458'], 'id' => '15ade9db34c4a556f56aa39805192a9f'},
	{'expected' => ['kb|g.1554'], 'id' => '4a1b448b1dc98b56dec5dcb092d49f4d'},
	{'expected' => ['kb|g.2620'], 'id' => 'dc4fb05c22adbc14908f9c857a2ad9f5'},
];

#
#
#
############

plan('tests' =>
      3 * (scalar keys %$all_available_data)
    + 2 * @$sample_data
    + 1 * @random_subset
    + 9);

foreach my $datum (keys %$all_available_data) {
    my $results = $cdmi->$test_method( [ $datum ] );
    ok($results, "Got results for $datum");
    is(scalar keys %$results, 1, "Only retrieved results for $datum");
    ok($results->{$datum}, "Retrieved results for $datum");
}

foreach my $sample (@$sample_data) {
    ok($sample->{'id'}, "Found known sample $sample->{'id'}");
    $sample->{'results'} = $cdmi->$test_method( [ $sample->{'id'} ] )->{ $sample->{'id'} };
    is_deeply($sample->{'results'}, $sample->{'expected'}, "Results match expectations");
}

#give it a few at once.
my $results = $cdmi->$test_method(\@random_subset);
foreach my $datum (@random_subset) {
    my $single_results = $cdmi->$test_method( [ $datum ] );
    is_deeply($single_results->{$datum}, $results->{$datum}, "Multi-results matches single results for $datum");
}
is_deeply($results->{$sample_data->[0]->{'id'}}, $sample_data->[0]->{'contigs'}, "Correct multi-results for $sample_data->[0]->{'id'}");
is_deeply($results->{$sample_data->[1]->{'id'}}, $sample_data->[1]->{'contigs'}, "Correct multi-results for $sample_data->[1]->{'id'}");

#ok. Now let's try to break it with invalid data.
eval {$cdmi->$test_method};
isnt($@, '', "Must give $test_method an arrayref (not scalar)");

eval {$cdmi->$test_method($sample_data->[0]->{'id'}, $sample_data->[1]->{'id'})};
isnt($@, '', "Must give $test_method an arrayref (not array)");

eval {$cdmi->$test_method('genome' => $sample_data->[0]->{'id'})};
isnt($@, '', "Must give $test_method an arrayref (not hash)");

eval {$cdmi->$test_method({'genome' => $sample_data->[0]->{'id'}})};
#my $res2 = $cdmi->$test_method({'genome' => $sample_data->[0]->{'id'}});
isnt($@, '', "Must give $test_method an arrayref (not hashref)");

is(scalar keys %{$cdmi->$test_method([])}, 0, "$test_method w/empty arrayref returns empty hashref");

my $invalid_id = 'q38 exploding space modulator';
my $invalid_genome_results = $cdmi->$test_method([$invalid_id]);
ok($invalid_genome_results, "Got results for invalid genome id");
ok(! defined $invalid_genome_results->{'invalid_id'}, "No results for invalid ID ($invalid_id)");
