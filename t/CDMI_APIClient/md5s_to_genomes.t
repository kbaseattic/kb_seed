#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 24;

use CDMI_APIClient;
use CDMI_EntityAPIClient;

my $url = 'http://140.221.92.46:5000';

my $cdmie = CDMI_EntityAPIClient->new($url);
ok($cdmie, "Got CDMI_EntityAPIClient");

my $cdmi = CDMI_APIClient->new($url);
ok($cdmi, "Got CDMI_APIClient");

my $genomes = $cdmie->all_entities_Genome(0,10000,['id']);
ok(keys %$genomes, "Loaded up some genomes");

my $sample_genomes = [
	{'id' => 'kb|g.3093', 'hash' => '94518bb814a8a79e60637ee6f92ce3bd'},
	{'id' => 'kb|g.5458', 'hash' => '15ade9db34c4a556f56aa39805192a9f'},
	{'id' => 'kb|g.1554', 'hash' => '4a1b448b1dc98b56dec5dcb092d49f4d'},
	{'id' => 'kb|g.2620', 'hash' => 'dc4fb05c22adbc14908f9c857a2ad9f5'},
];

ok($genomes->{$sample_genomes->[0]->{'id'}}, "Found known genome $sample_genomes->[0]->{'id'}");
ok(@{$cdmi->md5s_to_genomes([$sample_genomes->[0]->{'hash'}])->{$sample_genomes->[0]->{'hash'}}} == 1,
	"Only one genome for md5 $sample_genomes->[0]->{'hash'}");
is($cdmi->md5s_to_genomes([$sample_genomes->[0]->{'hash'}])->{$sample_genomes->[0]->{'hash'}}->[0],
	$sample_genomes->[0]->{'id'},
	"Correct md5 for $sample_genomes->[0]->{'id'}"
);

ok($genomes->{$sample_genomes->[1]->{'id'}}, "Found known genome $sample_genomes->[1]->{'id'}");
ok(@{$cdmi->md5s_to_genomes([$sample_genomes->[1]->{'hash'}])->{$sample_genomes->[1]->{'hash'}}} == 1,
	"Only one genome for md5 $sample_genomes->[1]->{'hash'}");
is($cdmi->md5s_to_genomes([$sample_genomes->[1]->{'hash'}])->{$sample_genomes->[1]->{'hash'}}->[0],
	$sample_genomes->[1]->{'id'},
	"Correct md5 for $sample_genomes->[1]->{'id'}"
);

ok($genomes->{$sample_genomes->[2]->{'id'}}, "Found known genome $sample_genomes->[2]->{'id'}");
ok(@{$cdmi->md5s_to_genomes([$sample_genomes->[2]->{'hash'}])->{$sample_genomes->[2]->{'hash'}}} == 1,
	"Only one genome for md5 $sample_genomes->[2]->{'hash'}");
is($cdmi->md5s_to_genomes([$sample_genomes->[2]->{'hash'}])->{$sample_genomes->[2]->{'hash'}}->[0],
	$sample_genomes->[2]->{'id'},
	"Correct md5 for $sample_genomes->[2]->{'id'}"
);

ok($genomes->{$sample_genomes->[3]->{'id'}}, "Found known genome $sample_genomes->[3]->{'id'}");
ok(@{$cdmi->md5s_to_genomes([$sample_genomes->[3]->{'hash'}])->{$sample_genomes->[3]->{'hash'}}} == 1,
	"Only one genome for md5 $sample_genomes->[3]->{'hash'}");
is($cdmi->md5s_to_genomes([$sample_genomes->[3]->{'hash'}])->{$sample_genomes->[3]->{'hash'}}->[0],
	$sample_genomes->[3]->{'id'},
	"Correct md5 for $sample_genomes->[3]->{'id'}"
);

#give it a few at once.
my $results = $cdmi->md5s_to_genomes([$sample_genomes->[0]->{'hash'}, $sample_genomes->[1]->{'hash'}]);
is($results->{$sample_genomes->[0]->{'hash'}}->[0], $sample_genomes->[0]->{'id'}, "Correct multi-md5 for $sample_genomes->[0]->{'id'}");
is($results->{$sample_genomes->[1]->{'hash'}}->[0], $sample_genomes->[1]->{'id'}, "Correct multi-md5 for $sample_genomes->[1]->{'id'}");

#ok. Now let's try to break it with invalid data.
eval {$cdmi->md5s_to_genomes};
like($@, qr/Invalid argument count \(expecting 1\)/, "Must give md5s_to_genomes an arrayref of genomes (not scalar)");

eval {$cdmi->md5s_to_genomes($sample_genomes->[0]->{'id'}, $sample_genomes->[1]->{'id'})};
like($@, qr/Invalid argument count \(expecting 1\)/, "Must give md5s_to_genomes an arrayref of genomes (not array)");

eval {$cdmi->md5s_to_genomes('genome' => $sample_genomes->[0]->{'id'})};
like($@, qr/Invalid argument count \(expecting 1\)/, "Must give md5s_to_genomes an arrayref of genomes (not hash)");

eval {$cdmi->md5s_to_genomes({'genome' => $sample_genomes->[0]->{'id'}})};
my $res2 = $cdmi->md5s_to_genomes({'genome' => $sample_genomes->[0]->{'id'}});
like($@, qr/Invalid argument count \(expecting 1\)/, "Must give md5s_to_genomes an arrayref of genomes (not hashref)");

is(scalar keys %{$cdmi->md5s_to_genomes([])}, 0, "md5s_to_genomes w/empty arrayref returns empty hashref");

my $invalid_genome_id = 'q38 exploding space modulator';
my $invalid_genome_results = $cdmi->md5s_to_genomes([$invalid_genome_id]);
ok($invalid_genome_results, "Got results for invalid genome id");
ok(! defined $invalid_genome_results->{'invalid_genome_id'}, "No MD5 for invalid genome ID ($invalid_genome_id)");

print "$@\n";
