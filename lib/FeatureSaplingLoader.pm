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

package FeatureSaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use CGI qw(-nosticky);
    use BasicLocation;
    use HyperLink;
    use AliasAnalysis;
    use LoaderUtils;
    use SeedUtils;
    use gjoseqlib;
    use MD5Computer;
    use base 'BaseSaplingLoader';

=head1 Sapling Feature Load Group Class

=head2 Introduction

The Feature Load Group includes all of the major feature-related tables.

=head3 new

    my $sl = FeatureSaplingLoader->new($erdb, $options, @tables);

Construct a new FeatureSaplingLoader object.

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
    my @tables = sort qw(Feature FeatureEssential FeatureEvidence FeatureLink
                         FeatureVirulent IsOwnerOf IsLocatedIn IsIdentifiedBy
                         Identifier IsNamedBy ProteinSequence Concerns
                         IsAttachmentSiteFor Publication IsProteinFor
                         Role RoleIndex IsFunctionalIn);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the feature-related files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the database object.
    my $erdb = $self->db();
    # Check for local or global.
    if (! $self->global()) {
        # Here we are generating data for a genome.
        my $genomeID = $self->section();
        # Load this genome's features.
        $self->LoadGenomeFeatures($genomeID);
    } else {
        # The global data is the roles from subsystems and the publications.
        my $fig = $self->source();
        # We need the master map of roles to IDs.
        my %roleHash;
        my $lastRoleIndex = -1;
        my $roleMapFile = $erdb->LoadDirectory() . "/roleMap.tbl";
        if (-f $roleMapFile) {
            for my $mapLine (Tracer::GetFile($roleMapFile)) {
                my ($role, $idx) = split /\t/, $mapLine;
                $roleHash{$role} = $idx;
                if ($idx > $lastRoleIndex) {
                    $lastRoleIndex = $idx;
                }
            }
        }
        # We'll track duplicate roles in here.
        my %roleList;
        # Now we get the subsystem list.
        my $subHash = $erdb->SubsystemHash();
        for my $sub (sort keys %$subHash) {
            $self->Add(subsystems => 1);
            Trace("Processing roles for $sub.") if T(3);
            # Get this subsystem's roles and write them out.
            my @roles = $fig->subsystem_to_roles($sub);
            for my $role (@roles) {
                $self->Add(subsystemRoles => 1);
                # Check to see if this role is hypothetical.
                my $hypo = hypo($role);
                if (! $hypo) {
                    # Is this role in the role index hash?
                    my $roleIndex = $roleHash{$role};
                    if (! defined $roleIndex) {
                        # No, compute a new index for it.
                        $roleIndex = ++$lastRoleIndex;
                        $roleHash{$role} = $roleIndex;
                    }
                    if (! $roleList{$role}) {
                        $roleList{$role} = 1;
                        $self->PutE(RoleIndex => $role, role_index => $roleIndex);
                    }
                }
                $self->PutE(Role => $role, hypothetical => $hypo);
            }
        }
        Trace("Subsystem roles generated.") if T(2);
        # Write out the role master file.
        Tracer::PutFile($roleMapFile, [map { "$_\t$roleHash{$_}" } keys %roleHash]);
        Trace("Role master file written to $roleMapFile.") if T(2);
        # Now, we get the publications.
        my $pubs = $fig->all_titles();
        for my $pub (@$pubs) {
            # Get the ID and title.
            my ($pubmedID, $title) = @$pub;
            # Only proceed if the ID is valid.
            if ($pubmedID) {
                # Create a hyperlink from the title and the pubmed ID.
                my $link;
                if (! $title) {
                    $link = HyperLink->new("<unknown>");
                } else {
                    $link = HyperLink->new($title, "http://www.ncbi.nlm.nih.gov/pubmed/$pubmedID");
                }
                # Create the publication record.
                $self->PutE(Publication => $pubmedID, citation => $link);
            }
        }
        Trace("Publications generated.") if T(2);
    }
}

=head3 LoadGenomeFeatures

    $sl->LoadGenomeFeatures($genomeID);

Load the feature-related data for a single genome.

=over 4

=item genomeID

ID of the genome whose feature data is to be loaded.

=back

=cut

