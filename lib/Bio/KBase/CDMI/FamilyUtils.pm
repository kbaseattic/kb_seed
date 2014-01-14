package Bio::KBase::CDMI::FamilyUtils;

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

=head1 CDMI Protein Family Loader

This module contains methods for loading protein family data into 
the KBase. Protein families come in two basic styles-- FIGfams, 
which are feature-based, and external families, which are protein-based. 
Both kinds of families are loaded from directories containing the family 
definitions. In each directory there will be two tab-delimited files of primary
importance.

=over 4

=item families.2c

This file relates each family to its members. The first column contains
the family ID and the second contains the member ID. These records should
be sorted by family ID, but all that is really necessary is that all of
the family members be grouped together.

=item families.functions

This file describes the function associated with each family. The first
column contains the family ID and the second contains the function text.

=back

=over 4

=item Family

Represents the families themselves, and includes the B<id>,
B<release>, B<type>, and B<family-function> fields.

=item FamilyAlignment

If the family has an associated alignment, it will be stored in
this table in FASTA format. This table is built from additional
data for certain family types.

=item HasMember

Relationship connecting each B<Family> (from-link) to each associated
member B<Feature> (to-link). This relation is built from the C<families.2c>
input file for feature-based families.  It is not used for protein-based
families.

=item HasProteinMember

Relationship connecting each B<Family> (from-link) to each associated
member B<ProteinSequence> (to-link). This relation is built from the
C<families.2c> input file for protein-based families. It is computed
for feature-based families.

=item IsCoupledTo

Relationship connecting related B<Family> records. This relation is built
from additional data for certain family types.

=item HasRepresentativeOf

Relationship connecting B<Family> (from-link) records to all the
B<Genome> (to-link) records for genomes having features in the family.
This relation is built in parallel to B<HasMember> for feature-based
families.

=item IsFamilyFor

Relationship connecting B<Family> (from-link) records to all the
B<Role> (to-link) records for roles described in the FIGfams. This
relation is built from the C<family.functions> input file.

=back

=head3 LoadFamily

    Bio::KBase::CDMI::FamilyUtils::LoadFamily($loader, $type, $releaseDirectory,
            $release, $clear, $nodelete);

Load protein families of a specified type into the database.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for loading the database.

=item type

Type of protein family to load. This must correspond to a L<Bio::KBase::CDMI::FamilyType>
subclass.

=item releaseDirectory

Name of the directory containing the family files.

=item release (optional)

Release code for the family. If omitted, the release code will be taken from
the last level of the directory name.

=item clear (optional)

TRUE if the protein family tables should be deleted and recreated prior to
loading. The default is FALSE.

=item nodelete (optional)

TRUE if the old family data should NOT be deleted, else FALSE. The default is
FALSE.

=cut

