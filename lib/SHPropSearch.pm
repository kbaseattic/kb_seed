#!/usr/bin/perl -w

package SHPropSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use RHFeatures;
    use base 'SearchHelper';

=head1 Property Search Feature Search Helper

=head2 Introduction

This search can be used to request all the features of a specified genome that have
specified property values. This search is not normally available to users; rather, it
is used by content developers to generate links.

It has the following extra parameters.

=over 4

=item propertyPair[]

One or more name/value pairs for properties. The name comes first, followed by an
equal sign and then the value. Theoretically, an unlimited number of name/value
pairs can be specified in this way, but the form only generates a fixed number
determined by the value of C<$FIG_Config::prop_search_limit>. A feature will
be returned if it matches any one of the name-value pairs.

=item genome

The ID of the genome whose features are to be searched.

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
    my $retVal = $self->FormStart("Attribute Search");
    my @rows = ();
    # First, we generate the genome menu.
    my $genomeMenu = $self->NmpdrGenomeMenu('genome', 0, [$cgi->param('genome')]);
    push @rows, CGI::Tr(CGI::td({valign => "top"}, "Genome"),
                         CGI::td({colspan => 2}, $genomeMenu));
    # Now add the property rows.
    my @pairs = grep { $_ } $cgi->param('propertyPair');
    Trace(scalar(@pairs) . " property pairs read from CGI.") if T(3);
    for (my $i = 1; $i <= $FIG_Config::prop_search_limit; $i++) {
        my $thisPair = shift @pairs;
        Trace("\"$thisPair\" popped from pairs array. " . scalar(@pairs) . " entries left.") if T(3);
        push @rows, CGI::Tr(CGI::td("Name=Value ($i)"),
                             CGI::td({colspan => 2}, CGI::textfield(-name => 'propertyPair',
                                                                      -value => $thisPair,
                                                                      -size => 40)));
    }
    # Finally, the submit row.
    push @rows, $self->SubmitRow();
    # Build the form table.
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
    # Insure we have a genome.
    my ($genomeID) = $self->GetGenomes('genome');
    if (! $genomeID) {
        $self->SetMessage("No genome was specified.");
    } else {
        # Now we verify the property filters. First we get the specified pairs.
        my @props = $cgi->param('propertyPair');
        # We'll put the property IDs found into this list.
        my @propIDs = ();
        # We'll accumulate error messages in this list.
        my @errors = ();
        # Loop through the specified pairs.
        for my $prop (@props) {
            # Only proceed if we have something.
            if ($prop) {
                # Separate the name and value.
                if ($prop =~ /^\s*(\w+)\s*=\s*(.*)\s*$/) {
                    my ($name, $value) = ($1, $2);
                    # Verify that they exist.
                    my ($id) = $sprout->GetFlat(['Property'],
                                                "Property(property-name) = ? AND Property(property-value) = ?",
                                                [$name, $value], 'Property(id)');
                    # If they do, save the ID.
                    if ($id) {
                        push @propIDs, $id;
                    }
                } else {
                    # Here the format is wrong.
                    push @errors, "Could not parse \"$prop\" into a name-value pair.";
                }
            }
        }
        # Insure we have some values and that there are no errors.
        if (@errors) {
            $self->SetMessage(join("  ", @errors));
        } elsif (! @propIDs) {
            $self->SetMessage("None of the name-value pairs specified exist in the database.");
        } else {
            # If we are here, then we have a genome ($genomeID) and a list
            # of desired property IDs (@propIDs). That means we can search.
            # Create the result helper.
            my $rhelp = RHFeatures->new($self);
            # Set the default columns.
            $self->DefaultColumns($rhelp);
            # Add the value columm at the front.
            $rhelp->AddExtraColumn(values => 0, title => 'Values', download => 'list',
                                   style => 'leftAlign');
            # Initialize the session file.
            $self->OpenSession($rhelp);
            # Initialize the result counter.
            $retVal = 0;
            # Create a variable to store the property value HTML.
            my @extraCols = ();
            # Denote that we currently don't have a feature.
            my $fid = undef;
            # Create the query.
            my $query = $sprout->Get(['HasFeature', 'Feature', 'HasProperty', 'Property'],
                                     "Property(id) IN (" . join(",", @propIDs) .
                                     ") AND HasFeature(from-link) = ? ORDER BY Feature(id)",
                                     [$genomeID]);
            # Loop through the query results. The same feature may appear multiple times,
            # but all the multiples will be grouped together.
            my $savedRow;
            while (my $row = $query->Fetch()) {
                # Get the feature ID;
                my $newFid = $row->PrimaryValue('Feature(id)');
                # Check to see if we have a new feature coming in. Note we check for undef
                # to avoid a run-time warning.
                if (! defined($fid) || $newFid ne $fid) {
                    if (defined($fid)) {
                        # Here we have an old feature to output.
                        $self->DumpFeature($rhelp, $savedRow, \@extraCols);
                        $retVal++;
                    }
                    # Clear the property value list.
                    @extraCols = ();
                    # Save this as the currently-active feature.
                    $savedRow = $row;
                    $fid = $newFid;
                }
                # Get this row's property data for the extra column.
                my ($name, $value, $url) = $row->Values(['Property(property-name)',
                                                         'Property(property-value)',
                                                         'HasProperty(evidence)']);
                # If the evidence is a URL, format it as a link; otherwise, ignore it.
                if ($url =~ m!http://!) {
                    push @extraCols, CGI::a({href => $url}, $value);
                } else {
                    push @extraCols, $value;
                }
            }
            # If there's a feature still in the buffer, write it here.
            if (defined $fid) {
                $self->DumpFeature($rhelp, $savedRow, \@extraCols);
                $retVal++;
            }
            # Close the session file.
            $self->CloseSession();
        }
    }
    # Return the result count.
    return $retVal;
}

=head3 DumpFeature

    $shelp->DumpFeature($rhelp, $record, \@extraCols);

Write the data for the current feature to the output.

=over 4

=item rhelp

Feature result helper.

=item record

B<ERDBObject> containing the feature.

=item extraCols

Reference to a list of extra column data.

=back

=cut

sub DumpFeature {
    # Get the parameters.
    my ($self, $rhelp, $record, $extraCols) = @_;
    # Format the extra column data.
    my $extraColumn = join(", ", @{$extraCols});
    # Add the extra column data.
    $rhelp->PutExtraColumns(values => $extraColumn);
    # Compute the sort key and the feature ID.
    my $sortKey = $rhelp->SortKey($record);
    my $fid = $record->PrimaryValue('Feature(id)');
    # Put everything to the output.
    $rhelp->PutData($sortKey, $fid, $record);
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
    return "Search for genes in a specific genome with specified property values.";
}

1;
