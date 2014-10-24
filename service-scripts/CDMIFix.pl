### Emergency fixup script for CDMI.

use strict;
use Stats;
use SeedUtils;
use Bio::KBase::CDMI::GenomeUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $stats = Stats->new();
    open my $oh, ">$ARGV[0]" || die "Could not open output file.";
    # Get the SEED genome directories.
    my @genomes = grep { $_ =~ /^\d+\.\d+$/ } 
        Bio::KBase::CDMI::GenomeUtils::OpenDir($FIG_Config::organisms);
    # Loop through the genomes found.
    for my $genome (@genomes) {
        my $genomeDir = "$FIG_Config::organisms/$genome";
        open(my $gh, "<$genomeDir/GENOME") || die "Could not open name file for $genome.";
        my $gname = <$gh>;
        chomp $gname;
        my $gline = "$genome\t$gname\n";
        my $taxFile = "$genomeDir/TAXONOMY";
        if (! -f $taxFile) {
        	print "Could not find taxonomy file for $genome.\n";
        	print $oh $gline;
        	$stats->Add(taxNotFound => 1);
        } elsif (! open(my $ih, "<$taxFile")) {
        	print "Could not open taxonomy file for $genome.\n";
        	print $oh $gline;
        } else {
        	my $taxLine = <$ih>;
        	$stats->Add(taxRead => 1);
        	if ($taxLine =~ /^Eukaryota/i) {
        		print "$genome is a Eukaryote.\n";
        		print $oh $gline;
        		$stats->Add(eukFound => 1);
        	} elsif ($taxLine =~ /^Meta|^Comm/i) {
        		print "$genome is a community.\n";
        		print $oh $gline;
        		$stats->Add(metaFound => 1);
        	}
        }
    }
    close $oh;
	print "All done.\n" . $stats->Show();