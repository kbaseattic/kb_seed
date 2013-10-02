
#
# This is a SAS Component
#


=head1 svr_roles_to_reactions

Get the reactions potentially supported by a set of functional roles

------

Example:

    svr_roles_to_reactions < roles.in.genome > reactions.possibly.supported


would produce a 2-column table.  The first column would contain
a role and the second a reaction id (i.e., a Model SEED reaction ID).

------

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the function associated with the PEG).

=cut
  
#########################################################################
# Janaka N Edirisinghe                                                  #
# This progragram take a single role per line as an input               #
# and proudce the mapping reactions based on the template model         #
#                                                                       #
# usage input file - functional roles (one per line)                    #
# perl roles_to_reaction < input.txt                                    #
#########################################################################

use strict;
use Data::Dumper;
use Try::Tiny;
use Bio::KBase::fbaModelServices::Client;
my $client = Bio::KBase::fbaModelServices::Client->new('http://140.221.85.73:4043');

my $comp;
$comp->{workspace} = 'KBaseTemplateModels';
$comp->{templateModel} = 'GramPosModelTemplate';


my $biochem = $client->role_to_reactions($comp);

my %hash1;
my %hash2;
for(my $i =0; $i< @{$biochem}; $i++){

  my $comp = $biochem->[$i]->{complexes};
  my $role = $biochem->[$i]->{name};
    
    for (my $j =0; $j< @{$comp}; $j++){

       my $comp_id = $comp->[$j]->{complex};
       my $rxns = $comp->[$j]->{reactions};
          for (my $k =0; $k< @{$rxns}; $k++){
        
             my $rxn_id = $rxns->[$k]->{reaction};
             $hash1{$role}->{$rxn_id} = 1;
             push(@{$hash2{$role}},$rxn_id);

         }
    }

}


while (defined($_ = <STDIN>)){

    chomp;
    $_ =~ s/^\s+//;
    $_ =~ s/\s+$//;

    foreach my $k(sort keys(%hash1)) {

        foreach my $k2 (keys(%{$hash1{$k}})) {
       
            if($k eq $_){
                print "$_\t$k2\n";
            }

        }

    }

}

