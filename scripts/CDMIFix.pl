### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Stats;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my @genomes = $cdmi->GetFlat('Submitted Genome', 'Submitted(from_link) = ?',
            ['MOL'], 'Genome(id)');
    print scalar(@genomes) . " genomes found in database.\n";
    my $stats = Stats->new();
    for my $genome (@genomes) {
        print "Deleting $genome.\n";
        my $newStats = $cdmi->Delete(Genome => $genome);
        $stats->Accumulate($newStats);
    }
    print "All done:\n" . $stats->Show();
