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

package FeatureSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use BioWords;
    use AliasAnalysis;
    use DBMaster;
    use HyperLink;
    use FFs;
    use SOAP::Lite;
    use Time::HiRes;
    use LoaderUtils;
    use base 'BaseSproutLoader';

=head1 Sprout Feature Load Group Class

=head2 Introduction

The Feature Load Group includes all of the major feature-related tables.

=head3 new

    my $sl = FeatureSproutLoader->new($erdb, $source, $options, @tables);

Construct a new FeatureSproutLoader object.

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
    my @tables = sort qw(Feature IsLocatedIn FeatureAlias IsAliasOf FeatureLink
                         FeatureTranslation FeatureUpstream HasFeature HasRoleInSubsystem
                         FeatureEssential FeatureVirulent FeatureIEDB CDD
                         IsPresentOnProteinOf CellLocation IsPossiblePlaceFor
                         IsAlsoFoundIn ExternalDatabase Keyword ProteinFamily
                         IsFamilyForFeature ProteinFamilyName FeatureEC);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
    # Get the list of relevant attributes.
    # Bless and return it.
    bless $retVal, $class;
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
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG object.
    my $fig = $self->source();
    # Get the subsystem list.
    my $subHash = $self->GetSubsystems();
    # Get the word stemmer.
    my $stemmer = $sprout->GetStemmer();
    # Get access to FIGfams.
    my $figfam_data = &FIG::get_figfams_data();
    my $ffs = new FFs($figfam_data, $fig);
    # Compute the load directory.
    my $loadDirectory = $sprout->LoadDirectory();
    # Only proceed if this is not the global section.
    if (! $self->global()) {
        # Get the section ID.
        my $genomeID = $self->section();
        MemTrace("Starting section $genomeID.") if T(ERDBLoadGroup => 3);
        # Connect to the ontology database.
        my $sqlite_db = "/home/mkubal/Temp/Ontology/ontology.sqlite";
        my $ontology_dbmaster = DBMaster->new(-database => $sqlite_db, -backend => 'SQLite');
        # This is our master hash of FIG IDs to aliases.
        my $aliasMasterHash = LoaderUtils::ReadAliasFile($loadDirectory, $genomeID) || {};
        # Get the maximum sequence size. We need this later for splitting up the
        # locations.
        my $chunkSize = $sprout->MaxSegment();
        MemTrace("Loading features for genome $genomeID.") if T(ERDBLoadGroup => 3);
        # Get the feature list for this genome.
        my $features = $fig->all_features_detailed_fast($genomeID);
        # Sort and count the list.
        my @featureTuples = sort { $a->[0] cmp $b->[0] } @{$features};
        my $count = scalar @featureTuples;
        MemTrace("$count features found for genome $genomeID.") if T(ERDBLoadGroup => 3);
        # Get the attributes for this genome and put them in a hash by feature ID.
        my $attributes = $self->GetGenomeAttributes($genomeID, \@featureTuples);
        Trace("Looping through features for $genomeID.") if T(ERDBLoadGroup => 3);
        # Loop through the features.
        for my $featureTuple (@featureTuples) {
            # Split the tuple.
            my ($featureID, $locations, $aliases, $type, $minloc, $maxloc, $assignment,
                $user, $quality) = @{$featureTuple};
            # Make sure this feature is active.
            if (! $fig->is_deleted_fid($featureID)) {
                # Handle missing assignments.
                if (! defined $assignment) {
                    $assignment = '';
                    $user = '';
                } else {
                    # The default assignment-maker is FIG.
                    $user ||= 'fig';
                }
                # Count this feature.
                $self->Track(features => $featureID, 1000);
                # Fix the quality. It is almost always a space, but some odd stuff might sneak through, and the
                # Sprout database requires a single character.
                if (! defined($quality) || $quality eq "") {
                    $quality = " ";
                }
                # Get the coupling count. The coupled features are returned as a list,
                # and we store it as a scalar to get the count.
                my $couplingCount = $fig->coupled_to($featureID);
                # Begin building the keywords. We start with the genome ID, the
                # feature ID, the taxonomy, and the organism name.
                my @keywords = ($genomeID, $featureID, $fig->genus_species($genomeID),
                                $fig->taxonomy_of($genomeID));
                # Next come the aliases. We put all aliases found in this hash.
                # They will be output as alias names and as keywords.
                my %aliasHash;
                # Note the trick here to insure that we have a list reference even
                # if this feature isn't in the alias table.
                my $aliasList = $aliasMasterHash->{$featureID} || [];
                # Loop through this feature ID's aliases.
                for my $aliasTuple (@$aliasList) {
                    my ($aliasID, $aliasType, $aliasConf) = @$aliasTuple;
                    # Only proceed if this alias is new.
                    if (! exists $aliasHash{$aliasID}) {
                        # Save this alias.
                        $aliasHash{$aliasID} = 1;
                        # Get its natural form.
                        my $natural = AliasAnalysis::Type($aliasType => $aliasID);
                        # Only proceed if a natural form exists.
                        if ($natural) {
                            $self->Add(miscAlias => 1);
                            # Save the natural form.
                            $aliasHash{$natural} = 1;
                            # Is this a corresponding ID?
                            if ($aliasConf eq 'A') {
                                # Yes. Connect its natural form to the feature.
                                $self->PutR(IsAlsoFoundIn => $featureID, $aliasType,
                                            alias => $natural);
                                $self->PutE(ExternalDatabase => $aliasType);
                            }
                        }
                    }
                }
                # Create the aliases and put them in the keyword list.
                for my $alias (sort keys %aliasHash) {
                    # Connect this alias to this feature and make an Alias record for it.
                    $self->PutR(IsAliasOf => $alias, $featureID);
                    $self->PutE(FeatureAlias => $alias);
                    # Add it to the keyword list.
                    push @keywords, $alias;
                }
                Trace("Assignment for $featureID is: $assignment") if T(ERDBLoadGroup => 4);
                # Break the assignment into words and shove it onto the
                # keyword list.
                push @keywords, split(/\s+/, $assignment);
                # Add any EC numbers.
                my @ecs = BioWords::ExtractECs($assignment);
                for my $ec (@ecs) {
                    push @keywords, $ec;
                    $self->PutE(FeatureEC => $featureID, ec => $ec);
                }
                # Link this feature to the parent genome.
                $self->PutR(HasFeature => $genomeID, $featureID,
                           type => $type);
                # Get the links.
                my @links = $fig->fid_links($featureID);
                for my $link (@links) {
                    $self->PutE(FeatureLink => $featureID, link => $link);
                }
                # If this is a peg, generate the translation and the upstream.
                if ($type eq 'peg') {
                    $self->Add(pegIn => 1);
                    my $translation = $fig->get_translation($featureID);
                    if ($translation) {
                        $self->PutE(FeatureTranslation => $featureID,
                                   translation => $translation);
                    }
                    # We use the default upstream values of u=200 and c=100.
                    my $upstream = $fig->upstream_of($featureID, 200, 100);
                    if ($upstream) {
                        $self->PutE(FeatureUpstream => $featureID,
                                   'upstream-sequence' => $upstream);
                    }
                }
                # Now we need to find the subsystems this feature participates in.
                my @ssList = $fig->subsystems_for_peg($featureID);
                # This hash prevents us from adding the same subsystem twice.
                my %seen = ();
                for my $ssEntry (@ssList) {
                    # Get the subsystem and role.
                    my ($subsystem, $role) = @{$ssEntry};
                    # Only proceed if we like this subsystem.
                    if (exists $subHash->{$subsystem}) {
                        # If this is the first time we've seen this subsystem for
                        # this peg, store the has-role link.
                        if (! $seen{$subsystem}) {
                            $self->PutR(HasRoleInSubsystem => $featureID, $subsystem,
                                        genome => $genomeID, type => $type);
                            # Save the subsystem's keywords.
                            push @keywords, split /[\s_]+/, $subsystem;
                        }
                        # Now add the role and any embedded EC nubmers to the keyword list.
                        push @keywords, split /\s+/, $role;
                        push @keywords, BioWords::ExtractECs($role);
                    }
                }
                # For each hyphenated word, we also need the pieces.
                my @hyphenated = grep { $_ =~ /-/ } @keywords;
                for my $hyphenated (@hyphenated) {
                    # Bust it into pieces.
                    my @pieces = grep { length($_) > 2 } split /-/, $hyphenated;
                    push @keywords, @pieces;
                }
                # There are three special attributes computed from property
                # data that we build next. If the special attribute is non-empty,
                # its name will be added to the keyword list. First, we get all
                # the attributes for this feature. They will come back as
                # 4-tuples: [peg, name, value, URL].
                my @attributes = @{$attributes->{$featureID}};
                # Now we process each of the special attributes.
                if ($self->SpecialAttribute($featureID, \@attributes,
                                     2, [1,3], '^(essential|potential_essential)$',
                                     qw(FeatureEssential essential))) {
                    push @keywords, 'essential';
                    $self->Add(essential => 1);
                }
                if ($self->SpecialAttribute($featureID, \@attributes,
                                     1, [2,3], '^virulen',
                                     qw(FeatureVirulent virulent))) {
                    push @keywords, 'virulent';
                    $self->Add(virulent => 1);
                }
                if ($self->SpecialAttribute($featureID, \@attributes,
                                     1, [2,3], '^iedb_',
                                     qw(FeatureIEDB iedb))) {
                    push @keywords, 'iedb';
                    $self->Add(iedb => 1);
                }
                # Now we have some other attributes we need to process. To get
                # through them, we convert the attribute list for this feature
                # into a two-layer hash: key => subkey => value.
                my %attributeHash = ();
                for my $attrRow (@{$attributes->{$featureID}}) {
                    my (undef, $key, @values) = @{$attrRow};
                    my ($realKey, $subKey);
                    if ($key =~ /^([^:]+)::(.+)/) {
                        ($realKey, $subKey) = ($1, $2);
                    } else {
                        ($realKey, $subKey) = ($key, "");
                    }
                    if (exists $attributeHash{$realKey}) {
                        $attributeHash{$realKey}->{$subKey} = \@values;
                    } else {
                        $attributeHash{$realKey} = {$subKey => \@values};
                    }
                }
                TraceDump(AttributeHash => \%attributeHash) if T(FeatureLoadGroup => 4);
                # First we handle CDD. This is a bit complicated, because
                # there are multiple CDDs per protein.
                if (exists $attributeHash{CDD}) {
                    # Get the hash of CDD IDs to scores for this feature. We
                    # already know it exists because of the above IF.
                    my $cddHash = $attributeHash{CDD};
                    my @cddData = sort keys %$cddHash;
                    for my $cdd (@cddData) {
                        # Extract the score for this CDD and decode it.
                        my ($codeScore) = split(/\s*[,;]\s*/, $cddHash->{$cdd}->[0]);
                        my $realScore = FIGRules::DecodeScore($codeScore);
                        # We can't afford to crash because of a bad attribute
                        # value, hence the IF below.
                        if (! defined($realScore)) {
                            # Bad score, so count it.
                            $self->Add(badCDDscore => 1);
                            Trace("CDD score \"$codeScore\" for feature $featureID invalid.") if T(ERDBLoadGroup => 3);
                        } else {
                            # Create the connection and a CDD record.
                            $self->PutR(IsPresentOnProteinOf => $cdd, $featureID,
                                        score => $realScore);
                            $self->PutE(CDD => $cdd);
                        }
                    }
                }
                # A similar situation exists for protein families.
                if (exists $attributeHash{PFAM}) {
                    # Get the hash of PFAMs to scores for this feature.
                    my $pfamHash = $attributeHash{PFAM};
                    for my $pfam (sort keys %$pfamHash) {
                        # Extract the range.
                        my $codeScore = $pfamHash->{$pfam}->[0];
                        $codeScore =~ /;(.+)/;
                        my $range = $1;
                        # Strip off the PFAM id from the source.
                        my ($pfamID) = split /_/, $pfam, 2;
                        # Emit the ProteinFamily record.
                        $self->PutE(ProteinFamily => $pfamID);
                        # Connect it to the feature.
                        $self->PutR(IsFamilyForFeature => $pfamID, $featureID,
                                    range => $range);
                        # Get its name from the ontology database. There can
                        # be at most one.
                        my $dt_objs =
                            $ontology_dbmaster->pfam->get_objects({id => $pfamID});
                        if (defined $dt_objs->[0]) {
                            $self->PutE(ProteinFamilyName => $pfamID,
                                        common_name => $dt_objs->[0]->term());
                        }
                    }
                }
                # Next we do PSORT cell locations. here the confidence value
                # could have the value "unknown", which we translate to -1.
                if (exists $attributeHash{PSORT}) {
                    # This will be a hash of cell locations to confidence
                    # factors.
                    my $psortHash = $attributeHash{PSORT};
                    for my $psort (keys %{$psortHash}) {
                        # Get the confidence, and convert it to a number if necessary.
                        my $confidence = $psortHash->{$psort}->[0];
                        if ($confidence eq 'unknown') {
                            $confidence = -1;
                        }
                        $self->PutR(IsPossiblePlaceFor => $psort, $featureID,
                                    confidence => $confidence);
                        $self->PutE(CellLocation => $psort);
                        # If this is a significant location, add it as a keyword.
                        if ($confidence > 2.5) {
                            # Before we add it as a keyword, we convert it from
                            # capital-case to hyphenated by inserting hyphens at
                            # case transition points.
                            $psort =~ s/([a-z])([A-Z])/$1-$2/g;
                            push @keywords, $psort;
                        }
                    }
                }
                # Phobius data is next. This consists of the signal peptide location and
                # the transmembrane locations.
                my $signalList = "";
                my $transList = "";
                my $transCount = 0;
                if (exists $attributeHash{Phobius}) {
                    # This will be a hash of two keys (transmembrane and signal) to
                    # location lists. GetCommaList converts them into comma-separated
                    # location strings. If there's no value, it returns an empty string.
                    $signalList = $self->GetCommaList($attributeHash{Phobius}->{signal});
                    my $transList = $attributeHash{Phobius}->{transmembrane};
                    my @transMap = split /\s*,\s*/, $transList;
                    $transCount = (defined $transList ? scalar(@transMap) : 0);
                }
                # Here are some more numbers: isoelectric point, molecular weight, and
                # the similar-to-human flag.
                my $isoelectric = 0;
                if (exists $attributeHash{isoelectric_point}) {
                    $isoelectric = $attributeHash{isoelectric_point}->{""}->[0];
                }
                my $similarToHuman = 0;
                if (exists $attributeHash{similar_to_human} && $attributeHash{similar_to_human}->{""}->[0] eq 'yes') {
                    $similarToHuman = 1;
                }
                my $molecularWeight = 0;
                if (exists $attributeHash{molecular_weight}) {
                    $molecularWeight = $attributeHash{molecular_weight}->{""}->[0];
                }
                # Join the keyword string.
                my $keywordString = join(" ", @keywords);
                # Get rid of annoying punctuation.
                $keywordString =~ s/[();@#\/,]/ /g;
                # Get the list of keywords in the keyword string, minus the delimiters.
                my @realKeywords = grep { $stemmer->IsWord($_) }
                    $stemmer->Split($keywordString);
                # We need to do two things here: create the keyword string for the feature table
                # and write records to the keyword table for the keywords.
                my (%keys, %stems, @realStems);
                for my $keyword (@realKeywords) {
                    # Compute the stem and phonex for this keyword.
                    my ($stem, $phonex) = $stemmer->StemLookup($keyword);
                    # Only proceed if a stem comes back. If no stem came back, it's a
                    # stop word and we throw it away.
                    if ($stem) {
                        $keys{$keyword} = $stem;
                        $stems{$stem} = $phonex;
                        push @realStems, $stem;
                    }
                }
                # Now create the keyword string.
                my $cleanWords = join(" ", @realStems);
                Trace("Keyword string for $featureID: $cleanWords") if T(ERDBLoadGroup => 4);
                # Create keyword table entries for the keywords found.
                for my $key (keys %keys) {
                    my $stem = $keys{$key};
                    $self->PutE(Keyword => $key, stem => $stem, phonex => $stems{$stem});
                }
                # Now we need to process the feature's locations. First, we split them up.
                my @locationList = split /\s*,\s*/, $locations;
                # Next, we convert them to Sprout location objects.
                my @locObjectList = map { BasicLocation->new("$genomeID:$_") } @locationList;
                # Assemble them into a sprout location string for later.
                my $locationString = join(", ", map { $_->String } @locObjectList);
                # We'll store the sequence length in here.
                my $sequenceLength = 0;
                # This part is the roughest. We need to relate the features to contig
                # locations, and the locations must be split so that none of them exceed
                # the maximum segment size. This simplifies the genes_in_region processing
                # for Sprout. To start, we create the location position indicator.
                my $i = 1;
                # Loop through the locations.
                for my $locObject (@locObjectList) {
                    # Record the length.
                    $sequenceLength += $locObject->Length;
                    # Split this location into a list of chunks.
                    my @locOList = ();
                    while (my $peeling = $locObject->Peel($chunkSize)) {
                        $self->Add(peeling => 1);
                        push @locOList, $peeling;
                    }
                    push @locOList, $locObject;
                    # Loop through the chunks, creating IsLocatedIn records. The variable
                    # "$i" will be used to keep the location index.
                    for my $locChunk (@locOList) {
                        $self->PutR(IsLocatedIn => $featureID, $locChunk->Contig,
                                    beg => $locChunk->Left, dir => $locChunk->Dir,
                                    len => $locChunk->Length, locN => $i);
                        $i++;
                    }
                }
                # Check for figfams. In case we find any, we need the range.
                # It's the whole sequence.
                my $range = "1-$sequenceLength";
                # Ask for the figfams.
                my @fams = $ffs->families_containing_peg($featureID);
                # Connect them to the feature (if any).
                for my $fam (@fams) {
                    $self->PutE(ProteinFamily => $fam);
                    $self->PutR(IsFamilyForFeature => $fam, $featureID,
                                range => $range);
                }
                # Now we get some ancillary flags.
                my $locked = $fig->is_locked_fid($featureID);
                my $in_genbank = $fig->peg_in_gendb($featureID);
                # Create the feature record.
                $self->PutE(Feature => $featureID, 'assignment-maker' => $user,
                           'assignment-quality' => $quality, 'feature-type' => $type,
                           'in-genbank' => $in_genbank, 'isoelectric-point' => $isoelectric,
                           locked => $locked, 'molecular-weight' => $molecularWeight,
                           'sequence-length' => $sequenceLength,
                           'signal-peptide' => $signalList, 'similar-to-human' => $similarToHuman,
                           assignment => $assignment, keywords => $cleanWords,
                           'location-string' => $locationString,
                           'transmembrane-map' => $transList,
                           'conserved-neighbors' => $couplingCount,
                           'transmembrane-domain-count' => $transCount);
            }
        }
    }
}


