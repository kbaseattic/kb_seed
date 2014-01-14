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

=head1 Biochemistry Data Load Script for CDMI

    CDMILoadBiochemistry [options] <inDirectory>

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

=item complex.dtx

Each record in this file corresponds to an instance of the B<Complex>
entity record. The fields are (0) the KBase complex ID (id), (1) the source id (source-id),
and (2) the last modification date (mod-date).

=item complexName.dtx

Each record in this file corresponds to a B<ComplexName> record. There
is one of these for each complex that has a descriptive name. The fields
are (0) the KBase complex ID (id), (1) the source ID (not used) and (2) the 
complex name (name).

=item compound.dtx

Each record in this file represents an instance of the B<Compound>
entity. The fields are (0) the KBase compound ID (id), (1) the source
ID (source-id), (2) the pH-neutral atomic mass (mass), (3) the last 
modification date (mod-date), (4) the abbreviated name (abbr), (5) the
default charge (charge), (6) the energy of formation (deltaG), (7) the
error in the energy-of-formation value (deltaG-error), (8) the pH-neutral
formula (formula), (9) the primary name of the compound for use in 
displaying reactions (label), and (10) the uncharged formula (not used). 
The I<ubiquitous> field will default to FALSE, and gets computed later.

=item hasCompoundAliasFrom.dtx

Each record in this file represents a relationship instance of
B<HasCompoundAliasFrom> between B<Compound> and B<Source>. The
fields are (0) the alias source (from-link), (1) the KBase 
compound ID (to-link), and (2) the compound alias (alias).

=item hasPresenceOf.dtx

Each record in this file represents a relationship instnce of
B<HasPresenceOf> between B<Media> and B<Compound>. The fields
are (0) the KBase ID of the media (from-link), (1) the KBase 
ID of the compound (to-link), (2) the compound concentration 
(concentration), (3) the maximum flux (not used), and
(3) the minimum flux (not used). The I<units> field is not
specified and will be set to a null string.

=item hasReactionAliasFrom.dtx

Each record in this file represents a relationship instance of
B<HasReactionAliasFrom> between B<Reaction> and B<Source>. The
fields are (0) the alias source (from-link), (1) the KBase 
reaction ID (to-link), and (2) the reaction alias (alias).

=item hasStep.dtx

Each record in this file represents a relationship instance of
B<HasStep> between B<Complex> and B<Reaction>. The fields are (0) the
KBase complex ID (from-link) and (1) the KBase reaction ID (to-link).

=item IsParticipatingAt.dtx

Each record in this file represents a relationship instance of
B<IsParticipatingAt> between B<Location> and B<LocalizedCompound>.
The fields are (0) the KBase ID of the location (from-link) and
(1) the KBase ID of the localized compound (to-link).

=item isTriggeredBy.dtx

Each record in this file represents a relationship instance of
B<IsTriggeredBy> between B<Complex> and B<Role>. The fields are
(0) the KBase ID of the complex (from-link), (1) the ID of the 
target role (to-link), (2) the source id (not used), (3) C<1> if 
the role is optional as a trigger and C<0> if it is required to 
trigger (optional), (4) the type of triggering relationship (type), 
and (5) C<1> if the presence of the role requires including the 
complex in the model and C<0> if it does not (triggering).

=item LocalizedCompound.dtx

Each record in this file represents an instance of the B<LocalizedCompound>
entity. The single field is the KBase ID of the localized compound (id).

=item location.dtx

Each record in this file represents an instance of the B<Location>
entity. The fields are (0) the KBase ID of the location (id), (1) the
hierarchy position of the location (not used), (2) the modification date
(mod-date), (3) the abbreviation (abbr), and (4) the name. The I<source-id>
field will be set to the same as the abbreviation. 

=item media.dtx

Each record in this file represents an instance of the B<Media> entity.
The fields are (0) the KBase ID of the media (id), (1) C<1> if the media is
minimal and C<0> if it is not (is-minimal), (2) the last modification
date (mod-date), (3) the media name (name), and (4) the media type (type).
The I<source-id> field will be set to the same as the media name.

=item ParticipatesAs.dtx

Each record in this file represents an instance of the B<ParticipatesAs>
relationship between B<Compound> and B<LocalizedCompound>. The fields
are (0) the KBase compound ID (from-link) and (1) the KBase localized
compound ID (to-link).

=item reaction.dtx

