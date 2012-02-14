#!/usr/bin/perl -w

package SproutLoad;

    use strict;
    use Tracer;
    use PageBuilder;
    use ERDBLoad;
    use FIG;
    use FIGRules;
    use Sprout;
    use Stats;
    use BasicLocation;
    use HTML;
    use AliasAnalysis;
    use BioWords;

=head1 Sprout Load Methods

=head2 Introduction

This object contains the methods needed to copy data from the FIG data store to the
Sprout database. It makes heavy use of the ERDBLoad object to manage the load into
individual tables. The client can create an instance of this object and then
call methods for each group of tables to load. For example, the following code will
load the Genome- and Feature-related tables. (It is presumed the first command line
parameter contains the name of a file specifying the genomes.)

    my $fig = FIG->new();
    my $sprout = SFXlate->new_sprout_only();
    my $spl = SproutLoad->new($sprout, $fig, $ARGV[0]);
    my $stats = $spl->LoadGenomeData();
    $stats->Accumulate($spl->LoadFeatureData());
    print $stats->Show();

It is worth noting that the FIG object does not need to be a real one. Any object
that implements the FIG methods for data retrieval could be used. So, for example,
this object could be used to copy data from one Sprout database to another, or
from any FIG-compliant data story implemented in the future.

To insure that this is possible, each time the FIG object is used, it will be via
a variable called C<$fig>. This makes it fairly straightforward to determine which
FIG methods are required to load the Sprout database.

This object creates the load files; however, the tables are not created until it
is time to actually do the load from the files into the target database.

=cut

#: Constructor SproutLoad->new();

=head2 Public Methods

=head3 new

    my $spl = SproutLoad->new($sprout, $fig, $genomeFile, $subsysFile, $options);

Construct a new Sprout Loader object, specifying the two participating databases and
the name of the files containing the list of genomes and subsystems to use.

=over 4

=item sprout

Sprout object representing the target database. This also specifies the directory to
be used for creating the load files.

=item fig

FIG object representing the source data store from which the data is to be taken.

=item genomeFile

Either the name of the file containing the list of genomes to load or a reference to
a hash of genome IDs to access codes. If nothing is specified, all complete genomes
will be loaded and the access code will default to 1. The genome list is presumed
to be all-inclusive. In other words, all existing data in the target database will
be deleted and replaced with the data on the specified genes. If a file is specified,
it should contain one genome ID and access code per line, tab-separated.

=item subsysFile

Either the name of the file containing the list of trusted subsystems or a reference
to a list of subsystem names. If nothing is specified, all NMPDR subsystems will be
considered trusted. (A subsystem is considered NMPDR if it has a file named C<NMPDR>
in its data directory.) Only subsystem data related to the NMPDR subsystems is loaded.

=item options

Reference to a hash of command-line options.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $sprout, $fig, $genomeFile, $subsysFile, $options) = @_;
    # Create the genome hash.
    my %genomes = ();
    # We only need it if load-only is NOT specified.
    if (! $options->{loadOnly}) {
        if (! defined($genomeFile) || $genomeFile eq '') {
            # Here we want all the complete genomes and an access code of 1.
            my @genomeList = $fig->genomes(1);
            %genomes = map { $_ => 1 } @genomeList;
            Trace(scalar(keys %genomes) . " genomes found.") if T(3);
        } else {
            my $type = ref $genomeFile;
            Trace("Genome file parameter type is \"$type\".") if T(3);
            if ($type eq 'HASH') {
                # Here the user specified a hash of genome IDs to access codes, which is
                # exactly what we want.
                %genomes = %{$genomeFile};
            } elsif (! $type || $type eq 'SCALAR' ) {
                # The caller specified a file, so read the genomes from the file. (Note
                # that some PERLs return an empty string rather than SCALAR.)
                my @genomeList = Tracer::GetFile($genomeFile);
                if (! @genomeList) {
                    # It's an error if the genome file is empty or not found.
                    Confess("No genomes found in file \"$genomeFile\".");
                } else {
                    # We build the genome Hash using a loop rather than "map" so that
                    # an omitted access code can be defaulted to 1.
                    for my $genomeLine (@genomeList) {
                        my ($genomeID, $accessCode) = split("\t", $genomeLine);
                        if (! defined($accessCode)) {
                            $accessCode = 1;
                        }
                        $genomes{$genomeID} = $accessCode;
                    }
                }
            } else {
                Confess("Invalid genome parameter ($type) in SproutLoad constructor.");
            }
        }
    }
    # Load the list of trusted subsystems.
    my %subsystems = ();
    # We only need it if load-only is NOT specified.
    if (! $options->{loadOnly}) {
        if (! defined $subsysFile || $subsysFile eq '') {
            # Here we want all the usable subsystems. First we get the whole list.
            my @subs = $fig->all_subsystems();
            # Loop through, checking for the NMPDR file.
            for my $sub (@subs) {
                if ($fig->nmpdr_subsystem($sub)) {
                    $subsystems{$sub} = 1;
                }
            }
        } else {
            my $type = ref $subsysFile;
            if ($type eq 'ARRAY') {
                # Here the user passed in a list of subsystems.
                %subsystems = map { $_ => 1 } @{$subsysFile};
            } elsif (! $type || $type eq 'SCALAR') {
                # Here the list of subsystems is in a file.
                if (! -e $subsysFile) {
                    # It's an error if the file does not exist.
                    Confess("Trusted subsystem file not found.");
                } else {
                    # GetFile automatically chomps end-of-line characters, so this
                    # is an easy task.
                    %subsystems = map { $_ => 1 } Tracer::GetFile($subsysFile);
                }
            } else {
                Confess("Invalid subsystem parameter in SproutLoad constructor.");
            }
        }
        # Go through the subsys hash again, creating the keyword list for each subsystem.
        for my $subsystem (keys %subsystems) {
            my $name = $subsystem;
            $name =~ s/_/ /g;
            $subsystems{$subsystem} = $name;
        }
    }
    # Get the list of NMPDR-oriented attribute keys.
    my @propKeys = $fig->get_group_keys("NMPDR");
    # Get the data directory from the Sprout object.
    my ($directory) = $sprout->LoadInfo();
    # Create the Sprout load object.
    my $retVal = {
                  fig => $fig,
                  genomes => \%genomes,
                  subsystems => \%subsystems,
                  sprout => $sprout,
                  loadDirectory => $directory,
                  erdb => $sprout,
                  loaders => [],
                  options => $options,
                  propKeys => \@propKeys,
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 LoadOnly

    my $flag = $spl->LoadOnly;

Return TRUE if we are in load-only mode, else FALSE.

=cut

sub LoadOnly {
    my ($self) = @_;
    return $self->{options}->{loadOnly};
}


=head3 LoadGenomeData

    my $stats = $spl->LoadGenomeData();

Load the Genome, Contig, and Sequence data from FIG into Sprout.

The Sequence table is the largest single relation in the Sprout database, so this
method is expected to be slow and clumsy. At some point we will need to make it
restartable, since an error 10 gigabytes through a 20-gigabyte load is bound to be
very annoying otherwise.

The following relations are loaded by this method.

    Genome
    HasContig
    Contig
    IsMadeUpOf
    Sequence

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadGenomeData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome count.
    my $genomeHash = $self->{genomes};
    my $genomeCount = (keys %{$genomeHash});
    # Create load objects for each of the tables we're loading.
    my $loadGenome = $self->_TableLoader('Genome');
    my $loadHasContig = $self->_TableLoader('HasContig');
    my $loadContig = $self->_TableLoader('Contig');
    my $loadIsMadeUpOf = $self->_TableLoader('IsMadeUpOf');
    my $loadSequence = $self->_TableLoader('Sequence');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating genome data.") if T(2);
        # Get the full info for the FIG genomes.
        my %genomeInfo = map { $_->[0] => { gname => $_->[1], szdna => $_->[2], maindomain => $_->[3],
                                            pegs => $_->[4], rnas => $_->[5], complete => $_->[6] } } @{$fig->genome_info()};
        # Now we loop through the genomes, generating the data for each one.
        for my $genomeID (sort keys %{$genomeHash}) {
            Trace("Generating data for genome $genomeID.") if T(3);
            $loadGenome->Add("genomeIn");
            # The access code comes in via the genome hash.
            my $accessCode = $genomeHash->{$genomeID};
            # Get the genus, species, and strain from the scientific name.
            my ($genus, $species, @extraData) = split / /, $self->{fig}->genus_species($genomeID);
            my $extra = join " ", @extraData;
            # Get the full taxonomy.
            my $taxonomy = $fig->taxonomy_of($genomeID);
            # Get the version. If no version is specified, we default to the genome ID by itself.
            my $version = $fig->genome_version($genomeID);
            if (! defined($version)) {
                $version = $genomeID;
            }
            # Get the DNA size.
            my $dnaSize = $fig->genome_szdna($genomeID);
            # Open the NMPDR group file for this genome.
            my $group;
            if (open(TMP, "<$FIG_Config::organisms/$genomeID/NMPDR") &&
                defined($group = <TMP>)) {
                # Clean the line ending.
                chomp $group;
            } else {
                # No group, so use the default.
                $group = $FIG_Config::otherGroup;
            }
            close TMP;
            # Get the contigs.
            my @contigs = $fig->all_contigs($genomeID);
            # Get this genome's info array.
            my $info = $genomeInfo{$genomeID};
            # Output the genome record.
            $loadGenome->Put($genomeID, $accessCode, $info->{complete}, scalar(@contigs),
                             $dnaSize, $genus, $info->{pegs}, $group, $info->{rnas}, $species, $extra, $version, $taxonomy);
            # Now we loop through each of the genome's contigs.
            for my $contigID (@contigs) {
                Trace("Processing contig $contigID for $genomeID.") if T(4);
                $loadContig->Add("contigIn");
                $loadSequence->Add("contigIn");
                # Create the contig ID.
                my $sproutContigID = "$genomeID:$contigID";
                # Create the contig record and relate it to the genome.
                $loadContig->Put($sproutContigID);
                $loadHasContig->Put($genomeID, $sproutContigID);
                # Now we need to split the contig into sequences. The maximum sequence size is
                # a property of the Sprout object.
                my $chunkSize = $self->{sprout}->MaxSequence();
                # Now we get the sequence a chunk at a time.
                my $contigLen = $fig->contig_ln($genomeID, $contigID);
                for (my $i = 1; $i <= $contigLen; $i += $chunkSize) {
                    $loadSequence->Add("chunkIn");
                    # Compute the endpoint of this chunk.
                    my $end = FIG::min($i + $chunkSize - 1, $contigLen);
                    # Get the actual DNA.
                    my $dna = $fig->get_dna($genomeID, $contigID, $i, $end);
                    # Compute the sequenceID.
                    my $seqID = "$sproutContigID.$i";
                    # Write out the data. For now, the quality vector is always "unknown".
                    $loadIsMadeUpOf->Put($sproutContigID, $seqID, $end + 1 - $i, $i);
                    $loadSequence->Put($seqID, "unknown", $dna);
                }
            }
        }
    }
    # Finish the loads.
    my $retVal = $self->_FinishAll();
    # Return the result.
    return $retVal;
}

