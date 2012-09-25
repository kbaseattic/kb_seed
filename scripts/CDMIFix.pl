### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use Data::Dumper;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $stats = Stats->new();
    # Get all the model links.
    my @links = $cdmi->GetAll('IsModeledBy', "", [], 'to-link from-link');
    $stats->Add(linesIn => scalar @links);
    # Clear the table.
    $cdmi->TruncateTable('IsModeledBy');
    # Reload it with the links inverted.
    for my $link (@links) {
    	$cdmi->InsertObject('IsModeledBy', from_link => $link->[0], to_link => $link->[1]);
    	$stats->Add(newLine => 1);
    }
    # All print.
    print "All done:\n" . $stats->Show();

