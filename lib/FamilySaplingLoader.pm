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

package FamilySaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use FFs;
    use FF;
    use SeedUtils;
    use LoaderUtils;
    use base 'BaseSaplingLoader';

=head1 Sapling Family Load Group Class

=head2 Introduction

The Family Load Group includes all of the major family and pairing tables.

=head3 new

    my $sl = FamilySaplingLoader->new($erdb, $options);

Construct a new FamilySaplingLoader object.

=over 4

=item erdb

L<Sapling> object for the database being loaded.

=item options

Reference to a hash of command-line options.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $options) = @_;
    # Create the table list.
    my @tables = sort qw(Family HasMember IsInPair Pairing IsDeterminedBy
                         PairSet OccursIn Cluster FamilyName IsFamilyFor
                         HasRepresentativeOf IsCoupledTo);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the family and pairing files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the database object.
    my $erdb = $self->db();
    # Get the source object.
    my $fig = $self->source();
    # Is this the global section?
    if ($self->global()) {
        # Here we load the coupling data. The coupling data is stored in flat files
        # in a Sapling data subdirectory.
        my $couplingDir = $erdb->LoadDirectory() . '/FamilyData';
        $self->LoadFromFile(Pairing => "$couplingDir/Pairing.dtx", qw(id));
        $self->LoadFromFile(Cluster => "$couplingDir/Cluster.dtx", qw(id));
        $self->LoadFromFile(IsDeterminedBy => "$couplingDir/IsDeterminedBy.dtx",
                            qw(from-link to-link inverted));
        $self->LoadFromFile(IsInPair => "$couplingDir/IsInPair.dtx",
                            qw(from-link to-link));
        $self->LoadFromFile(OccursIn => "$couplingDir/OccursIn.dtx",
                            qw(from-link to-link));
        $self->LoadFromFile(PairSet => "$couplingDir/PairSet.dtx",
                            qw(id score));
        # The next step is to load all the FIGfam data. This data is found in
        # the latest figfam-prod release directory.
        my @releases = sort { Tracer::Cmp($a, $b) } grep { $_ =~ /^Release\d+/ } OpenDir("/vol/figfam-prod");
        # Find the first valid FIGfam directory.
        my $figFamDir;
        for (my $i = $#releases; $i >= 0 && ! $figFamDir; $i--) {
            my $testDir = "/vol/figfam-prod/$releases[$i]";
            if (-f "$testDir/coupling.values") {
                $figFamDir = $testDir;
            }
        }
        if (! $figFamDir) {
            Confess("No FIGfam directory found.");
        } else {
            Trace("FIGfams will be loaded from $figFamDir.") if T(ERDBLoadGroup => 2);
            # We will keep the FIGfam IDs in here. We need them to filter the coupling
            # file.
            my %figFams;
            # Read the family functions.
            my $ih = Open(undef, "<$figFamDir/family.functions");
            while (! eof $ih) {
                my ($fam, $function) = Tracer::GetLine($ih);
                $self->Track(familyFunctionRecord => $fam, 1000);
                if (! defined $function) {
                    $function = "";
                    $self->Add(missingFamilyFunction => 1);
                }
                # Output the family record.
                $self->PutE(Family => $fam);
                $self->PutE(FamilyName => $fam,
                            family_function => $function);
                # Remember that this is a valid family.
                $figFams{$fam} = 1;
                # Connect the family to its roles.
                my ($roles, $errors) = SeedUtils::roles_for_loading($function);
                if (! defined $roles) {
                    # Here the family function was suspicious.
                    $self->Add(suspiciousFamilyFunction => 1);
                } else {
                    # Here we have a good function.
                    for my $role (@$roles) {
                        $self->Add(figfamRole => 1);
                        $self->PutR(IsFamilyFor => $fam, $role);
                    }
                    $self->Add(badFigfamRoles => $errors);
                }
            }
            close $ih;
            # Read the memberships.
            $ih = Open(undef, "<$figFamDir/families.2c");
            while (! eof $ih) {
                my ($fam, $featureID) = Tracer::GetLine($ih);
                $self->Track(familyFeatureRecord => "$fam:$featureID", 5000);
                # Connect the family to the feature.
                $self->PutR(HasMember => $fam, $featureID);
                # Extract the genome ID.
                if ($featureID =~ /^fig\|(\d+\.\d+)/) {
                    # Connect the family to the genome.
                    $self->PutR(HasRepresentativeOf => $1, $fam);
                }
            }
            close $ih;
            # Now read the coupling data.
            $ih = Open(undef, "<$figFamDir/coupling.values");
            while (! eof $ih) {
                my ($from, $to, $expScore, $contigScore) = Tracer::GetLine($ih);
                $self->Track(familyCouplingRecord => "$from:$to", 1000);
                # Verify that both FIGfams are ours and are distinct.
                if (! $figFams{$from} || ! $figFams{$to}) {
                    $self->Add(couplingFigFamNotFound => 1);
                } elsif ($from eq $to) {
                    $self->Add(couplingFigFamReflexive => 1);
                } else {
                    # Everything's okay, so we can connect the two figfams together.
                    # Insure the ordering is correct.
                    if ($from > $to) {
                        ($from, $to) = ($to, $from);
                    }
                    # Forge the connection.
                    $self->PutR(IsCoupledTo => $from, $to, co_occurrence_evidence => $contigScore,
                                co_expression_evidence => $expScore);
                }
            }
            close $ih;
        }
    }
}


1;
