# -*- perl -*-
########################################################################
#
# ModelObjectType is a object for handling the types of object if the database
# Initiating author: Christopher Henry
# Initiating author email: chrisshenry@gmail.com
# Initiating author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 3/28/2010
########################################################################

use strict;
use DBMaster;
use FIGMODEL;

package ModelObjectType;

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

=head3 parameter
Definition:
	[string]:values = ModelObjectType->parameter(string:key);
Description:
	Returns the values associated with the type parameter in the database
=cut
sub parameter {
	my ($self,$key) = @_;
	return $self->{_parameters}->{$key};
}

=head3 parameters
Definition:
	[string]:parameter names = ModelObjectType->parameters();
Description:
	Returns the list of parameter associated with the type in the database
=cut
sub parameters {
	my ($self) = @_;
	return $self->{_parameters}->{_list};
}

=head3 attribute
Definition:
	{key=>value} = ModelObjectType->attribute(string:attribute label);
Description:
	Returns the data associated with the specified object attribute
=cut
sub attribute {
	my ($self,$key) = @_;
	return $self->{_attributes}->{$key};
}

=head3 attributes
Definition:
	[string]:attribute names = ModelObjectType->attributes();
Description:
	Returns the list of attributes associated with the type in the database
=cut
sub attributes {
	my ($self) = @_;
	return $self->{_attributes}->{_list};
}

=head3 get_objects
Definition:
	[ModelObject]:matching objects = ModelObjectType->get_objects({attribute => [string]:values});
Description:
	Returns the list of objects that satisfy the input search criteria
=cut
sub get_objects {
	my ($self,$parameter) = @_;
	
	my $IDKey;
	if ($self->type() eq "feature") {
		$IDKey = "ID";
		#Filling in the genome search term based on the search terms present
		if (!defined($parameter->{genome})) {
			return undef;
		}
		if (ref($parameter->{genome}) ne "ARRAY") {
			$parameter->{genome}->[0] = $parameter->{genome};
		}
		#Getting the gene list based on the input genomes
		$self->{_data} = $self->figmodel()->GetGenomeFeatureTable($parameter->{genome}->[0]);
		for (my $j=1; $j < @{$parameter->{genome}}; $j++) {
			my $temp = $self->figmodel()->GetGenomeFeatureTable($parameter->{genome}->[$j]);
			for (my $i=0; $i < $temp->size(); $i++) {
				$self->{_data}->add_row($temp->get_row($i));
			}
		}
		delete $parameter->{genome};
	} elsif ($self->type() eq "bof") {
		$IDKey = "DATABASE";
		my $tbl = $self->figmodel()->database()->get_table("BIOMASS");
		$self->{_data} = $tbl->clone_table_def();
		for (my $i=0; $i < $tbl->size(); $i++) {
			$self->{_data}->add_row($tbl->get_row($i));
		}
	} elsif ($self->type() eq "compound") {
		$IDKey = "DATABASE";
		my $tbl = $self->figmodel()->database()->GetDBTable("COMPOUNDS");
		$self->{_data} = $tbl->clone_table_def();
		for (my $i=0; $i < $tbl->size(); $i++) {
			$self->{_data}->add_row($tbl->get_row($i));
		}
	} elsif ($self->type() eq "model") {
		$IDKey = "id";
		my $tbl = $self->figmodel()->database()->GetDBTable("MODELS");
		$self->{_data} = $tbl->clone_table_def();
		for (my $i=0; $i < $tbl->size(); $i++) {
			$self->{_data}->add_row($tbl->get_row($i));
		}
		$tbl = $self->figmodel()->database()->GetDBTable("MODEL STATS");
		$self->{_data}->add_headings($tbl->headings());
		for (my $i=0; $i < $self->{_data}->size(); $i++) {
			my $row = $self->{_data}->get_row($i);
			my $statrow = $tbl->get_row_by_key($row->{id}->[0],"Model ID");
			my @row_keys = keys(%{$statrow});
			for (my $j=0; $j < @row_keys; $j++) {
				$row->{$row_keys[$j]} = $statrow->{$row_keys[$j]};
			}
		}
		$self->figmodel()->database()->ClearDBTable("MODELS");
	}
	
	#Reducing the gene list based on the search terms that are in the table
	if (defined($parameter)) {
		my @searchTerms = keys(%{$parameter});
		foreach my $term (@searchTerms) {
			print STDERR "Search term:".$term."\n";
			#Checking if the search term is already in the table
			if ($self->{_data}->is_heading($term) == 1) {
				if ($self->{_data}->is_indexed($term) == 0) {
					$self->{_data}->add_hashheadings(($term));
				}
				my $results;
				foreach my $key (@{$parameter->{$term}}) {
					my @rows = $self->{_data}->get_rows_by_key($key,$term);
					foreach my $row (@rows) {
						$results->{$row->{$IDKey}->[0]} = $row;
					}
				}
				$self->{_data} = $self->{_data}->clone_table_def();
				my @keyList = keys(%{$results});
				foreach my $key (@keyList) {
					$self->{_data}->add_row($results->{$key});
				}
			#Checking if the search term is an object type
			} elsif ($self->figmodel()->database()->is_type($term) == 1) {
				my $links = $self->figmodel()->database()->db_link($term,$self->type(),$parameter->{$term});
				if (defined($links)) {
					$links = $self->figmodel()->invert_hash($links);
					my $reducedTable = $self->{_data}->clone_table_def();
					foreach my $feature (keys(%{$links})) {
						my $row = $reducedTable->add_row($self->{_data}->get_row_by_key($feature,$IDKey));
						$row->{$term} = $links->{$feature};
					}
					$self->{_data} = $reducedTable;
				}
			} else {
				print STDERR "ModelObjectType:get_objects:".$self->type().":search term ".$term." not recognized!\n";
			}
		}
	}
	
	return $self->{_data}->get_rows();
}

1;