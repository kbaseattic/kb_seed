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
use BasicLocation;

=head1 CDMI Phenotype Variations Loader

    CDMILoadVariations [options] source genomeDirectory

Load the phenotype variation data for a genome into a KBase Central Data
Model Instance. The variation data is represented by nine or more files in a
single directory. All of the IDs in the files are from the source
database, and need to be converted to KBase IDs. The low-level name
of the directory must be the same as the genome's ID in the source
database. In some cases there are two fields specified for an ID. In
this case, the first is an ID from the source database and the second
is a KBase ID. The KBase ID will be used if it is present, and the
source ID will be converted otherwise. If neither ID is present, then
it usually indicates that a particular link does not apply.

All of the source IDs will be converted to KBase IDs in the database with a
prefix based on the genome ID. This allows us to find and remove them
easily when preparing for a reload.

The files are as follows.

=over 4

=item experiment.tab

This file is used to fill the B<StudyExperiment> table. It contains (0)
the experiment ID (source-id), (1) the design of the experiment (design),
(2) the authors (originator), and (3) the ID of the assay technology
used in the experiment. The authors are sometimes expressed as
a paper citation.

=item obs_unit.tab

This file is used to fill the B<ObservationalUnit> table and its
associated relationships. It contains (0) the observational unit ID
(source-name), (1) the optional secondary name (source-name2),
(2,3) the ID of the experiment to which the unit belongs
(IncludesPart.from_link), (4,5) the ID of the locality where the
observation took place (HasUnits.from_link), (6,7) the ID of the
taxonomic grouping for the genetic source material, (8) the
KBase ID of the relevant reference genome (IsReferencedBy.from_link),
and (9) the ID of the physical organism assayed to produce the
observations.

=item locality.tab

This file is used to fill the B<Locality> table. It contains (0) the
locality ID (source-name), (1) the elevation in meters (elevation),
(2) the city name (city), (3) the country name (country), (4) the
ISO 3166-1 extended country code (origcty), (5) the latitude (latitude),
(6) the longitude (longitude), (7) the state or province, and (8) the
gazeteer ontology term ID (lo-accession).

=item trait.tab

This file is used to fill the B<Trait> table. It contains (0) the
trait ID (source-id), (1) the unit of measure (unit-of-measure),
(2) the trait ontology term ID (TO-ID), and (3) a description of the
protocol for measuring the trait (protocol).

=item measures.tab

This file is used to fill the B<HasTrait> table. It contains (0) the
source identifier of the measurement (measure-id), (1,2) the
ID of the trait being measured (to-link), (3,4) the ID of the
observational unit whose trait is being measured (from-link), (5) the
statistical type (statistic-type), and (6) the measurement value (value).

=item assay.tab

This file is used to fill the B<Assay> table. It contains (0) the
assay ID (source-id), (1) the assay type ID (assay-type-id), and (2) the
assay type description (assay-type).

=item impact.tab

This file is used to fill the B<Impacts> table. It contains (0) the
study ID (source-name), (1,2) the trait ID (from-link), (3) the
ID of the contig impacting by the trait (to-link), (4) the position
in the contig impacting the trait (position), (5) the rank of this
impact among all positions impacting this trait (rank), and (6) the
P-value of the correlation (pvalue).

=item allele_frequency.tab

This file is used to fill the B<AlleleFrequency> and B<IsSummarizedBy>
tables. It contains (0) the allele frequency ID (AlleleFrequency.source-id),
(1,2) the experiment ID (ignored), (3) the ID of the relevant contig
(IsSummarizedBy.from-link), (4) the position of the allele on the contig
(AlleleFrequency.position, IsSummarizedBy.position), (5) the
letter representing the minor allele (AlleleFrequency.minor-allele), (6) the
frequency of the minor allele as a fraction of 1 (AlleleFrequency.minor-AF),
(7) the letter representing the major allele (AlleleFrequency.major-allele),
(8) the frequency of the major allele as a fraction of 1
(AlleleFrequency.major-AF), and (9) the observation unit count
(AlleleFrequency.obs-unit-count).

=back

