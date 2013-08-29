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

=head1 CDMI FIGfam Loader

    CDMILoadFIGfams [options] releaseDirectory

This script loads FIGfam data from the SEED. The raw FIGfam files
are read in and the feature IDs converted from FIG IDs to KBase IDs. Only
features for genomes found in the KBase CDMI will be included in the
output. Six relations are loaded.

=over 4

=item Family

Represents the FIGfams themselves, and includes the B<id> and B<type>
fields. The B<id> is the FIGfam ID, and the B<type> is always C<FIGfam>.

=item FamilyFunction

One of these is created for each FIGfam, and it includes the B<id> and
B<family-function> fields. The B<id> is the FIGfam ID, and the
B<family-function> is the FIGfam's functional assignment. This relation
is built from the C<family.functions> input file.

=item HasMember

Relationship connecting each B<Family> (from-link) to each associated
member B<Feature> (to-link). This relation is built from the C<families.2c>
input file.

=item IsCoupledTo

Relationship connecting related B<Family> records. This relation is built
from the C<coupling.values> input file.

=item HasRepresentativeOf

Relationship connecting B<Family> (from-link) records to all the
B<Genome> (to-link) records for genomes having features in the family.
This relation is built in parallel to B<HasMember>.

=item IsFamilyFor

Relationship connecting B<Family> (from-link) records to all the
B<Role> (to-link) records for roles described in the FIGfams. This
relation is built from the C<family.functions> input file.

=back

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
the following.

=over 4

=item clear

If specified, the tables will be deleted and re-created before loading.

=item couplingFile

If specified, the name of a C<coupling.values> file to use. This allows
coupling information to be loaded even when it is not present in the
FIGfam release directory.

=back

There is one positional parameter: the name of the directory containing
the FIGfam release to load.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my ($couplingFile, $clear);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear,
        "couplingFile=s" => \$couplingFile);
if (! $cdmi) {
    print "usage: CDMILoadFIGfams [options] releaseDirectory\n";
} else {
    # Create the loader object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetSource('SEED');
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Get the input parameter.
    my ($releaseDirectory) = @ARGV;
    # Insure they're valid.
    if (! $releaseDirectory) {
        die "Missing release directory name.\n";
    } elsif (! -d $releaseDirectory) {
        die "Invalid release directory name $releaseDirectory.\n";
    } else {
        # Get the list of tables.
        my @tables = qw(Family FamilyFunction HasMember IsCoupledTo HasRepresentativeOf IsFamilyFor);
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
        # Start by deleting any existing FIGfams.
        print "Deleting old FIGfams.\n";
        my $ffQ = $cdmi->Get('Family', 'Family(type) = ?', ['FIGfam']);
        while (my $family = $ffQ->Fetch()) {
            my $newStats = $cdmi->Delete(Family => $family->PrimaryValue('id'));
            $stats->Accumulate($newStats);
        }
        # The first task is to create the FIGfams themselves. We do this
        # by reading the family.functions file.
        my $ih;
        print "Reading family functions file.\n";
        open($ih, "<$releaseDirectory/family.functions") || die "Could not open family.functions file: $!\n";
        while (! eof $ih) {
            # Read the family ID and the function.
            my ($family, $function) = $loader->GetLine($ih);
            $stats->Add(familyFunctionLineIn => 1);
            # Create the family records.
            $loader->InsertObject('Family', id => $family, type => 'FIGfam');
            if ($function) {
                $loader->InsertObject('FamilyFunction', id => $family,
                        family_function => $function);
            } else {
                 $stats->Add(functionMissing => 1);
            }
            # Now we mut associate the family with the roles implied by the
            # function.
            my ($roles, $errors) = SeedUtils::roles_for_loading($function);
            if (! defined $roles) {
                # Here the function does not appear to be a role.
                $stats->Add(roleRejected => 1);
            } else {
                # Here the function contained one or more roles. Count
                # the number of roles that were rejected for being too
                # long.
                $stats->Add(rolesTooLong => $errors);
                # Loop through the roles found.
                for my $role (@$roles) {
                    # Insure this role is in the database.
                    my $roleID = $loader->CheckRole($role);
                    # Connect it to the family.
                    $loader->InsertObject('IsFamilyFor', from_link => $family,
                            to_link => $roleID);
                }
            }
        }
        # Close the family.functions file.
        close $ih; undef $ih;
        # Now we must put the features into the families. We get this
        # information from the families.2c file. The HasRepresentativeOf
        # relationship presents a special problem, because we need to insure
        # we don't create duplicates. The following hash
        # will track the genomes for the current FIGfam. When the
        # FIGfam is completed, we will get the IDs for these genomes
        # and output them.
        my $genomes = {};
        my $currentFF;
        # We process the data in batches. This hash maps each FIGfam in
        # the current batch to its features.
        my $figFams = {};
        # This tracks all the features found in this batch.
        my $fids = {};
        # This counts the number of records in the current batch.
        my $batchSize = 0;
        # Open the families.2c file for input and loop through it.
        print "Processing member data.\n";
        open($ih, "<$releaseDirectory/families.2c") || die "Could not open families.2c file: $!\n";
        while (! eof $ih) {
            my ($family, $fid) = $loader->GetLine($ih);
            $stats->Add(lineIn => 1);
            # Is this a new family?
            if (! defined $currentFF || $family ne $currentFF) {
                # Yes. Process the genome relationships.
                ProcessGenomeLinks($loader, $genomes, $currentFF);
                # Set up for the next family.
                $currentFF = $family;
                $genomes = {};
            }
            # Get this feature's genome and store it in the hash.
            my $genome = SeedUtils::genome_of($fid);
            $genomes->{$genome} = 1;
            # Add this feature to the current batch.
            push @{$figFams->{$family}}, $fid;
            $batchSize++;
            # Save its ID.
            $fids->{$fid} = 1;
            # If this batch is full, process it.
            if ($batchSize >= 8000) {
                ProcessFigFamBatch($loader, $figFams, $fids);
                # Initialize for the next batch.
                $figFams = {};
                $fids = {};
                $batchSize = 0;
            }
        }
        # If there is a residual batch, process it.
        if ($batchSize) {
            ProcessFigFamBatch($loader, $figFams, $fids);
        }
        # If there is a residual genome list, process it.
        if ($currentFF) {
            ProcessGenomeLinks($loader, $genomes, $currentFF);
        }
        # Close the families.2c file.
        close $ih; undef $ih;
        # Now we process the coupling values.
        print "Processing coupling values.\n";
        # Get the default file name if one was not provided.
        if (! $couplingFile) {
            $couplingFile = "$releaseDirectory/coupling.values";
        }
        # Insure it exists.
        if (! -f $couplingFile) {
            print "Coupling file $couplingFile not found: skipping.\n";
        }
        # Open the file and loop through it.
        open($ih, "<$couplingFile") || die "Could not open coupling values file: $1\n";
        while (! eof $ih) {
            # Get this coupling record.
            my ($from, $to, $expScore, $fcScore) = $loader->GetLine($ih);
            $stats->Add(couplingValuesProcessed => 1);
            # Connect the FIGfams.
            $loader->InsertObject('IsCoupledTo', from_link => $from,
                    to_link => $to, co_expression_evidence => $expScore,
                    co_occurrence_evidence => $fcScore);
        }
        # Close the coupling file.
        close $ih; undef $ih;
        # Unspool the relations.
        print "Unspooling relations.\n";
        $loader->LoadRelations();
    }
    print "All done:\n" . $stats->Show();
}

