#!/usr/bin/perl -w

package SHOrgSumSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use Sprout;

    use RHFeatures;
    use base 'SearchHelper';

=head1 

=head2 Introduction

This is a simple search that returns features which are named or hypothetical
and in or not in subsystems. The goal is to separate the genes according to how
much we know about them. Genes in subsystems are ones in which we have a high
degree of confidence about their existence. Genes that are hypothetical are ones
in which we do not know the function. The two criteria lead to four different
possible sets.

This search has the following extra parameters.

=over 4

=item genome

ID of the target genome

=item hypothetical

C<hypo> if we only want hypothetical genes, C<named> if we only want
named genes, and C<both> if we want both hypothetical and named genes.

=item insubsystem

C<in> if we only want genes in subsystems, C<out> if we only want genes
not in subsystems, and C<both> if we want all genes.

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
    # Get the incoming parameter values.
    my $genomeID = $cgi->param('genome');
    my $hypothetical = $cgi->param('hypothetical') || 'both';
    my $inSubsystem = $cgi->param('insubsystem') || 'both';
    # Start the form.
    my $retVal = $self->FormStart("Organism Summary Gene Search");
    # Declare a variable to hold the table rows.
    my @rows = ();
    # Start with a genome control.
    push @rows, CGI::Tr(CGI::th('Select a genome'),
                        CGI::td($self->NmpdrGenomeMenu('genome',
                                                       0, [$genomeID], 10)));
    # Now the checkboxes.
    push @rows, CGI::Tr(CGI::th("Function"),
                        CGI::td(CGI::popup_menu(-name => 'hypothetical',
                                                -values => [qw(hypo named both)],
                                                -labels => { hypo => 'Hypothetical only',
                                                             named => 'Named only',
                                                             both => 'Both hypothetical and named' },
                                                -default => $hypothetical)));
    push @rows, CGI::Tr(CGI::th("Status"),
                        CGI::td(CGI::popup_menu(-name => 'insubsystem',
                                                -values => [qw(in out both)],
                                                -labels => { in => 'Subsystem genes only',
                                                             out => 'Non-subsystem genes only',
                                                             both => 'Both subsystem and non-subsystem genes' },
                                                -default => $inSubsystem)));
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

# This hash is used to compute the sort key. The input value is hypothetical flag
# followed by in-subsystem flag.
use constant SORT_POSITION => { ' X' => 1,
                                '  ' => 2,
                                'XX' => 3,
                                'X ' => 4};

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
        my $genome = $cgi->param('genome');
        my $hypothetical = $cgi->param('hypothetical') || 'both';
        my $insubsystem = $cgi->param('insubsystem') || 'both';
        # These hashes tell us which truth values for the subsystem
        # flag and the hypothetical flag correspond to features we
        # want to keep.
        my %subFlags  = (' ' => ($insubsystem ne 'in'),
                         'X' => ($insubsystem ne 'out'));
        my %hypoFlags = (' ' => ($hypothetical ne 'hypo'),
                         'X' => ($hypothetical ne 'named'));
        # Insure we have a genome ID.
        if (! defined $genome) {
            $self->SetMessage("Please select a genome.");
        } else {
            # Initialize the result counter.
            $retVal = 0;
            # Get the default columns.
            $self->DefaultColumns($rhelp);
            Trace("Column list is " . join(", ", @{$rhelp->GetColumnHeaders()})) if T(3);
            # Add the extra columns.
            $rhelp->AddExtraColumn(hypothetical => undef, download => 'text',
                                   title => 'Hypothetical', style => 'center');
            $rhelp->AddOptionalColumn(subsystem => undef);
            # Start the output session.
            $self->OpenSession($rhelp);
            # Create an SQL pattern for this genome's features.
            my $genomePattern = "fig|$genome.%";
            # Now we want to create a hash of all the features in this
            # genome that are in subsystems. We do this by querying the
            # HasRoleInSubsystem table.
            $self->PrintLine(CGI::p("Analyzing subsystems."));
            my %inSubsystem;
            my $qh = $sprout->Get('HasRoleInSubsystem',
                                  "HasRoleInSubsystem(from-link) LIKE ?",
                                  [$genomePattern]);
            while (my $feature = $qh->Fetch()) {
                $inSubsystem{$feature->PrimaryValue('from-link')} = 1;
            }
            # Create the query for all the features in this genome.
            $self->PrintLine(CGI::p("Computing query."));
            $qh = $sprout->Get('Feature',
                               "Feature(id) LIKE ?", [$genomePattern]);
            # Count the genome's features in here so the user gets progress.
            my $featureCount = 0;
            $self->PrintLine(CGI::p("Processing results."));
            # Loop through them.
            while (my $feature = $qh->Fetch()) {
                # Get the feature ID.
                my $fid = $feature->PrimaryValue('id');
                # Check to see if we're hypothetical.
                my $assignment = $feature->PrimaryValue('assignment');
                my $hypoFlag = ($assignment =~ /hypothetical/ ? 'X' : ' ');
                # Check to see if we're in a subsystem.
                my $subFlag = ($inSubsystem{$fid} ? 'X' : ' ');
                # Do we want to keep this feature?
                if ($hypoFlags{$hypoFlag} && $subFlags{$subFlag}) {
                    # Yes. Count it as a result.
                    $retVal++;
                    # Output its hypothetical flag.
                    $rhelp->PutExtraColumns(hypothetical => $hypoFlag);
                    # Compute the sort key. We sort from least confidence
                    # to most.
                    my $sortKey = SORT_POSITION->{"$hypoFlag$subFlag"} . $fid;
                    # Output the feature.
                    $rhelp->PutData($sortKey, $fid, $feature);
                }
                # Count this feature.
                $featureCount++;
                if ($featureCount % 500 == 0) {
                    $self->PrintLine(CGI::p("$featureCount features processed, $retVal kept."));
                }
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
    my $genomeID = $cgi->param('genome') || 'unknown genome';
    my $retVal = "Organism Summary Search Search Results for $genomeID.";
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
    return "Search for %FIG{genes}% with certain characteristics in a single %FIG{genome}%.";
}


1;
