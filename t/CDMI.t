use strict;
use Data::Dumper;
use Carp;
use CDMI_APIClient;

my $cdmi = CDMI_APIClient->new("http://140.221.92.46:5000");
my $results = $cdmi->text_search("coli", 0, 100, undef);
print STDOUT Data::Dumper->Dump([$results]);