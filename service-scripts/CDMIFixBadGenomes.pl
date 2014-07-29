### Emergency fixup script for CDMI.

use strict;
use Stats;
use Bio::KBase::CDMI::CDMI;
use FIG;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $stats = Stats->new();
    # Get all the genomes in the CDMI.
    my %genomes = map { $_->[0] => [$_->[1], $_->[2]] } $cdmi->GetAll('Submitted Genome', 
            '', [], 
            'Genome(id) Genome(source-id) Genome(scientific-name) Submitted(from-link)');
    # Loop through them.
    for my $genome (sort keys %genomes) {
        $stats->Add(genomes => 1);
        # Get the source ID and name for this genome.
        my $seedID = $genomes{$genome}[0];
        my $name = $genomes{$genome}[1];
        my $source = $genomes{$genome}[2];
        if ($source eq 'SEED') {
	        # Check the SEED taxonomy.
	        my $taxFile = "$FIG_Config::organisms/$seedID/TAXONOMY";
	        # Check for a taxonomy group.
	        my ($groupInfo) = $cdmi->GetFlat('Genome IsInTaxa', 'Genome(id) = ?',
	                [$genome], 'IsInTaxa(to-link)');
	        my $groupNum = $groupInfo || 'NONE';
	        if (open my $ih, "<$taxFile") {
	            my $line = <$ih>;
	            if ($line =~ /metagenomes/i) {
	                $stats->Add(metagenome => 1);
	                print "Metagenome taxonomy: $genome $seedID: $name in $groupNum\n";
	                print "TAX: $line";
	                print "Deleting genome.\n";
	                my $delStats = $cdmi->Delete(Genome => $genome);
	                $stats->Accumulate($delStats);
	            } elsif ($line =~ /environmental\s+samples/) {
	                $stats->Add(envirogenome => 1);
	                print "Environmental taxonomy: $genome $seedID: $name in $groupNum\n";
	                print "TAX: $line";
	                print "Deleting genome.\n";
	                my $delStats = $cdmi->Delete(Genome => $genome);
	                $stats->Accumulate($delStats);
	            } else {
	                if (! $groupInfo) {
	                    $stats->Add(lostGenome => 1);
	                    print "No taxa found for $genome: $seedID $name.\n";
	                    print "TAX: $line";
	                    $seedID =~ /(\d+)\.\d+/;
	                    my $taxID = $1;
	                    my ($taxName) = $cdmi->GetFlat('TaxonomicGrouping', 'TaxonomicGrouping(id) = ?',
	                            [$taxID], 'scientific-name');
	                    if (! defined $taxName) {
	                        print "Taxonomic grouping $taxID does not exist.\n";
	                        $stats->Add(lostTaxa => 1);
	                    } else {
	                        print "Repairing taxonomy for $genome: $taxName.\n";
	                        $cdmi->InsertObject('IsTaxonomyOf', from_link => $taxID, to_link => $genome);
	                        $stats->Add(fixedTaxonomy => 1);
	                    }
	                }
	            }
	        } else {
	            print "Could not open tax file for genome $genome $seedID ($name).\n";
	            $stats->Add(badOpen => 1);
	        }
        } else {
        	
        }
    }
    print "All done:\n" . $stats->Show();
