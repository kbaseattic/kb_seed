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
server.

=item validate

Validate the input files without loading them.

=item slow

Use individual INSERT commands to load the database instead of spooling into
sequential load files.

=back

There are two positional parameters-- the source database name (e.g. C<SEED>,
C<MOL>, ...) and the name of the directory containing the genome data.

=cut

# Create the command-line option variables.
my ($recursive, $newOnly, $clear, $id_server_url, $validate, $slow);
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
        "validate" => \$validate, "slow" => \$slow);
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
# Get the source and genome directory.
    my ($source, $genomeDirectory) = @ARGV;
    if (! $source) {
        die "No source database specified.\n";
    } elsif (! $genomeDirectory) {
        die "No genome directory specified.\n";
    } elsif (! -d $genomeDirectory) {
        die "Genome directory $genomeDirectory not found.\n";
    } else {
        # Connect to the KBID server and create the loader utility object.
        my $id_server;
        if ($id_server_url) {
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
            LoadGenome($loader, $genomeDirectory, $validate);
        } else {
            # Yes. Get the subdirectories.
            opendir(TMP, $genomeDirectory) || die "Could not open $genomeDirectory.\n";
            my @subDirs = sort grep { substr($_,0,1) ne '.' } readdir(TMP);
            print scalar(@subDirs) . " entries found in $genomeDirectory.\n";
            # Loop through the subdirectories.
            for my $subDir (@subDirs) {
                my $fullPath = "$genomeDirectory/$subDir";
                if (-d $fullPath) {
                    LoadGenome($loader, $fullPath, $validate);
                }
            }
        }
        # Display the statistics.
        print "All done.\n" . $loader->stats->Show();
    }


=head2 Subroutines

=head3 LoadGenome

    LoadGenome($loader, $genomeDirectory, $validate);

Load a single genome from the specified genome directory.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeDirectory

Directory containing the genome load files.

=item validate

If TRUE, the input files will be validated but not loaded.

=back

=cut

sub LoadGenome {
    # Get the parameters.
    my ($loader, $genomeDirectory, $validate) = @_;
    # Indicate our progress.
    print "Processing $genomeDirectory.\n";
    # Compute the genome ID from the directory name.
    my @parts = split /\//, $genomeDirectory;
    my $genomeOriginalID = pop @parts;
    print "Computed genome ID is $genomeOriginalID.\n";
    $loader->SetGenome($genomeOriginalID);
    # Read the metadata file.
    my $metaName = $loader->genome_load_file_name($genomeDirectory, "metadata.tbl");
    print "Reading metadata from $metaName.\n";
    my $metaHash = Bio::KBase::CDMI::CDMILoader::ParseMetadata($metaName);
    # Extract the genome name.
    my $scientificName = $metaHash->{name};
    if (! $scientificName) {
        die "No scientific name found in metadata for $genomeDirectory.\n";
    }
    # Ensure the genome has data.
    my $contigName = $loader->genome_load_file_name($genomeDirectory, "contigs.fa");
    if (! -s $contigName) {
        print "Genome skipped: no contig data.\n";
    } else {
        # This will be set to FALSE if this genome cannot be processed.
        my $processing = 1;
        # The KBase genome ID will be put in here.
        my $genomeID;
        # If we are not validating, we must prepare the database for
        # loading this genome.
        if (! $validate) {
            # Get the KBID for this genome.
            $genomeID = $loader->GetKBaseID('kb|g', 'Genome', $genomeOriginalID);
            # If this genome exists and we are only loading new genomes, skip it.
            if ($newOnly && $cdmi->Exists(Genome => $genomeID)) {
                $loader->stats->Add(genomeSkipped => 1);
                print "Genome skipped: already in database.\n";
                $processing = 0;
            } else {
                # Delete any existing data for this genome.
                DeleteGenome($loader, $genomeID);
                # Initialize the relation loaders. The order of the relations is
                # important, since it determines whether or not the DeleteGenome
                # method will work properly.
                if (! $slow) {
                    $loader->SetRelations(qw(IsComposedOf Contig IsSequenceOf
                            IsOwnerOf Feature FeatureAlias IsLocatedIn IsFunctionalIn
                            IsProteinFor Encompasses));
                }
            }
        }
        if ($processing) {
            # Process the contigs.
            my ($contigMap, $dnaSize, $gcContent, $md5) = LoadContigs($loader,
                    $genomeID, $genomeOriginalID, $contigName, $validate);
            # Process the features.
            my ($pegs, $rnas, $id_mapping) = LoadFeatures($loader, $genomeID,
                    $genomeDirectory, $contigMap, $validate);
            # Process the proteins.
            my $protName = $loader->genome_load_file_name($genomeDirectory, "proteins.fa");
            LoadProteins($loader, $id_mapping, $protName, $validate);
            # If we are loading for real, store everything in the database here.
            if (! $validate) {
                # Unspool the relation loaders.
                if (! $slow) {
                    $loader->LoadRelations();
                }
                # Create the genome record.
                CreateGenome($loader, $source, $genomeID, $genomeOriginalID, $metaHash,
                        $dnaSize, $gcContent, $md5, $pegs, $rnas, scalar(keys %$contigMap));
            }
        }
    }
}

