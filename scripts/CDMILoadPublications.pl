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
    use CDMI;
    use CDMILoader;
    use CustomAttributes;
    use HyperLink;

=head1 CDMI Publication Loader

    CDMILoadPublications [options] titleFile

This script loads the publication data from the SEED attribute database.
The publication data is stored as dlit evidence code attributes of proteins.
The script will retrieve the complete list of publications and replace
them. In particular, the following tables will be truncated and
rebuilt.

=over 4

=item Publication

citable publication stored in PUBMED

=item Concerns

relationship from publications to protein sequences.

=back

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<CDMI/new_for_script> plus the
following.

=over 4

=item attrHost

Name of the host server containing the attribute database. The default is
taken from B<FIG_Config> parameters.

=item attrPort

Port to use for connecting to the attribute database. The default is C<3306>.

=item attrDBD

Name of the database definition file for the attribute database. The default
is taken from the B<FIG_Config> parameters.

=back

There is a single positional parameter: the name of a tab-delimited file
containing PUBMED IDs in the first column and publication titles in the
second column.

=cut

# Connect to the database using the command-line options.
my $attrHost = $FIG_Config::attrHost;
my $attrPort = 3306;
my $attrDBD = $FIG_Config::attrDBD;
my $cdmi = CDMI->new_for_script('attrHost=s' => \$attrHost,
        'attrPort=i' => \$attrPort, 'attrDBD=s' => \$attrDBD);
if (! $cdmi) {
    print "usage: CDMILoadPublications [options] titleFile\n";
} else {
    # Create the statistics object.
    my $stats = Stats->new();
    # Recreate the two tables.
    print "Recreating tables.\n";
    $cdmi->CreateTable('Publication');
    $cdmi->CreateTable('Concerns');
    # Get the attribute database.
    print "Connecting to attribute database.\n";
    my $ca = CustomAttributes->new(dbport => $attrPort, dbhost => $attrHost,
            DBD => $attrDBD, dbuser => 'seed');
    # This hash will track the publications already stored. We prime it
    # with the data in the publications file.
    my %pubs;
    my $ih;
    my $titleFile = $ARGV[0];
    if (! $titleFile) {
        print "No publication title file specified.\n";
    } elsif (! -s $titleFile) {
        print "Publication title file $titleFile not found or empty.\n";
    } else {
        open $ih, "<$titleFile" || die "Could not open title file: $!\n";
        print "Reading titles from $titleFile.\n";
        while (! eof $ih) {
            my ($pubmed, $title) = CDMILoader::GetLine($ih);
            my $link = HyperLink->new($title, "http://www.ncbi.nlm.nih.gov/pubmed/$pubmed");
            $pubs{$pubmed} = $link;
            $stats->Add(titles => 1);
        }
    }
    print "Looking for evidence.\n";
    # Loop through the dlit evidence codes.
    my $query = $ca->Get('IsEvidencedBy', "IsEvidencedBy(to-link) LIKE ? AND IsEvidencedBy(value) LIKE ?",
            ['Protein:%', 'dlit%']);
    while (my $evidence = $query->Fetch()) {
        $stats->Add(evidenceFound => 1);
        # Get the protein ID and the pubmed ID.
        my $key = $evidence->PrimaryValue('to-link');
        my (undef, $protID) = split(':', $key);
        my $value = $evidence->PrimaryValue('value');
        unless ($protID && $value =~ /dlit\((\d+)/) {
            # Here we have one of the badly-formatted attributes.
            $stats->Add(invalidEvidence => 1);
        } else {
            my $pubmed = $1;
            # Now we have a valid publication ID and protein.
            $stats->Add(dlits => 1);
            # Does this publication already exist?
            if (! $pubs{$pubmed}) {
                # No. We need to add it to the hash with a made-up title.
                $pubs{$pubmed} = HyperLink->new("<unknown>", "http://www.ncbi.nlm.nih.gov/pubmed/$pubmed");
                $stats->Add(newPubmed => 1);
            }
            # Look for the protein sequence in the CDMI.
            if (! $cdmi->Exists(ProteinSequence => $protID)) {
                $stats->Add(proteinNotFound => 1);
            } else {
                # We found it, so add this link.
                $cdmi->InsertObject('Concerns', from_link => $pubmed, to_link => $protID);
                $stats->Add(publicationLinked => 1);
            }
        }
    }
    # Now output the publications.
    print "Writing publications.\n";
    for my $pubmed (keys %pubs) {
        $cdmi->InsertObject('Publication', id => $pubmed, citation => $pubs{$pubmed});
        $stats->Add(publicationOut => 1);
    }
    print "All done:\n" . $stats->Show();
}

