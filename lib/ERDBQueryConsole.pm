#!/usr/bin/perl -w

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#

package ERDBQueryConsole;

    use strict;
    use Tracer;
    use CGI;
    use ERDB;
    use Stats;

=head1 ERDB Query Console Helper

=head2 Introduction

This is a simple helper class used by the ERDB Query Console. The console
appears in two places: once as a SeedViewer page, and once as an NMPDR plugin
Wiki console. Each of these places is responsible for insuring that the user has
the proper credentials and then calling this package's main method. To construct
a console helper object, simply pass in the database name and the user's security
level, then call L</Submit> to validate the parameters and build the query. If
there are problems, call L</Errors> to get a list of error messages. If
everything went fine, call L</Headers> to get the names and styles for the result
columns and then L</GetRow> to get the individual result rows. The row elements
will be pre-encoded into HTML.

The fields in this object are as follows.

=over 4

=item erdb

L<ERDB> database object for the current database.

=item query

L<ERDBQuery> object for obtaining the query results.

=item fields

Reference to a list of result field information, in order. For
each result field, the list contains a hash consisting of the
field name (C<name>), a flag indicating whether or not it is
secondary (C<secondary>), and a reference to the field's
type object (C<type>).

=item objects

Object name string for the query.

=item filterString

Filter string for the query.

=item parms

Reference to a list of parameter values. There should be one parameter
value for each parameter mark in the query.

=item secure

TRUE if the user is privileged, else FALSE.

=item stats

Statistics object.

=back

=cut

=head3 new

    my $eq = ERDBQueryConsole->new($db, %options);

Construct a new ERDBQueryConsole object. The parameters are as follows.

=over 4

=item db

Database against which to run the query. This can be either an L<ERDB>
object for the database or a string containing the database name.

=item options

A hash of constructor options.

=back

The following options are supported.

=over 4

=item secure

TRUE if the user is privileged and can make unlimited queries. The default
is FALSE.

=item raw

