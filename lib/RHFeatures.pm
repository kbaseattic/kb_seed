#!/usr/bin/perl -w

package RHFeatures;

    use strict;
    use Tracer;
    use Sprout;
    use SearchHelper;
    use AliasAnalysis;
    use HTML;
    use base 'ResultHelper';

=head1 Feature Result Helper

=head2 Introduction

The feature result helper is used for searches where the result is a list of
features. As such, it is the biggest and most popular of all the result
helpers.

Because features are the bread and butter of the NMPDR, this helper provides
a set of built-in filters. Each built-in filter is associated
with a form fragment. The L</FilteredQuery> method returns a list of features
that satisfy all the filters used. The L</DefaultResultColumns> method will add
to the output columns relevant to the parameters of the search.

The default action of this helper is to assume no values are required for any of the
filters. In the case of a word search, you can use the method L</KeywordsRequired> to
denote that an empty keyword list is unacceptable.

=head3 ColumnFieldMap

The column field map converts ERDB field names to corresponding column names. This is
required by the [[TargetCriterionPm]] subclasses to determine the proper method for
adding a field to the result display. If the field is one of this helper's built-in
columns, then it is added as an optional column; otherwise, it is added as an extra
column. The optional columns are preferred, because they can be computed more
efficiently. Whenever you add a new column to this helper, you will need to update
this list.

=cut

use constant COLUMN_FIELD_MAP => {
    'Feature(id)' => 'fid',
    'FeatureAlias(id)' => 'alias',
    'IsAliasOf(from-link)' => 'alias',
    'Feature(assignment)' => 'function',
    'Genome(id)' => 'orgName',
    'Genome(scientific-name)' => 'orgName',
    'Genome(genus)' => 'orgName',
    'Genome(species)' => 'orgName',
    'Genome(unique-characterization)' => 'orgName',
    'HasRoleInSubsystem(to-link)' => 'subsystem',
    'Subsystem(id)' => 'subsystem',
    'IsIdentifiedByEC(to-link)' => 'function',
};

=head2 Search Criterion Table

The Search Criterion Table is a hash of [[TargetCriterionPm]] objects. The hash is
keyed on search type so that it can be used to quickly find the relevant criterion
object as soon as we know the type. The types must all be simple text! Fancy stuff
will break the javascript. The first criterion type is a special one that matches
every feature and doesn't display any controls.

The table is used to make useful fields available in feature search results. It is
also used by [[SHTargetSearchPm]] to define its search criteria. In both cases, the
B<GetCriteria> method is used to create the table.

It is a huge error if one of the criteria has the same name as a built-in column.
If a criterion is redundant with respect to a built-in column, then the B<colName>
method of that criterion should return the built-in column name.

=head3 GetCriteria

    my $tcHash = $rhelp->GetCriteria();

Return a reference to a hash mapping criterion type names to [[TargetCriterionPm]]
objects. The criterion objects can be used to access additional result columns or
to provide methods for processing general-purpose search criteria.

=cut

    use constant SEMI_BOOLEAN => { Y => '*Yes', N => 'No' };
    use constant REAL_BOOLEAN => { 1 => '*Yes', 0 => 'No' };
    use constant GRAM_STAIN   => { N => '*Negative', Y => 'Positive' };
    use constant SANE         => 1;
    use constant INSANE       => 0;

