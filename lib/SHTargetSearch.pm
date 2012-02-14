#!/usr/bin/perl -w

package SHTargetSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use RHFeatures;
    use base 'SearchHelper';

=head1 Candidate Target Features Search Helper

=head2 Introduction

This search allows the user to specify a boolean combination of genome and feature
criteria for searching.

The idea of this search is that the user initially sees a few rows of
fields, and has the option of adding more. As a result, instead of a single list
of form fields, every single form field is itself a list, and the lists are
precisely in parallel. So, there will be a list of C<operator> values and a list
of C<type> values, and the tenth operator will correspond to the tenth type.

Each criterion is represented by an [[TargetCriterionPm]] object. The methods of this
object are used to handle the special processing required by each individual
criterion, including the javascript required to configure the form fields and
the post-processing of the query results. The exceptions are the standard feature
filter fields.

A criterion in the target search form is implemented as a table row. The first
column of the table contains buttons for adding and deleting rows. The second
column contains the I<type dropdown>. Selecting an entry in the type dropdown tells
the target search which criterion object applies to it. The last column contains
configurable form fields, including a I<selection control>, a I<min/max control>,
a I<text input control>, and a I<hint control>.

The form fields for the search are as follows. 

=over 4

=item operator

Boolean operator for this criterion: C<AND>, C<OR>, or C<NOT>.

=item type

Type of this criterion from the I<type dropdown>. The type is used to find the
criterion's [[TargetCriterionPm]] object.

=item selection

Value selected from the I<selection control>.

=item minValue

Minimum value for a range, from the I<min/max control>.

=item maxValue

Maximum value for a range, from the I<min/max control>.

=item stringValue

String entered by the user, from the I<text input control>.

=back

This object contains the following local fields, in addition to the
fields of the [[SearchHelperPm]] base class.

=over 4

=item targetSearchTypes

Table of search criterion types. This is a reference to a hash that
matches the possible values in the type dropdown to [[TargetCriterionPm]]
objects.

=item targetSearchCriteria

Reference to a list of Criterion Parameter Objects describing the search
criteria present on the input form, or C<undef> if the criteria have not
been parsed yet.

=item targetSearchValid

TRUE if no error was detected during parsing of the search criteria, FALSE if
one or more parameters were invalid.

=back

=head3 Parameter Name List

The parameter name list is a constant that defines the names of the configurable
parameters in the target search form. Each criterion row has a complete set of these
fields, but only certain fields display for each criterion type.

=cut

my @ParmNames = qw(selection minValue maxValue stringValue operator);

=head3 Criterion Parameter Objects

