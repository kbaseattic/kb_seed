package Bio::KBase::CDMI::GenomeUtils;
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
    use MD5Computer;
    use Digest::MD5;

=head1 CDMI Genome Load Utilities

These are subroutines used to reload genome-related data. Included are
methods for converting SEED genome directories to exchange format and
processing subsystem bindings.

=head3 ConvertGenome

    Bio::KBase::CDMI::GenomeUtils::ConvertGenome($stats, $genomeID, $inDirectory,
                                                 $outDirectory);

Convert a SEED genome directory to KBase exchange format.

=over 4

=item stats

L<Stats> object into which statistics about the conversion should be
accumulated.

=item genomeID

ID of the genome being converted.

=item inDirectory

SEED genome directory containing the genome to convert.

=item outDirectory

Output directory to contain the genome in KBase exchange format. If it does
not exist it will be created.

=back

=cut


sub ConvertGenome {
    # Get the parameters.
    my ($stats, $genomeID, $inDirectory, $outDirectory) = @_;
    # These will be used for file handles.
    my ($ih, $oh);
    # Insure the output directory exists.
    if (! -d $outDirectory) {
        mkdir $outDirectory;
    }
    print "Processing $genomeID from $inDirectory.\n";
    # Now we must copy the contig FASTA file. The contig IDs have
    # to have the genome ID put in front.
    print "Copying contigs for $genomeID.\n";
    open($ih, "<$inDirectory/contigs") || die "Error opening contigs input: $!";
    open($oh, ">$outDirectory/contigs.fa") || die "Error opening contigs output: $!";
    while (! eof $ih) {
        my $line = <$ih>;
        if ($line =~ /^>(.+)/) {
            print $oh ">$genomeID:$1\n";
        } else {
            print $oh $line;
        }
    }
    close $ih; undef $ih;
    close $oh; undef $oh;
    # This will hold a map of the deleted features.
    my %deleted;
    # Open the feature output file.
    open ($oh, ">$outDirectory/features.tab") || die "Error output features output: $!";
    # Loop through the feature types. Each is in a separate directory.
    my @types = grep { $_ =~ /^[a-zA-Z]+$/ } OpenDir("$inDirectory/Features");
    for my $fidType (@types) {
        print "Processing $fidType features.\n";
        $stats->Add(featureType => 1);
        # Check for deleted features.
        my $deletedFidFile = "$inDirectory/Features/$fidType/deleted.features";
        if (-f $deletedFidFile) {
            open($ih, "<$deletedFidFile") || die "Error opening deleted features file: $!";
            while (! eof $ih) {
                my $line = <$ih>;
                chomp $line;
                $deleted{$line} = 1;
                $stats->Add(deletedFid => 1);
            }
            close $ih; undef $ih;
        }
        # Now open the tbl file for these features.
        open($ih, "<$inDirectory/Features/$fidType/tbl") || die "Error opening $fidType tbl file: $!";
        # Loop through the features in the file.
        while (! eof $ih) {
            my ($fid, $locs) = Tracer::GetLine($ih);
            # Insure the feature is not deleted.
            if ($deleted{$fid}) {
                $stats->Add(deletedInTbl => 1);
            } else {
                # Parse the locations.
                my @locs = split m/\s*,\s*/, $locs;
                my $convertedLocs = join(",", map { "$genomeID:" . BasicLocation->new($_)->String() } @locs);
                # Translate the feature type.
                if ($fidType eq 'peg') {
                    $fidType = 'CDS';
                }
                # Output the feature information.
                print $oh join("\t", $fid, $fidType, $convertedLocs) . "\n";
                $stats->Add(outputFromTbl => 1);
            }
        }
    }
    close $oh; undef $oh;
    close $ih; undef $ih;
    # Check for a protein FASTA file.
    if (-f "$inDirectory/Features/peg/fasta") {
        # We have one. We must copy it to the protein output file,
        # keeping on the lookout for deleted features.
        open($ih, "<$inDirectory/Features/peg/fasta") || die "Error opening protein FASTA input: $!";
        open($oh, ">$outDirectory/proteins.fa") || die "Error opening protein FASTA output: $!";
        print "Copying protein FASTA file.\n";
        # We'll set this to TRUE if we're handling a deleted feature.
        my $deleting = 0;
        # Loop through the input.
        while (! eof $ih) {
            my $line = <$ih>;
            $stats->Add(proteinFastaLineIn => 1);
            if ($line =~ /^>(\S+)/) {
                # Here we have a header line. Check the feature ID.
                if ($deleted{$1}) {
                    # It's deleted. Suppress this section.
                    $deleting = 1;
                    $stats->Add(deletedProtein => 1);
                } else {
                    $deleting = 0;
                    $stats->Add(keepingProtein => 1);
                }
            }
            # Output this line if we're not deleting.
            if (! $deleting) {
                print $oh $line;
                $stats->Add(proteinFastaLineOut => 1);
            } else {
                $stats->Add(proteinFastaLineSkipped => 1);
            }
        }
        close $oh; undef $oh;
        close $ih; undef $ih;
    }
    # Now we need to output the assignments. We loop through the three files in priority order.
    print "Copying assignments.\n";
    my %functions;
    my $fileCount = 0;
    for my $funFile ("assigned_functions", "proposed_non_ff_functions", "proposed_functions") {
    	my $fullName = "$inDirectory/$funFile";
    	if (-f $fullName) {
		    open($ih, "<$fullName") || die "Error opening $funFile input: $!";
		    $stats->Add("$funFile-open" => 1);
		    $fileCount++;
		    while (! eof $ih) {
		        # Get this assignment.
		        my ($fid, $assignment) = Tracer::GetLine($ih);
		        $stats->Add(assignmentLineIn => 1);
		        # Is it deleted?
		        if ($deleted{$fid}) {
		            # Yes. Skip it.
		            $stats->Add(assignmentLineSkipped => 1);
		        } else {
		            # No. Save it.
		            $functions{$fid} = $assignment;
		            $stats->Add("$funFile-stored" => 1);
		        }
		    }
		    close $ih; undef $ih;
    	}
    }
    if (! $fileCount) {
    	die "No assignment files found for $genomeID";
    }
    # Write out the assignments.
    open($oh, ">$outDirectory/functions.tab") || die "Error opening functions output: $!";
    for my $fid (sort keys %functions) {
        print $oh "$fid\t$functions{$fid}\n";
        $stats->Add(assignmentLineOut => 1);
    }
    close $oh; undef $oh;
    %functions = ();
    # Finally, we must create the metadata file.
    open($oh, ">$outDirectory/metadata.tbl") || die "Error opening metadata output: $!";
    print "Writing genome attributes.\n";
    my ($genomeName) = GetFile("$inDirectory/GENOME");
    print $oh "name\n$genomeName\n//\n";
    if (-f "$inDirectory/COMPLETE") {
        print $oh "complete\n1\n//\n";
    } else {
        print $oh "complete\n0\n//\n";
    }
    $stats->Add(attribute => 1);
    my ($taxonomy) = GetFile("$inDirectory/TAXONOMY");
    print $oh "taxonomy\n$taxonomy\n//\n";
    $stats->Add(attribute => 1);
    for my $attribute (qw(PROJECT VERSION TAXONOMY_ID GENETIC_CODE)) {
        my $fileName = "$inDirectory/$attribute";
        if (-f $fileName) {
            my ($value) = GetFile($fileName);
            print $oh lc($attribute) . "\n$value\n//\n";
            $stats->Add(attribute => 1);
        } else {
            $stats->Add(attributeNotFound => 1);
        }
    }
    close $oh;
    print "Genome completed.\n";
 }


