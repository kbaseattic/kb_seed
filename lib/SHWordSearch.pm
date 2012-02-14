#!/usr/bin/perl -w

package SHWordSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use RHFeatures;
    use base 'SearchHelper';

=head1 Simple Keyword Search Feature Search Helper

=head2 Introduction

This is a basic keyword search engine. Keyword searching is a subset of
the FidSearch mechanism, which allows filtering by keyword amongst a
host of other options; however, having a separate search class gives
new users a way to search without all the extra clutter.

It has the following extra parameters.

=over 4

=item keywords

Search expression. This is essentially a space-delimited list of words with the following
optional operators applied.

C<+>: A leading plus sign indicates that this word must be present in every row returned.

C<->: A leading minus sign indicates that this word must not be present in any row returned.
Note that if every search term has a leading minus sign, nothing will match. This is an
artifact of the search algorithm.

B<(no operator)>: By default (when neither + nor - is specified) the word is optional, but the
rows that contain it are rated higher.

    > <: These two operators are used to change a word's contribution to the relevance value
that is assigned to a row. The C<< > >> operator increases the contribution and the C<< < >>
operator decreases it.

C<( )>: Parentheses are used to group words into subexpressions. Parenthesized groups can be nested.

C<~>: A leading tilde acts as a negation operator, causing the word's contribution to the row
relevance to be negative. It's useful for marking noise words. A row that contains such a
word is rated lower than others, but is not excluded altogether, as it would be with the C<->
operator.

C<*>: An asterisk is the truncation operator. Unlike the other operators, it should be appended to the word.

C<"> A phrase that is enclosed within double quote characters matches only rows that contain the phrase
literally, as it was typed.

=item group[]

If specified, these should be the names of NMPDR groups to which the search is to be
restricted. Otherwise, all groups are searched. This parameter is not on the form; rather,
it is provided as a quick way to do keyword searches restricted to groups on pages that
want to provide that capability.

=back

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
    my $retVal = $self->FormStart("Keyword Search");
    # Declare a variable to hold the table rows.
    my @rows = ();
    # The first row is for the keyword search expression.
    push @rows, RHFeatures::WordSearchRow($self);
    # The second row is for special options.
    push @rows, RHFeatures::FeatureFilterFormRows($self, 'options');
    # The last row is for the submit button.
    push @rows, $self->SubmitRow();
    # Finally, if groups are specified, we include them as hidden fields and display
    # an explanation.
    my @groups = $cgi->param('group');
    my $groupCount = scalar(@groups);
    if ($groupCount) {
        # The explanation format is a bit tricky because of the way the English language
        # uses commas and conjunctions.
        my $message = "Search restricted to ";
        my $last = pop @groups;
        if ($groupCount == 1) {
            $message .= "$last.";
        } else {
            $message .= join(", ", @groups) . " and $last.";
        }
        # Assemble the hidden fields.
        my @hiddens = map { CGI::hidden(-name => 'group', -value => $_) } @groups, $last;
        push @rows, CGI::Tr(CGI::td(@hiddens), CGI::td($message));
    }
    # Create the table.
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
    # Get the result helper.
    my $rhelp = RHFeatures->new($self);
    # Validate the filtering parameters.
    $rhelp->KeywordsRequired();
    if ($rhelp->Valid()) {
        # Initialize the result counter.
        $retVal = 0;
        # Get the default columns.
        $self->DefaultColumns($rhelp);
        Trace("Column list is " . join(", ", @{$rhelp->GetColumnHeaders()})) if T(3);
        # Start the output session.
        $self->OpenSession($rhelp);
        # Get the keywords.
        my $keywords = $cgi->param('keywords') || '';
        # Check for groups.
        my @groups = $cgi->param('group');
        if (@groups) {
            # Here we do the search a group at a time.
            for my $group (@groups) {
                Trace("Starting the search.") if T(3);
                $self->PrintLine("Submitting search query for $group.<br />");
                my $query = $sprout->Search($keywords, 0, ['Feature', 'IsInGenome', 'Genome'],
                                            "Genome(primary-group) = ?", [$group]);
                Trace("Processing results.") if T(3);
                $retVal += $self->ProcessQuery($rhelp, $query);
                Trace("Results processed.") if T(3);
            }
        } else {
            # Here we do one search just for features.
            Trace("Starting the search.") if T(3);
            $self->PrintLine("Submitting search query for all genomes.<br />");
            my $query = $sprout->Search($keywords, 0, ['Feature']);
            Trace("Processing results.") if T(3);
            $retVal += $self->ProcessQuery($rhelp, $query);
            Trace("Results processed.") if T(3);
        }
        # Close the session file.
        $self->CloseSession();
        Trace("Session closed.") if T(3);
    }
    # Return the result count.
    return $retVal;
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
    # Compute the title.
    my $cgi = $self->Q();
    my $words = $cgi->param('keywords');
    my $retVal = "Keyword Search for $words.";
    # Return it.
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
    return "Search for %FIG{genes}% based on [[FIG.KeywordBox][keywords]].";
}

=head3 ProcessQuery

    my $count = $shelp->ProcessQuery($rhelp, $query);

Run through the results of a query, sending all the features retrieved to the output
cache. The number of features found will be returned to the caller.

=over 4

=item rhelp

Current result helper object, which should be B<RHFeatures>.

=item query

A B<ERDBQuery> object that returns features.

=item RETURN

Returns the number of features found.

=back

=cut

sub ProcessQuery {
    # Get the parameters.
    my ($self, $rhelp, $query) = @_;
    my $cgi = $self->Q();
    # Clear the result counter.
    my $retVal = 0;
    $self->PrintLine("Processing query results.<br />");
    Trace("Starting feature loop.") if T(3);
    # Loop through all the records returned by the query.
    while (my $record = $query->Fetch()) {
        # Compute the sort key.
        my $sort = $rhelp->SortKey($record);
        # Store this feature.
        $rhelp->PutData($sort, $record->PrimaryValue('Feature(id)'), $record);
        # Increment the result counter.
        $retVal++;
        if ($retVal % 100 == 0) {
            $self->PrintLine("$retVal results processed.<br />");
        }
    }
    $self->PrintLine("Results found: $retVal.<br />");
    # Return the counter.
    return $retVal;
}

1;
