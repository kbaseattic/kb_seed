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

=head1 CDMI Microbial Phenotype Loader

    CDMILoadPhenotypes [options] source loadDirectory

Load microbial phenotype experiment data into a KBase Central Data
Model Instance. The variation data is represented by eleven files in a
single directory. Many of the IDs in the files will be from the source
database and need to be converted to KBase IDs. The low-level name
of the directory must be the same as the genome's ID in the source
database. In some cases there are two fields specified for an ID. In
this case, the first is an ID from the source database and the second
is a KBase ID. The KBase ID will be used if it is present, and the
source ID will be converted otherwise. If neither ID is present, then
it usually indicates that a particular link does not apply.

Each file is tab-delimited, with a header line at the beginning.

The files are as follows.

=over 4

=item phenotype_experiment.tab

Each record in this file corresponds to a B<PhenotypeExperiment>. The fields
are (0) experiment-id (source-id), (1) description text (description),
(2,3) people links, (4) metadata string (metadata), and (5) publication ID
(PublishedExperiment.from-link).

The people links are semicolon-delimited strings containing (person-id, role)
pairs, the elements of each pair separated by commas. Each pair is used to
create a B<PerformedExperiment> record and optionally a new B<Person> record.
If the links appear in the (2) column, a person is represented by a source ID
that would be found in the C<person.tab> file. If the links appear in the
(3) column, a person is represented by a KBase ID.

=item person.tab

Each record in this file corresponds to a B<Person>. A person is a global
object, and it is necessary to verify that the person does not already
exist. The fields are (0) the person ID (source-id), (1) the first name
(firstName), (2) the last name (lastName), (3) the contact email
(contactEmail), and (4) the institution name (institution).

=item protocol.tab

Each record in this file corresponds to a B<Protocol> record. A protocol
is a global object, and it is necessary to verify that the protocol does
not already exist. The fields are (0) the protocol ID (source-id), (1) the
name (name), (2) the protocol description (description), and an
optional publication link (PublishedProtocol.from-link). The publication
link is expressed as a PUBMED ID.

=item publication.tab

Each record in this file corresponds to a B<Publication> record. A
publication is a global object, and it is necessary to verify that the
publication does not already exist. The fields are (0) the publication
id (id), (1) the publication URL (link), (2) the publication date (pubdate),
and (3) the publication title (title). If the publication title is
missing, it will be set to C<(unknown)>.

=item experimental_unit.tab

Each record in this file corresponds to an B<ExperimentalUnit> record.
Experimental units belong to strains, and when a strain is being replaced,
all its experimental units are removed along with it. The fields are
(0) the source ID (source-id), (1,2) the parent phenotype experiment
(HasExperimentalUnit.from-link), (3,4) the relevant experimental environment
type (UsedInExperimentalUnit.from-link), and (5,6) the strain used in
the experiment (BelongsTo.from-link).

=item strain.tab

Each record in this file corresponds to a B<Strain> record. The strain
is the root object for much of the data, and it is a common requirement
that a load operation may cause a strain to be replaced in its entirety.
The fields are (0) the source ID (source-id), (1) the description
(description), (2) the KBase ID of the parent genome (GenomeParentOf.from-link),
(3,4) the ID of the parent strain, if any (DerivedFromStrain.from-link),
(5) a semi-colon-delimited list of KBase IDs for features that were knocked
out in creating this strain (HasKnockoutIn.to-link), (6) TRUE if this
strain represents aggregated data about multiple strains, or FALSE
if this strain represents a real, physical strain (aggregateData).

=item environment.tab

Each record in this file corresponds to an B<Environment> record. The
environment is a global object, and it is necessary to verify that the
environment does not already exist. The fields are (0) the source ID
(source-id), (1) the temperature of the environment in Kelvin
(temperature), (2) a boolean flag (C<True> or C<False>) that indicates
whether or not the environment is anaerobic (anaerobic), (3) the pH
of the media (pH), (4,5) the ID of the media used (UsedBy.from-link), and
(6) a string containing compound information, delimited by exclamation
points (C<!>) and each part being a 3-tuple delimited by dollar signs
(C<$>) containing the compound ID (IncludesAdditionalCompounds.to-link),
concentration (IncludesAdditionalCompounds.concentration), and units
(IncludesAdditionalCompounds.units).

=item media.tab

