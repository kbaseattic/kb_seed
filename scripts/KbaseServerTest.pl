### Test program for Ross's project.

use strict;
use SeedUtils;
use Bio::KBase::CDMI::CDMI;
require Bio::KBase::CDMI::CDMI_APIImpl;

    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $kbO = Bio::KBase::CDMI::CDMI_APIImpl->new($cdmi);
    my @fids = qw(kb|g.237.peg.1 kb|g.1068.peg.914 kb|g.0.peg.4288);
    my @fidTypes = qw(crispr rna);
    my @fidPairs = (['kb|g.0.peg.2173', 'kb|g.0.peg.4288'],
                    ['kb|g.1068.peg.914', 'kb|g.1068.peg.529']);
    my @regions = qw(kb|MOL|103782:52814_0+4000 kb|SEED|83333.1:NC_000913_3000+2000 kb|SEED|360108.4:NZ_AANK01000003_185000-1000);
    my @locs = ([['kb|MOL|103782:52814',10,'+',100],['kb|MOL|103782:52814',110,'+',50]],
                [['kb|SEED|83333.1:NC_000913', 2020, '-', 110]]);
    my @prots = qw(00000de6b0798452314fd6e2af8e8652
                   00034076a8e2a95ef84c39e1504348b8
                   000351ef2b99f1af4d90b5d6ab26fd78
                   00034442a5a166de821349dd8fc0d102
                   057e0552d7cf597bc3935965c9996c81
                   015d00c9b7f7f2897a9ebd700c9a9d69);
    my @roles = ('putative histidine autokinase',
                 'tubby family protein',
                 'Beta-fimbriae usher protein',
                 'HTH-type transcriptional regulator PtxR');
    my @fams = qw(FIG00000134 FIG00000174 FIG00000141);
    my @contigs = qw(kb|MOL|103782:52814 kb|SEED|553973.6:NZ_GG657770);
    my @genomeMD5s = qw(415d0675326bf70a88be20d84c6a415c
                        b4ff0a0fea9686b26b4e2a3cf7b6adbf);
    my @genomes = qw(kb|g.0 kb|g.237 kb|g.1068 kb|g.3899);
    my @subs = ('Ribosome LSU bacterial', 'tRNA nucleotidyltransferase');

    my $result;

    $result = $kbO->subsystems_to_spreadsheets(undef, \@subs, \@genomes);
    print "subsystems_to_spreadsheets.\n";
    for my $sub (sort keys %$result) {
        print "$sub:\n";
        my $sheet = $result->{$sub};
        for my $genome (sort keys %$sheet) {
            print "  $genome:\n";
            my $rows = $sheet->{$genome};
            for my $row (@$rows) {
                my ($variant, $roleH) = @$row;
                print "    $variant:\n";
                for my $role (sort keys %$roleH) {
                    print "      $role: " . join(", ", @{$roleH->{$role}}) . "\n";
                }
            }
        }
        print "\n";
    }
    print "\n";

    $result = $kbO->fids_to_literature(undef, \@fids);
    print "fids_to_literature.\n";
    PrintListResult($result);
    print "\n";

    $result = $kbO->fids_to_roles(undef, \@fids);
    print "fids_to_roles.\n";
    PrintNormalResult($result);

    $result = $kbO->fids_to_functions(undef, \@fids);
    print "fids_to_functions.\n";
    PrintStringResult($result);

    $result = $kbO->fids_to_protein_families(undef, \@fids);
    print "fids_to_protein_families.\n";
    PrintNormalResult($result);

    $result = $kbO->fids_to_subsystems(undef, \@fids);
    print "fids_to_subsystems.\n";
    PrintNormalResult($result);

    $result = $kbO->genomes_to_fids(undef, \@genomes, []);
    print "fids_to_genomes (all).\n";
    PrintNormalResult($result);

    $result = $kbO->genomes_to_fids(undef, \@genomes, \@fidTypes);
    print "fids_to_genomes (typed).\n";
    PrintNormalResult($result);

    $result = $kbO->fids_to_co_occurring_fids(undef, \@fids);
    print "fids_to_co_occurring_fids.\n";
    PrintListResult($result);

    $result = $kbO->co_occurrence_evidence(undef, \@fidPairs);
    print "co_occurrence_evidence.\n";
    for my $evidence (@$result) {
        my ($pair, $evidenceList) = @$evidence;
        print join(", ", @$pair) . "\n";
       for my $evidenceItem (@$evidenceList) {
           print "  " . join(", ", @$evidenceItem) . "\n";
       }
        print "\n";
    }
    print "\n";
    $result = $kbO->fids_to_locations(undef, \@fids);
    print "fids_to_locations.\n";
    for my $fid (keys %$result) {
        my $locs = $result->{$fid};
        my @locStrings = map { join("", $_->[0], "_", $_->[1], $_->[2], $_->[3]) } @$locs;
        print "$fid: " . join(", ", @locStrings) . "\n";
    }
    print "\n";

    $result = $kbO->locations_to_fids(undef, \@regions);
    print "locations_to_fids.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->locations_to_dna_sequences(undef, \@locs);
    print "locations_to_dna_sequences.\n";
    for my $tuple (@$result) {
        my ($location, $dna) = @$tuple;
        my $locString = join(",", map { $_->[0] . "_" . $_->[1] . $_->[2] . $_->[3] } @$location);
        print "$locString: $dna\n";
    }
    print "\n";

    $result = $kbO->proteins_to_fids(undef, \@prots);
    print "proteins_to_fids.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->proteins_to_protein_families(undef, \@prots);
    print "proteins_to_protein_families.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->proteins_to_literature(undef, \@prots);
    print "proteins_to_literature.\n";
    PrintListResult($result);
    print "\n";

    $result = $kbO->proteins_to_functions(undef, \@prots);
    print "proteins_to_functions.\n";
    PrintListResult($result);
    print "\n";

    $result = $kbO->proteins_to_roles(undef, \@prots);
    print "proteins_to_roles.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->roles_to_subsystems(undef, \@roles);
    print "roles_to_subsystems.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->roles_to_protein_families(undef, \@roles);
    print "roles_to_protein_families.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->protein_families_to_fids(undef, \@fams);
    print "protein_families_to_fids.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->protein_families_to_functions(undef, \@fams);
    print "protein_families_to_functions.\n";
    PrintListResult($result);
    print "\n";

    $result = $kbO->contigs_to_sequences(undef, \@contigs);
    print "contigs_to_sequences.\n";
    PrintStringResult($result);
    print "\n";

    $result = $kbO->contigs_to_lengths(undef, \@contigs);
    print "contigs_to_lengths.\n";
    PrintStringResult($result);
    print "\n";

    $result = $kbO->contigs_to_md5s(undef, \@contigs);
    print "contigs_to_md5s.\n";
    PrintStringResult($result);
    print "\n";

    $result = $kbO->md5s_to_genomes(undef, \@genomeMD5s);
    print "md5s_to_genomes.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->genomes_to_md5s(undef, \@genomes);
    print "genomes_to_md5s.\n";
    PrintStringResult($result);
    print "\n";

    $result = $kbO->genomes_to_contigs(undef, \@genomes);
    print "genomes_to_contigs.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->genomes_to_taxonomies(undef, \@genomes);
    print "genomes_to_taxonomies.\n";
    PrintNormalResult($result);
    print "\n";

    $result = $kbO->genomes_to_subsystems(undef, \@genomes);
    print "genomes_to_subsystems.\n";
    PrintListResult($result);
    print "\n";

    $result = $kbO->subsystems_to_genomes(undef, \@subs);
    print "subsystems_to_genomes.\n";
    PrintListResult($result);
    print "\n";

    $result = $kbO->subsystems_to_fids(undef, \@subs, \@genomes);
    for my $sub (sort keys %$result) {
        print "$sub:\n";
        my $genomeH = $result->{$sub};
        for my $genome (sort keys %$genomeH) {
            print "   $genome:\n";
            my $rows = $genomeH->{$genome};
            for my $row (@$rows) {
                my ($variant, $fids) = @$row;
                print "      $variant:\n";
                for my $fid (@$fids) {
                    print "         $fid\n";
                }
            }
        }
        print "\n";
    }
    print "\n";

    $result = $kbO->subsystems_to_roles(undef, \@subs);
    print "subsystems_to_roles.\n";
    PrintNormalResult($result);

    print "Done.\n";

sub PrintNormalResult {
    my ($result) = @_;
    for my $fid (sort keys %$result) {
        my $values = $result->{$fid};
        print "$fid:\n";
        for my $value (@$values) {
            print "    $value\n";
        }
        print "\n";
    }
}

sub PrintStringResult {
    my ($result) = @_;
    for my $fid (sort keys %$result) {
        my $value = $result->{$fid};
        print "$fid: $value\n";
    }
}

sub PrintListResult {
    my ($result) = @_;
    for my $prot (keys %$result) {
        my $pubs = $result->{$prot};
        print "$prot:\n";
        for my $pub (@$pubs) {
            print "    " . join(", ", @$pub) . "\n";
        }
        print "\n";
    }

}