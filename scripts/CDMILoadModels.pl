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

=head1 Model Chemistry Data Load Script for CDMI

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

=item compartment.dtx

This file produces B<Compartment> and has five input columns--
C<abbr>, C<id>, C<mod-date>, C<msid>, and C<name>. The C<mod-date> column
must be translated.

=item complex.dtx

This file produces B<Complex> and has three input columns-- C<id>,
C<msid>, and C<mod-date>. The C<mod-date> column must be translated.

=item complexName.dtx

This file produces the C<name> field of B<Complex> and three two input
columns-- C<id>, C<msid> and C<name>.  If the C<name> column is empty
(indicating that the complex does not have a name), the record will
not produce output. The C<msid> column is not used.

=item compound.dtx

This file produces B<Compound> and has eight input columns-- C<abbr>,
C<formula>, C<id>, C<label>, C<mass>, C<mod-date>, C<msid>, and
C<uncharged-formula>. An ninth field-- C<ubiquitous>-- is computed
from data in the B<Reagent.dtx> file. This means the latter file must
be processed first. The C<mod-date> column must be translated. If the
C<uncharged-formula> column is empty it will be stored as an empty string.

=item hasCompoundAliasFrom.dtx

This file produces B<HasCompoundAliasFrom> and has three input columns--
C<alias>, C<from-link>, and C<to-link>. The C<from-link> column must
have a B<Source> entity associated with it.

=item hasPresenceOf.dtx

This file produces B<HasPresenceOf> and has five input columns--
C<concentration>, C<from-link>, C<maximum-flux>, C<minimum-flux>, and
C<to-link>.

=item hasReactionAliasFrom.dtx

This file produces B<HasReactionAliasFrom> and has three input columns--
C<alias>, C<from-link>, and C<to-link>. The C<from-link> column must
have a B<Source> entity associated with it.

=item hasStep.dtx

This file produces B<HasStep> and has two input columns-- C<from-link> and
C<to-link>.

=item isTriggeredBy.dtx

This file produces B<IsTriggeredBy> and has five input columns--
C<from-link>, C<msid>, C<optional>, C<to-link>, and C<type>.
The C<msid> column is not used.

=item isUsedAs.dtx

This file produces B<IsUsedAs> and has two input columns-- C<from-link> and
C<to-link>.

=item media.dtx

This file produces B<Media> and has four input columns-- C<id>, C<mod-date>,
C<name>, and C<type>. If C<type> is missing it will be stored as an empty
string. C<mod-date> must be translated.

=item ParticipatesAs.dtx

This file produces B<ParticipatesAs> and has two input columns-- C<from-link>
and C<to-link>.

=item reaction.dtx

This file produces B<Reaction> and has seven columns-- C<abbr>, C<equation>,
C<id>, C<mod-date>, C<msid>, C<name>, and C<reversibility>. C<mod-date>
must be translated.

=item reactionComplex.dtx

This file produces B<ReactionRule> and B<IsProposedLocationOf>
and has five columns-- C<compartment>, C<direction>, C<id>, C<reaction>,
and C<transproton-nature>. C<transproton-nature> will be set to 0 if
it is empty. The B<IsProposedLocationOf> relationship is built using
C<compartment> as the C<from-link> and C<id> as the C<to-link>.
The B<ReactionRule> entity is built using C<id>, C<direction>,
and C<transproton-nature>, the latter being renamed to C<transproton>.

=item Reagent.dtx

