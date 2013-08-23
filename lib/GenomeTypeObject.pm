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

# my new {
#     my ($class, $self) = @_;
#    
#     $self ||= {};
#    
#     return bless $self, $class;
# }

sub add_feature {
    my ($self, $parms) = @_;
    my $genomeTO = $self;
    print STDERR (Dumper($parms), qq(\n\n)) if $ENV{DEBUG};
    
    my $id_server  = $parms->{-id_server}  or die "No -id_server";
    my $id_prefix  = $parms->{-id_prefix}  or die "No -id_prefix";
    my $type       = $parms->{-type}       or die "No feature-type -type";
    my $location   = $parms->{-location}   or die "No feature location -location";
    my $function   = $parms->{-function};
    my $annotator  = $parms->{-annotator}  || q(Nobody);
    my $annotation = $parms->{-annotation} || q(Add feature);
    
    if (not defined $genomeTO->{features}) {
	$genomeTO->{features} = [];
    }
    my $features  = $genomeTO->{features};
    
    my $typed_prefix = "$id_prefix.$type";
    my $next_num     = $id_server->allocate_id_range($typed_prefix, 1);
#   print STDERR Dumper($typed_prefix, $next_num);
    
    if ($next_num) {
	print STDERR "Allocated id for typed-prefix \'$typed_prefix\' starting from $next_num\n" if $ENV{DEGUG};
    }
    else {
	die "Could not get a new ID with typed-prefix \"$typed_prefix\"" unless $next_num;
    }
    
    my $feature =  { id   => "$typed_prefix.$next_num",
		     type => $type,
		     location => $location,
		     annotations => [[ $annotation, 
				       $annotator,
				       time(),
				       ]],
		 };
    if ($function)   { $feature->{function} = $function; }
    
    push @$features, $feature;
    
    return;
}

1;
