use strict;
use Data::Dumper;
use Carp;

use ScriptThing;

use CDMI;

my $type = shift;
my $usage = "Usage: all_features type\n";
if (!$type) { die $usage};



my $column = 1;
my $i;
my $cdmi = CDMI->new_for_script('c=i' => \$column, 
                     'i=s' => \$i);
while (<>) {
	chomp;          
	my @features = $cdmi->GetAll('IsOwnerOf Feature', 'IsOwnerOf(from-link) = ? AND Feature(feature-type) = ?', [$_, $type],
			['Feature(id)', 'Feature(feature-type)', 'Feature(function)', 'Feature(sequence-length)', 'Feature(source_id)']);   
       
	foreach  my $feature (@features) {
		print "$feature->[0]\t$feature->[1]\t$feature->[2]\t$feature->[3]\t$feature->[4]\n";
	} 
}   	
