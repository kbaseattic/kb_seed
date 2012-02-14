# -*- perl -*-
#       This is a SAS Component.
########################################################################
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
########################################################################

# usage:  svr_genbank_to_seed  OrgDir genbank.file

use strict;
use warnings;

use FIGV;
use gjogenbank;
use gjoseqlib;

use File::Path;
use Data::Dumper;

my ($org_dir, $genbank_file) = @ARGV;
my ($taxID) = ($org_dir =~ m/(\d+\.\d+)$/o);

my $rc;
($rc = mkpath($org_dir)) || die qq(Could not create OrgDir \'$org_dir\', rc=$rc);
my $figV = FIGV->new($org_dir);

my $contigs_file = $org_dir.q(/contigs);
open(my $contigs_fh, q(>), $contigs_file)
    || die qq(Could not write-open contigs file \'$contigs_file\');

print STDERR qq(got to here\n);
while(defined(my $accession = gjogenbank::parse_next_genbank($genbank_file))) {
    print STDERR qq(Got an accession\n);
    
    my $contig_id   = $accession->{LOCUS};
    my $contig_dna  = $accession->{SEQUENCE};
    print STDERR qq(Writing contig=$contig_id\n);
    $figV->display_id_and_seq( $contig_id, \$contig_dna, $contigs_fh);
    
    foreach my $cds (@ { $accession->{FEATURES}->{CDS} }) {
	my $gb_loc      = gjogenbank::location( $cds, $accession );
	my $locus       = gjogenbank::genbank_loc_2_seed($contig_id, $gb_loc);
	my $func        = gjogenbank::product( $cds ) || q();
	my $translation = gjogenbank::CDS_translation($cds);
	
	my $gene_name   = defined($cds->[1]->{gene}->[0])       ? $cds->[1]->{gene}->[0]       : q();
	my $locus_tag   = defined($cds->[1]->{locus_tag}->[0])  ? $cds->[1]->{locus_tag}->[0]  : q();
	my $protein_id  = defined($cds->[1]->{protein_id}->[0]) ? $cds->[1]->{protein_id}->[0] : q();
	
	my @db_xrefs    = defined($cds->[1]->{db_xref}->[0])    ? @ { $cds->[1]->{db_xref} }   : ();
	
	my @gi_nums     = map { m/GI\:(\d+)/o     ? (q(gi|).$1)     : () } @db_xrefs;
	my @gene_nums   = map { m/GeneID\:(\d+)/o ? (q(GeneID|).$1) : () } @db_xrefs;
	
	my @aliases     = grep { $_ } ($gene_name, $locus_tag, $protein_id, @gi_nums, @db_xrefs, @gene_nums);
	
	if ($locus && defined($func) && $translation) {
	    print STDERR qq(Writing feature at loc=$locus\n);
	    if (my $fid = $figV->add_feature(q(Initial Import), $taxID, q(peg), $locus, \@aliases, $translation)) {
		if ($func) {
		    $figV->assign_function($fid, q(master:Initial Import), $func);
		}
	    }
	    else {
		die (qq(Could not add feature\n), Dumper($cds));
	    }
	}
	else {
	    warn (qq(Could not parse CDS feature in accession '$contig_id':\n), Dumper($cds), qq(\n));
	}
    }
}
exit(0);
