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
use Bio::KBase::CDMI::GenomeUtils;
use Getopt::Long;
use IDServerAPIClient;
use MD5Computer;
use BasicLocation;
use Digest::MD5;

=head1 CDMI Genome Loader

    CDMILoadGenome [options] source genomeDirectory

Load a genome into a KBase Central Data Model Instance. The genome
is represented by five files in a single directory, as follows.

=over 4

=item contigs.fa

A FASTA file containing the DNA sequences for the contigs.

=item features.tab

A tab-delimited file with one line for each feature. The first column
contains the feature ID, the second contains the feature type,
the third contains the feature location, the fourth contains an optional
parent feature ID, the fifth contains an optional subset ID,
and the remaining columns contain alternate identifiers for the feature.

=item functions.tab

A tab-delimited file with one line for each feature. The first column
contains the feature ID and the second contains the feature's functional
assignment.

=item proteins.fa

A FASTA file containing the protein translations for each feature in
the genome.

=item metadata.tbl

A file containing named attributes. Each attribute is represented by
a single line containing the attribute name followed by one or more
lines containing the attribute value, terminated by a line containing
double slashes (C<//>). The attributes currently used are

=over 8

=item complete

C<1> for a complete genome, C<0> for an incomplete genome. The default
is C<1>.

=item genetic_code

The genetic code used for protein translation for most of the contigs
in the genome. The default is C<11>.

=item name

The scientific name of the genome. This field is required.

=back

=back

In the B<features.tab> file, a location is specified as a comma-separated
list of one or more I<location strings>. Each location string consists of
a contig ID, an underscore, a start location, a strand (C<+> or C<->),
and a length. So, for example, C<NC_004663_4594728+66> indicates a feature
beginning at location 4594728 on the plus strand of contig NC_004663
and extending for 66 base pairs.

The following feature types are expected.

=over 4

=item 3putr

3' UTR for a transcript

=item 5putr

5' UTR for a transcript

=item att

attachment site

=item bs

binding site

=item CDS

protein-encoding gene

=item crispr

CRISPR location

=item crs

CRISPR spacer

=item locus

genetic region possibly producing multiple proteins

=item mRNA

gene transcript

=item pbs

protein binding site

=item pp

prophage

=item prm

promoter region

=item pseudo

pseudogene

=item rna

RNA feature

=item rsw

riboswitch

=back

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus the
following.

=over 4

=item recursive

If this option is specified, then instead of loading a single genome from
the specified directory, a genome will be loaded from each subdirectory
of the specified directory. This allows multiple genomes from a single
source to be loaded in one pass.

=item newOnly

If this option is specified, a genome will only be loaded if it is
not already found in the database.

=item clear

If this option is specified, the genome tables will be recreated
before loading.

=item idserver

URL to use for the ID server. The default uses the standard KBase ID
server. If C<none> is specified, source IDs will be used instead of
the ID server.

=item validate

Validate the input files without loading them.

=item slow

Use individual INSERT commands to load the database instead of spooling into
sequential load files.

=item noProteins

If specified, protein sequences will not be loaded.

=item noContigs

If specified, contigs will not be loaded.

=back

There are two positional parameters-- the source database name (e.g. C<SEED>,
C<MOL>, ...) and the name of the directory containing the genome data.

=cut

# Create the command-line option variables.
my ($recursive, $newOnly, $clear, $id_server_url, $validate, $slow, $noContigs, $noProteins);
# Turn off buffering for progress messages.
$| = 1;
# Connect to the database. If we are validating, we parse the command
# line but don't connect. Note we create a hash of the Getopt::Long
# parameters that we can pass into whichever method we use, and we check
# for the validate parameter first. This is complicated enough that I'm
# starting to question the wisdom of the whole validate mode instead of
# a separate validator.
$validate = grep { $_ =~ /^--?validate$/ } @ARGV;
my ($rc, $cdmi);
my %parms = ("recursive" => \$recursive, "newOnly" => \$newOnly,
        "clear" => \$clear, "idserver=s" => \$id_server_url,
        "validate" => \$validate, "slow" => \$slow, "noContigs" => \$noContigs,
        "noProteins" => \$noProteins);
if ($validate) {
    $rc = GetOptions(%parms);
} else {
    $cdmi = Bio::KBase::CDMI::CDMI->new_for_script(%parms);
    $rc = $cdmi;
    if ($rc) {
        print "Connected to CDMI.\n";
    }
}
if (! $rc) {
    print "usage: CDMILoadGenome [options] source genomeDirectory\n";
    exit;
}
my $time = time;
# Get the source and genome directory.
my ($source, $genomeDirectory) = @ARGV;
if (! $source) {
    die "No source database specified.\n";
} elsif (! $genomeDirectory) {
    die "No genome directory specified.\n";
} elsif (! -d $genomeDirectory) {
    die "Genome directory $genomeDirectory not found.\n";
} else {
	# Build our options hash.
	my $options = { slow => $slow, noContigs => $noContigs, newOnly => $newOnly,
					noProteins => $noProteins };
    # Connect to the KBID server and create the loader utility object.
    my $id_server;
    if ($id_server_url eq 'none') {
    	$options->{sourceIDs} = 1;
    } elsif ($id_server_url) {
        $id_server = IDServerAPIClient->new($id_server_url);
    }
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi, $id_server);
    $loader->SetSource($source);
    # Are we clearing?
    if($clear) {
        # Yes. Recreate the genome tables.
        my @tables = qw(Publication Role Concerns IsFunctionalIn
            ProteinSequence IsProteinFor Feature FeatureAlias
            IsLocatedIn IsOwnerOf Submitted
            Contig IsComposedOf Genome IsAlignedIn Variation
            IsSequenceOf IsTaxonomyOf ContigSequence HasSection
            ContigChunk Encompasses);
        for my $table (@tables) {
            print "Recreating $table.\n";
            $cdmi->CreateTable($table, 1);
        }
    }
    # Are we in recursive mode?
    if (! $recursive) {
        # No. Load the one genome.
        Bio::KBase::CDMI::GenomeUtils::LoadGenome($loader, $genomeDirectory, $validate, $source, $options);
    } else {
        # Yes. Get the subdirectories.
        opendir(TMP, $genomeDirectory) || die "Could not open $genomeDirectory.\n";
        my @subDirs = sort grep { substr($_,0,1) ne '.' } readdir(TMP);
        print scalar(@subDirs) . " entries found in $genomeDirectory.\n";
        # Loop through the subdirectories.
        for my $subDir (@subDirs) {
            my $fullPath = "$genomeDirectory/$subDir";
            if (-d $fullPath) {
                Bio::KBase::CDMI::GenomeUtils::LoadGenome($loader, $fullPath, $validate, $source, $options);
            }
        }
    }
    # Display the statistics.
    my $duration = time - $time;
    print "Load completed in $duration seconds.\n";
    print "All done.\n" . $loader->stats->Show();
}


