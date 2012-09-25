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

Each record in this file corresponds to an instance of the B<Biomass>
entity. The fields are (0) the cell wall portion (cell-wall), (1) the
co-factor portion (cofactor), (2) the DNA portion (dna), (3) the ATP
molecule count (energy), (4) the KBase Biomass ID (id), (5) the lipid
portion (lipid), (6) the last modification date (mod-date), and (7) the
protein portion (protein).

=item BiomassName.dtx

Each record in this file corresponds to a B<BiomassName> record. There
is one of these for each Biomass that has a descriptive name. The
fields are (0) the KBase Biomass ID (id) and (1) the Biomass name (name).

=item complex.dtx

Each record in this file corresponds to an instance of the B<Complex>
entity record. The fields are (0) the KBase complex ID (id), (1) last
modification date (mod-date), and (2) the source id (source-id).

=item complexName.dtx

Each record in this file corresponds to a B<ComplexName> record. There
is one of these for each complex that has a descriptive name. The fields
are (0) the KBase complex ID (id) and (1) the complex name (name).

=item compound.dtx

Each record in this file represents an instance of the B<Compound>
entity. The fields are (0) the abbreviated name (abbr), (1) the default charge (charge),
(2) the energy of formation (deltaG), (3) the error in the energy-of-
formation value (deltaG-error), (4) the pH-neutral formula (formula),
(5) the KBase compound ID (id), (6) the primary name of the compound
for use in displaying reactions (label), (7) the pH-neutral atomic mass
(mass), (8) the last modification date (mod-date), and (9) the source
ID (source-id). The I<ubiquitous> field will default to FALSE, and gets
computed later.

=item CompoundInstance.dtx

Each record in this file represents an instance of the
B<CompoundInstance> entity. The fields are (0) the computed charge
(charge), (1) the formula (formula), and (2) the KBase ID (id).

=item hasCompoundAliasFrom.dtx

Each record in this file represents a relationship instance of
B<HasCompoundAliasFrom> between B<Compound> and B<Source>. The
fields are (0) the compound alias (alias), (1) the KBase compound ID
(to-link), and (2) the alias source (from-link).

=item hasPresenceOf.dtx

Each record in this file represents a relationship instnce of
B<HasPresenceOf> between B<Media> and B<Compound>. The fields
are (0) the compound concentration (concentration), (1) the KBase
ID of the media (from-link), (2) the maximum flux (maximum-flux),
(3) the minimum flux (minimum-flux), and the (4) KBase ID of the
compound (to-link).

=item hasReactionAliasFrom.dtx

Each record in this file represents a relationship instance of
B<HasReactionAliasFrom> between B<Reaction> and B<Source>. The
fields are (0) the reaction alias (alias), (1) the KBase reaction ID
(to-link), and (2) the alias source (from-link).

=item HasRequirementOf.dtx

Each record in this file represents a relationship instance of
B<HasRequirementOf> between B<Model> and B<ReactionInstance>.
The fields are (0) the KBase model ID (from-link) and (1) the
KBase reaction instance ID (to-link).

=item hasStep.dtx

Each record in this file represents a relationship instance of
B<HasStep> between B<Complex> and B<Reaction>. The fields are (0) the
KBase complex ID (from-link) and (1) the KBase reaction ID (to-link).

=item HasUsage.dtx

Each record in this file represents a relationship instance of
B<HasUsage> between B<LocalizedCompound> and B<CompoundInstance>.
The fields are (0) the KBase LocalizedCompound ID (from-link) and
(1) the KBase CompoundInstance ID (to-link).

=item Involves.dtx

Each record in this file represents a relationship instance of
B<Involves> between B<Reaction> and B<LocalizedCompound>. The
fields are (0) the stoichiometric coefficient (coefficient), (1) C<1>
for a cofactor and C<0> otherwise (cofactor), (2) the KBase ID of
the source reaction (from-link) and (3) the KBase ID of the target
compound (to-link).

=item IsComprisedOf.dtx

Each record in this file represents a relationship instance of
B<IsComprisedOf> from B<Biomass> to B<CompoundInstance>. The
fields are (0) the coefficient, in millimoles of compound per gram
of biomass (coefficient), (1) the KBase ID of the source biomass
(from-link), and (2) the KBase ID of the target compound instance
(to-link).

=item IsDividedInto.dtx

Each record in this file represents a relationship instance of
B<IsDividedInto> between B<Model> and B<LocationInstance>. The
fields are (0) the KBase ID of the source model (from-link) and
(1) the KBase ID of the target location instance (to-link).

