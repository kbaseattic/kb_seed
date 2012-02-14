#!/usr/bin/perl -w

package SHOpSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use RHFeatures;
    use BasicLocation;
    use base 'SearchHelper';

=head1 Operon Analysis Feature Search Helper

=head2 Introduction

This search method takes a genome ID and produces a list of the operons. An operon is defined
as a set of genes in the same direction that are near each other with no intervening genes.
The concept of I<near> is defined by a parameter. In addition to the standard data
produced by a feature search, this method also shows the upstream DNA for each feature
found. The size of the upstream region is also defined by a parameter.

This search has the following extra parameters.

=over 4

=item genome

ID of the genome to process for operons.

=item nearDistance

Maximum distance in base pairs of successive genes in an operon. The default value is C<200>,
which means that if the distance between the end of one gene and the beginning of the next is more
than 200 base pairs, the genes are not considered to be part of the same operon.

=item upstream

Number of base pairs in front of the gene to include in the display of the upstream region. The default
value is C<250>.

=item instream

Number of base pairs inside the gene to include in the display of the upstream region. The default
value is C<50>.

=item lintSize

The maximum size of a gene that can be interpreted as lint. Genes with this number of base pairs
or fewer are ignored during the operon analysis. The default is C<100>.

=back

=cut

my %TuningParms = (nearDistance => 200, upstream => 250, instream => 50, lintSize => 100);

=head2 Virtual Methods

=head3 Form

    my $html = $shelp->Form();

Generate the HTML for a form to request a new search.

=cut

sub Form {
    # Get the parameters.
    my ($self) = @_;
    # Get the CGI and sprout objects.
    my $cgi = $self->Q();
    my $sprout = $self->DB();
    # Start the form.
    my $retVal = $self->FormStart("Operon Analysis");
    # Get the selected gene.
    my $genomeID = $cgi->param('genome');
    my $genomeList = ($genomeID ? [$genomeID] : []);
    # We'll accumulate the table rows in this variable.
    my @rows = ();
    # Start with the genome menu. We use a tall list but without multiple selection.
    my $menu = $self->NmpdrGenomeMenu('genome', 0, $genomeList, 10);
    push @rows, CGI::Tr(CGI::td("Select a genome"), CGI::td({colspan => 2}, $menu));
    # Next we have the tuning parameters.
    my $options = $self->TuningParameters(%TuningParms);
    push @rows, CGI::Tr(CGI::td({rowspan => 4}, "Tuning Parameters"),
                         CGI::td("Maximum distance between operon genes"),
                         CGI::td(CGI::textfield(-name => 'nearDistance',
                                                  -value => $options->{nearDistance},
                                                  -size => 5) .
                                  SearchHelper::Hint("OpSearch", 20))),
                CGI::Tr(CGI::td("Upstream base pairs to display"),
                         CGI::td(CGI::textfield(-name => 'upstream',
                                                  -value => $options->{upstream},
                                                  -size => 5) .
                         SearchHelper::Hint("OpSearch", 21))),
                CGI::Tr(CGI::td("Instream base pairs to display"),
                         CGI::td(CGI::textfield(-name => 'instream',
                                                  -value => $options->{instream},
                                                  -size => 5) .
                                  SearchHelper::Hint("OpSearch", 22))),
                CGI::Tr(CGI::td("Maximum lint size"),
                         CGI::td(CGI::textfield(-name => 'lintSize',
                                                  -value => $options->{lintSize},
                                                  -size => 5) .
                                  SearchHelper::Hint("OpSearch", 23)));
    # Add the special feature options.
    push @rows, RHFeatures::FeatureFilterFormRows($self, 'options');
    # Add the submit button.
    push @rows, $self->SubmitRow();
    # Make the rows into a table.
    $retVal .= $self->MakeTable(\@rows);
    # Close the form.
    $retVal .= $self->FormEnd();
    # Return the result.
    return $retVal;
}

=head3 Find

    my $resultCount = $shelp->Find();

Conduct a search based on the current CGI query parameters. The search results will
be written to the session cache file and the number of results will be
returned. If the search parameters are invalid, a result count of C<undef> will be
returned and a result message will be stored in this object describing the problem.

=cut

