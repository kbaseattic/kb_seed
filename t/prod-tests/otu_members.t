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

my $test_method = 'otu_members';
my @additional_args = (
        []
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
my $all_available_data = $cdmie->all_entities_Genome(0,100,['id']);
#for example, $cdmie->all_entities_Genome(0,100,['id']);

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
	{'id' => 'kb|g.3093', 'expected' => [ 'kb|g.3093' ] },
	{'id' => 'kb|g.1614', 'expected' => [
                           'kb|g.1554',
                           'kb|g.1614',
                           'kb|g.1736',
                           'kb|g.1737',
                           'kb|g.2193',
                           'kb|g.2971',
                           'kb|g.3380',
                           'kb|g.3463',
                           'kb|g.3465',
                           'kb|g.3556'
                         ]
},
	{'id' => 'kb|g.1554', 'expected' => [
                           'kb|g.1554',
                           'kb|g.1614',
                           'kb|g.1736',
                           'kb|g.1737',
                           'kb|g.2193',
                           'kb|g.2971',
                           'kb|g.3380',
                           'kb|g.3463',
                           'kb|g.3465',
                           'kb|g.3556'
                         ]},
	{'id' => 'kb|g.2620', 'expected' => [
                           'kb|g.114',
                           'kb|g.153',
                           'kb|g.154',
                           'kb|g.155',
                           'kb|g.156',
                           'kb|g.2617',
                           'kb|g.2618',
                           'kb|g.2619',
                           'kb|g.2620',
                           'kb|g.3148',
                           'kb|g.3149',
                           'kb|g.3727',
                           'kb|g.3728',
                           'kb|g.3729',
                           'kb|g.3730'
                         ]
},
];

#
#
#
############

plan('tests' =>
      2 * (scalar keys %$all_available_data) * @additional_args
    + 2 * @$sample_data * @additional_args
    + 1 * @random_subset * @additional_args
    + 7 * @additional_args);

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
        is_deeply($sample->{'results'}, $sample->{$expectations_key}, "Results match expectations");
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
