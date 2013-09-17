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
    use CustomAttributes;
    use Dlits;
    use Date::Parse;

=head1 CDMI Publication Loader

    CDMILoadPublications [options]

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

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus the
following.

=over 4

=item attrHost

Name of the host server containing the global and attribute databases.
The default is taken from B<FIG_Config> parameters.

=item attrPort

Port to use for connecting to the global and attribute databases. The
default is C<3306>.

=item attrDBD

Name of the database definition file for the attribute database. The default
is taken from the B<FIG_Config> parameters.

=back

=cut

# Prevent buffering on STDOUT.
$| = 1;
# Connect to the database using the command-line options.
my $attrHost = $FIG_Config::attrHost;
my $attrPort = 3306;
my $attrDBD = $FIG_Config::attrDBD;
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script('attrHost=s' => \$attrHost,
        'attrPort=i' => \$attrPort, 'attrDBD=s' => \$attrDBD);

if (! $cdmi) {
    print "usage: CDMILoadPublications [options]\n";
} else {
    # Create the statistics object.
    my $stats = Stats->new();
    # Recreate the two tables.
    print "Recreating tables.\n";
    $cdmi->CreateTable('Publication', 1);
    $cdmi->CreateTable('Concerns', 1);
    # Get the attribute database.
    print "Connecting to attribute database.\n";
    my $ca = CustomAttributes->new(dbport => $attrPort, dbhost => $attrHost,
            DBD => $attrDBD, dbuser => 'seed');
    # Get the seed global database. We set the default host and port here.
    print "Connecting to SEED global databaase.\n";
    my $sgdb = DBKernel->new('mysql', 'seed_global', 'seed', undef, $attrPort,
                             $attrHost);
    # This hash will track the publications already stored.
    my %pubs;
    # We'll use this counter to show our progress.
    my $count = 0;
    # Loop through the dlit evidence codes.
    print "Looking for evidence.\n";
    my $query = $ca->Get('IsEvidencedBy', "IsEvidencedBy(to_link) LIKE ? AND IsEvidencedBy(value) LIKE ?",
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
                # No. We need to get its data from Pubmed.
                my $articleH = Dlits::get_pubmed_document_details($sgdb, $pubmed);
                if (! $articleH) {
                    # We couldn't find it. Store it as unknown.
                    $stats->Add(unknownPubmed => 1);
                    $pubs{$pubmed} = { title => "(unknown)",
                            'link' => "http://www.ncbi.nlm.nih.gov/pubmed/$pubmed",
                            pubdate => 0,
                            id => $pubmed };
                } else {
                    # Here we found the title. Convert the date. Note we must
                    # deal with the possibility the date is missing or invalid.
                    my $pubdate = str2time($articleH->{pubdate});
                    if (! defined $pubdate) {
                        $pubdate = 0;
                        $stats->Add(badPubdate => 1);
                    }
                    # Store the new publication in the hash.
                    $stats->Add(newPubmed => 1);
                    $pubs{$pubmed} = { title => $articleH->{title},
                            'link' => "http://www.ncbi.nlm.nih.gov/pubmed/$pubmed",
                            pubdate => $pubdate,
                            id => $pubmed };
                }
            }
            # Look for the protein sequence in the CDMI.
            if (! $cdmi->Exists(ProteinSequence => $protID)) {
                $stats->Add(proteinNotFound => 1);
            } else {
                # We found it, so add this link.
                $cdmi->InsertObject('Concerns', from_link => $pubmed, to_link => $protID);
                $stats->Add(publicationLinked => 1);
            }
            # Display our progress.
            $count++;
            if ($count % 1000 == 0) {
                print "$count evidence records processed.\n";
            }
        }
    }
    # Now output the publications.
    my $pubCount = scalar(keys %pubs);
    print "Writing $pubCount publications.\n";
    for my $pubmed (sort keys %pubs) {
        my $pubData = $pubs{$pubmed};
        $cdmi->InsertObject('Publication', $pubData);
        $stats->Add(publicationOut => 1);
    }
    print "All done:\n" . $stats->Show();
}