sub GetCriteria {
    my ($self) = @_;
    # If we've already done this, we don't need to do it again.
    my $retVal = $self->{criterionList};
    if (! $retVal) {
        # We need to create the list. First, we require the TargetCriterion subclasses
        require TargetCriterionCellLocation;
        require TargetCriterionCodeMatch;
        require TargetCriterionConservedNeighborhood;
        require TargetCriterionGeneId;
        require TargetCriterionRange;
        require TargetCriterionGeneric;
        require TargetCriterionSmallTable;
        require TargetCriterionLookup;
        require TargetCriterionNull;
        require TargetCriterionExternalId;
        require TargetCriterionKeyword;
        require TargetCriterionEC;
        # Now we create a list of the TargetCriterion objects. This list is then used to
        # build the hash that our caller wants.
        my @targets = (
            TargetCriterionNull->new($self, "" => '',
                            ''),
            TargetCriterionCellLocation->new($self, cellLocation => 'Cell Location',
                            'Select a probable cell location.'),
            TargetCriterionConservedNeighborhood->new($self, conserved => 'Conserved Neighborhood',
                            'Select YES for a pinned feature, NO for an unconserved feature.'),
            TargetCriterionGeneric->new($self, function => 'Function',
                            'Entered text will match any substring of the functional assignment.',
                            scan => INSANE, assignment => qw(Feature)),
            TargetCriterionGeneId->new($self, geneId => 'ID',
                            'Enter a FIG gene ID, a locus tag, or any other common alias.'),
            TargetCriterionRange->new($self, isoElectric => 'Isoelectric Point',
                            'Enter minimum and maximum pH values.',
                            SANE, 'isoelectric-point' => qw(Feature)),
            TargetCriterionRange->new($self, molWeight => 'Molecular Weight',
                            'Enter minimum and maximum mass in daltons.',
                            SANE, 'molecular-weight' => qw(Feature)),
            TargetCriterionCodeMatch->new($self, endospore => 'Organism, Endospore Production',
                            'Select YES for an endospore.',
                            SEMI_BOOLEAN, endospore => qw(Genome)),
            TargetCriterionRange->new($self, gcContent => 'Organism, GC Content',
                            'Enter minimum and maximum percentage.',
                            INSANE, 'gc-content' => qw(Genome)),
            TargetCriterionCodeMatch->new($self, gramStain => 'Organism, Gram Stain',
                            'Indicate gram-positive or gram-negative.',
                            GRAM_STAIN, 'gram-stain' => qw(Genome)),
            TargetCriterionCodeMatch->new($self, habitat => 'Organism, Habitat',
                            'Select primary habitat.',
                            IDHASH(qw(Aquatic Host-associated Multiple Specialized Terrestrial)),
                            habitat => qw(Genome)),
            TargetCriterionGeneric->new($self, lineage => 'Organism, Lineage',
                            'Enter any word from the organism taxonomy.',
                            scan => INSANE, taxonomy => qw(Genome)),
            TargetCriterionCodeMatch->new($self, motility => 'Organism, Motility',
                            'Select YES for Motile, NO for Sessile.',
                            SEMI_BOOLEAN, motility => qw(Genome)),
            TargetCriterionGeneric->new($self, name => 'Organism, Name',
                            'Enter the genus, genus and species, or the full scientific name.',
                            prefix => SANE, 'scientific-name' => qw(Genome)),
            TargetCriterionCodeMatch->new($self, oxygen => 'Organism, Oxygen Requirement',
                            'Select the oxygen-related behavior of the organism.',
                            IDHASH(qw(Aerobic Anaerobic Facultative Microaerophilic)),
                            oxygen => qw(Genome)),
            TargetCriterionCodeMatch->new($self, pathogenic => 'Organism, Pathogenic',
                            'Select YES for a pathogenic organism, NO for a benign organism.',
                            SEMI_BOOLEAN, pathogenic => qw(Genome)),
            TargetCriterionSmallTable->new($self, host => 'Organism, Pathogenic Host',
                            'Select the desired pathogenic host.',
                            'to-link' => qw(Genome IsPathogenicIn Host)),
            TargetCriterionCodeMatch->new($self, salinity => 'Organism, Salinity',
                            'Select the salinity behavior of the organism.',
                            IDHASH('Extreme halophilic', 'Mesophilic', 'Moderate halophilic', 'Non-halophilic'),
                            salinity => qw(Genome)),
            TargetCriterionCodeMatch->new($self, tempCode => 'Organism, Temperature Range',
                            'Select the temperature-related behaviour of the organism',
                            IDHASH(qw(Hyperthermophilic Mesophilic Psychrophilic Thermophilic)),
                            'optimal-temperature-range' => qw(Genome)),
            TargetCriterionGeneric->new($self, taxonID => 'Organism, Taxon ID',
                            'Specify the taxonomic ID number for the genome.',
                            exact => SANE, id => qw(Genome)),
            TargetCriterionLookup->new($self, cdd => 'CDD number',
                            'Enter an ID number from the Conserved Domain Database.',
                            'from-link' => qw(Feature IsPresentOnProteinOf)),
            TargetCriterionLookup->new($self, protFamilyID => 'PFAM ID',
                            'Enter a protein family ID (PFxxxx).',
                            'from-link' => qw(Feature IsFamilyForFeature)),
            TargetCriterionLookup->new($self, protFamilyNM => 'PFAM Name',
                            'Enter the name of a protein family.',
                            'common-name' => qw(Feature IsFamilyForFeature ProteinFamily)),
            TargetCriterionRange->new($self, sequenceLen => 'Sequence Length',
                            'Enter the minimum and maximum number of base pairs.',
                            SANE, 'sequence-length' => qw(Feature)),
            TargetCriterionCodeMatch->new($self, simHuman => 'Similar to Human',
                            'Enter YES for a gene that generates a protein similar to a human protein.',
                            REAL_BOOLEAN, 'similar-to-human' => qw(Feature)),
            TargetCriterionRange->new($self, xmembrane => 'Transmembrane Domains',
                            'Enter the minimum and maximum number of protein sections that become embedded in the cell membrane.',
                            SANE, 'transmembrane-domain-count' => qw(Feature)),
            TargetCriterionEC->new($self, ecNumber => 'EC Number',
                            'Enter an EC number.'),
            TargetCriterionKeyword->new($self, essential => 'Essential Gene',
                            'Filter for essential genes.',
                            'essential'),
            TargetCriterionKeyword->new($self, virulent => 'Virulence Factor',
                            'Filter for virulence factors.',
                            'virulent'),
            TargetCriterionKeyword->new($self, iedb => 'Immune Epitope',
                            'Filter for genes identified as immune epitopes.',
                            'iedb'),
        );
        # Now we do the external database IDs.
        my $sprout = $self->DB();
        my @externals = $sprout->GetFlat("ExternalDatabase", "", [], "id");
        for my $external (@externals) {
            push @targets, TargetCriterionExternalId->new($self,
                            "xID$external" => "ID, $external",
                            "Enter a $external ID",
                            $external);
        }
        # Convert the list into a hash and save it.
        my %targetHash = map { $_->name() => $_ } @targets;
        $self->{criterionList} = \%targetHash;
        # Store it in the return variable.
        $retVal = \%targetHash;
    }
    # Return the hash.
    return $retVal;
}

=head2 Special Methods

=head3 new

    my $rhelp = RHFeatures->new($shelp);

Construct a new RHFeatures object.

=over 4

=item shelp

Parent search helper object for this result helper.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $shelp) = @_;
    # Create the helper object.
    my $retVal = ResultHelper::new($class, $shelp);
    # Denote no keyword is required.
    $retVal->{wordSearch} = 0;
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 Public Methods

=head3 SemiBoolean

    my $hash = RHFeatures::SemiBoolean();

Return the selection code hash for a semi-boolean field (C<Yes> = C<Y>, C<No> = C<N>).

=cut

sub SemiBoolean {
    return SEMI_BOOLEAN;
}

=head3 RealBoolean

    my $hash = RHFeatures::RealBoolean();

Return the selection code hash for a real boolean field (C<Yes> = 1, C<No> = 0).

=cut

sub RealBoolean {
    return REAL_BOOLEAN;
}

=head3 FieldMap

    my $name = RHFeatures::FieldMap($fieldSpec);

Return the name of the feature column containing the specified field. The
field specification should be in the standard format used by [[ErdbPm]]
for field names (e.g. C<Feature(assignment)>). If the field does not
correspond to a feature column, it must be specified as an extra column
in order to show up in the results.

=over 4

=item fieldSpec

Specification for the desired field, consisting of the name of the relevant
entity or relationship followed by the field name in parentheses.

=item RETURN

Returns the name of the corresponding feature result column, or C<undef> if the
specified field does not correspond to a feature result.

=back

=cut

sub FieldMap {
    # Get the parameters.
    my ($fieldSpec) = @_;
    # Query the hash.
    my $retVal = COLUMN_FIELD_MAP->{$fieldSpec};
    # Return the result.
    return $retVal;
}


=head2 Feature Filtering Support

=head3 KeywordsRequired

    $rhelp->KeywordsRequired();

Denote that a value is required for the word search (C<keywords>) field.

=cut

sub KeywordsRequired {
    # Get the parameters.
    my ($self) = @_;
    # Denote that a keyword is required.
    $self->{wordSearch} = 1;
}

=head3 FeatureFilterFormRows

    my $htmlText = RHFeatures::FeatureFilterFormRows($shelp, @sections);

Return a string of feature filter rows for a search form.

=over 4

=item shelp

Currently-active search helper.

=item sections

A list of section names. If no section names are specified, all sections will be
included.

=item RETURN

Returns the HTML text for table rows containing the selected filters.

=back

The currently-supported sections are:

=over 4

=item options

Contains checkboxes used to configure the search results. C<ShowAliases> includes feature aliases
in the output, C<FavoredAlias> allows the user to specify a favored alias for the alias list,
and C<FunctionSort> sorts the output by functional role, C<ShowProtein> displays the protein
sequence,

