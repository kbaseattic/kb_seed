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

my $test_method = 'reaction_strings';
my @additional_args = (
        [""],
    );     #ANYTHING EXTRA TO GIVE YOUR TEST METHOD
            #GIVE IT A LIST OF ARRAYREFS. EACH SUB ARRAYREF IS A SET OF ARGS TO TRY WITH

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
my $all_available_data = $cdmie->all_entities_Reaction(0,100,['id']);

my $good_data = $cdmie->all_entities_Reaction(101, 5, ['id']);
$good_data = $cdmi->reaction_strings([keys %$good_data], "");
print STDOUT Data::Dumper->Dump([$good_data]);

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
	{ 'id' => '437AAB0A-5392-11E1-8CD2-A9B7B226DF1C', 'expected' => 'H2O + Phosphate + PPi + Triphosphate <=> H2O + Phosphate + PPi + Triphosphate' },
	{ 'id' => '43778BD2-5392-11E1-8CD2-A9B7B226DF1C', 'expected' => 'ATP + ADP + 5-Hydroxymethyldeoxycytidylate + 2\'-Deoxy-5-hydroxymethylcytidine-5\'-diphosphate <=> ATP + ADP + 5-Hydroxymethyldeoxycytidylate + 2\'-Deoxy-5-hydroxymethylcytidine-5\'-diphosphate' },
	{ 'id' => '4374FAD4-5392-11E1-8CD2-A9B7B226DF1C', 'expected' => 'H2O + NAD + NADH + NH3 + (2) H+ + Hydroxylamine <=> H2O + NAD + NADH + NH3 + (2) H+ + Hydroxylamine' },
	{ 'id' => '437C8F9C-5392-11E1-8CD2-A9B7B226DF1C', 'expected' => 'ATP + NAD + PPi + Nicotinamide ribonucleotide <=> ATP + NAD + PPi + Nicotinamide ribonucleotide' },
	{ 'id' => '43792A6E-5392-11E1-8CD2-A9B7B226DF1C', 'expected' => 'ATP + ADP + 2\'-Deoxy-5-hydroxymethylcytidine-5\'-diphosphate + 2\'-Deoxy-5-hydroxymethylcytidine-5\'-triphosphate <=> ATP + ADP + 2\'-Deoxy-5-hydroxymethylcytidine-5\'-diphosphate + 2\'-Deoxy-5-hydroxymethylcytidine-5\'-triphosphate' }
];

#
#
#
############

my @args_count = @additional_args || 1;

plan('tests' =>
      2 * (scalar keys %$all_available_data) * @args_count
    + 2 * @$sample_data * @args_count
    + 1 * @random_subset * @args_count
    + 7 * @args_count);

foreach my $datum (keys %$all_available_data) {
    foreach my $args (@additional_args) {
        my $results = $cdmi->$test_method( [ $datum ], @$args);
        ok($results, "Got results for $datum");
        ok(scalar keys %$results <= 1, "Only retrieved results for $datum");
        #ok($results->{$datum}, "Retrieved results for $datum");
    }
}

foreach my $sample (@$sample_data) {
    foreach my $args (@additional_args) {
        ok($sample->{'id'}, "Found known sample $sample->{'id'}");
        $sample->{'results'} = $cdmi->$test_method( [ $sample->{'id'} ], @$args )->{ $sample->{'id'} };
        my $expectations_key = @$args ? $args : 'expected';
        is($sample->{'results'}, $sample->{'expected'}, "Results match expectations");
    }
}

#give it a few at once.
foreach my $args (@additional_args) {

    my $results = $cdmi->$test_method(\@random_subset, @$args);
    foreach my $datum (@random_subset) {
        my $single_results = $cdmi->$test_method( [ $datum ], @$args );
        is_deeply($single_results->{$datum}, $results->{$datum}, "Multi-results matches single results for $datum");
    }
}

foreach my $args (@additional_args) {
    #ok. Now let's try to break it with invalid data.
    eval {$cdmi->$test_method};
    ok($@, "Must give $test_method an arrayref (not scalar) with @$args");

    eval {$cdmi->$test_method($sample_data->[0]->{'id'}, $sample_data->[1]->{'id'}, @$args)};
    ok($@, "Must give $test_method an arrayref (not array) with @$args");

    eval {$cdmi->$test_method('genome' => $sample_data->[0]->{'id'}, @$args)};
    ok($@, "Must give $test_method an arrayref (not hash) with @$args");

    eval {$cdmi->$test_method({'genome' => $sample_data->[0]->{'id'}}, @$args)};
    ok($@, "Must give $test_method an arrayref (not hashref) with @$args");

    is(scalar keys %{$cdmi->$test_method([], @$args)}, 0, "$test_method w/empty arrayref returns empty hashref with @$args");

    my $invalid_id = 'q38 exploding space modulator';
    my $invalid_genome_results = $cdmi->$test_method([$invalid_id], @$args);
    ok($invalid_genome_results, "Got results for invalid genome id with @$args");
    ok(! defined $invalid_genome_results->{'invalid_id'}, "No results for invalid ID ($invalid_id) with @$args");
}