=head3 LoadFeatureData

    my $stats = $spl->LoadFeatureData();

Load the feature data from FIG into Sprout.

Features represent annotated genes, and are therefore the heart of the data store.

The following relations are loaded by this method.

    Feature
    FeatureAlias
    IsAliasOf
    FeatureLink
    FeatureTranslation
    FeatureUpstream
    IsLocatedIn
    HasFeature
    HasRoleInSubsystem
    FeatureEssential
    FeatureVirulent
    FeatureIEDB
    CDD
    IsPresentOnProteinOf
    CellLocation
    IsPossiblePlaceFor
    ExternalDatabase
    IsAlsoFoundIn
    Keyword

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadFeatureData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG and Sprout objects.
    my $fig = $self->{fig};
    my $sprout = $self->{sprout};
    # Get the table of genome IDs.
    my $genomeHash = $self->{genomes};
    # Create load objects for each of the tables we're loading.
    my $loadFeature = $self->_TableLoader('Feature');
    my $loadIsLocatedIn = $self->_TableLoader('IsLocatedIn');
    my $loadFeatureAlias = $self->_TableLoader('FeatureAlias');
    my $loadIsAliasOf = $self->_TableLoader('IsAliasOf');
    my $loadFeatureLink = $self->_TableLoader('FeatureLink');
    my $loadFeatureTranslation = $self->_TableLoader('FeatureTranslation');
    my $loadFeatureUpstream = $self->_TableLoader('FeatureUpstream');
    my $loadHasFeature = $self->_TableLoader('HasFeature');
    my $loadHasRoleInSubsystem = $self->_TableLoader('HasRoleInSubsystem');
    my $loadFeatureEssential = $self->_TableLoader('FeatureEssential');
    my $loadFeatureVirulent = $self->_TableLoader('FeatureVirulent');
    my $loadFeatureIEDB = $self->_TableLoader('FeatureIEDB');
    my $loadCDD = $self->_TableLoader('CDD');
    my $loadIsPresentOnProteinOf = $self->_TableLoader('IsPresentOnProteinOf');
    my $loadCellLocation = $self->_TableLoader('CellLocation');
    my $loadIsPossiblePlaceFor = $self->_TableLoader('IsPossiblePlaceFor');
    my $loadIsAlsoFoundIn = $self->_TableLoader('IsAlsoFoundIn');
    my $loadExternalDatabase = $self->_TableLoader('ExternalDatabase');
    my $loadKeyword = $self->_TableLoader('Keyword');
    # Get the subsystem hash.
    my $subHash = $self->{subsystems};
    # Get the property keys.
    my $propKeys = $self->{propKeys};
    # Create a hashes to hold CDD, Cell Location (PSORT), External Database, and alias values.
    my %CDD = ();
    my %alias = ();
    my %cellLocation = ();
    my %xdb = ();
    # Create the bio-words object.
    my $biowords = BioWords->new(exceptions => "$FIG_Config::sproutData/Exceptions.txt",
                                 stops => "$FIG_Config::sproutData/StopWords.txt",
                                 cache => 0);
    # One of the things we have to do here is build the keyword table, and the keyword
    # table needs to contain the originating text and feature count for each stem. Unfortunately,
    # the number of distinct keywords is so large it causes PERL to hang if we try to
    # keep them in memory. As a result, we need to track them using disk files.
    # Our approach will be to use two sequential files. One will contain stems and phonexes.
    # Each time a stem occurs in a feature, a record will be written to that file. The stem
    # file can then be sorted and collated to determine the number of features for each
    # stem. A separate file will contain keywords and stems. This last file
    # will be subjected to a sort unique on stem/keyword. The file is then merged
    # with the stem file to create the keyword table relation (keyword, stem, phonex, count).
    my $stemFileName = "$FIG_Config::temp/stems$$.tbl";
    my $keyFileName = "$FIG_Config::temp/keys$$.tbl";
    my $stemh = Open(undef, "| sort -T\"$FIG_Config::temp\" -t\"\t\" -k1,1 >$stemFileName");
    my $keyh = Open(undef, "| sort -T\"$FIG_Config::temp\" -t\"\t\" -u -k1,1 -k2,2 >$keyFileName");
    # Get the maximum sequence size. We need this later for splitting up the
    # locations.
    my $chunkSize = $self->{sprout}->MaxSegment();
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating feature data.") if T(2);
        # Now we loop through the genomes, generating the data for each one.
        my @allGenomes = sort keys %{$genomeHash};
        Trace(scalar(@allGenomes) . " genomes found in list.") if T(3);
        for my $genomeID (@allGenomes) {
            Trace("Loading features for genome $genomeID.") if T(3);
            $loadFeature->Add("genomeIn");
            # Get the feature list for this genome.
            my $features = $fig->all_features_detailed_fast($genomeID);
            # Sort and count the list.
            my @featureTuples = sort { $a->[0] cmp $b->[0] } @{$features};
            my $count = scalar @featureTuples;
            my @fids = map { $_->[0] } @featureTuples;
            Trace("$count features found for genome $genomeID.") if T(3);
            # Get the attributes for this genome and put them in a hash by feature ID.
            my $attributes = GetGenomeAttributes($fig, $genomeID, \@fids, $propKeys);
            Trace("Looping through features for $genomeID.") if T(3);
            # Set up for our duplicate-feature check.
            my $oldFeatureID = "";
            # Loop through the features.
            for my $featureTuple (@featureTuples) {
                # Split the tuple.
                my ($featureID, $locations, undef, $type, $minloc, $maxloc, $assignment, $user, $quality) = @{$featureTuple};
                # Check for duplicates.
                if ($featureID eq $oldFeatureID) {
                    Trace("Duplicate feature $featureID found.") if T(1);
                } else {
                    $oldFeatureID = $featureID;
                    # Count this feature.
                    $loadFeature->Add("featureIn");
                    # Fix the quality. It is almost always a space, but some odd stuff might sneak through, and the
                    # Sprout database requires a single character.
                    if (! defined($quality) || $quality eq "") {
                        $quality = " ";
                    }
                    # Begin building the keywords. We start with the genome ID, the
                    # feature ID, the taxonomy, and the organism name.
                    my @keywords = ($genomeID, $featureID, $fig->genus_species($genomeID),
                                    $fig->taxonomy_of($genomeID));
                    # Create the aliases.
                    for my $alias ($fig->feature_aliases($featureID)) {
                        #Connect this alias to this feature.
                        $loadIsAliasOf->Put($alias, $featureID);
                        push @keywords, $alias;
                        # If this is a locus tag, also add its natural form as a keyword.
                        my $naturalName = AliasAnalysis::Type(LocusTag => $alias);
                        if ($naturalName) {
                            push @keywords, $naturalName;
                        }
                        # If this is the first time for the specified alias, create its
                        # alias record.
                        if (! exists $alias{$alias}) {
                            $loadFeatureAlias->Put($alias);
                            $alias{$alias} = 1;
                        }
                    }
                    # Add the corresponding IDs. We ask for 2-tuples of the form (id, database).
                    my @corresponders = $fig->get_corresponding_ids($featureID, 1);
                    for my $tuple (@corresponders) {
                        my ($id, $xdb) = @{$tuple};
                        # Ignore SEED: that's us.
                        if ($xdb ne 'SEED') {
                            # Connect this ID to the feature.
                            $loadIsAlsoFoundIn->Put($featureID, $xdb, $id);
                            # Add it as a keyword.
                            push @keywords, $id;
                            # If this is a new database, create a record for it.
                            if (! exists $xdb{$xdb}) {
                                $xdb{$xdb} = 1;
                                $loadExternalDatabase->Put($xdb);
                            }
                        }
                    }
                    Trace("Assignment for $featureID is: $assignment") if T(4);
                    # Break the assignment into words and shove it onto the
                    # keyword list.
                    push @keywords, split(/\s+/, $assignment);
                    # Link this feature to the parent genome.
                    $loadHasFeature->Put($genomeID, $featureID, $type);
                    # Get the links.
                    my @links = $fig->fid_links($featureID);
                    for my $link (@links) {
                        $loadFeatureLink->Put($featureID, $link);
                    }
                    # If this is a peg, generate the translation and the upstream.
                    if ($type eq 'peg') {
                        $loadFeatureTranslation->Add("pegIn");
                        my $translation = $fig->get_translation($featureID);
                        if ($translation) {
                            $loadFeatureTranslation->Put($featureID, $translation);
                        }
                        # We use the default upstream values of u=200 and c=100.
                        my $upstream = $fig->upstream_of($featureID, 200, 100);
                        if ($upstream) {
                            $loadFeatureUpstream->Put($featureID, $upstream);
                        }
                    }
                    # Now we need to find the subsystems this feature participates in.
                    # We also add the subsystems to the keyword list. Before we do that,
                    # we must convert underscores to spaces.
                    my @subsystems = $fig->peg_to_subsystems($featureID);
                    for my $subsystem (@subsystems) {
                        # Only proceed if we like this subsystem.
                        if (exists $subHash->{$subsystem}) {
                            # Store the has-role link.
                            $loadHasRoleInSubsystem->Put($featureID, $subsystem, $genomeID, $type);
                            # Save the subsystem's keyword data.
                            my $subKeywords = $subHash->{$subsystem};
                            push @keywords, split /\s+/, $subKeywords;
                            # Now we need to get this feature's role in the subsystem.
                            my $subObject = $fig->get_subsystem($subsystem);
                            my @roleColumns = $subObject->get_peg_roles($featureID);
                            my @allRoles = $subObject->get_roles();
                            for my $col (@roleColumns) {
                                my $role = $allRoles[$col];
                                push @keywords, split /\s+/, $role;
                                push @keywords, $subObject->get_role_abbr($col);
                            }
                        }
                    }
                    # There are three special attributes computed from property
                    # data that we build next. If the special attribute is non-empty,
                    # its name will be added to the keyword list. First, we get all
                    # the attributes for this feature. They will come back as
                    # 4-tuples: [peg, name, value, URL]. We use a 3-tuple instead:
                    # [name, value, value with URL]. (We don't need the PEG, since
                    # we already know it.)
                    my @attributes = map { [$_->[1], $_->[2], Tracer::CombineURL($_->[2], $_->[3])] }
                                         @{$attributes->{$featureID}};
                    # Now we process each of the special attributes.
                    if (SpecialAttribute($featureID, \@attributes,
                                         1, [0,2], '^(essential|potential_essential)$',
                                         $loadFeatureEssential)) {
                        push @keywords, 'essential';
                        $loadFeature->Add('essential');
                    }
                    if (SpecialAttribute($featureID, \@attributes,
                                         0, [2], '^virulen',
                                         $loadFeatureVirulent)) {
                        push @keywords, 'virulent';
                        $loadFeature->Add('virulent');
                    }
                    if (SpecialAttribute($featureID, \@attributes,
                                         0, [0,2], '^iedb_',
                                         $loadFeatureIEDB)) {
                        push @keywords, 'iedb';
                        $loadFeature->Add('iedb');
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
                    # First we handle CDD. This is a bit complicated, because
                    # there are multiple CDDs per protein.
                    if (exists $attributeHash{CDD}) {
                        # Get the hash of CDD IDs to scores for this feature. We
                        # already know it exists because of the above IF.
                        my $cddHash = $attributeHash{CDD};
                        my @cddData = sort keys %{$cddHash};
                        for my $cdd (@cddData) {
                            # Extract the score for this CDD and decode it.
                            my ($codeScore) = split(/\s*[,;]\s*/, $cddHash->{$cdd}->[0]);
                            my $realScore = FIGRules::DecodeScore($codeScore);
                            # We can't afford to crash because of a bad attribute
                            # value, hence the IF below.
                            if (! defined($realScore)) {
                                # Bad score, so count it.
                                $loadFeature->Add('badCDDscore');
                                Trace("CDD score \"$codeScore\" for feature $featureID invalid.") if T(3);
                            } else {
                                # Create the connection.
                                $loadIsPresentOnProteinOf->Put($cdd, $featureID, $realScore);
                                # If this CDD does not yet exist, create its record.
                                if (! exists $CDD{$cdd}) {
                                    $CDD{$cdd} = 1;
                                    $loadCDD->Put($cdd);
                                }
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
                            my $confidence = $psortHash->{$psort};
                            if ($confidence eq 'unknown') {
                                $confidence = -1;
                            }
                            $loadIsPossiblePlaceFor->Put($psort, $featureID, $confidence);
                            # If this cell location does not yet exist, create its record.
                            if (! exists $cellLocation{$psort}) {
                                $cellLocation{$psort} = 1;
                                $loadCellLocation->Put($psort);
                            }
                            # If this is a significant location, add it as a keyword.
                            if ($confidence > 2.5) {
                                push @keywords, $psort;
                            }
                        }
                    }
                    # Phobius data is next. This consists of the signal peptide location and
                    # the transmembrane locations.
                    my $signalList = "";
                    my $transList = "";
                    if (exists $attributeHash{Phobius}) {
                        # This will be a hash of two keys (transmembrane and signal) to
                        # location strings. If there's no value, we stuff in an empty string.
                        $signalList = GetCommaList($attributeHash{Phobius}->{signal});
                        $transList = GetCommaList($attributeHash{Phobius}->{transmembrane});
                    }
                    # Here are some more numbers: isoelectric point, molecular weight, and
                    # the similar-to-human flag.
                    my $isoelectric = 0;
                    if (exists $attributeHash{isoelectric_point}) {
                        $isoelectric = $attributeHash{isoelectric_point}->{""};
                    }
                    my $similarToHuman = 0;
                    if (exists $attributeHash{similar_to_human} && $attributeHash{similar_to_human}->{""} eq 'yes') {
                        $similarToHuman = 1;
                    }
                    my $molecularWeight = 0;
                    if (exists $attributeHash{molecular_weight}) {
                        $molecularWeight = $attributeHash{molecular_weight}->{""};
                    }
                    # Create the keyword string.
                    my $keywordString = join(" ", @keywords);
                    Trace("Real keyword string for $featureID: $keywordString.") if T(4);
                    # Get rid of annoying punctuation.
                    $keywordString =~ s/[();@#\/]/ /g;
                    # Get the list of keywords in the keyword string.
                    my @realKeywords = grep { $biowords->IsWord($_) } $biowords->Split($keywordString);
                    # We need to do two things here: create the keyword string for the feature table
                    # and write records to the keyword and stem files. The stuff we write to
                    # the files will be taken from the following two hashes. The stuff used
                    # to create the keyword string will be taken from the list.
                    my (%keys, %stems, @realStems);
                    for my $keyword (@realKeywords) {
                        # Compute the stem and phonex for this keyword.
                        my ($stem, $phonex) = $biowords->StemLookup($keyword);
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
                    Trace("Keyword string for $featureID: $cleanWords") if T(4);
                    # Write the stem and keyword records.
                    for my $stem (keys %stems) {
                        Tracer::PutLine($stemh, [$stem, $stems{$stem}]);
                    }
                    for my $key (keys %keys) {
                        # The stem goes first in this file, because we want to sort
                        # by stem and then keyword.
                        Tracer::PutLine($keyh, [$keys{$key}, $key]);
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
                            $loadIsLocatedIn->Add("peeling");
                            push @locOList, $peeling;
                        }
                        push @locOList, $locObject;
                        # Loop through the chunks, creating IsLocatedIn records. The variable
                        # "$i" will be used to keep the location index.
                        for my $locChunk (@locOList) {
                            $loadIsLocatedIn->Put($featureID, $locChunk->Contig, $locChunk->Left,
                                                  $locChunk->Dir, $locChunk->Length, $i);
                            $i++;
                        }
                    }
                    # Now we get some ancillary flags.
                    my $locked = $fig->is_locked_fid($featureID);
                    my $in_genbank = $fig->peg_in_gendb($featureID);
                    # Create the feature record.
                    $loadFeature->Put($featureID, 1, $user, $quality, $type, $in_genbank, $isoelectric, $locked, $molecularWeight,
                                      $sequenceLength, $signalList, $similarToHuman, $assignment, $cleanWords, $locationString,
                                      $transList);
                }
            }
            Trace("Genome $genomeID processed.") if T(3);
        }
    }
    Trace("Sorting keywords.") if T(2);
    # Now we need to load the keyword table from the key and stem files.
    close $keyh;
    close $stemh;
    Trace("Loading keywords.") if T(2);
    $keyh = Open(undef, "<$keyFileName");
    $stemh = Open(undef, "<$stemFileName");
    # We'll count the keywords in here, for tracing purposes.
    my $count = 0;
    # These variables track the current stem's data. When an incoming
    # keyword's stem changes, these will be recomputed.
    my ($currentStem, $currentPhonex, $currentCount);
    # Prime the loop by reading the first stem in the stem file.
    my ($nextStem, $nextPhonex) = Tracer::GetLine($stemh);
    # Loop through the keyword file.
    while (! eof $keyh) {
        # Read this keyword.
        my ($thisStem, $thisKey) = Tracer::GetLine($keyh);
        # Check to see if it's the new stem yet.
        if ($thisStem ne $currentStem) {
            # Yes. It's a terrible error if it's not also the next stem.
            if ($thisStem ne $nextStem) {
                Confess("Error in stem file. Expected \"$nextStem\", but found \"$thisStem\".");
            } else {
                # Here we're okay.
                ($currentStem, $currentPhonex) = ($nextStem, $nextPhonex);
                # Count the number of features for this stem.
                $currentCount = 0;
                while ($nextStem eq $thisStem) {
                    ($nextStem, $nextPhonex) = Tracer::GetLine($stemh);
                    $currentCount++;
                }
            }
        }
        # Now $currentStem is the same as $thisStem, and the other $current-vars
        # contain the stem's data (phonex and count).
        $loadKeyword->Put($thisKey, $currentCount, $currentPhonex, $currentStem);
        if (++$count % 1000 == 0 && T(3)) {
            Trace("$count keywords loaded.");
        }
    }
    Trace("$count keywords loaded into keyword table.") if T(2);
    # Finish the loads.
    my $retVal = $self->_FinishAll();
    return $retVal;
}

=head3 LoadSubsystemData

    my $stats = $spl->LoadSubsystemData();

Load the subsystem data from FIG into Sprout.

Subsystems are groupings of genetic roles that work together to effect a specific
chemical reaction. Similar organisms require similar subsystems. To curate a subsystem,
a spreadsheet is created with genomes on one axis and subsystem roles on the other
axis. Similar features are then mapped into the cells, allowing the annotation of one
genome's roles to be used to assist in the annotation of others.

The following relations are loaded by this method.

    Subsystem
    SubsystemClass
    Role
    RoleEC
    IsIdentifiedByEC
    SSCell
    ContainsFeature
    IsGenomeOf
    IsRoleOf
    OccursInSubsystem
    ParticipatesIn
    HasSSCell
    ConsistsOfRoles
    RoleSubset
    HasRoleSubset
    ConsistsOfGenomes
    GenomeSubset
    HasGenomeSubset
    Diagram
    RoleOccursIn
    SubsystemHopeNotes

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadSubsystemData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome hash. We'll use it to filter the genomes in each
    # spreadsheet.
    my $genomeHash = $self->{genomes};
    # Get the subsystem hash. This lists the subsystems we'll process.
    my $subsysHash = $self->{subsystems};
    my @subsysIDs = sort keys %{$subsysHash};
    # Get the map list.
    my @maps = $fig->all_maps;
    # Create load objects for each of the tables we're loading.
    my $loadDiagram = $self->_TableLoader('Diagram');
    my $loadRoleOccursIn = $self->_TableLoader('RoleOccursIn');
    my $loadSubsystem = $self->_TableLoader('Subsystem');
    my $loadRole = $self->_TableLoader('Role');
    my $loadRoleEC = $self->_TableLoader('RoleEC');
    my $loadIsIdentifiedByEC = $self->_TableLoader('IsIdentifiedByEC');
    my $loadCatalyzes = $self->_TableLoader('Catalyzes');
    my $loadSSCell = $self->_TableLoader('SSCell');
    my $loadContainsFeature = $self->_TableLoader('ContainsFeature');
    my $loadIsGenomeOf = $self->_TableLoader('IsGenomeOf');
    my $loadIsRoleOf = $self->_TableLoader('IsRoleOf');
    my $loadOccursInSubsystem = $self->_TableLoader('OccursInSubsystem');
    my $loadParticipatesIn = $self->_TableLoader('ParticipatesIn');
    my $loadHasSSCell = $self->_TableLoader('HasSSCell');
    my $loadRoleSubset = $self->_TableLoader('RoleSubset');
    my $loadGenomeSubset = $self->_TableLoader('GenomeSubset');
    my $loadConsistsOfRoles = $self->_TableLoader('ConsistsOfRoles');
    my $loadConsistsOfGenomes = $self->_TableLoader('ConsistsOfGenomes');
    my $loadHasRoleSubset = $self->_TableLoader('HasRoleSubset');
    my $loadHasGenomeSubset = $self->_TableLoader('HasGenomeSubset');
    my $loadSubsystemClass = $self->_TableLoader('SubsystemClass');
    my $loadSubsystemHopeNotes = $self->_TableLoader('SubsystemHopeNotes');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating subsystem data.") if T(2);
        # This hash will contain the roles for each EC. When we're done, this
        # information will be used to generate the Catalyzes table.
        my %ecToRoles = ();
        # Loop through the subsystems. Our first task will be to create the
        # roles. We do this by looping through the subsystems and creating a
        # role hash. The hash tracks each role ID so that we don't create
        # duplicates. As we move along, we'll connect the roles and subsystems
        # and memorize up the reactions.
        my ($genomeID, $roleID);
        my %roleData = ();
        for my $subsysID (@subsysIDs) {
            # Get the subsystem object.
            my $sub = $fig->get_subsystem($subsysID);
            # Only proceed if the subsystem has a spreadsheet.
            if (defined($sub) && ! $sub->{empty_ss}) {
                Trace("Creating subsystem $subsysID.") if T(3);
                $loadSubsystem->Add("subsystemIn");
                # Create the subsystem record.
                my $curator = $sub->get_curator();
                my $notes = $sub->get_notes();
                my $version = $sub->get_version();
                my $description = $sub->get_description();
                $loadSubsystem->Put($subsysID, $curator, $version, $description, $notes);
                # Add the hope notes.
                my $hopeNotes = $sub->get_hope_curation_notes();
                if ($hopeNotes) {
                    $loadSubsystemHopeNotes->Put($sub, $hopeNotes);
                }
                # Now for the classification string. This comes back as a list
                # reference and we convert it to a space-delimited string.
                my $classList = $fig->subsystem_classification($subsysID);
                my $classString = join($FIG_Config::splitter, grep { $_ } @$classList);
                $loadSubsystemClass->Put($subsysID, $classString);
                # Connect it to its roles. Each role is a column in the subsystem spreadsheet.
                for (my $col = 0; defined($roleID = $sub->get_role($col)); $col++) {
                    # Get the role's abbreviation.
                    my $abbr = $sub->get_role_abbr($col);
                    # Get its essentiality.
                    my $aux = $fig->is_aux_role_in_subsystem($subsysID, $roleID);
                    # Get its reaction note.
                    my $hope_note = $sub->get_hope_reaction_notes($roleID) || "";
                    # Connect to this role.
                    $loadOccursInSubsystem->Add("roleIn");
                    $loadOccursInSubsystem->Put($roleID, $subsysID, $abbr, $aux, $col, $hope_note);
                    # If it's a new role, add it to the role table.
                    if (! exists $roleData{$roleID}) {
                        # Get the role's abbreviation.
                        # Add the role.
                        $loadRole->Put($roleID);
                        $roleData{$roleID} = 1;
                        # Check for an EC number.
                        if ($roleID =~ /\(EC (\d+\.\d+\.\d+\.\d+)\s*\)\s*$/) {
                            my $ec = $1;
                            $loadIsIdentifiedByEC->Put($roleID, $ec);
                            # Check to see if this is our first encounter with this EC.
                            if (exists $ecToRoles{$ec}) {
                                # No, so just add this role to the EC list.
                                push @{$ecToRoles{$ec}}, $roleID;
                            } else {
                                # Output this EC.
                                $loadRoleEC->Put($ec);
                                # Create its role list.
                                $ecToRoles{$ec} = [$roleID];
                            }
                        }
                    }
                }
                # Now we create the spreadsheet for the subsystem by matching roles to
                # genomes. Each genome is a row and each role is a column. We may need
                # to actually create the roles as we find them.
                Trace("Creating subsystem $subsysID spreadsheet.") if T(3);
                for (my $row = 0; defined($genomeID = $sub->get_genome($row)); $row++) {
                    # Only proceed if this is one of our genomes.
                    if (exists $genomeHash->{$genomeID}) {
                        # Count the PEGs and cells found for verification purposes.
                        my $pegCount = 0;
                        my $cellCount = 0;
                        # Create a list for the PEGs we find. This list will be used
                        # to generate cluster numbers.
                        my @pegsFound = ();
                        # Create a hash that maps spreadsheet IDs to PEGs. We will
                        # use this to generate the ContainsFeature data after we have
                        # the cluster numbers.
                        my %cellPegs = ();
                        # Get the genome's variant code for this subsystem.
                        my $variantCode = $sub->get_variant_code($row);
                        # Loop through the subsystem's roles. We use an index because it is
                        # part of the spreadsheet cell ID.
                        for (my $col = 0; defined($roleID = $sub->get_role($col)); $col++) {
                            # Get the features in the spreadsheet cell for this genome and role.
                            my @pegs = grep { !$fig->is_deleted_fid($_) } $sub->get_pegs_from_cell($row, $col);
                            # Only proceed if features exist.
                            if (@pegs > 0) {
                                # Create the spreadsheet cell.
                                $cellCount++;
                                my $cellID = "$subsysID:$genomeID:$col";
                                $loadSSCell->Put($cellID);
                                $loadIsGenomeOf->Put($genomeID, $cellID);
                                $loadIsRoleOf->Put($roleID, $cellID);
                                $loadHasSSCell->Put($subsysID, $cellID);
                                # Remember its features.
                                push @pegsFound, @pegs;
                                $cellPegs{$cellID} = \@pegs;
                                $pegCount += @pegs;
                            }
                        }
                        # If we found some cells for this genome, we need to compute clusters and
                        # denote it participates in the subsystem.
                        if ($pegCount > 0) {
                            Trace("$pegCount PEGs in $cellCount cells for $genomeID.") if T(3);
                            $loadParticipatesIn->Put($genomeID, $subsysID, $variantCode);
                            # Create a hash mapping PEG IDs to cluster numbers.
                            # We default to -1 for all of them.
                            my %clusterOf = map { $_ => -1 } @pegsFound;
                            # Partition the PEGs found into clusters.
                            my @clusters = $fig->compute_clusters([keys %clusterOf], $sub);
                            for (my $i = 0; $i <= $#clusters; $i++) {
                                my $subList = $clusters[$i];
                                for my $peg (@{$subList}) {
                                    $clusterOf{$peg} = $i;
                                }
                            }
                            # Create the ContainsFeature data.
                            for my $cellID (keys %cellPegs) {
                                my $cellList = $cellPegs{$cellID};
                                for my $cellPeg (@$cellList) {
                                    $loadContainsFeature->Put($cellID, $cellPeg, $clusterOf{$cellPeg});
                                }
                            }
                        }
                    }
                }
                # Now we need to generate the subsets. The subset names must be concatenated to
                # the subsystem name to make them unique keys. There are two types of subsets:
                # genome subsets and role subsets. We do the role subsets first.
                my @subsetNames = $sub->get_subset_names();
                for my $subsetID (@subsetNames) {
                    # Create the subset record.
                    my $actualID = "$subsysID:$subsetID";
                    $loadRoleSubset->Put($actualID);
                    # Connect the subset to the subsystem.
                    $loadHasRoleSubset->Put($subsysID, $actualID);
                    # Connect the subset to its roles.
                    my @roles = $sub->get_subsetC_roles($subsetID);
                    for my $roleID (@roles) {
                        $loadConsistsOfRoles->Put($actualID, $roleID);
                    }
                }
                # Next the genome subsets.
                @subsetNames = $sub->get_subset_namesR();
                for my $subsetID (@subsetNames) {
                    # Create the subset record.
                    my $actualID = "$subsysID:$subsetID";
                    $loadGenomeSubset->Put($actualID);
                    # Connect the subset to the subsystem.
                    $loadHasGenomeSubset->Put($subsysID, $actualID);
                    # Connect the subset to its genomes.
                    my @genomes = $sub->get_subsetR($subsetID);
                    for my $genomeID (@genomes) {
                        $loadConsistsOfGenomes->Put($actualID, $genomeID);
                    }
                }
            }
        }
        # Now we loop through the diagrams. We need to create the diagram records
        # and link each diagram to its roles. Note that only roles which occur
        # in subsystems (and therefore appear in the %ecToRoles hash) are
        # included.
        for my $map (@maps) {
            Trace("Loading diagram $map.") if T(3);
            # Get the diagram's descriptive name.
            my $name = $fig->map_name($map);
            $loadDiagram->Put($map, $name);
            # Now we need to link all the map's roles to it.
            # A hash is used to prevent duplicates.
            my %roleHash = ();
            for my $ec ($fig->map_to_ecs($map)) {
                if (exists $ecToRoles{$ec}) {
                    for my $role (@{$ecToRoles{$ec}}) {
                        if (! $roleHash{$role}) {
                            $loadRoleOccursIn->Put($role, $map);
                            $roleHash{$role} = 1;
                        }
                    }
                }
            }
        }
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}