Each record in this file represents an instance of the B<Reaction>
entity. The fields are (0) the KBase ID of the reaction (id), 
(1) the default number of protons absorbed (default-protons), (2) the
reactions Gibbs free-energy change (deltaG), (3) the uncertainty in the
deltaG value (deltaG-error), (4) the direction of the reaction (direction),
(5) the last modification date (mod-date), (6) the computed reversibility 
of the reaction in a pH-neutral environment (thermodynamic-reversibility),
(7) the abbreviated name of the reaction (abbr), (8) the MODELseed ID 
(source-id), (9) the descriptive name (name), and (10) a coded string indicating
whether the reaction is balanced or not (status).

=item Reagent.dtx

Each record in this file represents an instance of the B<Involves> relationship
between B<Reaction> and B<LocalizedCompound>. The fields are (0) the
KBase ID of the source reaction (from-link), (1) the KBase ID of the target
localized compound (to-link), (2) the coefficient (coefficient), and (3)
TRUE iff the reagent acts as a cofactor (cofactor).

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

    $| = 1;
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
    my @tables = qw(
        Complex ComplexName Media Location Compound
        ParticipatesAs HasPresenceOf HasCompoundAliasFrom
        LocalizedCompound Reaction IsParticipatingAt
        HasReactionAliasFrom HasStep IsTriggeredBy Involves
    );
    # Clear the tables, if necessary.
    if ($clear) {
        for my $table (@tables) {
            print "Recreating $table.\n";
            $cdmi->CreateTable($table, 1);
        }
    }
    # Initialize the relation loaders.
    $loader->SetRelations(@tables);
    # Load the simple files.
    $loader->SimpleLoad($inDirectory, 'complex.dtx', 'Complex', { id => 0,
        mod_date => [1, 'timeStamp', 0], source_id => 2 }, 1, 1);
    $loader->SimpleLoad($inDirectory, 'complexName.dtx', 'ComplexName', { id => 0,
        name => 1 }, 1, 1);
    $loader->SimpleLoad($inDirectory, 'compound.dtx', 'Compound', { abbr => 0,
        charge => 1, deltaG => [2, 'copy', 0], deltaG_error => [3, 'copy', 0],
        formula => [4, 'copy', ''], id => 5, label => [6, 'copy', ''],
        mass => [7, 'copy', 0], mod_date => [8, 'timeStamp', 0], source_id => 9,
        ubiquitous => [10, 'copy', 0] }, 1, 1);
    LoadAliasTable($loader, $inDirectory, 'hasCompoundAliasFrom.dtx',
        'HasCompoundAliasFrom', \%sources);
    $loader->SimpleLoad($inDirectory, 'hasPresenceOf.dtx', 'HasPresenceOf',
        { concentration => 0, from_link => 1, maximum_flux => 2,
          minimum_flux => 3, to_link => 4 }, 1);
    LoadAliasTable($loader, $inDirectory, 'hasReactionAliasFrom.dtx',
        'HasReactionAliasFrom', \%sources);
    $loader->SimpleLoad($inDirectory, 'hasStep.dtx', 'HasStep',
        { from_link => 0, to_link => 1 }, 1, 1);
    $loader->SimpleLoad($inDirectory, 'Involves.dtx', 'Involves',
        { coefficient => 0, cofactor => 1, from_link => 2,
          to_link => 3 }, 1, 1);
    $loader->SimpleLoad($inDirectory, 'isTriggeredBy.dtx', 'IsTriggeredBy',
        { from_link => 0, optional => 1, to_link => 2, triggering => 3,
          type => 4 }, 1, 1);
    $loader->SimpleLoad($inDirectory, 'LocalizedCompound.dtx', 'LocalizedCompound',
        { id => 0 }, 1);
    $loader->SimpleLoad($inDirectory, 'location.dtx', 'Location',
        { id => 1, abbr => 0, mod_date => 2, name => 3, source_id => 4 }, 1, 1);
    $loader->SimpleLoad($inDirectory, 'media.dtx', 'Media', { id => 0,
          is_minimal => 1, mod_date => [2, 'timeStamp', 0], source_id => 3,
          name => 4, type => 5 }, 1, 1);
    $loader->SimpleLoad($inDirectory, 'ParticipatesAs.dtx', 'ParticipatesAs',
        { from_link => 0, to_link => 1 }, 1, 1);
    $loader->SimpleLoad($inDirectory, 'reaction.dtx', 'Reaction', { abbr => [0, 'copy', ''],
          default_protons => 1, deltaG => [2, 'copy', 1000000], deltaG_error => [3, 'copy', 1000000],
          direction => 4, id => 5, mod_date => [6, 'timeStamp', 0], name => 7, source_id => 8,
          status => [9, 'copy', 'OK'], thermodynamic_reversibility => [10, 'copy', '<=>'] }, 1, 1);
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
