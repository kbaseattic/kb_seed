use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Carp;
use Bio::KBase::CDMI::Client;
use Cwd;

#  Test 1 - Can the CDMI_EntityAPIClient be created?
my $cdmie = Bio::KBase::CDMI::Client->new("http://localhost:7032");
#my $cdmie = Bio::KBase::CDMI::Client->new("http://bio-data-1.mcs.anl.gov/services/cdmi_api");
ok( defined $cdmie, "Can the CDMI_EntityAPIClient be created?" );               

#  Test 2 - Is the object in the right class?
isa_ok( $cdmie, 'Bio::KBase::CDMI::Client', "Is it in the right class" );

#Database scheme XML file tests and parsing
#  Test 3 - Does the database scheme file exist
my $path = Cwd::abs_path($0);
if ($path =~ m/(.+\/)[^\/]+$/) {
	$path = $1;
}

my $schemeFile = $path."../lib/KSaplingDBD_Published.xml";
#print $schemeFile."\n";
ok( -e $schemeFile, "Does the KBase CDM xml spec exist?" );

# READ the schemeFile and create method to test
if (!-e $schemeFile) {
	exit();	
}

open (INPUT, "<",$schemeFile);
my $entityMap;
while (my $Line = <INPUT>) {
	if ($Line =~ m/Entity\s+name=\"([^\"]+)\"/) {
		$entityMap->{$1} = {};
	} elsif ($Line =~ m/Relationship\s+name=\"([^\"]+)\"\s+from=\"([^\"]+)\"/) {
		$entityMap->{$2}->{$1} = 1;
	}
}
close(INPUT);

#  Test 4 - Do functions exist in the API for every entity and relationship in the database?
#	The should be an all_entities_ and get_entity_ for every entity and
#	a get_relationship_ for every relationship in the schemeFile
note("Test for methods all_entities_, get_entity_ and get_relationship_ ");
foreach my $entity (keys(%{$entityMap})) {
	can_ok($cdmie,"all_entities_".$entity);
	can_ok($cdmie,"get_entity_".$entity);
	foreach my $relationship (keys(%{$entityMap->{$entity}})) {
		can_ok($cdmie,"get_relationship_".$relationship);
	}
}
#  ENTITY TESTS: Now we test each entity one at a time;
my $entityResults;
foreach my $entity (keys(%{$entityMap})) {
	print "Now testing entity: ".$entity."\n";
	my $function = "all_entities_".$entity;
	my $output;
	my $result = eval {
		$output = $cdmie->$function(0,10,["id"]);
		return 1;
	};
	#  Test - Does the all_entities function run?
	ok( $result == 1, "Did all_entities_".$entity." successfully run?" );

	#  Test - Does the all_entities function return results?
	ok( defined $output, "Does the all_entities_".$entity." call return results?" );

	$entityResults->{$entity}->{count} = keys(%{$output});
	if ($entityResults->{$entity}->{count} == 0) {
		print "No objects of type ".$entity." in database. No further tests of this object are possible.\n";
	} else {
		my $objectList = [keys(%{$output})];
		my $object = $output->{$objectList->[0]};
		#  Test 6 - Does the all_entities function return an "id" as requested?
		ok( defined $object->{id}, "Does all_entities_".$entity." return an id of the first object?" );
		my $result = eval {
			$function = "get_entity_".$entity;
			$output = $cdmie->$function([$object->{id}],["id"]);
			return 1;
		};
		#  Test - Does the get_entity function run?
		ok( defined($result) && $result == 1, "Did get_entity_".$entity." successfully run?" );
		ok( defined $output->{$object->{id}}->{id}, "Does get_entity_".$entity." return an id of the first object?" );
		#  RELATIONSHIP TESTS: Now we test each relationship one at a time;
		foreach my $relationship (keys(%{$entityMap->{$entity}})) {
			my $result = eval {
				$function = "get_relationship_".$relationship;
				if ($object->{id} eq 'NCBI') { print "skipping NCBI\n"; next; }
				$output = $cdmie->$function([$object->{id}],["id"],[],["id"]);
				return 1;
			};
			#  Test - Does the get_entity function run?
			ok( defined($result) && $result == 1, "Did get_relationship_".$relationship." successfully run?" );
			ok( defined $output, "Does get_relationship_".$relationship." return a result?" );
			if (!defined($output->[0])) {
				print "No objects for relationship ".$entity."->".$relationship." in database. No further tests of this relationship are possible.\n";
			} else {
				ok( defined $output->[0]->[0]->{id} && $output->[0]->[2]->{id}, "Does get_relationship_".$relationship." return an id for the 'from' and 'to' entities?" );
			}
		}
	}
}
done_testing();
