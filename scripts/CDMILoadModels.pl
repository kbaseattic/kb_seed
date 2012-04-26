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
use Bio::KBase::CDMI::CDMILoader;
use Bio::KBase::CDMI::CDMI;

=head1 Model Data Load Script for CDMI

    CDMILoadModels [options] <inDirectory>

=head2 Introduction

This script processes Model data files and loads them into the
Kbase Central Data Model.

Dates in the input file are in the format

B<YYYY>C<->B<MM>C<->B<DD>C<T>B<HH>C<:>B<MM>C<:>B<SS>

and must be converted into a number of seconds since the base date. If
a date is the empty string, it will be converted to the base date.

The following files are processed by this script. All are tab-delimited
files with a heading line.

=over 4

=item Biomass.dtx

=item BiomassCompound.dtx

=item compartment.dtx

=item complex.dtx

=item complexName.dtx

=item compound.dtx

=item hasCompoundAliasFrom.dtx

=item hasPresenceOf

=item hasReactionAliasFrom

=item hasStep

=item HasUsage

=item Involves

=item IsARequirementIn

=item IsComprisedOf

=item IsDivisionOf

=item IsInstantiatedBy

=item IsRealLocationOf

=item IsTargetOfRelationship

=item isTriggeredBy

=item isUsedAs

=item Manages

=item media

=item Model

=item ModelCompartment

=item ParticipatesAs

=item reaction

=item reactionComplex

=item Reagent

=item Requirement

=item Requires

=back

=head2 Command-Line Options

The command-line options are those specified in L<CDMI/new_for_script>.

=head2 Positional Parameters

=over 4

=item inDirectory

Name of the directory containing the model data files.

=back