=head3 LoadPropertyData

    my $stats = $spl->LoadPropertyData();

Load the attribute data from FIG into Sprout.

Attribute data in FIG corresponds to the Sprout concept of Property. As currently
implemented, each key-value attribute combination in the SEED corresponds to a
record in the B<Property> table. The B<HasProperty> relationship links the
features to the properties.

The SEED also allows attributes to be assigned to genomes, but this is not yet
supported by Sprout.

The following relations are loaded by this method.

    HasProperty
    Property

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadPropertyData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome hash.
    my $genomeHash = $self->{genomes};
    # Create load objects for each of the tables we're loading.
    my $loadProperty = $self->_TableLoader('Property');
    my $loadHasProperty = $self->_TableLoader('HasProperty');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating property data.") if T(2);
        # Create a hash for storing property IDs.
        my %propertyKeys = ();
        my $nextID = 1;
        # Get the attributes we intend to store in the property table.
        my $propKeys = $self->{propKeys};
        # Loop through the genomes.
        for my $genomeID (sort keys %{$genomeHash}) {
            $loadProperty->Add("genomeIn");
            Trace("Generating properties for $genomeID.") if T(3);
            # Initialize a counter.
            my $propertyCount = 0;
            # Get the properties for this genome's features.
            my @attributes = $fig->get_attributes("fig|$genomeID%", $propKeys);
            Trace("Property list built for $genomeID.") if T(3);
            # Loop through the results, creating HasProperty records.
            for my $attributeData (@attributes) {
                # Pull apart the attribute tuple.
                my ($fid, $key, $value, $url) = @{$attributeData};
                # Concatenate the key and value and check the "propertyKeys" hash to
                # see if we already have an ID for it. We use a tab for the separator
                # character.
                my $propertyKey = "$key\t$value";
                # Use the concatenated value to check for an ID. If no ID exists, we
                # create one.
                my $propertyID = $propertyKeys{$propertyKey};
                if (! $propertyID) {
                    # Here we need to create a new property ID for this key/value pair.
                    $propertyKeys{$propertyKey} = $nextID;
                    $propertyID = $nextID;
                    $nextID++;
                    $loadProperty->Put($propertyID, $key, $value);
                }
                # Create the HasProperty entry for this feature/property association.
                $loadHasProperty->Put($fid, $propertyID, $url);
                $propertyCount++;
            }
            # Update the statistics.
            Trace("$propertyCount attributes processed.") if T(3);
            $loadHasProperty->Add("propertiesIn", $propertyCount);
        }
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}

