#!/usr/bin/perl -w

package SHDrugSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use RHLigands;
    use Tracer;
    use base 'SearchHelper';

=head1 Drug Target PDB Docking Results Search Helper

=head2 Introduction

This search helper will display all the docking results for a particular
PDB. Most search helpers return a list of features. This one returns
a list of ligands. As a result, it is structurally very different. In
particular, all the columns are returned as extras.

This search has the following extra parameters.

=over 4

=item PDB

ID of the PDB whose information is to be displayed.

=back

=cut

# Table of drug topic category codes.
my %CodeTable = (
                 'ES'   => 'Essential',
                 'ES-X' => 'Essential',
                 'ES-L' => 'Essential',
                 'KA-T' => 'Antibiotic Target',
                 'KA-I' => 'Antibiotic Inhibitor',
                 'VA'   => 'Virulence Associated',
                 'VA-K' => 'Virulence Associated',
                 'VA-P' => 'Virulence Assocated',
                 'TX-K' => 'Toxin',
                 'TX-B' => 'Toxin',
                 'SA-A' => 'Surface Associated',
                 'SA-P' => 'Surface Associated',
                 'SA-S' => 'Surface Associated',
                 'SA'   => 'Surface Associated',
                 'SE-P' => 'Secreted Protein',
                 'SE'   => 'Secreted Protein',
                );

=head3 GetCategory

    my $description = SHDrugSearch::GetCategory($code);

Return the description of the specified category code.

=over 4

=item code

Category code to convert.

=item RETURN

Returns the description of the specified category code, as taken from the C<CodeTable> hash.

=back

=cut

sub GetCategory {
    # Get the parameters.
    my ($code) = @_;
    # Convert to upper case.
    my $catCode = uc $code;
    # Trim spaces.
    $catCode =~ s/\s+//g;
    # Extract it from the hash table.
    my $retVal = $CodeTable{$catCode};
    # Check for a not-found condition.
    if (! $retVal) {
        $retVal = "Unknown Code $catCode";
    }
    # Return the result.
    return $retVal;
}

=head3 PDBLink

    my $pdbHtml = SHDrugSearch::PDBLink($cgi, $pdbID);

This method converts a PDB ID to a hyperlink into the PDB web site.

=over 4

=item cgi

CGI object to be used to create the HTML.

=item pdbID

ID of the PDB to be hyperlinked.

=item RETURN

Returns a hyperlinked PDB ID that points to the PDB's page on the RCSB web site.

=back

=cut

sub PDBLink {
    # Get the parameters.
    my ($cgi, $pdbID) = @_;
    # Compose the link.
    my $retVal = CGI::a({href => "http://www.rcsb.org/pdb/explore.do?structureId=$pdbID",
                          title => "display this protein's page in the Protein Data Bank",
                          alt =>  "display this protein's page in the Protein Data Bank",
                          target => "_blank"}, $pdbID);

    # Return the result.
    return $retVal;
}

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
    my $retVal = $self->FormStart("Select PDB");
    # Get a list of all the PDBs with docking results.
    my @pdbData = $sprout->GetAll(['PDB'], "PDB(docking-count) > 0 ORDER BY PDB(docking-count) DESC",
                                  [], ['PDB(id)', 'PDB(docking-count)']);
    # See if there's already a PDB selected.
    my $defaultPDB = $cgi->param('PDB');
    # Create the PDB selection strings.
    my %pdbStrings = map { $_->[0] => "$_->[0], $_->[1] docking results" } @pdbData;
    my @pdbNames = map { $_->[0] } @pdbData;
    # Compute the number of rows to display in the selection list.
    my $rowCount = (scalar(@pdbNames) < 20 ? scalar(@pdbNames) : 20);
    # Convert the PDB list into a selection list.
    my $menu = CGI::popup_menu(-name => 'PDB', -values => \@pdbNames,
                                -labels => \%pdbStrings,
                                -default => $defaultPDB, -rows => $rowCount);
    # Build a table from the PDB list and the submit row.
    my @rows = (CGI::Tr(CGI::th('PDB'), CGI::td($menu)),
                $self->SubmitRow()
               );
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
This search does not return features, so it calls B<WriteColumnHeaders> and
B<WriteColumnData> instead of the handier B<PutFeature>

=cut

sub Find {
    my ($self) = @_;
    # Get the CGI and Sprout objects.
    my $cgi = $self->Q();
    my $sprout = $self->DB();
    # Declare the return variable. If it remains undefined, the caller will
    # know that an error occurred.
    my $retVal;
    # Insure a PDB is selected.
    my $pdbID = $cgi->param('PDB');
    if (! $pdbID) {
        $self->SetMessage("No PDB specified.");
    } else {
        # Get the ligand result helper.
        my $rhelp = RHLigands->new($self);
        # Set the default output columns.
        $self->DefaultColumns($rhelp);
        # Add the extra columns, most of which are taking from DocksWith.
        $rhelp->AddExtraColumn(energy        => undef, title => 'Total Energy',  style => 'rightAlign', download => 'num');
        $rhelp->AddExtraColumn(electrostatic => undef, title => 'Electrostatic', style => 'rightAlign', download => 'num');
        $rhelp->AddExtraColumn(vanderwaals   => undef, title => 'Van der Waals', style => 'rightAlign', download => 'num');
        $rhelp->AddExtraColumn(tool          => undef, title => 'Tool',          style => 'leftAlign',  download => 'text');
        # Initialize the session file.
        $self->OpenSession($rhelp);
        # Initialize the result counter.
        $retVal = 0;
        $self->PrintLine("Finding docking results for $pdbID.");
        # Get a query that will return the docking results for this PDB.
        my $query= $sprout->Get(['DocksWith', 'Ligand'],
                                "DocksWith(from-link) = ? ORDER BY DocksWith(total-energy)",
                                [$pdbID]);
        # Write the column headers.
        $self->PrintLine("Processing results.");
        # Loop through the results.
        while (my $record = $query->Fetch()) {
            # Get the data for this row.
            my ($id, $total, $electro, $vander, $tool) = $record->Values(['Ligand(id)',
                                                                          'DocksWith(total-energy)',
                                                                          'DocksWith(electrostatic-energy)',
                                                                          'DocksWith(vanderwaals-energy)',
                                                                          'DocksWith(tool)']);
            # Format the energy results so they don't look so awful.
            ($total, $electro, $vander) = map { sprintf('%.2f', $_) } ($total, $electro, $vander);
            # Put the extra columns.
            $rhelp->PutExtraColumns(energy => $total, electrostatic => $electro, vanderwaals => $vander,
                                    tool => $tool);
            # Finally, we must compute the sort key. We're getting the records in the correct order, so
            # the sort key is the ordinal of this record, which we are keeping in $retVal.
            my $key = $retVal;
            # Write everything to the session file.
            $rhelp->PutData($key, $id, $record);
            # See if we need to update the user.
            $retVal++;
            if ($retVal % 1000 == 0) {
                $self->PrintLine("$retVal ligands processed.");
            }
        }
        Trace("$retVal rows processed.") if T(3);
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
    return "Show the docking results for a specific PDB.";
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
    # Compute the title. We extract the PDB ID from the query parameters.
    my $cgi = $self->Q();
    my $pdbID = $cgi->param('PDB');
    my $retVal = "Docking Results for $pdbID";
    # Return it.
    return $retVal;
}

1;
