### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $stats = Stats->new();
    # Loop through the subsystems.
    my %subMap = map { $_->[0] => $_->[1] } $cdmi->GetAll('Subsystem', '', [], 'id experimental');
    for my $sub (sort keys %subMap) {
        print "Checking $sub.\n";
        $stats->Add(subsChecked => 1);
        # We'll set this to 1 if the subsystem should be deleted. Experimental subsystems are
        # always deleted.
        my $delete = $subMap{$sub};
        if ($delete) {
            $stats->Add(experimental => 1);
            print "Subsystem is experimental.\n";
        } else {
            # It's not experimental, so check for bad roles.
            my @roles = $cdmi->GetFlat('Includes', 'Includes(from-link) = ?', [$sub], 'to-link');
            if (scalar(@roles) == 0) {
                $delete = 1;
                $stats->Add(noRoles => 1);
                print "Subsystem has no roles.\n";
            } else {
                for my $role (@roles) { last if $delete;
                    if (! $role) {
                        $delete = 1;
                        $stats->Add(nullRole => 1);
                        print "Subsystem has a null role.\n";
                    } elsif ($role =~ /hypothetical\s+protein/) {
                        $delete = 1;
                        $stats->Add(hypoRole => 1);
                        print "Subsystem has hypothetical role: $role.\n";
                    }
                }
            }
        }
        if ($delete) {
            # Delete the bad subsystem.
            print "Deleting subsystem $sub.\n";
            my $delStats = $cdmi->Delete(Subsystem => $sub);
            # Roll up the statistics.
            $stats->Accumulate($delStats);
        }
    }
    # All done.
    print "All done:\n" . $stats->Show();

