### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetSource('EnsemblPlant');
    $loader->SetGenome('Oglaberrima.AGI1.1');
    my @ids = qw(Oglab05_unplaced019 Oglab04_unplaced014 Oglab04_unplaced051 Oglab04_unplaced122 12 5 10 11);
    my $idMapping = $loader->FindKBaseIDs('Contig', \@ids);
    for my $id (@ids) {
        print "$id is mapped to $idMapping->{$id}.\n"
    }

