### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use Data::Dumper;
use IDServerAPIClient;

    $| = 1; # Prevent buffering on STDOUT.
    # Connect to the KBID server.
    my $id_server = IDServerAPIClient->new("http://bio-data-1.mcs.anl.gov:8080/services/idserver");
    my @ids = qw(kb|g.3899.trait.101 kb|g.3899.trait.100);
    my $retVal = $id_server->kbase_ids_to_external_ids(\@ids);
    print Dumper($retVal);
