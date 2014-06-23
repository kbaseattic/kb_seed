### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $stats = Stats->new();
    # Get all the contigs in the FASTA file.
    open(my $ih, "</homes/parrello/CdmiData/Plants/Genomes/new17/Oglaberrima.AGI1.1/contigs.fa") ||
        die "Could not open FASTA file.";
    my %fastaContigs;
    while (! eof $ih) {
        my $line = <$ih>;
        if ($line =~ /^>(\S+)/) {
            my $contigID = $1;
            if ($fastaContigs{$contigID}) {
                print "Duplicate contig ID $contigID.\n";
                $stats->Add(duplicateContig => 1);
            } else {
                $fastaContigs{$contigID} = 1;
                $stats->Add(fastaContig => 1);
            }
        }
    }
    print scalar(keys %fastaContigs) . " contigs read from FASTA.\n";
    # Display the genome's contig count.
    my ($count) = $cdmi->GetFlat('Genome', 'Genome(id) = ?', ['kb|g.3903'], 'contigs');
    print "$count contigs recorded in genome record.\n";
    $stats->Add(GenomeCount => $count);
    # Get the contigs for the specified genome.
    my %dbContigs = map { $_->[1] => $_->[0] } $cdmi->GetAll('IsComposedOf Contig',
        'IsComposedOf(from-link) = ?', ['kb|g.3903'], 'Contig(id) Contig(source-id)');
    $stats->Add(DbContig => scalar(keys %dbContigs));
    # Look for contigs in the FASTA that aren't in the database.
    for my $fastaContig (keys %fastaContigs) {
        if ($dbContigs{$fastaContig}) {
            $stats->Add(ContigFoundInDB => 1);
        } else {
            print "$fastaContig not found in database.\n";
            $stats->Add(ContigNotFoundInDB => 1); 
        }
    }
    # Look for contigs in the database that aren't in the FASTA.
    for my $dbContig (keys %dbContigs) {
        if ($fastaContigs{$dbContig}) {
            $stats->Add(ContigFoundInFasta => 1);
        } else {
            print "$dbContig not found in FASTA.\n";
            $stats->Add(ContigNotFoundInFasta => 1);
        }
    }
    # All done.
    print "All done:\n" . $stats->Show();

