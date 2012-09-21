### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use Data::Dumper;

    $| = 1; # Prevent buffering on STDOUT.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my @genomes = $cdmi->GetFlat('Genome', '', [], 'id');
    my $stats = Stats->new();
    for my $genome (@genomes) {
        print "Processing $genome.\n";
        my @locs = $cdmi->GetAll('IsLocatedIn', "IsLocatedIn(from-link) LIKE ? ORDER BY IsLocatedIn(from-link), IsLocatedIn(ordinal)", ["$genome%"],
            "from-link ordinal begin dir len to-link");
        my ($oldFid, $oldOrdinal, $oldBegin, $oldDir, $oldLen, $oldContig) =
            ("", "", "", "", "", "", "");
        print scalar(@locs) . " location records found for $genome.\n";
        my $dups = 0;
        for my $loc (@locs) {
            my ($fid, $ordinal, $begin, $dir, $len, $contig) = @$loc;
            if ($fid eq $oldFid && $begin eq $oldBegin && $ordinal eq $oldOrdinal) {
                $dups++;
                # We need to delete one of the duplicates, but our only choice
                # is to delete both, so we add one back afterward.
                $cdmi->DeleteRow('IsLocatedIn', $fid, $contig, {ordinal => $ordinal});
                $cdmi->InsertObject('IsLocatedIn', from_link => $fid,
                    to_link => $contig, ordinal => $ordinal, begin => $begin,
                    dir => $dir, len => $len);
            }
            ($oldFid, $oldOrdinal, $oldBegin, $oldDir, $oldLen, $oldContig) =
                ($fid, $ordinal, $begin, $dir, $len, $contig);
        }
        print "$dups duplicates fixed in $genome.\n";
        $stats->Add(genomes => 1);
        $stats->Add(dups => $dups);
    }
    print "All done:\n" . $stats->Show();
