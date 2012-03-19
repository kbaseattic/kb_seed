#!/usr/bin/perl -w

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
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
#

use strict;
use SeedEnv;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;

my $sapO = SAPserver->new;
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();

my  $IsFormedOf = "/home/disz/IsFormedOf";

if (! $cdmi) {
    print "usage: CDMILoadAtomicTables\n";
} else {
    $cdmi->LoadTable($IsFormedOf, "IsFormedOf");
}