=head3 DeleteGenome

    DeleteGenome($loader, $genomeID);

Delete the existing data for the specified genome. This method is designed
to work even if the genome was only partially loaded. It will not, however,
delete any roles or proteins, since these do not belong to the genome.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manager the load.

=item genomeID

KBase ID of the genome to delete.

=back

=cut

sub DeleteGenome {
    # Get the parameters.
    my ($loader, $genomeID) = @_;
    print "Deleting old copy of genome $genomeID.\n";
    # Get the database object.
    my $cdmi = $loader->cdmi;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Does the genome exist?
    if ($cdmi->Exists(Genome => $genomeID)) {
        # Yes. Delete the genome itself.
        my $subStats = $cdmi->Delete(Genome => $genomeID);
        # Roll up the statistics.
        $stats->Accumulate($subStats);
    } else {
        # No, we have to delete any remnants from a partial load.
        # Delete the contigs.
        $loader->DeleteRelatedRecords($genomeID, 'IsComposedOf', 'Contig');
        # Delete the features.
        $loader->DeleteRelatedRecords($genomeID, 'IsOwnerOf', 'Feature');
        # Check for a taxonomy connection.
        my ($taxon) = $cdmi->GetFlat("IsTaxonomyOf", 'IsTaxonomyOf(to_link) = ?',
                [$genomeID], 'from-link');
        if ($taxon) {
            # We found one, so disconnect it.
            $cdmi->DeleteRow('IsTaxonomyOf', $taxon, $genomeID);
            $stats->Add(IsTaxonomyOf => 1);
        }
        # Check for a submit connection.
        my ($source) = $cdmi->GetFlat("Submitted", 'Submitted(to_link) = ?',
                [$genomeID], 'from-link');
        if ($source) {
            # We found one, so disconnect it.
            $cdmi->DeleteRow('Submitted', $source, $genomeID);
            $stats->Add(Submitted => 1);
        }
    }
}

=head3 LoadContigs

    my ($contigMap, $dnaSize, $gcContent, $md5) =
        LoadContigs($loader, $genomeID, $genomeOriginalID,
        $contigFastaFile, $validate);

Load the contigs for the specified genome into the database.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manager the load.

=item genomeID

KBase ID of the genome being loaded.

=item genomeOriginalID

ID of the genome in the original database.

=item contigFastaFile

Name of the FASTA file containing the DNA for the contigs.

=item validate

If TRUE, the input files will be validated but not loaded.

=item RETURN

Returns a list with four elements: (0) a reference to a hash mapping
the foreign identifier of each contig to the KBase ID, (1) the number of base pairs in all of
the contigs put together, (2) the percent GC content in the DNA, and
(3) the genome's MD5 identifer.

=back

=cut

