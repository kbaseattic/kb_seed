#update 11/29/2012 - landml

use strict;
use Test::More 'no_plan';
use Data::Dumper;
use Carp;
#use CDMI_APIClient;
#use CDMI_EntityAPIClient;
use Bio::KBase::CDMI::Client;
use lib "t/server-tests";
use CDMITestConfig qw(getHost getPort);



my $NRANDOM = 2;
my $RANDOM_RANGE = 100; # max random interger

#my $cdmie = CDMI_EntityAPIClient->new("http://140.221.92.46:5000");
#my $cdmi = CDMI_APIClient->new("http://140.221.92.46:5000");

# MAKE A CONNECTION (DETERMINE THE URL TO USE BASED ON THE CONFIG MODULE)
my $host=getHost(); my $port=getPort();
print "-> attempting to connect to:'".$host.":".$port."'\n";
my $cdmi  = Bio::KBase::CDMI::Client->new($host.":".$port);
my $cdmie= Bio::KBase::CDMI::Client->new($host.":".$port);

my $ra_all_roles = $cdmi->all_roles_used_in_models();
ok($#$ra_all_roles > 1999, "# of all_roles_used_in_model() > 2000");
ok($#$ra_all_roles < 999999, "# of all_roles_used_in_model() < 1000000");


#
# Test complexes_to_complex_data() 
#

# Empty List
my @complexes = ();
my $rh_complexes = $cdmi->complexes_to_complex_data(\@complexes);
@complexes = keys %$rh_complexes;
is($#complexes, -1, "Empty List : complexes_to_complex_data");

# String input
my $value = "1";
$rh_complexes = undef; # reset
eval {$rh_complexes = $cdmi->complexes_to_complex_data($value);} or ok(1==2, "Wrong input (String): Failed to execute complexes_to_complex_data");
@complexes = keys %$rh_complexes;
is($#complexes, -1, "Wrong input (String): complexes_to_complex_data") if defined $rh_complexes ; # TODO: revisit this later
#print STDOUT Data::Dumper->Dump([$return]);

# integer input
$value =1;
$rh_complexes = undef; # reset
eval {$rh_complexes = $cdmi->complexes_to_complex_data($value);} or ok(1==2, "Wrong input (int): Failed to execute complexes_to_complex_data");
@complexes = keys %$rh_complexes;
is($#complexes, -1, "Wrong input (int): complexes_to_complex_data") if defined $rh_complexes ; # TODO: revisit this later


# Wrong input test
my @wrong = ("123xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
$rh_complexes = undef; # reset
eval {$rh_complexes = $cdmi->complexes_to_complex_data(\@wrong);} or ok(1==2, "Wrong input (invalid id): Failed to execute complexes_to_complex_data");
@complexes = keys %$rh_complexes;
is($#complexes, -1, "Wrong input (invalid id): complexes_to_complex_data") if defined $rh_complexes ; # TODO: revisit this later


# Single instance test 
my $idx = 0;
while ( $idx < $NRANDOM) {

  my $start = int(rand($RANDOM_RANGE));

  $rh_complexes = $cdmie->all_entities_Complex($start, 1, ["id"]);#, "mod_date"]);#, "name"]);
  # name field has a bug

  @complexes = keys %$rh_complexes;
  my $rh_complex_data = $cdmi->complexes_to_complex_data(\@complexes);
  my @complex_data = keys %$rh_complex_data;

  is($#complex_data, $#complexes, "# of retrieved complex data");
  ok(defined $rh_complex_data->{$complexes[0]}, "Retrieved ID shoud be matched");
  #print STDOUT Data::Dumper->Dump([$rh_complex_data]);
  $idx = $idx + 1;
}


# Multi instance test 
my $idx = 0;
while ( $idx < $NRANDOM) {

  my $start = int(rand($RANDOM_RANGE));
  my $count = int(rand($RANDOM_RANGE));

  $rh_complexes = $cdmie->all_entities_Complex($start, $count, ["id"]);#, "mod_date"]);#, "name"]);
  # name field has a bug

  @complexes = keys %$rh_complexes;
  my $rh_complex_data = $cdmi->complexes_to_complex_data(\@complexes);
  my @complex_data = keys %$rh_complex_data;

  is($#complex_data, $#complexes, "# of retrieved complex data");
  my $sidx = 0;
  while($sidx < $count) {
    ok(defined $rh_complex_data->{$complexes[$sidx]}, "Retrieved ID shoud be matched");
    $sidx = $sidx + 1;
  }
  #print STDOUT Data::Dumper->Dump([$rh_complex_data]);
  $idx = $idx + 1;
}

# STRESS test


#
# Test co_occurrence_evidence
#

# Empty List
my $ra_coor = $cdmi->co_occurrence_evidence([[]]);
is($ra_coor, undef, "Empty List : co_occurrence_evidence([[]])");

# Not a pair input
$ra_coor = $cdmi->co_occurrence_evidence([["kb|g.3223.peg.2633"]]);
is($ra_coor, undef, "Non Pair List : co_occurrence_evidence([[\"kb|g.3223.peg.2633\"]])");

# Sing array reference
$ra_coor = undef;
eval {$ra_coor = $cdmi->co_occurrence_evidence(["kb|g.3223.peg.2633", "kb|g.3223.peg.2687"]); } or ok(1==2, "Failed one level array reference");
is($ra_coor, undef, "Single array reference : co_occurrence_evidence([\"kb|g.3223.peg.2633\", \"kb|g.3223.peg.2687\"])");

# Single pair, not relevant
$ra_coor = undef;
eval {$ra_coor = $cdmi->co_occurrence_evidence([["kb|g.3223.peg.2633", "kb|g.99999.peg.2222222222222222"]]); } or ok(1==2, "Failed: single pair unrelevant");
is($ra_coor, undef, "Single pair not relevant : co_occurrence_evidence([[\"kb|g.3223.peg.2633\", \"kb|g.99999.peg.2222222222222222\"]])");

# Single pair, relevant
$ra_coor = $cdmi->co_occurrence_evidence([["kb|g.3223.peg.2633", "kb|g.3223.peg.2687"]]); 
my $ra_rst = $ra_coor->[0]->[1]; #evidences 
ok($#$ra_rst > 200, "Minimum evidence: co_occurrence_evidence([[\"kb|g.3223.peg.2633\", \"kb|g.3223.peg.2687\"]])");
ok($#$ra_rst < 1000, "Maximum evidence: co_occurrence_evidence([[\"kb|g.3223.peg.2633\", \"kb|g.3223.peg.2687\"]])");

# Double pair, relevant
$ra_coor = $cdmi->co_occurrence_evidence([["kb|g.3223.peg.2633", "kb|g.3223.peg.2687"], ["kb|g.3223.peg.2633", "kb|g.3223.peg.2687"]]); 
my $ra_rst1 = $ra_coor->[0]->[1]; #evidences 
my $ra_rst2 = $ra_coor->[1]->[1]; #evidences 
is($#$ra_rst1, $#$ra_rst2, "Double pair, relevant: co_occurrence_evidence([[\"kb|g.3223.peg.2633\", \"kb|g.3223.peg.2687\"], [\"kb|g.3223.peg.2633\", \"kb|g.3223.peg.2687\"]])");


#
# Test  equiv_sequence_assertions #
#
TODO: {
  local $TODO = "No data loaded yet";

  my $results = $cdmie->all_entities_ProteinSequence(0, 10000, ["id"]);#, "mod_date"]);#, "name"]);
  my @a = keys %$results;
  $results = $cdmi->equiv_sequence_assertions(\@a);
  my @b = keys %$results;
  ok($#b > -1, "Should have results : all_entities_ProteinSequence");
}