=head3 LoadAnnotationData

    my $stats = $spl->LoadAnnotationData();

Load the annotation data from FIG into Sprout.

Sprout annotations encompass both the assignments and the annotations in SEED.
These describe the function performed by a PEG as well as any other useful
information that may aid in identifying its purpose.

The following relations are loaded by this method.

    Annotation
    IsTargetOfAnnotation
    SproutUser
    MadeAnnotation

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadAnnotationData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome hash.
    my $genomeHash = $self->{genomes};
    # Create load objects for each of the tables we're loading.
    my $loadAnnotation = $self->_TableLoader('Annotation');
    my $loadIsTargetOfAnnotation = $self->_TableLoader('IsTargetOfAnnotation');
    my $loadSproutUser = $self->_TableLoader('SproutUser');
    my $loadUserAccess = $self->_TableLoader('UserAccess');
    my $loadMadeAnnotation = $self->_TableLoader('MadeAnnotation');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating annotation data.") if T(2);
        # Create a hash of user names. We'll use this to prevent us from generating duplicate
        # user records.
        my %users = ( FIG => 1, master => 1 );
        # Put in FIG and "master".
        $loadSproutUser->Put("FIG", "Fellowship for Interpretation of Genomes");
        $loadUserAccess->Put("FIG", 1);
        $loadSproutUser->Put("master", "Master User");
        $loadUserAccess->Put("master", 1);
        # Get the current time.
        my $time = time();
        # Loop through the genomes.
        for my $genomeID (sort keys %{$genomeHash}) {
            Trace("Processing $genomeID.") if T(3);
            # Create a hash of timestamps. We use this to prevent duplicate time stamps
            # from showing up for a single PEG's annotations.
            my %seenTimestamps = ();
            # Get the genome's annotations.
            my @annotations = $fig->read_all_annotations($genomeID);
            Trace("Processing annotations.") if T(2);
            for my $tuple (@annotations) {
                # Get the annotation tuple.
                my ($peg, $timestamp, $user, $text) = @{$tuple};
                # Here we fix up the annotation text. "\r" is removed,
                # and "\t" and "\n" are escaped. Note we use the "gs"
                # modifier so that new-lines inside the text do not
                # stop the substitution search.
                $text =~ s/\r//gs;
                $text =~ s/\t/\\t/gs;
                $text =~ s/\n/\\n/gs;
                # Change assignments by the master user to FIG assignments.
                $text =~ s/Set master function/Set FIG function/s;
                # Insure the time stamp is valid.
                if ($timestamp =~ /^\d+$/) {
                    # Here it's a number. We need to insure the one we use to form
                    # the key is unique.
                    my $keyStamp = $timestamp;
                    while ($seenTimestamps{"$peg:$keyStamp"}) {
                        $keyStamp++;
                    }
                    my $annotationID = "$peg:$keyStamp";
                    $seenTimestamps{$annotationID} = 1;
                    # Insure the user exists.
                    if (! $users{$user}) {
                        $loadSproutUser->Put($user, "SEED user");
                        $loadUserAccess->Put($user, 1);
                        $users{$user} = 1;
                    }
                    # Generate the annotation.
                    $loadAnnotation->Put($annotationID, $timestamp, $text);
                    $loadIsTargetOfAnnotation->Put($peg, $annotationID);
                    $loadMadeAnnotation->Put($user, $annotationID);
                } else {
                    # Here we have an invalid time stamp.
                    Trace("Invalid time stamp \"$timestamp\" in annotations for $peg.") if T(1);
                }
            }
        }
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}

