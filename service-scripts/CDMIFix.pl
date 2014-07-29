### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
	my $stats = $cdmi->Delete(SSCell => '');
	print "All done:\n" . $stats->Show();