=cut

    # Get the directories.
    my ($inDirectory) = @ARGV;
    if (! $inDirectory) {
        die "No input directory specified.";
    } elsif (! -d $inDirectory) {
        die "Invalid input directory $inDirectory.";
    }
    # Connect to the CDMI and create the loader object.
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Get the statistics object.
    my $stats = $loader->stats;
    # Alias sources will be cached in here.
    my %sources;
    # Clear the tables.
    my @tables = qw(Biomass BiomassCompound Compartment Complex
                    ComplexName Compound HasCompoundAliasFrom HasPresenceOf
                    HasReactionAliasFrom HasStep HasUsage Involves
                    IsARequirementIn IsComprisedOf IsDividedInto
                    IsInstantiatedBy IsRealLocationOf IsDefaultLocationOf
                    IsTargetOf IsTriggeredBy IsUsedAs IsProposedLocationOf
                    Manages Media Model ModelCompartment ParticipatesAs
                    Reaction ReactionRule Reagent Requirement
                    IsRequiredBy);
    for my $table (@tables) {
        print "Recreating $table.\n";
        $cdmi->CreateTable($table, 1);
    }
    # Initialize the relation loaders.
    $loader->SetRelations(@tables);
    # Process the Reagent file. This one requires special handling. We need
    # to track how many times each compound occurs as a Reagent. Those
    # that occur more than 25 times will be marked ubiquitous. This
    # file also produces two different tables.
    print "Processing Reagent file.\n";
    my ($ih, @fields);
    my %compoundCounts;
    open($ih, "<$inDirectory/Reagent.dtx") || die "Could not open Reagent.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(ReagentIn => 1);
        $loader->ConvertFileRecord('Reagent', 'SEED', \@fields,
                { id => [3, 'copy'], cofactor => [0, 'copy', 0],
                  compartment_index => [2, 'copy', 0],
                  stoichiometry => [4, 'copy', 1],
                  transport_coefficient => [5, 'copy', 0] });
        $stats->Add(ReagentOut => 1);
        # Compute the compound ID for the compound counting.
        my $compoundID = substr($fields[3], length($fields[3]/2));
        $compoundCounts{$compoundID}++;
        # Output IsDefaultLocationOf.
        $loader->ConvertFileRecord('IsDefaultLocationOf', 'SEED', \@fields,
                { from_link => [1, 'copy'], to_link => [3, 'copy'] });
        $stats->Add(IsDefaultLocationOf => 1);
    }
    close $ih; undef $ih;
    # With the compound counts available, we can now load the Compound
    # table.
    print "Processing compound file.\n";
    open($ih, "<$inDirectory/compound.dtx") || die "Could not open compound.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(compoundIn => 1);
        # Compute the ubiquity flag.
        my $ubiquitous = ($compoundCounts{$fields[2]} >= 25 ? 1 : 0);
        $loader->ConvertFileRecord('Compound', 'SEED', \@fields,
                { id => [2, 'copy'], abbr => [0, 'copy'],
                  label => [3, 'copy'], mass => [4, 'copy', 0],
                  mod_date => [5, 'timeStamp'], formula => [1, 'copy', ''],
                  uncharged_formula => [7, 'copy', ''],
                  msid => [6, 'copy'],
                  ubiquitous => [undef, 'copy', $ubiquitous] });
            $stats->Add(CompoundOut => 1);
    }
    close $ih; undef $ih;
    # Process the simple files.
    SimpleLoad($loader, 'Biomass', 'Biomass', { id => [0, 'copy'],
            mod_date => [1, 'timeStamp', 0], name => [2, 'copy'] });
    SimpleLoad($loader, 'BiomassCompound', 'BiomassCompound',
            { id => [1, 'copy'], coefficient => [0, 'copy']});
    SimpleLoad($loader, 'compartment', 'Compartment', { id => [1, 'copy'],
            abbr => [0, 'copy'], mod_date => [2, 'timeStamp'],
            msid => [3, 'copy'], name => [4, 'copy'] });
    SimpleLoad($loader, 'complex', 'Complex', { id => [0, 'copy'],
            mod_date => [1, 'timeStamp'], msid => [2, 'copy']});
    SimpleLoad($loader, 'hasCompoundAliasFrom', 'HasCompoundAliasFrom',
            { from_link => [1, 'copy'], to_link => [2, 'copy'],
            alias => [0, 'copy']});
    SimpleLoad($loader, 'hasPresenceOf', 'HasPresenceOf',
            { from_link => [1, 'copy'], to_link => [4, 'copy'],
            concentration => [0, 'copy'], maximum_flux => [2, 'copy', 100],
            minimum_flux => [3, 'copy', -100]});
    SimpleLoad($loader, 'hasReactionAliasFrom', 'HasReactionAliasFrom',
            { from_link => [1, 'copy'], to_link => [2, 'copy'],
            alias => [0, 'copy']});
    SimpleLoad($loader, 'hasStep', 'HasStep', { from_link => [0, 'copy'],
            to_link => [1, 'copy']});
    SimpleLoad($loader, 'HasUsage', 'HasUsage', { from_link => [0, 'copy'],
            to_link => [1, 'copy']});
    SimpleLoad($loader, 'Involves', 'Involves', { from_link => [0, 'copy'],
            to_link => [1, 'copy']});
    SimpleLoad($loader, 'IsARequirementIn', 'IsARequirementIn',
            { from_link => [0, 'copy'], to_link => [1, 'copy']});
    SimpleLoad($loader, 'IsComprisedOf', 'IsComprisedOf',
            { from_link => [0, 'copy'], to_link => [1, 'copy']});
    SimpleLoad($loader, 'IsDivisionOf', 'IsDividedInto',
            { from_link => [0, 'copy'], to_link => [1, 'copy']});
    SimpleLoad($loader, 'IsInstantiatedBy', 'IsInstantiatedBy',
            { from_link => [0, 'copy'], to_link => [1, 'copy']});
    SimpleLoad($loader, 'IsRealLocationOf', 'IsRealLocationOf',
            { from_link => [0, 'copy'], to_link => [1, 'copy'],
            type => [2, 'copy', 'primary']});
    SimpleLoad($loader, 'IsTargetOfRelationship', 'IsTargetOf',
            { from_link => [0, 'copy'], to_link => [1, 'copy']});
    SimpleLoad($loader, 'isTriggeredBy', 'IsTriggeredBy',
            { from_link => [0, 'copy'], optional => [2, 'copy', 0],
            to_link => [3, 'copy'], type => [4, 'copy', 'G']});
    SimpleLoad($loader, 'isUsedAs', 'IsUsedAs', { from_link => [0, 'copy'],
            to_link => [1, 'copy']});
    SimpleLoad($loader, 'Manages', 'Manages', { from_link => [0, 'copy'],
            to_link => [1, 'copy']});
    SimpleLoad($loader, 'media', 'Media', { id => [0, 'copy'],
            mod_date => [1, 'timeStamp', 0], name => [2, 'copy'],
            type => [3, 'copy', 'aerobic']});
    SimpleLoad($loader, 'Model', 'Model', { id=> [2, 'copy'],
            annotation_count => [0, 'copy', 0],
            compound_count => [1, 'copy', 0],
            mod_date => [3, 'timeStamp', 0], name => [4, 'copy'],
            reaction_count => [5, 'copy', 0], status => [6, 'copy', ''],
            type => [7, 'copy', ''], version => [8, 'copy', 0]});
    SimpleLoad($loader, 'ModelCompartment', 'ModelCompartment',
            { id => [1, 'copy'], compartment_index => [0, 'copy', 0],
            pH => [2, 'copy', 7], potential => [3, 'copy', 0]});
    SimpleLoad($loader, 'ParticipatesAs', 'ParticipatesAs',
            { from_link => [0, 'copy'], to_link => [1, 'copy']});
    SimpleLoad($loader, 'reaction', 'Reaction', { id => [2, 'copy'],
            abbr => [0, 'copy'], equation => [1, 'copy'],
            mod_date => [3, 'timeStamp'], msid => [4, 'copy'],
            name => [5, 'copy', ''], reversibility => [6, 'copy', '=']});
    SimpleLoad($loader, 'Requirement', 'Requirement', { id => [1, 'copy'],
            direction => [0, 'copy'], proton => [2, 'copy', 0],
            transproton => [3, 'copy', 0]});
    SimpleLoad($loader, 'Requires', 'IsRequiredBy', { from_link => [0, 'copy'],
            to_link => [1, 'copy']});
    # ComplexName is tricky because we only want to output records
    # with a nonempty name.
    print "Processing complexName file.\n";
    open($ih, "<$inDirectory/complexName.dtx") || die "Could not open complexName.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(complexNameIn => 1);
        if ($fields[2]) {
            $loader->ConvertFileRecord('ComplexName', 'SEED', \@fields,
                    { id => [0, 'copy'], name => [2, 'copy'] });
            $stats->Add(ComplexNameOut => 1);
        }
    }
    # The reactionComplex file actually produces multiple relations.
    print "Processing reactionComplex file.\n";
    open($ih, "<$inDirectory/reactionComplex.dtx") || die "Could not open reactionComplex.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(reactionComplexIn => 1);
        $loader->ConvertFileRecord('ReactionRule', 'SEED', \@fields,
                { direction => [1, 'copy'], id => [2, 'copy'],
                  transproton => [4, 'copy', 0] });
        $stats->Add(ReactionRuleOut => 1);
        $loader->ConvertFileRecord('IsProposedLocationOf', 'SEED', \@fields,
                { from_link => [0, 'copy'], to_link => [2, 'copy'],
                  type => [5, 'copy', ''] });
        $stats->Add(IsProposedLocationOfOut => 1);
    }
    # The Reagent file also produces multiple relations.
    print "Processing reagent file.\n";
    open($ih, "<$inDirectory/Reagent.dtx") || die "Could not open Reagent.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(ReagentIn => 1);
        $loader->ConvertFileRecord('Reagent', 'SEED', \@fields,
                { id => [3, 'copy'], cofactor => [0, 'copy', 0],
                compartment_index => [2, 'copy', 0],
                stoichiometry => [4, 'copy', 1],
                transport_coefficient => [5, 'copy', 0]});
        $stats->Add(ReagentOut => 1);
        $loader->ConvertFileRecord('IsDefaultLocationOf', 'SEED', \@fields,
                { from_link => [1, 'copy'], to_link => [3, 'copy'] });
        $stats->Add(IsDefaultLocationOfOut => 1);
    }
    close $ih; undef $ih;
    # Unspool the relation loaders.
    print "Loading database relations.\n";
    $loader->LoadRelations();
    print "All done: " . $stats->Show();

# Perform a simple load of the $fileName into the $tableName using the
# $instructions hash.
sub SimpleLoad {
    my ($loader, $fileName, $tableName, $instructions) = @_;
    # Open the input file.
    print "Processing $tableName file.\n";
    open(my $ih, "<$inDirectory/$fileName.dtx") || die "Could not open $fileName.dtx: $!\n";
    # Skip the header record.
    my @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(($fileName . 'In') => 1);
        $loader->ConvertFileRecord($tableName, 'SEED', \@fields,
            $instructions);
        $stats->Add(($tableName . "Out") => 1);
    }
    close $ih;
}