In addition to the above files, there is one for each observational unit
with the name I<unitID>B<.vcf>, where I<unitID> is an observational unit
identifier. This is a tab-delimited file like the others, but has the
additional proviso that any line beginning with a pound sign (C<#>) is
treated as a comment and ignored.

A non-comment line in one of these files consists of (0) a contig ID,
(1) the position in the contig of the modification, (2) the ID of the
modification, (3) a before-string, (4) an after-string, (5) a quality
score, and (6) comments. Each such line corresponds toa B<HasVariationIn>
record. the observational unit ID from the file name serves as the
to-link, and the contig ID as the from-link. The quality score is stored
in the quality field. The after string contains either a single (very
short) DNA sequence or two sequences separated by a comma. The first
sequence is for the primary chromosome and the sequence for the secondary
chromosome. If only a single sequence is present, it is used for both.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script> plus the
following.

=over 4

=item recursive

If this option is specified, then instead of loading a single genome from
the specified directory, a genome will be loaded from each subdirectory
of the specified directory. This allows multiple genomes from a single
source to be loaded in one pass.

=item clear

If this option is specified, the variation tables will be recreated
before loading.

=item nodelete

Do not delete pre-existing variation data for this genome. This is useful
when variation data for a genome is loaded in multiple passes.

=item keepTemp

If TRUE, the temporary files used by the loader will be kept. This option
is only valid on a single-genome load (when B<recursive> is not specified).

=back

There are two positional parameters-- the source database name (e.g. C<SEED>,
C<MOL>, ...) and the name of the directory containing the variation data
for the genome. The source database name determines how the genome and
contig IDs in the input stream are translated.

=cut

use constant TABLES => [qw(ObservationalUnit AlleleFrequency Assay
                          Trait Locality StudyExperiment IsSummarizedBy
                          Impacts HasVariationIn IsRepresentedBy
                          IsReferencedBy HasTrait HasUnits IncludesPart
                          IsAssayOf)];

# Create the command-line option variables.
my ($recursive, $clear, $nodelete, $keepTemp);
# Turn off buffering for progress messages.
$| = 1;

# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("recursive" => \$recursive,
        "clear" => \$clear, "nodelete" => \$nodelete, "keepTemp" => \$keepTemp);
if (! $cdmi) {
    print "usage: CDMILoadVariations [options] source genomeDirectory\n";
    exit;
}
print "Connected to CDMI.\n";
# Get the source and genome directory.
my ($source, $genomeDirectory) = @ARGV;
if (! $source) {
    die "No source database specified.\n";
} elsif (! $genomeDirectory) {
    die "No genome directory specified.\n";
} elsif (! -d $genomeDirectory) {
    die "Genome directory $genomeDirectory not found.\n";
} else {
    # Initialize the load helper.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetSource($source);
    # Are we clearing?
    if($clear) {
        # Yes. Recreate the variations tables.
        for my $table (@{TABLES()}) {
            print "Recreating $table.\n";
            $cdmi->CreateTable($table, 1);
        }
    }
    # Are we in recursive mode?
    if (! $recursive) {
        # No. Load the one genome.
        LoadGenomeVariations($loader, $genomeDirectory, $nodelete, $keepTemp);
    } else {
        # Yes. Get the subdirectories.
        opendir(TMP, $genomeDirectory) || die "Could not open $genomeDirectory.\n";
        my @subDirs = sort grep { substr($_,0,1) ne '.' } readdir(TMP);
        print scalar(@subDirs) . " entries found in $genomeDirectory.\n";
        # Loop through the subdirectories.
        for my $subDir (@subDirs) {
            my $fullPath = "$genomeDirectory/$subDir";
            if (-d $fullPath) {
                LoadGenomeVariations($loader, $fullPath, $nodelete);
            }
        }
    }
    # Display the statistics.
    print "All done.\n" . $loader->stats->Show();
}


=head2 Subroutines

=head3 LoadGenomeVariations

    LoadGenomeVariations($loader, $genomeDirectory, $nodelete, $keepTemp);

Load a single genome's variations from the specified genome directory.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeDirectory

Directory containing the genome load files.

=item nodelete

Normally, previous variation data for a genome is deleted before loading
new data. If this parameter is TRUE, the delete will be suppressed.

=item keepTemp

Normally, the temporary load files are deleted after being used. If this
parameter is TRUE, they will be kept on disk.

=back

=cut

