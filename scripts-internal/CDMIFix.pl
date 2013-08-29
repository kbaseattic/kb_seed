### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use Data::Dumper;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $stats = Stats->new();
    my %genomes;
    my $query = $cdmi->Get("IsComposedOf", "ORDER BY IsComposedOf(from-link)", []);
    while (my $row = $query->Fetch()) {
        my ($from, $to) = $row->Values("from-link to-link");
        $stats->Add(linkRow => 1);
        if (substr($to, 0, length $from) ne $from) {
            print "Contig $to does not match genome $from.\n";
            $stats->Add(badLink => 1);
            if (! $genomes{$from}) {
                $stats->Add(badGenome => 1);
                $genomes{$from} = 1;
            }
        }
    }
    # All done.
    print "All done:\n" . $stats->Show();