This file produces B<Reagent>, B<Involves>, and
B<IsDefaultLocationOf> and has six columns-- C<cofactor>, C<compartment>,
C<compartment-index>, C<id>, C<stoichiometry>, and C<transport-coefficient>.
The C<stoichiometry> will be set to 1 if it is empty,
C<transport-coefficient> will be set to 0 if it is empty, and
C<cofactor> and C<compartment-index> will be set to 0 when empty. The
C<id> is the concatenation of the corresponding reaction ID and the
corresponding compound ID. The B<Involves> relationship uses the
reaction ID as the C<from-link> and the C<id> as the C<to-link>. The
B<IsDefaultLocationOf> relationship uses C<compartment> as the C<from-link> and
C<id> as the C<to-link>. The C<Reagent> entity is built using C<id>, C<cofactor>,
C<compartment-index>, C<stoichiometry>, and C<transport-coefficient>.

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
    my @tables = qw(Compartment Complex ComplexName Compound
            HasCompoundAliasFrom HasPresenceOf HasReactionAliasFrom
            HasStep IsTriggeredBy IsUsedAs Media ParticipatesAs
            ReactionRule IsProposedLocationOf Reagent Involves
            IsDefaultLocationOf Reaction);
    for my $table (@tables) {
        print "Recreating $table.\n";
        $cdmi->CreateTable($table, 1);
    }
    # Initialize the relation loaders.
    $loader->SetRelations(@tables);
    my ($ih, @fields);
    # Open the media file.
    print "Processing media file.\n";
    open($ih, "<$inDirectory/media.dtx") || die "Could not open media.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(mediaIn => 1);
        $loader->ConvertFileRecord('Media', 'SEED', \@fields,
                { id => [0, 'copy'], mod_date => [1, 'timeStamp', 0],
                  name => [2, 'copy'], type => [3, 'copy', ''] });
        $stats->Add(MediaOut => 1);
    }
    close $ih; undef $ih;
    # Open the hasStep file.
    print "Processing ParticipatesAs file.\n";
    open($ih, "<$inDirectory/ParticipatesAs.dtx") || die "Could not open ParticipatesAs.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(ParticipatesAsIn => 1);
        $loader->ConvertFileRecord('ParticipatesAs', 'SEED', \@fields,
                { from_link => [0, 'copy'], to_link => [1, 'copy'] });
        $stats->Add(ParticipatesAsOut => 1);
    }
    close $ih; undef $ih;
    # Open the reaction file.
    print "Processing reaction file.\n";
    open($ih, "<$inDirectory/reaction.dtx") || die "Could not open reaction.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(reactionIn => 1);
        $loader->ConvertFileRecord('Reaction', 'SEED', \@fields,
                { abbr => [0, 'copy'], equation => [1, 'copy'],
                  id => [2, 'copy'], mod_date => [3, 'timeStamp'],
                  msid => [4, 'copy'], name => [5, 'copy'],
                  reversibility => [6, 'copy']
                   });
        $stats->Add(ReactionOut => 1);
    }
    close $ih; undef $ih;
    # Open the reactionComplex file.
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
    close $ih; undef $ih;
    # Open the compartment file.
    print "Processing compartment file.\n";
    open($ih, "<$inDirectory/compartment.dtx") || die "Could not open compartment.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        @fields = $loader->GetLine($ih);
        $stats->Add(compartmentIn => 1);
        $loader->ConvertFileRecord('Compartment', 'SEED', \@fields,
                { id => [1, 'copy'], mod_date => [2, 'timeStamp'],
                  name => [4, 'copy'], abbr => [0, 'copy'] });
        $stats->Add(CompartmnetOut => 1);
    }
    close $ih; undef $ih;
    # Open the complex file.
    print "Processing complex file.\n";
    open($ih, "<$inDirectory/complex.dtx") || die "Could not open complex.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(complexIn => 1);
        $loader->ConvertFileRecord('Complex', 'SEED', \@fields,
                { id => [0, 'copy'], mod_date => [2, 'timeStamp'],
                  msid => [1, 'copy'] });
        $stats->Add(ComplexOut => 1);
    }
    close $ih; undef $ih;
    # Open the complexName file.
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
    close $ih; undef $ih;
    # Open the Reagent file. This one requires special handling. We need
    # to track how many times each compound occurs as a Reagent. Those
    # that occur more than 25 times will be marked ubiquitous. This
    # file also produces four different tables.
    print "Processing Reagent file.\n";
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
        # Output Involves.
        $loader->ConvertFileRecord('Involves', 'SEED', \@fields,
                { from_link => [3, 'copy1'], to_link => [3, 'copy'] });
        $stats->Add(InvolvesOut => 1);
        # Output IsDefaultLocationOf.
        $loader->ConvertFileRecord('IsDefaultLocationOf', 'SEED', \@fields,
                { from_link => [1, 'copy'], to_link => [3, 'copy'] });
        $stats->Add(IsDefaultLocationOf => 1);
    }
    close $ih; undef $ih;
    # Open the compound file.
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
    # Process the hasAlias files.
    for my $dir (qw(Compound Reaction)) {
        print "Processing has${dir}AliasFrom file.\n";
        open($ih, "<$inDirectory/has${dir}AliasFrom.dtx") || die "Could not open has${dir}AliasFrom.dtx: $!\n";
        # Skip the header record.
        @fields = $loader->GetLine($ih);
        # Loop through the data records.
        while (! eof $ih) {
            my @fields = $loader->GetLine($ih);
            $stats->Add("has${dir}AliasFromIn" => 1);
            $loader->ConvertFileRecord("Has${dir}AliasFrom", 'SEED', \@fields,
                    { from_link => [1, 'copy'], to_link => [2, 'copy'],
                      alias => [0, 'copy'] });
            $stats->Add("Has${dir}AliasFromOut" => 1);
            my $source = $fields[1];
            if (! $sources{$source}) {
                $loader->InsureEntity(Source => $source);
                $sources{source} = 1;
            }
        }
    }
    close $ih; undef $ih;
    # Open the hasPresenceOf file.
    print "Processing hasPresenceOf file.\n";
    open($ih, "<$inDirectory/hasPresenceOf.dtx") || die "Could not open hasPresenceOf.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(hasPresenceOfIn => 1);
        $loader->ConvertFileRecord('HasPresenceOf', 'SEED', \@fields,
                { concentration => [0, 'copy'], from_link => [1, 'copy'],
                  maximum_flux => [2, 'copy', 0], minimum_flux => [3, 'copy', 0],
                  to_link => [4, 'copy'] });
        $stats->Add(HasPresenceOfOut => 1);
    }
    close $ih; undef $ih;
    # Open the hasStep file.
    print "Processing hasStep file.\n";
    open($ih, "<$inDirectory/hasStep.dtx") || die "Could not open hasStep.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(hasStepIn => 1);
        $loader->ConvertFileRecord('HasStep', 'SEED', \@fields,
                { from_link => [0, 'copy'], to_link => [1, 'copy'] });
        $stats->Add(HasStepOut => 1);
    }
    close $ih; undef $ih;
    # Open the hasStep file.
    print "Processing hasStep file.\n";
    open($ih, "<$inDirectory/hasStep.dtx") || die "Could not open hasStep.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(hasStepIn => 1);
        $loader->ConvertFileRecord('HasStep', 'SEED', \@fields,
                { from_link => [0, 'copy'], to_link => [1, 'copy'] });
        $stats->Add(HasStepOut => 1);
    }
    close $ih; undef $ih;
    # Open the isTriggeredBy file.
    print "Processing isTriggeredBy file.\n";
    open($ih, "<$inDirectory/isTriggeredBy.dtx") || die "Could not open isTriggeredBy.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(isTriggeredByIn => 1);
        $loader->ConvertFileRecord('IsTriggeredBy', 'SEED', \@fields,
                { from_link => [0, 'copy'], optional => [2, 'copy', 0],
                  to_link => [3, 'copy'], type => [4, 'copy'] });
        $stats->Add(IsTriggeredByOut => 1);
    }
    close $ih; undef $ih;
    # Open the isUsedAs file.
    print "Processing isUsedAs file.\n";
    open($ih, "<$inDirectory/isUsedAs.dtx") || die "Could not open isUsedAs.dtx: $!\n";
    # Skip the header record.
    @fields = $loader->GetLine($ih);
    # Loop through the data records.
    while (! eof $ih) {
        my @fields = $loader->GetLine($ih);
        $stats->Add(isUsedAsIn => 1);
        $loader->ConvertFileRecord('IsUsedAs', 'SEED', \@fields,
                { from_link => [0, 'copy'], to_link => [1, 'copy'] });
        $stats->Add(IsUsedAsOut => 1);
    }
    close $ih; undef $ih;
    # Unspool the relation loaders.
    print "Loading database relations.\n";
    $loader->LoadRelations();
    print "All done: " . $stats->Show();
