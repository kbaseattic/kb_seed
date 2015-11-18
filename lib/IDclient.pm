# -*- perl -*-
package IDclient;
# This is a SAS component.
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

sub new {
    my ($class, $source) = @_;

    my $self = {};
    if (ref($source) eq q(HASH) || (ref($source) && UNIVERSAL::can($source, 'isa') && $source->isa('GenomeTypeObject'))) {
        #...Hack to fake the service locally
        $self->{_counters} = {};

        if (defined(my $features = $source->{features})) {
            foreach my $feature (@$features) {
                if (my ($prefix, $num) = ($feature->{id} =~ m/^(\S+)\.(\d+)$/o)) {
                    if (defined($self->{_counters}->{$prefix})) {
                        if ($num > $self->{_counters}->{$prefix}) {
                            $self->{_counters}->{$prefix} = $num;
                        }
                    }
                    else {
                        $self->{_counters}->{$prefix} = $num;
                    }
                }
                #
                # If we can't parse, we'll just assume that
                # we'll start with zero.
                #
                # else {
                #    warn "Could not parse ID for feature: \'$feature->{id}\'";
                # }
            }
        }
    }

    return bless $self, $class;
}

sub allocate_id_range {
    my ($self, $id_prefix, $num_IDs) = @_;

    if (not defined $self->{_counters}->{$id_prefix}) {
        $self->{_counters}->{$id_prefix} = 0;
    }

    my $next_num = ($self->{_counters}->{$id_prefix} + 1);
    $self->{_counters}->{$id_prefix} += $num_IDs;

    return $next_num;
}

1;
