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

package SourceSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSproutLoader';

=head1 Sprout Source Load Group Class

=head2 Introduction

The  Load Group includes all of the major source citation tables.

=head3 new

    my $sl = SproutLoader->new($erdb, $source, $options, @tables);

Construct a new SproutLoader object.

=over 4

=item erdb

[[SproutPm]] object for the database being loaded.

=item options

Reference to a hash of command-line options.

=item tables

List of tables in this load group.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $options) = @_;
    # Create the table list.
    my @tables = sort qw(ComesFrom Source SourceURL);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the source citation files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG object.
    my $fig = $self->source();
    # Is this the global section?
    if ($self->global()) {
        ##TODO: global stuff
    } else {
        # Get the section ID.
        my $genomeID = $self->section();
        Trace("Processing $genomeID.") if T(3);
        # Open the project file.
        if ((open(TMP, "<$FIG_Config::organisms/$genomeID/PROJECT")) && ! eof TMP) {
            # Read the source data.
            my($sourceID, $desc, $url) = Tracer::GetLine(\*TMP);
            # Insure we have a description.
            $desc = "" if ! defined $desc;
            # Write it to the tables.
            $self->PutR(ComesFrom => $genomeID, $sourceID);
            $self->PutE(Source => $sourceID, description => $desc);
            # If there's a URL, it goes into a secondary table.
            if ($url) {
                $self->PutE(SourceURL => $sourceID, $url);
            }
        }
        close TMP;
    }
}


1;
