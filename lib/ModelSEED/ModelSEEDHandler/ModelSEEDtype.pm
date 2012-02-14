# -*- perl -*-
########################################################################
#
# ModelSEEDtype is a object for handling the types of object if the database
# Initiating author: Christopher Henry
# Initiating author email: chrisshenry@gmail.com
# Initiating author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 6/03/2010
########################################################################

use strict;
use DBMaster;
use FIGMODEL;

package ModelSEEDtype;

=head1 An object for handling the types of entities if the database

=head3 new
Definition:
	ModelObjectType:new object = ModelObjectType->new(FIGMODEL,string:entity type);
=cut
sub new {
	my ($class,$figmodel,$type) = @_;
	my $self;
	$self->{_figmodel} = $figmodel;
	$self->{_type} = $type;
	
#	($self->{_parameters}->{_list},$self->{_attributes}->{_list}) = $figmodel->get_type_data($type);
#	for (my $i=0; $i < @{$self->{_parameters}->{_list}}; $i++) {
#		$self->{_parameters}->{$self->{_parameters}->{_list}->[$i]} = $self->{_parameters}->{_list}->[$i];
#	}
#
#	for (my $i=0; $i < @{$self->{_attributes}->{_list}}; $i++) {
#		$self->{_parameters}->{$self->{_attributes}->{_list}->[$i]} = $self->{_attributes}->{_list}->[$i];
#		if (defined($self->{_attributes}->{_list}->[$i]->{source})) {
#			my @temp = split(/:/,$self->{_attributes}->{_list}->[$i]->{source});
#			if ($temp[0] eq "PPO" && defined($self->{_figmodel}->[0]->config("PPO_tbl_".$temp[1]))) {
#				$self->{_PPO}->{$temp[1]} = DBMaster->new(-database => $temp[1],
#                           -host     => $self->{_figmodel}->config("PPO_tbl_".$temp[1])->{host},
#                           -user     => $self->{_figmodel}->config("PPO_tbl_".$temp[1])->{user},
#                           -password => $self->{_figmodel}->config("PPO_tbl_".$temp[1])->{password},
#                           -port     => $self->{_figmodel}->config("PPO_tbl_".$temp[1])->{port},
#                           -socket   => $self->{_figmodel}->config("PPO_tbl_".$temp[1])->{"socket"});
#			} elsif ($temp[0] eq "figmodel" && $temp[1] =~ m/([\S])\((.+)\)/) {
#				my $function = $1;
#				my @temptemp = split(/,/,$2);
#				$self->{_functions}->{$function}->[0] = 1;
#				push(@{$self->{_functions}->{$function}},@temptemp);
#			} elsif ($temp[0] eq "flatfile" && defined($self->{_figmodel}->[0]->config("Flatfile_tbl_".$temp[1]))) {
#				$self->{_PPO}->{$temp[1]} = $self->{_figmodel}->[0]->database()->GetDBTable($temp[1]);
#			}
#		}
#	}
	
	bless $self;
}

=head3 figmodel
Definition:
	FIGMODEL = ModelObjectType->figmodel();
Description:
	Returns a FIGMODEL object
=cut
sub figmodel {
	my ($self) = @_;
	return $self->{_figmodel};
}

=head3 type
Definition:
	string = ModelObjectType->type();
Description:
	Returns the type of entity represented by this object
=cut
sub type {
	my ($self) = @_;
	return $self->{_type};
}

=head3 attributes
Definition:
	[string]:attribute names = ModelObjectType->attributes();
Description:
	Returns the list of attributes associated with the type in the database
=cut
sub attributes {
	my ($self) = @_;
	return $self->{_attributes};
}

=head3 get_objects
Definition:
	[ModelObject]:matching objects = ModelObjectType->get_objects({attribute => [string]:values});
Description:
	Returns the list of objects that satisfy the input search criteria
=cut
sub get_objects {
	my ($self,$parameter) = @_;
	
	if ($self->{_dbtype} eq "ERDB") {
		
	} elsif ($self->{_dbtype} eq "PPO") {
		
	} elsif  {
		
	}
}

=pod

=item * [string]:I<attribut list> = B<attributes> ();

=cut
sub attributes {
	my $self = shift;
	$self->{_attributes};
}

=pod

=item * 0/1:I<boolean> = B<has_attribute> (string:I<attribute>);

=cut

sub has_attribute {
	my ($self,$attribute) = @_;
	if (defined($self->{_attribute_hash}->{$attribute})) {
		return 1;	
	}
	return 0;
}

1;