Each record in this file corresponds to a B<Media> record. The media is
a global object, and it is necessary to verify that the media does not
already exist. The fields are (0) the source ID (source-id), (1) the
media name (name), (2) the media description (description), (3) a
boolean flag (C<True> or C<False>) that indicates whether or not the
media is fully defined (is-defined), and (4) a string containing compound
information, delimited by exclamation points (C<!>) and each part being a
3-tuple delimited by dollar signs (C<$>) containing the compound
ID (HasPresenceOf.to-link), concentration (HasPresenceOf.concentration),
and units (HasPresenceOf.units). Media loaded by this process are
always considered liquid (solid = FALSE).

=item measurement.tab

Each record in this file corresponds to a B<Measurement> record.
Measurements belong to strains, and when a strain is being replaced,
all its measurements are removed along with it. The fields are
(0) the source ID (source-id), (1,2) the associated experimental
unit's ID (HasMeasurement.from-link), (3,4) the associated phenotype
ID (HasAssociatedMeasurement.from-link), (5,6) the associated
protocol's ID (IsMeasurementMethodOf.from-link), (7) the value
of the measurement (value), (8) the mean if there were multiple
replicates (mean), (9) the median if there were multiple replicates
(median), (10) the standard deviation if there were multiple replicates
(stddev), (11) the number of replicates (N), (12) the p-value if there
were multiple replicates (p-value), (13) the Z-score ifthere were
multiple replicates (Z-score), and (14) the time series string
(timeSeries). Most values default to zero, the exceptions being the
mean and median, which default to the value.

=item phenotype_description.tab

Each record in this file corresponds to a B<PhenotypeDescription>
record. Phenotypes are global objects, and it is necessary to
verify that the phenotype does not already exist. The fields are
(0) the source ID (source-id), (1) the name (name), (2) the
description (description), and (3) the measurement units
(unitOfMeasure).

=back

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus the
following.

=over 4

=item clear

If this option is specified, the phenotype tables will be recreated
before loading.

=back

There are two positional parameters-- the source database name (e.g. C<SEED>,
C<MOL>, ...) and the name of the directory containing the phenotype data
for the genome. The source database name determines how the genome and
feature IDs in the input stream are translated.

=cut

use constant TABLES => [qw(PhenotypeExperiment
                           PublishedExperiment PerformedExperiment
                           Protocol PublishedProtocol Strain ExperimentalUnit
                           HasExperimentalUnit UsedInExperimentalUnit BelongsTo
                           GenomeParentOf DerivedFromStrain
                           HasKnockoutIn UsedBy IncludesAdditionaCompounds
                           HasPresenceOf Measurement HasMeasurement
                           HasAssociatedMeasurement IsMeasurementMethodOf)];
use constant GLOBALS => [qw(Publication Protocol Person PhenotypeDescription
                           Environment Media)];

# Create the command-line option variables.
my ($clear);
# Turn off buffering for progress messages.
$| = 1;

# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("clear" => \$clear);
if (! $cdmi) {
    print "usage: CDMILoadPhenotypes [options] source loadDirectory\n";
    exit;
}
print "Connected to CDMI.\n";
# Get the source and genome directory.
my ($source, $loadDirectory) = @ARGV;
if (! $source) {
    die "No source database specified.\n";
} elsif (! $loadDirectory) {
    die "No load directory specified.\n";
} elsif (! -d $loadDirectory) {
    die "Load directory $loadDirectory not found.\n";
} else {
    # Initialize the load helper.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetSource($source);
    # Are we clearing?
    if($clear) {
        # Yes. Recreate the variations tables.
        for my $table (@{TABLES()}, @{GLOBALS()}) {
            print "Recreating $table.\n";
            $cdmi->CreateTable($table, 1);
        }
    }
    # Set up the loader helpers.
    $loader->SetRelations(@{TABLES()});
    # Load the global objects.
    LoadPublications($loader, $loadDirectory);
    my $personMap = LoadPersons($loader, $loadDirectory);
    my $protocolMap = LoadProtocols($loader, $loadDirectory);
    my $mediaMap = LoadMedia($loader, $loadDirectory);
    my $environmentMap = LoadEnvironments($loader, $loadDirectory, $mediaMap);
    # Display the statistics.
    print "All done.\n" . $loader->stats->Show();
}


=head2 Subroutines

=head3 LoadPublications

    LoadPublications($loader, $loadDirectory);

Load the C<publications.tab> file. This contains publication records,
and is very no-frills: it does not even need to generate an ID map.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item loadDirectory

Directory containing the load files.

=back

=cut

