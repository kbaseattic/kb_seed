#!/usr/bin/perl -w

package SHSubSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use RHFeatures;
    use base 'SearchHelper';

=head1 Subsystem Feature Search Helper

=head2 Introduction

This search helper displays a subsystem tree and allows the user to
select any node in the tree to get back all of the features in a single
subsystem or all the subsystems in a class. The tree will also have links to
the subsystem display pages.

It has the following extra parameters.

=over 4

=item specification

A string of the form C<id=>I<string> or C<classification=>I<string>. In the
first case, I<string> is the ID of a subsystem. In the second case,
I<string> is a LIKE-style string that can be used to get subsystems in the
specified class.

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
    my $retVal = $self->FormStart("Search for Genes by Subsystem or Class");
    # Create a subsystem tree.
    my $tree = SearchHelper::SubsystemTree($sprout, radio => 1, links => 1);
    # Build a form field out of it.
    my $treeField = SearchHelper::SelectionTree($cgi, $tree,
                                                name => "specification",
                                                target => "_blank",
                                                selected => $cgi->param("specification"));
    # We'll accumulate the form table in here.
    my @rows = ();
    # Start with the subsystem tree.
    push @rows, CGI::Tr(CGI::th({ colspan => 3, align => "center" }, "Subsystem Tree")),
                CGI::Tr(CGI::td({ colspan => 3 }, $treeField));
    # Put in the keyword search box.
    my $expressionString = $cgi->param('keywords') || "";
    push @rows, RHFeatures::WordSearchRow($self);
    # Add the special options.
    push @rows, RHFeatures::FeatureFilterFormRows($self, 'options');
    # Finish it off with the submit row.
    push @rows, $self->SubmitRow();
    # Convert the form rows into a table.
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
    # Insure we have a specification.
    my $spec = $cgi->param('specification');
    if (! $spec) {
        $self->SetMessage("No subsystem or class selected.");
    } else {
        # We need to build a query to get our features. This involves building
        # a filter clause and a parameter list.
        my ($filterClause, $parameter);
        if ($spec =~ /^id=(.+)$/) {
            # Here we're filtering for a single subsystem.
            $filterClause = "Subsystem(id) = ?";
            $parameter = $1;
        } elsif ($spec =~ /^classification=(.+)$/) {
            # Here we're filtering for a class.
            $filterClause = "Subsystem(classification) LIKE ?";
            $parameter = $1;
        }
        # Now we do some validation.
        my $keywords = $cgi->param('keywords') || "";
        if (! defined($filterClause)) {
            $self->SetMessage("Invalid subsystem specification \"$spec\".");
        } elsif ($self->ValidateKeywords($keywords)) {
            # We're valid, so we start by collecting the main parameters for the query.
            my @majorParms = (['Subsystem', 'HasRoleInSubsystem', 'Feature'],
                                     $filterClause, [$parameter]);
            # The way we execute the query is determined by whether or not
            # any keywords were specified.
            my $query;
            if ($keywords) {
                $self->PrintLine("Word search query submitted.<br />");
                $query = $sprout->Search($keywords, 2, @majorParms);
            } else {
                $self->PrintLine("Standard search query submitted.<br />");
                $query = $sprout->Get(@majorParms);
            }
            # Get the result helper for a feature search.
            my $rhelp = RHFeatures->new($self);
            # Compute the default columns. This is a very simple search which
            # has no extra columns.
            $self->DefaultColumns($rhelp);
            # Initialize the session file.
            $self->OpenSession($rhelp);
            # Clear the result counter.
            $retVal = 0;
            # Process the query results.
            while (my $record = $query->Fetch()) {
                # Compute the sort key.
                my $sort = $rhelp->SortKey($record);
                # Store this feature.
                $rhelp->PutData($sort, $record->PrimaryValue('Feature(id)'), $record);
                # Increment the result counter.
                $retVal++;
            }
            # Close the session file.
            $self->CloseSession();
        }
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
    return "Search for %FIG{genes}% by keyword in a specified %FIG{subsystem}% or subsystem class.";
}

1;
