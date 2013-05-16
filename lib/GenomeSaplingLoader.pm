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

package GenomeSaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use MD5Computer;
    use base 'BaseSaplingLoader';

=head1 Sapling Genome Load Group Class

=head2 Introduction

The  Load Group includes all of the major genome-related tables.

=head3 new

    my $sl = GenomeSaplingLoader->new($erdb, $source, $options, @tables);

Construct a new GenomeSaplingLoader object.

=over 4

=item erdb

L<Sapling> object for the database being loaded.

=item options

Reference to a hash of command-line options.

=item tables

List of tables in this load group.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $options) = @_;
    # Create the table list.
    my @tables = sort qw(GenomeSet IsMadeUpOf IsCollectionOf Genome IsTaxonomyOf TaxonomicGrouping
                         TaxonomicGroupingAlias IsGroupFor Contig HasSection DNASequence);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the genome-related files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Process according to the type of section.
    if ($self->global()) {
        # This is the global section. Create the taxonomic hierarchy.
        $self->CreateTaxonomies();
        # Create the genome sets.
        $self->CreateGenomeSets();
    } else {
        # Get the section ID.
        my $genomeID = $self->section();
        # This is a genome section. Create the data for the genome.
        $self->PlaceGenome($genomeID);
    }
}

=head3 CreateGenomeSets

    $sl->CreateGenomeSets();

Generate the genome sets. This includes the GenomeSet and IsCollectionOf
tables.

=cut

sub CreateGenomeSets {
    # Get the parameters.
    my ($self) = @_;
    # Get the genome hash. Only genomes in this hash will be put into a set.
    my $sapling = $self->db();
    my $genomeHash = $sapling->GenomeHash();
    # We'll track genome set names in here. The set name is the most common
    # genus in the set with an optional number for uniqueness.
    my %setNames;
    # Get the genome set file.
    my $ih = Open(undef, "<$FIG_Config::global/genome.sets");
    # We will accumulate set data and output a set at the end of each set group.
    # This will be a list of genome IDs for the set.
    my @genomes;
    # This will contain the genus counts.
    my %names;
    # This will be the set ID number.
    my $setID;
    # Loop through the set file.
    while (! eof $ih) {
        # Get the next record.
        $self->Add("set-records" => 1);
        my ($newSetID, $genomeID, $name) = Tracer::GetLine($ih);
        # Only accept the genome if it's one of ours.
        if ($genomeHash->{$genomeID}) {
            # Is this a new set?
            if ($newSetID != $setID) {
                # Yes. Output the old set.
                $self->OutputGenomeSet(\%names, $setID, \@genomes);
                # Clear the set data.
                %names = ();
                @genomes = ();
                # Save the new set ID.
                $setID = $newSetID;
            }
            # Only proceed if this is one of our genomes.
            if ($genomeHash->{$genomeID}) {
                $self->Add("set-genomes" => 1);
                # Save the genome ID.
                push @genomes, $genomeID;
                # Remember it as the representative if it's the first in the set.
                # Count the genus.
                my ($genus) = split m/\s/, $name, 2;
                $names{$genus}++;
            }
        }
    }
    # Close the input file.
    close $ih;
    # Output the last set.
    $self->OutputGenomeSet(\%names, $setID, \@genomes);
}

=head3 OutputGenomeSet

    $sl->OutputGenomeSet(\%names, $setID, \@genomes);

Output the data for a genome set. The appropriate GenomeSet and IsCollectionOf
records will be generated for the genomes in the set.

=over 4

=item names

Reference to a hash of the genus names used in the set. The hash maps each name
to the number of times it appeared.

=item setID

The ID to use for this set.

=item genomes

Reference to a list of the IDs for the genomes in the set.

=back

=cut

sub OutputGenomeSet {
    # Get the parameters.
    my ($self, $names, $setID, $genomes) = @_;
    # Only proceed if there is at least one genome.
    my $count = scalar @$genomes;
    if ($count) {
        # Create the set record.
        $self->PutE(GenomeSet => $setID);
        # This will be TRUE for the first genome and FALSE thereafter, insuring that
        # the first genome is used for the representative.
        my $repFlag = 1;
        # Connect all the genomes to it.
        for my $genome (@$genomes) {
            $self->PutR(IsCollectionOf => $setID, $genome, representative => $repFlag);
            $repFlag = 0;
        }
    }
}


=head3 CreateTaxonomies

    $sl->CreateTaxonomies();

Generate the taxonomy hierarchy. This includes the TaxonomicGrouping,
IsGroupFor, TaxonomicGroupingAlias, and IsTaxonomyOf relationships. The
taxonomy hierarchy is computed from the NCBI taxonomy dump.

=cut