=item subsystem

Restricts the features to those that participate in a single subsystem. The subsystem name is
specified in a field called C<subsystem>.

=back

=cut

sub FeatureFilterFormRows {
    # Get the parameters.
    my ($shelp, @sections) = @_;
    # Get the CGI and Sprout objects from the search helper.
    my $cgi = $shelp->Q();
    my $sprout = $shelp->DB();
    # We'll stuff the computed table rows in here.
    my @retVal = ();
    # If there are no sections, denote we want all of them.
    my @actualSections;
    if (@sections) {
        @actualSections = @sections;
    } else {
        @actualSections = qw(subsystem options);
    }
    # Produce the sections in the named sequence.
    for my $section (@actualSections) {
        if ($section eq 'subsystem') {
            # Get the currently-selected subsystem name.
            my $subsystemName = $cgi->param('subsystem') || '(all)';
            # Get all the subsystems in the database.
            my @subsystemList = $sprout->GetFlat(['Subsystem'], "ORDER BY Subsystem(id)", [], 'Subsystem(id)');
            # Add the all-subsystem indicator.
            unshift @subsystemList, '(all)';
            # Format everything into a table row.
            push @retVal, CGI::Tr(CGI::td("Subsystem"),
                                   CGI::td({ colspan => 2 },
                                            CGI::popup_menu(-name => 'subsystem',
                                                         -values => \@subsystemList,
                                                         -default => $subsystemName) .
                                            SearchHelper::Hint("Subsystem Filter", 17)));

        } elsif ($section eq 'options') {
            # Get the current values of the parameters.
            my $aliases = $cgi->param('ShowAliases');
            my $funcSort = $cgi->param('FunctionSort');
            my $favored = $cgi->param('FavoredAlias') || '';
            my $showProt = $cgi->param('FunctionSort');
            # Display them as checkboxes.
            push @retVal, CGI::Tr(CGI::td("Options"),
                                   CGI::td({colspan => 2},
                                            CGI::checkbox(-name => 'FunctionSort',
                                                           -value => 1,
                                                           -label => 'Sort by Function',
                                                           -checked => $funcSort) .
                                            " " .
                                            CGI::checkbox(-name => 'ShowProtein',
                                                           -value => 1,
                                                           -label => 'Show Protein Sequence',
                                                           -checked => $showProt) .
                                            "<br />" .
                                            CGI::checkbox(-name => 'ShowAliases',
                                                           -value => 1,
                                                           -label => 'Show Alias Links',
                                                           -checked => $aliases) .
                                            "favoring those beginning with&nbsp;" .
                                            CGI::textfield(-name => 'FavoredAlias',
                                                            -size => 5,
                                                            -value => $favored) .
                                            SearchHelper::Hint("Gene Display Options", 18)
                                            ));
        } else {
            Trace("Invalid feature filter form row name \"$section\".") if T(1);
        }
    }
    # Return the accumulated table rows.
    return join("\n", @retVal);
}

=head3 WordSearchRow

    my $htmlText = RHFeatures::WordSearchRow($shelp);

Return a filter row for word searches. The word search uses the keyword search index
on the feature table, and allows many different options, including boolean flags and
phrase quoting. When a word search is used, there will be an extra field in the
returned B<ERDBObject>s-- C<search-relevance>-- which is a floating-point value that can
be used to modify the sort key for the search results.

=over 4

=item shelp

Currently-active search helper.

=item RETURN

Returns an HTML table row containing the form field and labels for keyword searching.
The word search parameter will have the name C<keywords>.

=back

=cut

sub WordSearchRow {
    # Get the parameters.
    my ($shelp) = @_;
    # Get the CGI query object.
    my $cgi = $shelp->Q();
    # Get the current keyword value.
    my $expressionString = $cgi->param('keywords') || '';
    # Create the word search row in the return variable.
    my $retVal = CGI::Tr(CGI::td("Search Words"),
                               CGI::td({colspan => 2}, CGI::textfield(-name => 'keywords',
                                                                        -value => $expressionString,
                                                                        -size => 40) .
                                                        SearchHelper::Hint("Keyword Box", 19)));
    # Return it.
    return $retVal;
}

=head3 GetQuery

    my $fquery = $rhelp->GetQuery($genomeID);

Construct a query for processing the features in a particular genome
relevant to a search. This method is used to retrieve all of the
features that satisfy the filtering criteria of the current search. Use this
method when your search is applying a post-query filter to the list of
features returned by the feature filters. Use L</CheckFeature> if your
search is retrieving a set of features and wants to reduce them using
the filter.

The feature filter attempts to find features in the most optimal way possible.
If a subsystem is specified, then we will start from the B<HasRoleInSubsystem>
relationship, taking advantage of the fact that all features for a given genome
are clustered together in the index. If no subsystem is specified, then we will
start from B<HasFeature>, filtering by genome. If no subsystem or genome is
specified, we start from B<Feature>. At some future point we may need
to be even more sophisticated than that.

=over 4

=item genomeID (optional)

Genome whose features are to be found and filtered. If omitted, then the
features for all genomes will be returned.

=item RETURN

Returns a hash containing information describing how to query the database
for the desired features. This hash is passed to the L</Fetch> method
to execute the query and return features.

=back

=cut