=head3 SpecialAttribute

    my $count = $sl->SpecialAttribute($id, \@attributes, $idxMatch, \@idxValues, $pattern, $tableName, $field);

Look for special attributes of a given type. A special attribute is found by comparing one of
the columns of the incoming attribute list to a search pattern. If a match is found, then
a set of columns is put into an output table connected to the specified ID.

For example, when processing features, the attribute list we look at has three columns: attribute
name, attribute value, and attribute value HTML. The IEDB attribute exists if the attribute name
begins with C<iedb_>. The call signature is therefore

    my $found = SpecialAttribute($fid, \@attributeList, 0, [0,2], '^iedb_', 'FeatureIEDB', 'iedb');

The pattern is matched against column 0, and if we have a match, then column 2's value is put
to the output along with the specified feature ID.

=over 4

=item id

ID of the object whose special attributes are being loaded. This forms the first column of the
output.

=item attributes

Reference to a list of tuples.

=item idxMatch

Index in each tuple of the column to be matched against the pattern. If the match is
successful, an output record will be generated.

=item idxValues

Reference to a list containing the indexes of the value and URL to put in the
second column of the output.

=item pattern

Pattern to be matched against the specified column. The match will be case-insensitive.

=item tableName

Name of the table to contain the attribute values found.

=item fieldName

Name of the field to contain the attribute values in the output table.

=item RETURN

Returns a count of the matches found.

=item

=back

=cut

sub SpecialAttribute {
    # Get the parameters.
    my ($self, $id, $attributes, $idxMatch, $idxValues, $pattern, $tableName, $fieldName) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Loop through the attribute rows.
    for my $row (@{$attributes}) {
        # Check for a match.
        if ($row->[$idxMatch] =~ m/$pattern/i) {
            # We have a match, so output a row.
            my $value = HyperLink->new(map { $row->[$_] } @$idxValues);
            $self->PutE($tableName => $id, $fieldName => $value);
            $retVal++;
        }
    }
    Trace("$retVal special attributes found for $id and table $tableName.") if T(ERDBLoadGroup => 4) && $retVal;
    # Return the number of matches.
    return $retVal;
}


1;