sub LoadGenomeVariations {
    # Get the parameters.
    my ($loader, $genomeDirectory, $nodelete, $keepTemp) = @_;
    # Indicate our progress.
    print "Processing $genomeDirectory.\n";
    # Compute the genome ID from the directory name.
    my @parts = split /\//, $genomeDirectory;
    my $genomeOriginalID = pop @parts;
    print "Computed genome ID is $genomeOriginalID.\n";
    $loader->SetGenome($genomeOriginalID);
    # Get the KBase ID for the genome.
    my $genomeKBID = $loader->LookupGenome($genomeOriginalID);
    # Only proceed if we found it.
    if (! $genomeKBID) {
        print "Genome not found in database.\n";
    } else {
        # Delete the old variation data for this genome.
        if (! $nodelete) {
            DeleteGenomeVariations($loader, $genomeKBID);
        }
        # Initialize the loaders.
        $loader->SetRelations(@{TABLES()});
        # Load the assays.
        my $assayMap = LoadAssays($loader, $genomeKBID, $genomeDirectory);
        # Load the experiments.
        my $experimentMap = LoadExperiments($loader, $genomeKBID,
                $genomeDirectory, $assayMap);
        # Load the localities.
        my $localityMap = LoadLocalities($loader, $genomeKBID,
                $genomeDirectory);
        # Load the observation units.
        my $obsMap = LoadObsUnits($loader, $genomeKBID, $genomeDirectory,
                $experimentMap, $localityMap);
        # Load the traits.
        my $traitMap = LoadTraits($loader, $genomeKBID, $genomeDirectory);
        # Load the trait measurements.
        LoadMeasures($loader, $genomeDirectory, $traitMap,
                $obsMap);
        # Create a map of internal contig IDs to KBase contig IDs.
        my %contigMap = map { $_->[0] => $_->[1] }
                $loader->cdmi->GetAll('IsComposedOf Contig',
                'IsComposedOf(from-link) = ?', [$genomeKBID],
                'Contig(source-id) Contig(id)');
        # Load the trait impacts.
        LoadImpacts($loader, $genomeDirectory, $traitMap,
                \%contigMap);
        # Load the allele frequencies.
        LoadAlleles($loader, $genomeKBID, $genomeDirectory, \%contigMap);
        # Load the variation files.
        LoadVCFs($loader, $obsMap, $genomeDirectory, \%contigMap);
        # Fill the database tables from the load information.
        $loader->LoadRelations($keepTemp);
    }
}

=head3 LoadVCFs

    LoadVCFs($loader, \%obsMap, $genomeDirectory, $contigMap);

Load the individual variations from the VCF files. There will be one
such file for each observational unit, and the contents are used to
populate the B<HasVariationIn> relationship.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item obsMap

Reference to a hash mapping source observation unit IDs to KBase IDs.

=item genomeDirectory

Directory containing the genome load files.

=item contigMap

Reference to a hash mapping source contig IDs to KBase IDs.

=back

=cut

sub LoadVCFs {
    # Get the parameters.
    my ($loader, $obsMap, $genomeDirectory, $contigMap) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Missing contig IDs will be saved in here.
    my %missingContigs;
    # Loop through the observational units. There should be a VCF file
    # for each one.
    for my $obsUnit (sort keys %$obsMap) {
        # Insure the VCF file exists.
        my $vcfFileName = "$genomeDirectory/$obsUnit.vcf";
        if (! -f $vcfFileName) {
            print "File $vcfFileName not found.\n";
            $stats->Add(missingVCF => 1);
        } else {
            print "Reading $vcfFileName.\n";
            # It does, so open it.
            my $ih = OpenFile($vcfFileName);
            # Compute the observation unit's KBase ID.
            my $obsUnitKBID = $obsMap->{$obsUnit};
            # Loop through the records in the file.
            while (! eof $ih) {
                my $line = <$ih>;
                $stats->Add(vcfRecords => 1);
                # Skip the line if it's a comment.
                if (substr($line, 0, 1) eq '#') {
                    $stats->Add(vcfComment => 1);
                } else {
                    # Here we have a real data line. Parse out the fields.
                    chomp $line;
                    my ($contigID, $position, undef, $before, $after,
                        $quality) = split /\t/, $line;
                   # Split the after-string into the primary and secondary
                   # chromosome versions. These may be the same.
                   my ($primary, $secondary);
                   if (! $after) {
                       ($primary, $secondary) = ('', '');
                   } else {
                       ($primary, $secondary) = split m/,/, $after;
                       $secondary = $primary if (! defined $secondary);
                   }
                   # Compute the before-string length.
                   my $len = length $before;
                   # Compute the real contig ID.
                   my $contigKBID = CheckContig($stats, $contigID, $contigMap,
                            \%missingContigs);
                   # Only proceed if the contig was found.
                   if ($contigKBID) {
                       # Submit this variation to the loader.
                       $loader->InsertObject('HasVariationIn',
                            from_link => $contigKBID, data => $primary,
                            data2 => $secondary, len => $len, position => $position,
                            quality => $quality, to_link => $obsUnitKBID);
                       $stats->Add(hasVariationIn_loaded => 1);
                   }
                }
            }
        }
    }
}


=head3 LoadAlleles

    LoadAlleles($loader, $genomeKBID, $genomeDirectory, \%contigMap);

Read and process the allele frequency. This method will read the
allele frequency statistics and submit the appropriate
B<AlleleFrequency> and B<IsSummarizedBy> records to the loader.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeKBID

KBase ID of the reference genome.

=item genomeDirectory

Directory containing the genome load files.

=item contigMap

Reference to a hash mapping source contig IDs to KBase IDs.

=back

=cut