=item IsExecutedAs.dtx

Each record in this file represents a relationship instance of
B<IsExecutedAs> between B<Reaction> and B<ReactionInstance>. The
fields are (0) the KBase ID of the reaction (from-link) and
(1) the KBase ID of the reaction instance (to-link).

=item IsInstantiatedBy.dtx

Each record in this file represents a relationship instance of
B<IsInstantiatedBy> between B<Location> and B<LocationInstance>.
The fields are (0) the KBase ID of the location (from-link) and
(1) the KBase ID of the location instance (to-link).

=item IsModeledBy.dtx

Each record in this file represents a relationship instance of
B<IsModeledBy> between B<Genome> and B<Model>. The fields are
(0) the KBase ID of the target model (to-link) and (1) the
KBase ID of the source genome(from-link).

=item IsParticipatingAt.dtx

Each record in this file represents a relationship instance of
B<IsParticipatingAt> between B<Location> and B<LocalizedCompound>.
The fields are (0) the KBase ID of the location (from-link) and
(1) the KBase ID of the localized compound (to-link).

=item IsReagentIn.dtx

Each record in this file represents a relationship instance of
B<IsReagentIn> between B<CompoundInstance> and B<ReactionInstance>.
The fields are (0) the stoichometric coefficient (coefficient),
(1) the KBase ID of the source compound instance (from-link), and
(2) the KBase ID of the targete reaction instance (to-link).

=item IsRealLocationOf.dtx

Each record in this file represents a relationship instance of
B<IsRealLocationOf> between B<LocationInstance> and B<CompoundInstance>.
The fields are (0) the KBase ID of the location instance (from-link)
and (1) the KBase ID of the compound instance (to-link).

=item isTriggeredBy.dtx

Each record in this file represents a relationship instance of
B<IsTriggeredBy> between B<Complex> and B<Role>. The fields are
(0) the KBase ID of the complex (from-link), (1) C<1> if the
role is optional as a trigger and C<0> if it is required to trigger
(optional), (2) the ID of the target role (to-link), (3) C<1> if
the presence of the role requires including the complex in the model
and C<0> if it does not (triggering), and (4) the type of triggering
relationship (type).

=item LocalizedCompound.dtx

Each record in this file represents an instance of the B<LocalizedCompound>
entity. The single field is the KBase ID of the localized compound (id).

=item Manages.dtx

Each record in this file represents an instance of the B<Manages> relationship
between B<Model> and B<Biomass>. The fields are (0) the KBase ID of the
model (from-link) and (1) the KBase ID of the biomass (to-link).

=item media.dtx

Each record in this file represents an instance of the B<Media> entity.
The fields are (0) the KBase ID of the media (id), (1) C<1> if the media is
minimal and C<0> if it is not (is-minimal), (2) the last modification
date (mod-date), (3) the MODELseed ID (source-id), (4) the media name
(name), and (5) the media type (type).

=item Model.dtx

Each record in this file represents an instance of the B<Model> entity.
The fields are (0) the number of features associated with reactions in
the model (annotation-count), (1) the number of compounds in the model
(compound-count), (2) the KBase ID of the model (id), (3) the last
modification date (mod-date), (4) the name of the model (name), (5) the
number of reactions in the model (reaction-count), (6) an indicator
of how stable the model is (status), (7) the origin of the model
(type), and (8) the version number of the model (version).

=item ParticipatesAs.dtx

Each record in this file represents an instance of the B<ParticipatesAs>
relationship between B<Compound> and B<LocalizedCompound>. The fields
are (0) the KBase compound ID (from-link) and (1) the KBase localized
compound ID (to-link).

=item reaction.dtx

Each record in this file represents an instance of the B<Reaction>
entity. The fields are (0) the abbreviated name of the reaction (abbr),
(1) the default number of protons absorbed (default-protons), (2) the
reactions Gibbs free-energy change (deltaG), (3) the uncertainty in the
deltaG value (deltaG-error), (4) the direction of the reaction (direction),
(5) the last modification date (mod-date), (6) the descriptive name
(name), (7) the MODELseed ID (source-id), (8) a coded string indicating
whether the reaction is balanced or not (status), and (9) the
computed reversibility of the reaction in a pH-neutral environment
(thermodynamic-reversibility).

=item ReactionInstance.dtx

Each record in this file represents an instance of the B<ReactionInstance>
entity. The fields are (0) the directionality of the reaction with respect
to the model (direction), (1) the KBase ID of the reaction instance (id),
and (2) the number of protons produced (protons).

