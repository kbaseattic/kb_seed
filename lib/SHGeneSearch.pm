#!/usr/bin/perl -w

package SHGeneSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use RHFeatures;
    use base 'SearchHelper';

=head1 Features in Genomes Search Helper

=head2 Introduction

The single feature search finds features from one or more selected organisms
using the full power of the B<RHFeature> filtering.

=over 4

=item genome

IDs of the relevant genome

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
    # Get the IDs of the currently-selected genomes (if any).
    my @genomeIDs = $cgi->param('genome');
    # Start the form.
    my $retVal = $self->FormStart("Gene Search");
    # Get the genome menu.
    my $menu = $self->NmpdrGenomeMenu('genome', 'multiple', \@genomeIDs);
    # Create a table for the form data.
    my @table = ();
    push @table, RHFeatures::WordSearchRow($self),
                 CGI::Tr(CGI::td("Select one or more %FIG{genomes}%"), CGI::td({colspan => 2}, $menu)),
                 RHFeatures::FeatureFilterFormRows($self),
                 $self->SubmitRow();
    $retVal .= $self->MakeTable(\@table);
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
    # Only proceed if the filter parameters are valid.
    if ($rhelp->Valid()) {
        # Get the genomes.
        $self->PrintLine("Retrieving genomes.  ");
        my @genomes = $self->GetGenomes('genome');
        # If the user specified all genomes, we simply use a single
        # undef so that the feature filter knows to act accordingly.
        if ($sprout->IsAllGenomes(\@genomes)) {
            $self->PrintLine("All genomes selected.<br />");
            @genomes = (undef);
        } else {
            my $genomeCount = scalar(@genomes);
            $self->PrintLine("Genomes found: $genomeCount.<br />");
        }
        # Only proceed if at least one genome is specified.
        if (scalar(@genomes) == 0) {
            $self->SetMessage("Please specify at least one genome.");
        } else {
            # Set the column list.
            $self->DefaultColumns($rhelp);
            # Initialize the session file.
            $self->OpenSession($rhelp);
            # Initialize the result counter.
            $retVal = 0;
            # Loop through the selected genomes.
            for my $genomeID (@genomes) {
                if (defined $genomeID) {
                    $self->PrintLine("Processing genome $genomeID.  ");
                } else {
                    $self->PrintLine("Processing query.");
                }
                Trace("Creating query. GenomeID = $genomeID") if T(3);
                my $fquery = $rhelp->GetQuery($genomeID);
                my $count = 0;
                while (my $feature = $rhelp->Fetch($fquery)) {
                    # Get the feature ID.
                    my $fid = $feature->PrimaryValue('Feature(id)');
                    # Compute the sort key.
                    my $sortKey = $rhelp->SortKey($feature);
                    $rhelp->PutData($sortKey, $fid, $feature);
                    $count++;
                }
                $self->PrintLine("Results found: $count.<br />");
                $retVal += $count;
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
    return "Search for %FIG{genes}% in selected %FIG{genomes}%, filtered by %FIG{subsystem}% or search [[FIG.KeywordBox][keywords]].";
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
    # Compute the title. We extract the number of genomes from the query parameters.
    my $cgi = $self->Q();
    my @genomes = $cgi->param('genome');
    my $count = scalar(@genomes);
    if ($count == 1) {
        $count = $genomes[0];
    } else {
        $count = "$count Genomes";
    }
    my $retVal = "Search for Genes in $count";
    # Return it.
    return $retVal;
}


1;