sub CreateTaxonomies {
    # Get the parameters.
    my ($self) = @_;
    # Get the Sapling object.
    my $sapling = $self->db();
    # Get the name of the taxonomy dump directory.
    my $taxDir = "/homes/parrello/Taxonomy"; # "/vol/biodb/ncbi/taxonomy";
    # The first step is to read in all the names. We will build a hash that maps
    # each taxonomy ID to a list of its names. The first scientific name encountered
    # will be saved as the primary name. Only scientific names, synonoyms, and
    # equivalent names will be kept.
    my (%nameLists, %primaryNames);
    my $ih = Open(undef, "<$taxDir/names.dmp");
    while (! eof $ih) {
        # Get the next name.
        my ($taxID, $name, undef, $type) = GetTaxData($ih);
        $self->Add('taxnames-in' => 1);
        # Is this a scientific name?
        if ($type =~ /scientific/i) {
            # Yes. Save it if it is the first for this ID.
            if (! exists $primaryNames{$taxID}) {
                $primaryNames{$taxID} = $name;
            }
            # Add it to the name list.
            push @{$nameLists{$taxID}}, $name;
            $self->Add('taxnames-scientific' => 1);
        } elsif ($type =~ /synonym|equivalent/i) {
            # Here it's not scientific, but it's generally useful, so we keep it.
            push @{$nameLists{$taxID}}, $name;
            $self->Add('taxnames-other' => 1);
        }
    }
    # Now we read in the taxonomy nodes. For each node, we generate a TaxonomicGrouping
    # record, and we connect it to its parent using IsGroupFor. We also keep the node ID
    # for later so we know what's available.
    close $ih;
    $ih = Open(undef, "<$taxDir/nodes.dmp");
    while (! eof $ih) {
        # Get the data for this group.
        my ($taxID, $parent, $type, undef, undef,
            undef,  undef,   undef, undef, undef, $hidden) = GetTaxData($ih);
        # Determine whether or not this is a domain group. A domain group is
        # terminal when doing taxonomy searches. The NCBI indicates a top-level
        # node by making it a child of the root node 1. We also include
        # super-kingdoms (archaea, eukaryota, bacteria), which are below cellular
        # organisms but are still terminal in our book.
        my $domain = ($type eq 'superkingdom') || ($parent == 1);
        # Get the node's name.
        my $name = $primaryNames{$taxID};
        # It's an error if there's no name.
        Confess("No name found for tax ID $taxID.") if ! $name;
        # Create the taxonomy group record.
        $self->PutE(TaxonomicGrouping => $taxID, domain => $domain, hidden => $hidden,
                    scientific_name => $name);
        # Create the alias records.
        for my $alias (@{$nameLists{$taxID}}) {
            $self->PutE(TaxonomicGroupingAlias => $taxID, alias => $alias);
        }
        # Connect the group to its parent.
        $self->PutR(IsGroupFor => $parent, $taxID);
    }
    # Read in the merge file. The merge file tells us which old IDs are mapped to
    # new IDs. We need this to connect genomes with old IDs to the correct group.
    my %merges;
    $ih = Open(undef, "<$taxDir/merged.dmp");
    while (! eof $ih) {
        # Get this merge record.
        my ($oldID, $newID) = GetTaxData($ih);
        # Store it in the hash.
        $merges{$oldID} = $newID;
    }
    # Now we need to connect each genome to its taxonomic grouping.
    # Get the genome hash. This gives us our list of genome IDs.
    my $genomeHash = $sapling->GenomeHash();
    # Loop through the genomes.
    for my $genomeID (keys %$genomeHash) {
        # Get this genome's taxonomic group.
        my ($taxID) = split m/\./, $genomeID, 2;
        # Check to see if we have this tax ID. If we don't, we check for a merge.
        if (! $primaryNames{$taxID}) {
            if ($merges{$taxID}) {
                $taxID = $merges{$taxID};
                $self->Add('merged-names' => 1);
                Trace("$genomeID has alternate taxonomy ID $taxID.") if T(ERDBLoadGroup => 2);
            } else {
                $taxID = undef;
                $self->Add('missing-groups' => 1);
                Trace("$genomeID has no taxonomy group.") if T(ERDBLoadGroup => 1);
            }
        }
        # Connect the genome and the group if the group is real.
        if (defined $taxID) {
            $self->PutR(IsTaxonomyOf => $taxID, $genomeID);
        }
    }
}


=head3 PlaceGenome

    $sl->PlaceGenome($genomeID);

Generate the data for a specific genome. This method generates data for
the Genome, IsMadeUpOf, Contig, HasSection, and DNASequence tables.

=over 4

=item genomeID

ID of the genome whose data is to be generated.

=back

=cut 

