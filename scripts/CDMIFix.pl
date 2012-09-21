### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use Data::Dumper;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    # Collect the sources in here.
    my %sources;
    # Get a stats object.
    my $stats = Stats->new();
    # Loop through the alias-from relationships.
    for my $rel (qw(HasCompoundAliasFrom HasReactionAliasFrom)) {
        print "Processing $rel\n";
        $stats->Add(rels => 1);
        my @sources = $cdmi->GetFlat($rel, "", [], 'from-link');
        print scalar(@sources) . " source records found.\n";
        for my $source (@sources) {
            $sources{$source} = 1;
            $stats->Add(sourceIn => 1);
        }
    }
    # Delete the bad sources.
    my @badSources = $cdmi->GetFlat("Source", "Source(id) LIKE ?",
            ['kb|%'], 'id');
    print scalar(@badSources) . " bad sources found.\n";
    print "Deleting bad sources.\n";
    for my $badSource (@badSources) {
        $stats->Add(badSource => 1);
        my $newStats = $cdmi->Delete(Source => $badSource);
        $stats->Accumulate($newStats);
    }
    # Add the good sources.
    print "Adding good sources.\n";
    for my $source (sort keys %sources) {
        if ($cdmi->Exists(Source => $source)) {
            $stats->Add(sourceFound => 1);
        } else {
            $cdmi->InsertObject('Source', id => $source);
            $stats->Add(sourceAdded => 1);
        }
    }
    # All print.
    print "All done:\n" . $stats->Show();