sub LoadFamily {
    # Get the parameters.
    my ($loader, $type, $releaseDirectory, $release, $clear, $nodelete) = @_;
    # Extract the statistics object and the CDMI object.
    my $stats = $loader->stats;
    my $cdmi = $loader->cdmi;
    # Get the list of tables.
    my @tables = qw(Family FamilyAlignment HasMember HasProteinMember IsCoupledTo HasRepresentativeOf IsFamilyFor);
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
    # Compute the release code.
    if (! $release) {
        # No release code specified on the command line, so compute
        # it from the directory name.
        my @parts = split /[\/\\]/, $releaseDirectory;
        $release = pop @parts;
    }
    # Create the family-type object.
    my $typeModule = "Bio::KBase::CDMI::FamilyType::$type";
    eval "require $typeModule";
    my $ftype = eval("$typeModule->new(\$release)");
    if ($@) {
        die "Error creating family type object: $@\n";
    }
    # This counter is used to track progress.
    my $count = 0;
    # Call the initialization method.
    $ftype->Init($loader, $releaseDirectory);
    # Extract the family type name and release code.
    my $typeName = $ftype->typeName;
    my $releaseCode = $ftype->release;
    # We are now ready to begin. Start by deleting any existing
    # families.
    if (! $nodelete) {
        print "Deleting old families of type $type.\n";
        my $ffQ = $cdmi->Get('Family', 'Family(type) = ?', [$typeName]);
        while (my $family = $ffQ->Fetch()) {
            my $newStats = $cdmi->Delete(Family => $family->PrimaryValue('id'));
            $stats->Accumulate($newStats);
            $count++;
            if ($count % 5000 == 0) {
                print "$count families deleted.\n";
            }
        }
    }
    # The first task is to create the families themselves. We do this
    # by reading the family.functions file.
    $count = 0;
    my $ih;
    print "Reading family functions file.\n";
    open($ih, "<$releaseDirectory/family.functions") || die "Could not open family.functions file: $!\n";
    while (! eof $ih) {
        # Read the family ID and the function.
        my ($family, $function) = $loader->GetLine($ih);
        $stats->Add(familyFunctionLineIn => 1);
        # Insure the function is non-null.
        if (! $function) {
            $stats->Add(functionMissing => 1);
            $function = '';
        }
        # Create the family records.
        $loader->InsertObject('Family', id => $family, type => $typeName,
            release => $releaseCode, family_function => $function);
        # Now we must associate the family with the roles implied by the
        # function. We only do this for non-null functions.
        if ($function) {
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
        $count++;
        if ($count % 5000 == 0) {
            print "$count families loaded.\n";
        }
    }
    # Close the family.functions file.
    close $ih; undef $ih;
    # Now we must put the members into the families. We get this
    # information from the families.2c file. For feature-based
    # families, the HasRepresentativeOf and HasProteinMember
    # relationship present special problems, because we need to
    # insure we don't create duplicates. The following hashes track
    # the KBase genome and protein IDs, respectively, for the current
    # family. When the family is completed, we will output them.
    my $genomes = {};
    my $proteins = {};
    my $currentFF;
    $count = 0;
    # Open the families.2c file for input and loop through it.
    print "Processing member data.\n";
    open($ih, "<$releaseDirectory/families.2c") || die "Could not open families.2c file: $!\n";
    while (! eof $ih) {
        my ($family, $mem) = $loader->GetLine($ih);
        $stats->Add(lineIn => 1);
        $count++;
        if ($count % 10000 == 0) {
            print "$count members processed.\n";
        }
        # Is this a new family?
        if (! defined $currentFF || $family ne $currentFF) {
            # Yes. Clear the hashes and set up for the next family.
            $currentFF = $family;
            $genomes = {};
            $proteins = {};
        }
        # Declare the basic data variables. These will store the
        # KBase feature, protein, and genome IDs, respectively.
        my ($fid, $pid, $genome);
        # Are we feature-based or protein-based?
        if ($ftype->featureBased) {
            # Get the data for this feature.
            ($fid, $pid, $genome) = $ftype->ResolveFeatureMember($loader,
                    $mem);
        } else {
            # Here we're protein-based. Get the protein ID.
            $pid = $ftype->ResolveProteinMember($loader, $mem);
        }
        # Now we store the stuff we've found.
        if ($pid) {
            # There is a protein. If it's new for this family, connect
            # it.
            if (! $proteins->{$pid}) {
                $stats->Add(newProteinConnected => 1);
                $loader->InsertObject('HasProteinMember',
                        from_link => $family,
                        source_id => $mem, to_link => $pid);
                # Insure we don't do this protein again.
                $proteins->{$pid} = 1;
            } else {
                $stats->Add(oldProteinSkipped => 1);
            }
        }
        if ($fid) {
            # There is a feature. This is always connected.
            $stats->Add(newFeatureConnected => 1);
            $loader->InsertObject('HasMember', from_link => $family,
                    to_link => $fid);
            # Check the genome.
            if (! $genomes->{$genome}) {
                # It's new, so connect it.
                $stats->Add(newGenomeConnected => 1);
                $loader->InsertObject('HasRepresentativeOf',
                        from_link => $family, to_link => $genome);
                $stats->Add(newGenomeConnected => 1);
                $genomes->{$genome} = 1;
            } else {
                $stats->Add(oldGenomeSkipped => 1);
            }
        }
    }
    # Close the families.2c file.
    close $ih;
    # Process any additional files.
    $ftype->ProcessAdditionalFiles($loader, $releaseDirectory);
    # Unspool the relations.
    print "Unspooling relations.\n";
    $loader->LoadRelations();
}

1;