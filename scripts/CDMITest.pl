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
    use Stats;
    use SeedUtils;
    use Data::Dumper;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;


=head1 CDMI Test Script

    CDMITest [options]

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script>. There are
no positional parameters.

=cut

$| = 1;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMITest [options]\n";
} else {
    print "Connecting to database.\n";
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetSource('SEED');
    for my $peg (qw(191 769 1980 1982 1961 1961 460 2019 2039 514 1225 1923 2061)) {
        my $fid = "fig|933267.3.peg.$peg";
        print "Seeking ID for $fid.\n";
        my $kbidMap = $loader->FindKBaseIDs('Feature', [$fid]);
        print "ID is $kbidMap->{$fid}.\n";
    }
    $loader->SetSource('EnsemblPlant');
    print "Looking up Arabidopsis genome.\n";
    my $gid = $loader->GetKBaseID('kb|g', 'Genome', 'Athaliana.TAIR10');
    print "Genome ID is $gid.\n";
}
