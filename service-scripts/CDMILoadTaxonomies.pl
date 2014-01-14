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
    use Bio::KBase::CDMI::CDMILoader;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::TaxonomyUtils;

=head1 CDMI Taxonomy Loader

    CDMILoadTaxonomies [options] taxonDirectory

This script loads NCBI taxonomy information into a Kbase Central Data Model
Instance. This is global information that involves deleting and recreating
entire tables. In particular, the following tables will be truncated and
rebuilt.

=over 4

=item TaxonomicGrouping

organism classifications

=item IsGroupFor

relationship that organizes taxonomic groupings into a hierarchy

=back

In addition, genomes connected to taxonomy IDs that have been remapped
will be moved to from the old IDs to the new ones.

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item verify

If specified, then instead of loading the taxonomic groupings, the hidden-group
flags will be verified against the load files. If specified with the value C<fix>,
the incorrect values will be updated in place.

=back

There is a single positional parameter that specifies the directory
containing the NCBI taxonomy files.

=cut

# Insure the log is unbuffered.
$| = 1;
# Connect to the database using the command-line options.
my $verify;
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script('verify:s' => \$verify);
if (! $cdmi) {
    print "usage: CDMILoadTaxonomies [options] taxonomyDirectory\n";
} else {
    # Get the directory of taxonomy files.
    my $taxDirectory = $ARGV[0];
    if (! $taxDirectory) {
        die "No taxonomy directory specified.\n";
    } elsif (! -d $taxDirectory) {
        die "Invalid taxonomy directory $taxDirectory.\n";
    } elsif (defined $verify) {
        # Here we want to verify the hidden-group flags.
        # Determine whether or not we are fixing.
        my $fix = ($verify eq 'fix');
        # Call the verifier.
        my $stats = Bio::KBase::CDMI::TaxonomyUtils::VerifyHidden($cdmi,
                $taxDirectory, $fix);
        # Display the results.
        print "All done:\n" . $stats->Show();
    } else {
        # Clear the existing taxonomy data.
        my $stats = Bio::KBase::CDMI::TaxonomyUtils::ClearTaxonomies($cdmi);
        # Create the CDMI loader.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        $loader->stats->Accumulate($stats);
        # Read the new taxonomy data.
        Bio::KBase::CDMI::TaxonomyUtils::ReadTaxonomies($loader, $taxDirectory);
        # Display the full statistics.
        print "All done:\n" . $loader->stats->Show();
    }
}