TRUE to return the results in raw form rather than in HTML form.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $db, %options) = @_;
    # Get the options.
    my $secure = $options{secure} || 0;
    my $raw = $options{raw} || 0;
    # Get access to the database.
    my $erdb;
    if (! ref $db) {
        $erdb = ERDB::GetDatabase($db);
    } else {
        $erdb = $db;
    }
    # Create the ERDBQueryConsole object.
    my $retVal = { 
                    erdb => $erdb,
                    secure => $secure,
                    raw => $raw,
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 Submit

    my $okFlag = $eq->Submit($objects, $filterString, \@parms, $fields, $limitNumber);

Submit a query to the console. This method stores the relevant
information about the query and creates the query object. Other methods
can be used to get the results of the query or a list of error messages.

=over 4

=item objects

Object name string containing the list of objects that particpate in the
query.

=item filterString

Filter string for the query, specifying the query conditions, sort order,
and limit.

=item parms

Reference to a list of parameter values. Each parameter value is plugged
into a parameter mark in the filter string.

=item fields

String containing the result field names.

=item limitNumber

Maximum number of rows for the query. If the user is not privileged,
all queries are limited to a maximum number of rows determined by
the C<$ERDBExtras::query_limit> parameter. If the user is privileged,
a false value (undefined or 0) indicates an unlimited query.

=item RETURN

Returns TRUE if the query was successful, FALSE if an error was
detected.

=back

=cut

sub Submit {
    # Get the parameters.
    my ($self, $objects, $filterString, $parms, $fields, $limitNumber) = @_;
    # Clear this object for a new query.
    $self->Clear();
    # Count the parameter marks in the filter string.
    my $parmCount = ERDB::CountParameterMarks($filterString);
    # Count the parameters.
    my $suppliedParms = scalar(@$parms);
    Trace("$suppliedParms parameters found.") if T(3);
    # Verify the various parameters.
    if (! $objects) {
        $self->Error("No object list specified. Query aborted.");
    } elsif (! $fields) {
        $self->Error("No output fields specified. Query aborted.");
    } elsif ($parmCount > $suppliedParms) {
        $self->Error("You have $parmCount parameter marks but only $suppliedParms " .
                     "Parameters. Insure each parameter is on a separate line in " .
                     "the parameters box and that you don't have any extra question " .
                     "marks (?) in the Filter String.");
    } elsif ($parmCount < $suppliedParms) {
        $self->Error("You have $suppliedParms Parameters but there are only " .
                     "$parmCount parameter marks in the Filter String.")
    } else {
        # Now we can do the query. First, get the database object.
        my $db = $self->{erdb};
        # Parse the object name list.
        my @nameErrors = $db->CheckObjectNames($objects);
        if (@nameErrors) {
            # Here there were errors in the object name string.
            for my $nameError (@nameErrors) {
                $self->Error($nameError);
            }
            $self->Error("Errors were found in the Object Names.");
        } else {
            # Check to see if we need to limit this query.
            my $limitClause = "";
            if (! $self->{secure}) {
                # We do. Check for an existing limit.
                if ($filterString =~ /(.*)LIMIT\s+(\d+)(.*)/) {
                    # Fix it if it's too big.
                    if ($2 >= $ERDBExtras::query_limit) {
                        $filterString = "$1LIMIT $ERDBExtras::query_limit$3";
                    }
                } else {
                    # No limit present, so add one.
                    $limitClause = " LIMIT $ERDBExtras::query_limit";
                }
            } else {
                # Privileged users can request a different limit. Only use it
                # if there is not already a limit in the filter clause.
                if ($limitNumber && $filterString !~ /(?:^|\s)LIMIT\s/) {
                    $limitClause = " LIMIT $limitNumber";
                    Trace("Limit clause for $limitNumber rows added to query.") if T(2);
                }
            }
            # Now we need to find things out about the fields. For each one,
            # we need a column name and a cell format. To get that, we
            # start the query and analyze the fields.
            Trace("Preparing query.") if T(3);
            my $query = eval('$db->Prepare($objects, "$filterString$limitClause", $parms)');
            if ($@) {
                # Here the query preparation failed for some reason. This is usually an
                # SQL syntax error.
                $self->Error("QUERY ERROR: $@");
            } else {
                Trace("Parsing field list.") if T(3);
                # We need to get the necessary data for each field in the field list.
                # This will be set to TRUE if a valid field is found.
                my $found;
                # Now loop through the field names.
                for my $field (@$fields) {
                    Trace("Processing field name \"$field\".") if T(3);
                    # Get the data for this field.
                    my ($objectName, $fieldName, $type) = $query->CheckFieldName($field);
                    if (! defined $objectName) {
                        # Here the field specification had an invalid format.
                        $self->Error("Field specifier \"$field\" has an invalid format.");
                    } elsif (! defined $fieldName) {
                        # Here the object name was invalid. That generates a warning.
                        $self->Error("Object name \"$objectName\" not found in query.");
                    } elsif (! defined $type) {
                        # Here the field name was invalid. That is also a warning.
                        $self->Error("Field \"$fieldName\" not found in $objectName.");
                    } else {
                        # Here the field name is okay. Save its data.
                        push @{$self->{fields}},
                            { name => $field, type => $type,
                              secondary => $db->IsSecondary($fieldName, $objectName)
                            };
                        # Count the field.
                        $self->AddStat(fields => 1);
                        $found = 1;
                    }
                }
                # Insure we have at least one valid field.
                if (! $found) {
                    $self->Error("No valid field names were specified for this query.");
                } else {
                    # We do, so save the query and its parameters.
                    $self->{query} = $query;
                    $self->{parms} = $parms;
                    $self->{objects} = $objects;
                    $self->{filterString} = $filterString;
                }
            }
        }
    }
    # Return TRUE if no errors were detected.
    return defined $self->{query};
}

=head3 Headers

    my @columnData = $eq->Headers();

Return the header information for each column of the output. The header
information is returned as a list of 2-tuples. For each column, the
2-tuple includes the column caption and the alignment (C<left>, C<right>,
or C<center>).

=cut

sub Headers {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my @retVal;
    # Insure we have fields. If we don't, the query will be treated as
    # having 0 output columns: we'll return an empty list.
    if (defined $self->{fields}) {
        # We have something, so loop through the fields.
        for my $field (@{$self->{fields}}) {
            # Compute the alignment.
            my $align = $field->{type}->align();
            # Push it into the result list along with the field name.
            push @retVal, [$field->{name}, $align];
        }
    }
    # Return the result.
    return @retVal;
}

=head3 GetRow

    my @items = $eq->GetRow();

Get the next row of data from the query. Each row will consist of a list
of HTML strings (in normal mode) or PERL objects (in raw mode), one per result
column, in the same order the field names appeared when the query was submitted.

If the query is complete, an empty list will be returned.

=cut

sub GetRow {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my @retVal;
    # Only proceed if we have an active query.
    if (defined $self->{query}) {
        # We do, so try to get the next record. Note we accumulate the
        # time spent and protect from errors.
        my $start = time();
        my $record = $self->{query}->Fetch();
        $self->AddStat(duration => time() - $start);
        # Only proceed if a record was found.
        if (defined $record) {
            $self->AddStat(records => 1);
            # Now we have the data for this row, and it's time to
            # stuff it into the return list. Loop through the fields.
            for my $field (@{$self->{fields}}) {
                # Get the values for this field.
                my @values = $record->Value($field->{name});
                $self->AddStat(values => scalar(@values));
                # Are we returning raw data or HTML?
                if (! $self->{raw}) {
                    # Here we are in HTML mode. Get the field type.
                    my $type = $field->{type};
                    # Convert the values to HTML and string them together.
                    my $cell = join("<br /><hr /><br />",
                                    map { $type->html($_) } @values);
                    # Put the result into the output list.
                    push @retVal, $cell;
                } elsif ($field->{secondary}) {
                    # This is a raw secondary field. It's returned as a list reference.
                    push @retVal, \@values;
                } else {
                    # This is a raw primary field. It's returned as a scalar.
                    # Note that if the field is empty, we'll be stuffing an
                    # undefined value in its position of this row.
                    push @retVal, $values[0];
                }
            }
        }
    }
    # Return the result.
    return @retVal;
}

=head3 GetCode

    my $codeString = $eq->GetCode($dbVarName, $codeStyle, @parameters);

Return the PERL code to perform the query submitted to this console.

=over 4

=item dbVarName

Name to give to the variable containing the database object.

=item codeStyle

Coding style to use: C<Get> for a get loop, C<GetAll> for a single get-all
statement.

=item parameters

List of parameter names. If a parameter name is a string, then the
corresponding parameter will be encoded as a variable with the name
given by the string. If a parameter name is an undefined value, the
parameter value will be encoded as a constant.

=item RETURN

Returns a string containing the PERL code to duplicate the incoming
query.

=back

=cut

use constant GET_VAR_NAME => { Get => '$qh', GetFlat => '@results',
                               GetAll => '@rows' };

sub GetCode {
    # Get the parameters.
    my ($self, $dbVarName, $codeStyle, @parameters) = @_;
    # We'll create lines of PERL code in here.
    my @codeLines;
    # We'll use this constant for tabbing purposes.
    my $tab = " " x 4;
    # Compute the name of the database object.
    my $dbObjectName = '$' . $dbVarName;
    # We start with some USE statements.
    push @codeLines, "use ERDB;",
                     "use Tracer;";
    # Get the field list. We'll be using it a lot.
    my $fields = $self->{fields};
    # Add "use" statements for all the field types. We build a hash
    # to prevent duplicates.
    my %uses;
    for my $field (@$fields) {
        my $type = $field->{type}->objectType();
        if ($type) {
            $uses{$type} = 1;
        }
    }
    push @codeLines, map { "use $_;" } sort keys %uses;
    # Now create the database object.
    my $dbType = ref $self->{erdb};
    push @codeLines, "",
                     "my $dbObjectName = ERDB::GetDatabase('$dbType');",
                     "";
    # Compute the parameter strings list.
    my @parmStrings;
    my $parms = $self->{parms};
    my $parmsCount = scalar @$parms;
    for (my $i = 0; $i < $parmsCount; $i++) {
        if (defined $parameters[$i]) {
            push @parmStrings, $parameters[$i];
        } else {
            push @parmStrings, Quotify($parms->[$i]);
        }
    }
    # Clean up and quote the object name string.
    my $quotedObjectNameString = qq("$self->{objects}");
    $quotedObjectNameString =~ s/\s+/ /;
    # Quote the filter string.
    my $quotedFilterString = Quotify($self->{filterString});
    # Not we compute the function name. It's the same as the code style
    # unless we're doing a GetAll and there's only one field. In that case
    # we do a GetFlat.
    my $getName = ($codeStyle eq 'GetAll' && scalar(@$fields) == 1 ? 'GetFlat' : $codeStyle);
    # The result from the Get call depends on the type: a list for
    # GetAll or GetFlat, a scalar for Get.
    my $getResultName = GET_VAR_NAME->{$getName};
    # Build the Get. It's multiple lines, so we need to compute how far to
    # indent the secondary lines. In addition, we need to decide here whether
    # we're doing a Get or a GetAll.
    my $buffer = "my $getResultName = $dbObjectName->$getName(";
    my $continueTab = " " x length($buffer);
    # Now set up the buffer so that it has the Get call and the object
    # name string. This is the minimum content for the first line.
    $buffer .= "$quotedObjectNameString, ";
    # Now we break the rest of the statement into pieces.
    my @pieces = "$quotedFilterString, ";
    if (! @parmStrings) {
        push @pieces, "[]";
    } else {
        # Here we have a list of parameters. The first begins with a left bracket.
        push @pieces, "[" . shift(@parmStrings);
        # If there's more than one, we need to do some comma-joining.
        while (my $piece = shift @parmStrings) {
            # Put a comma at the end of the last piece.
            $pieces[$#pieces] .= ",";
            # Add the next piece.
            push @pieces, $piece;
        }
        # Put a right bracket on the last piece.
        $pieces[$#pieces] .= "]";
    }
    # If this is a GetAll, the field names go in here, too.
    if ($codeStyle eq 'GetAll') {
        # First, we need to put a comma at the end of the last parameter.
        $pieces[$#pieces] .= ", ";
        # Is this GetFlat?
        if ($getName eq 'GetFlat') {
            # Yes, so we have a single field.
            my $fieldName = $fields->[0]{name};
            push @pieces, "'$fieldName'";
        } else {
            # No, so we create a list of the field names. We use the qw
            # trick to do this.
            my @quotedFields = map { $_->{name} } @$fields;
            $quotedFields[0] = "[qw(" . $quotedFields[0];
            $quotedFields[$#quotedFields] .= ")]";
            for (my $i = 0; $i < $#quotedFields; $i++) {
                $quotedFields[$i] .= " ";
            }
            push @pieces, @quotedFields;
        }
    }
    # Put the statement terminator on the last piece.
    $pieces[$#pieces] .= ");";
    # Loop through the pieces, building the code lines.
    for my $piece (@pieces) {
        if (length($buffer) + length($piece) > 80) {
            push @codeLines, $buffer;
            $buffer = $continueTab;
        }
        $buffer .= $piece;
    }
    # Finish the Get statement. The buffer is never empty after the above
    # loop.
    push @codeLines, $buffer;
    # The rest of this is only necessary for the Get-style.
    if ($codeStyle eq 'Get') {
        # Build the fetch loop.
        push @codeLines, "while (my \$resultRow = \$qh->Fetch()) {";
        # Extract each field value.
        for my $field (@$fields) {
            # Get the field name.
            my $fieldName = $field->{name};
            # Convert the field name to a camel-cased variable name.
            my @pieces = split /[^a-z]+/, lc $fieldName;
            my $varName = shift @pieces;
            $varName .= join("", map { ucfirst $_ } @pieces);
            # We'll put the retrieval statement in here.
            my $statement;
            # Is this a primary field or a secondary field?
            if ($field->{secondary}) {
                # It's a secondary field, so we get a list of values.
                $statement = "my \@$varName = \$resultRow->Value('$fieldName');";
            } else {
                # It's primary, so we get a single value.
                $statement = "my \$$varName = \$resultRow->PrimaryValue('$fieldName');";
            }
            # If this field is complex, add a comment about the field type.
            my $type = $field->{type}->objectType();
            if (defined $type) {
                $statement .= " # $type object";
            }
            # Output the statement.
            push @codeLines, "$tab$statement";
        }
        # Close the fetch loop. This next line looks strange, but it
        # is necessary to keep the Komodo TODO-hunter from flagging this
        # line as an uncompleted task.
        my $sharps = "##" . "TODO";
        push @codeLines, "$tab##" . "TODO: Process data";
        push @codeLines, "}";
                        }
    # Return the result.
    return join("\n", @codeLines, "");
}

=head3 Summary

    my $statsHtml = $eq->Summary();

Return an HTML display of the statistics and messages for this query.

=cut

sub Summary {
    # Get the parameters.
    my ($self) = @_;
    # We'll accumulate HTML in here.
    my $retVal = "";
    # Get the statistics object.
    my $stats = $self->{stats};
    # Extract the messages.
    my @messages = $stats->Messages();
    # If there are messages, we need to display them.
    if (scalar @messages) {
        $retVal .= CGI::p("Errors and warnings for this query.") .
                   CGI::ul(map { CGI::li(CGI::escapeHTML($_)) } @messages);
    }
    # Now we display the statistics in alphabetical order, using a table.
    my $statMap = $stats->Map();
    my @keys = sort { Tracer::Cmp($a, $b) } keys %$statMap;
    $retVal .= CGI::h3("Query Statistics");
    $retVal .= CGI::table(
        map { CGI::Tr(CGI::th($_), CGI::td({ align => 'right' },
                                           $statMap->{$_})) } @keys);
    # Return the result.
    return $retVal;
}

=head3 Messages

    my $messages = $eq->Messages();

Return the error and status messages for the current query as a single string.

=cut

sub Messages {
    # Get the parameters.
    my ($self) = @_;
    # Return the queued messages.
    return join("\n", $self->{stats}->Messages());
}



=head3 SplitFields

    my @fields = ERDBQueryConsole::SplitFields($fieldString);

Convert a field string to a list of field names. The string can be either
comma-delimited or space-delimited.

=over 4

=item fieldString

String of field names.

=item RETURN

Returns a list of the field names culled from the string.

=back

=cut

sub SplitFields {
    # Get the parameters.
    my ($fieldString) = @_;
    # Declare the return variable.
    my @retVal;
    if ($fieldString =~ /,/) {
        # We found a comma, so use the comma pattern.
        push @retVal, split /\s*,\s*/, $fieldString;
    } else {
        # No commas, so use the space pattern.
        push @retVal, split /\s+/, $fieldString;
    }
    # Return the result.
    return @retVal;
}

=head2 Internal Methods

=head3 Quotify

    my $quoted = ERDBQueryConsole::Quotify($string);

Convert the input string to a PERL string constant. Internal single
quotes will be escaped, and the entire string will be surrounded by
single quotes.

=over 4

=item string

String to be quoted.

=item RETURN

Returns the string in a format suitable for encoding as a PERL
string literal.

=back

=cut

sub Quotify {
    # Get the parameters.
    my ($string) = @_;
    # Declare the return variable.
    my $retVal = $string;
    # Quote the internal quotes.
    $retVal =~ s/'/\\'/g;
    # Literalize the new-lines.
    $retVal =~ s/\n/\\n/g;
    # Return the result.
    return "'$retVal'";
}

=head3 Error

    $eq->Error($message);

Record an error message. Error messages are kept in a list attached to
this object.

=over 4

=item message

Message to add to the error list.

=back

=cut

sub Error {
    # Get the parameters.
    my ($self, $message) = @_;
    # Add the error message to our statistics object.
    $self->{stats}->AddMessage($message);
    # Record the error as a statistic.
    $self->AddStat(errors => 1);
}

=head3 AddStat

    $eq->AddStat($statName => $value);

Add the specified value to the named statistic.

=over 4

=item statName

Name of the relevant statistic.

=item value

Value to add to the named statistic counter.

=back

=cut

sub AddStat {
    # Get the parameters.
    my ($self, $statName, $value) = @_;
    $self->{stats}->Add($statName => $value);
}

=head3 Clear

    $eq->Clear();

Initialize this object for a new query.

=cut

sub Clear {
    # Get the parameters.
    my ($self) = @_;
    # Empty the field list.
    $self->{fields} = [];
    # Erase the statistics.
    $self->{stats} = Stats->new(qw(records fields errors));
    # Denote we have no query attached.
    $self->{query} = undef;
}




1;
