### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use Data::Dumper;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my @locComps = $cdmi->GetFlat('LocalizedCompound', '', [], 'id');
    my $stats = Stats->new();
    for my $locComp (@locComps) {
        print "Processing $locComp.\n";
        my @rows = $cdmi->GetAll('Involves', "Involves(to-link) = ? ORDER BY Involves(from-link), Involves(coefficient)", ["$locComp"],
            "from-link coefficient to-link");
        my ($oldFrom, $oldCoeff, $oldTo) =
            ("", "", "");
        print scalar(@rows) . " Involves records found for $locComp.\n";
        my $dups = 0;
        for my $row (@rows) {
            my ($from, $coeff, $to) = @$row;
            if ($from eq $oldFrom && $coeff eq $oldCoeff && $to eq $oldTo) {
                $dups++;
                # We need to delete one of the duplicates, but our only choice
                # is to delete both, so we add one back afterward.
                $cdmi->DeleteRow('Involves', $from, $to, {coefficient => $coeff});
                $cdmi->InsertObject('Involves', from_link => $from,
                    to_link => $to, coefficient => $coeff);
            }
            ($oldFrom, $oldCoeff, $oldTo) = ($from, $coeff, $to);
        }
        print "$dups duplicates fixed in $locComp.\n";
        $stats->Add(locComps => 1);
        $stats->Add(dups => $dups);
    }
    print "All done:\n" . $stats->Show();