sub LoadPublications {
    # Get the parameters.
    my ($loader, $loadDirectory) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Check for the publications file.
    my $fileName = "$loadDirectory/publication.tab";
    if (! -f $fileName) {
        print "Publication file not found. No publications loaded.\n";
    } else {
        # We found it, so open it for input.
        open(my $ih, "<$fileName") ||
            die "Could not open publications file: $!";
        # Loop through the publications.
        while (! eof $ih) {
            my ($id, $link, $date, $title) = $loader->GetLine($ih);
            $stats->Add(publicationIn => 1);
            # Make sure all the values are filled in.
            $date = 0 if ! defined $date;
            $title = "(unknown)" if ! $title;
            $link = "" if ! defined $link;
            # Insure the publication is in the database.
            $loader->InsureEntity(Publication => $id, link => $link,
                    pubdate => $date, title => $title);
        }
    }
}

=head3 LoadPersons

    my $personMap = LoadPersons($loader, $loadDirectory);

Load the person file. The person file has no links in it, but it
is linked to from other files, so it is necessary to compute KBase
IDs for the records in it.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item loadDirectory

Directory containing the load files.

=item RETURN

Returns a reference to a hash mapping the source IDs read to their
KBase equivalents.

=back

=cut

sub LoadPersons {
    # Get the parameters.
    my ($loader, $loadDirectory) = @_;
    # Read the file into memory.
    my ($retVal, $people) = ReadGlobalFile($loader, $loadDirectory,
            'person.tab', 'person', 'Person');
    # Loop through the person records, putting the new ones
    # in the database.
    for my $person (@$people) {
        # Get the fields of this person.
        my ($sourceID, $firstName, $lastName, $contactEmail, $institution) = @$person;
        # Extract the KBase ID.
        my $kbID = $retVal->{$sourceID};
        # Insure the person is in the database.
        $loader->InsureEntity(Person => $kbID, firstName => $firstName,
                lastName => $lastName, contactEmail => $contactEmail,
                institution => $institution, source_id => $sourceID);
    }
    # Return the map of source IDs to KBase IDs.
    return $retVal;
}

=head3 LoadMedia

    my $mediaMap = LoadMedia($loader, $loadDirectory);

Load the media file. The media file has links to compounds, which
are loaded by the model loaders. All references to compounds are via
KBase IDs.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item loadDirectory

Directory containing the load files.

=item RETURN

Returns a reference to a hash mapping the source IDs read to their
KBase equivalents.

=back

=cut

sub LoadMedia {
    # Get the parameters.
    my ($loader, $loadDirectory) = @_;
    # Read the file into memory.
    my ($retVal, $media) = ReadGlobalFile($loader, $loadDirectory,
            'media.tab', 'media', 'Media');
    # Loop through the media records, putting the new ones
    # in the database.
    for my $media (@$media) {
        # Get the fields of this media.
        my ($sourceID, $name, $description, $isDefined, $compounds) = @$media;
        # Extract the KBase ID.
        my $kbID = $retVal->{$sourceID};
        # Insure the media is in the database.
        my $newFlag = $loader->InsureEntity(Media => $kbID, description => $description,
            mod_date => time(), name => $name, solid => 0, source_id => $sourceID);
        # If it's new, add the compounds.
        if ($newFlag) {
            ProcessCompoundString($loader, $compounds, $kbID,
                'HasPresenceOf');
        }
    }
    # Return the map of source IDs to KBase IDs.
    return $retVal;
}

=head3 LoadEnvironments

    my $environmentMap = LoadEnvironments($loader, $loadDirectory, \%mediaMap);

Load the environments file. The enviroments file has links to media,
some of which are loaded by this program, and compounds, which
are loaded by the model loaders. All references to compounds are via
KBase IDs.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item loadDirectory

Directory containing the load files.

=item mediaMap

Reference to a hash mapping media source IDs to KBase IDs.

=item RETURN

Returns a reference to a hash mapping the source IDs read to their
KBase equivalents.

=back

=cut

sub LoadEnvironments {
    # Get the parameters.
    my ($loader, $loadDirectory, $mediaMap) = @_;
    # Read the file into memory.
    my ($retVal, $environments) = ReadGlobalFile($loader, $loadDirectory,
            'environment.tab', 'environment', 'Environment');
    # Get the statistics object.
    my $stats = $loader->stats;
    # Loop through the environment records, putting the new ones
    # in the database.
    for my $environment (@$environments) {
        # Get the fields of this environment.
        my ($sourceID, $temp, $anaerobic, $pH, $mediaID, $mediaKBID,
            $compounds) = @$environment;
        # Extract the KBase ID.
        my $kbID = $retVal->{$sourceID};
        # Insure the environment is in the database.
        my $newFlag = $loader->InsureEntity(Environment => $kbID,
            temperature => $temp, pH => $pH, source_id => $sourceID);
        # If it's new, connect the media and add the compounds.
        if ($newFlag) {
            # Compute the media ID.
            my $mediaRealID = $loader->DoubleIdCheck($stats, $mediaID,
                    $mediaKBID, $mediaMap);
            # Connect the compounds.
            ProcessCompoundString($loader, $compounds, $kbID,
                'HasPresenceOf');
        }
    }
    # Return the map of source IDs to KBase IDs.
    return $retVal;
}