=head3 LoadSourceData

    my $stats = $spl->LoadSourceData();

Load the source data from FIG into Sprout.

Source data links genomes to information about the organizations that
mapped it.

The following relations are loaded by this method.

    ComesFrom
    Source
    SourceURL

There is no direct support for source attribution in FIG, so we access the SEED
files directly.

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadSourceData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome hash.
    my $genomeHash = $self->{genomes};
    # Create load objects for each of the tables we're loading.
    my $loadComesFrom = $self->_TableLoader('ComesFrom');
    my $loadSource = $self->_TableLoader('Source');
    my $loadSourceURL = $self->_TableLoader('SourceURL');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating annotation data.") if T(2);
        # Create hashes to collect the Source information.
        my %sourceURL = ();
        my %sourceDesc = ();
        # Loop through the genomes.
        my $line;
        for my $genomeID (sort keys %{$genomeHash}) {
            Trace("Processing $genomeID.") if T(3);
            # Open the project file.
            if ((open(TMP, "<$FIG_Config::organisms/$genomeID/PROJECT")) &&
                defined($line = <TMP>)) {
                chomp $line;
                my($sourceID, $desc, $url) = split(/\t/,$line);
                $loadComesFrom->Put($genomeID, $sourceID);
                if ($url && ! exists $sourceURL{$sourceID}) {
                    $loadSourceURL->Put($sourceID, $url);
                    $sourceURL{$sourceID} = 1;
                }
                if ($desc) {
                    $sourceDesc{$sourceID} = $desc;
                } elsif (! exists $sourceDesc{$sourceID}) {
                    $sourceDesc{$sourceID} = $sourceID;
                }
            }
            close TMP;
        }
        # Write the source descriptions.
        for my $sourceID (keys %sourceDesc) {
            $loadSource->Put($sourceID, $sourceDesc{$sourceID});
        }
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}

