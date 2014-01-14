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
    use Bio::KBase::CDMI::FamilyUtils;

=head1 CDMI Protein Family Loader

    CDMILoadFamilies [options] type releaseDirectory

This script loads protein family data into the KBase. Protein families
come in two basic styles-- FIGfams, which are feature-based, and
external families, which are protein-based. Both kinds of families
are loaded from directories containing the family definitions. In
each directory there will be two tab-delimited files of primary
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

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus
the following.

=over 4

=item clear

If specified, the tables will be deleted and re-created before loading.

=item nodelete

If specified, old families of the specified type will NOT be deleted
prior to loading. Use this option if the families of a specified type
must be loaded in multiple passes, to prevent the families of previous
passes from being removed.

=item release

Release code for this set of families. If omitted, the final segment of
the input directory name will be used.

=back

There are two positional parameters: the type of family, and the name of
the directory containing the family files.

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my ($clear, $release, $nodelete);
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear,
        "release=s" => \$release, nodelete => \$nodelete);
if (! $cdmi) {
    print "usage: CDMILoadFamilies [options] type releaseDirectory\n";
} else {
    # Create the loader object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Extract the statistics object.
    my $stats = $loader->stats;
    # Get the input parameters.
    my ($type, $releaseDirectory) = @ARGV;
    # Insure they're valid.
    if (! $releaseDirectory) {
        die "Missing release directory name.\n";
    } elsif (! -d $releaseDirectory) {
        die "Invalid release directory name $releaseDirectory.\n";
    } else {
        Bio::KBase::CDMI::FamilyUtils::LoadFamily($loader, $type, 
                $releaseDirectory, $release, $clear, $nodelete);
    }
    print "All done:\n" . $stats->Show();
}