=back

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item clear

Recreate the tables before loading. This removes all existing data.
If this option is not specified, errors may occur if chemistry data
already present in the database is loaded. If chemistry data is being
replaced, it should be done using a different script.

=item keepTemp

Keep temporary files. Normally, temporary load files are deleted before termination.
If this option is specified, they will be kept and must be deleted manually.

=head2 Positional Parameters

=over 4

=item inDirectory

Name of the directory containing the model data files.

=back

=cut
    my ($clear, $keep);
    # Connect to the CDMI and create the loader object.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear, keep => \$keep);
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Get the directories.
    my ($inDirectory) = @ARGV;
    if (! $inDirectory) {
        die "No input directory specified.";
    } elsif (! -d $inDirectory) {
        die "Invalid input directory $inDirectory.";
    }
    # Get the statistics object.
    my $stats = $loader->stats;
    # Set the source.
    $loader->SetSource('SEED');
    # Alias sources will be cached in here.
    my %sources;
    # This is the list of tables.
    my @tables = qw(Biomass BiomassName Complex ComplexName Media
                    Location Compound ParticipatesAs HasPresenceOf
                    HasCompoundAliasFrom LocalizedCompound
                    LocationInstance HasRequirementOf
                    HasUsage CompoundInstance IsRealLocationOf
                    IsComprisedOf IsReagentIn Model IsModeledBy
                    Reaction IsDividedInto IsInstantiatedBy
                    IsParticipatingAt ReactionInstance
                    IsExecutedAs HasReactionAliasFrom HasStep
                    IsTriggeredBy Involves Manages
                    );
    # Clear the tables, if necessary.
    if ($clear) {
        for my $table (@tables) {
            print "Recreating $table.\n";
            $cdmi->CreateTable($table, 1);
        }
    } else {
        # We aren't clearing, so make a pass through the models to
        # delete the existing ones.
        open(my $ih, "<$inDirectory/Model.dtx") || die "Could not open model file: $!\n";
        while (! eof $ih) {
            my (undef, undef, $id) = $loader->GetLine($ih);
            my $delStats = $cdmi->Delete(Model => $id);
            print "Model $id deleted.\n";
            $stats->Accumulate($delStats);
        }
    }
    # Initialize the relation loaders.
    $loader->SetRelations(@tables);
    # Load the simple files.
    $loader->SimpleLoad($inDirectory, 'Biomass.dtx', 'Biomass', { cell_wall => 0,
        cofactor => 1, dna => 2, energy => 3, id => 4, lipid => 5,
        mod_date => [6, 'timeStamp', 0], protein => 7 }, 1);
    $loader->SimpleLoad($inDirectory, 'BiomassName.dtx', 'BiomassName', { id => 0,
        name => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'complex.dtx', 'Complex', { id => 0,
        mod_date => [1, 'timeStamp', 0], source_id => 2 });
    $loader->SimpleLoad($inDirectory, 'complexName.dtx', 'ComplexName', { id => 0,
        name => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'compound.dtx', 'Compound', { abbr => 0,
        charge => 1, deltaG => [2, 'copy', 0], deltaG_error => [3, 'copy', 0],
        formula => [4, 'copy', ''], id => 5, label => [6, 'copy', ''],
        mass => [7, 'copy', 0], mod_date => [8, 'timeStamp', 0], source_id => 9,
        ubiquitous => [10, 'copy', 0] }, 1);
    $loader->SimpleLoad($inDirectory, 'CompoundInstance.dtx', 'CompoundInstance',
        { charge => 0, formula => [1, 'copy', ''], id => 2 });
    LoadAliasTable($loader, $inDirectory, 'hasCompoundAliasFrom.dtx',
        'HasCompoundAliasFrom', \%sources);
    $loader->SimpleLoad($inDirectory, 'hasPresenceOf.dtx', 'HasPresenceOf',
        { concentration => 0, from_link => 1, maximum_flux => 2,
          minimum_flux => 3, to_link => 4 }, 1);
    LoadAliasTable($loader, $inDirectory, 'hasReactionAliasFrom.dtx',
        'HasReactionAliasFrom', \%sources);
    $loader->SimpleLoad($inDirectory, 'hasStep.dtx', 'HasStep',
        { from_link => 0, to_link => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'HasUsage.dtx', 'HasUsage',
        { from_link => 0, to_link => 1}, 1);
    $loader->SimpleLoad($inDirectory, 'Involves.dtx', 'Involves',
        { coefficient => 0, cofactor => 1, from_link => 2,
          to_link => 3 }, 1);
    $loader->SimpleLoad($inDirectory, 'IsComprisedOf.dtx', 'IsComprisedOf',
        { coefficient => 0, from_link => 1, to_link => 2 }, 1);
    $loader->SimpleLoad($inDirectory, 'IsDividedInto.dtx', 'IsDividedInto',
        { from_link => 0, to_link => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'IsExecutedAs.dtx', 'IsExecutedAs',
        { from_link => 0, to_link => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'IsInstantiatedBy.dtx', 'IsInstantiatedBy',
        { from_link => 0, to_link => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'IsRealLocationOf.dtx', 'IsRealLocationOf',
        { from_link => 0, to_link => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'isTriggeredBy.dtx', 'IsTriggeredBy',
        { from_link => 0, optional => 1, to_link => 2, triggering => 3,
          type => 4 }, 1);
    $loader->SimpleLoad($inDirectory, 'LocalizedCompound.dtx', 'LocalizedCompound',
        { id => 0 }, 1);
    $loader->SimpleLoad($inDirectory, 'Manages.dtx', 'Manages',
        { from_link => 0, to_link => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'media.dtx', 'Media', { id => 0,
          is_minimal => 1, mod_date => [2, 'timeStamp', 0], source_id => 3,
          name => 4, type => 5 }, 1);
    $loader->SimpleLoad($inDirectory, 'Model.dtx', 'Model',
        { annotation_count => 0, compound_count => 1, id => 2,
          mod_date => [3, 'timeStamp', 0], name => 4, reaction_count => 5,
          status => 6, type => 7, version => 8 }, 1);
    $loader->SimpleLoad($inDirectory, 'ParticipatesAs.dtx', 'ParticipatesAs',
        { from_link => 0, to_link => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'reaction.dtx', 'Reaction', { abbr => [0, 'copy', ''],
          default_protons => 1, deltaG => [2, 'copy', 1000000], deltaG_error => [3, 'copy', 1000000],
          direction => 4, id => 5, mod_date => [6, 'timeStamp', 0], name => 7, source_id => 8,
          status => 9, thermodynamic_reversibility => [10, 'copy', '<=>'] }, 1);
    $loader->SimpleLoad($inDirectory, 'ReactionInstance.dtx', 'ReactionInstance',
        { direction => 0, id => 1, protons => [2, 'copy', 0] }, 1);
    $loader->SimpleLoad($inDirectory, 'IsReagentIn.dtx', 'IsReagentIn',
        { from_link => 1, to_link => 2, coefficient => 0 }, 1);
    $loader->SimpleLoad($inDirectory, 'IsModeledBy.dtx', 'IsModeledBy',
        { from_link => 1, to_link => 0 }, 1);
    $loader->SimpleLoad($inDirectory, 'IsParticipatingAt.dtx',
        'IsParticipatingAt', { from_link => 0, to_link => 1 }, 1);
    $loader->SimpleLoad($inDirectory, 'HasRequirementOf.dtx',
        'HasRequirementOf', { from_link => 0, to_link => 1 }, 1);
    # Unspool the relation loaders.
    print "Loading database relations.\n";
    $loader->LoadRelations($keep);
    # Insure all the sources are present.
    for my $source (%sources) {
        $stats->Add(sourcesFound => 1);
        $loader->InsureEntity(Source => $source);
    }
    print "All done: " . $stats->Show();

# Load the specified alias table. The alias sources are kept in the
# $sources hash.
sub LoadAliasTable {
    # Get the parameters.
    my ($loader, $inDirectory, $fileName, $tableName, $sources) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Only proceed if the file exists.
    my $fullFileName = "$inDirectory/$fileName";
    if (! -f $fullFileName) {
        print "$fullFileName not found: skipped.\n";
        $stats->Add(fileNotFound => 1);
    } else {
        # Open the file for input.
        open(my $ih, "<$fullFileName") || die "Could not open $fileName: $!\n";
        # Skip the header.
        $loader->GetLine($ih);
        # Loop through the records.
        while (! eof $ih) {
            # Get the input record.
            my ($alias, $from, $to) = $loader->GetLine($ih);
            $stats->Add($fileName . "In" => 1);
            # Write the output record.
            $loader->InsertObject($tableName, alias => $alias,
                from_link => $from, to_link => $to);
            $stats->Add($tableName . "Out" => 1);
            # Update the source hash.
            $sources->{$from} = 1;
        }
    }
}
