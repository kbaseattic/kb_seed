use strict;
use Data::Dumper;
use Carp;
use CDMI_APIClient;
use CDMI_EntityAPIClient;

my $cdmie = CDMI_EntityAPIClient->new("http://140.221.92.46:5000");
my $cdmi = CDMI_APIClient->new("http://140.221.92.46:5000");
my $results = $cdmie->all_entities_Genome(0, 100, ["id"]);
print STDOUT Data::Dumper->Dump([$results]);


$results = $cdmi->text_search("coli", 0, 100, []);
print STDOUT Data::Dumper->Dump([$results]);