sub LoadAlleles {
    # Get the parameters.
    my ($loader, $genomeKBID, $genomeDirectory, $contigMap) = @_;
    print "Processing allele frequencies.\n";
    # Get the statistics object.
    my $stats = $loader->stats;
    # Open the allele frequency file.
    my $ih = OpenFile($genomeDirectory, 'allele_frequency.tab');
    # We'll cache bad contig IDs in here.
    my %missingContigs;
    # This will count the allele records for status message purposes.
    my $count = 0;
    # We need to process the allele frequencies in batches. Each
    # batch is stored in here.
    my @records;
    # Loop through the file.
    while (! eof $ih) {
        push @records, [$loader->GetLine($ih)];
        $count++;
        $stats->Add('allele_frequency.tab-record' => 1);
        if (scalar(@records) >= 5000) {
            # Batch is full, so process it.
            ProcessAlleleBatch($loader, $genomeKBID, \@records, $contigMap,
                    \%missingContigs);
            print "$count allele records processed.\n";
            # Start the next batch.
            @records = ();
        }
    }
    # If there is a residual batch, process it.
    if (scalar(@records) > 0) {
        ProcessAlleleBatch($loader, $genomeKBID, \@records, $contigMap,
                \%missingContigs);
        print "$count allele records processed.\n";
    }
}

=head3 ProcessAlleleBatch

    ProcessAlleleBatch($loader, $genomeKBID, \@records, \%contigMap,
            \%missingContigs);

Process a list of allele frequency records. Allele frequencies are processed
in batches of roughly 1000 records to minimize the number of calls to the
ID services.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeKBID

KBase ID of the reference genome.

=item records

Reference to a list of records from the allele frequency file. Each
record contains (0) the frequency ID, (1,2) the assay ID (ignored),
(3) the target contig ID, (4) the position in the contig of the
allele, (5) the minor allele frequency, (6) the minor allele letter,
(7) the major allele frequency, and (8) the major allele letter.

=item contigMap

Reference to a hash mapping source contig IDs to KBase IDs for
the current genome.

=item missingContigs

Reference to a hash whose keys are contig IDs that were not found in
the contig map.

=back

=cut

sub ProcessAlleleBatch {
    # Get the parameters.
    my ($loader, $genomeKBID, $records, $contigMap, $missingContigs) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the KBase IDs for the frequencies. The frequency IDs are in
    # the first column of the input.
    my $freqMap = $loader->GetKBaseIDs("$genomeKBID.af", "AlleleFrequency",
        [ map { $_->[0] } @$records ]);
    # Now loop through the records. For each one, we create an
    # AlleleFrequency entity instance and a Summarizes relationship
    # instance.
    for my $record (@$records) {
        # Get the fields of the record.
        my ($sourceID, undef, undef, $contigID, $position, $minorF, $minor,
                $majorF, $major, $obsUnitCount) = @$record;
        $stats->Add(alleleRecord => 1);
        # Insure the line is valid.
        if (! $major) {
            print "Missing allele data in line $sourceID.\n";
            $stats->Add(badAlleleRecord => 1);
        } else {
            # Compute the contig ID.
            my $contigKBID = CheckContig($stats, $contigID, $contigMap,
                    $missingContigs);
            # Only proceed if the contig was found.
            if (! $contigKBID) {
                $stats->Add(allele_record_skipped => 1);
            } else {
                # Fix the observation unit count. It's not always present in the
                # current files.
                if (! defined $obsUnitCount) {
                    $obsUnitCount = 0;
                    $stats->Add(missingObsUnitCount => 1);
                }
                # Process the allele.
                $loader->InsertObject('AlleleFrequency', id => $freqMap->{$sourceID},
                        major_AF => $majorF, major_allele => $major,
                        minor_AF => $minorF, minor_allele => $minor,
                        position => $position, source_id => $sourceID,
                        obs_unit_count => $obsUnitCount);
                $stats->Add(alleleFrequency_loaded => 1);
                $loader->InsertObject('IsSummarizedBy', from_link => $contigKBID,
                        position => $position, to_link => $freqMap->{$sourceID});
                $stats->Add(isSummarizedBy_loaded => 1);
            }
        }
    }
    $stats->Add(alleleBatch => 1);
}

=head3 CheckContig

    my $contigKBID = CheckContig($stats, $contigID, \%contigMap,
                                 \%missingContigs);

Compute the KBase ID for the specified contig. If the contig ID is
not found, it will be processed as an error and tracked in the missing-
contigs hash.

=over 4

=item stats

L<Stats> object used for tracking statistics of the load.

=item contigID

Source ID of the target contig.

=item contigMap

Reference to a hash mapping source contig IDs to KBase IDs for
the current genome.

=item missingContigs