sub LoadContigs {
    # Get the parameters.
    my ($loader, $genomeID, $genomeOriginalID, $contigFastaFile, $validate) = @_;
    # Get the CDMI database object.
    my $cdmi = $loader->cdmi;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Create an MD5 computer so we can compute the contig and genome
    # MD5s.
    my $md5Object = MD5Computer->new();
    # Create the return variables. Note that until we're ready to return
    # to the caller, $gcContent will contain the total number of GC base
    # pairs found, not the percentage.
    my ($contigMap, $dnaSize, $gcContent) = ({}, 0, 0);
    # Open the contig FASTA file.
    open(my $ih, "<$contigFastaFile") || die "Could not open contig file: $!\n";
    # Get the length of a DNA segment.
    my $segmentLength = ($validate ? 10000 : $cdmi->TuningParameter('maxSequenceLength'));
    # Each contig is separated into a real contig that belongs to the
    # genome and a contig sequence that represents the DNA. Since
    # contig sequences are shared, we cache each contig in memory
    # first and then load it after we've verified that the sequence is
    # new to the database.
    # We start by reading the identifier line for the first contig.
    my $line = <$ih>;
    unless ($line =~ /^>(\S+)\s*(.*)/) {
        die "Invalid format in contig file: $contigFastaFile.\n";
    } else {
        my ($foreignID, $comment) = ($1, $2);
        # Loop through the contigs.
        while (defined $foreignID) {
            # Get this contig's sequence.
            my ($sequence, $nextID, $comment) =
                    $loader->ReadFastaRecord($ih);
            # Normalize to lower case.
            $sequence = lc $sequence;
            # Update the GC and DNA counts.
            $gcContent += ($sequence =~ tr/gc//);
            my $contigLen = length $sequence;
            $dnaSize += $contigLen;
            $stats->Add(dnaLetters => $contigLen);
            # We must break the contig into chunks. We do this with unpack.
            my $chunkCount = int($contigLen / $segmentLength);
            my $template = ("A$segmentLength" x $chunkCount) . "A*";
            my @chunks = unpack($template, $sequence);
            $stats->Add(contigChunks => scalar @chunks);
            # We don't need the full sequence any more.
            undef $sequence;
            # Compute the contig's MD5.
            my $contigMD5 = $md5Object->ProcessContig($foreignID, \@chunks);
            # If we are validating, we note the contig ID in the map and we're
            # done.
            if ($validate) {
                $contigMap->{$foreignID} = 1;
            } else {
                # Otherwise, we need to load the contig into the database.
                my $contigKBID = $loader->GetKBaseID("$genomeID.c", 'Contig',
                        $foreignID);
                $contigMap->{$foreignID} = $contigKBID;
                # We now have all the information we need to load the contig
                # into the database. First, check to see if the sequence is
                # already in the database.
                my $contigSeqData = $cdmi->GetEntity(ContigSequence => $contigMD5);
                if (defined $contigSeqData) {
                    # It is, so we don't have to create it.
                    $stats->Add(contigReused => 1);
                } else {
                    # Here we have to create the sequence.
                    $stats->Add(contigFresh => 1);
                    $cdmi->InsertObject('ContigSequence', id => $contigMD5,
                        'length' => $contigLen);
                    # Loop through the chunks, connecting them to the contig.
                    for (my $i = 0; $i < @chunks; $i++) {
                        # We have to create the key for this chunk. It's the
                        # contig key followed by the ordinal number padded to
                        # seven digits.
                        my $chunkID = $contigMD5 . ":" . ("0" x (7 - length($i))) . $i;
                        # Create the chunk and connect it to the sequence.
                        $cdmi->InsertObject('HasSection', from_link => $contigMD5,
                                to_link => $chunkID);
                        $cdmi->InsertObject('ContigChunk', id => $chunkID,
                            sequence => $chunks[$i]);
                        $stats->Add(chunkInserted => 1);
                    }
                }
                # Now the sequence is in the database. Add the contig and
                # connect it to the genome.
                $loader->InsertObject('IsComposedOf', from_link => $genomeID,
                        to_link => $contigKBID);
                $loader->InsertObject('Contig', id => $contigKBID,
                        source_id => $foreignID);
                $loader->InsertObject('IsSequenceOf', from_link => $contigMD5,
                        to_link => $contigKBID);
            }
            $stats->Add(contigs => 1);
            # Set up for the next contig.
            $foreignID = $nextID;
        }
    }
    # Compute the genome's MD5.
    my $md5 = $md5Object->CloseGenome();
    # Convert the GC content to a percentage.
    $gcContent = $gcContent * 100 / $dnaSize;
    print "$dnaSize base pairs loaded from $contigFastaFile.\n";
    # Return the computation results.
    return ($contigMap, $dnaSize, $gcContent, $md5);
}

=head3 LoadFeatures

    my ($pegs, $rnas, $id_mapping) = LoadFeatures($loader,
            $genomeID, $genomeDirectory, $contigMap, $validate);

Load the genome's features into the database from the feature files.
The feature information is kept in two tab-delimited files-- one
that specifies the feature types and locations, and one that
specifies each feature's functional assignment.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manager the load.

=item genomeID

KBase ID of the genome being loaded.

=item genomeDirectory

Directory containing the feature files-- C<features.tab> and C<functions.tab>.

=item contigMap

Reference to a hash that maps each contig's foreign identifier to
its KBase ID.

=item validate

If TRUE, the input files will be validated but not loaded.

=item RETURN

Returns a list containing (0) the number of protein-encoding genes
in the genome, (1) the number of RNAs in the genome, and (2) a
reference to a hash mapping foreign feature IDs to KBase IDs.

=back

=cut

sub LoadFeatures {
    # Get the parameters.
    my ($loader, $genomeID, $genomeDirectory, $contigMap, $validate) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Initialize the return variables.
    my ($pegs, $rnas) = (0, 0);
    # Count the total features for the progress display.
    my $fidCount = 0;
    # Create the feature ID mapping.
    my $id_mapping = {};
    # This will save the aliases.
    my $aliasMap = {};
    # We'll track the parents in here.
    my %parentMap;
    # To pull this off, we need to read two parallel files-- one
    # containing the locations and the feature types, and one containing
    # the assignments. Both files have the feature ID in the first
    # column. First, we read the function file into memory.
    my %funcs;
    my $funcFileName = $loader->genome_load_file_name($genomeDirectory, 'functions.tab');
    if (! -f $funcFileName) {
        print "Functions file not found. No functions will be processed.\n";
    } else {
        open(my $funch, "<$funcFileName") || die "Could not open functions file: $!\n";
        while (! eof $funch) {
            my ($fid2, $function) = $loader->GetLine($funch);
            $funcs{$fid2} = $function;
            $stats->Add(functionLines => 1);
        }
        close $funch;
    }
    # Now we open the feature file for input. This will drive the main loop.
    my $featFileName = $loader->genome_load_file_name($genomeDirectory, 'features.tab');
    open(my $feath, "<$featFileName") || die "Could not open features file: $!\n";
    my ($fid1, $type, $locations, $parent, $subset, @aliases) = $loader->GetLine($feath);
    $fidCount++;
    # Loop through the file. Note that it is acceptable for a feature to
    # be without an assignment. We will process the features
    # in batches of 1000 at a time. Each batch is formed into a hash
    # mapping feature IDs to 3-tuples (type, location, function). We
    # then get the KBase IDs for all the features and put the batch
    # into the database.
    my %fidBatch;
    my $batchSize = 0;
    while (defined $fid1) {
        # Compute the function for this feature.
        my $fidFunction = $funcs{$fid1};
        if (! defined $fidFunction) {
            print STDERR "No function found for $fid1.\n";
            $fidFunction = "";
            $stats->Add(missingFunction => 1);
        }
        # If this feature has aliases, save them.
        if (@aliases) {
            $aliasMap->{$fid1} = [@aliases];
            $stats->Add(aliasesFound => 1);
            $stats->Add(aliasIn => scalar(@aliases));
        }
        # If this feature has a parent, save it.
        if ($parent) {
            $parentMap{$fid1} = $parent;
            $stats->Add(parentIn => 1);
        }
        # Put this feature into the hash.
        $fidBatch{$fid1} = [$type, $locations, $fidFunction];
        $batchSize++;
        # Is the batch full?
        if ($batchSize >= 1000) {
            # Yes. Process It.
            ProcessFeatureBatch($loader, $id_mapping, \$pegs, \$rnas, $genomeID,
                    \%fidBatch, $contigMap, $aliasMap, $validate);
            # Start the next one.
            %fidBatch = ();
            $batchSize = 0;
        }
        # Get the next feature in the feature file.
        ($fid1, $type, $locations, $parent, $subset, @aliases) = $loader->GetLine($feath);
        $fidCount++;
    }
    # Process the residual batch.
    if ($batchSize > 0) {
        ProcessFeatureBatch($loader, $id_mapping, \$pegs, \$rnas, $genomeID,
                \%fidBatch, $contigMap, $aliasMap, $validate);
    }
    # Process the parents.
    for my $child (keys %parentMap) {
        my $parent = $parentMap{$child};
        # Insure the parent ID is valid.
        if (! $id_mapping->{$parent}) {
            $stats->Add(missingParent => 1);
            print "Feature parent $parent not found.\n";
        } elsif (! $validate) {
            # If we are loading for real, store it in the Encompasses table.
            $loader->InsertObject('Encompasses', from_link => $id_mapping->{$child},
                    to_link => $id_mapping->{$parent});
        }
    }
    # Accumulate the statistics on the number of features.
    $stats->Add(featureLines => $fidCount);
    # Display our progress.
    print "$fidCount features loaded from $genomeDirectory.\n";
    # Return the feature type counts and the mappings.
    return ($pegs, $rnas, $id_mapping);
}

=head3 ProcessFeatureBatch

    ProcessFeatureBatch($loader, $id_mapping, \$pegs, \$rnas,
                        $genomeID, \%fidBatch, \%contigMap,
                        \%aliasMap, $validate);

Load a batch of features into the database. Features are processed
in batches to reduce the overhead for requesting feature IDs from
the KBase ID service.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manager the load.

=item id_mapping

Reference to hash mapping foreign feature IDs to KBase IDs.

=item pegs

Reference to the counter for the number of protein-encoding genes found.

=item rnas

Reference to the counter for the number of RNAs found.

=item genomeID

KBase ID of the genome being loaded.

=item fidBatch

Reference to a hash that maps each foreign feature ID to a 3-tuple
consisting of (0) the feature type, (1) the feature's location strings,
and (2) the feature's functional assignment.

=item contigMap

Reference to a hash that maps each contig's foreign identifier to
its KBase ID.

=item aliasMap

Reference to a hash that maps each feature's foreign identifier to
a list of aliases (if any).

=item validate

If TRUE, the input files will be validated but not loaded.

=back

=cut

sub ProcessFeatureBatch {
    # Get the parameters.
    my ($loader, $id_mapping, $pegs, $rnas, $genomeID,
            $fidBatch, $contigMap, $aliasMap, $validate) = @_;
    # Get the CDMI database.
    my $cdmi = $loader->cdmi;
    # Get the statistics object.
    my $stats = $loader->stats;
    $stats->Add(featureBatches => 1);
    # Compute the maximum location segment length.
    my $segmentLength = ($validate ? 0 : $cdmi->TuningParameter('maxLocationLength'));
    # Get all the KBase IDs for the features in this batch.
    my @fids = keys %$fidBatch;
    # Split all the features by type. We need to do this to get the
    # correct prefixes.
    my %typemap;
    for my $fid (@fids) {
        my($type) = $fidBatch->{$fid}->[0];
        push(@{$typemap{$type}}, $fid);
    }
    if ($validate) {
        # If we are validating, we simply insert the IDs into the
        # ID map with a value of 1.
        for my $type (keys %typemap) {
            for my $fid (@{$typemap{$type}}) {
                $id_mapping->{$fid} = 1;
            }
        }
    } else {
        # If we are loading for real, we call the ID server.
        for my $type (keys %typemap) {
            my $h = $loader->GetKBaseIDs("$genomeID.$type", 'Feature',
                   $typemap{$type});
            $id_mapping->{$_} = $h->{$_} foreach keys %$h;
        }
    }
    # Now we have all the KBase IDs we need. Loop through the batch.
    for my $fid (@fids) {
        # Get the KBase ID for this feature.
        my $fidKBID = $id_mapping->{$fid};
        # Get the type, location, and function.
        my ($type, $locations, $function) = @{$fidBatch->{$fid}};
        # Parse the locations.
        my @locs = map { BasicLocation->new($_) } split /\s*,\s*/, $locations;
        $stats->Add(featureLocations => scalar @locs);
        # The feature length will be computed in here.
        my $len = 0;
        # Recover from bad locations.
        eval {
            # Compute the total feature length.
            for my $loc (@locs) {
                $len += $loc->Length;
            }
        };
        if ($@) {
            die "Invalid locations for feature $fid: $@\n";
        } elsif ($len == 0) {
            print "Zero-length feature $fid found.\n";
            $stats->Add(nullFeature => 1);
        }
        # If we are loading for real, create the feature record and
        # check for aliases.
        if (! $validate) {
            $loader->InsertObject('IsOwnerOf', from_link => $genomeID,
                    to_link => $fidKBID);
            $loader->InsertObject('Feature', id => $fidKBID,
                    feature_type => $type, function => $function,
                    sequence_length => $len, source_id => $fid);
            $stats->Add(features => 1);
            # Check for aliases.
            my $aliases = $aliasMap->{$fid};
            if (defined $aliases) {
                for my $alias (@$aliases) {
                    $loader->InsertObject('FeatureAlias', id => $fidKBID,
                            alias => $alias);
                    $stats->Add(featureAlias => 1);
                }
            }
        }
        # Count the feature type.
        $stats->Add("featureType-$type" => 1);
        $$pegs++ if $type eq 'CDS';
        $$rnas++ if $type eq 'rna';
        # Check the contig IDs in the locations.  If we find an
        # invalid contig ID, we must skip the location data for
        # this feature.
        my $badContig = 0;
        for my $loc (@locs) {
            if (! defined $contigMap->{$loc->Contig}) {
                $badContig++;
                print "Contig " . $loc->Contig . " not found for feature $fid.\n";
            }
        }
        if ($badContig) {
            $stats->Add(badContigs => $badContig);
            $stats->Add(featureContigError => 1);
        } elsif (! $validate) {
            # If we are loading for real, we need to create the feature's
            # location segments. This variable counts the segments created.
            my $locIndex = 0;
            # Loop through the sub-locations.
            for my $loc (@locs) {
                # Compute this location's contig.
                my $contigKBID = $contigMap->{$loc->Contig};
                # Divide the location into segments.
                while (my $segment = $loc->Peel($segmentLength)) {
                    # Output this segment.
                    $loader->InsertObject('IsLocatedIn', from_link => $fidKBID,
                            to_link => $contigKBID, begin => $segment->Left,
                            dir => $segment->Dir, 'len' => $segmentLength,
                            ordinal => $locIndex++);
                    $stats->Add(locSegments => 1);
                }
                # Output the residual part of the location.
                $loader->InsertObject('IsLocatedIn', from_link => $fidKBID,
                        to_link => $contigKBID, begin => $loc->Left,
                        dir => $loc->Dir, 'len' => $loc->Length,
                        ordinal => $locIndex++);
                $stats->Add(locSegments => 1);
            }
        }
        # Finally, we associate the feature with its roles.
        my ($roles, $errors) = SeedUtils::roles_for_loading($function);
        if (! defined $roles) {
            # Here the function does not appear to be a role.
            $stats->Add(roleRejected => 1);
        } elsif (! $validate) {
            # Here the function contained one or more roles and
            # we are loading for real. We will also count
            # the number of roles that were rejected for being too
            # long.
            $stats->Add(rolesTooLong => $errors);
            # Loop through the roles found.
            for my $role (@$roles) {
                # Insure this role is in the database.
                my $roleID = $loader->CheckRole($role);
                # Connect it to the feature.
                $loader->InsertObject('IsFunctionalIn', from_link => $roleID,
                        to_link => $fidKBID);
            }
        }
    }
}

=head3 LoadProteins

    LoadProteins($loader, $id_mapping, $proteinFastaFile, $validate);

Load the protein translations into the database.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manager the load.

=item id_mapping

Reference to a hash mapping foreign feature IDs to KBase IDs.

=item proteinFastaFile

Name of a FASTA file containing the protein translation for each feature.

=item validate

If TRUE, the input files will be validated but not loaded.

=back

=cut

sub LoadProteins {
    # Get the parameters.
    my ($loader, $id_mapping, $proteinFastaFile, $validate) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Ensure the protein file exists and is nonempty.
    if (! -s $proteinFastaFile) {
        $stats->Add(emptyProteinFile => 1);
    } else {
        # Open the protein file for input.
        open(my $ih, "<$proteinFastaFile") || die "Could not open protein file: $!\n";
        # This will count the proteins.
        my $protCount = 0;
        # Read the header of the first protein.
        my $line = <$ih>;
        unless ($line =~ /^>(\S+)\s*(.*)/) {
            die "Invalid format in protein file: $proteinFastaFile.\n";
        } else {
            # Loop through the fasta file.
            my ($fid, $comment) = ($1, $2);
            while (defined $fid) {
                # Get this feature's protein.
                my ($sequence, $nextFid, $comment) = $loader->ReadFastaRecord($ih);
                $protCount++;
                # The protein ID goes in here.
                my $protID;
                # If we are loading for real, we need to insure the protein
                # sequence is in the database and get its ID.
                if (! $validate) {
                    $protID = $loader->CheckProtein($sequence);
                }
                # Look for the feature.
                my $kbid = $id_mapping->{$fid};
                if (! $kbid) {
                    # Not found, so we have an error.
                    print "Feature $fid for protein sequence not found.\n";
                    $stats->Add(proteinFeatureNotFound => 1);
                } elsif (! $validate) {
                    # Found, and we are loading for real, so we can connect the
                    # protein to the feature.
                    $loader->InsertObject('IsProteinFor', from_link => $protID,
                            to_link => $kbid);
                    $stats->Add(featureProtein => 1);
                }
                # Set up for the next feature.
                $fid = $nextFid;
            }
        }
        # Update the protein statistics.
        $stats->Add(proteinsIn => $protCount);
        # Display our progress.
        print "$protCount proteins loaded from $proteinFastaFile.\n";
    }
}

=head3 CreateGenome

    CreateGenome($loader, $source, $genomeID, $genomeOriginalID,
                 $metaHash, $dnaSize, $gcContent, $md5, $pegs,
                 $rnas);

Create the genome record.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manager the load.

=item source

Source database the genome came from.

=item genomeID

KBase ID of the genome being loaded.

=item source

Source database the genome came from.

=item genomeOriginalID

Foreign identifier of the genome in the source database.

=item metaHash

Reference to a hash containing the contents of the metadata file.

=item dnaSize

Number of base pairs in the genome's DNA.

=item gcContent

Percent GC content in the DNA.

=item md5

MD5 identifier of the genome's DNA sequence.

=item pegs

Number of protein-encoding genes in the genome.

=item rnas

Number of RNAs in the genome.

=item contigs

Number of contigs in the genome.

=back

=cut

sub CreateGenome {
    # Get the parameters.
    my ($loader, $source, $genomeID, $genomeOriginalID, $metaHash, $dnaSize, $gcContent, $md5, $pegs, $rnas, $contigs) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    # Get the database object.
    my $cdmi = $loader->cdmi;
    # Default the domain to an empty string (unknown).
    my $domain = "";
    my $prokaryotic = 0;
    # Get the scientific name from the metadata.
    my $scientificName = $metaHash->{name};
    if (! $scientificName) {
        die "Invalid or missing name for $genomeOriginalID.\n";
    }
    # Try to find the taxon ID for this genome.
    my $taxID = $cdmi->ComputeTaxonID($scientificName);
    # If we found one, connect it to the genome and compute the domain.
    if (defined $taxID) {
        $cdmi->InsertObject('IsTaxonomyOf', from_link => $taxID,
                to_link => $genomeID);
        $stats->Add(genomeHasTaxon => 1);
        # Now we need to compute the domain. We do a looping climb up
        # the taxonomy tree.
        my $currentTaxID = $taxID;
        while ($currentTaxID && ! $domain) {
            my ($taxTuple) = $cdmi->GetAll('IsInGroup TaxonomicGrouping',
                    "IsInGroup(from_link) = ?", [$currentTaxID],
                    "TaxonomicGrouping(id) TaxonomicGrouping(domain) TaxonomicGrouping(scientific_name)");
            if (! $taxTuple) {
                # We've run off the end, so we stop the loop without a
                # domain.
                undef $currentTaxID;
            } else {
                # Get the data about this group.
                my ($nextTaxID, $domainFlag, $nextTaxName) = @$taxTuple;
                if ($domainFlag) {
                    # Here we've found a domain group, so save its name.
                    $domain = $nextTaxName;
                    # Decide if it's prokaryotic.
                    if ($nextTaxID == 2 || $nextTaxID == 2157) {
                        $prokaryotic = 1;
                    }
                } else {
                     # Here we have to keep looking.
                     $currentTaxID = $nextTaxID;
                }
            }
        }
    }
    # Connect the genome to its submitting source.
    $cdmi->InsertObject('Submitted', from_link => $source, to_link => $genomeID);
    $loader->InsureEntity(Source => $source);
    # Get the attributes.
    my $geneticCode = $metaHash->{genetic_code} || 11;
    my $complete = $metaHash->{complete} || 1;
    # Now we create the genome record itself.
    $cdmi->InsertObject('Genome', id => $genomeID, complete => $complete,
            contigs => $contigs, dna_size => $dnaSize, domain => $domain,
            gc_content => $gcContent, genetic_code => $geneticCode,
            md5 => $md5, pegs => $pegs, prokaryotic => $prokaryotic,
            rnas => $rnas, scientific_name => $scientificName,
            source_id => $genomeOriginalID);
    $stats->Add(genomesAdded => 1);
    print "Genome $genomeID created.\n";
}