=head3 LoadExternalData

    my $stats = $spl->LoadExternalData();

Load the external data from FIG into Sprout.

External data contains information about external feature IDs.

The following relations are loaded by this method.

    ExternalAliasFunc
    ExternalAliasOrg

The support for external IDs in FIG is hidden beneath layers of other data, so
we access the SEED files directly to create these tables. This is also one of
the few load methods that does not proceed genome by genome.

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadExternalData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome hash.
    my $genomeHash = $self->{genomes};
    # Convert the genome hash. We'll get the genus and species for each genome and make
    # it the key.
    my %speciesHash = map { $fig->genus_species($_) => $_ } (keys %{$genomeHash});
    # Create load objects for each of the tables we're loading.
    my $loadExternalAliasFunc = $self->_TableLoader('ExternalAliasFunc');
    my $loadExternalAliasOrg = $self->_TableLoader('ExternalAliasOrg');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating external data.") if T(2);
        # We loop through the files one at a time. First, the organism file.
        Open(\*ORGS, "sort +0 -1 -u -t\"\t\" $FIG_Config::global/ext_org.table |");
        my $orgLine;
        while (defined($orgLine = <ORGS>)) {
            # Clean the input line.
            chomp $orgLine;
            # Parse the organism name.
            my ($protID, $name) = split /\s*\t\s*/, $orgLine;
            $loadExternalAliasOrg->Put($protID, $name);
        }
        close ORGS;
        # Now the function file.
        my $funcLine;
        Open(\*FUNCS, "sort +0 -1 -u -t\"\t\" $FIG_Config::global/ext_func.table |");
        while (defined($funcLine = <FUNCS>)) {
            # Clean the line ending.
            chomp $funcLine;
            # Only proceed if the line is non-blank.
            if ($funcLine) {
                # Split it into fields.
                my @funcFields = split /\s*\t\s*/, $funcLine;
                # If there's an EC number, append it to the description.
                if ($#funcFields >= 2 && $funcFields[2] =~ /^(EC .*\S)/) {
                    $funcFields[1] .= " $1";
                }
                # Output the function line.
                $loadExternalAliasFunc->Put(@funcFields[0,1]);
            }
        }
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}


=head3 LoadReactionData

    my $stats = $spl->LoadReactionData();

Load the reaction data from FIG into Sprout.

Reaction data connects reactions to the compounds that participate in them.

The following relations are loaded by this method.

    Reaction
    ReactionURL
    Compound
    CompoundName
    CompoundCAS
    IsIdentifiedByCAS
    HasCompoundName
    IsAComponentOf
    Scenario
    Catalyzes
    HasScenario
    IsInputFor
    IsOutputOf
    ExcludesReaction
    IncludesReaction
    IsOnDiagram
    IncludesReaction

This method proceeds reaction by reaction rather than genome by genome.

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadReactionData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Create load objects for each of the tables we're loading.
    my $loadReaction = $self->_TableLoader('Reaction');
    my $loadReactionURL = $self->_TableLoader('ReactionURL');
    my $loadCompound = $self->_TableLoader('Compound');
    my $loadCompoundName = $self->_TableLoader('CompoundName');
    my $loadCompoundCAS = $self->_TableLoader('CompoundCAS');
    my $loadIsAComponentOf = $self->_TableLoader('IsAComponentOf');
    my $loadIsIdentifiedByCAS = $self->_TableLoader('IsIdentifiedByCAS');
    my $loadHasCompoundName = $self->_TableLoader('HasCompoundName');
    my $loadScenario = $self->_TableLoader('Scenario');
    my $loadHasScenario = $self->_TableLoader('HasScenario');
    my $loadIsInputFor = $self->_TableLoader('IsInputFor');
    my $loadIsOutputOf = $self->_TableLoader('IsOutputOf');
    my $loadIsOnDiagram = $self->_TableLoader('IsOnDiagram');
    my $loadIncludesReaction = $self->_TableLoader('IncludesReaction');
    my $loadExcludesReaction = $self->_TableLoader('ExcludesReaction');
    my $loadCatalyzes = $self->_TableLoader('Catalyzes');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating reaction data.") if T(2);
        # We need some hashes to prevent duplicates.
        my %compoundNames = ();
        my %compoundCASes = ();
        # First we create the compounds.
        my %compounds = map { $_ => 1 } $fig->all_compounds();
        for my $cid (keys %compounds) {
            # Check for names.
            my @names = $fig->names_of_compound($cid);
            # Each name will be given a priority number, starting with 1.
            my $prio = 1;
            for my $name (@names) {
                if (! exists $compoundNames{$name}) {
                    $loadCompoundName->Put($name);
                    $compoundNames{$name} = 1;
                }
                $loadHasCompoundName->Put($cid, $name, $prio++);
            }
            # Create the main compound record. Note that the first name
            # becomes the label.
            my $label = (@names > 0 ? $names[0] : $cid);
            $loadCompound->Put($cid, $label);
            # Check for a CAS ID.
            my $cas = $fig->cas($cid);
            if ($cas) {
                $loadIsIdentifiedByCAS->Put($cid, $cas);
                if (! exists $compoundCASes{$cas}) {
                    $loadCompoundCAS->Put($cas);
                    $compoundCASes{$cas} = 1;
                }
            }
        }
        # All the compounds are set up, so we need to loop through the reactions next. First,
        # we initialize the discriminator index. This is a single integer used to insure
        # duplicate elements in a reaction are not accidentally collapsed.
        my $discrim = 0;
        my %reactions = map { $_ => 1 } $fig->all_reactions();
        for my $reactionID (keys %reactions) {
            # Create the reaction record.
            $loadReaction->Put($reactionID, $fig->reversible($reactionID));
            # Compute the reaction's URL.
            my $url = HTML::reaction_link($reactionID);
            # Put it in the ReactionURL table.
            $loadReactionURL->Put($reactionID, $url);
            # Now we need all of the reaction's compounds. We get these in two phases,
            # substrates first and then products.
            for my $product (0, 1) {
                # Get the compounds of the current type for the current reaction. FIG will
                # give us 3-tuples: [ID, stoichiometry, main-flag]. At this time we do not
                # have location data in SEED, so it defaults to the empty string.
                my @compounds = $fig->reaction2comp($reactionID, $product);
                for my $compData (@compounds) {
                    # Extract the compound data from the current tuple.
                    my ($cid, $stoich, $main) = @{$compData};
                    # Link the compound to the reaction.
                    $loadIsAComponentOf->Put($cid, $reactionID, $discrim++, "", $main,
                                             $product, $stoich);
                }
            }
        }
        # Now we run through the subsystems and roles, generating the scenarios
        # and connecting the reactions. We'll need some hashes to prevent
        # duplicates and a counter for compound group keys.
        my %roles = ();
        my %scenarios = ();
        my @subsystems = $fig->all_subsystems();
        for my $subName (@subsystems) {
            my $sub = $fig->get_subsystem($subName);
            Trace("Processing $subName reactions.") if T(3);
            # Get the subsystem's reactions.
            my %reactions = $sub->get_hope_reactions();
            # Loop through the roles, connecting them to the reactions.
            for my $role (keys %reactions) {
                # Only process this role if it is new.
                if (! $roles{$role}) {
                    $roles{$role} = 1;
                    my @reactions = @{$reactions{$role}};
                    for my $reaction (@reactions) {
                        $loadCatalyzes->Put($role, $reaction);
                    }
                }
            }
            Trace("Processing $subName scenarios.") if T(3);
            # Get the subsystem's scenarios.
            my @scenarioNames = $sub->get_hope_scenario_names();
            # Loop through the scenarios, creating scenario data.
            for my $scenarioName (@scenarioNames) {
                # Link this scenario to this subsystem.
                $loadHasScenario->Put($subName, $scenarioName);
                # If this scenario is new, we need to create it.
                if (! $scenarios{$scenarioName}) {
                    Trace("Creating scenario $scenarioName.") if T(3);
                    $scenarios{$scenarioName} = 1;
                    # Create the scenario itself.
                    $loadScenario->Put($scenarioName);
                    # Attach the input compounds.
                    for my $input ($sub->get_hope_input_compounds($scenarioName)) {
                        $loadIsInputFor->Put($input, $scenarioName);
                    }
                    # Now we need to set up the output compounds. They come in two
                    # groups, which we mark 0 and 1.
                    my $outputGroup = 0;
                    # Set up the output compounds.
                    for my $outputGroup ($sub->get_hope_output_compounds($scenarioName)) {
                        # Attach the compounds.
                        for my $compound (@$outputGroup) {
                            $loadIsOutputOf->Put($scenarioName, $compound, $outputGroup);
                        }
                    }
                    # Create the reaction lists.
                    my @addReactions = $sub->get_hope_additional_reactions($scenarioName);
                    for my $reaction (@addReactions) {
                        $loadIncludesReaction->Put($scenarioName, $reaction);
                    }
                    my @notReactions = $sub->get_hope_ignore_reactions($scenarioName);
                    for my $reaction (@notReactions) {
                        $loadExcludesReaction->Put($scenarioName, $reaction);
                    }
                    # Link the maps.
                    my @maps = $sub->get_hope_map_ids($scenarioName);
                    for my $map (@maps) {
                        $loadIsOnDiagram->Put($scenarioName, "map$map");
                    }
                }
            }
        }
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}

=head3 LoadSynonymData

    my $stats = $spl->LoadSynonymData();

Load the synonym groups into Sprout.

The following relations are loaded by this method.

    SynonymGroup
    IsSynonymGroupFor