Reference to a hash whose keys are contig IDs that were not found in
the contig map.

=item RETURN

Returns the KBase ID of the target contig, or C<undef> if the contig
was not found in the contig map.

=back

=cut

sub CheckContig {
    # Get the parameters.
    my ($stats, $contigID, $contigMap, $missingContigs) = @_;
    # Look for the contig in the contig map.
    my $retVal = $contigMap->{$contigID};
    # Was it found?
    if (! $retVal) {
        # No. Process the error.
        $stats->Add(missingContigID => 1);
        # If this is the first time we've failed to find this contig,
        # output an error message.
        if (! $missingContigs->{$contigID}) {
            print "$contigID not found.\n";
            $missingContigs->{$contigID} = 1;
            $stats->Add(contigsNotFound => 1);
        }
    }
    # Return the contig ID found.
    return $retVal;
}

=head3 LoadImpacts

    LoadImpacts($loader, $genomeKBID, $genomeDirectory, \%traitMap,
                \%contigMap);

Read and process the impacts file. This method will read the estimates
of the impact different locations on the contigs have on the
various traits and submit the appropriate B<Impacts> records to
the loader.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeDirectory

Directory containing the genome load files.

=item traitMap

Reference to a hash mapping source trait IDs to KBase IDs.

=item contigMap

Reference to a hash mapping source contig IDs to KBase IDs.

=back

=cut

sub LoadImpacts {
    # Get the parameters.
    my ($loader, $genomeDirectory, $traitMap, $contigMap) = @_;
    print "Processing impacts.\n";
    # Get the statistics object.
    my $stats = $loader->stats;
    # Open the impact file.
    my $ih = OpenFile($genomeDirectory, 'impact.tab');
    # We'll cache bad contig IDs in here.
    my %missingContigs;
    # Loop through the file.
    while (! eof $ih) {
        my ($studyID, $traitID, $traitKBID, $contigID, $position, $rank,
                $pValue) = $loader->GetLine($ih);
        $stats->Add("impact.tab-record" => 1);
        # Compute the actual ID to use for the trait.
        my $traitRealID = $loader->DoubleIdCheck($stats, $traitID, $traitKBID,
                $traitMap);
        # Insure we have a p-value.
        $pValue = 0 if (! defined $pValue);
        # Verify the contig ID.
        my $contigKBID = $contigMap->{$contigID};
        if (! $contigKBID) {
            # Here it's invalid, so we have an error.
            $stats->Add(invalidImpactContigID => 1);
            if (! $missingContigs{$contigID}) {
                # Here it's a new one, so issue a message.
                print "Unrecognized contig ID in impact file: $contigID.\n";
                $missingContigs{$contigID} = 1;
            }
        } else {
            # Here we have a valid contig ID, so we can submit the record.
            $loader->InsertObject('Impacts', from_link => $traitRealID,
                    to_link => $contigKBID, position => $position,
                    rank => $rank, source_name => $studyID,
                    pvalue => $pValue);
            $stats->Add(impacts_loaded => 1);
        }
    }
}

=head3 LoadMeasures

    LoadMeasures($loader, $genomeDirectory, \%traitMap, \%obsMap);

Read and process the measures file. This method will read the measurements
of the various traits for the various observational units and submit the
appropriate B<HasTrait> records to the loader.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeDirectory

Directory containing the genome load files.

=item traitMap

Reference to a hash mapping source trait IDs to KBase IDs.

=item obsMap

Reference to a hash mapping source observational unit IDs to KBase IDs.

=back

=cut

sub LoadMeasures {
    # Get the parameters.
    my ($loader, $genomeDirectory, $traitMap, $obsMap) = @_;
    print "Processing measures.\n";
    # Get the statistics object.
    my $stats = $loader->stats;
    # Open the measures file.
    my $ih = OpenFile($genomeDirectory, 'measures.tab');
    # Loop through the file.
    while (! eof $ih) {
        my ($measureID, $traitID, $traitKBID, $obsuID, $obsuKBID, $type, $value) =
                $loader->GetLine($ih);
        $stats->Add("measures.tab-record" => 1);
        # Compute the actual IDs to use for the trait and observational unit.
        my $obsuRealID = $loader->DoubleIdCheck($stats, $obsuID, $obsuKBID,
                $obsMap);
        my $traitRealID = $loader->DoubleIdCheck($stats, $traitID, $traitKBID,
                $traitMap);
        # Insure they are valid.
        if (! defined $obsuRealID) {
            print STDERR "Could not find observation unit $obsuID in measure file.\n";
            $stats->Add(missingMeasureObsu => 1);
        } elsif (! defined $traitRealID) {
            print STDERR "Could not find trait $traitID in measure file.\n";
            $stats->Add(missingMeasureTrait => 1);
        } else {
            # Submit the trait record to the loader.
            $loader->InsertObject('HasTrait', from_link => $obsuRealID,
                    to_link => $traitRealID, measure_id => $measureID,
                    statistic_type => $type, value => $value);
            $stats->Add(hasTrait_loaded => 1);
        }
    }
}

