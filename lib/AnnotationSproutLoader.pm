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

package AnnotationSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSproutLoader';

=head1 Sprout Annotation Load Group Class

=head2 Introduction

The  Load Group includes all of the major annotation data tables.

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
    my @tables = sort qw(Annotation IsTargetOfAnnotation SproutUser MadeAnnotation);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the annotation data files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG object.
    my $fig = $self->source();
    # Check for global mode.
    if ($self->global()) {
        # In global mode, we create the built-in users.
        Trace("Creating default users.") if T(3);
        $self->PutE(SproutUser => "FIG", description => "Fellowship for Interpretation of Genomes");
        $self->PutE(SproutUser => "FIG", description => "Fellowship for Interpretation of Genomes");
    } else {
        # Get the section ID, which is the relevant genome.
        my $genomeID = $self->section();
        # Process the annotations for the specified genome.
        # Get the current time.
        my $time = time();
        # Create a hash of timestamps. We use this to prevent duplicate time stamps
        # from showing up for a single PEG's annotations.
        my %seenTimestamps = ();
        # Get the genome's annotations.
        my @annotations = $fig->read_all_annotations($genomeID);
        Trace("Processing annotations.") if T(2);
        for my $tuple (@annotations) {
            # Get the annotation tuple.
            my ($peg, $timestamp, $user, $text) = @{$tuple};
            # Change assignments by the master user to FIG assignments.
            $text =~ s/Set master function/Set FIG function/s;
            # Insure the time stamp is valid.
            if ($timestamp =~ /^\d+$/) {
                # Here it's a number. We need to insure the one we use to form
                # the key is unique.
                my $keyStamp = $timestamp;
                while ($seenTimestamps{"$peg:$keyStamp"}) {
                    $keyStamp++;
                }
                my $annotationID = "$peg:$keyStamp";
                $seenTimestamps{$annotationID} = 1;
                # Insure the user exists.
                $self->PutE(SproutUser => $user, description => "SEED user");
                # Generate the annotation.
                $self->PutE(Annotation => $annotationID, time => $timestamp,
                            annotation => $text);
                $self->PutR(IsTargetOfAnnotation => $peg, $annotationID);
                $self->PutR(MadeAnnotation => $user, $annotationID);
            } else {
                # Here we have an invalid time stamp.
                Trace("Invalid time stamp \"$timestamp\" in annotations for $peg.") if T(1);
            }
        }
    }
}


1;