The source information for these relations is taken from the C<maps_to_id> method
of the B<FIG> object. Unfortunately, to make this work, we need to use direct
SQL against the FIG database.

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadSynonymData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome hash.
    my $genomeHash = $self->{genomes};
    # Create a load object for the table we're loading.
    my $loadSynonymGroup = $self->_TableLoader('SynonymGroup');
    my $loadIsSynonymGroupFor = $self->_TableLoader('IsSynonymGroupFor');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating synonym group data.") if T(2);
        # Get the database handle.
        my $dbh = $fig->db_handle();
        # Ask for the synonyms. Note that "maps_to" is a group name, and "syn_id" is a PEG ID or alias.
        my $sth = $dbh->prepare_command("SELECT maps_to, syn_id FROM peg_synonyms ORDER BY maps_to");
        my $result = $sth->execute();
        if (! defined($result)) {
            Confess("Database error in Synonym load: " . $sth->errstr());
        } else {
            Trace("Processing synonym results.") if T(2);
            # Remember the current synonym.
            my $current_syn = "";
            # Count the features.
            my $featureCount = 0;
            my $entryCount = 0;
            # Loop through the synonym/peg pairs.
            while (my @row = $sth->fetchrow()) {
                # Get the synonym group ID and feature ID.
                my ($syn_id, $peg) = @row;
                # Count this row.
                $entryCount++;
                if ($entryCount % 1000 == 0) {
                    Trace("$entryCount rows processed.") if T(3);
                }
                # Insure it's for one of our genomes.
                my $genomeID = FIG::genome_of($peg);
                if (exists $genomeHash->{$genomeID}) {
                    # Verify the synonym.
                    if ($syn_id ne $current_syn) {
                        # It's new, so put it in the group table.
                        $loadSynonymGroup->Put($syn_id);
                        $current_syn = $syn_id;
                    }
                    # Connect the synonym to the peg.
                    $loadIsSynonymGroupFor->Put($syn_id, $peg);
                    # Count this feature.
                    $featureCount++;
                    if ($featureCount % 1000 == 0) {
                        Trace("$featureCount features processed.") if T(3);
                    }
                }
            }
            Trace("$entryCount rows produced $featureCount features.") if T(2);
        }
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}

=head3 LoadFamilyData

    my $stats = $spl->LoadFamilyData();

Load the protein families into Sprout.

The following relations are loaded by this method.

    Family
    IsFamilyForFeature

The source information for these relations is taken from the C<families_for_protein>,
C<family_function>, and C<sz_family> methods of the B<FIG> object.

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadFamilyData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome hash.
    my $genomeHash = $self->{genomes};
    # Create load objects for the tables we're loading.
    my $loadFamily = $self->_TableLoader('Family');
    my $loadIsFamilyForFeature = $self->_TableLoader('IsFamilyForFeature');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating family data.") if T(2);
        # Create a hash for the family IDs.
        my %familyHash = ();
        # Loop through the genomes.
        for my $genomeID (sort keys %{$genomeHash}) {
            Trace("Processing features for $genomeID.") if T(2);
            # Loop through this genome's PEGs.
            for my $fid ($fig->all_features($genomeID, "peg")) {
                $loadIsFamilyForFeature->Add("features", 1);
                # Get this feature's families.
                my @families = $fig->families_for_protein($fid);
                # Loop through the families, connecting them to the feature.
                for my $family (@families) {
                    $loadIsFamilyForFeature->Put($family, $fid);
                    # If this is a new family, create a record for it.
                    if (! exists $familyHash{$family}) {
                        $familyHash{$family} = 1;
                        $loadFamily->Add("families", 1);
                        my $size = $fig->sz_family($family);
                        my $func = $fig->family_function($family);
                        $loadFamily->Put($family, $size, $func);
                    }
                }
            }
        }
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}

=head3 LoadDrugData

    my $stats = $spl->LoadDrugData();

Load the drug target data into Sprout.

The following relations are loaded by this method.

    PDB
    DocksWith
    IsProteinForFeature
    Ligand

The source information for these relations is taken from attributes. The
C<PDB> attribute links a PDB to a feature, and is used to build B<IsProteinForFeature>.
The C<zinc_name> attribute describes the ligands. The C<docking_results>
attribute contains the information for the B<DocksWith> relationship. It is
expected that additional attributes and tables will be added in the future.

=over 4

=item RETURNS

Returns a statistics object for the loads.

=back

=cut
#: Return Type $%;
sub LoadDrugData {
    # Get this object instance.
    my ($self) = @_;
    # Get the FIG object.
    my $fig = $self->{fig};
    # Get the genome hash.
    my $genomeHash = $self->{genomes};
    # Create load objects for the tables we're loading.
    my $loadPDB = $self->_TableLoader('PDB');
    my $loadLigand = $self->_TableLoader('Ligand');
    my $loadIsProteinForFeature = $self->_TableLoader('IsProteinForFeature');
    my $loadDocksWith = $self->_TableLoader('DocksWith');
    if ($self->{options}->{loadOnly}) {
        Trace("Loading from existing files.") if T(2);
    } else {
        Trace("Generating drug target data.") if T(2);
        # First comes the "DocksWith" relationship. This will give us a list of PDBs.
        # We can also encounter PDBs when we process "IsProteinForFeature". To manage
        # this process, PDB information is collected in a hash table and then
        # unspooled after both relationships are created.
        my %pdbHash = ();
        Trace("Generating docking data.") if T(2);
        # Get all the docking data. This may cause problems if there are too many PDBs,
        # at which point we'll need another algorithm. The indicator that this is
        # happening will be a timeout error in the next statement.
        my @dockData = $fig->query_attributes('$key = ? AND $value < ?',
                                              ['docking_results', $FIG_Config::dockLimit]);
        Trace(scalar(@dockData) . " rows of docking data found.") if T(3);
        for my $dockData (@dockData) {
            # Get the docking data components.
            my ($pdbID, $docking_key, @valueData) = @{$dockData};
            # Fix the PDB ID. It's supposed to be lower-case, but this does not always happen.
            $pdbID = lc $pdbID;
            # Strip off the object type.
            $pdbID =~ s/pdb://;
            # Extract the ZINC ID from the docking key. Note that there are two possible
            # formats.
            my (undef, $zinc_id) = $docking_key =~ /^docking_results::(ZINC)?(\d+)$/;
            if (! $zinc_id) {
                Trace("Invalid docking result key $docking_key for $pdbID.") if T(0);
                $loadDocksWith->Add("errors");
            } else {
                # Get the pieces of the value and parse the energy.
                # Note that we don't care about the rank, since
                # we can sort on the energy level itself in our database.
                my ($energy, $tool, $type) = @valueData;
                my ($rank, $total, $vanderwaals, $electrostatic) = split /\s*;\s*/, $energy;
                # Ignore predicted results.
                if ($type ne "Predicted") {
                    # Count this docking result.
                    if (! exists $pdbHash{$pdbID}) {
                        $pdbHash{$pdbID} = 1;
                    } else {
                        $pdbHash{$pdbID}++;
                    }
                    # Write the result to the output.
                    $loadDocksWith->Put($pdbID, $zinc_id, $electrostatic, $type, $tool,
                                        $total, $vanderwaals);
                }
            }
        }
        Trace("Connecting features.") if T(2);
        # Loop through the genomes.
        for my $genome (sort keys %{$genomeHash}) {
            Trace("Generating PDBs for $genome.") if T(3);
            # Get all of the PDBs that BLAST against this genome's features.
            my @attributeData = $fig->get_attributes("fig|$genome%", 'PDB::%');
            for my $pdbData (@attributeData) {
                # The PDB ID is coded as a subkey.
                if ($pdbData->[1] !~ /PDB::(.+)/i) {
                    Trace("Invalid PDB ID \"$pdbData->[1]\" in attribute table.") if T(0);
                    $loadPDB->Add("errors");
                } else {
                    my $pdbID = $1;
                    # Insure the PDB is in the hash.
                    if (! exists $pdbHash{$pdbID}) {
                        $pdbHash{$pdbID} = 0;
                    }
                    # The score and locations are coded in the attribute value.
                    if ($pdbData->[2] !~ /^([^;]+)(.*)$/) {
                        Trace("Invalid PDB data for $pdbID and feature $pdbData->[0].") if T(0);
                        $loadIsProteinForFeature->Add("errors");
                    } else {
                        my ($score, $locData) = ($1,$2);
                        # The location data may not be present, so we have to start with some
                        # defaults and then check.
                        my ($start, $end) = (1, 0);
                        if ($locData) {
                            $locData =~ /(\d+)-(\d+)/;
                            $start = $1;
                            $end = $2;
                        }
                        # If we still don't have the end location, compute it from
                        # the feature length.
                        if (! $end) {
                            # Most features have one location, but we do a list iteration
                            # just in case.
                            my @locations = $fig->feature_location($pdbData->[0]);
                            $end = 0;
                            for my $loc (@locations) {
                                my $locObject = BasicLocation->new($loc);
                                $end += $locObject->Length;
                            }
                        }
                        # Decode the score.
                        my $realScore = FIGRules::DecodeScore($score);
                        # Connect the PDB to the feature.
                        $loadIsProteinForFeature->Put($pdbID, $pdbData->[0], $start, $realScore, $end);
                    }
                }
            }
        }
        # We've got all our PDBs now, so we unspool them from the hash.
        Trace("Generating PDBs. " . scalar(keys %pdbHash) . " found.") if T(2);
        my $count = 0;
        for my $pdbID (sort keys %pdbHash) {
            $loadPDB->Put($pdbID, $pdbHash{$pdbID});
            $count++;
            Trace("$count PDBs processed.") if T(3) && ($count % 500 == 0);
        }
        # Finally we create the ligand table. This information can be found in the
        # zinc_name attribute.
        Trace("Loading ligands.") if T(2);
        # The ligand list is huge, so we have to get it in pieces. We also have to check for duplicates.
        my $last_zinc_id = "";
        my $zinc_id = "";
        my $done = 0;
        while (! $done) {
            # Get the next 10000 ligands. We insist that the object ID is greater than
            # the last ID we processed.
            Trace("Loading batch starting with ZINC:$zinc_id.") if T(3);
            my @attributeData = $fig->query_attributes('$object > ? AND $key = ? ORDER BY $object LIMIT 10000',
                                                       ["ZINC:$zinc_id", "zinc_name"]);
            Trace(scalar(@attributeData) . " attribute rows returned.") if T(3);
            if (! @attributeData) {
                # Here there are no attributes left, so we quit the loop.
                $done = 1;
            } else {
                # Process the attribute data we've received.
                for my $zinc_data (@attributeData) {
                    # The ZINC ID is found in the first return column, prefixed with the word ZINC.
                    if ($zinc_data->[0] =~ /^ZINC:(\d+)$/) {
                        $zinc_id = $1;
                        # Check for a duplicate.
                        if ($zinc_id eq $last_zinc_id) {
                            $loadLigand->Add("duplicate");
                        } else {
                            # Here it's safe to output the ligand. The ligand name is the attribute value
                            # (third column in the row).
                            $loadLigand->Put($zinc_id, $zinc_data->[2]);
                            # Insure we don't try to add this ID again.
                            $last_zinc_id = $zinc_id;
                        }
                    } else {
                        Trace("Invalid zinc ID \"$zinc_data->[0]\" in attribute table.") if T(0);
                        $loadLigand->Add("errors");
                    }
                }
            }
        }
        Trace("Ligands loaded.") if T(2);
    }
    # Finish the load.
    my $retVal = $self->_FinishAll();
    return $retVal;
}