A [[TargetCriterionPm]] object describes a search criterion type. To describe an
actual search criterion, we use I<Criterion Parameter Objects>. These objects are
simple hashes containing the values for all the parameters in the search criterion's
table row on the search form. In addition, the object contains an index number (key C<idx>),
a pointer to the relevant [[TargetCriterionPm]] object (key C<type>), the relevant
criterion type (key C<typeKey>, and a flag indicating whether or not the
criterion was enforced using SQL (key C<sql>). This tells us all we need to know
to process the query and its aftermath.

=head2 Virtual Methods

=head3 Initialize

    $shelp->Initialize();

Perform end-of-constructor initialization for this search helper.

=cut

sub Initialize {
    my ($self) = @_;
    # Create the result helper.
    my $rhelp = RHFeatures->new($self);
    $self->{rhelp} = $rhelp;
    # Ask it for the search types.
    $self->{targetSearchTypes} = $rhelp->GetCriteria();
    # Denote we haven't parsed the criteria yet.
    $self->{targetSearchCriteria} = undef;
    $self->{targetSearchValid} = 1;
}

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
    # Insure the criteria have been computed. We need this for the CriterionRows
    # method that builds the form to work properly.
    $self->ComputeCriteria();
    # Include our special javascript.
    my $retVal = qq(<script type="text/javascript" src="$FIG_Config::cgi_url/Html/SHTargetSearch.js"></script>);
    # Start the form.
    $retVal .= $self->FormStart("Target Feature Search");
    # Create the data needed to manage the type dropdown. We start with a sorted
    # list of available criterion types.
    my $searchTypes = $self->{targetSearchTypes};
    my @typeList = sort { $self->CriterionCMP($searchTypes, $a, $b) } keys %$searchTypes;
    # Now we loop through the types. For each type, we store its label in the label hash,
    # generate its configuration javascript, and specify its style class in attribute hash.
    my $labelHash = {};
    my @javascript = ("function configureCriterion(field) {",
                      "  var selectData = new Array(0);",
                      "  var typeValue = field.value;",
                      "  switch (typeValue) {",
                     );
    for my $type (@typeList) {
        # Get the criterion object.
        my $typeData = $searchTypes->{$type};
        # Stuff the label in the label hash.
        $labelHash->{$type} = $typeData->label();
        # If it's sane, it gets an attribute.
        # Start the javascript for this type selection.
        push @javascript, "  case '$type' : ";
        # If we have selection data, we need to build it.
        my $selectionHash = $typeData->selectionData();
        if (defined $selectionHash) {
            my @constructor = map { qq("$_", "$selectionHash->{$_}") } sort keys %$selectionHash;
            push @javascript, "    selectData = [" . join(", ", @constructor) . "];";
        }
        # Create a Javascript string literal out of the hint.
        my $hint = $typeData->hint();
        $hint =~ s/'/\\'/g;
        $hint = "'$hint'";
        # Generate the parameters to configureRow.
        my @parms = ('field.parentNode', $typeData->minMax(), $typeData->text(), $hint,
                     'selectData');
        # Generate the configuration call.
        push @javascript, "    configureRow(", join(", ", @parms) . ");";
        # Finally, the break statement.
        push @javascript, "    break;";
    }
    # Create a table for the form data. It will contain one or more
    # criterion rows.
    my @table = CGI::Tr(CGI::td("Search Conditions"), CGI::td({colspan => 2},
                        $self->CriterionRows(\@typeList, $labelHash, $cgi)));
    # Add the submit row.
    push @table, $self->SubmitRow();
    $retVal .= $self->MakeTable(\@table);
    # Close the javascript and queue it.
    push @javascript, "  }",
                      "}";
    $self->QueueFormScript(join("\n", @javascript));
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
    my $rhelp = $self->{rhelp};
    $self->PrintLine("Analyzing criteria.");
    # Get the search criteria from the form fields. Most of the time, the
    # criteria will already have been computed when the form was built, but
    # if the client turned off the form, this precaution will save us from
    # disaster.
    my $criteria = $self->ComputeCriteria();
    # Only proceed if the criteria were valid.
    if (defined $criteria) {
        # Set the column list.
        $self->DefaultColumns($rhelp);
        # We now begin the process of handling extra columns. For each criterion
        # object, we ask it if extra columns are required. If so, it must call
        # the AddExtraColumn method on the result helper to make things
        # ready. We only want to do this, however, once per criterion object,
        # and the same criterion object may occur multiple times in the criterion
        # list. To start us off, we create a hash mapping TargetCriterion types to
        # TargetCriterion objects for the criteria used in this search, and a list
        # of the TargetCriterion objects used in this search that demand extra
        # columns be added to the results.
        my (%usedCriterionTypes, @extraColumnsNeeded);
        # Now loop through the criteria.
        for my $criterion (@$criteria) {
            # Get this criterion's type name.
            my $type = $criterion->{typeKey};
            # Only look at this criterion if it's a new type.
            if (! exists $usedCriterionTypes{$type}) {
                # Get its type object.
                my $typeData = $criterion->{type};
                $usedCriterionTypes{$type} = $typeData;
                # Add this to the result helper as an optional column.
                $rhelp->AddOptionalColumn($typeData->colName());
            }
        }
        # Initialize the session file.
        $self->OpenSession($rhelp);
        # Initialize the result counter.
        $retVal = 0;
        # This hash will be used to prevent duplicates.
        my %fids;
        # Create the query.
        Trace("Creating query.") if T(3);
        my $fquery = $self->ComputeQuery($criteria);
        while (my $feature = $fquery->Fetch()) {
            # Get the feature ID.
            my $fid = $feature->PrimaryValue('Feature(id)');
            # Only process this feature if it's new.
            if (! exists $fids{$fid}) {
                # Reset the criterion objects for the new feature.
                for my $typeData (values %usedCriterionTypes) {
                    $typeData->Reset();
                }
                # Check to see if this feature matches.
                if ($self->CheckFeature($feature, $criteria)) {
                    # It does. Compute the sort key.
                    my $sortKey = $rhelp->SortKey($feature);
                    # Emit the feature.
                    $rhelp->PutData($sortKey, $fid, $feature);
                    $retVal++;
                }
                # Insure we don't check this feature again.
                $fids{$fid} = 1;
            }
        }
        $self->PrintLine("Results found: $retVal.<br />");
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
    return "Search for genes in selected genomes, filtered by various criteria.";
}

=head3 SearchTitle

    my $titleHtml = $shelp->SearchTitle();

Return the display title for this search. The display title appears above the search results.
If no result is returned, no title will be displayed. The result should be an html string
that can be legally put inside a block tag such as C<h3> or C<p>.

=cut

sub SearchTitle {
    return "Custom Gene Target Search";
}

=head3 HeaderHtml

    my $html = $shelp->HeaderHtml();

Generate HTML for the HTML header. If extra styles or javascript are required,
they should go in here.

=cut

sub HeaderHtml {
    return qq(<script type="text/javascript" src="$FIG_Config::cgi_url/Html/SHTargetSearch.js"></script>);
}

=head3 GetResultHelper

    my $rhelp = $shelp->GetResultHelper($className);

Return a result helper for this search helper. The default action is to create
a result helper from scratch; however, if the subclass has an internal result
helper it can override this method to return it without having to create a new
one.

=over 4

=item className

Result helper class name.

=item RETURN

Returns a result helper of the specified class connected to this search helper.

=back

=cut

sub GetResultHelper {
    # Get the parameters.
    my ($self, $className) = @_;
    # Return our internal result helper.
    return $self->{rhelp};
}



=head2 Internal Methods

=head3 ComputeCriteria

    my $criteria = $self->ComputeCriteria(\@genomes);

Parse the search criteria from the form fields and return them in a list
reference. For each criterion, the list will contain a hash of the
relevant form fields. If the criteria are invalid, the return value will
be undefined instead of a list reference. The criteria are stored in
the =targetSearchCriteria= field of this object regardless of whether or
not there is an error; however, if there is an error, the return value
will not be the criterion list, it will be undefined.

=cut

sub ComputeCriteria {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return value.
    my $retVal;
    # Do we already have the criteria?
    my $criteria = $self->{targetSearchCriteria};
    if (defined $criteria) {
        # If there were no errors, return it.
        $retVal = $criteria if $self->{targetSearchValid};
    } else {
        # Here we need to compute them. Start with an empty list.
        $criteria = [];
        # Get the search type hash.
        my $searchTypes = $self->{targetSearchTypes};
        # This will be set to FALSE if an error is detected.
        my $ok = 1;
        # We'll save error messages in here.
        my @errors;
        # Get the CGI query object.
        my $cgi = $self->Q();
        # Extract the main parameter lists.
        my %parmLists = map { $_ => [ $cgi->param($_) ] } @ParmNames;
        # The number of sane criteria will be kept in here. We need at least one
        # sane criterion for the search to be possible. Theoretically, we will
        # only have a sanity failure if the user leaves the top row blank.
        my $sane = 0;
        # Get the list of incoming criterion types.
        my @types = $cgi->param('type');
        # Loop through the types.
        for (my $i = 0; $i <= $#types && $ok; $i++) {
            # Get this criterion's actual type.
            my $type = $types[$i];
            # Only proceed if it's non-null. Null criteria match every feature,
            # and do not affect the results. Leaving them in means extra work
            # and confuses the OR counting.
            if ($type) {
                # Get a hash for this type's parameter data.
                my $criterionRow = { map { $_ => $parmLists{$_}->[$i] } @ParmNames };
                # Add the type.
                my $typeData = $searchTypes->{$type};
                $criterionRow->{type} = $typeData;
                $criterionRow->{typeKey} = $type;
                # Add the index. The TargetCriterion object uses the index to generate
                # unique table names in the join string.
                $criterionRow->{idx} = $i;
                # Add the SQL flag. This is set to 1 later on if the criterion is
                # enforced by the SQL query.
                $criterionRow->{sql} = 0;
                # Validate the parameters.
                $ok = $typeData->Validate($criterionRow);
                if (! $ok) {
                    # The validation failed, so we need to set an error message.
                    push @errors, $typeData->message();
                }
                # Push this criterion into the result list.
                push @$criteria, $criterionRow;
                # If the operator is AND, we do a sanity check.
                if ($criterionRow->{operator} eq 'AND' && $typeData->Sane($criterionRow)) {
                    $sane++;
                }
            }
        }
        # If we're OK so far, do a sanity check.
        if ($ok && ! $sane) {
            push @errors, "This query is too broad. Please specify a value for the first condition.";
            Trace("Query rejected: too broad.") if T(3);
            $ok = 0;
        }
        # Save the criteria and the error flag.
        $self->{targetSearchCriteria} = $criteria;
        $self->{targetSearchValid} = $ok;
        # Do we have errors?
        if (! $ok) {
            # Yes, save the error message.
            $self->SetMessage(join("\n", @errors));
        } else {
            # No, return the criteria list.
            $retVal = $criteria;
        }
    }
    # Return the result.
    return $retVal;
}


=head3 CriterionRows

    my $html = $shelp->CriterionRows(\@typeList, \%labelHash, $cgi, $attrHash);

Return the HTML for a criterion table with a single row and the specified
boolean operator. The criterion table is an invisible table that allows
the user to add new rows or delete any row but the first one.

The last cell in each criterion row contains the controls that are configured
each time the user changes the type dropdown. The selection control is a C<select>
tag named C<selection>. The hint control is an anchor tag. The anchor tag's
title will contain the tooltip. The min/max control is a C<span> tag named C<minMax>.
The text control is an C<input> tag named C<stringValue>. This arrangement is
bound fairly tightly with the javascript methods in [[SHTargetSearchJs]].

The criterion row places a group of span tags in the last table cell. Each of
these has a class name that indicates which control it represents. The span style
is toggled between C<display: inline> and C<display: none> by the javascript
configuration method. If additional controls are needed, they should be treated
the same way. The Javascript counts rather heavily on the fact that the type
dropdown is the only select box that is an immediate child of a table cell.

=over 4

=item typeList

Reference to a list of the criterion types. This is used to build the type
dropdown.

=item labelHash

Reference to a hash of criterion types to display labels. This is used to build
the type dropdown.

=item cgi

A CGI query object containing the current values of the query parameters. This
is used to pre-generate the table rows using data from the previous search.

=item attrHash (optional)

Reference to a hash of display attributes for the entries in the type dropdown.
This is used to help the user determine which criterion types are sane.

=item RETURN

Returns a borderless HTML table with the javascript support needed to add and
delete criteria.

=back

=cut

# This constant helps us to compute the display style of each configurable control.
use constant STYLES => { true => 'display: inline', false => 'display: none' };

sub CriterionRows {
    # Get the parameters.
    my ($self, $typeList, $labelHash, $cgi, $attrHash) = @_;
    # Default the attribute hash if it wasn't passed in.
    if (! defined $attrHash) {
        Trace("No attributes for search criteria.") if T(3);
        $attrHash = {};
    } else {
        Trace("Attribute hash is\n" . Dumper($attrHash)) if T(3);
    }
    # Insure we have at least one criterion.
    my @criteria = @{$self->{targetSearchCriteria}};
    if (! @criteria) {
        my %nullCriterion = map { $_ => "" } @ParmNames;
        $nullCriterion{operator} = "AND";
        $nullCriterion{typeKey} = "";
        $nullCriterion{type} = $self->{targetSearchTypes}{""};
        push @criteria, \%nullCriterion;
    }
    # We'll build the table rows in here.
    my @rows = ();
    # Loop through the criteria.
    for my $criterion (@criteria) {
        # Get the TargetCriterion object and its name.
        my $typeData = $criterion->{type};
        my $typeKey = $criterion->{typeKey};
        # Get the operator.
        my $op = $criterion->{operator};
        # Compute the selection data stuff. Note that if there is no selection,
        # we create a dummy list to insure that the value is passed along by
        # the form. This is critical, because all of the value lists on the
        # form must be in parallel.
        my ($valueList, $selected, $showSelect);
        my $selectHash = $typeData->selectionData();
        if (! defined $selectHash) {
            # No select hash, so create a dummy list with a selected value of 0.
            $selectHash = {"0" => "(none)"};
            $valueList = ["0"];
            $selected = "0";
            $showSelect = "false";
        } else {
            # A select hash exists, so create a selection control out of it. We must
            # be sure to chop off the asterisk used to tell the JavaScript which value
            # is the default.
            $valueList = [ sort keys %$selectHash ];
            my %labelList;
            for my $key (@$valueList) {
                $labelList{$key} = $selectHash->{$key};
                $labelList{$key} =~ s/^\*//;
            }
            $selectHash = \%labelList;
            $selected = $criterion->{selection};
            $showSelect = "true";
        }
        # Get the other match flags.
        my $minMax = $typeData->minMax();
        my $text = $typeData->text();
        # Now generate the row.
        my $row = CGI::Tr(
            CGI::td(join("",
                CGI::button(-name => 'plus', -value => '+',
                            -class => 'button', -title => "Add a new row",
                            -onClick => 'addRow(this.parentNode)'),
                CGI::button(-name => 'minus', -value => '-',
                            -class => 'button', -title => "Delete this row",
                            -onClick => 'delRow(this.parentNode)'),
                " ",
                CGI::popup_menu(-name => 'operator', -values => [qw(AND OR NOT)],
                                -default => $op),
                    )),
            CGI::td(join("",
                        CGI::hidden(-name => 'operator', -value => $op),
                        CGI::popup_menu(-name => 'type', -values => $typeList,
                                        -labels => $labelHash,
                                        -onChange => 'configureCriterion(this)',
                                        -default => $typeKey,
                                        -attributes => $attrHash),
                    )),
            CGI::td(join(" ",
                        CGI::a({ href => "$FIG_Config::cgi_url/wiki/view.cgi/FIG/TargetSearch" },
                               qq(<img src="$FIG_Config::cgi_url/Html/button-h.png" />)),
                        CGI::span({ style => STYLES->{$showSelect}, class => '_selectionControl' },
                                  CGI::popup_menu(-name => 'selection', -values => $valueList,
                                                  -labels => $selectHash, -default => $selected)),
                        CGI::span({ style => STYLES->{$minMax},
                                    class => '_minMaxControl' },
                                  "from " .
                                  CGI::textfield(-name => 'minValue', -size => 5,
                                                 -value => $criterion->{minValue}) .
                                  " to " .
                                  CGI::textfield(-name => 'maxValue', -size => 5,
                                                 -value => $criterion->{maxValue})),
                        CGI::span({ style => STYLES->{$text}, class => '_textControl' },
                                  CGI::textfield(-name => 'stringValue', -size => 30,
                                                 -value => $criterion->{stringValue})),
                    )),
            );
        push @rows, $row;
    }
    # Return the result.
    my $retVal = CGI::table({ class => 'target' }, CGI::Tr(\@rows));
    return $retVal;
}

=head3 ComputeQuery

    my $fquery = $self->ComputeQuery($criteria);

Compute the query for searching in the specified genome to find the
features with the specified criteria. The return value will be an
[[ERDBQueryPm]] object that returns the desired features.

=over 4

=item criteria

Reference to a list of Criterion Parameter Objects.

=item RETURN

Returns a query object for retrieving features that match as many of the
criteria as possible.

=back

=cut

sub ComputeQuery {
    # Get the parameters.
    my ($self, $criteria) = @_;
    # The filter clauses and parameters will go in these arrays.
    my (@filters, @parms);
    # The join string will be built in here. The list always starts with a
    # genome-to-feature path. Additional criteria may add to the list.
    my $joinString = "Genome HasFeature Feature";
    # Now loop through the criteria, adding the filters. Only AND filters will
    # be processed this way. There's always at least one that's sane, or we
    # wouldn't have come this far.
    for my $criterion (@$criteria) {
        # Get this criterion's type and operator.
        my $typeData = $criterion->{type};
        my $op = $criterion->{operator};
        # Only continue if it's an AND.
        if ($op eq 'AND') {
            # Get this criterion's query data.
            my ($joins, $filterString, $parms) = $typeData->ComputeQuery($criterion);
            # Only proceed if this criterion really is involved in the query process.
            if (defined $joins) {
                # First, we must handle the join path. If there is one, each element after
                # the first needs to be suffixed with a number.
                if (scalar(@$joins) > 1) {
                    # Start by putting in the base entity (Feature or Genome).
                    my $base = shift @$joins;
                    $joinString .= " AND $base";
                    # Now put in the rest of the path.
                    for my $join (@$joins) {
                        # Suffix this criterion's index to the join.
                        my $newJoin = "$join$criterion->{idx}";
                        # Fix it in the filter string.
                        $filterString =~ s/$join\(/$newJoin\(/gx;
                        # Add this join onto the path.
                        $joinString .= " $newJoin";
                    }
                }
                # Now push in the fixed filter and the parameters.
                push @filters, "($filterString)";
                push @parms, @$parms;
                # Finally, denote that this criterion was processed using SQL.
                $criterion->{sql} = 1;
            }
        }
    }
    # Compute the final filter string.
    my $filter = join(" AND ", @filters);
    # Create and execute the query.
    my $sprout = $self->DB();
    Trace("Target search query filter is \"$filter\" against ($joinString) with parameters: " .
          join(", ", @parms)) if T(3);
    my $retVal = $sprout->Get($joinString, $filter, \@parms);
    # Return the result.
    return $retVal;
}

=head3 CheckFeature

    my $flag = $self->CheckFeature($feature, $criteria);

Return TRUE if the specified feature satisfies the criteria, else FALSE.

=over 4

=item feature

[[ERDBObjectPm]] object containing at least the feature and genome records.

=item criteria

Reference to a list of Criterion Parameter Objects.

=item RETURN

Returns TRUE if the feature matches, else FALSE.

=back

=cut

sub CheckFeature {
    # Get the parameters.
    my ($self, $feature, $criteria) = @_;
    # We have essentially three categories of criteria: AND, OR, and NOT. We will count
    # the total number of each as well as the number of matches for each. The result
    # will enable us to determine whether or not we have a match.
    my %total   = map { $_ => 0 } qw(AND OR NOT);
    my %matched = map { $_ => 0 } qw(AND OR NOT);
    # Now loop through the criteria.
    for my $criterion (@$criteria) {
        # Get the operator and the SQL flag.
        my $op = $criterion->{operator};
        my $match = $criterion->{sql};
        # If this criterion hasn't been enforced by SQL, check it against the
        # criterion type.
        if (! $match) {
            my $typeData = $criterion->{type};
            $match = $typeData->Check($criterion, $feature);
        }
        # Increment the total count.
        $total{$op}++;
        # If we have a match, increment the match count.
        $matched{$op}++ if $match;
    }
    # Now determine if the feature as a whole matches.
    my $retVal = ($total{AND} == $matched{AND} &&
                  ($total{OR} == 0 || $matched{OR} > 0) &&
                  $matched{NOT} == 0);
    # Return the result.
    return $retVal;
}


=head3 CriterionCMP

    my $cmp = $shelp->CriterionCMP(\%searchTypes, $a, $b);

Return a comparison number for two criteria. The comparison number is
designed to be used in a sort command that will order the criterion
types. Sane criteria sort before insane criteria, feature criteria sort
before organism criteria, and within those groups everything is
alphabetical.

=over 4

=item searchTypes

Reference to a hash of type names to [[TargetCriterionPm]] objects.

=item a

First type to compare.

=item b

Second type to compare.

=item RETURN

Return a negative number if the two types are in the correct order,
a positive number if they should be switched, and 0 if they are the
same.

=back

=cut

sub CriterionCMP {
    # Get the parameters.
    my ($self, $searchTypes, $a, $b) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Only proceed if there's a difference.
    if ($a ne $b) {
        # Null sorts before everything.
        if ($a eq '') {
            $retVal = -1;
        } elsif ($b eq '') {
            $retVal = 1;
        } else {
            # Here we have a nontrivial case. Compute a sort key for
            # each criterion type.
            my @keys;
            for my $type ($a, $b) {
                my $thing = $searchTypes->{$type};
                # Get the sanity flag. Sanity should sort low.
                my $key = ($thing->Sane() ? 'A' : 'Z');
                # Get the label.
                my $label = $thing->label();
                # First comes the organism flag. Organism sorts high.
                $key .= ($label =~ /^Organism/ ? 'Z' : 'A');
                # Tack on the label. Because we want to do a case-insensitive
                # sort, we put in the label lower-cased followed by the
                # real version.
                $key .= join(':', lc($label), $label);
                # Save this key.
                push @keys, $key;
            }
            # Compare the computed sort keys.
            $retVal = $keys[0] cmp $keys[1];
        }
    }
    # Return the result.
    return $retVal;
}
1;