sub Find {
    my ($self) = @_;
    # Get the CGI and Sprout objects.
    my $cgi = $self->Q();
    my $sprout = $self->DB();
    # Declare the return variable. If it remains undefined, the caller will
    # know that an error occurred.
    my $retVal;
    # Get the genome ID.
    my $genomeID = $cgi->param('genome');
    # Get the tuning parameters.
    my $options = $self->TuningParameters(%TuningParms);
    # Validate the tuning parameters.
    my @errorList = ();
    for my $parm (keys %{$options}) {
        if ($options->{$parm} !~ /^\d+$/) {
            push @errorList, "Invalid $parm value \"$options->{$parm}\".";
        }
    }
    if (@errorList > 0) {
        $self->SetMessage(join(" ", @errorList));
    } else {
        $self->PrintLine("Retrieving features for genome $genomeID.");
        # Here we have good tuning parameters. The next step is to loop through
        # all the features for the incoming genome. We want to get them in
        # location order within contig.
        my $query = $sprout->Get(['HasFeature', 'Feature', 'IsLocatedIn', 'Contig'],
                                 "HasFeature(from-link) = ? ORDER BY IsLocatedIn(to-link), IsLocatedIn(beg)",
                                 [$genomeID]);
        # Create a feature result helper to help us process the features.
        my $rhelp = RHFeatures->new($self);
        # Set the columns.
        $self->DefaultColumns($rhelp);
        # Define the extra columns.
        $rhelp->AddExtraColumn(operonID => 0,     download => 'text',  title => 'Operon ID', style => 'leftAlign');
        $rhelp->AddExtraColumn(location => 1,     download => 'text',  title => 'Location', style => 'leftAlign');
        $rhelp->AddExtraColumn(upstream => undef, download => 'align', title => 'Upstream DNA', style => 'leftAlign');
        # Start the session.
        $self->OpenSession($rhelp);
        # The trickiest part of this whole process is computing the operon information.
        # Each feature has an operon ID and an operon sequence number. The operon ID
        # is displayed as an extra column. The sequence number is combined with the
        # operon ID to create the sort key. We arbitrarily assume an upper limit
        # of a million operons each with no more than a million features. If we're
        # wrong, the sort won't work but the data will still be okay. To start
        # the whole process along, we prime the operon data with dummy values so
        # that the first feature is considered to be part of a new operon. Note that
        # the operon ID and sequence number are saved in the object so that the
        # sort key method can find them.
        $self->{operonID} = 0;
        $self->{operonFeatureSeq} = 0;
        # This variable contains the last feature's location. We put it on a bogus contig
        # so that the first feature we encounted will be considered the start of a new
        # operon.
        my $lastLocation = BasicLocation->new(" ", 0, '+', 0);
        # This variable contains the last feature. We may receive multiple results for
        # a single feature. Only the last result is output.
        my $lastFeature;
        my $lastFid = "";
        # Finally, we need to save the current contig ID and length.
        $self->{contigID} = "";
        $self->{contigLen} = 0;
        # Loop until we run out of features.
        while (my $feature = $query->Fetch()) {
            # Get this feature's location.
            my $thisLocation = BasicLocation->new($feature->Values(['IsLocatedIn(to-link)', 'IsLocatedIn(beg)',
                                                                   'IsLocatedIn(dir)', 'IsLocatedIn(len)']));
            # Get this feature's ID.
            my $thisFid = $feature->PrimaryValue('IsLocatedIn(from-link)');
            # Only proceed if this feature is not lint.
            if ($thisLocation->Length >= $options->{lintSize}) {
                # Determine whether or not this is a new feature.
                if ($thisFid eq $lastFid) {
                    # This is a second location for the same feature. Combine its location with
                    # the last location.
                    $lastLocation->Combine($thisLocation);
                    Trace("Sublocation found. New location is " . $lastLocation->String()) if T(4);
                } else {
                    # We have a new feature. Write out the previous feature's data (if any).
                    if ($lastFid) {
                        Trace("Writing feature $lastFid.") if T(4);
                        $self->OutputFeature($rhelp, $lastFeature, $lastLocation, $options);
                        $retVal++;
                        # Reveal our status every 100 features.
                        if ($retVal % 100 == 0) {
                            $self->PrintLine("$retVal features processed. $self->{operonID} operons found.");
                        }
                    }
                    # Remember the new feature and its ID.
                    $lastFid = $thisFid;
                    $lastFeature = $feature;
                    # Check the operon status.
                    if ($lastLocation->Contig eq $thisLocation->Contig &&
                        $lastLocation->Dir eq $thisLocation->Dir &&
                        $thisLocation->Left - $lastLocation->Right < $options->{nearDistance}) {
                        # Here we're part of the same operon. Increment the feature sequence number.
                        # For forward operons we add 1. For backward operons we subtract 1.
                        $self->{operonFeatureSeq} += $thisLocation->NumDirection();
                        Trace("New operon feature sequence number for $thisFid is $self->{operonFeatureSeq}.") if T(4);
                    } else {
                        # Here we belong to a new operon.
                        $self->{operonID}++;
                        # The sequence number will be incremented for forward operons and decremented
                        # for backward operons. The sequence number is used only for sorting: it insures
                        # that the operons are presented in their natural order. By starting at 5,000,000
                        # and relying on our assumption that therte are fewer than 1,000,000 features per
                        # operon, we insure that the sequence numbers are always the same number of
                        # digits, whether we decrement or increment.
                        $self->{operonFeatureSeq} = 5000000;
                        Trace("New operon ID for $thisFid is $self->{operonID}.") if T(4);
                    }
                    # Save the feature location.
                    $lastLocation = $thisLocation;
                }
            }
        }
        # Output the last feature (if any).
        if ($lastFid) {
            $self->OutputFeature($rhelp, $lastFeature, $lastLocation, $options);
            $retVal++;
        }
        # Close the session file.
        $self->CloseSession();
    }
    # Return the result count.
    return $retVal;
}

