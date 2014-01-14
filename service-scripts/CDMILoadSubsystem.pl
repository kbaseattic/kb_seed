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
    use SeedUtils;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Digest::MD5;
    use IDServerAPIClient;
    use Bio::KBase::CDMI::SubsystemUtils;

=head1 CDMI Subsystem Loader

    CDMILoadSubsystem [options] source subsystemDirectory

Load a subsystem into a KBase Central Data Model Instance. The subsystem
is represented by a standard SEED subsystem directory.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus the
following.

=over 4

=item recursive

If this option is specified, then instead of loading a single subsystem from
the specified directory, a subsystem will be loaded from each subdirectory
of the specified directory. This allows multiple subsystems from a single
source to be loaded in one pass.

=item clear

Recreate the subsystem tables before loading.

=item idserver

URL to use for the ID server. The default uses the standard KBase ID
server.

=item missing

If specified, only subsystems not already in the database will be
loaded.

=back

There are two positional parameters-- the source database name (e.g. C<SEED>,
C<MOL>, ...) and the name of the directory containing the subsystem data.

=cut

# Create the command-line option variables.
my ($recursive, $clear, $id_server_url, $missing);

$id_server_url = "http://bio-data-1.mcs.anl.gov:8080/services/idserver";

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("recursive" => \$recursive, "clear" => \$clear,
    "idserver=s" => \$id_server_url, "missing" => \$missing);
if (! $cdmi) {
    print "usage: CDMILoadSubsystem [options] source subsystemDirectory\n";
} else {
    # Get the source and subsystem directory.
    my ($source, $subsystemDirectory) = @ARGV;
    if (! $source) {
        die "No source database specified.\n";
    } elsif (! $subsystemDirectory) {
        die "No subsystem directory specified.\n";
    } elsif (! -d $subsystemDirectory) {
        die "Subsystem directory $subsystemDirectory not found.\n";
    } else {
        # Connect to the KBID server and create the loader utility object.
        my $id_server = IDServerAPIClient->new($id_server_url);
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi, $id_server);
        $loader->SetSource($source);
        # Are we clearing?
        if($clear) {
            # Yes. Recreate the subsystem tables.
            my @tables = qw(Subsystem IsClassFor SubsystemClass IsSuperclassOf Provided
                            Includes Describes Variant IsRoleOf IsImplementedBy
                            SSCell IsRowOf SSRow Contains Uses);
            for my $table (@tables) {
                print "Recreating $table.\n";
                $cdmi->CreateTable($table, 1);
            }
        }
        # Are we in recursive mode?
        if (! $recursive) {
            # No. Load the one subsystem.
            Bio::KBase::CDMI::SubsystemUtils::LoadSubsystem($loader, $source, 
                    $subsystemDirectory, $missing);
        } else {
            # Yes. Get the subdirectories.
            opendir(TMP, $subsystemDirectory) || die "Could not open $subsystemDirectory.\n";
            my @subDirs = sort grep { substr($_,0,1) ne '.' } readdir(TMP);
            print scalar(@subDirs) . " entries found in $subsystemDirectory.\n";
            # Loop through the subdirectories.
            for my $subDir (sort @subDirs) {
                my $fullPath = "$subsystemDirectory/$subDir";
                if (-d $fullPath) {
                    Bio::KBase::CDMI::SubsystemUtils::LoadSubsystem($loader, 
                            $source, $fullPath, $missing);
                }
            }
        }
        # Display the statistics.
        print "All done.\n" . $loader->stats->Show();
    }
}

