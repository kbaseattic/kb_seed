### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Stats;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $stats = Stats->new();
    # Drop the old assertion tables.
    my $dbh = $cdmi->{_dbh};
    my @badTables = qw(Identifier Imported HasAssertionFrom IsNamedBy);
    for my $table (@badTables) {
        print "Dropping $table.\n";
        $dbh->drop_table(tbl => $table);
        $stats->Add(tablesDropped => 1);
    }
    # Create the new tables.
    $cdmi->CreateTable('FeatureAlias');
    $cdmi->CreateTable('AssertsFunctionFor');
    # Loop through all the genomes.
    my @genomePairs = $cdmi->GetAll('Submitted Genome', '', [], "Submitted(from-link) Genome(id)");
    print scalar(@genomePairs) . " genomes found in database.\n";
    for my $genomePair (@genomePairs) {
        my ($source, $genome) = @$genomePair;
        $stats->Add($source => 1);
        $stats->Add(foundGenome => 1);
        print "Processing $genome from $source.\n";
        if ($source eq 'MOL') {
            # If this is an MOL genome, delete it.
            print "Deleting $genome.\n";
            my $newStats = $cdmi->Delete(Genome => $genome);
            $stats->Accumulate($newStats);
            $stats->Add(deletedGenome => 1);
        } else {
            # Otherwise, convert pegs to CDSs.
            my @fids = $cdmi->GetFlat('Feature', 'Feature(id) LIKE ? AND Feature(feature-type) = ?',
                ["$genome.%", 'peg'], 'id');
            print scalar(@fids) . " pegs found in $genome.\n";
            for my $fid (@fids) {
                $cdmi->UpdateEntity(Feature => $fid, feature_type => 'CDS');
                $stats->Add(pegFix => 1);
            }
        }
    }
    print "All done:\n" . $stats->Show();