sub GetQuery {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    Trace("Constructing query for $genomeID.") if T(3) && defined $genomeID;
    Trace("Constructing query for all genomes.") if T(3) && ! defined $genomeID;
    # Start with a hash reference.
    my $retVal = {};
    # Get the CGI query and Sprout objects.
    my $shelp = $self->Parent();
    my $cgi = $shelp->Q();
    my $sprout = $shelp->DB();
    # Get our stash variable for the property ID.
    my $propIDs;
    # Get the subsystem name. If it's "(all)", we convert to a null string.
    my $subsystem = $cgi->param('subsystem');
    $subsystem = "" if ($subsystem eq "(all)");
    # Set up the search data. The $qData will contain all the parameters we need
    # for the ERDB Get command.
    my $qData = { sprout => $sprout, count => 0 };
    # Now we determine what type of search we're doing based on the CGI paraneters.
    # Note that "findex" will be the index in the table list of the feature table.
    # We need this so we can tell the ERDB full-text search mechanism which table
    # has the keyword field in it.
    if ($subsystem) {
        # Here we are doing a subsystem search.
        $qData->{tables} = ['HasRoleInSubsystem', 'Feature'];
        $qData->{filter} = "HasRoleInSubsystem(to-link) = ?";
        $qData->{params} = [$subsystem];
        $qData->{findex} = 1;
        if (defined $genomeID) {
            # Here we're filtering by genome, so we need to add a genome filter.
            $qData->{filter} .= " AND HasRoleInSubsystem(genome) = ?";
            push @{$qData->{params}}, $genomeID;
        }
    } elsif (defined $genomeID) {
        # This is search by genome ID, so we start from Genome.
        $qData->{tables} = ['HasFeature', 'Feature'];
        $qData->{filter} = "HasFeature(from-link) = ?";
        $qData->{params} = [$genomeID];
        $qData->{findex} = 1;
    } else {
        # This is a pure feature type search, so we start from Feature.
        $qData->{tables} = ['Feature'];
        $qData->{filter} = "";
        $qData->{params} = [];
        $qData->{findex} = 0;
    }
    # Finally, check for search words. Note we take precautions to keep from being fooled by a
    # bunch of blanks.
    my $keywords = $cgi->param('keywords') || "";
    if ($keywords =~ /^\s+$/) {
        $keywords = "";
    }
    # If we have any search words left, denote we're a keyword search.
    if ($keywords) {
        $qData->{keywords} = $keywords;
    }
    Trace("Feature query filter is \"$qData->{filter}\" with keywords \"$keywords\".") if T(3);
    $retVal->{subsystem} = $subsystem;
    $retVal->{currentQuery} = undef;
    $retVal->{queryData} = $qData;
    $retVal->{fidCache} = {};
    # Return the query management object.
    return $retVal;
}

=head3 Fetch

    my $featureData = $rhelp->Fetch($fquery);

Return the data for the next feature. The object returned will be a B<ERDBObject> for
the desired feature plus any useful ancillary data. If there are no more features
it will return C<undef>.

=over 4

=item fquery

A feature query object creatd by L</GetQuery>.

=item RETURN

Returns an B<ERDBObject> for the desired feature, or C<undef> if there are no more
features available.

=back

=cut

