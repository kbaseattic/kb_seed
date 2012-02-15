#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use CDMI_APIClient;
use CDMI_EntityAPIClient;

############
#
# CONFIGURE THESE
#
my $url         = 'http://140.221.92.46:5000';

my $test_method = 'locations_to_dna_sequences';
my @additional_args = (
        [],

    );     #ANYTHING EXTRA TO GIVE YOUR TEST METHOD
            #GIVE IT A LIST OF ARRAYREFS. EACH SUB ARRAYREF IS A SET OF ARGS TO TRY WITH

my $cdmi = CDMI_APIClient->new($url);
my $cdmie = CDMI_EntityAPIClient->new($url);


#
# CONFIGURE THIS TO LOAD YOUR DATA
#
my $all_available_data = $cdmie->all_entities_Genome(0,100,['id', 'domain']);
my $all_locations = {};
foreach my $key (keys %$all_available_data) {
    if ($all_available_data->{$key}->{'domain'} ne 'Eukaryota') {
        next;
    }

    my $fids = $cdmi->genomes_to_fids([$key], []);

    my $throttle = 0;
    foreach my $fid (@{$fids->{$key}}) {
        my $locations = $cdmi->fids_to_locations([$fid]);
        foreach my $key (keys %$locations) {
            my $val = $locations->{$key}->[0];
            $all_locations->{$key} = [$val];
        }
        last if $throttle++ > 10;
    }

}
$all_available_data = $all_locations;

my @random_subset = ();
my @all_available_keys = keys %$all_available_data;
my $num_sample = int rand(@all_available_keys);

for (0..$num_sample) {
    push @random_subset, $all_available_data->{ $all_available_keys[int rand @all_available_keys] };
}

#
# SAMPLE DATA IS OPTIONAL
#

my $sample_data = [
	{'id' => [
                                  [
                                    'kb|g.1087.c.0',
                                    '2111515',
                                    '+',
                                    '76'
                                  ]]
                                , 'expected' => [
          [
            [
              [
                'kb|g.1087.c.0',
                '2111515',
                '+',
                '76'
              ]
            ],
            'tcctctgtagttcagtcggtagaacggcggactgttaatccgtatgtcactggttcgagtccagtcagaggagcca'
          ]
        ]},
];

#
#
#
############

my @args_count = @additional_args || 1;

plan('tests' =>
      4 * (scalar keys %$all_available_data) * @args_count
    + 2 * @$sample_data * @args_count
    + 1 * @random_subset * @args_count
    + 5 * @args_count);

foreach my $fid (keys %$all_available_data) {
    my $location = $all_available_data->{$fid};
    my $dna_seqs = $cdmi->$test_method([$location]);
    is(@$dna_seqs, 1, "Just one set of DNA sequences");
    is(@{$dna_seqs->[0]}, 2, "Properly sized DNA Sequences");
    is_deeply($dna_seqs->[0]->[0], $location, "Location returned");
    ok(length $dna_seqs->[0]->[1], "Has dna string");
}

foreach my $sample (@$sample_data) {
    foreach my $args (@additional_args) {
        ok($sample->{'id'}, "Found known sample $sample->{'id'}");
        my $results = $cdmi->$test_method( [ $sample->{'id'} ], @$args );
        my $expectations_key = @$args ? $args : 'expected';
        is_deeply($results, $sample->{$expectations_key}, "Results match expectations");
    }
}

#give it a few at once.
foreach my $args (@additional_args) {

    my $results = $cdmi->$test_method(\@random_subset, @$args);
    my $idx = 0;
    foreach my $datum (@random_subset) {
        my $single_results = $cdmi->$test_method( [ $datum ], @$args );
        is_deeply($single_results->[0], $results->[$idx], "Multi-results matches single results for $datum");
        $idx++;
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

    is(@{$cdmi->$test_method([], @$args)}, 0, "$test_method w/empty arrayref returns empty hashref with @$args");

    my $invalid_id = 'q38 exploding space modulator';
}
