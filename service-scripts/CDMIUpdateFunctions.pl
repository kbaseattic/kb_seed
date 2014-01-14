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

=head1 CDMI Function Updater

    CDMIUpdateFunctions [options] directory

This script updates Annotation data for features already in the CDMI.
It reads a directory of genome files, each with the same name as a genome
ID. Each file must be a tab-delimited file with a feature ID in the first
column and a functional annotation in the second. The indicated features
will be updated with the new functional role.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.

=back

There is a single positional parameter: the name of the directory containing
the new functional annotations.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my ($clear);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear);
if (! $cdmi) {
    print "usage: CDMIUpdateFunctions [options] directory\n";
} else {
    # Create the loader object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Get the input parameter.
    my ($inDirectory) = @ARGV;
    # Insure it's valid.
    if (! -d $inDirectory) {
        die "Invalid input directory $inDirectory.\n";
    } else {
        # Loop through the directory.
        opendir(TMP, $inDirectory) || die "Could not open $inDirectory.\n";
        my @files = sort grep { $_ =~ /^kb[|_]g\./ } readdir(TMP);
        for my $inFile (@files) {
            # Open the input file.
            open(my $ih, "<$inDirectory/$inFile") || die "Could not open input file: $!\n";
            # Loop through it.
            while (! eof $ih) {
                my $line = <$ih>;
                chomp $line;
                $stats->Add(lineIn => 1);
                # Get the feature ID and function.
                my ($fid, $func) = split m/\s*\t\s*/, $line;
                # Update the feature. We track how many features were updated and
                # how many were not found.
                my $ok = $cdmi->UpdateEntity(Feature => $fid, { function => $func }, 1);
                if (! $ok) {
                    $stats->Add(FeatureNotFound => 1);
                } else {
                    $stats->Add(FeatureUpdated => 1);
                    # Now we need an annotation for this. The annotation takes place at the current
                    # time.
                    my $time = time;
                    # Compute the annotation ID.
                    my $annoID = $cdmi->ComputeNewAnnotationID($fid, $time);
                    # Apply the annotation.
                    $cdmi->InsertObject('IsAnnotatedBy', from_link => $fid, to_link => $annoID);
                    $cdmi->InsertObject('Annotation', id => $annoID, annotation_time => $time,
                            annotator => 'automatic', comment => "Set function to\n$func");
                    # Now we need to connect to the new roles. First, disconnect from the old ones.
                    my $count = $cdmi->Disconnect('IsFunctionalIn', Feature => $fid);
                    $stats->Add(RolesDisconnected => $count);
                    # Get the roles and the error count from the function.
                    my ($roles, $errors) = SeedUtils::roles_for_loading($func);
                    # Accumulate the errors in the stats object.
                    $stats->Add(roleErrors => $errors);
                    # Is this a suspicious function?
                    if (! defined $roles) {
                        # Yes, so track it.
                        $stats->Add(badFunction => 1);
                    } else {
                        # No, connect the roles.
                        for my $role (@$roles) {
                            # Insure this role exists.
                            my $hypo = hypo($role);
                            $loader->InsureEntity(Role => $role, hypothetical => $hypo);
                            # Connect it to the feature.
                            $cdmi->InsertObject('IsFunctionalIn', from_link => $role, to_link => $fid);
                            $stats->Add(RolesConnected => 1);
                        }
                    }
                }
            }
        }
    }
    print "All done:\n" . $stats->Show();
}