=head3 ProcessCompoundString

    ProcessCompoundString($loader, $compounds, $kbID, $table);

Connect compound information to a source entity record. The compound
information is encoded as a C<!>-delimited string of C<$>-delimited
3-tuples.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item compounds

Compound string containing the information to process.

=item kbID

KBase ID of the source object to which the compounds will be
linked.

=item table

Name of the relationship the compound information is to be put into.

=back

=cut

sub ProcessCompoundString {
    # Get the parameters.
    my ($loader, $compounds, $kbID, $table) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the compound elements.
    my @compounds = split m/!/, $compounds;
    # Loop through them, connecting them to the new record.
    for my $compound (@compounds) {
        my ($compoundKBID, $concentration, $units) = split m/\$/, $compound;
        $loader->InsertObject($table, from_link => $kbID,
            to_link => $compoundKBID, concentration => $concentration,
            units => $units);
        $stats->Add(compoundLink => 1);
    }
}

=head3 LoadProtocols

    my $protocolMap = LoadProtocols($loader, $loadDirectory);

Load the protocols file. The protocols file has links to publications,
but these do not use KBase IDs, so no prior ID mapping is required.
Several other files link to protocols, so an ID map for protocols is
returned.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item loadDirectory

Directory containing the load files.

=item RETURN

Returns a reference to a hash mapping the source IDs read to their
KBase equivalents.

=back

=cut

sub LoadProtocols {
    # Get the parameters.
    my ($loader, $loadDirectory) = @_;
    # Read the file into memory.
    my ($retVal, $protocols) = ReadGlobalFile($loader, $loadDirectory,
            'protocol.tab', 'protocol', 'Protocol');
    # Loop through the protocol records, putting the new ones
    # in the database.
    for my $protocol (@$protocols) {
        # Get the fields of this protocol.
        my ($sourceID, $name, $description, $publication) = @$protocol;
        # Extract the KBase ID.
        my $kbID = $retVal->{$sourceID};
        # Insure the protocol is in the database.
        my $newFlag = $loader->InsureEntity(Protocol => $kbID,
                description => $description, name => $name,
                source_id => $sourceID);
        # If it wasn't, we also need to link it to the publication.
        if ($newFlag) {
            $loader->InsertObject('PublishedProtocol', from_link => $publication,
                    to_link => $kbID);
            $loader->stats->Add("PublishedProtocol-added" => 1);
        }
    }
    # Return the map of source IDs to KBase IDs.
    return $retVal;
}

=head3 ReadGlobalFile

    my ($idMap, $recordList) = ReadGlobalFile($loader, $loadDirectory, $fileName, $type, $table);

Read in a file of global records. The entire file is cached in memory, and
KBase IDs are computed for the various source IDs.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item loadDirectory

Directory containing the load files.

=item fileName

Base name of the file to load.

=item type

Type of record being loaded. This is used in the statistics and in the
KBase ID prefix.

=item table

Main table being loaded. This is used as the ID type when requesting the
KBase ID.

=item RETURN

Returns a two-element list. The first element is a reference to a hash
mapping the incoming source IDs to KBase IDs. The second element is a
reference to a list of tuples containing the records from the load file.

=back

=cut

sub ReadGlobalFile {
    # Get the parameters.
    my ($loader, $loadDirectory, $fileName, $type, $table) = @_;
    # Declare the return variables.
    my $idMap = {};
    my @recordList;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Check for the incoming file.
    my $fullFileName = "$loadDirectory/$fileName";
    if (! -f $fullFileName) {
        print "$table file not found. No $type records loaded.\n";
    } else {
        # We found it, so open it for input.
        open(my $ih, "<$fullFileName") ||
            die "Could not open $type file: $!";
        # Loop through the records, caching the information.
        while (! eof $ih) {
            push @recordList, [ $loader->GetLine($ih) ];
            $stats->Add("$type-in" => 1);
        }
        # Compute KBase IDs for all the people,
        $idMap = $loader->GetKBaseIDs("kb|$type", $table,
                [ map { $_->[0] } @recordList ]);
    }
    # Return the ID mapping and the records read.
    return ($idMap, \@recordList);
}