sub Fetch {
    # Get the parameters.
    my ($self, $fquery) = @_;
    # Declare the return variable. If we do not find anything to put in it, the
    # user will presume we've run out of features.
    my $retVal;
    # Get the query data object.
    my $qData = $fquery->{queryData};
    # Get the feature ID cache.
    my $fidCache = $fquery->{fidCache};
    # Insure we have a query.
    my $query = $fquery->{currentQuery};
    if (! defined($query)) {
        $query = _GetNextQuery($qData);
    }
    Trace("Starting query loop.") if T(4);
    # Loop until we find a feature or run out of queries.
    while (! defined($retVal) && defined($query)) {
        Trace("Starting fetch loop.") if T(4);
        # Save a place to store the feature that comes back.
        my $featureData;
        while (! defined($retVal) && ($featureData = $query->Fetch())) {
            # Only proceed if this feature is new.
            my $fid = $featureData->PrimaryValue('Feature(id)');
            Trace("Feature $fid found.") if T(4);
            if (! $fidCache->{$fid}) {
                # Make sure we don't check it again.
                $fidCache->{$fid} = 1;
                # Return it.
                $retVal = $featureData;
            }
        }
        # Check to see if we found a feature.
        if (! defined($retVal)) {
            # We did not, so we get the next query.
            $query = _GetNextQuery($qData);
        } else {
            # We did, so save the query for the next call.
            $fquery->{currentQuery} = $query;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 Valid

    my $flag = $rhelp->Valid();

Validate the filtering parameters for the current search request.

This method returns TRUE if the filtering parameters are valid, and FALSE if
they're invalid. In the latter case, B<SetMessage> will have been called on the
search helper object to communicate the error message.

=cut

sub Valid {
    # Get the parameters.
    my ($self) = @_;
    Trace("Validating filter parameters.") if T(3);
    # Get the CGI object.
    my $cgi = $self->Parent()->Q();
    # Declare the return variable. We assume everything's fine, then set it to
    # 0 if an error occurs. This enables us to flatten the IFs somewhat.
    my $retVal = 1;
    # The only validation we need to do here is for the keywords. We make use
    # of the "wordSearch" field to find out if the client has specified that
    # a keyword is required.
    my $keywords = $cgi->param('keywords') || "";
    if (! $self->ValidateKeywords($keywords, $self->{wordSearch})) {
        $retVal = 0;
    }
    Trace("Validation result is $retVal.") if T(3);
    # Return the result.
    return $retVal;
}

=head3 ValidateKeywords

    my $okFlag = $rhelp->ValidateKeywords($keywordString, $required);

Insure that a keyword string is reasonably valid. If it is invalid, a message will be
set.

=over 4

=item keywordString

Keyword string specified as a parameter to the current search.

=item required

TRUE if there must be at least one keyword specified, else FALSE.

=item RETURN

Returns TRUE if the keyword string is valid, else FALSE. Note that a null keyword string
is acceptable if the I<$required> parameter is not specified.

=back

=cut

sub ValidateKeywords {
    # Get the parameters.
    my ($self, $keywordString, $required) = @_;
    # Get the parent search helper.
    my $shelp = $self->Parent();
    # Declare the return variable.
    my $retVal = 0;
    my @wordList = split /\s+/, $keywordString;
    # Right now our only real worry is a list of all minus words. The problem with it is that
    # it will return an incorrect result.
    my @plusWords = grep { $_ =~ /^[^\-]/ } @wordList;
    if (! @wordList) {
        if ($required) {
            $shelp->SetMessage("No search words specified.");
        } else {
            $retVal = 1;
        }
    } elsif (! @plusWords) {
        $shelp->SetMessage("At least one keyword must be positive. All the keywords entered are preceded by minus signs.");
    } else {
        $retVal = 1;
    }
    # Return the result.
    return $retVal;
}

=head3 CheckSubsystem

    my $flag = $fquery->CheckSubsystem($featureData);

Determine whether or not the specified feature is in the correct subsystem.
This method will return TRUE if we pass the test, else FALSE.

=over 4

=item featureData

B<ERDBObject> for the feature to check.

=item RETURN

Returns TRUE if the feature is in the correct subsystem, else FALSE.

=back

=cut

sub CheckSubsystem {
    # Get the parameters.
    my ($self, $featureData) = @_;
    # Get the CGI query object.
    my $cgi = $self->Parent()->Q();
    # Declare the return variable.
    my $retVal;
    # Check to see if we're filtering by subsystem.
    my $subsystem = $cgi->param('subsystem') || "(all)";
    if ($subsystem eq '(all)') {
        # Not filtering, so we pass automatically.
        $retVal = 1;
    } else {
        # Here we're filtering. Check to see if the query is filtering for us.
        if ($featureData->HasField('HasRoleInSubsystem(to-link)')) {
            my ($mySubsystem) = $featureData->Value('HasRoleInSubsystem(to-link)');
            if ($mySubsystem && $subsystem eq $mySubsystem) {
                # Yes it is, so pass automatically.
                $retVal = 1;
            }
        }
        if (! $retVal) {
            # Now we have to check by querying the database.
            my $sprout = $self->DB();
            my ($mySubsystem) = $sprout->GetFlat(['HasRoleInSubsystem'],
                                                 "HasRoleInSubsystem(to-link) = ? AND HasRoleInSubsystem(from-link) = ?",
                                                 [$subsystem, $self->FID()],
                                                 'HasRoleInSubsystem(to-link)');
            if ($mySubsystem) {
                $retVal = 1;
            } else {
                $retVal = 0;
            }
        }
    }
    # Return the result.
    return $retVal;
}

=head3 CheckFeature

    my $okFlag = $rhelp->CheckFeature($feature);

Determine whether or not the specified feature fulfills all the requirements of
this result helper's active filters. This is an expensive method, so only use
it if you are filtering something fairly small.

=over 4

=item feature

B<ERDBObject> for the feature to examine.

=item RETURN

Returns TRUE if the feature satisfies all our conditions, else FALSE.

=back

=cut

sub CheckFeature {
    # Get the parameters.
    my ($self, $feature) = @_;
    # Get the CGI query and database objects.
    my $shelp = $self->Parent();
    my $cgi = $shelp->Q();
    my $sprout = $shelp->DB();
    # The first condition we require is a matching subsystem.
    my $retVal = $self->CheckSubsystem($feature);
    # If we match the subsystem, we need to check the keywords.
    my $keywords = $cgi->param('keywords') || '';
    if ($retVal && $keywords) {
        # Build a new query that will return a result only if the feature passes the keyword text.
        my $query = $sprout->Search($keywords, 0, ['Feature'], 'Feature(id) = ?',
                                    [$feature->PrimaryValue('Feature(id)')]);
        # If the query could not find a result, return FALSE.
        if (! $query->Fetch()) {
            $retVal = 0;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 _GetNextQuery

    my $query = RHFeatures::_GetNextQuery($qData);

Get the next query for retrieving features. This method should only be used internally.

Currently, we have a single query. This may not always be the case, in which instance
this method will need to return multiple queries in sequence.

=over 4

=item qData

Current query data object.

=item RETURN

Returns a B<ERDBQuery> object for the current feature query, or C<undef> if there are no
more queries to make.

=back

=cut

sub _GetNextQuery {
    # Get the parameters.
    my ($qData) = @_;
    # Declare the return variable.
    my $retVal;
    # Since there's only one query per request, we fail if this method is called
    # twice.
    if ($qData->{count} == 0) {
        $qData->{count}++;
        # Get the sprout object.
        my $sprout = $qData->{sprout};
        # The type of query is dependent on whether or not a keyword search
        # is involved.
        if (exists $qData->{keywords}) {
            Trace("Query is for a full-text search.") if T(3);
            $retVal = $sprout->Search($qData->{keywords}, $qData->{findex}, $qData->{tables},
                                      $qData->{filter}, $qData->{params});
        } else {
            $retVal = $sprout->Get($qData->{tables}, $qData->{filter}, $qData->{params});
        }
        Trace("Query created.") if T(3);
    } else {
        Trace("Last query processed.") if T(3);
    }
    # Return the result.
    return $retVal;
}

=head3 AdditionalColumns

    my @cols = $rhelp->AdditionalColumns();

Return any additional columns that should be included in the feature display.
The columns returned will be standard columns, not extra columns particular
to the search. This method is required to support the extra columns mandated
by the feature filter options row as well as extra columns that may be mandated
by keywords.

=cut

sub AdditionalColumns {
    # Get the parameters.
    my ($self) = @_;
    # Get the CGI query object and the sprout database.
    my $shelp = $self->Parent();
    my $cgi = $shelp->Q();
    my $sprout = $shelp->DB();
    # Get the return value.
    my @retVal = ();
    # Check for additional columns. If the feature filter form was not used,
    # these if-conditions will automatically be FALSE.
    if ($cgi->param('ShowAliases')) {
        push @retVal, 'alias';
    }
    if ($cgi->param('ShowProtein')) {
        push @retVal, 'protein';
    }
    # We look for the special attribute keywords here. First, we get the special
    # field list for features.
    my %specialHash = $sprout->SpecialFields('Feature');
    # Get the incoming keyword list.
    my $keywordString = $cgi->param('keywords');
    if ($keywordString) {
        # Okay, we have a keyword list here. Parse out the positive words.
        my @goodWords = ERDB::SplitKeywords($keywordString);
        Trace("Good words from the keyword list are: " . join(" ", @goodWords) . ".") if T(3);
        # Loop through them, checking for specials. (Note that in general,
        # the keyword list will contain only one or two words, so we're
        # faster cycling through it instead of cycling through the specials.)
        for my $word (@goodWords) {
            if ($specialHash{$word} eq 'property_search') {
                push @retVal, $word;
            }
        }
    }
    Trace("Returning from AdditionalColumns. " . scalar(@retVal) . " columns found.") if T(3);
    # Return the result.
    return @retVal;
}

=head3 SortKey

    my $key = $rhelp->SortKey($feature, $datum);

Return the sort key for the specified feature. The sort key is normally a
thing created from the group name, but it can be overridden by options
on the form generated by the feature query. For example, if a keyword
search is being used, the search relevance takes precedence over everything
but whether or not the feature is an NMPDR feature. If the user asked
to sort the features by functional assignment, that would take precedence
as well.

=over 4

=item feature

ERDB object for the feature to be sorted.

=item datum

A string to be prefixed to the sort key. If the sort is being overriden
by the search options, the overriding key will precede this value;
otherwise, this value precedes all other sort key data.

=item RETURN

Returns a string that can be used to sort the specified feature into the
correct position, or that can be suffixed to an existing key.

=back

=cut

sub SortKey {
    # Get the parameters.
    my ($self, $feature, $datum) = @_;
    # Insure we have a datum value.
    my $realDatum = (defined($datum) ? $datum : "");
    # Get the CGI query object and the parent search helper.
    my $shelp = $self->Parent();
    my $cgi = $shelp->Q();
    my $sprout = $shelp->DB();
    # Get the feature ID.
    my $fid = $feature->PrimaryValue('Feature(id)');
    # Get the organism data.
    my $genomeID = $sprout->GenomeOf($fid);
    my ($orgName, $group) = $shelp->OrganismData($genomeID);
    # Start the sort key with an "A" for an NMPDR genome and a "Z" otherwise.
    my $retVal = ($group ? "A" : "Z");
    # Check for keyword filtering.
    if ($feature->HasField('Feature(search-relevance)')) {
        # If there's keyword filtering, then search relevance is a factor.
        my $relevance = $feature->PrimaryValue('Feature(search-relevance)');
        # We need to normalize it so it works in a character-based sort. We
        # also need to invert it so that a higher relevance sorts to the top.
        my $relevanceString = sprintf("%0.3f", 9999 - $relevance);
        $relevanceString = " $relevanceString" while length($relevanceString) < 11;
        # Now we add it to the sort key.
        $retVal .= $relevanceString;
    }
    # Add the organism name and feature ID.
    $retVal .= "[$orgName $fid]";
    # Prefix the incoming datum.
    $retVal = "$datum $retVal";
    # Check for functional role sorting. If the caller is not using any feature filtering,
    # the following condition will automatically be FALSE and functional role sorting will
    # not be used.
    if ($cgi->param('FunctionSort')) {
        # Here the user wants to sort by function. We put the functional
        # assignment before the sort key.
        $retVal = $feature->PrimaryValue('Feature(assignment)') . $retVal;
    }
    # Return the result.
    return $retVal;
}

=head2 Virtual Overrides

=head3 VirtualCompute

    my $dataValue = $rhelp->VirtualCompute($colName, $type, $runTimeKey);

Retrieve the column data of the specified type for the specified column
using the optional run-time key.

This method will process columns in the L</GetCriteria> list. If a column
is not in that list (it is truly built-in), then it will pass on the column
so that the built-in methods can be used.

=over 4

=item colName

Name of the relevant column.

=item type

The type of column data requested: C<title> for the column title, C<style> for the
column's display style, C<value> for the value to be put in the result cache,
C<download> for the indicator of how the column should be included in
downloads, and C<runTimeValue> for the value to be used when the result is
displayed. Note that if a run-time value is required, then the normal value
must be formatted in a special way (see L<Column Processing>).

=item runTimeKey (optional)

If a run-time value is desired, this should be the key taken from the value stored
in the result cache.

=item RETURN

Returns the requested value for the named column, or C<undef> if the column
is built in to the subclass using the old protocol.

=back

=cut

sub VirtualCompute {
    # Get the parameters.
    my ($self, $colName, $type, $runTimeKey) = @_;
    # Declare the return variable.
    my $retVal;
    # Is this column in the TargetCriterion list?
    my $tcHash = $self->GetCriteria();
    if ($tcHash->{$colName}) {
        # Here the column is one of ours. Get the TargetCriterion object.
        my $colData = $tcHash->{$colName};
        # Process according to the type of data desired.
        if ($type eq 'title') {
            $retVal = $colData->label();
        } elsif ($type eq 'value') {
            # Get the current feature record. Note that when we're computing the
            # cached value it's about the only time there's guaranteed to be
            # a record here.
            my $feature = $self->Record();
            $retVal = $colData->CacheValue($feature);
        } elsif ($type eq 'style') {
            # Here we need the display style. This is computed from the
            # download type.
            my $dlType = $colData->DownloadType();
            $retVal = ($dlType eq 'num' ? 'rightAlign' : 'leftALign');
        } elsif ($type eq 'download') {
            $retVal = $colData->DownloadType();
        } elsif ($type eq 'runTimeValue' || $type eq 'valueFromKey') {
            $retVal = $colData->RunTimeValue($runTimeKey);
        }
    }
    # Return the result.
    return $retVal;
}

=head3 DefaultResultColumns

    my @colNames = $rhelp->DefaultResultColumns();

Return a list of the default columns to be used by searches with this
type of result. Note that the actual default columns are computed by
the search helper. This method is only needed if the search helper doesn't
care.

The columns returned should be in the form of column names, all of which
must be defined by the result helper class.

=cut

sub DefaultResultColumns {
    # Get the parameters.
    my ($self) = @_;
    # Start with the standard columns.
    my @retVal = qw(fid orgName function subsystem);
    # Add the optional columns.
    push @retVal, $self->AdditionalColumns();
    # Return the result.
    return @retVal;
}

=head3 MoreDownloadFormats

    $rhelp->MoreDownloadFormats(\%dlTypes);

Add additional supported download formats to the type table. The table is a
hash keyed on the download type code for which the values are the download
descriptions. There is a special syntax that allows the placement of text
fields inside the description. Use square brackets containing the name
for the text field. The field will come in to the download request as
a GET-type field.

=over 4

=item dlTypes

Reference to a download-type hash. The purpose of this method is to add more
download types relevant to the particular result type. Each type is described
by a key (the download type itself) and a description. The description can
contain a single text field that may be used to pass a parameter to the
download. The text field is of the format C<[>I<fieldName>C<]>,
where I<fieldName> is the name to give the text field's parameter in the
generated download URL.

=back

=cut

sub MoreDownloadFormats {
    # Get the parameters.
    my ($self, $dlTypes) = @_;
    Trace("Adding download formats for feature helper.") if T(3);
    # Add a download type for FASTA.
    $dlTypes->{fasta} = "DNA FASTA sequences of all results including [flank]nt flanking sequence";
    $dlTypes->{pfasta} = "Protein FASTA sequences of all results";
}

=head3 MoreDownloadDataMethods

    my @lines = $rhelp->MoreDownloadDataMethods($objectID, $dlType, \@cols, \@colHdrs);

Create one or more lines of download data for a download of the specified type. Override
this method if you need to process more download types than the default C<tbl> method.

=over 4

=item objectID

ID of the object for this data row.

=item dlType

Download type (e.g. C<fasta>, etc.)

=item cols

Reference to a list of the data columns from the result cache, or alternatively
the string C<header> (indicating that header lines are desired) or C<footer>
(indicating that footer lines are desired).

=item colHdrs

The list of column headers from the result cache.

=item RETURN

Returns an array of data lines to output to the download file.

=back

=cut

sub MoreDownloadDataMethods {
    # Get the parameters.
    my ($self, $objectID, $dlType, $cols, $colHdrs) = @_;
    # Declare the return variable.
    my @retVal;
    # Get the sprout object.
    my $sprout = $self->DB();
    # Check the download type.
    if ($dlType eq 'fasta' || $dlType eq 'pfasta') {
        # The FASTA downloads do not have headers or footers, so we only
        # process if we have a real ID. A real ID has an array of columns
        # passed with it, which is what we check.
        if (ref $cols eq 'ARRAY') {
            # Okay, here we have a real ID to download. The two types of
            # fasta sequences are computed almost identically. Let's start
            # with the CGI object and the search helper.
            my $shelp = $self->Parent();
            my $cgi = $shelp->Q();
            Trace("Processing $objectID for Fasta download.") if T(4);
            # Now, we need the flanking width from the CGI parameters. The default
            # is 0. The protein FASTA does not have flanking data, so it will always
            # use the default.
            my $flankingWidth = $cgi->param('flank') || 0;
            # Compute the fasta type.
            my $type = ($dlType eq 'fasta' ? 'dna' : 'prot');
            # Get the real feature ID. Usually, this will have no effect.
            my ($fid) = $sprout->FeaturesByAlias($objectID);
            Trace("Real ID of $objectID is $fid.") if T(4);
            # Get the feature's genome ID.
            my $genomeID = $sprout->GenomeOf($fid);
            # Compute the fasta comments. These include the organism ID, function,
            # and optionally the aliases. First, we get a cheap hash of the
            # column values.
            my $nCols = scalar(@$cols) - 1;
            my %colData = map { $colHdrs->[$_] => $cols->[$_] }
                            grep { ! ref($colHdrs->[$_]) } (0 .. $nCols);
            # We'll put the comments in here. The organism name is first, and it's
            # unconditional.
            my @comments = "[" . $shelp->Organism($genomeID) . "]";
            # Next the aliases, but only if they're in the result columns. We
            # also limit ourselves to curated aliases.
            if (exists $colData{alias}) {
                push @comments, map { "[$_]" } $sprout->GetFlat(['IsAlsoFoundIn'],
                                                                "IsAlsoFoundIn(from-link) = ?",
                                                                [$fid], 'IsAlsoFoundIn(alias)');
            }
            # We get the function from the columns.
            if (exists $colData{function}) {
                push @comments, $colData{function}
            }
            # We're done. Ask the search helper for the fasta data.
            my $fasta = $shelp->ComputeFASTA($type => $objectID, $flankingWidth,
                                             join(" ", @comments));
            # Break it into lines.
            @retVal = split(/\n/, $fasta);
        } else {
            Trace("Header/footer line skipped.") if T(3);
        }
    } else {
        # Here the download type is not one we recognize.
        Confess("Invalid download type \"$dlType\" specified for result class $self->{type}.");
    }
    # Return the output.
    return @retVal;
}

=head2 Utility Methods

=head3 CurrentFeature

    my $featureRecord = $rhelp->CurrentFeature($fid);

Return the feature record for the specified feature. If the feature record
is already cached, we'll use the cache value; otherwise, we will pull in the
feature record from the database.

=over 4

=item fid

Current feature's ID.

=item RETURN

Returns an B<ERDBObject> for the specified feature.

=back

=cut

sub CurrentFeature {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Check the cache.
    my $cache = $self->Cache();
    my $retVal = $cache->{feature};
    # If the cache is empty, read the feature from the database.
    if (! defined($retVal)) {
        my $sprout = $self->DB();
        $retVal = $sprout->GetEntity(Feature => $fid);
        # Put it in the cache for future use.
        $cache->{feature} = $retVal;
    }
    # Return the feature.
    return $retVal;
}

=head3 GetColumnNameList

    my @names = $rhelp->GetColumnNameList();

Return a complete list of the names of columns available for this result
helper. The base class method simply regurgitates the default columns.

=cut

sub GetColumnNameList {
    # Get the parameters.
    my ($self) = @_;
    # Get the criteria.
    my $criteria = $self->GetCriteria();
    # We'll put the column names found in here.
    my %colNames;
    # Start with the criteria columns.
    for my $criterion (values %$criteria) {
        my $name = $criterion->colName();
        # We suppress the null column.
        if ($name) {
            $colNames{$name} = 1;
        }
    }
    # Add the built-in columns, excepting relevance, which is not normally used.
    for my $name (qw(alias protein subsystem orgName fid function svLink)) {
        $colNames{$name} = 1;
    }
    # Return the result.
    return keys %colNames;
}

=head3 Permanent

    my $flag = $rhelp->Permanent($colName);

Return TRUE if the specified column should be permanent when used in a
Seed Viewer table, else FALSE.

=over 4

=item colName

Name of the column to check.

=item RETURN

Returns TRUE if the column should be permanent, else FALSE.

=back

=cut

sub Permanent {
    # Get the parameters.
    my ($self, $colName) = @_;
    # Declare the return variable.
    my $retVal = ($colName eq 'fid' || $colName eq 'orgName');
    # Return the result.
    return $retVal;
}

=head2 Column Methods

=head3 alias

    my $colDatum = RHFeatures::alias($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the alias column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the alias column.

=back

=cut

sub alias {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'External Aliases';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'list';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # Aliases are expensive to load, so we ask for a runtime value.
        # We need the feature ID and the favored alias type.
        my $cgi = $rhelp->Parent()->Q();
        my $favored = $cgi->param('FavoredAlias') || '';
        my $fid = $rhelp->ID();
        $retVal = "%%alias=$fid/$favored";
    } elsif ($type eq 'runTimeValue') {
        # Get the Sprout database object.
        my $sprout = $rhelp->DB();
        # Split the feature ID and the favored alias prefix.
        my ($fid, $favored) = split('/', $key);
        # Get the aliases for the specified feature.
        my %aliasMap = map { $_ => 1 } $sprout->FeatureAliases($fid);
        # Now we need to remove aliases that are redundant. We check each alias
        # to see if it has a natural form. If it does, and that natural form
        # is also in the alias list, we delete it.
        Trace("Processing aliases for $fid.") if T(3);
        for my $alias (keys %aliasMap) {
            Trace("Checking $alias for a natural form.") if T(3);
            my $natural = AliasAnalysis::Format(natural => $alias);
            # Only proceed if we have a natural form distinct from this form.
            if (defined $natural && $natural ne $alias) {
                Trace("Natural form \"$natural\" of $alias being deleted.") if T(3);
                $aliasMap{$natural} = 0;
            }
        }
        # Get back all the aliases we intend to keep.
        my @aliases = grep { $aliasMap{$_} } sort keys %aliasMap;
        # Is there a favored alias?
        if ($favored) {
            # Yes, so we have to sort the favored aliases to the beginning.
            my @favors = ();
            my @other = ();
            my $len = length $favored;
            my $lcFavored = lc $favored;
            # Separate the favored aliases from the others.
            for my $alias (@aliases) {
                if (lc(substr($alias, 0, $len)) eq $lcFavored) {
                    push @favors, $alias;
                } else {
                    push @other, $alias;
                }
            }
            # Put them back together.
            @aliases = (@favors, @other);
        }
        # Format them into a comma-separated list with URLs where appropriate.
        $retVal = AliasAnalysis::FormatHtml(@aliases);
    } elsif ($type eq 'valueFromKey') {
        # Here it's a little simpler. We don't need to worry about favoring.
        my $sprout = $rhelp->DB();
        my @aliases = $sprout->FeatureAliases($key);
        $retVal = AliasAnalysis::FormatHtml(@aliases);
    }
    return $retVal;
}

=head3 protein

    my $colDatum = RHFeatures::protein($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the protein column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the alias column.

=back

=cut

sub protein {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Protein Sequence';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'text';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'code';
    } elsif ($type eq 'value') {
        # Proteins are expensive to load, so we ask for a runtime value.
        my $fid = $rhelp->ID();
        $retVal = "%%protein=$fid";
    } elsif ($type eq 'runTimeValue' || $type eq 'valueFromKey') {
        # Get the Sprout database object.
        my $sprout = $rhelp->DB();
        # Check to see if the feature is a peg.
        if ($key =~ /peg/) {
            # Yes, get its translation.
            my $translation = $sprout->FeatureTranslation($key);
            # Bust it into pieces. This makes it easier to format when it appears in HTML.
            # The chunk size is based on FASTA rules.
            my @chunks = grep { $_ } split /(.{1,60})/, $translation;
            $retVal = join(" ", @chunks);
        } else {
            # No, leave the return value blank.
            $retVal = "";
        }
    }
    return $retVal;
}

=head3 subsystem

    my $colDatum = RHFeatures::subsystem($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the subsystem column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the subsystem column.

=back

=cut

sub subsystem {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Subsystems';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'list';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # Ask for a runtime value. Subsystems are expensive to load.
        $retVal = '%%subsystem=' . $rhelp->ID();
    } elsif ($type eq 'runTimeValue' || $type eq 'valueFromKey') {
        # Get the Sprout database object.
        my $sprout = $rhelp->DB();
        # Get the genome ID for this peg.
        my $genomeID = $sprout->GenomeOf($key);
        # Get the CGI query object.
        my $cgi = $rhelp->Parent()->Q();
        # Get the subsystems for the specified feature.
        my @subsystems = $sprout->SubsystemList($key);
        # Convert them to hyperlinks.
        my @links = map { HTML::sub_link($cgi, $_, $genomeID) } @subsystems;
        # String them together.
        $retVal = join(", ", @links);
    }
    return $retVal;
}

=head3 relevance

    my $colDatum = RHFeatures::relevance($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the relevance column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the relevance column.

=back

=cut

sub relevance {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Relevance';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'num';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'rightAlign';
    } elsif ($type eq 'value') {
        # Get the current record.
        my $record = $rhelp->Record();
        # Extract the search relevance.
        my $relevance = $record->PrimaryValue('Feature(search-relevance)');
        # Now we need to format it.
        $retVal = sprintf("%0.3f", $relevance);
    } elsif ($type eq 'runTimeValue') {
        # Runtime support is not needed for this column.
    } elsif ($type eq 'valueFromKey') {
        # This makes no sense. We just show a 1.
        $retVal = 1;
    }
    return $retVal;
}

=head3 orgName

    my $colDatum = RHFeatures::orgName($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the orgName column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the orgName column.

=back

=cut

sub orgName {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Organism Name';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'text';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value' || $type eq 'valueFromKey') {
        # Get the Sprout database object.
        my $sprout = $rhelp->DB();
        # Get the feature ID.
        my $fid = $key || $rhelp->ID();
        # Get the feature's genome ID.
        my ($genomeID) = FIGRules::ParseFeatureID($fid);
        # Extract the organism name from the search helper.
        my $shelp = $rhelp->Parent();
        $retVal = $shelp->Organism($genomeID);
        # Convert it to a hyperlink.
        $retVal = CGI::a({ href => "$FIG_Config::cgi_url/wiki/rest.cgi/NmpdrPlugin/SeedViewer?page=Organism;organism=$genomeID" },
                         $retVal);
        # Check to see if we're showing FIG IDs or another
        # type.
        my $aliasType = $shelp->GetPreferredAliasType();
        if ($aliasType ne 'FIG') {
            # We're showing non-FIG IDs, so we include the FIG ID in the
            # organism name.
            $retVal .= " [$fid]";
        }
    } elsif ($type eq 'runTimeValue') {
        # Runtime support is not needed for this column.
    }
    return $retVal;
}

=head3 fid

    my $colDatum = RHFeatures::fid($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the fid column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the fid column.

=back

=cut

sub fid {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Gene';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'text';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # Because this may involve aliases, we compute the feature ID at run-time.
        $retVal = "%%fid=" . $rhelp->ID();
    } elsif ($type eq 'runTimeValue') {
        # Get the feature object from the database or the cache.
        my $feature = $rhelp->CurrentFeature($key);
        # Ask for the preferred ID.
        my $alias = $rhelp->PreferredID($feature);
        # Format it into a link.
        $retVal = CGI::a({ href => "$FIG_Config::cgi_url/wiki/rest.cgi/NmpdrPlugin/SeedViewer?page=Annotation;feature=$key" },
                         $alias);
    } elsif ($type eq 'valueFromKey') {
        # This field is the key, so the value from the key is itself.
        $retVal = $key;
    }
    return $retVal;
}

=head3 function

    my $colDatum = RHFeatures::function($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the function column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the function column.

=back

=cut

sub function {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Functional Assignment';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'text';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # Get the current record.
        my $feature = $rhelp->Record();
        # Extract the functional role.
        $retVal = $feature->PrimaryValue('Feature(assignment)');
    } elsif ($type eq 'runTimeValue') {
        # Runtime support is not needed for this column.
    } elsif ($type eq 'valueFromKey') {
        # Get the sprout database.
        my $sprout = $rhelp->DB();
        # Get the assignment.
        ($retVal) = $sprout->GetEntityValues(Feature => $key, ['assignment']);
    }
    return $retVal;
}

=head3 svLink

    my $colDatum = RHFeatures::svLink($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the SeedViewer link column. Currently, this takes us to the Seed Viewer's
feature page.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the gblink column.

=back

=cut

sub svLink {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Viewer';
    } elsif ($type eq 'download') {
        # This field should not be included in a download.
        $retVal = '';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'center';
    } elsif ($type eq 'value' || $type eq 'valueFromKey') {
        # Here we want a link to the Seed Viewer page using the official Viewer button.
        my $fid = $key || $rhelp->ID();
        $retVal = $rhelp->FakeButton('Viewer', "wiki/rest.cgi/NmpdrPlugin/SeedViewer", undef, page => 'Annotation',
                                     feature => $fid);
    } elsif ($type eq 'runTimeValue') {
        # Runtime support is not needed for this column.
    }
    return $retVal;
}

1;
