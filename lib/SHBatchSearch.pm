#!/usr/bin/perl -w

package SHBatchSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);

    use RHFeatures;
    use base 'SearchHelper';

=head1 

=head2 Introduction

This search uploads a set of gene IDs from a sequential file or extracts them from
a text field and displays them as search results. Everything except quotes, commas,
and whitespace will be interpreted as a potential gene ID. The ID must either be
a FIG ID or an alias in the alias table.

This search has the following extra parameters.

=over 4

=item inFile

Sequential file to upload.

=item inText

Text containing IDs. This is an alternative to using a file, for the case in which
the IDs are in a clipboard or copied from text.

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
    my $retVal = $self->FormStart("Batch Target Search");
    # Add a hidden field to turn off the form on the result pages.
    $retVal .= CGI::hidden(-name => 'NoForm', -value => 1);
    # Declare a variable to hold the table rows.
    my @rows = ();
    # Create a table cell containing the upload control and help text.
    my $uploader = join("<br />",
                        CGI::filefield(-name => 'inFile', -size => 50),
                        "Upload a text file containing %FIG{FIG IDs}% or %FIG{aliases}%.");
    # The first row is for the file to upload.
    push @rows, CGI::Tr(CGI::td("File to Upload"),
                        CGI::td({ colspan => 2 }, $uploader),
                       );
    # Below that is a place to enter IDs directly.
    push @rows, CGI::Tr(CGI::td("<b>OR</b><br /><br />Type the IDs into This Box"),
                        CGI::td({ colspan => 2 }, CGI::textarea(-name => "inText",
                                                                -rows => 5,
                                                                -cols => 62)));
    # Next is a genome selection box. We start with all the genomes pre-selected.
    my $allGenomes = [ $sprout->Genomes() ];
    my $genomes = $sprout->GenomeMenu(name => 'batchGenomes',
                                      multiSelect => 1,
                                      selected => $allGenomes,
                                      );
    push @rows, CGI::Tr(CGI::td("Restrict to genomes"),
                        CGI::td({ colspan => 2 }, $genomes));
    # The other row is for the submit button.
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
    # Get the list of genomes.
    my %genomes = map { $_ => 1 } $self->GetGenomes('batchGenomes');
    # Validate the filtering parameters.
    if (! %genomes) {
        $self->SetMessage("No genomes selected. Please select at least one genome.");
    } elsif ($rhelp->Valid()) {
        # Get the list of feature IDs from the two inputs. If the file
        # is invalid, or there are no IDs anywhere, this method will set an
        # error message and return UNDEF. First, we declare the ID list variable
        # and fill it from the text box.
        my $inText = $cgi->param('inText') || '';
        my @flist = $self->ParseIDList($inText);
        if (@flist) {
            $self->PrintLine(scalar(@flist) . " IDs found in text box.");
        }
        # We'll set this to FALSE if there's an error.
        my $okFlag = 1;
        # Now, get the IDs from the text control.
        my $ih = $cgi->upload('inFile');
        if (defined $ih) {
            # We have a file. Parse it.
            $self->PrintLine("Reading input file.<br />");
            my $fileList = $self->GetFeatureList($ih);
            if (defined $fileList) {
                # No error, so save the results.
                push @flist, @$fileList;
            } else {
                # Denote we have an error.
                $okFlag = 0;
            }
        }
        # If there are no IDs, then we're not OK.
        if ($okFlag && ! scalar @flist) {
            $self->SetMessage("No IDs found. Specify a file or enter IDs into the text box.");
            $okFlag = 0;
        }
        # Only process if there's no error.
        if ($okFlag) {
            # Initialize the result counter.
            $retVal = 0;
            # Get the default columns.
            $self->DefaultColumns($rhelp);
            # Add aliases.
            $rhelp->AddOptionalColumn('alias');
            # Add a column for the matched ID.
            $rhelp->AddExtraColumn(match => 0, { title => 'Matching ID',
                                                 download => 'text',
                                                 style => 'leftAlign' });
            Trace("Column list is " . join(", ", @{$rhelp->GetColumnHeaders()})) if T(3);
            # We'll count the number of excluded features in here.
            my $excluded = 0;
            # Start the output session.
            $self->OpenSession($rhelp);
            $self->PrintLine("Processing feature list.<br />");
            for my $fid (@flist) {
                # We'll put the features we find in here. We expect only one at
                # a time, but for some aliases there can be two or more.
                my @features;
                # Is this a FIG ID?
                if ($fid =~ /^fig\|/) {
                    # Yes, get the feature by ID.
                    @features = $sprout->GetList("Genome HasFeature Feature",
                                                 "Feature(id) = ?", [$fid]);
                } else {
                    # Here we have an alias.
                    @features = $sprout->GetList("Genome HasFeature Feature IsAliasOf",
                                                 "IsAliasOf(from-link) = ?", [$fid]);
                }
                # Insure each feature belongs to a valid genome.
                my $total = scalar(@features);
                @features = grep { $genomes{$_->PrimaryValue('Genome(id)')} } @features;
                # Compute the number of features found.
                my $features = scalar(@features);
                Trace("$features found for \"$fid\".") if T(3);
                # Find out if any features were excluded.
                if ($features < $total) {
                    $excluded += $total - $features;
                }
                if (! $total) {
                    # No features for this ID, so we issue a warning.
                    $self->SetNotice("No data found for \"$fid\".");
                } elsif ($features > 1) {
                    # Multiple after filtering is also worth a warning.
                    $self->SetNotice("$features genes found for ID \"$fid\".");
                }
                # Process the features found.
                for my $feature (@features) {
                    # Count this feature.
                    $retVal++;
                    # Get its ID.
                    my $realID = $feature->PrimaryValue('Feature(id)');
                    # Indicate the matched ID.
                    $rhelp->PutExtraColumns(match => $fid);
                    # Store it in the result set.
                    $rhelp->PutData($retVal, $realID, $feature);
                }
            }
            # Add the exclusion notice.
            if ($excluded) {
                $self->SetNotice("$excluded features excluded by genome filter.");
            }
            # Close the session file.
            $self->CloseSession();
            Trace("Session closed.") if T(3);
        }
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
    my $retVal = "Batch Upload Search Results.";
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
    return "Display %FIG{genes}% listed in a sequential file.";
}

=head2 Internal Methods

=head3 GetFeatureList

    my $flist = $self->GetFeatureList($ih);

Read a list of feature IDs from the specified input handle and return it
as a list reference. If the file handle or its contents is missing or
invalid, returns C<undef>.

=over 4

=item ih

An open file handle for the input file. The file will be treated as a set
of feature IDs (or aliases), with quotes, white space, and commas treated as
delimiters.

=item RETURN

Returns a reference to a list of the ID sequences from the file, or C<undef>
if the file was empty or invald.

=back

=cut

sub GetFeatureList {
    # Get the parameters.
    my ($self, $ih) = @_;
    # Declare the return variable.
    my $retVal;
    # We'll put the file text in here.
    my $text = "";
    # Protect from errors.
    eval {
        # Loop through the file.
        while (! eof $ih) {
            # Get this line.
            $text .= <$ih>;
        }
        # Parse the list.
        my @idList = $self->ParseIDList($text);
        if (! @idList) {
            # The file was empty, which is an error.
            $self->SetMessage("No data found in file.");
        } else {
            # We found something, so return it.
            $retVal = \@idList;
        }
    };
    if ($@) {
        # Here there was probably a file error.
        $self->SetMessage("Error processing input file: $@");
    }
    # Return the result.
    return $retVal;
}



1;