sub LoadGenomeFeatures {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Get the source object.
    my $fig = $self->source();
    # Get the database.
    my $sapling = $self->db();
    # Get the maximum location  segment length. We'll need this later.
    my $maxLength = $sapling->TuningParameter('maxLocationLength');
    # Get the genome's aliases.
    my $aliasDir = $sapling->LoadDirectory() . "/AliasData";
    my $aliasHash = LoaderUtils::ReadAliasFile($aliasDir, $genomeID);
    if (! defined $aliasHash) {
        Trace("No aliases found for $genomeID.") if T(ERDBLoadGroup => 1);
        $self->Add(missingAliasFile => 1);
        $aliasHash = {};
    }
    # Get all of this genome's protein sequences.
    my %seqs = map { $_->[0] => $_->[2] } gjoseqlib::read_fasta("$FIG_Config::organisms/$genomeID/Features/peg/fasta");
    # Get all of this genome's features.
    my $featureList = $fig->all_features_detailed_fast($genomeID);
    # Loop through them.
    for my $feature (@$featureList) {
        # Get this feature's data.
        my ($fid, $locationString, $aliases, $type, undef, undef, $assignment,
            $assignmentMaker, $quality) = @$feature;
        $self->Track(Features => $fid, 1000);
        # Fix missing assignments. For RNAs, the assignment may be in the alias list.
        if (! defined $assignment) {
            if ($type eq 'rna') {
                $assignment = $aliases;
                $assignmentMaker ||= 'master';
            } else {
                $assignment = '';
            }
        }
        # Convert the location string to a list of location objects.
        my @locs = map { BasicLocation->new($_) } split /\s*,\s*/, $locationString;
        # Now we need to run through the locations. We'll put the total sequence
        # length in here.
        my $seqLen = 0;
        # This will track the ordinal position of the current location segment.
        my $locN = 1;
        # Loop through the location objects.
        for my $loc (@locs) {
            # Add this location's length to the total length.
            $seqLen += $loc->Length();
            # Extract the contig ID. Note that we need to prefix the
            # genome ID to make it unique.
            my $contig = $loc->Contig();
            my $contigID = "$genomeID:$contig";
            # We also need the location's direction.
            my $dir = $loc->Dir();
            # Now we peel off sections of the location and connect them
            # to the feature.
            my $peel = $loc->Peel($maxLength);
            while (defined $peel) {
                $self->PutR(IsLocatedIn => $fid, $contigID, ordinal => $locN++,
                            begin => $peel->Left(), len => $peel->Length(),
                            dir => $dir);
                $peel = $loc->Peel($maxLength);
            }
            # Output the residual. There will always be one, because of the way
            # Peel works.
            $self->PutR(IsLocatedIn => $fid, $contigID, ordinal => $locN,
                        begin => $loc->Left(), dir => $dir, len => $loc->Length());
        }
        # Is this an attachment site?
        if ($type eq 'att') {
            # Yes, connect it to the attached feature.
            if ($assignment =~ /att([LR])\s+for\s+(fig\|.+)/) {
                $self->PutR(IsAttachmentSiteFor => $fid, $2, edge => $1);
            } else {
                Trace("Invalid attachment function for $fid: $assignment") if T(ERDBLoadGroup => 1);
                $self->Add(badAttachment => 1);
            }
        }
        # Emit the feature record.
        $self->PutE(Feature => $fid, feature_type => $type,
                    sequence_length => $seqLen, function => $assignment,
                    locked => $fig->is_locked_fid($fid));
        # Connect the feature to its genome.
        $self->PutR(IsOwnerOf => $genomeID, $fid);
        # Connect the feature to its roles.
        my ($roles, $errors) = SeedUtils::roles_for_loading($assignment);
        if (! defined $roles) {
            # Here the functional assignment was suspicious.
            $self->Add(suspiciousFunction => 1);
            Trace("$fid has a suspicious function: $assignment") if T(ERDBLoadGroup => 1);
        } else {
            # Here we have a good assignment.
            for my $role (@$roles) {
                $self->Add(featureRole => 1);
                $self->PutR(IsFunctionalIn => $role, $fid);
                $self->PutE(Role => $role, hypothetical => hypo($role));
            }
            $self->Add(badFeatureRoles => $errors);
        }
        # Now we have a whole bunch of attribute-related stuff to store in
        # secondary Feature tables. First is the evidence codes. This is special
        # because we have to save the DLIT numbers.
        my @dlits;
        my @evidenceTuples = $fig->get_attributes($fid, 'evidence_code');
        for my $evidenceTuple (@evidenceTuples) {
            my (undef, undef, $code) = @$evidenceTuple;
            $self->PutE(FeatureEvidence => $fid, 'evidence-code' => $code);
            # If this is a direct literature reference, save it.
            if ($code =~ /dlit\((\d+)/) {
                push @dlits, $1;
                $self->Add(dlits => 1);
            }
        }
        # Now we have the external links. These are stored using hyperlink objects.
        my @links = $fig->fid_links($fid);
        for my $link (@links) {
            my $hl = HyperLink->newFromHtml($link);
            $self->PutE(FeatureLink => $fid, link => $hl);
        }
        # Virulence data is next. This is also hyperlink data.
        my @virulenceTuples = $fig->get_attributes($fid, 'virulence_associated%');
        for my $virulenceTuple (@virulenceTuples) {
            my (undef, undef, $text, $url) = @$virulenceTuple;
            my $hl = HyperLink->new($text, $url);
            $self->PutE(FeatureVirulent => $fid, virulent => $hl);
        }
        # Finally, the essentiality stuff, which is the last of the hyperlinks.
        my @essentials = $fig->get_attributes($fid, undef, ['essential', 'potential-essential']);
        for my $essentialTuple (@essentials) {
            my (undef, undef, $essentialityType, $url) = @$essentialTuple;
            # Only keep this datum if it has a URL. The ones without URLs are
            # all duplicates.
            if ($url) {
                # Form a hyperlink from this essentiality tuple.
                my $link = HyperLink->new($essentialityType, $url);
                # Store it as essentiality data for this feature.
                $self->PutE(FeatureEssential => $fid, essential => $link);
            }
        }
        # If this is a PEG, we have a protein sequence.
        my $proteinID;
        if ($type eq 'peg') {
            # Get the translation.
            my $proteinSequence = $seqs{$fid};
            if (! $proteinSequence) {
                Trace("No protein sequence found for $fid.") if T(ERDBLoadGroup => 2);
                $self->Add(missingProtein => 1);
                # Here there was some sort of error and the protein sequence did
                # not come back. Ask for the DNA and translate it instead.
                my $dna = $fig->get_dna_seq($fid);
                $proteinSequence = FIG::translate($dna, undef, 1);
            }
            # Compute the ID.
            $proteinID = $sapling->ProteinID($proteinSequence);
            # Create the protein record.
            $self->PutE(ProteinSequence => $proteinID, sequence => $proteinSequence);
            $self->PutR(IsProteinFor => $proteinID, $fid);
            # Connect this protein to the feature's publications (if any).
            for my $pub (@dlits) {
                $self->PutR(Concerns => $pub, $proteinID);
            }
        }
        # Now we need to compute the identifiers. We start with the aliases.
        # Get the alias data for this feature. If there is none, we force an
        # empty list.
        my $aliasList = $aliasHash->{$fid} || [];
        # Loop through the aliases found.
        for my $aliasTuple (@$aliasList) {
            my ($aliasID, $aliasType, $aliasConf) = @$aliasTuple;
            # Get the natural form. If there is none, then the canonical
            # form IS the natural form. Note we have to make a special check
            # for locus tags, which have an insane number of variants.
            my $natural;
            if ($aliasID =~ /LocusTag:(.+)/) {
                $natural = $1;
            } else {
                $natural = AliasAnalysis::Type($aliasType => $aliasID) || $aliasID;
            }
            # Create the identifier record.
            $self->PutE(Identifier => $aliasID, natural_form => $natural,
                        source => $aliasType);
            # Is this a protein alias?
            if ($aliasConf eq 'C' && $proteinID) {
                # Yes. Connect it using IsNamedBy.
                $self->PutR(IsNamedBy => $proteinID, $aliasID);
            } else {
                # No. Connect it to the feature.
                $self->PutR(IsIdentifiedBy => $fid, $aliasID, conf => $aliasConf);
            }
        }
        # Finally, this feature is an alias of itself.
        $self->PutE(Identifier => $fid, natural_form => $fid,
                    source => 'SEED');
        $self->PutR(IsIdentifiedBy => $fid, $fid, conf => 'A');
    }
}


1;