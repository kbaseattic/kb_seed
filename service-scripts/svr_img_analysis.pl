#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use ScriptThing;
use MD5Computer;
use SeedUtils;

#
#	This is a SAS Component.
#

=head1 svr_img_analysis

    svr_img_analysis <directory>

Read an IMG genome directory and compare it to the corresponding Sapling genomes
(if any). The single positional parameter is the IMG genome directory name. Note
that the last level of the directory name must also be the IMG genome number.
In other words, if the directory name is B<~/genomes/IMG/637000001>, then
the genome name must be B<637000001>.

This method imports an IMG genome into memory and then performs a gene-to-gene comparison
between it and each Sapling genome with the same contigs. It produces a report on
how many genes are found in both, which genes are only found in the Sapling genome,
and which genes are only found in the IMG genome.

The key files in the IMG directory are the B<*.fna> file, which is a FASTA file
containing the contigs, and the B<*.genes.tab.txt> file, which is a tab-delimited
file describing the genes. An MD5 identifier is produced for each of these genes
and the MD5s are used to map the genes between the IMG and Sapling genomes.

Currently, this is all done in memory, which may be a strain for eukaryotic genomes.

The report is produced to the standard output.

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item recursive

If this option is specified, then the command-line parameter is treated as a
directory of IMG genome directories instead of a single IMG genome directory.
Use this option to batch-process a large number of genomes.

=item terse

If this option is specified, then only statistical information will be output.
Detailed descriptions of which genes and proteins do not match will not be
output.

=back

=cut

