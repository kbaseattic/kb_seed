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
    use Stats;
    use SeedUtils;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;

=head1 CDMI Annotation Loader

    CDMILoadAnnotations [options] source annotationFile

This script loads Annotation data for features from the specified source.
The dump files are read in and the feature IDs converted from FIG IDs 
to KBase IDs. Only features for genomes found in the KBase CDMI will 
be included in the output. Two relations are loaded-- B<Annotation> and
 B<IsAnnotatedBy>.

The input file contains multi-line records, each delimited by a single
line containing a double slash (C<//>). The first line of each record
contains a feature ID, the second a time stamp (expressed as a number
of seconds since the epoch), the third the name of the annotator, and the
remaining lines form the annotation text.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
the following.

=over 4

=item clear

If specified, the tables will be deleted and re-created before loading.

=back

There are two positional parameters: the name of the source database
(C<SEED>, C<MOL>, etc) and the name of the file containing the annotations.
There is no attempt to verify that the annotations are new: if they
have already been processed, duplicates will appear in the database.
In addition, the source database cannot use genome-based IDs. These
issues may be addressed in the future.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my ($clear);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear);
if (! $cdmi) {
    print "usage: CDMILoadAnnotations [options] source inputFile\n";
} else {
    # Create the loader object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Get the input parameters.
    my ($source, $inFile) = @ARGV;
    # Insure they're valid.
    if (! $source) {
        die "Missing source database ID.\n";
    } elsif (! $inFile) {
        die "Missing input file name.\n";
    } elsif (! -f $inFile) {
        die "Invalid input file $inFile.\n";
    } else {
        # Inform the loader of our source.
        $loader->SetSource($source);
        if ($loader->{sourceData}->genomeBased) {
            die "Cannot use this script for genome-based sources.\n";
        }
        # Get the list of tables.
        my @tables = qw(Annotation IsAnnotatedBy);
        # Are we clearing?
        if ($clear) {
            # Recreate the tables.
            for my $table (@tables) {
                $cdmi->CreateTable($table, 1);
                print "$table recreated.\n";
            }
        }
        # Set up the relation loaders.
        $loader->SetRelations(@tables);
        # We process the data in batches. This list will contain the
        # annotation batches we have accumulated.
        my $annotations = [];
        # This hash will track the features we find.
        my $fids = {};
        # This variable holds the current record.
        my $record = [];
        # Open the input file.
        open(my $ih, "<$inFile") || die "Could not open input file: $!\n";
        # Loop through it.
        while (! eof $ih) {
            my $line = <$ih>;
            chomp $line;
            $stats->Add(lineIn => 1);
            # Is this an end-of-record line?
            if ($line ne '//') {
                # No, add it to the current record.
                push @$record, $line;
            } else {
                # Yes. Create an annotation from the record.
                my $fid = shift @$record;
                my $time = shift @$record;
                my $who = shift @$record;
                my $text = join("\\n", @$record);
                push @$annotations, [$fid, $time, $who, $text];
                # Save the feature for the ID server call.
                $fids->{$fid} = 1;
                # Clear the record.
                $record = [];
                # Is this batch full?
                if (scalar(@$annotations) >= 5000) {
                    # Yes, so process it.
                    ProcessBatch($loader, $annotations, $source, $fids);
                    # Clear the variables for the next batch.
                    $annotations = [];
                    $fids = {};
                }
            }
        }
        # If there is a residual batch, process it.
        if (scalar(@$annotations) > 0) {
            ProcessBatch($loader, $annotations, $source, $fids);
        }
        # Unspool the relations.
        $loader->LoadRelations();
    }
    print "All done:\n" . $stats->Show();
}

=head2 Subroutines

=head3 ProcessBatch

    ProcessBatch($loader, $annotations, $source, $fids);

Process a batch of annotations. The KBase IDs for the relevant features
must be computed, and then the annotation IDs themselves will be
created so that the two relations can be amended with the new annotations.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for loading the database and tracking statistics.

=item annotations

Reference to a list of 4-tuples representing annotations. Each 4-tuple
contains (0) a feature ID, (1) a time stamp, (2) an annotator name, and
(3) the annotation text.

=item source

Name of the source database from which the features were taken.

=item fids

Reference to a hash whose keys are the IDs for the features being
annotated.

=back

=cut

sub ProcessBatch {
    # Get the parameters.
    my ($loader, $annotations, $source, $fids) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the CDMI object.
    my $cdmi = $loader->cdmi;
    # Get the KBase IDs for the features.
    my $idMapping = $loader->FindKBaseIDs('Feature', [keys %$fids]);
    # Loop through the annotations, adding them to the database.
    for my $annotation (@$annotations) {
        $stats->Add(annotationProcessed => 1);
        my ($fid, $time, $who, $text) = @$annotation;
        # Find this feature's KBase ID.
        my $kbid = $idMapping->{$fid};
        if (! defined $kbid) {
            # Here the feature is not in the KBase, so we discard
            # the annotation.
            $stats->Add(fidNotFound => 1);
        } else {
            # Compute the annotation ID.
            my $annoID = $cdmi->ComputeNewAnnotationID($kbid, $time);
            # Create the annotation.
            $loader->InsertObject('IsAnnotatedBy', from_link => $kbid,
                    to_link => $annoID);
            $loader->InsertObject('Annotation', id => $annoID,
                    annotation_time => $time, annotator => $who,
                    comment => $text);
            $stats->Add(annotationAdded => 1);
        }
    }
    print "Batch processed: " . $stats->Ask('annotationAdded') . " annotations added.\n";
}