=head3 LoadTraits

    my $traitHash = LoadTraits($loader, $genomeKBID, $genomeDirectory);

Read and process the traits file. This method will read all the traits,
compute the KBase IDs, and submit the appropriate B<Trait> records to
the loader. The map of source trait IDs to KBase trait IDs will be returned.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeKBID

KBase ID of the reference genome.

=item genomeDirectory

Directory containing the genome load files.

=item RETURN

Returns a reference to a hash that maps source trait IDs to
KBase IDs.

=back

=cut

sub LoadTraits {
    # Get the parameters.
    my ($loader, $genomeKBID, $genomeDirectory) = @_;
    print "Processing traits.\n";
    # Get the statistics object.
    my $stats = $loader->stats;
    # Read the traits file.
    my $records = ReadFile($loader, $genomeDirectory, 'trait.tab');
    # Ask for the trait KBase IDs. The source IDs are in the
    # first column of the data we read in. The mapping is also our
    # return value.
    my $retVal = $loader->GetKBaseIDs("$genomeKBID.trait", "Trait",
        [ map { $_->[0] } @$records ]);
    # Fill the tables from the data we read in.
    for my $record (@$records) {
        my ($traitName, $units, $toID, $protocol) = @$record;
        # Insure we have units, a TO ID, and protocol.
        $units = "" if (! defined $units);
        $toID = "" if (! defined $toID);
        $protocol = "" if (! defined $protocol);
        # Create the trait record.
        $loader->InsertObject('Trait', id => $retVal->{$traitName},
                trait_name => $traitName, protocol => $protocol,
                TO_ID => $toID, unit_of_measure => $units);
        $stats->Add(trait_loaded => 1);
    }
    # Return the ID mapping.
    return $retVal;
}

=head3 LoadObsUnits

    my $obsHash = LoadObsUnits($loader, $genomeKBID,
            $genomeDirectory, $expMap, $locMap);

Read and process the observational units file. This method will read all
the observational units, compute the KBase IDs, submit the appropriate
B<ObservationalUnit>, B<HasUnits>, B<IsRepresentedBy>, and B<IncludesPart>
records to the loader, and return the map of source observational unit IDs
to KBase observational unit IDs.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeKBID

KBase ID of the reference genome.

=item genomeDirectory

Directory containing the genome load files.

=item expMap

Reference to a hash mapping source experiment IDs to KBase IDs.

=item locMap

Reference to a hash mapping source locality IDs to KBase IDs.

=item RETURN

Returns a reference to a hash that maps source observational unit IDs to
KBase IDs.

=back

=cut

sub LoadObsUnits {
    # Get the parameters.
    my ($loader, $genomeKBID, $genomeDirectory, $expMap, $locMap) = @_;
    print "Processing observation units.\n";
    # Get the statistics object.
    my $stats = $loader->stats;
    # Read the observational units file.
    my $records = ReadFile($loader, $genomeDirectory, 'obs_unit.tab');
    # Ask for the observational unit KBase IDs. The source IDs are in the
    # first column of the data we read in. The mapping is also our
    # return value.
    my $retVal = $loader->GetKBaseIDs("$genomeKBID.obsu", "ObservationalUnit",
        [ map { $_->[0] } @$records ]);
    # Fill the tables from the data we read in.
    for my $record (@$records) {
        my ($obsuID, $name2, $expID, $expKBID, $locID, $locKBID, $taxonID,
                undef, undef, $plantID) = @$record;
        # Compute the KBase ID for this observational unit.
        my $obsuKBID = $retVal->{$obsuID};
        # Insure the optional fields are present.
        $plantID = "" if (! defined $plantID);
        $name2 = "" if (! defined $name2);
        # Submit the observational unit to the loader.
        $loader->InsertObject('ObservationalUnit', id => $obsuKBID,
                source_name => $obsuID, source_name2 => $name2,
                plant_id => $plantID);
        $stats->Add(observationalUnit_loaded => 1);
        $loader->InsertObject('IsReferencedBy', from_link => $genomeKBID,
                to_link => $obsuKBID);
        $stats->Add(isReferencedBy_loaded => 1);
        # Find the associated experiment.
        my $expRealID = $loader->DoubleIdCheck($stats, $expID, $expKBID, $expMap);
        die "Experiment not found for $obsuID.\n" if (! $expRealID);
        $loader->InsertObject('IncludesPart', from_link => $expRealID,
                to_link => $obsuKBID);
        $stats->Add(includesPart_loaded => 1);
        # Find the associated locality. The locality is optional.
        my $locRealID = $loader->DoubleIdCheck($stats, $locID, $locKBID, $locMap);
        if (! $locRealID) {
            $stats->Add(missingLocation => 1);
        } else {
            $loader->InsertObject('HasUnits', from_link => $locRealID,
                    to_link => $obsuKBID);
            $stats->Add(hasUnits_loaded => 1);
        }
        # Connect the taxon ID.
        die "Taxon ID not found for $obsuID.\n" if (! $taxonID);
        $loader->InsertObject('IsRepresentedBy', from_link => $taxonID,
                to_link => $obsuKBID);
        $stats->Add(isRepresentedBy_loaded => 1);
    }
    # Return the map of experiment IDs.
    return $retVal;
}