=head3 GetFile

    my @fileContents = Bio::KBase::CDMI::GenomeUtils::GetFile($fileName);

    or

    my $fileContents = Bio::KBase::CDMI::GenomeUtils::GetFile($fileName);

Return the entire contents of a file. In list context, line-ends are removed and
each line is a list element. In scalar context, line-ends are replaced by C<\n>.

=over 4

=item fileName

Name of the file to read.

=item RETURN

In a list context, returns the entire file as a list with the line terminators removed.
In a scalar context, returns the entire file as a string. If an error occurs opening
the file, an empty list will be returned.

=back

=cut

sub GetFile {
    # Get the parameters.
    my ($fileName) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Open the file for input.
    if (open my $handle, "<$fileName") {
        # Read the whole file into the return variable, stripping off any terminator
        # characters.
        my $lineCount = 0;
        while (my $line = <$handle>) {
            $lineCount++;
            chomp $line;
            push @retVal, $line;
        }
        # Close it.
        close $handle;
    }
    # Return the file's contents in the desired format.
    if (wantarray) {
        return @retVal;
    } else {
        return join "\n", @retVal;
    }
}

=head3 OpenDir

    my @files = Bio::KBase::CDMI::GenomeUtils::OpenDir($dirName, $filtered, $flag);

Open a directory and return all the file names. This function essentially performs
the functions of an C<opendir> and C<readdir>. If the I<$filtered> parameter is
set to TRUE, all filenames beginning with a period (C<.>), dollar sign (C<$>),
or pound sign (C<#>) and all filenames ending with a tilde C<~>) will be
filtered out of the return list. If the directory does not open and I<$flag> is not
set, an exception is thrown. So, for example,

    my @files = OpenDir("/Volumes/fig/contigs", 1);

is effectively the same as

    opendir(TMP, "/Volumes/fig/contigs") || Confess("Could not open /Volumes/fig/contigs.");
    my @files = grep { $_ !~ /^[\.\$\#]/ && $_ !~ /~$/ } readdir(TMP);

Similarly, the following code

    my @files = grep { $_ =~ /^\d/ } OpenDir("/Volumes/fig/orgs", 0, 1);

Returns the names of all files in C</Volumes/fig/orgs> that begin with digits and
automatically returns an empty list if the directory fails to open.

=over 4

=item dirName

Name of the directory to open.

=item filtered

TRUE if files whose names begin with a period (C<.>) should be automatically removed
from the list, else FALSE.

=item flag

TRUE if a failure to open is okay, else FALSE

=back

=cut
#: Return Type @;
sub OpenDir {
    # Get the parameters.
    my ($dirName, $filtered, $flag) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Open the directory.
    if (opendir(my $dirHandle, $dirName)) {
        # The directory opened successfully. Get the appropriate list according to the
        # strictures of the filter parameter.
        if ($filtered) {
            @retVal = grep { $_ !~ /^[\.\$\#]/ && $_ !~ /~$/ } readdir $dirHandle;
        } else {
            @retVal = readdir $dirHandle;
        }
        closedir $dirHandle;
    } elsif (! $flag) {
        # Here the directory would not open and it's considered an error.
        die "Could not open directory $dirName.";
    }
    # Return the result.
    return @retVal;
}

=head3 LoadGenome

    LoadGenome($loader, $genomeDirectory, $validate, $source, $slow, $newOnly);

Load a single genome from the specified genome directory.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object to help manage the load.

=item genomeDirectory

Directory containing the genome load files.

=item validate

If TRUE, the input files will be validated but not loaded.

=item source

Source database from which the genomes have been taken.

=item slow

TRUE if the data is to be loaded using INSERTs, FALSE if it is to be loaded
using files. Note that the I<options> hash can be specified here, for
convenience. The intent is to use a hash of options instead of the old
list of flags going forward.

=item newOnly

TRUE if the genome should only be loaded if it is not already in the database.

=item options

Reference to a hash of options (if any). The options include the following.

=over 8

=item noContigs

If TRUE, then contigs will not be loaded. the default is FALSE.

=item noProteins

If specified, protein sequences will not be loaded.

=item sourceIDs

If TRUE, then source IDs will be used instead of generated IDs from the ID server. The
default is FALSE.

=item slow

Same as the I<slow> parameter above.

=item newOnly

Same as the I<newOnly> parameter above.

=back

=back

=cut

sub LoadGenome {
    # Get the parameters.
    my ($loader, $genomeDirectory, $validate, $source, $slow, $newOnly, $options) = @_;
    # Convert to an options hash.
    if (ref $slow eq 'HASH') {
    	$options = $slow;
    } else {
    	if (! defined $options) {
    		$options = {};
    	}
    	$options->{slow} = $slow;
    	$options->{newOnly} = $newOnly;
    }
    # Get the CDMI object.
    my $cdmi = $loader->cdmi;
    # Indicate our progress.
    print "Processing $genomeDirectory.\n";
    # Compute the genome ID from the directory name.
    my @parts = split m/\//, $genomeDirectory;
    my $genomeOriginalID = pop @parts;
    print "Computed genome ID is $genomeOriginalID.\n";
    $loader->SetGenome($genomeOriginalID);
    if ($options->{sourceIDs}) {
    	$loader->UseSourceIDs(1);
    }
    # Read the metadata file.
    my $metaName = $loader->genome_load_file_name($genomeDirectory, "metadata.tbl");
    print "Reading metadata from $metaName.\n";
    my $metaHash = Bio::KBase::CDMI::CDMILoader::ParseMetadata($metaName);
    # Extract the genome name.
    my $scientificName = $metaHash->{name};
    if (! $scientificName) {
        die "No scientific name found in metadata for $genomeDirectory.\n";
    }
    # This will be set to FALSE if this genome cannot be processed.
    my $processing = 1;
    my $contigName;
    # Are we including contigs?
    if (! $options->{noContigs}) {
	    # Ensure the genome has data.
	    $contigName = $loader->genome_load_file_name($genomeDirectory, "contigs.fa");
	    if (! -s $contigName) {
	        print "Genome skipped: no contig data.\n";
	        $processing = 0;
	    }
    }
    if ($processing) {
        # The KBase genome ID will be put in here.
        my $genomeID;
        # If we are not validating, we must prepare the database for
        # loading this genome.
        if (! $validate) {
            # Get the KBID for this genome.
          	$genomeID = $loader->GetKBaseID('kb|g', 'Genome', $genomeOriginalID);
            # If this genome exists and we are only loading new genomes, skip it.
            if ($cdmi->Exists(Genome => $genomeID)) {
            	if ($options->{newOnly}) {
	                $loader->stats->Add(genomeSkipped => 1);
	                print "Genome skipped: already in database.\n";
	                $processing = 0;
	            } else {
	                # Delete any existing data for this genome.
	                DeleteGenome($loader, $genomeID);
	            }
            }
            if ($processing) {
                # Initialize the relation loaders. The order of the relations is
                # important, since it determines whether or not the DeleteGenome
                # method will work properly.
                if (! $options->{slow}) {
                    $loader->SetRelations(qw(IsComposedOf Contig IsSequenceOf
                            IsOwnerOf Feature HasAliasAssertedFrom IsLocatedIn IsFunctionalIn
                            IsProteinFor Encompasses));
                }
            }
        }
        if ($processing) {
            # Process the contigs.
            my ($contigMap, $dnaSize, $gcContent, $md5);
            if ($options->{noContigs}) {
            	$dnaSize = 0;
            	$md5 = "";
            	$gcContent = 0;
            } else {
	            ($contigMap, $dnaSize, $gcContent, $md5) = LoadContigs($loader,
	                    $genomeID, $genomeOriginalID, $contigName, $validate);
            }
            # Process the features.
            my ($pegs, $rnas, $id_mapping) = LoadFeatures($loader, $genomeID,
                    $genomeDirectory, $contigMap, $validate);
            # Process the proteins.
            my $protName = $loader->genome_load_file_name($genomeDirectory, "proteins.fa");
            LoadProteins($loader, $id_mapping, $protName, $validate, $options->{noProteins});
            # If we are loading for real, store everything in the database here.
            if (! $validate) {
                # Unspool the relation loaders.
                if (! $options->{slow}) {
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
    open(my $ih, "<$contigFastaFile") || die "Could not open contig file $contigFastaFile: $!\n";
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
its KBase ID. If undefined, then the genome is being loaded without
contigs and no ID translation is performed.

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
            $loader->InsertObject('Encompasses', from_link => $id_mapping->{$parent},
                    to_link => $id_mapping->{$child});
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
its KBase ID. If undefined, then contigs are not being loaded
and the contig IDs will be untranslated.

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
        my $numLocs = scalar(@locs);
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
                    $loader->InsertObject('HasAliasAssertedFrom', from_link => $fidKBID,
                            alias => $alias, to_link => 'load_file');
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
        # this feature. This is only an issue if we are loading
        # contigs.
        my $badContig = 0;
        if (defined $contigMap) {
	        for my $loc (@locs) {
	            if (! defined $contigMap->{$loc->Contig}) {
	                $badContig++;
	                print "Contig " . $loc->Contig . " not found for feature $fid.\n";
	            }
	        }
        }	        
        if ($badContig) {
            $stats->Add(badContigs => $badContig);
            $stats->Add(featureContigError => 1);
        } elsif (! $validate) {
            # If we are loading for real, we need to create the feature's
            # location segments.
            CreateLocations($loader, $contigMap, $segmentLength, $fidKBID, \@locs);
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

=head3 CreateLocations

	Bio::KBase::CDMI::GenomeUtils::CreateLocations($loader, \%contigMap, $segmentLength, $fidKBID, \@locs);

Create the C<IsLocatedIn> records for a feature based on the specified list of 
L<BasicLocation> objects.
	
=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for accessing the database.

=item contigMap

Reference to a hash mapping source contig IDs to KBase contig IDs, or C<undef> if the locations already
contain KBase contig IDs.

=item segmentLength

Maximum length of the location chunk that can be stored. Larger sequences will be split to this size.

=item fidKBID

KBase feature ID for the feature whose location information is being processed.

=item locs

Reference to a list of L<BasicLocation> objects representing the feature DNA location.
	
=cut

sub CreateLocations {
	# Get the parameters.
	my ($loader, $contigMap, $segmentLength, $fidKBID, $locs) = @_;
	# Get the statistics object.
	my $stats = $loader->stats;
    # This variable counts the segments created.
    my $locIndex = 0;
    # Loop through the sub-locations.
    for my $loc (@$locs) {
        # Compute this location's contig.
        my $contigKBID = $loc->Contig;
        if (defined $contigMap) {
           	$contigKBID = $contigMap->{$contigKBID};
        }
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

=item noProteins

If TRUE, the proteins will be connected to the features, but the sequences will
not be loaded.

=back

=cut

sub LoadProteins {
    # Get the parameters.
    my ($loader, $id_mapping, $proteinFastaFile, $validate, $noProteins) = @_;
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
                # Insure the protein has no stop codon at the end.
                if ($sequence =~ /\*$/) {
                    $stats->Add(stopCodonRemovedFromProtein => 1);
                    chop $sequence;
                }
                # The protein ID goes in here.
                my $protID;
                # If we are loading for real, we need to insure the protein
                # sequence is in the database and get its ID. If we are not
                # loading sequences, we just compute the ID.
                if ($noProteins) {
                	$protID = Digest::MD5::md5_hex($sequence);
                } elsif (! $validate) {
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
    my $taxID = $cdmi->ComputeTaxonID($scientificName, $metaHash);
    # If we didn't find one, check for a SEED source ID and adapt it.
    if (! defined $taxID) {
        if ($source eq 'SEED') {
            # Strip out the taxonomy ID from the genome ID.
            $genomeOriginalID =~ /(\d+)\.\d+/;
            # Verify that we have this taxonomy group. If we do, it will be stored in
            # $taxID.
            ($taxID) = $cdmi->GetFlat('TaxonomicGrouping', 'TaxonomicGrouping(id) = ?', [$1], 'id');
        }
    }
    # If we found one, connect it to the genome and compute the domain.
    if (defined $taxID) {
        $cdmi->InsertObject('IsTaxonomyOf', from_link => $taxID,
                to_link => $genomeID);
        $stats->Add(genomeHasTaxon => 1);
        ($domain, $prokaryotic) = ComputeDomain($cdmi, $taxID);
    }
    # Connect the genome to its submitting source.
    $cdmi->InsertObject('Submitted', from_link => $source, to_link => $genomeID);
    $loader->InsureEntity(Source => $source);
    # Get the attributes.
    my $geneticCode = $metaHash->{genetic_code};
    my $complete = $metaHash->{complete} || 1;
    # Fix the genetic code if it was not found.
    if (! $geneticCode) {
    	$stats->Add(geneticCodeNotFound => 1);
    	if ($domain eq 'Eukaryota') {
    		$geneticCode = 1;
    	} elsif ($scientificName =~ /^(Achole|Meso|Myco|Spiro|Urea)plasma/) {
    		$geneticCode = 4;
    	} else {
    		$geneticCode = 11;
    	}
    }
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

=head3 ComputeDomain

	my ($domain, $prokaryotic) = Bio::KBase::CDMI::GenomeUtils::ComputeDomain($cdmi, $taxID);
	
Compute the domain associated with a specified taxonomicID. The domain name will be returned,
along with a flag indicating whether or not it is prokaryotic.

=over 4

=item cdmi

The L<Bio::KBase::KBaseCDMI::CDMI> object used to access the databse.

=item taxID

The taxonomic ID of the genome whose domain is desired.

=item RETURN

Returns a two-element list. The first element is the domain name, and the second is C<1> for a
prokaryotic genome and C<0> otherwise.

=back

=cut

sub ComputeDomain {
	# Get the parameters.
	my ($cdmi, $taxID) = @_;
    # Default the domain to an empty string (unknown).
    my $domain = "";
    my $prokaryotic = 0;
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
    # Return the computed results.
    return ($domain, $prokaryotic);
}


=head3 GetSeedGenomeHash

    my $seedGenomeH = Bio::KBase::CDMI::GenomeUtils::GetSeedGenomeHash($stats, 
            $blackListH);

Create a hash mapping SEED genome IDs to their MD5 checksums. Genomes in a
specified blacklist hash will be omitted.

=over 4

=item stats

L<Stats> object for keeping statistics about this process.

=item blackListH

Reference to a hash whose keys are SEED genome IDs of genomes to be left out
of the results.

=item RETURN

Returns a hash mapping each SEED genome ID to the MD5 checksum for its DNA
sequence.

=back

=cut

sub GetSeedGenomeHash {
    # Get the parameters.
    my ($stats, $blackListH) = @_;
    # This will be the return variable.
    my %retVal;
    # Get the SEED genome directories.
    my @genomes = grep { $_ =~ /^\d+\.\d+$/ } 
        Bio::KBase::CDMI::GenomeUtils::OpenDir($FIG_Config::organisms);
    # Loop through the genomes found.
    for my $genome (@genomes) {
        if (! $blackListH->{$genome}) {
            # Here we have a SEED genome that is not in the black list. Verify
            # that it has certain key files.
            my $genomeDir = "$FIG_Config::organisms/$genome";
            if (! -f "$genomeDir/contigs") {
                print "WARNING: $genome is missing its contig file.\n";
                $stats->Add(genomeContigFileNotFound => 1);
            } elsif (! -f "$genomeDir/assigned_functions") {
                print "WARNING: $genome is missing its assigned functions file.\n";
                $stats->Add(genomeFunctionFileNotFound => 1);
            } else {
                # Try to read the MD5.
                if (! -f "$genomeDir/KB_MD5") {
                	# This genome doesn't have one, so we create it.
                	my $md5Object = MD5Computer->new_from_fasta("$genomeDir/contigs");
                	my $md5 = $md5Object->genomeMD5();
                	open(my $oh, ">$genomeDir/KB_MD5") || die "Could not open KB_MD5 for $genome: $!";
                	print $oh $md5;
                	close $oh;
                	$stats->Add(genomeMD5Created => 1);
                }
                # Now try to read the MD5 file. We know it's there.
                if (! open(my $ih, "$genomeDir/KB_MD5")) {
                	print "WARNING: $genome has a bad KB_MD5 file.\n";
                	$stats->Add(genomeMD5FileError => 1);
                } else {
	                my $md5 = <$ih>;
	                if (! $md5) {
	                    print "WARNING: MD5 file for $genome is empty.\n";
	                    $stats->Add(genomeMD5FileEmpty => 1);
	                } else {
	                    # We read in the MD5. Clean the line-end and put it in
	                    # the hash.
	                    chomp $md5;
	                    $retVal{$genome} = $md5;
	                }
                }
            }
        }
    }
    # Return the hash.
    return \%retVal;
}

=head3 Cmp

    my $cmp = GenomeUtils::Cmp($a, $b);

This method performs a universal sort comparison. Each value coming in is
separated into a text parts and number parts. The text
part is string compared, and if both parts are equal, then the number
parts are compared numerically. A stream of just numbers or a stream of
just strings will sort correctly, and a mixed stream will sort with the
numbers first. Strings with a label and a number will sort in the
expected manner instead of lexically. Undefined values sort last.

=over 4

=item a

First item to compare.

=item b

Second item to compare.

=item RETURN

Returns a negative number if the first item should sort first (is less), a positive
number if the first item should sort second (is greater), and a zero if the items are
equal.

=back

=cut

sub Cmp {
    # Get the parameters.
    my ($a, $b) = @_;
    # Declare the return value.
    my $retVal;
    # Check for nulls.
    if (! defined($a)) {
        $retVal = (! defined($b) ? 0 : -1);
    } elsif (! defined($b)) {
        $retVal = 1;
    } else {
        # Here we have two real values. Parse the two strings.
        my @aParsed = _Parse($a);
        my @bParsed = _Parse($b);
        # Loop through the first string.
        while (! $retVal && @aParsed) {
            # Extract the string parts.
            my $aPiece = shift(@aParsed);
            my $bPiece = shift(@bParsed) || '';
            # Extract the number parts.
            my $aNum = shift(@aParsed);
            my $bNum = shift(@bParsed) || 0;
            # Compare the string parts insensitively.
            $retVal = (lc($aPiece) cmp lc($bPiece));
            # If they're equal, compare them sensitively.
            if (! $retVal) {
                $retVal = ($aPiece cmp $bPiece);
                # If they're STILL equal, compare the number parts.
                if (! $retVal) {
                    $retVal = $aNum <=> $bNum;
                }
            }
        }
    }
    # Return the result.
    return $retVal;
}

# This method parses an input string into a string parts alternating with
# number parts.
sub _Parse {
    # Get the incoming string.
    my ($string) = @_;
    # The pieces will be put in here.
    my @retVal;
    # Loop through as many alpha/num sets as we can.
    while ($string =~ /^(\D*)(\d+)(.*)/) {
        # Push the alpha and number parts into the return string.
        push @retVal, $1, $2;
        # Save the residual.
        $string = $3;
    }
    # If there's still stuff left, add it to the end with a trailing
    # zero.
    if ($string) {
        push @retVal, $string, 0;
    }
    # Return the list.
    return @retVal;
}


1;
