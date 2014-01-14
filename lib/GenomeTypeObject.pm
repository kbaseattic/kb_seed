# -*- perl -*-

package GenomeTypeObject;

#
# This is a SAS component.
#

########################################################################
# Copyright (c) 2003-2013 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
########################################################################

use strict;
use warnings;
use Data::Dumper;
use SeedUtils;
use File::Temp;
use gjoseqlib;
use Time::HiRes 'gettimeofday';
use UUID;

# my new {
#     my ($class, $self) = @_;
#    
#     $self ||= {};
#    
#     return bless $self, $class;
# }

sub initialize
{
    my($class, $self) = @_;

    bless $self, $class;

    $self->update_indexes();
}

sub prepare_for_return
{
    my($self) = @_;

    delete $self->{$_} foreach  grep { /^_/ } keys %$self;
}

sub update_indexes
{
    my($self) = @_;

    #
    # Create feature index.
    #

    my $feature_index = {};
    $self->{_feature_index} = $feature_index;
    for my $feature ($self->features)
    {
	$feature_index->{$feature->{id}} = $feature;
    }
    return $self;
}

sub features
{
    my($self) = @_;
    return @{$self->{features}};
}

sub add_feature {
    my ($self, $parms) = @_;
    my $genomeTO = $self;
    print STDERR (Dumper($parms), qq(\n\n)) if $ENV{DEBUG};
    
    my $id = $parms->{-id};
    my $id_client   = $parms->{-id_client};
    my $id_prefix   = $parms->{-id_prefix};
    my $type        = $parms->{-type}       or die "No feature-type -type";
    my $location    = $parms->{-location}   or die "No feature location -location";
    my $function    = $parms->{-function};
    my $annotator   = $parms->{-annotator}  || q(Nobody);
    my $annotation  = $parms->{-annotation} || q(Add feature);
    my $translation = $parms->{-protein_translation};
    my $event_id    = $parms->{-analysis_event_id};
    my $quality     = $parms->{-quality_measure};

    if (!defined($id))
    {
	if (!defined($id_client) || !defined($id_prefix))
	{
	    die "No id or id_client/id_prefix provided";
	}
	my $typed_prefix = "$id_prefix.$type";
	my $next_num     = $id_client->allocate_id_range($typed_prefix, 1);
	# print STDERR Dumper($typed_prefix, $next_num);
	
	if (defined($next_num)) {
	    print STDERR "Allocated id for typed-prefix \'$typed_prefix\' starting from $next_num\n" if $ENV{DEGUG};
	}
	else {
	    die "Could not get a new ID with typed-prefix \"$typed_prefix\"" unless $next_num;
	}
	$id = join(".", $typed_prefix, $next_num);
    }    
    
    if (not defined $genomeTO->{features}) {
	$genomeTO->{features} = [];
    }
    my $features  = $genomeTO->{features};
    
    my $feature =  { id   => $id,
		     type => $type,
		     location => $location,
		     annotations => [[ $annotation, 
				       $annotator,
				       time(),
				       ]],
    };

    $feature->{quality} = $quality if $quality;
    $feature->{feature_creation_event} = $event_id if $event_id;

    if ($function) {
	$feature->{function} = $function;
	push @ { $feature->{annotations} }, [ "Set function to $function",
					      $annotator,
					      time(),
	                                      ];
    }
    
    if ($translation) {
	$feature->{protein_translation} = $translation;
    }
    
    push @$features, $feature;
    
    return;
}

sub extract_protein_sequences_to_temp_file
{
    my($self) = @_;

    my($fh, $fn) = tmpnam();

    for my $feature (@{$self->{features}})
    {
	my $trans = $feature->{protein_translation};
	if ($trans)
	{
	    write_fasta($fh, [$feature->{id}, undef, $trans]);
	}
    }
    close($fh);
    return $fn;
}

sub extract_contig_sequences_to_temp_file
{
    my($self) = @_;

    my($fh, $fn) = tmpnam();

    for my $ctg (@{$self->{contigs}})
    {
	write_fasta($fh, [$ctg->{id}, undef, $ctg->{dna}]);
    }
    close($fh);
    return $fn;
}

sub add_analysis_event
{
    my($self, $event) = @_;

    if (ref($event) ne 'HASH')
    {
	die "GenomeTypeObject::add_analysis_event: event must be a hash reference";
    }

    my($uuid, $uuid_str);
    UUID::generate($uuid);
    UUID::unparse($uuid, $uuid_str);

    $event->{id} = $uuid_str;

    push(@{$self->{analysis_events}}, $event);
    return $uuid_str;
}

sub update_function
{
    my($self, $user, $fid, $function, $event_id) = @_;

    my $feature = $self->find_feature($fid);

    my $annotation = ["Function updated to $function", $user, scalar gettimeofday, $event_id];
    # print STDERR Dumper($fid, $feature, $annotation);
    
    push(@{$feature->{annotations}}, $annotation);
    $feature->{function} = $function;
}

sub find_feature
{
    my($self, $fid) = @_;

    return $self->{_feature_index}->{$fid};
}

1;
