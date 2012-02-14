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

package GenomeSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSproutLoader';

=head1 Sprout Genome Load Group Class

=head2 Introduction

The  Load Group includes all of the major genome-related tables.

=head3 new

    my $sl = SproutLoader->new($erdb, $source, $options, @tables);

Construct a new SproutLoader object.

=over 4

=item erdb

[[SproutPm]] object for the database being loaded.

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
    my @tables = sort qw(Genome HasContig Contig IsMadeUpOf Sequence Host IsPathogenicIn
                         IsRepresentativeOf);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
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
    # Get the section ID.
    my $genomeID = $self->section();
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG object.
    my $fig = $self->source();
    # Only proceed if we're not the global section.
    if (! $self->global()) {
        # Get the genus, species, and strain from the scientific name.
        my $scientificName = $fig->genus_species($genomeID);
        my ($genus, $species, $extra) = split / /, $scientificName, 3;
        # Get the full taxonomy.
        my $taxonomy = $fig->taxonomy_of($genomeID);
        # Get the version. If no version is specified, we default to the genome ID by itself.
        my $version = $fig->genome_version($genomeID);
        if (! defined($version)) {
            $version = $genomeID;
        }
        # Get the group hash and compute our group name.
        my $group;
        my $superGroup = $sprout->SuperGroup("$genus $species");
        if (! $superGroup) {
            # Here we have a supporting genome.
            $group = $FIG_Config::otherGroup;
        } else {
            # Now we have an NMPDR genome. Compute the group name. The group name
            # is either "other XXXX" or "XXXX YYYY" where XXXX is the genus and
            # YYYY is the species. The species is used if it's in the special-species
            # list.
            my %groupHash = $sprout->CheckGroupFile();
            if (exists $groupHash{$superGroup}->{specials}->{$species}){
                $group = "$genus $species";
            } else {
                $group = "other $genus";
            }
        }
        # Get the version-numbered ID. If there is none, we just use the genome.
        my $genomeVersion = $fig->genome_version($genomeID) || $genomeID;
        # Get the contigs.
        my @contigs = $fig->all_contigs($genomeID);
        Trace(scalar(@contigs) . " contigs found for $genomeID.") if T(ERDBLoadGroup => 3);
        # Now come some attribute-related values. We create a hash of the genome's
        # attributes.
        my %attributes = map { $_->[1] => $_->[2] } $fig->get_attributes($genomeID);
        # The first attribute is the pathogenic host list. Note we have to get rid
        # of the value "No", which we treat as not being connected to any host.
        my @hosts = grep { $_ ne 'No' } split /\s*,\s*/, ($attributes{Pathogenic_In} || "");
        for my $host (@hosts) {
            $self->PutE(Host => $host);
            $self->PutR(IsPathogenicIn => $genomeID, $host);
        }
        # Next is the gram stain, which must be converted to semi-boolean.
        my $gram_stain = $attributes{Gram_Stain};
        if ($gram_stain =~ /positive/i) {
            $gram_stain = 'Y';
        } elsif ($gram_stain =~ /negative/i) {
            $gram_stain = 'N';
        } else {
            $gram_stain = '?'
        }
        # The temperature range needs to be split in two. The default is 0 to 100.
        my ($tempRangeMin, $tempRangeMax);
        my $tempRange = $attributes{Temperature_Range};
        if (! defined $tempRange) {
            ($tempRangeMin, $tempRangeMax) = (0,100);
        } elsif ($tempRange =~ /^\d+$/) {
            ($tempRangeMin, $tempRangeMax) = ($tempRange, $tempRange);
        } elsif ($tempRange =~ /^(\d+)-(\d+)$/) {
            ($tempRangeMin, $tempRangeMax) = ($1, $2);
        } else {
            ($tempRangeMin, $tempRangeMax) = (0, 100);
        }
        # These attributes are all simple.
        my $endospore = ERDBTypeSemiBoolean::ComputeFromString($attributes{Endospores});
        my $motility = ERDBTypeSemiBoolean::ComputeFromString($attributes{Motility});
        my $oxygen = $attributes{Oxygen_Requirement} || "unknown";
        my $optimalTempRange = $attributes{Temperature_Range} || "unknown";
        my $pathogenic = ERDBTypeSemiBoolean::ComputeFromString($attributes{Pathogenic});
        my $salinity = $attributes{Salinity} || "unknown";
        my $habitat = $attributes{Habitat} || "unknown";
        # We need to find the representative genome. That's not simple, because the
        # representative has to be one of ours, and the SEED rep may not be.
        # To solve this problem, we read in the entire genome set file. For each
        # set, we stash the first eligible genome in a hash, and when we find
        # our genome, we'll get the saved representative.
        my (%repHash, $repGenome);
        my %eligibleGenomes = map { $_ => 1 } BaseSproutLoader::GetSectionList($sprout, $fig);
        my $ih = Open(undef, "<$FIG_Config::data/Global/genome.sets");
        while (! eof $ih && ! defined $repGenome) {
            my ($set, $member) = Tracer::GetLine($ih);
            # Only process our genomes.
            if ($eligibleGenomes{$member}) {
                # If this is the first eligible genome for the set, remember it.
                if (! exists $repHash{$set}) {
                    $repHash{$set} = $member;
                }
                # If this is our genome, we're done.
                if ($member eq $genomeID) {
                    $repGenome = $repHash{$set};
                }
            }
        }
        close $ih;
        # If we found a representative, save it.
        if (defined $repGenome) {
            $self->PutR(IsRepresentativeOf => $repGenome, $genomeID);
        }
        # Now we loop through each of the genome's contigs. While doing so, we'll
        # track the GC content and DNA size.
        my $gc_content = 0;
        my $dnaSize = 0;
        for my $contigID (@contigs) {
            Trace("Processing contig $contigID for $genomeID.") if T(4);
            $self->Track(Contigs => $contigID, 100);
            $self->Add(contigIn => 1);
            # Create the contig ID.
            my $sproutContigID = "$genomeID:$contigID";
            # Get the contig length.
            my $contigLen = $fig->contig_ln($genomeID, $contigID);
            # Create the contig record and relate it to the genome.
            $self->PutE(Contig => $sproutContigID, length => $contigLen);
            $self->PutR(HasContig => $genomeID, $sproutContigID);
            # Now we need to split the contig into sequences. The maximum sequence size is
            # a property of the Sprout object.
            my $chunkSize = $sprout->MaxSequence();
            # Now we get the sequence a chunk at a time.
            for (my $i = 1; $i <= $contigLen; $i += $chunkSize) {
                $self->Add(chunkIn => 1);
                # Compute the endpoint of this chunk.
                my $end = FIG::min($i + $chunkSize - 1, $contigLen);
                # Get the actual DNA.
                my $dna = $fig->get_dna($genomeID, $contigID, $i, $end);
                # Compute the stats.
                my $chunkLen = length($dna);
                my $chunkGC = length(join("", split /[^gc]+/, $dna));
                $gc_content += $chunkGC;
                $dnaSize += $chunkLen;
                # Compute the sequenceID.
                my $seqID = "$sproutContigID.$i";
                # Write out the data. For now, the quality vector is always "unknown".
                $self->PutR(IsMadeUpOf => $sproutContigID, $seqID, len => ($end + 1 - $i),
                           'start-position' => $i);
                $self->PutE(Sequence => $seqID, 'quality-vector' => "unknown", sequence => $dna);
                $self->Add('dna-letters' => $chunkLen);
            }
        }
        # Finalize the GC content computation.
        $gc_content = $gc_content * 100 / $dnaSize;
        # Output the genome record.
        $self->PutE(Genome => $genomeID, complete => $fig->is_complete($genomeID),
                   contigs => scalar(@contigs), dna_size => $dnaSize,
                   genus => $genus, pegs => $fig->genome_pegs($genomeID),
                   primary_group => $group, rnas => $fig->genome_rnas($genomeID),
                   species => $species, unique_characterization => $extra,
                   version => $genomeVersion, taxonomy => $taxonomy,
                   endospore => $endospore, gc_content => $gc_content,
                   gram_stain => $gram_stain, motility => $motility,
                   oxygen => $oxygen, optimal_temperature_range => $optimalTempRange,
                   pathogenic => $pathogenic, salinity => $salinity,
                   temperature_min => $tempRangeMin, temperature_max => $tempRangeMax,
                   habitat => $habitat, scientific_name => $scientificName);
    }
}


1;
