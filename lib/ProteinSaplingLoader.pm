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

package ProteinSaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use AliasAnalysis;
    use base 'BaseSaplingLoader';

=head1 Sapling Protein Load Group Class

=head2 Introduction

The Protein Load Group includes all of the major protein and annotation data tables.

=head3 new

    my $sl = ProteinSaplingLoader->new($erdb, $options, @tables);

Construct a new ProteinSaplingLoader object.

=over 4

=item erdb

L<Sapling> object for the database being loaded.

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
    my @tables = sort qw(Annotation IsAnnotatedBy HasAssertionFrom Source);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head3 BLACKLIST

BLACKLIST is a reference to a hash of protein sources to be ignored
when processing non-expert assertions. For example, if C<SEED> were included
in the list, then the SEED subdirectory of the non-expert assertion cluster
would be bypassed.

=cut

use constant BLACKLIST => { SEED => 1, NMPDR => 1 };

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the protein and annotation data files.

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
        # Yes. We do the assertions here. First, the expert assertions.
        # These are taken from the expert assertion file on the FTP. It has to be
        # unzipped so we can read it.
        Trace("Reading expert assertions.") if T(ERDBLoadGroup => 3);
        my $ah = Open(undef, "gunzip -cd /vol/ftp.theseed.org/AnnotationClearingHouse/ach_expert_assertions.gz |");
        # We'll track the assertion sources in this hash.
        my %sources;
        while (! eof $ah) {
            # Get the current assertion from the file.
            my ($id, $function, undef, $source) = Tracer::GetLine($ah);
            $self->Add("assertions-expert" => 1);
            $self->Track(assertionRows => $id, 1000);
            # Fix the function.
            $function =~ s/\s+$//;
            # Insure this user has a source record.
            if (! exists $sources{$source}) {
                $self->PutE(Source => $source);
                $sources{$source} = 1;
            }
            # Attach his assertion to the identifier as an expert assertion.
            $self->PutR(HasAssertionFrom => $id, $source, function => $function,
                        expert => 1);
        }
        # Create the SEED source. Its data is loaded during the section processing.
        $self->PutE(Source => 'SEED');
        # Now we need the non-expert assertions. These are kept in flat
        # files called "assigned_function" in the $FIG_Config::NR subdirectory.
        # The sub-directory names are used for the source.
        my $nr_directory = $FIG_Config::NR;
        my @sources = Tracer::OpenDir($nr_directory, 1);
        # Loop through the sources.
        for my $source (@sources) {
            # Insure this is a source we want.
            if (BLACKLIST->{$source}) {
                Trace("Assertions ignored for blacklisted source $source.") if T(ERDBLoadGroup => 3);
            } else {
                # Check for an assigned function file.
                my $functionFile = "$nr_directory/$source/assigned_functions";
                if (-s $functionFile) {
                    # Put this source is the source table.
                    $self->PutE(Source => $source);
                    Trace("Processing assertions for $source.") if T(ERDBLoadGroup => 3);
                    # Loop through the assigned function file.
                    my $ih = Open(undef, "<$functionFile");
                    while (! eof $ih) {
                        # Get the identifier and function from this row.
                        my ($fid, $function) = Tracer::GetLine($ih);
                        # Fix the function.
                        $function =~ s/\s+$//;
                        # If this is a RefSeq ID, convert it to its normal form.
                        $fid =~ s/^ref\|//;
                        # Count this identifier.
                        $self->Track(nrIdentifiers => $fid, 10000);
                        # Insure this identifier has a valid function.
                        if (! defined $function) {
                            $self->Add("badFunction-$source" => 1);
                        } else {
                            # It does, so put it in the assertion relationship.
                            $self->PutR(HasAssertionFrom => $fid, $source,
                                        function => $function, expert => 0);
                            $self->Add("goodFunction-$source" => 1);
                        }
                    }
                }
            }
        }
    } else {
        # Get the section ID.
        my $genomeID = $self->section();
        # Now we process the annotations for the specified genome.
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
            $self->Track(Annotations => "$peg:$timestamp", 1000);
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
                my $annotationID = "$peg:" . Tracer::Pad(9999999999 - $keyStamp, 10,
                                                         1, "0");
                $seenTimestamps{"$peg:$keyStamp"} = 1;
                # Generate the annotation.
                $self->PutE(Annotation => $annotationID, annotation_time => $timestamp,
                            comment => $text, annotator => $user);
                $self->PutR(IsAnnotatedBy => $peg, $annotationID);
            } else {
                # Here we have an invalid time stamp.
                Trace("Invalid time stamp \"$timestamp\" in annotations for $peg.") if T(ERDBLoadGroup => 1);
            }
        }
        # Get the genome's assertions. These serve as the non-expert assertions
        # from the SEED.
        Trace("Processing assertions.") if T(2);
        my $featureFile = "$FIG_Config::organisms/$genomeID/assigned_functions";
        if (! -f $featureFile) {
            Trace("Missing $featureFile for $genomeID.") if T(1);
            $self->Add(missingAssignedFunction => 1);
        } else {
            my $ih = Open(undef, "<$featureFile");
            while (! eof $ih) {
                # Get the FIG ID and function from this row.
                my ($fid, $function) = Tracer::GetLine($ih);
                # Count this ID.
                $self->Track(figAssertions => $fid, 5000);
                # Insure this identifier has a valid function.
                if (! defined $function) {
                    $self->Add("badFunction-SEED" => 1);
                } else {
                    # It does, so put it in the assertion relationship.
                    $self->PutR(HasAssertionFrom => $fid, 'SEED',
                                function => $function, expert => 0);
                    $self->Add("goodFunction-SEED" => 1);
                }
            }
        }
    }
}

=head3 PostProcess

    my $stats = $edbl->PostProcess();

Post-process the load files for this group. This method is called after all
of the load files have been assembled, but before anything is actually loaded.

This method returns a statistics object describing the post-processing activity,
or an undefined value if nothing happened.

For the Protein group, the post-processing removes assertions for identifiers
that are not in our database.

=cut

sub PostProcess {
    my ($self) = @_;
    my $retVal = $self->FilterRelationship(from => 'HasAssertionFrom');
    return $retVal;
}

1;
