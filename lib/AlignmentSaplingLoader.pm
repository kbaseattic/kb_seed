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

package AlignmentSaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use FFs;
    use FF;
    use SeedUtils;
    use LoaderUtils;
    use base 'BaseSaplingLoader';

=head1 Sapling Alignment Load Group Class

=head2 Introduction

The Alignment Load Group includes all of the major alignment and tree tables.

=head3 new

    my $sl = AlignmentSaplingLoader->new($erdb, $options);

Construct a new AlignmentSaplingLoader object.

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
    my @tables = sort qw(AlignmentTree Aligns ProjectsOnto);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the alignment and tree files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the database object.
    my $erdb = $self->db();
    # Get the source object.
    my $fig = $self->source();
    # The loading is done in the global section.
    if ($self->global()) {
        # The alignment dump files are in the coupling directory.
        my $couplingDir = $erdb->LoadDirectory() . '/FamilyData';
        $self->LoadFromFile(AlignmentTree => "$couplingDir/AlignmentTree.dtx",
                            qw(id alignment-method tree-method alignment-parameters
                               alignment-properties tree-parameters tree-properties));
        $self->LoadFromFile(Aligns => "$couplingDir/Aligns.dtx",
                            qw(from-link to-link begin end len sequence-id properties));
        $self->LoadFromFile(ProjectsOnto => "$couplingDir/ProjectsOnto.dtx",
                            qw(from-link to-link gene-context percent-identity score));
    }
}


1;