# Parse the command-line options.
my $url = '';
my $recursive;
my $terse;
my $opted =  GetOptions('url=s' => \$url, 'recursive' => \$recursive, 'terse' => \$terse);
# Get the directory name.
my $mainDirectory = $ARGV[0];
# Print the signature if we have invalid arguments.
if (! $opted || ! $mainDirectory) {
    print "usage: svr_img_analysis [--url=http://...] [-terse] [-recursive] directory";
} else {
    # Get the server object.
    my $sapObject = SAPserver->new(url => $url);
    # Clean off the trailing slash from the directory name.
    $mainDirectory =~ s/[\/\\]$//;
    # We'll put all the genome directories we're processing in here.
    my @imgDirectories;
    # Check for the mode: direct or recursive.
    if (! $recursive) {
        # Direct mode. Process the incoming directory.
        push @imgDirectories, $mainDirectory;
    } elsif (-d $mainDirectory) {
        # Recursive mode. Process the subdirectories.
        if (opendir(my $dh, $mainDirectory)) {
            my @genomes = grep { $_ =~ /^\d+$/ } readdir $dh;
            push @imgDirectories, map { "$mainDirectory/$_" } @genomes;
        }
    } else {
        die "$mainDirectory not found or not a directory.";
    }
    for my $imgDirectory (@imgDirectories) {
        # Get the genome ID by reading the directory name.
        $imgDirectory =~ /([^\/\\]+)$/;
        my $imgGenomeID = $1;
        # Verify that the genome directory is correctly formatted.
        my $fastaFileName = "$imgDirectory/$imgGenomeID.fna";
        my $geneFileName = "$imgDirectory/$imgGenomeID.genes.tab.txt";
        my $protFileName = "$imgDirectory/$imgGenomeID.genes.faa";
        if (! -d $imgDirectory || ! -f $fastaFileName || ! -f $geneFileName ||
            ! -f $protFileName) {
            print STDERR "$imgDirectory does not appear to be a valid IMG genome directory.\n";
        } else {
            # We have what we need to process the IMG directory. Start by creating a
            # descriptor of the genome and its contigs.
            my $imgDescriptor = MD5Computer->new_from_fasta($fastaFileName);
            # Read the first line of the FASTA to get the genome name and display it.
            open my $fh, "<$fastaFileName";
            my $header = <$fh>;
            chomp $header;
            if ($header =~ /^>\S+\s+([^,]+)/) {
                print "Genome $imgGenomeID is $1.\n";
            }
            close $fh;
            # Now we read in the genes and create a hash of genes to MD5s. The hash will
            # go in here.
            my %imgGenes;
            # This hash will track the number of times each gene is found in the Sapling.
            my %imgGenesFound;
            # Open the gene file.
            open my $ih, "<$geneFileName" || die "Could not open IMG gene file: $!";
            # Discard the title line.
            my $line = <$ih>;
            # Loop through the rest of the file.
            while (! eof $ih) {
                # Read the next gene.
                $line = <$ih>;
                chomp $line;
                my ($geneID, $start, $end, $strand, undef, $type, undef, undef, $function, $contig) =
                    split /\t/, $line;
                # Delete the genome name from the contig.
                $contig =~ /:\s*([^:]+)$/;
                $contig = $1;
                # Create the location string for this gene.
                my $len = $end - $start + 1;
                my $begin = ($strand eq '+' ? $start : $end);
                my $loc = "${contig}_$begin$strand$len";
                # Translate the gene type.
                my $realType = ($type eq 'CDS' ? 'peg' : $type =~ /RNA/ ? 'rna' : 'misc');
                # Compute the gene's MD5 and store it in the hash along with the location.
                # We will need the location if the gene is not found in the Sapling.
                my $geneMD5 = $imgDescriptor->ComputeFeatureMD5($realType, $loc);
                $imgGenes{$geneID} = [$geneMD5, $loc];
                $imgGenesFound{$geneID} = 0;
            }
            # Get the matching genomes in the Sapling.
            my $genomeMD5 = $imgDescriptor->genomeMD5;
            my $genomeHash = $sapObject->genomes_by_md5(-ids => $genomeMD5);
            my @genomes = @{$genomeHash->{$genomeMD5}};
            print scalar(@genomes) . " genomes found in Sapling for $imgGenomeID.\n";
            for my $genome (@genomes) {
                print "Analysis for $genome.\n";
                # Get the hash of FIG IDs to MD5s for this genome.
                $genomeHash = $sapObject->genome_fid_md5s(-ids => $genome);
                my $geneHash = $genomeHash->{$genome};
                # Reverse it to create a hash that enables us to bridge between the
                # IMG data and ours.
                my %fidGenes = map { $geneHash->{$_} => $_ } keys %$geneHash;
                # Get the hash of contig MD5s for this genome.
                my $contigMD5Hash = $sapObject->genome_contig_md5s(-ids => $genome);
                $contigMD5Hash = $contigMD5Hash->{$genome};
                # Reverse it to create a hash the maps contig MD5s to contig IDs.
                my %md5ToContig = map { $contigMD5Hash->{$_} => $_ } keys %$contigMD5Hash;
                # Release the memory for the hashes that we don't need any more.
                undef $geneHash;
                undef $genomeHash;
                undef $contigMD5Hash;
                # Genes in the Sapling genome that are close to genes in the IMG genome
                # will be tracked in here.
                my %closeGenes;
                # This will hold the number of genes found in both genomes.
                my $matching = 0;
                # This will hold the number of genes not found in the Sapling.
                my $notFound = 0;
                # This will hold the number of genes with close locations in the Sapling.
                my $closeFound = 0;
                # This will hold the number of genes which are close with the same stop in
                # the Sapling.
                my $startChangeFound = 0;
                # Loop through the IMG data, finding matching Sapling features. We delete
                # each feature that we find, and then what remains is the Sapling stuff
                # that doesn't have a match on the IMG side.
                for my $geneID (sort keys %imgGenes) {
                    # Get this gene's MD5.
                    my $geneMD5 = $imgGenes{$geneID}[0];
                    # Check for it in the Sapling hash.
                    if ($fidGenes{$geneMD5}) {
                        # We found it, so record a match.
                        $matching++;
                        $imgGenesFound{$geneID}++;
                        # Delete it from the Sapling Hash.
                        delete $fidGenes{$geneMD5};
                    } else {
                        # Not a match. Get this gene's location in the IMG genome.
                        my $geneLoc = $imgGenes{$geneID}[1];
                        # Convert the location to a Sapling equivalent.
                        my ($imgContigID, $imgBegin, $imgEnd, $imgStrand) = parse_location($geneLoc);
                        my $contigMD5 = $imgDescriptor->contigMD5($imgContigID);
                        my $sapContigID = $md5ToContig{$contigMD5};
                        my $sapLoc = join("_", $sapContigID , $imgBegin, $imgEnd);
                        # Now look for the genes in this region.
                        my $genesInRegionHash = $sapObject->genes_in_region(-locations => $sapLoc,
                                                                            -includeLocation => 1);
                        my $regionHash = $genesInRegionHash->{$sapLoc};
                        # Search for the best match. We allow a maximum error of 1000 bases.
                        my $bestDistance = 1000;
                        my $bestFid;
                        my $bestLoc;
                        my $sameStop;
                        # Of course, we only search if we found genes in the region.
                        if (defined $regionHash) {
                            for my $fid (keys %$regionHash) {
                                # Parse this feature's location string.
                                my $fidLoc = $regionHash->{$fid}[0];
                                my ($fidContigID, $fidBegin, $fidEnd, $fidStrand) = parse_location($fidLoc);
                                # Compute the distance: twice the stop difference plus the
                                # start difference.
                                my $distance = 2 * abs($fidEnd - $imgEnd) + abs($fidBegin - $imgBegin);
                                # If this is a better match, keep it.
                                if ($distance < $bestDistance) {
                                    $bestFid = $fid;
                                    $bestDistance = $distance;
                                    $bestLoc = $fidLoc;
                                    $sameStop = ($fidEnd == $imgEnd);
                                }
                            }
                        }
                        # Did we find a match?
                        if ($sameStop) {
                            if (! $terse) {
                                print "  $geneID ($geneLoc) has a different start from $bestFid ($bestLoc).\n";
                            }
                            $startChangeFound++;
                            $closeGenes{$bestFid} = 1;
                        } elsif ($bestFid) {
                            if (! $terse) {
                                print "  $geneID ($geneLoc) is close to $bestFid ($bestLoc).\n";
                            }
                            $closeFound++;
                            $closeGenes{$bestFid} = 1;
                        } else {
                            if (! $terse) {
                                print "  $geneID not found in Sapling.\n";
                            }
                            $notFound++;
                        }
                    }
                }
                # Now we want to list the genes not found in IMG.
                my $sapOnly = 0;
                for my $md5 (keys %fidGenes) {
                    my $fid = $fidGenes{$md5};
                    if (! $closeGenes{$fid}) {
                        if (! $terse) {
                            print "  $fid not found in IMG.\n";
                        }
                        $sapOnly++;
                    }
                }
                # Display the gene statistics.
                print "$matching found in both, $notFound in IMG and not Sapling, $closeFound in IMG with close analogs in Sapling, " .
                      "$startChangeFound in IMG with a different start and the same stop in Sapling, " .
                      "$sapOnly in Sapling and not IMG.\n";
            }
            print "Protein analysis.\n";
            # Finally, we want to run through the proteins in the IMG genome and find
            # the ones that aren't in the Sapling. Get a hash for the protein FASTA.
            my $protHash = $imgDescriptor->ProcessProteinFASTA($protFileName);
            # Now we create a list of the MD5s for genes that were not found in the Sapling
            # genomes. Note we have to deal with the possibility that some not-found
            # genes do not produce proteins and won't appear in $protHash.
            my @notFoundImgGenes = grep { ! $imgGenesFound{$_} && exists $protHash->{$_} } keys %imgGenesFound;
            my @md5List = map { $protHash->{$_} } @notFoundImgGenes;
            # Try to find Sapling genes for these proteins.
            my $protsInSapling = $sapObject->proteins_to_fids(-prots => \@md5List);
            # This will count the proteins not found.
            my $missingProteins = 0;
            # Loop through the not-found IMG genes, looking for proteins without matching
            # Sapling features.
            for my $imgGene (@notFoundImgGenes) {
                # Get the FIDs for this protein.
                my $fidList = $protsInSapling->{$imgGene};
                # If this is a protein and no FIDs were found, record the fact.
                if (! $fidList || ! @$fidList) {
                    if (! $terse) {
                        print "  $imgGene produces a protein not found in Sapling.\n";
                    }
                    $missingProteins++;
                }
            }
            # Output the number of missing proteins.
            print "$missingProteins genes produce proteins not found in Sapling.\n\n";
        }
    }
}
