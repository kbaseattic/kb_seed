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
    use Bio::KBase::CDMI::GenomeUtils;


=head1 CDMI Test Script

    CDMITest [options] figDirectory blacklist

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script>. The
positional parameters are the FIG organism directory and the blacklist file.

=cut

my $stats = Stats->new();
$| = 1;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMITest [options] figDirectory\n";
} else {
	my ($figDir, $blackList) = @ARGV;
	if (! $figDir || ! -d $figDir) {
		die "Invalid or missing FIG organism directory.";
	}
	$FIG_Config::organisms = $figDir;
    # Create the blacklist.
    my %blackListH;
    if ($blackList) {
        print "Reading genome blacklist from $blackList.\n";
        my @lines = Bio::KBase::CDMI::GenomeUtils::GetFile($blackList);
        for my $line (@lines) {
            my ($genomeID) = split /\t/, $line, 2;
            $blackListH{$genomeID} = 1;
            $stats->Add('blacklist-genomes' => 1);
        }
        print scalar(keys %blackListH) . " genome IDs read from blacklist file.\n";
    }
    print "Finding SEED genomes.\n";
    my $seedGenomes = Bio::KBase::CDMI::GenomeUtils::GetSeedGenomeHash($stats,
        \%blackListH);
    # Compare to the database.
    my %kbGenomes = map { $_->[0] => $_->[1] } $cdmi->GetAll('Submitted Genome', 'Submitted(from-link) = ?', ['SEED'], 'Genome(source-id) Genome(md5)');
    for my $kbGenome (sort keys %kbGenomes) {
    	if (exists $seedGenomes->{$kbGenome}) {
    		my $seedMd5 = $seedGenomes->{$kbGenome};
    		my $kbMd5 = $kbGenomes{$kbGenome};
    		if ($seedMd5 ne $kbMd5) {
    			print "MD5 mismatch for $kbGenome.\n";
    			$stats->Add(mismatch => 1);
    		} else {
    			$stats->Add(match => 1);
    		}
    	} else {
    		$stats->Add(skipped => 1);
    	}
    }
    print "All done:\n" . $stats->Show();
}