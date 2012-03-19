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

The command-line options are as specified in L<CDMI/new_for_script>. There are
no positional parameters.

=cut

# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMITest [options]\n";
} else {
    # This version of the script looks for Microbes Online IDs.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetTyped(0);
    my $genomeH = $loader->FindKBaseIDs('MOL.Genome', '', [325240]);
    my @ids = qw(6863495 6863494 6863493 6863490 6863491 6863492 6931558
                 6931557 6931556 6931555 6931554 6931553 6931552 6978110
                 6978112 6978111 6978116);
    my $hash = $loader->FindKBaseIDs('MOL.Feature', '', \@ids);
    print Dumper($hash);
    for my $id (@ids) {
        if ($hash->{$id}) {
            print "$id = $hash->{$id}\n";
        } else {
            print "$id not found.\n";
        }
    }
}