=head3 LoadLocalities

    my $localityMap = LoadLocalities($loader, $genomeKBID,
            $genomeDirectory);

Read and process the locality file. This method will read all the localities,
compute the KBase IDs, submit the appropriate records to the loader,
and return the map of source locality IDs to KBase locality IDs.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeKBID

KBase ID of the reference genome.

=item genomeDirectory

Directory containing the genome load files.

=back

=cut

sub LoadLocalities {
    # Get the parameters.
    my ($loader, $genomeKBID, $genomeDirectory) = @_;
    print "Processing localities.\n";
    # Get the statistics object.
    my $stats = $loader->stats;
    # Read in the localities.
    my $records = ReadFile($loader, $genomeDirectory, 'locality.tab');
    # Get the KBase IDs for the localities. The source IDs are in the first
    # column.
    my $retVal = $loader->GetKBaseIDs("$genomeKBID.locality", "Locality",
            [map { $_->[0] } @$records]);
    # Now loop through the records, submitting them to the loader.
    for my $record (@$records) {
        my ($sourceID, $elevation, $city, $country, $origcty,
            $latitude, $longitude, $state, $loAccession) = @$record;
        # Insure we have a values for everything.
        $elevation = 0 if ! defined $elevation;
        $city = "" if ! defined $city;
        $country = "" if ! defined $country;
        $origcty = "" if ! defined $origcty;
        $latitude = 0 if ! defined $latitude;
        $longitude = 0 if ! defined $longitude;
        $state = "" if ! defined $state;
        $loAccession = "" if ! defined $loAccession;
        # Submit the record to the loader.
        $loader->InsertObject('Locality', id => $retVal->{$sourceID},
            source_name => $sourceID, city => $city, country => $country,
            elevation => $elevation, latitude => $latitude,
            longitude => $longitude, state => $state,
            lo_accession => $loAccession, origcty => $origcty);
        $stats->Add(locality_loaded => 1);
    }
    # Return the locality ID map.
    return $retVal;
}



=head3 LoadAssays

    my $assayMap = LoadAssays($loader, $genomeKBID,
            $genomeDirectory);

Read and process the assay file. This method will read all the assays,
compute the KBase IDs, submit the appropriate records to the loader,
and return the map of source assay IDs to KBase assay IDs.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeKBID

KBase ID of the reference genome.

=item genomeDirectory

Directory containing the genome load files.

=back

=cut

sub LoadAssays {
    # Get the parameters.
    my ($loader, $genomeKBID, $genomeDirectory) = @_;
    print "Processing assays.\n";
    # Get the statistics object.
    my $stats = $loader->stats;
    # Read in the assays.
    my $records = ReadFile($loader, $genomeDirectory, 'assay.tab');
    # Get the KBase IDs for the assays. The source IDs are in the first
    # column.
    my $retVal = $loader->GetKBaseIDs("$genomeKBID.assay", "Assay",
            [map { $_->[0] } @$records]);
    # Now loop through the records, submitting them to the loader.
    for my $record (@$records) {
        my ($sourceID, $typeID, $type) = @$record;
        # Insure we have a valid type ID.
        if (! defined $typeID) {
            $typeID = "";
            $stats->Add(missing_assay_type_id => 1);
        }
        # Submit the record to the loader.
        $loader->InsertObject('Assay', id => $retVal->{$sourceID},
            source_id => $sourceID, assay_type => $type,
            assay_type_id => $typeID);
        $stats->Add(assay_loaded => 1);
    }
    # Return the assay ID map.
    return $retVal;
}

=head3 LoadExperiments

    my $expHash = LoadExperiments($loader, $genomeKBID,
            $genomeDirectory, $assayMap);

Read and process the experiments file. This method will read all
the experiments, compute the KBase IDs, submit the appropriate
B<StudyExperiment> and B<IsAssayOf> records to the loader, and
return the map of source experiment IDs to KBase experiment IDs.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeKBID

KBase ID of the reference genome.

=item genomeDirectory

Directory containing the genome load files.

=item assayMap

Reference to a hash mapping source assay IDs to KBase assay IDs.

=item RETURN

Returns a reference to a hash that maps source experiment IDs to
KBase experiment IDs.

=back

=cut

sub LoadExperiments {
    # Get the parameters.
    my ($loader, $genomeKBID, $genomeDirectory, $assayMap) = @_;
    print "Processing experiments.\n";
    # Get the statistics object.
    my $stats = $loader->stats;
    # Read the experiments file.
    my $records = ReadFile($loader, $genomeDirectory, 'experiment.tab');
    # Ask for the experiment KBase IDs. The source IDs are in the
    # first column of the data we read in. The mapping is also our
    # return value.
    my $retVal = $loader->GetKBaseIDs("$genomeKBID.exp", "StudyExperiment",
        [ map { $_->[0] } @$records ]);
    # Fill the StudyExperiment and IsAssayOf tables from the data we read in.
    for my $record (@$records) {
        my ($sourceID, $designer, $originator, $assayID) = @$record;
        # Compute the KBase ID for the experiment.
        my $expKBID = $retVal->{$sourceID};
        # Submit the StudyExperiment record to the loader.
        $loader->InsertObject('StudyExperiment', id => $expKBID,
                source_name => $sourceID, design => $designer,
                originator => $originator);
        $stats->Add(study_experiment_loaded => 1);
        # Submit the IsAssayOf record to the loader.
        my $assayKBID = $assayMap->{$assayID};
        $loader->InsertObject('IsAssayOf', from_link => $assayKBID,
                to_link => $expKBID);
        $stats->Add(is_assay_of_loaded => 1);
    }
    # Return the map of experiment IDs.
    return $retVal;
}

=head3 ReadFile

    my $records = ReadFile($loader, $genomeDirectory, $fileName);

Read the specified tab-delimited load file into memory. The file is
opened with L</OpenFile> and then all of the records are slurped into
a list that is returned to the caller.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeDirectory

Directory containing the file.

=item fileName

Name of the particular file to open.

=item RETURN

Returns a reference to a list of lists, with each sub-list containing the
fields in a single record from the file.

=back

=cut

sub ReadFile {
    # Get the parameters.
    my ($loader, $genomeDirectory, $fileName) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Open the file for input.
    my $ih = OpenFile($genomeDirectory, $fileName);
    $stats->Add(slurp_file_open => 1);
    # Read in the records.
    my @retVal;
    while (! eof $ih) {
        push @retVal, [ $loader->GetLine($ih) ];
        $stats->Add("$fileName-record" => 1);
    }
    # Return the record list.
    return \@retVal;
}

=head3 OpenFile

    my $ih = OpenFile($genomeDirectory, $fileName);

Open the specified file for processing. This method performs error handling
and displays a message about the file.

=over 4

=item genomeDirectory

Directory containing the file.

=item fileName (optional)

Name of the particular file to open. If this parameter is omitted,
the genomeDirectory name is used by itself without modification.

=item RETURN

Returns an open input handle for the file.

=back

=cut

sub OpenFile {
    # Get the parameters.
    my ($genomeDirectory, $fileName) = @_;
    # Attempt to open the file.
    my $realFileName = (defined $fileName ? "$genomeDirectory/$fileName"
                                          : $genomeDirectory);
    my $retVal;
    open($retVal, "<$realFileName") ||
        die "Could not open $realFileName: $!\n";
    # Return the open handle.
    return $retVal;
}

=head3 DeleteGenomeVariations

    DeleteGenomeVariations($loader, $genomeKBID);

Delete all variation data currently in the database for the specified
genome. This is normally required when reloading the complete variations
for a genome.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeKBID

The KBase ID for the genome whose variation data is to be deleted.

=back

=cut

sub DeleteGenomeVariations {
    # Get the parameters.
    my ($loader, $genomeID) = @_;
    # Get the CDMI database.
    my $cdmi = $loader->cdmi;
    # Get the statistics object.
    my $stats = $loader->stats;
    print "Deleting old data for $genomeID.\n";
    # Loop through each of the major entity types.
    for my $entity (@{TABLES()}) {
        if ($cdmi->IsEntity($entity)) {
            # Get all the instances of this entity type for the specified
            # genome.
            my @ids = $cdmi->GetFlat($entity, "$entity(id) LIKE ?",
                ["$genomeID%"], 'id');
            print scalar(@ids) . " old records found of type $entity.\n";
            # Delete them and keep the statistics.
            for my $id (@ids) {
                my $newStats = $cdmi->Delete($entity => $id);
                $stats->Accumulate($newStats);
            }
        }
    }
}

