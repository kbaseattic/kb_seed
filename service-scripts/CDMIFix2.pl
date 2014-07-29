### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;
use Bio::KBase::CDMI::TaxonomyUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $q = $cdmi->Get('Genome', '', []);
    while (my $row = $q->Fetch()) {
    	my $id = $row->PrimaryValue('id');
    	my $complete = $row->PrimaryValue('complete');
    	my $name = $row->PrimaryValue('scientific-name');
    	my $sourceID = $row->PrimaryValue('source-id');
    	print "$id: $name, complete = $complete from $sourceID\n";
    }
