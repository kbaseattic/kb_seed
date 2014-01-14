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
    use Bio::KBase::CDMI::CDMILoader;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::TaxonomyUtils;

=head1 CDMI Genome Set Loader

    CDMILoadGenomeSets [options] genomeSetFile

This script loads the OTU sets from the specified genome set file. This is
global information that requires deleting and recreating the following
tables.

=over 4

=item OTU

set of related genomes

=item IsCollectionOf

relationship that connects OTUs to genomes

=back

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item source

Source (core) database for the genome IDs in the input file. The
default is C<SEED>.

=back

There is a single positional parameter that specifies the genome set
input file. This is a tab-delimited file with three columns: genome
set number, genome ID, and genome name. The first genome ID for a set
is presumed to be the representative genome.

=cut

# The source database name will be stored in here.
my $source = 'SEED';
# Connect to the database using the command-line options.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script('source=s' => \$source);
if (! $cdmi) {
    print "usage: CDMILoadGenomeSets [options] genomeSetFile\n";
} else {
    # Create the loader utility object.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    # Get the genome set file name.
    my $setFile = $ARGV[0];
    # Get the statistics object inside the loader.
    my $stats = $loader->stats;
    # Perform the load.
    Bio::KBase::CDMI::TaxonomyUtils::LoadGenomeSets($loader, 'SEED', $setFile);
    # Display the full statistics.
    print "All done:\n" . $stats->Show();
}