sub PlaceGenome {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Get the Sapling object.
    my $sapling = $self->db();
    # Get the source object.
    my $fig = $sapling->GetSourceObject();
    # Get the DNA chunk size.
    my $segmentLength = $sapling->TuningParameter('maxSequenceLength');
    Trace("DNA chunk size is $segmentLength.") if T(ERDBLoadGroup => 3);
    # We start with the genome record itself, asking the FIG object
    # for its various properties.
    my $scientific_name = $fig->genus_species($genomeID);
    my $complete = $fig->is_complete($genomeID);
    my $dna_size = $fig->genome_szdna($genomeID);
    my $pegs = $fig->genome_pegs($genomeID);
    my $rnas = $fig->genome_rnas($genomeID);
    my $domain = $fig->genome_domain($genomeID);
    my $prokaryotic = ($domain =~ /bacter|archae/i);
    # We need to compute the number of contigs from the list of contig IDs.
    my @contigIDs = $fig->contigs_of($genomeID);
    my $contigs = scalar(@contigIDs);
    # This will be used to compute the GC content.
    my $gc_count = 0;
    # Compute the genetic code. Normally, it's 11, but it may be overridden
    # by a GENETIC_CODE file.
    my $gcFile = "$FIG_Config::organisms/$genomeID/GENETIC_CODE";
    my $genetic_code = 11;
    if (-f $gcFile) {
        $genetic_code = Tracer::GetFile($gcFile);
        chomp $genetic_code;
    }
    # Start a genome descriptor.
    my $genomeMD5Thing = MD5Computer->new();
    # First we create the Contigs. Each one needs to be split into DNA sequences.
    for my $contigID (@contigIDs) {
        $self->Track(Contigs => $contigID, 100);
        # Get the contig length.
        my $length = $fig->contig_ln($genomeID, $contigID);
        # Compute the contig ID. Note that the contig ID includes
        # the genome ID as a prefix. Otherwise, it would be non-unique.
        my $realContigID = "$genomeID:$contigID";
        # The contig chunks will be gathered in here. At a later point we'll use
        # the chunks to compute the contig's MD5.
        my @dnaChunks;
        # Now we loop through the DNA chunks.
        my $loc = 1;
        my $ordinal = 0;
        while ($loc <= $length) {
            # Get this segment's true length.
            my $trueLength = Tracer::Min($length + 1 - $loc, $segmentLength);
            # Compute the index of this segment's last base pair.
            my $endPoint = $loc + $trueLength - 1;
            # Get the DNA.
            my $chunkDNA = $fig->get_dna($genomeID, $contigID, $loc, $endPoint);
            push @dnaChunks, $chunkDNA;
            # Count the GC content.
            $gc_count += ($chunkDNA =~ tr/gcGC//);
            # Create its sequence record.
            my $paddedOrdinal = Tracer::Pad($ordinal, 7, 1, '0');
            my $seqID = "$realContigID:$paddedOrdinal";
            $self->PutE(DNASequence => $seqID, sequence => $chunkDNA);
            $self->Add('dna-letters' => $trueLength);
            # Connect it to the contig.
            $self->PutR(HasSection => $realContigID, $seqID);
            # Move to the next section of the contig.
            $loc = $endPoint + 1;
            $ordinal++;
        }
        # Compute the contig MD5.
        my $contigMD5 = $genomeMD5Thing->ProcessContig($contigID, \@dnaChunks);
        # Create the contig record.
        $self->PutE(Contig => $realContigID, length => $length,
                    md5_identifier => $contigMD5);
        $self->PutR(IsMadeUpOf => $genomeID, $realContigID);
    }
    # Compute the genome MD5.
    my $genomeMD5 = $genomeMD5Thing->CloseGenome();
    # Write the genome record.
    $self->PutE(Genome => $genomeID, complete => $complete, contigs => $contigs,
                dna_size => $dna_size, scientific_name => $scientific_name,
                pegs => $pegs, rnas => $rnas, prokaryotic => $prokaryotic,
                domain => $domain, genetic_code => $genetic_code,
                md5_identifier => $genomeMD5, 
                gc_content => ($gc_count * 100 / $dna_size));
}

=head3 GetTaxData

    my @fields = GenomeSaplingLoader::GetTaxData($ih);

Read a taxonomy dump record and return its fields in a list. Taxonomy
dump records end in a tab-bar-newline sequence, and fields are separated
by a tab-bar-tab sequence, a more complex arrangement than is used in
standard tab-delimited files.

=over 4

=item ih

Open input handle for the taxonomy dump file.

=item RETURN

Returns a list of the fields in the record read.

=back

=cut

sub GetTaxData {
    # Get the parameters.
    my ($ih) = @_;
    # Temporarily change the end-of-record character.
    local $/ = "\t|\n";
    # Read the next record.
    my $line = <$ih>;
    # Chop off the end, if any.
    if ($line =~ /(.+)\t\|\n$/) {
        $line = $1;
    }
    # Split the line into fields.
    my @retVal = split /\t\|\t/, $line;
    # Return the result.
    return @retVal;
}


1;
