# -*- perl -*-

#
# This is a SAS Component
#

########################################################################
# Copyright (c) 2003-2008 University of Chicago and Fellowship
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

my $usage = "svr_seed_table SEED_OrgDir > org.tab";

=head1 svr_seed_to_table SEED_OrgDir > org.tab

Extract a tab-separated feature table from a SEED Genome Directory.
Table format is:

Feature_ID     Location     Function

=cut

use strict;
use warnings;

use SeedV;

my ($org_dir) = @ARGV;
if ($org_dir =~ m/^-{1,2}help/o) {
    print STDERR "   usage: $usage\n";
    exit(0);
}

(-d $org_dir) || die "Organism directory \'$org_dir\' does not exist";

my $seedV = SeedV->new($org_dir);
$seedV->write_features_for_comparison(\*STDOUT);

exit(0);
