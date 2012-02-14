#!/usr/bin/perl -w

package SHGeneBbhSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use Sprout;
    use Stats;

    use RHFeatures;
    use base 'SearchHelper';

=head1 

=head2 Introduction

This is a simple search that accepts as input a FIG ID or alias and lists all of
the bidirectional best hits for the indicated gene. Because some aliases
indicate multiple genes, the source gene is included in the result set.

This search has the following extra parameters.

=over 4

=item gene_id

FIG ID or alias for the gene of interest

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
    my $retVal = $self->FormStart("Find Bidirectional Best Hits");
    # Declare a variable to hold the table rows.
    my @rows = ();
    push @rows, CGI::Tr(CGI::td("%FIG{FIG ID}% or %FIG{alias}%"),
                        CGI::td({ colSpan => 2 },
                                CGI::textfield(-name => 'gene_id', -size => 30)));
    # Get the display options for features.
    push @rows, RHFeatures::FeatureFilterFormRows($self, 'options');
    # The last row is for the submit button.
    push @rows, $self->SubmitRow();
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
    if ($rhelp->Valid()) {
        # Get the search parameters.
        my $gene_id = $cgi->param('gene_id');
        # Get the default columns.
        $self->DefaultColumns($rhelp);
        Trace("Column list is " . join(", ", @{$rhelp->GetColumnHeaders()})) if T(3);
        # Add the source gene and the score.
        $rhelp->AddExtraColumn(queryGene => undef, title => 'Query Gene',
                                 style => 'leftAlign', download => 'text');
        $rhelp->AddExtraColumn(score => undef, title => 'Score',
                                 style => 'left', download => 'num');
        # Start the output session.
        $self->OpenSession($rhelp);
        # Find the genes for the specified ID. If it's a FIG ID, this is easy;
        # otherwise, we have to get an alias.
        my $input_id = $cgi->param('gene_id');
        if (! $input_id) {
            $self->SetMessage("Please specify a valid ID.");
        } else {
            # We have an ID. We'll put its list of aliases in here.
            my @queryGenes;
            if ($input_id =~ /^fig|/) {
                # It's a FIG ID. if it exists, we want to keep it.
                if ($sprout->Exists(Feature => $input_id)) {
                    push @queryGenes, $input_id;
                }
            } else {
                # Look for aliases.
                push @queryGenes, $sprout->GetFlat('IsAliasOf',
                                                   "IsAliasOf(from-link) = ?",
                                                   [$input_id],
                                                   'to-link');
            }
            Trace("Query gene list is " . join(", ", @queryGenes) . ".") if T(3);
            # If we don't have anything, the ID is not found.
            if (! @queryGenes) {
                $self->SetMessage("The ID \"$input_id\" was not found in our database.");
            } else {
                # Initialize the result counter.
                $retVal = 0;
                # We're finally ready to search. Loop through the IDs.
                for my $queryGene (@queryGenes) {
                    $self->PrintLine("Locating BBHs of $queryGene.<br />");
                    Trace("Processing $queryGene.") if T(3);
                    # Get this feature's BBHs.
                    my $bbhList = FIGRules::BBHData($queryGene);
                    # Loop through the results.
                    $self->PrintLine(scalar(@$bbhList) . " hits found.<br />");
                    for my $bbh (@$bbhList) {
                        # Get the data.
                        my ($hit, $score) = @$bbh;
                        Trace("Hit found at $hit.") if T(3);
                        # Only proceed if this BBH exists in our database.
                        my $record = $sprout->GetEntity(Feature => $hit);
                        if (defined $record) {
                            Trace("Hit confirmed in Sprout.") if T(3);
                            # Compute the sort key.
                            my $sortKey = $rhelp->SortKey($record);
                            # Store the extra columns.
                            $rhelp->PutExtraColumns(queryGene => $queryGene,
                                                    score => $score);
                            # Put the data into the output.
                            $rhelp->PutData($sortKey, $hit, $record);
                            # Count it.
                            $retVal++;
                        }
                    }
                }
            }
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
    # Get a safe copy of the input value.
    my $input = CGI::escapeHTML($cgi->param('gene_id') || "Unknown Gene");
    # Generate the title.
    my $retVal = "Bidirectional Best Hits for $input.";
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
    return "Display the %FIG{bidirectional best hits}% of a specified %FIG{gene}%.";
}

1;