=head2 Internal Utility Methods

=head3 SpecialAttribute

    my $count = SproutLoad::SpecialAttribute($id, \@attributes, $idxMatch, \@idxValues, $pattern, $loader);

Look for special attributes of a given type. A special attribute is found by comparing one of
the columns of the incoming attribute list to a search pattern. If a match is found, then
a set of columns is put into an output table connected to the specified ID.

For example, when processing features, the attribute list we look at has three columns: attribute
name, attribute value, and attribute value HTML. The IEDB attribute exists if the attribute name
begins with C<iedb_>. The call signature is therefore

    my $found = SpecialAttribute($fid, \@attributeList, 0, [0,2], '^iedb_', $loadFeatureIEDB);

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

Reference to a list containing the indexes in each tuple of the columns to be put as
the second column of the output.

=item pattern

Pattern to be matched against the specified column. The match will be case-insensitive.

=item loader

An object to which each output record will be put. Usually this is an B<ERDBLoad> object,
but technically it could be anything with a C<Put> method.

=item RETURN

Returns a count of the matches found.

=item

=back

=cut

sub SpecialAttribute {
    # Get the parameters.
    my ($id, $attributes, $idxMatch, $idxValues, $pattern, $loader) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Loop through the attribute rows.
    for my $row (@{$attributes}) {
        # Check for a match.
        if ($row->[$idxMatch] =~ m/$pattern/i) {
            # We have a match, so output a row. This is a bit tricky, since we may
            # be putting out multiple columns of data from the input.
            my $value = join(" ", map { $row->[$_] } @{$idxValues});
            $loader->Put($id, $value);
            $retVal++;
        }
    }
    Trace("$retVal special attributes found for $id and loader " . $loader->RelName() . ".") if T(4) && $retVal;
    # Return the number of matches.
    return $retVal;
}

=head3 TableLoader

Create an ERDBLoad object for the specified table. The object is also added to
the internal list in the C<loaders> property of this object. That enables the
L</FinishAll> method to terminate all the active loads.

This is an instance method.

=over 4

=item tableName

Name of the table (relation) being loaded.

=item RETURN

Returns an ERDBLoad object for loading the specified table.

=back

=cut

sub _TableLoader {
    # Get the parameters.
    my ($self, $tableName) = @_;
    # Create the load object.
    my $retVal = ERDBLoad->new($self->{erdb}, $tableName, $self->{loadDirectory}, $self->LoadOnly);
    # Cache it in the loader list.
    push @{$self->{loaders}}, $retVal;
    # Return it to the caller.
    return $retVal;
}

=head3 FinishAll

Finish all the active loads on this object.

When a load is started by L</TableLoader>, the controlling B<ERDBLoad> object is cached in
the list pointed to be the C<loaders> property of this object. This method pops the loaders
off the list and finishes them to flush out any accumulated residue.

This is an instance method.

=over 4

=item RETURN

Returns a statistics object containing the accumulated statistics for the load.

=back

=cut

sub _FinishAll {
    # Get this object instance.
    my ($self) = @_;
    # Create the statistics object.
    my $retVal = Stats->new();
    # Get the loader list.
    my $loadList = $self->{loaders};
    # Create a hash to hold the statistics objects, keyed on relation name.
    my %loaderHash = ();
    # Loop through the list, finishing the loads. Note that if the finish fails, we die
    # ignominiously. At some future point, we want to make the loads more restartable.
    while (my $loader = pop @{$loadList}) {
        # Get the relation name.
        my $relName = $loader->RelName;
        # Check the ignore flag.
        if ($loader->Ignore) {
            Trace("Relation $relName not loaded.") if T(2);
        } else {
            # Here we really need to finish.
            Trace("Finishing $relName.") if T(2);
            my $stats = $loader->Finish();
            $loaderHash{$relName} = $stats;
        }
    }
    # Now we loop through again, actually loading the tables. We want to finish before
    # loading so that if something goes wrong at this point, all the load files are usable
    # and we don't have to redo all that work.
    for my $relName (sort keys %loaderHash) {
        # Get the statistics for this relation.
        my $stats = $loaderHash{$relName};
        # Check for a database load.
        if ($self->{options}->{dbLoad}) {
            # Here we want to use the load file just created to load the database.
            Trace("Loading relation $relName.") if T(2);
            my $newStats = $self->{sprout}->LoadUpdate(1, [$relName]);
            # Accumulate the statistics from the DB load.
            $stats->Accumulate($newStats);
        }
        $retVal->Accumulate($stats);
        Trace("Statistics for $relName:\n" . $stats->Show()) if T(2);
    }
    # Return the load statistics.
    return $retVal;
}

=head3 GetGenomeAttributes

    my $aHashRef = GetGenomeAttributes($fig, $genomeID, \@fids, \@propKeys);

Return a hash of attributes keyed on feature ID. This method gets all the NMPDR-related
attributes for all the features of a genome in a single call, then organizes them into
a hash.

=over 4

=item fig

FIG-like object for accessing attributes.

=item genomeID

ID of the genome who's attributes are desired.

=item fids

Reference to a list of the feature IDs whose attributes are to be kept.

=item propKeys

A list of the keys to retrieve.

=item RETURN

Returns a reference to a hash. The key of the hash is the feature ID. The value is the
reference to a list of the feature's attribute tuples. Each tuple contains the feature ID,
the attribute key, and one or more attribute values.

=back

=cut

sub GetGenomeAttributes {
    # Get the parameters.
    my ($fig, $genomeID, $fids, $propKeys) = @_;
    # Declare the return variable.
    my $retVal = {};
    # Initialize the hash. This not only enables us to easily determine which FIDs to
    # keep, it insures that the caller sees a list reference for every known fid,
    # simplifying the logic.
    for my $fid (@{$fids}) {
        $retVal->{$fid} = [];
    }
    # Get the attributes. If ev_code_cron is running, we may get a timeout error, so
    # an eval is used.
    my @aList = ();
    eval {
        @aList = $fig->get_attributes("fig|$genomeID%", $propKeys);
        Trace(scalar(@aList) . " attributes returned for genome $genomeID.") if T(3);
    };
    # Check for a problem.
    if ($@) {
        Trace("Retrying attributes for $genomeID due to error: $@") if T(1);
        # Our fallback plan is to process the attributes in blocks of 100. This is much slower,
        # but allows us to continue processing.
        my $nFids = scalar @{$fids};
        for (my $i = 0; $i < $nFids; $i += 100) {
            # Determine the index of the last feature ID we'll be specifying on this pass.
            # Normally it's $i + 99, but if we're close to the end it may be less.
            my $end = ($i + 100 > $nFids ? $nFids - 1 : $i + 99);
            # Get a slice of the fid list.
            my @slice = @{$fids}[$i .. $end];
            # Get the relevant attributes.
            Trace("Retrieving attributes for fids $i to $end.") if T(3);
            my @aShort = $fig->get_attributes(\@slice, $propKeys);
            Trace(scalar(@aShort) . " attributes returned for fids $i to $end.") if T(3);
            push @aList, @aShort;
        }
    }
    # Now we should have all the interesting attributes in @aList. Populate the hash with
    # them.
    for my $aListEntry (@aList) {
        my $fid = $aListEntry->[0];
        if (exists $retVal->{$fid}) {
            push @{$retVal->{$fid}}, $aListEntry;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 GetCommaList

    my $string = GetCommaList($value);

Create a comma-separated list of the values in a list reference. If the
list reference is a scalar, it will be returned unchanged. If it is
undefined, an empty string will be returned. The idea is that we may be
looking at a string, a list, or nothing, but whatever comes out will be a
string.

=over 4

=item value

Reference to a list of values to be assembled into the return string.

=item RETURN

Returns a scalar string containing the content of the input value.

=back

=cut

sub GetCommaList {
    # Get the parameters.
    my ($value) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Only proceed if we have an input value.
    if (defined $value) {
        # Analyze the input value.
        if (ref $value eq 'ARRAY') {
            # Here it's a list reference.
            $retVal = join(", ", @$value);
        } else {
            # Here it's not. Flatten it to a scalar.
            $retVal = "$value";
        }
    }
    # Return the result.
    return $retVal;
}


1;