=head3 Description

    my $htmlText = $shelp->Description();

Return a description of this search. The description is used for the table of contents
on the main search tools page. It may contain HTML, but it should be character-level,
not block-level, since the description is going to appear in a list.

=cut

sub Description {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return "Search for %FIG{operons}% in a single %FIG{genome}%.";
}

=head3 SortKey

    my $key = $shelp->SortKey($rhelp, $record);

Return the sort key for the current feature. The features are
sorted by sequence within operon, which is determined entirely
by data cached in this object. The sort order may, however,
be modified by options

=over 4

=item rhelp

Current result helper object.

=item record

The C<ERDBObject> containing the current feature.

=item RETURN

Returns a key field that can be used to sort this row in among the results.

=back

=cut

sub SortKey {
    # Get the parameters.
    my ($self, $rhelp, $record) = @_;
    # Get the current operon ID and sequence.
    my $operonID = $self->{operonID};
    my $operonSeqNumber = $self->{operonFeatureSeq};
    # The operon Sequence number is already at a fixed width. We need to pad to a
    # fixed width for the operon ID.
    my $operonKey = "$operonID.$operonSeqNumber";
    while (length $operonKey < 20) {
        $operonKey = "0$operonKey";
    }
    # Create a feature sort key for this feature with the operon data mixed in.
    my $retVal = $rhelp->SortKey($record, $operonKey);
    # Return the result.
    return $retVal;
}

=head3 OutputFeature

    $shelp->OutputFeature($rhelp, $feature, $location, $options);

Output the current feature. We use the location to compute an upstream location for the feature,
and this is added to the feature data object as an extra column named C<Upstream DNA>. The operon ID
is added to the feature data object as an extra column named C<Operon ID>.

=over 4

=item rhelp

Feature result helper.

=item feature

=item location

A BasicLocation object describing the combined feature locations for the current feature.

=item options

Reference to a hash of options for this search. The options of interest to us are C<instream> and
C<upstream>

=back

=cut

sub OutputFeature {
    # Get the parameters.
    my ($self, $rhelp, $feature, $location, $options) = @_;
    # Get access to Sprout.
    my $sprout = $self->DB();
    # Get the contig length.
    if ($self->{contigID} ne $location->Contig) {
        $self->{contigID} = $location->Contig;
        $self->{contigLen} = $sprout->ContigLength($location->Contig);
    }
    my $contigLen = $self->{contigLen};
    # Get the upstream location.
    my $upstreamLocation = $location->Upstream($options->{upstream}, $contigLen);
    # Compute its DNA and convert it to upper case.
    my $upstreamDNA = uc $sprout->DNASeq([$upstreamLocation->String]);
    # Compute the instream DNA. We do this by truncating the feature location.
    my $instreamLocation = BasicLocation->new($location);
    $instreamLocation->Truncate($options->{instream});
    my $instreamDNA = lc $sprout->DNASeq([$instreamLocation->String]);
    # Combine the DNA sequences.
    $upstreamDNA .= ":$instreamDNA";
    if (T(4)) {
        my $uString = $upstreamLocation->String;
        my $iString = $instreamLocation->String;
        my $oString = $location->String;
        Trace("Upstream = $uString, Instream = $iString, Original = $oString.");
    }
    # Chop the genome ID off the location string so it looks better. Also, we'll use
    # the SEED format so the user can eyeball the distance between genes.
    my $locationString = $location->SeedString;
    $locationString =~ s/^[^:]+://;
    # Store the upstream DNA in the result helper along with the operon ID. We add
    # the direction to the operon ID so the user knows more easily which way we're pointing.
    $rhelp->PutExtraColumns(operonID => $self->{operonID} . $location->Dir,
                            upstream => $upstreamDNA,
                            location => $locationString);
    # Compute the sort key and the feature ID.
    my $sortKey = $self->SortKey($rhelp, $feature);
    my $fid = $feature->PrimaryValue('Feature(id)');
    # Put the feature to the output.
    $rhelp->PutData($sortKey, $fid, $feature);
}

=head3 SearchTitle

    my $titleHtml = $shelp->SearchTitle();

Return the display title for this search. The display title appears above the search results.
If no result is returned, no title will be displayed. The result should be an html string
that can be legally put inside a block tag such as C<h3> or C<p>.

=cut

sub SearchTitle {
    # Get the parameters.
    my ($self) = @_;
    # Compute the title. We extract the genome ID from the query parameters.
    my $cgi = $self->Q();
    my $genomeID = $cgi->param('genome');
    my $retVal = "Operon search for $genomeID";
    # Return it.
    return $retVal;
}


1;
