#!/usr/bin/perl -w

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#

    use strict;
    use Stats;
    use SeedUtils;
    use Data::Dumper;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;


=head1 CDMI Test Script

    CDMITest [options]

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script>. There are
no positional parameters.

=cut

$| = 1;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMITest [options]\n";
} else {
    my @rows = $cdmi->GetAll('Genome WasSubmittedBy',
            'ORDER BY Genome(scientific-name), Genome(md5)', [],
            'id scientific-name source-id md5 WasSubmittedBy(to-link)');
    my $speciesID = "";
    my $stats = Stats->new();
    my (%md5s,%sources, @saved);
    for my $row (@rows) {
        $stats->Add(genomes => 1);
        my ($id, $name, $sourceID, $md5, $sourceDB) = @$row;
        my ($genus, $species, $other) = split /\s+/, $name, 3;
        my $newSpeciesID = "$genus $species";
        if ($newSpeciesID ne $speciesID) {
            DisplaySpecies($stats, $speciesID, \%md5s, \%sources, \@saved);
            $speciesID = $newSpeciesID;
            %md5s = ();
            %sources = ();
            @saved = ();
        }
        push @saved, $row;
        $md5s{$md5}++;
        $sources{$sourceDB}++;
    }
    DisplaySpecies($stats, $speciesID, \%md5s, \%sources, \@saved);
    print "All done.\n" . $stats->Show();;
}

sub DisplaySpecies {
    my ($stats, $speciesID, $md5s, $sources, $saved) = @_;
    my $count = scalar @$saved;
    $stats->Add(groups => 1) if $count > 0;
    if ($count > 1) {
        $stats->Add("group$count" => 1);
        my $seqCount = scalar(keys %$md5s);
        if ($seqCount < $count) {
            print "*** WARNING: Duplicate sequence in $speciesID.\n";
            $stats->Add(badgroups => 1);
        }
        print "$speciesID: $count genomes, $seqCount unique sequences from " .
                scalar(keys %$sources) . " source databases.\n";
        for my $row (@$saved) {
            print join("\t", "", @$row) . "\n";
        }
        print "\n";
    }
}

