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
use SeedEnv;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use RelationLoader;

my $sapO = SAPserver->new;
my $id_server_url = "http://bio-data-1.mcs.anl.gov:8080/services/idserver";


my $hasMember = RelationLoader->new('HasMember', [qw(from_link to_link)]);
my $isFamilyFor = RelationLoader->new('IsFamilyFor', [qw(from_link to_link)]);
my $hasRepresentativeOf = RelationLoader->new('HasRepresentativeOf', [qw(from_link to_link)]);
# my $isCoupledTo = RelationLoader->new('IsCoupledTo', [qw(from_link to_link co_expression_evidence co_occurrence_evidence)]);
my @rels = ($hasMember, $isFamilyFor, $hasRepresentativeOf);
# Connect to the database.
my $cdmi = CDMI->new_for_script("idserver=s" => \$id_server_url);
if (! $cdmi) {
    print "usage: CDMILoadFIGfams\n";
} else {
    # Connect to the KBID server and create the loader utility object.
    my $id_server = IDServerAPIClient->new($id_server_url);
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi, $id_server);
    my @tables = qw(Family FamilyFunction IsFamilyFor HasMember IsCoupledTo HasRepresentativeOf);

    for my $table (@tables) {
        print "Recreating $table.\n";
        $cdmi->CreateTable($table, 1);
    }
    my $ffH = $sapO->all_figfams;
    foreach my $ff (sort keys(%$ffH))
    {
        LoadFamily($loader,$ff,$ffH->{$ff});
    }
    for my $rel (@rels) {
        $rel->load();
    }
    # Display the statistics.
    print "All done.\n" . $loader->stats->Show();
}

sub LoadFamily {
    my ($loader,$ff,$function) = @_;

    print STDERR "Loading $ff\n";

    if (! $function ) { $function = 'hypothetical protein' }

    $cdmi->InsertObject('Family', id => $ff, 'family-function' => [$function], type => 'FIGfam');
    $loader->stats->Add(addedFamily => 1);
    my $pegs = $sapO->figfam_fids( -id => $ff);
    my %genomes = map { (&SeedUtils::genome_of($_) => 1) } @$pegs;
    my $kbase_peg_idsH = $loader->get_kbase_ids('SEED',$pegs);
    my $kbase_genome_idsH = $loader->get_kbase_ids('SEED',[keys(%genomes)]);
#    my $relatedH  = $sapO->related_figfams( -ids => [$ff], -all => 1);
#    foreach my $tuple (@{$relatedH->{$ff}})
#    {
#        my($other,$scores) = @$tuple;
#        my($fc,$exp)       = @$scores;
#        $isCoupledTo->($ff, $other, $exp, $fc);
#    }

    my @roles = &SeedUtils::roles_of_function($function);
    foreach my $role (@roles) {
	    my $roleID = $loader->CheckRole($role);
	    $isFamilyFor->add($ff, $roleID);
    }
    foreach my $peg (@$pegs) {
        $hasMember->add($ff, $kbase_peg_idsH->{$peg});
    }

    foreach my $g (sort { $a <=> $b } keys(%genomes))
    {
	$hasRepresentativeOf->($kbase_genome_idsH->{$g}, $ff);
    }
}