=head2 Subroutines

=head3 ProcessFigFamBatch

    ProcessFigFamBatch($loader, $figFams);

Process a batch of FIGfam memberships. The main input is a hash mapping
FIGfam IDs (which are unchanged) to feature IDs (which are from the SEED
and must be translated). We get the KBase IDs for the features and then
output B<HasMember> records for them.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for loading the database and tracking statistics.

=item figFams

Reference to a hash keyed by FIGfam ID. Each FIGfam is mapped to a
list of features in the FIGfam.

=item fids

Reference to a hash whose keys are all the feature IDs in this batch.

=back

=cut

sub ProcessFigFamBatch {
    # Get the parameters.
    my ($loader, $figFams, $fids) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the KBase IDs for the features.
    my $idMapping = $loader->FindKBaseIDs('Feature', [keys %$fids]);
    # Loop through the FIGfams.
    for my $figFam (keys %$figFams) {
        $stats->Add(figFamInBatch => 1);
        # Loop through the features in this FIGfam.
        my $members = $figFams->{$figFam};
        for my $fid (@$members) {
            # Look for the KBase ID of this member.
            my $kbid = $idMapping->{$fid};
            if (! defined $kbid) {
                # Not found, so skip it.
                $stats->Add(fidNotFound => 1);
            } else {
                # Add its membership to the output.
                $loader->InsertObject('HasMember', from_link => $figFam,
                        to_link => $kbid);
                $stats->Add(memberships => 1);
            }
        }
    }
    print "Batch processed: " . $stats->Ask('lineIn') . " lines read.\n";
}

=head3 ProcessGenomeLinks

    ProcessGenomeLinks($loader, $genomes, $currentFF);

Denote that the specified genomes belong to the specified FIGfam. This
method must find the KBase IDs for the genomes and then output the
appropriate B<HasRepresentativeOf> records.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for loading the database and tracking statistics.

=item genomes

Reference to a hash whose keys are the SEED IDs of the genomes in the
specified FIGfam.

=item currentFF

ID of the FIGfam of interest.

=back

=cut

sub ProcessGenomeLinks {
    # Get the parameters.
    my ($loader, $genomes, $currentFF) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the IDs of the specified genomes.
    my $idMapping = $loader->FindKBaseIDs('Genome', [keys %$genomes]);
    # Loop through the KBase IDs found, creating the HasRepresentativeOf
    # records.
    for my $genome (keys %$genomes) {
        my $kbid = $idMapping->{$genome};
        if (! defined $kbid) {
            $stats->Add(genomeNotFound => 1);
        } else {
            # We have a KBase ID for the genome, so add it.
            $loader->InsertObject('HasRepresentativeOf', from_link => $currentFF,
                    to_link => $kbid);
            $stats->Add(genomeConnected => 1);
        }
    }
    print "Genomes output for $currentFF.\n";
}

